import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_footer_builder.dart';

/// Définit la charte graphique, les thèmes de page et les primitives de mise en page
/// pour l'ensemble des rapports PDF d'inspection (KES Inspections and Projects).
class PdfReportStyles {
  // ──────────────────────────────────────────────────────────────
  //  CONSTANTES DE MISE EN PAGE (1.5 cm partout)
  // ──────────────────────────────────────────────────────────────
  static const double kLeftMargin = 1.5 * 28.35; // 1.5 cm
  static const double kTopMargin = 1.5 * 28.35; // 1.5 cm
  static const double kRightMargin = 1.5 * 28.35; // 1.5 cm
  static const double kBottomMargin = 1.5 * 28.35; // 1.5 cm

  // ──────────────────────────────────────────────────────────────
  //  PALETTE DE COULEURS OFFICIELLES
  // ──────────────────────────────────────────────────────────────
  static final PdfColor headerColor = PdfColor.fromInt(0xFF1F3864);
  static final PdfColor accentColor = PdfColor.fromInt(0xFF2E74B5);
  static final PdfColor lightBlue = PdfColor.fromInt(0xFFD6E4F0);
  static final PdfColor darkGrey = PdfColor.fromInt(0xFF404040);
  static final PdfColor tableRowAlt = PdfColor.fromInt(0xFFF5F8FC);
  static final PdfColor borderColor = PdfColor.fromInt(0xFFAAAAAA);
  static final PdfColor priorite1Color = PdfColor.fromInt(0xFFFFF2CC);
  static final PdfColor priorite2Color = PdfColor.fromInt(0xFFFFE0B2);
  static final PdfColor priorite3Color = PdfColor.fromInt(0xFFFFCDD2);
  static final PdfColor conformeColor = PdfColor.fromInt(0xFFE8F5E9);
  static final PdfColor nonConformeColor = PdfColor.fromInt(0xFFFFEBEE);
  static final PdfColor sansObjetColor = PdfColor.fromInt(0xFFEEEEEE);

  // ──────────────────────────────────────────────────────────────
  //  POLICES DE CARACTÈRES
  // ──────────────────────────────────────────────────────────────
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  // ──────────────────────────────────────────────────────────────
  //  TAILLES DE POLICE
  // ──────────────────────────────────────────────────────────────
  static const double fsH1 = 12.0;
  static const double fsH2 = 10.5;
  static const double fsH3 = 10.0;
  static const double fsBody = 9.0;
  static const double fsSmall = 7.5;

  // ──────────────────────────────────────────────────────────────
  //  NORMALISATION DE TEXTE & DATES
  // ──────────────────────────────────────────────────────────────

  /// Conserve tous les accents français et les caractères Unicode supportés par Roboto
  static String normalizeText(String text) {
    if (text.isEmpty) return text;
    // Harmonisation des renvois d'articles
    text = text.replaceAll(RegExp(r'§\s*'), 'art ');
    // Remplacement des espaces insécables par des espaces réguliers
    text = text.replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');

    const replacements = <String, String>{
      '«': '"', '»': '"', '“': '"', '”': '"',
      '•': '-',
      // Note: '’', '‘', '–', '—', 'Ω', 'Δ', '≤', '≥', '±', '°', 'µ', '²', '³', 'ₙ'
      // sont nativement supportés par Roboto (cmap format 12 vérifié).
      // On évite toute dégradation ou substitution inattendue.
      '≠': '!=',
      '∞': 'inf', '√': 'racine',
      '→': '->', '←': '<-', '↔': '<->',
      '∑': 'Somme', 'Φ': 'Phi',
      'θ': 'theta',
      'Σ': 'Sigma',
      '₁': '1', '₂': '2', '₃': '3', '₄': '4',
      '€': 'EUR', '£': 'GBP', '¥': 'JPY',
    };

    var result = text;
    replacements.forEach((k, v) => result = result.replaceAll(k, v));
    return result;
  }

