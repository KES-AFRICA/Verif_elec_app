import '../models/audit_installations_electriques.dart';
import 'dispositions_constructives_registry.dart';

/// Service central déterministe gérant l'intégrité métier et la compatibilité des équipements
/// lors d'un changement de type ou de la normalisation de données historiques (Coffret, Armoire, TGBT, Inverseur).
class EquipmentTypeTransitionService {
  /// Ensemble des titres de points de vérification strictement exclusifs à l'Inverseur de Source.
  /// Ces points ne doivent JAMAIS apparaître dans un Coffret, une Armoire ou un TGBT.
  static final Set<String> inverseurExclusivePointKeys = {
    _normalizeKey("Interverrouillage empêchant le couplage intempestif des deux sources"),
    _normalizeKey("Interverrouillage mécanique et électrique entre les deux sources"),
    _normalizeKey("Identification claire des deux sources et de la source prioritaire"),
    _normalizeKey("Identification claire de la source prioritaire et de la source de secours"),
    _normalizeKey("Signalisation de la position des sources et de l'état de l'inverseur"),
    _normalizeKey("Signalisation claire de la position de l'inverseur (Normal / Secours)"),
    _normalizeKey("Protection contre les retours de tension vers une source indisponible"),
    _normalizeKey("Fonctionnement du transfert automatique et du retour à la source normale"),
    _normalizeKey("Temps de transfert compatible avec les équipements alimentés"),
    _normalizeKey("Commande manuelle de secours fonctionnelle"),
    _normalizeKey("Absence d'échauffement anormal par thermographie infrarouge"),
    _normalizeKey("Dispositif de connexion"),
    _normalizeKey("Serrage et état des connexions contrôlés"),
    _normalizeKey("Pouvoir de coupure et courant assigné adaptés à l'installation"),
    _normalizeKey("Etat des équipements"),
    _normalizeKey("fixation des équipements"),
    _normalizeKey("Protection IP/IK adaptée au local d'installation"),
    _normalizeKey("Présence et fonctionnement des dispositifs de coupure / arrêt d'urgence"),
  };

  /// Ensemble des titres de points de vérification exclusifs aux Coffrets / Armoires / TGBT.
  static final Set<String> coffretExclusivePointKeys = {
    _normalizeKey("Compatibilité du degré IP/IK avec l'environnement d'installation"),
    _normalizeKey("Présence d'écrans ou plastrons empêchant l'accès aux parties actives"),
    _normalizeKey("Continuité de la mise à la terre des portes et parties métalliques"),
    _normalizeKey("Réserve disponible et obturation des emplacements non utilisés"),
    _normalizeKey("Présence d'une coupure générale clairement identifiée et accessible"),
    _normalizeKey("Présence et lisibilité du schéma unifilaire et du repérage des départs"),
    _normalizeKey("Etat du Coffret / Armoire / TGBT"),
    _normalizeKey("Absence de surcharge des répartiteurs, borniers et jeux de barres"),
    _normalizeKey("État, fixation et protection des jeux de barres"),
    _normalizeKey("Contrôle du courant dans le conducteur neutre"),
    _normalizeKey("Dispositif de protection contre les surtensions (parafoudre)"),
    _normalizeKey("Coordination du parafoudre avec les protections amont"),
    _normalizeKey("Coordination du parafoudre avec les protections amont et aval"),
  };

