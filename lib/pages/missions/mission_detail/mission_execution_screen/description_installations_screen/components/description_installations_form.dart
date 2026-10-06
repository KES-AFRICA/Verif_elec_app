// lib/.../description_installations_form.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/constants/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/features/description_installations/presentation/providers/description_installations_provider.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';
import 'package:inspec_app/services/cellule_types_registry.dart';

// ============================================================
// GAMMES DE CELLULES → TYPES ASSOCIÉS
// ============================================================
class CelluleGammes {
  static const Map<String, List<String>> gammeTypes = {
    'Cellules RM6': [
      'I : Interrupteur‑sectionneur',
      'IM : Interrupteur‑sectionneur avec mise à la terre',
      'IQ : Interrupteur avec disjoncteur',
      'ID : Interrupteur départ ligne',
      'Q : Disjoncteur HTA',
      'IF : Interrupteur‑fusibles',
      'D : Départ direct',
      'DM : Départ avec mise à la terre',
      'M : Mesure HTA',
      'DE : Cellule de mise à la terre',
    ],
    'Cellules SM6': [
      'IM : interrupteur',
      'IMC : interrupteur',
      'IMB : interrupteur',
      'EMB : mise à la terre du jeu de barres',
      'PM : interrupteur-fusibles associés',
      'QM : combiné interrupteur-fusibles',
      'QMC : combiné interrupteur-fusibles',
      'QMB : combiné interrupteur-fusibles',
      'CRM : contacteur et contacteur-fusibles',
      'DM1-A : disjoncteur (SF6) simple sectionnement',
      'DM1-D : disjoncteur (SF6) simple sectionnement',
      'DM1-S : disjoncteur (SF6) simple sectionnement',
      'DMV-A : disjoncteur (vide) simple sectionnement',
      'DMV-D : disjoncteur (vide) simple sectionnement',
      'DMV-S : disjoncteur (vide) simple sectionnement',
      'DM1-W : disjoncteur (SF6) débrochable simple sectionnement',
      'DM1-Z : disjoncteur (SF6) débrochable simple sectionnement',
      'DM2 : disjoncteur (SF6) double sectionnement',
      'CM : transformateurs de potentiel',
      'CM2 : transformateurs de potentiel',
      'GBC-A : mesures d’intensité et/ou de tension',
      'GBC-B : mesures d’intensité et/ou de tension',
      'NSM-câbles : pour arrivée prioritaire et secours',
      'NSM-barres : pour arrivée prioritaire et câbles pour secours',
      'GIM : gaine intercalaire',
      'GEM : gaine d’extension',
      'GBM : gaine de liaison',
      'GAM2 : gaine d’arrivée',
      'GAM : gaine d’arrivée',
      'SM : sectionneur',
      'TM : transformateur MT/BT pour auxiliaires',
    ],
    'Cellules MCset': [
      'Incoming (I) : Arrivée réseau',
      'Outgoing (O) : Départ ligne ou câble',
      'Bus Coupler (BC) : Couplage jeux de barres',
      'Transformer Feeder (TF) : Départ transformateur',
      'Generator Feeder (GF) : Groupe électrogène',
      'Motor Feeder (MF) : Moteur HTA',
      'Capacitor Feeder (CF) : Batterie de condensateurs',
      'Metering (M) : Mesure HTA',
      'Bus Riser (BR) : Liaison tableau',
    ],
    'UniSwitch': [
      'SDC : Cellule interrupteur-sectionneur',
      'SDF : Cellule interrupteur-sectionneur fusibles',
      'CBC : Cellule disjoncteur',
      'DBC : Cellule raccordement direct sur jeu de barres',
      'SEC : Cellule de sectionnement type',
      'BRC : Cellule remontée de barres',
      'SBC : Cellule de sectionnement avec disjoncteur',
      'SMC : Cellule de sectionnement avec comptage',
    ],
    'UniSec': [
      'SDC : Cellule interrupteur-sectionneur',
      'SDS : Cellule de couplage interrupteur-sectionneur',
      'SDD : Cellule double interrupteur-sectionneur',
      'SDM : Cellule interrupteur-sectionneur de mesure',
      'UMP : Cellule de mesure universelle',
      'DRC : Cellule de remontée avec raccordement câbles',
      'DRS : Cellule de remontée pour raccordement barres',
      'SFV : Cellule de mesure avec interrupteur-sectionneur fusibles',
      'SFC : Cellule interrupteur-sectionneur fusibles',
      'SFS : Cellule de couplage interrupteur-sectionneur fusibles',
      'SBC : Cellule simple interrupteur-sectionneur et disjoncteur',
      'SBC-W : Cellule simple interrupteur-sectionneur et disjoncteur débrochable',
      'SBS : Cellule de couplage simple interrupteur-sectionneur et disjoncteur',
      'SBS-W : Cellule de couplage simple interrupteur-sectionneur et disjoncteur débrochable',
      'SBM : Cellule de couplage double interrupteur-sectionneur et disjoncteur',
      'SBR : Cellule inversée disjoncteur et simple interrupteur-sectionneur',
      'HBC : Cellule disjoncteur et interrupteur-sectionneur intégrés',
      'SCC : Cellule interrupteur-sectionneur et contacteur',
      'HBS : Cellule de couplage interrupteur-sectionneur et disjoncteur intégrés',
      'RLC : Caisson de remontée de câble latéral gauche',
      'RRC : Caisson de remontée de câble latéral droit',
      'WBC : Cellule disjoncteur débrochable',
      'WBS : Cellule de couplage disjoncteur débrochable',
      'BME : Cellule directe avec mesure et mise à la terre des barres',
    ],
  };

