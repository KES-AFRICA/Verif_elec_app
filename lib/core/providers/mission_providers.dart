// lib/core/providers/mission_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/features/mission/domain/usecases/get_missions_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/get_mission_by_id_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/update_document_status_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/add_document_personnalise_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/remove_document_personnalise_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/update_schema_option_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/update_centrale_photovoltaique_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/update_mission_status_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/save_last_report_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/get_all_reports_for_mission_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/get_renseignements_generaux_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/save_renseignements_generaux_use_case.dart';

final getMissionsUseCaseProvider = Provider<GetMissionsUseCase>((ref) {
  return GetIt.instance<GetMissionsUseCase>();
});

final getMissionByIdUseCaseProvider = Provider<GetMissionByIdUseCase>((ref) {
  return GetIt.instance<GetMissionByIdUseCase>();
});

final updateDocumentStatusUseCaseProvider = Provider<UpdateDocumentStatusUseCase>((ref) {
  return GetIt.instance<UpdateDocumentStatusUseCase>();
});

final addDocumentPersonnaliseUseCaseProvider = Provider<AddDocumentPersonnaliseUseCase>((ref) {
  return GetIt.instance<AddDocumentPersonnaliseUseCase>();
});

final removeDocumentPersonnaliseUseCaseProvider = Provider<RemoveDocumentPersonnaliseUseCase>((ref) {
  return GetIt.instance<RemoveDocumentPersonnaliseUseCase>();
});

final updateSchemaOptionUseCaseProvider = Provider<UpdateSchemaOptionUseCase>((ref) {
  return GetIt.instance<UpdateSchemaOptionUseCase>();
});

final updateCentralePhotovoltaiqueUseCaseProvider = Provider<UpdateCentralePhotovoltaiqueUseCase>((ref) {
  return GetIt.instance<UpdateCentralePhotovoltaiqueUseCase>();
});

final updateMissionStatusUseCaseProvider = Provider<UpdateMissionStatusUseCase>((ref) {
  return GetIt.instance<UpdateMissionStatusUseCase>();
});

final saveLastReportUseCaseProvider = Provider<SaveLastReportUseCase>((ref) {
  return GetIt.instance<SaveLastReportUseCase>();
});

final getAllReportsForMissionUseCaseProvider = Provider<GetAllReportsForMissionUseCase>((ref) {
  return GetIt.instance<GetAllReportsForMissionUseCase>();
});

final getRenseignementsGenerauxUseCaseProvider = Provider<GetRenseignementsGenerauxUseCase>((ref) {
  return GetIt.instance<GetRenseignementsGenerauxUseCase>();
});

final saveRenseignementsGenerauxUseCaseProvider = Provider<SaveRenseignementsGenerauxUseCase>((ref) {
  return GetIt.instance<SaveRenseignementsGenerauxUseCase>();
});
