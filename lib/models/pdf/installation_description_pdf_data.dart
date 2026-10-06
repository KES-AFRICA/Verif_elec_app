import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';

/// Ligne de donnée normalisée pour un tableau de la Description des Installations dans le PDF
class InstallationDescriptionPdfRow {
  final int index;
  final String rawId;
  final String zoneName;
  final String localName;
  final Map<String, String> normalizedFields;

  InstallationDescriptionPdfRow({
    required this.index,
    required this.rawId,
    this.zoneName = '',
    this.localName = '',
    required this.normalizedFields,
  });

  /// Extrait la valeur d'une colonne PDF de manière tolérante aux clés anciennes,
  /// récentes, majuscules, minuscules, accents et unités.
  String getValueForColumn(String columnHeader, String sectionKey) {
    // 1. Match direct sur l'en-tête exact
    if (normalizedFields.containsKey(columnHeader) &&
        normalizedFields[columnHeader]!.trim().isNotEmpty) {
      return normalizedFields[columnHeader]!.trim();
    }

    // 2. Match sur la clé normalisée
    final targetNorm = InstallationFieldsRegistry.normalizeKey(columnHeader);
    if (normalizedFields.containsKey(targetNorm) &&
        normalizedFields[targetNorm]!.trim().isNotEmpty) {
      return normalizedFields[targetNorm]!.trim();
    }

    // 3. Fallback via le dictionnaire d'alias global
    final aliases = sectionKey == 'MT'
        ? InstallationDescriptionSyncService.celluleAliases
        : InstallationDescriptionSyncService.transfoAliases;

    final valAlias = InstallationDescriptionSyncService.getFieldWithAlias(
        normalizedFields, columnHeader, aliases);
    if (valAlias.isNotEmpty) return valAlias;

    // 4. Recherche tolérante par égalité normalisée
    for (final entry in normalizedFields.entries) {
      if (entry.value.trim().isEmpty) continue;
      final entryNorm = InstallationFieldsRegistry.normalizeKey(entry.key);
      if (entryNorm == targetNorm) {
        return entry.value.trim();
      }
    }

    return '-';
  }
}

/// Structure de données intermédiaire normalisée alimentée directement à partir des entités réelles d'audit
/// (Cellule & TransformateurMTBT) et synchronisées avec DescriptionInstallations pour le rapport PDF.
class InstallationDescriptionPdfData {
  final List<InstallationDescriptionPdfRow> mtRows;
  final List<InstallationDescriptionPdfRow> btRows;

  InstallationDescriptionPdfData({
    required this.mtRows,
    required this.btRows,
  });

