import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  group('Forensic Incident N° 3 — Isolation des équipements et photos entre zones', () {
    test('Deux coffrets homonymes ("INVERSEUR") créés sans ID explicite ne doivent PAS collisionner ni fusionner leurs photos', () {
      final invZoneA = CoffretArmoire(
        nom: 'INVERSEUR',
        type: 'INVERSEUR',
        qrCode: 'TEMP_1720000001',
        photos: ['zoneA_photo1.jpg', 'zoneA_photo2.jpg'],
        photosExternes: ['zoneA_photo1.jpg'],
        photosInternes: ['zoneA_photo2.jpg'],
      );

      final invZoneB = CoffretArmoire(
        nom: 'INVERSEUR',
        type: 'INVERSEUR',
        qrCode: 'TEMP_1720000002',
        photos: ['centre_medical_photo1.jpg'],
        photosExternes: ['centre_medical_photo1.jpg'],
        photosInternes: [],
      );

      // Si les IDs collisionnent, deduplicateCoffrets les fusionnera
      expect(invZoneA.equipmentId, isNot(equals(invZoneB.equipmentId)),
          reason: 'Deux coffrets distincts de même nom doivent avoir des identifiants distincts.');

      final deduplicated = HiveService.deduplicateCoffrets([invZoneA, invZoneB]);
      expect(deduplicated.length, equals(2),
          reason: 'Les deux coffrets doivent rester strictement séparés.');
      
      final first = deduplicated.firstWhere((c) => c.qrCode == 'TEMP_1720000001');
      final second = deduplicated.firstWhere((c) => c.qrCode == 'TEMP_1720000002');

      expect(first.photos, containsAll(['zoneA_photo1.jpg', 'zoneA_photo2.jpg']));
      expect(first.photos, isNot(contains('centre_medical_photo1.jpg')),
          reason: 'Le coffret de la zone A ne doit pas recevoir les photos du centre médical.');
      expect(second.photos, contains('centre_medical_photo1.jpg'));
      expect(second.photos, isNot(contains('zoneA_photo1.jpg')),
          reason: 'Le coffret du centre médical ne doit pas recevoir les photos de la zone A.');
    });

    test('deduplicateCoffrets ne fusionne PAS deux coffrets avec des QR codes réels distincts', () {
      final coffret1 = CoffretArmoire(
        id: 'equip_fixed_123',
        nom: 'COFFRET PRISES',
        type: 'COFFRET',
        qrCode: 'QR_ZONE_A_01',
        photos: ['photo_zone_a.jpg'],
      );

      final coffret2 = CoffretArmoire(
        id: 'equip_fixed_123', // même equipmentId technique hérité
        nom: 'COFFRET PRISES',
        type: 'COFFRET',
        qrCode: 'QR_ZONE_B_02', // mais QR code physique distinct !
        photos: ['photo_zone_b.jpg'],
      );

      final res = HiveService.deduplicateCoffrets([coffret1, coffret2]);
      expect(res.length, equals(2),
          reason: 'Deux équipements avec des QR codes physiques distincts ne doivent jamais être fusionnés.');
      expect(res[0].photos, equals(['photo_zone_a.jpg']));
      expect(res[1].photos, equals(['photo_zone_b.jpg']));
    });

    test('deduplicateCoffrets ne fusionne PAS deux coffrets avec des IDs explicites distincts', () {
      final coffret1 = CoffretArmoire(
        id: 'equip_unique_uuid_1',
        nom: 'INVERSEUR',
        type: 'INVERSEUR',
        qrCode: '',
        photos: ['photo_1.jpg'],
      );

      final coffret2 = CoffretArmoire(
        id: 'equip_unique_uuid_2',
        nom: 'INVERSEUR',
        type: 'INVERSEUR',
        qrCode: '',
        photos: ['photo_2.jpg'],
      );

      final res = HiveService.deduplicateCoffrets([coffret1, coffret2]);
      expect(res.length, equals(2),
          reason: 'Deux équipements avec des IDs explicites distincts ne doivent jamais être fusionnés.');
    });
  });

  group('Forensic Incident N° 1 — Cycle de vie des observations sur PointVerification', () {
    test('Suppression d\'observation : point.observations vidé et point.observation null', () {
      final point = PointVerification(
        pointVerification: 'Continuité des masses et liaisons équipotentielles',
        conformite: 'non',
        observation: 'Liaison interrompue sur chassis',
        observations: [
          ElementControle(
            elementControle: 'Continuité des masses et liaisons équipotentielles',
            conforme: false,
            observation: 'Liaison interrompue sur chassis',
          ),
        ],
      );

      // Simuler la suppression de l'observation
      point.observations?.clear();
      if (point.observations == null || point.observations!.isEmpty) {
        point.observation = null;
        point.priorite = null;
        point.photos = [];
      }

      expect(point.observation, isNull);
      expect(point.observations, isEmpty);

      // Vérifier qu'une re-synchro ne réinvente pas l'ancienne valeur
      if (point.observations != null && point.observations!.isNotEmpty) {
        point.observation = point.observations!.first.observation;
      } else {
        point.observation = null;
      }
      expect(point.observation, isNull);
    });

    test('Modification de texte d\'observation : répercussion bidirectionnelle', () {
      final point = PointVerification(
        pointVerification: 'Repérage des circuits et départs',
        conformite: 'non',
        observation: 'Ancien texte',
        observations: [
          ElementControle(
            elementControle: 'Repérage des circuits et départs',
            conforme: false,
            observation: 'Ancien texte',
          ),
        ],
      );

      // Modification du texte dans le premier ElementControle
      point.observations!.first.observation = 'Nouveau texte corrigé';
      // Synchronisation
      point.observation = point.observations!.first.observation;

      expect(point.observation, equals('Nouveau texte corrigé'));
      expect(point.observations!.first.observation, equals('Nouveau texte corrigé'));
    });
  });

  group('Forensic Incident N° 2 — Persistance exhaustive des champs clés BT', () {
    test('CoffretArmoire préserve les sources et protections de tête lors de copyWith et constructeur', () {
      final coffret = CoffretArmoire(
        id: 'equip_bt_test_1',
        nom: 'TGBT PRINCIPAL',
        type: 'TGBT',
        qrCode: 'QR_TGBT_1',
        sourceEquipementId: 'transfo_1',
        sourceNomComplet: 'TRANSFO 630kVA',
        sourceDepartId: 'depart_general',
        departPrisAvecProtection: true,
        protectionTete: Alimentation(
          typeProtection: 'Disjoncteur',
          calibre: '1600',
          courbe: 'C',
          ddr: '300mA',
          pdcKA: '50',
          sectionCable: '3x240',
        ),
        alimentations: [
          Alimentation(
            typeProtection: 'Disjoncteur',
            calibre: '1600',
            courbe: 'C',
            ddr: '300mA',
            pdcKA: '50',
            sectionCable: '3x240',
          ),
        ],
        indiceIpIk: 'IP54 IK08',
        indiceIpIkRepere: 'IP54 IK08',
        departures: [
          DepartEquipement(
            id: 'dep_1',
            identification: 'Départ Climatisation',
            typeProtection: 'Disjoncteur',
            calibre: '63',
            courbe: 'D',
            ddr: '30mA',
          ),
        ],
        terminalCircuits: [
          CircuitTerminalEquipement(
            id: 'circ_1',
            identification: 'Éclairage TGBT',
            typeProtection: 'Disjoncteur',
            calibre: '16',
            courbe: 'C',
          ),
        ],
      );

      expect(coffret.sourceEquipementId, equals('transfo_1'));
      expect(coffret.sourceNomComplet, equals('TRANSFO 630kVA'));
      expect(coffret.sourceDepartId, equals('depart_general'));
      expect(coffret.isDepartPrisAvecProtection, isTrue);
      expect(coffret.protectionTete?.calibre, equals('1600'));
      expect(coffret.effectiveDepartures.length, equals(1));
      expect(coffret.effectiveTerminalCircuits.length, equals(1));
      expect(coffret.indiceIpIk, equals('IP54 IK08'));

      // Test copyWith
      final updated = coffret.copyWith(
        sourceNomComplet: 'TRANSFO 800kVA (Modifié)',
      );
      expect(updated.sourceEquipementId, equals('transfo_1'));
      expect(updated.sourceNomComplet, equals('TRANSFO 800kVA (Modifié)'));
      expect(updated.sourceDepartId, equals('depart_general'));
      expect(updated.effectiveDepartures.length, equals(1));
    });
  });
}
