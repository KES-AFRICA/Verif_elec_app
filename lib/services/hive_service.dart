import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/models/last_report.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/secure_password_service.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import '../models/verificateur.dart';
import '../models/mission.dart';
import '../models/renseignements_generaux.dart';

import 'package:inspec_app/models/trash_item.dart';
import 'package:inspec_app/services/trash_service.dart';
import 'dispositions_constructives_registry.dart';
import 'installation_description_sync_service.dart';
import 'normative_matching/mission_normative_batch_service.dart';
import 'equipment_number_service.dart';
import 'ip_ik_evaluator_service.dart';
import 'persistence_queue.dart';
import 'package:inspec_app/features/backup/data/services/mission_activity_tracker.dart';
import '../utils/normative_reference_cleaner.dart';
import 'intervenants_service.dart';

class HiveService {
  static const String _verificateurBox = 'verificateurs';
  static const String _missionBox = 'missions';
  static const String _currentUserKey = 'current_user';
  static const String _descriptionBox = 'description_installations';
  static const String _auditBox = 'audit_installations_electriques';
  static const String _classementBox = 'classement_locaux';
  static const String _foudreBox = 'foudre_observations';
  static const String _mesuresEssaisBox = 'mesures_essais';
  static const String _jsaBox = 'jsa';
  static const String _coffretDraftsBox = 'coffret_drafts';
  static const String _classementZoneBox = 'classement_zones';
  static const String _localDraftsBox = 'local_drafts';
  static const String _lightingInspectionBox = 'lighting_inspections';
  static const String _trashBox = 'trash_items';

  // Enregistrer tous les adaptateurs
  static void registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(VerificateurAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MissionAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DescriptionInstallationsAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AuditInstallationsElectriquesAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(MoyenneTensionLocalAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(MoyenneTensionZoneAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(BasseTensionZoneAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(BasseTensionLocalAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(ElementControleAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(CelluleAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TransformateurMTBTAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(CoffretArmoireAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(AlimentationAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(PointVerificationAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ClassementEmplacementAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(FoudreAdapter()); 
    if (!Hive.isAdapterRegistered(16)) Hive.registerAdapter(MesuresEssaisAdapter());
    if (!Hive.isAdapterRegistered(17)) Hive.registerAdapter(ConditionMesureAdapter());
    if (!Hive.isAdapterRegistered(18)) Hive.registerAdapter(EssaiDemarrageAutoAdapter());
    if (!Hive.isAdapterRegistered(19)) Hive.registerAdapter(TestArretUrgenceAdapter());
    if (!Hive.isAdapterRegistered(20)) Hive.registerAdapter(PriseTerreAdapter());
    if (!Hive.isAdapterRegistered(21)) Hive.registerAdapter(AvisMesuresTerreAdapter());
    if (!Hive.isAdapterRegistered(22)) Hive.registerAdapter(EssaiDeclenchementDifferentielAdapter());
    if (!Hive.isAdapterRegistered(23)) Hive.registerAdapter(ContinuiteResistanceAdapter());
    if (!Hive.isAdapterRegistered(63)) Hive.registerAdapter(EssaiIsolementAdapter());
    if (!Hive.isAdapterRegistered(66)) Hive.registerAdapter(CpiTestAdapter());
    if (!Hive.isAdapterRegistered(24)) Hive.registerAdapter(ObservationLibreAdapter());
    if (!Hive.isAdapterRegistered(25)) Hive.registerAdapter(InstallationItemAdapter()); 
    if (!Hive.isAdapterRegistered(34)) Hive.registerAdapter(RenseignementsGenerauxAdapter());
    if (!Hive.isAdapterRegistered(35)) Hive.registerAdapter(TrashItemAdapter());
    if (!Hive.isAdapterRegistered(39)) Hive.registerAdapter(JSAAdapter());
    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(JSAInspecteurAdapter());
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(JSAPlanUrgenceAdapter());
    if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(JSADangersAdapter());
    if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(JSAExigencesGeneralesAdapter());
    if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(JSAEPIAdapter());
    if (!Hive.isAdapterRegistered(45)) Hive.registerAdapter(JSAVerificationFinaleAdapter());
    if (!Hive.isAdapterRegistered(46)) Hive.registerAdapter(ClassementZoneAdapter());
    if (!Hive.isAdapterRegistered(50)) Hive.registerAdapter(LastReportAdapter());
    if (!Hive.isAdapterRegistered(60)) Hive.registerAdapter(LightingInspectionAdapter());
    if (!Hive.isAdapterRegistered(61)) Hive.registerAdapter(NonConformingLuminaireAdapter());
    if (!Hive.isAdapterRegistered(62)) Hive.registerAdapter(LuminaireQuestionAnswerAdapter());
    if (!Hive.isAdapterRegistered(64)) Hive.registerAdapter(DepartEquipementAdapter());
    if (!Hive.isAdapterRegistered(65)) Hive.registerAdapter(CircuitTerminalEquipementAdapter());
  }

  // Initialiser Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    registerAdapters();

    // Ouvrir toutes les boxes avec le type correct
    await Hive.openBox('meta');
    await Hive.openBox<Verificateur>(_verificateurBox);
    await Hive.openBox<Mission>(_missionBox);
    await Hive.openBox<DescriptionInstallations>(_descriptionBox); 
    await Hive.openBox<AuditInstallationsElectriques>(_auditBox);
    await Hive.openBox<ClassementEmplacement>(_classementBox);
    await Hive.openBox<Foudre>(_foudreBox); 
    await Hive.openBox<LightingInspection>(_lightingInspectionBox); 
    await Hive.openBox<MesuresEssais>(_mesuresEssaisBox);
    await Hive.openBox(_currentUserKey);  // Box sans type (dynamic)
    await Hive.openBox<RenseignementsGeneraux>(_renseignementsGenerauxBox);
    await Hive.openBox<JSA>(_jsaBox);
    await Hive.openBox(_coffretDraftsBox);  
    await Hive.openBox(_localDraftsBox); 
    await Hive.openBox<ClassementZone>(_classementZoneBox);  
    await Hive.openBox<LastReport>('last_reports');  
    await Hive.openBox<TrashItem>(_trashBox);
    
    // Box pour les préférences MT et la sauvegarde automatique
    await Hive.openBox(_mtPreferenceBox);
    await Hive.openBox('sync_cache');
    await Hive.openBox('backup_queue');
    await Hive.openBox('backup_preferences');
    await Hive.openBox('executive_summary_cache');

    // Auto-purge automatique des éléments corbeille de +90 jours
    await TrashService.autoPurgeExpiredItems(retentionDays: 90);
  }

  // ============================================================
  //                      GESTION UTILISATEUR
  // ============================================================

  /// Sauvegarder l'utilisateur (clé = email)
  static Future<void> saveCurrentUser(Verificateur user) async {
    final box = Hive.box<Verificateur>(_verificateurBox);
    await box.put(user.email.toLowerCase(), user);  // Clé = email en minuscule

    final currentBox = Hive.box(_currentUserKey);
    await currentBox.put('email', user.email.toLowerCase());
    await currentBox.put('isLoggedIn', true);
  }

  /// Vérifier si un matricule existe déjà
  static bool matriculeExists(String matricule) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    try {
      return box.values.any((user) => user.matricule.toUpperCase() == matricule.toUpperCase());
    } catch (e) {
      if (kDebugMode) print('Erreur matriculeExists: $e');
      return false;
    }
  }

  /// Récupérer l’utilisateur ACTUELLEMENT connecté
  static Verificateur? getCurrentUser() {
    try {
      final currentBox = Hive.box(_currentUserKey);
      final email = currentBox.get('email');
      final isLoggedIn = currentBox.get('isLoggedIn', defaultValue: false);

      if (email == null || email is! String || !isLoggedIn) return null;

      final box = Hive.box<Verificateur>(_verificateurBox);
      final user = box.get(email);

      if (user == null) {
        currentBox.delete('email');
        currentBox.delete('isLoggedIn');
      }

      return user;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getCurrentUser: $e');
      return null;
    }
  }

  /// Vérifier si un email existe déjà
  static bool emailExists(String email) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.containsKey(email.toLowerCase());
  }

  static Verificateur? getUserByEmail(String email) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.get(email);
  }

  /// Vérifier si un utilisateur existe (par email)
  static bool userExists(String email) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.containsKey(email);
  }

  /// Vérifier les identifiants (email + password)
  static Verificateur? authenticateUser(String email, String password) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    final user = box.get(email.toLowerCase());
    
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  //liste de tous les verificateurs
  static List<Verificateur> getAllVerificateurs() {
    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.values.toList();
  }

  /// Récupérer un utilisateur par son matricule
  static Verificateur? getUserByMatricule(String matricule) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    try {
      return box.values.firstWhere(
        (user) => user.matricule.toUpperCase() == matricule.toUpperCase(),
      );
    } catch (e) {
      if (kDebugMode) print('Erreur getUserByMatricule: $e');
      return null;
    }
  }

  /// Vérifie si un utilisateur est connecté
  static bool isUserLoggedIn() {
    final currentBox = Hive.box(_currentUserKey);
    return currentBox.get('isLoggedIn', defaultValue: false);
  }

  /// Déconnecter l’utilisateur mais conserver ses données
  static Future<void> logout() async {
    try {
      final currentBox = Hive.box(_currentUserKey);
      await currentBox.put('isLoggedIn', false);
      if (kDebugMode) print('🟡 Utilisateur déconnecté proprement.');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur lors de logout: $e');
      throw Exception('Erreur lors de la déconnexion');
    }
  }

  /// Effacer toute la session utilisateur
  static Future<void> logoutCompletely() async {
    try {
      final currentBox = Hive.box(_currentUserKey);
      await currentBox.clear();
      if (kDebugMode) print('🔴 Déconnexion complète : session effacée.');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur logoutCompletely: $e');
      throw Exception('Erreur lors de la déconnexion complète');
    }
  }

  /// Debug de l’état des utilisateurs
  static void debugUserState() {
    if (!kDebugMode) return;
    final currentBox = Hive.box(_currentUserKey);
    final matricule = currentBox.get('matricule');
    final isLoggedIn = currentBox.get('isLoggedIn', defaultValue: false);
    final userBox = Hive.box<Verificateur>(_verificateurBox);

    if (kDebugMode) {
      print('====== DEBUG USER STATE ======');
    }
    if (kDebugMode) {
      print('Matricule current_user : $matricule');
    }
    if (kDebugMode) {
      print('isLoggedIn : $isLoggedIn');
    }
    if (kDebugMode) {
      print('Liste users locaux : ${userBox.keys.toList()}');
    }

    if (matricule != null) {
      final user = userBox.get(matricule);
      if (kDebugMode) {
        print('User actuel : ${user?.nom}');
      }
    }
    if (kDebugMode) {
      print('==============================');
    }
  }

  static Verificateur? getUserByMatriculeAndPassword(String matricule, String password) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    final user = box.get(matricule);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  
  // ============================================================
  //                      GESTION MISSIONS
  // ============================================================

  static Future<void> saveMission(Mission mission) async {
    final box = Hive.box<Mission>(_missionBox);
    await box.put(mission.id, mission);

    // ✅ Synchroniser également avec RenseignementsGeneraux s'il existe déjà
    try {
      final rensBox = Hive.box<RenseignementsGeneraux>(_renseignementsGenerauxBox);
      final existing = rensBox.values.firstWhere((r) => r.missionId == mission.id);
      bool changed = false;
      if (mission.activiteSurSite != existing.activiteSurSite) {
        existing.activiteSurSite = mission.activiteSurSite;
        changed = true;
      }
      if (mission.classementReglementaireType != existing.classementReglementaireType) {
        existing.classementReglementaireType = mission.classementReglementaireType;
        changed = true;
      }
      if (mission.classementReglementaireCategorie != existing.classementReglementaireCategorie) {
        existing.classementReglementaireCategorie = mission.classementReglementaireCategorie;
        changed = true;
      }
      if (mission.nomClient.isNotEmpty && mission.nomClient != existing.etablissement) {
        existing.etablissement = mission.nomClient;
        changed = true;
      }
      if (mission.installation != null && mission.installation != existing.installation) {
        existing.installation = mission.installation!;
        changed = true;
      }
      if (mission.activiteClient != null && mission.activiteClient != existing.activite) {
        existing.activite = mission.activiteClient!;
        changed = true;
      }
      if (mission.nomSite != null && mission.nomSite != existing.nomSite) {
        existing.nomSite = mission.nomSite!;
        changed = true;
      }
      if (mission.lieuIntervention != null && mission.lieuIntervention != existing.lieuIntervention) {
        existing.lieuIntervention = mission.lieuIntervention;
        changed = true;
      }
      if (mission.recepteurRapport != null && mission.recepteurRapport != existing.recepteurRapport) {
        existing.recepteurRapport = mission.recepteurRapport;
        changed = true;
      }
      if (mission.recepteurCivilite != null && mission.recepteurCivilite != existing.recepteurCivilite) {
        existing.recepteurCivilite = mission.recepteurCivilite;
        changed = true;
      }
      if (mission.recepteurNom != null && mission.recepteurNom != existing.recepteurNom) {
        existing.recepteurNom = mission.recepteurNom;
        changed = true;
      }
      if (mission.recepteurFonction != null && mission.recepteurFonction != existing.recepteurFonction) {
        existing.recepteurFonction = mission.recepteurFonction;
        changed = true;
      }
      if (mission.recepteurEmail != null && mission.recepteurEmail != existing.recepteurEmail) {
        existing.recepteurEmail = mission.recepteurEmail;
        changed = true;
      }
      if (mission.recepteurTelephone != null && mission.recepteurTelephone != existing.recepteurTelephone) {
        existing.recepteurTelephone = mission.recepteurTelephone;
        changed = true;
      }
      if (mission.dateRapport != null && mission.dateRapport != existing.dateRapport) {
        existing.dateRapport = mission.dateRapport;
        changed = true;
      }
      if (changed) {
        existing.updatedAt = DateTime.now();
        await existing.save();
      }
    } catch (_) {
      // Aucun RenseignementsGeneraux existant pour l'instant
    }

    // ✅ Détection automatique pour le système de sauvegarde 17h30
    Future.microtask(() async {
      await MissionActivityTracker.markMissionModifiedToday(mission.id);
    });
  }

  static Future<void> saveMissions(List<Mission> missions) async {
    final box = Hive.box<Mission>(_missionBox);
    for (var m in missions) {
      await box.put(m.id, m);
      Future.microtask(() async {
        await MissionActivityTracker.markMissionModifiedToday(m.id);
      });
    }
  }

  static List<Mission> getAllMissions() {
    final box = Hive.box<Mission>(_missionBox);
    final trashedIds = TrashService.getTrashedMissionIds();
    return box.values.where((m) => !trashedIds.contains(m.id)).toList();
  }

  static List<Mission> getMissionsByMatricule(String matricule) {
    final box = Hive.box<Mission>(_missionBox);
    final trashedIds = TrashService.getTrashedMissionIds();
    return box.values.where((mission) {
      if (trashedIds.contains(mission.id)) return false;
      if (mission.verificateurs == null) return false;
      return mission.verificateurs!.any((v) => v['matricule'] == matricule);
    }).toList();
  }

  static bool missionExists(String id) {
    final box = Hive.box<Mission>(_missionBox);
    return box.containsKey(id);
  }

  static Future<void> clearMissions() async {
    final box = Hive.box<Mission>(_missionBox);
    await box.clear();
  }

  static int getMissionsCount() {
    final box = Hive.box<Mission>(_missionBox);
    return box.length;
  }

  static List<Verificateur> getAllUsers() {
    try {
      final box = Hive.box<Verificateur>(_verificateurBox);
      return box.values.toList();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getAllUsers: $e');
      return [];
    }
  }

  // Récupérer un vérificateur par matricule
  static Verificateur? getVerificateurByMatricule(String matricule) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    try {
      return box.values.firstWhere((v) => v.matricule == matricule);
    } catch (e) {
      return null;
    }
  }

// ============================================================
//          GESTION DES ACCOMPAGNATEURS
// ============================================================

/// Ajouter un accompagnateur à une mission
static Future<bool> addAccompagnateur({
  required String missionId,
  required String accompagnateur,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null) {
      if (kDebugMode) print('❌ Mission non trouvée: $missionId');
      return false;
    }

    // Initialiser la liste si null
    mission.accompagnateurs ??= [];

    // Vérifier si l'accompagnateur n'existe pas déjà
    if (!mission.accompagnateurs!.contains(accompagnateur)) {
      mission.accompagnateurs!.add(accompagnateur);
      mission.updatedAt = DateTime.now();
      await mission.save();
      if (kDebugMode) print('✅ Accompagnateur ajouté: $accompagnateur');
      return true;
    } else {
      if (kDebugMode) print('⚠️ Accompagnateur déjà présent: $accompagnateur');
      return false;
    }
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addAccompagnateur: $e');
    return false;
  }
}

/// Supprimer un accompagnateur d'une mission
static Future<bool> removeAccompagnateur({
  required String missionId,
  required String accompagnateur,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null || mission.accompagnateurs == null) {
      if (kDebugMode) print('❌ Mission non trouvée ou liste vide: $missionId');
      return false;
    }

    // Supprimer l'accompagnateur
    final removed = mission.accompagnateurs!.remove(accompagnateur);
    
    if (removed) {
      mission.updatedAt = DateTime.now();
      await mission.save();
      if (kDebugMode) print('✅ Accompagnateur supprimé: $accompagnateur');
      return true;
    } else {
      if (kDebugMode) print('⚠️ Accompagnateur non trouvé: $accompagnateur');
      return false;
    }
  } catch (e) {
    if (kDebugMode) print('❌ Erreur removeAccompagnateur: $e');
    return false;
  }
}

/// Modifier un accompagnateur (renommer)
static Future<bool> updateAccompagnateur({
  required String missionId,
  required String oldAccompagnateur,
  required String newAccompagnateur,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null || mission.accompagnateurs == null) {
      if (kDebugMode) print('❌ Mission non trouvée ou liste vide: $missionId');
      return false;
    }

    final index = mission.accompagnateurs!.indexOf(oldAccompagnateur);
    if (index == -1) {
      if (kDebugMode) print('❌ Ancien accompagnateur non trouvé: $oldAccompagnateur');
      return false;
    }

    // Vérifier si le nouveau nom n'existe pas déjà
    if (mission.accompagnateurs!.contains(newAccompagnateur)) {
      if (kDebugMode) print('⚠️ Nouvel accompagnateur déjà présent: $newAccompagnateur');
      return false;
    }

    // Remplacer l'ancien par le nouveau
    mission.accompagnateurs![index] = newAccompagnateur;
    mission.updatedAt = DateTime.now();
    await mission.save();
    
    if (kDebugMode) print('✅ Accompagnateur modifié: $oldAccompagnateur -> $newAccompagnateur');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateAccompagnateur: $e');
    return false;
  }
}

/// Récupérer la liste des accompagnateurs d'une mission
static List<String>? getAccompagnateurs(String missionId) {
  try {
    final mission = getMissionById(missionId);
    return mission?.accompagnateurs;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur getAccompagnateurs: $e');
    return null;
  }
}

/// Vérifier si un accompagnateur existe dans une mission
static bool hasAccompagnateur({
  required String missionId,
  required String accompagnateur,
}) {
  try {
    final mission = getMissionById(missionId);
    return mission?.accompagnateurs?.contains(accompagnateur) ?? false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur hasAccompagnateur: $e');
    return false;
  }
}
  // ============================================================
  //                  MODIFICATION STATUT MISSION
  // ============================================================

  /// Mettre à jour le statut d'une mission localement
  static Future<bool> updateMissionStatus({
    required String missionId,
    required String newStatus,
  }) async {
    try {
      final box = Hive.box<Mission>(_missionBox);
      final mission = box.get(missionId);

      if (mission == null) {
        if (kDebugMode) print('❌ Mission non trouvée: $missionId');
        return false;
      }

      // Normaliser le statut
      String normalizedStatus = newStatus.toLowerCase();
      if (normalizedStatus == 'en cours') normalizedStatus = 'en_cours';
      if (normalizedStatus == 'terminé') normalizedStatus = 'termine';
      if (normalizedStatus == 'en attente') normalizedStatus = 'en_attente';

      mission.status = normalizedStatus;
      mission.updatedAt = DateTime.now();
      await mission.save();
      
      if (kDebugMode) print('✅ Statut mis à jour: $missionId -> $normalizedStatus');
      return true;

    } catch (e) {
      if (kDebugMode) print('❌ Erreur mise à jour statut: $e');
      return false;
    }
  }

  /// Récupérer une mission par son ID
  static Mission? getMissionById(String missionId) {
    try {
      final box = Hive.box<Mission>(_missionBox);
      return box.get(missionId);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getMissionById: $e');
      return null;
    }
  }

  // ============================================================
//                  MODIFICATION DOCUMENTS MISSION
// ============================================================

/// Mettre à jour l'état d'un document spécifique pour une mission
static Future<bool> updateDocumentStatus({
  required String missionId,
  required String documentField,
  required bool value,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null) {
      if (kDebugMode) print('❌ Mission non trouvée: $missionId');
      return false;
    }

    // Mettre à jour le document spécifique
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
      case 'doc_rapport_q18':
        mission.docRapportQ18 = value;
        break;
      case 'doc_autre':
        mission.docAutre = value;
        break;
      default:
        if (kDebugMode) print('❌ Champ document inconnu: $documentField');
        return false;
    }

    // Mettre à jour la date de modification
    mission.updatedAt = DateTime.now();

    // Sauvegarder la mission modifiée
    await mission.save();
    
    if (kDebugMode) print('✅ Document mis à jour: $documentField -> $value pour mission $missionId');
    return true;

  } catch (e) {
    if (kDebugMode) print('❌ Erreur mise à jour document local: $e');
    return false;
  }
}
static const String _renseignementsGenerauxBox = 'renseignements_generaux';
/// Mettre à jour plusieurs documents en une seule opération
static Future<bool> updateMultipleDocuments({
  required String missionId,
  required Map<String, bool> documentUpdates,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null) {
      if (kDebugMode) print('❌ Mission non trouvée: $missionId');
      return false;
    }

    // Appliquer toutes les mises à jour
    documentUpdates.forEach((documentField, value) {
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
        case 'doc_rapport_q18':
          mission.docRapportQ18 = value;
          break;
        case 'doc_autre':
          mission.docAutre = value;
          break;
        default:
          if (kDebugMode) print('❌ Champ document inconnu: $documentField');
      }
    });

    // Mettre à jour la date de modification
    mission.updatedAt = DateTime.now();

    // Sauvegarder la mission modifiée
    await mission.save();
    
    if (kDebugMode) print('✅ ${documentUpdates.length} documents mis à jour pour mission $missionId');
    return true;

  } catch (e) {
    if (kDebugMode) print('❌ Erreur mise à jour multiples documents: $e');
    return false;
  }
}

/// Récupérer l'état de tous les documents d'une mission
static Map<String, bool> getMissionDocumentsStatus(String missionId) {
  try {
    final mission = getMissionById(missionId);
    if (mission == null) {
      return {};
    }

    return {
      'doc_cahier_prescriptions': mission.docCahierPrescriptions,
      'doc_notes_calculs': mission.docNotesCalculs,
      'doc_schemas_unifilaires': mission.docSchemasUnifilaires,
      'doc_plan_masse': mission.docPlanMasse,
      'doc_plans_architecturaux': mission.docPlansArchitecturaux,
      'doc_declarations_ce': mission.docDeclarationsCe,
      'doc_liste_installations': mission.docListeInstallations,
      'doc_plan_locaux_risques': mission.docPlanLocauxRisques,
      'doc_rapport_analyse_foudre': mission.docRapportAnalyseFoudre,
      'doc_rapport_etude_foudre': mission.docRapportEtudeFoudre,
      'doc_registre_securite': mission.docRegistreSecurite,
      'doc_rapport_derniere_verif': mission.docRapportDerniereVerif,
      'doc_autre': mission.docAutre,
    };
  } catch (e) {
    if (kDebugMode) print('❌ Erreur getMissionDocumentsStatus: $e');
    return {};
  }
}

/// Réinitialiser tous les documents d'une mission à false
static Future<bool> resetAllDocuments(String missionId) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null) {
      if (kDebugMode) print('❌ Mission non trouvée: $missionId');
      return false;
    }

    // Réinitialiser tous les documents
    mission.docCahierPrescriptions = false;
    mission.docNotesCalculs = false;
    mission.docSchemasUnifilaires = false;
    mission.docPlanMasse = false;
    mission.docPlansArchitecturaux = false;
    mission.docDeclarationsCe = false;
    mission.docListeInstallations = false;
    mission.docPlanLocauxRisques = false;
    mission.docRapportAnalyseFoudre = false;
    mission.docRapportEtudeFoudre = false;
    mission.docRegistreSecurite = false;
    mission.docRapportDerniereVerif = false;
    mission.docAutre = false;

    // Mettre à jour la date de modification
    mission.updatedAt = DateTime.now();

    // Sauvegarder la mission modifiée
    await mission.save();
    
    if (kDebugMode) print('✅ Tous les documents réinitialisés pour mission $missionId');
    return true;

  } catch (e) {
    if (kDebugMode) print('❌ Erreur réinitialisation documents: $e');
    return false;
  }
}

  // ============================================================
  //          GESTION DESCRIPTION DES INSTALLATIONS
  // ============================================================

  /// Créer ou récupérer les données de description des installations pour une mission
  static Future<DescriptionInstallations> getOrCreateDescriptionInstallations(String missionId) async {
    final box = await Hive.openBox<DescriptionInstallations>(_descriptionBox);
    try {
      final existing = getDescriptionInstallationsByMissionId(missionId);
      if (existing != null) return existing;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur lors de la recherche: $e');
    }
    
    final newDesc = DescriptionInstallations.create(missionId);
    await box.put(missionId, newDesc);
    
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.descriptionInstallationsId = missionId;
      await mission.save();
    }
    
    return newDesc;
  }

  /// Sauvegarder les données de description des installations
  static Future<void> saveDescriptionInstallations(DescriptionInstallations desc) async {
    try {
      final box = await Hive.openBox<DescriptionInstallations>(_descriptionBox);
      desc.updatedAt = DateTime.now();
      await box.put(desc.missionId, desc);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur saveDescriptionInstallations: $e');
    }
  }

  /// Consolide et fusionne tous les enregistrements DescriptionInstallations pour une missionId donnée.
  /// Récupère toutes les données renseignées (clés entières ou String), fusionne les listes
  /// et les champs texte, et enregistre un objet unique sous la clé String `missionId`.
  static DescriptionInstallations _mergeAndConsolidateDescriptions(
    Box<DescriptionInstallations> box,
    String missionId,
    List<DescriptionInstallations> matches,
  ) {
    if (matches.length == 1 && matches.first.key == missionId) {
      final res = matches.first;
      if (res.cpi.length > 1) {
        res.cpi = [res.cpi.last];
        box.put(missionId, res);
      }
      return res;
    }

    DescriptionInstallations primary = box.get(missionId) ?? DescriptionInstallations.create(missionId);

    for (final desc in matches) {
      void mergeItems(List<InstallationItem> target, List<InstallationItem> source) {
        for (final srcItem in source) {
          final exists = target.any((t) {
            if (t.createdAt == srcItem.createdAt) return true;
            if (t.data.length == srcItem.data.length) {
              bool identical = true;
              for (final entry in srcItem.data.entries) {
                if (t.data[entry.key] != entry.value) {
                  identical = false;
                  break;
                }
              }
              if (identical) return true;
            }
            return false;
          });
          if (!exists) {
            target.add(srcItem);
          }
        }
      }

      mergeItems(primary.alimentationMoyenneTension, desc.alimentationMoyenneTension);
      mergeItems(primary.alimentationBasseTension, desc.alimentationBasseTension);
      mergeItems(primary.groupeElectrogene, desc.groupeElectrogene);
      mergeItems(primary.alimentationCarburant, desc.alimentationCarburant);
      mergeItems(primary.inverseur, desc.inverseur);
      mergeItems(primary.stabilisateur, desc.stabilisateur);
      mergeItems(primary.onduleurs, desc.onduleurs);
      mergeItems(primary.cpi, desc.cpi);

      if ((primary.regimeNeutre == null || primary.regimeNeutre!.isEmpty) && desc.regimeNeutre != null && desc.regimeNeutre!.isNotEmpty) {
        primary.regimeNeutre = desc.regimeNeutre;
      }
      if ((primary.regimeNeutreDetail == null || primary.regimeNeutreDetail!.isEmpty) && desc.regimeNeutreDetail != null && desc.regimeNeutreDetail!.isNotEmpty) {
        primary.regimeNeutreDetail = desc.regimeNeutreDetail;
      }
      if ((primary.eclairageSecurite == null || primary.eclairageSecurite!.isEmpty) && desc.eclairageSecurite != null && desc.eclairageSecurite!.isNotEmpty) {
        primary.eclairageSecurite = desc.eclairageSecurite;
      }
      if ((primary.modificationsInstallations == null || primary.modificationsInstallations!.isEmpty) && desc.modificationsInstallations != null && desc.modificationsInstallations!.isNotEmpty) {
        primary.modificationsInstallations = desc.modificationsInstallations;
      }
      if ((primary.noteCalcul == null || primary.noteCalcul!.isEmpty) && desc.noteCalcul != null && desc.noteCalcul!.isNotEmpty) {
        primary.noteCalcul = desc.noteCalcul;
      }
      if ((primary.registreSecurite == null || primary.registreSecurite!.isEmpty) && desc.registreSecurite != null && desc.registreSecurite!.isNotEmpty) {
        primary.registreSecurite = desc.registreSecurite;
      }
      if ((primary.presenceParatonnerre == null || primary.presenceParatonnerre!.isEmpty) && desc.presenceParatonnerre != null && desc.presenceParatonnerre!.isNotEmpty) {
        primary.presenceParatonnerre = desc.presenceParatonnerre;
      }
      if ((primary.analyseRisqueFoudre == null || primary.analyseRisqueFoudre!.isEmpty) && desc.analyseRisqueFoudre != null && desc.analyseRisqueFoudre!.isNotEmpty) {
        primary.analyseRisqueFoudre = desc.analyseRisqueFoudre;
      }
      if ((primary.etudeTechniqueFoudre == null || primary.etudeTechniqueFoudre!.isEmpty) && desc.etudeTechniqueFoudre != null && desc.etudeTechniqueFoudre!.isNotEmpty) {
        primary.etudeTechniqueFoudre = desc.etudeTechniqueFoudre;
      }
      if ((primary.natureReseauAlimentationSite == null || primary.natureReseauAlimentationSite!.isEmpty) && desc.natureReseauAlimentationSite != null && desc.natureReseauAlimentationSite!.isNotEmpty) {
        primary.natureReseauAlimentationSite = desc.natureReseauAlimentationSite;
      }
      if ((primary.tensionAlimentationSite == null || primary.tensionAlimentationSite!.isEmpty) && desc.tensionAlimentationSite != null && desc.tensionAlimentationSite!.isNotEmpty) {
        primary.tensionAlimentationSite = desc.tensionAlimentationSite;
      }
      if ((primary.nombreAlimentationSite == null || primary.nombreAlimentationSite!.isEmpty) && desc.nombreAlimentationSite != null && desc.nombreAlimentationSite!.isNotEmpty) {
        primary.nombreAlimentationSite = desc.nombreAlimentationSite;
      }
      if ((primary.presenceIacmAlimentationSite == null || primary.presenceIacmAlimentationSite!.isEmpty) && desc.presenceIacmAlimentationSite != null && desc.presenceIacmAlimentationSite!.isNotEmpty) {
        primary.presenceIacmAlimentationSite = desc.presenceIacmAlimentationSite;
      }
      if (primary.foudreObservations.isEmpty && desc.foudreObservations.isNotEmpty) {
        primary.foudreObservations = List.from(desc.foudreObservations);
      }

      if (desc.updatedAt.isAfter(primary.updatedAt)) {
        primary.updatedAt = desc.updatedAt;
      }
    }

    if (primary.cpi.length > 1) {
      primary.cpi = [primary.cpi.last];
    }

    primary.updatedAt = DateTime.now();
    box.put(missionId, primary);

    for (final desc in matches) {
      if (desc.key != null && desc.key != missionId) {
        try {
          box.delete(desc.key);
        } catch (_) {}
      }
    }

    return primary;
  }

  /// Récupérer les données de description des installations par missionId (avec consolidation automatique)
  static DescriptionInstallations? getDescriptionInstallationsByMissionId(String missionId) {
    if (!Hive.isBoxOpen(_descriptionBox)) {
      return null;
    }
    final box = Hive.box<DescriptionInstallations>(_descriptionBox);
    try {
      final matches = box.values.where((d) => d.missionId == missionId).toList();
      if (matches.isEmpty) {
        final res = box.get(missionId);
        if (res != null) {
          if (res.cpi.length > 1) {
            res.cpi = [res.cpi.last];
            box.put(missionId, res);
          }
          return res;
        }
        return null;
      }

      return _mergeAndConsolidateDescriptions(box, missionId, matches);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getDescriptionInstallationsByMissionId: $e');
      return null;
    }
  }

  // Dans hive_service.dart - Ajoutez ces méthodes

// ============================================================
//          GESTION INSTALLATION ITEM AVEC PHOTOS
// ============================================================

/// Ajouter une carte (InstallationItem) à une section spécifique
static Future<bool> addInstallationItemToSection({
  required String missionId,
  required String section,
  required InstallationItem item,
}) async {
  try {
    final box = await Hive.openBox<DescriptionInstallations>('description_installations'); // OUVERTURE EXPLICITE
    final desc = await getOrCreateDescriptionInstallations(missionId);
    
    switch (section) {
      case 'alimentation_moyenne_tension':
        desc.alimentationMoyenneTension.add(item);
        break;
      case 'alimentation_basse_tension':
        desc.alimentationBasseTension.add(item);
        break;
      case 'groupe_electrogene':
        desc.groupeElectrogene.add(item);
        break;
      case 'alimentation_carburant':
        desc.alimentationCarburant.add(item);
        break;
      case 'inverseur':
        desc.inverseur.add(item);
        break;
      case 'stabilisateur':
        desc.stabilisateur.add(item);
        break;
      case 'onduleurs':
        desc.onduleurs.add(item);
        break;
      case 'cpi':
        desc.cpi = [item];
        break;
      default:
        if (kDebugMode) print('❌ Section inconnue: $section');
        return false;
    }

    desc.updatedAt = DateTime.now(); // METTRE À JOUR LA DATE
    await box.put(desc.key, desc); // SAUVEGARDER CORRECTEMENT
    
    if (kDebugMode) print('✅ InstallationItem ajouté à la section: $section');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addInstallationItemToSection: $e');
    return false;
  }
}
/// Mettre à jour une InstallationItem existante
static Future<bool> updateInstallationItemInSection({
  required String missionId,
  required String section,
  required int index,
  required InstallationItem item,
}) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    
    switch (section) {
      case 'alimentation_moyenne_tension':
        if (index < desc.alimentationMoyenneTension.length) {
          desc.alimentationMoyenneTension[index] = item;
        }
        break;
      case 'alimentation_basse_tension':
        if (index < desc.alimentationBasseTension.length) {
          desc.alimentationBasseTension[index] = item;
        }
        break;
      case 'groupe_electrogene':
        if (index < desc.groupeElectrogene.length) {
          desc.groupeElectrogene[index] = item;
        }
        break;
      case 'alimentation_carburant':
        if (index < desc.alimentationCarburant.length) {
          desc.alimentationCarburant[index] = item;
        }
        break;
      case 'inverseur':
        if (index < desc.inverseur.length) {
          desc.inverseur[index] = item;
        }
        break;
      case 'stabilisateur':
        if (index < desc.stabilisateur.length) {
          desc.stabilisateur[index] = item;
        }
        break;
      case 'onduleurs':
        if (index < desc.onduleurs.length) {
          desc.onduleurs[index] = item;
        }
        break;
      case 'cpi':
        desc.cpi = [item];
        break;
      default:
        if (kDebugMode) print('❌ Section inconnue: $section');
        return false;
    }

    await saveDescriptionInstallations(desc);
    if (kDebugMode) print('✅ InstallationItem mis à jour dans la section: $section');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateInstallationItemInSection: $e');
    return false;
  }
}