  static String _normalizeKey(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// Indique si un point de vérification est strictement exclusif à l'Inverseur.
  static bool isInverseurExclusivePoint(String title) {
    return inverseurExclusivePointKeys.contains(_normalizeKey(title));
  }

  /// Indique si un point de vérification est strictement exclusif à un Coffret/Armoire/TGBT.
  static bool isCoffretExclusivePoint(String title) {
    return coffretExclusivePointKeys.contains(_normalizeKey(title));
  }

  /// Normalise un équipement [coffret] pour correspondre strictement à son [targetType].
  /// Préserve l'identité technique (id, numéro, photos, métadonnées communes)
  /// tout en éliminant les données structurellement incompatibles avec le type cible.
  static void normalizeEquipmentForType(CoffretArmoire coffret, String targetType) {
    final normalizedType = targetType.toUpperCase().trim();
    coffret.type = normalizedType;

    if (normalizedType == 'INVERSEUR') {
      // 1. Présence CPI non applicable aux inverseurs
      coffret.presenceCPI = null;

      // 2. Protection de tête non applicable à l'inverseur (située sur les alimentations d'entrée/sorties)
      coffret.protectionTete = null;

      // 3. Départs et circuits terminaux : non applicables à l'inverseur (ce sont des sorties inverseur)
      // On conserve les listes vides pour éviter les incohérences de modèle
      coffret.departures = [];
      coffret.terminalCircuits = [];

      // 4. Structure des alimentations : 2 entrées + sorties (au moins 3 éléments)
      final alims = List<Alimentation>.from(coffret.alimentations);
      while (alims.length < 3) {
        alims.add(Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''));
      }
      coffret.alimentations = alims;

      // 5. Checklist : points d'inverseur
      // Éliminer d'abord les points exclusifs de coffret avant d'exécuter la garantie
      coffret.pointsVerification.removeWhere(
        (pt) => isCoffretExclusivePoint(pt.pointVerification),
      );
      DispositionsConstructivesRegistry.ensureCompleteInverseurChecklist(
        coffret.pointsVerification,
      );
    } else {
      // Pour COFFRET, ARMOIRE, TGBT :
      // 1. Purge des points exclusifs à l'Inverseur
      coffret.pointsVerification.removeWhere(
        (pt) => isInverseurExclusivePoint(pt.pointVerification),
      );

      // 2. Assurer la checklist officielle des coffrets
      DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(
        coffret.pointsVerification,
      );

      // 3. Protection de tête : s'assurer qu'elle existe
      coffret.protectionTete ??= Alimentation(
        typeProtection: '',
        pdcKA: '',
        calibre: '',
        sectionCable: '',
      );

      // 4. Nettoyage des alimentations :
      // Si l'équipement provient d'un ancien INVERSEUR, il avait 3+ alimentations
      // dont les indices 1 et 2 étaient "Source de secours" et "Sortie 1".
      // Pour un coffret/armoire, si les alimentations d'index >= 1 sont vides ou génériques
      // ("Source inconnue", pas de calibre, pas de protection), les retirer pour ne pas polluer le PDF.
      if (coffret.alimentations.length > 1) {
        final alimsNettoyees = <Alimentation>[];
        for (int i = 0; i < coffret.alimentations.length; i++) {
          final a = coffret.alimentations[i];
          if (i == 0) {
            alimsNettoyees.add(a);
          } else {
            // Ne conserver les alimentations secondaires que si elles contiennent de vraies données
            final hasData = (a.source.trim().isNotEmpty && !a.source.trim().toLowerCase().contains('inconn')) ||
                (a.typeProtection.trim().isNotEmpty && a.typeProtection.trim() != '-') ||
                (a.calibre.trim().isNotEmpty && a.calibre.trim() != '-') ||
                (a.sectionCable.trim().isNotEmpty && a.sectionCable.trim() != '-');
            if (hasData) {
              alimsNettoyees.add(a);
            }
          }
        }
        coffret.alimentations = alimsNettoyees;
      }
      if (coffret.alimentations.isEmpty) {
        coffret.alimentations = [
          Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''),
        ];
      }
    }
  }

  /// Assainit les points de vérification d'un équipement lors du rendu PDF ou de la lecture
  /// afin d'éliminer immédiatement toute contamination dans les missions historiques.
  static List<PointVerification> filterPointsForDisplay(
    List<PointVerification> points,
    String equipmentType,
  ) {
    final typeNorm = equipmentType.toUpperCase().trim();
    if (typeNorm == 'INVERSEUR') {
      return points.where((pt) => !isCoffretExclusivePoint(pt.pointVerification)).toList();
    } else {
      return points.where((pt) => !isInverseurExclusivePoint(pt.pointVerification)).toList();
    }
  }

  /// Assainit les alimentations d'un équipement COFFRET / ARMOIRE / TGBT lors du rendu PDF
  /// pour ne pas afficher des lignes factices orphelines provenant d'un ancien inverseur.
  static List<Alimentation> filterAlimentationsForDisplay(
    List<Alimentation> alims,
    String equipmentType,
  ) {
    final typeNorm = equipmentType.toUpperCase().trim();
    if (typeNorm == 'INVERSEUR') return alims;
    if (alims.length <= 1) return alims;

    final cleaned = <Alimentation>[];
    for (int i = 0; i < alims.length; i++) {
      final a = alims[i];
      if (i == 0) {
        cleaned.add(a);
      } else {
        final hasRealData = (a.source.trim().isNotEmpty &&
                !a.source.trim().toLowerCase().contains('inconnu') &&
                !a.source.trim().toLowerCase().contains('source 2')) ||
            (a.typeProtection.trim().isNotEmpty &&
                a.typeProtection.trim() != '-' &&
                a.typeProtection.trim().toLowerCase() != 'absent') ||
            (a.calibre.trim().isNotEmpty && a.calibre.trim() != '-');
        if (hasRealData) {
          cleaned.add(a);
        }
      }
    }
    return cleaned.isEmpty ? [alims.first] : cleaned;
  }
}
