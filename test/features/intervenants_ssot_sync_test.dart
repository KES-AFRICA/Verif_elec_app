import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/intervenants_service.dart';

void main() {
  group('Évolution 8 — Intervenants & Vérificateurs Mission SSOT', () {
    test('deduplicateVerificateursList élimine les doublons par matricule et nom/prénom', () {
      final listWithDuplicates = [
        {
          'nom': 'Dupont',
          'prenom': 'Jean',
          'matricule': 'MAT001',
          'role': 'Inspecteur',
        },
        {
          'nom': 'dupont',
          'prenom': 'jean',
          'matricule': '', // Même personne sans matricule
          'role': 'Inspecteur',
        },
        {
          'nom': 'Dupont',
          'prenom': 'Jean-Pierre',
          'matricule': 'MAT001', // Même matricule
          'role': 'Vérificateur',
        },
        {
          'nom': 'Martin',
          'prenom': 'Sophie',
          'matricule': 'MAT002',
          'role': 'Responsable',
        },
      ];

      final deduplicated = IntervenantsService.deduplicateVerificateursList(listWithDuplicates);

      // On doit avoir exactement 2 personnes : Jean Dupont (MAT001) et Sophie Martin (MAT002)
      expect(deduplicated.length, 2);
      expect(deduplicated[0]['matricule'], 'MAT001');
      expect(deduplicated[1]['nom'], 'Martin');
    });

    test('getMissionIntervenants priorise Mission.verificateurs en tant que SSOT', () {
      final mission = Mission(
        id: 'mission_ssot_test',
        nomClient: 'Client Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'en_cours',
        verificateurs: [
          {
            'nom': 'Kamer',
            'prenom': 'Engineer',
            'matricule': 'KES001',
            'role': 'Chef de mission',
          },
        ],
      );

      final intervenants = IntervenantsService.getMissionIntervenants(
        'mission_ssot_test',
        mission: mission,
      );

      expect(intervenants.length, 1);
      expect(intervenants.first.nom, 'Kamer');
      expect(intervenants.first.prenom, 'Engineer');
      expect(intervenants.first.matricule, 'KES001');

      final nomsFormates = IntervenantsService.getMissionIntervenantsNoms(
        'mission_ssot_test',
        mission: mission,
        uppercase: true,
      );
      expect(nomsFormates, ['ENGINEER KAMER']);
    });
  });
}