/// Récupérer tous les InstallationItems d'une section
static Future<List<InstallationItem>> getInstallationItemsFromSection({
  required String missionId,
  required String section,
}) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    
    switch (section) {
      case 'alimentation_moyenne_tension':
        return desc.alimentationMoyenneTension;
      case 'alimentation_basse_tension':
        return desc.alimentationBasseTension;
      case 'groupe_electrogene':
        return desc.groupeElectrogene;
      case 'alimentation_carburant':
        return desc.alimentationCarburant;
      case 'inverseur':
        return desc.inverseur;
      case 'stabilisateur':
        return desc.stabilisateur;
      case 'onduleurs':
        return desc.onduleurs;
      case 'cpi':
        return desc.cpi;
      default:
        if (kDebugMode) print('❌ Section inconnue: $section');
        return [];
    }
  } catch (e) {
    if (kDebugMode) print('❌ Erreur getInstallationItemsFromSection: $e');
    return [];
  }
}

/// Supprimer une InstallationItem d'une section
static Future<bool> removeInstallationItemFromSection({
  required String missionId,
  required String section,
  required int index,
}) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    
    switch (section) {
      case 'alimentation_moyenne_tension':
        if (index < desc.alimentationMoyenneTension.length) {
          desc.alimentationMoyenneTension.removeAt(index);
        }
        break;
      case 'alimentation_basse_tension':
        if (index < desc.alimentationBasseTension.length) {
          desc.alimentationBasseTension.removeAt(index);
        }
        break;
      case 'groupe_electrogene':
        if (index < desc.groupeElectrogene.length) {
          desc.groupeElectrogene.removeAt(index);
        }
        break;
      case 'alimentation_carburant':
        if (index < desc.alimentationCarburant.length) {
          desc.alimentationCarburant.removeAt(index);
        }
        break;
      case 'inverseur':
        if (index < desc.inverseur.length) {
          desc.inverseur.removeAt(index);
        }
        break;
      case 'stabilisateur':
        if (index < desc.stabilisateur.length) {
          desc.stabilisateur.removeAt(index);
        }
        break;
      case 'onduleurs':
        if (index < desc.onduleurs.length) {
          desc.onduleurs.removeAt(index);
        }
        break;
      case 'cpi':
        if (index < desc.cpi.length) {
          desc.cpi.removeAt(index);
        }
        break;
      default:
        if (kDebugMode) print('❌ Section inconnue: $section');
        return false;
    }

    await saveDescriptionInstallations(desc);
    if (kDebugMode) print('✅ InstallationItem supprimé de la section: $section');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur removeInstallationItemFromSection: $e');
    return false;
  }
}

/// Vérifier si une section est complète
static Future<bool> isSectionComplete({
  required String missionId,
  required String sectionKey,
}) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    return desc.isSectionComplete(sectionKey);
  } catch (e) {
    return false;
  }
}

/// Obtenir la progression de la mission
static Future<Map<String, bool>> getMissionProgress(String missionId) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    return desc.getProgress();
  } catch (e) {
    if (kDebugMode) print('❌ Erreur getMissionProgress: $e');
    return {};
  }
}

/// Obtenir le pourcentage de complétion
static Future<int> getCompletionPercentage(String missionId) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    return desc.getCompletionPercentage();
  } catch (e) {
    return 0;
  }
}

// Méthodes pour les anciennes compatibilités (à conserver)
static Future<List<Map<String, String>>> getCartesFromSection({
  required String missionId,
  required String section,
}) async {
  try {
    final items = await getInstallationItemsFromSection(
      missionId: missionId,
      section: section,
    );
    return items.map((item) => item.data).toList();
  } catch (e) {
    if (kDebugMode) print('❌ Erreur getCartesFromSection: $e');
    return [];
  }
}

static Future<bool> addCarteToSection({
  required String missionId,
  required String section,
  required Map<String, String> carte,
}) async {
  return await addInstallationItemToSection(
    missionId: missionId,
    section: section,
    item: InstallationItem(data: carte),
  );
}

static Future<bool> updateCarteInSection({
  required String missionId,
  required String section,
  required int index,
  required Map<String, String> carte,
}) async {
  final items = await getInstallationItemsFromSection(
    missionId: missionId,
    section: section,
  );
  
  if (index < items.length) {
    items[index].data = carte;
    return await updateInstallationItemInSection(
      missionId: missionId,
      section: section,
      index: index,
      item: items[index],
    );
  }
  return false;
}

static Future<bool> removeCarteFromSection({
  required String missionId,
  required String section,
  required int index,
}) async {
  return await removeInstallationItemFromSection(
    missionId: missionId,
    section: section,
    index: index,
  );
}

  /// Mettre à jour une sélection radio
  static Future<bool> updateSelection({
    required String missionId,
    required String field,
    required String value,
  }) async {
    try {
      final desc = await getOrCreateDescriptionInstallations(missionId);
      
      switch (field) {
        case 'regime_neutre':
          desc.regimeNeutre = value;
          break;
        case 'eclairage_securite':
          desc.eclairageSecurite = value;
          break;
        case 'modifications_installations':
          desc.modificationsInstallations = value;
          break;
        case 'note_calcul':
          desc.noteCalcul = value;
          break;
        case 'registre_securite':
          desc.registreSecurite = value;
          break;
        case 'presence_paratonnerre':
          desc.presenceParatonnerre = value;
          break;
        case 'analyse_risque_foudre':
          desc.analyseRisqueFoudre = value;
          break;
        case 'etude_technique_foudre':
          desc.etudeTechniqueFoudre = value;
          break;
        default:
          if (kDebugMode) print('❌ Champ inconnu: $field');
          return false;
      }

      await saveDescriptionInstallations(desc);
      if (kDebugMode) print('✅ Sélection mise à jour: $field -> $value');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updateSelection: $e');
      return false;
    }
  }

  /// Vérifier si une mission a des données de description
  static bool hasDescriptionInstallations(String missionId) {
    return getDescriptionInstallationsByMissionId(missionId) != null;
  }

  static bool _ensureStableIds(AuditInstallationsElectriques audit) {
    bool changed = false;

    void checkCoffret(CoffretArmoire c) {
      if (c.id == null || c.id!.trim().isEmpty) {
        c.id = c.equipmentId;
        changed = true;
      }
    }

    void checkCellule(Cellule cell) {
      if (cell.syncId == null || cell.syncId!.trim().isEmpty) {
        final createdTs = cell.createdAt?.millisecondsSinceEpoch ?? 0;
        final stableHash = (cell.fonction.trim() + (cell.nom ?? '')).hashCode.abs();
        cell.syncId = 'cellule_${createdTs}_$stableHash';
        changed = true;
      }
    }

    void checkTransfo(TransformateurMTBT transfo) {
      if (transfo.syncId == null || transfo.syncId!.trim().isEmpty) {
        final createdTs = transfo.createdAt?.millisecondsSinceEpoch ?? 0;
        final stableHash = (transfo.typeTransformateur.trim() + (transfo.nom ?? '')).hashCode.abs();
        transfo.syncId = 'transfo_${createdTs}_$stableHash';
        changed = true;
      }
    }

    for (var l in audit.moyenneTensionLocaux) {
      if (l.id == null || l.id!.trim().isEmpty) {
        l.id = l.localId;
        changed = true;
      }
      for (var c in l.coffrets) {
        checkCoffret(c);
      }
      for (var cell in l.cellules) {
        checkCellule(cell);
      }
      for (var transfo in l.transformateurs) {
        checkTransfo(transfo);
      }
    }

    for (var z in audit.moyenneTensionZones) {
      if (z.id == null || z.id!.trim().isEmpty) {
        z.id = z.zoneId;
        changed = true;
      }
      for (var c in z.coffrets) {
        checkCoffret(c);
      }
      for (var l in z.locaux) {
        if (l.id == null || l.id!.trim().isEmpty) {
          l.id = l.localId;
          changed = true;
        }
        for (var c in l.coffrets) {
          checkCoffret(c);
        }
        for (var cell in l.cellules) {
          checkCellule(cell);
        }
        for (var transfo in l.transformateurs) {
          checkTransfo(transfo);
        }
      }
    }

    for (var z in audit.basseTensionZones) {
      if (z.id == null || z.id!.trim().isEmpty) {
        z.id = z.zoneId;
        changed = true;
      }
      for (var c in z.coffretsDirects) {
        checkCoffret(c);
      }
      for (var l in z.locaux) {
        if (l.id == null || l.id!.trim().isEmpty) {
          l.id = l.localId;
          changed = true;
        }
        for (var c in l.coffrets) {
          checkCoffret(c);
        }
        for (var cell in l.cellules) {
          checkCellule(cell);
        }
        for (var transfo in l.transformateurs) {
          checkTransfo(transfo);
        }
      }
    }

    return changed;
  }

/// Créer ou récupérer les données d'audit pour une mission avec cache O(1)
static Future<AuditInstallationsElectriques> getOrCreateAuditInstallations(String missionId) async {
  final existing = getAuditInstallationsByMissionId(missionId);
  if (existing != null) {
    if (!_migratedMissions.contains(missionId)) {
      _migratedMissions.add(missionId);
      final report = EquipmentNumberService.auditAndFixMissionNumbers(existing);
      final idsFixed = _ensureStableIds(existing);
      if (report.hasChanges || idsFixed) {
        await existing.save();
      }
      reconcileQrCodes(missionId);
    }
    return existing;
  }

  final box = Hive.box<AuditInstallationsElectriques>(_auditBox);
  // Créer une nouvelle instance
  final newAudit = AuditInstallationsElectriques.create(missionId);
  await box.put(missionId, newAudit);
  _auditCache[missionId] = newAudit;
  _migratedMissions.add(missionId);
  
  // Mettre à jour la référence dans la mission
  final missionBox = Hive.box<Mission>(_missionBox);
  final mission = missionBox.get(missionId);
  if (mission != null) {
    mission.auditInstallationsElectriquesId = newAudit.key.toString();
    await mission.save();
  }
  
  return newAudit;
}

  /// Sauvegarder les données d'audit
  static Future<void> saveAuditInstallations(
    AuditInstallationsElectriques audit, {
    bool skipDescriptionSync = false,
  }) async {
    return PersistenceQueue.enqueue('audit_${audit.missionId}', () async {
      final box = Hive.box<AuditInstallationsElectriques>(_auditBox);
      audit.updatedAt = DateTime.now();
      _auditCache[audit.missionId] = audit;
      _migratedMissions.add(audit.missionId);

      if (!skipDescriptionSync) {
        try {
          await InstallationDescriptionSyncService.syncAuditToDescription(audit);
        } catch (e) {
          if (kDebugMode) {
            print('❌ Erreur de synchronisation Audit ↔ Description: $e');
          }
        }
      }

      if (audit.isInBox) {
        await audit.save();
      } else {
        await box.put(audit.missionId, audit);
      }
    });
  }

/// Synchroniser toutes les missions existantes (migration)
static Future<void> synchronizeAllExistingMissions() async {
  try {
    final auditBox = Hive.box<AuditInstallationsElectriques>(_auditBox);
    final audits = auditBox.values.toList();
    if (kDebugMode) {
      print('🔄 Synchronisation automatique de ${audits.length} missions...');
    }
    for (final audit in audits) {
      try {
        await InstallationDescriptionSyncService.syncAuditToDescription(audit);
      } catch (e, st) {
        if (kDebugMode) {
          print('⚠️ Échec synchronisation pour la mission ${audit.missionId}: $e\n$st');
        }
      }
    }
    if (kDebugMode) {
      print('✅ Synchronisation de fond terminée.');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ synchronizeAllExistingMissions: $e');
    }
  }
}

static Future<void> _syncCellulesToDescription(AuditInstallationsElectriques audit) async {
  await InstallationDescriptionSyncService.syncAuditToDescription(audit);
}

static Future<void> _syncTransformateursToDescription(AuditInstallationsElectriques audit) async {
  await InstallationDescriptionSyncService.syncAuditToDescription(audit);
}

/// Trouver la localisation physique d'une cellule par son syncId
static Future<String?> getCelluleLocalisation(String missionId, String syncId) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    // 1. Chercher dans les locaux MT directs
    for (var local in audit.moyenneTensionLocaux) {
      if (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT') {
        for (var cellule in local.cellules) {
          if (cellule.syncId == syncId) {
            final cellName = cellule.type.isNotEmpty ? cellule.type : 'Cellule';
            return 'Moyenne Tension ➔ ${local.nom} ➔ $cellName';
          }
        }
      }
    }

    // 2. Chercher dans les zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        if (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT') {
          for (var cellule in local.cellules) {
            if (cellule.syncId == syncId) {
              final cellName = cellule.type.isNotEmpty ? cellule.type : 'Cellule';
              return 'Moyenne Tension ➔ ${zone.nom} ➔ ${local.nom} ➔ $cellName';
            }
          }
        }
      }
    }

    // 3. Chercher dans les zones BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        if (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT') {
          for (var cellule in local.cellules) {
            if (cellule.syncId == syncId) {
              final cellName = cellule.type.isNotEmpty ? cellule.type : 'Cellule';
              return 'Basse Tension ➔ ${zone.nom} ➔ ${local.nom} ➔ $cellName';
            }
          }
        }
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Trouver la localisation physique d'un transformateur par son syncId
static Future<String?> getTransformateurLocalisation(String missionId, String syncId) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    // 1. Chercher dans les locaux MT directs
    for (var local in audit.moyenneTensionLocaux) {
      if (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT') {
        for (var transfo in local.transformateurs) {
          if (transfo.syncId == syncId) {
            final name = transfo.typeTransformateur.isNotEmpty ? transfo.typeTransformateur : 'Transformateur';
            return 'Moyenne Tension ➔ ${local.nom} ➔ $name';
          }
        }
      }
    }

    // 2. Chercher dans les zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        if (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT') {
          for (var transfo in local.transformateurs) {
            if (transfo.syncId == syncId) {
              final name = transfo.typeTransformateur.isNotEmpty ? transfo.typeTransformateur : 'Transformateur';
              return 'Moyenne Tension ➔ ${zone.nom} ➔ ${local.nom} ➔ $name';
            }
          }
        }
      }
    }

    // 3. Chercher dans les zones BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        if (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT') {
          for (var transfo in local.transformateurs) {
            if (transfo.syncId == syncId) {
              final name = transfo.typeTransformateur.isNotEmpty ? transfo.typeTransformateur : 'Transformateur';
              return 'Basse Tension ➔ ${zone.nom} ➔ ${local.nom} ➔ $name';
            }
          }
        }
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

  static final Map<String, AuditInstallationsElectriques> _auditCache = {};
  static final Set<String> _migratedMissions = {};

  static void clearCacheForMission(String missionId) {
    _auditCache.remove(missionId);
    _migratedMissions.remove(missionId);
  }

  /// Récupérer les données brutes d'audit par missionId sans exécuter les migrations
  static AuditInstallationsElectriques? getRawAuditInstallationsByMissionId(String missionId) {
    if (_auditCache.containsKey(missionId)) {
      final cached = _auditCache[missionId]!;
      if (cached.isInBox) return cached;
    }
    if (!Hive.isBoxOpen(_auditBox)) return null;
    final box = Hive.box<AuditInstallationsElectriques>(_auditBox);
    try {
      AuditInstallationsElectriques? audit = box.get(missionId);
      audit ??= box.values.firstWhere((a) => a.missionId == missionId);
      _auditCache[missionId] = audit;
      return audit;
    } catch (_) {
      return null;
    }
  }

  /// Récupérer les données d'audit par missionId avec cache O(1) et migration unique
  static AuditInstallationsElectriques? getAuditInstallationsByMissionId(String missionId) {
    if (_auditCache.containsKey(missionId)) {
      final cached = _auditCache[missionId]!;
      if (cached.isInBox) {
        if (!_migratedMissions.contains(missionId)) {
          _migratedMissions.add(missionId);
          _migrateAuditIfNeeded(cached);
        }
        return cached;
      }
    }
    if (!Hive.isBoxOpen(_auditBox)) return null;
    final box = Hive.box<AuditInstallationsElectriques>(_auditBox);
    try {
      AuditInstallationsElectriques? audit = box.get(missionId);
      audit ??= box.values.firstWhere((a) => a.missionId == missionId);
      _auditCache[missionId] = audit;
      if (!_migratedMissions.contains(missionId)) {
        _migratedMissions.add(missionId);
        _migrateAuditIfNeeded(audit);
      }
      return audit;
    } catch (e) {
      return null;
    }
  }

static void _migrateAuditIfNeeded(AuditInstallationsElectriques audit) {
  bool changed = false;

  void migrateObservationLibre(ObservationLibre obs) {
    if (obs.referenceNormative != null && obs.referenceNormative!.isNotEmpty) {
      final cleaned = NormativeReferenceCleaner.clean(obs.referenceNormative);
      final finalVal = (cleaned == '-' || cleaned.isEmpty) ? null : cleaned;
      if (finalVal != obs.referenceNormative) {
        obs.referenceNormative = finalVal;
        changed = true;
      }
    }
  }

  void migrateElementControle(ElementControle el, {String? localType}) {
    final meta = DispositionsConstructivesRegistry.getMetadata(el.elementControle, localType: localType);
    if (meta != null) {
      if (el.criticite == null || el.criticite!.isEmpty) {
        el.criticite = meta.criticite;
        changed = true;
      }
      if (el.familleRisque == null || el.familleRisque!.isEmpty) {
        el.familleRisque = meta.familleRisque;
        changed = true;
      }
      if (el.referenceNormative == null || el.referenceNormative!.isEmpty) {
        el.referenceNormative = meta.referenceNormative;
        changed = true;
      }
    }
    if (el.referenceNormative != null && el.referenceNormative!.isNotEmpty) {
      final cleaned = NormativeReferenceCleaner.clean(el.referenceNormative);
      final finalVal = (cleaned == '-' || cleaned.isEmpty) ? null : cleaned;
      if (finalVal != el.referenceNormative) {
        el.referenceNormative = finalVal;
        changed = true;
      }
    }
  }

  void migrateCoffret(CoffretArmoire coffret, {String? parentName}) {
    if (coffret.id == null || coffret.id!.trim().isEmpty) {
      coffret.id =
          'equip_${DateTime.now().microsecondsSinceEpoch}_${coffret.nom.hashCode.abs()}_${coffret.qrCode.hashCode.abs()}';
      changed = true;
    }
    if (coffret.observationsParafoudreEnrichies == null) {
      coffret.observationsParafoudreEnrichies = [];
      changed = true;
    }
    if (coffret.observationsParafoudreEnrichies!.isEmpty && coffret.observationsParafoudre.isNotEmpty) {
      for (var oldObs in coffret.observationsParafoudre) {
        final el = ElementControle(
          elementControle: oldObs.texte,
          conforme: false,
          observation: oldObs.texte,
          photos: List.from(oldObs.photos),
        );
        migrateElementControle(el);
        coffret.observationsParafoudreEnrichies!.add(el);
      }
      changed = true;
    }

    for (var el in coffret.observationsParafoudreEnrichies!) {
      migrateElementControle(el);
    }

    // Synchronisation automatique et déterministe du point IP/IK avec la règle métier
    final previousIpIkState = coffret.pointsVerification.map((p) => '${p.pointVerification}:${p.conformite}:${p.observation}').join('|');
    IpIkEvaluatorService.syncIpIkPoint(
      coffret: coffret,
      missionId: audit.missionId,
      parentName: parentName,
      audit: audit,
    );
    final currentIpIkState = coffret.pointsVerification.map((p) => '${p.pointVerification}:${p.conformite}:${p.observation}').join('|');
    if (previousIpIkState != currentIpIkState) {
      changed = true;
    }

    for (var pv in coffret.pointsVerification) {
      if (pv.observations == null) {
        pv.observations = [];
        changed = true;
      }
      if (pv.observations!.isEmpty && pv.observation != null && pv.observation!.isNotEmpty) {
        final el = ElementControle(
          elementControle: pv.pointVerification,
          conforme: false,
          observation: pv.observation,
          priorite: pv.priorite,
          criticite: pv.criticite,
          familleRisque: pv.familleRisque,
          referenceNormative: pv.referenceNormative,
          photos: List.from(pv.photos),
        );
        migrateElementControle(el);
        pv.observations!.add(el);
        changed = true;
      }

      final meta = DispositionsConstructivesRegistry.getCoffretMetadata(pv.pointVerification, coffretType: coffret.type);
      if (meta != null) {
        if (pv.criticite == null || pv.criticite!.isEmpty) {
          pv.criticite = meta.criticite;
          changed = true;
        }
        if (pv.familleRisque == null || pv.familleRisque!.isEmpty) {
          pv.familleRisque = meta.familleRisque;
          changed = true;
        }
        if (pv.referenceNormative == null || pv.referenceNormative!.isEmpty) {
          pv.referenceNormative = meta.referenceNormative;
          changed = true;
        }
      }
      if (pv.referenceNormative != null && pv.referenceNormative!.isNotEmpty) {
        final cleaned = NormativeReferenceCleaner.clean(pv.referenceNormative);
        final finalVal = (cleaned == '-' || cleaned.isEmpty) ? null : cleaned;
        if (finalVal != pv.referenceNormative) {
          pv.referenceNormative = finalVal;
          changed = true;
        }
      }

      for (var obs in pv.observations!) {
        migrateElementControle(obs);
      }
    }
  }

  int cellCounter = 0;
  void migrateLocalCellules(dynamic local) {
    if (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT' || local.type == 'LOCAL_POSTE_HTA') {
      for (var cellule in local.cellules) {
        if (cellule.syncId == null || cellule.syncId!.isEmpty) {
          cellule.syncId = 'cellule_${DateTime.now().microsecondsSinceEpoch}_$cellCounter';
          cellCounter++;
          changed = true;
        }
        for (var el in cellule.elementsVerifies) {
          migrateElementControle(el, localType: local.type);
        }
      }
    }
  }

  DescriptionInstallations? cachedDesc;
  bool descFetched = false;
  DescriptionInstallations? getCachedDescription() {
    if (!descFetched) {
      descFetched = true;
      cachedDesc = getDescriptionInstallationsByMissionId(audit.missionId);
    }
    return cachedDesc;
  }

  int transfoCounter = 0;
  void migrateLocalTransformateurs(dynamic local) {
    if (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT' || local.type == 'LOCAL_POSTE_HTA') {
      for (var transfo in local.transformateurs) {
        if (transfo.syncId == null || transfo.syncId!.isEmpty) {
          transfo.syncId = 'transfo_${DateTime.now().microsecondsSinceEpoch}_$transfoCounter';
          transfoCounter++;
          changed = true;
        }
        if (transfo.observations == null) {
          transfo.observations = [];
          changed = true;
        }
        for (var el in transfo.elementsVerifies) {
          migrateElementControle(el, localType: local.type);
        }

        // Data healing / Récupération automatique des champs perdus depuis DescriptionInstallations
        final desc = getCachedDescription();
        if (desc != null) {
          final allItems = [
            ...desc.alimentationMoyenneTension,
            ...desc.alimentationBasseTension,
          ];
          for (final item in allItems) {
            final data = item.data;
            final syncIdInDesc = data['auditTransformateurId'];
            final isMatch = (syncIdInDesc != null && syncIdInDesc == transfo.syncId);

            if (isMatch) {
              String? getVal(List<String> keys) {
                for (final k in keys) {
                  final v = data[k];
                  if (v != null && v.trim().isNotEmpty && v.trim() != '-') {
                    return v.trim();
                  }
                }
                return null;
              }

              final c = getVal(['COUPLAGE', 'Couplage']);
              if ((transfo.couplage == null || transfo.couplage!.isEmpty) && c != null) {
                transfo.couplage = c;
                changed = true;
              }

              final tr = getVal(['TYPE DE RESEAU', 'Type de réseau', 'Nature du réseau']);
              if ((transfo.typeReseau == null || transfo.typeReseau!.isEmpty) && tr != null) {
                transfo.typeReseau = tr;
                changed = true;
              }

              final pcc = getVal(['PCC AMONT EN MVA', 'PCC amont', 'PCC AMONT']);
              if ((transfo.pccAmont == null || transfo.pccAmont!.isEmpty) && pcc != null) {
                transfo.pccAmont = pcc;
                changed = true;
              }

              final ucc = getVal(['UCC EN %', 'Puissance UCC', 'UCC']);
              if ((transfo.puissanceUcc == null || transfo.puissanceUcc!.isEmpty) && ucc != null) {
                transfo.puissanceUcc = ucc;
                changed = true;
              }

              final ik3 = getVal(['IK3 MAX(KA)', 'IK3 MAX', 'IK3 MAX (kA)']);
              if ((transfo.ik3Max == null || transfo.ik3Max!.isEmpty) && ik3 != null) {
                transfo.ik3Max = ik3;
                changed = true;
              }

              final inom = getVal(['INTENSITE NOMINALE', 'Intensité nominale']);
              if ((transfo.intensiteNominale == null || transfo.intensiteNominale!.isEmpty) && inom != null) {
                transfo.intensiteNominale = inom;
                changed = true;
              }
            }
          }
        }
      }
    }
  }

  // Locaux MT
  for (var local in audit.moyenneTensionLocaux) {
    for (var el in local.dispositionsConstructives) {
      migrateElementControle(el, localType: local.type);
    }
    for (var el in local.conditionsExploitation) {
      migrateElementControle(el, localType: local.type);
    }
    for (var obs in local.observationsLibres) {
      migrateObservationLibre(obs);
    }
    migrateLocalCellules(local);
    migrateLocalTransformateurs(local);
    for (var coffret in local.coffrets) {
      migrateCoffret(coffret, parentName: local.nom);
      for (var obs in coffret.observationsLibres) {
        migrateObservationLibre(obs);
      }
    }
  }

  // Zones MT
  for (var zone in audit.moyenneTensionZones) {
    for (var obs in zone.observationsLibres) {
      migrateObservationLibre(obs);
    }
    for (var coffret in zone.coffrets) {
      migrateCoffret(coffret, parentName: zone.nom);
      for (var obs in coffret.observationsLibres) {
        migrateObservationLibre(obs);
      }
    }
    for (var local in zone.locaux) {
      for (var el in local.dispositionsConstructives) {
        migrateElementControle(el, localType: local.type);
      }
      for (var el in local.conditionsExploitation) {
        migrateElementControle(el, localType: local.type);
      }
      for (var obs in local.observationsLibres) {
        migrateObservationLibre(obs);
      }
      migrateLocalCellules(local);
      migrateLocalTransformateurs(local);
      for (var coffret in local.coffrets) {
        migrateCoffret(coffret, parentName: local.nom);
        for (var obs in coffret.observationsLibres) {
          migrateObservationLibre(obs);
        }
      }
    }
  }

  // Zones BT
  for (var zone in audit.basseTensionZones) {
    for (var obs in zone.observationsLibres) {
      migrateObservationLibre(obs);
    }
    for (var coffret in zone.coffretsDirects) {
      migrateCoffret(coffret, parentName: zone.nom);
      for (var obs in coffret.observationsLibres) {
        migrateObservationLibre(obs);
      }
    }
    for (var local in zone.locaux) {
      if (local.dispositionsConstructives != null) {
        for (var el in local.dispositionsConstructives!) {
          migrateElementControle(el, localType: local.type);
        }
      }
      if (local.conditionsExploitation != null) {
        for (var el in local.conditionsExploitation!) {
          migrateElementControle(el, localType: local.type);
        }
      }
      for (var obs in local.observationsLibres) {
        migrateObservationLibre(obs);
      }
      migrateLocalCellules(local);
      migrateLocalTransformateurs(local);
      for (var coffret in local.coffrets) {
        migrateCoffret(coffret, parentName: local.nom);
        for (var obs in coffret.observationsLibres) {
          migrateObservationLibre(obs);
        }
      }
    }
  }

  final batchReport = MissionNormativeBatchService.processAudit(audit);
  if (changed || batchReport.autoLinkedCount > 0) {
    audit.save();
  }
}

// ============================================================
//          GESTION COFFRETS/ARMOIRES
// ============================================================

/// Ajouter un coffret à un local moyenne tension
static Future<bool> addCoffretToMoyenneTensionLocal({
  required String missionId,
  required int localIndex,
  required String qrCode, // Nouveau paramètre
  required CoffretArmoire coffret,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (localIndex < audit.moyenneTensionLocaux.length) {
      // Assurer que le coffret a le bon QR code
      coffret.qrCode = qrCode;
      audit.moyenneTensionLocaux[localIndex].coffrets.add(coffret);
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addCoffretToMoyenneTensionLocal: $e');
    return false;
  }
}

  /// Recherche forensique d'un coffret dans toute la mission par son ID d'équipement ou son QR code
  static CoffretArmoire? findCoffretByIdOrQrCode({
    required String missionId,
    required String equipmentId,
    String? qrCode,
  }) {
    try {
      final audit = getAuditInstallationsByMissionId(missionId);
      if (audit == null) return null;

      final normQr = qrCode?.trim() ?? '';
      final hasValidQr = normQr.isNotEmpty && !normQr.startsWith('TEMP_') && !normQr.startsWith('DRAFT_');

      bool matches(CoffretArmoire c) {
        if (c.id != null && c.id == equipmentId) return true;
        if (c.equipmentId == equipmentId) return true;
        if (hasValidQr && c.qrCode.trim() == normQr) return true;
        return false;
      }

      for (var local in audit.moyenneTensionLocaux) {
        for (var coffret in local.coffrets) {
          if (matches(coffret)) return coffret;
        }
      }
      for (var zone in audit.moyenneTensionZones) {
        for (var coffret in zone.coffrets) {
          if (matches(coffret)) return coffret;
        }
        for (var local in zone.locaux) {
          for (var coffret in local.coffrets) {
            if (matches(coffret)) return coffret;
          }
        }
      }
      for (var zone in audit.basseTensionZones) {
        for (var coffret in zone.coffretsDirects) {
          if (matches(coffret)) return coffret;
        }
        for (var local in zone.locaux) {
          for (var coffret in local.coffrets) {
            if (matches(coffret)) return coffret;
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur findCoffretByIdOrQrCode: $e');
      return null;
    }
  }

/// Chercher un coffret par son QR code dans toute la mission
static CoffretArmoire? findCoffretByQrCode(String missionId, String qrCode) {
  try {
    final audit = getAuditInstallationsByMissionId(missionId);
    if (audit == null) return null;
    
    // Chercher dans les locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      for (var coffret in local.coffrets) {
        if (coffret.qrCode == qrCode) {
          return coffret;
        }
      }
    }
    
    // Chercher dans les zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var coffret in zone.coffrets) {
        if (coffret.qrCode == qrCode) {
          return coffret;
        }
      }
      
      // Chercher dans les locaux de la zone
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          if (coffret.qrCode == qrCode) {
            return coffret;
          }
        }
      }
    }
    
    // Chercher dans les zones BT
    for (var zone in audit.basseTensionZones) {
      for (var coffret in zone.coffretsDirects) {
        if (coffret.qrCode == qrCode) {
          return coffret;
        }
      }
      
      // Chercher dans les locaux de la zone BT
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          if (coffret.qrCode == qrCode) {
            return coffret;
          }
        }
      }
    }
    
    return null;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur findCoffretByQrCode: $e');
    }
    return null;
  }
}

/// Calcule le prochain numéro d'équipement pour une mission.
///
/// Stratégie :
/// - Parcourt TOUS les coffrets de la mission (locaux MT, zones MT, zones BT, locaux BT).
/// - Collecte uniquement les [numeroEquipement] qui sont des entiers purs.
/// - Retourne max + 1, ou 1 si aucun entier trouvé.
/// - Les valeurs textuelles existantes sont totalement ignorées.
  /// Calcule le prochain numéro d'équipement pour une mission via [EquipmentNumberService].
  static int getNextNumeroEquipement(String missionId) {
    return EquipmentNumberService.getNextEquipmentNumber(missionId);
  }

  /// Mettre à jour un coffret en base de données par son [equipmentId] immuable (SaveGuard inclus)
  /// Protégé contre les accès concurrents via la [PersistenceQueue].
  static Future<bool> updateCoffretById({
    required String missionId,
    required String equipmentId,
    required CoffretArmoire updatedCoffret,
    String? oldNom,
    bool allowClearDepartures = false,
    bool allowClearCircuits = false,
  }) async {
    return PersistenceQueue.enqueue('audit_$missionId', () async {
      try {
        final audit = await getOrCreateAuditInstallations(missionId);
        
        bool findAndReplaceInList(List<CoffretArmoire> list) {
          // 1. Match par equipmentId immuable / id
          int index = list.indexWhere((c) => c.equipmentId == equipmentId || (c.id != null && c.id == equipmentId));
          
          // 2. Fallback pour anciennes missions importées : match par qrCode ou par ancien nom
          if (index == -1 && updatedCoffret.qrCode.trim().isNotEmpty) {
            index = list.indexWhere((c) => c.qrCode.trim() == updatedCoffret.qrCode.trim());
          }
          if (index == -1 && oldNom != null && oldNom.trim().isNotEmpty) {
            index = list.indexWhere((c) => c.nom.trim() == oldNom.trim());
          }
          if (index == -1 && updatedCoffret.nom.trim().isNotEmpty) {
            index = list.indexWhere((c) => c.nom.trim() == updatedCoffret.nom.trim());
          }

          if (index != -1) {
            final existing = list[index];
            updatedCoffret.id = existing.id ?? equipmentId;
            updatedCoffret.createdAt = existing.createdAt ?? updatedCoffret.createdAt;
            updatedCoffret.updatedAt = DateTime.now().toUtc();

            // RÈGLE ZERO DATA LOSS : Préserver les départs existants si l'instance entrante est vide et non autorisée à vider
            if (updatedCoffret.effectiveDepartures.isEmpty && existing.effectiveDepartures.isNotEmpty && !allowClearDepartures) {
              updatedCoffret.departures = List.from(existing.effectiveDepartures);
            }
            // RÈGLE ZERO DATA LOSS : Préserver les circuits existants si l'instance entrante est vide et non autorisée à vider
            if (updatedCoffret.effectiveTerminalCircuits.isEmpty && existing.effectiveTerminalCircuits.isNotEmpty && !allowClearCircuits) {
              updatedCoffret.terminalCircuits = List.from(existing.effectiveTerminalCircuits);
            }

            list[index] = updatedCoffret;
            return true;
          }
          return false;
        }

        bool found = false;
        for (var local in audit.moyenneTensionLocaux) {
          if (findAndReplaceInList(local.coffrets)) { found = true; break; }
        }

        if (!found) {
          for (var zone in audit.moyenneTensionZones) {
            if (findAndReplaceInList(zone.coffrets)) { found = true; break; }
            for (var local in zone.locaux) {
              if (findAndReplaceInList(local.coffrets)) { found = true; break; }
            }
            if (found) break;
          }
        }

        if (!found) {
          for (var zone in audit.basseTensionZones) {
            if (findAndReplaceInList(zone.coffretsDirects)) { found = true; break; }
            for (var local in zone.locaux) {
              if (findAndReplaceInList(local.coffrets)) { found = true; break; }
            }
            if (found) break;
          }
        }

        if (!found) {
          if (kDebugMode) {
            print('❌ SAVEGUARD FAILURE: Équipement avec ID $equipmentId (ou QR/Nom) introuvable dans la mission $missionId.');
          }
          return false;
        }

        await saveAuditInstallations(audit, skipDescriptionSync: true);
        if (kDebugMode) {
          print('✅ Coffret mis à jour par ID/Fallback immuable: $equipmentId (${updatedCoffret.nom})');
        }
        return true;
      } catch (e, stack) {
        if (kDebugMode) {
          print('❌ Erreur updateCoffretById: $e');
          print(stack);
        }
        rethrow;
      }
    });
  }

  /// Déconnecte proprement tout équipement aval qui référençait ce [departId] supprimé
  static Future<int> cleanupOrphanDepartSources(String missionId, String departId) async {
    if (departId.trim().isEmpty) return 0;
    try {
      final audit = getAuditInstallationsByMissionId(missionId);
      if (audit == null) return 0;

      int cleanedCount = 0;
      void checkAndClean(List<CoffretArmoire> coffrets) {
        for (final c in coffrets) {
          if (c.sourceDepartId != null && c.sourceDepartId == departId) {
            c.sourceDepartId = null;
            cleanedCount++;
          }
        }
      }

      for (final l in audit.moyenneTensionLocaux) {
        checkAndClean(l.coffrets);
      }
      for (final z in audit.moyenneTensionZones) {
        checkAndClean(z.coffrets);
        for (final l in z.locaux) {
          checkAndClean(l.coffrets);
        }
      }
      for (final z in audit.basseTensionZones) {
        checkAndClean(z.coffretsDirects);
        for (final l in z.locaux) {
          checkAndClean(l.coffrets);
        }
      }

      if (cleanedCount > 0) {
        await saveAuditInstallations(audit, skipDescriptionSync: true);
        if (kDebugMode) {
          print('🧹 [CLEANUP ORPHAN DEPART] $cleanedCount équipement(s) aval déconnecté(s) du départ supprimé $departId');
        }
      }
      return cleanedCount;
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur cleanupOrphanDepartSources: $e');
      return 0;
    }
  }

