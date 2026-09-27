// lib/services/file_storage_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';

class FileStorageService {
  static const String reportFolderName = 'Verif Elec';
  
  /// Récupérer le dossier de destination des rapports
  static Future<Directory> getReportsDirectory() async {
    Directory targetDir;
    
    try {
      // Pour Android, utiliser ExternalPath
      if (Platform.isAndroid) {
        final downloadsPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOAD
        );
        targetDir = Directory('$downloadsPath/$reportFolderName');
      } 
      // Pour iOS ou fallback
      else {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          targetDir = Directory('${downloadsDir.path}/$reportFolderName');
        } else {
          final documentsDir = await getApplicationDocumentsDirectory();
          targetDir = Directory('${documentsDir.path}/$reportFolderName');
        }
      }
    } catch (e) {
      // Fallback ultime
      final appDir = await getApplicationDocumentsDirectory();
      targetDir = Directory('${appDir.path}/$reportFolderName');
    }
    
    // Créer le dossier s'il n'existe pas
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
      if (kDebugMode) {
        print('✅ Dossier créé: ${targetDir.path}');
      }
    }
    
    return targetDir;
  }
  
  /// Sauvegarder un rapport dans le dossier dédié
  static Future<File> saveReport(File sourceFile, String fileName) async {
    final reportsDir = await getReportsDirectory();
    final destinationFile = File('${reportsDir.path}/$fileName');
    
    // Copier le fichier (écrase s'il existe déjà)
    await sourceFile.copy(destinationFile.path);
    if (kDebugMode) {
      if (kDebugMode) {
        print('✅ Rapport sauvegardé: ${destinationFile.path}');
      }
    }
    
    return destinationFile;
  }
  
  /// Récupérer tous les rapports d'une mission
  static Future<List<File>> getReportsForMission(String missionId) async {
    final reportsDir = await getReportsDirectory();
    if (!await reportsDir.exists()) return [];

    final files = await reportsDir.list().toList();

    return files
        .whereType<File>()
        .where((file) => file.path.contains(missionId))
        .toList();
  }

  /// Sauvegarder le logo d'un client de façon permanente pour une mission
  static Future<File> saveClientLogo(String missionId, File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final logosDir = Directory('${appDir.path}/client_logos');
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }

    // Nettoyer les anciens logos enregistrés pour cette mission
    try {
      if (await logosDir.exists()) {
        final existingFiles = logosDir.listSync();
        for (final f in existingFiles) {
          if (f is File && f.path.contains('logo_$missionId')) {
            await f.delete();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Nettoyage ancien logo: $e');
    }

    final ext = sourceFile.path.contains('.')
        ? sourceFile.path.split('.').last
        : 'png';
    final destinationFile = File(
        '${logosDir.path}/logo_${missionId}_${DateTime.now().millisecondsSinceEpoch}.$ext');

    await sourceFile.copy(destinationFile.path);
    if (kDebugMode) print('✅ Logo client sauvegardé: ${destinationFile.path}');
    return destinationFile;
  }

  /// Supprimer le logo d'un client
  static Future<void> deleteClientLogo(String logoPath) async {
    try {
      final file = File(logoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) print('Erreur suppression logo client: $e');
    }
  }

  /// Sauvegarder le QR Code d'un client / de la mission
  static Future<File> saveClientQrCode(String missionId, File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final qrDir = Directory('${appDir.path}/client_qrcodes');
    if (!await qrDir.exists()) {
      await qrDir.create(recursive: true);
    }

    // Nettoyer les anciens QR codes enregistrés pour cette mission
    try {
      if (await qrDir.exists()) {
        final existingFiles = qrDir.listSync();
        for (final f in existingFiles) {
          if (f is File && f.path.contains('qrcode_$missionId')) {
            await f.delete();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Nettoyage ancien QR Code: $e');
    }

    final ext = sourceFile.path.contains('.')
        ? sourceFile.path.split('.').last
        : 'png';
    final destinationFile = File(
        '${qrDir.path}/qrcode_${missionId}_${DateTime.now().millisecondsSinceEpoch}.$ext');

    await sourceFile.copy(destinationFile.path);
    if (kDebugMode) print('✅ QR Code client sauvegardé: ${destinationFile.path}');
    return destinationFile;
  }

  /// Supprimer le QR Code d'un client
  static Future<void> deleteClientQrCode(String qrCodePath) async {
    try {
      final file = File(qrCodePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) print('Erreur suppression QR Code client: $e');
    }
  }

  /// Sauvegarder le QR Code du rapport Q18 (APSAD D18)
  static Future<File> saveQ18QrCode(String missionId, File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final qrDir = Directory('${appDir.path}/q18_qrcodes');
    if (!await qrDir.exists()) {
      await qrDir.create(recursive: true);
    }

    // Nettoyer les anciens QR codes Q18 enregistrés pour cette mission
    try {
      if (await qrDir.exists()) {
        final existingFiles = qrDir.listSync();
        for (final f in existingFiles) {
          if (f is File && f.path.contains('qrcode_q18_$missionId')) {
            await f.delete();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Nettoyage ancien QR Code Q18: $e');
    }

    final ext = sourceFile.path.contains('.')
        ? sourceFile.path.split('.').last
        : 'png';
    final destinationFile = File(
        '${qrDir.path}/qrcode_q18_${missionId}_${DateTime.now().millisecondsSinceEpoch}.$ext');

    await sourceFile.copy(destinationFile.path);
    if (kDebugMode) print('✅ QR Code Q18 sauvegardé: ${destinationFile.path}');
    return destinationFile;
  }

  /// Supprimer le QR Code Q18
  static Future<void> deleteQ18QrCode(String qrCodePath) async {
    try {
      final file = File(qrCodePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) print('Erreur suppression QR Code Q18: $e');
    }
  }
}