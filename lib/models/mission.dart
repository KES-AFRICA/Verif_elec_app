// lib/models/mission.dart
import 'package:hive/hive.dart';

part 'mission.g.dart';

@HiveType(typeId: 1)
class Mission extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nomClient;

  @HiveField(2)
  String? activiteClient;

  @HiveField(3)
  String? adresseClient;

  @HiveField(4)
  String? logoClient;

  @HiveField(5)
  List<String>? accompagnateurs;

  @HiveField(6)
  List<Map<String, dynamic>>? verificateurs;

  @HiveField(7)
  String? dgResponsable;

  @HiveField(8)
  DateTime? dateIntervention;

  @HiveField(9)
  DateTime? dateRapport;

  @HiveField(10)
  String? natureMission;

  @HiveField(11)
  String? periodicite;

  @HiveField(12)
  int? dureeMissionJours;

  @HiveField(13, defaultValue: false)
  bool docCahierPrescriptions;

  @HiveField(14, defaultValue: false)
  bool docNotesCalculs;

  @HiveField(15, defaultValue: false)
  bool docSchemasUnifilaires;

  @HiveField(16, defaultValue: false)
  bool docPlanMasse;

  @HiveField(17, defaultValue: false)
  bool docPlansArchitecturaux;

  @HiveField(18, defaultValue: false)
  bool docDeclarationsCe;

  @HiveField(19, defaultValue: false)
  bool docListeInstallations;

  @HiveField(20, defaultValue: false)
  bool docPlanLocauxRisques;

  @HiveField(21, defaultValue: false)
  bool docRapportAnalyseFoudre;

  @HiveField(22, defaultValue: false)
  bool docRapportEtudeFoudre;

  @HiveField(23, defaultValue: false)
  bool docRegistreSecurite;

  @HiveField(24, defaultValue: false)
  bool docRapportDerniereVerif;

  @HiveField(25)
  DateTime createdAt;

  @HiveField(26)
  DateTime updatedAt;

  @HiveField(27, defaultValue: 'brouillon')
  String status;

  @HiveField(28)
  String? descriptionInstallationsId;

  @HiveField(29)
  String? auditInstallationsElectriquesId;

  @HiveField(30, defaultValue: false)
  bool docAutre;

  @HiveField(31)
  String? classementLocauxId;

  @HiveField(32)
  List<String>? foudreIds;

  @HiveField(33)
  String? mesuresEssaisId;

  @HiveField(34)
  String? renseignementsGenerauxId;

  @HiveField(35)
  String? nomSite;

  @HiveField(36)
  String? jsaId;

  @HiveField(37)
  String? schemaOption;

  @HiveField(38)
  List<String> autresDocuments;

  @HiveField(39)
  String? installation;

  @HiveField(40)
  List<String>? perimetreMission;

  @HiveField(41)
  String? qrCodeClient;

  @HiveField(42)
  String? activiteSurSite;

  @HiveField(43)
  String? classementReglementaireType;

  @HiveField(44)
  String? classementReglementaireCategorie;

  @HiveField(45, defaultValue: false)
  bool afficherTableauFoudre;

  @HiveField(46)
  String? classementReglementaire;

  @HiveField(47)
  String? recepteurRapport;

  @HiveField(48)
  String? lieuIntervention;

  @HiveField(49)
  String? recepteurCivilite;

  @HiveField(50)
  String? recepteurNom;

  @HiveField(51)
  String? recepteurFonction;

  @HiveField(52)
  String? recepteurEmail;

  @HiveField(53)
  String? recepteurTelephone;

  @HiveField(54, defaultValue: false)
  bool docRapportQ18;

  @HiveField(55, defaultValue: 'sans_objet')
  String? centralePhotovoltaique;

  @HiveField(56)
  String? qrCodeQ18;

  Mission({
    required this.id,
    required this.nomClient,
    this.activiteClient,
    this.activiteSurSite,
    this.classementReglementaire,
    this.classementReglementaireType,
    this.classementReglementaireCategorie,
    this.afficherTableauFoudre = false,
    this.adresseClient,
    this.logoClient,
    this.accompagnateurs,
    this.verificateurs,
    this.dgResponsable,
    this.dateIntervention,
    this.dateRapport,
    this.natureMission,
    this.periodicite,
    this.dureeMissionJours,
    this.docCahierPrescriptions = false,
    this.docNotesCalculs = false,
    this.docSchemasUnifilaires = false,
    this.docPlanMasse = false,
    this.docPlansArchitecturaux = false,
    this.docDeclarationsCe = false,
    this.docListeInstallations = false,
    this.docPlanLocauxRisques = false,
    this.docRapportAnalyseFoudre = false,
    this.docRapportEtudeFoudre = false,
    this.docRegistreSecurite = false,
    this.docRapportDerniereVerif = false,
    this.docRapportQ18 = false,
    this.centralePhotovoltaique = 'sans_objet',
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.descriptionInstallationsId,
    this.auditInstallationsElectriquesId,
    this.docAutre = false,
    this.classementLocauxId,
    this.foudreIds,
    this.mesuresEssaisId,
    this.nomSite,
    this.jsaId,
    this.schemaOption,
    List<String>? autresDocuments,
    this.installation,
    this.perimetreMission,
    this.qrCodeClient,
    this.qrCodeQ18,
    this.recepteurRapport,
    this.lieuIntervention,
    this.recepteurCivilite,
    this.recepteurNom,
    this.recepteurFonction,
    this.recepteurEmail,
    this.recepteurTelephone,
  }) : autresDocuments = autresDocuments ?? [];

  /// Fonction effective du récepteur (source de vérité : recepteurFonction, repli historique : recepteurRapport)
  String get effectiveRecepteurFonction {
    if (recepteurFonction != null && recepteurFonction!.trim().isNotEmpty) {
      return recepteurFonction!.trim();
    }
    if (recepteurRapport != null && recepteurRapport!.trim().isNotEmpty) {
      return recepteurRapport!.trim();
    }
    return '';
  }

  /// Nom effectif du récepteur
  String get effectiveRecepteurNom => recepteurNom?.trim() ?? '';

  /// Civilité effective du récepteur
  String? get effectiveRecepteurCivilite {
    if (recepteurCivilite != null && recepteurCivilite!.trim().isNotEmpty) {
      return recepteurCivilite!.trim();
    }
    if (effectiveRecepteurFonction.isNotEmpty || (recepteurNom != null && recepteurNom!.trim().isNotEmpty)) {
      return 'Monsieur';
    }
    return null;
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? '',
      nomClient: json['nom_client'] ?? '',
      activiteClient: json['activite_client'],
      adresseClient: json['adresse_client'],
      logoClient: json['logo_client'],
      qrCodeClient: json['qr_code_client'],
      accompagnateurs: json['accompagnateurs'] != null
          ? List<String>.from(json['accompagnateurs'])
          : null,
      verificateurs: json['verificateurs'] != null
          ? List<Map<String, dynamic>>.from(
              json['verificateurs'].map((v) => Map<String, dynamic>.from(v)))
          : null,
      dgResponsable: json['dg_responsable'],
      dateIntervention: json['date_intervention'] != null
          ? DateTime.parse(json['date_intervention'])
          : null,
      dateRapport: json['date_rapport'] != null
          ? DateTime.parse(json['date_rapport'])
          : null,
      natureMission: json['nature_mission'],
      periodicite: json['periodicite'],
      dureeMissionJours: json['duree_mission_jours'],
      docCahierPrescriptions: json['doc_cahier_prescriptions'] ?? false,
      docNotesCalculs: json['doc_notes_calculs'] ?? false,
      docSchemasUnifilaires: json['doc_schemas_unifilaires'] ?? false,
      docPlanMasse: json['doc_plan_masse'] ?? false,
      docPlansArchitecturaux: json['doc_plans_architecturaux'] ?? false,
      docDeclarationsCe: json['doc_declarations_ce'] ?? false,
      docListeInstallations: json['doc_liste_installations'] ?? false,
      docPlanLocauxRisques: json['doc_plan_locaux_risques'] ?? false,
      docRapportAnalyseFoudre: json['doc_rapport_analyse_foudre'] ?? false,
      docRapportEtudeFoudre: json['doc_rapport_etude_foudre'] ?? false,
      docRegistreSecurite: json['doc_registre_securite'] ?? false,
      docRapportDerniereVerif: json['doc_rapport_derniere_verif'] ?? false,
      docRapportQ18: json['doc_rapport_q18'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      status: json['status'] ?? 'active',
      descriptionInstallationsId: json['description_installations_id'],
      auditInstallationsElectriquesId: json['audit_installations_electriques_id'],
      docAutre: json['doc_autre'] ?? false,
      classementLocauxId: json['classement_locaux_id'],
      foudreIds: json['foudre_ids'] != null
          ? List<String>.from(json['foudre_ids'])
          : null,
      mesuresEssaisId: json['mesures_essais_id'],
      nomSite: json['nom_site'],
      jsaId: json['jsa_id'],
      schemaOption: json['schema_option'],
      autresDocuments: json['autres_documents'] != null
          ? List<String>.from(json['autres_documents'])
          : [],
      installation: json['installation'] as String?,
      perimetreMission: json['perimetre_mission'] != null
          ? List<String>.from(json['perimetre_mission'])
          : null,
      activiteSurSite: json['activite_sur_site'],
      classementReglementaire: json['classement_reglementaire'] ?? json['classementReglementaire'],
      classementReglementaireType: json['classement_reglementaire_type'] ?? json['classementReglementaireType'],
      classementReglementaireCategorie: json['classement_reglementaire_categorie'] ?? json['classementReglementaireCategorie'],
      afficherTableauFoudre: json['afficher_tableau_foudre'] ?? false,
      recepteurRapport: json['recepteur_rapport'] ?? json['recepteurRapport'],
      lieuIntervention: json['lieu_intervention'] ?? json['lieuIntervention'],
      recepteurCivilite: json['recepteur_civilite'] ?? json['recepteurCivilite'],
      recepteurNom: json['recepteur_nom'] ?? json['recepteurNom'],
      recepteurFonction: json['recepteur_fonction'] ?? json['recepteurFonction'],
      recepteurEmail: json['recepteur_email'] ?? json['recepteurEmail'],
      recepteurTelephone: json['recepteur_telephone'] ?? json['recepteurTelephone'],
      centralePhotovoltaique: json['centrale_photovoltaique'] ?? 'sans_objet',
      qrCodeQ18: json['qr_code_q18'] ?? json['qrCodeQ18'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_client': nomClient,
      'activite_client': activiteClient,
      'activite_sur_site': activiteSurSite,
      'classement_reglementaire': classementReglementaire,
      'classement_reglementaire_type': classementReglementaireType,
      'classement_reglementaire_categorie': classementReglementaireCategorie,
      'afficher_tableau_foudre': afficherTableauFoudre,
      'adresse_client': adresseClient,
      'logo_client': logoClient,
      'qr_code_client': qrCodeClient,
      'accompagnateurs': accompagnateurs,
      'verificateurs': verificateurs,
      'dg_responsable': dgResponsable,
      'date_intervention': dateIntervention?.toIso8601String(),
      'date_rapport': dateRapport?.toIso8601String(),
      'nature_mission': natureMission,
      'periodicite': periodicite,
      'duree_mission_jours': dureeMissionJours,
      'doc_cahier_prescriptions': docCahierPrescriptions,
      'doc_notes_calculs': docNotesCalculs,
      'doc_schemas_unifilaires': docSchemasUnifilaires,
      'doc_plan_masse': docPlanMasse,
      'doc_plans_architecturaux': docPlansArchitecturaux,
      'doc_declarations_ce': docDeclarationsCe,
      'doc_liste_installations': docListeInstallations,
      'doc_plan_locaux_risques': docPlanLocauxRisques,
      'doc_rapport_analyse_foudre': docRapportAnalyseFoudre,
      'doc_rapport_etude_foudre': docRapportEtudeFoudre,
      'doc_registre_securite': docRegistreSecurite,
      'doc_rapport_derniere_verif': docRapportDerniereVerif,
      'doc_rapport_q18': docRapportQ18,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'description_installations_id': descriptionInstallationsId,
      'audit_installations_electriques_id': auditInstallationsElectriquesId,
      'doc_autre': docAutre,
      'classement_locaux_id': classementLocauxId,
      'foudre_ids': foudreIds,
      'mesures_essais_id': mesuresEssaisId,
      'nom_site': nomSite,
      'jsa_id': jsaId,
      'schema_option': schemaOption,
      'autres_documents': autresDocuments,
      'installation': installation,
      'perimetre_mission': perimetreMission,
      'recepteur_rapport': recepteurRapport,
      'lieu_intervention': lieuIntervention,
      'recepteur_civilite': recepteurCivilite,
      'recepteur_nom': recepteurNom,
      'recepteur_fonction': recepteurFonction,
      'recepteur_email': recepteurEmail,
      'recepteur_telephone': recepteurTelephone,
      'centrale_photovoltaique': centralePhotovoltaique ?? 'sans_objet',
      'qr_code_q18': qrCodeQ18,
    };
  }

  // Méthodes utilitaires pour vérifier le statut
  bool get isEnAttente => status.toLowerCase() == 'en_attente';
  bool get isEnCours => status.toLowerCase() == 'en_cours' || status.toLowerCase() == 'en cours';
  bool get isTermine => status.toLowerCase() == 'termine' || status.toLowerCase() == 'terminé';

  // ✅ NOUVEAU : Méthodes utilitaires pour les documents personnalisés
  bool hasDocumentPersonnalise(String documentNom) {
    return autresDocuments.contains(documentNom);
  }

  void ajouterDocumentPersonnalise(String documentNom) {
    if (!autresDocuments.contains(documentNom)) {
      autresDocuments.add(documentNom);
    }
  }

  void supprimerDocumentPersonnalise(String documentNom) {
    autresDocuments.remove(documentNom);
  }
}