// Vérifier si un QR code existe déjà
static bool qrCodeExists(String missionId, String qrCode) {
  if (qrCode.trim().isEmpty) return false;
  return findCoffretByQrCode(missionId, qrCode) != null;
}

/// Valider qu'un QR code est unique pour la mission
static Future<bool> validateUniqueQrCode({
  required String missionId,
  required String qrCode,
  String? excludeCoffretName, // Pour les mises à jour
}) async {
  if (qrCode.trim().isEmpty) return true;
  final existingCoffret = findCoffretByQrCode(missionId, qrCode);
  
  if (existingCoffret == null) {
    return true; // QR code unique
  }
  
  // Si on exclut un coffret (pour les mises à jour)
  if (excludeCoffretName != null && existingCoffret.nom == excludeCoffretName) {
    return true; // Même coffret, mise à jour autorisée
  }
  
  return false; // QR code déjà utilisé
}

  /// Supprime un équipement (BT ou MT) de façon propre et atomique dans la mission
  /// en le localisant par son [equipmentId] immuable (ou fallback QR/nom).
  /// Libère et délie IMMÉDIATEMENT le QR code associé en purgeant la boîte de brouillons.
  static Future<bool> deleteCoffret({
    required String missionId,
    required String equipmentId,
    String? qrCode,
  }) async {
    return PersistenceQueue.enqueue('audit_$missionId', () async {
      try {
        final audit = await getOrCreateAuditInstallations(missionId);
        String? foundQrCode = qrCode;

        bool removeInList(List<CoffretArmoire> list) {
          int index = list.indexWhere((c) => c.equipmentId == equipmentId || (c.id != null && c.id == equipmentId));
          if (index == -1 && qrCode != null && qrCode.trim().isNotEmpty) {
            index = list.indexWhere((c) => c.qrCode.trim() == qrCode.trim());
          }
          if (index != -1) {
            foundQrCode ??= list[index].qrCode;
            list.removeAt(index);
            return true;
          }
          return false;
        }

        bool deleted = false;
        // MT Locaux
        for (var local in audit.moyenneTensionLocaux) {
          if (removeInList(local.coffrets)) { deleted = true; break; }
        }
        // MT Zones
        if (!deleted) {
          for (var zone in audit.moyenneTensionZones) {
            if (removeInList(zone.coffrets)) { deleted = true; break; }
            for (var local in zone.locaux) {
              if (removeInList(local.coffrets)) { deleted = true; break; }
            }
            if (deleted) break;
          }
        }
        // BT Zones
        if (!deleted) {
          for (var zone in audit.basseTensionZones) {
            if (removeInList(zone.coffretsDirects)) { deleted = true; break; }
            for (var local in zone.locaux) {
              if (removeInList(local.coffrets)) { deleted = true; break; }
            }
            if (deleted) break;
          }
        }

        // 2. Libération immédiate du QR Code et purge des brouillons orphelins
        if (foundQrCode != null && foundQrCode!.trim().isNotEmpty) {
          await deleteCoffretDraft(foundQrCode!.trim());
        }
        // Purge d'éventuels brouillons indexés sous l'equipmentId
        await deleteCoffretDraft(equipmentId);

        if (deleted) {
          await saveAuditInstallations(audit, skipDescriptionSync: true);
          if (kDebugMode) {
            print('✅ Équipement supprimé avec succès ($equipmentId). QR code délié et libéré.');
          }
          return true;
        }

        // Même si absent de l'arborescence (déjà supprimé), purger les résidus de brouillons
        if (foundQrCode != null && foundQrCode!.trim().isNotEmpty) {
          await deleteCoffretDraft(foundQrCode!.trim());
        }
        return false;
      } catch (e, stack) {
        if (kDebugMode) {
          print('❌ Erreur deleteCoffret: $e');
          print(stack);
        }
        return false;
      }
    });
  }

  /// Procédure idempotente et sécurisée de réconciliation des QR codes d'une mission.
  /// Identifie les entrées orphelines dans `coffret_drafts` dont l'équipement parent ou
  /// l'équipement lui-même a été supprimé de l'audit, et libère leurs QR codes.
  static Future<int> reconcileQrCodes(String missionId) async {
    int freedCount = 0;
    try {
      if (!Hive.isBoxOpen(_coffretDraftsBox)) {
        await Hive.openBox(_coffretDraftsBox);
      }
      final box = Hive.box(_coffretDraftsBox);
      final audit = getAuditInstallationsByMissionId(missionId);
      if (audit == null) return 0;

      // Rassembler tous les QR codes d'équipements valides existant dans l'audit
      final activeEquipmentsByQr = <String, CoffretArmoire>{};
      final activeEquipmentIds = <String>{};

      for (var local in audit.moyenneTensionLocaux) {
        for (var c in local.coffrets) {
          if (c.qrCode.trim().isNotEmpty) activeEquipmentsByQr[c.qrCode.trim()] = c;
          activeEquipmentIds.add(c.equipmentId);
        }
      }
      for (var zone in audit.moyenneTensionZones) {
        for (var c in zone.coffrets) {
          if (c.qrCode.trim().isNotEmpty) activeEquipmentsByQr[c.qrCode.trim()] = c;
          activeEquipmentIds.add(c.equipmentId);
        }
        for (var local in zone.locaux) {
          for (var c in local.coffrets) {
            if (c.qrCode.trim().isNotEmpty) activeEquipmentsByQr[c.qrCode.trim()] = c;
            activeEquipmentIds.add(c.equipmentId);
          }
        }
      }
      for (var zone in audit.basseTensionZones) {
        for (var c in zone.coffretsDirects) {
          if (c.qrCode.trim().isNotEmpty) activeEquipmentsByQr[c.qrCode.trim()] = c;
          activeEquipmentIds.add(c.equipmentId);
        }
        for (var local in zone.locaux) {
          for (var c in local.coffrets) {
            if (c.qrCode.trim().isNotEmpty) activeEquipmentsByQr[c.qrCode.trim()] = c;
            activeEquipmentIds.add(c.equipmentId);
          }
        }
      }

      // Parcourir les clés de coffret_drafts
      final keysToDelete = <dynamic>[];
      for (var key in box.keys) {
        final val = box.get(key);
        if (val is Map && val['missionId'] == missionId) {
          final coffret = val['coffret'];
          final isCompleted = coffret is CoffretArmoire && coffret.statut == 'complet';
          final draftQr = key.toString();

          // Si le brouillon est marqué 'complet' et correspond à un équipement déjà dans l'audit, purger le brouillon
          if (isCompleted && activeEquipmentsByQr.containsKey(draftQr)) {
            keysToDelete.add(key);
            freedCount++;
            continue;
          }

          // Si le brouillon référence un emplacement parent inexistant (zone ou local supprimé)
          final isMt = val['isMoyenneTension'] as bool? ?? false;
          final pType = val['parentType'] as String?;
          final pIdx = val['parentIndex'] as int?;
          final zIdx = val['zoneIndex'] as int?;

          bool parentExists = true;
          if (pType == 'local') {
            if (isMt) {
              if (zIdx != null) {
                if (zIdx >= audit.moyenneTensionZones.length || pIdx == null || pIdx >= audit.moyenneTensionZones[zIdx].locaux.length) {
                  parentExists = false;
                }
              } else if (pIdx == null || pIdx >= audit.moyenneTensionLocaux.length) {
                parentExists = false;
              }
            } else {
              if (zIdx == null || zIdx >= audit.basseTensionZones.length || pIdx == null || pIdx >= audit.basseTensionZones[zIdx].locaux.length) {
                parentExists = false;
              }
            }
          } else if (pType == 'zone_mt') {
            if (pIdx == null || pIdx >= audit.moyenneTensionZones.length) parentExists = false;
          } else if (pType == 'zone_bt') {
            if (pIdx == null || pIdx >= audit.basseTensionZones.length) parentExists = false;
          }

          if (!parentExists) {
            keysToDelete.add(key);
            freedCount++;
          }
        }
      }

      for (var k in keysToDelete) {
        await box.delete(k);
      }

      if (kDebugMode && freedCount > 0) {
        print('🧹 Réconciliation QR codes : $freedCount brouillons/QR orphelins libérés pour la mission $missionId');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur reconcileQrCodes: $e');
    }
    return freedCount;
  }

/// Mettre à jour les informations d'un coffret après scan du QR code
static Future<bool> updateCoffretAfterQrScan({
  required String missionId,
  required String qrCode,
  required CoffretArmoire updatedCoffret,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    bool found = false;
    
    // Fonction de recherche et remplacement
    bool replaceInList(List<CoffretArmoire> coffrets) {
      final index = coffrets.indexWhere((c) => c.qrCode == qrCode);
      if (index != -1) {
        coffrets[index] = updatedCoffret;
        return true;
      }
      return false;
    }
    
    // Chercher dans tous les endroits possibles
    for (var local in audit.moyenneTensionLocaux) {
      if (replaceInList(local.coffrets)) {
        found = true;
        break;
      }
    }
    
    if (!found) {
      for (var zone in audit.moyenneTensionZones) {
        if (replaceInList(zone.coffrets)) {
          found = true;
          break;
        }
        for (var local in zone.locaux) {
          if (replaceInList(local.coffrets)) {
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (!found) {
      for (var zone in audit.basseTensionZones) {
        if (replaceInList(zone.coffretsDirects)) {
          found = true;
          break;
        }
        for (var local in zone.locaux) {
          if (replaceInList(local.coffrets)) {
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (found) {
      await saveAuditInstallations(audit);
      if (kDebugMode) {
        print('✅ Coffret mis à jour après scan QR code: $qrCode');
      }
      return true;
    }
    
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur updateCoffretAfterQrScan: $e');
    }
    return false;
  }
}

/// Créer un nouveau coffret avec QR code
static CoffretArmoire createNewCoffretWithQrCode({
  required String qrCode,
  required String nom,
  required String type,
  String? description,
}) {
  return CoffretArmoire(
    qrCode: qrCode,
    nom: nom,
    type: type,
    description: description,
    zoneAtex: false,
    domaineTension: '',
    identificationArmoire: false,
    signalisationDanger: false,
    presenceSchema: false,
    presenceParafoudre: false,
    verificationThermographie: false,
    alimentations: [],
    pointsVerification: [],
    observationsLibres: [],
    photos: [],
  );
}

static CoffretArmoire? getCoffretDraftByQrCode(String qrCode) {
  if (qrCode.trim().isEmpty) return null;
  try {
    final box = Hive.box(_coffretDraftsBox);
    final data = box.get(qrCode);
    
    if (data != null && data is Map && data['coffret'] is CoffretArmoire) {
      return data['coffret'] as CoffretArmoire;
    }
    return null;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getCoffretDraftByQrCode: $e');
    }
    return null;
  }
}

/// Ajouter un coffret à un local basse tension
static Future<bool> addCoffretToBasseTensionLocal({
  required String missionId,
  required int zoneIndex,
  required int localIndex,
  required CoffretArmoire coffret,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.basseTensionZones.length && 
        localIndex < audit.basseTensionZones[zoneIndex].locaux.length) {
      audit.basseTensionZones[zoneIndex].locaux[localIndex].coffrets.add(coffret);
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addCoffretToBasseTensionLocal: $e');
    return false;
  }
}

/// Ajouter un coffret directement dans une zone
static Future<bool> addCoffretToMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
  required CoffretArmoire coffret,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.moyenneTensionZones.length) {
      audit.moyenneTensionZones[zoneIndex].coffrets.add(coffret);
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addCoffretToMoyenneTensionZone: $e');
    return false;
  }
}

/// Ajouter un coffret directement dans une zone basse tension
static Future<bool> addCoffretToBasseTensionZone({
  required String missionId,
  required int zoneIndex,
  required CoffretArmoire coffret,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.basseTensionZones.length) {
      audit.basseTensionZones[zoneIndex].coffretsDirects.add(coffret);
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addCoffretToBasseTensionZone: $e');
    return false;
  }
}

// ============================================================
//          MÉTHODES UTILITAIRES
// ============================================================

/// Vérifier si une mission a des données d'audit
static bool hasAuditInstallations(String missionId) {
  return getAuditInstallationsByMissionId(missionId) != null;
}

/// Obtenir tous les types de coffrets disponibles
static List<String> getCoffretTypes() {
  return [
    'Tableau urbain réduit (TUR)',
    'INVERSEUR',
    'TGBT',
    'ARMOIRE',
    'COFFRET',
    //'ARMOIRE CENTRAL CLIMATISATION',
    //'COFFRET ALIMANTATION DU COFFRET AC',
    // 'COFFRET GESTION ADMINISTRATIVE',
    // 'COFFRET NORMAL 1',
    // 'COFFRET NORMAL 2',
    // 'COFFRET SERVICE JURIDIQUE',
    // 'COFFRET CLIENTELE PROFESSIONNEL',
    // 'COFFRET DIRECTION GENERALE',
    //'COFFRET CLIENTELE ENTREPRISE',
    'TABLEAU ALIMENTATION PRINCIPAL ONDULEUR (TAOP)',
    'TABLEAU DIVISIONNAIRE ONDULEUR SERVEUR (TDOSA)',
    'TABLEAU DIVISIONNAIRE ONDULEUR SERVEUR (TDOSB)',
    'TABLEAU DIVISIONNAIRE CLIM SERVEUR (TDCS)',
    'TABLEAU GENERAL ONDULEUR (TGO)',
    // 'COFFRET LOCAL TECHNIQUE ASCENCEUR',
    // 'COFFRET ELCTRIQUE ONDULE REZ DE CHAUSSEE',
    // 'COFFRET ELCTRIQUE ONDULE SOUS SOL - 2',
    // 'ARMOIRE ELECTRIQUE TT + VENT',
    // 'ARMOIRE ELECTRIQUE TD ETAGE 2',
    //'COFFRET NORMAL',
    //'COFFRET ELCTRIQUE ONDULE SOUS ETAGE 1',
    // 'COFFRET ELCTRIQUE ONDULE SOUS ETAGE 2',
    // 'COFFRET SOUS SOL – 2 LOCAL DE CONTROLE',
  ];
}

/// Retourne tous les types de locaux.
/// [isMoyenneTension] filtre les types selon le contexte :
/// - null (non filtré) : retourne tous les types
static Map<String, String> getLocalTypes({bool? isMoyenneTension}) {
  final all = {
    'LOCAL_TRANSFORMATEUR': 'Local Moyenne Tension',
    'LOCAL_MTBT': 'Local HT/BT',
    'LOCAL_GROUPE_ELECTROGENE': 'Local Groupe Électrogène',
    'LOCAL_TGBT': 'Local TGBT',
    'LOCAL_ONDULEUR': 'Local Onduleur',
    'GAINE_TECHNIQUE': 'Gaine Technique',
    'LOCAL_TECHNIQUE_ASCENCEUR': 'Local Technique Ascenseur',
    'BAIE_INFORMATIQUE': 'Baie Informatique',
    'LOCAL_ELECTRIQUE': 'Local Électrique',
    'LOCAL_DE_CONTROLE': 'Local de Contrôle',
  };

    if (isMoyenneTension == true) {
      return {
        'LOCAL_TRANSFORMATEUR': 'Local Moyenne Tension',
        'LOCAL_MTBT': 'Local HT/BT',
      };
    } else if (isMoyenneTension == false) {
      // Zone BT : on retire Local Moyenne Tension (pure MT) et Local MT/BT
      return Map.fromEntries(
          all.entries.where((e) => e.key != 'LOCAL_TRANSFORMATEUR' && e.key != 'LOCAL_MTBT'));
    }
    return all;

  // if (isMoyenneTension == true) {
  //   return all;
  // } else if (isMoyenneTension == false) {
  //   // Zone BT : on retire Local Moyenne Tension (pure MT)
  //   return Map.fromEntries(all.entries.where((e) => e.key != 'LOCAL_TRANSFORMATEUR'));
  // }
  // return all;
}

/// Obtenir les éléments de contrôle pour un type de local
static List<String> getDispositionsConstructivesForLocal(String localType) {
  switch (localType) {
    case 'LOCAL_TRANSFORMATEUR':
    case 'LOCAL_MTBT':
      return List<String>.from(DispositionsConstructivesRegistry.allDispositionsConstructives);
    
    case 'LOCAL_GROUPE_ELECTROGENE':
      return List<String>.from(DispositionsConstructivesRegistry.allGEDispositionsPoints);

    case 'LOCAL_BT':
    case 'LOCAL_TGBT':
    case 'LOCAL_ONDULEUR':
    case 'LOCAL_ELECTRIQUE':
    default:
      return List<String>.from(DispositionsConstructivesRegistry.allBTDispositionsPoints);
  }
}

/// Obtenir les conditions d'exploitation pour un type de local
static List<String> getConditionsExploitationForLocal(String localType) {
  if (localType == 'LOCAL_TRANSFORMATEUR' || localType == 'LOCAL_MTBT') {
    return List<String>.from(DispositionsConstructivesRegistry.allConditionsExploitation);
  } else if (localType == 'LOCAL_GROUPE_ELECTROGENE') {
    return List<String>.from(DispositionsConstructivesRegistry.allGEConditionsPoints);
  }
  return List<String>.from(DispositionsConstructivesRegistry.allBTConditionsPoints);
}

/// Obtenir les points de vérification pour un type de coffret
static List<String> getPointsVerificationForCoffret(String coffretType) {
  switch (coffretType) {
    case 'INVERSEUR':
      return List<String>.from(DispositionsConstructivesRegistry.allInverseurPoints);
    
    default:
      return List<String>.from(DispositionsConstructivesRegistry.allCoffretPoints);
  }
}

// ============================================================
//          GESTION MOYENNE TENSION
// ============================================================

/// Ajouter un local moyenne tension
static Future<bool> addMoyenneTensionLocal({
  required String missionId,
  required MoyenneTensionLocal local,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    // S'assurer que la liste est modifiable
    if (audit.moyenneTensionLocaux.isEmpty) {
      audit.moyenneTensionLocaux = [];
    }
    
    audit.moyenneTensionLocaux.add(local);
    await saveAuditInstallations(audit);
    if (kDebugMode) print('✅ Local moyenne tension ajouté: ${local.nom}');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addMoyenneTensionLocal: $e');
    return false;
  }
}

/// Ajouter une zone moyenne tension
static Future<bool> addMoyenneTensionZone({
  required String missionId,
  required MoyenneTensionZone zone,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    if (audit.moyenneTensionZones.isEmpty) {
      audit.moyenneTensionZones = [];
    }
    
    // Créer le classement pour la zone AVANT de l'ajouter
    final classement = await getOrCreateClassementForZone(
      missionId: missionId,
      nomZone: zone.nom,
    );
    
    // Lier le classement à la zone
    zone.classementZoneId = classement.key.toString();
    
    audit.moyenneTensionZones.add(zone);
    await saveAuditInstallations(audit);
    if (kDebugMode) print('✅ Zone moyenne tension ajoutée: ${zone.nom} avec classement ${zone.classementZoneId}');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addMoyenneTensionZone: $e');
    return false;
  }
}

/// Ajouter une zone basse tension
static Future<bool> addBasseTensionZone({
  required String missionId,
  required BasseTensionZone zone,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    if (audit.basseTensionZones.isEmpty) {
      audit.basseTensionZones = [];
    }
    
    // Créer le classement pour la zone AVANT de l'ajouter
    final classement = await getOrCreateClassementForZone(
      missionId: missionId,
      nomZone: zone.nom,
    );
    
    // Lier le classement à la zone
    zone.classementZoneId = classement.key.toString();
    
    audit.basseTensionZones.add(zone);
    await saveAuditInstallations(audit);
    if (kDebugMode) print('✅ Zone basse tension ajoutée: ${zone.nom} avec classement ${zone.classementZoneId}');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addBasseTensionZone: $e');
    return false;
  }
}

/// Ajouter un local dans une zone basse tension
static Future<bool> addLocalToBasseTensionZone({
  required String missionId,
  required int zoneIndex,
  required BasseTensionLocal local,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    if (zoneIndex < audit.basseTensionZones.length) {
      final zone = audit.basseTensionZones[zoneIndex];
      
      // S'assurer que la liste est modifiable
      if (zone.locaux.isEmpty) {
        zone.locaux = [];
      }
      
      zone.locaux.add(local);
      await saveAuditInstallations(audit);
      if (kDebugMode) {
        print('✅ Local basse tension ajouté: ${local.nom}');
      }
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur addLocalToBasseTensionZone: $e');
    }
    return false;
  }
}

  /// Dédupliquer intelligemment une liste de coffrets/équipements
  /// en conservant l'instance la plus complète et à jour, avec fusion protectrice sans perte.
  static List<CoffretArmoire> deduplicateCoffrets(List<CoffretArmoire> coffrets) {
    if (coffrets.length <= 1) return coffrets;
    
    final result = <CoffretArmoire>[];
    
    for (var coffret in coffrets) {
      final normNom = coffret.nom.trim().toLowerCase();
      final normQr = coffret.qrCode.trim();
      final eqId = coffret.equipmentId;
      final explicitId = coffret.id?.trim();
      
      final matchIdx = result.indexWhere((existing) {
        if (explicitId != null && explicitId.isNotEmpty && existing.id != null && existing.id!.trim() == explicitId) {
          return true;
        }
        if (existing.equipmentId == eqId) {
          return true;
        }
        if (normQr.isNotEmpty && !normQr.startsWith('TEMP_') && !normQr.startsWith('DRAFT_') && existing.qrCode.trim() == normQr) {
          return true;
        }
        return false;
      });
      
      if (matchIdx == -1) {
        result.add(coffret);
      } else {
        final existing = result[matchIdx];
        final existingCompleteness = (existing.pointsVerification.length * 2) +
            existing.photos.length +
            (existing.departures?.length ?? 0) +
            (existing.terminalCircuits?.length ?? 0) +
            (existing.statut == 'complet' ? 10 : 0);
        final newCompleteness = (coffret.pointsVerification.length * 2) +
            coffret.photos.length +
            (coffret.departures?.length ?? 0) +
            (coffret.terminalCircuits?.length ?? 0) +
            (coffret.statut == 'complet' ? 10 : 0);
            
        final base = (newCompleteness >= existingCompleteness) ? coffret : existing;
        final donor = (newCompleteness >= existingCompleteness) ? existing : coffret;
        
        base.id ??= donor.id;
        base.createdAt ??= donor.createdAt;

        // FUSION PROTECTRICE DES DÉPARTS (Deep Merge sans perte)
        final mergedDepartures = <DepartEquipement>[...base.effectiveDepartures];
        for (final dep in donor.effectiveDepartures) {
          final idx = mergedDepartures.indexWhere((d) {
            // 1. Même ID explicite non-vide
            if (d.id.isNotEmpty && dep.id.isNotEmpty && d.id == dep.id) {
              return true;
            }
            // 2. Clone strict en cas d'absence de concordance d'ID : même identification ET mêmes specs techniques clés
            final dNom = d.identification.trim().toLowerCase();
            final depNom = dep.identification.trim().toLowerCase();
            if (dNom.isNotEmpty && dNom == depNom) {
              final sameCalibre = d.calibre.trim() == dep.calibre.trim();
              final sameType = d.typeProtection.trim() == dep.typeProtection.trim();
              final sameCourbe = d.courbe.trim() == dep.courbe.trim();
              final sameDdr = d.ddr.trim() == dep.ddr.trim();
              return sameCalibre && sameType && sameCourbe && sameDdr;
            }
            return false;
          });
          if (idx == -1) {
            mergedDepartures.add(dep);
          } else {
            // Enrichir les champs vides du départ existant avec le donneur
            final current = mergedDepartures[idx];
            if (current.typeProtection.isEmpty && dep.typeProtection.isNotEmpty) current.typeProtection = dep.typeProtection;
            if (current.calibre.isEmpty && dep.calibre.isNotEmpty) current.calibre = dep.calibre;
            if (current.courbe.isEmpty && dep.courbe.isNotEmpty) current.courbe = dep.courbe;
            if (current.ddr.isEmpty && dep.ddr.isNotEmpty) current.ddr = dep.ddr;
            if (current.pdcKA.isEmpty && dep.pdcKA.isNotEmpty) current.pdcKA = dep.pdcKA;
            if (current.sectionCable.isEmpty && dep.sectionCable.isNotEmpty) current.sectionCable = dep.sectionCable;
            if (current.sectionCableNeutre == null && dep.sectionCableNeutre != null) current.sectionCableNeutre = dep.sectionCableNeutre;
            if (current.conducteursPhase == null && dep.conducteursPhase != null) current.conducteursPhase = dep.conducteursPhase;
            if (current.conducteursNeutre == null && dep.conducteursNeutre != null) current.conducteursNeutre = dep.conducteursNeutre;
            if (current.natureCable == null && dep.natureCable != null) current.natureCable = dep.natureCable;
          }
        }
        base.departures = mergedDepartures;

        // FUSION PROTECTRICE DES CIRCUITS TERMINAUX (Deep Merge sans perte)
        final mergedCircuits = <CircuitTerminalEquipement>[...base.effectiveTerminalCircuits];
        for (final ct in donor.effectiveTerminalCircuits) {
          final idx = mergedCircuits.indexWhere((c) {
            // 1. Même ID explicite non-vide
            if (c.id.isNotEmpty && ct.id.isNotEmpty && c.id == ct.id) {
              return true;
            }
            // 2. Clone strict en cas d'absence de concordance d'ID : même identification ET mêmes specs techniques clés
            final cNom = c.identification.trim().toLowerCase();
            final ctNom = ct.identification.trim().toLowerCase();
            if (cNom.isNotEmpty && cNom == ctNom) {
              final sameCalibre = c.calibre.trim() == ct.calibre.trim();
              final sameType = c.typeProtection.trim() == ct.typeProtection.trim();
              final sameCourbe = c.courbe.trim() == ct.courbe.trim();
              final sameDdr = c.ddr.trim() == ct.ddr.trim();
              return sameCalibre && sameType && sameCourbe && sameDdr;
            }
            return false;
          });
          if (idx == -1) {
            mergedCircuits.add(ct);
          } else {
            // Enrichir les champs vides du circuit existant avec le donneur
            final current = mergedCircuits[idx];
            if (current.typeProtection.isEmpty && ct.typeProtection.isNotEmpty) current.typeProtection = ct.typeProtection;
            if (current.calibre.isEmpty && ct.calibre.isNotEmpty) current.calibre = ct.calibre;
            if (current.courbe.isEmpty && ct.courbe.isNotEmpty) current.courbe = ct.courbe;
            if (current.ddr.isEmpty && ct.ddr.isNotEmpty) current.ddr = ct.ddr;
            if (current.pdcKA.isEmpty && ct.pdcKA.isNotEmpty) current.pdcKA = ct.pdcKA;
            if (current.sectionCable.isEmpty && ct.sectionCable.isNotEmpty) current.sectionCable = ct.sectionCable;
            if (current.sectionCableNeutre == null && ct.sectionCableNeutre != null) current.sectionCableNeutre = ct.sectionCableNeutre;
            if (current.conducteursPhase == null && ct.conducteursPhase != null) current.conducteursPhase = ct.conducteursPhase;
            if (current.conducteursNeutre == null && ct.conducteursNeutre != null) current.conducteursNeutre = ct.conducteursNeutre;
            if (current.natureCable == null && ct.natureCable != null) current.natureCable = ct.natureCable;
          }
        }
        base.terminalCircuits = mergedCircuits;

        // FUSION DES PHOTOS
        final photoSet = <String>{...base.photos, ...donor.photos};
        base.photos = photoSet.toList();
        if (base.photosExternes.isEmpty && donor.photosExternes.isNotEmpty) {
          base.photosExternes = List.from(donor.photosExternes);
        }
        if (base.photosInternes.isEmpty && donor.photosInternes.isNotEmpty) {
          base.photosInternes = List.from(donor.photosInternes);
        }

        // FUSION DES OBSERVATIONS LIBRES
        if (donor.observationsLibres.isNotEmpty) {
          final existingTexts = base.observationsLibres.map((o) => o.texte.trim().toLowerCase()).toSet();
          for (final obs in donor.observationsLibres) {
            if (!existingTexts.contains(obs.texte.trim().toLowerCase())) {
              base.observationsLibres.add(obs);
            }
          }
        }

        result[matchIdx] = base;
      }
    }
    
    return result;
  }

  /// Mettre à jour une zone par son ID avec préservation et fusion atomique des enfants
  static Future<bool> updateZoneById({
    required String missionId,
    required String zoneId,
    required dynamic updatedZone,
    required bool isMoyenneTension,
    int? fallbackIndex,
  }) async {
    return PersistenceQueue.enqueue('audit_$missionId', () async {
      try {
        final audit = await getOrCreateAuditInstallations(missionId);
        if (isMoyenneTension) {
          int targetIdx = audit.moyenneTensionZones.indexWhere(
            (z) =>
                (z.id != null && z.id == zoneId) ||
                z.zoneId == zoneId ||
                z.nom.trim() == (updatedZone as MoyenneTensionZone).nom.trim(),
          );
          if (targetIdx == -1 &&
              fallbackIndex != null &&
              fallbackIndex < audit.moyenneTensionZones.length) {
            targetIdx = fallbackIndex;
          }
          if (targetIdx == -1) return false;

          final target = audit.moyenneTensionZones[targetIdx];
          final mtZone = updatedZone as MoyenneTensionZone;
          mtZone.id = target.zoneId;

          // Fusion protectrice des locaux enfants
          if (target.locaux.isNotEmpty) {
            if (mtZone.locaux.isEmpty) {
              mtZone.locaux = target.locaux;
            } else {
              final incomingIds = {for (var l in mtZone.locaux) l.localId};
              for (var l in target.locaux) {
                if (!incomingIds.contains(l.localId)) {
                  mtZone.locaux.add(l);
                }
              }
            }
          }

          // Fusion protectrice des coffrets enfants sans duplication
          if (target.coffrets.isNotEmpty) {
            if (mtZone.coffrets.isEmpty) {
              mtZone.coffrets = target.coffrets;
            } else {
              mtZone.coffrets = deduplicateCoffrets([...mtZone.coffrets, ...target.coffrets]);
            }
          } else if (mtZone.coffrets.isNotEmpty) {
            mtZone.coffrets = deduplicateCoffrets(mtZone.coffrets);
          }

          audit.moyenneTensionZones[targetIdx] = mtZone;
        } else {
          int targetIdx = audit.basseTensionZones.indexWhere(
            (z) =>
                (z.id != null && z.id == zoneId) ||
                z.zoneId == zoneId ||
                z.nom.trim() == (updatedZone as BasseTensionZone).nom.trim(),
          );
          if (targetIdx == -1 &&
              fallbackIndex != null &&
              fallbackIndex < audit.basseTensionZones.length) {
            targetIdx = fallbackIndex;
          }
          if (targetIdx == -1) return false;

          final target = audit.basseTensionZones[targetIdx];
          final btZone = updatedZone as BasseTensionZone;
          btZone.id = target.zoneId;

          // Fusion protectrice des locaux enfants
          if (target.locaux.isNotEmpty) {
            if (btZone.locaux.isEmpty) {
              btZone.locaux = target.locaux;
            } else {
              final incomingIds = {for (var l in btZone.locaux) l.localId};
              for (var l in target.locaux) {
                if (!incomingIds.contains(l.localId)) {
                  btZone.locaux.add(l);
                }
              }
            }
          }

          // Fusion protectrice des coffrets directs sans duplication
          if (target.coffretsDirects.isNotEmpty) {
            if (btZone.coffretsDirects.isEmpty) {
              btZone.coffretsDirects = target.coffretsDirects;
            } else {
              btZone.coffretsDirects = deduplicateCoffrets([...btZone.coffretsDirects, ...target.coffretsDirects]);
            }
          } else if (btZone.coffretsDirects.isNotEmpty) {
            btZone.coffretsDirects = deduplicateCoffrets(btZone.coffretsDirects);
          }

          audit.basseTensionZones[targetIdx] = btZone;
        }

        await saveAuditInstallations(audit);
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur updateZoneById: $e');
        }
        return false;
      }
    });
  }

  /// Mettre à jour un local par son ID avec préservation et fusion atomique des enfants
  static Future<bool> updateLocalById({
    required String missionId,
    required String localId,
    required dynamic updatedLocal,
    required bool isMoyenneTension,
    bool isInZone = true,
    String? zoneId,
    int? fallbackZoneIndex,
    int? fallbackLocalIndex,
    bool skipDescriptionSync = false,
    bool preserveExistingCoffrets = true,
  }) async {
    return PersistenceQueue.enqueue('audit_$missionId', () async {
      try {
        final audit = await getOrCreateAuditInstallations(missionId);
        if (isMoyenneTension) {
          if (isInZone) {
            MoyenneTensionZone? targetZone;
            if (zoneId != null && zoneId.isNotEmpty) {
              targetZone = audit.moyenneTensionZones
                  .cast<MoyenneTensionZone?>()
                  .firstWhere(
                    (z) => z != null && (z.id == zoneId || z.zoneId == zoneId),
                    orElse: () => null,
                  );
            }
            if (targetZone == null &&
                fallbackZoneIndex != null &&
                fallbackZoneIndex < audit.moyenneTensionZones.length) {
              targetZone = audit.moyenneTensionZones[fallbackZoneIndex];
            }
            if (targetZone == null) return false;

            int targetIdx = targetZone.locaux.indexWhere(
              (l) =>
                  (l.id != null && l.id == localId) ||
                  l.localId == localId ||
                  l.nom.trim() ==
                      (updatedLocal as MoyenneTensionLocal).nom.trim(),
            );
            if (targetIdx == -1 &&
                fallbackLocalIndex != null &&
                fallbackLocalIndex < targetZone.locaux.length) {
              targetIdx = fallbackLocalIndex;
            }

            final mtLocal = updatedLocal as MoyenneTensionLocal;
            if (targetIdx != -1) {
              final existing = targetZone.locaux[targetIdx];
              mtLocal.id = existing.localId;

              // Gestion protectrice ou directe des coffrets
              if (preserveExistingCoffrets) {
                if (existing.coffrets.isNotEmpty) {
                  if (mtLocal.coffrets.isEmpty) {
                    mtLocal.coffrets = existing.coffrets;
                  } else {
                    mtLocal.coffrets = deduplicateCoffrets([...mtLocal.coffrets, ...existing.coffrets]);
                  }
                } else if (mtLocal.coffrets.isNotEmpty) {
                  mtLocal.coffrets = deduplicateCoffrets(mtLocal.coffrets);
                }
              } else {
                mtLocal.coffrets = deduplicateCoffrets(mtLocal.coffrets);
              }

              // Fusion protectrice des cellules
              if (existing.cellules.isNotEmpty && mtLocal.cellules.isEmpty) {
                mtLocal.cellules = existing.cellules;
              }
              // Fusion protectrice des transformateurs
              if (existing.transformateurs.isNotEmpty &&
                  mtLocal.transformateurs.isEmpty) {
                mtLocal.transformateurs = existing.transformateurs;
              }

              targetZone.locaux[targetIdx] = mtLocal;
            } else {
              targetZone.locaux.add(mtLocal);
            }
          } else {
            // Local MT indépendant
            int targetIdx = audit.moyenneTensionLocaux.indexWhere(
              (l) =>
                  (l.id != null && l.id == localId) ||
                  l.localId == localId ||
                  l.nom.trim() ==
                      (updatedLocal as MoyenneTensionLocal).nom.trim(),
            );
            if (targetIdx == -1 &&
                fallbackLocalIndex != null &&
                fallbackLocalIndex < audit.moyenneTensionLocaux.length) {
              targetIdx = fallbackLocalIndex;
            }

            final mtLocal = updatedLocal as MoyenneTensionLocal;
            if (targetIdx != -1) {
              final existing = audit.moyenneTensionLocaux[targetIdx];
              mtLocal.id = existing.localId;

              // Gestion protectrice ou directe des coffrets
              if (preserveExistingCoffrets) {
                if (existing.coffrets.isNotEmpty) {
                  if (mtLocal.coffrets.isEmpty) {
                    mtLocal.coffrets = existing.coffrets;
                  } else {
                    mtLocal.coffrets = deduplicateCoffrets([...mtLocal.coffrets, ...existing.coffrets]);
                  }
                } else if (mtLocal.coffrets.isNotEmpty) {
                  mtLocal.coffrets = deduplicateCoffrets(mtLocal.coffrets);
                }
              } else {
                mtLocal.coffrets = deduplicateCoffrets(mtLocal.coffrets);
              }
              if (existing.cellules.isNotEmpty && mtLocal.cellules.isEmpty) {
                mtLocal.cellules = existing.cellules;
              }
              if (existing.transformateurs.isNotEmpty &&
                  mtLocal.transformateurs.isEmpty) {
                mtLocal.transformateurs = existing.transformateurs;
              }

              audit.moyenneTensionLocaux[targetIdx] = mtLocal;
            } else {
              audit.moyenneTensionLocaux.add(mtLocal);
            }
          }
        } else {
          // Basse Tension
          BasseTensionZone? targetZone;
          if (zoneId != null && zoneId.isNotEmpty) {
            targetZone = audit.basseTensionZones
                .cast<BasseTensionZone?>()
                .firstWhere(
                  (z) => z != null && (z.id == zoneId || z.zoneId == zoneId),
                  orElse: () => null,
                );
          }
          if (targetZone == null &&
              fallbackZoneIndex != null &&
              fallbackZoneIndex < audit.basseTensionZones.length) {
            targetZone = audit.basseTensionZones[fallbackZoneIndex];
          }
          if (targetZone == null) return false;

          int targetIdx = targetZone.locaux.indexWhere(
            (l) =>
                (l.id != null && l.id == localId) ||
                l.localId == localId ||
                l.nom.trim() == (updatedLocal as BasseTensionLocal).nom.trim(),
          );
          if (targetIdx == -1 &&
              fallbackLocalIndex != null &&
              fallbackLocalIndex < targetZone.locaux.length) {
            targetIdx = fallbackLocalIndex;
          }

          final btLocal = updatedLocal as BasseTensionLocal;
          if (targetIdx != -1) {
            final existing = targetZone.locaux[targetIdx];
            btLocal.id = existing.localId;

            // Gestion protectrice ou directe des coffrets
            if (preserveExistingCoffrets) {
              if (existing.coffrets.isNotEmpty) {
                if (btLocal.coffrets.isEmpty) {
                  btLocal.coffrets = existing.coffrets;
                } else {
                  btLocal.coffrets = deduplicateCoffrets([...btLocal.coffrets, ...existing.coffrets]);
                }
              } else if (btLocal.coffrets.isNotEmpty) {
                btLocal.coffrets = deduplicateCoffrets(btLocal.coffrets);
              }
            } else {
              btLocal.coffrets = deduplicateCoffrets(btLocal.coffrets);
            }

            if (existing.cellules.isNotEmpty && btLocal.cellules.isEmpty) {
              btLocal.cellules = existing.cellules;
            }
            if (existing.transformateurs.isNotEmpty &&
                btLocal.transformateurs.isEmpty) {
              btLocal.transformateurs = existing.transformateurs;
            }

            targetZone.locaux[targetIdx] = btLocal;
          } else {
            targetZone.locaux.add(btLocal);
          }
        }

        await saveAuditInstallations(audit, skipDescriptionSync: skipDescriptionSync);
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur updateLocalById: $e');
        }
        return false;
      }
    });
  }

  /// Supprimer un local d'une zone (MT ou BT) par ID ou index
  static Future<bool> deleteLocalFromZone({
    required String missionId,
    required bool isMoyenneTension,
    String? zoneId,
    int? zoneIndex,
    String? localId,
    int? localIndex,
  }) async {
    return PersistenceQueue.enqueue('audit_$missionId', () async {
      try {
        final audit = await getOrCreateAuditInstallations(missionId);
        if (isMoyenneTension) {
          MoyenneTensionZone? targetZone;
          if (zoneId != null && zoneId.isNotEmpty) {
            targetZone = audit.moyenneTensionZones
                .cast<MoyenneTensionZone?>()
                .firstWhere(
                  (z) => z != null && (z.id == zoneId || z.zoneId == zoneId),
                  orElse: () => null,
                );
          }
          if (targetZone == null &&
              zoneIndex != null &&
              zoneIndex < audit.moyenneTensionZones.length) {
            targetZone = audit.moyenneTensionZones[zoneIndex];
          }
          if (targetZone == null) return false;

          int idx = -1;
          if (localId != null && localId.isNotEmpty) {
            idx = targetZone.locaux.indexWhere(
              (l) => l.id == localId || l.localId == localId,
            );
          }
          if (idx == -1 &&
              localIndex != null &&
              localIndex < targetZone.locaux.length) {
            idx = localIndex;
          }
          if (idx != -1) {
            targetZone.locaux.removeAt(idx);
            await saveAuditInstallations(audit);
            return true;
          }
        } else {
          BasseTensionZone? targetZone;
          if (zoneId != null && zoneId.isNotEmpty) {
            targetZone = audit.basseTensionZones
                .cast<BasseTensionZone?>()
                .firstWhere(
                  (z) => z != null && (z.id == zoneId || z.zoneId == zoneId),
                  orElse: () => null,
                );
          }
          if (targetZone == null &&
              zoneIndex != null &&
              zoneIndex < audit.basseTensionZones.length) {
            targetZone = audit.basseTensionZones[zoneIndex];
          }
          if (targetZone == null) return false;

          int idx = -1;
          if (localId != null && localId.isNotEmpty) {
            idx = targetZone.locaux.indexWhere(
              (l) => l.id == localId || l.localId == localId,
            );
          }
          if (idx == -1 &&
              localIndex != null &&
              localIndex < targetZone.locaux.length) {
            idx = localIndex;
          }
          if (idx != -1) {
            targetZone.locaux.removeAt(idx);
            await saveAuditInstallations(audit);
            return true;
          }
        }
        return false;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur deleteLocalFromZone: $e');
        }
        return false;
      }
    });
  }

  /// Supprimer un local basse tension d'une zone
  static Future<bool> deleteLocalFromBasseTensionZone({
    required String missionId,
    required int zoneIndex,
    required int localIndex,
    String? zoneId,
    String? localId,
  }) async {
    return await deleteLocalFromZone(
      missionId: missionId,
      isMoyenneTension: false,
      zoneId: zoneId,
      zoneIndex: zoneIndex,
      localId: localId,
      localIndex: localIndex,
    );
  }

  /// Supprimer un local moyenne tension indépendant
  static Future<bool> deleteMoyenneTensionLocal({
    required String missionId,
    required int localIndex,
    String? localId,
  }) async {
    return PersistenceQueue.enqueue('audit_$missionId', () async {
      try {
        final audit = await getOrCreateAuditInstallations(missionId);
        int idx = -1;
        if (localId != null && localId.isNotEmpty) {
          idx = audit.moyenneTensionLocaux.indexWhere(
            (l) => l.id == localId || l.localId == localId,
          );
        }
        if (idx == -1 && localIndex < audit.moyenneTensionLocaux.length) {
          idx = localIndex;
        }
        if (idx != -1) {
          audit.moyenneTensionLocaux.removeAt(idx);
          await saveAuditInstallations(audit);
          return true;
        }
        return false;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur deleteMoyenneTensionLocal: $e');
        }
        return false;
      }
    });
  }

  /// Mettre à jour un local moyenne tension
  static Future<bool> updateMoyenneTensionLocal({
    required String missionId,
    required int localIndex,
    required MoyenneTensionLocal local,
    String? localId,
  }) async {
    return await updateLocalById(
      missionId: missionId,
      localId: localId ?? local.localId,
      updatedLocal: local,
      isMoyenneTension: true,
      isInZone: false,
      fallbackLocalIndex: localIndex,
    );
  }

  /// Mettre à jour une zone moyenne tension
  static Future<bool> updateMoyenneTensionZone({
    required String missionId,
    required int zoneIndex,
    required MoyenneTensionZone zone,
    String? zoneId,
  }) async {
    return await updateZoneById(
      missionId: missionId,
      zoneId: zoneId ?? zone.zoneId,
      updatedZone: zone,
      isMoyenneTension: true,
      fallbackIndex: zoneIndex,
    );
  }

  /// Mettre à jour une zone basse tension
  static Future<bool> updateBasseTensionZone({
    required String missionId,
    required int zoneIndex,
    required BasseTensionZone zone,
    String? zoneId,
  }) async {
    return await updateZoneById(
      missionId: missionId,
      zoneId: zoneId ?? zone.zoneId,
      updatedZone: zone,
      isMoyenneTension: false,
      fallbackIndex: zoneIndex,
    );
  }

  /// Mettre à jour un local basse tension
  static Future<bool> updateBasseTensionLocal({
    required String missionId,
    required int zoneIndex,
    required int localIndex,
    required BasseTensionLocal local,
    String? zoneId,
    String? localId,
  }) async {
    return await updateLocalById(
      missionId: missionId,
      localId: localId ?? local.localId,
      updatedLocal: local,
      isMoyenneTension: false,
      isInZone: true,
      zoneId: zoneId,
      fallbackZoneIndex: zoneIndex,
      fallbackLocalIndex: localIndex,
    );
  }

// ============================================================
//          GESTION LOCAUX DANS LES ZONES MOYENNE TENSION
// ============================================================

  /// Ajouter un local dans une zone moyenne tension
  static Future<bool> addLocalToMoyenneTensionZone({
    required String missionId,
    required int zoneIndex,
    required MoyenneTensionLocal local,
  }) async {
    return PersistenceQueue.enqueue('audit_$missionId', () async {
      try {
        final audit = await getOrCreateAuditInstallations(missionId);

        if (zoneIndex < audit.moyenneTensionZones.length) {
          final zone = audit.moyenneTensionZones[zoneIndex];

          if (zone.locaux.isEmpty) {
            zone.locaux = [];
          }

          zone.locaux.add(local);
          await saveAuditInstallations(audit);
          if (kDebugMode) {
            print('✅ Local moyenne tension ajouté dans zone: ${local.nom}');
          }
          return true;
        }
        return false;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur addLocalToMoyenneTensionZone: $e');
        }
        return false;
      }
    });
  }

  /// Mettre à jour un local dans une zone moyenne tension
  static Future<bool> updateLocalInMoyenneTensionZone({
    required String missionId,
    required int zoneIndex,
    required int localIndex,
    required MoyenneTensionLocal local,
    String? zoneId,
    String? localId,
  }) async {
    return await updateLocalById(
      missionId: missionId,
      localId: localId ?? local.localId,
      updatedLocal: local,
      isMoyenneTension: true,
      isInZone: true,
      zoneId: zoneId,
      fallbackZoneIndex: zoneIndex,
      fallbackLocalIndex: localIndex,
    );
  }

  /// Supprimer un local d'une zone moyenne tension
  static Future<bool> deleteLocalFromMoyenneTensionZone({
    required String missionId,
    required int zoneIndex,
    required int localIndex,
    String? zoneId,
    String? localId,
  }) async {
    return await deleteLocalFromZone(
      missionId: missionId,
      isMoyenneTension: true,
      zoneId: zoneId,
      zoneIndex: zoneIndex,
      localId: localId,
      localIndex: localIndex,
    );
  }