  static List<String> get gammes => gammeTypes.keys.toList();

  static List<String> getTypesForGamme(String? gamme) {
    if (gamme == null || gamme.isEmpty) return [];
    return gammeTypes[gamme] ?? gammeTypes['Autre / Inconnu']!;
  }
}

// ============================================================
// HELPERS DE NORMALISATION POUR LA RECHERCHE DE CLÉS DE MANIÈRE ROBUSTE
// ============================================================
String _normalizeKey(String key) {
  return key
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('ç', 'c')
      .replaceAll('-', ' ')
      .replaceAll('_', ' ')
      .replaceAll("'", ' ')
      .trim();
}

String? _getValueForField(Map<String, String>? data, String field) {
  if (data == null) return null;
  if (data.containsKey(field)) return data[field];
  final normalizedField = _normalizeKey(field);
  for (var entry in data.entries) {
    if (_normalizeKey(entry.key) == normalizedField) {
      return entry.value;
    }
  }
  return null;
}

bool _hasField(Map<String, String>? data, String field) {
  final val = _getValueForField(data, field);
  return val != null && val.isNotEmpty;
}

// ============================================================
// WIDGET PRINCIPAL : LISTE DES ITEMS
// ============================================================
class DescriptionInstallationsForm extends ConsumerStatefulWidget {
  final Mission mission;
  final String title;
  final String sectionKey;
  final List<String> champs;
  final Function(String) onComplete;
  final bool isComplete;
  final VoidCallback onTerminate;

  const DescriptionInstallationsForm({
    super.key,
    required this.mission,
    required this.title,
    required this.sectionKey,
    required this.champs,
    required this.onComplete,
    required this.isComplete,
    required this.onTerminate,
  });

  @override
  ConsumerState<DescriptionInstallationsForm> createState() =>
      _DescriptionInstallationsFormState();
}