  /// Construit la représentation normalisée pour le PDF en respectant :
  /// 1. L'ordre exact de la liste des descriptions de l'application (du plus ancien au plus récent).
  /// 2. Le filtrage strict : seules les descriptions correspondant à un équipement d'audit ACTIF sont affichées dans le PDF.
  factory InstallationDescriptionPdfData.fromDescription({
    required DescriptionInstallations? desc,
    AuditInstallationsElectriques? audit,
  }) {
    final mtRows = <InstallationDescriptionPdfRow>[];
    final btRows = <InstallationDescriptionPdfRow>[];

    // Indexer les équipements d'audit actifs par leur syncId ainsi que le nom de local et de zone
    final activeCellulesMap = <String, Cellule>{};
    final activeCelluleLocalMap = <String, String>{};
    final activeCelluleZoneMap = <String, String>{};

    final activeTransfosMap = <String, TransformateurMTBT>{};
    final activeTransfoLocalMap = <String, String>{};
    final activeTransfoZoneMap = <String, String>{};

    if (audit != null) {
      // 1. Moyenne Tension Locaux (Locaux directs hors zone)
      for (var local in audit.moyenneTensionLocaux) {
        local.migrateFromOldFields();
        final locNom = local.nom.trim();
        for (var c in local.cellules) {
          if (c.syncId != null && c.syncId!.isNotEmpty) {
            activeCellulesMap[c.syncId!] = c;
            activeCelluleLocalMap[c.syncId!] = locNom;
            activeCelluleZoneMap[c.syncId!] = '';
          }
        }
        for (var t in local.transformateurs) {
          if (t.syncId != null && t.syncId!.isNotEmpty) {
            activeTransfosMap[t.syncId!] = t;
            activeTransfoLocalMap[t.syncId!] = locNom;
            activeTransfoZoneMap[t.syncId!] = '';
          }
        }
      }

      // 2. Moyenne Tension Zones et leurs locaux
      for (var zone in audit.moyenneTensionZones) {
        final zNom = zone.nom.trim();
        for (var local in zone.locaux) {
          local.migrateFromOldFields();
          final locNom = local.nom.trim();
          for (var c in local.cellules) {
            if (c.syncId != null && c.syncId!.isNotEmpty) {
              activeCellulesMap[c.syncId!] = c;
              activeCelluleLocalMap[c.syncId!] = locNom;
              activeCelluleZoneMap[c.syncId!] = zNom;
            }
          }
          for (var t in local.transformateurs) {
            if (t.syncId != null && t.syncId!.isNotEmpty) {
              activeTransfosMap[t.syncId!] = t;
              activeTransfoLocalMap[t.syncId!] = locNom;
              activeTransfoZoneMap[t.syncId!] = zNom;
            }
          }
        }
      }

      // 3. Basse Tension Zones et leurs locaux
      for (var zone in audit.basseTensionZones) {
        final zNom = zone.nom.trim();
        for (var local in zone.locaux) {
          final locNom = local.nom.trim();
          for (var c in local.cellules) {
            if (c.syncId != null && c.syncId!.isNotEmpty) {
              activeCellulesMap[c.syncId!] = c;
              activeCelluleLocalMap[c.syncId!] = locNom;
              activeCelluleZoneMap[c.syncId!] = zNom;
            }
          }
          for (var t in local.transformateurs) {
            if (t.syncId != null && t.syncId!.isNotEmpty) {
              activeTransfosMap[t.syncId!] = t;
              activeTransfoLocalMap[t.syncId!] = locNom;
              activeTransfoZoneMap[t.syncId!] = zNom;
            }
          }
        }
      }
    }

    final processedCelluleIds = <String>{};
    final processedTransfoIds = <String>{};

    // ── 1. CONSTRUCT DEPUIS LA LISTE DE DESCRIPTION (RESPECT DE L'ORDRE D'ORIGINE) ──
    if (desc != null) {
      // MT : Ordre du plus ancien au plus récent
      final itemsMT = List<InstallationItem>.from(desc.alimentationMoyenneTension);
      itemsMT.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (var item in itemsMT) {
        final auditCelluleId = item.data['auditCelluleId'];
        if (auditCelluleId != null) {
          if (activeCellulesMap.containsKey(auditCelluleId)) {
            final c = activeCellulesMap[auditCelluleId]!;
            final locName = activeCelluleLocalMap[auditCelluleId];
            final zName = activeCelluleZoneMap[auditCelluleId] ?? item.data['Zone'] ?? item.data['ZONE'] ?? '';
            mtRows.add(_createRowFromCelluleAndItem(c, item, mtRows.length + 1, localName: locName, zoneName: zName));
            processedCelluleIds.add(auditCelluleId);
          }
        } else {
          final itemLocName = item.data['Poste'] ??
              item.data['POSTE'] ??
              item.data['Local'] ??
              item.data['LOCAL'] ??
              item.data['Localisation'] ??
              item.data['Emplacement'] ??
              '';
          final itemZoneName = item.data['Zone'] ?? item.data['ZONE'] ?? '';
          mtRows.add(_createRowFromItemOnly(item, mtRows.length + 1, localName: itemLocName, zoneName: itemZoneName));
        }
      }

      // BT : Ordre du plus ancien au plus récent
      final itemsBT = List<InstallationItem>.from(desc.alimentationBasseTension);
      itemsBT.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (var item in itemsBT) {
        final auditTransfoId = item.data['auditTransformateurId'];
        if (auditTransfoId != null) {
          if (activeTransfosMap.containsKey(auditTransfoId)) {
            final t = activeTransfosMap[auditTransfoId]!;
            final locName = activeTransfoLocalMap[auditTransfoId];
            final zName = activeTransfoZoneMap[auditTransfoId] ?? item.data['Zone'] ?? item.data['ZONE'] ?? '';
            btRows.add(_createRowFromTransformateurAndItem(t, item, btRows.length + 1, localName: locName, zoneName: zName));
            processedTransfoIds.add(auditTransfoId);
          }
        } else {
          final itemLocName = item.data['Poste'] ??
              item.data['POSTE'] ??
              item.data['Local'] ??
              item.data['LOCAL'] ??
              item.data['Localisation'] ??
              item.data['Emplacement'] ??
              '';
          final itemZoneName = item.data['Zone'] ?? item.data['ZONE'] ?? '';
          btRows.add(_createRowFromItemOnly(item, btRows.length + 1, localName: itemLocName, zoneName: itemZoneName));
        }
      }
    }

    // ── 2. COMPLÉMENTATION POUR TOUT ÉQUIPEMENT ACTIF SANS ITEM DESCRIPTIF CORRESPONDANT ──
    if (audit != null) {
      for (var entry in activeCellulesMap.entries) {
        if (!processedCelluleIds.contains(entry.key)) {
          final locName = activeCelluleLocalMap[entry.key];
          final zName = activeCelluleZoneMap[entry.key] ?? '';
          mtRows.add(_createRowFromCellule(entry.value, mtRows.length + 1, localName: locName, zoneName: zName));
        }
      }
      for (var entry in activeTransfosMap.entries) {
        if (!processedTransfoIds.contains(entry.key)) {
          final locName = activeTransfoLocalMap[entry.key];
          final zName = activeTransfoZoneMap[entry.key] ?? '';
          btRows.add(_createRowFromTransformateur(entry.value, btRows.length + 1, localName: locName, zoneName: zName));
        }
      }
    }

    return InstallationDescriptionPdfData(mtRows: mtRows, btRows: btRows);
  }

