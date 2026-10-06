import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/pdf/installation_description_pdf_data.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

void main() {
  group('Tension primaire / secondaire sync & PDF integration tests', () {
    test('1. PdfReportStyles.columnOrderBySection BT contains TENSION PRIMAIRE/SECONDAIRE', () {
      final cols = PdfReportStyles.columnOrderBySection['BT']!;
      expect(cols.contains('TENSION PRIMAIRE/SECONDAIRE'), isTrue);
      expect(cols.contains('TENSION MT/BT (KV/V)'), isFalse);
    });

    test('2. InstallationDescriptionPdfRow resolves TENSION PRIMAIRE/SECONDAIRE and aliases via fromDescription', () {
      final transfo = TransformateurMTBT(
        typeTransformateur: 'SEC',
        marqueAnnee: 'Schneider 2021',
        puissanceAssignee: '250',
        tensionPrimaireSecondaire: '15/400',
        relaisBuchholz: 'Sans',
        typeRefroidissement: 'Air',
        regimeNeutre: 'IT',
        syncId: 'transfo_test_1',
      );

      final local = MoyenneTensionLocal(
        nom: 'LOCAL ARRIVÉE ENEO',
        type: 'LOCAL_TRANSFORMATEUR',
        transformateurs: [transfo],
      );

      final zone = MoyenneTensionZone(
        nom: 'SS2',
        locaux: [local],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'mission_pdf_tension_test',
        moyenneTensionZones: [zone],
        updatedAt: DateTime.now(),
      );

      final pdfData = InstallationDescriptionPdfData.fromDescription(
        desc: null,
        audit: audit,
      );

      expect(pdfData.btRows.length, equals(1));
      final row = pdfData.btRows.first;

      expect(row.getValueForColumn('TENSION PRIMAIRE/SECONDAIRE', 'BT'), equals('15/400'));
      expect(row.getValueForColumn('Tension primaire / secondaire', 'BT'), equals('15/400'));
      expect(row.getValueForColumn('Tension', 'BT'), equals('15/400'));
      expect(row.getValueForColumn('TENSION MT/BT', 'BT'), equals('15/400'));
      expect(row.getValueForColumn('TENSION MT/BT (KV/V)', 'BT'), equals('15/400'));
    });
  });
}