// Récupérer les locaux d'une zone moyenne tension
static List<MoyenneTensionLocal> getLocauxInMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
}) {
  try {
    final audit = getAuditInstallationsByMissionId(missionId);
    if (audit == null || zoneIndex >= audit.moyenneTensionZones.length) {
      return [];
    }
    return audit.moyenneTensionZones[zoneIndex].locaux;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getLocauxInMoyenneTensionZone: $e');
    }
    return [];
  }
}

// ============================================================
//          GESTION CLASSEMENT DES LOCAUX (COMPLET)
// ============================================================

/// Synchroniser automatiquement les emplacements depuis l'audit
/// MODIFICATION : Ne synchroniser que les LOCAUX, pas les zones
static Future<List<ClassementEmplacement>> syncEmplacementsFromAudit(String missionId) async {
  final classementBox = Hive.box<ClassementEmplacement>(_classementBox);
  final auditBox = Hive.box<AuditInstallationsElectriques>(_auditBox);
  
  try {
    // Récupérer l'audit de la mission
    final audit = auditBox.values.firstWhere((audit) => audit.missionId == missionId);
    
    final List<ClassementEmplacement> emplacements = [];
    final List<String> emplacementNoms = []; // Pour éviter les doublons
    
    // ===========================================
    // 1. SEULEMENT LES LOCAUX MOYENNE TENSION
    // ===========================================
    for (var local in audit.moyenneTensionLocaux) {
      if (emplacementNoms.contains(local.nom)) continue;
      
      final existant = classementBox.values.firstWhere(
        (e) => e.missionId == missionId && e.localisation == local.nom,
        orElse: () => ClassementEmplacement.create(
          missionId: missionId,
          localisation: local.nom,
          zone: null, // Ces locaux ne sont PAS dans une zone
          typeLocal: local.type,
        ),
      );
      
      if (existant.key == null) {
        await classementBox.add(existant);
      }
      
      emplacements.add(existant);
      emplacementNoms.add(local.nom);
    }
    
    // ===========================================
    // 2. IGNORER LES ZONES MOYENNE TENSION 
    // (Ce ne sont pas des locaux, ce sont des zones)
    // ===========================================
    // NE PAS AJOUTER LES ZONES MOYENNE TENSION
    // for (var zone in audit.moyenneTensionZones) {
    //   if (emplacementNoms.contains(zone.nom)) continue;
    //   // ... code supprimé ...
    // }
    
    // ===========================================
    // 3. IGNORER LES ZONES BASSE TENSION 
    // (Ce ne sont pas des locaux, ce sont des zones)
    // ===========================================
    // NE PAS AJOUTER LES ZONES BASSE TENSION
    // for (var zone in audit.basseTensionZones) {
    //   if (emplacementNoms.contains(zone.nom)) continue;
    //   // ... code supprimé ...
    // }
    
    // ===========================================
    // 4. SEULEMENT LES LOCAUX DANS LES ZONES BASSE TENSION
    // ===========================================
    for (var zone in audit.basseTensionZones) {
      // Ajouter les locaux dans la zone
      for (var local in zone.locaux) {
        // IMPORTANT: Ici, on utilise local.nom comme nom, pas "zone.nom - local.nom"
        if (emplacementNoms.contains(local.nom)) continue;
        
        final existantLocal = classementBox.values.firstWhere(
          (e) => e.missionId == missionId && e.localisation == local.nom,
          orElse: () => ClassementEmplacement.create(
            missionId: missionId,
            localisation: local.nom, // Juste le nom du local
            zone: zone.nom, // On garde la référence à la zone
            typeLocal: local.type,
          ),
        );
        
        if (existantLocal.key == null) {
          await classementBox.add(existantLocal);
        }
        
        emplacements.add(existantLocal);
        emplacementNoms.add(local.nom);
      }
    }
    
    // ===========================================
    // 5. LOCAUX DANS LES ZONES MOYENNE TENSION (si existent)
    // ===========================================
    for (var zone in audit.moyenneTensionZones) {
      // Ajouter les locaux dans la zone MT
      for (var local in zone.locaux) {
        if (emplacementNoms.contains(local.nom)) continue;
        
        final existantLocal = classementBox.values.firstWhere(
          (e) => e.missionId == missionId && e.localisation == local.nom,
          orElse: () => ClassementEmplacement.create(
            missionId: missionId,
            localisation: local.nom,
            zone: zone.nom, // On garde la référence à la zone
            typeLocal: local.type,
          ),
        );
        
        if (existantLocal.key == null) {
          await classementBox.add(existantLocal);
        }
        
        emplacements.add(existantLocal);
        emplacementNoms.add(local.nom);
      }
    }
    
    // ===========================================
    // 6. Mettre à jour la référence dans la mission
    // ===========================================
    await _updateMissionClassementReference(missionId, emplacements);
    
    if (kDebugMode) {
      print('✅ ${emplacements.length} LOCAUX (seulement) synchronisés pour mission $missionId');
    }
    return emplacements;
    
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur syncEmplacementsFromAudit: $e');
    }
    return [];
  }
}
/// Mettre à jour la référence de classement dans la mission
static Future<void> _updateMissionClassementReference(String missionId, List<ClassementEmplacement> emplacements) async {
  final missionBox = Hive.box<Mission>(_missionBox);
  final mission = missionBox.get(missionId);
  
  if (mission != null) {
    if (emplacements.isNotEmpty) {
      // Créer un ID de référence unique pour cette mission
      mission.classementLocauxId = 'classement_$missionId';
    } else {
      mission.classementLocauxId = null;
    }
    await mission.save();
    if (kDebugMode) {
      print('✅ Référence classement mise à jour pour mission $missionId');
    }
  }
}

/// Récupérer tous les emplacements d'une mission
static List<ClassementEmplacement> getEmplacementsByMissionId(String missionId) {
  final box = Hive.box<ClassementEmplacement>(_classementBox);
  try {
    return box.values.where((e) => e.missionId == missionId).toList();
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getEmplacementsByMissionId: $e');
    }
    return [];
  }
}

/// Normalisation robuste d'une chaîne pour la comparaison d'emplacements (casse, espaces, accents)
static String _normalizeLocationKey(String text) {
  return text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ùûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Récupérer un emplacement (Local ou Zone) par son nom
static ClassementEmplacement? getEmplacementByNom(String missionId, String localisation) {
  try {
    if (!Hive.isBoxOpen(_classementBox)) return null;
    final box = Hive.box<ClassementEmplacement>(_classementBox);
    final targetRaw = localisation.trim();
    if (targetRaw.isEmpty) return null;

    // 1. Recherche par égalité exacte
    for (var e in box.values) {
      if (e.missionId == missionId && e.localisation == targetRaw) {
        return e;
      }
    }

    // 2. Recherche insensible à la casse et aux espaces aux extrémités
    final targetLower = targetRaw.toLowerCase();
    for (var e in box.values) {
      if (e.missionId == missionId && e.localisation.trim().toLowerCase() == targetLower) {
        return e;
      }
    }

    // 3. Recherche normalisée (sans accents et caractères spéciaux)
    final normTarget = _normalizeLocationKey(targetRaw);
    for (var e in box.values) {
      if (e.missionId == missionId && _normalizeLocationKey(e.localisation) == normTarget) {
        return e;
      }
    }

    return null;
  } catch (e) {
    return null;
  }
}

/// Mettre à jour un emplacement
static Future<bool> updateEmplacement(ClassementEmplacement emplacement) async {
  try {
    final box = Hive.box<ClassementEmplacement>(_classementBox);
    
    emplacement.calculerIndices();
    emplacement.updatedAt = DateTime.now();
    
    if (emplacement.key != null) {
      await box.put(emplacement.key, emplacement);
    } else {
      await box.add(emplacement);
    }
    
    if (kDebugMode) {
      print('✅ Emplacement sauvegardé: ${emplacement.localisation} (${emplacement.typeEmplacement})');
      print('   AF: ${emplacement.af}, BE: ${emplacement.be}, AE: ${emplacement.ae}');
      print('   AD: ${emplacement.ad}, AG: ${emplacement.ag}');
    }
    
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur updateEmplacement: $e');
    }
    return false;
  }
}

/// Supprimer un emplacement
static Future<bool> deleteEmplacement(ClassementEmplacement emplacement) async {
  try {
    await emplacement.delete();
    if (kDebugMode) {
      print('✅ Emplacement supprimé: ${emplacement.localisation}');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteEmplacement: $e');
    }
    return false;
  }
}

/// Supprimer tous les emplacements d'une mission
static Future<bool> clearEmplacementsForMission(String missionId) async {
  try {
    final box = Hive.box<ClassementEmplacement>(_classementBox);
    final emplacements = box.values.where((e) => e.missionId == missionId).toList();
    
    for (var emplacement in emplacements) {
      await emplacement.delete();
    }
    
    // Supprimer la référence dans la mission
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.classementLocauxId = null;
      await mission.save();
    }
    
    if (kDebugMode) {
      print('✅ ${emplacements.length} emplacements supprimés pour mission $missionId');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur clearEmplacementsForMission: $e');
    }
    return false;
  }
}

/// Vérifier si un emplacement existe
static bool emplacementExists(String missionId, String localisation) {
  return getEmplacementByNom(missionId, localisation) != null;
}

/// Obtenir les statistiques des emplacements
static Map<String, dynamic> getEmplacementsStats(String missionId) {
  final emplacements = getEmplacementsByMissionId(missionId);
  
  final complet = emplacements.where((e) => 
    e.af != null && e.be != null && e.ae != null && e.ad != null && e.ag != null
  ).length;
  
  final incomplet = emplacements.length - complet;
  
  return {
    'total': emplacements.length,
    'complet': complet,
    'incomplet': incomplet,
    'pourcentage_complet': emplacements.isNotEmpty ? (complet / emplacements.length * 100).round() : 0,
  };
}

// Récupérer un classement par ID (supporte les clés String et int)
static ClassementEmplacement? getClassementById(String id) {
  final box = Hive.box<ClassementEmplacement>(_classementBox);
  final direct = box.get(id);
  if (direct != null) return direct;
  final intKey = int.tryParse(id);
  if (intKey != null) {
    return box.get(intKey);
  }
  return null;
}

/// Synchroniser automatiquement les ZONES depuis l'audit
static Future<List<ClassementEmplacement>> syncZonesFromAudit(String missionId) async {
  final classementBox = Hive.box<ClassementEmplacement>(_classementBox);
  final auditBox = Hive.box<AuditInstallationsElectriques>(_auditBox);
  
  try {
    final audit = auditBox.values.firstWhere((audit) => audit.missionId == missionId);
    final List<ClassementEmplacement> zones = [];
    
    // ===== ZONES MOYENNE TENSION =====
    for (var zone in audit.moyenneTensionZones) {
      ClassementEmplacement? classement;
      
      // D'abord essayer de récupérer via l'ID sauvegardé
      if (zone.classementZoneId != null) {
        classement = classementBox.get(zone.classementZoneId);
      }
      
      // Si pas trouvé, chercher par nom
      if (classement == null) {
        try {
          classement = classementBox.values.firstWhere(
            (e) => e.missionId == missionId && 
                   e.localisation == zone.nom && 
                   e.typeEmplacement == 'zone',
          );
        } catch (e) {
          classement = null;
        }
      }
      
      // Si toujours pas trouvé, créer
      if (classement == null) {
        classement = ClassementEmplacement.createZone(
          missionId: missionId,
          nomZone: zone.nom,
        );
        await classementBox.add(classement);
        zone.classementZoneId = classement.key.toString();
        await saveAuditInstallations(audit);
        if (kDebugMode) {
          print('✅ Nouveau classement zone MT créé: ${zone.nom}');
        }
      }
      
      zones.add(classement);
    }
    
    // ===== ZONES BASSE TENSION =====
    for (var zone in audit.basseTensionZones) {
      ClassementEmplacement? classement;
      
      if (zone.classementZoneId != null) {
        classement = classementBox.get(zone.classementZoneId);
      }
      
      if (classement == null) {
        try {
          classement = classementBox.values.firstWhere(
            (e) => e.missionId == missionId && 
                   e.localisation == zone.nom && 
                   e.typeEmplacement == 'zone',
          );
        } catch (e) {
          classement = null;
        }
      }
      
      if (classement == null) {
        classement = ClassementEmplacement.createZone(
          missionId: missionId,
          nomZone: zone.nom,
        );
        await classementBox.add(classement);
        zone.classementZoneId = classement.key.toString();
        await saveAuditInstallations(audit);
        if (kDebugMode) {
          print('✅ Nouveau classement zone BT créé: ${zone.nom}');
        }
      }
      
      zones.add(classement);
    }
    
    if (kDebugMode) {
      print('✅ ${zones.length} ZONES synchronisées pour mission $missionId');
    }
    return zones;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur syncZonesFromAudit: $e');
    }
    return [];
  }
}

static Future<void> ensureZonesHaveClassement(String missionId) async {
  final audit = getAuditInstallationsByMissionId(missionId);
  if (audit == null) return;
  
  final classementBox = Hive.box<ClassementEmplacement>(_classementBox);
  
  // Vérifier les zones MT
  for (var zone in audit.moyenneTensionZones) {
    final exists = classementBox.values.any(
      (c) => c.missionId == missionId && 
             c.localisation == zone.nom && 
             c.typeEmplacement == 'zone'
    );
    
    if (!exists) {
      final newClassement = ClassementEmplacement.createZone(
        missionId: missionId,
        nomZone: zone.nom,
      );
      await classementBox.add(newClassement);
      if (kDebugMode) {
        print('✅ Classement manquant créé pour zone MT: ${zone.nom}');
      }
    }
  }
  
  // Vérifier les zones BT
  for (var zone in audit.basseTensionZones) {
    final exists = classementBox.values.any(
      (c) => c.missionId == missionId && 
             c.localisation == zone.nom && 
             c.typeEmplacement == 'zone'
    );
    
    if (!exists) {
      final newClassement = ClassementEmplacement.createZone(
        missionId: missionId,
        nomZone: zone.nom,
      );
      await classementBox.add(newClassement);
      if (kDebugMode) {
        print('✅ Classement manquant créé pour zone BT: ${zone.nom}');
      }
    }
  }
}


/// Synchroniser TOUT (zones + locaux) depuis l'audit
static Future<List<ClassementEmplacement>> syncAllEmplacementsFromAudit(String missionId) async {
  final zones = await syncZonesFromAudit(missionId);
  final locaux = await syncEmplacementsFromAudit(missionId);
  
  // Pour chaque local, vérifier s'il a une zone parente et proposer l'héritage
  for (var local in locaux) {
    if (local.zone != null) {
      // Chercher la zone correspondante
      final zoneParente = zones.firstWhere(
        (z) => z.localisation == local.zone,
        orElse: () => null as ClassementEmplacement,
      );
      
      if (zoneParente != null && local.af == null) {
        // Si le local n'a pas encore de classement, on peut proposer l'héritage
        // (sera fait au moment de l'édition)
      }
    }
  }
  
  return [...zones, ...locaux];
}

/// Récupérer les zones uniquement
static List<ClassementEmplacement> getZonesByMissionId(String missionId) {
  final box = Hive.box<ClassementEmplacement>(_classementBox);
  try {
    return box.values
        .where((e) => e.missionId == missionId && e.typeEmplacement == 'zone')
        .toList();
  } catch (e) {
    return [];
  }
}

/// Récupérer les locaux uniquement
static List<ClassementEmplacement> getLocauxByMissionId(String missionId) {
  final box = Hive.box<ClassementEmplacement>(_classementBox);
  try {
    return box.values
        .where((e) => e.missionId == missionId && e.typeEmplacement == 'local')
        .toList();
  } catch (e) {
    return [];
  }
}

/// Appliquer l'héritage d'une zone à un local
static Future<void> appliquerHeritageZone({
  required String missionId,
  required String localId,
  required String zoneId,
}) async {
  final local = getClassementById(localId);
  final zone = getClassementById(zoneId);
  
  if (local != null && zone != null) {
    local.heriteDeZone = true;
    local.zoneParenteId = zoneId;
    // On ne copie pas les valeurs, on utilise les getters effective
    local.updatedAt = DateTime.now();
    await local.save();
  }
}

/// Retirer l'héritage et passer en classement spécifique
static Future<void> passerEnClassementSpecifique({
  required String localId,
}) async {
  final local = getClassementById(localId);
  if (local != null) {
    // Copier les valeurs effectives actuelles
    local.af = local.afEffective;
    local.be = local.beEffective;
    local.ae = local.aeEffective;
    local.ad = local.adEffective;
    local.ag = local.agEffective;
    local.ip = local.ipEffective;
    local.ik = local.ikEffective;
    
    local.heriteDeZone = false;
    local.zoneParenteId = null;
    local.updatedAt = DateTime.now();
    await local.save();
  }
}

// Créer ou récupérer le classement pour une zone
static Future<ClassementEmplacement> getOrCreateClassementForZone({
  required String missionId,
  required String nomZone,
}) async {
  final classementBox = Hive.box<ClassementEmplacement>(_classementBox);
  
  try {
    // Chercher un classement existant pour cette zone
    for (var classement in classementBox.values) {
      if (classement.missionId == missionId && 
          classement.localisation == nomZone &&
          classement.typeEmplacement == 'zone') {
        return classement;
      }
    }
    
    // Créer un nouveau classement
    final newClassement = ClassementEmplacement.createZone(
      missionId: missionId,
      nomZone: nomZone,
    );
    await classementBox.add(newClassement);
    if (kDebugMode) {
      print('✅ Classement zone créé: $nomZone');
    }
    return newClassement;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getOrCreateClassementForZone: $e');
    }
    final newClassement = ClassementEmplacement.createZone(
      missionId: missionId,
      nomZone: nomZone,
    );
    await classementBox.add(newClassement);
    return newClassement;
  }
}

/// Sauvegarder un classement
static Future<void> saveClassement(ClassementEmplacement classement) async {
  classement.updatedAt = DateTime.now();
  classement.calculerIndices();
  await classement.save();
}

// ============================================================
//          OPTIONS ET DESCRIPTIONS (COMPLET)
// ============================================================

/// Obtenir les options pour chaque type d'influence
// Codes stockés en base (inchangés — rétrocompatibilité PDF)
static List<String> getOptionsAF() => ['AF1', 'AF2', 'AF3', 'AF4'];
static List<String> getOptionsBE() => ['BE1', 'BE2', 'BE3', 'BE4'];
static List<String> getOptionsAE() => ['AE1', 'AE2', 'AE3', 'AE4'];
static List<String> getOptionsAD() => ['AD1', 'AD2', 'AD3', 'AD4', 'AD5', 'AD6', 'AD7', 'AD8', 'AD9'];
static List<String> getOptionsAG() => ['AG1', 'AG2', 'AG3', 'AG4'];

// Labels complets pour l'affichage dans les dropdowns (value = code, child = label)
static const Map<String, String> labelsAF = {
  'AF1': 'AF1 : Négligeable',
  'AF2': 'AF2 : Agents d\'origine atmosphérique',
  'AF3': 'AF3 : Intermittente ou accidentelle',
  'AF4': 'AF4 : Permanente',
};
static const Map<String, String> labelsBE = {
  'BE1': 'BE1 : Risques négligeables',
  'BE2': 'BE2 : Risques d\'incendie',
  'BE3': 'BE3 : Risques d\'explosion',
  'BE4': 'BE4 : Risques de contamination',
};
static const Map<String, String> labelsAE = {
  'AE1': 'AE1 : Négligeable',
  'AE2': 'AE2 : Petits objets (≥ 2,5 mm)',
  'AE3': 'AE3 : Très petits objets',
  'AE4': 'AE4 : Poussières',
};
static const Map<String, String> labelsAD = {
  'AD1': 'AD1 : Négligeable',
  'AD2': 'AD2 : Chutes de gouttes d\'eau',
  'AD3': 'AD3 : Chutes de gouttes d\'eau jusqu\'à 15°',
  'AD4': 'AD4 : Aspersion d\'eau',
  'AD5': 'AD5 : Projections d\'eau',
  'AD6': 'AD6 : Jets d\'eau',
  'AD7': 'AD7 : Paquets d\'eau',
  'AD8': 'AD8 : Immersion',
  'AD9': 'AD9 : Submersion',
};
static const Map<String, String> labelsAG = {
  'AG1': 'AG1 : Faibles (0,225 J)',
  'AG2': 'AG2 : Moyens (2 J)',
  'AG3': 'AG3 : Importants (5 J)',
  'AG4': 'AG4 : Très importants (20 J)',
};

/// Retourne le label complet pour un code donné (ex: 'AF1' → 'AF1 : Négligeable')
static String getLabelForCode(String code) {
  return labelsAF[code] ?? labelsBE[code] ?? labelsAE[code] ??
         labelsAD[code] ?? labelsAG[code] ?? code;
}

/// Obtenir toutes les options groupées
static Map<String, List<String>> getAllOptions() {
  return {
    'AF': getOptionsAF(),
    'BE': getOptionsBE(),
    'AE': getOptionsAE(),
    'AD': getOptionsAD(),
    'AG': getOptionsAG(),
  };
}

/// Récupérer la description d'une option
static String getDescriptionAF(String code) {
  final descriptions = {
    'AF1': 'Négligeable',
    'AF2': 'Agents d\'origine atmosphérique',
    'AF3': 'Intermittente ou accidentelle',
    'AF4': 'Permanente',
  };
  return descriptions[code] ?? code;
}

static String getDescriptionBE(String code) {
  final descriptions = {
    'BE1': 'Risques négligeables',
    'BE2': 'Risques d\'incendie',
    'BE3': 'Risques d\'explosion',
    'BE4': 'Risques de contamination',
  };
  return descriptions[code] ?? code;
}

static String getDescriptionAE(String code) {
  final descriptions = {
    'AE1': 'Négligeable → IP 2X',
    'AE2': 'Petits objets (≥ 2,5 mm) → IP 3X',
    'AE3': 'Très petits objets (1 à 2,5 mm) → IP 4X',
    'AE4': 'Poussières → IP 5X (Protégé)',
  };
  return descriptions[code] ?? code;
}

static String getDescriptionAD(String code) {
  final descriptions = {
    'AD1': 'Négligeable → IP X0',
    'AD2': 'Chutes de gouttes d\'eau → IP X1',
    'AD3': 'Chutes de gouttes d\'eau jusqu\'à 15° → IP X2',
    'AD4': 'Aspersion d\'eau → IP X3',
    'AD5': 'Projections d\'eau → IP X4',
    'AD6': 'Jets d\'eau → IP X5',
    'AD7': 'Paquets d\'eau → IP X6',
    'AD8': 'Immersion → IP X7',
    'AD9': 'Submersion → IP X8',
  };
  return descriptions[code] ?? code;
}

static String getDescriptionAG(String code) {
  final descriptions = {
    'AG1': 'Faibles (0,225 J) → IK 02',
    'AG2': 'Moyens (2 J) → IK 07',
    'AG3': 'Importants (5 J) → IK 08',
    'AG4': 'Très importants (20 J) → IK 10',
  };
  return descriptions[code] ?? code;
}

/// Obtenir la description pour n'importe quel code
static String getDescriptionForCode(String code) {
  if (code.startsWith('AF')) return getDescriptionAF(code);
  if (code.startsWith('BE')) return getDescriptionBE(code);
  if (code.startsWith('AE')) return getDescriptionAE(code);
  if (code.startsWith('AD')) return getDescriptionAD(code);
  if (code.startsWith('AG')) return getDescriptionAG(code);
  return code;
}

// ============================================================
//          CALCUL DES INDICES (COMPLET)
// ============================================================

/// Calculer l'indice IP à partir de AE et AD
static String? calculateIP(String? ae, String? ad) {
  if (ae == null || ad == null) return null;
  
  final aeNum = _extractAENumber(ae);
  final adNum = _extractADNumber(ad);
  
  if (aeNum == null || adNum == null) return null;
  
  return 'IP$aeNum$adNum';
}

/// Calculer l'indice IK à partir de AG
static String? calculateIK(String? ag) {
  if (ag == null) return null;
  
  switch (ag) {
    case 'AG1': return 'IK02';
    case 'AG2': return 'IK07';
    case 'AG3': return 'IK08';
    case 'AG4': return 'IK10';
    default: return null;
  }
}

/// Extraire le numéro pour AE
static int? _extractAENumber(String ae) {
  switch (ae) {
    case 'AE1': return 2;
    case 'AE2': return 3;
    case 'AE3': return 4;
    case 'AE4': return 5; // ou 6 selon spécification
    default: return null;
  }
}

