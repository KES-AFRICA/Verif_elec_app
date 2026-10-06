// audit_installations_electriques.dart
import 'package:hive/hive.dart';
import '../core/utils/source_status_resolver.dart';
import '../services/dispositions_constructives_registry.dart';
import '../utils/observation_text_normalizer.dart';

part 'audit_installations_electriques.g.dart';

@HiveType(typeId: 3)
class AuditInstallationsElectriques extends HiveObject {
  @HiveField(0)
  String missionId;

  @HiveField(1)
  DateTime updatedAt;

  @HiveField(20)
  DateTime? createdAt;

  // MOYENNE TENSION
  @HiveField(2)
  List<MoyenneTensionLocal> moyenneTensionLocaux;

  @HiveField(3)
  List<MoyenneTensionZone> moyenneTensionZones;

  // BASSE TENSION
  @HiveField(4)
  List<BasseTensionZone> basseTensionZones;

  // PHOTOS GLOBALES DE L'AUDIT
  @HiveField(15)
  List<String> photos; // Chemins des photos générales de l'audit

  AuditInstallationsElectriques({
    required this.missionId,
    required this.updatedAt,
    this.createdAt,
    List<MoyenneTensionLocal>? moyenneTensionLocaux,
    List<MoyenneTensionZone>? moyenneTensionZones,
    List<BasseTensionZone>? basseTensionZones,
    List<String>? photos,
  })  : moyenneTensionLocaux = moyenneTensionLocaux ?? [],
        moyenneTensionZones = moyenneTensionZones ?? [],
        basseTensionZones = basseTensionZones ?? [],
        photos = photos ?? [];

  factory AuditInstallationsElectriques.create(String missionId) {
    final now = DateTime.now().toUtc();
    return AuditInstallationsElectriques(
      missionId: missionId,
      updatedAt: now,
      createdAt: now,
      moyenneTensionLocaux: [],
      moyenneTensionZones: [],
      basseTensionZones: [],
      photos: [],
    );
  }
}

// STRUCTURES MOYENNE TENSION
@HiveType(typeId: 4)
class MoyenneTensionLocal {
  @HiveField(0)
  String nom;

  @HiveField(1)
  String type;

  // SECTIONS DU LOCAL
  @HiveField(2)
  List<ElementControle> dispositionsConstructives;

  @HiveField(3)
  List<ElementControle> conditionsExploitation;

  @HiveField(4)
  Cellule? cellule;

  @HiveField(5)
  TransformateurMTBT? transformateur;

  // COFFRETS DANS CE LOCAL
  @HiveField(6)
  List<CoffretArmoire> coffrets;

  @HiveField(7)
  List<ObservationLibre> observationsLibres; 

  // PHOTOS DU LOCAL
  @HiveField(8)
  List<String> photos; // Chemins des photos spécifiques à ce local

  @HiveField(30)
  List<Cellule> cellules = [];
  
  @HiveField(31)
  List<TransformateurMTBT> transformateurs = [];

  @HiveField(32)
  bool accessible;

  @HiveField(33)
  bool aReverifier;

  @HiveField(34)
  bool isRiskZone;

  @HiveField(40)
  String? id;

  @HiveField(41)
  DateTime? createdAt;

  @HiveField(42)
  DateTime? updatedAt;

  String get localId {
    if (id != null && id!.trim().isNotEmpty) return id!;
    final createdTs = createdAt?.millisecondsSinceEpoch ?? 0;
    final stableHash = nom.trim().hashCode.abs();
    id = 'local_${createdTs}_$stableHash';
    return id!;
  }

  MoyenneTensionLocal({
    String? id,
    required this.nom,
    required this.type,
    this.createdAt,
    this.updatedAt,
    List<ElementControle>? dispositionsConstructives,
    List<ElementControle>? conditionsExploitation,
    this.cellule,
    this.transformateur,
    List<CoffretArmoire>? coffrets,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    List<Cellule>? cellules,
    List<TransformateurMTBT>? transformateurs,
    bool? accessible,
    bool? aReverifier,
    bool? isRiskZone,
  })  : id = (id != null && id.trim().isNotEmpty)
            ? id
            : (createdAt != null)
                ? 'local_${createdAt.millisecondsSinceEpoch}_${nom.trim().hashCode.abs()}'
                : 'local_${nom.trim().hashCode.abs()}',
        dispositionsConstructives = dispositionsConstructives ?? [],
        conditionsExploitation = conditionsExploitation ?? [],
        coffrets = coffrets ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        cellules = cellules ?? [],
        transformateurs = transformateurs ?? [],
        accessible = accessible ?? true,
        aReverifier = aReverifier ?? false,
        isRiskZone = isRiskZone ?? false;

  // MÉTHODE DE MIGRATION (préserve les données existantes)
  void migrateFromOldFields() {
    // Migrer l'ancienne cellule unique vers la liste
    if (cellule != null && cellules.isEmpty) {
      cellules.add(cellule!);
    }
    // Migrer l'ancien transformateur unique vers la liste
    if (transformateur != null && transformateurs.isEmpty) {
      transformateurs.add(transformateur!);
    }
    DispositionsConstructivesRegistry.ensureCompleteLocalChecklists(
      dispositionsConstructives: dispositionsConstructives,
      conditionsExploitation: conditionsExploitation,
    );
  }
  
  // GETTER POUR COMPATIBILITÉ (optionnel, peut être supprimé plus tard)
  Cellule? get primaryCellule => cellules.isNotEmpty ? cellules.first : cellule;
  TransformateurMTBT? get primaryTransformateur => transformateurs.isNotEmpty ? transformateurs.first : transformateur;

}

@HiveType(typeId: 5)
class MoyenneTensionZone {
  @HiveField(0)
  String nom;

  @HiveField(1)
  String? description;

  @HiveField(2)
  List<CoffretArmoire> coffrets;

  @HiveField(3)
  List<ObservationLibre> observationsLibres; 

  // PHOTOS DE LA ZONE
  @HiveField(4)
  List<String> photos; // Chemins des photos de la zone

  @HiveField(5)
  List<MoyenneTensionLocal> locaux;

  @HiveField(6)
  String? classementZoneId;

  @HiveField(7)
  bool isRiskZone;

  @HiveField(40)
  String? id;

  @HiveField(41)
  DateTime? createdAt;

  @HiveField(42)
  DateTime? updatedAt;

  String get zoneId {
    if (id != null && id!.trim().isNotEmpty) return id!;
    final createdTs = createdAt?.millisecondsSinceEpoch ?? 0;
    final stableHash = nom.trim().hashCode.abs();
    id = 'zone_${createdTs}_$stableHash';
    return id!;
  }

  MoyenneTensionZone({
    String? id,
    required this.nom,
    this.description,
    this.createdAt,
    this.updatedAt,
    List<CoffretArmoire>? coffrets,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    List<MoyenneTensionLocal>? locaux,
    this.classementZoneId,
    bool? isRiskZone,
  })  : id = (id != null && id.trim().isNotEmpty)
            ? id
            : (createdAt != null)
                ? 'zone_${createdAt.millisecondsSinceEpoch}_${nom.trim().hashCode.abs()}'
                : 'zone_${nom.trim().hashCode.abs()}',
        coffrets = coffrets ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        locaux = locaux ?? [],
        isRiskZone = isRiskZone ?? false;
}

// STRUCTURES BASSE TENSION
@HiveType(typeId: 6)
class BasseTensionZone {
  @HiveField(0)
  String nom;

  @HiveField(1)
  String? description;

  @HiveField(2)
  List<BasseTensionLocal> locaux;

  @HiveField(3)
  List<CoffretArmoire> coffretsDirects;

  @HiveField(4)
  List<ObservationLibre> observationsLibres; 

  // PHOTOS DE LA ZONE
  @HiveField(5)
  List<String> photos; // Chemins des photos de la zone basse tension

