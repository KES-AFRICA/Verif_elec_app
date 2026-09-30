import 'package:inspec_app/models/last_report.dart';
import '../entities/mission_entity.dart';

abstract class MissionRepository {
  List<MissionEntity> getMissionsByMatricule(String matricule);
  MissionEntity? getMissionById(String id);
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
