// lib/features/mission/presentation/providers/mission_detail_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/core/providers/mission_providers.dart';
import 'package:inspec_app/features/mission/data/mappers/mission_mapper.dart';
import 'package:inspec_app/models/mission.dart';

final missionDetailProvider = StateNotifierProvider.family.autoDispose<
    MissionDetailNotifier,
    AsyncValue<Mission>,
    String>((ref, missionId) {
  return MissionDetailNotifier(ref: ref, missionId: missionId);
});

class MissionDetailNotifier extends StateNotifier<AsyncValue<Mission>> {
  final Ref ref;
  final String missionId;

  MissionDetailNotifier({required this.ref, required this.missionId})
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final getUseCase = ref.read(getMissionByIdUseCaseProvider);
      final entity = getUseCase(missionId);
      if (entity != null) {
        final model = MissionMapper.toModel(entity);
        state = AsyncValue.data(model);
      } else {
        state = AsyncValue.error(
            Exception('Mission non trouvée'), StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateDocumentStatus(String documentField, bool value) async {
    final current = state.value;
    if (current == null) return;

    try {
      // Mettre à jour l'état local
      switch (documentField) {
        case 'doc_cahier_prescriptions':
          current.docCahierPrescriptions = value;
          break;
        case 'doc_notes_calculs':
          current.docNotesCalculs = value;
          break;
        case 'doc_schemas_unifilaires':
          current.docSchemasUnifilaires = value;
          break;
        case 'doc_plan_masse':
          current.docPlanMasse = value;
          break;
        case 'doc_plans_architecturaux':
          current.docPlansArchitecturaux = value;
          break;
        case 'doc_declarations_ce':
          current.docDeclarationsCe = value;
          break;
        case 'doc_liste_installations':
          current.docListeInstallations = value;
          break;
        case 'doc_plan_locaux_risques':
          current.docPlanLocauxRisques = value;
          break;
        case 'doc_rapport_analyse_foudre':
          current.docRapportAnalyseFoudre = value;
          break;
        case 'doc_rapport_etude_foudre':
          current.docRapportEtudeFoudre = value;
          break;
        case 'doc_registre_securite':
          current.docRegistreSecurite = value;
          break;
        case 'doc_rapport_derniere_verif':
          current.docRapportDerniereVerif = value;
          break;
        case 'doc_autre':
          current.docAutre = value;
          break;
      }
      current.updatedAt = DateTime.now();
      state = AsyncValue.data(current);

      // Persister dans Hive via le Use Case
      final updateUseCase = ref.read(updateDocumentStatusUseCaseProvider);
      await updateUseCase(
        missionId: missionId,
        documentField: documentField,
        value: value,
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateSchemaOption(String option) async {
    final current = state.value;
    if (current == null) return;

    try {
      current.schemaOption = option;
      current.updatedAt = DateTime.now();
      state = AsyncValue.data(current);

      final updateUseCase = ref.read(updateSchemaOptionUseCaseProvider);
      await updateUseCase(
        missionId: missionId,
        option: option,
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateCentralePhotovoltaique(String option) async {
    final current = state.value;
    if (current == null) return;

    try {
      current.centralePhotovoltaique = option;
      current.updatedAt = DateTime.now();
      state = AsyncValue.data(current);

      final updateUseCase = ref.read(updateCentralePhotovoltaiqueUseCaseProvider);
      await updateUseCase(
        missionId: missionId,
        option: option,
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addDocumentPersonnalise(String documentName) async {
    final current = state.value;
    if (current == null) return false;

    try {
      final addUseCase = ref.read(addDocumentPersonnaliseUseCaseProvider);
      final success = await addUseCase(
        missionId: missionId,
        documentName: documentName,
      );

      if (success) {
        // Recharger le modèle depuis la DB locale pour garantir la cohérence
        await load();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeDocumentPersonnalise(String documentName) async {
    final current = state.value;
    if (current == null) return false;

    try {
      final removeUseCase = ref.read(removeDocumentPersonnaliseUseCaseProvider);
      final success = await removeUseCase(
        missionId: missionId,
        documentName: documentName,
      );

      if (success) {
        // Recharger le modèle depuis la DB locale
        await load();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateMissionStatus(String status) async {
    final current = state.value;
    if (current == null) return;

    try {
      current.status = status;
      current.updatedAt = DateTime.now();
      state = AsyncValue.data(current);

      final updateUseCase = ref.read(updateMissionStatusUseCaseProvider);
      await updateUseCase(
        missionId: missionId,
        status: status,
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