  static String formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  static String formatDateRangeFrench(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return formatDate(DateTime.now());
    }
    if (start != null && end == null) {
      return 'du ${formatDate(start)}';
    }
    if (start == null && end != null) {
      return 'au ${formatDate(end)}';
    }
    if (start!.year == end!.year &&
        start.month == end.month &&
        start.day == end.day) {
      return 'le ${formatDate(start)}';
    }
    return 'du ${formatDate(start)} au ${formatDate(end)}';
  }

  static String formatPercent(double val) {
    if (val.isNaN || val.isInfinite) return '0%';
    final rounded = (val * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return '${rounded.toInt()}%';
    }
    return '${rounded.toStringAsFixed(1)}%';
  }

  static String formatHeaderUnit(String text) {
    if (text.isEmpty || !text.contains('(')) return text;
    final unitRegex = RegExp(r'\s*\(([^)]+)\)');
    return text.replaceAllMapped(unitRegex, (match) {
      final unitContent = match.group(1)?.trim() ?? '';
      if (unitContent.isEmpty) return match.group(0)!;
      final nonBreakingUnitContent = unitContent.replaceAll(' ', '\u00A0');
      return ' ($nonBreakingUnitContent)';
    });
  }

  static PdfColor getCriticitePdfColor(String criticite) {
    final c = criticite.trim().toLowerCase();
    if (c.contains('critique') || c == '3') {
      return PdfColor.fromInt(0xFFD32F2F); // Rouge
    }
    if (c.contains('majeure') || c.contains('majeur') || c == '2') {
      return PdfColor.fromInt(0xFFF57C00); // Orange
    }
    if (c.contains('mineure') || c.contains('mineur') || c == '1') {
      return PdfColor.fromInt(0xFFFBC02D); // Jaune / Ambre
    }
    return darkGrey;
  }

  // ──────────────────────────────────────────────────────────────
  //  THEMES DE PAGE
  // ──────────────────────────────────────────────────────────────

  // Ratios calculés sur filigranne_image.png (1023 x 887 px) :
  // Le centre exact du cercle de la loupe est à cx = 650 px, cy = 371.5 px
  static const double kWatermarkCircleCxRatio = 650.0 / 1023.0; // ~0.63539
  static const double kWatermarkCircleCyRatio = 371.5 / 887.0;  // ~0.41883
  static const double kWatermarkAspectRatio = 887.0 / 1023.0;   // ~0.86706

  static pw.PageTheme buildCoverPageTheme(
    pw.Font fontRegular,
    pw.Font fontBold, {
    pw.MemoryImage? watermarkImage,
  }) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      margin: const pw.EdgeInsets.only(
        left: kLeftMargin,
        top: kTopMargin,
        right: kRightMargin,
        bottom: kBottomMargin + 40,
      ),
      buildBackground: (ctx) =>
          watermarkImage != null ? buildCoverWatermarkBackground(watermarkImage, opacity: 0.30) : pw.SizedBox(),
      buildForeground: (ctx) => buildFooterAbsolute(
        isFirstPage: true,
        ctx: ctx,
        fontRegular: fontRegular,
        fontBold: fontBold,
      ),
    );
  }

  static pw.PageTheme buildInnerPageTheme({
    required pw.Font fontRegular,
    required pw.Font fontBold,
    pw.MemoryImage? watermarkImage,
    int pageOffset = 0,
    int? overrideTotalPages,
    bool showWatermark = true,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) {
    return pw.PageTheme(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      margin: const pw.EdgeInsets.only(
        left: kLeftMargin,
        top: kTopMargin,
        right: kRightMargin,
        bottom: kBottomMargin + 4,
      ),
      buildBackground: (ctx) =>
          showWatermark ? buildWatermarkBackground(watermarkImage, pageFormat: ctx.page.pageFormat) : pw.SizedBox(),
      buildForeground: (ctx) => buildFooterAbsolute(
        isFirstPage: false,
        ctx: ctx,
        fontRegular: fontRegular,
        fontBold: fontBold,
        pageOffset: pageOffset,
        overrideTotalPages: overrideTotalPages,
      ),
    );
  }

  /// Filigrane spécifique de la page de couverture :
  /// - Loupe agrandie à width = 680 pt
  /// - Cercle de la loupe parfaitement centré horizontalement sur la page (shiftRight = 0.0)
  /// - Positionné verticalement pour cadrer au centre le texte 'RAPPORT / NATURE / SITE' (targetCenterY = 390.0 pt)
  /// - Le bas de la loupe déborde harmonieusement sans erreur (Stack overflow visible)
  /// - Opacité 0.30
  static pw.Widget buildCoverWatermarkBackground(
    pw.MemoryImage? watermarkImage, {
    double width = 680,
    double targetCenterY = 390.0,
    double shiftRight = 0.0,
    double opacity = 0.30,
    PdfPageFormat? pageFormat,
  }) {
    if (watermarkImage == null) return pw.SizedBox();

    final double pageWidth = pageFormat?.width ?? PdfFooterBuilder.kFullPageWidth;
    final double height = width * kWatermarkAspectRatio;

    final double circleCenterXInImage = width * kWatermarkCircleCxRatio;
    final double circleCenterYInImage = height * kWatermarkCircleCyRatio;

    final double imagePageX = (pageWidth / 2.0) - circleCenterXInImage + shiftRight;
    final double imagePageY = targetCenterY - circleCenterYInImage;

    final double left = imagePageX - kLeftMargin;
    final double top = imagePageY - kTopMargin;

    return pw.Stack(
      overflow: pw.Overflow.visible,
      children: [
        pw.Positioned(
          left: left,
          top: top,
          child: pw.Opacity(
            opacity: opacity,
            child: pw.Image(
              watermarkImage,
              width: width,
              height: height,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  /// Filigrane des pages intérieures :
  /// - Loupe agrandie à width = 680 pt
  /// - Cercle de la loupe rigoureusement centré horizontalement
  ///   et verticalement sur la page réelle (Portrait A4: 595.28x841.89 ou Paysage A4: 841.89x595.28)
  /// - Le bas de la loupe (manche) déborde sans erreur
  /// - Opacité 0.15
  static pw.Widget buildWatermarkBackground(
    pw.MemoryImage? watermarkImage, {
    double? width,
    double? targetCenterY,
    double shiftRight = 0.0,
    double opacity = 0.15,
    PdfPageFormat? pageFormat,
  }) {
    if (watermarkImage == null) return pw.SizedBox();

    final double pageWidth = pageFormat?.width ?? PdfFooterBuilder.kFullPageWidth;
    final double pageHeight = pageFormat?.height ?? 841.89;
    final bool isLandscape = pageWidth > pageHeight;

    // En mode paysage (hauteur 595 pt vs 842 pt en portrait), on réduit la largeur de la loupe
    // de 680 pt à 460 pt pour éviter qu'elle ne déborde et vienne chevaucher l'en-tête de page.
    final double effectiveWidth = width ?? (isLandscape ? 460.0 : 680.0);
    final double height = effectiveWidth * kWatermarkAspectRatio;
    final double actualTargetCenterY = targetCenterY ?? (pageHeight / 2.0);

    final double circleCenterXInImage = effectiveWidth * kWatermarkCircleCxRatio;
    final double circleCenterYInImage = height * kWatermarkCircleCyRatio;

    final double imagePageX = (pageWidth / 2.0) - circleCenterXInImage + shiftRight;
    final double imagePageY = actualTargetCenterY - circleCenterYInImage;

    final double left = imagePageX - kLeftMargin;
    final double top = imagePageY - kTopMargin;

    return pw.Stack(
      overflow: pw.Overflow.visible,
      children: [
        pw.Positioned(
          left: left,
          top: top,
          child: pw.Opacity(
            opacity: opacity,
            child: pw.Image(
              watermarkImage,
              width: effectiveWidth,
              height: height,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget buildFooterAbsolute({
    required bool isFirstPage,
    required pw.Context ctx,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    int pageOffset = 0,
    int? overrideTotalPages,
  }) {
    final double footerHeight = isFirstPage ? 72.0 : 40.0;
    final double descente = isFirstPage
        ? (kBottomMargin + 40)
        : (kBottomMargin + 12);
    final double pageWidth = ctx.page.pageFormat.width;

    final widget = isFirstPage
        ? PdfFooterBuilder.buildFirstPageFooter(
            ctx,
            pageWidth: pageWidth,
            fontRegular: fontRegular,
            fontBold: fontBold,
          )
        : PdfFooterBuilder.buildOtherPageFooter(
            ctx,
            pageWidth: pageWidth,
            pageOffset: pageOffset,
            overrideTotalPages: overrideTotalPages,
            fontRegular: fontRegular,
            fontBold: fontBold,
          );

    return pw.Stack(
      overflow: pw.Overflow.visible,
      children: [
        pw.Positioned(
          bottom: -descente,
          left: -kLeftMargin,
          right: -kRightMargin,
          child: pw.SizedBox(
            height: footerHeight,
            width: pageWidth,
            child: widget,
          ),
        ),
      ],
    );
  }

  static pw.Widget buildPageHeaderWidget({
    pw.MemoryImage? logoKesImage,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    String? nomClient,
    String? nomSite,
    String? numeroRapport,
    String? titreRapport,
  }) {
    final titre =
        titreRapport ??
        'VERIFICATION PERIODIQUE REGLEMENTAIRE DES INSTALLATIONS ELECTRIQUES';
    final rapportNum = numeroRapport ?? 'KES/IP/VE/${DateTime.now().year}/001';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: accentColor, width: 0.8),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoKesImage != null)
            pw.Image(
              logoKesImage,
              width: 55,
              height: 28,
              fit: pw.BoxFit.contain,
            )
          else
            pw.Text(
              'KES',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8,
                color: accentColor,
              ),
            ),
          pw.Expanded(child: pw.SizedBox()),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                '© KES INSPECTIONS & PROJECTS',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 6,
                  color: headerColor,
                ),
                textAlign: pw.TextAlign.right,
              ),
              if (nomSite != null && nomSite.isNotEmpty)
                pw.Text(
                  nomSite,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 6,
                    color: darkGrey,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              pw.Text(
                titre,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 5.5,
                  color: darkGrey,
                ),
                textAlign: pw.TextAlign.right,
              ),
              pw.Text(
                'Rapport n° : $rapportNum',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 5.5,
                  color: darkGrey,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  PRIMITIVES DE MISE EN PAGE
  // ──────────────────────────────────────────────────────────────

  static pw.Widget sectionBox(String title, {pw.Font? fontBold}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: headerColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Text(
        normalizeText(title),
        style: pw.TextStyle(
          font: fontBold,
          fontSize: fsH1,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static pw.Widget subTitle(
    String title, {
    pw.Font? fontBold,
    double topPadding = 4,
    double bottomPadding = 2,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: pw.Text(
        normalizeText(title),
        style: pw.TextStyle(
          font: fontBold,
          fontSize: fsH3,
          fontWeight: pw.FontWeight.bold,
          color: accentColor,
        ),
      ),
    );
  }

  static pw.Widget bodyText(String text, {pw.Font? fontRegular}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        normalizeText(text),
        style: pw.TextStyle(
          font: fontRegular ?? PdfReportStyles.fontRegular,
          fontSize: fsBody,
          color: darkGrey,
          lineSpacing: 2.0,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  static pw.Widget bodyBold(String text, {pw.Font? fontBold}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        normalizeText(text),
        style: pw.TextStyle(
          font: fontBold ?? PdfReportStyles.fontBold,
          fontSize: fsBody,
          fontWeight: pw.FontWeight.bold,
          color: darkGrey,
          lineSpacing: 2.0,
        ),
      ),
    );
  }

  static pw.Widget bulletItem(String text, {pw.Font? fontRegular}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 14, bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            width: 5,
            height: 5,
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              normalizeText(text),
              style: pw.TextStyle(
                font: fontRegular ?? PdfReportStyles.fontRegular,
                fontSize: fsBody,
                color: darkGrey,
                lineSpacing: 1.8,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget cell(
    String text, {
    required bool isHeader,
    PdfColor? color,
    int colspan = 1,
    bool centered = false,
    pw.Font? fontRegular,
    pw.Font? fontBold,
  }) {
    final displayText = isHeader ? formatHeaderUnit(text) : text;
    return pw.Container(
      color: color,
      alignment: centered ? pw.Alignment.center : pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        normalizeText(displayText),
        style: pw.TextStyle(
          font: isHeader
              ? (fontBold ?? PdfReportStyles.fontBold)
              : (fontRegular ?? PdfReportStyles.fontRegular),
          fontSize: fsSmall,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.white : darkGrey),
        ),
        textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.TableRow tableHeaderRow(List<String> headers, {pw.Font? fontBold}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: accentColor),
      children: headers
          .map((h) => cell(h, isHeader: true, centered: true, fontBold: fontBold))
          .toList(),
    );
  }

  static pw.TableRow tableDataRow(
    List<String> data, {
    required bool alt,
    bool centered = false,
    pw.Font? fontRegular,
  }) {
    return pw.TableRow(
      decoration: alt ? pw.BoxDecoration(color: tableRowAlt) : null,
      children: data
          .map((d) => cell(d, isHeader: false, centered: centered, fontRegular: fontRegular))
          .toList(),
    );
  }

  static String cleanRecommendationText(String text) {
    var cleaned = text.trim();
    cleaned = cleaned
        .replaceAll(
          RegExp(
            r'^Priorit[eé]\s*\d+\s*[—\-:]?\s*(Action\s+Immédiate|Immédiat|Court\s+[Tt]erme|Moyen\s+[Tt]erme)?\s*:\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    if (cleaned.isNotEmpty) {
      cleaned = '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
    }
    return cleaned;
  }

  static ParsedObservationRow parseObservationRow(String rawText) {
    var trimmed = rawText.trim();
    trimmed = trimmed
        .replaceAll(RegExp(r'^[•\-\*]\s*'), '')
        .replaceAll(RegExp(r'^\d+[\.\)]\s*'), '')
        .trim();

    if (trimmed.endsWith(';')) {
      trimmed = trimmed.substring(0, trimmed.length - 1).trim();
    }

    String leftPart = trimmed;
    String constatMajeur = '';

    final colonIdx = trimmed.indexOf(' : ');
    if (colonIdx != -1) {
      leftPart = trimmed.substring(0, colonIdx).trim();
      constatMajeur = trimmed.substring(colonIdx + 3).trim();
    } else {
      final singleColonIdx = trimmed.indexOf(':');
      if (singleColonIdx != -1) {
        leftPart = trimmed.substring(0, singleColonIdx).trim();
        constatMajeur = trimmed.substring(singleColonIdx + 1).trim();
      }
    }

    String observation = leftPart;
    String stats = '';

    final openParen = leftPart.lastIndexOf('(');
    final closeParen = leftPart.lastIndexOf(')');

    if (openParen != -1 && closeParen != -1 && openParen < closeParen) {
      observation = leftPart.substring(0, openParen).trim();
      stats = leftPart.substring(openParen + 1, closeParen).trim();
    }

    if (stats.isEmpty && constatMajeur.isNotEmpty) {
      final statsMatch = RegExp(
        r'^(\d+\s*constats?(?:\s*\([^)]+\)|[,\s]*[\d,\s%.]+))\s*(?:,\s*|;\s*|:\s*|-\s*)?(.*)$',
        caseSensitive: false,
      ).firstMatch(constatMajeur);

      if (statsMatch != null) {
        stats = statsMatch.group(1)?.trim() ?? '';
        var remainingConstat = statsMatch.group(2)?.trim() ?? '';
        if (remainingConstat.isNotEmpty) {
          remainingConstat =
              '${remainingConstat[0].toUpperCase()}${remainingConstat.substring(1)}';
          constatMajeur = remainingConstat;
        }
      }
    }

    if (stats.isEmpty) {
      final statsMatchObs = RegExp(
        r'(\d+\s*constats?(?:\s*\([^)]+\)|[,\s]*[\d,\s%.]+))',
        caseSensitive: false,
      ).firstMatch(observation);

      if (statsMatchObs != null) {
        stats = statsMatchObs.group(1)?.trim() ?? '';
        observation = observation.replaceAll(statsMatchObs.group(0)!, '').trim();
      }
    }

    observation = observation
        .replaceAll(
          RegExp(
            r'^Défauts?\s+prédominants?\s+liés?\s+[àa]\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'^Non-conformités?\s+prédominantes?\s+liées?\s+[àa]\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'^Anomalies?\s+liées?\s+[àa]\s*', caseSensitive: false),
          '',
        )
        .trim();

    if (observation.isNotEmpty) {
      observation = '${observation[0].toUpperCase()}${observation.substring(1)}';
    }

    return ParsedObservationRow(
      observation: observation,
      stats: stats,
      constatMajeur: constatMajeur,
    );
  }

  // ────────────────────────────────────────────────────────────
  //  PAGINATION ET DÉCOUPAGE DE TABLEAUX
  // ────────────────────────────────────────────────────────────
  static List<pw.Widget> buildHeaderWithTableList({
    required pw.Widget headerWidget,
    pw.Widget? introWidget,
    required pw.TableRow headerRow,
    required List<pw.TableRow> dataRows,
    required Map<int, pw.TableColumnWidth> columnWidths,
    pw.TableCellVerticalAlignment defaultVerticalAlignment =
        pw.TableCellVerticalAlignment.middle,
    pw.TableBorder? border,
    double minFreeSpace = 115,
    int minRowsWithHeader = 1,
  }) {
    if (dataRows.isEmpty) {
      return [
        pw.NewPage(freeSpace: minFreeSpace),
        headerWidget,
        if (introWidget != null) ...[pw.SizedBox(height: 4), introWidget],
      ];
    }

    final tableBorder =
        border ?? pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5);

    final initialCount = dataRows.length <= minRowsWithHeader
        ? dataRows.length
        : minRowsWithHeader;

    final block1Children = <pw.Widget>[
      headerWidget,
      if (introWidget != null) ...[pw.SizedBox(height: 4), introWidget],
      pw.SizedBox(height: 4),
      pw.Table(
        defaultVerticalAlignment: defaultVerticalAlignment,
        border: tableBorder,
        columnWidths: columnWidths,
        children: [headerRow, ...dataRows.take(initialCount)],
      ),
    ];

    if (dataRows.length <= initialCount) {
      return [
        pw.NewPage(freeSpace: minFreeSpace),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: block1Children,
        ),
      ];
    }

    final block2Table = pw.Table(
      defaultVerticalAlignment: defaultVerticalAlignment,
      border: tableBorder,
      columnWidths: columnWidths,
      children: dataRows.sublist(initialCount),
    );

    return [
      pw.NewPage(freeSpace: minFreeSpace),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: block1Children,
      ),
      block2Table,
    ];
  }

  static String formatConcentrationTitle(String rawTitle) {
    final trimmed = rawTitle.trim();
    if (trimmed.isEmpty) return '3. Concentration du risque';
    if (RegExp(r'^3\.\s*').hasMatch(trimmed)) return trimmed;
    return '3. $trimmed';
  }

  static pw.Widget buildMultiLineValueWidget(
    String value, {
    pw.Font? font,
  }) {
    final trimmed = value.trim();
    if (!trimmed.contains('\n')) {
      return pw.Text(
        trimmed,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          color: PdfReportStyles.darkGrey,
        ),
      );
    }

    final lines = trimmed
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines.map((line) {
        var cleanText = line;
        if (cleanText.startsWith('-') || cleanText.startsWith('*')) {
          cleanText = cleanText.substring(1).trim();
        }
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 3,
                height: 3,
                margin: const pw.EdgeInsets.only(top: 3, right: 4),
                decoration: pw.BoxDecoration(color: PdfReportStyles.headerColor, shape: pw.BoxShape.circle),
              ),
              pw.Expanded(
                child: pw.Text(
                  cleanText,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 8,
                    color: PdfReportStyles.darkGrey,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.TableRow buildIndicateurRow(
    String label,
    String value, {
    pw.Font? fontBold,
    pw.Font? fontRegular,
  }) {
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8,
              color: PdfReportStyles.headerColor,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: buildMultiLineValueWidget(value, font: fontRegular),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  //  ORDRE DES COLONNES PAR SECTION D'INSTALLATION
  // ────────────────────────────────────────────────────────────
  static const Map<String, List<String>> columnOrderBySection = {
    'MT': [
      'TYPE DE CELLULE',
      'TENSION DE SERVICE (kV)',
      'TENSION ASSIGNÉE (kV)',
      'POUVOIR DE COUPURE ASSIGNÉ (kA)',
      'SECTION DU CÂBLE (mm²)',
      'NATURE DU RÉSEAU',
    ],
    'BT': [
      'PUISSANCE TRANSFORMATEUR (kVA)',
      'TYPE DE TRANSFORMATEUR',
      'INTENSITE NOMINALE (A)',
      'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR (A)',
      'SECTION DU CÂBLE (mm²)',
      'TENSION PRIMAIRE/SECONDAIRE',
      'COUPLAGE',
      'REGIME DE NEUTRE',
      'PCC AMONT (MVA)',
      'UCC (%)',
      'IK3 MAX (kA)',
    ],
    'GROUPE': [
      'N°',
      'IDENTIFICATION',
      'MARQUE',
      'TYPE',
      'N° SERIE',
      'PUISSANCE(KVA)',
      'INTENSITE(A)',
      'ANNEE DE FABRICATION',
      'CALIBRE DU DISJONCTEUR(A)',
      'SECTION DU CABLE(mm2)',
    ],
    'CARBURANT': [
      'N°',
      'IDENTIFICATION DU GE',
      'MODE',
      'CAPACITE(L)',
      'CUVE DE RETENTION',
      'INDICATEUR DE NIVEAU',
      'MISE A LA TERRE',
      'ANNEE DE FABRICATION',
    ],
    'INVERSEUR': [
      'N°',
      'IDENTIFICATION DU GE',
      'MARQUE',
      'TYPE',
      'N° SERIE',
      'INTENSITE (A)',
      'REGLAGES',
    ],
    'STABILISATEUR': [
      'N°',
      'MARQUE',
      'TYPE',
      'N° SERIE',
      'ANNEE DE FABRICATION',
      'ANNEE D\'INSTALLATION',
      'PUISSANCE (KVA)',
      'INTENSITE (A)',
      'ENTREE',
      'SORTIE',
    ],
    'ONDULEUR': [
      'N°',
      'MARQUE',
      'TYPE',
      'N° DE SERIE',
      'PUISSANCE (KVA)',
      'INTENSITE (A)',
      'NOMBRE DE PHASE',
    ],
    'CPI': [
      'N°',
      'MARQUE',
      'TYPE',
      'N° SÉRIE',
      'RÉGIME DE NEUTRE SURVEILLÉ',
      'SEUIL D\'ALERTE (kΩ)',
      'SEUIL DE DÉCLENCHEMENT (kΩ)',
      'LOCALISATION',
    ],
  };

  static String docStatus(bool? val) =>
      val == true ? 'Présenté' : 'Non présenté';

  static pw.Widget buildGroupedCellWidget({
    required int currentIndex,
    required int totalRows,
    required String text,
    required pw.TextStyle style,
    required pw.Border border,
    PdfColor decorationColor = PdfColors.white,
    pw.EdgeInsets padding = const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    pw.TextAlign textAlign = pw.TextAlign.center,
    pw.Alignment alignment = pw.Alignment.center,
    bool condition = true,
  }) {
    final midIndex = (totalRows - 1) ~/ 2;
    if (currentIndex != midIndex || !condition || text.isEmpty) {
      return pw.Container(
        decoration: pw.BoxDecoration(color: decorationColor, border: border),
        padding: padding,
        alignment: alignment,
        child: pw.SizedBox(),
      );
    }

    final textWidget = pw.Text(
      text,
      style: style,
      textAlign: textAlign,
    );

    if (totalRows % 2 == 0) {
      final fs = style.fontSize ?? 8.5;
      final dynamicTopPadding = fs * 1.6;

      return pw.Container(
        decoration: pw.BoxDecoration(color: decorationColor, border: border),
        padding: pw.EdgeInsets.only(top: dynamicTopPadding, left: 4, right: 4, bottom: 2),
        alignment: pw.Alignment.topCenter,
        child: textWidget,
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(color: decorationColor, border: border),
      padding: padding,
      alignment: alignment,
      child: textWidget,
    );
  }

  /// Nettoie une valeur de cellule en retirant l'unité de mesure résiduelle
  /// pour respecter la règle : l'unité figure dans le titre de colonne uniquement.
  static String stripUnitFromValue(String? raw, [String? expectedUnit]) {
    if (raw == null) return '-';
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') return '-';

    // Si c'est un texte long ou une observation, ne pas altérer
    if (trimmed.length > 40 && !trimmed.contains(RegExp(r'^\d'))) {
      return trimmed;
    }

    String result = trimmed;
    if (expectedUnit != null && expectedUnit.trim().isNotEmpty) {
      final unitClean = expectedUnit.trim();
      final regex = RegExp(r'\s*' + RegExp.escape(unitClean) + r'\b', caseSensitive: false);
      result = result.replaceAll(regex, '').trim();
    }

    // Traitement spécifique des fractions de tension : ex: "20 kV / 400 V" -> "20 / 400"
    if (result.contains(RegExp(r'\d+\s*k?V\s*/\s*\d+\s*k?V', caseSensitive: false))) {
      result = result.replaceAll(RegExp(r'\s*k?V\b', caseSensitive: false), '').trim();
    }

    // Nettoyage générique des unités courantes si la chaîne se termine par une unité
    final genericUnitsRegex = RegExp(
      r'^(.*?)\s*(?:k?V|kVA|mm²|mm2|kA|MVA|mA|A|V|L|m|%)\s*$',
      caseSensitive: false,
    );
    final match = genericUnitsRegex.firstMatch(result);
    if (match != null) {
      final prefix = match.group(1)?.trim();
      if (prefix != null && prefix.isNotEmpty && RegExp(r'\d').hasMatch(prefix)) {
        result = prefix;
      }
    }

    return result.isNotEmpty ? result : '-';
  }
}

class ParsedObservationRow {
  final String observation;
  final String stats;
  final String constatMajeur;

  ParsedObservationRow({
    required this.observation,
    required this.stats,
    required this.constatMajeur,
  });
}