  @HiveField(6)
  String? classementZoneId;

  @HiveField(7)
  bool isRiskZone;

  @HiveField(40)
  String? id;

  @HiveField(41)
  DateTime? createdAt;

  @HiveField(42)
  DateTime? updatedAt;

  String get zoneId {
    if (id != null && id!.trim().isNotEmpty) return id!;
    final createdTs = createdAt?.millisecondsSinceEpoch ?? 0;
    final stableHash = nom.trim().hashCode.abs();
    id = 'zone_${createdTs}_$stableHash';
    return id!;
  }

  BasseTensionZone({
    String? id,
    required this.nom,
    this.description,
    this.createdAt,
    this.updatedAt,
    List<BasseTensionLocal>? locaux,
    List<CoffretArmoire>? coffretsDirects,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    this.classementZoneId,
    bool? isRiskZone,
  })  : id = (id != null && id.trim().isNotEmpty)
            ? id
            : (createdAt != null)
                ? 'zone_${createdAt.millisecondsSinceEpoch}_${nom.trim().hashCode.abs()}'
                : 'zone_${nom.trim().hashCode.abs()}',
        locaux = locaux ?? [],
        coffretsDirects = coffretsDirects ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        isRiskZone = isRiskZone ?? false;
}

@HiveType(typeId: 7)
class BasseTensionLocal {
  @HiveField(0)
  String nom;

  @HiveField(1)
  String type; // LOCAL_GROUPE_ELECTROGENE, LOCAL_TGBT, LOCAL_ONDULEUR, etc.

  // SECTIONS SPÉCIFIQUES PAR TYPE
  @HiveField(2)
  List<ElementControle>? dispositionsConstructives;

  @HiveField(3)
  List<ElementControle>? conditionsExploitation;

  // COFFRETS DANS CE LOCAL
  @HiveField(4)
  List<CoffretArmoire> coffrets;

  @HiveField(5)
  List<ObservationLibre> observationsLibres; 

  // PHOTOS DU LOCAL
  @HiveField(6)
  List<String> photos; // Chemins des photos spécifiques à ce local

  @HiveField(7)
  bool accessible;

  @HiveField(8)
  bool aReverifier;

  @HiveField(9)
  List<Cellule> cellules;

  @HiveField(10)
  List<TransformateurMTBT> transformateurs;

  @HiveField(11)
  bool isRiskZone;

  @HiveField(40)
  String? id;

  @HiveField(41)
  DateTime? createdAt;

  @HiveField(42)
  DateTime? updatedAt;

  String get localId {
    if (id != null && id!.trim().isNotEmpty) return id!;
    final createdTs = createdAt?.millisecondsSinceEpoch ?? 0;
    final stableHash = nom.trim().hashCode.abs();
    id = 'local_${createdTs}_$stableHash';
    return id!;
  }

  BasseTensionLocal({
    String? id,
    required this.nom,
    required this.type,
    this.createdAt,
    this.updatedAt,
    List<ElementControle>? dispositionsConstructives,
    List<ElementControle>? conditionsExploitation,
    List<CoffretArmoire>? coffrets,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    bool? accessible,
    bool? aReverifier,
    List<Cellule>? cellules,
    List<TransformateurMTBT>? transformateurs,
    bool? isRiskZone,
  })  : id = (id != null && id.trim().isNotEmpty)
            ? id
            : (createdAt != null)
                ? 'local_${createdAt.millisecondsSinceEpoch}_${nom.trim().hashCode.abs()}'
                : 'local_${nom.trim().hashCode.abs()}',
        dispositionsConstructives = dispositionsConstructives ?? [],
        conditionsExploitation = conditionsExploitation ?? [],
        coffrets = coffrets ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        accessible = accessible ?? true,
        aReverifier = aReverifier ?? false,
        cellules = cellules ?? [],
        transformateurs = transformateurs ?? [],
        isRiskZone = isRiskZone ?? false;
}

// STRUCTURES COMMUNES
@HiveType(typeId: 8)
class ElementControle {
  @HiveField(0)
  String elementControle;

  @HiveField(1)
  bool? conforme;

  @HiveField(2)
  String? observation;

  @HiveField(3)
  int? priorite; // 1, 2 ou 3

  // PHOTO LIÉE À CET ÉLÉMENT
  @HiveField(4)
  List<String> photos; // Photos spécifiques pour cet élément de contrôle

  @HiveField(5)
  String? referenceNormative;

  @HiveField(6)
  bool estNA;

  @HiveField(7)
  String? familleRisque;

  @HiveField(8)
  String? criticite;

  ElementControle({
    required this.elementControle,
    required this.conforme,
    this.observation,
    this.priorite,
    List<String>? photos,
    this.referenceNormative,
    bool? estNA,
    this.familleRisque,
    this.criticite,
  })  : photos = photos ?? [],
        estNA = estNA ?? false;

  String? referenceNormativeEffectiveFor({String? localType}) {
    final meta = DispositionsConstructivesRegistry.getMetadata(elementControle, localType: localType);
    final raw = (meta?.referenceNormative != null && meta!.referenceNormative!.isNotEmpty)
        ? meta.referenceNormative
        : referenceNormative;
    return DispositionsConstructivesRegistry.normalizeNormativeReference(raw);
  }

  String? get referenceNormativeEffective => referenceNormativeEffectiveFor();

  String? familleRisqueEffectiveFor({String? localType}) {
    final meta = DispositionsConstructivesRegistry.getMetadata(elementControle, localType: localType);
    if (meta?.familleRisque != null && meta!.familleRisque!.isNotEmpty) {
      return meta.familleRisque;
    }
    return familleRisque;
  }

  String? get familleRisqueEffective => familleRisqueEffectiveFor();

  String? criticiteEffectiveFor({String? localType}) {
    final meta = DispositionsConstructivesRegistry.getMetadata(elementControle, localType: localType);
    if (meta?.criticite != null && meta!.criticite!.isNotEmpty) {
      return meta.criticite;
    }
    return criticite;
  }

  String? get criticiteEffective => criticiteEffectiveFor();
}

@HiveType(typeId: 9)
class Cellule {
  @HiveField(0)
  String fonction;

  @HiveField(1)
  String type;

  @HiveField(2)
  String marqueModeleAnnee;

  @HiveField(3)
  String tensionAssignee;

  @HiveField(4)
  String pouvoirCoupure;

  @HiveField(5)
  String numerotation;

  @HiveField(6)
  String parafoudres;

  @HiveField(7)
  List<ElementControle> elementsVerifies;

  // PHOTOS DE LA CELLULE
  @HiveField(8)
  List<String> photos; // Chemins des photos de la cellule

  @HiveField(9)
  String? gamme;

  @HiveField(10)
  String? calibreDisjoncteur;

  @HiveField(11)
  String? sectionCables;

  @HiveField(12)
  String? natureReseau;

  @HiveField(13)
  List<ElementControle>? observations;

  @HiveField(14)
  String? presenceIacm;

  @HiveField(15)
  String? syncId;

  @HiveField(16)
  String? tensionService;

  @HiveField(17)
  String? nom;

  @HiveField(18)
  String? photo;

  @HiveField(19)
  String? repere;

  @HiveField(20)
  String? marque;

  @HiveField(21)
  String? modele;

  @HiveField(22)
  String? annee;

  @HiveField(23)
  DateTime? createdAt;

  @HiveField(24)
  DateTime? updatedAt;

  @HiveField(25)
  String? sectionCablePhase;

  @HiveField(26)
  String? sectionCableNeutre;

  @HiveField(27)
  int? conducteursPhase;

  @HiveField(28)
  int? conducteursNeutre;

  @HiveField(29)
  String? celluleDepart;