  /// Construit une ligne de tableau PDF à partir d'une Cellule active et de son item descriptif
  static InstallationDescriptionPdfRow _createRowFromCelluleAndItem(
      Cellule c, InstallationItem item, int rowIndex, {String? localName, String? zoneName}) {
    final resolvedLocal = (localName != null && localName.trim().isNotEmpty)
        ? localName.trim()
        : (item.data['Poste'] ?? item.data['POSTE'] ?? item.data['Local'] ?? item.data['LOCAL'] ?? item.data['Localisation'] ?? '');
    final resolvedZone = zoneName ?? item.data['Zone'] ?? item.data['ZONE'] ?? '';
    final row = _createRowFromCellule(c, rowIndex, localName: resolvedLocal, zoneName: resolvedZone);
    for (final entry in item.data.entries) {
      if (entry.value.trim().isNotEmpty && !row.normalizedFields.containsKey(entry.key)) {
        row.normalizedFields[entry.key] = entry.value.trim();
        row.normalizedFields[InstallationFieldsRegistry.normalizeKey(entry.key)] = entry.value.trim();
      }
    }
    return row;
  }

  /// Construit une ligne de tableau PDF à partir d'un TransformateurMTBT actif et de son item descriptif
  static InstallationDescriptionPdfRow _createRowFromTransformateurAndItem(
      TransformateurMTBT t, InstallationItem item, int rowIndex, {String? localName, String? zoneName}) {
    final resolvedLocal = (localName != null && localName.trim().isNotEmpty)
        ? localName.trim()
        : (item.data['Poste'] ?? item.data['POSTE'] ?? item.data['Local'] ?? item.data['LOCAL'] ?? item.data['Localisation'] ?? '');
    final resolvedZone = zoneName ?? item.data['Zone'] ?? item.data['ZONE'] ?? '';
    final row = _createRowFromTransformateur(t, rowIndex, localName: resolvedLocal, zoneName: resolvedZone);
    for (final entry in item.data.entries) {
      if (entry.value.trim().isNotEmpty && !row.normalizedFields.containsKey(entry.key)) {
        row.normalizedFields[entry.key] = entry.value.trim();
        row.normalizedFields[InstallationFieldsRegistry.normalizeKey(entry.key)] = entry.value.trim();
      }
    }
    return row;
  }

