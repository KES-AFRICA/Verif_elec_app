import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';
import 'package:inspec_app/services/hive_service.dart';

/// Service centralisé de synchronisation entre l'Audit des Installations 
/// (Cellules MT et Transformateurs MT/BT) et la Description des Installations.
class InstallationDescriptionSyncService {
  static const String _auditBox = 'audit_installations_electriques';

  /// Normalisation intelligente des clés (accents, casse, séparateurs)
  static String normalizeKey(String key) => InstallationFieldsRegistry.normalizeKey(key);

  /// Dictionnaire d'alias pour les champs de Cellules MT
  static final Map<String, String> _celluleAliases = {
    normalizeKey(InstallationFieldsRegistry.keyGammeCellule): InstallationFieldsRegistry.keyGammeCellule,
    normalizeKey('Gamme'): InstallationFieldsRegistry.keyGammeCellule,
    normalizeKey('Gamme de la cellule'): InstallationFieldsRegistry.keyGammeCellule,
    normalizeKey(InstallationFieldsRegistry.keyTypeCellule): InstallationFieldsRegistry.keyTypeCellule,
    normalizeKey('TYPE DE CELLULE'): InstallationFieldsRegistry.keyTypeCellule,
    normalizeKey('Type'): InstallationFieldsRegistry.keyTypeCellule,
    normalizeKey('Type de cellule'): InstallationFieldsRegistry.keyTypeCellule,
    normalizeKey(InstallationFieldsRegistry.keyTensionAssignee): InstallationFieldsRegistry.keyTensionAssigneeMT,
    normalizeKey(InstallationFieldsRegistry.keyTensionAssigneeMT): InstallationFieldsRegistry.keyTensionAssigneeMT,
    normalizeKey('Tension assignée (kV)'): InstallationFieldsRegistry.keyTensionAssigneeMT,
    normalizeKey(InstallationFieldsRegistry.keyTensionDeServiceMT): InstallationFieldsRegistry.keyTensionDeServiceMT,
    normalizeKey('Tension de service'): InstallationFieldsRegistry.keyTensionDeServiceMT,
    normalizeKey('TENSION DE SERVICE (kV)'): InstallationFieldsRegistry.keyTensionDeServiceMT,
    normalizeKey('Tension de service (kV)'): InstallationFieldsRegistry.keyTensionDeServiceMT,
    normalizeKey(InstallationFieldsRegistry.keyPouvoirCoupure): InstallationFieldsRegistry.keyPouvoirCoupure,
    normalizeKey('POUVOIR DE COUPURE ASSIGNE(KA)'): InstallationFieldsRegistry.keyPouvoirCoupure,
    normalizeKey('Pouvoir de coupure assigné (kA)'): InstallationFieldsRegistry.keyPouvoirCoupure,
    normalizeKey(InstallationFieldsRegistry.keyCalibreDisjoncteurMT): InstallationFieldsRegistry.keyCalibreDisjoncteurMT,
    normalizeKey('Calibre disjoncteur'): InstallationFieldsRegistry.keyCalibreDisjoncteurMT,
    normalizeKey('Calibre'): InstallationFieldsRegistry.keyCalibreDisjoncteurMT,
    normalizeKey(InstallationFieldsRegistry.keySectionCableMT): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey('SECTION DU CABLE(mm2)'): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey('SECTION DU CABLE (mm²)'): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey('Section cable'): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey('Section des cables'): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey(InstallationFieldsRegistry.keyNatureReseau): InstallationFieldsRegistry.keyNatureReseau,
    normalizeKey('NATURE DU RESEAU'): InstallationFieldsRegistry.keyNatureReseau,
    normalizeKey('Nature reseau'): InstallationFieldsRegistry.keyNatureReseau,
    normalizeKey(InstallationFieldsRegistry.keyPresenceIacm): InstallationFieldsRegistry.keyPresenceIacm,
    normalizeKey('Presence IACM'): InstallationFieldsRegistry.keyPresenceIacm,
    normalizeKey('IACM'): InstallationFieldsRegistry.keyPresenceIacm,
    normalizeKey(InstallationFieldsRegistry.keyObservations): InstallationFieldsRegistry.keyObservations,
    normalizeKey('OBSERVATIONS'): InstallationFieldsRegistry.keyObservations,
    normalizeKey('Observation'): InstallationFieldsRegistry.keyObservations,
  };