  Cellule({
    required this.fonction,
    required this.type,
    required this.marqueModeleAnnee,
    required this.tensionAssignee,
    required this.pouvoirCoupure,
    required this.numerotation,
    required this.parafoudres,
    this.createdAt,
    this.updatedAt,
    List<ElementControle>? elementsVerifies,
    List<String>? photos,
    this.gamme,
    this.calibreDisjoncteur,
    this.celluleDepart,
    this.sectionCables,
    this.natureReseau,
    List<ElementControle>? observations,
    this.presenceIacm,
    String? syncId,
    this.tensionService,
    this.nom,
    this.photo,
    this.repere,
    this.marque,
    this.modele,
    this.annee,
    this.sectionCablePhase,
    this.sectionCableNeutre,
    this.conducteursPhase,
    this.conducteursNeutre,
  })  : elementsVerifies = elementsVerifies ?? [],
        photos = photos ?? [],
        observations = observations ?? [],
        syncId = (syncId != null && syncId.isNotEmpty)
            ? syncId
            : (createdAt != null)
                ? 'cellule_${createdAt.millisecondsSinceEpoch}_${(nom ?? fonction).trim().hashCode.abs()}'
                : 'cellule_${(fonction.trim() + (nom ?? '')).hashCode.abs()}';

  /// Résout le repère effectif de la cellule (nom du local parent s'il est connu, sinon repere stocké)
  String getEffectiveRepere(String? parentLocalNom) {
    if (parentLocalNom != null && parentLocalNom.trim().isNotEmpty) {
      return parentLocalNom.trim();
    }
    if (repere != null && repere!.trim().isNotEmpty) {
      return repere!.trim();
    }
    return '';
  }

  /// Résout la section de câble phase effective (fallback sur historique sectionCables)
  String? get effectiveSectionCablePhase =>
      (sectionCablePhase != null && sectionCablePhase!.trim().isNotEmpty)
          ? sectionCablePhase
          : sectionCables;

  /// Résout la section de câble neutre effective (fallback sur phase puis historique sectionCables)
  String? get effectiveSectionCableNeutre =>
      (sectionCableNeutre != null && sectionCableNeutre!.trim().isNotEmpty)
          ? sectionCableNeutre
          : effectiveSectionCablePhase;

  /// Nombre effectif de conducteurs phase (1 par défaut si section présente, null sinon)
  int? get effectiveConducteursPhase {
    if (conducteursPhase != null && conducteursPhase! > 0) return conducteursPhase;
    final sec = effectiveSectionCablePhase;
    if (sec != null && sec.trim().isNotEmpty && sec.trim() != '-') return 1;
    return null;
  }

  /// Nombre effectif de conducteurs neutre (1 par défaut si section présente, null sinon)
  int? get effectiveConducteursNeutre {
    if (conducteursNeutre != null && conducteursNeutre! > 0) return conducteursNeutre;
    final sec = effectiveSectionCableNeutre;
    if (sec != null && sec.trim().isNotEmpty && sec.trim() != '-') return 1;
    return null;
  }

  /// Résout la marque effective avec fallback rétrocompatible
  String get effectiveMarque {
    if (marque != null && marque!.trim().isNotEmpty) {
      return marque!.trim();
    }
    return marqueModeleAnnee.trim();
  }

  /// Résout le modèle effectif avec fallback
  String get effectiveModele => modele?.trim() ?? '';

  /// Résout l'année effective avec fallback
  String get effectiveAnnee => annee?.trim() ?? '';

  /// Formate l'ensemble des informations constructeur
  String get formattedMarqueModeleAnnee {
    final m = effectiveMarque;
    final mod = effectiveModele;
    final a = effectiveAnnee;
    final parts = [m, mod, a].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' / ');
    return marqueModeleAnnee;
  }

  Cellule copyWith({
    String? fonction,
    String? type,
    String? marqueModeleAnnee,
    String? tensionAssignee,
    String? pouvoirCoupure,
    String? numerotation,
    String? parafoudres,
    List<ElementControle>? elementsVerifies,
    List<String>? photos,
    String? gamme,
    String? calibreDisjoncteur,
    String? celluleDepart,
    String? sectionCables,
    String? natureReseau,
    List<ElementControle>? observations,
    String? presenceIacm,
    String? syncId,
    String? tensionService,
    String? nom,
    String? photo,
    String? repere,
    String? marque,
    String? modele,
    String? annee,
    String? sectionCablePhase,
    String? sectionCableNeutre,
    int? conducteursPhase,
    int? conducteursNeutre,
  }) {
    return Cellule(
      fonction: fonction ?? this.fonction,
      type: type ?? this.type,
      marqueModeleAnnee: marqueModeleAnnee ?? this.marqueModeleAnnee,
      tensionAssignee: tensionAssignee ?? this.tensionAssignee,
      pouvoirCoupure: pouvoirCoupure ?? this.pouvoirCoupure,
      numerotation: numerotation ?? this.numerotation,
      parafoudres: parafoudres ?? this.parafoudres,
      elementsVerifies: elementsVerifies ?? this.elementsVerifies,
      photos: photos ?? this.photos,
      gamme: gamme ?? this.gamme,
      calibreDisjoncteur: calibreDisjoncteur ?? this.calibreDisjoncteur,
      celluleDepart: celluleDepart ?? this.celluleDepart,
      sectionCables: sectionCables ?? this.sectionCables,
      natureReseau: natureReseau ?? this.natureReseau,
      observations: observations ?? this.observations,
      presenceIacm: presenceIacm ?? this.presenceIacm,
      syncId: syncId ?? this.syncId,
      tensionService: tensionService ?? this.tensionService,
      nom: nom ?? this.nom,
      photo: photo ?? this.photo,
      repere: repere ?? this.repere,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      annee: annee ?? this.annee,
      sectionCablePhase: sectionCablePhase ?? this.sectionCablePhase,
      sectionCableNeutre: sectionCableNeutre ?? this.sectionCableNeutre,
      conducteursPhase: conducteursPhase ?? this.conducteursPhase,
      conducteursNeutre: conducteursNeutre ?? this.conducteursNeutre,
    );
  }
}

// TRANSFORMATEUR MT/BT
@HiveType(typeId: 10)
class TransformateurMTBT {
  @HiveField(0)
  String typeTransformateur;

  @HiveField(1)
  String marqueAnnee;

  @HiveField(2)
  String puissanceAssignee;

  @HiveField(3)
  String tensionPrimaireSecondaire;

  @HiveField(4)
  String relaisBuchholz;

  @HiveField(5)
  String typeRefroidissement;

  @HiveField(6)
  String regimeNeutre;

  @HiveField(7)
  List<ElementControle> elementsVerifies;

  // PHOTOS DU TRANSFORMATEUR
  @HiveField(8)
  List<String> photos; // Chemins des photos du transformateur

  @HiveField(9)
  String? calibreDisjoncteur;

  @HiveField(10)
  String? sectionCables;

  @HiveField(11)
  List<ElementControle>? observations;

  @HiveField(12)
  String? syncId;

  @HiveField(13)
  String? intensiteNominale;

  @HiveField(14)
  String? couplage;

  @HiveField(15)
  String? typeReseau;

  @HiveField(16)
  String? pccAmont;

  @HiveField(17)
  String? puissanceUcc;

  @HiveField(18)
  String? ik3Max;

  @HiveField(19)
  String? nom;

  @HiveField(20)
  String? photo;

  @HiveField(21)
  String? repere;

  @HiveField(22)
  String? marque;

  @HiveField(23)
  String? anneeFabrication;

  @HiveField(24)
  String? typeImmersion;

  @HiveField(25)
  String? presenceDGPT2;

  @HiveField(26)
  DateTime? createdAt;

  @HiveField(27)
  DateTime? updatedAt;

  @HiveField(28)
  String? sectionCablePhase;

  @HiveField(29)
  String? sectionCableNeutre;

  @HiveField(30)
  int? conducteursPhase;

