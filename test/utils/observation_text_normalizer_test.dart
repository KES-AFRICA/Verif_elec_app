// test/utils/observation_text_normalizer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/utils/observation_text_normalizer.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('ObservationTextNormalizer - Règles fondamentales', () {
    test('Chaîne vide ou nulle', () {
      expect(ObservationTextNormalizer.normalize(''), equals(''));
      expect(ObservationTextNormalizer.normalize('   '), equals(''));
      expect(ObservationTextNormalizer.normalize(null), isNull);
    });

    test('Phrase simple sans majuscule ni point', () {
      const input = 'câble non fixé sous le chemin de câbles';
      const expected = 'Câble non fixé sous le chemin de câbles.';
      expect(ObservationTextNormalizer.normalize(input), equals(expected));
    });

    test('Multi-phrases avec minuscules après ponctuation', () {
      const input = 'présence d\'eau dans le regard. nettoyer d\'urgence. risque d\'électrocution!';
      const expected = 'Présence d\'eau dans le regard. Nettoyer d\'urgence. Risque d\'électrocution!';
      expect(ObservationTextNormalizer.normalize(input), equals(expected));
    });

    test('Préservation absolue des termes électrotechniques normalisés', () {
      const input = 'protection par disjoncteur différentiel IΔn 30 mA 3x16 A courbe C pdc 6 kA sous 230 V / 400 V. prise IP54 et coffret IK08 non relié au PE avec seuil 100 Ω selon NF C 15-100 et APSAD D18.';
      final result = ObservationTextNormalizer.normalize(input);
      expect(result, contains('IΔn'));
      expect(result, contains('30 mA'));
      expect(result, contains('3x16 A'));
      expect(result, contains('6 kA'));
      expect(result, contains('230 V'));
      expect(result, contains('400 V'));
      expect(result, contains('IP54'));
      expect(result, contains('IK08'));
      expect(result, contains('PE'));
      expect(result, contains('100 Ω'));
      expect(result, contains('NF C 15-100'));
      expect(result, contains('APSAD D18'));
    });

    test('Nombres décimaux préservés sans fausse rupture de phrase', () {
      const input = 'section mesurée de 2.5 mm² avec une chute de tension de 1.8 V.';
      final result = ObservationTextNormalizer.normalize(input);
      expect(result, equals('Section mesurée de 2.5 mm² avec une chute de tension de 1.8 V.'));
    });

    test('Abréviations techniques ne créent pas de fausse majuscule', () {
      const input = 'conforme selon art. 421.1 et ref. 842-B du dossier technique.';
      final result = ObservationTextNormalizer.normalize(input);
      expect(result, equals('Conforme selon art. 421.1 et ref. 842-B du dossier technique.'));
    });

    test('Listes à puces et retours à la ligne respectés', () {
      const input = 'constats relevés sur le TGBT :\n- présence de poussière conductrice\n- presse-étoupe manquant';
      final result = ObservationTextNormalizer.normalize(input);
      expect(result, contains('Constats relevés sur le TGBT :'));
      expect(result, contains('- Présence de poussière conductrice'));
      expect(result, contains('- Presse-étoupe manquant'));
    });

    test('Points de suspension ne tronquent pas la chaîne', () {
      const input = 'état d\'usure avancé... remplacement à prévoir';
      final result = ObservationTextNormalizer.normalize(input);
      expect(result, equals('État d\'usure avancé... Remplacement à prévoir.'));
    });

    test('Idempotence absolue : normalize(normalize(x)) == normalize(x)', () {
      const input = 'défaut d\'isolement constaté sous 500 V sur le départ 3x16 A.';
      final firstPass = ObservationTextNormalizer.normalize(input);
      final secondPass = ObservationTextNormalizer.normalize(firstPass);
      expect(secondPass, equals(firstPass));
    });
  });

  group('ObservationTextNormalizer - Modèles métier et LightingInspection', () {
    test('Normalisation d\'une LightingInspection', () {
      final inspection = LightingInspection(
        id: 'test_insp',
        missionId: 'm_123',
        batimentLocal: 'Atelier de production',
        typeLuminaire: 'Éclairage normal',
        dateVerification: DateTime(2026, 10, 6),
        nbLuminairesConformes: 5,
        nonConformingLuminaires: [
          NonConformingLuminaire(
            id: 'ncl_1',
            answers: [
              LuminaireQuestionAnswer(
                questionIndex: 1,
                commentaire: 'diffuseur cassé et poussière conductrice',
              ),
            ],
          ),
        ],
      );

      final normalized = ObservationTextNormalizer.normalizeLightingInspection(inspection);
      expect(normalized.nonConformingLuminaires.first.answers.first.commentaire,
          equals('Diffuseur cassé et poussière conductrice.'));
    });

    test('Normalisation d\'un PointVerification', () {
      final pv = PointVerification(
        pointVerification: 'Continuité des masses',
        conformite: 'Non conforme',
        observation: 'liaison équipotentielle sectionnée au niveau du châssis',
      );
      ObservationTextNormalizer.normalizePointVerification(pv);
      expect(pv.observation,
          equals('Liaison équipotentielle sectionnée au niveau du châssis.'));
    });
  });
}
