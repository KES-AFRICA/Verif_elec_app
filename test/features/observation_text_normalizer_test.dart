import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/utils/observation_text_normalizer.dart';

void main() {
  group('ObservationTextNormalizer - Évolution 11', () {
    test('Capitalise automatiquement le début de phrase en début de texte', () {
      expect(
        ObservationTextNormalizer.normalize('absence de plastron de protection.'),
        equals('Absence de plastron de protection.'),
      );
      expect(
        normalizeObservationText('présence d\'un échauffement.'),
        equals('Présence d\'un échauffement.'),
      );
    });

    test('Capitalise le début de chaque nouvelle phrase (. ! ?)', () {
      expect(
        ObservationTextNormalizer.normalize('premier défaut constaté. second défaut observé! est-ce conforme? non.'),
        equals('Premier défaut constaté. Second défaut observé! Est-ce conforme? Non.'),
      );
    });

    test('Préserve intacts les acronymes et majuscules internes (TGBT, HTA, DDR, IP2X, etc.)', () {
      expect(
        ObservationTextNormalizer.normalize('armoire TGBT non consignée. cellule HTA vérifiée.'),
        equals('Armoire TGBT non consignée. Cellule HTA vérifiée.'),
      );
      expect(
        ObservationTextNormalizer.normalize('protection DDR 30mA déclenchée. degré IP2X non respecté.'),
        equals('Protection DDR 30mA déclenchée. Degré IP2X non respecté.'),
      );
      expect(
        ObservationTextNormalizer.normalize('disjoncteur Q1 ouvert.'),
        equals('Disjoncteur Q1 ouvert.'),
      );
    });

    test('Ignore les séparateurs décimaux (2.5 mm², 0.5 MΩ, etc.)', () {
      expect(
        ObservationTextNormalizer.normalize('câble de section 2.5 mm² détérioré. isolement mesuré à 0.5 MΩ.'),
        equals('Câble de section 2.5 mm² détérioré. Isolement mesuré à 0.5 MΩ.'),
      );
    });

    test('Gère les retours à la ligne et les listes à puces', () {
      final input = '- premier constat\n- deuxième constat\n• troisième constat';
      final expected = '- Premier constat\n- Deuxième constat\n• Troisième constat';
      expect(ObservationTextNormalizer.normalize(input), equals(expected));
    });

    test('Est strictement idempotent', () {
      final input = 'TGBT défaillant. IP55 requis. Câble 4x50 mm² vérifié.';
      final firstPass = ObservationTextNormalizer.normalize(input);
      final secondPass = ObservationTextNormalizer.normalize(firstPass);
      expect(firstPass, equals(input));
      expect(secondPass, equals(input));
    });

    test('Gère les chaînes nulles, vides ou avec seulement des espaces', () {
      expect(ObservationTextNormalizer.normalize(null), isNull);
      expect(ObservationTextNormalizer.normalize(''), equals(''));
      expect(ObservationTextNormalizer.normalize('   '), equals('   '));
    });

    test('Prend en compte les lettres accentuées françaises au début de phrase', () {
      expect(
        ObservationTextNormalizer.normalize('éclairage de secours absent. état général moyen.'),
        equals('Éclairage de secours absent. État général moyen.'),
      );
    });
  });
}
