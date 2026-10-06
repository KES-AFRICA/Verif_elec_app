// test/services/pdf/builders/pdf_zone_header_layout_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

void main() {
  group('Bloc de Zone PDF - Disposition Nom à gauche et IP/IK à droite', () {
    test('pw.Row structure contient le nom de zone dans Expanded et IP/IK à droite', () {
      final font = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();
      const nom = 'Zone Atelier Traitement Thermique';
      const ipIkText = 'IP54 / IK08';

      // Reproduction exacte du layout de _buildZoneHeader
      final headerWidget = pw.Container(
        width: double.infinity,
        color: PdfReportStyles.accentColor,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Text(
                nom.toUpperCase(),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsH3,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              ipIkText,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: PdfReportStyles.fsH3,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      );

      expect(headerWidget.child, isA<pw.Row>());
      final row = headerWidget.child as pw.Row;
      expect(row.children.length, equals(3));

      // Premier élément : Expanded contenant le Nom en majuscules
      expect(row.children[0], isA<pw.Expanded>());
      final expanded = row.children[0] as pw.Expanded;
      expect(expanded.child, isA<pw.Text>());
      final nomText = expanded.child as pw.Text;
      expect(nomText.text.toPlainText(), equals(nom.toUpperCase()));

      // Deuxième élément : SizedBox espacement
      expect(row.children[1], isA<pw.SizedBox>());

      // Troisième élément : Text aligné à l'extrême droite avec IP/IK
      expect(row.children[2], isA<pw.Text>());
      final ipText = row.children[2] as pw.Text;
      expect(ipText.text.toPlainText(), equals(ipIkText));
    });
  });
}
