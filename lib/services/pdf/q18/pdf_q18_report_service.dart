// lib/services/pdf/q18/pdf_q18_report_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:inspec_app/services/cancellation_token.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:inspec_app/services/pdf/builders/pdf_cover_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_final_page_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_sommaire_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_conclusion_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_dangers_synthesis_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_identification_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_perimetre_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_photos_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_regulatory_builder.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_collector.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';


typedef PdfProgressCallback = void Function(double progress, String statusMessage);

/// Service orchestrateur de production et génération du Rapport Q18 (APSAD D18).
///
/// Implémente la mise en page conforme à la charte KES, la pagination absolue en 2 passes
/// et le respect scrupuleux des 16 sections réglementaires du Traité APSAD D18.
class PdfQ18ReportService {
  /// Génère le nom de fichier officiel pour le rapport Q18
  static String buildQ18ReportFileName(Mission mission) {
    final client = mission.nomClient.trim().isNotEmpty
        ? _sanitizeFileName(mission.nomClient.trim())
        : 'Client';
    final site = (mission.nomSite != null && mission.nomSite!.trim().isNotEmpty)
        ? _sanitizeFileName(mission.nomSite!.trim())
        : 'Site';
    final annee = (mission.dateIntervention != null)
        ? mission.dateIntervention!.year
        : DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Rapport_Q18_${client}_${site}_${annee}_$timestamp.pdf';
  }

  static String _sanitizeFileName(String text) {
    var s = text.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    s = s.replaceAll(' ', '_');
    return s.replaceAll(RegExp(r'_+'), '_');
  }

