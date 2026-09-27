// lib/features/mission/domain/entities/mission_entity.dart
class MissionEntity {
  final String id;
  final String nomClient;
  final String? activiteClient;
  final String? activiteSurSite;
  final String? classementReglementaire;
  final String? classementReglementaireType;
  final String? classementReglementaireCategorie;
  final String? adresseClient;
  final String? logoClient;
  final String? qrCodeClient;
  final String? qrCodeQ18;
  final List<String>? accompagnateurs;
  final List<Map<String, dynamic>>? verificateurs;
  final String? dgResponsable;
  final DateTime? dateIntervention;
  final DateTime? dateRapport;
  final String? natureMission;
  final String? periodicite;
  final int? dureeMissionJours;
  final bool docCahierPrescriptions;
  final bool docNotesCalculs;
  final bool docSchemasUnifilaires;
  final bool docPlanMasse;
  final bool docPlansArchitecturaux;
  final bool docDeclarationsCe;
  final bool docListeInstallations;
  final bool docPlanLocauxRisques;
  final bool docRapportAnalyseFoudre;
  final bool docRapportEtudeFoudre;
  final bool docRegistreSecurite;
  final bool docRapportDerniereVerif;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String? descriptionInstallationsId;
  final String? auditInstallationsElectriquesId;
  final bool docAutre;
  final String? classementLocauxId;
  final List<String>? foudreIds;
  final String? mesuresEssaisId;
  final String? renseignementsGenerauxId;
  final String? nomSite;
  final String? jsaId;
  final String? schemaOption;
  final List<String> autresDocuments;
  final String? installation;
  final List<String>? perimetreMission;
  final bool afficherTableauFoudre;
  final String? recepteurRapport;
  final String? lieuIntervention;
  final String? recepteurCivilite;
  final String? recepteurNom;
  final String? recepteurFonction;
  final String? recepteurEmail;
  final String? recepteurTelephone;

  const MissionEntity({
    required this.id,
    required this.nomClient,
    this.activiteClient,
    this.activiteSurSite,
    this.classementReglementaire,
    this.classementReglementaireType,
    this.classementReglementaireCategorie,
    this.adresseClient,
    this.logoClient,
    this.qrCodeClient,
    this.qrCodeQ18,
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
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.descriptionInstallationsId,
    this.auditInstallationsElectriquesId,
    this.docAutre = false,
    this.classementLocauxId,
    this.foudreIds,
    this.mesuresEssaisId,
    this.renseignementsGenerauxId,
    this.nomSite,
    this.jsaId,
    this.schemaOption,
    this.autresDocuments = const [],
    this.installation,
    this.perimetreMission,
    this.afficherTableauFoudre = false,
    this.recepteurRapport,
    this.lieuIntervention,
    this.recepteurCivilite,
    this.recepteurNom,
    this.recepteurFonction,
    this.recepteurEmail,
    this.recepteurTelephone,
  });

  bool get isEnAttente => status.toLowerCase() == 'en_attente';
  bool get isEnCours => status.toLowerCase() == 'en_cours' || status.toLowerCase() == 'en cours';
  bool get isTermine => status.toLowerCase() == 'termine' || status.toLowerCase() == 'terminé';
}