  /// Construit une ligne de tableau PDF directement depuis les propriétés de l'entité Cellule
  static InstallationDescriptionPdfRow _createRowFromCellule(Cellule c, int rowIndex, {String? localName, String? zoneName}) {
    final normMap = <String, String>{};

    void addField(String headerKey, String value) {
      if (value.trim().isNotEmpty) {
        normMap[headerKey] = value.trim();
        normMap[InstallationFieldsRegistry.normalizeKey(headerKey)] = value.trim();
      }
    }

    addField('TYPE DE CELLULE', c.type);
    addField('Type De Cellule', c.type);
    addField('TENSION ASSIGNEE(KV)', c.tensionAssignee);
    addField('Tension assignée', c.tensionAssignee);
    addField('POUVOIR DE COUPURE ASSIGNE(KA)', c.pouvoirCoupure);
    addField('Pouvoir de coupure assigné', c.pouvoirCoupure);
    addField('SECTION DU CABLE(mm2)', c.sectionCables ?? '');
    addField('Section Du Cable', c.sectionCables ?? '');
    addField('NATURE DU RESEAU', c.natureReseau ?? '');
    addField('Nature Du Reseau', c.natureReseau ?? '');

    if (c.tensionService != null && c.tensionService!.isNotEmpty) {
      addField('TENSION DE SERVICE (kV)', c.tensionService!);
      addField('Tension de service', c.tensionService!);
    }
    if (c.gamme != null && c.gamme!.isNotEmpty) {
      addField('Gamme De Cellule', c.gamme!);
    }
    if (c.calibreDisjoncteur != null && c.calibreDisjoncteur!.isNotEmpty) {
      addField('Calibre Du Disjoncteur', c.calibreDisjoncteur!);
    }

    final observationsTxt = (c.observations ?? [])
        .map((o) => o.observation ?? '')
        .where((s) => s.isNotEmpty)
        .join('\n');
    if (observationsTxt.isNotEmpty) {
      addField('Observations', observationsTxt);
      addField('OBSERVATIONS', observationsTxt);
    }

    return InstallationDescriptionPdfRow(
      index: rowIndex,
      rawId: c.syncId ?? 'cellule_$rowIndex',
      zoneName: zoneName ?? '',
      localName: localName ?? '',
      normalizedFields: normMap,
    );
  }