  @HiveField(31)
  int? conducteursNeutre;

  @HiveField(32)
  String? courantReglageDisjoncteur;

  /// Indique si le transformateur est de type immergé (tolérant aux majuscules/accents)
  bool get isImmerge {
    final t = typeTransformateur.trim().toUpperCase();
    return t == 'IMMERGÉ' || t == 'IMMERGE';
  }

  TransformateurMTBT({
    required this.typeTransformateur,
    required this.marqueAnnee,
    required this.puissanceAssignee,
    required this.tensionPrimaireSecondaire,
    required this.relaisBuchholz,
    required this.typeRefroidissement,
    required this.regimeNeutre,
    this.createdAt,
    this.updatedAt,
    List<ElementControle>? elementsVerifies,
    List<String>? photos,
    this.calibreDisjoncteur,
    this.courantReglageDisjoncteur,
    this.sectionCables,
    List<ElementControle>? observations,
    String? syncId,
    this.intensiteNominale,
    this.couplage,
    this.typeReseau,
    this.pccAmont,
    this.puissanceUcc,
    this.ik3Max,
    this.nom,
    this.photo,
    this.repere,
    this.marque,
    this.anneeFabrication,
    this.typeImmersion,
    this.presenceDGPT2,
    this.sectionCablePhase,
    this.sectionCableNeutre,
    this.conducteursPhase,
    this.conducteursNeutre,
  })  : elementsVerifies = elementsVerifies ?? [],
        photos = photos ?? [],
        observations = observations ?? [],
        syncId = (syncId != null && syncId.isNotEmpty)
            ? syncId
            : (createdAt != null)
                ? 'transfo_${createdAt.millisecondsSinceEpoch}_${(nom ?? puissanceAssignee).trim().hashCode.abs()}'
                : 'transfo_${(typeTransformateur.trim() + (nom ?? '')).hashCode.abs()}';

  /// Résout le repère effectif du transformateur (nom du local parent s'il est connu, sinon repere stocké)
  String getEffectiveRepere(String? parentLocalNom) {
    if (parentLocalNom != null && parentLocalNom.trim().isNotEmpty) {
      return parentLocalNom.trim();
    }
    if (repere != null && repere!.trim().isNotEmpty) {
      return repere!.trim();
    }
    return '';
  }

  /// Résout la section de câble phase effective (fallback sur historique sectionCables)
  String? get effectiveSectionCablePhase =>
      (sectionCablePhase != null && sectionCablePhase!.trim().isNotEmpty)
          ? sectionCablePhase
          : sectionCables;

  /// Résout la section de câble neutre effective (fallback sur phase puis historique sectionCables)
  String? get effectiveSectionCableNeutre =>
      (sectionCableNeutre != null && sectionCableNeutre!.trim().isNotEmpty)
          ? sectionCableNeutre
          : effectiveSectionCablePhase;

  /// Nombre effectif de conducteurs phase (1 par défaut si section présente, null sinon)
  int? get effectiveConducteursPhase {
    if (conducteursPhase != null && conducteursPhase! > 0) return conducteursPhase;
    final sec = effectiveSectionCablePhase;
    if (sec != null && sec.trim().isNotEmpty && sec.trim() != '-') return 1;
    return null;
  }

  /// Nombre effectif de conducteurs neutre (1 par défaut si section présente, null sinon)
  int? get effectiveConducteursNeutre {
    if (conducteursNeutre != null && conducteursNeutre! > 0) return conducteursNeutre;
    final sec = effectiveSectionCableNeutre;
    if (sec != null && sec.trim().isNotEmpty && sec.trim() != '-') return 1;
    return null;
  }

  /// Résout la marque effective avec fallback rétrocompatible
  String get effectiveMarque {
    if (marque != null && marque!.trim().isNotEmpty) {
      return marque!.trim();
    }
    return marqueAnnee.trim();
  }

  /// Résout l'année de fabrication effective avec fallback
  String get effectiveAnneeFabrication => anneeFabrication?.trim() ?? '';

  /// Formate l'ensemble des informations constructeur
  String get formattedMarqueAnnee {
    final m = effectiveMarque;
    final a = effectiveAnneeFabrication;
    final parts = [m, a].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' / ');
    return marqueAnnee;
  }

  TransformateurMTBT copyWith({
    String? typeTransformateur,
    String? marqueAnnee,
    String? puissanceAssignee,
    String? tensionPrimaireSecondaire,
    String? relaisBuchholz,
    String? typeRefroidissement,
    String? regimeNeutre,
    List<ElementControle>? elementsVerifies,
    List<String>? photos,
    String? calibreDisjoncteur,
    String? courantReglageDisjoncteur,
    String? sectionCables,
    List<ElementControle>? observations,
    String? syncId,
    String? intensiteNominale,
    String? couplage,
    String? typeReseau,
    String? pccAmont,
    String? puissanceUcc,
    String? ik3Max,
    String? nom,
    String? photo,
    String? repere,
    String? marque,
    String? anneeFabrication,
    String? typeImmersion,
    String? presenceDGPT2,
    String? sectionCablePhase,
    String? sectionCableNeutre,
    int? conducteursPhase,
    int? conducteursNeutre,
  }) {
    return TransformateurMTBT(
      typeTransformateur: typeTransformateur ?? this.typeTransformateur,
      marqueAnnee: marqueAnnee ?? this.marqueAnnee,
      puissanceAssignee: puissanceAssignee ?? this.puissanceAssignee,
      tensionPrimaireSecondaire: tensionPrimaireSecondaire ?? this.tensionPrimaireSecondaire,
      relaisBuchholz: relaisBuchholz ?? this.relaisBuchholz,
      typeRefroidissement: typeRefroidissement ?? this.typeRefroidissement,
      regimeNeutre: regimeNeutre ?? this.regimeNeutre,
      elementsVerifies: elementsVerifies ?? this.elementsVerifies,
      photos: photos ?? this.photos,
      calibreDisjoncteur: calibreDisjoncteur ?? this.calibreDisjoncteur,
      courantReglageDisjoncteur: courantReglageDisjoncteur ?? this.courantReglageDisjoncteur,
      sectionCables: sectionCables ?? this.sectionCables,
      observations: observations ?? this.observations,
      syncId: syncId ?? this.syncId,
      intensiteNominale: intensiteNominale ?? this.intensiteNominale,
      couplage: couplage ?? this.couplage,
      typeReseau: typeReseau ?? this.typeReseau,
      pccAmont: pccAmont ?? this.pccAmont,
      puissanceUcc: puissanceUcc ?? this.puissanceUcc,
      ik3Max: ik3Max ?? this.ik3Max,
      nom: nom ?? this.nom,
      photo: photo ?? this.photo,
      repere: repere ?? this.repere,
      marque: marque ?? this.marque,
      anneeFabrication: anneeFabrication ?? this.anneeFabrication,
      typeImmersion: typeImmersion ?? this.typeImmersion,
      presenceDGPT2: presenceDGPT2 ?? this.presenceDGPT2,
      sectionCablePhase: sectionCablePhase ?? this.sectionCablePhase,
      sectionCableNeutre: sectionCableNeutre ?? this.sectionCableNeutre,
      conducteursPhase: conducteursPhase ?? this.conducteursPhase,
      conducteursNeutre: conducteursNeutre ?? this.conducteursNeutre,
    );
  }
}

/// Règle métier centrale : détermine si un départ est pris sans protection en fonction du Type de protection.
/// Source de vérité unique pour toute l'application.
bool isDepartureWithoutProtection(String? typeProtection) {
  if (typeProtection == null) return true;
  final norm = typeProtection.trim().toLowerCase();
  return norm.isEmpty || norm == '-aucun-' || norm == 'aucun' || norm == '-';
}

