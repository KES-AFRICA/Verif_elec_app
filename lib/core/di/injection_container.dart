// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/backup_service.dart';
// Auth
import 'package:inspec_app/features/auth/domain/repositories/verificateur_repository.dart';
import 'package:inspec_app/features/auth/data/repositories/verificateur_repository_impl.dart';
import 'package:inspec_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:inspec_app/features/auth/domain/usecases/check_login_status_use_case.dart';
import 'package:inspec_app/features/auth/domain/usecases/get_current_user_use_case.dart';
// Mission
import 'package:inspec_app/features/mission/domain/repositories/mission_repository.dart';
import 'package:inspec_app/features/mission/data/repositories/mission_repository_impl.dart';
import 'package:inspec_app/features/mission/data/datasources/mission_local_data_source.dart';
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
// JSA
import 'package:inspec_app/features/jsa/domain/repositories/jsa_repository.dart';
import 'package:inspec_app/features/jsa/data/repositories/jsa_repository_impl.dart';
import 'package:inspec_app/features/jsa/data/datasources/jsa_local_data_source.dart';
import 'package:inspec_app/features/jsa/domain/usecases/get_jsa_by_mission_use_case.dart';
import 'package:inspec_app/features/jsa/domain/usecases/save_jsa_use_case.dart';
// Renseignements Généraux
import 'package:inspec_app/features/mission/domain/repositories/renseignements_generaux_repository.dart';
import 'package:inspec_app/features/mission/data/repositories/renseignements_generaux_repository_impl.dart';
import 'package:inspec_app/features/mission/data/datasources/renseignements_generaux_local_data_source.dart';
import 'package:inspec_app/features/mission/domain/usecases/get_renseignements_generaux_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/save_renseignements_generaux_use_case.dart';
// Description des Installations
import 'package:inspec_app/features/description_installations/domain/repositories/description_installations_repository.dart';
import 'package:inspec_app/features/description_installations/data/repositories/description_installations_repository_impl.dart';
import 'package:inspec_app/features/description_installations/data/datasources/description_installations_local_data_source.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/get_description_installations_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/save_description_installations_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/add_installation_item_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/update_installation_item_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/remove_installation_item_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/update_description_selection_use_case.dart';
// Audit des Installations
import 'package:inspec_app/features/audit_installations/domain/repositories/audit_installations_repository.dart';
import 'package:inspec_app/features/audit_installations/data/repositories/audit_installations_repository_impl.dart';
import 'package:inspec_app/features/audit_installations/data/datasources/audit_installations_local_data_source.dart';
import 'package:inspec_app/features/audit_installations/domain/usecases/get_audit_installations_use_case.dart';
import 'package:inspec_app/features/audit_installations/domain/usecases/save_audit_installations_use_case.dart';
// Audit Foudre
import 'package:inspec_app/features/foudre/domain/repositories/foudre_repository.dart';
import 'package:inspec_app/features/foudre/data/repositories/foudre_repository_impl.dart';
import 'package:inspec_app/features/foudre/data/datasources/foudre_local_data_source.dart';
import 'package:inspec_app/features/foudre/domain/usecases/get_foudre_observations_use_case.dart';
import 'package:inspec_app/features/foudre/domain/usecases/create_foudre_observation_use_case.dart';
import 'package:inspec_app/features/foudre/domain/usecases/update_foudre_observation_use_case.dart';
import 'package:inspec_app/features/foudre/domain/usecases/delete_foudre_observation_use_case.dart';
// Mesures et Essais
import 'package:inspec_app/features/mesures_essais/domain/repositories/mesures_essais_repository.dart';
import 'package:inspec_app/features/mesures_essais/data/repositories/mesures_essais_repository_impl.dart';
import 'package:inspec_app/features/mesures_essais/data/datasources/mesures_essais_local_data_source.dart';
import 'package:inspec_app/features/mesures_essais/domain/usecases/get_mesures_essais_use_case.dart';
import 'package:inspec_app/features/mesures_essais/domain/usecases/save_mesures_essais_use_case.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Enregistrement des services d'infrastructure
  sl.registerLazySingleton<HiveService>(() => HiveService());
  sl.registerLazySingleton<BackupService>(() => BackupService());

  // DataSources
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl());
  sl.registerLazySingleton<MissionLocalDataSource>(() => MissionLocalDataSourceImpl());
  sl.registerLazySingleton<JsaLocalDataSource>(() => JsaLocalDataSourceImpl());
  sl.registerLazySingleton<RenseignementsGenerauxLocalDataSource>(
    () => RenseignementsGenerauxLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<DescriptionInstallationsLocalDataSource>(
    () => DescriptionInstallationsLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<AuditInstallationsLocalDataSource>(
    () => AuditInstallationsLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<FoudreLocalDataSource>(
    () => FoudreLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<MesuresEssaisLocalDataSource>(
    () => MesuresEssaisLocalDataSourceImpl(),
  );

  // Repositories (avec injection de DataSource)
  sl.registerLazySingleton<VerificateurRepository>(
    () => VerificateurRepositoryImpl(authLocalDataSource: sl()),
  );
  sl.registerLazySingleton<MissionRepository>(
    () => MissionRepositoryImpl(missionLocalDataSource: sl()),
  );
  sl.registerLazySingleton<JsaRepository>(
    () => JsaRepositoryImpl(jsaLocalDataSource: sl()),
  );
  sl.registerLazySingleton<RenseignementsGenerauxRepository>(
    () => RenseignementsGenerauxRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<DescriptionInstallationsRepository>(
    () => DescriptionInstallationsRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<AuditInstallationsRepository>(
    () => AuditInstallationsRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<FoudreRepository>(
    () => FoudreRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<MesuresEssaisRepository>(
    () => MesuresEssaisRepositoryImpl(localDataSource: sl()),
  );

  // UseCases
  sl.registerLazySingleton<CheckLoginStatusUseCase>(() => CheckLoginStatusUseCase(repository: sl()));
  sl.registerLazySingleton<GetCurrentUserUseCase>(() => GetCurrentUserUseCase(repository: sl()));
  sl.registerLazySingleton<GetMissionsUseCase>(() => GetMissionsUseCase(repository: sl()));
  sl.registerLazySingleton<GetMissionByIdUseCase>(() => GetMissionByIdUseCase(repository: sl()));
  sl.registerLazySingleton<UpdateDocumentStatusUseCase>(
    () => UpdateDocumentStatusUseCase(repository: sl()),
  );
  sl.registerLazySingleton<AddDocumentPersonnaliseUseCase>(
    () => AddDocumentPersonnaliseUseCase(repository: sl()),
  );
  sl.registerLazySingleton<RemoveDocumentPersonnaliseUseCase>(
    () => RemoveDocumentPersonnaliseUseCase(repository: sl()),
  );
  sl.registerLazySingleton<UpdateSchemaOptionUseCase>(
    () => UpdateSchemaOptionUseCase(repository: sl()),
  );
  sl.registerLazySingleton<UpdateCentralePhotovoltaiqueUseCase>(
    () => UpdateCentralePhotovoltaiqueUseCase(repository: sl()),
  );
  sl.registerLazySingleton<UpdateMissionStatusUseCase>(
    () => UpdateMissionStatusUseCase(repository: sl()),
  );
  sl.registerLazySingleton<SaveLastReportUseCase>(
    () => SaveLastReportUseCase(repository: sl()),
  );
  sl.registerLazySingleton<GetAllReportsForMissionUseCase>(
    () => GetAllReportsForMissionUseCase(repository: sl()),
  );
  sl.registerLazySingleton<GetJsaByMissionUseCase>(() => GetJsaByMissionUseCase(repository: sl()));
  sl.registerLazySingleton<SaveJsaUseCase>(() => SaveJsaUseCase(repository: sl()));
  sl.registerLazySingleton<GetRenseignementsGenerauxUseCase>(
    () => GetRenseignementsGenerauxUseCase(repository: sl()),
  );
  sl.registerLazySingleton<SaveRenseignementsGenerauxUseCase>(
    () => SaveRenseignementsGenerauxUseCase(repository: sl()),
  );
  sl.registerLazySingleton<GetDescriptionInstallationsUseCase>(
    () => GetDescriptionInstallationsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<SaveDescriptionInstallationsUseCase>(
    () => SaveDescriptionInstallationsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<AddInstallationItemUseCase>(
    () => AddInstallationItemUseCase(repository: sl()),
  );
  sl.registerLazySingleton<UpdateInstallationItemUseCase>(
    () => UpdateInstallationItemUseCase(repository: sl()),
  );
  sl.registerLazySingleton<RemoveInstallationItemUseCase>(
    () => RemoveInstallationItemUseCase(repository: sl()),
  );
  sl.registerLazySingleton<UpdateDescriptionSelectionUseCase>(
    () => UpdateDescriptionSelectionUseCase(repository: sl()),
  );
  sl.registerLazySingleton<GetAuditInstallationsUseCase>(
    () => GetAuditInstallationsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<SaveAuditInstallationsUseCase>(
    () => SaveAuditInstallationsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<GetFoudreObservationsUseCase>(
    () => GetFoudreObservationsUseCase(repository: sl()),
  );
  sl.registerLazySingleton<CreateFoudreObservationUseCase>(
    () => CreateFoudreObservationUseCase(repository: sl()),
  );
  sl.registerLazySingleton<UpdateFoudreObservationUseCase>(
    () => UpdateFoudreObservationUseCase(repository: sl()),
  );
  sl.registerLazySingleton<DeleteFoudreObservationUseCase>(
    () => DeleteFoudreObservationUseCase(repository: sl()),
  );
  sl.registerLazySingleton<GetMesuresEssaisUseCase>(
    () => GetMesuresEssaisUseCase(repository: sl()),
  );
  sl.registerLazySingleton<SaveMesuresEssaisUseCase>(
    () => SaveMesuresEssaisUseCase(repository: sl()),
  );
}
