import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  group('Persistance et cohérence du champ "Nombre de câble" (Audit Installations)', () {
    test('Cellule: effectiveConducteursPhase et effectiveNombreCables', () {
      Cellule makeCellule({
        String? sectionCablePhase,
        int? conducteursPhase,
      }) {
        return Cellule(
          fonction: 'Arrivée',
          type: 'Interrupteur',
          marqueModeleAnnee: 'Schneider SM6 2020',
          tensionAssignee: '24kV',
          pouvoirCoupure: '16kA',
          numerotation: '1',
          parafoudres: 'Oui',
          sectionCablePhase: sectionCablePhase,
          conducteursPhase: conducteursPhase,
        );
      }

      // Cas 1: conducteursPhase explicite
      final cell1 = makeCellule(
        sectionCablePhase: '150 mm²',
        conducteursPhase: 3,
      );
      expect(cell1.conducteursPhase, 3);
      expect(cell1.effectiveConducteursPhase, 3);
      expect(cell1.effectiveNombreCables, '3');

      // Cas 2: conducteursPhase non renseigné mais section présente -> fallback 1
      final cell2 = makeCellule(
        sectionCablePhase: '95 mm²',
        conducteursPhase: null,
      );
      expect(cell2.conducteursPhase, isNull);
      expect(cell2.effectiveConducteursPhase, 1);
      expect(cell2.effectiveNombreCables, isNull);

      // Cas 3: Ni section ni conducteurs -> null
      final cell3 = makeCellule(
        sectionCablePhase: null,
        conducteursPhase: null,
      );
      expect(cell3.effectiveConducteursPhase, isNull);
      expect(cell3.effectiveNombreCables, isNull);

      // Cas 4: conducteurs renseignés sans section (inspecteur note "2 câbles" sans section)
      final cell4 = makeCellule(
        sectionCablePhase: null,
        conducteursPhase: 2,
      );
      expect(cell4.conducteursPhase, 2);
      expect(cell4.effectiveConducteursPhase, 2);
      expect(cell4.effectiveNombreCables, '2');
    });

    test('TransformateurMTBT: effectiveConducteursPhase, Neutre et effectiveNombreCables', () {
      TransformateurMTBT makeTransfo({
        String? sectionCablePhase,
        String? sectionCableNeutre,
        int? conducteursPhase,
        int? conducteursNeutre,
      }) {
        return TransformateurMTBT(
          typeTransformateur: 'Huile',
          marqueAnnee: 'France Transfo 2018',
          puissanceAssignee: '630 kVA',
          tensionPrimaireSecondaire: '20kV / 400V',
          relaisBuchholz: 'Présent',
          typeRefroidissement: 'ONAN',
          regimeNeutre: 'TNS',
          sectionCablePhase: sectionCablePhase,
          sectionCableNeutre: sectionCableNeutre,
          conducteursPhase: conducteursPhase,
          conducteursNeutre: conducteursNeutre,
        );
      }

      // Cas 1: conducteursPhase et conducteursNeutre explicites
      final transfo1 = makeTransfo(
        sectionCablePhase: '240 mm²',
        sectionCableNeutre: '150 mm²',
        conducteursPhase: 2,
        conducteursNeutre: 2,
      );
      expect(transfo1.conducteursPhase, 2);
      expect(transfo1.conducteursNeutre, 2);
      expect(transfo1.effectiveConducteursPhase, 2);
      expect(transfo1.effectiveConducteursNeutre, 2);
      expect(transfo1.effectiveNombreCables, '2');

      // Cas 2: sections renseignées sans conducteurs explicites -> fallback 1
      final transfo2 = makeTransfo(
        sectionCablePhase: '185 mm²',
        sectionCableNeutre: '95 mm²',
      );
      expect(transfo2.conducteursPhase, isNull);
      expect(transfo2.conducteursNeutre, isNull);
      expect(transfo2.effectiveConducteursPhase, 1);
      expect(transfo2.effectiveConducteursNeutre, 1);
      expect(transfo2.effectiveNombreCables, isNull);

      // Cas 3: conducteurs saisis sans section obligatoire
      final transfo3 = makeTransfo(
        conducteursPhase: 4,
        conducteursNeutre: 2,
      );
      expect(transfo3.conducteursPhase, 4);
      expect(transfo3.conducteursNeutre, 2);
      expect(transfo3.effectiveConducteursPhase, 4);
      expect(transfo3.effectiveConducteursNeutre, 2);
      expect(transfo3.effectiveNombreCables, '4');
    });

    test('Alimentation: synchronisation et fallback bidirectionnel nombreCables / conducteursPhase', () {
      // Cas 1: nombreCables texte '3' avec conducteursPhase null
      final alim1 = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '25',
        calibre: '400',
        sectionCable: '185 mm²',
        nombreCables: '3',
      );
      expect(alim1.effectiveConducteursPhase, 3);
      expect(alim1.effectiveNombreCables, '3');

      // Cas 2: conducteursPhase numérique 4 avec nombreCables null
      final alim2 = Alimentation(
        typeProtection: 'Interrupteur',
        pdcKA: '10',
        calibre: '250',
        sectionCable: '120 mm²',
        conducteursPhase: 4,
      );
      expect(alim2.effectiveConducteursPhase, 4);
      expect(alim2.effectiveNombreCables, '4');

      // Cas 3: conducteursPhase prioritaire sur nombreCables si les deux sont fournis
      final alim3 = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '50',
        calibre: '630',
        sectionCable: '240 mm²',
        conducteursPhase: 2,
        nombreCables: '2',
      );
      expect(alim3.effectiveConducteursPhase, 2);
      expect(alim3.effectiveNombreCables, '2');

      // Cas 4: Ni l'un ni l'autre mais section renseignée -> fallback 1
      final alim4 = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '16',
        calibre: '160',
        sectionCable: '50 mm²',
      );
      expect(alim4.effectiveConducteursPhase, 1);
      expect(alim4.effectiveNombreCables, isNull);
    });

    test('DepartEquipement: effectiveConducteursPhase et effectiveNombreCables', () {
      // Cas 1: nombreCables renseigné '2'
      final dep1 = DepartEquipement(
        id: 'dep_1',
        identification: 'Départ Climatisation',
        calibre: '63',
        sectionCable: '16 mm²',
        nombreCables: '2',
      );
      expect(dep1.effectiveConducteursPhase, 2);
      expect(dep1.effectiveNombreCables, '2');

      // Cas 2: conducteursPhase numérique 3
      final dep2 = DepartEquipement(
        id: 'dep_2',
        identification: 'Départ Éclairage Extérieur',
        calibre: '32',
        sectionCable: '10 mm²',
        conducteursPhase: 3,
      );
      expect(dep2.effectiveConducteursPhase, 3);
      expect(dep2.effectiveNombreCables, '3');

      // Cas 3: Pas de nombre renseigné mais section -> 1
      final dep3 = DepartEquipement(
        id: 'dep_3',
        identification: 'Départ Prises',
        calibre: '20',
        sectionCable: '2.5 mm²',
      );
      expect(dep3.effectiveConducteursPhase, 1);
      expect(dep3.effectiveNombreCables, isNull);
    });

    test('CircuitTerminalEquipement: effectiveConducteursPhase et effectiveNombreCables', () {
      final ct1 = CircuitTerminalEquipement(
        id: 'ct_1',
        identification: 'Circuit Onduleur',
        calibre: '16',
        sectionCable: '4 mm²',
        nombreCables: '2',
      );
      expect(ct1.effectiveConducteursPhase, 2);
      expect(ct1.effectiveNombreCables, '2');

      final ct2 = CircuitTerminalEquipement(
        id: 'ct_2',
        identification: 'Circuit PC Bureaux',
        calibre: '16',
        sectionCable: '2.5 mm²',
        conducteursPhase: 1,
      );
      expect(ct2.effectiveConducteursPhase, 1);
      expect(ct2.effectiveNombreCables, '1');
    });

    test('HiveService.deduplicateCoffrets: fusion protectrice sans perte de nombreCables', () {
      // Coffret donneur avec nombreCables dans départs, circuits terminaux et protection de tête
      final donor = CoffretArmoire(
        qrCode: 'QR_TEST_100',
        nom: 'TGBT PRINCIPAL',
        type: 'TGBT',
        statut: 'incomplet',
        protectionTete: Alimentation(
          id: 'prot_1',
          typeProtection: 'Disjoncteur',
          pdcKA: '50',
          calibre: '630',
          sectionCable: '240 mm²',
          nombreCables: '2',
          conducteursPhase: 2,
        ),
        alimentations: [
          Alimentation(
            id: 'alim_1',
            typeProtection: 'Interrupteur',
            pdcKA: '50',
            calibre: '630',
            sectionCable: '240 mm²',
            nombreCables: '2',
            conducteursPhase: 2,
          ),
        ],
        departures: [
          DepartEquipement(
            id: 'dep_test_1',
            identification: 'Départ Atelier',
            calibre: '125',
            sectionCable: '35 mm²',
            nombreCables: '3',
            conducteursPhase: 3,
          ),
        ],
        terminalCircuits: [
          CircuitTerminalEquipement(
            id: 'ct_test_1',
            identification: 'Circuit Pompes',
            calibre: '32',
            sectionCable: '6 mm²',
            nombreCables: '2',
            conducteursPhase: 2,
          ),
        ],
      );

      // Coffret existant avec plus de points de vérification (donc élu base), mais départ/circuit sans nombreCables
      final base = CoffretArmoire(
        qrCode: 'QR_TEST_100',
        nom: 'TGBT PRINCIPAL',
        type: 'TGBT',
        statut: 'complet',
        pointsVerification: [
          PointVerification(pointVerification: 'Point 1', conformite: 'oui'),
          PointVerification(pointVerification: 'Point 2', conformite: 'oui'),
          PointVerification(pointVerification: 'Point 3', conformite: 'oui'),
        ],
        protectionTete: Alimentation(
          id: 'prot_1',
          typeProtection: 'Disjoncteur',
          pdcKA: '50',
          calibre: '630',
          sectionCable: '240 mm²',
          nombreCables: null, // Manquant dans la base
        ),
        alimentations: [
          Alimentation(
            id: 'alim_1',
            typeProtection: 'Interrupteur',
            pdcKA: '50',
            calibre: '630',
            sectionCable: '240 mm²',
            nombreCables: null, // Manquant dans la base
          ),
        ],
        departures: [
          DepartEquipement(
            id: 'dep_test_1',
            identification: 'Départ Atelier',
            calibre: '125',
            sectionCable: '35 mm²',
            nombreCables: null, // Manquant dans la base
          ),
        ],
        terminalCircuits: [
          CircuitTerminalEquipement(
            id: 'ct_test_1',
            identification: 'Circuit Pompes',
            calibre: '32',
            sectionCable: '6 mm²',
            nombreCables: null, // Manquant dans la base
          ),
        ],
      );

      // Exécution de la déduplication
      final result = HiveService.deduplicateCoffrets([base, donor]);

      expect(result.length, 1);
      final merged = result.first;

      // Vérifier que le départ fusionné a récupéré le nombreCables et conducteursPhase du donneur
      expect(merged.departures?.first.nombreCables, '3');
      expect(merged.departures?.first.effectiveConducteursPhase, 3);

      // Vérifier que le circuit terminal fusionné a récupéré le nombreCables et conducteursPhase du donneur
      expect(merged.terminalCircuits?.first.nombreCables, '2');
      expect(merged.terminalCircuits?.first.effectiveConducteursPhase, 2);

      // Vérifier que la protection de tête et l'alimentation ont également fusionné nombreCables
      expect(merged.protectionTete?.nombreCables, '2');
      expect(merged.protectionTete?.effectiveConducteursPhase, 2);

      expect(merged.alimentations.first.nombreCables, '2');
      expect(merged.alimentations.first.effectiveConducteursPhase, 2);
    });
  });
}
