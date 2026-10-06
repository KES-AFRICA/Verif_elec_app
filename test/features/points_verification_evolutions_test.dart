import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';
import 'package:inspec_app/services/normative_reference_service.dart';
import 'package:inspec_app/services/equipment_type_transition_service.dart';

void main() {
  group('Points de vérification Coffret - Évolutions 9 & 10', () {
    test('allCoffretPoints exclut la section des départs et inclut le nouveau parafoudre amont', () {
      final points = DispositionsConstructivesRegistry.allCoffretPoints;

      // Évolution 10: Masquage de la section des câbles de départs
      expect(
        points.contains("Section des câbles de départs adaptée au courant nominal des dispositifs de protection associés"),
        isFalse,
      );

      // Évolution 9: Nouveau libellé parafoudre
      expect(
        points.contains("Coordination du parafoudre avec les protections amont"),
        isTrue,
      );
      expect(
        points.contains("Coordination du parafoudre avec les protections amont et aval"),
        isFalse,
      );
    });

    test('getCoffretMetadata résout le nouveau libellé et préserve la rétrocompatibilité historique', () {
      // Nouveau libellé
      final metaNouveau = DispositionsConstructivesRegistry.getCoffretMetadata(
        "Coordination du parafoudre avec les protections amont",
      );
      expect(metaNouveau, isNotNull);
      expect(metaNouveau?.referenceNormative, contains("art 443 et art 534"));

      // Ancien libellé parafoudre (rétrocompatibilité)
      final metaAncien = DispositionsConstructivesRegistry.getCoffretMetadata(
        "Coordination du parafoudre avec les protections amont et aval",
      );
      expect(metaAncien, isNotNull);
      expect(metaAncien?.referenceNormative, contains("art 443 et art 534"));

      // Ancien point départs (rétrocompatibilité pour les coffrets historiques)
      final metaDeparts = DispositionsConstructivesRegistry.getCoffretMetadata(
        "Section des câbles de départs adaptée au courant nominal des dispositifs de protection associés",
      );
      expect(metaDeparts, isNotNull);
    });

    test('NormativeReferenceService et EquipmentTypeTransitionService reconnaissent le nouveau libellé', () {
      final ref = NormativeReferenceService.getReferenceForPoint(
        "Coordination du parafoudre avec les protections amont",
      );
      expect(ref, isNotNull);
      expect(ref, contains("art 443 et art 534"));

      expect(
        EquipmentTypeTransitionService.isCoffretExclusivePoint(
          "Coordination du parafoudre avec les protections amont",
        ),
        isTrue,
      );
      expect(
        EquipmentTypeTransitionService.isCoffretExclusivePoint(
          "Coordination du parafoudre avec les protections amont et aval",
        ),
        isTrue,
      );
    });
  });
}
