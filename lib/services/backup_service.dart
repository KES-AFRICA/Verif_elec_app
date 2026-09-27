// lib/services/backup_service.dart
// ============================================================
// SYSTÈME DE SAUVEGARDE ET RESTAURATION COMPLÈTE
// Schema version : 2
// Rétrocompatible V1 : les sauvegardes V1 sont importables.
// Nouveautés V2 :
//   - exporterMission(missionId) : export ciblé d'une seule mission
//   - deleteMissionCompletely(missionId) : suppression totale sécurisée
//   - Checksum SHA-256 sur chaque export (détection de corruption)
//   - Magic V2 : INSPEC_BACKUP_V2
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/trash_item.dart';
import 'package:inspec_app/services/trash_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/mission.dart';
import '../models/audit_installations_electriques.dart';
import '../models/description_installations.dart';
import '../models/classement_locaux.dart';
import '../models/classement_zone.dart';
import '../models/foudre.dart';
import '../models/mesures_essais.dart';
import '../models/jsa.dart';
import '../models/renseignements_generaux.dart';
import '../models/lighting_inspection.dart';
import 'hive_service.dart';
import 'installation_description_sync_service.dart';
import 'sequence_progress_service.dart';
import 'intervenants_service.dart';
import 'package:inspec_app/services/backup/backup_format_strategy.dart';
import 'package:inspec_app/services/backup/operation_progress_state.dart';
import 'package:inspec_app/features/backup/data/datasources/backup_queue_service.dart';
import 'package:inspec_app/features/backup/data/datasources/local_backup_store.dart';
import 'package:inspec_app/features/backup/data/services/mission_activity_tracker.dart';
import 'package:inspec_app/features/backup/domain/models/backup_queue_item.dart';

// ─────────────────────────────────────────────────────────────
// RÉSULTATS TYPÉS
// ─────────────────────────────────────────────────────────────
class BackupResult {
  final bool success;
  final String? message;
  final String? filePath;
  final int? missionCount;
  final String? errorDetail;
  const BackupResult({
    required this.success,
    this.message,
    this.filePath,
    this.missionCount,
    this.errorDetail,
  });
}

class ImportResult {
  final bool success;
  final String? message;
  final int importedMissions;
  final int skippedMissions;
  final List<String> warnings;
  final String? errorDetail;
  const ImportResult({
    required this.success,
    this.message,
    this.importedMissions = 0,
    this.skippedMissions = 0,
    this.warnings = const [],
    this.errorDetail,
  });
}

// ─────────────────────────────────────────────────────────────
// RÉSULTAT DE SUPPRESSION
// ─────────────────────────────────────────────────────────────
class DeleteResult {
  final bool success;
  final String? message;
  final int deletedPhotos;
  const DeleteResult({
    required this.success,
    this.message,
    this.deletedPhotos = 0,
  });
}

// ─────────────────────────────────────────────────────────────
// RÉSULTAT D'INSPECTION DE SAUVEGARDE
// ─────────────────────────────────────────────────────────────
class InspectionSauvegarde {
  final bool isValid;
  final String? magic;
  final int schemaVersion;
  final String? exportType;
  final int missionCount;
  final String? exportedAt;
  final bool checksumValid;
  final String? message;

  const InspectionSauvegarde({
    required this.isValid,
    this.magic,
    this.schemaVersion = 1,
    this.exportType,
    this.missionCount = 0,
    this.exportedAt,
    this.checksumValid = true,
    this.message,
  });
}

// ─────────────────────────────────────────────────────────────
// SERVICE PRINCIPAL
// ─────────────────────────────────────────────────────────────
class BackupService {
  static const int _schemaVersion = 4;
  static const String _magicV4 = 'INSPEC_BACKUP_V4';
  static const String _magic   = 'INSPEC_BACKUP_V3';
  static const String _magicV2 = 'INSPEC_BACKUP_V2';
  static const String _magicV1 = 'INSPEC_BACKUP_V1'; // rétrocompat import

  /// Génère un nom de fichier de sauvegarde au format standardisé :
  /// backup_nomduclient_sitedelamission_matriculedelinspecteur_timestamp.inspec
  static String buildBackupFileName({
    required String clientName,
    required String siteName,
    required String matricule,
    required String timestamp,
  }) {
    String sanitize(String? val, String fallback) {
      if (val == null || val.trim().isEmpty) return fallback;
      final s = val.trim().replaceAll(RegExp(r'[/\\?%*:|"<> ]'), '_');
      return s.isEmpty ? fallback : s;
    }

    final safeClient = sanitize(clientName, 'client');
    final safeSite = sanitize(siteName, 'site');
    final safeMatricule = sanitize(matricule, 'kes');

    return 'backup_${safeClient}_${safeSite}_${safeMatricule}_$timestamp.inspec';
  }

  static Future<BackupResult> exporterMissions(
    String matricule, {
    void Function(OperationProgressState)? onProgressState,
    bool Function()? isCancelled,
  }) async {
    try {
      final missions = HiveService.getMissionsByMatricule(matricule);
      if (missions.isEmpty) {
        return const BackupResult(
          success: false,
          message: 'Aucune mission à exporter.',
        );
      }

      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final clientName =
          missions.length == 1 ? missions.first.nomClient : 'tous_clients';
      final siteName = missions.length == 1
          ? (missions.first.nomSite ?? 'tous_sites')
          : 'tous_sites';
      final fileName = buildBackupFileName(
        clientName: clientName,
        siteName: siteName,
        matricule: matricule,
        timestamp: ts,
      );

      final serializedMissions = <Map<String, dynamic>>[];
      for (int i = 0; i < missions.length; i++) {
        if (isCancelled?.call() == true) {
          return const BackupResult(
            success: false,
            message: 'Exportation annulée par l\'utilisateur.',
          );
        }
        final m = missions[i];
        onProgressState?.call(OperationProgressState(
          type: OperationType.export,
          status: OperationStatus.inProgress,
          title: 'Exportation de ${missions.length} mission(s)',
          currentMissionName: m.nomClient,
          currentMissionIndex: i + 1,
          totalMissions: missions.length,
          currentStep: 'Préparation de la structure de données...',
          overallProgress: (i / missions.length) * 0.4,
        ));
        serializedMissions.add(await _serializeMissionStructureOnly(m));
      }

      return await _exportV4Core(
        fileName: fileName,
        serializedMissions: serializedMissions,
        missionIds: missions.map((m) => m.id).toList(),
        exportType: 'all_missions',
        matricule: matricule,
        subject: 'Sauvegarde Inspec V4 — $ts',
        text: '${missions.length} mission(s) — $ts',
        onProgressState: onProgressState,
        isCancelled: isCancelled,
      );
    } catch (e, st) {
      if (kDebugMode) print('❌ Export V4: $e\n$st');
      return BackupResult(
        success: false,
        message: "Erreur lors de l'export.",
        errorDetail: e.toString(),
      );
    }
  }

  // ── EXPORT DE MISSIONS SÉLECTIONNÉES ──

  static Future<BackupResult> exporterMissionsSelection(
    List<String> missionIds, {
    required String matricule,
    void Function(OperationProgressState)? onProgressState,
    bool Function()? isCancelled,
    bool openShareSheet = true,
    bool isCloudBackup = false,
  }) async {
    try {
      if (missionIds.isEmpty) {
        return const BackupResult(
          success: false,
          message: 'Aucune mission sélectionnée à exporter.',
        );
      }

      final missions = HiveService.getMissionsByMatricule(matricule)
          .where((m) => missionIds.contains(m.id))
          .toList();

      if (missions.isEmpty) {
        return const BackupResult(
          success: false,
          message: 'Aucune mission correspondante trouvée.',
        );
      }

      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final clientName = missions.length == 1
          ? missions.first.nomClient
          : 'selection_clients';
      final siteName = missions.length == 1
          ? (missions.first.nomSite ?? 'selection_sites')
          : 'selection_sites';
      final fileName = buildBackupFileName(
        clientName: clientName,
        siteName: siteName,
        matricule: matricule,
        timestamp: ts,
      );

      final serializedMissions = <Map<String, dynamic>>[];
      for (int i = 0; i < missions.length; i++) {
        if (isCancelled?.call() == true) {
          return const BackupResult(
            success: false,
            message: 'Exportation annulée par l\'utilisateur.',
          );
        }
        final m = missions[i];
        await HiveService.ensureCurrentUserInJSA(m.id);
        onProgressState?.call(OperationProgressState(
          type: OperationType.export,
          status: OperationStatus.inProgress,
          title: 'Exportation de ${missions.length} mission(s)',
          currentMissionName: m.nomClient,
          currentMissionIndex: i + 1,
          totalMissions: missions.length,
          currentStep: 'Préparation des données...',
          overallProgress: (i / missions.length) * 0.4,
        ));
        serializedMissions.add(await _serializeMissionStructureOnly(m));
      }

      return await _exportV4Core(
        fileName: fileName,
        serializedMissions: serializedMissions,
        missionIds: missions.map((m) => m.id).toList(),
        exportType: missions.length == 1 ? 'single_mission' : 'selection_missions',
        matricule: matricule,
        subject: 'Sauvegarde Inspec V4 — ${missions.length} mission(s)',
        text: 'Exportation ${missions.length} mission(s) ($ts)',
        openShareSheet: openShareSheet,
        isCloudBackup: isCloudBackup,
        onProgressState: onProgressState,
        isCancelled: isCancelled,
      );
    } catch (e, st) {
      if (kDebugMode) print('❌ Export selection V4: $e\n$st');
      return BackupResult(
        success: false,
        message: "Erreur lors de l'export de la sélection.",
        errorDetail: e.toString(),
      );
    }
  }

  // ── EXPORT CIBLÉ D'UNE SEULE MISSION (FORMAT V4 ZIP BUNDLE) ──

  static Future<BackupResult> exporterMission(
    String missionId, {
    bool openShareSheet = true,
    bool isCloudBackup = false,
    void Function(OperationProgressState)? onProgressState,
    bool Function()? isCancelled,
  }) async {
    try {
      final mission = HiveService.getMissionById(missionId);
      if (mission == null) {
        return const BackupResult(
          success: false,
          message: 'Mission introuvable.',
        );
      }

      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final effectiveMatricule = (mission.verificateurs != null &&
              mission.verificateurs!.isNotEmpty)
          ? (mission.verificateurs!.first['matricule'] as String? ?? 'kes')
          : 'kes';
      final fileName = buildBackupFileName(
        clientName: mission.nomClient,
        siteName: mission.nomSite ?? 'site',
        matricule: effectiveMatricule,
        timestamp: ts,
      );

      onProgressState?.call(OperationProgressState(
        type: OperationType.export,
        status: OperationStatus.inProgress,
        title: 'Exportation de 1 mission',
        currentMissionName: mission.nomClient,
        currentMissionIndex: 1,
        totalMissions: 1,
        currentStep: 'Préparation des données...',
        overallProgress: 0.2,
      ));

      final serializedMission = await _serializeMissionStructureOnly(mission);

      return await _exportV4Core(
        fileName: fileName,
        serializedMissions: [serializedMission],
        missionIds: [mission.id],
        exportType: 'single_mission',
        subject: 'Sauvegarde V4 — ${mission.nomClient}',
        text: 'Export mission ${mission.nomClient} ($ts)',
        openShareSheet: openShareSheet,
        isCloudBackup: isCloudBackup,
        onProgressState: onProgressState,
        isCancelled: isCancelled,
      );
    } catch (e, st) {
      if (kDebugMode) print('❌ exporterMission V4: $e\n$st');
      return BackupResult(
        success: false,
        message: "Erreur lors de l'export de la mission.",
        errorDetail: e.toString(),
      );
    }
  }

  // ── PIPELINE CORE D'ÉCRITURE STREAMING V4 (FORMAT ZIP BUNDLE) ──