/// Règle métier inverse : détermine si une protection valide est présente.
bool isDepartPrisAvecProtectionFromType(String? typeProtection) {
  return !isDepartureWithoutProtection(typeProtection);
}

// COFFRETS/ARMOIRES
@HiveType(typeId: 11)
class CoffretArmoire {
  @HiveField(0)
  String qrCode; 

  @HiveField(1)
  String nom;

  @HiveField(2)
  String type; // TUR, INVERSEUR, TGBT, etc.

  @HiveField(3)
  String? description;

  @HiveField(4)
  String? repere;

  // INFORMATIONS GÉNÉRALES (Oui/Non)
  @HiveField(5, defaultValue: false)
  bool zoneAtex;

  @HiveField(6, defaultValue: '')
  String domaineTension;

  @HiveField(7, defaultValue: false)
  bool identificationArmoire;

  @HiveField(8, defaultValue: false)
  bool signalisationDanger;

  @HiveField(9, defaultValue: false)
  bool presenceSchema;

  @HiveField(10, defaultValue: false)
  bool presenceParafoudre;

  @HiveField(11, defaultValue: false)
  bool verificationThermographie;

  // ALIMENTATIONS (dépend du type)
  @HiveField(12)
  List<Alimentation> alimentations;

  // PROTECTION DE TÊTE
  @HiveField(13)
  Alimentation? protectionTete;

  // POINTS DE VÉRIFICATION
  @HiveField(14)
  List<PointVerification> pointsVerification;

  @HiveField(15)
  List<ObservationLibre> observationsLibres; 

  // PHOTOS DU COFFRET/ARMOIRE
  @HiveField(16)
  List<String> photos; // Chemins des photos du coffret/armoire

  @HiveField(17)
  String? numeroEquipement;

  @HiveField(18)
  String statut; // 'complet' ou 'incomplet'

  //Étape courante pour reprise
  @HiveField(19)
  int currentStep;

  @HiveField(20)
  List<String> photosExternes;

  @HiveField(21)
  List<String> photosInternes;

  @HiveField(22)
  List<ObservationLibre> observationsParafoudre;

  @HiveField(23)
  List<ElementControle>? observationsParafoudreEnrichies;

  @HiveField(24)
  String? presenceDefautThermo;

  @HiveField(25, defaultValue: true)
  bool? _accessible;

  @HiveField(26)
  bool? alimenteeParTransformateur;

  @HiveField(27)
  bool? presenceCPI;

  @HiveField(28)
  String? id;

  @HiveField(29)
  bool? departPrisAvecProtection;

  @HiveField(30)
  DateTime? createdAt;

  @HiveField(31)
  DateTime? updatedAt;

  @HiveField(32)
  String? indiceIpIk;

  @HiveField(33)
  List<DepartEquipement>? departures;

  @HiveField(34)
  List<CircuitTerminalEquipement>? terminalCircuits;

  @HiveField(35)
  String? sourceEquipementId;

  @HiveField(36)
  String? sourceNomComplet;

  @HiveField(37)
  String? sourceDepartId;

  @HiveField(38)
  String? transformateurId;

  @HiveField(39)
  String? transformateurNomComplet;

  @HiveField(40)
  String? indiceIpIkRepere;

  List<DepartEquipement> get effectiveDepartures => departures ?? [];
  List<CircuitTerminalEquipement> get effectiveTerminalCircuits => terminalCircuits ?? [];

  /// Résout l'état "Départ pris avec protection"
  /// - L'Inverseur est toujours considéré avec protection (true).
  /// - typeProtection (protectionTete ou premier élément alimentations) est la SOURCE DE VÉRITÉ UNIQUE.
  /// - Si mainProt est présent (non null), typeProtection détermine immédiatement l'état dérivé réactif.
  /// - En dernier fallback pour anciennes missions dépouillées de typeProtection, on consulte departPrisAvecProtection.
  bool get isDepartPrisAvecProtection {
    if (type == 'INVERSEUR') return true;

    final mainProt = protectionTete?.typeProtection ??
        (alimentations.isNotEmpty ? alimentations.first.typeProtection : null);
    if (mainProt != null) {
      return isDepartPrisAvecProtectionFromType(mainProt);
    }

    return departPrisAvecProtection ?? false;
  }

  /// Identifiant technique immuable (avec fallback auto déterministe pour anciennes missions)
  String get equipmentId {
    if (id != null && id!.trim().isNotEmpty) return id!;
    final createdTs = createdAt?.millisecondsSinceEpoch ?? 0;
    final stableHash = (nom.trim() + (qrCode ?? '').trim() + (numeroEquipement ?? '')).hashCode.abs();
    id = 'equip_${createdTs}_$stableHash';
    return id!;
  }

  bool get accessible => _accessible ?? true;
  set accessible(bool value) => _accessible = value;

  /// Getter rétrocompatible pour interpréter l'état de la présence de défaut thermo.
  /// Rends 'Sans objet' pour les anciens équipements ayant la thermographie activée mais sans valeur enregistrée.
  String? get effectivePresenceDefautThermo {
    if (!verificationThermographie) return null;
    if (presenceDefautThermo != null && presenceDefautThermo!.isNotEmpty) {
      return presenceDefautThermo;
    }
    return 'Sans objet';
  }

  CoffretArmoire({
    String? id,
    required this.qrCode, // Ajouté dans le constructeur
    required this.nom,
    required this.type,
    this.description,
    this.repere,
    this.zoneAtex = false,
    this.domaineTension = '',
    this.identificationArmoire = false,
    this.signalisationDanger = false,
    this.presenceSchema = false,
    this.presenceParafoudre = false,
    this.verificationThermographie = false,
    this.presenceDefautThermo,
    this.alimenteeParTransformateur,
    this.transformateurId,
    this.transformateurNomComplet,
    this.presenceCPI,
    this.departPrisAvecProtection,
    this.createdAt,
    this.updatedAt,
    this.indiceIpIk,
    this.indiceIpIkRepere,
    List<DepartEquipement>? departures,
    List<CircuitTerminalEquipement>? terminalCircuits,
    this.sourceEquipementId,
    this.sourceNomComplet,
    this.sourceDepartId,
    bool? accessible,
    List<Alimentation>? alimentations,
    this.protectionTete,
    List<PointVerification>? pointsVerification,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    this.statut = 'incomplet',
    this.currentStep = 0,
    this.numeroEquipement,
    List<String>? photosExternes,
    List<String>? photosInternes,
    List<ObservationLibre>? observationsParafoudre,
    List<ElementControle>? observationsParafoudreEnrichies,
  })  : id = (id != null && id.trim().isNotEmpty)
            ? id
            : (createdAt != null)
                ? 'equip_${createdAt.millisecondsSinceEpoch}_${nom.trim().hashCode.abs()}'
                : (qrCode.trim().isNotEmpty && !qrCode.startsWith('TEMP_') && !qrCode.startsWith('DRAFT_'))
                    ? 'equip_${qrCode.trim()}'
                    : 'equip_${(nom.trim() + (numeroEquipement ?? '')).hashCode.abs()}',
        _accessible = accessible ?? true,
        departures = departures,
        terminalCircuits = terminalCircuits ?? [],
        alimentations = alimentations ?? [],
        pointsVerification = pointsVerification ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        photosExternes = photosExternes ?? [],
        photosInternes = photosInternes ?? [],
        observationsParafoudre = observationsParafoudre ?? [],
        observationsParafoudreEnrichies = observationsParafoudreEnrichies ?? [];

