import 'package:flutter/foundation.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/services/hive_service.dart';

class IpIkEvaluationResult {
  final String conformite; // 'oui' ou 'non'
  final String? observation;
  final String? repereIpIkFormatted;

  const IpIkEvaluationResult({
    required this.conformite,
    this.observation,
    this.repereIpIkFormatted,
  });
}

class ParsedIpIk {
  final String? ip; // ex: "IP55"
  final String? ik; // ex: "IK08"

  const ParsedIpIk({this.ip, this.ik});

  String? get ipDigits {
    if (ip == null) return null;
    final digits = ip!.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : digits;
  }

  String? get ikDigits {
    if (ik == null) return null;
    final digits = ik!.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : digits;
  }

  /// Construit la chaîne formatée normalisée à partir des chiffres entrés par l'utilisateur
  static String formatFromDigits(String? ipDigits, String? ikDigits) {
    final ipClean = ipDigits?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final ikClean = ikDigits?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';

    final ipPart = ipClean.isNotEmpty ? 'IP$ipClean' : null;
    final ikPart = ikClean.isNotEmpty ? 'IK$ikClean' : null;

    if (ipPart != null && ikPart != null) {
      return '$ipPart / $ikPart';
    } else if (ipPart != null) {
      return ipPart;
    } else if (ikPart != null) {
      return ikPart;
    }
    return '';
  }

  static ParsedIpIk parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const ParsedIpIk(ip: null, ik: null);
    }
    final s = raw.trim().toUpperCase();

    String? ipVal;
    String? ikVal;

    final ipMatch = RegExp(r'IP\s*([0-9]{1,2})').firstMatch(s);
    if (ipMatch != null) {
      ipVal = 'IP${ipMatch.group(1)}';
    }

    final ikMatch = RegExp(r'IK\s*([0-9]{1,2})').firstMatch(s);
    if (ikMatch != null) {
      ikVal = 'IK${ikMatch.group(1)}';
    }

    // Si ni "IP" ni "IK" n'apparaissent mais qu'une suite de chiffres est passée (ex: "55" ou "5508")
    if (ipVal == null && ikVal == null) {
      final digitsOnly = s.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length == 2) {
        ipVal = 'IP$digitsOnly';
      } else if (digitsOnly.length == 4) {
        ipVal = 'IP${digitsOnly.substring(0, 2)}';
        ikVal = 'IK${digitsOnly.substring(2, 4)}';
      }
    }

    return ParsedIpIk(ip: ipVal, ik: ikVal);
  }

  bool get hasIpOrIk => ip != null || ik != null;

  @override
  String toString() {
    if (ip != null && ik != null) return '$ip / $ik';
    if (ip != null) return ip!;
    if (ik != null) return ik!;
    return '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedIpIk &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          ik == other.ik;

  @override
  int get hashCode => ip.hashCode ^ ik.hashCode;
}

class IpIkEvaluatorService {
  /// Titres officiels des points de vérification IP/IK
  static const String coffretPointTitle =
      "Compatibilité du degré IP/IK avec l'environnement d'installation";
  static const String inverseurPointTitle =
      "Protection IP/IK adaptée au local d'installation";

  static bool isIpIkPoint(String title) {
    final t = title.trim();
    return t == coffretPointTitle ||
        t == inverseurPointTitle ||
        t.toLowerCase().contains("compatibilité du degré ip/ik") ||
        t.toLowerCase().contains("protection ip/ik adaptée");
  }

  /// Détecte si l'observation actuelle est une observation automatique générée par le système
  static bool isAutomatedIpIkObservation(String? obs) {
    if (obs == null) return false;
    final o = obs.trim().toLowerCase();
    return o.contains("absence de l'indice ip/ik") ||
        o.contains("absence d'indice ip/ik") ||
        o.contains("absence de l'indice") ||
        o.contains("différent de l'indice") ||
        o.contains("different de l'indice");
  }

