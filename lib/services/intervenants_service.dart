// lib/services/intervenants_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/hive_service.dart';

/// Service centralisé assurant que la Mission (`mission.verificateurs`) est la
/// Source de Vérité Unique (SSOT) pour l'ensemble des vérificateurs / inspecteurs.
/// 
/// Garantit :
/// - `Mission.verificateurs` comme SSOT absolu, propageant vers la JSA et les Renseignements Généraux.
/// - Déduplication stricte par matricule ou couple (nom + prénom).
/// - Enrôlement automatique et idempotent de l'utilisateur courant.
/// - Préservation intégrale et survie lors des cycles export / import.
/// - Rétrocompatibilité totale avec les composants d'interface et d'édition existants.
class IntervenantsService {
  /// Déduplique de façon robuste et déterministe une liste brute de vérificateurs.
  static List<Map<String, dynamic>> deduplicateVerificateursList(List<dynamic> rawList) {
    final result = <Map<String, dynamic>>[];
    for (final item in rawList) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final nom = (m['nom'] ?? '').toString().trim();
      final prenom = (m['prenom'] ?? '').toString().trim();
      final matricule = (m['matricule'] ?? '').toString().trim();
      if (nom.isEmpty && prenom.isEmpty && matricule.isEmpty) continue;

      final existingIndex = result.indexWhere((existing) {
        final exMat = (existing['matricule'] ?? '').toString().trim();
        if (matricule.isNotEmpty && exMat.isNotEmpty && matricule.toLowerCase() == exMat.toLowerCase()) {
          return true;
        }
        final exNom = (existing['nom'] ?? '').toString().trim().toLowerCase();
        final exPrenom = (existing['prenom'] ?? '').toString().trim().toLowerCase();
        return nom.toLowerCase() == exNom && prenom.toLowerCase() == exPrenom;
      });

      if (existingIndex >= 0) {
        // Enrichir le matricule, rôle ou email si manquant
        if (matricule.isNotEmpty &&
            (result[existingIndex]['matricule'] == null ||
             result[existingIndex]['matricule'].toString().trim().isEmpty)) {
          result[existingIndex]['matricule'] = matricule;
        }
        final email = (m['email'] ?? '').toString().trim();
        if (email.isNotEmpty &&
            (result[existingIndex]['email'] == null ||
             result[existingIndex]['email'].toString().trim().isEmpty)) {
          result[existingIndex]['email'] = email;
        }
        final role = (m['role'] ?? '').toString().trim();
        if (role.isNotEmpty &&
            (result[existingIndex]['role'] == null ||
             result[existingIndex]['role'].toString().trim().isEmpty ||
             result[existingIndex]['role'] == 'Inspecteur')) {
          result[existingIndex]['role'] = role;
        }
      } else {
        result.add({
          'nom': nom,
          'prenom': prenom,
          'matricule': matricule,
          'role': (m['role'] ?? m['fonction'] ?? 'Inspecteur').toString().trim(),
          'email': (m['email'] ?? '').toString().trim(),
        });
      }
    }
    return result;
  }

  /// S'assure que l'utilisateur courant (ou les données transmises en repli)
  /// est inscrit dans la Mission (SSOT) de façon strictement idempotente et dédupliquée.
  static Future<void> ensureCurrentUserInMission(
    String missionId, {
    String? fallbackMatricule,
    String? fallbackNom,
    String? fallbackPrenom,
  }) async {
    try {
      if (missionId.trim().isEmpty) return;

      final currentUser = HiveService.getCurrentUser();
      String nom = currentUser?.nom.trim() ?? '';
      String prenom = currentUser?.prenom.trim() ?? '';
      String? matricule = currentUser?.matricule.trim();
      String? email = currentUser?.email.trim();
      String role = 'Inspecteur';

      if (nom.isEmpty && fallbackNom != null) {
        nom = fallbackNom.trim();
      }
      if (prenom.isEmpty && fallbackPrenom != null) {
        prenom = fallbackPrenom.trim();
      }
      if ((matricule == null || matricule.isEmpty) && fallbackMatricule != null) {
        matricule = fallbackMatricule.trim();
      }

      // Si aucune identité n'est disponible, rien à inscrire
      if (nom.isEmpty && prenom.isEmpty && (matricule == null || matricule.isEmpty)) {
        return;
      }

      final mission = HiveService.getMissionById(missionId);
      if (mission != null) {
        mission.verificateurs ??= [];
        final rawList = List<Map<String, dynamic>>.from(mission.verificateurs!);
        rawList.add({
          'nom': nom,
          'prenom': prenom,
          'matricule': matricule ?? '',
          'email': email ?? '',
          'role': role,
        });

        mission.verificateurs = deduplicateVerificateursList(rawList);
        await mission.save();

        // Propager unilatéralement du SSOT (Mission) vers JSA et RG
        await syncMissionVerificateursToJsaAndRg(missionId, mission: mission);
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('⚠️ IntervenantsService.ensureCurrentUserInMission error: $e\n$st');
      }
    }
  }

  /// Alias de rétrocompatibilité : assure la présence de l'utilisateur dans la Mission (SSOT)
  /// et propage vers la JSA.
  static Future<void> ensureCurrentUserInJSA(
    String missionId, {
    String? fallbackMatricule,
    String? fallbackNom,
    String? fallbackPrenom,
  }) async {
    await ensureCurrentUserInMission(
      missionId,
      fallbackMatricule: fallbackMatricule,
      fallbackNom: fallbackNom,
      fallbackPrenom: fallbackPrenom,
    );
  }

  /// Récupère la liste des intervenants pour une mission.
  /// Priorité absolue : Mission (SSOT).
  /// Fallbacks résilients : RG -> JSA -> CurrentUser.
  static List<JSAInspecteur> getMissionIntervenants(
    String missionId, {
    Mission? mission,
    RenseignementsGeneraux? rg,
    JSA? jsa,
  }) {
    final effectiveMission = mission ?? HiveService.getMissionById(missionId);
    final fallbackList = <JSAInspecteur>[];

    // 1. Priorité absolue : Mission.verificateurs (SSOT)
    if (effectiveMission?.verificateurs != null && effectiveMission!.verificateurs!.isNotEmpty) {
      final deduplicated = deduplicateVerificateursList(effectiveMission.verificateurs!);
      for (final v in deduplicated) {
        final vNom = (v['nom'] ?? '').toString().trim();
        final vPrenom = (v['prenom'] ?? '').toString().trim();
        final vMatricule = (v['matricule'] ?? '').toString().trim();
        final vRole = (v['role'] ?? 'Inspecteur').toString().trim();
        final vEmail = (v['email'] ?? '').toString().trim();
        JSAUtils.addInspectorIfAbsent(
          fallbackList,
          vNom,
          vPrenom,
          matricule: vMatricule.isNotEmpty ? vMatricule : null,
          role: vRole.isNotEmpty ? vRole : null,
          email: vEmail.isNotEmpty ? vEmail : null,
        );
      }
      if (fallbackList.isNotEmpty) {
        return fallbackList;
      }
    }

    // 2. Fallback RG
    final effectiveRg = rg ?? HiveService.getRenseignementsGenerauxByMissionId(missionId);
    if (effectiveRg != null && effectiveRg.verificateurs.isNotEmpty) {
      final deduplicatedRg = deduplicateVerificateursList(effectiveRg.verificateurs);
      for (final v in deduplicatedRg) {
        final vNom = (v['nom'] ?? '').toString().trim();
        final vPrenom = (v['prenom'] ?? '').toString().trim();
        final vRole = (v['fonction'] ?? v['role'] ?? 'Inspecteur').toString().trim();
        final vMatricule = (v['matricule'] ?? '').toString().trim();
        JSAUtils.addInspectorIfAbsent(
          fallbackList,
          vNom,
          vPrenom,
          matricule: vMatricule.isNotEmpty ? vMatricule : null,
          role: vRole.isNotEmpty ? vRole : null,
        );
      }
      if (fallbackList.isNotEmpty) {
        return fallbackList;
      }
    }

    // 3. Fallback JSA
    final effectiveJsa = jsa ?? HiveService.getJSAByMissionId(missionId);
    if (effectiveJsa != null && effectiveJsa.inspecteurs.isNotEmpty) {
      for (final insp in effectiveJsa.inspecteurs) {
        JSAUtils.addInspectorIfAbsent(
          fallbackList,
          insp.nom,
          insp.prenom,
          matricule: insp.matricule,
          email: insp.email,
          role: insp.role,
        );
      }
      if (fallbackList.isNotEmpty) {
        return fallbackList;
      }
    }

    // 4. Fallback CurrentUser
    final currentUser = HiveService.getCurrentUser();
    if (currentUser != null && (currentUser.nom.isNotEmpty || currentUser.prenom.isNotEmpty)) {
      fallbackList.add(JSAInspecteur(
        nom: currentUser.nom.trim(),
        prenom: currentUser.prenom.trim(),
        matricule: currentUser.matricule.trim().isNotEmpty ? currentUser.matricule.trim() : null,
        email: currentUser.email.trim().isNotEmpty ? currentUser.email.trim() : null,
        role: 'Inspecteur',
      ));
    }

    return fallbackList;
  }

  /// Retourne la liste des noms formatés des intervenants pour les rapports (dédupliqués).
  static List<String> getMissionIntervenantsNoms(
    String missionId, {
    Mission? mission,
    RenseignementsGeneraux? rg,
    JSA? jsa,
    bool uppercase = true,
  }) {
    final intervenants = getMissionIntervenants(
      missionId,
      mission: mission,
      rg: rg,
      jsa: jsa,
    );

    final noms = <String>[];
    for (final insp in intervenants) {
      final fullName = '${insp.prenom} ${insp.nom}'.trim();
      if (fullName.isNotEmpty) {
        final formatted = uppercase ? fullName.toUpperCase() : fullName;
        if (!noms.contains(formatted)) {
          noms.add(formatted);
        }
      }
    }

    if (noms.isEmpty) {
      return ['Non spécifié'];
    }
    return noms;
  }

  /// Synchronise unilatéralement du SSOT (`Mission.verificateurs`) vers la JSA et les Renseignements Généraux.
  static Future<void> syncMissionVerificateursToJsaAndRg(
    String missionId, {
    Mission? mission,
  }) async {
    try {
      final effectiveMission = mission ?? HiveService.getMissionById(missionId);
      if (effectiveMission == null) return;

      // Récupérer et dédupliquer les vérificateurs de la mission
      var verifs = effectiveMission.verificateurs != null
          ? deduplicateVerificateursList(effectiveMission.verificateurs!)
          : <Map<String, dynamic>>[];

      // Si la mission n'en a pas encore, tenter de migrer depuis JSA ou RG pour amorcer le SSOT
      if (verifs.isEmpty) {
        final jsa = HiveService.getJSAByMissionId(missionId);
        final rg = HiveService.getRenseignementsGenerauxByMissionId(missionId);
        final fallbackInspectors = getMissionIntervenants(
          missionId,
          mission: effectiveMission,
          rg: rg,
          jsa: jsa,
        );
        if (fallbackInspectors.isNotEmpty) {
          verifs = fallbackInspectors.map((i) => {
            'nom': i.nom,
            'prenom': i.prenom,
            'matricule': i.matricule ?? '',
            'role': i.role ?? 'Inspecteur',
            'email': i.email ?? '',
          }).toList();
          effectiveMission.verificateurs = verifs;
          await effectiveMission.save();
        }
      }

      if (verifs.isEmpty) return;

      // 1. Synchroniser JSA
      var jsa = HiveService.getJSAByMissionId(missionId);
      if (jsa == null) {
        jsa = await HiveService.getOrCreateJSA(missionId);
      }
      bool jsaChanged = false;
      for (final v in verifs) {
        final added = JSAUtils.addInspectorIfAbsent(
          jsa.inspecteurs,
          v['nom'] ?? '',
          v['prenom'] ?? '',
          matricule: (v['matricule'] != null && v['matricule'].toString().isNotEmpty) ? v['matricule'] : null,
          role: (v['role'] != null && v['role'].toString().isNotEmpty) ? v['role'] : null,
          email: (v['email'] != null && v['email'].toString().isNotEmpty) ? v['email'] : null,
        );
        if (added) jsaChanged = true;
      }
      if (jsaChanged) {
        await HiveService.saveJSA(jsa);
      }

      // 2. Synchroniser RenseignementsGeneraux
      if (Hive.isBoxOpen('renseignements_generaux')) {
        final rgBox = Hive.box<RenseignementsGeneraux>('renseignements_generaux');
        final rg = rgBox.values.cast<RenseignementsGeneraux?>().firstWhere(
          (r) => r?.missionId == missionId,
          orElse: () => null,
        );
        if (rg != null) {
          rg.verificateurs = verifs
              .map((v) => v.map((k, val) => MapEntry(k, val?.toString() ?? '')))
              .toList();
          await rg.save();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ syncMissionVerificateursToJsaAndRg error: $e');
      }
    }
  }

  /// Migre les intervenants legacy vers la JSA (méthode de transition)
  static int syncLegacyInspectorsToJSA(
    JSA jsa,
    Mission? mission,
    RenseignementsGeneraux? rg,
  ) {
    int addedCount = 0;
    if (mission?.verificateurs != null && mission!.verificateurs!.isNotEmpty) {
      for (final v in mission.verificateurs!) {
        final vNom = (v['nom'] ?? '').toString().trim();
        final vPrenom = (v['prenom'] ?? '').toString().trim();
        final vMatricule = (v['matricule'] ?? '').toString().trim();
        final vRole = (v['role'] ?? '').toString().trim();
        final added = JSAUtils.addInspectorIfAbsent(
          jsa.inspecteurs,
          vNom,
          vPrenom,
          matricule: vMatricule.isNotEmpty ? vMatricule : null,
          role: vRole.isNotEmpty ? vRole : null,
        );
        if (added) addedCount++;
      }
    }
    if (rg != null && rg.verificateurs.isNotEmpty) {
      for (final v in rg.verificateurs) {
        final vNom = (v['nom'] ?? '').toString().trim();
        final vPrenom = (v['prenom'] ?? '').toString().trim();
        final vFonction = (v['fonction'] ?? '').toString().trim();
        final added = JSAUtils.addInspectorIfAbsent(
          jsa.inspecteurs,
          vNom,
          vPrenom,
          role: vFonction.isNotEmpty ? vFonction : null,
        );
        if (added) addedCount++;
      }
    }
    return addedCount;
  }
}
