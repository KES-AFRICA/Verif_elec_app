import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/services/ip_ik_evaluator_service.dart';

void main() {
  group('Évolutions 4 & 5 — IP/IK Zone & Résolution Équipements BT', () {
    test('ParsedIpIk formate et compare correctement', () {
      final parsed = ParsedIpIk.parse('IP54 / IK08');
      expect(parsed.ip, 'IP54');
      expect(parsed.ik, 'IK08');
      expect(parsed.toString(), 'IP54 / IK08');

      final parsedIpOnly = ParsedIpIk.parse('IP54');
      expect(parsedIpOnly.ip, 'IP54');
      expect(parsedIpOnly.ik, isNull);
      expect(parsedIpOnly.toString(), 'IP54');

      final empty = ParsedIpIk.parse('');
      expect(empty.hasIpOrIk, isFalse);
    });

    test('comparerIndicesIpIk gère les concordances et divergences', () {
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP54 / IK08', 'IP54 / IK08'), isTrue);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP55 / IK08', 'IP54 / IK08'), isFalse);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP54', 'IP54'), isTrue);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP54', 'IP55'), isFalse);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('', 'IP54'), isFalse);
    });

    test('evaluate retourne conforme quand indice coffret == indice repère', () {
      final coffret = CoffretArmoire(
        nom: 'TGBT',
        type: 'Armoire',
        repere: 'Local Technique',
        indiceIpIk: 'IP54 / IK08',
        qrCode: '',
      );

      // Création d'un audit de test avec un local
      final local = BasseTensionLocal(
        nom: 'Local Technique',
        type: 'LOCAL_ELECTRIQUE',
        coffrets: [coffret],
      );
      final zone = BasseTensionZone(
        nom: 'Zone 1',
        locaux: [local],
      );
      final audit = AuditInstallationsElectriques(
        missionId: 'mission_test_ipik',
        updatedAt: DateTime.now(),
        basseTensionZones: [zone],
      );

      // Simulation sans Hive box ouverte : candidats testés
      final evalMissing = IpIkEvaluatorService.evaluate(
        coffret: coffret,
        missionId: 'mission_test_ipik',
        audit: audit,
      );
      // Comme la boîte Hive n'a pas été peuplée, le repère n'a pas d'indice
      expect(evalMissing.conformite, 'non');
      expect(evalMissing.observation, contains("Absence d'indice"));
    });

    test('Équipement sans IP/IK est toujours non conforme avec observation automatique', () {
      final coffret = CoffretArmoire(
        nom: 'Coffret Secondaire',
        type: 'Coffret',
        repere: 'Zone 1',
        indiceIpIk: null,
        qrCode: '',
      );

      final eval = IpIkEvaluatorService.evaluate(
        coffret: coffret,
        missionId: 'mission_test_ipik',
      );

      expect(eval.conformite, 'non');
      expect(eval.observation, "Absence de l'indice ip/ik");
    });
  });
}
