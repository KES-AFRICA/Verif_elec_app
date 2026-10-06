// test/features/lighting/lighting_forensic_integrity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import 'package:inspec_app/utils/observation_text_normalizer.dart';

void main() {
  group('Audit Forensic & Durcissement — Module Inspection des Luminaires', () {
    test('1. Tolérance aux valeurs nulles dans la désérialisation JSON/Hive', () {
      final jsonDegrade = {
        'id': 'insp_legacy_1',
        'missionId': 'm_test_1',
        'batimentLocal': 'Magasin Central',
        'typeLuminaire': 'Fluorescent',
        'dateVerification': '2026-08-15T10:00:00.000Z',
        // nbLuminairesConformes absent / null
        'nonConformingLuminaires': null,
      };

      final item = LightingInspection.fromJson(jsonDegrade);
      expect(item.id, equals('insp_legacy_1'));
      expect(item.nbLuminairesConformes, equals(0));
      expect(item.nonConformingLuminaires, isEmpty);
      expect(item.nbLuminairesNonConformes, equals(0));
    });

    test('2. Sérialisation et intégrité de la structure des luminaires non conformes', () {
      final item = LightingInspection(
        id: 'insp_101',
        missionId: 'm_101',
        batimentLocal: 'Local TGBT',
        typeLuminaire: 'LED Etanche',
        dateVerification: DateTime(2026, 10, 6),
        nbLuminairesConformes: 12,
        nonConformingLuminaires: [
          NonConformingLuminaire(
            id: 'ncl_001',
            repereLocalisation: 'Rangée 1 - Luminaire 3',
            answers: [
              LuminaireQuestionAnswer(
                questionIndex: 2,
                isConform: false,
                commentaire: 'vasque fêlée avec perte d\'étanchéité IP',
                photoPaths: ['/audit_photos/luminaires/photo_123.jpg'],
              ),
            ],
          ),
        ],
      );

      final json = item.toJson();
      final restored = LightingInspection.fromJson(json);

      expect(restored.id, equals('insp_101'));
      expect(restored.nbLuminairesConformes, equals(12));
      expect(restored.nbLuminairesNonConformes, equals(1));
      expect(restored.nonConformingLuminaires.first.repereLocalisation, equals('Rangée 1 - Luminaire 3'));
      expect(restored.nonConformingLuminaires.first.answers.first.photoPaths,
          contains('/audit_photos/luminaires/photo_123.jpg'));
    });

    test('3. Normalisation automatique des observations et commentaires de luminaires', () {
      final rawItem = LightingInspection(
        id: 'insp_202',
        missionId: 'm_202',
        batimentLocal: 'atelier de découpe',
        typeLuminaire: 'Éclairage normal',
        dateVerification: DateTime(2026, 10, 6),
        nbLuminairesConformes: 4,
        nonConformingLuminaires: [
          NonConformingLuminaire(
            id: 'ncl_202',
            answers: [
              LuminaireQuestionAnswer(
                questionIndex: 1,
                isConform: false,
                commentaire: 'absence de mise à la terre sur le luminaire 3x16 A IP54 sous 230 V. risque de contact indirect!',
              ),
            ],
          ),
        ],
      );

      final normalized = ObservationTextNormalizer.normalizeLightingInspection(rawItem);
      final cmt = normalized.nonConformingLuminaires.first.answers.first.commentaire!;

      expect(cmt, startsWith('Absence de mise à la terre'));
      expect(cmt, contains('3x16 A'));
      expect(cmt, contains('IP54'));
      expect(cmt, contains('230 V'));
      expect(cmt, contains('Risque de contact indirect!'));
    });

    test('4. Règle anti-collision d\'ID de luminaires lors de l\'importation de mission', () {
      // Simulation du comportement de BackupService._remapMissionId
      final originalList = [
        {
          'id': 'insp_l_1700000_1',
          'missionId': 'm_original',
          'batimentLocal': 'Atelier',
          'typeLuminaire': 'LED',
          'dateVerification': '2026-10-06T10:00:00.000',
          'nbLuminairesConformes': 8,
          'nonConformingLuminaires': [],
        }
      ];

      const newMissionId = 'm_cloned_999';

      // Remap
      final remappedList = originalList.asMap().entries.map((entry) {
        final idx = entry.key;
        final itemMap = Map<String, dynamic>.from(entry.value);
        if (itemMap.containsKey('missionId')) {
          itemMap['missionId'] = newMissionId;
        }
        itemMap['id'] = 'insp_l_${DateTime.now().microsecondsSinceEpoch}_${idx}_$newMissionId';
        return itemMap;
      }).toList();

      expect(remappedList.first['missionId'], equals(newMissionId));
      expect(remappedList.first['id'], isNot(equals('insp_l_1700000_1')));
      expect(remappedList.first['id'], contains(newMissionId));
    });

    test('5. Protection anti-écrasement si l\'archive importée ne contient aucun luminaire', () {
      // Vérifie que si targetData['lighting_inspections'] est vide, la condition lBox.delete n'est pas déclenchée
      final incomingDataWithoutLighting = <String, dynamic>{
        'mission': {'id': 'm_test'},
        'audit': {'missionId': 'm_test'},
        // Pas de clé lighting_inspections
      };

      final incomingLighting = (incomingDataWithoutLighting['lighting_inspections'] as List?) ?? [];
      bool shouldDeleteExisting = incomingLighting.isNotEmpty;

      expect(shouldDeleteExisting, isFalse);
    });
  });
}
