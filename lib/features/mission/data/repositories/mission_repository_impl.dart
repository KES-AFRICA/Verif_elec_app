// lib/features/mission/data/repositories/mission_repository_impl.dart
import '../../domain/entities/mission_entity.dart';
import '../../domain/repositories/mission_repository.dart';
import '../datasources/mission_local_data_source.dart';
import '../mappers/mission_mapper.dart';

import 'package:inspec_app/models/last_report.dart';

class MissionRepositoryImpl implements MissionRepository {
  final MissionLocalDataSource missionLocalDataSource;

  MissionRepositoryImpl({required this.missionLocalDataSource});

  @override
  List<MissionEntity> getMissionsByMatricule(String matricule) {
    final models = missionLocalDataSource.getMissionsByMatricule(matricule);
    return models.map(MissionMapper.toEntity).toList();
  }

  @override
  MissionEntity? getMissionById(String id) {
    final model = missionLocalDataSource.getMissionById(id);
    return model != null ? MissionMapper.toEntity(model) : null;
  }

  @override
  Future<bool> updateDocumentStatus({
    required String missionId,
    required String documentField,
    required bool value,
  }) {
    return missionLocalDataSource.updateDocumentStatus(
      missionId: missionId,
      documentField: documentField,
      value: value,
    );
  }

  @override
  Future<bool> addDocumentPersonnalise({
    required String missionId,
    required String documentName,
  }) {
    return missionLocalDataSource.addDocumentPersonnalise(
      missionId: missionId,
      documentName: documentName,
    );
  }

  @override
  Future<bool> removeDocumentPersonnalise({
    required String missionId,
    required String documentName,
  }) {
    return missionLocalDataSource.removeDocumentPersonnalise(
      missionId: missionId,
      documentName: documentName,
    );
  }

  @override
  Future<bool> updateSchemaOption({
    required String missionId,
    required String option,
  }) {
    return missionLocalDataSource.updateSchemaOption(
      missionId: missionId,
      option: option,
    );
  }

  @override
  Future<bool> updateCentralePhotovoltaique({
    required String missionId,
    required String option,
  }) {
    return missionLocalDataSource.updateCentralePhotovoltaique(
      missionId: missionId,
      option: option,
    );
  }

  @override
  Future<bool> updateMissionStatus({
    required String missionId,
    required String status,
  }) {
    return missionLocalDataSource.updateMissionStatus(
      missionId: missionId,
      status: status,
    );
  }

  @override
  Future<void> saveLastReport(LastReport report) {
    return missionLocalDataSource.saveLastReport(report);
  }

  @override
  Future<List<LastReport>> getAllReportsForMission(String missionId) {
    return missionLocalDataSource.getAllReportsForMission(missionId);
  }
}