  CoffretArmoire copyWith({
    String? id,
    String? qrCode,
    String? nom,
    String? type,
    String? description,
    String? repere,
    bool? zoneAtex,
    String? domaineTension,
    bool? identificationArmoire,
    bool? signalisationDanger,
    bool? presenceSchema,
    bool? presenceParafoudre,
    bool? verificationThermographie,
    String? presenceDefautThermo,
    bool? alimenteeParTransformateur,
    String? transformateurId,
    String? transformateurNomComplet,
    bool? presenceCPI,
    bool? departPrisAvecProtection,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? indiceIpIk,
    String? indiceIpIkRepere,
    List<DepartEquipement>? departures,
    List<CircuitTerminalEquipement>? terminalCircuits,
    String? sourceEquipementId,
    String? sourceNomComplet,
    String? sourceDepartId,
    bool? accessible,
    List<Alimentation>? alimentations,
    Alimentation? protectionTete,
    List<PointVerification>? pointsVerification,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    String? statut,
    int? currentStep,
    String? numeroEquipement,
    List<String>? photosExternes,
    List<String>? photosInternes,
    List<ObservationLibre>? observationsParafoudre,
    List<ElementControle>? observationsParafoudreEnrichies,
  }) {
    return CoffretArmoire(
      id: id ?? this.id,
      qrCode: qrCode ?? this.qrCode,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      description: description ?? this.description,
      repere: repere ?? this.repere,
      zoneAtex: zoneAtex ?? this.zoneAtex,
      domaineTension: domaineTension ?? this.domaineTension,
      identificationArmoire: identificationArmoire ?? this.identificationArmoire,
      signalisationDanger: signalisationDanger ?? this.signalisationDanger,
      presenceSchema: presenceSchema ?? this.presenceSchema,
      presenceParafoudre: presenceParafoudre ?? this.presenceParafoudre,
      verificationThermographie: verificationThermographie ?? this.verificationThermographie,
      presenceDefautThermo: presenceDefautThermo ?? this.presenceDefautThermo,
      alimenteeParTransformateur: alimenteeParTransformateur ?? this.alimenteeParTransformateur,
      transformateurId: transformateurId ?? this.transformateurId,
      transformateurNomComplet: transformateurNomComplet ?? this.transformateurNomComplet,
      presenceCPI: presenceCPI ?? this.presenceCPI,
      departPrisAvecProtection: departPrisAvecProtection ?? this.departPrisAvecProtection,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      indiceIpIk: indiceIpIk ?? this.indiceIpIk,
      indiceIpIkRepere: indiceIpIkRepere ?? this.indiceIpIkRepere,
      departures: departures ?? this.departures,
      terminalCircuits: terminalCircuits ?? this.terminalCircuits,
      sourceEquipementId: sourceEquipementId ?? this.sourceEquipementId,
      sourceNomComplet: sourceNomComplet ?? this.sourceNomComplet,
      sourceDepartId: sourceDepartId ?? this.sourceDepartId,
      accessible: accessible ?? this.accessible,
      alimentations: alimentations ?? this.alimentations,
      protectionTete: protectionTete ?? this.protectionTete,
      pointsVerification: pointsVerification ?? this.pointsVerification,
      observationsLibres: observationsLibres ?? this.observationsLibres,
      photos: photos ?? this.photos,
      statut: statut ?? this.statut,
      currentStep: currentStep ?? this.currentStep,
      numeroEquipement: numeroEquipement ?? this.numeroEquipement,
      photosExternes: photosExternes ?? this.photosExternes,
      photosInternes: photosInternes ?? this.photosInternes,
      observationsParafoudre: observationsParafoudre ?? this.observationsParafoudre,
      observationsParafoudreEnrichies: observationsParafoudreEnrichies ?? this.observationsParafoudreEnrichies,
    );
  }

  /// Pour un Inverseur, retourne les alimentations d'entrée (Alimentation 1 & Alimentation 2)
  List<Alimentation> get alimentationsInverseurEntree {
    if (type != 'INVERSEUR') return alimentations;
    return alimentations.take(2).toList();
  }

  /// Pour un Inverseur, retourne la liste dynamique des sorties inverseur (éléments à partir de l'index 2)
  List<Alimentation> get sortiesInverseur {
    if (type != 'INVERSEUR') return [];
    if (alimentations.length <= 2) return [];
    return alimentations.skip(2).toList();
  }
}

@HiveType(typeId: 12)
class Alimentation {
  @HiveField(0)
  String typeProtection;

  @HiveField(1)
  String pdcKA;

  @HiveField(2)
  String calibre;

  @HiveField(3)
  String sectionCable;

  // PHOTO DE L'ALIMENTATION (schéma, étiquette)
  @HiveField(4)
  List<String> photos; // Photos de l'étiquette ou de l'installation

  @HiveField(5)
  String source;

  @HiveField(6)
  String? courbe;

  @HiveField(7)
  String? ddr;

  @HiveField(8)
  String? sourceKnown; // "Connue" | "Inconnue" (nullable)

  @HiveField(9)
  String? marqueDisjoncteur;

  @HiveField(10)
  String? icc3Max;

  @HiveField(11)
  String? nombreCables;

  @HiveField(12)
  String? sectionCableNeutre;

  @HiveField(13)
  int? conducteursPhase;

  @HiveField(14)
  int? conducteursNeutre;

  @HiveField(15)
  String? id;

  @HiveField(16)
  String? natureCable; // "Cuivre" ou "Aluminium"

  /// Identifiant technique stable (généré automatiquement si absent)
  String get alimentationId {
    if (id != null && id!.trim().isNotEmpty) return id!;
    id = 'alim_${DateTime.now().microsecondsSinceEpoch}_${typeProtection.hashCode.abs()}';
    return id!;
  }

  /// Getter rétrocompatible pour la section phase (réutilise le champ historique sectionCable)
  String get sectionCablePhase => sectionCable;
  String get effectiveSectionCablePhase => sectionCablePhase;
  set sectionCablePhase(String val) => sectionCable = val;

  /// Getter rétrocompatible pour la section neutre (avec fallback auto sur sectionCable Phase si absent)
  String get effectiveSectionCableNeutre => (sectionCableNeutre != null && sectionCableNeutre!.trim().isNotEmpty) ? sectionCableNeutre! : sectionCable;

  /// Nombre effectif de conducteurs phase (1 par défaut si section présente, null sinon)
  int? get effectiveConducteursPhase {
    if (conducteursPhase != null && conducteursPhase! > 0) return conducteursPhase;
    if (sectionCable.trim().isNotEmpty && sectionCable.trim() != '-') return 1;
    return null;
  }

  /// Nombre effectif de conducteurs neutre (1 par défaut si section présente, null sinon)
  int? get effectiveConducteursNeutre {
    if (conducteursNeutre != null && conducteursNeutre! > 0) return conducteursNeutre;
    final sec = effectiveSectionCableNeutre;
    if (sec.trim().isNotEmpty && sec.trim() != '-') return 1;
    return null;
  }

  /// Résout le statut de connaissance de la source dérivé automatiquement de typeProtection
  String get effectiveSourceKnown => SourceStatusResolver.resolve(typeProtection);

  Alimentation({
    String? id,
    required this.typeProtection,
    this.courbe = '',
    this.ddr,
    required this.pdcKA,
    required this.calibre,
    required this.sectionCable,
    List<String>? photos,
    this.source = '',
    String? sourceKnown,
    this.marqueDisjoncteur,
    this.icc3Max = '',
    this.nombreCables,
    this.sectionCableNeutre,
    this.conducteursPhase,
    this.conducteursNeutre,
    this.natureCable,
  })  : id = (id != null && id.trim().isNotEmpty)
            ? id
            : 'alim_${DateTime.now().microsecondsSinceEpoch}_${typeProtection.hashCode.abs()}',
        photos = photos ?? [],
        sourceKnown = sourceKnown ?? SourceStatusResolver.resolve(typeProtection);