  /// Synchronise déterministement le point de vérification IP/IK selon la règle métier
  static void syncIpIkPoint({
    required CoffretArmoire coffret,
    required String missionId,
    String? parentName,
    AuditInstallationsElectriques? audit,
  }) {
    for (final point in coffret.pointsVerification) {
      if (isIpIkPoint(point.pointVerification)) {
        final eval = evaluate(
          coffret: coffret,
          missionId: missionId,
          parentName: parentName,
          audit: audit,
        );

        // Si l'équipement n'a pas d'IP/IK renseigné, il est obligatoirement NON CONFORME
        final hasNoIpIk =
            coffret.indiceIpIk == null || coffret.indiceIpIk!.trim().isEmpty;
        if (hasNoIpIk) {
          point.conformite = 'non';
          if (point.observation == null ||
              point.observation!.trim().isEmpty ||
              isAutomatedIpIkObservation(point.observation)) {
            point.observation = eval.observation ?? "Absence de l'indice ip/ik";
          }
          point.observations ??= [];
          if (point.observations!.isEmpty) {
            point.observations!.add(ElementControle(
              elementControle: point.pointVerification,
              conforme: false,
              priorite: 3,
              observation: point.observation,
            ));
          } else {
            point.observations!.first.observation = point.observation;
            point.observations!.first.conforme = false;
          }
          continue;
        }

        // Si le point est déjà enregistré comme NON CONFORME pour une raison MANUELLE (ex: casse physique),
        // on respecte scrupuleusement cet état sans l'écraser arbitrairement par 'oui'.
        // Mais si c'était une observation AUTOMATIQUE liée à l'absence ou la divergence d'indice,
        // et que l'évaluation est désormais 'oui', on autorise la transition vers 'oui'.
        final isAlreadyNonConforme =
            point.conformite.toLowerCase().trim() == 'non';
        if (isAlreadyNonConforme && eval.conformite == 'oui') {
          if (!isAutomatedIpIkObservation(point.observation)) {
            continue;
          }
        }

        // Appliquer le résultat de l'évaluation
        point.conformite = eval.conformite;
        if (eval.conformite == 'oui') {
          if (isAutomatedIpIkObservation(point.observation)) {
            point.observation = null;
            point.observations?.clear();
          }
        } else {
          // Si non conforme, mettre à jour l'observation si vide ou si c'est une observation automatique
          if (point.observation == null ||
              point.observation!.trim().isEmpty ||
              isAutomatedIpIkObservation(point.observation)) {
            point.observation = eval.observation;
          }
          point.observations ??= [];
          if (point.observations!.isEmpty) {
            point.observations!.add(ElementControle(
              elementControle: point.pointVerification,
              conforme: false,
              priorite: 3,
              observation: point.observation ?? eval.observation,
            ));
          } else {
            point.observations!.first.observation =
                point.observation ?? eval.observation;
            point.observations!.first.conforme = false;
          }
        }
      }
    }
  }

  /// Évalue automatiquement le degré IP/IK d'un équipement par rapport à son repère
  static IpIkEvaluationResult evaluate({
    required CoffretArmoire coffret,
    required String missionId,
    String? parentName,
    AuditInstallationsElectriques? audit,
  }) {
    // CAS A — L'équipement n'a pas d'indice IP/IK (vide, nul ou sans IP/IK exploitable)
    final equipParsed = ParsedIpIk.parse(coffret.indiceIpIk);
    if (!equipParsed.hasIpOrIk) {
      return const IpIkEvaluationResult(
        conformite: 'non',
        observation: "Absence de l'indice ip/ik",
      );
    }

    // CAS B & D — Recherche du repère et de son classement
    final repereParsed = resolveRepereIpIk(
      missionId: missionId,
      coffret: coffret,
      parentName: parentName,
      audit: audit,
    );

    if (!repereParsed.hasIpOrIk) {
      return const IpIkEvaluationResult(
        conformite: 'non',
        observation: "Absence d'indice ip/ik du repère",
      );
    }

    final repereFormatted = repereParsed.toString();

    // Comparaison intelligente stricte et déterministe
    final bool isMatching = comparerIndicesIpIk(coffret.indiceIpIk, repereFormatted);

    // CAS C1 — Présent + compatible
    if (isMatching) {
      return IpIkEvaluationResult(
        conformite: 'oui',
        observation: null,
        repereIpIkFormatted: repereFormatted,
      );
    }

    // CAS C2 — Présent + différent
    return IpIkEvaluationResult(
      conformite: 'non',
      observation: "Indice ip/ik différent de l'indice du repère",
      repereIpIkFormatted: repereFormatted,
    );
  }

