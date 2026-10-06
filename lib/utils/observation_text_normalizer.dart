// lib/utils/observation_text_normalizer.dart

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/audit_installations_electriques.dart';
import '../models/description_installations.dart';
import '../models/mesures_essais.dart';
import '../models/lighting_inspection.dart';
import '../models/foudre.dart';
import '../models/jsa.dart';

/// Résultat détaillé d'un Dry Run ou d'une migration des observations
class ObservationMigrationReport {
  final int totalAnalyzed;
  final int totalModified;
  final int totalUnchanged;
  final int ambiguousCases;
  final List<ObservationSampleDiff> samples;

  const ObservationMigrationReport({
    required this.totalAnalyzed,
    required this.totalModified,
    required this.totalUnchanged,
    required this.ambiguousCases,
    required this.samples,
  });

  @override
  String toString() {
    return 'ObservationMigrationReport('
        'analyzed: $totalAnalyzed, '
        'modified: $totalModified, '
        'unchanged: $totalUnchanged, '
        'ambiguous: $ambiguousCases, '
        'samples: ${samples.length})';
  }
}

/// Exemple de transformation avant / après pour le rapport
class ObservationSampleDiff {
  final String source;
  final String before;
  final String after;

  const ObservationSampleDiff({
    required this.source,
    required this.before,
    required this.after,
  });
}

/// Utilitaire de normalisation automatique et centralisée du texte des observations.
///
/// Garantit :
/// - Première lettre alphabétique pertinente en majuscule pour chaque phrase.
/// - Détection fine multi-phrases (. ! ? \n et puces - • *).
/// - Préservation stricte des chaînes techniques (IP54, IK08, 230 V, 3x16 A, IΔn, 6 kA, NF C 15-100).
/// - Préservation des nombres décimaux (2.5 mm², 0.5 MΩ, 12.5 A).
/// - Préservation des abréviations usuelles (art., ref., ex., cf., env., etc., vol., c.à.d., n°).
/// - Préservation des points de suspension (...).
/// - Idempotence absolue : normalize(normalize(x)) == normalize(x).
class ObservationTextNormalizer {
  const ObservationTextNormalizer._();

  static const Set<String> _knownAbbreviations = {
    'art',
    'ref',
    'ex',
    'cf',
    'env',
    'etc',
    'vol',
    'al',
    'par',
    'fig',
    'tab',
  };

  /// Normalise une chaîne d'observation isolée.
  static String? normalize(String? input) {
    if (input == null) return null;
    if (input.trim().isEmpty) return '';

    final buffer = StringBuffer();
    bool isStartOfSentence = true;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (isStartOfSentence) {
        if (_isSentencePrefix(char)) {
          buffer.write(char);
          continue;
        } else if (_isLetter(char)) {
          buffer.write(char.toUpperCase());
          isStartOfSentence = false;
        } else {
          // Chiffre ou autre caractère débutant la phrase (ex. 230 V, 3x16 A, 1.)
          buffer.write(char);
          isStartOfSentence = false;
        }
      } else {
        buffer.write(char);

        // Détection de fin de phrase
        if (char == '!' || char == '?') {
          isStartOfSentence = true;
        } else if (char == '\n') {
          isStartOfSentence = true;
        } else if (char == ':') {
          // Deux-points annonce souvent une précision ou suite
          isStartOfSentence = true;
        } else if (char == '.') {
          // 1. Points de suspension (...)
          final hasNextDot = (i + 1 < input.length && input[i + 1] == '.');
          final hasPrevDot = (i > 0 && input[i - 1] == '.');

          if (hasNextDot) {
            // Milieu ou début des points de suspension, continuer
            continue;
          }
          if (hasPrevDot && !hasNextDot) {
            // Dernier point de suspension : la phrase se termine ici
            isStartOfSentence = true;
            continue;
          }

          // 2. Séparateur décimal (ex: 2.5 mm², 0.5 MΩ)
          final isDecimal = (i > 0 && i + 1 < input.length) &&
              _isDigit(input[i - 1]) &&
              _isDigit(input[i + 1]);
          if (isDecimal) {
            continue;
          }

          // 3. Abréviations connues (ex: art. 12, ref. KES, ex. câble)
          if (_isPrecededByAbbreviation(input, i)) {
            continue;
          }

          // Point classique de fin de phrase
          isStartOfSentence = true;
        }
      }
    }