/// Extraire le numéro pour AD
static int? _extractADNumber(String ad) {
  switch (ad) {
    case 'AD1': return 0;
    case 'AD2': return 1;
    case 'AD3': return 2;
    case 'AD4': return 3;
    case 'AD5': return 4;
    case 'AD6': return 5;
    case 'AD7': return 6;
    case 'AD8': return 7;
    case 'AD9': return 8;
    default: return null;
  }
}

// ============================================================
//          UTILITAIRES (COMPLET)
// ============================================================

/// Vérifier si un emplacement est complet
static bool isEmplacementComplet(ClassementEmplacement emplacement) {
  return emplacement.af != null && 
         emplacement.be != null && 
         emplacement.ae != null && 
         emplacement.ad != null && 
         emplacement.ag != null;
}

/// Obtenir le pourcentage de complétion
// static int getCompletionPercentage(ClassementEmplacement emplacement) {
//   int filled = 0;
//   if (emplacement.af != null) filled++;
//   if (emplacement.be != null) filled++;
//   if (emplacement.ae != null) filled++;
//   if (emplacement.ad != null) filled++;
//   if (emplacement.ag != null) filled++;
//   
//   return (filled / 5 * 100).round();
// }

/// Obtenir le type d'icône pour un emplacement
static Future<IconData> getIconForEmplacement(ClassementEmplacement emplacement) async {
  if (isEmplacementComplet(emplacement)) {
    return Icons.check_circle_outline;
  } else if (await getCompletionPercentage(emplacement.missionId) > 0) {
    return Icons.info_outline;
  } else {
    return Icons.location_on_outlined;
  }
}

/// Obtenir la couleur pour un emplacement
static Future<Color> getColorForEmplacement(ClassementEmplacement emplacement) async {
  final percentage = await getCompletionPercentage(emplacement.missionId);
  
  if (percentage == 100) return Colors.green;
  if (percentage >= 50) return Colors.orange;
  return Colors.blue;
}

/// Exporter les données de classement au format CSV
static String exportClassementToCSV(String missionId) {
  final emplacements = getEmplacementsByMissionId(missionId);
  
  final csv = StringBuffer();
  
  // En-tête
  csv.writeln('Localisation;Zone;Origine classement;AF;BE;AE;AD;AG;IP;IK');
  
  // Données
  for (var emp in emplacements) {
    csv.writeln('${emp.localisation};${emp.zone ?? ""};${emp.origineClassement};'
                '${emp.af ?? ""};${emp.be ?? ""};${emp.ae ?? ""};${emp.ad ?? ""};${emp.ag ?? ""};'
                '${emp.ip ?? ""};${emp.ik ?? ""}');
  }
  
  return csv.toString();
}

/// Importer les données de classement depuis CSV
static Future<bool> importClassementFromCSV(String missionId, String csvData) async {
  try {
    final lines = csvData.split('\n');
    
    // Ignorer l'en-tête
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final parts = line.split(';');
      if (parts.length < 3) continue;
      
      final localisation = parts[0];
      final zone = parts[1].isEmpty ? null : parts[1];
      final origineClassement = parts[2];
      
      // Chercher l'emplacement existant ou en créer un nouveau
      var emplacement = getEmplacementByNom(missionId, localisation);
      
      if (emplacement == null) {
        emplacement = ClassementEmplacement.create(
          missionId: missionId,
          localisation: localisation,
          zone: zone,
          typeLocal: null,
        );
        final box = Hive.box<ClassementEmplacement>(_classementBox);
        await box.add(emplacement);
      }
      
      // Mettre à jour les valeurs
      emplacement.origineClassement = origineClassement;
      
      if (parts.length > 3 && parts[3].isNotEmpty) emplacement.af = parts[3];
      if (parts.length > 4 && parts[4].isNotEmpty) emplacement.be = parts[4];
      if (parts.length > 5 && parts[5].isNotEmpty) emplacement.ae = parts[5];
      if (parts.length > 6 && parts[6].isNotEmpty) emplacement.ad = parts[6];
      if (parts.length > 7 && parts[7].isNotEmpty) emplacement.ag = parts[7];
      
      // Recalculer les indices
      emplacement.calculerIndices();
      emplacement.updatedAt = DateTime.now();
      
      await emplacement.save();
    }
    
    if (kDebugMode) {
      print('✅ Données de classement importées pour mission $missionId');
    }
    return true;
    
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur importClassementFromCSV: $e');
    }
    return false;
  }
}

/// Vérifier la cohérence des données d'audit
static Map<String, dynamic> checkAuditConsistency(String missionId) {
  final audit = getAuditInstallationsByMissionId(missionId);
  final emplacements = getEmplacementsByMissionId(missionId);
  
  final issues = <String>[];
  
  if (audit == null) {
    issues.add('Aucun audit trouvé pour cette mission');
    return {'hasIssues': true, 'issues': issues, 'suggestions': ['Créer d\'abord un audit']};
  }
  
  // Vérifier les locaux moyenne tension
  for (var local in audit.moyenneTensionLocaux) {
    if (!emplacements.any((e) => e.localisation == local.nom)) {
      issues.add('Local MT "${local.nom}" non synchronisé');
    }
  }
  
  // Vérifier les zones moyenne tension
  for (var zone in audit.moyenneTensionZones) {
    if (!emplacements.any((e) => e.localisation == zone.nom)) {
      issues.add('Zone MT "${zone.nom}" non synchronisée');
    }
  }
  
  // Vérifier les zones basse tension
  for (var zone in audit.basseTensionZones) {
    if (!emplacements.any((e) => e.localisation == zone.nom)) {
      issues.add('Zone BT "${zone.nom}" non synchronisée');
    }
    
    // Vérifier les locaux dans les zones
    for (var local in zone.locaux) {
      final nomLocal = '${zone.nom} - ${local.nom}';
      if (!emplacements.any((e) => e.localisation == nomLocal)) {
        issues.add('Local BT "$nomLocal" non synchronisé');
      }
    }
  }
  
  return {
    'hasIssues': issues.isNotEmpty,
    'issues': issues,
    'totalIssues': issues.length,
    'suggestions': issues.isEmpty 
      ? ['Tout est synchronisé ✓'] 
      : ['Cliquez sur "Synchroniser" pour corriger']
  };
}

/// Obtenir un résumé du classement
static Map<String, dynamic> getClassementSummary(String missionId) {
  final emplacements = getEmplacementsByMissionId(missionId);
  final stats = getEmplacementsStats(missionId);
  final consistency = checkAuditConsistency(missionId);
  
  // Calculer les influences les plus fréquentes
  final influenceCounts = <String, int>{};
  
  for (var emp in emplacements) {
    if (emp.af != null) influenceCounts['AF'] = (influenceCounts['AF'] ?? 0) + 1;
    if (emp.be != null) influenceCounts['BE'] = (influenceCounts['BE'] ?? 0) + 1;
    if (emp.ae != null) influenceCounts['AE'] = (influenceCounts['AE'] ?? 0) + 1;
    if (emp.ad != null) influenceCounts['AD'] = (influenceCounts['AD'] ?? 0) + 1;
    if (emp.ag != null) influenceCounts['AG'] = (influenceCounts['AG'] ?? 0) + 1;
  }
  
  return {
    'total_emplacements': stats['total'],
    'complet': stats['complet'],
    'incomplet': stats['incomplet'],
    'pourcentage_complet': stats['pourcentage_complet'],
    'consistency_issues': consistency['totalIssues'],
    'influence_counts': influenceCounts,
    'last_updated': emplacements.isNotEmpty 
      ? emplacements.map((e) => e.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b)
      : null,
  };
}

/// Forcer la synchronisation (supprime et recrée)
static Future<bool> forceSyncEmplacements(String missionId) async {
  try {
    // 1. Supprimer les anciens emplacements
    await clearEmplacementsForMission(missionId);
    
    // 2. Synchroniser à nouveau
    await syncEmplacementsFromAudit(missionId);
    
    if (kDebugMode) {
      print('✅ Synchronisation forcée terminée pour mission $missionId');
    }
    return true;
    
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur forceSyncEmplacements: $e');
    }
    return false;
  }
}

/// Obtenir les emplacements groupés par type
static Map<String, List<ClassementEmplacement>> getEmplacementsByType(String missionId) {
  final emplacements = getEmplacementsByMissionId(missionId);
  
  final result = <String, List<ClassementEmplacement>>{
    'LOCAUX_MT': [],
    'ZONES_MT': [],
    'ZONES_BT': [],
    'LOCAUX_BT': [],
    'AUTRES': [],
  };
  
  for (var emp in emplacements) {
    if (emp.typeLocal == 'LOCAL_TRANSFORMATEUR') {
      result['LOCAUX_MT']!.add(emp);
    } else if (emp.typeLocal == 'ZONE_MT') {
      result['ZONES_MT']!.add(emp);
    } else if (emp.typeLocal == 'ZONE_BT') {
      result['ZONES_BT']!.add(emp);
    } else if (emp.typeLocal?.contains('LOCAL_') == true && emp.zone != null) {
      result['LOCAUX_BT']!.add(emp);
    } else {
      result['AUTRES']!.add(emp);
    }
  }
  
  return result;
}

/// Obtenir les statistiques par type
static Map<String, Map<String, dynamic>> getStatsByType(String missionId) {
  final grouped = getEmplacementsByType(missionId);
  final result = <String, Map<String, dynamic>>{};
  
  for (var entry in grouped.entries) {
    final type = entry.key;
    final emplacements = entry.value;
    
    final complet = emplacements.where((e) => isEmplacementComplet(e)).length;
    final incomplet = emplacements.length - complet;
    
    result[type] = {
      'total': emplacements.length,
      'complet': complet,
      'incomplet': incomplet,
      'pourcentage': emplacements.isNotEmpty ? (complet / emplacements.length * 100).round() : 0,
    };
  }
  
  return result;
}

// ============================================================
//          LISTENERS ET OBSERVATEURS
// ============================================================

/// Écouter les changements dans les emplacements
static ValueListenable<Box<ClassementEmplacement>> watchEmplacements(String missionId) {
  final box = Hive.box<ClassementEmplacement>(_classementBox);
  return box.listenable();
}

/// Filtrer les emplacements par critères
static List<ClassementEmplacement> filterEmplacements({
  required String missionId,
  String? searchQuery,
  bool? onlyComplete,
  String? typeLocal,
}) {
  var emplacements = getEmplacementsByMissionId(missionId);
  
  // Filtrer par recherche
  if (searchQuery != null && searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    emplacements = emplacements.where((e) =>
      e.localisation.toLowerCase().contains(query) ||
      (e.zone?.toLowerCase() ?? '').contains(query) ||
      (e.typeLocal?.toLowerCase() ?? '').contains(query)
    ).toList();
  }
  
  // Filtrer par complétude
  if (onlyComplete != null) {
    if (onlyComplete) {
      emplacements = emplacements.where((e) => isEmplacementComplet(e)).toList();
    } else {
      emplacements = emplacements.where((e) => !isEmplacementComplet(e)).toList();
    }
  }
  
  // Filtrer par type
  if (typeLocal != null && typeLocal.isNotEmpty) {
    emplacements = emplacements.where((e) => e.typeLocal == typeLocal).toList();
  }
  
  return emplacements;
}

/// Trier les emplacements
static List<ClassementEmplacement> sortEmplacements({
  required List<ClassementEmplacement> emplacements,
  String sortBy = 'localisation',
  bool ascending = true,
}) {
  List<ClassementEmplacement> sorted = List.from(emplacements);
  
  switch (sortBy) {
    case 'localisation':
      sorted.sort((a, b) => a.localisation.compareTo(b.localisation));
      break;
    case 'zone':
      sorted.sort((a, b) => (a.zone ?? '').compareTo(b.zone ?? ''));
      break;
    case 'completude':
      sorted.sort((a, b) {
        final aComplete = isEmplacementComplet(a);
        final bComplete = isEmplacementComplet(b);
        if (aComplete == bComplete) return 0;
        return aComplete ? 1 : -1;
      });
      break;
    case 'updated':
      sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      break;
  }
  
  if (!ascending) {
    sorted = sorted.reversed.toList();
  }
  
  return sorted;
}

// ============================================================
//          GESTION DES OBSERVATIONS FOUDRES ``
// ============================================================

/// Créer une nouvelle observation foudre
static Future<Foudre> createFoudreObservation({
  required String missionId,
  required String observation,
  required int niveauPriorite,
}) async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    
    // Créer la nouvelle observation
    final foudre = Foudre.create(
      missionId: missionId,
      observation: observation,
      niveauPriorite: niveauPriorite,
    );
    
    // Sauvegarder dans Hive
    await box.add(foudre);
    
    // Mettre à jour la référence dans la mission (si nécessaire)
    await _updateFoudreReferenceInMission(missionId, foudre);
    
    if (kDebugMode) {
      print('✅ Observation foudre créée: ${foudre.key}');
    }
    return foudre;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur createFoudreObservation: $e');
    }
    rethrow;
  }
}

/// Récupérer toutes les observations foudre d'une mission
static List<Foudre> getFoudreObservationsByMissionId(String missionId) {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    return box.values
        .where((foudre) => foudre.missionId == missionId)
        .toList();
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getFoudreObservationsByMissionId: $e');
    }
    return [];
  }
}

/// Récupérer une observation foudre par son ID (clé Hive)
static Foudre? getFoudreObservationById(dynamic id) {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    return box.get(id);
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getFoudreObservationById: $e');
    }
    return null;
  }
}

/// Récupérer les observations foudre par niveau de priorité
static List<Foudre> getFoudreObservationsByPriority(String missionId, int niveauPriorite) {
  try {
    final allObservations = getFoudreObservationsByMissionId(missionId);
    return allObservations
        .where((foudre) => foudre.niveauPriorite == niveauPriorite)
        .toList();
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getFoudreObservationsByPriority: $e');
    }
    return [];
  }
}

// ============================================================
//          MISE À JOUR FOUDRES
// ============================================================

/// Mettre à jour une observation foudre existante
static Future<bool> updateFoudreObservation({
  required dynamic foudreId,
  required String observation,
  required int niveauPriorite,
}) async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    final foudre = box.get(foudreId);
    
    if (foudre == null) {
      if (kDebugMode) {
        print('❌ Observation foudre non trouvée: $foudreId');
      }
      return false;
    }
    
    // Valider le niveau de priorité
    if (niveauPriorite < 1 || niveauPriorite > 3) {
      if (kDebugMode) print('❌ Niveau de priorité invalide: $niveauPriorite');
      return false;
    }
    
    // Mettre à jour les propriétés
    foudre.observation = observation;
    foudre.niveauPriorite = niveauPriorite;
    foudre.updatedAt = DateTime.now();
    
    // Sauvegarder les modifications
    await foudre.save();
    
    if (kDebugMode) print('✅ Observation foudre mise à jour: $foudreId');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateFoudreObservation: $e');
    return false;
  }
}

/// Mettre à jour uniquement l'observation (sans changer la priorité)
static Future<bool> updateFoudreObservationText({
  required dynamic foudreId,
  required String observation,
}) async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    final foudre = box.get(foudreId);
    
    if (foudre == null) {
      if (kDebugMode) print('❌ Observation foudre non trouvée: $foudreId');
      return false;
    }
    
    foudre.observation = observation;
    foudre.updatedAt = DateTime.now();
    
    await foudre.save();
    
    if (kDebugMode) print('✅ Texte observation foudre mis à jour: $foudreId');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateFoudreObservationText: $e');
    return false;
  }
}

/// Mettre à jour uniquement la priorité
static Future<bool> updateFoudreObservationPriority({
  required dynamic foudreId,
  required int niveauPriorite,
}) async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    final foudre = box.get(foudreId);
    
    if (foudre == null) {
      if (kDebugMode) print('❌ Observation foudre non trouvée: $foudreId');
      return false;
    }
    
    // Valider le niveau de priorité
    if (niveauPriorite < 1 || niveauPriorite > 3) {
      if (kDebugMode) print('❌ Niveau de priorité invalide: $niveauPriorite');
      return false;
    }
    
    foudre.niveauPriorite = niveauPriorite;
    foudre.updatedAt = DateTime.now();
    
    await foudre.save();
    
    if (kDebugMode) print('✅ Priorité observation foudre mise à jour: $foudreId -> $niveauPriorite');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateFoudreObservationPriority: $e');
    return false;
  }
}

// ============================================================
//          SUPPRESSION FOUDRES
// ============================================================

/// Supprimer une observation foudre
static Future<bool> deleteFoudreObservation(dynamic foudreId) async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    final foudre = box.get(foudreId);
    
    if (foudre == null) {
      if (kDebugMode) print('❌ Observation foudre non trouvée: $foudreId');
      return false;
    }
    
    // Supprimer la référence dans la mission (si nécessaire)
    await _removeFoudreReferenceFromMission(foudre.missionId, foudreId);
    
    // Supprimer l'observation
    await foudre.delete();
    
    if (kDebugMode) print('✅ Observation foudre supprimée: $foudreId');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur deleteFoudreObservation: $e');
    return false;
  }
}

/// Supprimer toutes les observations foudre d'une mission
static Future<bool> deleteAllFoudreObservationsForMission(String missionId) async {
  try {
    final observations = getFoudreObservationsByMissionId(missionId);
    
    for (var foudre in observations) {
      await foudre.delete();
    }
    
    // Supprimer les références dans la mission (si nécessaire)
    await _clearFoudreReferencesFromMission(missionId);
    
    if (kDebugMode) print('✅ ${observations.length} observations foudre supprimées pour mission $missionId');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur deleteAllFoudreObservationsForMission: $e');
    return false;
  }
}

// ============================================================
//          GESTION DES RÉFÉRENCES DANS LA MISSION (FACULTATIF)
// ============================================================

/// Mettre à jour la référence d'une observation foudre dans la mission
static Future<void> _updateFoudreReferenceInMission(String missionId, Foudre foudre) async {
  try {
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    
    if (mission != null) {
      // Initialiser la liste si nécessaire
      mission.foudreIds ??= [];
      
      // Ajouter l'ID de l'observation (key est l'ID Hive)
      final foudreId = foudre.key.toString();
      if (!mission.foudreIds!.contains(foudreId)) {
        mission.foudreIds!.add(foudreId);
        mission.updatedAt = DateTime.now();
        await mission.save();
        
        if (kDebugMode) print('✅ Référence foudre ajoutée à la mission $missionId: $foudreId');
      }
    }
  } catch (e) {
    if (kDebugMode) print('❌ Erreur _updateFoudreReferenceInMission: $e');
  }
}

/// Supprimer la référence d'une observation foudre d'une mission
static Future<void> _removeFoudreReferenceFromMission(String missionId, dynamic foudreId) async {
  try {
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    
    if (mission != null && mission.foudreIds != null) {
      final foudreIdStr = foudreId.toString();
      mission.foudreIds!.remove(foudreIdStr);
      mission.updatedAt = DateTime.now();
      await mission.save();
      
      if (kDebugMode) print('✅ Référence foudre supprimée de la mission $missionId: $foudreIdStr');
    }
  } catch (e) {
    if (kDebugMode) print('❌ Erreur _removeFoudreReferenceFromMission: $e');
  }
}

/// Supprimer toutes les références foudre d'une mission
static Future<void> _clearFoudreReferencesFromMission(String missionId) async {
  try {
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    
    if (mission != null) {
      mission.foudreIds = null;
      mission.updatedAt = DateTime.now();
      await mission.save();
      
      if (kDebugMode) print('✅ Toutes les références foudre supprimées de la mission $missionId');
    }
  } catch (e) {
    if (kDebugMode) print('❌ Erreur _clearFoudreReferencesFromMission: $e');
  }
}

// ============================================================
//          STATISTIQUES FOUDRES
// ============================================================

/// Obtenir les statistiques des observations foudre pour une mission
static Map<String, dynamic> getFoudreStatsForMission(String missionId) {
  try {
    final observations = getFoudreObservationsByMissionId(missionId);
    
    final total = observations.length;
    
    // Compter par priorité
    final byPriority = {
      1: observations.where((f) => f.niveauPriorite == 1).length,
      2: observations.where((f) => f.niveauPriorite == 2).length,
      3: observations.where((f) => f.niveauPriorite == 3).length,
    };
    
    // Dates des observations
    final latestObservation = observations.isNotEmpty
        ? observations.map((f) => f.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    
    final latestUpdate = observations.isNotEmpty
        ? observations.map((f) => f.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    
    return {
      'total': total,
      'priorite_1': byPriority[1] ?? 0,
      'priorite_2': byPriority[2] ?? 0,
      'priorite_3': byPriority[3] ?? 0,
      'derniere_creation': latestObservation,
      'derniere_modification': latestUpdate,
      'pourcentage_priorite_1': total > 0 ? ((byPriority[1] ?? 0) / total * 100).round() : 0,
      'pourcentage_priorite_2': total > 0 ? ((byPriority[2] ?? 0) / total * 100).round() : 0,
      'pourcentage_priorite_3': total > 0 ? ((byPriority[3] ?? 0) / total * 100).round() : 0,
    };
  } catch (e) {
    if (kDebugMode) print('❌ Erreur getFoudreStatsForMission: $e');
    return {
      'total': 0,
      'priorite_1': 0,
      'priorite_2': 0,
      'priorite_3': 0,
      'derniere_creation': null,
      'derniere_modification': null,
      'pourcentage_priorite_1': 0,
      'pourcentage_priorite_2': 0,
      'pourcentage_priorite_3': 0,
    };
  }
}

/// Obtenir le label de priorité (texte)
static String getPrioriteLabel(int niveauPriorite) {
  switch (niveauPriorite) {
    case 1: return 'Priorité Haute';
    case 2: return 'Priorité Moyenne';
    case 3: return 'Priorité Basse';
    default: return 'Non défini';
  }
}

/// Obtenir la couleur pour une priorité
static String getPrioriteColor(int niveauPriorite) {
  switch (niveauPriorite) {
    case 1: return '#FF0000'; // Rouge
    case 2: return '#FFA500'; // Orange
    case 3: return '#008000'; // Vert
    default: return '#000000'; // Noir
  }
}

/// Vérifier si une mission a des observations foudre
static bool hasFoudreObservations(String missionId) {
  return getFoudreObservationsByMissionId(missionId).isNotEmpty;
}

/// Obtenir le nombre total d'observations foudre pour une mission
static int getFoudreCountForMission(String missionId) {
  return getFoudreObservationsByMissionId(missionId).length;
}

// ============================================================
//          FILTRAGE ET TRI FOUDRES
// ============================================================

/// Filtrer les observations foudre
static List<Foudre> filterFoudreObservations({
  required String missionId,
  String? searchQuery,
  int? niveauPriorite,
}) {
  var observations = getFoudreObservationsByMissionId(missionId);
  
  // Filtrer par recherche textuelle
  if (searchQuery != null && searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    observations = observations
        .where((f) => f.observation.toLowerCase().contains(query))
        .toList();
  }
  
  // Filtrer par priorité
  if (niveauPriorite != null) {
    observations = observations
        .where((f) => f.niveauPriorite == niveauPriorite)
        .toList();
  }
  
  return observations;
}

/// Trier les observations foudre
static List<Foudre> sortFoudreObservations({
  required List<Foudre> observations,
  String sortBy = 'created_at',
  bool ascending = true,
}) {
  List<Foudre> sorted = List.from(observations);
  
  switch (sortBy) {
    case 'created_at':
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case 'updated_at':
      sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      break;
    case 'priorite':
      sorted.sort((a, b) => a.niveauPriorite.compareTo(b.niveauPriorite));
      break;
    case 'observation':
      sorted.sort((a, b) => a.observation.compareTo(b.observation));
      break;
  }
  
  if (!ascending) {
    sorted = sorted.reversed.toList();
  }
  
  return sorted;
}

// ============================================================
//          IMPORT/EXPORT FOUDRES
// ============================================================

/// Exporter les observations foudre au format CSV
static String exportFoudreToCSV(String missionId) {
  try {
    final observations = getFoudreObservationsByMissionId(missionId);
    
    final csv = StringBuffer();
    
    // En-tête
    csv.writeln('ID;Observation;Priorité;Date création;Date modification');
    
    // Données
    for (var foudre in observations) {
      csv.writeln('${foudre.key};'
                  '${foudre.observation.replaceAll(';', ',')};'
                  '${foudre.niveauPriorite};'
                  '${foudre.createdAt.toIso8601String()};'
                  '${foudre.updatedAt.toIso8601String()}');
    }
    
    return csv.toString();
  } catch (e) {
    if (kDebugMode) print('❌ Erreur exportFoudreToCSV: $e');
    return '';
  }
}

/// Importer les observations foudre depuis JSON
static Future<bool> importFoudreFromJson(String missionId, List<Map<String, dynamic>> jsonData) async {
  try {
    int imported = 0;
    
    for (var data in jsonData) {
      try {
        // Créer l'observation depuis le JSON
        final foudre = Foudre.fromJson(data);
        
        // S'assurer que la missionId est correcte
        foudre.missionId = missionId;
        
        // Sauvegarder dans Hive
        final box = Hive.box<Foudre>(_foudreBox);
        await box.add(foudre);
        
        imported++;
      } catch (e) {
        if (kDebugMode) print('❌ Erreur lors de l\'import d\'une observation: $e');
      }
    }
    
    if (kDebugMode) print('✅ $imported observations foudre importées pour mission $missionId');
    return true;
    
  } catch (e) {
    if (kDebugMode) print('❌ Erreur importFoudreFromJson: $e');
    return false;
  }
}

// ============================================================
//          ÉCOUTEUR ET OBSERVATEURS FOUDRES
// ============================================================

/// Écouter les changements dans les observations foudre d'une mission
static ValueListenable<Box<Foudre>> watchFoudreObservations(String missionId) {
  final box = Hive.box<Foudre>(_foudreBox);
  return box.listenable();
}

/// Obtenir un stream des observations filtrées
static Stream<List<Foudre>> streamFoudreObservations({
  required String missionId,
  int? niveauPriorite,
}) {
  final box = Hive.box<Foudre>(_foudreBox);
  
  return box.watch().map((event) {
    return filterFoudreObservations(
      missionId: missionId,
      niveauPriorite: niveauPriorite,
    );
  });
}

// ============================================================
//          UTILITAIRES FOUDRES
// ============================================================

/// Vérifier si une observation existe
static bool foudreObservationExists(dynamic foudreId) {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    return box.containsKey(foudreId);
  } catch (e) {
    if (kDebugMode) print('❌ Erreur foudreObservationExists: $e');
    return false;
  }
}

/// Obtenir toutes les observations foudre (toutes missions confondues)
static List<Foudre> getAllFoudreObservations() {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    return box.values.toList();
  } catch (e) {
    if (kDebugMode) print('❌ Erreur getAllFoudreObservations: $e');
    return [];
  }
}

/// Vider complètement la table foudre
static Future<bool> clearAllFoudreObservations() async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    await box.clear();
    
    // Supprimer aussi toutes les références dans les missions
    final missionBox = Hive.box<Mission>(_missionBox);
    for (var mission in missionBox.values) {
      mission.foudreIds = null;
      await mission.save();
    }
    
    if (kDebugMode) print('✅ Toutes les observations foudre supprimées');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur clearAllFoudreObservations: $e');
    return false;
  }
}

/// Copier les observations foudre d'une mission à une autre
static Future<bool> copyFoudreObservations({
  required String sourceMissionId,
  required String targetMissionId,
}) async {
  try {
    final sourceObservations = getFoudreObservationsByMissionId(sourceMissionId);
    
    for (var sourceFoudre in sourceObservations) {
      // Créer une nouvelle observation pour la mission cible
      await createFoudreObservation(
        missionId: targetMissionId,
        observation: sourceFoudre.observation,
        niveauPriorite: sourceFoudre.niveauPriorite,
      );
    }
    
    if (kDebugMode) print('✅ ${sourceObservations.length} observations foudre copiées de $sourceMissionId vers $targetMissionId');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur copyFoudreObservations: $e');
    return false;
  }
}

// ============================================================
//          GESTION MESURES ET ESSAIS (NOUVEAU)
// ============================================================

/// Créer ou récupérer les données de mesures et essais pour une mission
static Future<MesuresEssais> getOrCreateMesuresEssais(String missionId) async {
  final box = Hive.box<MesuresEssais>(_mesuresEssaisBox);
  
  try {
    final existing = box.values.firstWhere((mesures) => mesures.missionId == missionId);
    return existing;
  } catch (e) {
    // Créer une nouvelle instance
    final newMesures = MesuresEssais.create(missionId);
    await box.add(newMesures);
    
    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.mesuresEssaisId = newMesures.key.toString();
      await mission.save();
    }
    
    if (kDebugMode) print('✅ MesuresEssais créé pour mission: $missionId');
    return newMesures;
  }
}

/// Sauvegarder les données de mesures et essais
static Future<void> saveMesuresEssais(MesuresEssais mesures) async {
  final box = Hive.box<MesuresEssais>(_mesuresEssaisBox);
  mesures.updatedAt = DateTime.now();
  if (mesures.isInBox) {
    await mesures.save();
  } else {
    final existingIndex = box.values.toList().indexWhere((m) => m.missionId == mesures.missionId);
    if (existingIndex != -1) {
      final existingKey = box.keyAt(existingIndex);
      await box.put(existingKey, mesures);
    } else {
      await box.add(mesures);
    }
  }
  if (kDebugMode) print('✅ MesuresEssais sauvegardé pour mission: ${mesures.missionId}');
}

/// Récupérer les données de mesures et essais par missionId
static MesuresEssais? getMesuresEssaisByMissionId(String missionId) {
  final box = Hive.box<MesuresEssais>(_mesuresEssaisBox);
  try {
    return box.values.firstWhere((mesures) => mesures.missionId == missionId);
  } catch (e) {
    return null;
  }
}

/// Vérifier si une mission a des données de mesures et essais
static bool hasMesuresEssais(String missionId) {
  return getMesuresEssaisByMissionId(missionId) != null;
}

/// Obtenir les statistiques des mesures et essais pour une mission
static Map<String, dynamic> getMesuresEssaisStats(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  if (mesures == null) {
    return {
      'total_prises_terre': 0,
      'total_essais_differ': 0,
      'total_continuites': 0,
      'condition_mesure_renseignee': false,
      'demarrage_auto_renseigne': false,
      'arret_urgence_renseigne': false,
      'avis_mesures_renseigne': false,
    };
  }
  
  return mesures.calculerStatistiques();
}

// ============================================================
//          SECTION 1: CONDITIONS DE MESURE
// ============================================================

/// Mettre à jour les conditions de mesure
static Future<bool> updateConditionMesure({
  required String missionId,
  required String observation,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.conditionMesure.observation = observation;
    await saveMesuresEssais(mesures);
    if (kDebugMode) print('✅ Conditions de mesure mises à jour');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateConditionMesure: $e');
    return false;
  }
}

// ============================================================
//          SECTION 2: ESSAIS DE DÉMARRAGE AUTOMATIQUE
// ============================================================

/// Mettre à jour les essais de démarrage automatique
static Future<bool> updateEssaiDemarrageAuto({
  required String missionId,
  required String observation,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.essaiDemarrageAuto.observation = observation;
    await saveMesuresEssais(mesures);
    if (kDebugMode) print('✅ Essais démarrage auto mis à jour');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateEssaiDemarrageAuto: $e');
    return false;
  }
}

// ============================================================
//          SECTION 3: TEST D'ARRÊT D'URGENCE
// ============================================================

/// Mettre à jour les tests d'arrêt d'urgence
static Future<bool> updateTestArretUrgence({
  required String missionId,
  bool? presence,
  String? observation,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (presence != null) {
      mesures.testArretUrgence.presence = presence;
    }
    if (observation != null) {
      mesures.testArretUrgence.observation = observation;
    }
    await saveMesuresEssais(mesures);
    if (kDebugMode) print('✅ Tests arrêt urgence mis à jour (presence: $presence, obs: $observation)');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateTestArretUrgence: $e');
    return false;
  }
}

// ============================================================
//          SECTION 4: PRISES DE TERRE
// ============================================================

/// Ajouter une prise de terre
static Future<bool> addPriseTerre({
  required String missionId,
  required PriseTerre priseTerre,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.prisesTerre.add(priseTerre);
    await saveMesuresEssais(mesures);
    if (kDebugMode) print('✅ Prise de terre ajoutée: ${priseTerre.identification}');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addPriseTerre: $e');
    return false;
  }
}

/// Mettre à jour une prise de terre existante
static Future<bool> updatePriseTerre({
  required String missionId,
  required int index,
  required PriseTerre priseTerre,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.prisesTerre.length) {
      mesures.prisesTerre[index] = priseTerre;
      await saveMesuresEssais(mesures);
      if (kDebugMode) print('✅ Prise de terre mise à jour: ${priseTerre.identification}');
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updatePriseTerre: $e');
    return false;
  }
}

/// Supprimer une prise de terre
static Future<bool> deletePriseTerre({
  required String missionId,
  required int index,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.prisesTerre.length) {
      final pt = mesures.prisesTerre.removeAt(index);
      await saveMesuresEssais(mesures);
      if (kDebugMode) print('✅ Prise de terre supprimée: ${pt.identification}');
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur deletePriseTerre: $e');
    return false;
  }
}

/// Récupérer toutes les prises de terre d'une mission
static List<PriseTerre> getPrisesTerre(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  return mesures?.prisesTerre ?? [];
}

// ============================================================
//          SECTION 5: AVIS SUR LES MESURES
// ============================================================

/// Mettre à jour l'avis sur les mesures
static Future<bool> updateAvisMesuresTerre({
  required String missionId,
  String? observation,
  List<String>? satisfaisants,
  List<String>? nonSatisfaisants,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    
    if (observation != null) {
      mesures.avisMesuresTerre.observation = observation;
    }
    
    if (satisfaisants != null) {
      mesures.avisMesuresTerre.satisfaisants = satisfaisants;
    }
    
    if (nonSatisfaisants != null) {
      mesures.avisMesuresTerre.nonSatisfaisants = nonSatisfaisants;
    }
    
    await saveMesuresEssais(mesures);
    if (kDebugMode) print('✅ Avis sur les mesures mis à jour');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateAvisMesuresTerre: $e');
    return false;
  }
}

// ============================================================
//          SECTION 6: ESSAIS DÉCLENCHEMENT DIFFÉRENTIELS
// ============================================================

/// Ajouter un essai de déclenchement différentiel
static Future<bool> addEssaiDeclenchement({
  required String missionId,
  required EssaiDeclenchementDifferentiel essai,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.essaisDeclenchement.add(essai);
    await saveMesuresEssais(mesures);
    if (kDebugMode) print('✅ Essai déclenchement ajouté: ${essai.designationCircuit}');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addEssaiDeclenchement: $e');
    return false;
  }
}

/// Mettre à jour un essai de déclenchement différentiel existant
static Future<bool> updateEssaiDeclenchement({
  required String missionId,
  required int index,
  required EssaiDeclenchementDifferentiel essai,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.essaisDeclenchement.length) {
      mesures.essaisDeclenchement[index] = essai;
      await saveMesuresEssais(mesures);
      if (kDebugMode) print('✅ Essai déclenchement mis à jour: ${essai.designationCircuit}');
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateEssaiDeclenchement: $e');
    return false;
  }
}

/// Supprimer un essai de déclenchement différentiel
static Future<bool> deleteEssaiDeclenchement({
  required String missionId,
  required int index,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.essaisDeclenchement.length) {
      final essai = mesures.essaisDeclenchement.removeAt(index);
      await saveMesuresEssais(mesures);
      if (kDebugMode) print('✅ Essai déclenchement supprimé: ${essai.designationCircuit}');
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur deleteEssaiDeclenchement: $e');
    return false;
  }
}

/// Récupérer tous les essais de déclenchement d'une mission
static List<EssaiDeclenchementDifferentiel> getEssaisDeclenchement(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  return mesures?.essaisDeclenchement ?? [];
}

// ============================================================
//          SECTION 7: ESSAIS DE MESURE D'ISOLEMENT
// ============================================================

