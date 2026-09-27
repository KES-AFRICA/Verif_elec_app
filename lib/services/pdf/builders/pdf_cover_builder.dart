import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/services/intervenants_service.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable de la Page de Couverture et de la page Intervenants & Responsabilités
class PdfCoverBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();
  static pw.MemoryImage? logoKesImage;
  static pw.MemoryImage? cachedClientLogoImg;
  static pw.MemoryImage? cachedClientQrImg;

  static final pw.MemoryImage placeholder1x1 = pw.MemoryImage(
    Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]),
  );

  static String docStatus(bool? val) =>
      val == true ? 'Présenté' : 'Non présenté';

  /// Résolution dynamique du récepteur du rapport (civilité et fonction/nom en majuscules)
  /// Utilisée de manière rigoureusement identique pour la page de garde Verif Elec et Q18.
  static ({String attentionTitle, String fonctionAffichee}) resolveRecepteurInfo({
    required Mission mission,
    RenseignementsGeneraux? rg,
  }) {
    String rawFonction = (mission.recepteurFonction ??
            rg?.recepteurFonction ??
            mission.recepteurRapport ??
            rg?.recepteurRapport ??
            mission.effectiveRecepteurFonction)
        .trim();
    String rawNom = (mission.recepteurNom ??
            rg?.recepteurNom ??
            mission.effectiveRecepteurNom)
        .trim();
    String rawCivilite = (mission.recepteurCivilite ??
            rg?.recepteurCivilite ??
            mission.effectiveRecepteurCivilite ??
            '')
        .trim();

    // Si la civilité commence dans la fonction, l'extraire et nettoyer la fonction
    final lowerFonction = rawFonction.toLowerCase();
    if (lowerFonction.startsWith('monsieur ') || lowerFonction == 'monsieur') {
      if (rawCivilite.isEmpty || rawCivilite == 'Mme/M.') rawCivilite = 'Monsieur';
      rawFonction = rawFonction.substring(lowerFonction.startsWith('monsieur ') ? 9 : lowerFonction.length).trim();
    } else if (lowerFonction.startsWith('m. ') || lowerFonction.startsWith('m.')) {
      if (rawCivilite.isEmpty || rawCivilite == 'Mme/M.') rawCivilite = 'Monsieur';
      rawFonction = rawFonction.substring(lowerFonction.startsWith('m. ') ? 3 : 2).trim();
    } else if (lowerFonction.startsWith('madame ') || lowerFonction == 'madame') {
      if (rawCivilite.isEmpty || rawCivilite == 'Mme/M.') rawCivilite = 'Madame';
      rawFonction = rawFonction.substring(lowerFonction.startsWith('madame ') ? 7 : lowerFonction.length).trim();
    } else if (lowerFonction.startsWith('mme ') || lowerFonction.startsWith('mme.')) {
      if (rawCivilite.isEmpty || rawCivilite == 'Mme/M.') rawCivilite = 'Madame';
      rawFonction = rawFonction.substring(lowerFonction.startsWith('mme ') ? 4 : 4).trim();
    } else if (lowerFonction.startsWith('mademoiselle ') || lowerFonction == 'mademoiselle') {
      if (rawCivilite.isEmpty || rawCivilite == 'Mme/M.') rawCivilite = 'Mademoiselle';
      rawFonction = rawFonction.substring(lowerFonction.startsWith('mademoiselle ') ? 13 : lowerFonction.length).trim();
    } else if (lowerFonction.startsWith('mlle ') || lowerFonction.startsWith('mlle.')) {
      if (rawCivilite.isEmpty || rawCivilite == 'Mme/M.') rawCivilite = 'Mademoiselle';
      rawFonction = rawFonction.substring(lowerFonction.startsWith('mlle ') ? 5 : 5).trim();
    }

    if (rawCivilite.isEmpty || rawCivilite == 'Mme/M.') {
      final lowerNom = rawNom.toLowerCase();
      if (lowerNom.startsWith('monsieur ') || lowerNom == 'monsieur') {
        rawCivilite = 'Monsieur';
        rawNom = rawNom.substring(lowerNom.startsWith('monsieur ') ? 9 : lowerNom.length).trim();
      } else if (lowerNom.startsWith('m. ') || lowerNom.startsWith('m.')) {
        rawCivilite = 'Monsieur';
        rawNom = rawNom.substring(lowerNom.startsWith('m. ') ? 3 : 2).trim();
      } else if (lowerNom.startsWith('madame ') || lowerNom == 'madame') {
        rawCivilite = 'Madame';
        rawNom = rawNom.substring(lowerNom.startsWith('madame ') ? 7 : lowerNom.length).trim();
      } else if (lowerNom.startsWith('mme ') || lowerNom.startsWith('mme.')) {
        rawCivilite = 'Madame';
        rawNom = rawNom.substring(lowerNom.startsWith('mme ') ? 4 : 4).trim();
      }
    }

    final bool hasRecepteur = rawFonction.isNotEmpty || rawNom.isNotEmpty;
    final String? civiliteEffective = rawCivilite.isNotEmpty
        ? rawCivilite
        : (hasRecepteur ? 'Monsieur' : null);

    final String attentionTitle = civiliteEffective != null
        ? "A l'attention de $civiliteEffective"
        : "A l'attention de Mme/M.";

    final String fonctionAffichee = rawFonction.isNotEmpty
        ? rawFonction.toUpperCase()
        : (rawNom.isNotEmpty ? rawNom.toUpperCase() : 'XXXXXXXXXXXXXXX');

    return (
      attentionTitle: attentionTitle,
      fonctionAffichee: fonctionAffichee,
    );
  }


  static Future<void> preloadCoverImages(
    Mission mission, {
    required bool saveFilesToDisk,
  }) async {
    cachedClientLogoImg = null;
    cachedClientQrImg = null;

    if (mission.logoClient != null && mission.logoClient!.trim().isNotEmpty) {
      if (!saveFilesToDisk) {
        cachedClientLogoImg = placeholder1x1;
      } else {
        try {
          final resolvedPath = await AppImageUtils.resolvePathAsync(
            mission.logoClient!.trim(),
          );
          if (resolvedPath != null) {
            final file = File(resolvedPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              if (bytes.isNotEmpty) {
                cachedClientLogoImg = pw.MemoryImage(bytes);
              }
            }
          }
        } catch (_) {}
      }
    }

    if (mission.qrCodeClient != null &&
        mission.qrCodeClient!.trim().isNotEmpty) {
      if (!saveFilesToDisk) {
        cachedClientQrImg = placeholder1x1;
      } else {
        try {
          final resolvedPath = await AppImageUtils.resolvePathAsync(
            mission.qrCodeClient!.trim(),
          );
          if (resolvedPath != null) {
            final file = File(resolvedPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              if (bytes.isNotEmpty) cachedClientQrImg = pw.MemoryImage(bytes);
            }
          }
        } catch (_) {}
      }
    }
  }


  static pw.Widget buildCoverPage(
    Mission mission,
    RenseignementsGeneraux? rg,
    pw.Context ctx, {
    String? subTitleOverride,
    String? numeroRapport,
  }) {
    final dateDebut = rg?.dateDebut ?? mission.dateIntervention;
    final dateFin = rg?.dateFin;
    final bool hasDateRange = dateDebut != null &&
        dateFin != null &&
        (dateDebut.year != dateFin.year ||
            dateDebut.month != dateFin.month ||
            dateDebut.day != dateFin.day);
    String dateIntervention;
    if (hasDateRange) {
      dateIntervention =
          'Du\n${PdfReportStyles.formatDate(dateDebut)}\nAU\n${PdfReportStyles.formatDate(dateFin)}';
    } else if (dateDebut != null) {
      dateIntervention = PdfReportStyles.formatDate(dateDebut);
    } else {
      dateIntervention = '';
    }

    final numRapport = numeroRapport ??
        'KES/IP/VE/${(mission.dateRapport ?? DateTime.now()).year}/001';

    pw.MemoryImage? clientQrMemoryImg = cachedClientQrImg;
    if (clientQrMemoryImg == null &&
        mission.qrCodeClient != null &&
        mission.qrCodeClient!.isNotEmpty) {
      final qrFile = File(mission.qrCodeClient!);
      if (qrFile.existsSync()) {
        try {
          final qrBytes = qrFile.readAsBytesSync();
          clientQrMemoryImg = pw.MemoryImage(qrBytes);
        } catch (e) {
          if (kDebugMode) print('Erreur chargement QR Code client PDF: $e');
        }
      }
    }

    final nomClientStr = mission.nomClient.trim().toUpperCase();
    
    // Détermination dynamique du récepteur (civilité + fonction en MAJUSCULES au rendu)
    final recepteur = resolveRecepteurInfo(mission: mission, rg: rg);
    final String attentionTitle = recepteur.attentionTitle;
    final String fonctionAffichee = recepteur.fonctionAffichee;

    final nomSiteStr = (mission.nomSite ?? rg?.nomSite ?? '').trim().toUpperCase();
    final siteAffichage = nomSiteStr.isNotEmpty ? nomSiteStr : nomClientStr;
    final lieuInterventionStr = (mission.lieuIntervention ?? rg?.lieuIntervention ?? (nomSiteStr.isNotEmpty ? nomSiteStr : '')).trim();

    const double coverHeaderRowHeight = 24.0;
    const double coverDataRowHeight = 46.0;
    const double coverTableAndQrHeight = coverHeaderRowHeight + coverDataRowHeight; // 70.0 pt

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── En-tête supérieur : Logo KES (gauche) & Bloc Client (droite) ──
        pw.Container(
          height: 68,
          child: pw.Stack(
            overflow: pw.Overflow.visible,
            children: [
              pw.Positioned(
                left: 0,
                top: 0,
                child: logoKesImage != null
                    ? pw.Image(
                        logoKesImage!,
                        width: 170,
                        height: 62,
                        fit: pw.BoxFit.contain,
                      )
                    : pw.Text(
                        'KES INSPECTIONS AND PROJECTS',
                        style: pw.TextStyle(
                          font: fontBold,
                          color: PdfReportStyles.headerColor,
                          fontSize: 11,
                        ),
                      ),
              ),
              pw.Positioned(
                right: 0,
                top: 52,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'CLIENT',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        color: PdfReportStyles.accentColor,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    pw.ConstrainedBox(
                      constraints: const pw.BoxConstraints(maxWidth: 190),
                      child: pw.Text(
                        nomClientStr,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                          color: PdfReportStyles.accentColor,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      attentionTitle,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10.5,
                        color: PdfReportStyles.accentColor,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    pw.ConstrainedBox(
                      constraints: const pw.BoxConstraints(maxWidth: 190),
                      child: pw.Text(
                        fonctionAffichee,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10.5,
                          color: PdfReportStyles.accentColor,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.Spacer(flex: 1),

        // ── Titre principal : RAPPORT (Centré au cœur de la loupe, Bleu KES) ──
        pw.Center(
          child: pw.Text(
            'RAPPORT',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 24,
              color: PdfReportStyles.accentColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),

        pw.SizedBox(height: 16),

        // ── Nature de la mission (Centrée, calibrée pour ne pas toucher les recoins) ──
        pw.Center(
          child: pw.ConstrainedBox(
            constraints: const pw.BoxConstraints(maxWidth: 460),
            child: pw.Text(
              subTitleOverride ??
                  (() {
                    String nature = (mission.natureMission ?? rg?.verificationType ?? 'Vérification Périodique Réglementaire').trim();
                    if (nature.isEmpty) nature = 'Vérification Périodique Réglementaire';
                    String natureUpper = nature.toUpperCase();
                    if (!natureUpper.startsWith('VÉRIFICATION') && !natureUpper.startsWith('VERIFICATION')) {
                      natureUpper = 'VÉRIFICATION $natureUpper';
                    }
                    natureUpper = natureUpper
                        .replaceAll(RegExp(r'\s+DES\s+INSTALLATIONS\s+ELECTRIQUES', caseSensitive: false), '')
                        .replaceAll(RegExp(r'\s+DES\s+INSTALLATIONS\s+ÉLECTRIQUES', caseSensitive: false), '')
                        .trim();
                    return '$natureUpper\nDES INSTALLATIONS ELECTRIQUES';
                  })(),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 15,
                color: PdfReportStyles.accentColor,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),

        pw.SizedBox(height: 18),

        // ── Nom du site (Centré, harmonisé avec le centre de la loupe) ──
        pw.Center(
          child: pw.ConstrainedBox(
            constraints: const pw.BoxConstraints(maxWidth: 440),
            child: pw.Text(
              siteAffichage,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                color: PdfReportStyles.accentColor,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),

        pw.Spacer(flex: 1),

        // ── Bloc inférieur : Tableau unifié intégrant les 5 colonnes et le QR Code (hauteur exacte 70pt) ──
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: pw.FixedColumnWidth(440),
            1: pw.FixedColumnWidth(70),
          },
          children: [
            pw.TableRow(
              children: [
                // Colonne 0 : Tableau interne des 5 colonnes d'identification de la mission
                pw.Table(
                  border: const pw.TableBorder(
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  ),
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: pw.FixedColumnWidth(106),
                    1: pw.FixedColumnWidth(94),
                    2: pw.FixedColumnWidth(70),
                    3: pw.FixedColumnWidth(80),
                    4: pw.FixedColumnWidth(90),
                  },
                  children: [
                    // Ligne d'en-tête (PAS de couleur de fond, texte en accentColor)
                    pw.TableRow(
                      children: [
                        _buildCoverTableHeaderCell('Nature de la mission', height: coverHeaderRowHeight),
                        _buildCoverTableHeaderCell('N° du rapport', height: coverHeaderRowHeight),
                        _buildCoverTableHeaderCell('Date du rapport', height: coverHeaderRowHeight),
                        _buildCoverTableHeaderCell('Date d\'intervention', height: coverHeaderRowHeight),
                        _buildCoverTableHeaderCell('Lieu d\'intervention', height: coverHeaderRowHeight),
                      ],
                    ),
                    // Ligne des valeurs
                    pw.TableRow(
                      children: [
                        _buildCoverTableDataCell(
                          (() {
                            final n = (mission.natureMission ?? rg?.verificationType ?? 'Vérification Périodique Réglementaire').trim();
                            if (n.toUpperCase().contains('PERIODIQUE') || n.toUpperCase().contains('PÉRIODIQUE')) {
                              return 'Vérification Périodique Réglementaire';
                            }
                            return n;
                          })(),
                          height: coverDataRowHeight,
                        ),
                        _buildCoverTableDataCell(
                          numRapport,
                          height: coverDataRowHeight,
                        ),
                        _buildCoverTableDataCell(
                          PdfReportStyles.formatDate(mission.dateRapport ?? DateTime.now()),
                          height: coverDataRowHeight,
                        ),
                        _buildCoverTableDataCell(
                          dateIntervention.isNotEmpty ? dateIntervention : '-',
                          height: coverDataRowHeight,
                          fontSize: hasDateRange ? 7.0 : 8.0,
                        ),
                        _buildCoverTableDataCell(
                          lieuInterventionStr.isNotEmpty ? lieuInterventionStr : '-',
                          height: coverDataRowHeight,
                        ),
                      ],
                    ),
                  ],
                ),
                // Colonne 1 : Encadré QR Code KES carré (70x70) intégré nativement dans le tableau
                pw.Container(
                  height: coverTableAndQrHeight,
                  padding: const pw.EdgeInsets.all(5),
                  alignment: pw.Alignment.center,
                  child: clientQrMemoryImg != null
                      ? pw.Image(
                          clientQrMemoryImg,
                          width: 58,
                          height: 58,
                          fit: pw.BoxFit.contain,
                        )
                      : pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              'QR CODE',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 7.5,
                                color: PdfReportStyles.accentColor,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'KES Verification',
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 6,
                                color: PdfReportStyles.accentColor,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 25),
      ],
    );
  }

  static pw.Widget _buildCoverTableHeaderCell(String text, {double height = 24.0}) {
    return pw.Container(
      height: height,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 7.5,
          color: PdfReportStyles.accentColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildCoverTableDataCell(
    String text, {
    double height = 46.0,
    double fontSize = 8.0,
  }) {
    return pw.Container(
      height: height,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontRegular,
          fontSize: fontSize,
          color: PdfReportStyles.accentColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget coverInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 125,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: PdfReportStyles.fsBody,
                fontWeight: pw.FontWeight.bold,
                color: PdfReportStyles.headerColor,
              ),
            ),
          ),
          pw.Text(
            ': ',
            style: pw.TextStyle(
              fontSize: PdfReportStyles.fsBody,
              fontWeight: pw.FontWeight.bold,
              color: PdfReportStyles.headerColor,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: PdfReportStyles.fsBody, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildIntervenantsEtResponsabilitesPage(
    JSA? jsa,
    RenseignementsGeneraux? rg,
    dynamic currentUser,
    Map<String, int> trackedPages,
    int pageOffset, {
    DateTime? reportGenerationDate,
    Mission? mission,
    String? dateIntervention,
  }) {
    final List<String> inspecteursNoms = IntervenantsService.getMissionIntervenantsNoms(
      mission?.id ?? '',
      mission: mission,
      rg: rg,
      jsa: jsa,
      uppercase: false,
    );

    final dateGen = mission?.dateRapport ?? reportGenerationDate ?? DateTime.now();
    final dateGenStr = PdfReportStyles.formatDate(dateGen);

    final dateDebut = rg?.dateDebut ?? mission?.dateIntervention;
    final dateFin = rg?.dateFin;
    String intervDateStr;
    if (dateIntervention != null && dateIntervention.isNotEmpty) {
      intervDateStr = dateIntervention;
    } else if (dateDebut != null &&
        dateFin != null &&
        !dateDebut.isAtSameMomentAs(dateFin)) {
      intervDateStr =
          'Du ${PdfReportStyles.formatDate(dateDebut)}\nau ${PdfReportStyles.formatDate(dateFin)}';
    } else if (dateDebut != null) {
      intervDateStr = PdfReportStyles.formatDate(dateDebut);
    } else {
      intervDateStr = dateGenStr;
    }

    pw.Widget buildBulletList(List<String> list, {required String trackerKey}) {
      return PageTracker(
        key: trackerKey,
        registry: trackedPages,
        offset: pageOffset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: list.map((name) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    width: 3.5,
                    height: 3.5,
                    margin: const pw.EdgeInsets.only(right: 5),
                    decoration: pw.BoxDecoration(color: PdfReportStyles.headerColor),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      name,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: PdfReportStyles.fsBody,
                        color: PdfReportStyles.darkGrey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    pw.Widget buildHeaderCell(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: PdfReportStyles.fsSmall,
            color: PdfColors.white,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    pw.Widget buildRowHeaderCell(String text) {
      return pw.Container(
        decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: PdfReportStyles.fsBody,
            color: PdfReportStyles.headerColor,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    pw.Widget buildDateCell(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: PdfReportStyles.fsSmall + 0.5,
            color: PdfColors.black,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    final table = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(2.15),
        2: pw.FlexColumnWidth(2.15),
        3: pw.FlexColumnWidth(2.15),
        4: pw.FlexColumnWidth(2.15),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            pw.Container(),
            buildHeaderCell("INSPECTION\nRÉALISÉE PAR"),
            buildHeaderCell("RAPPORT\nRÉDIGÉ PAR"),
            buildHeaderCell("RAPPORT\nVÉRIFIÉ PAR"),
            buildHeaderCell("RAPPORT\nVALIDÉ PAR"),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            buildRowHeaderCell("NOM"),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList(
                inspecteursNoms,
                trackerKey: 'intervenants_inspection',
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList(
                inspecteursNoms,
                trackerKey: 'intervenants_redaction',
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList([
                'Patrick ESSAME',
              ], trackerKey: 'intervenants_verification'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList([
                'Patrick ESSAME',
              ], trackerKey: 'intervenants_validation'),
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            buildRowHeaderCell("Date"),
            buildDateCell(intervDateStr),
            buildDateCell(dateGenStr),
            buildDateCell(dateGenStr),
            buildDateCell(dateGenStr),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            buildRowHeaderCell("Signature"),
            pw.Container(height: 70),
            pw.Container(height: 70),
            pw.Container(height: 70),
            pw.Container(height: 70),
          ],
        ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PageTracker(
          key: 'intervenants',
          registry: trackedPages,
          offset: pageOffset,
          child: PdfReportStyles.sectionBox('INTERVENANTS ET RESPONSABILITÉS'),
        ),
        pw.SizedBox(height: 14),
        table,
      ],
    );
  }

  // Page signature "LA DIRECTION"

}