class _DescriptionInstallationsFormState
    extends ConsumerState<DescriptionInstallationsForm> {
  bool _isSaving = false;

  static String getGeDisplayName(InstallationItem ge, [int? index]) {
    final idField = ge.data['Identification']?.trim() ?? '';
    if (idField.isNotEmpty) {
      return idField;
    }
    final marque = ge.data['Marque']?.trim() ?? '';
    final puissance = ge.data['Puissance (Kva)']?.trim() ?? '';
    final parts = [marque, if (puissance.isNotEmpty) '$puissance kVA'].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      final base = parts.join(' — ');
      return index != null ? 'GE ${index + 1} ($base)' : base;
    }
    return 'GE ${index != null ? index + 1 : (ge.data['N°'] ?? '')}';
  }

  static const Map<String, String> _numericFieldsWithUnit = {
    'Calibre Du Disjoncteur': 'A',
    'Tension assignée': 'kV',
    'TENSION ASSIGNEE(KV)': 'kV',
    'Section Du Cable': 'mm²',
    'SECTION DU CABLE': 'mm²',
    'SECTION DU CABLE(mm2)': 'mm²',
    'Puissance Transformateur': 'kVA',
    'PUISSANCE TRANSFORMATEUR (KVA)': 'kVA',
    'Intensité nominale': 'A',
    'INTENSITE NOMINALE': 'A',
    'Calibre Du Disjoncteur Sortie Transformateur': 'A',
    'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR': 'A',
    'Tension': 'V',
    'TENSION MT/BT': 'V',
    'PCC amont': 'MVA',
    'PCC AMONT EN MVA': 'MVA',
    'IK3 MAX': 'kA',
    'IK3 MAX(KA)': 'kA',
    'Puissance (Kva)': 'kVA',
    'Intensite': 'A',
    'Capacite': 'L',
    'Intensite (A)': 'A',
    'Entree': 'V',
    'Sortie': 'V',
    'Nombre De Phase': '',
  };

  static const List<String> _natureReseauOptions = [
    'Aérien',
    'Souterrain',
    'Mixte',
  ];
  static const List<String> _sectionCableOptions = [
    '0,5',
    '0,75',
    '1',
    '1,5',
    '2,5',
    '4',
    '6',
    '10',
    '16',
    '25',
    '35',
    '50',
    '70',
    '95',
    '120',
    '150',
    '185',
    '240',
    '300',
    '400',
    '500',
    '630',
  ];
  static const List<String> _modeOptions = [
    'Pompe électrique',
    'Gravitaire',
    'Manuel',
    'Autre',
  ];
  static const List<String> _ouiNonOptions = ['Oui', 'Non'];

  Future<void> _onRefresh() async {
    final audit = HiveService.getAuditInstallationsByMissionId(widget.mission.id);
    if (audit != null) {
      await InstallationDescriptionSyncService.syncAuditToDescription(audit);
    }
    await ref
        .read(descriptionInstallationsProvider(widget.mission.id).notifier)
        .load(syncWithAudit: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descriptions régénérées depuis l\'audit'),
          backgroundColor: AppTheme.primaryBlue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addItem([List<InstallationItem>? availableGes]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddEditItemScreen(
          title: widget.title,
          champs: widget.champs,
          numericFieldsWithUnit: _numericFieldsWithUnit,
          natureReseauOptions: _natureReseauOptions,
          sectionCableOptions: _sectionCableOptions,
          modeOptions: _modeOptions,
          ouiNonOptions: _ouiNonOptions,
          availableGes: availableGes ?? [],
        ),
      ),
    );
    if (result != null && result is Map<String, String>) {
      setState(() => _isSaving = true);
      final notifier = ref.read(
        descriptionInstallationsProvider(widget.mission.id).notifier,
      );
      final success = await notifier.addInstallationItem(
        widget.sectionKey,
        InstallationItem(data: result, createdAt: DateTime.now()),
      );
      if (success) {
        if (mounted) {
          final shouldContinue = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Élément ajouté',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'L\'élément a été ajouté avec succès.\nSouhaitez-vous en ajouter un autre ?',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Terminer'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'CONTINUER',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
          if (shouldContinue == true) {
            _addItem(availableGes);
          } else {
            widget.onTerminate();
          }
        }
      }
      setState(() => _isSaving = false);
    }
  }

  Future<void> _editItem(int index, List<InstallationItem> items, [List<InstallationItem>? availableGes]) async {
    final item = items[index];
    final isCelluleAuto = item.data.containsKey('auditCelluleId') && item.data['auditCelluleId']!.isNotEmpty;
    final isTransfoAuto = item.data.containsKey('auditTransformateurId') && item.data['auditTransformateurId']!.isNotEmpty;
    final isAutomatic = isCelluleAuto || isTransfoAuto;

    String localisation = 'Créée manuellement';
    if (isAutomatic) {
      if (isCelluleAuto) {
        final cellId = item.data['auditCelluleId']!;
        final locResult = await HiveService.getCelluleLocalisation(
          widget.mission.id,
          cellId,
        );
        if (!mounted) return;
        localisation = locResult ?? 'Moyenne Tension';
      } else {
        final transfoId = item.data['auditTransformateurId']!;
        final locResult = await HiveService.getTransformateurLocalisation(
          widget.mission.id,
          transfoId,
        );
        if (!mounted) return;
        localisation = locResult ?? 'Basse Tension';
      }
    }

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddEditItemScreen(
          title: widget.title,
          champs: widget.champs,
          initialData: item.data,
          numericFieldsWithUnit: _numericFieldsWithUnit,
          natureReseauOptions: _natureReseauOptions,
          sectionCableOptions: _sectionCableOptions,
          modeOptions: _modeOptions,
          ouiNonOptions: _ouiNonOptions,
          isReadOnly: isAutomatic ? !_isItemACompleter(item) : false,
          localisation: localisation,
          availableGes: availableGes ?? [],
        ),
      ),
    );
    if (result != null && result is Map<String, String>) {
      setState(() => _isSaving = true);
      final notifier = ref.read(
        descriptionInstallationsProvider(widget.mission.id).notifier,
      );
      final success = await notifier.updateInstallationItem(
        widget.sectionKey,
        index,
        InstallationItem(
          data: result,
          photoPaths: item.photoPaths,
          createdAt: item.createdAt,
        ),
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Modifié avec succès'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 700),
            ),
          );
        }
      }
      setState(() => _isSaving = false);
    }
  }

  bool _isItemACompleter(InstallationItem item) {
    final isCelluleAuto = item.data.containsKey('auditCelluleId') && item.data['auditCelluleId']!.isNotEmpty;
    final isTransfoAuto = item.data.containsKey('auditTransformateurId') && item.data['auditTransformateurId']!.isNotEmpty;
    if (!isCelluleAuto && !isTransfoAuto) return false;

    if (isCelluleAuto) {
      final calibre = item.data['Calibre Du Disjoncteur'] ?? '';
      final section = item.data['Section Du Cable'] ?? '';
      final nature = item.data['Nature Du Reseau'] ?? '';
      return calibre.isEmpty || section.isEmpty || nature.isEmpty;
    } else {
      final calibre = item.data['Calibre Du Disjoncteur Sortie Transformateur'] ?? '';
      final section = item.data['Section Du Cable'] ?? '';
      return calibre.isEmpty || section.isEmpty;
    }
  }

  Future<void> _deleteItem(int index, InstallationItem item) async {
    final isCelluleAuto = item.data.containsKey('auditCelluleId') && item.data['auditCelluleId']!.isNotEmpty;
    final isTransfoAuto = item.data.containsKey('auditTransformateurId') && item.data['auditTransformateurId']!.isNotEmpty;
    final isAutomatic = isCelluleAuto || isTransfoAuto;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteDescriptionDialog(
        isAutomatic: isAutomatic,
        title: widget.title,
      ),
    );
    if (confirm == true) {
      setState(() => _isSaving = true);
      final notifier = ref.read(
        descriptionInstallationsProvider(widget.mission.id).notifier,
      );
      final success = await notifier.removeInstallationItem(
        widget.sectionKey,
        index,
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supprimé'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      }
      setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeleteAllDescriptions() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Supprimer les descriptions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir supprimer toutes les descriptions ?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                borderRadius: BorderRadius.all(Radius.circular(8)),
                border: Border.fromBorderSide(BorderSide(color: Color(0xFFFFB74D))),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action concerne uniquement les descriptions. Aucune cellule, aucun transformateur et aucune donnée d\'audit ne sera supprimé.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Un simple Pull-to-Refresh (glisser vers le bas) permettra ensuite de reconstruire automatiquement les descriptions si souhaité.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ANNULER', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('SUPPRIMER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      final notifier = ref.read(
        descriptionInstallationsProvider(widget.mission.id).notifier,
      );
      final success = await notifier.clearAllDescriptions();
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Toutes les descriptions ont été supprimées (Audit intact). Glisser vers le bas pour régénérer.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final asyncData = ref.watch(
      descriptionInstallationsProvider(widget.mission.id),
    );

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
      data: (desc) {
        List<InstallationItem> items = [];
        switch (widget.sectionKey) {
          case 'alimentation_moyenne_tension':
            items = desc.alimentationMoyenneTension;
            break;
          case 'alimentation_basse_tension':
            items = desc.alimentationBasseTension;
            break;
          case 'groupe_electrogene':
            items = desc.groupeElectrogene;
            break;
          case 'alimentation_carburant':
            items = desc.alimentationCarburant;
            break;
          case 'inverseur':
            items = desc.inverseur;
            break;
          case 'stabilisateur':
            items = desc.stabilisateur;
            break;
          case 'onduleurs':
            items = desc.onduleurs;
            break;
        }

        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final audit = HiveService.getAuditInstallationsByMissionId(widget.mission.id);
        final localisationMap = audit != null
            ? InstallationDescriptionSyncService.buildLocalisationMap(audit)
            : <String, String>{};

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (items.isNotEmpty && !widget.isComplete) {
            widget.onComplete(widget.sectionKey);
          }
        });

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primaryBlue,
          child: Stack(
            children: [
              items.isEmpty
                  ? _buildEmpty(isSmallScreen)
                  : _buildList(items, isSmallScreen, localisationMap, desc.groupeElectrogene),
              Positioned(
                bottom: isSmallScreen ? 16 : 20,
                right: isSmallScreen ? 16 : 20,
                child: FloatingActionButton(
                  onPressed: _isSaving ? null : () => _addItem(desc.groupeElectrogene),
                  backgroundColor: AppTheme.primaryBlue,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(bool isSmallScreen) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: isSmallScreen ? 56 : 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun élément',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Appuyez sur + pour ajouter ou glissez vers le bas (Pull-to-Refresh) pour régénérer automatiquement les descriptions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildList(
    List<InstallationItem> items,
    bool isSmallScreen,
    Map<String, String> localisationMap, [
    List<InstallationItem> availableGes = const [],
  ]) =>
      Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16 : 20,
              isSmallScreen ? 10 : 12,
              isSmallScreen ? 16 : 20,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${items.length} élément${items.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isSaving ? null : _confirmDeleteAllDescriptions,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                  label: const Text(
                    'Tout supprimer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 16 : 20,
                6,
                isSmallScreen ? 16 : 20,
                90,
              ),
              itemCount: items.length,
              itemBuilder: (ctx, i) =>
                  _buildCard(items, items[i], i, isSmallScreen, localisationMap, availableGes),
            ),
          ),
        ],
      );

  Widget _buildCard(
    List<InstallationItem> items,
    InstallationItem item,
    int index,
    bool isSmallScreen,
    Map<String, String> localisationMap, [
    List<InstallationItem> availableGes = const [],
  ]) {
    final isCelluleAuto = item.data.containsKey('auditCelluleId') && item.data['auditCelluleId']!.isNotEmpty;
    final isTransfoAuto = item.data.containsKey('auditTransformateurId') && item.data['auditTransformateurId']!.isNotEmpty;
    final isAutomatic = isCelluleAuto || isTransfoAuto;

    String? loc;
    if (isCelluleAuto) {
      loc = localisationMap[item.data['auditCelluleId']!] ?? 'Moyenne Tension';
    } else if (isTransfoAuto) {
      loc = localisationMap[item.data['auditTransformateurId']!] ?? 'Basse Tension';
    }

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () => _editItem(index, items, availableGes),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isSmallScreen ? 32 : 36,
                    height: isSmallScreen ? 32 : 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue,
                          AppTheme.primaryBlue.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      (isAutomatic && !_isItemACompleter(item))
                          ? Icons.visibility_outlined
                          : Icons.edit_outlined,
                      color: AppTheme.primaryBlue,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    onPressed: () => _editItem(index, items, availableGes),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    onPressed: () => _deleteItem(index, item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              // Encart d'Origine / Localisation synchrone sans FutureBuilder
              isAutomatic
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              loc ?? 'Audit',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9.5 : 10.5,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Origine : Créée manuellement',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
               if (_isItemACompleter(item))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'À compléter',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.champs
                    .where((c) => _hasField(item.data, c))
                    .map((champ) {
                      final rawVal = _getValueForField(item.data, champ)!;
                      String value = rawVal;
                      if (champ == 'Identification du GE' && item.data.containsKey('geId') && item.data['geId']!.isNotEmpty) {
                        final geId = item.data['geId']!;
                        for (final g in availableGes) {
                          if (g.itemId == geId || g.id == geId) {
                            final liveName = _DescriptionInstallationsFormState.getGeDisplayName(g);
                            if (liveName.isNotEmpty) {
                              value = liveName;
                            }
                            break;
                          }
                        }
                      }
                      final unit = _numericFieldsWithUnit[champ] ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          unit.isNotEmpty ? '$value $unit' : value,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    })
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteDescriptionDialog extends StatefulWidget {
  final bool isAutomatic;
  final String title;

  const _DeleteDescriptionDialog({
    required this.isAutomatic,
    required this.title,
  });

  @override
  State<_DeleteDescriptionDialog> createState() => _DeleteDescriptionDialogState();
}

class _DeleteDescriptionDialogState extends State<_DeleteDescriptionDialog> {
  int _countdown = 3;
  bool ready = false;
  StreamSubscription? _timerSubscription;

  @override
  void initState() {
    super.initState();
    _timerSubscription = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        setState(() {
          ready = true;
          _countdown = 0;
        });
        _timerSubscription?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirmer la suppression',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isAutomatic
                ? 'Cette description de type automatique est liée à un équipement d\'Audit des installations.'
                : 'Cette description a été créée manuellement.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isAutomatic
                        ? 'La suppression retirera la description de cette liste. L\'équipement d\'Audit restera intact et la description sera recréée lors de la prochaine synchronisation.'
                        : 'Cette action est irréversible. La description sera définitivement effacée.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ready
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Confirmation disponible',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            value: (3 - _countdown) / 3,
                            strokeWidth: 2,
                            backgroundColor: Colors.grey.shade100,
                            color: Colors.red.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Confirmation dans $_countdown s',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Annuler',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: ready ? () => Navigator.pop(context, true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: ready ? 2 : 0,
                ),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// ÉCRAN D'AJOUT / MODIFICATION — DESIGN MODERNE
// ============================================================
class _AddEditItemScreen extends StatefulWidget {
  final String title;
  final List<String> champs;
  final Map<String, String>? initialData;
  final Map<String, String> numericFieldsWithUnit;
  final List<String> natureReseauOptions;
  final List<String> sectionCableOptions;
  final List<String> modeOptions;
  final List<String> ouiNonOptions;
  final bool isReadOnly;
  final String? localisation;
  final List<InstallationItem> availableGes;

  const _AddEditItemScreen({
    required this.title,
    required this.champs,
    this.initialData,
    required this.numericFieldsWithUnit,
    required this.natureReseauOptions,
    required this.sectionCableOptions,
    required this.modeOptions,
    required this.ouiNonOptions,
    this.isReadOnly = false,
    this.localisation,
    this.availableGes = const [],
  });

  @override
  State<_AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<_AddEditItemScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectedValues = {};
  final Map<String, String> _geOptionToIdMap = {};
  String? _selectedGamme;
  String? _selectedGeId;

  @override
  void initState() {
    super.initState();
    _selectedGamme = _getValueForField(widget.initialData, 'Gamme De Cellule');
    _selectedGeId = widget.initialData?['geId'];

    if (widget.champs.any(_isIdentificationGeField)) {
      _optionsFor('Identification du GE');
      if (_selectedGeId != null && _selectedGeId!.isNotEmpty) {
        for (var entry in _geOptionToIdMap.entries) {
          if (entry.value == _selectedGeId) {
            _selectedValues['Identification du GE'] = entry.key;
            break;
          }
        }
      }
    }

    for (var champ in widget.champs) {
      if (_isGammeField(champ)) {
        // handled via _selectedGamme
      } else if (_isDropdownField(champ)) {
        if (!_selectedValues.containsKey(champ)) {
          _selectedValues[champ] = _getValueForField(widget.initialData, champ);
        }
      } else {
        _controllers[champ] = TextEditingController(
          text: _getValueForField(widget.initialData, champ) ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isIdentificationGeField(String c) => c == 'Identification du GE';
  bool _isGammeField(String c) => c == 'Gamme De Cellule';
  bool _isTypeCelluleField(String c) => c == 'Type De Cellule' || c == 'TYPE DE CELLULE';
  bool _isTensionDeServiceField(String c) => c == 'Tension de service' || c == 'TENSION DE SERVICE';
  bool _isSectionCableField(String c) => c == 'Section Du Cable' || c == 'SECTION DU CABLE' || c == 'SECTION DU CABLE(mm2)';
  bool _isNatureReseauField(String c) => c == 'Nature Du Reseau' || c == 'NATURE DU RESEAU';
  bool _isTypeTransformateurField(String c) => c == 'Type de transformateur' || c == 'TYPE DE TRANSFORMATEUR';
  bool _isCouplageField(String c) => c == 'Couplage' || c == 'COUPLAGE';
  bool _isTypeReseauField(String c) => c == 'Type de réseau' || c == 'TYPE DE RESEAU';
  bool _isPuissanceTransfoField(String c) => c == 'Puissance Transformateur' || c == 'PUISSANCE TRANSFORMATEUR (KVA)';
  bool _isPuissanceUccField(String c) => c == 'Puissance UCC' || c == 'UCC EN %';
  bool _isModeField(String c) => c == 'Mode';
  bool _isOuiNonField(String c) =>
      c == 'Cuve De Retention' ||
      c == 'Indicateur De Niveau' ||
      c == 'Mise A La Terre';
  bool _isAnneeField(String c) =>
      c == 'Annee De Fabrication' || c == "Annee D'Installation";

  bool _isDropdownField(String c) =>
      _isIdentificationGeField(c) ||
      _isGammeField(c) ||
      _isTypeCelluleField(c) ||
      _isTensionDeServiceField(c) ||
      _isSectionCableField(c) ||
      _isNatureReseauField(c) ||
      _isTypeTransformateurField(c) ||
      _isCouplageField(c) ||
      _isTypeReseauField(c) ||
      _isPuissanceTransfoField(c) ||
      _isPuissanceUccField(c) ||
      _isModeField(c) ||
      _isOuiNonField(c) ||
      _isAnneeField(c);

  List<String> _getAnneeOptions() {
    final y = DateTime.now().year;
    return List.generate(y - 1900 + 1, (i) => (y - i).toString());
  }

  List<String> _optionsFor(String champ) {
    if (_isIdentificationGeField(champ)) {
      final opts = <String>[];
      _geOptionToIdMap.clear();
      for (int i = 0; i < widget.availableGes.length; i++) {
        final ge = widget.availableGes[i];
        final name = _DescriptionInstallationsFormState.getGeDisplayName(ge, i);
        var uniqueName = name;
        int dupCount = 1;
        while (opts.contains(uniqueName)) {
          dupCount++;
          uniqueName = '$name ($dupCount)';
        }
        opts.add(uniqueName);
        _geOptionToIdMap[uniqueName] = ge.itemId;
      }
      return opts;
    }
    if (_isTypeCelluleField(champ))
      return CelluleGammes.getTypesForGamme(_selectedGamme);
    if (_isTensionDeServiceField(champ)) return InstallationFieldsRegistry.tensionDeServiceOptions;
    if (_isSectionCableField(champ)) return widget.sectionCableOptions;
    if (_isNatureReseauField(champ)) return widget.natureReseauOptions;
    if (_isTypeTransformateurField(champ)) return InstallationFieldsRegistry.typeTransformateurOptions;
    if (_isCouplageField(champ)) return InstallationFieldsRegistry.couplageOptions;
    if (_isTypeReseauField(champ)) return InstallationFieldsRegistry.typeReseauOptions;
    if (_isPuissanceTransfoField(champ)) return InstallationFieldsRegistry.puissanceTransformateurOptions;
    if (_isPuissanceUccField(champ)) return InstallationFieldsRegistry.puissanceUccOptions;
    if (_isModeField(champ)) return widget.modeOptions;
    if (_isOuiNonField(champ)) return widget.ouiNonOptions;
    if (_isAnneeField(champ)) return _getAnneeOptions();
    return [];
  }

  void _onDropdownValueChanged(String champ, String? value) {
    setState(() {
      _selectedValues[champ] = value;

      if (_isIdentificationGeField(champ)) {
        if (value != null && _geOptionToIdMap.containsKey(value)) {
          _selectedGeId = _geOptionToIdMap[value];
        } else {
          _selectedGeId = null;
        }
      }

      if (_isTypeReseauField(champ)) {
        final pccSuggested = InstallationFieldsRegistry.getPccAmontForTypeReseau(value ?? '');
        for (var key in ['PCC amont', 'PCC AMONT EN MVA']) {
          if (_controllers.containsKey(key)) {
            _controllers[key]!.text = pccSuggested;
          }
        }
      }

      if (_isPuissanceTransfoField(champ) || _isPuissanceUccField(champ)) {
        String puissanceVal = '';
        for (var pKey in ['Puissance Transformateur', 'PUISSANCE TRANSFORMATEUR (KVA)']) {
          if (_selectedValues.containsKey(pKey) && _selectedValues[pKey] != null) {
            puissanceVal = _selectedValues[pKey]!;
            break;
          }
        }

        String uccVal = '';
        for (var uKey in ['Puissance UCC', 'UCC EN %']) {
          if (_selectedValues.containsKey(uKey) && _selectedValues[uKey] != null) {
            uccVal = _selectedValues[uKey]!;
            break;
          }
        }

        final ik3Calculated = InstallationFieldsRegistry.calculateIk3Max(
          puissanceKva: puissanceVal,
          uccPercent: uccVal,
        );

        if (ik3Calculated.isNotEmpty) {
          for (var ikKey in ['IK3 MAX', 'IK3 MAX(KA)']) {
            if (_controllers.containsKey(ikKey)) {
              _controllers[ikKey]!.text = ik3Calculated;
            }
          }
        }
      }
    });
  }

  bool _hasAtLeastOneFieldFilled() {
    if (_selectedGamme != null && _selectedGamme!.isNotEmpty) return true;
    for (var c in widget.champs) {
      if (_isGammeField(c)) continue;
      if (_isDropdownField(c)) {
        if (_selectedValues[c] != null && _selectedValues[c]!.isNotEmpty)
          return true;
      } else {
        if (_controllers[c]?.text.trim().isNotEmpty == true) return true;
      }
    }
    return false;
  }

  void _save() {
    if (!_hasAtLeastOneFieldFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir au moins un champ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final result = widget.initialData != null
        ? Map<String, String>.from(widget.initialData!)
        : <String, String>{};
    for (var champ in widget.champs) {
      if (_isGammeField(champ)) {
        if (_selectedGamme != null && _selectedGamme!.isNotEmpty)
          result[champ] = _selectedGamme!;
      } else if (_isDropdownField(champ)) {
        final v = _selectedValues[champ];
        if (v != null && v.isNotEmpty) result[champ] = v;
      } else {
        final v = _controllers[champ]?.text.trim() ?? '';
        if (v.isNotEmpty) result[champ] = v;
      }
    }

    if (_selectedGeId != null && _selectedGeId!.isNotEmpty) {
      result['geId'] = _selectedGeId!;
    } else if (result.containsKey('geId')) {
      result.remove('geId');
    }

    Navigator.pop(context, result);
  }

  // ── Dropdown moderne avec option vide ──
  Widget _buildModernDropdown(
    BuildContext context,
    String champ, {
    required String? currentValue,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String? unitPrefixLabel,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final hasValue = currentValue != null && currentValue.isNotEmpty;
    final accent = AppTheme.primaryBlue;

    final effectiveOptions = List<String>.from(options);
    if (hasValue && !effectiveOptions.contains(currentValue)) {
      effectiveOptions.add(currentValue);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue ? accent.withOpacity(0.5) : Colors.grey.shade300,
          width: hasValue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: hasValue ? currentValue : null,
        isExpanded: true,
        iconSize: 0,
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: champ,
          labelStyle: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: hasValue ? accent : Colors.grey.shade500,
            fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 12 : 14,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasValue)
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.clear,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasValue ? accent : Colors.grey.shade400,
                  size: 22,
                ),
              ),
            ],
          ),
          prefixIcon: unitPrefixLabel != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4, top: 16),
                  child: Text(
                    unitPrefixLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        hint: Text(
          'Sélectionnez...',
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: Colors.grey.shade400,
          ),
        ),
        items: [
          DropdownMenuItem<String>(
            value: '',
            child: Row(
              children: [
                Icon(
                  Icons.remove_circle_outline,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  '— Aucun —',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          ...effectiveOptions.map(
            (opt) => DropdownMenuItem<String>(
              value: opt,
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (v) => onChanged(v == '' ? null : v),
        selectedItemBuilder: (ctx) => [
          Text(
            '—',
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey.shade400,
            ),
          ),
          ...effectiveOptions.map(
            (opt) => Text(
              opt,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String champ,
    TextEditingController controller,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final unit = widget.numericFieldsWithUnit[champ];
    final isNumeric = unit != null;
    final hasValue = controller.text.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue
              ? AppTheme.primaryBlue.withOpacity(0.4)
              : Colors.grey.shade300,
          width: hasValue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        maxLines: champ == 'Observations' ? 3 : 1,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          color: Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          labelText: champ,
          labelStyle: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: hasValue ? AppTheme.primaryBlue : Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 12 : 14,
          ),
          suffixIcon: (unit != null && unit.isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.only(right: 14, top: 16),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
        ),
      ),
    );
  }

  bool _isFieldReadOnly(String champ) {
    if (widget.isReadOnly) return true;

    final isCelluleAuto = widget.initialData?.containsKey('auditCelluleId') == true &&
        widget.initialData?['auditCelluleId']?.isNotEmpty == true;
    final isTransfoAuto = widget.initialData?.containsKey('auditTransformateurId') == true &&
        widget.initialData?['auditTransformateurId']?.isNotEmpty == true;
    final isAutomatic = isCelluleAuto || isTransfoAuto;

    if (!isAutomatic) return false;

    if (isCelluleAuto) {
      if (champ == 'Gamme De Cellule' || champ == 'Type De Cellule' || champ == 'Observations') {
        return true;
      }
      return false;
    } else {
      if (champ == 'Puissance Transformateur' ||
          champ == 'Tension' ||
          champ == 'Tension primaire / secondaire' ||
          champ == 'Tension primaire/secondaire' ||
          champ == 'TENSION PRIMAIRE/SECONDAIRE' ||
          champ == 'TENSION MT/BT' ||
          champ == 'Observations') {
        return true;
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.isReadOnly
              ? 'Consultation Cellule'
              : (widget.initialData != null ? 'Modifier' : 'Ajouter'),
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!widget.isReadOnly)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Origine / Localisation
              if (widget.localisation != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isReadOnly
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isReadOnly
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                      'ORIGINE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.isReadOnly
                              ? Colors.blue.shade800
                              : Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.localisation!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.isReadOnly
                              ? Colors.blue.shade900
                              : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Champs éditables ou en lecture seule granulaires
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.champs.map((champ) {
                  final readOnly = _isFieldReadOnly(champ);
                  
                  Widget champWidget;
                  // Gamme → masqué dans l'UI (donnée conservée en historique)
                  if (_isGammeField(champ)) {
                    champWidget = const SizedBox.shrink();
                  }
                  // Type de cellule → indépendant (liste officielle des 14 types + types legacy)
                  else if (_isTypeCelluleField(champ)) {
                    final currentVal = _selectedValues[champ];
                    final types = CelluleGammes.getTypesForGamme(_selectedGamme);
                    final availableOptions = (types.isNotEmpty && types.contains(currentVal))
                        ? types
                        : CelluleTypesRegistry.getAvailableTypes(currentVal);

                    champWidget = IgnorePointer(
                      ignoring: readOnly,
                      child: Opacity(
                        opacity: readOnly ? 0.4 : 1.0,
                        child: _buildModernDropdown(
                          context,
                          champ,
                          currentValue: currentVal,
                          options: availableOptions,
                          onChanged: (v) => setState(
                            () => _selectedValues[champ] = v,
                          ),
                        ),
                      ),
                    );
                  }
                  // Section de câble avec unité à gauche (préfixe)
                  else if (_isSectionCableField(champ)) {
                    champWidget = _buildModernDropdown(
                      context,
                      champ,
                      currentValue: _selectedValues[champ],
                      options: widget.sectionCableOptions,
                      unitPrefixLabel: 'mm²',
                      onChanged: (v) =>
                          setState(() => _selectedValues[champ] = v),
                    );
                  }
                  // Dropdowns standard
                  else if (_isDropdownField(champ)) {
                    champWidget = _buildModernDropdown(
                      context,
                      champ,
                      currentValue: _selectedValues[champ],
                      options: _optionsFor(champ),
                      onChanged: (v) => _onDropdownValueChanged(champ, v),
                    );
                  }
                  // TextField
                  else {
                    champWidget = _buildTextField(
                      context,
                      champ,
                      _controllers[champ]!,
                    );
                  }

                  if (_isTypeCelluleField(champ)) {
                    return champWidget; // Déjà enveloppé
                  }

                  return IgnorePointer(
                    ignoring: readOnly,
                    child: Opacity(
                      opacity: readOnly ? 0.65 : 1.0,
                      child: champWidget,
                    ),
                  );
                }).toList(),
              ),

              if (!widget.isReadOnly) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      widget.initialData != null
                          ? 'Mettre à jour'
                          : 'Enregistrer',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 14 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
              SizedBox(height: isSmallScreen ? 16 : 20),
            ],
          ),
        ),
      ),
    );
  }
}