/// Ajouter ou mettre à jour un essai d'isolement (remplace l'essai existant pour le même équipment/pointControle)
static Future<bool> saveEssaiIsolement({
  required String missionId,
  required EssaiIsolement essai,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    final existingIndex = mesures.essaisIsolement.indexWhere(
      (e) => e.equipmentSyncId == essai.equipmentSyncId && e.pointControle == essai.pointControle,
    );
    if (existingIndex >= 0) {
      mesures.essaisIsolement[existingIndex] = essai;
    } else {
      mesures.essaisIsolement.add(essai);
    }
    await saveMesuresEssais(mesures);
    if (kDebugMode) print('✅ Essai isolement sauvegardé: ${essai.designation} (${essai.pointControle})');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur saveEssaiIsolement: $e');
    return false;
  }
}

/// Supprimer un essai d'isolement
static Future<bool> deleteEssaiIsolement({
  required String missionId,
  required String equipmentSyncId,
  required String pointControle,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    final initialCount = mesures.essaisIsolement.length;
    mesures.essaisIsolement.removeWhere(
      (e) => e.equipmentSyncId == equipmentSyncId && e.pointControle == pointControle,
    );
    if (mesures.essaisIsolement.length < initialCount) {
      await saveMesuresEssais(mesures);
      if (kDebugMode) print('✅ Essai isolement supprimé pour: $equipmentSyncId - $pointControle');
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur deleteEssaiIsolement: $e');
    return false;
  }
}

/// Récupérer tous les essais d'isolement d'une mission
static List<EssaiIsolement> getEssaisIsolement(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  return mesures?.essaisIsolement ?? [];
}

/// Récupérer l'essai d'isolement pour un point spécifique d'un équipement
static EssaiIsolement? getEssaiIsolementForPoint({
  required String missionId,
  required String equipmentSyncId,
  required String pointControle,
}) {
  final essais = getEssaisIsolement(missionId);
  try {
    return essais.firstWhere(
      (e) => e.equipmentSyncId == equipmentSyncId && e.pointControle == pointControle,
    );
  } catch (_) {
    return null;
  }
}

/// Récupérer les localisations disponibles depuis l'audit pour les essais
static List<String> getLocalisationsForEssais(String missionId) {
  final audit = getAuditInstallationsByMissionId(missionId);
  if (audit == null) return [];
  
  final localisations = <String>[];
  
  // Locaux moyenne tension
  for (var local in audit.moyenneTensionLocaux) {
    localisations.add(local.nom);
  }
  
  // Zones moyenne tension
  for (var zone in audit.moyenneTensionZones) {
    localisations.add(zone.nom);
  }
  
  // Zones basse tension
  for (var zone in audit.basseTensionZones) {
    localisations.add(zone.nom);
    // Locaux dans les zones
    for (var local in zone.locaux) {
      localisations.add('${zone.nom} - ${local.nom}');
    }
  }
  
  // Ajouter aussi les classements existants
  final classements = getEmplacementsByMissionId(missionId);
  for (var classement in classements) {
    if (!localisations.contains(classement.localisation)) {
      localisations.add(classement.localisation);
    }
  }
  
  return localisations;
}

/// Récupérer les coffrets pour une localisation spécifique
static List<String> getCoffretsForLocalisation(String missionId, String localisation) {
  final audit = getAuditInstallationsByMissionId(missionId);
  if (audit == null) return [];
  
  final coffrets = <String>[];
  
  // Chercher dans tous les locaux et zones
  // (Cette méthode pourrait être améliorée selon votre structure exacte)
  for (var local in audit.moyenneTensionLocaux) {
    if (local.nom == localisation || localisation.contains(local.nom)) {
      for (var coffret in local.coffrets) {
        coffrets.add(coffret.nom);
      }
    }
  }
  
  for (var zone in audit.moyenneTensionZones) {
    if (zone.nom == localisation || localisation.contains(zone.nom)) {
      for (var coffret in zone.coffrets) {
        coffrets.add(coffret.nom);
      }
    }
  }
  
  for (var zone in audit.basseTensionZones) {
    if (zone.nom == localisation || localisation.contains(zone.nom)) {
      for (var coffret in zone.coffretsDirects) {
        coffrets.add(coffret.nom);
      }
      for (var local in zone.locaux) {
        if (localisation.contains(local.nom)) {
          for (var coffret in local.coffrets) {
            coffrets.add(coffret.nom);
          }
        }
      }
    }
  }
  
  return coffrets;
}

/// Récupérer les équipements (Armoire, Coffret, TGBT, Inverseur) pour une localisation spécifique avec typage
static List<String> getEquipementsForLocalisation(String missionId, String localisation) {
  final audit = getAuditInstallationsByMissionId(missionId);
  if (audit == null) return [];

  final equipements = <String>[];

  void addCoffret(dynamic coffret) {
    final type = coffret.type?.toString() ?? '';
    final nom = coffret.nom?.toString() ?? '';
    if (nom.isEmpty) return;
    String formatted;
    if (type.isNotEmpty && !nom.toUpperCase().contains(type.toUpperCase())) {
      formatted = '$type - $nom';
    } else {
      formatted = nom;
    }
    if (!equipements.contains(formatted)) {
      equipements.add(formatted);
    }
  }

  for (var local in audit.moyenneTensionLocaux) {
    if (local.nom == localisation || localisation.contains(local.nom)) {
      for (var coffret in local.coffrets) {
        addCoffret(coffret);
      }
    }
  }

  for (var zone in audit.moyenneTensionZones) {
    if (zone.nom == localisation || localisation.contains(zone.nom)) {
      for (var coffret in zone.coffrets) {
        addCoffret(coffret);
      }
    }
  }

  for (var zone in audit.basseTensionZones) {
    if (zone.nom == localisation || localisation.contains(zone.nom)) {
      for (var coffret in zone.coffretsDirects) {
        addCoffret(coffret);
      }
      for (var local in zone.locaux) {
        if (localisation.contains(local.nom)) {
          for (var coffret in local.coffrets) {
            addCoffret(coffret);
          }
        }
      }
    }
  }

  return equipements;
}

/// Récupérer tous les équipements structurés de la mission pour les essais d'isolement
static List<EquipementIsolementItem> getAllEquipementsIsolementForMission(String missionId) {
  final audit = getAuditInstallationsByMissionId(missionId);
  if (audit == null) return [];

  final items = <EquipementIsolementItem>[];

  void addCoffretItem(CoffretArmoire coffret, String repereName, {String zoneName = ''}) {
    final typeStr = coffret.type.trim();
    final nomStr = coffret.nom.trim();
    if (nomStr.isEmpty) return;

    String formattedName;
    if (typeStr.isNotEmpty && !nomStr.toUpperCase().contains(typeStr.toUpperCase())) {
      formattedName = '$typeStr - $nomStr';
    } else {
      formattedName = nomStr;
    }

    final id = coffret.qrCode.isNotEmpty
        ? coffret.qrCode
        : (coffret.numeroEquipement != null && coffret.numeroEquipement!.isNotEmpty
            ? coffret.numeroEquipement!
            : '${repereName}_$formattedName');

    // Section Point A : Origine de la source d'alimentation
    String? secA;
    for (var ali in coffret.alimentations) {
      if (ali.sectionCable.trim().isNotEmpty) {
        secA = ali.sectionCable.trim();
        break;
      }
    }

    // Section Point B : Protection de tête (Coffret/Armoire) ou Sortie inverseur (Inverseur)
    String? secB;
    if (typeStr.toUpperCase() == 'INVERSEUR') {
      final sorties = coffret.sortiesInverseur;
      if (sorties.isNotEmpty && sorties.first.sectionCable.trim().isNotEmpty) {
        secB = sorties.first.sectionCable.trim();
      }
    } else {
      if (coffret.protectionTete != null && coffret.protectionTete!.sectionCable.trim().isNotEmpty) {
        secB = coffret.protectionTete!.sectionCable.trim();
      }
    }

    items.add(EquipementIsolementItem(
      id: id,
      nom: formattedName,
      type: typeStr.isNotEmpty ? typeStr : 'Coffret/Armoire',
      repere: repereName,
      zone: zoneName,
      sectionPointA: secA,
      sectionPointB: secB,
    ));
  }

  void addCelluleItem(Cellule cellule, String repereName, {String zoneName = ''}) {
    final nomStr = (cellule.nom != null && cellule.nom!.trim().isNotEmpty)
        ? cellule.nom!.trim()
        : 'Cellule ${cellule.fonction}';
    final id = (cellule.syncId != null && cellule.syncId!.isNotEmpty)
        ? cellule.syncId!
        : '${repereName}_$nomStr';
    final sec = (cellule.sectionCables != null && cellule.sectionCables!.trim().isNotEmpty)
        ? cellule.sectionCables!.trim()
        : null;

    items.add(EquipementIsolementItem(
      id: id,
      nom: nomStr,
      type: 'Cellule MT',
      repere: repereName,
      zone: zoneName,
      sectionPointA: sec,
      sectionPointB: sec,
    ));
  }

  void addTransfoItem(TransformateurMTBT transfo, String repereName, {String zoneName = ''}) {
    final nomStr = transfo.marqueAnnee.trim().isNotEmpty
        ? 'Transfo ${transfo.marqueAnnee.trim()}'
        : 'Transformateur MT/BT';
    final id = (transfo.syncId != null && transfo.syncId!.isNotEmpty)
        ? transfo.syncId!
        : '${repereName}_$nomStr';
    final sec = (transfo.sectionCables != null && transfo.sectionCables!.trim().isNotEmpty)
        ? transfo.sectionCables!.trim()
        : null;

    items.add(EquipementIsolementItem(
      id: id,
      nom: nomStr,
      type: 'Transformateur MT/BT',
      repere: repereName,
      zone: zoneName,
      sectionPointA: sec,
      sectionPointB: sec,
    ));
  }

  // Moyenne Tension Locaux
  for (var local in audit.moyenneTensionLocaux) {
    final rep = local.nom.trim();
    for (var c in local.coffrets) {
      addCoffretItem(c, rep);
    }
    for (var cell in local.cellules) {
      addCelluleItem(cell, rep);
    }
    for (var tr in local.transformateurs) {
      addTransfoItem(tr, rep);
    }
  }

  // Moyenne Tension Zones
  for (var zone in audit.moyenneTensionZones) {
    final repZone = zone.nom.trim();
    for (var c in zone.coffrets) {
      addCoffretItem(c, repZone, zoneName: repZone);
    }
    for (var local in zone.locaux) {
      final repLocal = local.nom.trim();
      for (var c in local.coffrets) {
        addCoffretItem(c, repLocal, zoneName: repZone);
      }
      for (var cell in local.cellules) {
        addCelluleItem(cell, repLocal, zoneName: repZone);
      }
      for (var tr in local.transformateurs) {
        addTransfoItem(tr, repLocal, zoneName: repZone);
      }
    }
  }

  // Basse Tension Zones & Locaux
  for (var zone in audit.basseTensionZones) {
    final repZone = zone.nom.trim();
    for (var c in zone.coffretsDirects) {
      addCoffretItem(c, repZone, zoneName: repZone);
    }
    for (var local in zone.locaux) {
      final repLocal = local.nom.trim();
      for (var c in local.coffrets) {
        addCoffretItem(c, repLocal, zoneName: repZone);
      }
      for (var cell in local.cellules) {
        addCelluleItem(cell, repLocal, zoneName: repZone);
      }
      for (var tr in local.transformateurs) {
        addTransfoItem(tr, repLocal, zoneName: repZone);
      }
    }
  }

  return items;
}

// ============================================================
//          SECTION 4: TEST CPI (CONTRÔLEUR PERMANENT D'ISOLEMENT)
// ============================================================

/// Ajouter un test CPI
static Future<bool> addCpiTest({
  required String missionId,
  required CpiTest test,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.cpiTests.add(test);
    await saveMesuresEssais(mesures);
    if (kDebugMode) print('✅ Test CPI ajouté: ${test.equipmentNom}');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addCpiTest: $e');
    return false;
  }
}

/// Mettre à jour un test CPI existant
static Future<bool> updateCpiTest({
  required String missionId,
  required CpiTest test,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    final idx = mesures.cpiTests.indexWhere((t) => t.id == test.id);
    if (idx != -1) {
      mesures.cpiTests[idx] = test;
      await saveMesuresEssais(mesures);
      if (kDebugMode) print('✅ Test CPI mis à jour: ${test.equipmentNom}');
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateCpiTest: $e');
    return false;
  }
}

/// Supprimer un test CPI (supprime uniquement l'entité CpiTest, pas l'équipement ni le transformateur)
static Future<bool> deleteCpiTest({
  required String missionId,
  required String testId,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    final initialCount = mesures.cpiTests.length;
    mesures.cpiTests.removeWhere((t) => t.id == testId);
    if (mesures.cpiTests.length < initialCount) {
      await saveMesuresEssais(mesures);
      if (kDebugMode) print('✅ Test CPI supprimé: $testId');
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur deleteCpiTest: $e');
    return false;
  }
}

/// Récupérer tous les tests CPI d'une mission
static List<CpiTest> getCpiTestsForMission(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  return mesures?.cpiTests ?? [];
}

/// Récupérer tous les équipements éligibles aux tests CPI pour une mission
static List<CpiEligibleEquipment> getCpiEligibleEquipementsForMission(String missionId) {
  final audit = getAuditInstallationsByMissionId(missionId);
  if (audit == null) return [];

  final transfoOptions = getAllTransformateurOptionsForMission(missionId);
  final transfoMap = <String, MissionTransformateurOption>{};
  for (final opt in transfoOptions) {
    transfoMap[opt.id] = opt;
    if (opt.transformateur.syncId != null && opt.transformateur.syncId!.trim().isNotEmpty) {
      transfoMap[opt.transformateur.syncId!.trim()] = opt;
    }
  }

  final results = <CpiEligibleEquipment>[];
  final seenIds = <String>{};

  void checkAndAddCoffret(CoffretArmoire coffret, String repereName, {String zoneName = ''}) {
    final nomStr = coffret.nom.trim();
    if (nomStr.isEmpty) return;

    final typeStr = coffret.type.trim();
    String formattedName;
    if (typeStr.isNotEmpty && !nomStr.toUpperCase().contains(typeStr.toUpperCase())) {
      formattedName = '$typeStr - $nomStr';
    } else {
      formattedName = nomStr;
    }

    final id = coffret.qrCode.isNotEmpty
        ? coffret.qrCode
        : (coffret.numeroEquipement != null && coffret.numeroEquipement!.isNotEmpty
            ? coffret.numeroEquipement!
            : '${repereName}_$formattedName');

    if (!seenIds.add(id)) return;

    // Analyse du transformateur et de l'antériorité
    final transfoId = coffret.transformateurId?.trim();
    if (transfoId != null && transfoId.isNotEmpty) {
      final opt = transfoMap[transfoId];
      if (opt != null) {
        final regime = opt.transformateur.regimeNeutre.trim().toUpperCase();
        if (regime == 'IT') {
          results.add(CpiEligibleEquipment(
            id: id,
            equipmentNom: formattedName,
            type: typeStr.isNotEmpty ? typeStr : 'Coffret/Armoire',
            repere: repereName,
            zone: zoneName,
            transformateurId: opt.id,
            transformateurNom: opt.transformerName,
            isHistorical: false,
          ));
        }
      } else {
        // Le transfo renseigné n'est plus trouvé dans les options actuelles :
        // Si l'équipement est antérieur à l'évolution, on le préserve
        final isOld = coffret.createdAt == null || coffret.createdAt!.isBefore(kCpiEvolutionCutoff);
        if (isOld) {
          results.add(CpiEligibleEquipment(
            id: id,
            equipmentNom: formattedName,
            type: typeStr.isNotEmpty ? typeStr : 'Coffret/Armoire',
            repere: repereName,
            zone: zoneName,
            transformateurId: transfoId,
            transformateurNom: null,
            isHistorical: true,
          ));
        }
      }
    } else {
      // Aucun transformateur lié : éligible uniquement s'il est antérieur à l'évolution
      final isOld = coffret.createdAt == null || coffret.createdAt!.isBefore(kCpiEvolutionCutoff);
      if (isOld) {
        results.add(CpiEligibleEquipment(
          id: id,
          equipmentNom: formattedName,
          type: typeStr.isNotEmpty ? typeStr : 'Coffret/Armoire',
          repere: repereName,
          zone: zoneName,
          transformateurId: null,
          transformateurNom: null,
          isHistorical: true,
        ));
      }
    }
  }

  // Moyenne Tension Locaux
  for (var local in audit.moyenneTensionLocaux) {
    final rep = local.nom.trim();
    for (var c in local.coffrets) {
      checkAndAddCoffret(c, rep);
    }
  }

  // Moyenne Tension Zones
  for (var zone in audit.moyenneTensionZones) {
    final repZone = zone.nom.trim();
    for (var c in zone.coffrets) {
      checkAndAddCoffret(c, repZone, zoneName: repZone);
    }
    for (var local in zone.locaux) {
      final repLocal = local.nom.trim();
      for (var c in local.coffrets) {
        checkAndAddCoffret(c, repLocal, zoneName: repZone);
      }
    }
  }

  // Basse Tension Zones & Locaux
  for (var zone in audit.basseTensionZones) {
    final repZone = zone.nom.trim();
    for (var c in zone.coffretsDirects) {
      checkAndAddCoffret(c, repZone, zoneName: repZone);
    }
    for (var local in zone.locaux) {
      final repLocal = local.nom.trim();
      for (var c in local.coffrets) {
        checkAndAddCoffret(c, repLocal, zoneName: repZone);
      }
    }
  }

  return results;
}

// ============================================================
//          SECTION 7: CONTINUITÉ ET RÉSISTANCE
// ============================================================

/// Ajouter une mesure de continuité et résistance
static Future<bool> addContinuiteResistance({
  required String missionId,
  required ContinuiteResistance mesure,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.continuiteResistances.add(mesure);
    await saveMesuresEssais(mesures);
    if (kDebugMode) print('✅ Continuité/résistance ajoutée: ${mesure.designationTableau}');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addContinuiteResistance: $e');
    return false;
  }
}

/// Mettre à jour une mesure de continuité et résistance existante
static Future<bool> updateContinuiteResistance({
  required String missionId,
  required int index,
  required ContinuiteResistance mesure,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.continuiteResistances.length) {
      mesures.continuiteResistances[index] = mesure;
      await saveMesuresEssais(mesures);
      if (kDebugMode) print('✅ Continuité/résistance mise à jour: ${mesure.designationTableau}');
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateContinuiteResistance: $e');
    return false;
  }
}

/// Supprimer une mesure de continuité et résistance
static Future<bool> deleteContinuiteResistance({
  required String missionId,
  required int index,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.continuiteResistances.length) {
      final mesure = mesures.continuiteResistances.removeAt(index);
      await saveMesuresEssais(mesures);
      if (kDebugMode) {
        print('✅ Continuité/résistance supprimée: ${mesure.designationTableau}');
      }
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteContinuiteResistance: $e');
    }
    return false;
  }
}

/// Récupérer toutes les mesures de continuité et résistance d'une mission
static List<ContinuiteResistance> getContinuiteResistances(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  return mesures?.continuiteResistances ?? [];
}

// ============================================================
//          MÉTHODES UTILITAIRES MESURES ESSAIS
// ============================================================

/// Obtenir les options pour les types de dispositifs différentiels
static List<String> getTypesDispositifDifferentiel() {
  return ['Disjoncteur différentiel', 'Interrupteur différentiel'];
}

/// Obtenir les options pour les résultats d'essai
static List<String> getResultatsEssai() {
  return ['OK', 'NON OK', 'NE'];
}

/// Obtenir les options pour les statuts des prises de terre
static List<String> getStatutsPriseTerre() {
  return ['Satisfaisant', 'Non satisfaisant', 'Non accessible'];
}

/// Obtenir les options pour les statuts de continuité
static List<String> getStatutsContinuite() {
  return ['Conforme', 'Non conforme'];
}

/// Obtenir les natures de prise de terre courantes
static List<String> getNaturesPriseTerre() {
  return [
    'Boucle en fond de fouille',
    'Piquet de terre',
    'Plaque de terre',
    'Fond de fouille interconnecté',
    'Autre',
  ];
}

/// Obtenir les méthodes de mesure courantes
static List<String> getMethodesMesure() {
  return [
    'Impédance de boucle',
    'Résistance de terre',
    'Méthode des 62%',
    'Méthode de chute de potentiel',
    'Autre',
  ];
}

/// Supprimer toutes les mesures et essais d'une mission
static Future<bool> deleteAllMesuresEssaisForMission(String missionId) async {
  try {
    final mesures = getMesuresEssaisByMissionId(missionId);
    if (mesures != null) {
      await mesures.delete();
      
      // Supprimer la référence dans la mission
      final missionBox = Hive.box<Mission>(_missionBox);
      final mission = missionBox.get(missionId);
      if (mission != null) {
        mission.mesuresEssaisId = null;
        await mission.save();
      }
      
      if (kDebugMode) {
        print('✅ Toutes les mesures et essais supprimés pour mission $missionId');
      }
      return true;
    }
    return true; // Aucune donnée à supprimer
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteAllMesuresEssaisForMission: $e');
    }
    return false;
  }
}

/// Vérifier si les mesures et essais sont complets
static Map<String, bool> checkMesuresEssaisCompletion(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  if (mesures == null) {
    return {
      'condition_mesure': false,
      'demarrage_auto': false,
      'arret_urgence': false,
      'prises_terre': false,
      'avis_mesures': false,
      'essais_differ': false,
      'essais_isolement': false,
      'continuites': false,
    };
  }
  
  final stats = mesures.calculerStatistiques();
  
  return {
    'condition_mesure': stats['condition_mesure_renseignee'] as bool,
    'demarrage_auto': stats['demarrage_auto_renseigne'] as bool,
    'arret_urgence': stats['arret_urgence_renseigne'] as bool,
    'prises_terre': (mesures.prisesTerre.isNotEmpty),
    'avis_mesures': stats['avis_mesures_renseigne'] as bool,
    'essais_differ': (mesures.essaisDeclenchement.isNotEmpty),
    'essais_isolement': (mesures.essaisIsolement.isNotEmpty),
    'continuites': (mesures.continuiteResistances.isNotEmpty),
  };
}

/// Obtenir le pourcentage de complétion global
static int getMesuresEssaisCompletionPercentage(String missionId) {
  final completion = checkMesuresEssaisCompletion(missionId);
  final sections = completion.values;
  final completed = sections.where((isComplete) => isComplete).length;
  
  return (completed / sections.length * 100).round();
}

/// Écouter les changements dans les mesures et essais d'une mission
static ValueListenable<Box<MesuresEssais>> watchMesuresEssais(String missionId) {
  final box = Hive.box<MesuresEssais>(_mesuresEssaisBox);
  return box.listenable();
}

/// Créer des données de test pour une mission
static Future<void> createTestMesuresEssais(String missionId) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    
    // Ajouter quelques prises de terre d'exemple
    mesures.prisesTerre.addAll([
      PriseTerre(
        localisation: 'Extérieur',
        identification: 'PT1',
        conditionPriseTerre: '-',
        naturePriseTerre: 'Boucle en fond de fouille',
        methodeMesure: 'Impédance de boucle',
        valeurMesure: 10.93,
        observation: 'Satisfaisant',
      ),
      PriseTerre(
        localisation: 'Local GE',
        identification: 'PT3',
        conditionPriseTerre: '-',
        naturePriseTerre: 'Boucle en fond de fouille',
        methodeMesure: 'Impédance de boucle',
        valeurMesure: 187.5,
        observation: 'Non satisfaisant',
      ),
    ]);
    
    // Mettre à jour automatiquement l'avis
    mesures.avisMesuresTerre.observation = 'Prévoir un plan d\'exécution\nRenforcer l\'interconnexion avec le réseau de fond de fouille';
    
    // Ajouter quelques essais différentiels
    final localisations = getLocalisationsForEssais(missionId);
    if (localisations.isNotEmpty) {
      mesures.essaisDeclenchement.add(
        EssaiDeclenchementDifferentiel(
          localisation: localisations.first,
          designationCircuit: 'Circuit éclairage bureau',
          typeDispositif: 'DDR',
          reglageIAn: 30,
          tempo: 0.3,
          isolement: 500,
          essai: 'B',
          observation: 'Bon fonctionnement',
        ),
      );
    }
    
    await saveMesuresEssais(mesures);
    if (kDebugMode) {
      print('✅ Données de test créées pour mesures et essais');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur createTestMesuresEssais: $e');
    }
  }
}

// ============================================================
//          GESTION OBSERVATIONS LIBRES AVEC PHOTOS
// ============================================================

/// Ajouter une observation libre avec photos à un local moyenne tension
static Future<bool> addObservationToMoyenneTensionLocal({
  required String missionId,
  required int localIndex,
  required String texte,
  List<String>? photos,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (localIndex < audit.moyenneTensionLocaux.length) {
      final local = audit.moyenneTensionLocaux[localIndex];
      local.observationsLibres.add(ObservationLibre(
        texte: texte,
        photos: photos ?? [],
      ));
      await saveAuditInstallations(audit);
      if (kDebugMode) {
        print('✅ Observation ajoutée au local MT: ${local.nom}');
      }
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur addObservationToMoyenneTensionLocal: $e');
    }
    return false;
  }
}

/// Ajouter une observation libre avec photos à une zone moyenne tension
static Future<bool> addObservationToMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
  required String texte,
  List<String>? photos,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.moyenneTensionZones.length) {
      final zone = audit.moyenneTensionZones[zoneIndex];
      zone.observationsLibres.add(ObservationLibre(
        texte: texte,
        photos: photos ?? [],
      ));
      await saveAuditInstallations(audit);
      if (kDebugMode) {
        print('✅ Observation ajoutée à la zone MT: ${zone.nom}');
      }
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur addObservationToMoyenneTensionZone: $e');
    }
    return false;
  }
}

/// Ajouter une observation libre avec photos à une zone basse tension
static Future<bool> addObservationToBasseTensionZone({
  required String missionId,
  required int zoneIndex,
  required String texte,
  List<String>? photos,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.basseTensionZones.length) {
      final zone = audit.basseTensionZones[zoneIndex];
      zone.observationsLibres.add(ObservationLibre(
        texte: texte,
        photos: photos ?? [],
      ));
      await saveAuditInstallations(audit);
      if (kDebugMode) {
        print('✅ Observation ajoutée à la zone BT: ${zone.nom}');
      }
      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur addObservationToBasseTensionZone: $e');
    }
    return false;
  }
}

/// Ajouter une observation libre avec photos à un local basse tension
static Future<bool> addObservationToBasseTensionLocal({
  required String missionId,
  required int zoneIndex,
  required int localIndex,
  required String texte,
  List<String>? photos,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.basseTensionZones.length) {
      final zone = audit.basseTensionZones[zoneIndex];
      if (localIndex < zone.locaux.length) {
        final local = zone.locaux[localIndex];
        local.observationsLibres.add(ObservationLibre(
          texte: texte,
          photos: photos ?? [],
        ));
        await saveAuditInstallations(audit);
        if (kDebugMode) {
          print('✅ Observation ajoutée au local BT: ${local.nom}');
        }
        return true;
      }
    }
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur addObservationToBasseTensionLocal: $e');
    }
    return false;
  }
}

/// Ajouter une observation libre avec photos à un coffret/armoire
static Future<bool> addObservationToCoffret({
  required String missionId,
  required CoffretArmoire coffret,
  required String texte,
  List<String>? photos,
}) async {
  try {
    // Chercher le coffret dans l'audit
    final audit = await getOrCreateAuditInstallations(missionId);
    bool found = false;
    
    // Chercher dans les locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      final index = local.coffrets.indexWhere((c) => c.equipmentId == coffret.equipmentId || (c.nom == coffret.nom && c.type == coffret.type));
      if (index != -1) {
        local.coffrets[index].observationsLibres.add(ObservationLibre(
          texte: texte,
          photos: photos ?? [],
        ));
        found = true;
        break;
      }
    }
    
    // Chercher dans les zones MT
    if (!found) {
      for (var zone in audit.moyenneTensionZones) {
        final index = zone.coffrets.indexWhere((c) => c.equipmentId == coffret.equipmentId || (c.nom == coffret.nom && c.type == coffret.type));
        if (index != -1) {
          zone.coffrets[index].observationsLibres.add(ObservationLibre(
            texte: texte,
            photos: photos ?? [],
          ));
          found = true;
          break;
        }
      }
    }
    
    // Chercher dans les zones BT (coffrets directs)
    if (!found) {
      for (var zone in audit.basseTensionZones) {
        final index = zone.coffretsDirects.indexWhere((c) => c.equipmentId == coffret.equipmentId || (c.nom == coffret.nom && c.type == coffret.type));
        if (index != -1) {
          zone.coffretsDirects[index].observationsLibres.add(ObservationLibre(
            texte: texte,
            photos: photos ?? [],
          ));
          found = true;
          break;
        }
        
        // Chercher dans les locaux BT
        for (var local in zone.locaux) {
          final index = local.coffrets.indexWhere((c) => c.equipmentId == coffret.equipmentId || (c.nom == coffret.nom && c.type == coffret.type));
          if (index != -1) {
            local.coffrets[index].observationsLibres.add(ObservationLibre(
              texte: texte,
              photos: photos ?? [],
            ));
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (found) {
      await saveAuditInstallations(audit);
      if (kDebugMode) {
        print('✅ Observation ajoutée au coffret: ${coffret.nom}');
      }
      return true;
    }
    
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur addObservationToCoffret: $e');
    }
    return false;
  }
}

/// Mettre à jour une observation libre existante
static Future<bool> updateObservationLibre({
  required String missionId,
  required ObservationLibre observation,
  required String newTexte,
  List<String>? newPhotos,
  String? pointVerificationKey,
  String? referenceNormative,
  String? familleRisque,
  String? criticite,
}) async {
  try {
    observation.updateTexte(newTexte);
    if (newPhotos != null) {
      observation.photos = newPhotos;
    }
    if (pointVerificationKey != null) observation.pointVerificationKey = pointVerificationKey;
    if (referenceNormative != null) observation.referenceNormative = referenceNormative;
    if (familleRisque != null) observation.familleRisque = familleRisque;
    if (criticite != null) observation.criticite = criticite;
    
    // Sauvegarder l'audit
    final audit = await getOrCreateAuditInstallations(missionId);
    await saveAuditInstallations(audit);
    
    if (kDebugMode) {
      print('✅ Observation mise à jour');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur updateObservationLibre: $e');
    }
    return false;
  }
}

/// Supprimer une observation libre d'un local/zone/coffret
static Future<bool> deleteObservationLibre({
  required String missionId,
  required dynamic parent, // Peut être MoyenneTensionLocal, MoyenneTensionZone, etc.
  required ObservationLibre observation,
}) async {
  try {
    if (parent is MoyenneTensionLocal) {
      parent.observationsLibres.remove(observation);
    } else if (parent is MoyenneTensionZone) {
      parent.observationsLibres.remove(observation);
    } else if (parent is BasseTensionZone) {
      parent.observationsLibres.remove(observation);
    } else if (parent is BasseTensionLocal) {
      parent.observationsLibres.remove(observation);
    } else if (parent is CoffretArmoire) {
      parent.observationsLibres.remove(observation);
    } else {
      if (kDebugMode) {
        print('❌ Type de parent non supporté');
      }
      return false;
    }
    
    // Sauvegarder l'audit
    final audit = await getOrCreateAuditInstallations(missionId);
    await saveAuditInstallations(audit);
    
    if (kDebugMode) {
      print('✅ Observation supprimée');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteObservationLibre: $e');
    }
    return false;
  }
}

/// Ajouter une photo à une observation existante
static Future<bool> addPhotoToObservation({
  required String missionId,
  required ObservationLibre observation,
  required String cheminPhoto,
}) async {
  try {
    observation.addPhoto(cheminPhoto);
    
    // Sauvegarder l'audit
    final audit = await getOrCreateAuditInstallations(missionId);
    await saveAuditInstallations(audit);
    
    if (kDebugMode) {
      print('✅ Photo ajoutée à l\'observation');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur addPhotoToObservation: $e');
    }
    return false;
  }
}

/// Supprimer une photo d'une observation
static Future<bool> removePhotoFromObservation({
  required String missionId,
  required ObservationLibre observation,
  required String cheminPhoto,
}) async {
  try {
    observation.removePhoto(cheminPhoto);
    
    // Sauvegarder l'audit
    final audit = await getOrCreateAuditInstallations(missionId);
    await saveAuditInstallations(audit);
    
    if (kDebugMode) {
      print('✅ Photo supprimée de l\'observation');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur removePhotoFromObservation: $e');
    }
    return false;
  }
}

/// Récupérer toutes les observations d'une mission
static List<Map<String, dynamic>> getAllObservationsForMission(String missionId) {
  try {
    final audit = getAuditInstallationsByMissionId(missionId);
    if (audit == null) return [];
    
    final observations = <Map<String, dynamic>>[];
    
    // Collecter les observations des locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      for (var obs in local.observationsLibres) {
        observations.add({
          'type': 'localMT',
          'entityName': local.nom,
          'entityType': local.type,
          'observation': obs,
          'photos': obs.photos,
          'dateCreation': obs.dateCreation,
          'dateModification': obs.dateModification,
        });
      }
    }
    
    // Collecter les observations des zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var obs in zone.observationsLibres) {
        observations.add({
          'type': 'zoneMT',
          'entityName': zone.nom,
          'observation': obs,
          'photos': obs.photos,
          'dateCreation': obs.dateCreation,
          'dateModification': obs.dateModification,
        });
      }
    }
    
    // Collecter les observations des zones BT
    for (var zone in audit.basseTensionZones) {
      for (var obs in zone.observationsLibres) {
        observations.add({
          'type': 'zoneBT',
          'entityName': zone.nom,
          'observation': obs,
          'photos': obs.photos,
          'dateCreation': obs.dateCreation,
          'dateModification': obs.dateModification,
        });
      }
    }
    
    // Collecter les observations des locaux BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        for (var obs in local.observationsLibres) {
          observations.add({
            'type': 'localBT',
            'entityName': '${zone.nom} - ${local.nom}',
            'zoneName': zone.nom,
            'localName': local.nom,
            'observation': obs,
            'photos': obs.photos,
            'dateCreation': obs.dateCreation,
            'dateModification': obs.dateModification,
          });
        }
      }
    }
    
    // Collecter les observations des coffrets
    // (à implémenter si nécessaire)
    
    return observations;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getAllObservationsForMission: $e');
    }
    return [];
  }
}

/// Obtenir les statistiques des observations pour une mission
static Map<String, dynamic> getObservationStats(String missionId) {
  final allObservations = getAllObservationsForMission(missionId);
  
  final total = allObservations.length;
  final avecPhotos = allObservations.where((obs) => (obs['photos'] as List<String>).isNotEmpty).length;
  
  // Compter par type d'entité
  final byType = {
    'localMT': allObservations.where((obs) => obs['type'] == 'localMT').length,
    'zoneMT': allObservations.where((obs) => obs['type'] == 'zoneMT').length,
    'zoneBT': allObservations.where((obs) => obs['type'] == 'zoneBT').length,
    'localBT': allObservations.where((obs) => obs['type'] == 'localBT').length,
  };
  
  return {
    'total': total,
    'avec_photos': avecPhotos,
    'sans_photos': total - avecPhotos,
    'par_type': byType,
    'pourcentage_avec_photos': total > 0 ? (avecPhotos / total * 100).round() : 0,
  };
}