  /// Construit une ligne de tableau PDF directement depuis les propriétés de l'entité TransformateurMTBT
  static InstallationDescriptionPdfRow _createRowFromTransformateur(TransformateurMTBT t, int rowIndex, {String? localName, String? zoneName}) {
    final normMap = <String, String>{};

    void addField(String headerKey, String value) {
      if (value.trim().isNotEmpty) {
        normMap[headerKey] = value.trim();
        normMap[InstallationFieldsRegistry.normalizeKey(headerKey)] = value.trim();
      }
    }

    if (t.nom != null && t.nom!.trim().isNotEmpty) {
      addField('NOM DU TRANSFORMATEUR', t.nom!.trim());
      addField('Nom du transformateur', t.nom!.trim());
      addField('DESIGNATION', t.nom!.trim());
    }

    addField('PUISSANCE TRANSFORMATEUR (KVA)', t.puissanceAssignee);
    addField('PUISSANCE TRANSFORMATEUR(KVA)', t.puissanceAssignee);
    addField('Puissance Transformateur', t.puissanceAssignee);
    addField('TYPE DE TRANSFORMATEUR', t.typeTransformateur);
    addField('Type de transformateur', t.typeTransformateur);
    addField('INTENSITE NOMINALE', t.intensiteNominale ?? '');
    addField('INTENSITE NOMINALE (A)', t.intensiteNominale ?? '');
    addField('INTENSITE NOMINALE(A)', t.intensiteNominale ?? '');
    addField('Intensité nominale', t.intensiteNominale ?? '');
    addField('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', t.calibreDisjoncteur ?? '');
    addField('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR(A)', t.calibreDisjoncteur ?? '');
    addField('Calibre Du Disjoncteur Sortie Transformateur', t.calibreDisjoncteur ?? '');
    addField('SECTION DU CABLE', t.sectionCables ?? '');
    addField('SECTION DU CABLE(mm2)', t.sectionCables ?? '');
    addField('Section Du Cable', t.sectionCables ?? '');
    addField('TENSION PRIMAIRE/SECONDAIRE', t.tensionPrimaireSecondaire);
    addField('TENSION PRIMAIRE / SECONDAIRE', t.tensionPrimaireSecondaire);
    addField('Tension primaire/secondaire', t.tensionPrimaireSecondaire);
    addField('Tension primaire / secondaire', t.tensionPrimaireSecondaire);
    addField('TENSION PRIMAIRE/SECONDAIRE (KV/V)', t.tensionPrimaireSecondaire);
    addField('TENSION PRIMAIRE / SECONDAIRE (KV/V)', t.tensionPrimaireSecondaire);
    addField('TENSION MT/BT', t.tensionPrimaireSecondaire);
    addField('TENSION MT/BT(KV)', t.tensionPrimaireSecondaire);
    addField('TENSION MT/BT (KV/V)', t.tensionPrimaireSecondaire);
    addField('TENSION MT/BT(KV/V)', t.tensionPrimaireSecondaire);
    addField('Tension', t.tensionPrimaireSecondaire);
    addField('COUPLAGE', t.couplage ?? '');
    addField('Couplage', t.couplage ?? '');
    addField('REGIME DE NEUTRE', t.regimeNeutre);
    addField('Régime de neutre', t.regimeNeutre);
    addField('REGIME DU NEUTRE', t.regimeNeutre);
    addField('Régime du neutre', t.regimeNeutre);
    addField('TYPE DE RESEAU', t.typeReseau ?? '');
    addField('Type de réseau', t.typeReseau ?? '');
    addField('PCC AMONT EN MVA', t.pccAmont ?? '');
    addField('PCC AMONT(MVA)', t.pccAmont ?? '');
    addField('PCC amont', t.pccAmont ?? '');
    addField('UCC EN %', t.puissanceUcc ?? '');
    addField('UCC EN(%)', t.puissanceUcc ?? '');
    addField('Puissance UCC', t.puissanceUcc ?? '');
    addField('IK3 MAX(KA)', t.ik3Max ?? '');
    addField('IK3 MAX', t.ik3Max ?? '');

    final observationsTxt = (t.observations ?? [])
        .map((o) => o.observation ?? '')
        .where((s) => s.isNotEmpty)
        .join('\n');
    if (observationsTxt.isNotEmpty) {
      addField('Observations', observationsTxt);
      addField('OBSERVATIONS', observationsTxt);
    }

    return InstallationDescriptionPdfRow(
      index: rowIndex,
      rawId: t.syncId ?? 'transfo_$rowIndex',
      zoneName: zoneName ?? '',
      localName: localName ?? '',
      normalizedFields: normMap,
    );
  }

  /// Construit une ligne de tableau PDF directement depuis un InstallationItem (sans entité d'audit liée)
  static InstallationDescriptionPdfRow _createRowFromItemOnly(
      InstallationItem item, int rowIndex, {String? localName, String? zoneName}) {
    final normMap = <String, String>{};
    for (final entry in item.data.entries) {
      if (entry.value.trim().isNotEmpty) {
        normMap[entry.key] = entry.value.trim();
        normMap[InstallationFieldsRegistry.normalizeKey(entry.key)] = entry.value.trim();
      }
    }
    return InstallationDescriptionPdfRow(
      index: rowIndex,
      rawId: 'item_$rowIndex',
      zoneName: zoneName ?? '',
      localName: localName ?? '',
      normalizedFields: normMap,
    );
  }

  /// Helper interne pour collecter l'ensemble des Cellules de l'audit
  static List<Cellule> _collectAllCellules(AuditInstallationsElectriques audit) {
    final List<Cellule> res = [];
    for (var local in audit.moyenneTensionLocaux) {
      local.migrateFromOldFields();
      res.addAll(local.cellules);
    }
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        local.migrateFromOldFields();
        res.addAll(local.cellules);
      }
    }
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        res.addAll(local.cellules);
      }
    }
    return res;
  }

  /// Helper interne pour collecter l'ensemble des Transformateurs de l'audit
  static List<TransformateurMTBT> _collectAllTransformateurs(AuditInstallationsElectriques audit) {
    final List<TransformateurMTBT> res = [];
    for (var local in audit.moyenneTensionLocaux) {
      local.migrateFromOldFields();
      res.addAll(local.transformateurs);
    }
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        local.migrateFromOldFields();
        res.addAll(local.transformateurs);
      }
    }
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        res.addAll(local.transformateurs);
      }
    }
    return res;
  }
}