  Alimentation copyWith({
    String? id,
    String? typeProtection,
    String? courbe,
    String? ddr,
    String? pdcKA,
    String? calibre,
    String? sectionCable,
    List<String>? photos,
    String? source,
    String? sourceKnown,
    String? marqueDisjoncteur,
    String? icc3Max,
    String? nombreCables,
    String? sectionCableNeutre,
    int? conducteursPhase,
    int? conducteursNeutre,
    String? natureCable,
  }) {
    return Alimentation(
      id: id ?? this.id,
      typeProtection: typeProtection ?? this.typeProtection,
      courbe: courbe ?? this.courbe,
      ddr: ddr ?? this.ddr,
      pdcKA: pdcKA ?? this.pdcKA,
      calibre: calibre ?? this.calibre,
      sectionCable: sectionCable ?? this.sectionCable,
      photos: photos ?? this.photos,
      source: source ?? this.source,
      sourceKnown: sourceKnown ?? this.sourceKnown,
      marqueDisjoncteur: marqueDisjoncteur ?? this.marqueDisjoncteur,
      icc3Max: icc3Max ?? this.icc3Max,
      nombreCables: nombreCables ?? this.nombreCables,
      sectionCableNeutre: sectionCableNeutre ?? this.sectionCableNeutre,
      conducteursPhase: conducteursPhase ?? this.conducteursPhase,
      conducteursNeutre: conducteursNeutre ?? this.conducteursNeutre,
      natureCable: natureCable ?? this.natureCable,
    );
  }
}

@HiveType(typeId: 13)
class PointVerification {
  @HiveField(0)
  String pointVerification;

  @HiveField(1)
  String conformite; // "oui", "non", "non_acquis"

  @HiveField(2)
  String? observation;

  @HiveField(3)
  String? referenceNormative;

  @HiveField(4)
  int? priorite; // 1, 2 ou 3

  // PHOTO DU POINT DE VÉRIFICATION
  @HiveField(5)
  List<String> photos; // Photos illustrant ce point spécifique

  @HiveField(6)
  List<ElementControle>? observations;

  @HiveField(7)
  String? criticite;

  @HiveField(8)
  String? familleRisque;

  PointVerification({
    required this.pointVerification,
    required this.conformite,
    this.observation,
    this.referenceNormative,
    this.priorite,
    List<String>? photos,
    List<ElementControle>? observations,
    this.criticite,
    this.familleRisque,
  }) : photos = photos ?? [],
       observations = observations ?? [];

  /// Getter normalisé déterministe pour la conformité
  /// Convertit les équivalents majuscules / historiques / booléens en 'oui', 'non', 'na', ou ''
  String get normalizedConformite {
    final c = conformite.trim().toLowerCase();
    if (c == 'oui' || c == 'true' || c == 'conforme') return 'oui';
    if (c == 'non' || c == 'false' || c == 'non_conforme' || c == 'non conforme') return 'non';
    if (c == 'na' || c == 'sans_objet' || c == 'sans objet' || c == 's.o.' || c == 'so' || c == 'non_acquis') return 'na';
    return c;
  }
}

@HiveType(typeId: 24)
class ObservationLibre {
  @HiveField(0)
  String texte;
  
  @HiveField(1)
  List<String> photos; // Photos associées à cette observation
  
  @HiveField(2)
  DateTime dateCreation;
  
  @HiveField(3)
  DateTime dateModification;

  @HiveField(4)
  String? pointVerificationKey;

  @HiveField(5)
  String? referenceNormative;

  @HiveField(6)
  String? familleRisque;

  @HiveField(7)
  String? criticite;

  @HiveField(8, defaultValue: false)
  bool isAutoLinked;

  ObservationLibre({
    required this.texte,
    List<String>? photos,
    DateTime? dateCreation,
    DateTime? dateModification,
    this.pointVerificationKey,
    this.referenceNormative,
    this.familleRisque,
    this.criticite,
    this.isAutoLinked = false,
  })  : photos = photos ?? [],
        dateCreation = dateCreation ?? DateTime.now(),
        dateModification = dateModification ?? DateTime.now();

  bool get hasNormativeReference =>
      referenceNormative != null && referenceNormative!.trim().isNotEmpty;

  void linkToNormativePoint({
    required String key,
    required String refNormative,
    required String famille,
    required String crit,
    bool auto = false,
  }) {
    pointVerificationKey = key;
    final cleaned = DispositionsConstructivesRegistry.normalizeNormativeReference(refNormative);
    referenceNormative = (cleaned == '-' || cleaned?.isEmpty == true) ? null : cleaned;
    familleRisque = famille;
    criticite = (criticite != null && criticite!.trim().isNotEmpty) ? criticite : crit;
    isAutoLinked = auto;
    dateModification = DateTime.now();
  }

  void unlinkNormativePoint() {
    pointVerificationKey = null;
    referenceNormative = null;
    familleRisque = null;
    criticite = null;
    isAutoLinked = false;
    dateModification = DateTime.now();
  }

  ObservationLibre copyWith({
    String? texte,
    List<String>? photos,
    DateTime? dateCreation,
    DateTime? dateModification,
    String? pointVerificationKey,
    String? referenceNormative,
    String? familleRisque,
    String? criticite,
    bool? isAutoLinked,
  }) {
    return ObservationLibre(
      texte: texte ?? this.texte,
      photos: photos ?? this.photos,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      pointVerificationKey: pointVerificationKey ?? this.pointVerificationKey,
      referenceNormative: referenceNormative ?? this.referenceNormative,
      familleRisque: familleRisque ?? this.familleRisque,
      criticite: criticite ?? this.criticite,
      isAutoLinked: isAutoLinked ?? this.isAutoLinked,
    );
  }

  // Méthode pour ajouter une photo
  void addPhoto(String cheminPhoto) {
    photos.add(cheminPhoto);
    dateModification = DateTime.now();
  }

  // Méthode pour supprimer une photo
  void removePhoto(String cheminPhoto) {
    photos.remove(cheminPhoto);
    dateModification = DateTime.now();
  }

  // Méthode pour mettre à jour le texte
  void updateTexte(String nouveauTexte) {
    texte = ObservationTextNormalizer.normalize(nouveauTexte) ?? nouveauTexte;
    dateModification = DateTime.now();
  }
}

// DÉPART ISSU D'UN TGBT/ARMOIRE/COFFRET
@HiveType(typeId: 64)
class DepartEquipement {
  @HiveField(0)
  String id;

  @HiveField(1)
  String protectionTete; // 'Présent' | 'Absent'

  @HiveField(2)
  String identification;

  @HiveField(3)
  String typeProtection;

  @HiveField(4)
  String marque;

  @HiveField(5)
  String courbe;

  @HiveField(6)
  String pdcKA;

  @HiveField(7)
  String icc3Max;

  @HiveField(8)
  String calibre;

  @HiveField(9)
  String sectionCable;

  @HiveField(10)
  String ddr;

  @HiveField(11)
  String? nombreCables;

  @HiveField(12)
  String? sectionCableNeutre;

  @HiveField(13)
  int? conducteursPhase;

  @HiveField(14)
  int? conducteursNeutre;

  @HiveField(15)
  String? natureCable; // "Cuivre" ou "Aluminium"

  /// Getter rétrocompatible pour la section phase (réutilise le champ historique sectionCable)
  String get sectionCablePhase => sectionCable;
  String get effectiveSectionCablePhase => sectionCablePhase;
  set sectionCablePhase(String val) => sectionCable = val;

  /// Getter rétrocompatible pour la section neutre (avec fallback auto sur sectionCable Phase si absent)
  String get effectiveSectionCableNeutre => (sectionCableNeutre != null && sectionCableNeutre!.trim().isNotEmpty) ? sectionCableNeutre! : sectionCable;

  /// Nombre effectif de conducteurs phase (1 par défaut si section présente, null sinon)
  int? get effectiveConducteursPhase {
    if (conducteursPhase != null && conducteursPhase! > 0) return conducteursPhase;
    if (sectionCable.trim().isNotEmpty && sectionCable.trim() != '-') return 1;
    return null;
  }