/// Convertir les anciennes observations (String) en nouvelles (ObservationLibre)
static Future<bool> migrateOldObservations(String missionId) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    bool migrated = false;
    
    // Migrer les locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      // Vérifier si c'est l'ancien type (List<String>)
      if (local.observationsLibres is List<String>) {
        final oldObservations = local.observationsLibres as List<String>;
        final newObservations = <ObservationLibre>[];
        
        for (var text in oldObservations) {
          newObservations.add(ObservationLibre(texte: text));
        }
        
        local.observationsLibres = newObservations;
        migrated = true;
      }
    }
    
    // Migrer les zones MT
    for (var zone in audit.moyenneTensionZones) {
      if (zone.observationsLibres is List<String>) {
        final oldObservations = zone.observationsLibres as List<String>;
        final newObservations = <ObservationLibre>[];
        
        for (var text in oldObservations) {
          newObservations.add(ObservationLibre(texte: text));
        }
        
        zone.observationsLibres = newObservations;
        migrated = true;
      }
    }
    
    // Migrer les zones BT
    for (var zone in audit.basseTensionZones) {
      if (zone.observationsLibres is List<String>) {
        final oldObservations = zone.observationsLibres as List<String>;
        final newObservations = <ObservationLibre>[];
        
        for (var text in oldObservations) {
          newObservations.add(ObservationLibre(texte: text));
        }
        
        zone.observationsLibres = newObservations;
        migrated = true;
      }
    }
    
    // Migrer les locaux BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        if (local.observationsLibres is List<String>) {
          final oldObservations = local.observationsLibres as List<String>;
          final newObservations = <ObservationLibre>[];
          
          for (var text in oldObservations) {
            newObservations.add(ObservationLibre(texte: text));
          }
          
          local.observationsLibres = newObservations;
          migrated = true;
        }
      }
    }
    
    // Migrer les coffrets
    // (à implémenter si nécessaire)
    
    if (migrated) {
      await saveAuditInstallations(audit);
      if (kDebugMode) {
        print('✅ Anciennes observations migrées pour mission $missionId');
      }
    } else {
      if (kDebugMode) {
        print('✅ Aucune migration nécessaire');
      }
    }
    
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur migrateOldObservations: $e');
    }
    return false;
  }
}

// ============================================================
//          GESTION PHOTOS DES ÉLÉMENTS DE CONTRÔLE
// ============================================================

/// Ajouter une photo à un élément de contrôle spécifique
static Future<bool> addPhotoToElementControle({
  required String missionId,
  required String localisation, // Nom du local ou zone
  required int elementIndex,
  required String cheminPhoto,
  required String sectionType, // 'dispositions', 'conditions', 'cellule', 'transformateur'
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    bool found = false;
    
    // Chercher le local par son nom
    for (var local in audit.moyenneTensionLocaux) {
      if (local.nom == localisation) {
        found = _processElementPhotos(local, elementIndex, cheminPhoto, sectionType);
        break;
      }
    }
    
    if (!found) {
      // Chercher dans les zones MT
      for (var zone in audit.moyenneTensionZones) {
        for (var local in zone.locaux) {
          if (local.nom == localisation) {
            found = _processElementPhotos(local, elementIndex, cheminPhoto, sectionType);
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (!found) {
      // Chercher dans les zones BT
      for (var zone in audit.basseTensionZones) {
        for (var local in zone.locaux) {
          if (local.nom == localisation) {
            found = _processElementPhotos(local, elementIndex, cheminPhoto, sectionType);
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (found) {
      await saveAuditInstallations(audit);
      if (kDebugMode) {
        print('✅ Photo ajoutée à l\'élément $elementIndex');
      }
      return true;
    }
    
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur addPhotoToElementControle: $e');
    }
    return false;
  }
}

/// Traiter les photos pour un élément spécifique
static bool _processElementPhotos(
  dynamic local, // MoyenneTensionLocal ou BasseTensionLocal
  int elementIndex,
  String cheminPhoto,
  String sectionType,
) {
  List<ElementControle> elements;
  
  switch (sectionType) {
    case 'dispositions':
      elements = local.dispositionsConstructives;
      break;
    case 'conditions':
      elements = local.conditionsExploitation;
      break;
    case 'cellule':
      if (local is MoyenneTensionLocal && local.cellule != null) {
        elements = local.cellule!.elementsVerifies;
      } else {
        return false;
      }
      break;
    case 'transformateur':
      if (local is MoyenneTensionLocal && local.transformateur != null) {
        elements = local.transformateur!.elementsVerifies;
      } else {
        return false;
      }
      break;
    default:
      return false;
  }
  
  if (elementIndex < elements.length) {
    elements[elementIndex].photos.add(cheminPhoto);
    return true;
  }
  
  return false;
}

/// Supprimer une photo d'un élément de contrôle
static Future<bool> removePhotoFromElementControle({
  required String missionId,
  required String localisation,
  required int elementIndex,
  required int photoIndex,
  required String sectionType,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    bool found = false;
    
    // Chercher le local par son nom
    for (var local in audit.moyenneTensionLocaux) {
      if (local.nom == localisation) {
        found = _removeElementPhoto(local, elementIndex, photoIndex, sectionType);
        break;
      }
    }
    
    if (!found) {
      // Chercher dans les zones MT
      for (var zone in audit.moyenneTensionZones) {
        for (var local in zone.locaux) {
          if (local.nom == localisation) {
            found = _removeElementPhoto(local, elementIndex, photoIndex, sectionType);
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (!found) {
      // Chercher dans les zones BT
      for (var zone in audit.basseTensionZones) {
        for (var local in zone.locaux) {
          if (local.nom == localisation) {
            found = _removeElementPhoto(local, elementIndex, photoIndex, sectionType);
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (found) {
      await saveAuditInstallations(audit);
      if (kDebugMode) {
        print('✅ Photo supprimée de l\'élément $elementIndex');
      }
      return true;
    }
    
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur removePhotoFromElementControle: $e');
    }
    return false;
  }
}

static bool _removeElementPhoto(
  dynamic local,
  int elementIndex,
  int photoIndex,
  String sectionType,
) {
  List<ElementControle> elements;
  
  switch (sectionType) {
    case 'dispositions':
      elements = local.dispositionsConstructives;
      break;
    case 'conditions':
      elements = local.conditionsExploitation;
      break;
    case 'cellule':
      if (local is MoyenneTensionLocal && local.cellule != null) {
        elements = local.cellule!.elementsVerifies;
      } else {
        return false;
      }
      break;
    case 'transformateur':
      if (local is MoyenneTensionLocal && local.transformateur != null) {
        elements = local.transformateur!.elementsVerifies;
      } else {
        return false;
      }
      break;
    default:
      return false;
  }
  
  if (elementIndex < elements.length && 
      photoIndex < elements[elementIndex].photos.length) {
    elements[elementIndex].photos.removeAt(photoIndex);
    return true;
  }
  
  return false;
}

/// Récupérer toutes les photos des éléments non conformes pour une mission
static List<Map<String, dynamic>> getAllElementPhotos(String missionId) {
  try {
    final audit = getAuditInstallationsByMissionId(missionId);
    if (audit == null) return [];
    
    final allPhotos = <Map<String, dynamic>>[];
    
    // Fonction pour collecter les photos
    void collectPhotos(List<ElementControle> elements, String source, String type) {
      for (int i = 0; i < elements.length; i++) {
        final element = elements[i];
        if (element.photos.isNotEmpty) {
          allPhotos.add({
            'element': element.elementControle,
            'photos': element.photos,
            'conforme': element.conforme,
            'priorite': element.priorite,
            'observation': element.observation,
            'source': source,
            'type': type,
            'elementIndex': i,
          });
        }
      }
    }
    
    // Parcourir tous les locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      collectPhotos(local.dispositionsConstructives, local.nom, 'dispositions_mt');
      collectPhotos(local.conditionsExploitation, local.nom, 'conditions_mt');
      
      if (local.cellule != null) {
        collectPhotos(local.cellule!.elementsVerifies, local.nom, 'cellule_mt');
      }
      
      if (local.transformateur != null) {
        collectPhotos(local.transformateur!.elementsVerifies, local.nom, 'transformateur_mt');
      }
    }
    
    // Parcourir les zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        collectPhotos(local.dispositionsConstructives, '${zone.nom}/${local.nom}', 'dispositions_mt_zone');
        collectPhotos(local.conditionsExploitation, '${zone.nom}/${local.nom}', 'conditions_mt_zone');
      }
    }
    
    // Parcourir les zones BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        collectPhotos(local.dispositionsConstructives!, '${zone.nom}/${local.nom}', 'dispositions_bt');
        collectPhotos(local.conditionsExploitation!, '${zone.nom}/${local.nom}', 'conditions_bt');
      }
    }
    
    return allPhotos;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getAllElementPhotos: $e');
    }
    return [];
  }
}

/// Obtenir les statistiques des photos
static Map<String, dynamic> getElementPhotosStats(String missionId) {
  final allPhotos = getAllElementPhotos(missionId);
  
  int totalPhotos = 0;
  final photosByType = <String, int>{};
  final nonConformeWithPhotos = allPhotos.where((p) => p['conforme'] == false).length;
  
  for (var item in allPhotos) {
    final photos = item['photos'] as List<String>;
    totalPhotos += photos.length;
    
    final type = item['type'] as String;
    photosByType[type] = (photosByType[type] ?? 0) + photos.length;
  }
  
  return {
    'total_elements_avec_photos': allPhotos.length,
    'total_photos': totalPhotos,
    'elements_non_conforme_avec_photos': nonConformeWithPhotos,
    'photos_par_type': photosByType,
  };
}

/// Sauvegarder un élément avec ses photos
static Future<void> saveElementWithPhotos({
  required String missionId,
  required String localisation,
  required ElementControle element,
  required int elementIndex,
  required String sectionType,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    // Chercher et mettre à jour l'élément
    bool updated = _updateElementInAudit(audit, localisation, element, elementIndex, sectionType);
    
    if (updated) {
      await saveAuditInstallations(audit);
      if (kDebugMode) {
        print('✅ Élément avec photos sauvegardé');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur saveElementWithPhotos: $e');
    }
    rethrow;
  }
}

static bool _updateElementInAudit(
  AuditInstallationsElectriques audit,
  String localisation,
  ElementControle element,
  int elementIndex,
  String sectionType,
) {
  // Chercher dans tous les locaux MT
  for (var local in audit.moyenneTensionLocaux) {
    if (local.nom == localisation) {
      return _replaceElement(local, element, elementIndex, sectionType);
    }
  }
  
  // Chercher dans les zones MT
  for (var zone in audit.moyenneTensionZones) {
    for (var local in zone.locaux) {
      if (local.nom == localisation) {
        return _replaceElement(local, element, elementIndex, sectionType);
      }
    }
  }
  
  // Chercher dans les zones BT
  for (var zone in audit.basseTensionZones) {
    for (var local in zone.locaux) {
      if (local.nom == localisation) {
        return _replaceElement(local, element, elementIndex, sectionType);
      }
    }
  }
  
  return false;
}

static bool _replaceElement(
  dynamic local,
  ElementControle element,
  int elementIndex,
  String sectionType,
) {
  List<ElementControle> elements;
  
  switch (sectionType) {
    case 'dispositions':
      elements = local.dispositionsConstructives;
      break;
    case 'conditions':
      elements = local.conditionsExploitation;
      break;
    case 'cellule':
      if (local is MoyenneTensionLocal && local.cellule != null) {
        elements = local.cellule!.elementsVerifies;
      } else {
        return false;
      }
      break;
    case 'transformateur':
      if (local is MoyenneTensionLocal && local.transformateur != null) {
        elements = local.transformateur!.elementsVerifies;
      } else {
        return false;
      }
      break;
    default:
      return false;
  }
  
  if (elementIndex < elements.length) {
    elements[elementIndex] = element;
    return true;
  }
  
  return false;
}

// ============================================================
//          GESTION CLASSEMENT POUR UN LOCAL SPÉCIFIQUE
// ============================================================

/// Créer ou récupérer le classement pour un local spécifique
static Future<ClassementEmplacement> getOrCreateClassementForLocal({
  required String missionId,
  required String localisation,
  String? zone,
  String? typeLocal,
}) async {
  final classementBox = Hive.box<ClassementEmplacement>(_classementBox);
  
  try {
    // Méthode 1: Chercher manuellement sans firstWhere
    ClassementEmplacement? existing;
    
    // Parcourir tous les classements pour trouver celui qui correspond
    for (var classement in classementBox.values) {
      if (classement.missionId == missionId && classement.localisation == localisation) {
        existing = classement;
        break;
      }
    }
    
    if (existing != null) {
      // Mettre à jour les informations si elles ont changé
      if (zone != null && existing.zone != zone) {
        existing.zone = zone;
      }
      if (typeLocal != null && existing.typeLocal != typeLocal) {
        existing.typeLocal = typeLocal;
      }
      if (zone != null || typeLocal != null) {
        existing.updatedAt = DateTime.now();
        await existing.save();
      }
      
      if (kDebugMode) {
        print('✅ Classement existant trouvé pour: $localisation');
      }
      return existing;
    } else {
      // Créer un nouveau classement
      final newClassement = ClassementEmplacement.create(
        missionId: missionId,
        localisation: localisation,
        zone: zone,
        typeLocal: typeLocal,
      );
      await classementBox.add(newClassement);
      if (kDebugMode) {
        print('✅ Nouveau classement créé pour: $localisation');
      }
      return newClassement;
    }
    
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getOrCreateClassementForLocal: $e');
    }
    // En cas d'erreur, créer une nouvelle instance
    final newClassement = ClassementEmplacement.create(
      missionId: missionId,
      localisation: localisation,
      zone: zone,
      typeLocal: typeLocal,
    );
    await classementBox.add(newClassement);
    return newClassement;
  }
}

/// Méthode plus simple pour récupérer seulement (pas de création)
static ClassementEmplacement? getClassementForLocal({
  required String missionId,
  required String localisation,
}) {
  final classementBox = Hive.box<ClassementEmplacement>(_classementBox);
  
  try {
    return classementBox.values.firstWhere(
      (c) => c.missionId == missionId && c.localisation == localisation,
    );
  } catch (e) {
    return null;
  }
}

/// Mettre à jour uniquement les informations de zone/type d'un classement existant
static Future<bool> updateClassementInfo({
  required String missionId,
  required String localisation,
  String? zone,
  String? typeLocal,
}) async {
  try {
    final classement = getClassementForLocal(
      missionId: missionId,
      localisation: localisation,
    );
    
    if (classement != null) {
      if (zone != null) classement.zone = zone;
      if (typeLocal != null) classement.typeLocal = typeLocal;
      
      if (zone != null || typeLocal != null) {
        classement.updatedAt = DateTime.now();
        await classement.save();
        if (kDebugMode) {
          print('✅ Informations classement mises à jour pour: $localisation');
        }
      }
      return true;
    }
    
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur updateClassementInfo: $e');
    }
    return false;
  }
}
/// Récupérer un classement existant sans en créer un nouveau
static ClassementEmplacement? getClassementExisting({
  required String missionId,
  required String localisation,
}) {
  try {
    final box = Hive.box<ClassementEmplacement>(_classementBox);
    return box.values.firstWhere(
      (c) => c.missionId == missionId && c.localisation == localisation,
    );
  } catch (e) {
    return null;
  }
}

// ============================================================
//          GESTION RENSEIGNEMENTS GENERAUX
// ============================================================

/// Créer ou récupérer les renseignements généraux pour une mission
// lib/services/hive_service.dart

// Dans getOrCreateRenseignementsGeneraux, ajouter la synchronisation :

/// Créer ou récupérer les renseignements généraux pour une mission
static Future<RenseignementsGeneraux> getOrCreateRenseignementsGeneraux(String missionId) async {
  final box = Hive.box<RenseignementsGeneraux>(_renseignementsGenerauxBox);
  final mission = getMissionById(missionId);
  
  try {
    // Chercher si des renseignements existent déjà pour cette mission
    final existing = box.values.firstWhere((r) => r.missionId == missionId);
    if (mission != null) {
      bool changed = false;
      if (existing.activiteSurSite == null && mission.activiteSurSite != null) {
        existing.activiteSurSite = mission.activiteSurSite;
        changed = true;
      }
      if (existing.classementReglementaire == null && mission.classementReglementaire != null) {
        existing.classementReglementaire = mission.classementReglementaire;
        changed = true;
      }
      if (existing.classementReglementaireType == null && mission.classementReglementaireType != null) {
        existing.classementReglementaireType = mission.classementReglementaireType;
        changed = true;
      }
      if (existing.classementReglementaireCategorie == null && mission.classementReglementaireCategorie != null) {
        existing.classementReglementaireCategorie = mission.classementReglementaireCategorie;
        changed = true;
      }
      if (existing.lieuIntervention == null && mission.lieuIntervention != null) {
        existing.lieuIntervention = mission.lieuIntervention;
        changed = true;
      }
      if (existing.recepteurRapport == null && mission.recepteurRapport != null) {
        existing.recepteurRapport = mission.recepteurRapport;
        changed = true;
      }
      if (existing.recepteurCivilite == null && mission.recepteurCivilite != null) {
        existing.recepteurCivilite = mission.recepteurCivilite;
        changed = true;
      }
      if (existing.recepteurNom == null && mission.recepteurNom != null) {
        existing.recepteurNom = mission.recepteurNom;
        changed = true;
      }
      if (existing.recepteurFonction == null && mission.recepteurFonction != null) {
        existing.recepteurFonction = mission.recepteurFonction;
        changed = true;
      }
      if (existing.recepteurEmail == null && mission.recepteurEmail != null) {
        existing.recepteurEmail = mission.recepteurEmail;
        changed = true;
      }
      if (existing.recepteurTelephone == null && mission.recepteurTelephone != null) {
        existing.recepteurTelephone = mission.recepteurTelephone;
        changed = true;
      }
      if (existing.dateRapport == null && mission.dateRapport != null) {
        existing.dateRapport = mission.dateRapport;
        changed = true;
      }
      if (changed) {
        await existing.save();
      }
    }
    if (kDebugMode) {
      print('✅ Renseignements existants trouvés pour: $missionId');
    }
    return existing;
  } catch (e) {
    if (kDebugMode) {
      print('🔵 Création de nouveaux renseignements pour: $missionId');
    }
    
    // ✅ Créer avec préremplissage complet depuis Mission
    final newData = RenseignementsGeneraux(
      missionId: missionId,
      etablissement: mission?.nomClient ?? '',
      installation: mission?.installation ?? '',
      activite: mission?.activiteClient ?? '',
      verificationType: mission?.natureMission,
      updatedAt: DateTime.now(),
      nomSite: mission?.nomSite ?? '',
      activiteSurSite: mission?.activiteSurSite,
      classementReglementaire: mission?.classementReglementaire,
      classementReglementaireType: mission?.classementReglementaireType,
      classementReglementaireCategorie: mission?.classementReglementaireCategorie,
      recepteurRapport: mission?.recepteurRapport,
      lieuIntervention: mission?.lieuIntervention,
      dateRapport: mission?.dateRapport,
      recepteurCivilite: mission?.recepteurCivilite,
      recepteurNom: mission?.recepteurNom,
      recepteurFonction: mission?.recepteurFonction,
      recepteurEmail: mission?.recepteurEmail,
      recepteurTelephone: mission?.recepteurTelephone,
      compteRendu: [],
      accompagnateurs: [],
      verificateurs: [],
    );
    
    await box.add(newData);
    
    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>(_missionBox);
    final missionToUpdate = missionBox.get(missionId);
    if (missionToUpdate != null) {
      missionToUpdate.renseignementsGenerauxId = newData.key.toString();
      await missionToUpdate.save();
    }
    
    if (kDebugMode) {
      print('✅ RenseignementsGeneraux créé et prérempli pour mission: $missionId');
    }
    return newData;
  }
}

/// Sauvegarder les renseignements généraux
static Future<void> saveRenseignementsGeneraux(RenseignementsGeneraux data) async {
  final box = Hive.box<RenseignementsGeneraux>(_renseignementsGenerauxBox);
  data.updatedAt = DateTime.now();
  if (data.isInBox) {
    await data.save();
  } else {
    await box.add(data);
  }

  // ✅ Synchroniser avec la Mission correspondante
  final missionBox = Hive.box<Mission>(_missionBox);
  final mission = missionBox.get(data.missionId);
  if (mission != null) {
    bool missionChanged = false;
    if (data.activiteSurSite != mission.activiteSurSite) {
      mission.activiteSurSite = data.activiteSurSite;
      missionChanged = true;
    }
    if (data.classementReglementaire != mission.classementReglementaire) {
      mission.classementReglementaire = data.classementReglementaire;
      missionChanged = true;
    }
    if (data.classementReglementaireType != mission.classementReglementaireType) {
      mission.classementReglementaireType = data.classementReglementaireType;
      missionChanged = true;
    }
    if (data.classementReglementaireCategorie != mission.classementReglementaireCategorie) {
      mission.classementReglementaireCategorie = data.classementReglementaireCategorie;
      missionChanged = true;
    }
    if (data.lieuIntervention != null && data.lieuIntervention != mission.lieuIntervention) {
      mission.lieuIntervention = data.lieuIntervention;
      missionChanged = true;
    }
    if (data.recepteurRapport != null && data.recepteurRapport != mission.recepteurRapport) {
      mission.recepteurRapport = data.recepteurRapport;
      missionChanged = true;
    }
    if (data.recepteurCivilite != null && data.recepteurCivilite != mission.recepteurCivilite) {
      mission.recepteurCivilite = data.recepteurCivilite;
      missionChanged = true;
    }
    if (data.recepteurNom != null && data.recepteurNom != mission.recepteurNom) {
      mission.recepteurNom = data.recepteurNom;
      missionChanged = true;
    }
    if (data.recepteurFonction != null && data.recepteurFonction != mission.recepteurFonction) {
      mission.recepteurFonction = data.recepteurFonction;
      missionChanged = true;
    }
    if (data.recepteurEmail != null && data.recepteurEmail != mission.recepteurEmail) {
      mission.recepteurEmail = data.recepteurEmail;
      missionChanged = true;
    }
    if (data.recepteurTelephone != null && data.recepteurTelephone != mission.recepteurTelephone) {
      mission.recepteurTelephone = data.recepteurTelephone;
      missionChanged = true;
    }
    if (data.dateRapport != null && data.dateRapport != mission.dateRapport) {
      mission.dateRapport = data.dateRapport;
      missionChanged = true;
    }
    if (missionChanged) {
      await mission.save();
    }
  }

  if (kDebugMode) {
    print('✅ Renseignements généraux sauvegardés pour mission ${data.missionId}');
  }
}

/// Récupérer les renseignements généraux par missionId
static RenseignementsGeneraux? getRenseignementsGenerauxByMissionId(String missionId) {
  final box = Hive.box<RenseignementsGeneraux>(_renseignementsGenerauxBox);
  try {
    return box.values.firstWhere((r) => r.missionId == missionId);
  } catch (e) {
    return null;
  }
}

// ============================================================
//          GESTION PREFERENCE MOYENNE TENSION
// ============================================================

static const String _mtPreferenceBox = 'mt_preference';

/// Sauvegarder la préférence MT pour une mission
static Future<void> saveMoyenneTensionPreference(String missionId, bool isApplicable) async {
  final box = await Hive.openBox(_mtPreferenceBox);
  await box.put(missionId, {
    'isApplicable': isApplicable,
    'timestamp': DateTime.now().toIso8601String(),
  });
  if (kDebugMode) {
    print('✅ Préférence MT sauvegardée pour mission $missionId: $isApplicable');
  }
}

/// Vérifier si la préférence MT a déjà été définie
static Future<bool> hasMoyenneTensionPreference(String missionId) async {
  final box = await Hive.openBox(_mtPreferenceBox);
  return box.containsKey(missionId);
}

/// Récupérer la préférence MT
static Future<bool> isMoyenneTensionApplicable(String missionId) async {
  final box = await Hive.openBox(_mtPreferenceBox);
  final data = box.get(missionId);
  if (data != null && data is Map) {
    final isApplicable = data['isApplicable'];
    if (isApplicable is bool) return isApplicable;
  }
  return true;
}

// Méthodes JSA
static Future<JSA> getOrCreateJSA(String missionId) async {
  final box = Hive.box<JSA>(_jsaBox);
  
  try {
    final existing = box.values.firstWhere((jsa) => jsa.missionId == missionId);
    return existing;
  } catch (e) {
    final newJSA = JSA.create(missionId);
    await box.add(newJSA);
    
    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.jsaId = newJSA.key.toString();
      await mission.save();
    }
    
    return newJSA;
  }
}

static Future<void> saveJSA(JSA jsa) async {
  final box = Hive.box<JSA>(_jsaBox);
  jsa.updatedAt = DateTime.now();
  if (jsa.isInBox) {
    await jsa.save();
  } else {
    await box.add(jsa);
  }
}

static JSA? getJSAByMissionId(String missionId) {
  if (!Hive.isBoxOpen(_jsaBox)) return null;
  final box = Hive.box<JSA>(_jsaBox);
  try {
    return box.values.firstWhere((jsa) => jsa.missionId == missionId);
  } catch (e) {
    return null;
  }
}

/// S'assure que l'inspecteur connecté actuel est présent dans la liste des inspecteurs JSA (sans doublon)
/// et synchronise la source unique de vérité.
static Future<void> ensureCurrentUserInJSA(String missionId) async {
  await IntervenantsService.ensureCurrentUserInJSA(missionId);
}

/// Vérifie si les 6 sous-sections du JSA d'une mission sont intégralement complétées
static bool isJsaCompleted(String missionId) {
  final jsa = getJSAByMissionId(missionId);
  if (jsa == null) return false;

  // 0. Opération & Équipe
  final sub0 = jsa.operationEffectuer.trim().isNotEmpty &&
      jsa.inspecteurs.isNotEmpty;

  // 1. Plan Urgence
  final p = jsa.planUrgence;
  final sub1 = p.voiesIssuesIdentifiees ||
      p.zonesRassemblementIdentifiees ||
      p.consignesSecuriteInternes ||
      p.personneContactClient.trim().isNotEmpty ||
      p.personneContactKES.trim().isNotEmpty;

  // 2. Dangers
  final d = jsa.dangers;
  final sub2 = d.chocElectrique ||
      d.bruit ||
      d.stressThermique ||
      d.eclairageInadapte ||
      d.zoneCirculationMalDefinie ||
      d.solAccidente ||
      d.emissionGazPoussiere ||
      d.espaceConfine ||
      d.autreEnvironnement.trim().isNotEmpty ||
      d.chuteObjets ||
      d.coactivite ||
      d.portCharge ||
      d.expositionProduitsChimiques ||
      d.chuteHauteur ||
      d.electrification ||
      d.incendiesExplosion ||
      d.mauvaisesPostures ||
      d.chutePlainPied ||
      d.autrePhysique.trim().isNotEmpty;

  // 3. Exigences Générales (EPC)
  final e = jsa.exigencesGenerales;
  final sub3 = e.signaletiqueSecurite ||
      e.ficheDonneeSecuriteDisponible ||
      e.uneMinuteMaSecurite ||
      e.balise ||
      e.zoneTravailPropre ||
      e.toolboxMeeting ||
      e.permisTravail ||
      e.extincteurs ||
      e.outilsMaterielsIsolants ||
      e.boitePharmacie ||
      e.autre.trim().isNotEmpty;

  // 4. Équipements de Protection Individuelle (EPI)
  final ep = jsa.epi;
  final sub4 = ep.casqueSecurite ||
      ep.bouchonsOreille ||
      ep.lunettesProtection ||
      ep.harnaisSecurite ||
      ep.chaussureSecurite ||
      ep.masqueSecurite ||
      ep.combinaisonLongueManche ||
      ep.gantsIsolants ||
      ep.cacheNez ||
      ep.gilet ||
      ep.autre.trim().isNotEmpty;

  // 5. Vérification finale & Signatures
  final v = jsa.verificationFinale;
  final sub5 = v.travailTermineNA ||
      v.travailTermineApplicable ||
      v.consignationCadenasRetireNA ||
      v.consignationCadenasRetireApplicable ||
      v.absenceConsignataireProcedureNA ||
      v.absenceConsignataireProcedureApplicable ||
      v.consignataireAbsentProcedureAppliqueeNA ||
      v.consignataireAbsentProcedureAppliqueeApplicable ||
      v.materielEnleveZoneNettoyeeNA ||
      v.materielEnleveZoneNettoyeeApplicable ||
      v.risquesSupprimesEquipementPretNA ||
      v.risquesSupprimesEquipementPretApplicable ||
      v.donneurOrdreSignature.trim().isNotEmpty ||
      v.chargeAffairesSignature.trim().isNotEmpty;

  return sub0 && sub1 && sub2 && sub3 && sub4 && sub5;
}

// ===== MÉTHODES POUR LES BROUILLONS DE COFFRET =====
  
  /// Sauvegarder un brouillon de coffret
static Future<void> saveCoffretDraft({
  required String missionId,
  required String parentType,
  required int parentIndex,
  required bool isMoyenneTension,
  required int? zoneIndex,
  required CoffretArmoire coffret,
  required int currentStep,
}) async {
  try {
    final box = Hive.box(_coffretDraftsBox);
    String draftKey = coffret.qrCode.trim();
    if (draftKey.isEmpty) {
      final idVal = (coffret.id ?? '').trim();
      if (idVal.isNotEmpty) {
        draftKey = idVal;
      } else {
        draftKey = 'DRAFT_${missionId}_${parentType}_${parentIndex}_${zoneIndex ?? "null"}';
      }
      coffret.qrCode = draftKey;
    }
    
    coffret.statut = 'incomplet';
    coffret.currentStep = currentStep;
    
    // S'assurer que les photos sont bien dans les nouveaux champs
    if (coffret.photosExternes.isEmpty && coffret.photosInternes.isEmpty && coffret.photos.isNotEmpty) {
      coffret.photosExternes = coffret.photos.where((p) => p.contains('externe')).toList();
      coffret.photosInternes = coffret.photos.where((p) => p.contains('interne')).toList();
    }
    
    // Sauvegarder une Map avec toutes les métadonnées (comme dans les autres méthodes)
    final draftData = {
      'coffret': coffret,
      'currentStep': currentStep,
      'missionId': missionId,
      'parentType': parentType,
      'parentIndex': parentIndex,
      'isMoyenneTension': isMoyenneTension,
      'zoneIndex': zoneIndex,
      'savedAt': DateTime.now().toIso8601String(),
    };
    
    await box.put(draftKey, draftData);
    if (kDebugMode) {
      print('✅ Brouillon sauvegardé: $draftKey (step $currentStep)');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur saveCoffretDraft: $e');
    }
    rethrow;
  }
}

  /// Récupérer les données complètes du brouillon
  static Map<String, dynamic>? getCoffretDraftData(String qrCode) {
    final box = Hive.box(_coffretDraftsBox);
    final data = box.get(qrCode);
    
    if (data != null && data['coffret'] is CoffretArmoire) {
      return {
        'coffret': data['coffret'] as CoffretArmoire,
        'currentStep': data['currentStep'] as int? ?? 0,
        'missionId': data['missionId'] as String?,
        'parentType': data['parentType'] as String?,
        'parentIndex': data['parentIndex'] as int?,
        'isMoyenneTension': data['isMoyenneTension'] as bool?,
        'zoneIndex': data['zoneIndex'] as int?,
      };
    }
    return null;
  }

  /// Récupérer tous les brouillons pour une mission
  static List<CoffretArmoire> getAllCoffretDrafts(String missionId) {
    final box = Hive.box(_coffretDraftsBox);
    final drafts = <CoffretArmoire>[];
    
    for (var data in box.values) {
      if (data['missionId'] == missionId && data['coffret'] is CoffretArmoire) {
        final coffret = data['coffret'] as CoffretArmoire;
        if (coffret.statut == 'incomplet') {
          drafts.add(coffret);
        }
      }
    }
    
    return drafts;
  }

  /// Supprimer un brouillon
  static Future<void> deleteCoffretDraft(String qrCode) async {
    final box = Hive.box(_coffretDraftsBox);
    await box.delete(qrCode);
    if (kDebugMode) {
      print('✅ Brouillon supprimé: $qrCode');
    }
  }

  /// Récupérer les brouillons pour un emplacement spécifique
  static List<CoffretArmoire> getCoffretDraftsForLocation({
    required String missionId,
    required String parentType,
    required int parentIndex,
    required bool isMoyenneTension,
    required int? zoneIndex,
  }) {
    final box = Hive.box(_coffretDraftsBox);
    final drafts = <CoffretArmoire>[];
    
    for (var data in box.values) {
      if (data['missionId'] == missionId &&
          data['parentType'] == parentType &&
          data['parentIndex'] == parentIndex &&
          data['isMoyenneTension'] == isMoyenneTension &&
          data['zoneIndex'] == zoneIndex &&
          data['coffret'] is CoffretArmoire) {
        
        final coffret = data['coffret'] as CoffretArmoire;
        if (coffret.statut == 'incomplet') {
          drafts.add(coffret);
        }
      }
    }
    
    return drafts;
  }

  /// Récupérer et indexer TOUS les brouillons de coffrets d'une mission en une seule passe O(N)
  static Map<String, List<CoffretArmoire>> getIndexedCoffretDraftsForMission({
    required String missionId,
    required bool isMoyenneTension,
  }) {
    final box = Hive.box(_coffretDraftsBox);
    final index = <String, List<CoffretArmoire>>{};
    
    for (var data in box.values) {
      if (data is Map &&
          data['missionId'] == missionId &&
          data['isMoyenneTension'] == isMoyenneTension &&
          data['coffret'] is CoffretArmoire) {
        final coffret = data['coffret'] as CoffretArmoire;
        if (coffret.statut == 'incomplet') {
          final parentType = data['parentType'] as String? ?? '';
          final parentIndex = data['parentIndex'] as int? ?? -1;
          final zoneIndex = data['zoneIndex'] as int?;
          final key = '${parentType}_${parentIndex}_$zoneIndex';
          (index[key] ??= []).add(coffret);
        }
      }
    }
    
    return index;
  }

  /// Récupérer ou créer le classement d'une zone
static Future<ClassementZone> getOrCreateClassementZone({
  required String missionId,
  required String nomZone,
  String typeZone = 'BT',
}) async {
  final box = Hive.box<ClassementZone>(_classementZoneBox);
  
  try {
    // Chercher un classement existant
    for (var cz in box.values) {
      if (cz.missionId == missionId && cz.nomZone == nomZone) {
        return cz;
      }
    }
    
    // Créer un nouveau classement
    final newClassement = ClassementZone.create(
      missionId: missionId,
      nomZone: nomZone,
      typeZone: typeZone,
    );
    await box.add(newClassement);
    if (kDebugMode) {
      print('✅ ClassementZone créé: $nomZone');
    }
    return newClassement;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getOrCreateClassementZone: $e');
    }
    final newClassement = ClassementZone.create(
      missionId: missionId,
      nomZone: nomZone,
      typeZone: typeZone,
    );
    await box.add(newClassement);
    return newClassement;
  }
}

/// Sauvegarder un classement de zone
static Future<bool> saveClassementZone(ClassementZone classement) async {
  try {
    final box = Hive.box<ClassementZone>(_classementZoneBox);
    classement.updatedAt = DateTime.now();
    classement.calculerIndices();
    
    if (classement.key != null) {
      await box.put(classement.key, classement);
    } else {
      await box.add(classement);
    }
    
    if (kDebugMode) {
      print('✅ ClassementZone sauvegardé: ${classement.nomZone}');
      print('   AF: ${classement.af}, BE: ${classement.be}, AE: ${classement.ae}');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur saveClassementZone: $e');
    }
    return false;
  }
}

/// Récupérer tous les classements de zones d'une mission
static List<ClassementZone> getClassementsZonesByMissionId(String missionId) {
  final box = Hive.box<ClassementZone>(_classementZoneBox);
  return box.values.where((cz) => cz.missionId == missionId).toList();
}

/// Récupérer un classement de zone par son nom
static ClassementZone? getClassementZoneByNom(String missionId, String nomZone) {
  final box = Hive.box<ClassementZone>(_classementZoneBox);
  try {
    return box.values.firstWhere(
      (cz) => cz.missionId == missionId && cz.nomZone == nomZone,
    );
  } catch (e) {
    try {
      final cleanNom = nomZone.trim().toLowerCase();
      return box.values.firstWhere(
        (cz) => cz.missionId == missionId && cz.nomZone.trim().toLowerCase() == cleanNom,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Synchroniser les classements de zones depuis l'audit
static Future<void> syncClassementsZonesFromAudit(String missionId) async {
  final audit = getAuditInstallationsByMissionId(missionId);
  if (audit == null) return;
  
  // Zones MT
  for (var zone in audit.moyenneTensionZones) {
    await getOrCreateClassementZone(
      missionId: missionId,
      nomZone: zone.nom,
      typeZone: 'MT',
    );
  }
  
  // Zones BT
  for (var zone in audit.basseTensionZones) {
    await getOrCreateClassementZone(
      missionId: missionId,
      nomZone: zone.nom,
      typeZone: 'BT',
    );
  }
  
  if (kDebugMode) {
    print('✅ Classements zones synchronisés pour mission $missionId');
  }
}

/// Supprimer le classement d'un local
static Future<void> deleteClassementLocal({
  required String missionId,
  required String nomLocal,
}) async {
  final box = Hive.box<ClassementEmplacement>(_classementBox);
  
  try {
    ClassementEmplacement? toDelete;
    for (var ce in box.values) {
      if (ce.missionId == missionId && ce.localisation == nomLocal && ce.typeEmplacement == 'local') {
        toDelete = ce;
        break;
      }
    }
    
    if (toDelete != null) {
      await toDelete.delete();
      if (kDebugMode) {
        print('✅ ClassementLocal supprimé: $nomLocal');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteClassementLocal: $e');
    }
  }
}

/// Supprimer le classement d'une zone
static Future<void> deleteClassementZone({
  required String missionId,
  required String nomZone,
}) async {
  final box = Hive.box<ClassementZone>(_classementZoneBox);
  
  try {
    ClassementZone? toDelete;
    for (var cz in box.values) {
      if (cz.missionId == missionId && cz.nomZone == nomZone) {
        toDelete = cz;
        break;
      }
    }
    
    if (toDelete != null) {
      await toDelete.delete();
      if (kDebugMode) print('✅ ClassementZone supprimé: $nomZone');
    }

    // Réinitialiser également le classementZoneId sur la zone dans l'audit
    final audit = getAuditInstallationsByMissionId(missionId);
    if (audit != null) {
      bool modified = false;
      for (var z in audit.moyenneTensionZones) {
        if (z.nom == nomZone && z.classementZoneId != null) {
          z.classementZoneId = null;
          modified = true;
        }
      }
      for (var z in audit.basseTensionZones) {
        if (z.nom == nomZone && z.classementZoneId != null) {
          z.classementZoneId = null;
          modified = true;
        }
      }
      if (modified) {
        await saveAuditInstallations(audit);
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteClassementZone: $e');
    }
  }
}

/// Récupérer un classement de zone par son ID (supporte les clés String et int)
static ClassementZone? getClassementZoneById(String id) {
  try {
    final box = Hive.box<ClassementZone>(_classementZoneBox);
    final direct = box.get(id);
    if (direct != null) return direct;
    final intKey = int.tryParse(id);
    if (intKey != null) {
      return box.get(intKey);
    }
    return null;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getClassementZoneById: $e');
    }
    return null;
  }
}

/// Obtenir un identifiant de brouillon stable et persistant pour un local
static String getStableLocalDraftId({
  required String missionId,
  required bool isMoyenneTension,
  int? zoneIndex,
  bool isInZone = false,
  int? localIndex,
  String? nomLocal,
  String? customDraftId,
}) {
  if (customDraftId != null && customDraftId.isNotEmpty && !customDraftId.startsWith('EDIT_')) {
    return customDraftId;
  }
  final domain = isMoyenneTension ? 'MT' : 'BT';
  final zonePart = isInZone && zoneIndex != null ? 'ZONE_$zoneIndex' : 'DIRECT';
  final localPart = localIndex != null ? 'INDEX_$localIndex' : (nomLocal?.trim().replaceAll(' ', '_') ?? 'NEW');
  return 'DRAFT_${missionId}_${domain}_${zonePart}_$localPart';
}

/// Vérifier si un brouillon actif existe pour une clé donnée
static bool hasActiveLocalDraft(String draftKey) {
  try {
    final box = Hive.box(_localDraftsBox);
    return box.containsKey(draftKey);
  } catch (_) {
    return false;
  }
}

/// Sauvegarder un brouillon de local
static Future<void> saveLocalDraft({
  required String missionId,
  required bool isMoyenneTension,
  required int? zoneIndex,
  required bool isInZone,
  required dynamic local, // MoyenneTensionLocal ou BasseTensionLocal
  required int currentStep,
  String? localId, // Pour l'édition
}) async {
  try {
    final box = Hive.box(_localDraftsBox);
    
    // Générer une clé unique pour ce brouillon
    String draftKey = localId ?? 'TEMP_${DateTime.now().millisecondsSinceEpoch}';
    
    // Déterminer le type de local
    String localType = isMoyenneTension ? 'MT' : 'BT';
    if (isMoyenneTension && local is MoyenneTensionLocal && 
        (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT')) {
      localType = 'MT_TRANSFO';
    }
    
    final draftData = {
      'local': local,
      'currentStep': currentStep,
      'missionId': missionId,
      'isMoyenneTension': isMoyenneTension,
      'zoneIndex': zoneIndex,
      'isInZone': isInZone,
      'localType': localType,
      'nomLocal': local.nom,
      'savedAt': DateTime.now().toIso8601String(),
      'localId': draftKey,
    };
    
    await box.put(draftKey, draftData);
    if (kDebugMode) {
      print('✅ Brouillon local sauvegardé: ${local.nom} (step $currentStep)');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur saveLocalDraft: $e');
    }
    rethrow;
  }
}

/// Récupérer les données complètes d'un brouillon de local
static Map<String, dynamic>? getLocalDraftData(String draftKey) {
  try {
    final box = Hive.box(_localDraftsBox);
    final data = box.get(draftKey);
    
    if (data != null) {
      return {
        'local': data['local'],
        'currentStep': data['currentStep'] as int? ?? 0,
        'missionId': data['missionId'] as String?,
        'isMoyenneTension': data['isMoyenneTension'] as bool? ?? true,
        'zoneIndex': data['zoneIndex'] as int?,
        'isInZone': data['isInZone'] as bool? ?? false,
        'localType': data['localType'] as String?,
        'nomLocal': data['nomLocal'] as String?,
        'localId': data['localId'] as String?,
      };
    }
    return null;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getLocalDraftData: $e');
    }
    return null;
  }
}

/// Supprimer un brouillon de local
static Future<void> deleteLocalDraft(String draftKey) async {
  try {
    final box = Hive.box(_localDraftsBox);
    await box.delete(draftKey);
    if (kDebugMode) {
      print('✅ Brouillon local supprimé: $draftKey');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteLocalDraft: $e');
    }
  }
}

/// Récupérer tous les brouillons de locaux pour une mission
static List<Map<String, dynamic>> getLocalDraftsForMission(String missionId) {
  try {
    final box = Hive.box(_localDraftsBox);
    final drafts = <Map<String, dynamic>>[];
    
    for (var data in box.values) {
      if (data['missionId'] == missionId) {
        drafts.add({
          'local': data['local'],
          'currentStep': data['currentStep'] as int? ?? 0,
          'isMoyenneTension': data['isMoyenneTension'] as bool? ?? true,
          'zoneIndex': data['zoneIndex'] as int?,
          'isInZone': data['isInZone'] as bool? ?? false,
          'nomLocal': data['nomLocal'] as String? ?? 'Sans nom',
          'localId': data['localId'] as String?,
          'localType': data['localType'] as String?,
        });
      }
    }
    
    return drafts;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getLocalDraftsForMission: $e');
    }
    return [];
  }
}

/// Récupérer les brouillons de locaux pour une zone spécifique (MT)
static List<Map<String, dynamic>> getLocalDraftsForMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
}) {
  try {
    final box = Hive.box(_localDraftsBox);
    final drafts = <Map<String, dynamic>>[];
    
    for (var data in box.values) {
      if (data['missionId'] == missionId &&
          data['isMoyenneTension'] == true &&
          data['isInZone'] == true &&
          data['zoneIndex'] == zoneIndex) {
        drafts.add({
          'local': data['local'],
          'currentStep': data['currentStep'] as int? ?? 0,
          'nomLocal': data['nomLocal'] as String? ?? 'Sans nom',
          'localId': data['localId'] as String?,
        });
      }
    }
    
    return drafts;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getLocalDraftsForMoyenneTensionZone: $e');
    }
    return [];
  }
}

/// Récupérer les brouillons de locaux pour une zone spécifique (BT)
static List<Map<String, dynamic>> getLocalDraftsForBasseTensionZone({
  required String missionId,
  required int zoneIndex,
}) {
  try {
    final box = Hive.box(_localDraftsBox);
    final drafts = <Map<String, dynamic>>[];
    
    for (var data in box.values) {
      if (data['missionId'] == missionId &&
          data['isMoyenneTension'] == false &&
          data['zoneIndex'] == zoneIndex) {
        drafts.add({
          'local': data['local'],
          'currentStep': data['currentStep'] as int? ?? 0,
          'nomLocal': data['nomLocal'] as String? ?? 'Sans nom',
          'localId': data['localId'] as String?,
        });
      }
    }
    
    return drafts;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getLocalDraftsForBasseTensionZone: $e');
    }
    return [];
  }
}

/// Récupérer les brouillons de locaux hors zone (MT uniquement)
static List<Map<String, dynamic>> getLocalDraftsForMoyenneTensionHorsZone({
  required String missionId,
}) {
  try {
    final box = Hive.box(_localDraftsBox);
    final drafts = <Map<String, dynamic>>[];
    
    for (var data in box.values) {
      if (data['missionId'] == missionId &&
          data['isMoyenneTension'] == true &&
          data['isInZone'] == false) {
        drafts.add({
          'local': data['local'],
          'currentStep': data['currentStep'] as int? ?? 0,
          'nomLocal': data['nomLocal'] as String? ?? 'Sans nom',
          'localId': data['localId'] as String?,
          'zoneIndex': data['zoneIndex'],
          'isInZone': data['isInZone'],
        });
      }
    }
    
    return drafts;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur getLocalDraftsForMoyenneTensionHorsZone: $e');
    }
    return [];
  }
}

static Future<void> refreshDrafts() async {
  // Hive n'a pas de cache, mais cette méthode force la réouverture de la box
  try {
    if (Hive.isBoxOpen(_localDraftsBox)) {
      await Hive.box(_localDraftsBox).compact();
    }
    if (Hive.isBoxOpen(_coffretDraftsBox)) {
      await Hive.box(_coffretDraftsBox).compact();
    }
    if (kDebugMode) {
      print('✅ Brouillons rafraîchis');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur refreshDrafts: $e');
    }
  }
}


// ============================================================
//          SUPPRESSION CASCADE DES BROUILLONS
// ============================================================

/// Supprimer tous les brouillons de locaux pour une mission
static Future<void> deleteAllLocalDraftsForMission(String missionId) async {
  try {
    final box = Hive.box(_localDraftsBox);
    final toDelete = <String>[];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null && data['missionId'] == missionId) {
        toDelete.add(key as String);
      }
    }
    
    for (var key in toDelete) {
      await box.delete(key);
    }
    
    if (kDebugMode) {
      print('✅ ${toDelete.length} brouillons de locaux supprimés pour la mission $missionId');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteAllLocalDraftsForMission: $e');
    }
  }
}

/// Supprimer tous les brouillons de coffrets pour une mission
static Future<void> deleteAllCoffretDraftsForMission(String missionId) async {
  try {
    final box = Hive.box(_coffretDraftsBox);
    final toDelete = <String>[];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null && data['missionId'] == missionId) {
        toDelete.add(key as String);
      }
    }
    
    for (var key in toDelete) {
      await box.delete(key);
    }
    
    if (kDebugMode) {
      print('✅ ${toDelete.length} brouillons de coffrets supprimés pour la mission $missionId');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteAllCoffretDraftsForMission: $e');
    }
  }
}