  /// Dictionnaire d'alias pour les champs de Transformateurs MT/BT
  static final Map<String, String> _transfoAliases = {
    normalizeKey(InstallationFieldsRegistry.keyPuissanceTransformateur): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey('PUISSANCE TRANSFORMATEUR (KVA)'): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey('PUISSANCE TRANSFORMATEUR(KVA)'): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey('Puissance'): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey('Puissance (kVA)'): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey(InstallationFieldsRegistry.keyTypeTransformateur): InstallationFieldsRegistry.keyTypeTransformateur,
    normalizeKey('TYPE DE TRANSFORMATEUR'): InstallationFieldsRegistry.keyTypeTransformateur,
    normalizeKey(InstallationFieldsRegistry.keyIntensiteNominale): InstallationFieldsRegistry.keyIntensiteNominale,
    normalizeKey('INTENSITE NOMINALE'): InstallationFieldsRegistry.keyIntensiteNominale,
    normalizeKey('INTENSITE NOMINALE (A)'): InstallationFieldsRegistry.keyIntensiteNominale,
    normalizeKey('INTENSITE NOMINALE(A)'): InstallationFieldsRegistry.keyIntensiteNominale,
    normalizeKey('Intensite nominale (A)'): InstallationFieldsRegistry.keyIntensiteNominale,
    normalizeKey(InstallationFieldsRegistry.keyCalibreDisjoncteurBT):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR'):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR(A)'):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey('Calibre Disjoncteur Sortie'):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey('Calibre Disjoncteur'):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey(InstallationFieldsRegistry.keySectionCableBT): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey('SECTION DU CABLE'): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey('SECTION DU CABLE(mm2)'): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey('Section cable'): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey('Section des cables'): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey('Tension'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey(InstallationFieldsRegistry.keyTensionPrimaireSecondaire): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION MT/BT'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION MT/BT(KV)'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION MT/BT (KV/V)'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION MT/BT(KV/V)'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('Tension primaire / secondaire'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('Tension primaire/secondaire'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION PRIMAIRE / SECONDAIRE'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION PRIMAIRE/SECONDAIRE'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION PRIMAIRE / SECONDAIRE (KV/V)'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION PRIMAIRE/SECONDAIRE (KV/V)'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION PRIMAIRE/SECONDAIRE(KV/V)'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey(InstallationFieldsRegistry.keyCouplage): InstallationFieldsRegistry.keyCouplage,
    normalizeKey('COUPLAGE'): InstallationFieldsRegistry.keyCouplage,
    normalizeKey(InstallationFieldsRegistry.keyTypeReseau): InstallationFieldsRegistry.keyTypeReseau,
    normalizeKey('TYPE DE RESEAU'): InstallationFieldsRegistry.keyTypeReseau,
    normalizeKey(InstallationFieldsRegistry.keyPccAmont): InstallationFieldsRegistry.keyPccAmont,
    normalizeKey('PCC AMONT EN MVA'): InstallationFieldsRegistry.keyPccAmont,
    normalizeKey('PCC AMONT(MVA)'): InstallationFieldsRegistry.keyPccAmont,
    normalizeKey('PCC amont (MVA)'): InstallationFieldsRegistry.keyPccAmont,
    normalizeKey(InstallationFieldsRegistry.keyPuissanceUcc): InstallationFieldsRegistry.keyPuissanceUcc,
    normalizeKey('UCC EN %'): InstallationFieldsRegistry.keyPuissanceUcc,
    normalizeKey('UCC EN(%)'): InstallationFieldsRegistry.keyPuissanceUcc,
    normalizeKey('Puissance UCC (%)'): InstallationFieldsRegistry.keyPuissanceUcc,
    normalizeKey(InstallationFieldsRegistry.keyIk3Max): InstallationFieldsRegistry.keyIk3Max,
    normalizeKey('IK3 MAX(KA)'): InstallationFieldsRegistry.keyIk3Max,
    normalizeKey('IK3 MAX (kA)'): InstallationFieldsRegistry.keyIk3Max,
    normalizeKey(InstallationFieldsRegistry.keyObservations): InstallationFieldsRegistry.keyObservations,
    normalizeKey('OBSERVATIONS'): InstallationFieldsRegistry.keyObservations,
    normalizeKey('Observation'): InstallationFieldsRegistry.keyObservations,
  };

  /// Expose publiquement le dictionnaire d'alias pour les Cellules MT
  static Map<String, String> get celluleAliases => _celluleAliases;

  /// Expose publiquement le dictionnaire d'alias pour les Transformateurs MT/BT
  static Map<String, String> get transfoAliases => _transfoAliases;

  /// Recherche une valeur dans un dictionnaire de données avec alias tolérant
  static String getFieldWithAlias(
      Map<String, String>? data, String targetField, Map<String, String> aliases) {
    if (data == null || data.isEmpty) return '';

    // 1. Match exact par clé
    if (data.containsKey(targetField) && data[targetField]!.trim().isNotEmpty) {
      return data[targetField]!.trim();
    }

    final targetNorm = normalizeKey(targetField);
    final targetCanonical = aliases[targetNorm];

    for (final entry in data.entries) {
      if (entry.value.trim().isEmpty) continue;
      final entryNorm = normalizeKey(entry.key);
      
      // 2. Match par clé normalisée directe
      if (entryNorm == targetNorm) {
        return entry.value.trim();
      }
      
      // 3. Match via la clé canonique commune dans les alias
      if (targetCanonical != null) {
        final entryCanonical = aliases[entryNorm];
        if (entryCanonical == targetCanonical || entryNorm == normalizeKey(targetCanonical)) {
          return entry.value.trim();
        }
      } else if (aliases.containsKey(entryNorm) && normalizeKey(aliases[entryNorm]!) == targetNorm) {
        return entry.value.trim();
      }
    }

    return '';
  }

  /// Comparaison d'égalité profonde entre deux listes d'InstallationItem
  static bool _areItemListsEqual(List<InstallationItem> a, List<InstallationItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final itemA = a[i];
      final itemB = b[i];
      if (itemA.photoPaths.length != itemB.photoPaths.length) return false;
      for (int p = 0; p < itemA.photoPaths.length; p++) {
        if (itemA.photoPaths[p] != itemB.photoPaths[p]) return false;
      }
      if (itemA.data.length != itemB.data.length) return false;
      for (final entry in itemA.data.entries) {
        if (itemB.data[entry.key] != entry.value) return false;
      }
    }
    return true;
  }

  /// Normalise un libellé de régime de neutre vers l'un des 4 standards ('TT', 'TN-C', 'TN-S', 'IT')
  static String? normalizeRegimeNeutre(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toUpperCase();
    if (clean == 'TT') return 'TT';
    if (clean == 'TN-C' || clean == 'TNC') return 'TN-C';
    if (clean == 'TN-S' || clean == 'TNS') return 'TN-S';
    if (clean == 'IT') return 'IT';
    return null;
  }

  /// Extrait l'ensemble des régimes standards et personnalisés depuis une chaîne (ex: "TT, TN-S" ou "TN-C / IT")
  static Set<String> extractRegimesFromText(String? text, {String? detail}) {
    final result = <String>{};
    if (text == null || text.trim().isEmpty) return result;

    final trimmed = text.trim();
    if (trimmed.toLowerCase() == 'non renseigné' ||
        trimmed.toLowerCase() == 'non renseigne' ||
        trimmed.toLowerCase() == 'absent') {
      return result;
    }

    if (trimmed.toUpperCase() == 'TN') {
      if (detail != null && detail.trim().toUpperCase() == 'S') {
        result.add('TN-S');
      } else {
        result.add('TN-C');
      }
      return result;
    }

    final parts = trimmed
        .split(RegExp(r'[,/;\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    for (final part in parts) {
      final norm = normalizeRegimeNeutre(part);
      if (norm != null) {
        result.add(norm);
      } else if (part.toUpperCase() == 'TN') {
        if (detail != null && detail.trim().toUpperCase() == 'S') {
          result.add('TN-S');
        } else {
          result.add('TN-C');
        }
      } else {
        result.add(part);
      }
    }
    return result;
  }

  /// Collecte tous les transformateurs MT/BT présents dans un audit
  static List<TransformateurMTBT> collectAllTransformateursFromAudit(AuditInstallationsElectriques? audit) {
    if (audit == null) return [];
    final List<TransformateurMTBT> transfos = [];

    // 1. Locaux MT directs
    for (var local in audit.moyenneTensionLocaux) {
      local.migrateFromOldFields();
      transfos.addAll(local.transformateurs);
    }

    // 2. Locaux des zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        local.migrateFromOldFields();
        transfos.addAll(local.transformateurs);
      }
    }

    // 3. Locaux des zones BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        transfos.addAll(local.transformateurs);
      }
    }

    return transfos;
  }

  /// Récupère l'ensemble des régimes de neutre enregistrés sur tous les transformateurs de l'audit
  static Set<String> getRegimesNeutreFromAuditTransformers(AuditInstallationsElectriques? audit) {
    final transfos = collectAllTransformateursFromAudit(audit);
    final regimes = <String>{};
    for (final t in transfos) {
      final r = t.regimeNeutre.trim();
      if (r.isEmpty) continue;
      regimes.addAll(extractRegimesFromText(r));
    }
    return regimes;
  }

  /// Résout les régimes de neutre effectifs pour la mission.
  /// Pour chacun des 4 régimes ('TT', 'TN-C', 'TN-S', 'IT') :
  /// 1. On vérifie s'il est renseigné dans le formulaire de description.
  /// 2. S'il n'a pas été renseigné, on vérifie dans la liste de tous les transformateurs
  ///    de l'audit (locaux MT et BT). S'il y a un transformateur avec ce régime, il est
  ///    automatiquement sélectionné.
  /// Conserve également les éventuels régimes personnalisés.
  static List<String> resolveEffectiveRegimes({
    required DescriptionInstallations? desc,
    required AuditInstallationsElectriques? audit,
  }) {
    final standardRegimes = ['TT', 'TN-C', 'TN-S', 'IT'];
    final selectedInDesc = extractRegimesFromText(
      desc?.regimeNeutre,
      detail: desc?.regimeNeutreDetail,
    );

    final auditTransfoRegimes = getRegimesNeutreFromAuditTransformers(audit);

    final result = <String>[];

    // Traitement séquentiel des 4 régimes selon la règle métier :
    // Vérification dans le formulaire de description, et si absent, auto-sélection depuis les transfos
    for (final regime in standardRegimes) {
      if (selectedInDesc.contains(regime)) {
        result.add(regime);
      } else if (auditTransfoRegimes.contains(regime)) {
        result.add(regime);
      }
    }

    // Conservation des régimes personnalisés ("Autre") saisis dans la description
    for (final item in selectedInDesc) {
      if (!standardRegimes.contains(item) && !result.contains(item)) {
        result.add(item);
      }
    }

    return result;
  }

  /// Synchronise l'ensemble de l'Audit des Installations vers la Description des Installations
  static Future<void> syncAuditToDescription(AuditInstallationsElectriques audit) async {
    try {
      final missionId = audit.missionId;
      final descBox = await Hive.openBox<DescriptionInstallations>('description_installations');
      
      DescriptionInstallations? desc = HiveService.getDescriptionInstallationsByMissionId(missionId);
      desc ??= DescriptionInstallations.create(missionId);

      final oldMTA = List<InstallationItem>.from(desc.alimentationMoyenneTension);
      final oldBTA = List<InstallationItem>.from(desc.alimentationBasseTension);
      final oldRegime = desc.regimeNeutre;
      final oldRegimeDetail = desc.regimeNeutreDetail;

      bool auditModifie = false;

      // 1. Synchronisation des Cellules MT -> alimentationMoyenneTension
      auditModifie |= await _syncCellules(audit, desc);

      // 2. Synchronisation des Transformateurs MT/BT -> alimentationBasseTension
      auditModifie |= await _syncTransformateurs(audit, desc);

      // 3. Synchronisation automatique du Régime de neutre depuis les transformateurs
      final effectiveRegimes = resolveEffectiveRegimes(desc: desc, audit: audit);
      if (effectiveRegimes.isNotEmpty) {
        final newRegimeStr = effectiveRegimes.join(', ');
        if (desc.regimeNeutre != newRegimeStr) {
          desc.regimeNeutre = newRegimeStr;
          if (effectiveRegimes.contains('TN-S') && !effectiveRegimes.contains('TN-C')) {
            desc.regimeNeutreDetail = 'S';
          } else if (effectiveRegimes.contains('TN-C') && !effectiveRegimes.contains('TN-S')) {
            desc.regimeNeutreDetail = 'C';
          }
        }
      }

      // Sauvegarde des modifications de l'audit si des syncId ont été générés
      if (auditModifie) {
        Box<AuditInstallationsElectriques> auditBox;
        if (Hive.isBoxOpen(_auditBox)) {
          auditBox = Hive.box<AuditInstallationsElectriques>(_auditBox);
        } else {
          auditBox = await Hive.openBox<AuditInstallationsElectriques>(_auditBox);
        }
        await auditBox.put(audit.key ?? missionId, audit);
      }

      final mtEqual = _areItemListsEqual(oldMTA, desc.alimentationMoyenneTension);
      final btEqual = _areItemListsEqual(oldBTA, desc.alimentationBasseTension);
      final regimeEqual = (oldRegime == desc.regimeNeutre) && (oldRegimeDetail == desc.regimeNeutreDetail);

      if (!mtEqual || !btEqual || !regimeEqual || descBox.get(missionId) == null) {
        desc.updatedAt = DateTime.now();
        await descBox.put(missionId, desc);
        if (kDebugMode) {
          print('✅ Synchronisation Audit ↔ Description enregistrée pour la mission $missionId');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ Synchronisation Audit ↔ Description : Aucun changement (No-Op) pour $missionId');
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Erreur de synchronisation Audit ↔ Description: $e\n$st');
      }
    }
  }

  /// Supprime l'ensemble des descriptions pour une mission donnée,
  /// SANS TOUCHER AUX CELLULES, TRANSFORMATEURS OU DONNÉES D'AUDIT.
  static Future<void> clearAllDescriptions(String missionId) async {
    try {
      final descBox = await Hive.openBox<DescriptionInstallations>('description_installations');
      DescriptionInstallations? desc = descBox.get(missionId);
      desc ??= descBox.values.firstWhere(
        (d) => d.missionId == missionId,
        orElse: () => DescriptionInstallations.create(missionId),
      );

      desc.alimentationMoyenneTension = [];
      desc.alimentationBasseTension = [];
      desc.groupeElectrogene = [];
      desc.alimentationCarburant = [];
      desc.inverseur = [];
      desc.stabilisateur = [];
      desc.onduleurs = [];
      desc.updatedAt = DateTime.now();

      await descBox.put(missionId, desc);
      if (kDebugMode) {
        print('🗑️ Toutes les descriptions de la mission $missionId ont été supprimées proprement (Audit intact)');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Erreur lors de clearAllDescriptions pour la mission $missionId: $e\n$st');
      }
    }
  }

  /// Supprime uniquement les descriptions d'une section spécifique pour une mission donnée,
  /// SANS TOUCHER AUX CELLULES, TRANSFORMATEURS OU DONNÉES D'AUDIT.
  static Future<void> clearSectionDescriptions(String missionId, String sectionKey) async {
    try {
      final descBox = await Hive.openBox<DescriptionInstallations>('description_installations');
      DescriptionInstallations? desc = descBox.get(missionId);
      if (desc == null) return;

      switch (sectionKey) {
        case 'alimentation_moyenne_tension':
          desc.alimentationMoyenneTension = [];
          break;
        case 'alimentation_basse_tension':
          desc.alimentationBasseTension = [];
          break;
        case 'groupe_electrogene':
          desc.groupeElectrogene = [];
          break;
        case 'alimentation_carburant':
          desc.alimentationCarburant = [];
          break;
        case 'inverseur':
          desc.inverseur = [];
          break;
        case 'stabilisateur':
          desc.stabilisateur = [];
          break;
        case 'onduleurs':
          desc.onduleurs = [];
          break;
      }

      desc.updatedAt = DateTime.now();
      await descBox.put(missionId, desc);
      if (kDebugMode) {
        print('🗑️ Section $sectionKey de la mission $missionId réinitialisée (Audit intact)');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Erreur lors de clearSectionDescriptions ($sectionKey) pour la mission $missionId: $e\n$st');
      }
    }
  }

  /// Construction synchrone en mémoire d'une carte mapping `syncId -> breadcrumb de localisation`
  static Map<String, String> buildLocalisationMap(AuditInstallationsElectriques audit) {
    final Map<String, String> map = {};

    void processCellule(Cellule c, String path) {
      if (c.syncId != null && c.syncId!.isNotEmpty) {
        final cellName = c.type.isNotEmpty ? c.type : 'Cellule';
        map[c.syncId!] = '$path ➔ $cellName';
      }
    }

    void processTransfo(TransformateurMTBT t, String path) {
      if (t.syncId != null && t.syncId!.isNotEmpty) {
        final transfoName = (t.nom != null && t.nom!.trim().isNotEmpty)
            ? t.nom!.trim()
            : (t.puissanceAssignee.isNotEmpty ? '${t.puissanceAssignee} kVA' : 'Transformateur');
        map[t.syncId!] = '$path ➔ $transfoName';
      }
    }

    // 1. Locaux MT directs
    for (var local in audit.moyenneTensionLocaux) {
      final locPath = 'Moyenne Tension ➔ ${local.nom}';
      for (var c in local.cellules) {
        processCellule(c, locPath);
      }
      for (var t in local.transformateurs) {
        processTransfo(t, locPath);
      }
    }

    // 2. Zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        final locPath = 'Moyenne Tension ➔ ${zone.nom} ➔ ${local.nom}';
        for (var c in local.cellules) {
          processCellule(c, locPath);
        }
        for (var t in local.transformateurs) {
          processTransfo(t, locPath);
        }
      }
    }

    // 3. Zones BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        final locPath = 'Basse Tension ➔ ${zone.nom} ➔ ${local.nom}';
        for (var c in local.cellules) {
          processCellule(c, locPath);
        }
        for (var t in local.transformateurs) {
          processTransfo(t, locPath);
        }
      }
    }

    return map;
  }

  static final Map<String, DateTime> _lastSyncedAuditTime = {};

  /// Mécanisme d'auto-réparation et de synchronisation idempotente pour une mission
  static Future<void> repairAndSyncDescriptions(String missionId, {bool force = false}) async {
    try {
      Box<AuditInstallationsElectriques> auditBox;
      if (Hive.isBoxOpen(_auditBox)) {
        auditBox = Hive.box<AuditInstallationsElectriques>(_auditBox);
      } else {
        auditBox = await Hive.openBox<AuditInstallationsElectriques>(_auditBox);
      }
      
      AuditInstallationsElectriques? audit = auditBox.get(missionId);
      if (audit == null) {
        try {
          audit = auditBox.values.firstWhere((a) => a.missionId == missionId);
        } catch (_) {
          audit = AuditInstallationsElectriques(missionId: missionId, updatedAt: DateTime.now());
        }
      }
      
      final lastSync = _lastSyncedAuditTime[missionId];
      if (!force && lastSync != null && (audit.updatedAt.isBefore(lastSync) || audit.updatedAt.isAtSameMomentAs(lastSync))) {
        return;
      }

      await syncAuditToDescription(audit);
      _lastSyncedAuditTime[missionId] = DateTime.now();
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Erreur repairAndSyncDescriptions pour mission $missionId: $e\n$st');
      }
    }
  }

  /// Extraction de toutes les cellules dans tous les locaux (locaux MT directs, zones MT et zones BT)
  static List<Cellule> _collectAllCellulesMT(
      AuditInstallationsElectriques audit, List<bool> auditModifieRef) {
    final List<Cellule> cellules = [];

    void checkAndAddCellule(Cellule c) {
      if (c.syncId == null || c.syncId!.isEmpty) {
        c.syncId =
            'cellule_${DateTime.now().microsecondsSinceEpoch}_${cellules.length}';
        auditModifieRef[0] = true;
      }
      cellules.add(c);
    }

    // 1. Locaux MT directs
    for (var local in audit.moyenneTensionLocaux) {
      local.migrateFromOldFields();
      for (var cellule in local.cellules) {
        checkAndAddCellule(cellule);
      }
    }

    // 2. Locaux des zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        local.migrateFromOldFields();
        for (var cellule in local.cellules) {
          checkAndAddCellule(cellule);
        }
      }
    }

    // 3. Locaux des zones BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        for (var cellule in local.cellules) {
          checkAndAddCellule(cellule);
        }
      }
    }

    return cellules;
  }

  /// Extraction de tous les transformateurs dans tous les locaux (locaux MT directs, zones MT et zones BT)
  static List<TransformateurMTBT> _collectAllTransformateursMT(
      AuditInstallationsElectriques audit, List<bool> auditModifieRef) {
    final List<TransformateurMTBT> transfos = [];

    void checkAndAddTransfo(TransformateurMTBT t) {
      if (t.syncId == null || t.syncId!.isEmpty) {
        t.syncId =
            'transfo_${DateTime.now().microsecondsSinceEpoch}_${transfos.length}';
        auditModifieRef[0] = true;
      }
      transfos.add(t);
    }

    // 1. Locaux MT directs
    for (var local in audit.moyenneTensionLocaux) {
      local.migrateFromOldFields();
      for (var transfo in local.transformateurs) {
        checkAndAddTransfo(transfo);
      }
    }

    // 2. Locaux des zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        local.migrateFromOldFields();
        for (var transfo in local.transformateurs) {
          checkAndAddTransfo(transfo);
        }
      }
    }

    // 3. Locaux des zones BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        for (var transfo in local.transformateurs) {
          checkAndAddTransfo(transfo);
        }
      }
    }

    return transfos;
  }

  /// Synchronisation des cellules vers alimentationMoyenneTension
  static Future<bool> _syncCellules(
      AuditInstallationsElectriques audit, DescriptionInstallations desc) async {
    final List<bool> auditModifieRef = [false];
    final cellulesAudit = _collectAllCellulesMT(audit, auditModifieRef);
    final List<InstallationItem> itemsMiseAJour = [];

    // Conserver les items créés manuellement sans auditCelluleId
    for (var item in desc.alimentationMoyenneTension) {
      final auditCelluleId = item.data['auditCelluleId'];
      if (auditCelluleId == null || auditCelluleId.isEmpty) {
        itemsMiseAJour.add(item);
      }
    }

    final processedIds = <String>{};

    // Mettre à jour / ajouter les cellules de l'audit
    for (var cellule in cellulesAudit) {
      processedIds.add(cellule.syncId!);
      final observationsTxt = (cellule.observations ?? [])
          .map((o) => o.observation ?? '')
          .where((s) => s.isNotEmpty)
          .join('\n');

      InstallationItem? itemExistant;
      try {
        itemExistant = desc.alimentationMoyenneTension.firstWhere(
            (item) => item.data['auditCelluleId'] == cellule.syncId);
      } catch (_) {}

      final Map<String, String> existingData = itemExistant?.data ?? {};

      String valGamme = cellule.gamme ??
          getFieldWithAlias(existingData, 'Gamme De Cellule', _celluleAliases);
      String valType = cellule.type.isNotEmpty
          ? cellule.type
          : getFieldWithAlias(existingData, 'TYPE DE CELLULE', _celluleAliases);
      String valTensionAssignee = cellule.tensionAssignee.isNotEmpty
          ? cellule.tensionAssignee
          : getFieldWithAlias(existingData, 'TENSION ASSIGNEE(KV)', _celluleAliases);
      String valTensionService = (cellule.tensionService != null && cellule.tensionService!.isNotEmpty)
          ? cellule.tensionService!
          : getFieldWithAlias(existingData, 'Tension de service', _celluleAliases);
      String valPouvoirCoupure = cellule.pouvoirCoupure.isNotEmpty
          ? cellule.pouvoirCoupure
          : getFieldWithAlias(existingData, 'POUVOIR DE COUPURE ASSIGNE(KA)', _celluleAliases);
      String valCalibre = cellule.calibreDisjoncteur ??
          getFieldWithAlias(existingData, 'Calibre Du Disjoncteur', _celluleAliases);
      String valSection = cellule.effectiveSectionCablePhase ??
          cellule.sectionCables ??
          getFieldWithAlias(existingData, 'SECTION DU CABLE(mm2)', _celluleAliases);
      String valNature = cellule.natureReseau ??
          getFieldWithAlias(existingData, 'NATURE DU RESEAU', _celluleAliases);
      String valIacm = cellule.presenceIacm ??
          getFieldWithAlias(existingData, 'PRESENCE IACM', _celluleAliases);

      final itemData = Map<String, String>.from(existingData);
      itemData['auditCelluleId'] = cellule.syncId!;

      void updateField(String k, String v) {
        if (v.trim().isNotEmpty) {
          itemData[k] = v.trim();
        }
      }

      updateField('Gamme De Cellule', valGamme);
      updateField('Type De Cellule', valType);
      updateField('TYPE DE CELLULE', valType);
      updateField('Tension assignée', valTensionAssignee);
      updateField('TENSION ASSIGNEE(KV)', valTensionAssignee);
      if (valTensionService.isNotEmpty) {
        updateField('Tension de service', valTensionService);
      }
      updateField('Pouvoir de coupure assigné', valPouvoirCoupure);
      updateField('POUVOIR DE COUPURE ASSIGNE(KA)', valPouvoirCoupure);
      updateField('Calibre Du Disjoncteur', valCalibre);
      updateField('Section Du Cable', valSection);
      updateField('SECTION DU CABLE(mm2)', valSection);
      updateField('Nature Du Reseau', valNature);
      updateField('NATURE DU RESEAU', valNature);
      if (valNature == 'Aérien' || valIacm.isNotEmpty) {
        updateField('PRESENCE IACM', valIacm);
      }
      if (observationsTxt.isNotEmpty) {
        itemData['Observations'] = observationsTxt;
        itemData['OBSERVATIONS'] = observationsTxt;
      }

      if (itemExistant != null) {
        itemExistant.data = itemData;
        itemExistant.photoPaths = List.from(cellule.photos);
        itemsMiseAJour.add(itemExistant);
      } else {
        itemsMiseAJour.add(InstallationItem(
          data: itemData,
          photoPaths: List.from(cellule.photos),
          createdAt: DateTime.now(),
        ));
      }
    }

    itemsMiseAJour.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    desc.alimentationMoyenneTension = itemsMiseAJour;
    return auditModifieRef[0];
  }

  /// Synchronisation des transformateurs vers alimentationBasseTension
  static Future<bool> _syncTransformateurs(
      AuditInstallationsElectriques audit, DescriptionInstallations desc) async {
    final List<bool> auditModifieRef = [false];
    final transfosAudit = _collectAllTransformateursMT(audit, auditModifieRef);
    final List<InstallationItem> itemsMiseAJour = [];

    // Conserver les items créés manuellement sans auditTransformateurId
    for (var item in desc.alimentationBasseTension) {
      final auditTransfoId = item.data['auditTransformateurId'];
      if (auditTransfoId == null || auditTransfoId.isEmpty) {
        itemsMiseAJour.add(item);
      }
    }

    final processedIds = <String>{};

    // Mettre à jour / ajouter les transformateurs de l'audit
    for (var transfo in transfosAudit) {
      processedIds.add(transfo.syncId!);
      final observationsTxt = (transfo.observations ?? [])
          .map((o) => o.observation ?? '')
          .where((s) => s.isNotEmpty)
          .join('\n');

      InstallationItem? itemExistant;
      try {
        itemExistant = desc.alimentationBasseTension.firstWhere(
            (item) => item.data['auditTransformateurId'] == transfo.syncId);
      } catch (_) {}

      final Map<String, String> existingData = itemExistant?.data ?? {};

      String valPuissance = transfo.puissanceAssignee.isNotEmpty
          ? transfo.puissanceAssignee
          : getFieldWithAlias(existingData, 'PUISSANCE TRANSFORMATEUR (KVA)', _transfoAliases);
      String valTypeTransfo = transfo.typeTransformateur.isNotEmpty
          ? transfo.typeTransformateur
          : getFieldWithAlias(existingData, 'TYPE DE TRANSFORMATEUR', _transfoAliases);
      String valIntensiteNominale = transfo.intensiteNominale ??
          getFieldWithAlias(existingData, 'INTENSITE NOMINALE', _transfoAliases);
      String valCalibre = transfo.calibreDisjoncteur ??
          getFieldWithAlias(
              existingData, 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', _transfoAliases);
      String valSection = transfo.effectiveSectionCablePhase ??
          transfo.sectionCables ??
          getFieldWithAlias(existingData, 'SECTION DU CABLE', _transfoAliases);
      String valTension = transfo.tensionPrimaireSecondaire.trim().isNotEmpty
          ? transfo.tensionPrimaireSecondaire.trim()
          : getFieldWithAlias(existingData, 'Tension primaire / secondaire', _transfoAliases);
      if (valTension.isEmpty) {
        valTension = getFieldWithAlias(existingData, 'Tension', _transfoAliases);
      }
      if (valTension.isEmpty) {
        valTension = getFieldWithAlias(existingData, 'TENSION MT/BT', _transfoAliases);
      }
      String valCouplage = transfo.couplage ??
          getFieldWithAlias(existingData, 'COUPLAGE', _transfoAliases);
      String valTypeReseau = transfo.typeReseau ??
          getFieldWithAlias(existingData, 'TYPE DE RESEAU', _transfoAliases);
      String valPccAmont = transfo.pccAmont ??
          getFieldWithAlias(existingData, 'PCC AMONT EN MVA', _transfoAliases);
      String valPuissanceUcc = transfo.puissanceUcc ??
          getFieldWithAlias(existingData, 'UCC EN %', _transfoAliases);
      String valIk3Max = transfo.ik3Max ??
          getFieldWithAlias(existingData, 'IK3 MAX(KA)', _transfoAliases);

      final itemData = Map<String, String>.from(existingData);
      itemData['auditTransformateurId'] = transfo.syncId!;

      void updateField(String k, String v) {
        if (v.trim().isNotEmpty) {
          itemData[k] = v.trim();
        }
      }

      updateField('Puissance Transformateur', valPuissance);
      updateField('PUISSANCE TRANSFORMATEUR (KVA)', valPuissance);
      updateField('Type de transformateur', valTypeTransfo);
      updateField('TYPE DE TRANSFORMATEUR', valTypeTransfo);
      updateField('Intensité nominale', valIntensiteNominale);
      updateField('INTENSITE NOMINALE', valIntensiteNominale);
      updateField('Calibre Du Disjoncteur Sortie Transformateur', valCalibre);
      updateField('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', valCalibre);
      updateField('Section Du Cable', valSection);
      updateField('SECTION DU CABLE', valSection);
      updateField('Tension', valTension);
      updateField('Tension primaire / secondaire', valTension);
      updateField('Tension primaire/secondaire', valTension);
      updateField('TENSION PRIMAIRE/SECONDAIRE', valTension);
      updateField('TENSION PRIMAIRE / SECONDAIRE', valTension);
      updateField('TENSION MT/BT', valTension);
      updateField('TENSION MT/BT (KV/V)', valTension);
      updateField('Couplage', valCouplage);
      updateField('COUPLAGE', valCouplage);
      updateField('Type de réseau', valTypeReseau);
      updateField('TYPE DE RESEAU', valTypeReseau);
      updateField('PCC amont', valPccAmont);
      updateField('PCC AMONT EN MVA', valPccAmont);
      updateField('Puissance UCC', valPuissanceUcc);
      updateField('UCC EN %', valPuissanceUcc);
      updateField('IK3 MAX', valIk3Max);
      updateField('IK3 MAX(KA)', valIk3Max);
      if (observationsTxt.isNotEmpty) {
        itemData['Observations'] = observationsTxt;
        itemData['OBSERVATIONS'] = observationsTxt;
      }

      if (itemExistant != null) {
        itemExistant.data = itemData;
        itemExistant.photoPaths = List.from(transfo.photos);
        itemsMiseAJour.add(itemExistant);
      } else {
        itemsMiseAJour.add(InstallationItem(
          data: itemData,
          photoPaths: List.from(transfo.photos),
          createdAt: DateTime.now(),
        ));
      }
    }

    itemsMiseAJour.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    desc.alimentationBasseTension = itemsMiseAJour;
    return auditModifieRef[0];
  }
}
