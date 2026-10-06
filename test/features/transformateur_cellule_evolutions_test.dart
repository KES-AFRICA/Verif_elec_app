import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/backup_service.dart';

void main() {
  group('TransformateurMTBT & Cellule Évolutions Tests', () {
    test('TransformateurMTBT supporte courantReglageDisjoncteur et copyWith', () {
      final transfo = TransformateurMTBT(
        typeTransformateur: 'SEC',
        marqueAnnee: 'Schneider / 2020',
        puissanceAssignee: '630',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Non',
        typeRefroidissement: 'AN',
        regimeNeutre: 'TN-S',
        calibreDisjoncteur: '1000',
        courantReglageDisjoncteur: '800',
      );

      expect(transfo.courantReglageDisjoncteur, '800');
      expect(transfo.tensionPrimaireSecondaire, '20kV / 400V');

      final updated = transfo.copyWith(
        courantReglageDisjoncteur: '900',
      );

      expect(updated.courantReglageDisjoncteur, '900');
      expect(updated.calibreDisjoncteur, '1000');
      expect(updated.tensionPrimaireSecondaire, '20kV / 400V');
    });

    test('Cellule supporte celluleDepart et copyWith', () {
      final cellule = Cellule(
        fonction: 'Cellule disjoncteur',
        type: 'Disjoncteur MT',
        marqueModeleAnnee: 'ABB / VD4 / 2022',
        tensionAssignee: '24',
        pouvoirCoupure: '25',
        numerotation: '1',
        parafoudres: 'Oui',
        celluleDepart: 'Départ Transfo 1',
      );

      expect(cellule.celluleDepart, 'Départ Transfo 1');

      final updated = cellule.copyWith(
        celluleDepart: 'Départ Ligne Nord',
      );

      expect(updated.celluleDepart, 'Départ Ligne Nord');
      expect(updated.fonction, 'Cellule disjoncteur');
    });

    test('BackupService sérialise et désérialise correctement les nouveaux champs', () {
      final transfo = TransformateurMTBT(
        typeTransformateur: 'HUILE',
        marqueAnnee: 'Legrand / 2021',
        puissanceAssignee: '1000',
        tensionPrimaireSecondaire: '15kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'IT',
        calibreDisjoncteur: '1600',
        courantReglageDisjoncteur: '1400',
      );

      final cellule = Cellule(
        fonction: 'Cellule disjoncteur',
        type: 'Fluokit M24',
        marqueModeleAnnee: 'Schneider / 2023',
        tensionAssignee: '20',
        pouvoirCoupure: '16',
        numerotation: '2',
        parafoudres: 'Non',
        celluleDepart: 'Départ Usine',
      );

      final serializedTransfo = BackupService.testSerializeTransformateur(transfo);
      expect(serializedTransfo['courantReglageDisjoncteur'], '1400');

      final parsedTransfo = BackupService.testParseTransformateur(serializedTransfo);
      expect(parsedTransfo.courantReglageDisjoncteur, '1400');
      expect(parsedTransfo.tensionPrimaireSecondaire, '15kV / 400V');

      final serializedCellule = BackupService.testSerializeCellule(cellule);
      expect(serializedCellule['celluleDepart'], 'Départ Usine');

      final parsedCellule = BackupService.testParseCellule(serializedCellule);
      expect(parsedCellule.celluleDepart, 'Départ Usine');
    });

    test('Rétrocompatibilité : données sans les nouveaux champs parsées sans erreur', () {
      final legacyTransfoMap = {
        'typeTransformateur': 'SEC',
        'marqueAnnee': 'France Transfo / 2018',
        'puissanceAssignee': '400',
        'tensionPrimaireSecondaire': '20kV / 400V',
        'relaisBuchholz': 'Non',
        'typeRefroidissement': 'AN',
        'regimeNeutre': 'TT',
        'elementsVerifies': <Map<String, dynamic>>[],
      };

      final parsedLegacyTransfo = BackupService.testParseTransformateur(legacyTransfoMap);
      expect(parsedLegacyTransfo.courantReglageDisjoncteur, isNull);
      expect(parsedLegacyTransfo.tensionPrimaireSecondaire, '20kV / 400V');

      final legacyCelluleMap = {
        'fonction': 'Cellule arrivée câble',
        'type': 'SM6 IM',
        'marqueModeleAnnee': 'Schneider / 2019',
        'tensionAssignee': '24',
        'pouvoirCoupure': '20',
        'numerotation': '1',
        'parafoudres': 'Non',
        'elementsVerifies': <Map<String, dynamic>>[],
      };

      final parsedLegacyCellule = BackupService.testParseCellule(legacyCelluleMap);
      expect(parsedLegacyCellule.celluleDepart, isNull);
    });
  });
}