  /// Normalise un indice IP/IK brut en chaîne standardisée (ex: "IP55 / IK08", "IP55", "IK08" ou "")
  static String normaliserIndiceIpIk(String? raw) {
    final parsed = ParsedIpIk.parse(raw);
    return parsed.toString();
  }

  /// Compare un indice d'équipement avec l'indice attendu de son repère de façon stricte et déterministe
  static bool comparerIndicesIpIk(String? equipRaw, String? repereRaw) {
    final equipParsed = ParsedIpIk.parse(equipRaw);
    final repereParsed = ParsedIpIk.parse(repereRaw);

    if (!repereParsed.hasIpOrIk) return false;
    if (!equipParsed.hasIpOrIk) return false;

    if (repereParsed.ip != null && repereParsed.ik != null) {
      return equipParsed.ip == repereParsed.ip && equipParsed.ik == repereParsed.ik;
    } else if (repereParsed.ip != null) {
      return equipParsed.ip == repereParsed.ip;
    } else if (repereParsed.ik != null) {
      return equipParsed.ik == repereParsed.ik;
    }
    return false;
  }

  /// Résout l'indice IP/IK propre à une Zone (depuis ClassementZone ou fallback ClassementEmplacement)
  static ParsedIpIk resolveZoneIpIk(String missionId, String zoneNom) {
    if (zoneNom.trim().isEmpty) return const ParsedIpIk(ip: null, ik: null);
    try {
      final cz = HiveService.getClassementZoneByNom(missionId, zoneNom);
      if (cz != null) {
        final ip = (cz.ip != null && cz.ip!.trim().isNotEmpty) ? cz.ip!.trim() : null;
        final ik = (cz.ik != null && cz.ik!.trim().isNotEmpty) ? cz.ik!.trim() : null;
        if (ip != null || ik != null) {
          return ParsedIpIk.parse('${ip ?? ''} ${ik ?? ''}');
        }
      }

      final emp = HiveService.getEmplacementByNom(missionId, zoneNom);
      if (emp != null) {
        final ip = (emp.ipEffective != null && emp.ipEffective!.trim().isNotEmpty) ? emp.ipEffective!.trim() : null;
        final ik = (emp.ikEffective != null && emp.ikEffective!.trim().isNotEmpty) ? emp.ikEffective!.trim() : null;
        if (ip != null || ik != null) {
          return ParsedIpIk.parse('${ip ?? ''} ${ik ?? ''}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur resolveZoneIpIk: $e');
    }
    return const ParsedIpIk(ip: null, ik: null);
  }

  /// Résout l'indice IP/IK attendu du repère réel de l'équipement (Local ou Zone)
  static ParsedIpIk resolveRepereIpIk({
    required String missionId,
    CoffretArmoire? coffret,
    String? parentName,
    String? repere,
    AuditInstallationsElectriques? audit,
  }) {
    final candidates = <String>[];
    if (repere != null && repere.trim().isNotEmpty) {
      candidates.add(repere.trim());
    } else if (coffret?.repere != null && coffret!.repere!.trim().isNotEmpty) {
      candidates.add(coffret.repere!.trim());
    }

    if (parentName != null && parentName.trim().isNotEmpty) {
      final p = parentName.trim();
      if (!candidates.contains(p)) {
        candidates.add(p);
      }
    } else if (coffret != null) {
      final discoveredLocation = _findLocationForCoffret(
        coffret,
        missionId,
        audit: audit,
      );
      if (discoveredLocation != null && discoveredLocation.trim().isNotEmpty) {
        final d = discoveredLocation.trim();
        if (!candidates.contains(d)) {
          candidates.add(d);
        }
      }
    }

    if (candidates.isEmpty) {
      return const ParsedIpIk(ip: null, ik: null);
    }

    // Priorité 1 : trouver un candidat ayant un classement IP ou IK renseigné
    // en vérifiant à la fois dans les Locaux (ClassementEmplacement) et les Zones (ClassementZone)
    for (final candidate in candidates) {
      try {
        final found = HiveService.getEmplacementByNom(missionId, candidate);
        if (found != null &&
            ((found.ipEffective != null && found.ipEffective!.trim().isNotEmpty) ||
             (found.ikEffective != null && found.ikEffective!.trim().isNotEmpty))) {
          return ParsedIpIk.parse('${found.ipEffective ?? ''} ${found.ikEffective ?? ''}');
        }

        final foundZone = HiveService.getClassementZoneByNom(missionId, candidate);
        if (foundZone != null &&
            ((foundZone.ip != null && foundZone.ip!.trim().isNotEmpty) ||
             (foundZone.ik != null && foundZone.ik!.trim().isNotEmpty))) {
          return ParsedIpIk.parse('${foundZone.ip ?? ''} ${foundZone.ik ?? ''}');
        }
      } catch (_) {}
    }

    // Priorité 2 : si aucun n'a d'IP/IK effectif, prendre le premier emplacement existant
    for (final candidate in candidates) {
      try {
        final found = HiveService.getEmplacementByNom(missionId, candidate);
        if (found != null) {
          return ParsedIpIk.parse('${found.ipEffective ?? ''} ${found.ikEffective ?? ''}');
        }

        final foundZone = HiveService.getClassementZoneByNom(missionId, candidate);
        if (foundZone != null) {
          return ParsedIpIk.parse('${foundZone.ip ?? ''} ${foundZone.ik ?? ''}');
        }
      } catch (_) {}
    }

    return const ParsedIpIk(ip: null, ik: null);
  }

  /// Retrouve le nom de l'emplacement (Local ou Zone) où est situé le coffret
  static String? _findLocationForCoffret(
    CoffretArmoire coffret,
    String missionId, {
    AuditInstallationsElectriques? audit,
  }) {
    try {
      final auditData = audit ?? HiveService.getRawAuditInstallationsByMissionId(missionId);
      if (auditData == null) return null;

      final eqId = coffret.equipmentId;

      // 1. Chercher dans les locaux MT direct
      for (final local in auditData.moyenneTensionLocaux) {
        if (local.coffrets.any((c) => c.equipmentId == eqId || c.nom == coffret.nom)) {
          return local.nom;
        }
      }

      // 2. Chercher dans les zones MT
      for (final zone in auditData.moyenneTensionZones) {
        if (zone.coffrets.any((c) => c.equipmentId == eqId || c.nom == coffret.nom)) {
          return zone.nom;
        }
        for (final local in zone.locaux) {
          if (local.coffrets.any((c) => c.equipmentId == eqId || c.nom == coffret.nom)) {
            return local.nom;
          }
        }
      }

      // 3. Chercher dans les zones BT
      for (final zone in auditData.basseTensionZones) {
        if (zone.coffretsDirects.any((c) => c.equipmentId == eqId || c.nom == coffret.nom)) {
          return zone.nom;
        }
        for (final local in zone.locaux) {
          if (local.coffrets.any((c) => c.equipmentId == eqId || c.nom == coffret.nom)) {
            return local.nom;
          }
        }
      }

      // Fallback sur le champ repere du coffret s'il existe
      if (coffret.repere != null && coffret.repere!.trim().isNotEmpty) {
        return coffret.repere!.trim();
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur _findLocationForCoffret: $e');
      return null;
    }
  }
}
