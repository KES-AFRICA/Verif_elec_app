/// Source de vérité unique pour les métadonnées des Dispositions Constructives et Conditions d'Exploitation du Local
library;

import '../models/audit_installations_electriques.dart';
import '../utils/normative_reference_cleaner.dart';
import 'equipment_type_transition_service.dart';

class DispositionMetadata {
  final String referenceNormative;
  final String familleRisque;
  final String criticite;

  const DispositionMetadata({
    required this.referenceNormative,
    required this.familleRisque,
    required this.criticite,
  });
}

class DispositionsConstructivesRegistry {
  static String? normalizeNormativeReference(String? ref) {
    if (ref == null || ref.isEmpty) return ref;
    final cleaned = NormativeReferenceCleaner.clean(ref);
    if (cleaned == null || cleaned.isEmpty) return cleaned;
    return cleaned.replaceAll(RegExp(r'§\s*'), 'art ');
  }

  static const Map<String, DispositionMetadata> _registry = {
    // --- I. DISPOSITIONS CONSTRUCTIVES DU LOCAL TECHNIQUE MOYENNE TENSION ---
    "Le local est exclusivement réservé à l'usage électrique":
        DispositionMetadata(
          referenceNormative: "NF EN 62305-3",
          familleRisque: "Foudre",
          criticite: "Critique",
        ),
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"':
        DispositionMetadata(
          referenceNormative: "NF C 15-100-7-729:2024 – art 729",
          familleRisque: "Accès non autorisé / risque électrique",
          criticite: "Majeure",
        ),
    "Dimensions": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 512.2",
      familleRisque:
          "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Parois, plancher et plafond en matériaux non combustibles":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 421, art 422 et art 527",
          familleRisque: "Incendie / propagation du feu",
          criticite: "Majeure",
        ),
    "Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 462",
          familleRisque: "Sécurité des interventions",
          criticite: "Majeure",
        ),
    "Verrouillage empêchant tout accès non autorisé": DispositionMetadata(
      referenceNormative: "NF C 15-100-7-729:2024 – art 729",
      familleRisque: "Accès non autorisé / risque électrique",
      criticite: "Majeure",
    ),
    "Absence de communication directe avec les locaux à risque":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2",
          familleRisque:
              "Protection mécanique / pénétration corps solides-liquides",
          criticite: "Majeure",
        ),
    "Absence de stockage d'objets non électriques": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 421, art 422 et art 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Accessibilité du local et dégagement permanent des accès":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 513",
          familleRisque: "Accès / exploitation / intervention",
          criticite: "Critique",
        ),
    "État et continuité des liaisons équipotentielles du local":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 544",
          familleRisque: "Électrisation / défaut d'équipotentialité",
          criticite: "Critique",
        ),
    "Présence et lisibilité des consignes de sécurité et plaques de danger":
        DispositionMetadata(
          referenceNormative: "NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Critique",
        ),
    "Présence de canalisations étrangères": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 514",
      familleRisque: "Erreur d’exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Présence d'un dispositif empêchant l'entrée d'eau et les infiltrations":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2 et art 522",
          familleRisque: "Humidité / défaut d'isolement / électrisation",
          criticite: "Critique",
        ),
    "Obturation coupe-feu des traversées de câbles et canalisations":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 421, art 422 et art 527",
          familleRisque: "Incendie / propagation du feu",
          criticite: "Majeure",
        ),
    "Absence de traces d'humidité, corrosion ou condensation":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2 et art 522",
          familleRisque: "Humidité / défaut d'isolement / électrisation",
          criticite: "Majeure",
        ),
    "Éclairage normal": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 559",
      familleRisque: "Sécurité d’exploitation",
      criticite: "Majeure",
    ),
    "Éclairage de secours conforme": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Partie 5-56",
      familleRisque: "Évacuation / continuité des installations de sécurité",
      criticite: "Majeure",
    ),
    "Ventilation / Climatisation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 512.2",
      familleRisque: "Échauffement / conditions d’environnement",
      criticite: "Majeure",
    ),
    "Compatibilité de la ventilation avec les équipements installés":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2",
          familleRisque: "Échauffement / conditions d'environnement",
          criticite: "Critique",
        ),
    "Présence d'un éclairage de sécurité permettant les manœuvres et l'évacuation":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 414",
          familleRisque:
              "Évacuation / continuité des installations de sécurité",
          criticite: "Majeure",
        ),
    "Revêtement de sol isolant ou antidérapant": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 555",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Présence d'un revêtement diélectrique ou isolant au sol":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 555",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Majeure",
        ),
    "Mise à la terre de toutes les masses métalliques": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 542 et art 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Présence de la terre du neutre": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 542 et art 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Présence de la terre des masses": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 542 et art 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),

    // --- II. CONDITIONS D'EXPLOITATION ET DE SÉCURITÉ LOCAL MOYENNE TENSION ---
    "Accès réservé au personnel habilité (habilitation électrique à jour)":
        DispositionMetadata(
          referenceNormative: "NF C 13-100:2015 – art 412",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Majeure",
        ),
    "Présence d'un dispositif de mise hors tension générale du local":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 462, art 465 et art 537",
          familleRisque: "Sécurité des interventions / arrêt d’urgence",
          criticite: "Critique",
        ),
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)":
        DispositionMetadata(
          referenceNormative: "NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Zone dégagée et propre, sans obstruction des voies d'accès":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 513",
          familleRisque: "Accès / exploitation / intervention",
          criticite: "Majeure",
        ),
    "Absence de stockage de matériaux inflammables": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 421, art 422 et art 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Identification et condamnation des accès aux parties sous tension":
        DispositionMetadata(
          referenceNormative: "NF C 13-100:2015 – art 541",
          familleRisque: "Électrisation / électrocution",
          criticite: "Critique",
        ),
    "Présence d'un plan d'intervention et de consignation affiché":
        DispositionMetadata(
          referenceNormative: "NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Disponibilité et mise à jour du schéma unifilaire de l'installation":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 514",
          familleRisque: "Erreur d'exploitation / maintenance",
          criticite: "Majeure",
        ),
    "Affichage des consignes de manœuvre, secours et premiers soins":
        DispositionMetadata(
          referenceNormative: "NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Critique",
        ),
    "Disponibilité du matériel de mise à la terre et en court-circuit":
        DispositionMetadata(
          referenceNormative: "NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Critique",
        ),
    "Disponibilité d'un dispositif de vérification d'absence de tension adapté à la MT":
        DispositionMetadata(
          referenceNormative: "NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Critique",
        ),
    "Contrôle périodique et traçabilité des EPI et équipements de sécurité":
        DispositionMetadata(
          referenceNormative: "NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible":
        DispositionMetadata(
          referenceNormative: "NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 514",
          familleRisque: "Erreur d’exploitation / maintenance",
          criticite: "Majeure",
        ),
    "Tenue d'un registre des opérations, incidents et maintenances":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 561",
          familleRisque: "Évacuation / sécurité incendie",
          criticite: "Critique",
        ),
    "Présence d'une procédure de consignation et déconsignation":
        DispositionMetadata(
          referenceNormative: "NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),

    // --- III. CELLULE MOYENNE TENSION ---
    "Schéma unifilaire affiché dans le local": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – art 134",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Verrouillage mécanique": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – art 464.1",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Fonctionnement des interverrouillages électriques et mécaniques":
        DispositionMetadata(
          referenceNormative: "NF C 13-100:2015 – art 511",
          familleRisque: "Électrisation / électrocution",
          criticite: "Majeure",
        ),
    "Etat et serrage apparent des connexions accessibles": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – art 413",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Identification et lisibilité des plaques signalétiques":
        DispositionMetadata(
          referenceNormative: "NF C 13-100:2015 – art 514",
          familleRisque: "Erreur d’exploitation",
          criticite: "Majeure",
        ),
    "Cellule correctement posée et fixée": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – art 411.3",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Critique",
    ),
    "Jonctions inter-cellules": DispositionMetadata(
      referenceNormative: "NF C 13-200:2009 – art 542 à art 544",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Canalisations et câbles d'arrivée / départ": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – art 514",
      familleRisque: "Erreur d'exploitation",
      criticite: "Majeure",
    ),
    "État général de l'enveloppe, absence de corrosion et déformation":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2",
          familleRisque:
              "Protection mécanique / pénétration corps solides-liquides",
          criticite: "Majeure",
        ),
    "État des isolateurs et absence de traces d'amorçage": DispositionMetadata(
      referenceNormative: "NF EN 62271-200",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Respect des distances de sécurité": DispositionMetadata(
      referenceNormative: "NF C 13-200:2009 – art 412.2",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Voyants de position (O / F / T)": DispositionMetadata(
      referenceNormative: "NF C 13-200:2009 – art 133.4",
      familleRisque: "Erreur de manœuvre",
      criticite: "Majeure",
    ),
    "Présence et état des dispositifs de détection / indication de tension":
        DispositionMetadata(
          referenceNormative: "NF C 13-200:2009 – art 538",
          familleRisque: "Électrisation / électrocution",
          criticite: "Critique",
        ),
    "Terre de protection (PE) reliée à chaque cellule": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – Partie 5-54",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Fonctionnement du sectionneur de terre et indication de position":
        DispositionMetadata(
          referenceNormative: "NF EN 62271-102",
          familleRisque: "Électrocution",
          criticite: "Critique",
        ),
    "Continuité du circuit de terre de la cellule": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 542 et art 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Majeure",
    ),
    "Conformité du pouvoir de coupure aux caractéristiques du réseau":
        DispositionMetadata(
          referenceNormative: "NF C 13-100:2015 – art 312",
          familleRisque: "Défaillance d’exploitation",
          criticite: "Majeure",
        ),
    "Etat des fusibles, disjoncteurs et relais de protection":
        DispositionMetadata(
          referenceNormative: "NF C 13-200:2009 – art 431 et art 432",
          familleRisque: "Électrisation / électrocution / défaut d'isolement",
          criticite: "Critique",
        ),
    "Réglage et coordination des protections MT": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 542",
      familleRisque: "Défaut de coordination / perte de sélectivité",
      criticite: "Majeure",
    ),
    "Commande manuelle / motorisée": DispositionMetadata(
      referenceNormative: "NF EN 62271-200",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Absence d'échauffement anormal contrôlée par thermographie infrarouge":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 6.6.4.3.2",
          familleRisque: "Incendie / échauffement",
          criticite: "Majeure",
        ),

    // --- IV. TRANSFORMATEUR MT/BT ---
    "Adapté au local et à la ventilation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 512.2",
      familleRisque:
          "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Vérification de la ventilation et des distances de dégagement":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2",
          familleRisque:
              "Protection mécanique / pénétration corps solides-liquides",
          criticite: "Majeure",
        ),
    "État et dimensionnement du bac de rétention pour transformateur à huile":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Plaque signalétique (puissance, tension, couplage)": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 538",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Raccordement des câbles MT et BT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 544",
      familleRisque: "Électrisation / défaut de continuité de protection",
      criticite: "Critique",
    ),
    "État général du transformateur et absence de fuite d'huile":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Majeure",
        ),
    "État des traversées / isolateurs MT et BT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 414",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "État des connexions et serrage des bornes MT et BT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 526",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Bac de rétention (pour transfo à huile)": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 551",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Niveau d'huile conforme pour transformateur immergé": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 551",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Essais diélectriques": DispositionMetadata(
      referenceNormative: "NF C 13-200:2009 – art 426.8",
      familleRisque: "Électrisation / défaut d'isolement",
      criticite: "Majeure",
    ),
    "Écran de câble MT relié à la terre": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 544",
      familleRisque: "Électrisation / défaut de continuité de protection",
      criticite: "Critique",
    ),
    "Distance entre transformateur": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – art 432",
      familleRisque: "Incendie",
      criticite: "Majeure",
    ),
    "État et fonctionnement des dispositifs de surveillance de température":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 465",
          familleRisque: "Sécurité des interventions / arrêt d’urgence",
          criticite: "Majeure",
        ),
    "Compatibilité de la puissance du transformateur avec la charge":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 311",
          familleRisque: "Continuité de service / surcharge / exploitation",
          criticite: "Critique",
        ),
    "Mise à la terre du neutre et de la carcasse": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 542",
      familleRisque:
          "Électrisation / défaut d’évacuation des courants de défaut",
      criticite: "Critique",
    ),
    "Continuité de la mise à la terre de la cuve et des masses":
        DispositionMetadata(
          referenceNormative: "NF C 13-100:2015 – art 412.1",
          familleRisque: "Électrocution",
          criticite: "Critique",
        ),
    "Protection contre les contacts directs": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 414",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Protection contre les surintensités": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 430",
      familleRisque: "Incendie / échauffement / détérioration des conducteurs",
      criticite: "Critique",
    ),
    "Protection MT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 512.2",
      familleRisque:
          "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Protection BT (disjoncteur général, fusibles, relais thermique)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 430",
          familleRisque:
              "Incendie / échauffement / détérioration des conducteurs",
          criticite: "Critique",
        ),
    "Fonctionnement des protections DGPT2 / Buchholz lorsqu'elles existent":
        DispositionMetadata(
          referenceNormative: "NF C 13-100:2015 – art 112",
          familleRisque: "Incendie / échauffement",
          criticite: "Critique",
        ),
    "Protection contre les surtensions côté MT et BT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 414",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Contrôle thermographique des connexions, et protections":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 6.6.4.3.2",
          familleRisque: "Incendie / échauffement",
          criticite: "Majeure",
        ),
    "Mesure de la résistance d'isolement des enroulements": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 538",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Contrôle du rapport de transformation et du couplage": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – art 134",
      familleRisque: "Non-conformité réglementaire",
      criticite: "Mineure",
    ),

    // --- V. DISPOSITIONS CONSTRUCTIVES & CONDITIONS GROUPE ÉLECTROGENE (Nouveaux points spécifiques) ---
    "Sol du local imperméable et formé comme une cuvette étanche, le seuil des baies étant surélevé d'au moins 0,10 mètre et toutes dispositions doivent être prises pour que le combustible accidentellement répandu ne puisse se déverser par les orifices placés dans le sol.":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Présence d'une rétention adaptée au stockage et aux fuites de combustible":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Canalisations du combustible": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 551",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Moyens d'extinction adaptés aux risques électriques et de carburant":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "État et étanchéité des conduites et raccords de combustible":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Évacuation des gaz d'échappement vers l'extérieur sans risque pour les occupants":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Protection des parties chaudes et du conduit d'échappement":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Ventilation suffisante pour le refroidissement et la combustion":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2",
          familleRisque: "Échauffement / conditions d’environnement",
          criticite: "Majeure",
        ),
    "Mise à la terre du châssis du groupe électrogène": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 542 et art 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Disponibilité des consignes de démarrage, arrêt normal et arrêt d'urgence":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 462, art 465 et art 537",
          familleRisque: "Sécurité des interventions / arrêt d’urgence",
          criticite: "Critique",
        ),
    "Disponibilité du schéma de raccordement et de l'inverseur de sources":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque:
              "Défaillance de la source de remplacement / continuité de service",
          criticite: "Majeure",
        ),
    "Contrôle du niveau de carburant, huile et liquide de refroidissement":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Absence de fuite de carburant ou d'huile lors de l'exploitation":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Essai périodique du démarrage automatique du groupe électrogène":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque:
              "Défaillance de la source de remplacement / continuité de service",
          criticite: "Majeure",
        ),
    "Traçabilité des essais périodiques et opérations de maintenance":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 561",
          familleRisque: "Évacuation / sécurité incendie",
          criticite: "Majeure",
        ),
    "Vérification du fonctionnement des alarmes et sécurités moteur":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque:
              "Défaillance de la source de remplacement / continuité de service",
          criticite: "Majeure",
        ),
  };

  /// Liste officielle des 21 points de vérification des Dispositions Constructives du Groupe Électrogène
  static const List<String> allGEDispositionsPoints = [
    "Sol du local imperméable et formé comme une cuvette étanche, le seuil des baies étant surélevé d'au moins 0,10 mètre et toutes dispositions doivent être prises pour que le combustible accidentellement répandu ne puisse se déverser par les orifices placés dans le sol.",
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
    "Dimensions",
    "Parois, plancher et plafond en matériaux non combustibles coupe-feu de degré 2 heures",
    "Présence d'une porte pleine coupe-feu de degré 1 heure, ouvrant vers l'extérieur, munie d'un dispositif antipanique",
    "Absence de communication directe avec les locaux à risque",
    "Absence de stockage d'objets non électriques",
    "Présence d'une rétention adaptée au stockage et aux fuites de combustible",
    "Présence d'un dispositif d'arrêt d'urgence accessible et identifié",
    "Canalisations du combustible",
    "Absence de canalisations étrangères",
    "Éclairage normal",
    "Éclairage de secours conforme",
    "Ventilation",
    "Moyens d'extinction adaptés aux risques électriques et de carburant",
    "État et étanchéité des conduites et raccords de combustible",
    "Évacuation des gaz d'échappement vers l'extérieur sans risque pour les occupants",
    "Protection des parties chaudes et du conduit d'échappement",
    "Ventilation suffisante pour le refroidissement et la combustion",
    "Mise à la terre de toutes les masses métalliques",
    "Mise à la terre du châssis du groupe électrogène",
  ];

  /// Liste officielle des 15 points de vérification des Conditions d'Exploitation du Groupe Électrogène
  static const List<String> allGEConditionsPoints = [
    "Accès réservé au personnel habilité (habilitation électrique à jour)",
    "Présence d'un dispositif de mise hors tension générale du local",
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)",
    "Zone dégagée et propre, sans obstruction des voies d'accès",
    "Absence de stockage de matériaux inflammables",
    "Présence d'un plan d'intervention et de consignation affiché",
    "Disponibilité des consignes de démarrage, arrêt normal et arrêt d'urgence",
    "Disponibilité du schéma de raccordement et de l'inverseur de sources",
    "Contrôle du niveau de carburant, huile et liquide de refroidissement",
    "Absence de fuite de carburant ou d'huile lors de l'exploitation",
    "Essai périodique du démarrage automatique du groupe électrogène",
    "Traçabilité des essais périodiques et opérations de maintenance",
    "Vérification du fonctionnement des alarmes et sécurités moteur",
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible",
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)",
  ];

  /// Registre spécifique des métadonnées pour le local Groupe Électrogène
  static const Map<String, DispositionMetadata> _geRegistry = {
    "Sol du local imperméable et formé comme une cuvette étanche, le seuil des baies étant surélevé d'au moins 0,10 mètre et toutes dispositions doivent être prises pour que le combustible accidentellement répandu ne puisse se déverser par les orifices placés dans le sol.":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"':
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 514",
          familleRisque: "Accès non autorisé / risque électrique",
          criticite: "Majeure",
        ),
    "Dimensions": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 513 et art 512.2",
      familleRisque:
          "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Parois, plancher et plafond en matériaux non combustibles coupe-feu de degré 2 heures":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 421, art 422 et art 527",
          familleRisque: "Incendie / propagation du feu",
          criticite: "Majeure",
        ),
    "Présence d'une porte pleine coupe-feu de degré 1 heure, ouvrant vers l'extérieur, munie d'un dispositif antipanique":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 421, art 422 et art 513",
          familleRisque: "Incendie / propagation du feu",
          criticite: "Majeure",
        ),
    "Absence de communication directe avec les locaux à risque":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2 et art 522",
          familleRisque:
              "Protection mécanique / pénétration corps solides-liquides",
          criticite: "Majeure",
        ),
    "Absence de stockage d'objets non électriques": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 421 et art 422",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Présence d'une rétention adaptée au stockage et aux fuites de combustible":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Présence d'un dispositif d'arrêt d'urgence accessible et identifié":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 465 et art 537",
          familleRisque: "Sécurité des interventions / arrêt d’urgence",
          criticite: "Critique",
        ),
    "Canalisations du combustible": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 551",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Absence de canalisations étrangères": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 514",
      familleRisque: "Sécurité d’exploitation",
      criticite: "Majeure",
    ),
    "Éclairage normal": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 559",
      familleRisque: "Sécurité d’exploitation",
      criticite: "Majeure",
    ),
    "Éclairage de secours conforme": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Partie 5-56",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Ventilation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 512.2 et art 551",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Moyens d'extinction adaptés aux risques électriques et de carburant":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 421, art 422 et art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "État et étanchéité des conduites et raccords de combustible":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Évacuation des gaz d'échappement vers l'extérieur sans risque pour les occupants":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Protection des parties chaudes et du conduit d'échappement":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 423 et art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Ventilation suffisante pour le refroidissement et la combustion":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2 et art 551",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Majeure",
        ),
    "Mise à la terre de toutes les masses métalliques": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 542 et art 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Mise à la terre du châssis du groupe électrogène": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 542 et art 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Accès réservé au personnel habilité (habilitation électrique à jour)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 6.5.1.2 ; NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Présence d'un dispositif de mise hors tension générale du local":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 462, art 465 et art 537",
          familleRisque: "Sécurité des interventions / arrêt d’urgence",
          criticite: "Critique",
        ),
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)":
        DispositionMetadata(
          referenceNormative: "NF C 18-510 ; NF C 15-100-1:2024 – art 6.5.1.2",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Zone dégagée et propre, sans obstruction des voies d'accès":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 513",
          familleRisque: "Accès / exploitation / intervention",
          criticite: "Majeure",
        ),
    "Absence de stockage de matériaux inflammables": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 421 et art 422",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Présence d'un plan d'intervention et de consignation affiché":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 514 ; NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Disponibilité des consignes de démarrage, arrêt normal et arrêt d'urgence":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 551.2.4, art 465 et art 537",
          familleRisque: "Sécurité des interventions / arrêt d’urgence",
          criticite: "Critique",
        ),
    "Disponibilité du schéma de raccordement et de l'inverseur de sources":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551.2.4 et art 537",
          familleRisque:
              "Défaillance de la source de remplacement / continuité de service",
          criticite: "Majeure",
        ),
    "Contrôle du niveau de carburant, huile et liquide de refroidissement":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Absence de fuite de carburant ou d'huile lors de l'exploitation":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551",
          familleRisque: "Incendie / brûlure / fuite de combustible",
          criticite: "Critique",
        ),
    "Essai périodique du démarrage automatique du groupe électrogène":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551.2 et art 6.5",
          familleRisque:
              "Défaillance de la source de remplacement / continuité de service",
          criticite: "Majeure",
        ),
    "Traçabilité des essais périodiques et opérations de maintenance":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 6.5 et art 6.6",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Majeure",
        ),
    "Vérification du fonctionnement des alarmes et sécurités moteur":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551.2",
          familleRisque:
              "Défaillance de la source de remplacement / continuité de service",
          criticite: "Majeure",
        ),
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible":
        DispositionMetadata(
          referenceNormative: "NF C 18-510 ; NF C 15-100-1:2024 – art 537",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 421 et art 422",
          familleRisque: "Erreur d’exploitation / maintenance",
          criticite: "Majeure",
        ),
  };

  static final Map<String, String> _geDispositionsTitleAliases = {
    _normalizeKey(
      "Parois, plancher et plafond en matériaux non combustibles",
    ): "Parois, plancher et plafond en matériaux non combustibles coupe-feu de degré 2 heures",
    _normalizeKey(
      "Parois, plancher et plafond en materiaux non combustibles",
    ): "Parois, plancher et plafond en matériaux non combustibles coupe-feu de degré 2 heures",
    _normalizeKey(
      "Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique",
    ): "Présence d'une porte pleine coupe-feu de degré 1 heure, ouvrant vers l'extérieur, munie d'un dispositif antipanique",
    _normalizeKey(
      "Présence d'une porte pleine, ouvrant vers l'exterieur, munie d'un dispositif anti-panique",
    ): "Présence d'une porte pleine coupe-feu de degré 1 heure, ouvrant vers l'extérieur, munie d'un dispositif antipanique",
    _normalizeKey("Présence de canalisations étrangères"):
        "Absence de canalisations étrangères",
    _normalizeKey("Présence de stockage d'objets non électriques"):
        "Absence de stockage d'objets non électriques",
    _normalizeKey("Ventilation / Climatisation"): "Ventilation",
  };

  static final Map<String, String> _geConditionsTitleAliases = {
    _normalizeKey("Présence de stockage de matériaux inflammables"):
        "Absence de stockage de matériaux inflammables",
    _normalizeKey("Presence de stockage de materiaux inflammables"):
        "Absence de stockage de matériaux inflammables",
    _normalizeKey(
      "Identification et condamnation des accès aux parties sous tension",
    ): "Accès réservé au personnel habilité (habilitation électrique à jour)",
    _normalizeKey(
      "Disponibilité et mise à jour du schéma unifilaire de l'installation",
    ): "Disponibilité du schéma de raccordement et de l'inverseur de sources",
    _normalizeKey(
      "Affichage des consignes de manœuvre, secours et premiers soins",
    ): "Présence d'un plan d'intervention et de consignation affiché",
    _normalizeKey(
      "Disponibilité du matériel de mise à la terre et en court-circuit",
    ): "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible",
  };

  /// Liste officielle des 23 points de vérification des Dispositions Constructives du Local Basse Tension (BT)
  static const List<String> allBTDispositionsPoints = [
    "Le local est exclusivement réservé à l'usage électrique",
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
    "Dimensions",
    "Parois, plancher et plafond en matériaux non combustibles",
    "Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique",
    "Verrouillage empêchant tout accès non autorisé",
    "Absence de communication directe avec les locaux à risque",
    "Absence de stockage d'objets non électriques",
    "Accessibilité du local et dégagement permanent devant les tableaux",
    "Obturation des traversées et maintien du degré coupe-feu des parois",
    "Présence et lisibilité des consignes de sécurité",
    "Identification du schéma de liaison à la terre de l'installation",
    "Présence de canalisations étrangères",
    "Absence d'infiltration d'eau, humidité ou condensation",
    "Éclairage normal",
    "Éclairage de secours conforme",
    "Ventilation / Climatisation",
    "Revêtement de sol isolant ou antidérapant",
    "Présence d'un revêtement diélectrique ou isolant au sol",
    "Mise à la terre de toutes les masses métalliques",
    "Présence de la terre du neutre",
    "Présence de la terre des masses",
    "Continuité des liaisons équipotentielles principales",
  ];

  /// Liste officielle des 13 points de vérification des Conditions d'Exploitation du Local Basse Tension (BT)
  static const List<String> allBTConditionsPoints = [
    "Accès réservé au personnel habilité (habilitation électrique à jour)",
    "Présence d'un dispositif de mise hors tension générale du local",
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)",
    "Zone dégagée et propre, sans obstruction des voies d'accès",
    "Absence de stockage de matériaux inflammables",
    "Accès permanent aux dispositifs de coupure d'urgence",
    "Absence de pièces nues sous tension accessibles",
    "Présence d'un plan d'intervention et de consignation affiché",
    "Disponibilité et mise à jour du schéma unifilaire",
    "Traçabilité des opérations de maintenance et des vérifications",
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible",
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)",
    "Disponibilité d'une procédure de consignation électrique",
  ];

  /// Registre spécifique des métadonnées pour le local Basse Tension (BT)
  static const Map<String, DispositionMetadata> _btRegistry = {
    "Le local est exclusivement réservé à l'usage électrique":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 513 et art 514 ",
          familleRisque: "Sécurité d’exploitation",
          criticite: "Majeure",
        ),
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"':
        DispositionMetadata(
          referenceNormative: "NF C 15-100-7-729:2024 – art 729",
          familleRisque: "Accès non autorisé / risque électrique",
          criticite: "Majeure",
        ),
    "Dimensions": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 513 et art 512.2",
      familleRisque:
          "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Parois, plancher et plafond en matériaux non combustibles":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 421, art 422 et art 527",
          familleRisque: "Incendie / propagation du feu",
          criticite: "Majeure",
        ),
    "Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 513",
          familleRisque: "Sécurité des interventions",
          criticite: "Majeure",
        ),
    "Verrouillage empêchant tout accès non autorisé": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 513 et art 514",
      familleRisque: "Accès non autorisé / risque électrique",
      criticite: "Majeure",
    ),
    "Absence de communication directe avec les locaux à risque":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2 et art 522",
          familleRisque:
              "Protection mécanique / pénétration corps solides-liquides",
          criticite: "Majeure",
        ),
    "Absence de stockage d'objets non électriques": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 421, art 422 et art 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Accessibilité du local et dégagement permanent devant les tableaux":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 513",
          familleRisque: "Accès / exploitation / intervention",
          criticite: "Majeure",
        ),
    "Obturation des traversées et maintien du degré coupe-feu des parois":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 421, art 422 et art 527",
          familleRisque: "Incendie / propagation du feu",
          criticite: "Majeure",
        ),
    "Présence et lisibilité des consignes de sécurité": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 514 ; NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
    "Identification du schéma de liaison à la terre de l'installation":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 514",
          familleRisque: "Erreur d’exploitation / maintenance",
          criticite: "Majeure",
        ),
    "Présence de canalisations étrangères": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 512.2 et art 522",
      familleRisque: "Erreur d’exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Absence d'infiltration d'eau, humidité ou condensation":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 421, art 422 et art 527",
          familleRisque: "Humidité / défaut d’isolement / électrisation",
          criticite: "Critique",
        ),
    "Éclairage normal": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 512.2 et art 522",
      familleRisque: "Sécurité d’exploitation",
      criticite: "Majeure",
    ),
    "Éclairage de secours conforme": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 559",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Ventilation / Climatisation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Partie 5-56",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Revêtement de sol isolant ou antidérapant": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 411",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Présence d'un revêtement diélectrique ou isolant au sol":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 411",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Majeure",
        ),
    "Mise à la terre de toutes les masses métalliques": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 542 et art 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Présence de la terre du neutre": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 312.2 et art 542",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Présence de la terre des masses": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 411, art 542 et art 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Continuité des liaisons équipotentielles principales": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 544",
      familleRisque: "Électrisation / défaut d’équipotentialité",
      criticite: "Critique",
    ),
    "Accès réservé au personnel habilité (habilitation électrique à jour)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 6.5.1.2 ; NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Présence d'un dispositif de mise hors tension générale du local":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 462, art 465 et art 537",
          familleRisque: "Sécurité des interventions / arrêt d’urgence",
          criticite: "Critique",
        ),
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)":
        DispositionMetadata(
          referenceNormative: "NF C 18-510 ; NF C 15-100-1:2024 – art 6.5.1.2",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Zone dégagée et propre, sans obstruction des voies d'accès":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 513",
          familleRisque: "Accès / exploitation / intervention",
          criticite: "Majeure",
        ),
    "Absence de stockage de matériaux inflammables": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 421 et art 422",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Accès permanent aux dispositifs de coupure d'urgence": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 465 et art 537",
      familleRisque: "Sécurité des interventions / arrêt d’urgence",
      criticite: "Critique",
    ),
    "Absence de pièces nues sous tension accessibles": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 411 et Annexe 41A",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Présence d'un plan d'intervention et de consignation affiché":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 514 ; NF C 18-510",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Disponibilité et mise à jour du schéma unifilaire": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 514",
      familleRisque: "Erreur d’exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Traçabilité des opérations de maintenance et des vérifications":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 6.5 et art 6.6",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Majeure",
        ),
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible":
        DispositionMetadata(
          referenceNormative: "NF C 18-510 ; NF C 15-100-1:2024 – art 537",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 421 et art 422",
          familleRisque: "Erreur d’exploitation / maintenance",
          criticite: "Majeure",
        ),
    "Disponibilité d'une procédure de consignation électrique":
        DispositionMetadata(
          referenceNormative: "NF C 18-510 ; NF C 15-100-1:2024 – art 537",
          familleRisque: "Sécurité des interventions / risque électrique",
          criticite: "Majeure",
        ),
  };

  static final Map<String, String> _btDispositionsTitleAliases = {
    _normalizeKey("Accessibilité du local et dégagement permanent des accès"):
        "Accessibilité du local et dégagement permanent devant les tableaux",
    _normalizeKey(
      "Obturation coupe-feu des traversées de câbles et canalisations",
    ): "Obturation des traversées et maintien du degré coupe-feu des parois",
    _normalizeKey(
      "Présence et lisibilité des consignes de sécurité et plaques de danger",
    ): "Présence et lisibilité des consignes de sécurité",
    _normalizeKey("Absence de traces d'humidité, corrosion ou condensation"):
        "Absence d'infiltration d'eau, humidité ou condensation",
    _normalizeKey(
      "Présence d'un éclairage de sécurité permettant les manœuvres et l'évacuation",
    ): "Éclairage de secours conforme",
    _normalizeKey("État et continuité des liaisons équipotentielles du local"):
        "Continuité des liaisons équipotentielles principales",
  };

  static final Map<String, String> _btConditionsTitleAliases = {
    _normalizeKey("Présence de stockage de matériaux inflammables"):
        "Absence de stockage de matériaux inflammables",
    _normalizeKey(
      "Disponibilité et mise à jour du schéma unifilaire de l'installation",
    ): "Disponibilité et mise à jour du schéma unifilaire",
    _normalizeKey(
      "Affichage des consignes de manœuvre, secours et premiers soins",
    ): "Présence d'un plan d'intervention et de consignation affiché",
    _normalizeKey(
      "Disponibilité du matériel de mise à la terre et en court-circuit",
    ): "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible",
  };

  /// Assure l'exhaustivité et l'ordonnancement exact des points de contrôle pour un local Groupe Électrogène.
  static void ensureCompleteGELocalChecklists({
    required List<ElementControle> dispositionsConstructives,
    required List<ElementControle> conditionsExploitation,
  }) {
    // --- 1. MIGRATION DES DISPOSITIONS CONSTRUCTIVES GE ---
    final existingDispMap = <String, ElementControle>{};
    final usedDispKeys = <String>{};
    for (final el in dispositionsConstructives) {
      final normKey = _normalizeKey(el.elementControle);
      String targetTitle = el.elementControle;

      if (_geDispositionsTitleAliases.containsKey(normKey)) {
        targetTitle = _geDispositionsTitleAliases[normKey]!;
      } else {
        for (final refTitle in allGEDispositionsPoints) {
          if (_normalizeKey(refTitle) == normKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      el.elementControle = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      final current = existingDispMap[targetKey];
      if (current == null) {
        existingDispMap[targetKey] = el;
      } else {
        if (current.conforme == null && el.conforme != null) {
          existingDispMap[targetKey] = el;
        } else if ((el.observation?.isNotEmpty == true) &&
            (current.observation == null || current.observation!.isEmpty)) {
          existingDispMap[targetKey] = el;
        }
      }
    }

    dispositionsConstructives.clear();
    for (final refTitle in allGEDispositionsPoints) {
      final targetKey = _normalizeKey(refTitle);
      if (existingDispMap.containsKey(targetKey)) {
        final el = existingDispMap[targetKey]!;
        usedDispKeys.add(targetKey);
        el.elementControle = refTitle;
        dispositionsConstructives.add(el);
      } else {
        dispositionsConstructives.add(
          ElementControle(
            elementControle: refTitle,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
    for (final entry in existingDispMap.entries) {
      if (!usedDispKeys.contains(entry.key)) {
        final el = entry.value;
        if (el.conforme != null ||
            !el.estNA ||
            (el.observation != null && el.observation!.isNotEmpty)) {
          dispositionsConstructives.add(el);
        }
      }
    }

    // --- 2. MIGRATION DES CONDITIONS D'EXPLOITATION GE ---
    final existingCondMap = <String, ElementControle>{};
    final usedCondKeys = <String>{};
    for (final el in conditionsExploitation) {
      final normKey = _normalizeKey(el.elementControle);
      String targetTitle = el.elementControle;

      if (_geConditionsTitleAliases.containsKey(normKey)) {
        targetTitle = _geConditionsTitleAliases[normKey]!;
      } else {
        for (final refTitle in allGEConditionsPoints) {
          if (_normalizeKey(refTitle) == normKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      el.elementControle = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      final current = existingCondMap[targetKey];
      if (current == null) {
        existingCondMap[targetKey] = el;
      } else {
        if (current.conforme == null && el.conforme != null) {
          existingCondMap[targetKey] = el;
        } else if ((el.observation?.isNotEmpty == true) &&
            (current.observation == null || current.observation!.isEmpty)) {
          existingCondMap[targetKey] = el;
        }
      }
    }

    conditionsExploitation.clear();
    for (final refTitle in allGEConditionsPoints) {
      final targetKey = _normalizeKey(refTitle);
      if (existingCondMap.containsKey(targetKey)) {
        final el = existingCondMap[targetKey]!;
        usedCondKeys.add(targetKey);
        el.elementControle = refTitle;
        conditionsExploitation.add(el);
      } else {
        conditionsExploitation.add(
          ElementControle(
            elementControle: refTitle,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
    for (final entry in existingCondMap.entries) {
      if (!usedCondKeys.contains(entry.key)) {
        final el = entry.value;
        if (el.conforme != null ||
            !el.estNA ||
            (el.observation != null && el.observation!.isNotEmpty)) {
          conditionsExploitation.add(el);
        }
      }
    }
  }

  /// Assure l'exhaustivité et l'ordonnancement exact des points de contrôle pour un local Basse Tension (BT).
  static void ensureCompleteBTLocalChecklists({
    required List<ElementControle> dispositionsConstructives,
    required List<ElementControle> conditionsExploitation,
  }) {
    // --- 1. MIGRATION DES DISPOSITIONS CONSTRUCTIVES BT ---
    final existingDispMap = <String, ElementControle>{};
    final usedDispKeys = <String>{};
    for (final el in dispositionsConstructives) {
      final normKey = _normalizeKey(el.elementControle);
      String targetTitle = el.elementControle;

      if (_btDispositionsTitleAliases.containsKey(normKey)) {
        targetTitle = _btDispositionsTitleAliases[normKey]!;
      } else {
        for (final refTitle in allBTDispositionsPoints) {
          if (_normalizeKey(refTitle) == normKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      el.elementControle = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      final current = existingDispMap[targetKey];
      if (current == null) {
        existingDispMap[targetKey] = el;
      } else {
        if (current.conforme == null && el.conforme != null) {
          existingDispMap[targetKey] = el;
        } else if ((el.observation?.isNotEmpty == true) &&
            (current.observation == null || current.observation!.isEmpty)) {
          existingDispMap[targetKey] = el;
        }
      }
    }

    dispositionsConstructives.clear();
    for (final refTitle in allBTDispositionsPoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getMetadata(refTitle, localType: 'LOCAL_BT');
      if (existingDispMap.containsKey(targetKey)) {
        final el = existingDispMap[targetKey]!;
        usedDispKeys.add(targetKey);
        el.elementControle = refTitle;
        if (meta != null) {
          el.referenceNormative ??= meta.referenceNormative;
          el.familleRisque ??= meta.familleRisque;
          el.criticite ??= meta.criticite;
        }
        dispositionsConstructives.add(el);
      } else {
        dispositionsConstructives.add(
          ElementControle(
            elementControle: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
    for (final entry in existingDispMap.entries) {
      if (!usedDispKeys.contains(entry.key)) {
        final el = entry.value;
        if (el.conforme != null ||
            !el.estNA ||
            (el.observation != null && el.observation!.isNotEmpty)) {
          dispositionsConstructives.add(el);
        }
      }
    }

    // --- 2. MIGRATION DES CONDITIONS D'EXPLOITATION BT ---
    final existingCondMap = <String, ElementControle>{};
    final usedCondKeys = <String>{};
    for (final el in conditionsExploitation) {
      final normKey = _normalizeKey(el.elementControle);
      String targetTitle = el.elementControle;

      if (_btConditionsTitleAliases.containsKey(normKey)) {
        targetTitle = _btConditionsTitleAliases[normKey]!;
      } else {
        for (final refTitle in allBTConditionsPoints) {
          if (_normalizeKey(refTitle) == normKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      el.elementControle = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      final current = existingCondMap[targetKey];
      if (current == null) {
        existingCondMap[targetKey] = el;
      } else {
        if (current.conforme == null && el.conforme != null) {
          existingCondMap[targetKey] = el;
        } else if ((el.observation?.isNotEmpty == true) &&
            (current.observation == null || current.observation!.isEmpty)) {
          existingCondMap[targetKey] = el;
        }
      }
    }

    conditionsExploitation.clear();
    for (final refTitle in allBTConditionsPoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getMetadata(refTitle, localType: 'LOCAL_BT');
      if (existingCondMap.containsKey(targetKey)) {
        final el = existingCondMap[targetKey]!;
        usedCondKeys.add(targetKey);
        el.elementControle = refTitle;
        if (meta != null) {
          el.referenceNormative ??= meta.referenceNormative;
          el.familleRisque ??= meta.familleRisque;
          el.criticite ??= meta.criticite;
        }
        conditionsExploitation.add(el);
      } else {
        conditionsExploitation.add(
          ElementControle(
            elementControle: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
    for (final entry in existingCondMap.entries) {
      if (!usedCondKeys.contains(entry.key)) {
        final el = entry.value;
        if (el.conforme != null ||
            !el.estNA ||
            (el.observation != null && el.observation!.isNotEmpty)) {
          conditionsExploitation.add(el);
        }
      }
    }
  }

  /// Liste officielle des 29 points de vérification pour les Coffrets / Armoires / TGBT
  static const List<String> allCoffretPoints = [
    "Emplacement / Dégagement autour",
    "Compatibilité du degré IP/IK avec l'environnement d'installation",
    "Présence d'écrans ou plastrons empêchant l'accès aux parties actives",
    "Continuité de la mise à la terre des portes et parties métalliques",
    "Réserve disponible et obturation des emplacements non utilisés",
    "Présence d'une coupure générale clairement identifiée et accessible",
    "Identification complète des circuits",
    "Respect code couleur des câbles",
    "Présence et lisibilité du schéma unifilaire et du repérage des départs",
    "Etat du Coffret / Armoire / TGBT",
    "Câblage",
    "Répartiteur de circuit",
    "Absence de surcharge des répartiteurs, borniers et jeux de barres",
    "État, fixation et protection des jeux de barres",
    "Contrôle thermographique des connexions, et protections",
    "Répartition des circuits",
    "Continuité du conducteur de protection (PE)",
    "Contrôle du courant dans le conducteur neutre",
    "Protection contre les contacts directs (capots, caches, bornes protégées)",
    "Présence et fonctionnement des dispositifs de protection",
    "Adéquation des dispositifs de protection",
    "Section des câbles d'alimentation adaptée au courant nominal des dispositifs de protection associés",
    "Coordination entre dispositifs de protection et contacteurs",
    "Coordination entre dispositifs de protection",
    "Protection contre les contacts indirects",
    "Sélectivité des protections (montée sélective des calibres)",
    "Dispositif de protection contre les surtensions (parafoudre)",
    "Coordination du parafoudre avec les protections amont",
    "Présence de double alimentation électrique",
  ];

  /// Registre spécifique des métadonnées pour Coffret / Armoire / TGBT
  static const Map<String, DispositionMetadata> _coffretRegistry = {
    "TGBT XXXXXX - Localisation - Zone (L'inspecteur va faire la recherche)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Majeure",
        ),
    "Present / Absent": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Emplacement / Dégagement autour": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 513",
      familleRisque: "Accès / exploitation / intervention",
      criticite: "Majeure",
    ),
    "Compatibilité du degré IP/IK avec l'environnement d'installation":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 512.2",
          familleRisque:
              "Contact électrique / influences externes / protection mécanique",
          criticite: "Majeure",
        ),
    "Présence d'écrans ou plastrons empêchant l'accès aux parties actives":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 411 et Annexe 41A",
          familleRisque: "Électrisation / électrocution",
          criticite: "Critique",
        ),
    "Continuité de la mise à la terre des portes et parties métalliques":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 544",
          familleRisque: "Sécurité d’exploitation",
          criticite: "Majeure",
        ),
    "Réserve disponible et obturation des emplacements non utilisés":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 411 et Annexe 41A",
          familleRisque: "Électrisation / contact avec parties actives",
          criticite: "Critique",
        ),
    "Présence d'une coupure générale clairement identifiée et accessible":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 462, art 465 et art 537",
          familleRisque: "Sécurité des interventions / arrêt d’urgence",
          criticite: "Critique",
        ),
    "Identification complète des circuits": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 514",
      familleRisque: "Erreur d’exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Respect code couleur des câbles": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 514",
      familleRisque: "Erreur d’exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Présence et lisibilité du schéma unifilaire et du repérage des départs":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 514",
          familleRisque: "Erreur d’exploitation / maintenance",
          criticite: "Majeure",
        ),
    "Etat du Coffret / Armoire / TGBT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 6.6.4.3.1",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Câblage": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Partie 5-52",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Répartiteur de circuit": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 526 et art 533",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Critique",
    ),
    "Absence de surcharge des répartiteurs, borniers et jeux de barres":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 523 et art 526",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Critique",
        ),
    "État, fixation et protection des jeux de barres": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 523 et art 526",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Critique",
    ),
    "Répartition des circuits": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 314",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Continuité du conducteur de protection (PE)": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 543 et art 6.4.3.8",
      familleRisque: "Électrisation / défaut de continuité de protection",
      criticite: "Critique",
    ),
    "Contrôle du courant dans le conducteur neutre": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 524.2",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Protection contre les contacts directs (capots, caches, bornes protégées)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 411 et Annexe 41A",
          familleRisque: "Électrisation / électrocution",
          criticite: "Critique",
        ),
    "Présence et fonctionnement des dispositifs de protection":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 430 à art 436 et art 533",
          familleRisque: "Surintensité / court-circuit / incendie",
          criticite: "Critique",
        ),
    "Adéquation des dispositifs de protection": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 430 à art 436 et art 533",
      familleRisque: "Surintensité / court-circuit / incendie",
      criticite: "Critique",
    ),
    "Section des câbles d'alimentation adaptée au courant nominal des dispositifs de protection associés":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 523, art 524 et art 433",
          familleRisque: "Incendie / échauffement / surcharge des conducteurs",
          criticite: "Critique",
        ),
    "Section des câbles de départs adaptée au courant nominal des dispositifs de protection associés":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 523, art 524 et art 433",
          familleRisque: "Incendie / échauffement / surcharge des conducteurs",
          criticite: "Critique",
        ),
    "Calibre des dispositifs de protection / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 434 et art 533",
          familleRisque: "Incendie / échauffement / surcharge des conducteurs",
          criticite: "Critique",
        ),
    "Coordination entre dispositifs de protection et contacteurs":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 536",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Majeure",
        ),
    "Coordination entre dispositifs de protection": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 536",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Section des câbles d'alimentation adaptée au courant nominal des disjoncteurs associés":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 523, art 524 et art 433",
          familleRisque: "Incendie / échauffement / surcharge des conducteurs",
          criticite: "Critique",
        ),
    "Section des câbles de départs adaptée au courant nominal des disjoncteurs associés":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 523, art 524 et art 433",
          familleRisque: "Incendie / échauffement / surcharge des conducteurs",
          criticite: "Critique",
        ),
    "Calibre des disjoncteurs / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 434 et art 533",
          familleRisque: "Incendie / échauffement / surcharge des conducteurs",
          criticite: "Critique",
        ),
    "Coordination entre disjoncteurs et contacteurs": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 536",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Coordination entre disjoncteurs": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 536",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Protection contre les contacts indirects": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 411",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Sélectivité des protections (montée sélective des calibres)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 536",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Majeure",
        ),
    "Dispositif de protection contre les surtensions (parafoudre)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 443 et art 534",
          familleRisque: "Surtension / foudre / détérioration des équipements",
          criticite: "Majeure",
        ),
    "Coordination du parafoudre avec les protections amont":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 443 et art 534",
          familleRisque: "Surtension / foudre / détérioration des équipements",
          criticite: "Majeure",
        ),
    "Coordination du parafoudre avec les protections amont et aval":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 443 et art 534",
          familleRisque: "Surtension / foudre / détérioration des équipements",
          criticite: "Majeure",
        ),
    "Présence de double alimentation électrique": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 313, art 551 et art 537",
      familleRisque: "Sécurité des interventions / arrêt d’urgence",
      criticite: "Majeure",
    ),
  };

  static const Map<String, DispositionMetadata> _legacyRegistry = {
    "Contrôle thermographique des connexions, et protections":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 6.6.4.3.2",
          familleRisque: "Incendie / échauffement",
          criticite: "Majeure",
        ),
  };

  /// Table d'alias pour les points de vérification Coffrets / Armoires / TGBT
  static final Map<String, String> _coffretTitleAliases = {
    _normalizeKey("Dégagement autour de l'équipement"):
        "Emplacement / Dégagement autour",
    _normalizeKey("Dégagement autour du coffret / armoire"):
        "Emplacement / Dégagement autour",
    _normalizeKey("Protection IP/IK adaptée au local d'installation"):
        "Compatibilité du degré IP/IK avec l'environnement d'installation",
    _normalizeKey("Protection IP/IK adaptée au local"):
        "Compatibilité du degré IP/IK avec l'environnement d'installation",
    _normalizeKey("Présence d'écrans ou plastrons (IP2X/IP4X)"):
        "Présence d'écrans ou plastrons empêchant l'accès aux parties actives",
    _normalizeKey("Continuité de masse des portes et parties métalliques"):
        "Continuité de la mise à la terre des portes et parties métalliques",
    _normalizeKey("Continuité de masse"):
        "Continuité de la mise à la terre des portes et parties métalliques",
    _normalizeKey("Obturation des réservations et espaces libres"):
        "Réserve disponible et obturation des emplacements non utilisés",
    _normalizeKey("Présence d'un organe de coupure générale accessible"):
        "Présence d'une coupure générale clairement identifiée et accessible",
    _normalizeKey("Présence d'un organe de coupure générale"):
        "Présence d'une coupure générale clairement identifiée et accessible",
    _normalizeKey(
      "Présence et fonctionnement des dispositifs de coupure / arrêt d'urgence",
    ): "Présence d'une coupure générale clairement identifiée et accessible",
    _normalizeKey("Identification des départ/circuits"):
        "Identification complète des circuits",
    _normalizeKey("Identification des départs"):
        "Identification complète des circuits",
    _normalizeKey("Repérage des conducteurs / code couleur"):
        "Respect code couleur des câbles",
    _normalizeKey(
      "Schéma électrique / unifilaire disponible sur site",
    ): "Présence et lisibilité du schéma unifilaire et du repérage des départs",
    _normalizeKey(
      "Schéma électrique disponible",
    ): "Présence et lisibilité du schéma unifilaire et du repérage des départs",
    _normalizeKey("Etat du coffret / Armoire"):
        "Etat du Coffret / Armoire / TGBT",
    _normalizeKey("Etat du coffret"): "Etat du Coffret / Armoire / TGBT",
    _normalizeKey("Propreté et état général du coffret"):
        "Etat du Coffret / Armoire / TGBT",
    _normalizeKey("État des connexions et échauffement visuel"):
        "Contrôle thermographique des connexions, et protections",
    _normalizeKey(
      "Section des câbles de départs adaptée au courant nominal des disjoncteurs associés",
    ): "Section des câbles de départs adaptée au courant nominal des dispositifs de protection associés",
    _normalizeKey(
      "Section des câbles d'alimentation adaptée au courant nominal des disjoncteurs associés",
    ): "Section des câbles d'alimentation adaptée au courant nominal des dispositifs de protection associés",
    _normalizeKey("Coordination entre disjoncteurs et contacteurs"):
        "Coordination entre dispositifs de protection et contacteurs",
    _normalizeKey("Coordination entre disjoncteurs"):
        "Coordination entre dispositifs de protection",
    _normalizeKey(
      "Sélectivité et coordination des protections (montée sélective des calibres)",
    ): "Sélectivité des protections (montée sélective des calibres)",
    _normalizeKey(
      "Sélectivité  des protections (montée sélective des calibres)",
    ): "Sélectivité des protections (montée sélective des calibres)",
    _normalizeKey(
      "Présence et conformité du dispositif de protection contre les surtensions (parafoudre)",
    ): "Dispositif de protection contre les surtensions (parafoudre)",
    _normalizeKey("Présence d'un parafoudre et état du voyant de d'état"):
        "Dispositif de protection contre les surtensions (parafoudre)",
    _normalizeKey("Présence d'un parafoudre"):
        "Dispositif de protection contre les surtensions (parafoudre)",
    _normalizeKey(
      "Coordination du parafoudre avec les protections amont et aval",
    ): "Coordination du parafoudre avec les protections amont",
  };

  /// Obtenir la métadonnée normative pour un point de coffret ou d'inverseur
  static DispositionMetadata? getCoffretMetadata(
    String pointVerification, {
    String? coffretType,
  }) {
    if (coffretType == 'INVERSEUR') {
      if (_inverseurRegistry.containsKey(pointVerification)) {
        return _inverseurRegistry[pointVerification];
      }
      final normKey = _normalizeKey(pointVerification);
      for (final entry in _inverseurRegistry.entries) {
        if (_normalizeKey(entry.key) == normKey) {
          return entry.value;
        }
      }
    }

    if (_coffretRegistry.containsKey(pointVerification)) {
      return _coffretRegistry[pointVerification];
    }
    final normKey = _normalizeKey(pointVerification);
    for (final entry in _coffretRegistry.entries) {
      if (_normalizeKey(entry.key) == normKey) {
        return entry.value;
      }
    }

    if (_inverseurRegistry.containsKey(pointVerification)) {
      return _inverseurRegistry[pointVerification];
    }
    for (final entry in _inverseurRegistry.entries) {
      if (_normalizeKey(entry.key) == normKey) {
        return entry.value;
      }
    }

    // Fallback historique sur le registre legacy
    if (_legacyRegistry.containsKey(pointVerification)) {
      return _legacyRegistry[pointVerification];
    }
    final normKeyLegacy = _normalizeKey(pointVerification);
    for (final entry in _legacyRegistry.entries) {
      if (_normalizeKey(entry.key) == normKeyLegacy) {
        return entry.value;
      }
    }

    return null;
  }

  /// Liste officielle des 31 points de vérification pour l'Inverseur de Source
  static const List<String> allInverseurPoints = [
    "Emplacement / Dégagement autour",
    "Protection IP/IK adaptée au local d'installation",
    "Interverrouillage empêchant le couplage intempestif des deux sources",
    "Identification complète des circuits",
    "Respect code couleur des câbles",
    "Identification claire des deux sources et de la source prioritaire",
    "Signalisation de la position des sources et de l'état de l'inverseur",
    "Etat du coffret / Armoire",
    "Câblage",
    "Répartiteur de circuit",
    "Dispositif de connexion",
    "Serrage et état des connexions contrôlés",
    "Répartition des circuits",
    "Continuité du conducteur de protection (PE)",
    "Protection contre les contacts directs (capots, caches, bornes protégées)",
    "Présence et fonctionnement des dispositifs de protection",
    "Adéquation des dispositifs de protection",
    "Section des câbles d'alimentation adaptée au courant nominal des dispositifs de protection associés",
    "Section des câbles de départs adaptée au courant nominal des dispositifs de protection associés",
    "Calibre des dispositifs de protection / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)",
    "Coordination entre dispositifs de protection et contacteurs",
    "Coordination entre dispositifs de protection",
    "Protection contre les contacts indirects",
    "Sélectivité des protections (montée sélective des calibres)",
    "Pouvoir de coupure et courant assigné adaptés à l'installation",
    "Protection contre les retours de tension vers une source indisponible",
    "Présence et fonctionnement des dispositifs de coupure / arrêt d'urgence",
    "Fonctionnement du transfert automatique et du retour à la source normale",
    "Temps de transfert compatible avec les équipements alimentés",
    "Commande manuelle de secours fonctionnelle",
    "Absence d'échauffement anormal par thermographie infrarouge",
  ];

  /// Registre spécifique des métadonnées pour Inverseur de Source
  static const Map<String, DispositionMetadata> _inverseurRegistry = {
    "SORTIE INVERSEUR": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Emplacement / Dégagement autour": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 513",
      familleRisque: "Accès / exploitation / intervention",
      criticite: "Majeure",
    ),
    "Protection IP/IK adaptée au local d'installation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 512.2",
      familleRisque:
          "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Interverrouillage empêchant le couplage intempestif des deux sources":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 551.2.1, art 551.2.2 et art 537",
          familleRisque:
              "Couplage intempestif / retour de tension / perte de continuité",
          criticite: "Critique",
        ),
    "Identification complète des circuits": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 514",
      familleRisque: "Erreur d’exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Respect code couleur des câbles": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 514",
      familleRisque: "Erreur d’exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Identification claire des deux sources et de la source prioritaire":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 514 et art 551.2.1",
          familleRisque: "Erreur d’exploitation / maintenance",
          criticite: "Majeure",
        ),
    "Signalisation de la position des sources et de l'état de l'inverseur":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 514 et art 551.2.4",
          familleRisque: "Erreur d’exploitation / maintenance",
          criticite: "Majeure",
        ),
    "Etat du coffret / Armoire": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 6.6.4.3.1",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Câblage": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Partie 5-52",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Répartiteur de circuit": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 526 et art 533",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Critique",
    ),
    "Dispositif de connexion": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 537",
      familleRisque: "Sécurité des interventions / arrêt d’urgence",
      criticite: "Majeure",
    ),
    "Serrage et état des connexions contrôlés": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 526",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Répartition des circuits": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 314",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Continuité du conducteur de protection (PE)": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 543 et art 6.4.3.8",
      familleRisque: "Électrisation / défaut de continuité de protection",
      criticite: "Critique",
    ),
    "Protection contre les contacts directs (capots, caches, bornes protégées)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 411 et Annexe 41A",
          familleRisque: "Électrisation / électrocution",
          criticite: "Critique",
        ),
    "Présence et fonctionnement des dispositifs de protection":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 430 à art 436 et art 533",
          familleRisque: "Surintensité / court-circuit / incendie",
          criticite: "Critique",
        ),
    "Adéquation des dispositifs de protection": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 430 à art 436 et art 533",
      familleRisque: "Surintensité / court-circuit / incendie",
      criticite: "Critique",
    ),
    "Section des câbles d'alimentation adaptée au courant nominal des disjoncteurs associés":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 523, art 524 et art 433",
          familleRisque: "Incendie / échauffement / surcharge des conducteurs",
          criticite: "Critique",
        ),
    "Section des câbles de départs adaptée au courant nominal des disjoncteurs associés":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 523, art 524 et art 433",
          familleRisque: "Incendie / échauffement / surcharge des conducteurs",
          criticite: "Critique",
        ),
    "Calibre des disjoncteurs / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 434 et art 533",
          familleRisque: "Incendie / échauffement / surcharge des conducteurs",
          criticite: "Critique",
        ),
    "Coordination entre disjoncteurs et contacteurs": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 536",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Coordination entre disjoncteurs": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 536",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Protection contre les contacts indirects": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 411",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Sélectivité  des protections (montée sélective des calibres)":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 536",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Majeure",
        ),
    "Pouvoir de coupure et courant assigné adaptés à l'installation":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 434 et art 533",
          familleRisque: "Sécurité / conformité réglementaire",
          criticite: "Critique",
        ),
    "Protection contre les retours de tension vers une source indisponible":
        DispositionMetadata(
          referenceNormative:
              "NF C 15-100-1:2024 – art 551.2.1, art 551.2.2 et art 537",
          familleRisque:
              "Couplage intempestif / retour de tension / perte de continuité",
          criticite: "Critique",
        ),
    "Présence et fonctionnement des dispositifs de coupure / arrêt d'urgence":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 465 et art 537",
          familleRisque: "Sécurité des interventions / arrêt d’urgence",
          criticite: "Critique",
        ),
    "Fonctionnement du transfert automatique et du retour à la source normale":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551.2.4 et art 537",
          familleRisque:
              "Couplage intempestif / retour de tension / perte de continuité",
          criticite: "Critique",
        ),
    "Temps de transfert compatible avec les équipements alimentés":
        DispositionMetadata(
          referenceNormative: "NF C 15-100-1:2024 – art 551.2.3",
          familleRisque:
              "Couplage intempestif / retour de tension / perte de continuité",
          criticite: "Critique",
        ),
    "Commande manuelle de secours fonctionnelle": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – art 551.2.4 et art 537",
      familleRisque:
          "Couplage intempestif / retour de tension / perte de continuité",
      criticite: "Critique",
    ),
  };

  /// Table d'alias 1-à-1 stricte pour l'Inverseur de Source (sans aucune collision N-to-1)
  static final Map<String, String> _inverseurTitleAliases = {
    _normalizeKey(
      "Dispositif de protection contre les surtensions (parafoudre)",
    ): "Dispositif de protection contre les surtensions (parafoudre)",
    _normalizeKey(
      "Présence et conformité du dispositif de protection contre les surtensions (parafoudre)",
    ): "Dispositif de protection contre les surtensions (parafoudre)",
    _normalizeKey("Présence d'un parafoudre"):
        "Dispositif de protection contre les surtensions (parafoudre)",
    _normalizeKey(
      "Pouvoir de coupure et courant assigné adaptés à l'installation",
    ): "Pouvoir de coupure et courant assigné adaptés à l'installation",
    _normalizeKey(
      "Sélectivité des protections (montée sélective des calibres)",
    ): "Sélectivité des protections (montée sélective des calibres)",
    _normalizeKey(
      "Sélectivité et coordination des protections (montée sélective des calibres)",
    ): "Sélectivité des protections (montée sélective des calibres)",
    _normalizeKey(
      "Sélectivité  des protections (montée sélective des calibres)",
    ): "Sélectivité des protections (montée sélective des calibres)",
    _normalizeKey("Emplacement / Dégagement autour"):
        "Emplacement / Dégagement autour",
    _normalizeKey(
      "Compatibilité du degré IP/IK avec l'environnement d'installation",
    ): "Protection IP/IK adaptée au local d'installation",
    _normalizeKey("Protection IP/IK adaptée au local"):
        "Protection IP/IK adaptée au local d'installation",
    _normalizeKey("Protection IP/IK adaptée au local d'installation"):
        "Protection IP/IK adaptée au local d'installation",
    _normalizeKey("Identification complète des circuits"):
        "Identification complète des circuits",
    _normalizeKey("Respect code couleur des câbles"):
        "Respect code couleur des câbles",
    _normalizeKey("Repérage des conducteurs / code couleur"):
        "Respect code couleur des câbles",
    _normalizeKey("Etat du Coffret / Armoire / TGBT"):
        "Etat du coffret / Armoire",
    _normalizeKey("Etat du coffret / Armoire"): "Etat du coffret / Armoire",
    _normalizeKey("Propreté et état général du coffret"):
        "Etat du coffret / Armoire",
    _normalizeKey("Câblage"): "Câblage",
    _normalizeKey("Répartiteur de circuit"): "Répartiteur de circuit",
    _normalizeKey("Dispositif de connexion"): "Dispositif de connexion",
    _normalizeKey("Serrage et état des connexions contrôlés"):
        "Serrage et état des connexions contrôlés",
    _normalizeKey("Répartition des circuits"): "Répartition des circuits",
    _normalizeKey("Continuité du conducteur de protection (PE)"):
        "Continuité du conducteur de protection (PE)",
    _normalizeKey(
      "Protection contre les contacts directs (capots, caches, bornes protégées)",
    ): "Protection contre les contacts directs (capots, caches, bornes protégées)",
    _normalizeKey("Présence et fonctionnement des dispositifs de protection"):
        "Présence et fonctionnement des dispositifs de protection",
    _normalizeKey("Adéquation des dispositifs de protection"):
        "Adéquation des dispositifs de protection",
    _normalizeKey(
      "Section des câbles d'alimentation adaptée au courant nominal des dispositifs de protection associés",
    ): "Section des câbles d'alimentation adaptée au courant nominal des dispositifs de protection associés",
    _normalizeKey(
      "Section des câbles d'alimentation adaptée au courant nominal des disjoncteurs associés",
    ): "Section des câbles d'alimentation adaptée au courant nominal des dispositifs de protection associés",
    _normalizeKey(
      "Section des câbles de départs adaptée au courant nominal des dispositifs de protection associés",
    ): "Section des câbles de départs adaptée au courant nominal des dispositifs de protection associés",
    _normalizeKey(
      "Section des câbles de départs adaptée au courant nominal des disjoncteurs associés",
    ): "Section des câbles de départs adaptée au courant nominal des dispositifs de protection associés",
    _normalizeKey(
      "Calibre des dispositifs de protection / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)",
    ): "Calibre des dispositifs de protection / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)",
    _normalizeKey(
      "Calibre des disjoncteurs / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)",
    ): "Calibre des dispositifs de protection / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)",
    _normalizeKey(
      "Coordination entre dispositifs de protection et contacteurs",
    ): "Coordination entre dispositifs de protection et contacteurs",
    _normalizeKey("Coordination entre disjoncteurs et contacteurs"):
        "Coordination entre dispositifs de protection et contacteurs",
    _normalizeKey("Coordination entre dispositifs de protection"):
        "Coordination entre dispositifs de protection",
    _normalizeKey("Coordination entre disjoncteurs"):
        "Coordination entre dispositifs de protection",
    _normalizeKey("Protection contre les contacts indirects"):
        "Protection contre les contacts indirects",
    _normalizeKey(
      "Interverrouillage mécanique et électrique entre les deux sources",
    ): "Interverrouillage empêchant le couplage intempestif des deux sources",
    _normalizeKey(
      "Identification claire de la source prioritaire et de la source de secours",
    ): "Identification claire des deux sources et de la source prioritaire",
    _normalizeKey(
      "Signalisation claire de la position de l'inverseur (Normal / Secours)",
    ): "Signalisation de la position des sources et de l'état de l'inverseur",
    _normalizeKey("Contrôle thermographique des connexions, et protections"):
        "Absence d'échauffement anormal par thermographie infrarouge",
    _normalizeKey("Thermographie infrarouge des connexions"):
        "Absence d'échauffement anormal par thermographie infrarouge",
  };

  /// Assure l'exhaustivité, la migration et l'ordonnancement exact (1 à 31) pour l'Inverseur de Source
  static void ensureCompleteInverseurChecklist(List<PointVerification> points) {
    final existingMap = <String, PointVerification>{};
    final usedKeys = <String>{};

    for (final pt in points) {
      final rawKey = _normalizeKey(pt.pointVerification);
      String targetTitle = pt.pointVerification;

      if (_inverseurTitleAliases.containsKey(rawKey)) {
        targetTitle = _inverseurTitleAliases[rawKey]!;
      } else {
        for (final refTitle in allInverseurPoints) {
          if (_normalizeKey(refTitle) == rawKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      pt.pointVerification = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      final confNorm = pt.normalizedConformite;
      final isExistingEmpty = confNorm.isEmpty;

      final current = existingMap[targetKey];
      if (current == null) {
        existingMap[targetKey] = pt;
      } else {
        final currentConfNorm = current.normalizedConformite;
        final currentIsEmpty = currentConfNorm.isEmpty;
        if (currentIsEmpty && !isExistingEmpty) {
          existingMap[targetKey] = pt;
        } else if ((pt.observation?.isNotEmpty == true ||
                (pt.observations != null && pt.observations!.isNotEmpty)) &&
            (current.observation == null || current.observation!.isEmpty)) {
          existingMap[targetKey] = pt;
        }
      }
    }

    points.clear();
    for (final refTitle in allInverseurPoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getCoffretMetadata(refTitle, coffretType: 'INVERSEUR');
      if (existingMap.containsKey(targetKey)) {
        final pt = existingMap[targetKey]!;
        usedKeys.add(targetKey);
        pt.pointVerification = refTitle;
        if (meta != null) {
          pt.referenceNormative ??= meta.referenceNormative;
          pt.familleRisque ??= meta.familleRisque;
          pt.criticite ??= meta.criticite;
        }
        points.add(pt);
      } else {
        points.add(
          PointVerification(
            pointVerification: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conformite: '',
          ),
        );
      }
    }

    // Conservation garantie de tous les points utilisateur orphelins (en excluant les points exclusifs de coffret)
    for (final entry in existingMap.entries) {
      if (!usedKeys.contains(entry.key) &&
          !EquipmentTypeTransitionService.isCoffretExclusivePoint(entry.value.pointVerification)) {
        points.add(entry.value);
      }
    }
  }

  /// Assure l'exhaustivité, la migration et l'ordonnancement exact (1 à 29) des points de vérification d'un coffret / armoire / TGBT
  static void ensureCompleteCoffretChecklist(List<PointVerification> points) {
    final existingMap = <String, PointVerification>{};
    final usedKeys = <String>{};

    for (final pt in points) {
      final rawKey = _normalizeKey(pt.pointVerification);
      String targetTitle = pt.pointVerification;

      if (_coffretTitleAliases.containsKey(rawKey)) {
        targetTitle = _coffretTitleAliases[rawKey]!;
      } else {
        for (final refTitle in allCoffretPoints) {
          if (_normalizeKey(refTitle) == rawKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      pt.pointVerification = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      final confNorm = pt.normalizedConformite;
      final isExistingEmpty = confNorm.isEmpty;

      final current = existingMap[targetKey];
      if (current == null) {
        existingMap[targetKey] = pt;
      } else {
        final currentConfNorm = current.normalizedConformite;
        final currentIsEmpty = currentConfNorm.isEmpty;
        if (currentIsEmpty && !isExistingEmpty) {
          existingMap[targetKey] = pt;
        } else if ((pt.observation?.isNotEmpty == true ||
                (pt.observations != null && pt.observations!.isNotEmpty)) &&
            (current.observation == null || current.observation!.isEmpty)) {
          existingMap[targetKey] = pt;
        }
      }
    }

    points.clear();
    for (final refTitle in allCoffretPoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getCoffretMetadata(refTitle);
      if (existingMap.containsKey(targetKey)) {
        final pt = existingMap[targetKey]!;
        usedKeys.add(targetKey);
        pt.pointVerification = refTitle;
        if (meta != null) {
          pt.referenceNormative ??= meta.referenceNormative;
          pt.familleRisque ??= meta.familleRisque;
          pt.criticite ??= meta.criticite;
        }
        points.add(pt);
      } else {
        points.add(
          PointVerification(
            pointVerification: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conformite: '',
          ),
        );
      }
    }

    // Conservation garantie de tous les points utilisateur orphelins (en excluant les points exclusifs d'inverseur)
    for (final entry in existingMap.entries) {
      if (!usedKeys.contains(entry.key) &&
          !EquipmentTypeTransitionService.isInverseurExclusivePoint(entry.value.pointVerification)) {
        points.add(entry.value);
      }
    }
  }

  /// Liste officielle des 25 points de vérification des Dispositions Constructives
  static const List<String> allDispositionsConstructives = [
    "Le local est exclusivement réservé à l'usage électrique",
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
    "Dimensions",
    "Parois, plancher et plafond en matériaux non combustibles",
    "Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique",
    "Verrouillage empêchant tout accès non autorisé",
    "Absence de communication directe avec les locaux à risque",
    "Absence de stockage d'objets non électriques",
    "Accessibilité du local et dégagement permanent des accès",
    "État et continuité des liaisons équipotentielles du local",
    "Présence et lisibilité des consignes de sécurité et plaques de danger",
    "Présence de canalisations étrangères",
    "Présence d'un dispositif empêchant l'entrée d'eau et les infiltrations",
    "Obturation coupe-feu des traversées de câbles et canalisations",
    "Absence de traces d'humidité, corrosion ou condensation",
    "Éclairage normal",
    "Éclairage de secours conforme",
    "Ventilation / Climatisation",
    "Compatibilité de la ventilation avec les équipements installés",
    "Présence d'un éclairage de sécurité permettant les manœuvres et l'évacuation",
    "Revêtement de sol isolant ou antidérapant",
    "Présence d'un revêtement diélectrique ou isolant au sol",
    "Mise à la terre de toutes les masses métalliques",
    "Présence de la terre du neutre",
    "Présence de la terre des masses",
  ];

  /// Liste officielle des 16 points de vérification des Conditions d'Exploitation et de Sécurité
  static const List<String> allConditionsExploitation = [
    "Accès réservé au personnel habilité (habilitation électrique à jour)",
    "Présence d'un dispositif de mise hors tension générale du local",
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)",
    "Zone dégagée et propre, sans obstruction des voies d'accès",
    "Absence de stockage de matériaux inflammables",
    "Identification et condamnation des accès aux parties sous tension",
    "Présence d'un plan d'intervention et de consignation affiché",
    "Disponibilité et mise à jour du schéma unifilaire de l'installation",
    "Affichage des consignes de manœuvre, secours et premiers soins",
    "Disponibilité du matériel de mise à la terre et en court-circuit",
    "Disponibilité d'un dispositif de vérification d'absence de tension adapté à la MT",
    "Contrôle périodique et traçabilité des EPI et équipements de sécurité",
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible",
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)",
    "Tenue d'un registre des opérations, incidents et maintenances",
    "Présence d'une procédure de consignation et déconsignation",
  ];

  /// Liste officielle des 21 points de vérification de la Cellule Moyenne Tension
  static const List<String> allCellulePoints = [
    "Schéma unifilaire affiché dans le local",
    "Verrouillage mécanique",
    "Fonctionnement des interverrouillages électriques et mécaniques",
    "Etat et serrage apparent des connexions accessibles",
    "Identification et lisibilité des plaques signalétiques",
    "Cellule correctement posée et fixée",
    "Jonctions inter-cellules",
    "Canalisations et câbles d'arrivée / départ",
    "État général de l'enveloppe, absence de corrosion et déformation",
    "État des isolateurs et absence de traces d'amorçage",
    "Respect des distances de sécurité",
    "Voyants de position (O / F / T)",
    "Présence et état des dispositifs de détection / indication de tension",
    "Terre de protection (PE) reliée à chaque cellule",
    "Fonctionnement du sectionneur de terre et indication de position",
    "Continuité du circuit de terre de la cellule",
    "Conformité du pouvoir de coupure aux caractéristiques du réseau",
    "Etat des fusibles, disjoncteurs et relais de protection",
    "Réglage et coordination des protections MT",
    "Commande manuelle / motorisée",
    "Absence d'échauffement anormal contrôlée par thermographie infrarouge",
  ];

  /// Liste officielle des 26 points de vérification du Transformateur MT/BT
  static const List<String> allTransformateurPoints = [
    "Adapté au local et à la ventilation",
    "Vérification de la ventilation et des distances de dégagement",
    "État et dimensionnement du bac de rétention pour transformateur à huile",
    "Plaque signalétique (puissance, tension, couplage)",
    "Raccordement des câbles MT et BT",
    "État général du transformateur et absence de fuite d'huile",
    "État des traversées / isolateurs MT et BT",
    "État des connexions et serrage des bornes MT et BT",
    "Bac de rétention (pour transfo à huile)",
    "Niveau d'huile conforme pour transformateur immergé",
    "Essais diélectriques",
    "Écran de câble MT relié à la terre",
    "Distance entre transformateur",
    "État et fonctionnement des dispositifs de surveillance de température",
    "Compatibilité de la puissance du transformateur avec la charge",
    "Mise à la terre du neutre et de la carcasse",
    "Continuité de la mise à la terre de la cuve et des masses",
    "Protection contre les contacts directs",
    "Protection contre les surintensités",
    "Protection MT",
    "Protection BT (disjoncteur général, fusibles, relais thermique)",
    "Fonctionnement des protections DGPT2 / Buchholz lorsqu'elles existent",
    "Protection contre les surtensions côté MT et BT",
    "Contrôle thermographique des connexions, et protections",
    "Mesure de la résistance d'isolement des enroulements",
    "Contrôle du rapport de transformation et du couplage",
  ];

  /// Assure l'exhaustivité et le respect strict de l'ordre officiel des points de contrôle pour un local.
  /// Les points manquants sont ajoutés à leur position de référence avec estNA = true ("Sans objet").
  static void ensureCompleteLocalChecklists({
    required List<ElementControle> dispositionsConstructives,
    required List<ElementControle> conditionsExploitation,
  }) {
    // 1. Dispositions Constructives MT
    final existingDispMap = <String, ElementControle>{};
    final usedDispKeys = <String>{};
    for (final el in dispositionsConstructives) {
      final normKey = _normalizeKey(el.elementControle);
      final current = existingDispMap[normKey];
      if (current == null) {
        existingDispMap[normKey] = el;
      } else {
        if (current.conforme == null && el.conforme != null) {
          existingDispMap[normKey] = el;
        } else if ((el.observation?.isNotEmpty == true) &&
            (current.observation == null || current.observation!.isEmpty)) {
          existingDispMap[normKey] = el;
        }
      }
    }

    dispositionsConstructives.clear();
    for (final refTitle in allDispositionsConstructives) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getMetadata(refTitle, localType: 'LOCAL_POSTE_HTA');
      if (existingDispMap.containsKey(targetKey)) {
        final el = existingDispMap[targetKey]!;
        usedDispKeys.add(targetKey);
        el.elementControle = refTitle;
        if (meta != null) {
          el.referenceNormative ??= meta.referenceNormative;
          el.familleRisque ??= meta.familleRisque;
          el.criticite ??= meta.criticite;
        }
        dispositionsConstructives.add(el);
      } else {
        dispositionsConstructives.add(
          ElementControle(
            elementControle: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
    for (final entry in existingDispMap.entries) {
      if (!usedDispKeys.contains(entry.key)) {
        final el = entry.value;
        if (el.conforme != null ||
            !el.estNA ||
            (el.observation != null && el.observation!.isNotEmpty)) {
          dispositionsConstructives.add(el);
        }
      }
    }

    // 2. Conditions d'Exploitation MT
    final existingCondMap = <String, ElementControle>{};
    final usedCondKeys = <String>{};
    for (final el in conditionsExploitation) {
      final normKey = _normalizeKey(el.elementControle);
      final current = existingCondMap[normKey];
      if (current == null) {
        existingCondMap[normKey] = el;
      } else {
        if (current.conforme == null && el.conforme != null) {
          existingCondMap[normKey] = el;
        } else if ((el.observation?.isNotEmpty == true) &&
            (current.observation == null || current.observation!.isEmpty)) {
          existingCondMap[normKey] = el;
        }
      }
    }

    conditionsExploitation.clear();
    for (final refTitle in allConditionsExploitation) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getMetadata(refTitle, localType: 'LOCAL_POSTE_HTA');
      if (existingCondMap.containsKey(targetKey)) {
        final el = existingCondMap[targetKey]!;
        usedCondKeys.add(targetKey);
        el.elementControle = refTitle;
        if (meta != null) {
          el.referenceNormative ??= meta.referenceNormative;
          el.familleRisque ??= meta.familleRisque;
          el.criticite ??= meta.criticite;
        }
        conditionsExploitation.add(el);
      } else {
        conditionsExploitation.add(
          ElementControle(
            elementControle: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
    for (final entry in existingCondMap.entries) {
      if (!usedCondKeys.contains(entry.key)) {
        final el = entry.value;
        if (el.conforme != null ||
            !el.estNA ||
            (el.observation != null && el.observation!.isNotEmpty)) {
          conditionsExploitation.add(el);
        }
      }
    }
  }

  /// Assure l'exhaustivité des points de contrôle pour une cellule (auto-migration silencieuse).
  static void ensureCompleteCelluleChecklist(
    List<ElementControle> elementsVerifies,
  ) {
    final existingMap = <String, ElementControle>{};
    final usedKeys = <String>{};
    for (final el in elementsVerifies) {
      final normKey = _normalizeKey(el.elementControle);
      final current = existingMap[normKey];
      if (current == null) {
        existingMap[normKey] = el;
      } else {
        if (current.conforme == null && el.conforme != null) {
          existingMap[normKey] = el;
        } else if ((el.observation?.isNotEmpty == true) &&
            (current.observation == null || current.observation!.isEmpty)) {
          existingMap[normKey] = el;
        }
      }
    }

    elementsVerifies.clear();
    for (final refTitle in allCellulePoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getMetadata(refTitle, localType: 'LOCAL_POSTE_HTA');
      if (existingMap.containsKey(targetKey)) {
        final el = existingMap[targetKey]!;
        usedKeys.add(targetKey);
        el.elementControle = refTitle;
        if (meta != null) {
          el.referenceNormative ??= meta.referenceNormative;
          el.familleRisque ??= meta.familleRisque;
          el.criticite ??= meta.criticite;
        }
        elementsVerifies.add(el);
      } else {
        elementsVerifies.add(
          ElementControle(
            elementControle: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
    for (final entry in existingMap.entries) {
      if (!usedKeys.contains(entry.key)) {
        final el = entry.value;
        if (el.conforme != null ||
            !el.estNA ||
            (el.observation != null && el.observation!.isNotEmpty)) {
          elementsVerifies.add(el);
        }
      }
    }
  }

  /// Assure l'exhaustivité des points de contrôle pour un transformateur (auto-migration silencieuse).
  static void ensureCompleteTransformateurChecklist(
    List<ElementControle> elementsVerifies,
  ) {
    final existingMap = <String, ElementControle>{};
    final usedKeys = <String>{};
    for (final el in elementsVerifies) {
      final normKey = _normalizeKey(el.elementControle);
      final current = existingMap[normKey];
      if (current == null) {
        existingMap[normKey] = el;
      } else {
        if (current.conforme == null && el.conforme != null) {
          existingMap[normKey] = el;
        } else if ((el.observation?.isNotEmpty == true) &&
            (current.observation == null || current.observation!.isEmpty)) {
          existingMap[normKey] = el;
        }
      }
    }

    elementsVerifies.clear();
    for (final refTitle in allTransformateurPoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getMetadata(refTitle, localType: 'LOCAL_POSTE_HTA');
      if (existingMap.containsKey(targetKey)) {
        final el = existingMap[targetKey]!;
        usedKeys.add(targetKey);
        el.elementControle = refTitle;
        if (meta != null) {
          el.referenceNormative ??= meta.referenceNormative;
          el.familleRisque ??= meta.familleRisque;
          el.criticite ??= meta.criticite;
        }
        elementsVerifies.add(el);
      } else {
        elementsVerifies.add(
          ElementControle(
            elementControle: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
    for (final entry in existingMap.entries) {
      if (!usedKeys.contains(entry.key)) {
        final el = entry.value;
        if (el.conforme != null ||
            !el.estNA ||
            (el.observation != null && el.observation!.isNotEmpty)) {
          elementsVerifies.add(el);
        }
      }
    }
  }

  /// Vérifie si le type de local correspond à un local de la famille Basse Tension (BT, TGBT, Onduleur, Électrique...)
  static bool isBTLocal(String? localType) {
    if (localType == null) return true;
    return localType == 'LOCAL_BT' ||
        localType == 'LOCAL_TGBT' ||
        localType == 'LOCAL_ONDULEUR' ||
        localType == 'LOCAL_ELECTRIQUE' ||
        localType == 'LOCAL_SERVEUR' ||
        localType == 'LOCAL_BATTERIES' ||
        localType == 'LOCAL_CHAUTERIE' ||
        localType == 'LOCAL_AUTRE' ||
        (![
          'LOCAL_TRANSFORMATEUR',
          'LOCAL_MTBT',
          'LOCAL_GROUPE_ELECTROGENE',
        ].contains(localType));
  }

  /// Retourne l'ensemble des points de vérification et leurs métadonnées normatives.
  static Map<String, DispositionMetadata> getAllEntries() {
    final Map<String, DispositionMetadata> combined = {};
    combined.addAll(_registry);
    combined.addAll(_btRegistry);
    combined.addAll(_geRegistry);
    combined.addAll(_coffretRegistry);
    combined.addAll(_inverseurRegistry);
    return combined;
  }

  /// Récupère la métadonnée par le libellé de l'élément de contrôle (avec recherche insensible aux majuscules/espaces)
  static DispositionMetadata? getMetadata(
    String elementControle, {
    String? localType,
  }) {
    if (localType == 'LOCAL_GROUPE_ELECTROGENE') {
      if (_geRegistry.containsKey(elementControle)) {
        return _geRegistry[elementControle];
      }
      final normKey = _normalizeKey(elementControle);
      for (final entry in _geRegistry.entries) {
        if (_normalizeKey(entry.key) == normKey) {
          return entry.value;
        }
      }
    }

    if (isBTLocal(localType)) {
      if (_btRegistry.containsKey(elementControle)) {
        return _btRegistry[elementControle];
      }
      final normKey = _normalizeKey(elementControle);
      for (final entry in _btRegistry.entries) {
        if (_normalizeKey(entry.key) == normKey) {
          return entry.value;
        }
      }
    }

    if (_registry.containsKey(elementControle)) {
      return _registry[elementControle];
    }
    final normalizedKey = _normalizeKey(elementControle);
    for (final entry in _registry.entries) {
      if (_normalizeKey(entry.key) == normalizedKey) {
        return entry.value;
      }
    }

    if (localType != 'LOCAL_GROUPE_ELECTROGENE') {
      if (_geRegistry.containsKey(elementControle)) {
        return _geRegistry[elementControle];
      }
      final normKey = _normalizeKey(elementControle);
      for (final entry in _geRegistry.entries) {
        if (_normalizeKey(entry.key) == normKey) {
          return entry.value;
        }
      }
    }

    if (!isBTLocal(localType)) {
      if (_btRegistry.containsKey(elementControle)) {
        return _btRegistry[elementControle];
      }
      final normKey = _normalizeKey(elementControle);
      for (final entry in _btRegistry.entries) {
        if (_normalizeKey(entry.key) == normKey) {
          return entry.value;
        }
      }
    }

    return null;
  }

  static String _normalizeKey(String key) {
    return key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