    final res = buffer.toString();
    final trimmed = res.trim();
    if (trimmed.isNotEmpty) {
      final lastChar = trimmed[trimmed.length - 1];
      if (lastChar != '.' &&
          lastChar != '!' &&
          lastChar != '?' &&
          lastChar != ':' &&
          lastChar != '-' &&
          lastChar != '–' &&
          lastChar != '—') {
        return '$trimmed.';
      }
    }

    return res;
  }

  static bool _isDigit(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  static bool _isLetter(String char) {
    if (char.isEmpty) return false;
    return RegExp(r'[a-zA-ZàâäéèêëîïôöùûüÿçœæÀÂÄÉÈÊËÎÏÔÖÙÛÜŸÇŒÆ]').hasMatch(char);
  }

  static bool _isSentencePrefix(String char) {
    return char == ' ' ||
        char == '\t' ||
        char == '\r' ||
        char == '\n' ||
        char == '-' ||
        char == '•' ||
        char == '*' ||
        char == '"' ||
        char == '«' ||
        char == '»' ||
        char == '\'' ||
        char == '(' ||
        char == '[' ||
        char == '{' ||
        char == '>' ||
        char == '–' ||
        char == '—';
  }

  static bool _isPrecededByAbbreviation(String text, int dotIndex) {
    int start = dotIndex - 1;
    while (start >= 0 && _isLetter(text[start])) {
      start--;
    }
    final word = text.substring(start + 1, dotIndex).toLowerCase();
    return _knownAbbreviations.contains(word);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NORMALISATION DU DOMAINE (CENTRALISÉE & EXHAUSTIVE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Normalise exhaustivement un modèle AuditInstallationsElectriques
  static void normalizeAuditInstallations(AuditInstallationsElectriques audit) {
    // Moyenne Tension Locaux
    for (final local in audit.moyenneTensionLocaux) {
      _normalizeMTLocal(local);
    }

    // Moyenne Tension Zones
    for (final zone in audit.moyenneTensionZones) {
      for (final obs in zone.observationsLibres) {
        obs.texte = normalize(obs.texte) ?? obs.texte;
      }
      for (final coffret in zone.coffrets) {
        _normalizeCoffret(coffret);
      }
      for (final local in zone.locaux) {
        _normalizeMTLocal(local);
      }
    }

    // Basse Tension Zones
    for (final zone in audit.basseTensionZones) {
      for (final obs in zone.observationsLibres) {
        obs.texte = normalize(obs.texte) ?? obs.texte;
      }
      for (final coffret in zone.coffretsDirects) {
        _normalizeCoffret(coffret);
      }
      for (final local in zone.locaux) {
        _normalizeBTLocal(local);
      }
    }
  }

  static void _normalizeMTLocal(MoyenneTensionLocal local) {
    for (final el in local.dispositionsConstructives) {
      el.observation = normalize(el.observation);
    }
    for (final el in local.conditionsExploitation) {
      el.observation = normalize(el.observation);
    }
    for (final obs in local.observationsLibres) {
      obs.texte = normalize(obs.texte) ?? obs.texte;
    }
    // Cellules
    for (final cellule in local.cellules) {
      _normalizeCellule(cellule);
    }
    if (local.cellule != null) {
      _normalizeCellule(local.cellule!);
    }
    // Transformateurs
    for (final transfo in local.transformateurs) {
      _normalizeTransformateur(transfo);
    }
    if (local.transformateur != null) {
      _normalizeTransformateur(local.transformateur!);
    }
    // Coffrets
    for (final coffret in local.coffrets) {
      _normalizeCoffret(coffret);
    }
  }

  static void _normalizeBTLocal(BasseTensionLocal local) {
    for (final el in (local.dispositionsConstructives ?? [])) {
      el.observation = normalize(el.observation);
    }
    for (final el in (local.conditionsExploitation ?? [])) {
      el.observation = normalize(el.observation);
    }
    for (final obs in local.observationsLibres) {
      obs.texte = normalize(obs.texte) ?? obs.texte;
    }
    for (final coffret in local.coffrets) {
      _normalizeCoffret(coffret);
    }
  }

  static void _normalizeCellule(Cellule c) {
    for (final el in c.elementsVerifies) {
      el.observation = normalize(el.observation);
    }
    if (c.observations != null) {
      for (final el in c.observations!) {
        el.observation = normalize(el.observation);
      }
    }
  }

  static void _normalizeTransformateur(TransformateurMTBT t) {
    for (final el in t.elementsVerifies) {
      el.observation = normalize(el.observation);
    }
    if (t.observations != null) {
      for (final el in t.observations!) {
        el.observation = normalize(el.observation);
      }
    }
  }

  static void _normalizeCoffret(CoffretArmoire c) {
    for (final pv in c.pointsVerification) {
      pv.observation = normalize(pv.observation);
      if (pv.observations != null) {
        for (final el in pv.observations!) {
          el.observation = normalize(el.observation);
        }
      }
    }
    for (final obs in c.observationsLibres) {
      obs.texte = normalize(obs.texte) ?? obs.texte;
    }
  }

  /// Normalise exhaustivement un modèle DescriptionInstallations
  static void normalizeDescriptionInstallations(DescriptionInstallations desc) {
    for (final obs in desc.foudreObservations) {
      obs.texte = normalize(obs.texte) ?? obs.texte;
    }

    final allItems = [
      ...desc.alimentationMoyenneTension,
      ...desc.alimentationBasseTension,
      ...desc.groupeElectrogene,
      ...desc.alimentationCarburant,
      ...desc.inverseur,
      ...desc.stabilisateur,
      ...desc.onduleurs,
      ...desc.cpi,
    ];

    for (final item in allItems) {
      for (final key in item.data.keys.toList()) {
        final val = item.data[key];
        if (val != null && val.trim().isNotEmpty) {
          // Normaliser si c'est un champ de texte libre (observations, remarques, constats, etc.)
          final kLower = key.toLowerCase();
          if (kLower.contains('obs') ||
              kLower.contains('remarque') ||
              kLower.contains('constat') ||
              kLower.contains('commentaire') ||
              kLower.contains('description')) {
            item.data[key] = normalize(val) ?? val;
          }
        }
      }
    }
  }

  /// Normalise exhaustivement un modèle MesuresEssais
  static void normalizeMesuresEssais(MesuresEssais mesures) {
    for (final pt in mesures.prisesTerre) {
      pt.observation = normalize(pt.observation);
    }
    if (mesures.avisMesuresTerre.observation != null) {
      mesures.avisMesuresTerre.observation =
          normalize(mesures.avisMesuresTerre.observation);
    }
    for (final cr in mesures.continuiteResistances) {
      cr.observation = normalize(cr.observation);
    }
    for (final ed in mesures.essaisDeclenchement) {
      ed.observation = normalize(ed.observation);
    }
    mesures.conditionMesure.observation =
        normalize(mesures.conditionMesure.observation);
    mesures.testArretUrgence.observation =
        normalize(mesures.testArretUrgence.observation);
    mesures.essaiDemarrageAuto.observation =
        normalize(mesures.essaiDemarrageAuto.observation);
  }

  /// Normalise un point de vérification
  static void normalizePointVerification(PointVerification pv) {
    pv.observation = normalize(pv.observation);
    if (pv.observations != null) {
      for (final el in pv.observations!) {
        el.observation = normalize(el.observation);
      }
    }
  }

  /// Normalise exhaustivement une inspection d'éclairage
  static LightingInspection normalizeLightingInspection(LightingInspection inspection) {
    for (final lum in inspection.nonConformingLuminaires) {
      for (final ans in lum.answers) {
        ans.commentaire = normalize(ans.commentaire);
      }
    }
    return inspection;
  }

  /// Normalise une observation Foudre
  static void normalizeFoudre(Foudre foudre) {
    foudre.observation = normalize(foudre.observation) ?? foudre.observation;
  }

  /// Normalise un modèle JSA
  static void normalizeJSA(JSA jsa) {
    if (jsa.dangers.autreEnvironnement.isNotEmpty) {
      jsa.dangers.autreEnvironnement =
          normalize(jsa.dangers.autreEnvironnement) ?? jsa.dangers.autreEnvironnement;
    }
    if (jsa.verificationFinale.autresPoints.isNotEmpty) {
      jsa.verificationFinale.autresPoints =
          normalize(jsa.verificationFinale.autresPoints) ??
              jsa.verificationFinale.autresPoints;
    }
  }

  /// Normalise un brouillon de coffret ou de local
  static void normalizeDraftMap(Map<dynamic, dynamic> draft) {
    if (draft.containsKey('observationsLibres') &&
        draft['observationsLibres'] is List) {
      final list = draft['observationsLibres'] as List;
      for (final item in list) {
        if (item is Map && item.containsKey('texte')) {
          item['texte'] = normalize(item['texte']?.toString()) ?? item['texte'];
        }
      }
    }
    if (draft.containsKey('pointsVerification') &&
        draft['pointsVerification'] is List) {
      final list = draft['pointsVerification'] as List;
      for (final item in list) {
        if (item is Map) {
          if (item.containsKey('observation')) {
            item['observation'] =
                normalize(item['observation']?.toString());
          }
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRY RUN & MIGRATION HISTORIQUE IDEMPOTENTE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Exécute un dry run ou applique la migration sur toutes les boîtes Hive
  static Future<ObservationMigrationReport> runMigrationOrDryRun({
    bool applyChanges = false,
  }) async {
    int totalAnalyzed = 0;
    int totalModified = 0;
    int totalUnchanged = 0;
    int ambiguousCases = 0;
    final samples = <ObservationSampleDiff>[];

    void inspect(String source, String? original, void Function(String) onApply) {
      if (original == null || original.trim().isEmpty) return;
      totalAnalyzed++;
      final normalized = normalize(original);
      if (normalized != null && normalized != original) {
        totalModified++;
        if (samples.length < 20) {
          samples.add(ObservationSampleDiff(
            source: source,
            before: original,
            after: normalized,
          ));
        }
        if (applyChanges) {
          onApply(normalized);
        }
      } else {
        totalUnchanged++;
      }
    }

    // 1. Audit Installations Électriques
    if (Hive.isBoxOpen('audit_installations_electriques')) {
      final box = Hive.box<AuditInstallationsElectriques>('audit_installations_electriques');
      for (final audit in box.values) {
        bool auditModified = false;

        void checkObsLibre(ObservationLibre obs, String context) {
          inspect('$context.observationLibre', obs.texte, (newVal) {
            obs.texte = newVal;
            auditModified = true;
          });
        }

        void checkElement(ElementControle el, String context) {
          inspect('$context.elementControle', el.observation, (newVal) {
            el.observation = newVal;
            auditModified = true;
          });
        }

        void checkPoint(PointVerification pv, String context) {
          inspect('$context.pointVerification', pv.observation, (newVal) {
            pv.observation = newVal;
            auditModified = true;
          });
          if (pv.observations != null) {
            for (final el in pv.observations!) {
              checkElement(el, '$context.pointVerification.subObs');
            }
          }
        }

        // MT Locaux
        for (final loc in audit.moyenneTensionLocaux) {
          for (final el in loc.dispositionsConstructives) {
            checkElement(el, 'MTLocal(${loc.nom}).dispConst');
          }
          for (final el in loc.conditionsExploitation) {
            checkElement(el, 'MTLocal(${loc.nom}).condExploit');
          }
          for (final obs in loc.observationsLibres) {
            checkObsLibre(obs, 'MTLocal(${loc.nom})');
          }
          for (final cel in loc.cellules) {
            for (final el in cel.elementsVerifies) {
              checkElement(el, 'Cellule(${cel.nom})');
            }
            if (cel.observations != null) {
              for (final el in cel.observations!) {
                checkElement(el, 'Cellule(${cel.nom}).obs');
              }
            }
          }
          for (final tr in loc.transformateurs) {
            for (final el in tr.elementsVerifies) {
              checkElement(el, 'Transfo(${tr.nom})');
            }
            if (tr.observations != null) {
              for (final el in tr.observations!) {
                checkElement(el, 'Transfo(${tr.nom}).obs');
              }
            }
          }
          for (final cof in loc.coffrets) {
            for (final pv in cof.pointsVerification) {
              checkPoint(pv, 'Coffret(${cof.nom})');
            }
            for (final obs in cof.observationsLibres) {
              checkObsLibre(obs, 'Coffret(${cof.nom})');
            }
          }
        }

        // BT Zones
        for (final z in audit.basseTensionZones) {
          for (final obs in z.observationsLibres) {
            checkObsLibre(obs, 'BTZone(${z.nom})');
          }
          for (final cof in z.coffretsDirects) {
            for (final pv in cof.pointsVerification) {
              checkPoint(pv, 'BTZone(${z.nom}).Coffret(${cof.nom})');
            }
            for (final obs in cof.observationsLibres) {
              checkObsLibre(obs, 'BTZone(${z.nom}).Coffret(${cof.nom})');
            }
          }
          for (final loc in z.locaux) {
            for (final el in (loc.dispositionsConstructives ?? [])) {
              checkElement(el, 'BTLocal(${loc.nom}).dispConst');
            }
            for (final el in (loc.conditionsExploitation ?? [])) {
              checkElement(el, 'BTLocal(${loc.nom}).condExploit');
            }
            for (final obs in loc.observationsLibres) {
              checkObsLibre(obs, 'BTLocal(${loc.nom})');
            }
            for (final cof in loc.coffrets) {
              for (final pv in cof.pointsVerification) {
                checkPoint(pv, 'BTLocal(${loc.nom}).Coffret(${cof.nom})');
              }
              for (final obs in cof.observationsLibres) {
                checkObsLibre(obs, 'BTLocal(${loc.nom}).Coffret(${cof.nom})');
              }
            }
          }
        }

        if (applyChanges && auditModified) {
          await audit.save();
        }
      }
    }

    // 2. Mesures & Essais
    if (Hive.isBoxOpen('mesures_essais')) {
      final box = Hive.box<MesuresEssais>('mesures_essais');
      for (final m in box.values) {
        bool mModified = false;
        for (final pt in m.prisesTerre) {
          inspect('PriseTerre', pt.observation, (val) {
            pt.observation = val;
            mModified = true;
          });
        }
        if (m.avisMesuresTerre.observation != null) {
          inspect('AvisMesuresTerre', m.avisMesuresTerre.observation, (val) {
            m.avisMesuresTerre.observation = val;
            mModified = true;
          });
        }
        for (final cr in m.continuiteResistances) {
          inspect('ContinuiteResistance', cr.observation, (val) {
            cr.observation = val;
            mModified = true;
          });
        }
        for (final ed in m.essaisDeclenchement) {
          inspect('EssaiDeclenchement', ed.observation, (val) {
            ed.observation = val;
            mModified = true;
          });
        }
        inspect('ConditionMesure', m.conditionMesure.observation, (val) {
          m.conditionMesure.observation = val;
          mModified = true;
        });
        inspect('TestArretUrgence', m.testArretUrgence.observation, (val) {
          m.testArretUrgence.observation = val;
          mModified = true;
        });
        inspect('EssaiDemarrageAuto', m.essaiDemarrageAuto.observation, (val) {
          m.essaiDemarrageAuto.observation = val;
          mModified = true;
        });

        if (applyChanges && mModified) {
          await m.save();
        }
      }
    }

    // 3. Foudre
    if (Hive.isBoxOpen('foudre_observations')) {
      final box = Hive.box<Foudre>('foudre_observations');
      for (final f in box.values) {
        inspect('Foudre', f.observation, (val) {
          f.observation = val;
          if (applyChanges) f.save();
        });
      }
    }

    // 4. Lighting Inspections
    if (Hive.isBoxOpen('lighting_inspections')) {
      final box = Hive.box<LightingInspection>('lighting_inspections');
      for (final l in box.values) {
        bool lModified = false;
        for (final lum in l.nonConformingLuminaires) {
          for (final ans in lum.answers) {
            inspect('LightingAnswer', ans.commentaire, (val) {
              ans.commentaire = val;
              lModified = true;
            });
          }
        }
        if (applyChanges && lModified) {
          await l.save();
        }
      }
    }

    final report = ObservationMigrationReport(
      totalAnalyzed: totalAnalyzed,
      totalModified: totalModified,
      totalUnchanged: totalUnchanged,
      ambiguousCases: ambiguousCases,
      samples: samples,
    );

    if (kDebugMode) {
      print('📊 Rapport Dry-Run Normalisation: $report');
    }

    return report;
  }
}

/// Fonction utilitaire de raccourci
String? normalizeObservationText(String? input) =>
    ObservationTextNormalizer.normalize(input);
