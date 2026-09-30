import 'package:hive/hive.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/last_report.dart';

abstract class MissionLocalDataSource {
  List<Mission> getMissionsByMatricule(String matricule);
  Mission? getMissionById(String id);
  Future<bool> updateDocumentStatus({
    required String missionId,
    required String documentField,
    required bool value,
  });
  Future<bool> addDocumentPersonnalise({
    required String missionId,
    required String documentName,
  });
  Future<bool> removeDocumentPersonnalise({
    required String missionId,
    required String documentName,
  });
  Future<bool> updateSchemaOption({
    required String missionId,
    required String option,
  });
  Future<bool> updateCentralePhotovoltaique({
    required String missionId,
    required String option,
  });
  Future<bool> updateMissionStatus({
    required String missionId,
    required String status,
  });
  Future<void> saveLastReport(LastReport report);
  Future<List<LastReport>> getAllReportsForMission(String missionId);
}

class MissionLocalDataSourceImpl implements MissionLocalDataSource {
  static const String _missionBox = 'missions';

  @override
  List<Mission> getMissionsByMatricule(String matricule) {
    final box = Hive.box<Mission>(_missionBox);
    return box.values.where((mission) {
      if (mission.verificateurs == null) return false;
      return mission.verificateurs!.any((v) => v['matricule'] == matricule);
    }).toList();
  }

  @override
  Mission? getMissionById(String id) {
    final box = Hive.box<Mission>(_missionBox);
    return box.get(id);
  }

  @override
  Future<bool> updateDocumentStatus({
    required String missionId,
    required String documentField,
    required bool value,
  }) async {
    try {
      final box = Hive.box<Mission>(_missionBox);
      final mission = box.get(missionId);

      if (mission == null) return false;

      switch (documentField) {
        case 'doc_cahier_prescriptions':
          mission.docCahierPrescriptions = value;
          break;
        case 'doc_notes_calculs':
          mission.docNotesCalculs = value;
          break;
        case 'doc_schemas_unifilaires':
          mission.docSchemasUnifilaires = value;
          break;
        case 'doc_plan_masse':
          mission.docPlanMasse = value;
          break;
        case 'doc_plans_architecturaux':
          mission.docPlansArchitecturaux = value;
          break;
        case 'doc_declarations_ce':
          mission.docDeclarationsCe = value;
          break;
        case 'doc_liste_installations':
          mission.docListeInstallations = value;
          break;
        case 'doc_plan_locaux_risques':
          mission.docPlanLocauxRisques = value;
          break;
        case 'doc_rapport_analyse_foudre':
          mission.docRapportAnalyseFoudre = value;
          break;
        case 'doc_rapport_etude_foudre':
          mission.docRapportEtudeFoudre = value;
          break;
        case 'doc_registre_securite':
          mission.docRegistreSecurite = value;
          break;
        case 'doc_rapport_derniere_verif':
          mission.docRapportDerniereVerif = value;
          break;
        case 'doc_autre':
          mission.docAutre = value;
          break;
        default:
          return false;
      }

      mission.updatedAt = DateTime.now();
      await mission.save();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> addDocumentPersonnalise({
    required String missionId,
    required String documentName,
  }) async {
    try {
      final box = Hive.box<Mission>(_missionBox);
      final mission = box.get(missionId);

      if (mission == null) return false;

      final nomClean = documentName.trim();
      if (nomClean.isEmpty) return false;

      if (mission.autresDocuments == null) {
        mission.autresDocuments = [];
      }

      if (!mission.autresDocuments.contains(nomClean)) {
        mission.autresDocuments.add(nomClean);
        mission.updatedAt = DateTime.now();
        await mission.save();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeDocumentPersonnalise({
    required String missionId,
    required String documentName,
  }) async {
    try {
      final box = Hive.box<Mission>(_missionBox);
      final mission = box.get(missionId);

      if (mission == null || mission.autresDocuments == null) return false;

      final removed = mission.autresDocuments.remove(documentName);
      if (removed) {
        mission.updatedAt = DateTime.now();
        await mission.save();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateSchemaOption({
    required String missionId,
    required String option,
  }) async {
    try {
      final box = Hive.box<Mission>(_missionBox);
      final mission = box.get(missionId);
      if (mission == null) return false;
      
      mission.schemaOption = option;
      mission.updatedAt = DateTime.now();
      await mission.save();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateCentralePhotovoltaique({
    required String missionId,
    required String option,
  }) async {
    try {
      final box = Hive.box<Mission>(_missionBox);
      final mission = box.get(missionId);
      if (mission == null) return false;
      
      mission.centralePhotovoltaique = option;
      mission.updatedAt = DateTime.now();
      await mission.save();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateMissionStatus({
    required String missionId,
    required String status,
  }) async {
    try {
      final box = Hive.box<Mission>(_missionBox);
      final mission = box.get(missionId);
      if (mission == null) return false;
      
      mission.status = status;
      mission.updatedAt = DateTime.now();
      await mission.save();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> saveLastReport(LastReport report) async {
    final box = await Hive.openBox<LastReport>('last_reports');
    await box.add(report);
  }

  @override
  Future<List<LastReport>> getAllReportsForMission(String missionId) async {
    final box = await Hive.openBox<LastReport>('last_reports');
    return box.values.where((r) => r.missionId == missionId).toList();
  }
}
