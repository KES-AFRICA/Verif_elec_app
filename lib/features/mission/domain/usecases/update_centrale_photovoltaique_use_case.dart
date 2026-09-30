// lib/features/mission/domain/usecases/update_centrale_photovoltaique_use_case.dart
import '../repositories/mission_repository.dart';

class UpdateCentralePhotovoltaiqueUseCase {
  final MissionRepository repository;

  UpdateCentralePhotovoltaiqueUseCase({required this.repository});

  Future<bool> call({required String missionId, required String option}) async {
    return await repository.updateCentralePhotovoltaique(missionId: missionId, option: option);
  }
}