/// Supprimer les brouillons de locaux liés à une zone spécifique (MT ou BT)
static Future<void> deleteLocalDraftsForZone({
  required String missionId,
  required int zoneIndex,
  required bool isMoyenneTension,
}) async {
  try {
    final box = Hive.box(_localDraftsBox);
    final toDelete = <String>[];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null &&
          data['missionId'] == missionId &&
          data['zoneIndex'] == zoneIndex &&
          data['isMoyenneTension'] == isMoyenneTension) {
        toDelete.add(key as String);
      }
    }
    
    for (var key in toDelete) {
      await box.delete(key);
    }
    
    if (kDebugMode) {
      print('✅ ${toDelete.length} brouillons de locaux supprimés pour zone $zoneIndex');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteLocalDraftsForZone: $e');
    }
  }
}

/// Supprimer les brouillons de coffrets liés à un local spécifique
static Future<void> deleteCoffretDraftsForLocal({
  required String missionId,
  required int parentIndex,
  required bool isMoyenneTension,
  int? zoneIndex,
}) async {
  try {
    final box = Hive.box(_coffretDraftsBox);
    final toDelete = <String>[];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null &&
          data['missionId'] == missionId &&
          data['parentType'] == 'local' &&
          data['parentIndex'] == parentIndex &&
          data['isMoyenneTension'] == isMoyenneTension &&
          data['zoneIndex'] == zoneIndex) {
        toDelete.add(key as String);
      }
    }
    
    for (var key in toDelete) {
      await box.delete(key);
    }
    
    if (kDebugMode) {
      print('✅ ${toDelete.length} brouillons de coffrets supprimés pour local $parentIndex');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteCoffretDraftsForLocal: $e');
    }
  }
}

/// Supprimer les brouillons de coffrets liés à une zone spécifique
static Future<void> deleteCoffretDraftsForZone({
  required String missionId,
  required int parentIndex,
  required bool isMoyenneTension,
}) async {
  try {
    final parentType = isMoyenneTension ? 'zone_mt' : 'zone_bt';
    final box = Hive.box(_coffretDraftsBox);
    final toDelete = <String>[];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null &&
          data['missionId'] == missionId &&
          data['parentType'] == parentType &&
          data['parentIndex'] == parentIndex) {
        toDelete.add(key as String);
      }
    }
    
    for (var key in toDelete) {
      await box.delete(key);
    }
    
    if (kDebugMode) {
      print('✅ ${toDelete.length} brouillons de coffrets supprimés pour zone $parentIndex');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur deleteCoffretDraftsForZone: $e');
    }
  }
}


// ============================================================
//          GESTION DERNIER RAPPORT GÉNÉRÉ
// ============================================================

static const String _lastReportBox = 'last_reports';

static Future<void> saveLastReport(LastReport report) async {
  final box = await Hive.openBox<LastReport>(_lastReportBox);
  
  // Ne pas supprimer l'ancien, on garde les deux types
  await box.add(report);
  if (kDebugMode) {
    print('✅ Rapport ${report.reportType} sauvegardé pour mission ${report.missionId}');
  }
}

static Future<LastReport?> getLastReport(String missionId) async {
  final box = await Hive.openBox<LastReport>(_lastReportBox);
  try {
    return box.values.firstWhere((r) => r.missionId == missionId);
  } catch (e) {
    return null;
  }
}

static Future<void> deleteLastReport(String missionId) async {
  final box = await Hive.openBox<LastReport>(_lastReportBox);
  final toDelete = box.values.where((r) => r.missionId == missionId).toList();
  for (var report in toDelete) {
    await report.delete();
  }
}


static Future<LastReport?> getLastReportByType(String missionId, String reportType) async {
  final box = await Hive.openBox<LastReport>(_lastReportBox);
  try {
    return box.values.firstWhere(
      (r) => r.missionId == missionId && r.reportType == reportType,
    );
  } catch (e) {
    return null;
  }
}

static Future<List<LastReport>> getAllReportsForMission(String missionId) async {
  final box = await Hive.openBox<LastReport>(_lastReportBox);
  return box.values.where((r) => r.missionId == missionId).toList();
}



/// Mettre à jour le mot de passe d'un utilisateur par email
static Future<bool> updateUserPassword({
  required String email,
  required String newPassword,
}) async {
  try {
    final normalizedEmail = email.trim().toLowerCase();
    final box = Hive.box<Verificateur>(_verificateurBox);
    final user = box.get(normalizedEmail);

    if (user == null) {
      if (kDebugMode) print('❌ Utilisateur non trouvé: $normalizedEmail');
      return false;
    }

    // Écrire le nouveau hash bcrypt dans FlutterSecureStorage
    final passwordResult = await SecurePasswordService.createPassword(
      email: normalizedEmail,
      plainPassword: newPassword,
    );

    if (!passwordResult.success) {
      if (kDebugMode) {
        print('❌ Hash bcrypt échoué: ${passwordResult.errorMessage}');
      }
      return false;
    }

    user.password = ''; // vider l'éventuel ancien mot de passe en clair
    await user.save();

    // Réinitialiser les compteurs de sécurité (lockout, tentatives échouées)
    await SecurePasswordService.resetSecurityCounters(normalizedEmail);

    if (kDebugMode) print('✅ Mot de passe mis à jour avec bcrypt pour: $normalizedEmail');
    return true;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur updateUserPassword: $e');
    return false;
  }
}

  // ═══════════════════════════════════════════════════════════════
  // MÉTHODES D'AUTHENTIFICATION SÉCURISÉES (NOUVELLES)
  // ═══════════════════════════════════════════════════════════════
  
  static Future<bool> createUserWithSecurePassword({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String matricule,
  }) async {
    try {
      // 1. Vérifier si l'email existe déjà
      if (emailExists(email)) {
        return false;
      }
      
      // 2. Vérifier si le matricule existe déjà
      if (matriculeExists(matricule)) {
        return false;
      }
      
      // 3. Créer le mot de passe sécurisé
      final passwordResult = await SecurePasswordService.createPassword(
        email: email.toLowerCase(),
        plainPassword: password,
      );
      
      if (!passwordResult.success) {
        if (kDebugMode) {
          print('❌ Création password échouée: ${passwordResult.errorMessage}');
        }
        return false;
      }
      
      // 4. Créer l'utilisateur
      final newUser = Verificateur(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: nom.trim(),
        prenom: prenom.trim(),
        email: email.toLowerCase(),
        password: '', // Le mot de passe n'est plus stocké ici !
        matricule: matricule.toUpperCase(),
        createdAt: DateTime.now(),
      );
      
      // Sauvegarder l'utilisateur dans la box
      final box = Hive.box<Verificateur>(_verificateurBox);
      await box.put(email.toLowerCase(), newUser);
      
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur createUserWithSecurePassword: $e');
      }
      return false;
    }
  }

  
  static Future<SecureLoginResult> authenticateUserSecure({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Vérifier si l'utilisateur existe
      final user = getUserByEmail(email.toLowerCase());
      if (user == null) {
        return SecureLoginResult(
          success: false,
          errorMessage: 'Aucun compte trouvé avec cet email.',
        );
      }
      
      // 2. Vérifier le mot de passe avec Argon2id
      final verification = await SecurePasswordService.verifyPassword(
        email: email.toLowerCase(),
        plainPassword: password,
      );
      
      if (!verification.success) {
        // Ne pas révéler si c'est le mot de passe ou le verrouillage pour éviter le fingerprinting
        String errorMessage = verification.errorMessage ?? 'Email ou mot de passe incorrect';
        
        // Messages personnalisés pour le verrouillage
        if (verification.isLocked) {
          final minutes = verification.lockoutRemainingSeconds ~/ 60;
          errorMessage = 'Compte temporairement verrouillé. Réessayez dans $minutes minutes.';
        } else if (verification.remainingAttempts < 5) {
          errorMessage = 'Mot de passe incorrect. Plus que ${verification.remainingAttempts} tentative(s).';
        }
        
        return SecureLoginResult(
          success: false,
          errorMessage: errorMessage,
          isLocked: verification.isLocked,
          remainingAttempts: verification.remainingAttempts,
        );
      }
      
      // 3. Connecter l'utilisateur
      await saveCurrentUser(user);
      
      return SecureLoginResult(
        success: true,
        user: user,
        errorMessage: null,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur authenticateUserSecure: $e');
      return SecureLoginResult(
        success: false,
        errorMessage: 'Erreur lors de l\'authentification. Veuillez réessayer.',
      );
    }
  }
  
  static Future<SecureLoginResult> updateUserPasswordSecure({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final result = await SecurePasswordService.updatePassword(
      email: email.toLowerCase(),
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    
    return SecureLoginResult(
      success: result.success,
      errorMessage: result.errorMessage,
    );
  }
  
  static Future<void> resetSecurityCounters(String email) async {
  await SecurePasswordService.resetSecurityCounters(email.toLowerCase());
}

// ============================================================
//          GESTION DES DOCUMENTS PERSONNALISÉS
// ============================================================

/// Ajouter un document personnalisé à une mission
static Future<bool> addDocumentPersonnalise({
  required String missionId,
  required String documentNom,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null) {
      if (kDebugMode) print('❌ Mission non trouvée: $missionId');
      return false;
    }

    // Nettoyer le nom
    final nomClean = documentNom.trim();
    if (nomClean.isEmpty) return false;

    // Initialiser la liste si nécessaire
    if (mission.autresDocuments == null) {
      mission.autresDocuments = [];
    }

    // Ajouter si pas déjà présent
    if (!mission.autresDocuments.contains(nomClean)) {
      mission.autresDocuments.add(nomClean);
      mission.updatedAt = DateTime.now();
      await mission.save();
      if (kDebugMode) print('✅ Document personnalisé ajouté: $nomClean');
      return true;
    }

    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur addDocumentPersonnalise: $e');
    return false;
  }
}

/// Supprimer un document personnalisé d'une mission
static Future<bool> removeDocumentPersonnalise({
  required String missionId,
  required String documentNom,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null || mission.autresDocuments == null) {
      if (kDebugMode) print('❌ Mission non trouvée ou liste vide: $missionId');
      return false;
    }

    final removed = mission.autresDocuments.remove(documentNom);
    
    if (removed) {
      mission.updatedAt = DateTime.now();
      await mission.save();
      if (kDebugMode) print('✅ Document personnalisé supprimé: $documentNom');
      return true;
    }

    return false;
  } catch (e) {
    if (kDebugMode) print('❌ Erreur removeDocumentPersonnalise: $e');
    return false;
  }
}

/// Récupérer tous les documents personnalisés d'une mission
static List<String> getDocumentsPersonnalises(String missionId) {
  try {
    final mission = getMissionById(missionId);
    return mission?.autresDocuments ?? [];
  } catch (e) {
    if (kDebugMode) print('❌ Erreur getDocumentsPersonnalises: $e');
    return [];
  }
}

/// Mettre à jour l'état d'un document personnalisé (cochen/décochen)
/// Note: Pour les documents personnalisés, on considère que présence = coché
static Future<bool> updateDocumentPersonnaliseStatus({
  required String missionId,
  required String documentNom,
  required bool value,
}) async {
  if (value) {
    return await addDocumentPersonnalise(missionId: missionId, documentNom: documentNom);
  } else {
    return await removeDocumentPersonnalise(missionId: missionId, documentNom: documentNom);
  }
}

/// Vérifier si un document personnalisé est présent (coché)
static bool hasDocumentPersonnalise(String missionId, String documentNom) {
  try {
    final mission = getMissionById(missionId);
    return mission?.autresDocuments.contains(documentNom) ?? false;
  } catch (e) {
    return false;
  }
}


// ============================================================
//          GESTION DU DÉTAIL TN POUR LE RÉGIME DE NEUTRE
// ============================================================

/// Mettre à jour le détail TN pour le régime de neutre
static Future<bool> updateRegimeNeutreDetail({
  required String missionId,
  required String? detail, // 'C', 'S' ou null
}) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    desc.regimeNeutreDetail = detail;
    await saveDescriptionInstallations(desc);
    if (kDebugMode) {
      print('✅ Détail TN mis à jour: ${desc.regimeNeutre}${detail != null ? '-$detail' : ''}');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur updateRegimeNeutreDetail: $e');
    }
    return false;
  }
}

/// Récupérer le détail TN
static String? getRegimeNeutreDetail(String missionId) {
  try {
    final desc = getDescriptionInstallationsByMissionId(missionId);
    return desc?.regimeNeutreDetail;
  } catch (e) {
    return null;
  }
}


/// Migration unique : corriger les points de vérification sans priorité.
/// À appeler une seule fois au démarrage de l'app, après l'ouverture des boxes.
/// Les données créées avant l'ajout du champ priorité ont priorite=null
/// pour les conformités 'non' — ce qui bloque la navigation dans le formulaire.
static Future<void> migratePointsVerificationPriorite() async {
  const migrationKey = 'migration_pv_priorite_done_v1';
  final metaBox = Hive.box('meta');
  if (metaBox.get(migrationKey) == true) return; // déjà faite

  if (kDebugMode) print('🔄 Migration priorité points de vérification...');
  int fixed = 0;

  final auditBox = Hive.box<AuditInstallationsElectriques>(_auditBox);

  void fixCoffret(CoffretArmoire c) {
    bool changed = false;
    for (final p in c.pointsVerification) {
      if ((p.conformite == 'non' || p.conformite == 'na') && p.priorite == null) {
        p.priorite = 3; // Priorité basse par défaut
        changed = true;
        fixed++;
      }
    }
    // Pas besoin de sauvegarder individuellement — l'audit parent sera sauvegardé
  }

  for (final audit in auditBox.values) {
    bool auditChanged = false;

    for (final local in audit.moyenneTensionLocaux) {
      for (final c in local.coffrets) { fixCoffret(c); auditChanged = true; }
    }
    for (final zone in audit.moyenneTensionZones) {
      for (final c in zone.coffrets) { fixCoffret(c); auditChanged = true; }
      for (final local in zone.locaux) {
        for (final c in local.coffrets) { fixCoffret(c); auditChanged = true; }
      }
    }
    for (final zone in audit.basseTensionZones) {
      for (final c in zone.coffretsDirects) { fixCoffret(c); auditChanged = true; }
      for (final local in zone.locaux) {
        for (final c in local.coffrets) { fixCoffret(c); auditChanged = true; }
      }
    }

    if (auditChanged) await audit.save();
  }

  // Migrer aussi les brouillons coffrets
  final draftsBox = Hive.box('coffret_drafts');
  for (final key in draftsBox.keys) {
    final data = draftsBox.get(key);
    if (data is! Map) continue;
    final coffret = data['coffret'];
    if (coffret is! CoffretArmoire) continue;
    bool changed = false;
    for (final p in coffret.pointsVerification) {
      if ((p.conformite == 'non' || p.conformite == 'na') && p.priorite == null) {
        p.priorite = 3;
        changed = true;
        fixed++;
      }
    }
    if (changed) await draftsBox.put(key, data);
  }

  await metaBox.put(migrationKey, true);
  if (kDebugMode) print('✅ Migration terminée: $fixed points corrigés');
}

/// Vérifie si un coffret avec le même nom ET le même type existe déjà
/// dans la mission (tous les emplacements confondus), excluant les brouillons.
/// Retourne le nom de l'emplacement si doublon trouvé, null sinon.
static String? findCoffretDoublon({
  required String missionId,
  required String nom,
  required String type,
  String? excludeQrCode, // Exclure le coffret en cours d'édition
}) {
  final audit = Hive.box<AuditInstallationsElectriques>(_auditBox)
      .values
      .cast<AuditInstallationsElectriques?>()
      .firstWhere((a) => a?.missionId == missionId, orElse: () => null);
  if (audit == null) return null;

  final nomTrim = nom.trim().toLowerCase();
  final typeTrim = type.trim().toLowerCase();

  bool isDoublon(CoffretArmoire c) {
    if (c.statut != 'complet') return false; // ignorer brouillons
    if (excludeQrCode != null && c.qrCode == excludeQrCode) return false;
    return c.nom.trim().toLowerCase() == nomTrim &&
        c.type.trim().toLowerCase() == typeTrim;
  }

  for (final l in audit.moyenneTensionLocaux) {
    for (final c in l.coffrets) {
      if (isDoublon(c)) return 'Local MT "${l.nom}"';
    }
  }
  for (final z in audit.moyenneTensionZones) {
    for (final c in z.coffrets) {
      if (isDoublon(c)) return 'Zone MT "${z.nom}"';
    }
    for (final l in z.locaux) {
      for (final c in l.coffrets) {
        if (isDoublon(c)) return 'Local "${l.nom}" (Zone MT "${z.nom}")';
      }
    }
  }
  for (final z in audit.basseTensionZones) {
    for (final c in z.coffretsDirects) {
      if (isDoublon(c)) return 'Zone BT "${z.nom}"';
    }
    for (final l in z.locaux) {
      for (final c in l.coffrets) {
        if (isDoublon(c)) return 'Local "${l.nom}" (Zone BT "${z.nom}")';
      }
    }
  }
  return null;
}

  // ═══════════════════════════════════════════════════════════════
  // MÉTHODES - INSPECTIONS ÉCLAIRAGE
  // ═══════════════════════════════════════════════════════════════

  static Box<LightingInspection> get _lightingBox =>
      Hive.box<LightingInspection>(_lightingInspectionBox);

  /// Récupère toutes les inspections d'éclairage pour une mission donnée
  static List<LightingInspection> getLightingInspectionsByMissionId(
      String missionId) {
    return _lightingBox.values
        .where((inspection) => inspection.missionId == missionId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Récupère une inspection d'éclairage par son ID
  static LightingInspection? getLightingInspectionById(String inspectionId) {
    try {
      return _lightingBox.values
          .firstWhere((inspection) => inspection.id == inspectionId);
    } catch (_) {
      return null;
    }
  }

  /// Sauvegarde ou met à jour une inspection d'éclairage
  static Future<void> saveLightingInspection(
      LightingInspection inspection) async {
    inspection.updatedAt = DateTime.now();
    await _lightingBox.put(inspection.id, inspection);
  }

  /// Supprime une inspection d'éclairage par son ID
  static Future<void> deleteLightingInspection(String inspectionId) async {
    await _lightingBox.delete(inspectionId);
  }

  /// Récupère la liste de toutes les options de transformateurs MT de la mission avec local et numéro d'ordre
  static List<MissionTransformateurOption> getAllTransformateurOptionsForMission(String missionId) {
    if (!Hive.isBoxOpen(_auditBox)) return [];
    final box = Hive.box<AuditInstallationsElectriques>(_auditBox);
    final audit = box.values.cast<AuditInstallationsElectriques?>().firstWhere(
      (a) => a?.missionId == missionId,
      orElse: () => null,
    );
    if (audit == null) return [];

    final list = <MissionTransformateurOption>[];
    final seenIds = <String>{};
    int orderCounter = 1;

    void addTransfo(TransformateurMTBT? t, String localNom) {
      if (t == null) return;
      final sid = (t.syncId != null && t.syncId!.trim().isNotEmpty)
          ? t.syncId!.trim()
          : 'tr_${t.nom ?? ''}_${t.repere ?? ''}_${t.puissanceAssignee}';
      if (seenIds.add(sid)) {
        list.add(MissionTransformateurOption(
          transformateur: t,
          localNom: localNom,
          orderIndex: orderCounter++,
        ));
      }
    }

    // 1. Locaux MT directs
    for (final l in audit.moyenneTensionLocaux) {
      final lNom = l.nom.trim().isNotEmpty ? l.nom.trim() : 'Local MT';
      if (l.transformateur != null) addTransfo(l.transformateur, lNom);
      for (final t in l.transformateurs) {
        addTransfo(t, lNom);
      }
    }

    // 2. MoyenneTensionZones
    for (final z in audit.moyenneTensionZones) {
      for (final l in z.locaux) {
        final lNom = l.nom.trim().isNotEmpty ? l.nom.trim() : 'Local MT';
        if (l.transformateur != null) addTransfo(l.transformateur, lNom);
        for (final t in l.transformateurs) {
          addTransfo(t, lNom);
        }
      }
    }

    // 3. BasseTensionZones
    for (final z in audit.basseTensionZones) {
      for (final l in z.locaux) {
        final lNom = l.nom.trim().isNotEmpty ? l.nom.trim() : 'Local BT';
        for (final t in l.transformateurs) {
          addTransfo(t, lNom);
        }
      }
    }

    return list;
  }

  /// Récupère la liste de tous les transformateurs MT de la mission (locaux MT, zones MT, zones BT)
  static List<TransformateurMTBT> getAllTransformateursForMission(String missionId) {
    return getAllTransformateurOptionsForMission(missionId).map((o) => o.transformateur).toList();
  }

  /// Formate le libellé d'affichage conventionnel d'un transformateur
  static String formatTransformateurDisplayName(TransformateurMTBT t, {String? localNom, int? orderIndex}) {
    final tNom = t.nom?.trim() ?? '';
    final baseName = tNom.isNotEmpty
        ? tNom
        : (() {
            final p = t.puissanceAssignee.trim();
            final pStr = p.isNotEmpty ? (p.toLowerCase().contains('kva') ? p : '$p kVA') : '';
            final orderStr = orderIndex != null ? '$orderIndex' : (t.repere?.trim().isNotEmpty == true ? t.repere!.trim() : '');
            return 'Transformateur ${orderStr.isNotEmpty ? orderStr : ''}${pStr.isNotEmpty ? ' $pStr' : ''}'.trim();
          })();
    if (localNom != null && localNom.trim().isNotEmpty) {
      return '${localNom.trim()} - $baseName';
    }
    return baseName;
  }
}

/// Modèle d'option de transformateur dans une mission associant le transformateur à son local et numéro d'ordre
class MissionTransformateurOption {
  final TransformateurMTBT transformateur;
  final String localNom;
  final int orderIndex;

  MissionTransformateurOption({
    required this.transformateur,
    required this.localNom,
    required this.orderIndex,
  });

  String get id {
    if (transformateur.syncId != null && transformateur.syncId!.trim().isNotEmpty) {
      return transformateur.syncId!.trim();
    }
    return 'tr_${transformateur.nom ?? ''}_${transformateur.repere ?? ''}_${transformateur.puissanceAssignee}';
  }

  /// Nom seul du transformateur (sans le chemin/local) :
  /// - Si son nom est rempli : le nom du transfo
  /// - Si son nom n'est pas rempli : Transformateur x + sa puissance kVA
  String get transformerName {
    final tNom = transformateur.nom?.trim() ?? '';
    if (tNom.isNotEmpty) {
      return tNom;
    }
    final p = transformateur.puissanceAssignee.trim();
    if (p.isNotEmpty) {
      final pKva = p.toLowerCase().contains('kva') ? p : '$p kVA';
      return 'Transformateur $orderIndex $pKva';
    }
    return 'Transformateur $orderIndex';
  }

  /// Libellé affiché dans la liste déroulante : "le local - le nom du transfo"
  String get dropdownLabel {
    final loc = localNom.trim().isNotEmpty ? localNom.trim() : 'Local';
    return '$loc - $transformerName';
  }
}

// ═══════════════════════════════════════════════════════════════
// CLASSES DE RÉSULTATS
// ═══════════════════════════════════════════════════════════════

class SecureLoginResult {
  final bool success;
  final Verificateur? user;
  final String? errorMessage;
  final bool isLocked;
  final int remainingAttempts;
  
  SecureLoginResult({
    required this.success,
    this.user,
    this.errorMessage,
    this.isLocked = false,
    this.remainingAttempts = 5,
  });
}

/// Structure d'équipement typée pour les essais de mesure d'isolement
class EquipementIsolementItem {
  final String id;
  final String nom;
  final String type;
  final String repere;
  final String zone;
  final String? sectionPointA;
  final String? sectionPointB;

  const EquipementIsolementItem({
    required this.id,
    required this.nom,
    required this.type,
    required this.repere,
    this.zone = '',
    this.sectionPointA,
    this.sectionPointB,
  });

  String get displayName {
    final parts = <String>[];
    final z = zone.trim();
    final r = repere.trim();
    final n = nom.trim();

    if (z.isNotEmpty) parts.add(z);
    if (r.isNotEmpty && r != z) parts.add(r);
    if (n.isNotEmpty) parts.add(n);

    return parts.join(' - ');
  }
}

/// Équipement BT éligible pour le test CPI (relié à un transformateur MT en régime IT,
/// ou équipement historique sans transfo créé avant kCpiEvolutionCutoff)
class CpiEligibleEquipment {
  final String id;
  final String equipmentNom;
  final String type;
  final String repere;
  final String zone;
  final String? transformateurId;
  final String? transformateurNom;
  final bool isHistorical;

  const CpiEligibleEquipment({
    required this.id,
    required this.equipmentNom,
    required this.type,
    required this.repere,
    this.zone = '',
    this.transformateurId,
    this.transformateurNom,
    this.isHistorical = false,
  });

  String get displayName {
    final parts = <String>[];
    final z = zone.trim();
    final r = repere.trim();
    final n = equipmentNom.trim();

    if (z.isNotEmpty) parts.add(z);
    if (r.isNotEmpty && r != z) parts.add(r);
    if (n.isNotEmpty) parts.add(n);

    return parts.join(' - ');
  }
}