  /// Nombre effectif de conducteurs neutre (1 par défaut si section présente, null sinon)
  int? get effectiveConducteursNeutre {
    if (conducteursNeutre != null && conducteursNeutre! > 0) return conducteursNeutre;
    final sec = effectiveSectionCableNeutre;
    if (sec.trim().isNotEmpty && sec.trim() != '-') return 1;
    return null;
  }

  DepartEquipement({
    String? id,
    this.protectionTete = 'Présent',
    this.identification = '',
    this.typeProtection = '',
    this.marque = '',
    this.courbe = '',
    this.pdcKA = '',
    this.icc3Max = '',
    this.calibre = '',
    this.sectionCable = '',
    this.ddr = '',
    this.nombreCables,
    this.sectionCableNeutre,
    this.conducteursPhase,
    this.conducteursNeutre,
    this.natureCable,
  }) : id = _resolveStableDepartId(
          id: id,
          identification: identification,
          calibre: calibre,
          typeProtection: typeProtection,
          sectionCable: sectionCable,
        );

  static String _resolveStableDepartId({
    String? id,
    required String identification,
    required String calibre,
    required String typeProtection,
    required String sectionCable,
  }) {
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    if (identification.trim().isNotEmpty || calibre.trim().isNotEmpty || typeProtection.trim().isNotEmpty) {
      final sig = '${identification.trim()}_${calibre.trim()}_${typeProtection.trim()}_${sectionCable.trim()}';
      return 'dep_legacy_${sig.hashCode.abs()}';
    }
    return 'dep_${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(identification)}';
  }

  DepartEquipement copyWith({
    String? id,
    String? protectionTete,
    String? identification,
    String? typeProtection,
    String? marque,
    String? courbe,
    String? pdcKA,
    String? icc3Max,
    String? calibre,
    String? sectionCable,
    String? ddr,
    String? nombreCables,
    String? sectionCableNeutre,
    int? conducteursPhase,
    int? conducteursNeutre,
    String? natureCable,
  }) {
    return DepartEquipement(
      id: id ?? this.id,
      protectionTete: protectionTete ?? this.protectionTete,
      identification: identification ?? this.identification,
      typeProtection: typeProtection ?? this.typeProtection,
      marque: marque ?? this.marque,
      courbe: courbe ?? this.courbe,
      pdcKA: pdcKA ?? this.pdcKA,
      icc3Max: icc3Max ?? this.icc3Max,
      calibre: calibre ?? this.calibre,
      sectionCable: sectionCable ?? this.sectionCable,
      ddr: ddr ?? this.ddr,
      nombreCables: nombreCables ?? this.nombreCables,
      sectionCableNeutre: sectionCableNeutre ?? this.sectionCableNeutre,
      conducteursPhase: conducteursPhase ?? this.conducteursPhase,
      conducteursNeutre: conducteursNeutre ?? this.conducteursNeutre,
      natureCable: natureCable ?? this.natureCable,
    );
  }
}

// CIRCUIT TERMINAL ISSU D'UN TGBT/ARMOIRE/COFFRET
@HiveType(typeId: 65)
class CircuitTerminalEquipement {
  @HiveField(0)
  String id;

  @HiveField(1)
  String protectionTete; // 'Oui' | 'Non' / 'Présent' | 'Absent'

  @HiveField(2)
  String identification;

  @HiveField(3)
  String typeProtection;

  @HiveField(4)
  String marque;

  @HiveField(5)
  String courbe;

  @HiveField(6)
  String pdcKA;

  @HiveField(7)
  String icc3Max;

  @HiveField(8)
  String calibre;

  @HiveField(9)
  String sectionCable;

  @HiveField(10)
  String ddr;

  @HiveField(11)
  String? nombreCables;

  @HiveField(12)
  String? sectionCableNeutre;

  @HiveField(13)
  int? conducteursPhase;

  @HiveField(14)
  int? conducteursNeutre;

  @HiveField(15)
  String? natureCable; // "Cuivre" ou "Aluminium"

  /// Getter rétrocompatible pour la section phase (réutilise le champ historique sectionCable)
  String get sectionCablePhase => sectionCable;
  String get effectiveSectionCablePhase => sectionCablePhase;
  set sectionCablePhase(String val) => sectionCable = val;

  /// Getter rétrocompatible pour la section neutre (avec fallback auto sur sectionCable Phase si absent)
  String get effectiveSectionCableNeutre => (sectionCableNeutre != null && sectionCableNeutre!.trim().isNotEmpty) ? sectionCableNeutre! : sectionCable;

  /// Nombre effectif de conducteurs phase (1 par défaut si section présente, null sinon)
  int? get effectiveConducteursPhase {
    if (conducteursPhase != null && conducteursPhase! > 0) return conducteursPhase;
    if (sectionCable.trim().isNotEmpty && sectionCable.trim() != '-') return 1;
    return null;
  }

  /// Nombre effectif de conducteurs neutre (1 par défaut si section présente, null sinon)
  int? get effectiveConducteursNeutre {
    if (conducteursNeutre != null && conducteursNeutre! > 0) return conducteursNeutre;
    final sec = effectiveSectionCableNeutre;
    if (sec.trim().isNotEmpty && sec.trim() != '-') return 1;
    return null;
  }

  CircuitTerminalEquipement({
    String? id,
    this.protectionTete = 'Oui',
    this.identification = '',
    this.typeProtection = '',
    this.marque = '',
    this.courbe = '',
    this.pdcKA = '',
    this.icc3Max = '',
    this.calibre = '',
    this.sectionCable = '',
    this.ddr = '',
    this.nombreCables,
    this.sectionCableNeutre,
    this.conducteursPhase,
    this.conducteursNeutre,
    this.natureCable,
  }) : id = _resolveStableCircuitId(
          id: id,
          identification: identification,
          calibre: calibre,
          typeProtection: typeProtection,
          sectionCable: sectionCable,
        );

  static String _resolveStableCircuitId({
    String? id,
    required String identification,
    required String calibre,
    required String typeProtection,
    required String sectionCable,
  }) {
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    if (identification.trim().isNotEmpty || calibre.trim().isNotEmpty || typeProtection.trim().isNotEmpty) {
      final sig = '${identification.trim()}_${calibre.trim()}_${typeProtection.trim()}_${sectionCable.trim()}';
      return 'ct_legacy_${sig.hashCode.abs()}';
    }
    return 'ct_${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(identification)}';
  }

  CircuitTerminalEquipement copyWith({
    String? id,
    String? protectionTete,
    String? identification,
    String? typeProtection,
    String? marque,
    String? courbe,
    String? pdcKA,
    String? icc3Max,
    String? calibre,
    String? sectionCable,
    String? ddr,
    String? nombreCables,
    String? sectionCableNeutre,
    int? conducteursPhase,
    int? conducteursNeutre,
    String? natureCable,
  }) {
    return CircuitTerminalEquipement(
      id: id ?? this.id,
      protectionTete: protectionTete ?? this.protectionTete,
      identification: identification ?? this.identification,
      typeProtection: typeProtection ?? this.typeProtection,
      marque: marque ?? this.marque,
      courbe: courbe ?? this.courbe,
      pdcKA: pdcKA ?? this.pdcKA,
      icc3Max: icc3Max ?? this.icc3Max,
      calibre: calibre ?? this.calibre,
      sectionCable: sectionCable ?? this.sectionCable,
      ddr: ddr ?? this.ddr,
      nombreCables: nombreCables ?? this.nombreCables,
      sectionCableNeutre: sectionCableNeutre ?? this.sectionCableNeutre,
      conducteursPhase: conducteursPhase ?? this.conducteursPhase,
      conducteursNeutre: conducteursNeutre ?? this.conducteursNeutre,
      natureCable: natureCable ?? this.natureCable,
    );
  }
}