  /// Génère le document complet du Rapport Q18 pour une mission donnée.
  static Future<File> generateMissionReport(
    String missionId, {
    Directory? outputDir,
    PdfProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    onProgress?.call(0.05, 'Initialisation des données de la mission...');
    await Future.delayed(const Duration(milliseconds: 30));

    final mission = HiveService.getMissionById(missionId);
    if (mission == null) {
      throw Exception('Mission introuvable pour l\'id : $missionId');
    }

    // 1. Collecte pure et snapshot certifié
    onProgress?.call(0.15, 'Collecte et classification des dangers Q18...');
    await Future.delayed(const Duration(milliseconds: 30));
    final data = Q18DataCollector.collect(missionId);

    // 2. Traitement et compression adaptative haute performance des photos
    Map<String, pw.MemoryImage> compressedPhotoImages = {};
    if (data.photoEntries.isNotEmpty) {
      onProgress?.call(0.20, 'Traitement et compression des photos (${data.photoEntries.length})...');
      await Future.delayed(const Duration(milliseconds: 30));
      compressedPhotoImages = await _prepareCompressedPhotos(
        data.photoEntries,
        cancellationToken: cancellationToken,
        onProgress: onProgress,
      );
    }

    // 3. Chargement des polices et assets graphiques
    onProgress?.call(0.35, 'Chargement de la typographie et des ressources...');
    await Future.delayed(const Duration(milliseconds: 30));
    final fonts = await _loadFonts();
    PdfReportStyles.fontRegular = fonts.regular;
    PdfReportStyles.fontBold = fonts.bold;
    final assets = await _loadAssets();

    // Chargement du QR Code du rapport Q18 (ou repli sur QR Code client si configuré)
    pw.MemoryImage? q18QrImage;
    final qrPathStr = (data.mission.qrCodeQ18 != null && data.mission.qrCodeQ18!.trim().isNotEmpty)
        ? data.mission.qrCodeQ18!.trim()
        : (data.mission.qrCodeClient != null && data.mission.qrCodeClient!.trim().isNotEmpty
            ? data.mission.qrCodeClient!.trim()
            : null);

    if (qrPathStr != null) {
      try {
        final resolved = await AppImageUtils.resolvePathAsync(qrPathStr);
        if (resolved != null) {
          final f = File(resolved);
          if (await f.exists()) {
            final bytes = await f.readAsBytes();
            if (bytes.isNotEmpty) {
              q18QrImage = pw.MemoryImage(bytes);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Erreur chargement QR Code Q18: $e');
      }
    }

    // 4. Passe 1 : Calcul de la pagination exacte (Zero-Load sur les photos)
    onProgress?.call(0.50, 'Mise en page préliminaire (Passe 1)...');
    await Future.delayed(const Duration(milliseconds: 30));
    final trackedPages = <String, int>{};
    final pass1Doc = _buildDocument(
      data: data,
      fonts: fonts,
      assets: assets,
      overrideTotalPages: null,
      trackedPages: trackedPages,
      photoImages: null,
      isPreflight: true,
      q18QrImage: q18QrImage,
    );
    await pass1Doc.save();
    cancellationToken?.throwIfCancelled();

    final totalPages = pass1Doc.document.pdfPageList.pages.length;

    // 5. Passe 2 : Rendu final avec numérotation absolue et photos compressées
    onProgress?.call(0.75, 'Génération du livrable définitif (Passe 2 : $totalPages pages)...');
    await Future.delayed(const Duration(milliseconds: 30));
    final pass2Doc = _buildDocument(
      data: data,
      fonts: fonts,
      assets: assets,
      overrideTotalPages: totalPages,
      trackedPages: trackedPages,
      photoImages: compressedPhotoImages,
      isPreflight: false,
      q18QrImage: q18QrImage,
    );
    final finalPdfBytes = await pass2Doc.save();
    cancellationToken?.throwIfCancelled();

    // 6. Sauvegarde sur le disque
    onProgress?.call(0.92, 'Écriture du fichier PDF certifié...');
    await Future.delayed(const Duration(milliseconds: 30));
    final dir = outputDir ?? await getApplicationDocumentsDirectory();
    final fileName = buildQ18ReportFileName(mission);
    final outputFile = File(path.join(dir.path, fileName));
    await outputFile.writeAsBytes(finalPdfBytes, flush: true);

    if (kDebugMode && await outputFile.exists()) {
      final double sizeMb = (await outputFile.length()) / (1024 * 1024);
      debugPrint('⚡ [Q18 Compression] Rapport Q18 généré : ${sizeMb.toStringAsFixed(2)} Mo ($totalPages pages)');
    }

    onProgress?.call(1.0, 'Rapport Q18 finalisé avec succès ($totalPages pages).');
    await Future.delayed(const Duration(milliseconds: 30));
    return outputFile;
  }

  /// Collecte la liste exhaustive et ordonnée des entrées du Sommaire Q18.
  static List<SommaireEntry> _buildSommaireEntries(Q18DataSnapshot data) {
    final entries = <SommaireEntry>[
      SommaireEntry(
        titre: "1. IDENTIFICATION DE LA MISSION",
        key: 'q18_s1',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "2. OBJET ET CADRE DE LA MISSION",
        key: 'q18_s2',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "3. CADRE RÉGLEMENTAIRE ET NORMATIF",
        key: 'q18_s3',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "4. PRÉSENTATION DU SITE ET DES INSTALLATIONS",
        key: 'q18_s4',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "4.1 Renseignements généraux",
        key: 'q18_s4_1',
        level: 1,
      ),
      SommaireEntry(
        titre: "4.2 Synthèse quantitative des installations",
        key: 'q18_s4_2',
        level: 1,
      ),
      SommaireEntry(
        titre: "5. PÉRIMÈTRE DE LA VÉRIFICATION ET EXCLUSIONS",
        key: 'q18_s5',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "5.1 Périmètre vérifié",
        key: 'q18_s5_1',
        level: 1,
      ),
      SommaireEntry(
        titre: "5.2 Parties exclues ou non visitées",
        key: 'q18_s5_2',
        level: 1,
      ),
      SommaireEntry(
        titre: "6. DOCUMENTS ET ÉLÉMENTS CONSULTÉS",
        key: 'q18_s6',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "7. MÉTHODOLOGIE ET POINTS DE CONTRÔLE",
        key: 'q18_s7',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "8. ÉCHELLE DE CLASSIFICATION DES DANGERS",
        key: 'q18_s8',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "9. TYPOLOGIE DES DANGERS LES PLUS COURANTS",
        key: 'q18_s9',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "10. SYNTHÈSE DES DANGERS CONSTATÉS",
        key: 'q18_s10',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "11. RÉCAPITULATIF STATISTIQUE DES DANGERS",
        key: 'q18_s11',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "12. AVIS GLOBAL ET CONCLUSION",
        key: 'q18_s12',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "13. COMPTE RENDU DE LEVÉE DES DANGERS",
        key: 'q18_s13',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "14. PROCHAINE ÉCHÉANCE",
        key: 'q18_s14',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
      SommaireEntry(
        titre: "15. VISA ET SIGNATURE DES VÉRIFICATEURS AGRÉÉS",
        key: 'q18_s15',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    ];

    if (data.photoEntries.isNotEmpty) {
      entries.add(
        SommaireEntry(
          titre: "16. PLANCHE PHOTOGRAPHIQUE DES CONSTATS",
          key: 'q18_s16',
          level: 0,
          isBold: true,
          isUppercase: true,
        ),
      );
    }

    return entries;
  }

  /// Associe le marqueur PageTracker au premier widget de la section pour la résolution du Sommaire.
  static List<pw.Widget> _trackList(
    List<pw.Widget> widgets,
    String key,
    Map<String, int>? trackedPages,
    int pageOffset,
  ) {
    if (widgets.isEmpty || trackedPages == null) return widgets;
    return [
      PageTracker(
        key: key,
        registry: trackedPages,
        offset: pageOffset,
        child: widgets.first,
      ),
      ...widgets.sublist(1),
    ];
  }

  @visibleForTesting
  static pw.Document buildDocumentForTesting({
    required Q18DataSnapshot data,
    required ({pw.Font regular, pw.Font bold}) fonts,
    required ({pw.MemoryImage? logoKes, pw.MemoryImage? watermark, pw.MemoryImage? watermarkWhite}) assets,
    required int? overrideTotalPages,
    Map<String, int>? trackedPages,
    Map<String, pw.MemoryImage>? photoImages,
    bool isPreflight = false,
    pw.MemoryImage? q18QrImage,
  }) => _buildDocument(
    data: data,
    fonts: fonts,
    assets: assets,
    overrideTotalPages: overrideTotalPages,
    trackedPages: trackedPages,
    photoImages: photoImages,
    isPreflight: isPreflight,
    q18QrImage: q18QrImage,
  );

  static pw.Document _buildDocument({
    required Q18DataSnapshot data,
    required ({pw.Font regular, pw.Font bold}) fonts,
    required ({pw.MemoryImage? logoKes, pw.MemoryImage? watermark, pw.MemoryImage? watermarkWhite}) assets,
    required int? overrideTotalPages,
    Map<String, int>? trackedPages,
    Map<String, pw.MemoryImage>? photoImages,
    bool isPreflight = false,
    pw.MemoryImage? q18QrImage,
  }) {
    // Configuration de la quatrième de couverture institutionnelle
    PdfFinalPageBuilder.fontRegular = fonts.regular;
    PdfFinalPageBuilder.fontBold = fonts.bold;
    if (assets.watermarkWhite != null) {
      PdfFinalPageBuilder.watermarkWhiteImage = assets.watermarkWhite;
    }

    final pdf = pw.Document(
      title: 'Rapport Q18 - ${data.mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      creator: 'KES Inspection App',
      compress: true,
    );

    // ── PAGE 1 : PAGE DE COUVERTURE ──
    pdf.addPage(
      pw.Page(
        pageTheme: PdfReportStyles.buildCoverPageTheme(
          fonts.regular,
          fonts.bold,
          watermarkImage: assets.watermark,
        ),
        build: (ctx) => _buildCoverPage(
          data: data,
          logoKesImage: assets.logoKes,
          q18QrImage: q18QrImage,
          fontBold: fonts.bold,
          fontRegular: fonts.regular,
        ),
      ),
    );

    // ── PAGE 2 : SOMMAIRE DYNAMIQUE (PAGINATION 2 PASSES) ──
    final sommaireEntries = _buildSommaireEntries(data);
    PdfSommaireBuilder.addSommairePages(
      pdf,
      sommaireEntries,
      trackedPages ?? {},
      nomClient: data.mission.nomClient,
      nomSite: data.mission.nomSite,
      numeroRapport: data.numeroRapportQ18,
      titreRapport: 'RAPPORT Q18 - VÉRIFICATION DES INSTALLATIONS ÉLECTRIQUES (APSAD D18)',
      pageOffset: 0,
      overrideTotalPages: overrideTotalPages,
      fontRegular: fonts.regular,
      fontBold: fonts.bold,
      logoKesImage: assets.logoKes,
      watermarkImage: assets.watermark,
    );

    // ── CORPS DU RAPPORT (SECTIONS 1 À 16, À PARTIR DE LA PAGE 3) ──
    final innerPageTheme = PdfReportStyles.buildInnerPageTheme(
      fontRegular: fonts.regular,
      fontBold: fonts.bold,
      watermarkImage: assets.watermark,
      pageOffset: 0,
      overrideTotalPages: overrideTotalPages,
      showWatermark: true,
    );

    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: innerPageTheme,
        header: (ctx) => PdfReportStyles.buildPageHeaderWidget(
          logoKesImage: assets.logoKes,
          fontRegular: fonts.regular,
          fontBold: fonts.bold,
          nomClient: data.mission.nomClient,
          nomSite: data.mission.nomSite,
          numeroRapport: data.numeroRapportQ18,
          titreRapport: 'RAPPORT Q18 - VÉRIFICATION DES INSTALLATIONS ÉLECTRIQUES (APSAD D18)',
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          // Section 1 : Identification de la mission
          widgets.addAll(
            _trackList(
              Q18IdentificationBuilder.buildSection1Identification(
                data,
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s1',
              trackedPages,
              0,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 2 : Objet et cadre de la mission
          widgets.addAll(
            _trackList(
              Q18RegulatoryBuilder.buildSection2ObjetCadre(
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s2',
              trackedPages,
              0,
            ),
          );

          // Section 3 : Cadre réglementaire et normatif
          widgets.addAll(
            _trackList(
              Q18RegulatoryBuilder.buildSection3CadreReglementaire(
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s3',
              trackedPages,
              0,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 4 : Présentation du site et des installations
          widgets.addAll(
            _trackList(
              Q18IdentificationBuilder.buildSection4Presentation(
                data,
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
                trackedPages: trackedPages,
                pageOffset: 0,
              ),
              'q18_s4',
              trackedPages,
              0,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 5 : Périmètre de la vérification et exclusions
          widgets.addAll(
            _trackList(
              Q18PerimetreBuilder.buildSection5Perimetre(
                data,
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
                trackedPages: trackedPages,
                pageOffset: 0,
              ),
              'q18_s5',
              trackedPages,
              0,
            ),
          );

          // Section 6 : Documents et éléments consultés (commence sur la page suivante, avec Section 7)
          widgets.add(pw.NewPage());
          widgets.addAll(
            _trackList(
              Q18PerimetreBuilder.buildSection6DocumentsConsultes(
                data,
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s6',
              trackedPages,
              0,
            ),
          );

          // Section 7 : Méthodologie et points de contrôle (sur la même page que Section 6)
          widgets.addAll(
            _trackList(
              Q18RegulatoryBuilder.buildSection7Methodologie(
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s7',
              trackedPages,
              0,
            ),
          );

          // Section 8 : Échelle de classification des dangers (sur la page suivante, avec Section 9)
          widgets.add(pw.NewPage());
          widgets.addAll(
            _trackList(
              Q18RegulatoryBuilder.buildSection8ClassificationDangers(
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s8',
              trackedPages,
              0,
            ),
          );

          // Section 9 : Typologie des dangers les plus courants (sur la même page que Section 8)
          widgets.addAll(
            _trackList(
              Q18RegulatoryBuilder.buildSection9TypologieDangers(
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s9',
              trackedPages,
              0,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 10 : Synthèse des dangers constatés
          widgets.addAll(
            _trackList(
              Q18DangersSynthesisBuilder.buildSection10Dangers(
                data,
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s10',
              trackedPages,
              0,
            ),
          );

          // Section 11 : Récapitulatif statistique des dangers (démarre sur une nouvelle page)
          widgets.add(pw.NewPage());
          widgets.addAll(
            _trackList(
              Q18DangersSynthesisBuilder.buildSection11Statistiques(
                data,
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s11',
              trackedPages,
              0,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 12 : Avis global et conclusion
          widgets.addAll(
            _trackList(
              Q18ConclusionBuilder.buildSection12AvisGlobal(
                data,
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s12',
              trackedPages,
              0,
            ),
          );

          // Section 13 : Compte rendu de levée des dangers (démarre sur une nouvelle page)
          widgets.add(pw.NewPage());
          widgets.addAll(
            _trackList(
              Q18ConclusionBuilder.buildSection13LeveeDangers(
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s13',
              trackedPages,
              0,
            ),
          );

          // Section 14 : Prochaine échéance
          widgets.addAll(
            _trackList(
              Q18ConclusionBuilder.buildSection14ProchaineEcheance(
                data,
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s14',
              trackedPages,
              0,
            ),
          );

          // Section 15 : Visa et signature des vérificateurs agréés (toujours sur une nouvelle page)
          widgets.add(pw.NewPage());
          widgets.addAll(
            _trackList(
              Q18ConclusionBuilder.buildSection15Signature(
                data,
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
              'q18_s15',
              trackedPages,
              0,
            ),
          );

          // Section 16 : Planche photographique
          if (data.photoEntries.isNotEmpty) {
            widgets.add(pw.NewPage());
            widgets.addAll(
              _trackList(
                Q18PhotosBuilder.buildSection16Photos(
                  data.photoEntries,
                  fontBold: fonts.bold,
                  fontRegular: fonts.regular,
                  photoImages: photoImages,
                  isPreflight: isPreflight,
                ),
                'q18_s16',
                trackedPages,
                0,
              ),
            );
          }

          return widgets;
        },
      ),
    );

    // ── DERNIÈRE PAGE DU RAPPORT : QUATRIÈME DE COUVERTURE INSTITUTIONNELLE KES ──
    pdf.addPage(PdfFinalPageBuilder.buildPage());

    return pdf;
  }

  static pw.Widget _buildCoverPage({
    required Q18DataSnapshot data,
    required pw.MemoryImage? logoKesImage,
    pw.MemoryImage? q18QrImage,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final mission = data.mission;
    final rg = data.renseignements;

    final nomClientStr = mission.nomClient.trim().isNotEmpty
        ? mission.nomClient.trim().toUpperCase()
        : 'CLIENT';

    // Détermination dynamique du récepteur (civilité + fonction en MAJUSCULES au rendu)
    final rawFonction = (mission.recepteurFonction ?? rg?.recepteurFonction ?? mission.effectiveRecepteurFonction).trim();
    final rawNom = (mission.recepteurNom ?? rg?.recepteurNom ?? mission.effectiveRecepteurNom).trim();
    final rawCivilite = (mission.recepteurCivilite ?? rg?.recepteurCivilite ?? mission.effectiveRecepteurCivilite ?? '').trim();
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

    final nomSiteStr = (mission.nomSite ?? rg?.nomSite ?? '').trim().toUpperCase();
    final lieuInterventionStr = (mission.lieuIntervention ?? rg?.lieuIntervention ?? (nomSiteStr.isNotEmpty ? nomSiteStr : '')).trim();

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

    const double coverHeaderRowHeight = 24.0;
    const double coverDataRowHeight = 46.0;
    const double coverTableAndQrHeight = coverHeaderRowHeight + coverDataRowHeight; // 70.0 pt

    // Résolution synchrone de repli pour le QR Code si non fourni en amont
    pw.MemoryImage? clientQrMemoryImg = q18QrImage;
    if (clientQrMemoryImg == null) {
      final qrPath = (mission.qrCodeQ18 != null && mission.qrCodeQ18!.trim().isNotEmpty)
          ? mission.qrCodeQ18!.trim()
          : (mission.qrCodeClient != null && mission.qrCodeClient!.trim().isNotEmpty
              ? mission.qrCodeClient!.trim()
              : null);
      if (qrPath != null) {
        final qrFile = File(qrPath);
        if (qrFile.existsSync()) {
          try {
            final qrBytes = qrFile.readAsBytesSync();
            if (qrBytes.isNotEmpty) {
              clientQrMemoryImg = pw.MemoryImage(qrBytes);
            }
          } catch (e) {
            if (kDebugMode) print('Erreur chargement QR Code Q18: $e');
          }
        }
      }
    }

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
                        logoKesImage,
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

        // ── Titre principal : Calibré pour déborder du cercle blanc central sans jamais toucher le cercle externe gris de la loupe ──
        pw.Center(
          child: pw.ConstrainedBox(
            constraints: const pw.BoxConstraints(maxWidth: 285),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'RAPPORT Q18',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 22,
                    color: PdfReportStyles.accentColor,
                    letterSpacing: 1.0,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Compte rendu de vérification\ndes installations électriques',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: PdfReportStyles.accentColor,
                    lineSpacing: 1.2,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Établi selon le référentiel APSAD D18 (prévention des risques d\'incendie et d\'explosion), à la suite de la mission de vérification de conformité des installations électriques',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8.2,
                    color: PdfReportStyles.accentColor,
                    lineSpacing: 1.25,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
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
                        _buildCoverTableHeaderCell('Nature de la mission', fontBold: fontBold, height: coverHeaderRowHeight),
                        _buildCoverTableHeaderCell('N° du rapport', fontBold: fontBold, height: coverHeaderRowHeight),
                        _buildCoverTableHeaderCell('Date du rapport', fontBold: fontBold, height: coverHeaderRowHeight),
                        _buildCoverTableHeaderCell('Date d\'intervention', fontBold: fontBold, height: coverHeaderRowHeight),
                        _buildCoverTableHeaderCell('Lieu d\'intervention', fontBold: fontBold, height: coverHeaderRowHeight),
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
                          fontBold: fontBold,
                          fontRegular: fontRegular,
                          height: coverDataRowHeight,
                        ),
                        _buildCoverTableDataCell(
                          data.numeroRapportQ18,
                          fontBold: fontBold,
                          fontRegular: fontRegular,
                          height: coverDataRowHeight,
                        ),
                        _buildCoverTableDataCell(
                          PdfReportStyles.formatDate(mission.dateRapport ?? DateTime.now()),
                          fontBold: fontBold,
                          fontRegular: fontRegular,
                          height: coverDataRowHeight,
                        ),
                        _buildCoverTableDataCell(
                          dateIntervention.isNotEmpty ? dateIntervention : '-',
                          fontBold: fontBold,
                          fontRegular: fontRegular,
                          height: coverDataRowHeight,
                          fontSize: hasDateRange ? 7.0 : 8.0,
                        ),
                        _buildCoverTableDataCell(
                          lieuInterventionStr.isNotEmpty
                              ? lieuInterventionStr
                              : (data.lieuIntervention.isNotEmpty ? data.lieuIntervention : '-'),
                          fontBold: fontBold,
                          fontRegular: fontRegular,
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

  static pw.Widget _buildCoverTableHeaderCell(
    String text, {
    required pw.Font fontBold,
    double height = 24.0,
  }) {
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
    required pw.Font fontBold,
    required pw.Font fontRegular,
    bool isBold = false,
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
          font: isBold ? fontBold : fontRegular,
          fontSize: fontSize,
          color: PdfReportStyles.accentColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<({pw.Font regular, pw.Font bold})> _loadFonts() async {
    try {
      final regData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      return (
        regular: pw.Font.ttf(regData),
        bold: pw.Font.ttf(boldData),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Fallback sur polices système PDF pour le rapport Q18: $e');
      }
      return (
        regular: PdfReportStyles.fontRegular,
        bold: PdfReportStyles.fontBold,
      );
    }
  }

  static Future<({pw.MemoryImage? logoKes, pw.MemoryImage? watermark, pw.MemoryImage? watermarkWhite})> _loadAssets() async {
    pw.MemoryImage? logoKes;
    pw.MemoryImage? watermark;
    pw.MemoryImage? watermarkWhite;

    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      if (logoBytes.lengthInBytes > 0) {
        logoKes = pw.MemoryImage(logoBytes.buffer.asUint8List());
      }
    } catch (_) {}

    logoKes ??= PdfReportService.logoKesImage ?? PdfCoverBuilder.logoKesImage;

    try {
      final wmBytes = await rootBundle.load('assets/images/filigranne_image.png');
      if (wmBytes.lengthInBytes > 0) {
        watermark = pw.MemoryImage(wmBytes.buffer.asUint8List());
      }
    } catch (_) {}

    try {
      final wmWhiteBytes = await rootBundle.load('assets/images/filigranne_white.png');
      if (wmWhiteBytes.lengthInBytes > 0) {
        watermarkWhite = pw.MemoryImage(wmWhiteBytes.buffer.asUint8List());
      }
    } catch (_) {}

    return (logoKes: logoKes, watermark: watermark, watermarkWhite: watermarkWhite);
  }

  /// Pré-traitement, mise en cache et compression adaptative haute performance des photos d'illustration.
  /// Réduit les photos de 3-5 Mo brutes à ~30-50 Ko en JPEG haute définition (640x480, Q: 65),
  /// divisant la taille globale du livrable par 8 à 12 sans perte visuelle de diagnostic.
  static Future<Map<String, pw.MemoryImage>> _prepareCompressedPhotos(
    List<PdfPhotoEntry> photoEntries, {
    CancellationToken? cancellationToken,
    PdfProgressCallback? onProgress,
  }) async {
    final photoMap = <String, pw.MemoryImage>{};
    final resolvedPathsMap = <String, pw.MemoryImage>{};
    final total = photoEntries.length;
    if (total == 0) return photoMap;

    Directory? tempDir;
    try {
      tempDir = await getTemporaryDirectory();
    } catch (_) {}

    for (int i = 0; i < total; i++) {
      cancellationToken?.throwIfCancelled();
      final entry = photoEntries[i];
      final pathStr = entry.filePath.trim();
      if (pathStr.isEmpty) continue;

      if (photoMap.containsKey(pathStr)) continue;

      try {
        final resolvedPath = await AppImageUtils.resolvePathAsync(pathStr);
        if (resolvedPath == null) continue;

        // Déduplication d'instance : si le même fichier physique a déjà été compressé
        if (resolvedPathsMap.containsKey(resolvedPath)) {
          final existingInstance = resolvedPathsMap[resolvedPath]!;
          photoMap[pathStr] = existingInstance;
          photoMap[entry.filePath] = existingInstance;
          continue;
        }

        final file = File(resolvedPath);
        if (!await file.exists()) continue;

        // 1. Cache disque pour réactivité instantanée
        File? cacheFile;
        if (tempDir != null) {
          final cacheKey = 'q18_photo_${resolvedPath.hashCode}_640_480_65.jpg';
          cacheFile = File('${tempDir.path}/$cacheKey');
        }

        pw.MemoryImage? memImage;

        if (cacheFile != null && await cacheFile.exists()) {
          try {
            final cachedBytes = await cacheFile.readAsBytes();
            if (cachedBytes.isNotEmpty) {
              memImage = pw.MemoryImage(cachedBytes);
            }
          } catch (_) {}
        }

        // 2. Compression FlutterImageCompress via fichier
        if (memImage == null) {
          try {
            final compressed = await FlutterImageCompress.compressWithFile(
              resolvedPath,
              minWidth: 640,
              minHeight: 480,
              quality: 65,
              format: CompressFormat.jpeg,
            );
            if (compressed != null && compressed.isNotEmpty) {
              if (cacheFile != null) {
                try {
                  await cacheFile.writeAsBytes(compressed);
                } catch (_) {}
              }
              memImage = pw.MemoryImage(compressed);
            }
          } catch (_) {}
        }

        // 3. Fallback FlutterImageCompress via liste d'octets
        if (memImage == null) {
          try {
            final rawBytes = await file.readAsBytes();
            if (rawBytes.isNotEmpty) {
              final compressed = await FlutterImageCompress.compressWithList(
                rawBytes,
                minWidth: 640,
                minHeight: 480,
                quality: 65,
                format: CompressFormat.jpeg,
              );
              if (compressed.isNotEmpty) {
                if (cacheFile != null) {
                  try {
                    await cacheFile.writeAsBytes(compressed);
                  } catch (_) {}
                }
                memImage = pw.MemoryImage(compressed);
              } else {
                memImage = pw.MemoryImage(rawBytes);
              }
            }
          } catch (_) {}
        }

        // 4. Dernier repli : lecture brute non compressée
        if (memImage == null) {
          try {
            final rawBytes = await file.readAsBytes();
            if (rawBytes.isNotEmpty) {
              memImage = pw.MemoryImage(rawBytes);
            }
          } catch (_) {}
        }

        if (memImage != null) {
          photoMap[pathStr] = memImage;
          photoMap[entry.filePath] = memImage;
          resolvedPathsMap[resolvedPath] = memImage;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Erreur compression photo Q18 ($pathStr): $e');
        }
      }

      if (i % 2 == 0 || i == total - 1) {
        final progress = 0.20 + (0.15 * (i + 1) / total);
        onProgress?.call(progress, 'Optimisation des photos (${i + 1}/$total)...');
        await Future.delayed(Duration.zero);
      }
    }

    return photoMap;
  }
}