  static Future<BackupResult> _exportV4Core({
    required String fileName,
    required List<Map<String, dynamic>> serializedMissions,
    required List<String> missionIds,
    required String exportType,
    String? matricule,
    String? subject,
    String? text,
    bool openShareSheet = true,
    bool isCloudBackup = false,
    void Function(OperationProgressState)? onProgressState,
    bool Function()? isCancelled,
  }) async {
    try {
      if (serializedMissions.isEmpty) {
        return const BackupResult(
          success: false,
          message: 'Aucune donnée à exporter.',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final zipFilePath = '${tempDir.path}/$fileName';
      final zipFile = File(zipFilePath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      final encoder = ZipFileEncoder();
      encoder.create(zipFile.path);

      final photoPaths = <String>{};
      int totalItemsProcessed = 0;

      // 1. Ajouter les missions en micro JSON files et collecter les photos
      for (int i = 0; i < serializedMissions.length; i++) {
        if (isCancelled?.call() == true) {
          try {
            await encoder.close();
            if (await zipFile.exists()) await zipFile.delete();
          } catch (_) {}
          return const BackupResult(
            success: false,
            message: 'Exportation annulée par l\'utilisateur.',
          );
        }

        final mData = serializedMissions[i];
        final mId = _safeString(((mData['mission'] as Map?))?['id'], 'm_$i');
        final mClient = _safeString(((mData['mission'] as Map?))?['nomClient'], 'Mission ${i + 1}');

        _collectPhotoPathsRecursively(mData, photoPaths);

        final mJson = jsonEncode(mData);
        final tempFile = File('${tempDir.path}/mission_$mId.json');
        await tempFile.writeAsString(mJson);
        await encoder.addFile(tempFile, 'missions/mission_$mId.json');
        if (await tempFile.exists()) await tempFile.delete();

        totalItemsProcessed += 1;

        final prg = 0.4 + ((i + 1) / serializedMissions.length) * 0.3;
        onProgressState?.call(OperationProgressState(
          type: OperationType.export,
          status: OperationStatus.inProgress,
          title: 'Exportation de ${serializedMissions.length} mission(s)',
          currentMissionName: mClient,
          currentMissionIndex: i + 1,
          totalMissions: serializedMissions.length,
          currentStep: 'Création du bundle de la mission...',
          overallProgress: prg,
          processedItemsCount: totalItemsProcessed,
          processedPhotosCount: photoPaths.length,
        ));
      }

      // 2. Écrire les brouillons
      final localDrafts = _serializeLocalDrafts(missionIds);
      if (localDrafts.isNotEmpty) {
        final draftsFile = File('${tempDir.path}/local_drafts.json');
        await draftsFile.writeAsString(jsonEncode(localDrafts));
        await encoder.addFile(draftsFile, 'drafts/local_drafts.json');
        if (await draftsFile.exists()) await draftsFile.delete();
      }

      final coffretDrafts = _serializeCoffretDrafts(missionIds);
      if (coffretDrafts.isNotEmpty) {
        final coffretFile = File('${tempDir.path}/coffret_drafts.json');
        await coffretFile.writeAsString(jsonEncode(coffretDrafts));
        await encoder.addFile(coffretFile, 'drafts/coffret_drafts.json');
        if (await coffretFile.exists()) await coffretFile.delete();
      }

      // 3. Ajouter les photos sous forme de fichiers bruts (0% Base64 overhead)
      final photoList = photoPaths.toList();
      for (int pIdx = 0; pIdx < photoList.length; pIdx++) {
        if (isCancelled?.call() == true) {
          try {
            await encoder.close();
            if (await zipFile.exists()) await zipFile.delete();
          } catch (_) {}
          return const BackupResult(
            success: false,
            message: 'Exportation annulée par l\'utilisateur.',
          );
        }

        final p = photoList[pIdx];
        final photoFile = File(p);
        if (photoFile.existsSync()) {
          final normalizedPath = p.replaceAll('\\', '/');
          final parts = normalizedPath.split('/');
          final idx = parts.indexOf('audit_photos');
          final idxLogo = parts.indexOf('client_logos');
          final idxQr = parts.indexOf('client_qrcodes');
          String relativePath;
          if (idx != -1 && idx < parts.length) {
            relativePath = parts.sublist(idx).join('/');
          } else if (idxLogo != -1 && idxLogo < parts.length) {
            relativePath = parts.sublist(idxLogo).join('/');
          } else if (idxQr != -1 && idxQr < parts.length) {
            relativePath = parts.sublist(idxQr).join('/');
          } else {
            relativePath = 'audit_photos/misc/${photoFile.path.split('/').last}';
          }
          await encoder.addFile(photoFile, 'photos/$relativePath');
        }

        if (photoList.isNotEmpty && pIdx % 3 == 0) {
          final prg = 0.7 + ((pIdx + 1) / photoList.length) * 0.2;
          onProgressState?.call(OperationProgressState(
            type: OperationType.export,
            status: OperationStatus.inProgress,
            title: 'Exportation de ${serializedMissions.length} mission(s)',
            currentMissionName: serializedMissions.first['mission']?['nomClient'],
            currentMissionIndex: serializedMissions.length,
            totalMissions: serializedMissions.length,
            currentStep: 'Compression des médias (${pIdx + 1}/${photoList.length})...',
            overallProgress: prg,
            processedItemsCount: totalItemsProcessed,
            processedPhotosCount: pIdx + 1,
          ));
        }
      }

      // 4. Ajouter manifest.json
      final manifest = {
        'magic': _magicV4,
        'schema_version': _schemaVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'app_version': '2.0.0',
        'export_type': exportType,
        'matricule': matricule,
        'mission_count': serializedMissions.length,
      };

      final manifestFile = File('${tempDir.path}/manifest.json');
      await manifestFile.writeAsString(jsonEncode(manifest));
      await encoder.addFile(manifestFile, 'manifest.json');
      if (await manifestFile.exists()) await manifestFile.delete();

      await encoder.close();

      onProgressState?.call(OperationProgressState(
        type: OperationType.export,
        status: OperationStatus.inProgress,
        title: 'Exportation de ${serializedMissions.length} mission(s)',
        currentMissionName: serializedMissions.first['mission']?['nomClient'],
        currentMissionIndex: serializedMissions.length,
        totalMissions: serializedMissions.length,
        currentStep: 'Finalisation et enregistrement...',
        overallProgress: 0.95,
        processedItemsCount: totalItemsProcessed,
        processedPhotosCount: photoPaths.length,
      ));

      // 5. Copie vers le dossier Downloads/Verif Elec (Export Classique) ou Dossier Sauvegarde (Sauvegarde Cloud)
      Directory? baseDir;
      if (Platform.isAndroid) {
        try {
          final pathStr = await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOWNLOAD);
          baseDir = Directory(pathStr);
        } catch (_) {
          baseDir = await getExternalStorageDirectory();
        }
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      baseDir ??= await getApplicationDocumentsDirectory();

      // Séparation nette des workflows :
      // - Export classique (Importer / Exporter -> Exporter) : Downloads/Verif Elec
      // - Sauvegarde cloud / auto : dossier dédié au système de sauvegarde
      final String targetFolderPath = isCloudBackup
          ? baseDir.path
          : '${baseDir.path}/Verif Elec';

      final targetFolder = Directory(targetFolderPath);
      if (!await targetFolder.exists()) {
        await targetFolder.create(recursive: true);
      }

      final safeFileBasename = fileName.replaceAll('\\', '/').split('/').last;
      final publicFile = File('${targetFolder.path}/$safeFileBasename');
      await zipFile.copy(publicFile.path);

      final locationName = isCloudBackup ? 'Sauvegardes' : 'Downloads/Verif Elec';
      onProgressState?.call(OperationProgressState(
        type: OperationType.export,
        status: OperationStatus.completed,
        title: 'Exportation terminée',
        currentMissionName: null,
        currentMissionIndex: serializedMissions.length,
        totalMissions: serializedMissions.length,
        currentStep: 'Exportation réussie.',
        overallProgress: 1.0,
        processedItemsCount: totalItemsProcessed,
        processedPhotosCount: photoPaths.length,
        message: '${serializedMissions.length} mission(s) exportée(s) avec succès dans $locationName.',
      ));

      if (openShareSheet) {
        try {
          await Share.shareXFiles(
            [XFile(publicFile.path)],
            subject: subject ?? 'Sauvegarde Inspec V4',
            text: text ?? 'Sauvegarde Inspec V4 (${serializedMissions.length} mission(s))',
          );
        } catch (e) {
          if (kDebugMode) print('⚠️ Partage annulé ou non disponible: $e');
        }
      }

      return BackupResult(
        success: true,
        message: 'Sauvegarde V4 générée avec succès.',
        filePath: publicFile.path,
        missionCount: serializedMissions.length,
      );
    } catch (e, st) {
      if (kDebugMode) print('❌ Erreur _exportV4Core: $e\n$st');
      return BackupResult(
        success: false,
        message: 'Erreur lors de l\'exportation V4.',
        errorDetail: e.toString(),
      );
    }
  }



  /// Liste des fichiers de sauvegarde (.json, .bin, .inspec, .zip) stockés localement dans Downloads/Verif Elec/
  static Future<List<File>> getLocalBackupFiles() async {
    try {
      final downloadsPath = Platform.isAndroid
          ? await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOWNLOAD)
          : (await getApplicationDocumentsDirectory()).path;
      final verifElecDir = Directory('$downloadsPath/Verif Elec');
      if (!await verifElecDir.exists()) return [];

      final files = verifElecDir
          .listSync()
          .whereType<File>()
          .where((f) {
            final p = f.path.toLowerCase();
            final isSupportedExt = p.endsWith('.json') ||
                p.endsWith('.bin') ||
                p.endsWith('.inspec') ||
                p.endsWith('.zip');
            return isSupportedExt && p.contains('inspec');
          })
          .toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur getLocalBackupFiles: $e');
      return [];
    }
  }

  // ── Mission + structure de ses données liées (sans charger les photos en Base64) ──
  static Future<Map<String, dynamic>> _serializeMissionStructureOnly(Mission m) async {
    final id = m.id;
    final audit = HiveService.getAuditInstallationsByMissionId(id);
    final desc = HiveService.getDescriptionInstallationsByMissionId(id);
    final mesures = HiveService.getMesuresEssaisByMissionId(id);
    final jsa = HiveService.getJSAByMissionId(id);
    final rens = HiveService.getRenseignementsGenerauxByMissionId(id);
    final foudres = HiveService.getFoudreObservationsByMissionId(id);
    final classements = _classementsByMission(id);
    final classementZones = _classementZonesByMission(id);
    final sequenceProgress = await SequenceProgressService.getProgress(id);
    final trashItems = TrashService.getAllTrashItems()
        .where((t) => t.missionId == id)
        .map((t) => t.toJson())
        .toList();

    final lightingBox = Hive.box<LightingInspection>('lighting_inspections');
    final lightings = lightingBox.values
        .where((l) => l.missionId == id)
        .map((l) => l.toJson())
        .toList();

    // Collecter exhaustivement toutes les photos physiques de la mission
    final allCollectedPhotos = <String>{};
    if (m.logoClient != null && m.logoClient!.trim().isNotEmpty) {
      allCollectedPhotos.add(m.logoClient!.trim());
    }
    if (m.qrCodeClient != null && m.qrCodeClient!.trim().isNotEmpty) {
      allCollectedPhotos.add(m.qrCodeClient!.trim());
    }
    if (m.qrCodeQ18 != null && m.qrCodeQ18!.trim().isNotEmpty) {
      allCollectedPhotos.add(m.qrCodeQ18!.trim());
    }
    if (audit != null) {
      allCollectedPhotos.addAll(_collectAllPhotoPaths(audit));
    }
    if (desc != null) {
      for (final item in [
        ...desc.alimentationMoyenneTension,
        ...desc.alimentationBasseTension,
        ...desc.groupeElectrogene,
        ...desc.alimentationCarburant,
        ...desc.inverseur,
        ...desc.stabilisateur,
        ...desc.onduleurs,
        ...desc.cpi,
      ]) {
        allCollectedPhotos.addAll(item.photoPaths.where((p) => p.isNotEmpty));
      }
      for (final obs in desc.foudreObservations) {
        allCollectedPhotos.addAll(obs.photos.where((p) => p.isNotEmpty));
      }
    }
    if (mesures != null) {
      for (final pt in mesures.prisesTerre) {
        if (pt.photo != null && pt.photo!.isNotEmpty) {
          allCollectedPhotos.add(pt.photo!);
        }
      }
    }
    for (final l in lightingBox.values.where((l) => l.missionId == id)) {
      for (final ncl in l.nonConformingLuminaires) {
        for (final ans in ncl.answers) {
          allCollectedPhotos.addAll(ans.photoPaths.where((p) => p.isNotEmpty));
        }
      }
    }

    final photoPaths = allCollectedPhotos.toList();

    return {
      'mission': m.toJson(),
      'photo_paths': photoPaths, // Utilisé pour l'Isolate de streaming V4 et l'export photos legacy
      'audit': audit != null ? _serializeAudit(audit) : null,

      'description_installations':
          desc != null ? _serializeDescription(desc) : null,
      'mesures_essais': mesures != null ? _serializeMesures(mesures) : null,
      'jsa': jsa != null ? _serializeJSA(jsa) : null,
      'renseignements_generaux':
          rens != null ? _serializeRenseignements(rens) : null,
      'foudre_observations': foudres.map(_f).toList(),
      'classements_locaux': classements,
      'classements_zones': classementZones,
      'lighting_inspections': lightings,
      'sequence_progress': sequenceProgress,
      'trash_items': trashItems,
    };
  }

  // ── Audit installations ──
  static Map<String, dynamic> _serializeAudit(
      AuditInstallationsElectriques a) {
    return {
      'missionId': a.missionId,
      'updatedAt': a.updatedAt.toIso8601String(),
      'photos': a.photos,
      'moyenneTensionLocaux':
          a.moyenneTensionLocaux.map(_serializeMTLocal).toList(),
      'moyenneTensionZones':
          a.moyenneTensionZones.map(_serializeMTZone).toList(),
      'basseTensionZones':
          a.basseTensionZones.map(_serializeBTZone).toList(),
    };
  }

  static Map<String, dynamic> _serializeMTLocal(MoyenneTensionLocal l) => {
        'id': l.id,
        'nom': l.nom,
        'type': l.type,
        'accessible': l.accessible,
        'aReverifier': l.aReverifier,
        'isRiskZone': l.isRiskZone,
        'createdAt': l.createdAt?.toIso8601String(),
        'updatedAt': l.updatedAt?.toIso8601String(),
        'photos': l.photos,
        'dispositionsConstructives':
            l.dispositionsConstructives.map(_serializeElement).toList(),
        'conditionsExploitation':
            l.conditionsExploitation.map(_serializeElement).toList(),
        // Ancien champ unique (rétrocompat)
        'cellule': l.cellule != null ? _serializeCellule(l.cellule!) : null,
        'transformateur': l.transformateur != null
            ? _serializeTransformateur(l.transformateur!)
            : null,
        // Nouvelles listes
        'cellules': l.cellules.map(_serializeCellule).toList(),
        'transformateurs':
            l.transformateurs.map(_serializeTransformateur).toList(),
        'coffrets': l.coffrets.map(_serializeCoffret).toList(),
        'observationsLibres':
            l.observationsLibres.map(_serializeObs).toList(),
      };

  static Map<String, dynamic> _serializeMTZone(MoyenneTensionZone z) => {
        'id': z.id,
        'nom': z.nom,
        'description': z.description,
        'isRiskZone': z.isRiskZone,
        'createdAt': z.createdAt?.toIso8601String(),
        'updatedAt': z.updatedAt?.toIso8601String(),
        'photos': z.photos,
        'classementZoneId': z.classementZoneId,
        'coffrets': z.coffrets.map(_serializeCoffret).toList(),
        'observationsLibres': z.observationsLibres.map(_serializeObs).toList(),
        'locaux': z.locaux.map(_serializeMTLocal).toList(),
      };

  static Map<String, dynamic> _serializeBTZone(BasseTensionZone z) => {
        'id': z.id,
        'nom': z.nom,
        'description': z.description,
        'isRiskZone': z.isRiskZone,
        'createdAt': z.createdAt?.toIso8601String(),
        'updatedAt': z.updatedAt?.toIso8601String(),
        'photos': z.photos,
        'classementZoneId': z.classementZoneId,
        'coffretsDirects': z.coffretsDirects.map(_serializeCoffret).toList(),
        'observationsLibres': z.observationsLibres.map(_serializeObs).toList(),
        'locaux': z.locaux.map(_serializeBTLocal).toList(),
      };

  static Map<String, dynamic> _serializeBTLocal(BasseTensionLocal l) => {
        'id': l.id,
        'nom': l.nom,
        'type': l.type,
        'accessible': l.accessible,
        'aReverifier': l.aReverifier,
        'isRiskZone': l.isRiskZone,
        'createdAt': l.createdAt?.toIso8601String(),
        'updatedAt': l.updatedAt?.toIso8601String(),
        'photos': l.photos,
        'dispositionsConstructives':
            (l.dispositionsConstructives ?? []).map(_serializeElement).toList(),
        'conditionsExploitation':
            (l.conditionsExploitation ?? []).map(_serializeElement).toList(),
        // Fields 9 et 10 — présents si build_runner a été relancé
        'cellules': l.cellules.map(_serializeCellule).toList(),
        'transformateurs': l.transformateurs.map(_serializeTransformateur).toList(),
        'coffrets': l.coffrets.map(_serializeCoffret).toList(),
        'observationsLibres': l.observationsLibres.map(_serializeObs).toList(),
      };

  static Map<String, dynamic> _serializeElement(ElementControle e) => {
        'elementControle': e.elementControle,
        'conforme': e.conforme,
        'observation': e.observation,
        'priorite': e.priorite,
        'photos': e.photos,
        'referenceNormative': e.referenceNormative,
        'estNA': e.estNA,
        'familleRisque': e.familleRisque,
        'criticite': e.criticite,
      };

  static Map<String, dynamic> _serializeCellule(Cellule c) => {
        'fonction': c.fonction,
        'type': c.type,
        'marqueModeleAnnee': c.marqueModeleAnnee,
        'marque': c.marque,
        'modele': c.modele,
        'annee': c.annee,
        'gamme': c.gamme,
        'tensionAssignee': c.tensionAssignee,
        'pouvoirCoupure': c.pouvoirCoupure,
        'numerotation': c.numerotation,
        'parafoudres': c.parafoudres,
        'photos': c.photos,
        'calibreDisjoncteur': c.calibreDisjoncteur,
        'sectionCables': c.sectionCables,
        'sectionCablePhase': c.sectionCablePhase,
        'sectionCableNeutre': c.sectionCableNeutre,
        'conducteursPhase': c.conducteursPhase,
        'conducteursNeutre': c.conducteursNeutre,
        'natureReseau': c.natureReseau,
        'presenceIacm': c.presenceIacm,
        'nom': c.nom,
        'repere': c.repere,
        'photo': c.photo,
        'elementsVerifies':
            c.elementsVerifies.map(_serializeElement).toList(),
        'observations': c.observations?.map(_serializeElement).toList(),
        'syncId': c.syncId,
        'tensionService': c.tensionService,
        'createdAt': c.createdAt?.toIso8601String(),
        'updatedAt': c.updatedAt?.toIso8601String(),
      };

  static Map<String, dynamic> _serializeTransformateur(
          TransformateurMTBT t) =>
      {
        'typeTransformateur': t.typeTransformateur,
        'marqueAnnee': t.marqueAnnee,
        'marque': t.marque,
        'anneeFabrication': t.anneeFabrication,
        'puissanceAssignee': t.puissanceAssignee,
        'tensionPrimaireSecondaire': t.tensionPrimaireSecondaire,
        'relaisBuchholz': t.relaisBuchholz,
        'typeImmersion': t.typeImmersion,
        'presenceDGPT2': t.presenceDGPT2,
        'typeRefroidissement': t.typeRefroidissement,
        'regimeNeutre': t.regimeNeutre,
        'photos': t.photos,
        'calibreDisjoncteur': t.calibreDisjoncteur,
        'sectionCables': t.sectionCables,
        'sectionCablePhase': t.sectionCablePhase,
        'sectionCableNeutre': t.sectionCableNeutre,
        'conducteursPhase': t.conducteursPhase,
        'conducteursNeutre': t.conducteursNeutre,
        'observations': t.observations?.map(_serializeElement).toList(),
        'syncId': t.syncId,
        'intensiteNominale': t.intensiteNominale,
        'couplage': t.couplage,
        'typeReseau': t.typeReseau,
        'pccAmont': t.pccAmont,
        'puissanceUcc': t.puissanceUcc,
        'ik3Max': t.ik3Max,
        'nom': t.nom,
        'photo': t.photo,
        'repere': t.repere,
        'elementsVerifies':
            t.elementsVerifies.map(_serializeElement).toList(),
      };

  @visibleForTesting
  static Map<String, dynamic> testSerializeCoffret(CoffretArmoire c) => _serializeCoffret(c);

  @visibleForTesting
  static List<CoffretArmoire> testParseCoffrets(dynamic raw) => _parseCoffrets(raw);

  @visibleForTesting
  static dynamic testFixPathsRecursively(dynamic value, String appDirPath) => _fixPathsRecursively(value, appDirPath);

  @visibleForTesting
  static Map<String, dynamic> testSerializeCellule(Cellule c) => _serializeCellule(c);

  @visibleForTesting
  static Cellule testParseCellule(Map<String, dynamic> d) => _parseCellule(d);

  @visibleForTesting
  static Map<String, dynamic> testSerializeTransformateur(TransformateurMTBT t) => _serializeTransformateur(t);

  @visibleForTesting
  static TransformateurMTBT testParseTransformateur(Map<String, dynamic> d) => _parseTransformateur(d);

  @visibleForTesting
  static Map<String, dynamic> testSerializePoint(PointVerification p) => _serializePoint(p);

  @visibleForTesting
  static PointVerification testParsePoint(Map<String, dynamic> d) => _parsePoint(d);

  @visibleForTesting
  static Map<String, dynamic> testSerializeObs(ObservationLibre o) => _serializeObs(o);

  @visibleForTesting
  static List<ObservationLibre> testParseObs(dynamic raw) => _parseObs(raw);

  @visibleForTesting
  static Map<String, dynamic> testSerializeRenseignements(RenseignementsGeneraux r) => _serializeRenseignements(r);

  @visibleForTesting
  static Map<String, dynamic> testRemapMissionId(
          Map<String, dynamic> data, String oldId, String newId, String newClientName) =>
      _remapMissionId(data, oldId, newId, newClientName);

  static Map<String, dynamic> _serializeCoffret(CoffretArmoire c) => {
        'id': c.id,
        'createdAt': c.createdAt?.toIso8601String(),
        'updatedAt': c.updatedAt?.toIso8601String(),
        'qrCode': c.qrCode,
        'nom': c.nom,
        'type': c.type,
        'description': c.description,
        'repere': c.repere,
        'numeroEquipement': c.numeroEquipement,
        'statut': c.statut,
        'currentStep': c.currentStep,
        'zoneAtex': c.zoneAtex,
        'accessible': c.accessible,
        'domaineTension': c.domaineTension,
        'identificationArmoire': c.identificationArmoire,
        'signalisationDanger': c.signalisationDanger,
        'presenceSchema': c.presenceSchema,
        'presenceParafoudre': c.presenceParafoudre,
        'verificationThermographie': c.verificationThermographie,
        'presenceDefautThermo': c.presenceDefautThermo,
        'alimenteeParTransformateur': c.alimenteeParTransformateur,
        'transformateurId': c.transformateurId,
        'transformateurNomComplet': c.transformateurNomComplet,
        'presenceCPI': c.presenceCPI,
        'departPrisAvecProtection': c.departPrisAvecProtection,
        'photos': c.photos,
        'photosExternes': c.photosExternes,
        'photosInternes': c.photosInternes,
        'alimentations': c.alimentations.map(_serializeAlim).toList(),
        'protectionTete': c.protectionTete != null
            ? _serializeAlim(c.protectionTete!)
            : null,
        'pointsVerification':
            c.pointsVerification.map(_serializePoint).toList(),
        'observationsLibres': c.observationsLibres.map(_serializeObs).toList(),
        'observationsParafoudre':
            c.observationsParafoudre.map(_serializeObs).toList(),
        'observationsParafoudreEnrichies': c.observationsParafoudreEnrichies
            ?.map(_serializeElement)
            .toList(),
        'departures': c.effectiveDepartures.map(_serializeDepart).toList(),
        'terminalCircuits': c.effectiveTerminalCircuits.map(_serializeCircuit).toList(),
        'sourceEquipementId': c.sourceEquipementId,
        'sourceNomComplet': c.sourceNomComplet,
        'sourceDepartId': c.sourceDepartId,
        'indiceIpIk': c.indiceIpIk,
        'indiceIpIkRepere': c.indiceIpIkRepere,
      };

  static Map<String, dynamic> _serializeDepart(DepartEquipement d) => {
        'id': d.id,
        'protectionTete': d.protectionTete,
        'identification': d.identification,
        'typeProtection': d.typeProtection,
        'courbe': d.courbe,
        'ddr': d.ddr,
        'pdcKA': d.pdcKA,
        'icc3Max': d.icc3Max,
        'calibre': d.calibre,
        'sectionCable': d.sectionCable,
        'marque': d.marque,
        'nombreCables': d.nombreCables,
        'sectionCableNeutre': d.sectionCableNeutre,
        'conducteursPhase': d.conducteursPhase,
        'conducteursNeutre': d.conducteursNeutre,
        'natureCable': d.natureCable,
      };

  static Map<String, dynamic> _serializeCircuit(CircuitTerminalEquipement c) => {
        'id': c.id,
        'protectionTete': c.protectionTete,
        'identification': c.identification,
        'typeProtection': c.typeProtection,
        'courbe': c.courbe,
        'ddr': c.ddr,
        'pdcKA': c.pdcKA,
        'icc3Max': c.icc3Max,
        'calibre': c.calibre,
        'sectionCable': c.sectionCable,
        'marque': c.marque,
        'nombreCables': c.nombreCables,
        'sectionCableNeutre': c.sectionCableNeutre,
        'conducteursPhase': c.conducteursPhase,
        'conducteursNeutre': c.conducteursNeutre,
        'natureCable': c.natureCable,
      };

  static Map<String, dynamic> _serializeAlim(Alimentation a) => {
        'id': a.id,
        'typeProtection': a.typeProtection,
        'courbe': a.courbe,
        'ddr': a.ddr,
        'pdcKA': a.pdcKA,
        'calibre': a.calibre,
        'sectionCable': a.sectionCable,
        'source': a.source,
        'sourceKnown': a.sourceKnown,
        'marqueDisjoncteur': a.marqueDisjoncteur,
        'icc3Max': a.icc3Max,
        'photos': a.photos,
        'nombreCables': a.nombreCables,
        'sectionCableNeutre': a.sectionCableNeutre,
        'conducteursPhase': a.conducteursPhase,
        'conducteursNeutre': a.conducteursNeutre,
        'natureCable': a.natureCable,
      };

  static Map<String, dynamic> _serializePoint(PointVerification p) => {
        'pointVerification': p.pointVerification,
        'conformite': p.conformite,
        'observation': p.observation,
        'referenceNormative': p.referenceNormative,
        'priorite': p.priorite,
        'photos': p.photos,
        'observations': p.observations?.map(_serializeElement).toList(),
        'criticite': p.criticite,
        'familleRisque': p.familleRisque,
      };

  static Map<String, dynamic> _serializeObs(ObservationLibre o) => {
        'texte': o.texte,
        'photos': o.photos,
        'dateCreation': o.dateCreation.toIso8601String(),
        'dateModification': o.dateModification.toIso8601String(),
        'pointVerificationKey': o.pointVerificationKey,
        'referenceNormative': o.referenceNormative,
        'familleRisque': o.familleRisque,
        'criticite': o.criticite,
        'isAutoLinked': o.isAutoLinked,
      };

  // ── Description des installations ──
  static Map<String, dynamic> _serializeDescription(
      DescriptionInstallations d) =>
      {
        'missionId': d.missionId,
        'alimentationMoyenneTension': d.alimentationMoyenneTension
            .map(_serializeInstallationItem)
            .toList(),
        'alimentationBasseTension': d.alimentationBasseTension
            .map(_serializeInstallationItem)
            .toList(),
        'groupeElectrogene':
            d.groupeElectrogene.map(_serializeInstallationItem).toList(),
        'alimentationCarburant':
            d.alimentationCarburant.map(_serializeInstallationItem).toList(),
        'inverseur': d.inverseur.map(_serializeInstallationItem).toList(),
        'stabilisateur':
            d.stabilisateur.map(_serializeInstallationItem).toList(),
        'onduleurs': d.onduleurs.map(_serializeInstallationItem).toList(),
        'cpi': d.cpi.map(_serializeInstallationItem).toList(),
        'regimeNeutre': d.regimeNeutre,
        'regimeNeutreDetail': d.regimeNeutreDetail,
        'eclairageSecurite': d.eclairageSecurite,
        'modificationsInstallations': d.modificationsInstallations,
        'noteCalcul': d.noteCalcul,
        'registreSecurite': d.registreSecurite,
        'presenceParatonnerre': d.presenceParatonnerre,
        'analyseRisqueFoudre': d.analyseRisqueFoudre,
        'etudeTechniqueFoudre': d.etudeTechniqueFoudre,
        'natureReseauAlimentationSite': d.natureReseauAlimentationSite,
        'tensionAlimentationSite': d.tensionAlimentationSite,
        'nombreAlimentationSite': d.nombreAlimentationSite,
        'presenceIacmAlimentationSite': d.presenceIacmAlimentationSite,
        'foudreObservations': d.foudreObservations.map(_serializeObs).toList(),
        'updatedAt': d.updatedAt.toIso8601String(),
      };

  static Map<String, dynamic> _serializeInstallationItem(
          InstallationItem i) =>
      {'data': i.data, 'photoPaths': i.photoPaths};

  // ── Mesures et essais — sérialisation champ par champ ──
  static Map<String, dynamic> _serializeMesures(MesuresEssais m) => {
        'missionId': m.missionId,
        'updatedAt': m.updatedAt.toIso8601String(),
        'conditionMesure': {'observation': m.conditionMesure.observation},
        'essaiDemarrageAuto': {
          'observation': m.essaiDemarrageAuto.observation
        },
        'testArretUrgence': {
          'observation': m.testArretUrgence.observation,
          'presence': m.testArretUrgence.presence,
        },
        'avisMesuresTerre': {
          'satisfaisants': m.avisMesuresTerre.satisfaisants,
          'nonSatisfaisants': m.avisMesuresTerre.nonSatisfaisants,
          'observation': m.avisMesuresTerre.observation,
        },
        'prisesTerre': m.prisesTerre
            .map((p) => {
                  'localisation': p.localisation,
                  'identification': p.identification,
                  'conditionPriseTerre': p.conditionPriseTerre,
                  'naturePriseTerre': p.naturePriseTerre,
                  'methodeMesure': p.methodeMesure,
                  'valeurMesure': p.valeurMesure,
                  'observation': p.observation,
                  'interconnecteAutrePrise': p.interconnecteAutrePrise,
                  'photo': p.photo,
                })
            .toList(),
        'essaisDeclenchement': m.essaisDeclenchement
            .map((e) => {
                  'localisation': e.localisation,
                  'coffret': e.coffret,
                  'designationCircuit': e.designationCircuit,
                  'typeDispositif': e.typeDispositif,
                  'calibre': e.calibre,
                  'reglageIAn': e.reglageIAn,
                  'tempo': e.tempo,
                  'tempoText': e.tempoText,
                  'isolement': e.isolement,
                  'essai': e.essai,
                  'observation': e.observation,
                })
            .toList(),
        'continuiteResistances': m.continuiteResistances
            .map((c) => {
                  'localisation': c.localisation,
                  'designationTableau': c.designationTableau,
                  'origineMesure': c.origineMesure,
                  'observation': c.observation,
                  'essai': c.essai,
                })
            .toList(),
        'essaisIsolement': m.essaisIsolement
            .map((ei) => {
                  'syncId': ei.syncId,
                  'equipmentSyncId': ei.equipmentSyncId,
                  'pointControle': ei.pointControle,
                  'isolement': ei.isolement,
                  'appreciation': ei.appreciation,
                  'localisation': ei.localisation,
                  'designation': ei.designation,
                  'reperePointOrigine': ei.reperePointOrigine,
                  'pointA': ei.pointA,
                  'pointB': ei.pointB,
                  'sectionCable': ei.sectionCable,
                  'nombreCablesTestes': ei.nombreCablesTestes,
                  'sectionCablePointA': ei.sectionCablePointA,
                  'sectionCablePointB': ei.sectionCablePointB,
                  'isSectionPointAManual': ei.isSectionPointAManual,
                  'isSectionPointBManual': ei.isSectionPointBManual,
                  'equipmentPointASyncId': ei.equipmentPointASyncId,
                  'equipmentPointBSyncId': ei.equipmentPointBSyncId,
                  'zonePointA': ei.zonePointA,
                  'reperePointA': ei.reperePointA,
                  'nomEquipementPointA': ei.nomEquipementPointA,
                  'zonePointB': ei.zonePointB,
                  'reperePointB': ei.reperePointB,
                  'nomEquipementPointB': ei.nomEquipementPointB,
                  'natureCable': ei.natureCable,
                })
            .toList(),
        'cpiTests': m.cpiTests.map((ct) => ct.toMap()).toList(),
      };

  // ── JSA ──
  static Map<String, dynamic> _serializeJSA(JSA j) {
    return {
      'missionId': j.missionId,
      'operationEffectuer': j.operationEffectuer,
      'updatedAt': j.updatedAt.toIso8601String(),
      'currentSubCategory': j.currentSubCategory,
      'inspecteurs': j.inspecteurs.map((i) => {
        'nom': i.nom,
        'prenom': i.prenom,
        'signature': i.signature,
        'matricule': i.matricule,
        'email': i.email,
        'role': i.role,
      }).toList(),
      'planUrgence': {
        'voiesIssuesIdentifiees': j.planUrgence.voiesIssuesIdentifiees,
        'zonesRassemblementIdentifiees': j.planUrgence.zonesRassemblementIdentifiees,
        'consignesSecuriteInternes': j.planUrgence.consignesSecuriteInternes,
        'personneContactClient': j.planUrgence.personneContactClient,
        'personneContactKES': j.planUrgence.personneContactKES,
      },
      'dangers': {
        'chocElectrique': j.dangers.chocElectrique,
        'bruit': j.dangers.bruit,
        'stressThermique': j.dangers.stressThermique,
        'eclairageInadapte': j.dangers.eclairageInadapte,
        'zoneCirculationMalDefinie': j.dangers.zoneCirculationMalDefinie,
        'solAccidente': j.dangers.solAccidente,
        'emissionGazPoussiere': j.dangers.emissionGazPoussiere,
        'espaceConfine': j.dangers.espaceConfine,
        'autreEnvironnement': j.dangers.autreEnvironnement,
        'chuteObjets': j.dangers.chuteObjets,
        'coactivite': j.dangers.coactivite,
        'portCharge': j.dangers.portCharge,
        'expositionProduitsChimiques': j.dangers.expositionProduitsChimiques,
        'chuteHauteur': j.dangers.chuteHauteur,
        'electrification': j.dangers.electrification,
        'incendiesExplosion': j.dangers.incendiesExplosion,
        'mauvaisesPostures': j.dangers.mauvaisesPostures,
        'chutePlainPied': j.dangers.chutePlainPied,
        'autrePhysique': j.dangers.autrePhysique,
      },
      'exigencesGenerales': {
        'signaletiqueSecurite': j.exigencesGenerales.signaletiqueSecurite,
        'ficheDonneeSecuriteDisponible': j.exigencesGenerales.ficheDonneeSecuriteDisponible,
        'uneMinuteMaSecurite': j.exigencesGenerales.uneMinuteMaSecurite,
        'balise': j.exigencesGenerales.balise,
        'zoneTravailPropre': j.exigencesGenerales.zoneTravailPropre,
        'toolboxMeeting': j.exigencesGenerales.toolboxMeeting,
        'permisTravail': j.exigencesGenerales.permisTravail,
        'extincteurs': j.exigencesGenerales.extincteurs,
        'outilsMaterielsIsolants': j.exigencesGenerales.outilsMaterielsIsolants,
        'boitePharmacie': j.exigencesGenerales.boitePharmacie,
        'autre': j.exigencesGenerales.autre,
      },
      'epi': {
        'casqueSecurite': j.epi.casqueSecurite,
        'bouchonsOreille': j.epi.bouchonsOreille,
        'lunettesProtection': j.epi.lunettesProtection,
        'harnaisSecurite': j.epi.harnaisSecurite,
        'chaussureSecurite': j.epi.chaussureSecurite,
        'masqueSecurite': j.epi.masqueSecurite,
        'combinaisonLongueManche': j.epi.combinaisonLongueManche,
        'gantsIsolants': j.epi.gantsIsolants,
        'cacheNez': j.epi.cacheNez,
        'gilet': j.epi.gilet,
        'autre': j.epi.autre,
      },
      'verificationFinale': {
        'travailTermineNA': j.verificationFinale.travailTermineNA,
        'travailTermineApplicable': j.verificationFinale.travailTermineApplicable,
        'consignationCadenasRetireNA': j.verificationFinale.consignationCadenasRetireNA,
        'consignationCadenasRetireApplicable': j.verificationFinale.consignationCadenasRetireApplicable,
        'absenceConsignataireProcedureNA': j.verificationFinale.absenceConsignataireProcedureNA,
        'absenceConsignataireProcedureApplicable': j.verificationFinale.absenceConsignataireProcedureApplicable,
        'consignataireAbsentProcedureAppliqueeNA': j.verificationFinale.consignataireAbsentProcedureAppliqueeNA,
        'consignataireAbsentProcedureAppliqueeApplicable': j.verificationFinale.consignataireAbsentProcedureAppliqueeApplicable,
        'materielEnleveZoneNettoyeeNA': j.verificationFinale.materielEnleveZoneNettoyeeNA,
        'materielEnleveZoneNettoyeeApplicable': j.verificationFinale.materielEnleveZoneNettoyeeApplicable,
        'risquesSupprimesEquipementPretNA': j.verificationFinale.risquesSupprimesEquipementPretNA,
        'risquesSupprimesEquipementPretApplicable': j.verificationFinale.risquesSupprimesEquipementPretApplicable,
        'autresPoints': j.verificationFinale.autresPoints,
        'donneurOrdreSignature': j.verificationFinale.donneurOrdreSignature,
        'chargeAffairesSignature': j.verificationFinale.chargeAffairesSignature,
      },
    };
  }

  static Map<String, dynamic> _serializeRenseignements(
      RenseignementsGeneraux r) =>
      {
        'missionId': r.missionId,
        'etablissement': r.etablissement,
        'installation': r.installation,
        'activite': r.activite,
        'dateDebut': r.dateDebut?.toIso8601String(),
        'dateFin': r.dateFin?.toIso8601String(),
        'dureeJours': r.dureeJours,
        'verificationType': r.verificationType,
        'registreControle': r.registreControle,
        'compteRendu': r.compteRendu,
        'accompagnateurs': r.accompagnateurs,
        'verificateurs': r.verificateurs,
        'formationHabilitationElectrique': r.formationHabilitationElectrique,
        'createdAt': r.createdAt?.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
        'nomSite': r.nomSite,
        'activiteSurSite': r.activiteSurSite,
        'classementReglementaire': r.classementReglementaire,
        'classementReglementaireType': r.classementReglementaireType,
        'classementReglementaireCategorie': r.classementReglementaireCategorie,
      };

  static Map<String, dynamic> _f(Foudre f) => f.toJson();

  // ── Classements ──
  static List<Map<String, dynamic>> _classementsByMission(String missionId) {
    final box = Hive.box<ClassementEmplacement>('classement_locaux');
    return box.values
        .where((c) => c.missionId == missionId)
        .map((c) => {
              'missionId': c.missionId,
              'localisation': c.localisation,
              'zone': c.zone,
              'origineClassement': c.origineClassement,
              'af': c.af,
              'be': c.be,
              'ae': c.ae,
              'ad': c.ad,
              'ag': c.ag,
              'ip': c.ip,
              'ik': c.ik,
              'updatedAt': c.updatedAt.toIso8601String(),
              'typeLocal': c.typeLocal,
              'typeEmplacement': c.typeEmplacement,
              'heriteDeZone': c.heriteDeZone,
              'zoneParenteId': c.zoneParenteId,
            })
        .toList();
  }

  static List<Map<String, dynamic>> _classementZonesByMission(
      String missionId) {
    final box = Hive.box<ClassementZone>('classement_zones');
    return box.values
        .where((c) => c.missionId == missionId)
        .map((c) => {
              'missionId': c.missionId,
              'nomZone': c.nomZone,
              'origineClassement': c.origineClassement,
              'typeZone': c.typeZone,
              'af': c.af,
              'be': c.be,
              'ae': c.ae,
              'ad': c.ad,
              'ag': c.ag,
              'ip': c.ip,
              'ik': c.ik,
              'updatedAt': c.updatedAt.toIso8601String(),
            })
        .toList();
  }

  // ── Brouillons locaux ──
  static List<Map<String, dynamic>> _serializeLocalDrafts(
      List<String> missionIds) {
    final box = Hive.box('local_drafts');
    final result = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data is! Map) continue;
        final missionId = data['missionId'];
        if (!missionIds.contains(missionId)) continue;
        final local = data['local'];
        Map<String, dynamic>? serializedLocal;
        String localClass = 'MT';
        if (local is MoyenneTensionLocal) {
          serializedLocal = _serializeMTLocal(local);
          localClass = 'MT';
        } else if (local is BasseTensionLocal) {
          serializedLocal = _serializeBTLocal(local);
          localClass = 'BT';
        }
        if (serializedLocal == null) continue;
        result.add({
          'key': key.toString(),
          'missionId': missionId,
          'isMoyenneTension': data['isMoyenneTension'],
          'zoneIndex': data['zoneIndex'],
          'isInZone': data['isInZone'],
          'localType': data['localType'],
          'nomLocal': data['nomLocal'],
          'currentStep': data['currentStep'],
          'savedAt': data['savedAt'],
          'localId': data['localId'],
          'localClass': localClass,
          'local': serializedLocal,
        });
      } catch (e) {
        if (kDebugMode) print('⚠️ Draft local ignoré: $e');
      }
    }
    return result;
  }

  // ── Brouillons coffrets ──
  static List<Map<String, dynamic>> _serializeCoffretDrafts(
      List<String> missionIds) {
    final box = Hive.box('coffret_drafts');
    final result = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data is! Map) continue;
        final missionId = data['missionId'];
        if (!missionIds.contains(missionId)) continue;
        final coffret = data['coffret'];
        if (coffret is! CoffretArmoire) continue;
        result.add({
          'key': key.toString(),
          'missionId': missionId,
          'parentType': data['parentType'],
          'parentIndex': data['parentIndex'],
          'isMoyenneTension': data['isMoyenneTension'],
          'zoneIndex': data['zoneIndex'],
          'savedAt': data['savedAt'],
          'coffret': _serializeCoffret(coffret),
        });
      } catch (e) {
        if (kDebugMode) print('⚠️ Draft coffret ignoré: $e');
      }
    }
    return result;
  }


  // ── Isolate helper pour calculer le checksum lors de l'export ──
  static Map<String, dynamic> _computeExportChecksum(Map<String, dynamic> payload) {
    final contentForHash = jsonEncode(payload);
    payload['checksum'] = sha256.convert(utf8.encode(contentForHash)).toString();
    return payload;
  }

  // ── HELPER DE VÉRIFICATION DU CHECKSUM EN STREAMING (MÉMOIRE < 64 KO) ──
  static Future<bool> _verifyChecksumStream(String filePath, String expectedChecksum) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final len = await file.length();
      if (len <= 79) return false;

      final bytesToHashLength = len - 79;
      var accumulated = 0;

      final outputSink = AccumulatorSink<Digest>();
      final inputByteSink = sha256.startChunkedConversion(outputSink);

      final stream = file.openRead();
      await for (final chunk in stream) {
        if (accumulated + chunk.length <= bytesToHashLength) {
          inputByteSink.add(chunk);
          accumulated += chunk.length;
        } else {
          final remainingNeeded = bytesToHashLength - accumulated;
          if (remainingNeeded > 0) {
            inputByteSink.add(chunk.sublist(0, remainingNeeded));
            accumulated += remainingNeeded;
          }
          break;
        }
      }
      inputByteSink.close();
      final computed = outputSink.events.single.toString();
      return computed == expectedChecksum;
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur _verifyChecksumStream: $e');
      return false;
    }
  }

  // ── EXTRACTION PROGRESSIVE DES MÉTADONNÉES ET DES PHOTOS (MÉMOIRE < 15 MO) ──
  // ── EXTRACTION PROGRESSIVE SÉCURISÉE DES MÉDIAS ET MÉTADONNÉES (RAM < 2 MO) ──
  static Future<Map<String, dynamic>> _extractMetadataAndPhotosStream(
    String filePath,
    String appDirPath, {
    void Function(String stage, double progress)? onProgress,
  }) async {
    final inputFile = File(filePath);
    final tempDir = await getTemporaryDirectory();
    final tempCleanFile = File('${tempDir.path}/temp_clean_import_${DateTime.now().millisecondsSinceEpoch}.json');

    if (await tempCleanFile.exists()) {
      await tempCleanFile.delete();
    }

    final sink = tempCleanFile.openWrite(mode: FileMode.write, encoding: utf8);

    onProgress?.call('Lecture du fichier de sauvegarde...', 0.05);

    final photoRegex = RegExp(
      r'"([^"]+?\.(?:jpg|jpeg|png|webp|gif))"\s*:\s*"([A-Za-z0-9+/=\s]{100,})"',
      multiLine: true,
    );

    int photoCount = 0;
    String buffer = '';

    final stringStream = inputFile.openRead().transform(const Utf8Decoder(allowMalformed: true));

    await for (final chunk in stringStream) {
      buffer += chunk;

      while (true) {
        final match = photoRegex.firstMatch(buffer);
        if (match == null) break;

        // 1. Écrire le JSON propre qui précède la photo directement dans le fichier temporaire sur disque
        if (match.start > 0) {
          sink.write(buffer.substring(0, match.start));
        }

        // 2. Extraire la photo Base64 vers le stockage physique
        final photoPath = match.group(1)!;
        final b64Raw = match.group(2)!;
        final b64 = b64Raw.replaceAll(RegExp(r'\s+'), '');

        if (photoPath.isNotEmpty && b64.isNotEmpty) {
          try {
            final normalizedPath = photoPath.replaceAll('\\', '/');
            final fileName = normalizedPath.split('/').last;
            String subDir = 'misc';
            final parts = normalizedPath.split('/');
            final idx = parts.indexOf('audit_photos');
            if (idx != -1 && idx + 2 < parts.length) {
              subDir = parts[idx + 1];
            }
            final dir = Directory('$appDirPath/audit_photos/$subDir');
            if (!dir.existsSync()) dir.createSync(recursive: true);
            final newFile = File('${dir.path}/$fileName');
            if (!newFile.existsSync()) {
              newFile.writeAsBytesSync(base64Decode(b64));
            }
          } catch (e) {
            if (kDebugMode) print('⚠️ Restauration photo streaming: $e');
          }
          photoCount++;
          if (photoCount % 10 == 0) {
            await Future.delayed(Duration.zero);
          }
          if (photoCount % 25 == 0) {
            final prg = (0.05 + (photoCount * 0.0004)).clamp(0.05, 0.80);
            onProgress?.call('Extraction des photos : $photoCount...', prg);
          }
        }

        // 3. Écrire la version nettoyée '"path": ""' dans le fichier temporaire
        sink.write('"$photoPath": ""');

        // 4. Avancer le buffer après la photo
        buffer = buffer.substring(match.end);
      }

      // Vider périodiquement le buffer si aucun match n'est en cours pour maintenir la RAM sous 2 Mo
      if (buffer.length > 256 * 1024) {
        final lastPhotoStart = buffer.lastIndexOf(RegExp(r'"[^"]+?\.(?:jpg|jpeg|png|webp|gif)"\s*:\s*"'));
        if (lastPhotoStart > 0) {
          sink.write(buffer.substring(0, lastPhotoStart));
          buffer = buffer.substring(lastPhotoStart);
        } else if (!buffer.contains('"')) {
          final flushLen = buffer.length - 32 * 1024;
          if (flushLen > 0) {
            sink.write(buffer.substring(0, flushLen));
            buffer = buffer.substring(flushLen);
          }
        }
      }
    }

    // Évacuer la fin du buffer après le dernier chunk
    if (buffer.isNotEmpty) {
      sink.write(buffer);
      buffer = '';
    }

    await sink.flush();
    await sink.close();

    onProgress?.call('Désérialisation des métadonnées métier...', 0.85);

    try {
      final cleanContent = await tempCleanFile.readAsString();
      final payload = jsonDecode(cleanContent) as Map<String, dynamic>;

      try {
        if (await tempCleanFile.exists()) await tempCleanFile.delete();
      } catch (_) {}

      return payload;
    } catch (e) {
      try {
        if (await tempCleanFile.exists()) await tempCleanFile.delete();
      } catch (_) {}
      if (kDebugMode) print('❌ Erreur extraction streaming métadonnées: $e');
      rethrow;
    }
  }

  // Helper récursif pour corriger les chemins de photos absolus dans les données importées
  static dynamic _fixPathsRecursively(dynamic value, String appDirPath) {
    if (value is String) {
      for (final folder in const ['audit_photos', 'client_logos', 'client_qrcodes']) {
        if (value.contains('/$folder/') || value.contains('\\$folder\\')) {
          final separator = value.contains('\\$folder\\') ? '\\' : '/';
          final keyword = '$separator$folder$separator';
          final parts = value.split(keyword);
          if (parts.length >= 2) {
            final suffix = parts.sublist(1).join(keyword);
            return '$appDirPath$separator$folder$separator$suffix';
          }
        }
      }
      return value;
    } else if (value is Map) {
      final newMap = <String, dynamic>{};
      value.forEach((k, v) {
        newMap[k.toString()] = _fixPathsRecursively(v, appDirPath);
      });
      return newMap;
    } else if (value is List) {
      return value.map((item) => _fixPathsRecursively(item, appDirPath)).toList();
    }
    return value;
  }


  // ── INSPECTION ET VALIDATION PRÉALABLE D'UN CONTENU JSON ──

  static Future<InspectionSauvegarde> inspecterSauvegarde(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent);
      if (data is! Map<String, dynamic>) {
        return const InspectionSauvegarde(
          isValid: false,
          message: 'Format JSON invalide.',
        );
      }

      final magic = data['magic'] as String?;
      if (magic != _magic && magic != _magicV2 && magic != _magicV1) {
        return InspectionSauvegarde(
          isValid: false,
          message: 'Format de sauvegarde incompatible ($magic).',
        );
      }

      final schemaVersion = (data['schema_version'] as num?)?.toInt() ?? 1;
      final exportType = data['export_type'] as String?;
      final exportedAt = data['exported_at'] as String?;

      int count = (data['mission_count'] as num?)?.toInt() ?? 0;
      if (count == 0 && data.containsKey('missions') && data['missions'] is List) {
        count = (data['missions'] as List).length;
      } else if (count == 0 && data.containsKey('mission')) {
        count = 1;
      }

      return InspectionSauvegarde(
        isValid: true,
        magic: magic,
        schemaVersion: schemaVersion,
        exportType: exportType,
        missionCount: count,
        exportedAt: exportedAt,
        checksumValid: true,
      );
    } catch (e) {
      return InspectionSauvegarde(
        isValid: false,
        message: 'Erreur d\'analyse du fichier : $e',
      );
    }
  }

  // ── INSPECTION SUR DISQUE ULTRA-RAPIDE (MÉMOIRE < 1 MO) ──

  static Future<InspectionSauvegarde> inspecterSauvegardeFichier(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const InspectionSauvegarde(
          isValid: false,
          message: 'Fichier introuvable sur le disque.',
        );
      }

      final formatInfo = await BackupFormatDetector.detectFormat(file);
      if (!formatInfo.isSupported) {
        return const InspectionSauvegarde(
          isValid: false,
          message: 'Format de fichier non reconnu ou non pris en charge. Veuillez sélectionner un fichier .bin ou .json valide.',
        );
      }

      // 1. Détection du format ZIP / BIN V4
      if (formatInfo.format == BackupFileFormat.zipBin || await _isZipFile(file)) {
        try {
          final bytes = await file.readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);
          final manifestEntry = archive.findFile('manifest.json');
          if (manifestEntry != null) {
            final content = const Utf8Decoder(allowMalformed: true)
                .convert(manifestEntry.content as List<int>);
            final manifest = jsonDecode(content) as Map<String, dynamic>;
            final magic = manifest['magic'] as String?;
            final schemaVersion = (manifest['schema_version'] as num?)?.toInt() ?? 4;
            final exportType = manifest['export_type'] as String?;
            final exportedAt = manifest['exported_at'] as String?;
            final missionCount = (manifest['mission_count'] as num?)?.toInt() ?? 1;

            return InspectionSauvegarde(
              isValid: magic == _magicV4 || magic == _magic || magic == _magicV2,
              magic: magic,
              schemaVersion: schemaVersion,
              exportType: exportType,
              missionCount: missionCount,
              exportedAt: exportedAt,
              checksumValid: true,
            );
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ Inspection Zip V4 error: $e');
        }
      }

      // 2. Inspection Legacy JSON (V1 / V2 / V3) via streaming partiel 64 Ko
      final stream = file.openRead(0, 65536);
      final bytes = await stream.fold<List<int>>(<int>[], (p, e) {
        p.addAll(e);
        return p;
      });

      String headerText = const Utf8Decoder(allowMalformed: true).convert(bytes);
      final magicMatch = RegExp(r'"magic"\s*:\s*"([^"]+)"').firstMatch(headerText);
      final schemaMatch = RegExp(r'"schema_version"\s*:\s*(\d+)').firstMatch(headerText);
      final exportTypeMatch = RegExp(r'"export_type"\s*:\s*"([^"]+)"').firstMatch(headerText);
      final exportedAtMatch = RegExp(r'"exported_at"\s*:\s*"([^"]+)"').firstMatch(headerText);
      final missionCountMatch = RegExp(r'"mission_count"\s*:\s*(\d+)').firstMatch(headerText);

      final magic = magicMatch?.group(1);
      final schemaVersion = int.tryParse(schemaMatch?.group(1) ?? '') ?? 1;
      final exportType = exportTypeMatch?.group(1);
      final exportedAt = exportedAtMatch?.group(1);
      final missionCount = int.tryParse(missionCountMatch?.group(1) ?? '') ?? 1;

      if (magic == null || (magic != _magic && magic != _magicV2 && magic != _magicV1 && magic != _magicV4)) {
        return InspectionSauvegarde(
          isValid: false,
          magic: magic,
          message: 'Format de sauvegarde non reconnu ou incompatible ($magic). Veuillez sélectionner un fichier .bin ou .json valide.',
        );
      }

      return InspectionSauvegarde(
        isValid: true,
        magic: magic,
        schemaVersion: schemaVersion,
        exportType: exportType,
        missionCount: missionCount,
        exportedAt: exportedAt,
        checksumValid: true,
      );
    } catch (e) {
      return InspectionSauvegarde(
        isValid: false,
        message: 'Erreur d\'analyse du fichier : $e',
      );
    }
  }

  // ── IMPORTATION STREAMING DEPUIS LE DISQUE AVEC PROGRESSION (HAUTE PERFORMANCE) ──

  static Future<ImportResult> importerSauvegardeFichier({
    required String filePath,
    required bool ecraser,
    required String importeurMatricule,
    required String importeurNom,
    required String importeurPrenom,
    void Function(String stage, double progress)? onProgress,
  }) async {
    return importerMissions(
      filePath,
      ecraserExistants: ecraser,
      importeurMatricule: importeurMatricule,
      importeurNom: importeurNom,
      importeurPrenom: importeurPrenom,
      onProgress: onProgress,
    );
  }

  // ── IMPORTATION DIRECTE DEPUIS UN CONTENU JSON EN MÉMOIRE ──

  static Future<ImportResult> importerSauvegarde({
    required String jsonContent,
    required bool ecraser,
    required String importeurMatricule,
    required String importeurNom,
    required String importeurPrenom,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_import_${DateTime.now().millisecondsSinceEpoch}.json');
      await tempFile.writeAsString(jsonContent);

      final result = await importerMissions(
        tempFile.path,
        ecraserExistants: ecraser,
        importeurMatricule: importeurMatricule,
        importeurNom: importeurNom,
        importeurPrenom: importeurPrenom,
      );

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return result;
    } catch (e, st) {
      if (kDebugMode) print('❌ Erreur importerSauvegarde: $e\n$st');
      return ImportResult(
        success: false,
        message: "Erreur lors de l'importation.",
        errorDetail: e.toString(),
      );
    }
  }

  // ── DÉTECTION DU FORMAT ARCHIVE ZIP (PK 0x504B0304) ──
  static Future<bool> _isZipFile(File file) async {
    try {
      final len = await file.length();
      if (len < 4) return false;
      final bytes = await file.openRead(0, 4).first;
      return bytes.length >= 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          bytes[2] == 0x03 &&
          bytes[3] == 0x04;
    } catch (_) {
      return false;
    }
  }

  // ── DÉPLACEMENT / COPIE DE DOSSIERS EN DISQUE CONTINU ──
  static Future<void> _copyDirRecursively(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }
    await for (final entity in source.list(recursive: false)) {
      final lastPart = entity.path.replaceAll('\\', '/').split('/').last;
      if (entity is Directory) {
        final newDir = Directory('${destination.path}/$lastPart');
        await _copyDirRecursively(entity, newDir);
      } else if (entity is File) {
        final newFile = File('${destination.path}/$lastPart');
        if (!await newFile.parent.exists()) {
          await newFile.parent.create(recursive: true);
        }
        if (!await newFile.exists()) {
          await entity.copy(newFile.path);
        }
      }
    }
  }

  // ── ISOLATE WORKER POUR EXTRACTION ET RESTAURATION DES MÉDIAS SANS BLOQUER L'UI ──
  static Future<void> _extractAndRestoreMediaWorker(Map<String, String> params) async {
    final zipPath = params['zipPath']!;
    final extractPath = params['extractPath']!;
    final appPhotosPath = params['appPhotosPath']!;
    final appDirPath = params['appDirPath'] ?? Directory(appPhotosPath).parent.path;

    // 1. Extraction zip sur le disque
    await extractFileToDisk(zipPath, extractPath);

    // 2. Déplacement/copie des photos et médias extraits (audit_photos, client_logos, client_qrcodes)
    final extractedPhotosDir = Directory('$extractPath/photos/audit_photos');
    if (extractedPhotosDir.existsSync()) {
      _syncCopyDirRecursively(extractedPhotosDir, Directory('$appDirPath/audit_photos'));
    }

    final extractedLogosDir = Directory('$extractPath/photos/client_logos');
    if (extractedLogosDir.existsSync()) {
      _syncCopyDirRecursively(extractedLogosDir, Directory('$appDirPath/client_logos'));
    }

    final extractedQrcodesDir = Directory('$extractPath/photos/client_qrcodes');
    if (extractedQrcodesDir.existsSync()) {
      _syncCopyDirRecursively(extractedQrcodesDir, Directory('$appDirPath/client_qrcodes'));
    }
  }

  static void _syncCopyDirRecursively(Directory source, Directory destination) {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }
    for (final entity in source.listSync(recursive: false)) {
      final baseName = entity.path.replaceAll('\\', '/').split('/').last;
      if (entity is Directory) {
        final newDir = Directory('${destination.path}/$baseName');
        _syncCopyDirRecursively(entity, newDir);
      } else if (entity is File) {
        final newFile = File('${destination.path}/$baseName');
        if (!newFile.parent.existsSync()) {
          newFile.parent.createSync(recursive: true);
        }
        if (!newFile.existsSync()) {
          entity.copySync(newFile.path);
        }
      }
    }
  }

  // ── COLLECTEUR DE CHEMINS PHOTOS POUR EXPORT V4 ──
  static void _collectPhotoPathsRecursively(dynamic value, Set<String> paths) {
    if (value is String) {
      final vLower = value.toLowerCase();
      final hasMediaFolder = value.contains('/audit_photos/') ||
          value.contains(r'\audit_photos\') ||
          value.contains('/client_logos/') ||
          value.contains(r'\client_logos\') ||
          value.contains('/client_qrcodes/') ||
          value.contains(r'\client_qrcodes\');
      final isImageExt = vLower.endsWith('.jpg') ||
          vLower.endsWith('.jpeg') ||
          vLower.endsWith('.png') ||
          vLower.endsWith('.webp');
      if (hasMediaFolder && isImageExt) {
        paths.add(value);
      }
    } else if (value is Map) {
      for (final v in value.values) {
        _collectPhotoPathsRecursively(v, paths);
      }
    } else if (value is List) {
      for (final item in value) {
        _collectPhotoPathsRecursively(item, paths);
      }
    }
  }


  // ── ENTREE UNIFIEE D'IMPORTATION (DUAL-MODE AUTOMATIQUE BIN/ZIP & LEGACY JSON) ──
  static Future<ImportResult> importerMissions(
    String filePath, {
    bool ecraserExistants = false,
    required String importeurMatricule,
    required String importeurNom,
    required String importeurPrenom,
    void Function(String stage, double progress)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const ImportResult(
        success: false,
        message: 'Fichier introuvable sur le disque.',
      );
    }

    final formatInfo = await BackupFormatDetector.detectFormat(file);

    if (formatInfo.format == BackupFileFormat.zipBin || await _isZipFile(file)) {
      return _importBackupV4(
        filePath,
        ecraserExistants: ecraserExistants,
        importeurMatricule: importeurMatricule,
        importeurNom: importeurNom,
        importeurPrenom: importeurPrenom,
        onProgress: onProgress,
      );
    }

    if (formatInfo.format == BackupFileFormat.jsonLegacy) {
      return _importLegacyBackup(
        filePath,
        ecraserExistants: ecraserExistants,
        importeurMatricule: importeurMatricule,
        importeurNom: importeurNom,
        importeurPrenom: importeurPrenom,
        onProgress: onProgress,
      );
    }

    return const ImportResult(
      success: false,
      message: 'Format de fichier non supporté. Seuls les fichiers .bin et .json sont acceptés.',
    );
  }

  // ── IMPORTATION MOTEUR V4 (STREAMING ZIP BUNDLE - RAM < 5 MO) ──
  static Future<ImportResult> _importBackupV4(
    String zipFilePath, {
    bool ecraserExistants = false,
    required String importeurMatricule,
    required String importeurNom,
    required String importeurPrenom,
    void Function(String stage, double progress)? onProgress,
  }) async {
    final warnings = <String>[];
    int imported = 0;
    int skipped = 0;

    onProgress?.call('Extraction progressive du paquet V4 sur disque...', 0.05);

    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory('${tempDir.path}/import_v4_${DateTime.now().millisecondsSinceEpoch}');
    await extractDir.create(recursive: true);

    String effectiveZipPath = zipFilePath;
    File? tempZipCopy;
    if (!zipFilePath.toLowerCase().endsWith('.zip')) {
      tempZipCopy = File('${tempDir.path}/temp_import_${DateTime.now().millisecondsSinceEpoch}.zip');
      await File(zipFilePath).copy(tempZipCopy.path);
      effectiveZipPath = tempZipCopy.path;
    }

    try {
      // 1 & 2. Extraction Zip streaming et déplacement photos déportés dans un Isolate (0ms UI freeze)
      await Isolate.run(() => _extractAndRestoreMediaWorker({
        'zipPath': effectiveZipPath,
        'extractPath': extractDir.path,
        'appPhotosPath': '${appDir.path}/audit_photos',
        'appDirPath': appDir.path,
      }));

      onProgress?.call('Analyse du manifeste V4...', 0.35);

      // 3. Lire manifest.json
      final manifestFile = File('${extractDir.path}/manifest.json');
      if (!await manifestFile.exists()) {
        return const ImportResult(
          success: false,
          message: 'Manifeste V4 introuvable dans l\'archive de sauvegarde.',
        );
      }
      final manifestStr = await manifestFile.readAsString();
      final manifest = jsonDecode(manifestStr) as Map<String, dynamic>;

      final magic = manifest['magic'] as String?;
      if (magic != _magicV4) {
        return const ImportResult(
          success: false,
          message: 'Format de sauvegarde V4 invalide.',
        );
      }

      // 4. Importer les missions
      final importedMissionIds = <String>[];
      final missionsDir = Directory('${extractDir.path}/missions');
      if (await missionsDir.exists()) {
        final files = missionsDir.listSync().whereType<File>().toList();
        for (int i = 0; i < files.length; i++) {
          final f = files[i];
          try {
            final content = await f.readAsString();
            var mData = jsonDecode(content) as Map<String, dynamic>;
            // ✅ CORRECTION FORENSIC CRITIQUE V4 : Réécrire les chemins physiques vers l'appareil récepteur
            mData = _fixPathsRecursively(mData, appDir.path) as Map<String, dynamic>;
            final r = await _importMission(
              mData,
              ecraser: ecraserExistants,
              importeurMatricule: importeurMatricule,
              importeurNom: importeurNom,
              importeurPrenom: importeurPrenom,
              onProgress: onProgress,
              missionIndex: i,
              totalMissions: files.length,
            );
            if (r.startsWith('imported')) {
              imported++;
              if (r.contains(':')) {
                importedMissionIds.add(r.substring('imported:'.length));
              }
            } else {
              skipped++;
            }
          } catch (e) {
            warnings.add('Erreur lors de l\'importation d\'une mission V4: $e');
          }

          // Purge Skia & Flush Hive
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }

      // 5. Importer les brouillons
      final localDraftsFile = File('${extractDir.path}/drafts/local_drafts.json');
      if (await localDraftsFile.exists()) {
        try {
          final content = await localDraftsFile.readAsString();
          final list = jsonDecode(content) as List<dynamic>;
          await _importLocalDrafts(list, ecraser: ecraserExistants);
        } catch (e) {
          warnings.add('Brouillons locaux V4 partiellement importés: $e');
        }
      }

      final coffretDraftsFile = File('${extractDir.path}/drafts/coffret_drafts.json');
      if (await coffretDraftsFile.exists()) {
        try {
          final content = await coffretDraftsFile.readAsString();
          final list = jsonDecode(content) as List<dynamic>;
          await _importCoffretDrafts(list, ecraser: ecraserExistants);
        } catch (e) {
          warnings.add('Brouillons coffrets V4 partiellement importés: $e');
        }
      }

      // Synchronisation ciblée uniquement sur les missions importées (évite d'auditer toute la DB)
      for (final mId in importedMissionIds) {
        try {
          final audit = HiveService.getAuditInstallationsByMissionId(mId);
          if (audit != null) {
            await InstallationDescriptionSyncService.syncAuditToDescription(audit);
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ Sync post-import pour $mId: $e');
        }
      }
      onProgress?.call('Importation V4 terminée avec succès !', 1.0);

      return ImportResult(
        success: true,
        message: imported > 0 ? '$imported mission(s) restaurée(s).' : 'Aucune nouvelle mission importée.',
        importedMissions: imported,
        skippedMissions: skipped,
        warnings: warnings,
      );
    } catch (e, st) {
      if (kDebugMode) print('❌ Erreur _importBackupV4: $e\n$st');
      return ImportResult(
        success: false,
        message: 'Erreur lors de l\'importation du paquet V4.',
        errorDetail: e.toString(),
      );
    } finally {
      if (tempZipCopy != null && await tempZipCopy.exists()) {
        try {
          await tempZipCopy.delete();
        } catch (_) {}
      }
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }

  // ── IMPORTATION MOTEUR LEGACY (V1/V2/V3 JSON STREAMING - RAM < 15 MO) ──
  static Future<ImportResult> _importLegacyBackup(
    String filePath, {
    bool ecraserExistants = false,
    required String importeurMatricule,
    required String importeurNom,
    required String importeurPrenom,
    void Function(String stage, double progress)? onProgress,
  }) async {
    final warnings = <String>[];
    int imported = 0;
    int skipped = 0;

    onProgress?.call('Analyse de la structure de sauvegarde Legacy...', 0.05);

    Map<String, dynamic> payload;
    try {
      final appDir = await getApplicationDocumentsDirectory();

      payload = await _extractMetadataAndPhotosStream(
        filePath,
        appDir.path,
        onProgress: onProgress,
      );

      payload = _fixPathsRecursively(payload, appDir.path) as Map<String, dynamic>;
    } catch (e, st) {
      if (kDebugMode) print('❌ Erreur extraction payload import Legacy: $e\n$st');

      String userMessage;
      final errStr = e.toString().toLowerCase();

      if (errStr.contains('out of memory') || e is OutOfMemoryError) {
        userMessage = "Mémoire vive (RAM) insuffisante sur l'appareil pour importer cette sauvegarde volumineuse.";
      } else if (errStr.contains('checksum_invalid')) {
        userMessage = "Intégrité du fichier compromise (signature checksum SHA-256 invalide). Le fichier a peut-être été modifié.";
      } else if (e is FormatException || errStr.contains('formatexception')) {
        userMessage = "Structure du fichier JSON invalide ou malformée.";
      } else if (e is FileSystemException || errStr.contains('filesystemexception')) {
        userMessage = "Erreur d'accès ou de lecture du fichier sur le disque.";
      } else {
        userMessage = "Erreur lors du traitement de la sauvegarde.";
      }

      return ImportResult(
        success: false,
        message: userMessage,
        errorDetail: e.toString(),
      );
    }

    final fileMagic = payload['magic'] as String?;
    if (fileMagic != _magic && fileMagic != _magicV2 && fileMagic != _magicV1 && fileMagic != _magicV4) {
      return const ImportResult(
        success: false,
        message: "Ce fichier n'est pas une sauvegarde Inspec valide.",
      );
    }

    final schemaVersion = payload['schema_version'] as int? ?? 1;
    if (schemaVersion > _schemaVersion) {
      return ImportResult(
        success: false,
        message:
            'Sauvegarde créée avec une version plus récente (schéma v$schemaVersion). '
            'Mettez à jour l\'application.',
      );
    }

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    onProgress?.call('Restauration des données des missions...', 0.25);

    // ─ 3. Import des missions ─
    final importedLegacyMissionIds = <String>[];
    final missionsData = payload['missions'] as List<dynamic>? ?? [];
    for (int idx = 0; idx < missionsData.length; idx++) {
      final m = missionsData[idx];
      try {
        final r = await _importMission(
            _safeMap(m),
            ecraser: ecraserExistants,
            importeurMatricule: importeurMatricule,
            importeurNom: importeurNom,
            importeurPrenom: importeurPrenom,
            onProgress: onProgress,
            missionIndex: idx,
            totalMissions: missionsData.length,
          );
        if (r.startsWith('imported')) {
          imported++;
          if (r.contains(':')) {
            importedLegacyMissionIds.add(r.substring('imported:'.length));
          }
        } else {
          skipped++;
          final nom = ((m['mission'] as Map?))?['nom_client'] as String? ??
              'Mission inconnue';
          warnings.add('Mission "$nom" ignorée (déjà existante).');
        }
      } catch (e) {
        warnings.add('Erreur sur une mission: $e');
        if (kDebugMode) print('❌ Import mission: $e');
      }

      // Purge mémoire Skia et temporisation pour le garbage collector
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await Future.delayed(const Duration(milliseconds: 10));
    }

    onProgress?.call('Restauration des brouillons et synchronisation...', 0.92);

    // ─ 4. Import brouillons ─
    try {
      await _importLocalDrafts(
          payload['local_drafts'] as List<dynamic>? ?? [],
          ecraser: ecraserExistants);
    } catch (e) {
      warnings.add('Brouillons locaux partiellement importés: $e');
    }
    try {
      await _importCoffretDrafts(
          payload['coffret_drafts'] as List<dynamic>? ?? [],
          ecraser: ecraserExistants);
    } catch (e) {
      warnings.add('Brouillons coffrets partiellement importés: $e');
    }

    // ─ 5. Synchroniser uniquement les missions importées ─
    for (final mId in importedLegacyMissionIds) {
      try {
        final audit = HiveService.getAuditInstallationsByMissionId(mId);
        if (audit != null) {
          await InstallationDescriptionSyncService.syncAuditToDescription(audit);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Sync post-import pour $mId: $e');
      }
    }
    onProgress?.call('Importation terminée !', 1.0);

    return ImportResult(
      success: imported > 0 || warnings.isEmpty,
      message: imported > 0
          ? '$imported mission(s) importée(s).'
          : 'Aucune nouvelle mission importée.',
      importedMissions: imported,
      skippedMissions: skipped,
      warnings: warnings,
    );
  }



  // ── HELPER DE REMAPPAGE DU MISSION_ID ET NOM POUR LES DOUBLONS ──

  static Map<String, dynamic> _remapMissionId(
      Map<String, dynamic> data, String oldId, String newId, [String? newClientName]) {
    final copy = Map<String, dynamic>.from(data);

    if (copy.containsKey('mission') && copy['mission'] is Map) {
      final mj = Map<String, dynamic>.from(copy['mission'] as Map);
      mj['id'] = newId;
      if (newClientName != null && newClientName.isNotEmpty) {
        mj['nom_client'] = newClientName;
      }
      copy['mission'] = mj;
    }

    void remapIdInSubMap(String key) {
      if (copy.containsKey(key) && copy[key] is Map) {
        final subMap = Map<String, dynamic>.from(copy[key] as Map);
        if (subMap.containsKey('missionId')) {
          subMap['missionId'] = newId;
        }
        copy[key] = subMap;
      }
    }

    remapIdInSubMap('audit');
    remapIdInSubMap('description_installations');
    remapIdInSubMap('mesures_essais');
    remapIdInSubMap('jsa');
    remapIdInSubMap('renseignements_generaux');

    void remapIdInList(String key) {
      if (copy.containsKey(key) && copy[key] is List) {
        final list = (copy[key] as List).map((item) {
          if (item is Map) {
            final itemMap = Map<String, dynamic>.from(item);
            if (itemMap.containsKey('missionId')) {
              itemMap['missionId'] = newId;
            }
            return itemMap;
          }
          return item;
        }).toList();
        copy[key] = list;
      }
    }

    remapIdInList('foudre_observations');
    remapIdInList('classements_locaux');
    remapIdInList('classements_zones');
    remapIdInList('trash_items');
    remapIdInList('local_drafts');
    remapIdInList('coffret_drafts');
    remapIdInList('lighting_inspections');

    return copy;
  }

  // ─────────────────────────────────────────────────────────
  // IMPORT D'UNE MISSION
  // ─────────────────────────────────────────────────────────

  static Future<String> _importMission(
    Map<String, dynamic> rawData, {
    required bool ecraser,
    required String importeurMatricule,
    required String importeurNom,
    required String importeurPrenom,
    void Function(String stage, double progress)? onProgress,
    int missionIndex = 0,
    int totalMissions = 1,
  }) async {
    final data = _safeMap(rawData);
    final mj = _safeMap(data['mission']);
    if (mj.isEmpty) return 'skipped';
    
    final originalMissionId = _safeString(mj['id']);
    if (originalMissionId.isEmpty) return 'skipped';

    final box = Hive.box<Mission>('missions');
    final existingById = box.get(originalMissionId);

    String targetMissionId = originalMissionId;
    Map<String, dynamic> targetData = data;

    // Stratégie d'importation :
    if (ecraser && existingById != null) {
      targetMissionId = originalMissionId;
      targetData = data;
    } else if (existingById != null) {
      // Conflit d'identifiant technique sans écrasement :
      // On réattribue un nouvel ID technique unique mais on préserve
      // STRICTEMENT le nomClient métier original sans le modifier
      targetMissionId = 'm_${DateTime.now().microsecondsSinceEpoch}_${box.length}';
      targetData = _remapMissionId(data, originalMissionId, targetMissionId);
    }

    final targetMj = _safeMap(targetData['mission']);
    final createdPhotoPaths = <String>[];

    try {
      final mission = Mission.fromJson(targetMj);

      mission.verificateurs ??= [];
      final dejaPresent = mission.verificateurs!
          .any((v) => v['matricule'] == importeurMatricule);
      if (!dejaPresent) {
        mission.verificateurs!.add({
          'matricule': importeurMatricule,
          'nom': importeurNom,
          'prenom': importeurPrenom,
          'role': 'importeur',
        });
      }

      await box.put(targetMissionId, mission);

      // Restaurer les photos
      final photosMap = _safeMap(targetData['photos']);
      if (photosMap.isNotEmpty) {
        final paths = await _restorePhotos(
          photosMap,
          onProgress: onProgress,
          missionIndex: missionIndex,
          totalMissions: totalMissions,
        );
        createdPhotoPaths.addAll(paths);
      }

      // Nettoyage en cas d'écrasement explicite pour éviter les orphelins et doublons
      if (ecraser) {
        final foudreBox = Hive.box<Foudre>('foudre_observations');
        final fKeys = foudreBox.values.where((f) => f.missionId == targetMissionId).map((f) => f.key).toList();
        for (final k in fKeys) {
          await foudreBox.delete(k);
        }

        final cBox = Hive.box<ClassementEmplacement>('classement_locaux');
        final cKeys = cBox.values.where((c) => c.missionId == targetMissionId).map((c) => c.key).toList();
        for (final k in cKeys) {
          await cBox.delete(k);
        }

        final czBox = Hive.box<ClassementZone>('classement_zones');
        final czKeys = czBox.values.where((c) => c.missionId == targetMissionId).map((c) => c.key).toList();
        for (final k in czKeys) {
          await czBox.delete(k);
        }

        final tBox = Hive.box<TrashItem>('trash_items');
        final tKeys = tBox.values.where((t) => t.missionId == targetMissionId).map((t) => t.key).toList();
        for (final k in tKeys) {
          await tBox.delete(k);
        }

        final lBox = Hive.box<LightingInspection>('lighting_inspections');
        final lKeys = lBox.values.where((l) => l.missionId == targetMissionId).map((l) => l.id).toList();
        for (final k in lKeys) {
          await lBox.delete(k);
        }
      }

      // Sub-modules avec targetMissionId
      final auditData = _safeMap(targetData['audit']);
      if (auditData.isNotEmpty) await _importAudit(auditData, ecraser: ecraser);

      final descData = _safeMap(targetData['description_installations']);
      if (descData.isNotEmpty) await _importDescription(descData, ecraser: ecraser);

      final mesuresData = _safeMap(targetData['mesures_essais']);
      if (mesuresData.isNotEmpty) await _importMesures(mesuresData, ecraser: ecraser);

      final jsaData = _safeMap(targetData['jsa']);
      if (jsaData.isNotEmpty) await _importJSA(jsaData, ecraser: ecraser);

      final rensData = _safeMap(targetData['renseignements_generaux']);
      if (rensData.isNotEmpty) await _importRenseignements(rensData, ecraser: ecraser);

      for (final l in _safeList(targetData['lighting_inspections'])) {
        if (l is Map) await _importLightingInspection(_safeMap(l), ecraser: ecraser);
      }

      for (final f in _safeList(targetData['foudre_observations'])) {
        if (f is Map) await _importFoudre(_safeMap(f), ecraser: ecraser);
      }

      for (final c in _safeList(targetData['classements_locaux'])) {
        if (c is Map) await _importClassement(_safeMap(c));
      }

      for (final c in _safeList(targetData['classements_zones'])) {
        if (c is Map) await _importClassementZone(_safeMap(c));
      }

      final progressData = targetData['sequence_progress'];
      if (progressData is Map) {
        final progressBox = await Hive.openBox('mission_progress');
        await progressBox.put(targetMissionId, Map<String, dynamic>.from(progressData));
      }

      final trashData = _safeList(targetData['trash_items']);
      if (trashData.isNotEmpty) {
        final trashBox = Hive.box<TrashItem>('trash_items');
        for (final t in trashData) {
          if (t is Map) {
            final itemMap = _safeMap(t);
            itemMap['missionId'] = targetMissionId;
            final item = TrashItem.fromJson(itemMap);
            await trashBox.put(item.id, item);
          }
        }
      }

      // ✅ Enrôlement automatique de l'importateur dans la JSA (Source Unique de Vérité)
      await IntervenantsService.ensureCurrentUserInJSA(
        targetMissionId,
        fallbackMatricule: importeurMatricule,
        fallbackNom: importeurNom,
        fallbackPrenom: importeurPrenom,
      );

      // ✅ Enrôlement automatique de la mission importée pour la sauvegarde (Local + Cloud)
      Future.microtask(() async {
        try {
          await MissionActivityTracker.markMissionModifiedToday(targetMissionId);
          final localStore = LocalBackupStore();
          await localStore.saveLocalBackup(
            missionId: targetMissionId,
            matricule: importeurMatricule,
          );
          final queueService = BackupQueueService();
          await queueService.enqueueOrUpdate(
            BackupQueueItem(
              missionId: targetMissionId,
              matricule: importeurMatricule,
              status: BackupQueueStatus.pending,
              addedAt: DateTime.now(),
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Auto-enrôlement sauvegarde post-importation: $e');
          }
        }
      });

      return 'imported:$targetMissionId';
    } catch (e, st) {
      if (kDebugMode) print('❌ Exception détectée lors de l\'import: $e\n$st');
      await _rollbackMission(targetMissionId, createdPhotoPaths);
      rethrow;
    }
  }

  // ── Audit ──
  static Future<void> _importAudit(Map<String, dynamic> d, {bool ecraser = false}) async {
    final missionId = d['missionId'] as String;

    // Vérifier si un audit existe déjà pour cette mission
    final box = Hive.box<AuditInstallationsElectriques>(
        'audit_installations_electriques');
    final existingKeys = box.values
        .where((a) => a.missionId == missionId)
        .map((a) => a.key)
        .toList();
    if (existingKeys.isNotEmpty) {
      if (!ecraser) return;
      for (final k in existingKeys) {
        await box.delete(k);
      }
    }

    final audit = AuditInstallationsElectriques(
      missionId: missionId,
      updatedAt: _dt(d['updatedAt']),
      photos: _strList(d['photos']),
      moyenneTensionLocaux:
          (d['moyenneTensionLocaux'] as List<dynamic>?)
                  ?.map((l) =>
                      _parseMTLocal(l as Map<String, dynamic>))
                  .toList() ??
              [],
      moyenneTensionZones:
          (d['moyenneTensionZones'] as List<dynamic>?)
                  ?.map((z) =>
                      _parseMTZone(z as Map<String, dynamic>))
                  .toList() ??
              [],
      basseTensionZones:
          (d['basseTensionZones'] as List<dynamic>?)
                  ?.map((z) =>
                      _parseBTZone(z as Map<String, dynamic>))
                  .toList() ??
              [],
    );

    // Utiliser box.add() comme HiveService le fait — clé auto-incrémentée
    await box.add(audit);

    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>('missions');
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.auditInstallationsElectriquesId =
          audit.key.toString();
      await mission.save();
    }
  }

  static MoyenneTensionLocal _parseMTLocal(Map<String, dynamic> d) {
    final local = MoyenneTensionLocal(
      id: d['id'] as String?,
      nom: d['nom'] as String? ?? '',
      type: d['type'] as String? ?? 'LOCAL_ELECTRIQUE',
      accessible: d['accessible'] as bool? ?? true,
      aReverifier: d['aReverifier'] as bool? ?? false,
      isRiskZone: d['isRiskZone'] as bool? ?? false,
      createdAt: d['createdAt'] != null ? _dt(d['createdAt']) : null,
      updatedAt: d['updatedAt'] != null ? _dt(d['updatedAt']) : null,
      photos: _strList(d['photos']),
      dispositionsConstructives: _parseElements(d['dispositionsConstructives']),
      conditionsExploitation: _parseElements(d['conditionsExploitation']),
      cellule: d['cellule'] != null
          ? _parseCellule(d['cellule'] as Map<String, dynamic>)
          : null,
      transformateur: d['transformateur'] != null
          ? _parseTransformateur(d['transformateur'] as Map<String, dynamic>)
          : null,
      cellules: (d['cellules'] as List<dynamic>?)
              ?.map((c) => _parseCellule(c as Map<String, dynamic>))
              .toList() ??
          [],
      transformateurs: (d['transformateurs'] as List<dynamic>?)
              ?.map((t) => _parseTransformateur(t as Map<String, dynamic>))
              .toList() ??
          [],
      coffrets: _parseCoffrets(d['coffrets']),
      observationsLibres: _parseObs(d['observationsLibres']),
    );
    local.migrateFromOldFields();
    return local;
  }

  static MoyenneTensionZone _parseMTZone(Map<String, dynamic> d) =>
      MoyenneTensionZone(
        id: d['id'] as String?,
        nom: d['nom'] as String? ?? '',
        description: d['description'] as String?,
        photos: _strList(d['photos']),
        classementZoneId: d['classementZoneId'] as String?,
        isRiskZone: d['isRiskZone'] as bool? ?? false,
        createdAt: d['createdAt'] != null ? _dt(d['createdAt']) : null,
        updatedAt: d['updatedAt'] != null ? _dt(d['updatedAt']) : null,
        coffrets: _parseCoffrets(d['coffrets']),
        observationsLibres: _parseObs(d['observationsLibres']),
        locaux: (d['locaux'] as List<dynamic>?)
                ?.map((l) => _parseMTLocal(l as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static BasseTensionZone _parseBTZone(Map<String, dynamic> d) =>
      BasseTensionZone(
        id: d['id'] as String?,
        nom: d['nom'] as String? ?? '',
        description: d['description'] as String?,
        photos: _strList(d['photos']),
        classementZoneId: d['classementZoneId'] as String?,
        isRiskZone: d['isRiskZone'] as bool? ?? false,
        createdAt: d['createdAt'] != null ? _dt(d['createdAt']) : null,
        updatedAt: d['updatedAt'] != null ? _dt(d['updatedAt']) : null,
        coffretsDirects: _parseCoffrets(d['coffretsDirects']),
        observationsLibres: _parseObs(d['observationsLibres']),
        locaux: (d['locaux'] as List<dynamic>?)
                ?.map((l) => _parseBTLocal(l as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static BasseTensionLocal _parseBTLocal(Map<String, dynamic> d) =>
      BasseTensionLocal(
        id: d['id'] as String?,
        nom: d['nom'] as String? ?? '',
        type: d['type'] as String? ?? 'LOCAL_ELECTRIQUE',
        accessible: d['accessible'] as bool? ?? true,
        aReverifier: d['aReverifier'] as bool? ?? false,
        isRiskZone: d['isRiskZone'] as bool? ?? false,
        createdAt: d['createdAt'] != null ? _dt(d['createdAt']) : null,
        updatedAt: d['updatedAt'] != null ? _dt(d['updatedAt']) : null,
        photos: _strList(d['photos']),
        dispositionsConstructives: _parseElements(d['dispositionsConstructives']),
        conditionsExploitation: _parseElements(d['conditionsExploitation']),
        cellules: (d['cellules'] as List<dynamic>?)
                ?.map((c) => _parseCellule(c as Map<String, dynamic>))
                .toList() ??
            [],
        transformateurs: (d['transformateurs'] as List<dynamic>?)
                ?.map((t) => _parseTransformateur(t as Map<String, dynamic>))
                .toList() ??
            [],
        coffrets: _parseCoffrets(d['coffrets']),
        observationsLibres: _parseObs(d['observationsLibres']),
      );

  static List<ElementControle> _parseElements(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      final conforme = m['conforme'] as bool?;
      final estNA = m['estNA'] as bool? ?? false;
      // Priorité par défaut à 3 si Non ou NA et absente du JSON
      final priorite = m['priorite'] as int? ??
          ((conforme == false || estNA) ? 3 : null);
      return ElementControle(
        elementControle: m['elementControle'] as String? ?? '',
        conforme: conforme,
        observation: m['observation'] as String?,
        priorite: priorite,
        photos: _strList(m['photos']),
        referenceNormative: m['referenceNormative'] as String?,
        estNA: estNA,
        familleRisque: m['familleRisque'] as String?,
        criticite: m['criticite'] as String?,
      );
    }).toList();
  }

  static Cellule _parseCellule(Map<String, dynamic> d) {
    final legacySection = d['sectionCables'] as String?;
    final secPhase = d['sectionCablePhase'] as String? ?? legacySection;
    final secNeutre = d['sectionCableNeutre'] as String? ?? legacySection;
    return Cellule(
      fonction: d['fonction'] as String? ?? '',
      type: d['type'] as String? ?? '',
      marqueModeleAnnee: d['marqueModeleAnnee'] as String? ?? '',
      marque: d['marque'] as String?,
      modele: d['modele'] as String?,
      annee: d['annee'] as String?,
      tensionAssignee: d['tensionAssignee'] as String? ?? '',
      pouvoirCoupure: d['pouvoirCoupure'] as String? ?? '',
      numerotation: d['numerotation'] as String? ?? '',
      parafoudres: d['parafoudres'] as String? ?? '',
      photos: _strList(d['photos']),
      elementsVerifies: _parseElements(d['elementsVerifies']),
      observations: _parseElements(d['observations']),
      syncId: d['syncId'] as String?,
      tensionService: d['tensionService'] as String?,
      createdAt: d['createdAt'] != null ? _dt(d['createdAt']) : null,
      updatedAt: d['updatedAt'] != null ? _dt(d['updatedAt']) : null,
      gamme: d['gamme'] as String?,
      calibreDisjoncteur: d['calibreDisjoncteur'] as String?,
      sectionCables: legacySection ?? secPhase,
      sectionCablePhase: secPhase,
      sectionCableNeutre: secNeutre,
      conducteursPhase: d['conducteursPhase'] as int?,
      conducteursNeutre: d['conducteursNeutre'] as int?,
      natureReseau: d['natureReseau'] as String?,
      presenceIacm: d['presenceIacm'] as String?,
      nom: d['nom'] as String?,
      repere: d['repere'] as String?,
      photo: d['photo'] as String?,
    );
  }

  static TransformateurMTBT _parseTransformateur(Map<String, dynamic> d) {
    final legacySection = d['sectionCables'] as String?;
    final secPhase = d['sectionCablePhase'] as String? ?? legacySection;
    final secNeutre = d['sectionCableNeutre'] as String? ?? legacySection;
    return TransformateurMTBT(
      typeTransformateur: d['typeTransformateur'] as String? ?? '',
      marqueAnnee: d['marqueAnnee'] as String? ?? '',
      marque: d['marque'] as String?,
      anneeFabrication: d['anneeFabrication'] as String?,
      puissanceAssignee: d['puissanceAssignee'] as String? ?? '',
      tensionPrimaireSecondaire:
          d['tensionPrimaireSecondaire'] as String? ?? '',
      relaisBuchholz: d['relaisBuchholz'] as String? ?? '',
      typeImmersion: d['typeImmersion'] as String?,
      presenceDGPT2: d['presenceDGPT2'] as String?,
      typeRefroidissement: d['typeRefroidissement'] as String? ?? '',
      regimeNeutre: d['regimeNeutre'] as String? ?? '',
      photos: _strList(d['photos']),
      calibreDisjoncteur: d['calibreDisjoncteur'] as String?,
      sectionCables: legacySection ?? secPhase,
      sectionCablePhase: secPhase,
      sectionCableNeutre: secNeutre,
      conducteursPhase: d['conducteursPhase'] as int?,
      conducteursNeutre: d['conducteursNeutre'] as int?,
      observations: _parseElements(d['observations']),
      syncId: d['syncId'] as String?,
      intensiteNominale: d['intensiteNominale'] as String?,
      couplage: d['couplage'] as String?,
      typeReseau: d['typeReseau'] as String?,
      pccAmont: d['pccAmont'] as String?,
      puissanceUcc: d['puissanceUcc'] as String?,
      ik3Max: d['ik3Max'] as String?,
      elementsVerifies: _parseElements(d['elementsVerifies']),
      nom: d['nom'] as String?,
      photo: d['photo'] as String?,
      repere: d['repere'] as String?,
      createdAt: d['createdAt'] != null ? _dt(d['createdAt']) : null,
      updatedAt: d['updatedAt'] != null ? _dt(d['updatedAt']) : null,
    );
  }

  static List<CoffretArmoire> _parseCoffrets(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) {
      final d = e as Map<String, dynamic>;
      return CoffretArmoire(
        id: d['id'] as String?,
        qrCode: d['qrCode'] as String? ?? '',
        nom: d['nom'] as String? ?? '',
        type: d['type'] as String? ?? '',
        description: d['description'] as String?,
        repere: d['repere'] as String?,
        numeroEquipement: d['numeroEquipement'] as String?,
        statut: d['statut'] as String? ?? 'incomplet',
        currentStep: d['currentStep'] as int? ?? 0,
        zoneAtex: d['zoneAtex'] as bool? ?? false,
        domaineTension: d['domaineTension'] as String? ?? '',
        identificationArmoire: d['identificationArmoire'] as bool? ?? false,
        signalisationDanger: d['signalisationDanger'] as bool? ?? false,
        presenceSchema: d['presenceSchema'] as bool? ?? false,
        presenceParafoudre: d['presenceParafoudre'] as bool? ?? false,
        verificationThermographie:
            d['verificationThermographie'] as bool? ?? false,
        presenceDefautThermo: d['presenceDefautThermo'] as String?,
        alimenteeParTransformateur: d['alimenteeParTransformateur'] as bool?,
        transformateurId: d['transformateurId'] as String?,
        transformateurNomComplet: d['transformateurNomComplet'] as String?,
        presenceCPI: d['presenceCPI'] as bool?,
        departPrisAvecProtection: d['departPrisAvecProtection'] as bool?,
        accessible: d['accessible'] as bool? ?? true,
        createdAt: d['createdAt'] != null ? _dt(d['createdAt']) : null,
        updatedAt: d['updatedAt'] != null ? _dt(d['updatedAt']) : null,
        photos: _strList(d['photos']),
        photosExternes: _strList(d['photosExternes']),
        photosInternes: _strList(d['photosInternes']),
        alimentations: (d['alimentations'] as List<dynamic>?)
                ?.map((a) => _parseAlim(a as Map<String, dynamic>))
                .toList() ??
            [],
        protectionTete: d['protectionTete'] != null
            ? _parseAlim(d['protectionTete'] as Map<String, dynamic>)
            : null,
        pointsVerification: (d['pointsVerification'] as List<dynamic>?)
                ?.map((p) => _parsePoint(p as Map<String, dynamic>))
                .toList() ??
            [],
        observationsLibres: _parseObs(d['observationsLibres']),
        observationsParafoudre: _parseObs(d['observationsParafoudre']),
        observationsParafoudreEnrichies:
            _parseElements(d['observationsParafoudreEnrichies']),
        departures: (d['departures'] as List<dynamic>?)
                ?.map((dep) => _parseDepart(dep as Map<String, dynamic>))
                .toList() ??
            [],
        terminalCircuits: (d['terminalCircuits'] as List<dynamic>?)
                ?.map((circ) => _parseCircuit(circ as Map<String, dynamic>))
                .toList() ??
            [],
        sourceEquipementId: d['sourceEquipementId'] as String?,
        sourceNomComplet: d['sourceNomComplet'] as String?,
        sourceDepartId: d['sourceDepartId'] as String?,
        indiceIpIk: d['indiceIpIk'] as String?,
        indiceIpIkRepere: d['indiceIpIkRepere'] as String?,
      );
    }).toList();
  }

  static DepartEquipement _parseDepart(Map<String, dynamic> d) => DepartEquipement(
        id: d['id'] as String?,
        protectionTete: d['protectionTete'] as String? ?? 'Présent',
        identification: d['identification'] as String? ?? d['nom'] as String? ?? '',
        typeProtection: d['typeProtection'] as String? ?? '',
        courbe: d['courbe'] as String? ?? '',
        ddr: d['ddr'] as String? ?? '',
        pdcKA: d['pdcKA'] as String? ?? '',
        icc3Max: d['icc3Max'] as String? ?? '',
        calibre: d['calibre'] as String? ?? '',
        sectionCable: d['sectionCable'] as String? ?? '',
        marque: d['marque'] as String? ?? '',
        nombreCables: d['nombreCables'] as String?,
        sectionCableNeutre: d['sectionCableNeutre'] as String?,
        conducteursPhase: d['conducteursPhase'] as int?,
        conducteursNeutre: d['conducteursNeutre'] as int?,
        natureCable: d['natureCable'] as String?,
      );

  static CircuitTerminalEquipement _parseCircuit(Map<String, dynamic> d) => CircuitTerminalEquipement(
        id: d['id'] as String?,
        protectionTete: d['protectionTete'] as String? ?? 'Présent',
        identification: d['identification'] as String? ?? '',
        typeProtection: d['typeProtection'] as String? ?? '',
        courbe: d['courbe'] as String? ?? '',
        ddr: d['ddr'] as String? ?? '',
        pdcKA: d['pdcKA'] as String? ?? '',
        icc3Max: d['icc3Max'] as String? ?? '',
        calibre: d['calibre'] as String? ?? '',
        sectionCable: d['sectionCable'] as String? ?? '',
        marque: d['marque'] as String? ?? '',
        nombreCables: d['nombreCables'] as String?,
        sectionCableNeutre: d['sectionCableNeutre'] as String?,
        conducteursPhase: d['conducteursPhase'] as int?,
        conducteursNeutre: d['conducteursNeutre'] as int?,
        natureCable: d['natureCable'] as String?,
      );

  static Alimentation _parseAlim(Map<String, dynamic> d) => Alimentation(
        id: d['id'] as String?,
        typeProtection: d['typeProtection'] as String? ?? '',
        courbe: d['courbe'] as String? ?? '',
        ddr: d['ddr'] as String?,
        pdcKA: d['pdcKA'] as String? ?? '',
        calibre: d['calibre'] as String? ?? '',
        sectionCable: d['sectionCable'] as String? ?? '',
        source: d['source'] as String? ?? '',
        sourceKnown: d['sourceKnown'] as String?,
        marqueDisjoncteur: d['marqueDisjoncteur'] as String?,
        photos: _strList(d['photos']),
        icc3Max: d['icc3Max'] as String? ?? '',
        nombreCables: d['nombreCables'] as String?,
        sectionCableNeutre: d['sectionCableNeutre'] as String?,
        conducteursPhase: d['conducteursPhase'] as int?,
        conducteursNeutre: d['conducteursNeutre'] as int?,
        natureCable: d['natureCable'] as String?,
      );

  static PointVerification _parsePoint(Map<String, dynamic> d) {
    final conformite = d['conformite'] as String? ?? '';
    // Priorité par défaut à 3 si Non ou NA et absente du JSON
    // évite que _isCurrentSlideValid bloque la navigation après import
    final priorite = d['priorite'] as int? ??
        ((conformite == 'non' || conformite == 'na') ? 3 : null);
    return PointVerification(
      pointVerification: d['pointVerification'] as String? ?? '',
      conformite: conformite,
      observation: d['observation'] as String?,
      referenceNormative: d['referenceNormative'] as String?,
      priorite: priorite,
      photos: _strList(d['photos']),
      observations: _parseElements(d['observations']),
      criticite: d['criticite'] as String?,
      familleRisque: d['familleRisque'] as String?,
    );
  }

  static List<ObservationLibre> _parseObs(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return ObservationLibre(
        texte: m['texte'] as String? ?? '',
        photos: _strList(m['photos']),
        dateCreation: _dt(m['dateCreation']),
        dateModification: _dt(m['dateModification']),
        pointVerificationKey: m['pointVerificationKey'] as String?,
        referenceNormative: m['referenceNormative'] as String?,
        familleRisque: m['familleRisque'] as String?,
        criticite: m['criticite'] as String?,
        isAutoLinked: m['isAutoLinked'] as bool? ?? false,
      );
    }).toList();
  }

  // ── Description ──
  static Future<void> _importDescription(Map<String, dynamic> d, {bool ecraser = false}) async {
    final missionId = d['missionId'] as String;
    final box = Hive.box<DescriptionInstallations>('description_installations');

    final existingKeys = box.values
        .where((v) => v.missionId == missionId)
        .map((v) => v.key)
        .toList();
    if (existingKeys.isNotEmpty) {
      if (!ecraser) return;
      for (final k in existingKeys) {
        await box.delete(k);
      }
    }

    final desc = DescriptionInstallations(
      missionId: missionId,
      alimentationMoyenneTension: _parseItems(d['alimentationMoyenneTension']),
      alimentationBasseTension: _parseItems(d['alimentationBasseTension']),
      groupeElectrogene: _parseItems(d['groupeElectrogene']),
      alimentationCarburant: _parseItems(d['alimentationCarburant']),
      inverseur: _parseItems(d['inverseur']),
      stabilisateur: _parseItems(d['stabilisateur']),
      onduleurs: _parseItems(d['onduleurs']),
      cpi: _parseItems(d['cpi']),
      regimeNeutre: d['regimeNeutre'] as String?,
      regimeNeutreDetail: d['regimeNeutreDetail'] as String?,
      eclairageSecurite: d['eclairageSecurite'] as String?,
      modificationsInstallations: d['modificationsInstallations'] as String?,
      noteCalcul: d['noteCalcul'] as String?,
      registreSecurite: d['registreSecurite'] as String?,
      presenceParatonnerre: d['presenceParatonnerre'] as String?,
      analyseRisqueFoudre: d['analyseRisqueFoudre'] as String?,
      etudeTechniqueFoudre: d['etudeTechniqueFoudre'] as String?,
      natureReseauAlimentationSite: d['natureReseauAlimentationSite'] as String?,
      tensionAlimentationSite: d['tensionAlimentationSite'] as String?,
      nombreAlimentationSite: d['nombreAlimentationSite'] as String?,
      presenceIacmAlimentationSite: d['presenceIacmAlimentationSite'] as String?,
      foudreObservations: _parseObs(d['foudreObservations']),
      updatedAt: _dt(d['updatedAt']),
    );

    await box.add(desc);

    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>('missions');
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.descriptionInstallationsId = desc.key.toString();
      await mission.save();
    }
  }

  static List<InstallationItem> _parseItems(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return InstallationItem(
        data: Map<String, String>.from(m['data'] as Map? ?? {}),
        photoPaths: _strList(m['photoPaths']),
      );
    }).toList();
  }

  // ── Mesures et essais ──
  static Future<void> _importMesures(Map<String, dynamic> d, {bool ecraser = false}) async {
    try {
      final missionId = d['missionId'] as String;
      final box = Hive.box<MesuresEssais>('mesures_essais');
      final existingKeys = box.values
          .where((m) => m.missionId == missionId)
          .map((m) => m.key)
          .toList();
      if (existingKeys.isNotEmpty) {
        if (!ecraser) return;
        for (final k in existingKeys) {
          await box.delete(k);
        }
      }

      final cm = d['conditionMesure'] as Map<String, dynamic>?;
      final eda = d['essaiDemarrageAuto'] as Map<String, dynamic>?;
      final tau = d['testArretUrgence'] as Map<String, dynamic>?;
      final amt = d['avisMesuresTerre'] as Map<String, dynamic>?;

      final mesures = MesuresEssais(
        missionId: missionId,
        updatedAt: _dt(d['updatedAt']),
        conditionMesure:
            ConditionMesure(observation: cm?['observation'] as String?),
        essaiDemarrageAuto:
            EssaiDemarrageAuto(observation: eda?['observation'] as String?),
        testArretUrgence: TestArretUrgence(
          observation: tau?['observation'] as String?,
          presence: tau?['presence'] as bool?,
        ),
        avisMesuresTerre: AvisMesuresTerre(
          satisfaisants: _strList(amt?['satisfaisants']),
          nonSatisfaisants: _strList(amt?['nonSatisfaisants']),
          observation: amt?['observation'] as String?,
        ),
        prisesTerre: (d['prisesTerre'] as List<dynamic>?)
                ?.map((p) {
                  final m = p as Map<String, dynamic>;
                  return PriseTerre(
                    localisation: m['localisation'] as String? ?? '',
                    identification: m['identification'] as String? ?? '',
                    conditionPriseTerre:
                        m['conditionPriseTerre'] as String? ?? '',
                    naturePriseTerre: m['naturePriseTerre'] as String? ?? '',
                    methodeMesure: m['methodeMesure'] as String? ?? '',
                    valeurMesure: (m['valeurMesure'] as num?)?.toDouble(),
                    observation: m['observation'] as String?,
                    interconnecteAutrePrise:
                        m['interconnecteAutrePrise'] as String?,
                    photo: m['photo'] as String?,
                  );
                })
                .toList() ??
            [],
        essaisDeclenchement: (d['essaisDeclenchement'] as List<dynamic>?)
                ?.map((e) {
                  final m = e as Map<String, dynamic>;
                  return EssaiDeclenchementDifferentiel(
                    localisation: m['localisation'] as String? ?? '',
                    coffret: m['coffret'] as String?,
                    designationCircuit: m['designationCircuit'] as String?,
                    typeDispositif: m['typeDispositif'] as String? ?? 'Disjoncteur différentiel',
                    calibre: (m['calibre'] as num?)?.toDouble(),
                    reglageIAn: (m['reglageIAn'] as num?)?.toDouble(),
                    tempo: (m['tempo'] as num?)?.toDouble(),
                    tempoText: m['tempoText'] as String?,
                    isolement: (m['isolement'] as num?)?.toDouble(),
                    essai: m['essai'] as String? ?? 'NE',
                    observation: m['observation'] as String?,
                  );
                })
                .toList() ??
            [],
        continuiteResistances: (d['continuiteResistances'] as List<dynamic>?)
                ?.map((c) {
                  final m = c as Map<String, dynamic>;
                  return ContinuiteResistance(
                    localisation: m['localisation'] as String? ?? '',
                    designationTableau: m['designationTableau'] as String? ?? '',
                    origineMesure: m['origineMesure'] as String? ?? '',
                    observation: m['observation'] as String?,
                    essai: m['essai'] as String?,
                  );
                })
                .toList() ??
            [],
        essaisIsolement: (d['essaisIsolement'] as List<dynamic>?)
                ?.map((i) {
                  final m = i as Map<String, dynamic>;
                  return EssaiIsolement(
                    syncId: m['syncId'] as String? ?? '',
                    equipmentSyncId: m['equipmentSyncId'] as String?,
                    pointControle: m['pointControle'] as String? ?? '',
                    isolement: (m['isolement'] as num?)?.toDouble() ?? 0.0,
                    appreciation: m['appreciation'] as String? ?? 'Satisfaisant',
                    localisation: m['localisation'] as String?,
                    designation: m['designation'] as String?,
                    reperePointOrigine: m['reperePointOrigine'] as String?,
                    pointA: m['pointA'] as String?,
                    pointB: m['pointB'] as String?,
                    sectionCable: m['sectionCable'] as String?,
                    nombreCablesTestes: m['nombreCablesTestes'] as int?,
                    sectionCablePointA: m['sectionCablePointA'] as String?,
                    sectionCablePointB: m['sectionCablePointB'] as String?,
                    isSectionPointAManual: m['isSectionPointAManual'] as bool?,
                    isSectionPointBManual: m['isSectionPointBManual'] as bool?,
                    equipmentPointASyncId: m['equipmentPointASyncId'] as String?,
                    equipmentPointBSyncId: m['equipmentPointBSyncId'] as String?,
                    zonePointA: m['zonePointA'] as String?,
                    reperePointA: m['reperePointA'] as String?,
                    nomEquipementPointA: m['nomEquipementPointA'] as String?,
                    zonePointB: m['zonePointB'] as String?,
                    reperePointB: m['reperePointB'] as String?,
                    nomEquipementPointB: m['nomEquipementPointB'] as String?,
                    natureCable: m['natureCable'] as String?,
                  );
                })
                .toList() ??
            [],
        cpiTests: (d['cpiTests'] as List<dynamic>?)
                ?.map((c) => CpiTest.fromMap(c as Map<String, dynamic>))
                .toList() ??
            [],
      );
      await box.add(mesures);
    } catch (e) {
      if (kDebugMode) print('⚠️ Mesures import: $e');
    }
  }

  // ── JSA ──
  static Future<void> _importJSA(Map<String, dynamic> d, {bool ecraser = false}) async {
    try {
      final missionId = d['missionId'] as String;
      final box = Hive.box<JSA>('jsa');
      final existingKeys = box.values
          .where((j) => j.missionId == missionId)
          .map((j) => j.key)
          .toList();
      if (existingKeys.isNotEmpty) {
        if (!ecraser) return;
        for (final k in existingKeys) {
          await box.delete(k);
        }
      }

      final pu = d['planUrgence'] as Map<String, dynamic>?;
      final da = d['dangers'] as Map<String, dynamic>?;
      final eg = d['exigencesGenerales'] as Map<String, dynamic>?;
      final ep = d['epi'] as Map<String, dynamic>?;
      final vf = d['verificationFinale'] as Map<String, dynamic>?;

      final planUrgence = JSAPlanUrgence();
      if (pu != null) {
        planUrgence.voiesIssuesIdentifiees = pu['voiesIssuesIdentifiees'] as bool? ?? false;
        planUrgence.zonesRassemblementIdentifiees = pu['zonesRassemblementIdentifiees'] as bool? ?? false;
        planUrgence.consignesSecuriteInternes = pu['consignesSecuriteInternes'] as bool? ?? false;
        planUrgence.personneContactClient = pu['personneContactClient'] as String? ?? '';
        planUrgence.personneContactKES = pu['personneContactKES'] as String? ?? '';
      }

      final dangers = JSADangers();
      if (da != null) {
        dangers.chocElectrique = da['chocElectrique'] as bool? ?? false;
        dangers.bruit = da['bruit'] as bool? ?? false;
        dangers.stressThermique = da['stressThermique'] as bool? ?? false;
        dangers.eclairageInadapte = da['eclairageInadapte'] as bool? ?? false;
        dangers.zoneCirculationMalDefinie = da['zoneCirculationMalDefinie'] as bool? ?? false;
        dangers.solAccidente = da['solAccidente'] as bool? ?? false;
        dangers.emissionGazPoussiere = da['emissionGazPoussiere'] as bool? ?? false;
        dangers.espaceConfine = da['espaceConfine'] as bool? ?? false;
        dangers.autreEnvironnement = da['autreEnvironnement'] as String? ?? '';
        dangers.chuteObjets = da['chuteObjets'] as bool? ?? false;
        dangers.coactivite = da['coactivite'] as bool? ?? false;
        dangers.portCharge = da['portCharge'] as bool? ?? false;
        dangers.expositionProduitsChimiques = da['expositionProduitsChimiques'] as bool? ?? false;
        dangers.chuteHauteur = da['chuteHauteur'] as bool? ?? false;
        dangers.electrification = da['electrification'] as bool? ?? false;
        dangers.incendiesExplosion = da['incendiesExplosion'] as bool? ?? false;
        dangers.mauvaisesPostures = da['mauvaisesPostures'] as bool? ?? false;
        dangers.chutePlainPied = da['chutePlainPied'] as bool? ?? false;
        dangers.autrePhysique = da['autrePhysique'] as String? ?? '';
      }

      final exigences = JSAExigencesGenerales();
      if (eg != null) {
        exigences.signaletiqueSecurite = eg['signaletiqueSecurite'] as bool? ?? false;
        exigences.ficheDonneeSecuriteDisponible = eg['ficheDonneeSecuriteDisponible'] as bool? ?? false;
        exigences.uneMinuteMaSecurite = eg['uneMinuteMaSecurite'] as bool? ?? false;
        exigences.balise = eg['balise'] as bool? ?? false;
        exigences.zoneTravailPropre = eg['zoneTravailPropre'] as bool? ?? false;
        exigences.toolboxMeeting = eg['toolboxMeeting'] as bool? ?? false;
        exigences.permisTravail = eg['permisTravail'] as bool? ?? false;
        exigences.extincteurs = eg['extincteurs'] as bool? ?? false;
        exigences.outilsMaterielsIsolants = eg['outilsMaterielsIsolants'] as bool? ?? false;
        exigences.boitePharmacie = eg['boitePharmacie'] as bool? ?? false;
        exigences.autre = eg['autre'] as String? ?? '';
      }

      final epi = JSAEPI();
      if (ep != null) {
        epi.casqueSecurite = ep['casqueSecurite'] as bool? ?? false;
        epi.bouchonsOreille = ep['bouchonsOreille'] as bool? ?? false;
        epi.lunettesProtection = ep['lunettesProtection'] as bool? ?? false;
        epi.harnaisSecurite = ep['harnaisSecurite'] as bool? ?? false;
        epi.chaussureSecurite = ep['chaussureSecurite'] as bool? ?? false;
        epi.masqueSecurite = ep['masqueSecurite'] as bool? ?? false;
        epi.combinaisonLongueManche = ep['combinaisonLongueManche'] as bool? ?? false;
        epi.gantsIsolants = ep['gantsIsolants'] as bool? ?? false;
        epi.cacheNez = ep['cacheNez'] as bool? ?? false;
        epi.gilet = ep['gilet'] as bool? ?? false;
        epi.autre = ep['autre'] as String? ?? '';
      }

      final verif = JSAVerificationFinale();
      if (vf != null) {
        verif.travailTermineNA = vf['travailTermineNA'] as bool? ?? false;
        verif.travailTermineApplicable = vf['travailTermineApplicable'] as bool? ?? false;
        verif.consignationCadenasRetireNA = vf['consignationCadenasRetireNA'] as bool? ?? false;
        verif.consignationCadenasRetireApplicable = vf['consignationCadenasRetireApplicable'] as bool? ?? false;
        verif.absenceConsignataireProcedureNA = vf['absenceConsignataireProcedureNA'] as bool? ?? false;
        verif.absenceConsignataireProcedureApplicable = vf['absenceConsignataireProcedureApplicable'] as bool? ?? false;
        verif.consignataireAbsentProcedureAppliqueeNA = vf['consignataireAbsentProcedureAppliqueeNA'] as bool? ?? false;
        verif.consignataireAbsentProcedureAppliqueeApplicable = vf['consignataireAbsentProcedureAppliqueeApplicable'] as bool? ?? false;
        verif.materielEnleveZoneNettoyeeNA = vf['materielEnleveZoneNettoyeeNA'] as bool? ?? false;
        verif.materielEnleveZoneNettoyeeApplicable = vf['materielEnleveZoneNettoyeeApplicable'] as bool? ?? false;
        verif.risquesSupprimesEquipementPretNA = vf['risquesSupprimesEquipementPretNA'] as bool? ?? false;
        verif.risquesSupprimesEquipementPretApplicable = vf['risquesSupprimesEquipementPretApplicable'] as bool? ?? false;
        verif.autresPoints = vf['autresPoints'] as String? ?? '';
        verif.donneurOrdreSignature = vf['donneurOrdreSignature'] as String? ?? '';
        verif.chargeAffairesSignature = vf['chargeAffairesSignature'] as String? ?? '';
      }

      final jsa = JSA(
        missionId: missionId,
        operationEffectuer: d['operationEffectuer'] as String? ?? '',
        updatedAt: _dt(d['updatedAt']),
        currentSubCategory: d['currentSubCategory'] as int? ?? 0,
        inspecteurs: (d['inspecteurs'] as List<dynamic>?)?.map((i) {
          final m = i as Map<String, dynamic>;
          return JSAInspecteur(
            nom: m['nom'] as String? ?? '',
            prenom: m['prenom'] as String? ?? '',
            signature: m['signature'] as String? ?? '',
            matricule: m['matricule'] as String?,
            email: m['email'] as String?,
            role: m['role'] as String?,
          );
        }).toList() ?? [],
        planUrgence: planUrgence,
        dangers: dangers,
        exigencesGenerales: exigences,
        epi: epi,
        verificationFinale: verif,
      );
      await box.add(jsa);
    } catch (e) {
      if (kDebugMode) print('⚠️ JSA import: $e');
    }
  }

  // ── Renseignements généraux ──
  static Future<void> _importRenseignements(Map<String, dynamic> d, {bool ecraser = false}) async {
    try {
      final missionId = d['missionId'] as String;
      final box =
          Hive.box<RenseignementsGeneraux>('renseignements_generaux');
      final existingKeys = box.values
          .where((r) => r.missionId == missionId)
          .map((r) => r.key)
          .toList();
      if (existingKeys.isNotEmpty) {
        if (!ecraser) return;
        for (final k in existingKeys) {
          await box.delete(k);
        }
      }
      final rens = RenseignementsGeneraux(
        missionId: missionId,
        etablissement: d['etablissement'] as String? ?? '',
        installation: d['installation'] as String? ?? '',
        activite: d['activite'] as String? ?? '',
        dateDebut: d['dateDebut'] != null
            ? DateTime.tryParse(d['dateDebut'] as String)
            : null,
        dateFin: d['dateFin'] != null
            ? DateTime.tryParse(d['dateFin'] as String)
            : null,
        dureeJours: d['dureeJours'] as int? ?? 0,
        verificationType: d['verificationType'] as String?,
        registreControle: d['registreControle'] as String? ?? '',
        compteRendu: _strList(d['compteRendu']),
        accompagnateurs: (d['accompagnateurs'] as List<dynamic>?)
                ?.map((e) => Map<String, String>.from(e as Map))
                .toList() ??
            [],
        verificateurs: (d['verificateurs'] as List<dynamic>?)
                ?.map((e) => Map<String, String>.from(e as Map))
                .toList() ??
            [],
        nomSite: d['nomSite'] as String? ?? '',
        updatedAt: _dt(d['updatedAt']),
        formationHabilitationElectrique:
            d['formationHabilitationElectrique'] as String?,
        createdAt: d['createdAt'] != null
            ? DateTime.tryParse(d['createdAt'] as String)
            : null,
        activiteSurSite: d['activiteSurSite'] as String?,
        classementReglementaire: d['classementReglementaire'] as String?,
        classementReglementaireType: d['classementReglementaireType'] as String?,
        classementReglementaireCategorie: d['classementReglementaireCategorie'] as String?,
      );
      await box.add(rens);
    } catch (e) {
      if (kDebugMode) print('⚠️ Renseignements import: $e');
    }
  }

  // ── Foudre ──
  static Future<void> _importFoudre(Map<String, dynamic> d, {bool ecraser = false}) async {
    try {
      final foudre = Foudre.fromJson(d);
      final box = Hive.box<Foudre>('foudre_observations');
      if (!ecraser) {
        final exists = box.values.any((f) =>
            f.missionId == foudre.missionId &&
            f.observation == foudre.observation);
        if (exists) return;
      }
      await box.add(foudre);
    } catch (e) {
      if (kDebugMode) print('⚠️ Foudre import: $e');
    }
  }

  // ── Inspection d'éclairage ──
  static Future<void> _importLightingInspection(Map<String, dynamic> d, {bool ecraser = false}) async {
    try {
      final item = LightingInspection.fromJson(d);
      final box = Hive.box<LightingInspection>('lighting_inspections');
      if (box.containsKey(item.id) && !ecraser) return;
      await box.put(item.id, item);
    } catch (e) {
      if (kDebugMode) print('⚠️ LightingInspection import: $e');
    }
  }

  // ── Classements ──
  static Future<void> _importClassement(Map<String, dynamic> d) async {
    try {
      final box = Hive.box<ClassementEmplacement>('classement_locaux');
      final missionId = d['missionId'] as String? ?? '';
      final localisation = d['localisation'] as String? ?? '';
      // Anti-doublon : ne pas réinsérer si déjà présent
      final existe = box.values.any(
          (c) => c.missionId == missionId && c.localisation == localisation);
      if (existe) return;

      await box.add(ClassementEmplacement(
        missionId: d['missionId'] as String? ?? '',
        localisation: d['localisation'] as String? ?? '',
        zone: d['zone'] as String?,
        origineClassement:
            d['origineClassement'] as String? ?? 'KES I&P',
        af: d['af'] as String?,
        be: d['be'] as String?,
        ae: d['ae'] as String?,
        ad: d['ad'] as String?,
        ag: d['ag'] as String?,
        ip: d['ip'] as String?,
        ik: d['ik'] as String?,
        updatedAt: _dt(d['updatedAt']),
        typeLocal: d['typeLocal'] as String?,
        typeEmplacement: d['typeEmplacement'] as String? ?? 'local',
        heriteDeZone: d['heriteDeZone'] as bool? ?? false,
        zoneParenteId: d['zoneParenteId'] as String?,
      ));
    } catch (e) {
      if (kDebugMode) print('⚠️ Classement import: $e');
    }
  }

  static Future<void> _importClassementZone(Map<String, dynamic> d) async {
    try {
      final box = Hive.box<ClassementZone>('classement_zones');
      final missionId = d['missionId'] as String? ?? '';
      final nomZone = d['nomZone'] as String? ?? '';
      // Anti-doublon : ne pas réinsérer si déjà présent
      final existe = box.values
          .any((c) => c.missionId == missionId && c.nomZone == nomZone);
      if (existe) return;
      await box.add(ClassementZone(
        missionId: d['missionId'] as String? ?? '',
        nomZone: d['nomZone'] as String? ?? '',
        origineClassement:
            d['origineClassement'] as String? ?? 'KES I&P',
        typeZone: d['typeZone'] as String? ?? 'BT',
        af: d['af'] as String?,
        be: d['be'] as String?,
        ae: d['ae'] as String?,
        ad: d['ad'] as String?,
        ag: d['ag'] as String?,
        ip: d['ip'] as String?,
        ik: d['ik'] as String?,
        updatedAt: _dt(d['updatedAt']),
      ));
    } catch (e) {
      if (kDebugMode) print('⚠️ ClassementZone import: $e');
    }
  }

  // ── Brouillons locaux ──
  static Future<void> _importLocalDrafts(
    List<dynamic> drafts, {
    required bool ecraser,
  }) async {
    final box = Hive.box('local_drafts');
    for (final draft in drafts) {
      try {
        final d = draft as Map<String, dynamic>;
        final key = d['key'] as String?;
        if (key == null) continue;
        if (box.containsKey(key) && !ecraser) continue;
        final localData = d['local'] as Map<String, dynamic>?;
        if (localData == null) continue;
        final localClass = d['localClass'] as String? ?? 'MT';
        final localObj = localClass == 'MT'
            ? _parseMTLocal(localData)
            : _parseBTLocal(localData);
        await box.put(key, {
          'local': localObj,
          'currentStep': d['currentStep'],
          'missionId': d['missionId'],
          'isMoyenneTension': d['isMoyenneTension'],
          'zoneIndex': d['zoneIndex'],
          'isInZone': d['isInZone'],
          'localType': d['localType'],
          'nomLocal': d['nomLocal'],
          'savedAt': d['savedAt'],
          'localId': key,
        });
      } catch (e) {
        if (kDebugMode) print('⚠️ Draft local import: $e');
      }
    }
  }

  // ── Brouillons coffrets ──
  static Future<void> _importCoffretDrafts(
    List<dynamic> drafts, {
    required bool ecraser,
  }) async {
    final box = Hive.box('coffret_drafts');
    for (final draft in drafts) {
      try {
        final d = draft as Map<String, dynamic>;
        final key = d['key'] as String?;
        if (key == null) continue;
        if (box.containsKey(key) && !ecraser) continue;
        final coffretData = d['coffret'] as Map<String, dynamic>?;
        if (coffretData == null) continue;
        final coffrets = _parseCoffrets([coffretData]);
        if (coffrets.isEmpty) continue;
        await box.put(key, {
          'coffret': coffrets.first,
          'missionId': d['missionId'],
          'parentType': d['parentType'],
          'parentIndex': d['parentIndex'],
          'isMoyenneTension': d['isMoyenneTension'],
          'zoneIndex': d['zoneIndex'],
          'savedAt': d['savedAt'],
        });
      } catch (e) {
        if (kDebugMode) print('⚠️ Draft coffret import: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // UTILITAIRES
  // ─────────────────────────────────────────────────────────

  static List<String> _strList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) => e as String).toList();
  }

  static DateTime _dt(dynamic raw) {
    if (raw == null) return DateTime.now();
    try {
      return DateTime.parse(raw as String);
    } catch (_) {
      return DateTime.now();
    }
  }



  // ── Sérialiser toutes les photos d'une mission en base64 ──
  // ── Collecter tous les chemins photos d'un audit ──
  static List<String> _collectAllPhotoPaths(AuditInstallationsElectriques a) {
    final paths = <String>{};

    void addPhotos(List<String> p) => paths.addAll(p.where((x) => x.isNotEmpty));
    void addElement(ElementControle e) => addPhotos(e.photos);
    void addObs(List<ObservationLibre> obs) {
      for (final o in obs) addPhotos(o.photos);
    }
    void addCoffret(CoffretArmoire c) {
      addPhotos(c.photos);
      addPhotos(c.photosExternes);
      addPhotos(c.photosInternes);
      addObs(c.observationsLibres);
      addObs(c.observationsParafoudre);
      if (c.observationsParafoudreEnrichies != null) {
        c.observationsParafoudreEnrichies!.forEach(addElement);
      }
      for (final p in c.pointsVerification) {
        addPhotos(p.photos);
        if (p.observations != null) {
          p.observations!.forEach(addElement);
        }
      }
      for (final al in c.alimentations) addPhotos(al.photos);
      if (c.protectionTete != null) addPhotos(c.protectionTete!.photos);
    }
    void addMTLocal(MoyenneTensionLocal l) {
      addPhotos(l.photos);
      addObs(l.observationsLibres);
      l.dispositionsConstructives.forEach(addElement);
      l.conditionsExploitation.forEach(addElement);
      for (final c in l.coffrets) addCoffret(c);
      for (final cell in l.cellules) {
        addPhotos(cell.photos);
        if (cell.photo != null && cell.photo!.isNotEmpty) paths.add(cell.photo!);
        cell.elementsVerifies.forEach(addElement);
        if (cell.observations != null) cell.observations!.forEach(addElement);
      }
      for (final t in l.transformateurs) {
        addPhotos(t.photos);
        if (t.photo != null && t.photo!.isNotEmpty) paths.add(t.photo!);
        t.elementsVerifies.forEach(addElement);
        if (t.observations != null) t.observations!.forEach(addElement);
      }
    }
    void addBTLocal(BasseTensionLocal l) {
      addPhotos(l.photos);
      addObs(l.observationsLibres);
      (l.dispositionsConstructives ?? []).forEach(addElement);
      (l.conditionsExploitation ?? []).forEach(addElement);
      for (final c in l.coffrets) addCoffret(c);
      for (final cell in l.cellules) {
        addPhotos(cell.photos);
        if (cell.photo != null && cell.photo!.isNotEmpty) paths.add(cell.photo!);
        cell.elementsVerifies.forEach(addElement);
        if (cell.observations != null) cell.observations!.forEach(addElement);
      }
      for (final t in l.transformateurs) {
        addPhotos(t.photos);
        if (t.photo != null && t.photo!.isNotEmpty) paths.add(t.photo!);
        t.elementsVerifies.forEach(addElement);
        if (t.observations != null) t.observations!.forEach(addElement);
      }
    }

    addPhotos(a.photos);
    for (final l in a.moyenneTensionLocaux) addMTLocal(l);
    for (final z in a.moyenneTensionZones) {
      addPhotos(z.photos);
      addObs(z.observationsLibres);
      for (final c in z.coffrets) addCoffret(c);
      for (final l in z.locaux) addMTLocal(l);
    }
    for (final z in a.basseTensionZones) {
      addPhotos(z.photos);
      addObs(z.observationsLibres);
      for (final c in z.coffretsDirects) addCoffret(c);
      for (final l in z.locaux) addBTLocal(l);
    }
    return paths.toList();
  }

  // ── Encoder les photos en base64 ──
  static Future<Map<String, String>> _exportPhotos(List<String> paths) async {
    final result = <String, String>{};
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          result[path] = base64Encode(bytes);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Photo ignorée: $path — $e');
      }
    }
    return result;
  }

  // ── HELPER DE CONVERSION ET PARSING SÉCURISÉ (DÉFENSIF) ──

  static Map<String, dynamic> _safeMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      final res = <String, dynamic>{};
      v.forEach((k, val) => res[k.toString()] = val);
      return res;
    }
    return <String, dynamic>{};
  }

  static List<dynamic> _safeList(dynamic v) {
    if (v is List) return v;
    return <dynamic>[];
  }

  static String _safeString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  static int _safeInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double _safeDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool _safeBool(dynamic v, [bool fallback = false]) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    if (v is num) return v != 0;
    return fallback;
  }

  // ── Restaurer les photos depuis base64 ──
  static Future<List<String>> _restorePhotos(
    Map<String, dynamic> photosMap, {
    void Function(String stage, double progress)? onProgress,
    int missionIndex = 0,
    int totalMissions = 1,
  }) async {
    final createdPaths = <String>[];
    final appDir = await getApplicationDocumentsDirectory();
    final totalPhotos = photosMap.length;
    int processed = 0;

    final keys = photosMap.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      final originalPath = _safeString(keys[i]);
      final b64 = _safeString(photosMap[originalPath]);
      photosMap[originalPath] = null; // Libération immédiate de la chaîne Base64 en RAM

      if (originalPath.isNotEmpty && b64.isNotEmpty) {
        try {
          final normalizedPath = originalPath.replaceAll('\\', '/');
          final fileName = normalizedPath.split('/').last;
          String subDir = 'misc';
          final parts = normalizedPath.split('/');
          final idx = parts.indexOf('audit_photos');
          if (idx != -1 && idx + 2 < parts.length) {
            subDir = parts[idx + 1];
          }
          final dir = Directory('${appDir.path}/audit_photos/$subDir');
          if (!dir.existsSync()) dir.createSync(recursive: true);
          final newFile = File('${dir.path}/$fileName');
          if (!newFile.existsSync()) {
            newFile.writeAsBytesSync(base64Decode(b64));
            createdPaths.add(newFile.path);
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ Restauration photo: $originalPath — $e');
        }
      }

      processed++;
      if (processed % 15 == 0 || processed == totalPhotos) {
        // Purge régulière du cache d'images Flutter/Skia pour éviter l'accumulation en RAM GPU/Heap
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        if (totalPhotos > 0) {
          final prg = 0.30 + (processed / totalPhotos) * 0.55;
          final pct = ((processed / totalPhotos) * 100).toInt();
          onProgress?.call('Restauration des photos : $processed / $totalPhotos ($pct%)', prg);
        }
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }
    photosMap.clear();
    return createdPaths;
  }

  // ── Rollback atomique d'une mission en cas d'échec d'import ──
  static Future<void> _rollbackMission(String missionId, List<String> createdPhotoPaths) async {
    if (kDebugMode) print('🔄 Rollback de l\'import pour la mission: $missionId');

    // 1. Nettoyer les boxes Hive liées
    Future<void> cleanBox<T>(String boxName, bool Function(T) predicate) async {
      try {
        final box = Hive.box<T>(boxName);
        final toDelete = box.values.where(predicate).map((e) => (e as dynamic).key).toList();
        for (final k in toDelete) {
          await box.delete(k);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Rollback cleanBox $boxName: $e');
      }
    }

    await cleanBox<AuditInstallationsElectriques>('audit_installations_electriques', (a) => a.missionId == missionId);
    await cleanBox<DescriptionInstallations>('description_installations', (d) => d.missionId == missionId);
    await cleanBox<ClassementEmplacement>('classement_locaux', (c) => c.missionId == missionId);
    await cleanBox<ClassementZone>('classement_zones', (z) => z.missionId == missionId);
    await cleanBox<Foudre>('foudre_observations', (f) => f.missionId == missionId);
    await cleanBox<MesuresEssais>('mesures_essais', (m) => m.missionId == missionId);
    await cleanBox<JSA>('jsa', (j) => j.missionId == missionId);
    await cleanBox<RenseignementsGeneraux>('renseignements_generaux', (r) => r.missionId == missionId);
    await cleanBox<LightingInspection>('lighting_inspections', (l) => l.missionId == missionId);

    // Brouillons
    try {
      final coffretDraftsBox = Hive.box('coffret_drafts');
      final coffretKeys = coffretDraftsBox.keys.where((k) {
        final data = coffretDraftsBox.get(k);
        return data is Map && data['missionId'] == missionId;
      }).toList();
      for (final k in coffretKeys) await coffretDraftsBox.delete(k);
    } catch (_) {}

    try {
      final localDraftsBox = Hive.box('local_drafts');
      final localKeys = localDraftsBox.keys.where((k) {
        final data = localDraftsBox.get(k);
        return data is Map && data['missionId'] == missionId;
      }).toList();
      for (final k in localKeys) await localDraftsBox.delete(k);
    } catch (_) {}

    try {
      final progressBox = Hive.box('mission_progress');
      if (progressBox.containsKey(missionId)) {
        await progressBox.delete(missionId);
      }
    } catch (_) {}

    // Supprimer la mission elle-même
    try {
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.delete(missionId);
    } catch (_) {}

    // 2. Nettoyer les fichiers physiques de photos spécifiquement créés pour cet import
    for (final path in createdPhotoPaths) {
      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Rollback photo: $path — $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // SUPPRESSION COMPLÈTE D'UNE MISSION — utilisé par MissionCard
  // ─────────────────────────────────────────────────────────

  /// Supprime une mission et TOUTES ses données associées de façon atomique.
  /// Nettoie : toutes les boxes Hive + photos disque + brouillons + rapports.
  /// Aucune donnée orpheline ne subsiste après l'appel.
  static Future<DeleteResult> deleteMissionCompletely(
      String missionId) async {
    int deletedPhotos = 0;

    try {
      // ── 1. Collecter les chemins photos AVANT suppression ─────────
      final allPhotoPaths = <String>{};
      final missionBox = Hive.box<Mission>('missions');
      final mission = missionBox.get(missionId);
      if (mission != null) {
        if (mission.logoClient != null && mission.logoClient!.trim().isNotEmpty) {
          allPhotoPaths.add(mission.logoClient!.trim());
        }
        if (mission.qrCodeClient != null && mission.qrCodeClient!.trim().isNotEmpty) {
          allPhotoPaths.add(mission.qrCodeClient!.trim());
        }
        if (mission.qrCodeQ18 != null && mission.qrCodeQ18!.trim().isNotEmpty) {
          allPhotoPaths.add(mission.qrCodeQ18!.trim());
        }
      }

      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      if (audit != null) {
        allPhotoPaths.addAll(_collectAllPhotoPaths(audit));
      }

      final desc = HiveService.getDescriptionInstallationsByMissionId(missionId);
      if (desc != null) {
        for (final item in [
          ...desc.alimentationMoyenneTension,
          ...desc.alimentationBasseTension,
          ...desc.groupeElectrogene,
          ...desc.alimentationCarburant,
          ...desc.inverseur,
          ...desc.stabilisateur,
          ...desc.onduleurs,
          ...desc.cpi,
        ]) {
          allPhotoPaths.addAll(item.photoPaths.where((p) => p.isNotEmpty));
        }
        for (final obs in desc.foudreObservations) {
          allPhotoPaths.addAll(obs.photos.where((p) => p.isNotEmpty));
        }
      }

      final mesures = HiveService.getMesuresEssaisByMissionId(missionId);
      if (mesures != null) {
        for (final pt in mesures.prisesTerre) {
          if (pt.photo != null && pt.photo!.isNotEmpty) {
            allPhotoPaths.add(pt.photo!);
          }
        }
      }

      final lightingBox = Hive.box<LightingInspection>('lighting_inspections');
      for (final l in lightingBox.values.where((l) => l.missionId == missionId)) {
        for (final ncl in l.nonConformingLuminaires) {
          for (final ans in ncl.answers) {
            allPhotoPaths.addAll(ans.photoPaths.where((p) => p.isNotEmpty));
          }
        }
      }

      // ── 2. Supprimer toutes les boxes Hive liées ──────────────────
      Future<void> cleanBox<T>(String boxName,
          bool Function(T) predicate) async {
        try {
          final box = Hive.box<T>(boxName);
          final toDelete =
              box.values.where(predicate).map((e) => (e as dynamic).key).toList();
          for (final k in toDelete) {
            await box.delete(k);
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ cleanBox $boxName: $e');
        }
      }

      await cleanBox<AuditInstallationsElectriques>(
          'audit_installations_electriques',
          (a) => a.missionId == missionId);
      await cleanBox<DescriptionInstallations>(
          'description_installations',
          (d) => d.missionId == missionId);
      await cleanBox<ClassementEmplacement>(
          'classement_locaux',
          (c) => c.missionId == missionId);
      await cleanBox<ClassementZone>(
          'classement_zones',
          (z) => z.missionId == missionId);
      await cleanBox<Foudre>(
          'foudre_observations',
          (f) => f.missionId == missionId);
      await cleanBox<MesuresEssais>(
          'mesures_essais',
          (m) => m.missionId == missionId);
      await cleanBox<JSA>(
          'jsa',
          (j) => j.missionId == missionId);
      await cleanBox<RenseignementsGeneraux>(
          'renseignements_generaux',
          (r) => r.missionId == missionId);
      await cleanBox<LightingInspection>(
          'lighting_inspections',
          (l) => l.missionId == missionId);

      // Brouillons coffrets
      try {
        final coffretDraftsBox = Hive.box('coffret_drafts');
        final coffretKeys = coffretDraftsBox.keys.where((k) {
          final data = coffretDraftsBox.get(k);
          return data is Map && data['missionId'] == missionId;
        }).toList();
        for (final k in coffretKeys) {
          await coffretDraftsBox.delete(k);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ coffret_drafts delete: $e');
      }

      // Brouillons locaux
      try {
        final localDraftsBox = Hive.box('local_drafts');
        final localKeys = localDraftsBox.keys.where((k) {
          final data = localDraftsBox.get(k);
          return data is Map && data['missionId'] == missionId;
        }).toList();
        for (final k in localKeys) {
          await localDraftsBox.delete(k);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ local_drafts delete: $e');
      }

      // Rapports générés
      try {
        final lastReportBox = Hive.box('last_reports');
        if (lastReportBox.containsKey(missionId)) {
          await lastReportBox.delete(missionId);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ last_reports delete: $e');
      }

      // ── 3. Supprimer la mission elle-même ─────────────────────────
      await missionBox.delete(missionId);

      // ── 4. Supprimer les photos du disque ─────────────────────────
      for (final path in allPhotoPaths) {
        try {
          final f = File(path);
          if (await f.exists()) {
            await f.delete();
            deletedPhotos++;
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ Photo non supprimée: $path — $e');
        }
      }

      if (kDebugMode) {
        print(
            '✅ Mission $missionId supprimée. Photos: $deletedPhotos');
      }

      return DeleteResult(
        success: true,
        message:
            'Mission supprimée avec succès ($deletedPhotos photo(s) effacée(s)).',
        deletedPhotos: deletedPhotos,
      );
    } catch (e, st) {
      if (kDebugMode) print('❌ deleteMissionCompletely: $e\n$st');
      return DeleteResult(
        success: false,
        message: 'Erreur lors de la suppression : ${e.toString()}',
        deletedPhotos: deletedPhotos,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// STRUCTURE DE PARAMÈTRES POUR L'ISOLATE D'EXPORT STREAMING
// ─────────────────────────────────────────────────────────────

class ExportParams {
  final String filePath;
  final String magic;
  final int schemaVersion;
  final String exportedAt;
  final String appVersion;
  final String exportType;
  final String? matricule;
  final List<Map<String, dynamic>> missionsData;
  final List<Map<String, dynamic>> localDrafts;
  final List<Map<String, dynamic>> coffretDrafts;

  ExportParams({
    required this.filePath,
    required this.magic,
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.exportType,
    this.matricule,
    required this.missionsData,
    required this.localDrafts,
    required this.coffretDrafts,
  });
}

// Classe sink simple pour accumuler la valeur de hachage finale
class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

// Function Isolate globale (ou top-level/static) exécutant l'écriture progressive
Future<void> _performStreamingExport(ExportParams params) async {
  final file = File(params.filePath);
  if (file.existsSync()) {
    file.deleteSync();
  }
  final sink = file.openWrite(encoding: utf8);
  
  final digestSink = _DigestSink();
  final hashInput = sha256.startChunkedConversion(digestSink);

  // Helper pour écrire et hasher en même temps
  void writeChunk(String chunk) {
    sink.write(chunk);
    hashInput.add(utf8.encode(chunk));
  }

  // 1. Début du payload
  writeChunk('{');
  writeChunk('"magic":${jsonEncode(params.magic)},');
  writeChunk('"schema_version":${params.schemaVersion},');
  writeChunk('"exported_at":${jsonEncode(params.exportedAt)},');
  writeChunk('"app_version":${jsonEncode(params.appVersion)},');
  writeChunk('"export_type":${jsonEncode(params.exportType)},');
  if (params.matricule != null) {
    writeChunk('"matricule":${jsonEncode(params.matricule)},');
  }
  writeChunk('"mission_count":${params.missionsData.length},');
  
  // 2. Début des missions
  writeChunk('"missions":[');
  
  for (int i = 0; i < params.missionsData.length; i++) {
    if (i > 0) writeChunk(',');
    final mData = params.missionsData[i];
    
    // Début de l'objet mission
    writeChunk('{');
    
    // a. mission metadata
    writeChunk('"mission":${jsonEncode(mData['mission'])},');
    
    // b. photos list (progressive)
    final photoPaths = List<String>.from(mData['photo_paths'] ?? []);
    writeChunk('"photo_count":${photoPaths.length},');
    writeChunk('"photos":{');
    
    for (int j = 0; j < photoPaths.length; j++) {
      if (j > 0) writeChunk(',');
      final path = photoPaths[j];
      final photoFile = File(path);
      String base64Content = '';
      if (photoFile.existsSync()) {
        final bytes = photoFile.readAsBytesSync();
        base64Content = base64Encode(bytes);
      }
      writeChunk('${jsonEncode(path)}:${jsonEncode(base64Content)}');
    }
    writeChunk('},'); // fin de "photos"
    
    // c. audit
    writeChunk('"audit":${jsonEncode(mData['audit'])},');
    
    // d. autres tables
    writeChunk('"description_installations":${jsonEncode(mData['description_installations'])},');
    writeChunk('"mesures_essais":${jsonEncode(mData['mesures_essais'])},');
    writeChunk('"jsa":${jsonEncode(mData['jsa'])},');
    writeChunk('"renseignements_generaux":${jsonEncode(mData['renseignements_generaux'])},');
    writeChunk('"foudre_observations":${jsonEncode(mData['foudre_observations'])},');
    writeChunk('"classements_locaux":${jsonEncode(mData['classements_locaux'])},');
    writeChunk('"classements_zones":${jsonEncode(mData['classements_zones'])},');
    writeChunk('"sequence_progress":${jsonEncode(mData['sequence_progress'])}');
    
    writeChunk('}'); // fin de l'objet mission
  }
  writeChunk('],'); // fin de "missions"
  
  // 3. Drafts
  writeChunk('"local_drafts":${jsonEncode(params.localDrafts)},');
  writeChunk('"coffret_drafts":${jsonEncode(params.coffretDrafts)}');
  
  // 4. Fermeture de l'accumulateur SHA-256 (calculé sur tout le payload sans la clé checksum)
  hashInput.close();
  final checksum = digestSink.value.toString();
  
  // 5. Ajout du checksum et accolade de fermeture finale
  sink.write(',"checksum":${jsonEncode(checksum)}');
  sink.write('}');
  
  await sink.flush();
  await sink.close();
}