import 'package:inspec_app/services/pdf/builders/pdf_cover_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';
export 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';
import 'package:inspec_app/services/pdf/pdf_photo_context.dart';
import 'package:inspec_app/services/pdf/builders/pdf_mesures_essais_builder.dart';
export 'package:inspec_app/services/pdf/builders/pdf_mesures_essais_builder.dart';
export 'package:inspec_app/services/pdf/pdf_photo_context.dart';
import 'package:inspec_app/services/pdf/builders/pdf_classement_foudre_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_audit_installations_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_observations_recap_builder.dart';
// pdf_report_service.dart

import 'package:inspec_app/services/pdf/builders/pdf_equipements_synthesis_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_renseignements_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_description_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
export 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/services/cancellation_token.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:inspec_app/services/pdf/pdf_chunk_merger.dart';
import 'builders/pdf_sommaire_builder.dart';
import 'builders/pdf_regulatory_builder.dart';
import 'builders/pdf_executive_summary_builder.dart';
import 'builders/pdf_statistics_builder.dart';
import 'builders/pdf_final_page_builder.dart';
import 'pdf_page_tracker.dart';
export 'pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_footer_builder.dart';
import '../../components/safe_file_image.dart';
import '../ai/executive_summary_data.dart';
import '../ai/executive_summary_snapshot.dart';
import '../ai/mission_executive_summary_service.dart';

typedef PdfProgressCallback =
    void Function(double progress, String statusMessage);

/// Contexte d'affichage de photo pour l'optimisation adaptative de résolution et de qualité.
// PdfPhotoContext is defined in pdf_photo_context.dart

// ================================================================
//  PdfReportService
// ================================================================



class PdfReportService {
  // ──────────────────────────────────────────────────────────────
  //  CONSTANTES DE MISE EN PAGE (1.5 cm partout)
  // ──────────────────────────────────────────────────────────────

  static const double kLeftMargin = 1.5 * 28.35; // 1.5 cm
  static const double kTopMargin = 1.5 * 28.35; // 1.5 cm
  static const double kRightMargin = 1.5 * 28.35; // 1.5 cm
  static const double kBottomMargin = 1.5 * 28.35; // 1.5 cm

  // ──────────────────────────────────────────────────────────────
  //  COULEURS
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
  //  TAILLES DE POLICE
  // ──────────────────────────────────────────────────────────────
  static const double fsH1 = 12.0;
  static const double fsH2 = 10.5;
  static const double fsH3 = 10.0;
  static const double fsBody = 9.0;
  static const double fsSmall = 7.5;

  // ──────────────────────────────────────────────────────────────
  //  IMAGES (chargees une seule fois)
  // ──────────────────────────────────────────────────────────────
  static pw.MemoryImage? _watermarkImage;
  static pw.MemoryImage? _watermarkWhiteImage;
  static pw.MemoryImage? _firstPageFooterImage;
  static pw.MemoryImage? _logoKesImage;
  static pw.MemoryImage? _imgHabilitation;
  static pw.MemoryImage? _imgAccesGauche;
  static pw.MemoryImage? _imgAccesDroite1;
  static pw.MemoryImage? _imgAccesDroite2;
  static bool _imagesLoaded = false;

  /// Cache d'instances de session en mémoire : garantit qu'une même image partagée
  /// (ex. équipement apparaissant en tableau ET en galerie, ou photos répétées) n'est instanciée
  /// et encodée qu'UNE SEULE FOIS comme XObject dans le document PDF.
  static final Map<String, pw.MemoryImage> _sessionMemoryImageCache = {};

  static void clearSessionCache() {
    _sessionMemoryImageCache.clear();
  }

  static pw.Font _fontRegular = pw.Font.helvetica();
  static pw.Font _fontBold = pw.Font.helveticaBold();
  static bool _fontsLoaded = false;
  /// Charge toutes les images necessaires avec compression adaptative des assets statiques
  static Future<void> _loadImages() async {
    if (_imagesLoaded) return;

    Set<String>? manifestAssets;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      manifestAssets = manifest.listAssets().toSet();
    } catch (_) {}

    Future<pw.MemoryImage?> tryLoad(
      String asset, {
      int targetWidth = 500,
      int targetQuality = 70,
    }) async {
      try {
        if (manifestAssets != null && !manifestAssets.contains(asset)) {
          return null;
        }
        final data = await rootBundle.load(asset);
        final bytes = data.buffer.asUint8List();
        if (bytes.isEmpty) return null;

        try {
          final tempDir = await getTemporaryDirectory();
          final cacheFile = File(
            '${tempDir.path}/asset_${asset.hashCode}_${targetWidth}_$targetQuality.jpg',
          );
          if (await cacheFile.exists()) {
            final cachedBytes = await cacheFile.readAsBytes();
            if (cachedBytes.isNotEmpty) return pw.MemoryImage(cachedBytes);
          }

          final tempAssetFile = File(
            '${tempDir.path}/raw_asset_${asset.hashCode}.png',
          );
          await tempAssetFile.writeAsBytes(bytes);

          final compressedBytes = await FlutterImageCompress.compressWithFile(
            tempAssetFile.absolute.path,
            minWidth: targetWidth,
            quality: targetQuality,
            format: CompressFormat.jpeg,
          ).timeout(const Duration(seconds: 10));

          if (compressedBytes != null && compressedBytes.isNotEmpty) {
            try {
              await cacheFile.writeAsBytes(compressedBytes);
            } catch (_) {}
            return pw.MemoryImage(compressedBytes);
          }
        } catch (_) {}

        return pw.MemoryImage(bytes);
      } catch (e) {
        if (kDebugMode) print('Image non trouvee: $asset');
        return null;
      }
    }

    Future<pw.MemoryImage?> tryLoadRaw(String asset) async {
      try {
        if (manifestAssets != null && !manifestAssets.contains(asset)) {
          return null;
        }
        final data = await rootBundle.load(asset);
        final bytes = data.buffer.asUint8List();
        if (bytes.isEmpty) return null;
        return pw.MemoryImage(bytes);
      } catch (e) {
        if (kDebugMode) print('Image non trouvee: $asset');
        return null;
      }
    }

    // Polices et filigranes/logos PNG avec transparence native (0 fond noir/gris)
    _watermarkImage = await tryLoadRaw('assets/images/filigranne_image.png');
    _watermarkWhiteImage = await tryLoadRaw('assets/images/filigranne_white.png');
    _logoKesImage = await tryLoadRaw('assets/images/logo.png');
    _firstPageFooterImage = await tryLoad(
      'assets/images/firstpage_footer.png',
      targetWidth: 600,
      targetQuality: 70,
    );
    _imgHabilitation = await tryLoad(
      'assets/images/image.png',
      targetWidth: 500,
      targetQuality: 70,
    );
    _imgAccesGauche = await tryLoad(
      'assets/images/image copy.png',
      targetWidth: 400,
      targetQuality: 70,
    );
    _imgAccesDroite1 = await tryLoad(
      'assets/images/image copy 2.png',
      targetWidth: 400,
      targetQuality: 70,
    );
    _imgAccesDroite2 = await tryLoad(
      'assets/images/image copy 3.png',
      targetWidth: 400,
      targetQuality: 70,
    );

    PdfCoverBuilder.logoKesImage = _logoKesImage;
    PdfSommaireBuilder.logoKesImage = _logoKesImage;
    PdfSommaireBuilder.watermarkImage = _watermarkImage;
    PdfFinalPageBuilder.watermarkWhiteImage = _watermarkWhiteImage;
    _imagesLoaded = true;
  }

  /// Charge les polices necessaires
  static Future<void> _loadFonts() async {
    if (_fontsLoaded) return;

    try {
      final regularData = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      _fontRegular = pw.Font.ttf(regularData);
      _fontBold = pw.Font.ttf(boldData);
      _propagateFonts();
    } catch (e) {
      if (kDebugMode) {
        print(
          '⚠️ Polices personnalisees non trouvees, utilisation des polices standard',
        );
      }
      _fontRegular = pw.Font.helvetica();
      _fontBold = pw.Font.helveticaBold();
      _propagateFonts();
    }

    _fontsLoaded = true;
  }

  /// Propage les polices à l'ensemble des 13 builders et à PdfReportStyles
  static void _propagateFonts() {
    PdfReportStyles.fontRegular = _fontRegular;
    PdfReportStyles.fontBold = _fontBold;
    PdfCoverBuilder.fontRegular = _fontRegular;
    PdfCoverBuilder.fontBold = _fontBold;
    PdfSommaireBuilder.fontRegular = _fontRegular;
    PdfSommaireBuilder.fontBold = _fontBold;
    PdfRegulatoryBuilder.fontRegular = _fontRegular;
    PdfRegulatoryBuilder.fontBold = _fontBold;
    PdfExecutiveSummaryBuilder.fontRegular = _fontRegular;
    PdfExecutiveSummaryBuilder.fontBold = _fontBold;
    PdfStatisticsBuilder.fontRegular = _fontRegular;
    PdfStatisticsBuilder.fontBold = _fontBold;
    PdfDescriptionBuilder.fontRegular = _fontRegular;
    PdfDescriptionBuilder.fontBold = _fontBold;
    PdfRenseignementsBuilder.fontRegular = _fontRegular;
    PdfRenseignementsBuilder.fontBold = _fontBold;
    PdfEquipementsSynthesisBuilder.fontRegular = _fontRegular;
    PdfEquipementsSynthesisBuilder.fontBold = _fontBold;
    PdfObservationsRecapBuilder.fontRegular = _fontRegular;
    PdfObservationsRecapBuilder.fontBold = _fontBold;
    PdfAuditInstallationsBuilder.fontRegular = _fontRegular;
    PdfAuditInstallationsBuilder.fontBold = _fontBold;
    PdfClassementFoudreBuilder.fontRegular = _fontRegular;
    PdfClassementFoudreBuilder.fontBold = _fontBold;
    PdfMesuresEssaisBuilder.fontRegular = _fontRegular;
    PdfMesuresEssaisBuilder.fontBold = _fontBold;
    PdfPhotosSchemasBuilder.fontRegular = _fontRegular;
    PdfPhotosSchemasBuilder.fontBold = _fontBold;
    PdfFinalPageBuilder.fontRegular = _fontRegular;
    PdfFinalPageBuilder.fontBold = _fontBold;
  }

  // ──────────────────────────────────────────────────────────────
  //  THEMES DE PAGE (Couverture et Interieures)
  // ──────────────────────────────────────────────────────────────

  /// Thème couverture (footer firstPage - Filigrane KES avec opacité plus soutenue)
  static pw.PageTheme _buildCoverPageTheme() {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: _fontRegular, bold: _fontBold),
      margin: pw.EdgeInsets.only(
        left: kLeftMargin,
        top: kTopMargin,
        right: kRightMargin,
        bottom: kBottomMargin + 40,
      ),
      buildBackground: (ctx) => _buildCoverWatermarkBackground(pageFormat: ctx.page.pageFormat),
      buildForeground: (ctx) =>
          _buildFooterAbsolute(isFirstPage: true, ctx: ctx),
    );
  }

  /// Thème pages intérieures (footer otherPage)
  static pw.PageTheme _buildInnerPageTheme({
    int pageOffset = 0,
    int? overrideTotalPages,
    bool showWatermark = true,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) {
    return pw.PageTheme(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(base: _fontRegular, bold: _fontBold),
      margin: pw.EdgeInsets.only(
        left: kLeftMargin,
        top: kTopMargin,
        right: kRightMargin,
        bottom: kBottomMargin + 4,
      ),
      buildBackground: (ctx) =>
          showWatermark ? _buildWatermarkBackground(pageFormat: ctx.page.pageFormat) : pw.SizedBox(),
      buildForeground: (ctx) => _buildFooterAbsolute(
        isFirstPage: false,
        ctx: ctx,
        pageOffset: pageOffset,
        overrideTotalPages: overrideTotalPages,
      ),
    );
  }

  // Filigrane seul dans background des pages intérieures
  static pw.Widget _buildWatermarkBackground({PdfPageFormat? pageFormat}) {
    return PdfReportStyles.buildWatermarkBackground(_watermarkImage, pageFormat: pageFormat);
  }

  // Filigrane spécifique page de garde (opacité 0.30, centré sur le texte de couverture)
  static pw.Widget _buildCoverWatermarkBackground({PdfPageFormat? pageFormat}) {
    return PdfReportStyles.buildCoverWatermarkBackground(_watermarkImage, pageFormat: pageFormat);
  }

  // Footer bord à bord physique vectoriel natif
  static pw.Widget _buildFooterAbsolute({
    required bool isFirstPage,
    required pw.Context ctx,
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
            fontRegular: _fontRegular,
            fontBold: _fontBold,
          )
        : PdfFooterBuilder.buildOtherPageFooter(
            ctx,
            pageWidth: pageWidth,
            pageOffset: pageOffset,
            overrideTotalPages: overrideTotalPages,
            fontRegular: _fontRegular,
            fontBold: _fontBold,
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

  // ──────────────────────────────────────────────────────────────
  //  EN-TETE DE PAGE (format multi-lignes droite)
  static DateTime? _currentReportDate;

  static void setCurrentReportDate(DateTime? date) {
    _currentReportDate = date;
  }

  static pw.Widget _buildPageHeaderWidget({
    String? nomClient,
    String? nomSite,
    String? numeroRapport,
    String? titreRapport,
    DateTime? dateRapport,
  }) {
    final effectiveDate = dateRapport ?? _currentReportDate ?? DateTime.now();
    final dateGeneration = _formatDate(effectiveDate);
    final titre =
        titreRapport ??
        'VERIFICATION PERIODIQUE REGLEMENTAIRE DES INSTALLATIONS ELECTRIQUES';
    final rapportNum = numeroRapport ?? 'KES/IP/VE/${effectiveDate.year}/001';

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
          if (_logoKesImage != null)
            pw.Image(
              _logoKesImage!,
              width: 55,
              height: 28,
              fit: pw.BoxFit.contain,
            )
          else
            pw.Text(
              'KES',
              style: pw.TextStyle(
                font: _fontBold,
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
                '\u00A9 KES INSPECTIONS & PROJECTS',
                style: pw.TextStyle(
                  font: _fontBold,
                  fontSize: 6,
                  color: headerColor,
                ),
                textAlign: pw.TextAlign.right,
              ),
              if (nomSite != null && nomSite.isNotEmpty)
                pw.Text(
                  nomSite,
                  style: pw.TextStyle(
                    font: _fontRegular,
                    fontSize: 6,
                    color: darkGrey,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              pw.Text(
                titre,
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: 5.5,
                  color: darkGrey,
                ),
                textAlign: pw.TextAlign.right,
              ),
              pw.Text(
                'Rapport n\u00B0 : $rapportNum',
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: 5.5,
                  color: darkGrey,
                ),
                textAlign: pw.TextAlign.right,
              ),
              pw.Text(
                'Date du : $dateGeneration',
                style: pw.TextStyle(
                  font: _fontRegular,
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
  //  PAGE DE COUVERTURE
  // ──────────────────────────────────────────────────────────────


  static Future<void> _preloadCoverImages(
    Mission mission, {
    required bool saveFilesToDisk,
  }) => PdfCoverBuilder.preloadCoverImages(mission, saveFilesToDisk: saveFilesToDisk);

  static pw.Widget _buildCoverPage(
    Mission mission,
    RenseignementsGeneraux? rg,
    pw.Context ctx, {
    String? subTitleOverride,
    String? numeroRapport,
  }) => PdfCoverBuilder.buildCoverPage(
    mission,
    rg,
    ctx,
    subTitleOverride: subTitleOverride,
    numeroRapport: numeroRapport,
  );


  static List<SommaireEntry> getSommaireEntriesForTesting({
    Mission? mission,
    AuditInstallationsElectriques? audit,
    MesuresEssais? mesures,
  }) => PdfSommaireBuilder.getSommaireEntriesForTesting(
    mission: mission,
    audit: audit,
    mesures: mesures,
  );

  static List<SommaireEntry> _collectSommaireEntries({
    required Mission mission,
    required RenseignementsGeneraux? rg,
    required DescriptionInstallations? desc,
    required AuditInstallationsElectriques? audit,
    required MesuresEssais? mesures,
    required List<Foudre> foudres,
  }) => PdfSommaireBuilder.collectSommaireEntries(
    mission: mission,
    rg: rg,
    desc: desc,
    audit: audit,
    mesures: mesures,
    foudres: foudres,
  );

  static void _addSommairePages(
    pw.Document pdf,
    List<SommaireEntry> entries,
    Map<String, int> trackedPages, {
    String? nomClient,
    String? nomSite,
    String? numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
  }) => PdfSommaireBuilder.addSommairePages(
    pdf,
    entries,
    trackedPages,
    nomClient: nomClient,
    nomSite: nomSite,
    numeroRapport: numeroRapport,
    pageOffset: pageOffset,
    overrideTotalPages: overrideTotalPages,
    fontRegular: _fontRegular,
    fontBold: _fontBold,
    logoKesImage: _logoKesImage,
    watermarkImage: _watermarkImage,
  );

  static pw.Widget _buildNormesTable() =>
      PdfRegulatoryBuilder.buildNormesTable(fontBold: _fontBold, fontRegular: _fontRegular);

  static pw.Widget _buildMaterielTable() =>
      PdfRegulatoryBuilder.buildMaterielTable(fontBold: _fontBold, fontRegular: _fontRegular);

  static pw.Widget _buildPerimetreTable(
    Mission mission,
    RenseignementsGeneraux? rg, {
    JSA? jsa,
  }) => PdfRegulatoryBuilder.buildPerimetreTable(
    mission,
    rg,
    jsa: jsa,
    fontBold: _fontBold,
    fontRegular: _fontRegular,
  );

  static List<pw.Widget> _buildResumeExecutif(
    Mission mission,
    Map<String, int> trackedPages,
    String numeroRapportDoc, {
    ExecutiveSummaryData? summaryData,
    int offset = 0,
  }) => PdfExecutiveSummaryBuilder.buildResumeExecutif(
    mission,
    trackedPages,
    numeroRapportDoc,
    summaryData: summaryData,
    offset: offset,
  );

  static List<pw.Widget> _buildAnalyseStatistique(
    Mission mission,
    Map<String, int> trackedPages,
    String numeroRapportDoc, {
    int offset = 0,
  }) => PdfStatisticsBuilder.buildAnalyseStatistique(
    mission,
    trackedPages,
    numeroRapportDoc,
    offset: offset,
  );



  // ────────────────────────────────────────────────────────────
  //  RENSEIGNEMENTS GÉNÉRAUX & DESCRIPTION DES INSTALLATIONS
  // ────────────────────────────────────────────────────────────
  static pw.Widget _buildRenseignementsGeneraux(
    Mission mission,
    RenseignementsGeneraux? rg,
    Map<String, int> trackedPages, {
    int offset = 0,
  }) => PdfRenseignementsBuilder.buildRenseignementsGeneraux(
    mission,
    rg,
    trackedPages,
    offset: offset,
    fontBold: _fontBold,
    fontRegular: _fontRegular,
    pageHeaderBuilder: _buildPageHeaderWidget,
  );

  static List<String> collectRiskZonesAndLocauxForTesting(
    AuditInstallationsElectriques? audit,
  ) => PdfDescriptionBuilder.collectRiskZonesAndLocauxForTesting(audit);

  static List<pw.Widget> _buildDescriptionInstallationsMulti(
    DescriptionInstallations? desc,
    AuditInstallationsElectriques? audit,
    Map<String, int> trackedPages, {
    int offset = 0,
  }) => PdfDescriptionBuilder.buildDescriptionInstallationsMulti(
    desc,
    audit,
    trackedPages,
    offset: offset,
  );


  @visibleForTesting
  static PdfLocationInfo resolveLocationForTesting(
    AuditInstallationsElectriques? audit, {
    String? localisationStr,
    String? coffretStr,
  }) {
    return _resolveLocation(audit, localisationStr: localisationStr, coffretStr: coffretStr);
  }

  @visibleForTesting
  static List<PdfObsRecap> collectObservationsMTForTesting(
    AuditInstallationsElectriques audit,
  ) {
    return _collectObservationsMT(audit);
  }

  @visibleForTesting
  static List<PdfObsRecap> collectObservationsBTForTesting(
    AuditInstallationsElectriques audit,
  ) {
    return _collectObservationsBT(audit);
  }

  @visibleForTesting
  static PdfObsRecap createObsRecapForTesting({
    String zoneName = '',
    String localName = '',
    String localisation = '',
    required String coffret,
    required String observation,
    required String refNorm,
    required String priorite,
    String? repere,
  }) =>
      PdfObservationsRecapBuilder.createObsRecapForTesting(
        zoneName: zoneName,
        localName: localName,
        localisation: localisation,
        coffret: coffret,
        observation: observation,
        refNorm: refNorm,
        priorite: priorite,
        repere: repere,
      );

  @visibleForTesting
  static List<PdfObsZoneGroup> groupByZoneLocalEquipForTesting(
    List<PdfObsRecap> obs,
  ) =>
      PdfObservationsRecapBuilder.groupByZoneLocalEquipForTesting(obs);

  @visibleForTesting
  static List<pw.Widget> buildObsRecapTableUnifieForTesting(
    List<PdfObsRecap> obs,
  ) =>
      PdfObservationsRecapBuilder.buildObsRecapTableUnifieForTesting(obs);

  @visibleForTesting
  static List<PdfParafoudreEquipementRow> collectParafoudreRowsForTest(
    AuditInstallationsElectriques? audit,
  ) =>
      PdfClassementFoudreBuilder.collectParafoudreRows(audit);

  @visibleForTesting
  static String getFormattedPhotoLabelForTest(
    List<String> photoPaths,
    Map<String, int>? photoRegistry,
  ) =>
      PdfClassementFoudreBuilder.getFormattedPhotoLabel(photoPaths, photoRegistry);

  @visibleForTesting
  static String formatPhotoNumbersForTest(List<int> numbers) =>
      PdfAuditInstallationsBuilder.formatPhotoNumbers(numbers);

  @visibleForTesting
  static Map<String, int> buildPhotoNumberRegistryForTest(
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
  ) =>
      PdfAuditInstallationsBuilder.buildPhotoNumberRegistry(audit, description);

  static PdfLocationInfo _resolveLocation(
    AuditInstallationsElectriques? audit, {
    String? localisationStr,
    String? coffretStr,
  }) =>
      PdfObservationsRecapBuilder.resolveLocation(
        audit,
        localisationStr: localisationStr,
        coffretStr: coffretStr,
      );

  static List<PdfObsRecap> _collectObservationsMT(AuditInstallationsElectriques audit) =>
      PdfObservationsRecapBuilder.collectObservationsMT(audit);

  static List<PdfObsRecap> _collectObservationsBT(AuditInstallationsElectriques audit) =>
      PdfObservationsRecapBuilder.collectObservationsBT(audit);

  static List<PdfObsZoneGroup> _groupByZoneLocalEquip(List<PdfObsRecap> obs) =>
      PdfObservationsRecapBuilder.groupByZoneLocalEquip(obs);

  static List<pw.Widget> _buildObsRecapTableUnifie(List<PdfObsRecap> obs) =>
      PdfObservationsRecapBuilder.buildObsRecapTableUnifie(obs);

  static pw.Widget _subSectionBar(String title) =>
      PdfAuditInstallationsBuilder.subSectionBar(title);

  static Map<String, int> _buildPhotoNumberRegistry(
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
  ) =>
      PdfAuditInstallationsBuilder.buildPhotoNumberRegistry(audit, description);

  static List<pw.Widget> _buildLocalMT(
    MoyenneTensionLocal local,
    Map<String, int> trackedPages, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
    bool saveFilesToDisk = true,
    Map<String, int>? photoRegistry,
    String? missionId,
  }) =>
      PdfAuditInstallationsBuilder.buildLocalMT(
        local,
        trackedPages,
        photoCache: photoCache,
        saveFilesToDisk: saveFilesToDisk,
        photoRegistry: photoRegistry,
        missionId: missionId,
      );

  static List<pw.Widget> _buildZone(
    String zoneName,
    List<ObservationLibre> obs,
    Map<String, int> trackedPages, {
    Map<String, int>? photoRegistry,
    String? missionId,
  }) =>
      PdfAuditInstallationsBuilder.buildZone(
        zoneName,
        obs,
        trackedPages,
        photoRegistry: photoRegistry,
        missionId: missionId,
      );

  static List<pw.Widget> _buildCoffret(
    CoffretArmoire coffret,
    Map<String, int> trackedPages,
    String parentName, {
    String? missionId,
    Map<dynamic, pw.MemoryImage?>? photoCache,
    Map<String, int>? photoRegistry,
  }) =>
      PdfAuditInstallationsBuilder.buildCoffret(
        coffret,
        trackedPages,
        parentName,
        missionId: missionId,
        photoCache: photoCache,
        photoRegistry: photoRegistry,
      );

  static List<pw.Widget> _buildLocalBT(
    BasseTensionLocal local,
    Map<String, int> trackedPages, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
    Map<String, int>? photoRegistry,
    String? missionId,
  }) =>
      PdfAuditInstallationsBuilder.buildLocalBT(
        local,
        trackedPages,
        photoCache: photoCache,
        photoRegistry: photoRegistry,
        missionId: missionId,
      );

  static pw.Widget _buildIntervenantsEtResponsabilitesPage(
    JSA? jsa,
    RenseignementsGeneraux? rg,
    dynamic currentUser,
    Map<String, int> trackedPages,
    int pageOffset, {
    DateTime? reportGenerationDate,
    Mission? mission,
    String? dateIntervention,
  }) =>
      PdfCoverBuilder.buildIntervenantsEtResponsabilitesPage(
        jsa,
        rg,
        currentUser,
        trackedPages,
        pageOffset,
        reportGenerationDate: reportGenerationDate,
        mission: mission,
        dateIntervention: dateIntervention,
      );

  static List<pw.Widget> _buildClassementEmplacementsMulti(
    List<ClassementEmplacement> emplacements,
    List<ClassementZone> zonesClassement,
    Map<String, int> trackedPages, {
    int offset = 0,
    AuditInstallationsElectriques? audit,
  }) =>
      PdfClassementFoudreBuilder.buildClassementEmplacementsMulti(
        emplacements,
        zonesClassement,
        trackedPages,
        offset: offset,
        audit: audit,
      );

  static List<pw.Widget> _buildFoudre(
    AuditInstallationsElectriques? audit,
    List<Foudre> foudres,
    Map<String, int> trackedPages, {
    bool afficherTableauFoudre = false,
    int offset = 0,
    DescriptionInstallations? desc,
    Map<String, int>? photoRegistry,
    pw.Widget? headerWidget,
  }) =>
      PdfClassementFoudreBuilder.buildFoudre(
        audit,
        foudres,
        trackedPages,
        afficherTableauFoudre: afficherTableauFoudre,
        offset: offset,
        desc: desc,
        photoRegistry: photoRegistry,
        headerWidget: headerWidget,
      );

  static Future<void> _addMesuresEssaisPages(
    pw.Document pdf,
    MesuresEssais mesures,
    Map<String, int> trackedPages, {
    int pageOffset = 0,
    int? overrideTotalPages,
    DescriptionInstallations? desc,
    bool saveFilesToDisk = true,
    AuditInstallationsElectriques? audit,
    String? nomSite,
    String? numeroRapport,
  }) =>
      PdfMesuresEssaisBuilder.addMesuresEssaisPages(
        pdf,
        mesures,
        trackedPages,
        pageOffset: pageOffset,
        overrideTotalPages: overrideTotalPages,
        desc: desc,
        saveFilesToDisk: saveFilesToDisk,
        audit: audit,
        nomSite: nomSite,
        numeroRapport: numeroRapport,
        innerPageThemeBuilder: _buildInnerPageTheme,
        pageHeaderBuilder: _buildPageHeaderWidget,
        imageLoader: _loadAndOptimizeImage,
      );

  static pw.Widget _buildSignaturePage(
    RenseignementsGeneraux? rg,
    String? nomInspecteur, [
    Map<String, int>? trackedPages,
    int offset = 0,
  ]) {
    final dateGen = DateTime.now();
    final dateStr = _formatDate(dateGen);

    final content = pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'LA DIRECTION',
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: headerColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Patrick ESSAME ESSAME',
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: headerColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 36),
          pw.Text(
            'Fait à Douala le $dateStr',
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 13,
              color: headerColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: 180,
            height: 1,
            color: PdfColors.grey500,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Signature et cachet',
            style: pw.TextStyle(
              font: _fontRegular,
              fontSize: 8.5,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    if (trackedPages != null) {
      return PageTracker(
        key: 'signature_rapport',
        registry: trackedPages,
        offset: offset,
        child: content,
      );
    }
    return content;
  }



  // ────────────────────────────────────────────────────────────
  //  SYNTHÈSE DES ÉQUIPEMENTS
  // ────────────────────────────────────────────────────────────
  static List<PdfEquipementItem> _collectEquipementsMT(
    AuditInstallationsElectriques? audit,
  ) => PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);

  static List<PdfEquipementItem> _collectEquipementsBT(
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? desc,
  ) => PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, desc);

  static List<PdfUnknownSourceItem> _collectEquipementsUnknownSource(
    AuditInstallationsElectriques? audit,
  ) => PdfEquipementsSynthesisBuilder.collectEquipementsUnknownSource(audit);

  static List<pw.Widget> _buildUnknownSourcesTable(
    List<PdfUnknownSourceItem> items, {
    int startNumber = 1,
    bool showTableHeader = true,
  }) => PdfEquipementsSynthesisBuilder.buildUnknownSourcesTable(
    items,
    startNumber: startNumber,
    showTableHeader: showTableHeader,
  );

  static List<pw.Widget> _buildEquipementsTable(
    List<PdfEquipementItem> items, {
    int startNumber = 1,
    bool showTableHeader = true,
    bool isMT = false,
  }) => PdfEquipementsSynthesisBuilder.buildEquipementsTable(
    items,
    startNumber: startNumber,
    showTableHeader: showTableHeader,
    isMT: isMT,
  );

  @visibleForTesting
  static List<PdfEquipementItem> getEquipementsBTForTesting(
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? desc,
  ) => PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, desc);

  @visibleForTesting
  static pw.Widget buildEquipementsTableForTesting(
    List<PdfEquipementItem> items, {
    bool isMT = false,
  }) => PdfEquipementsSynthesisBuilder.buildEquipementsTableForTesting(items, isMT: isMT);

  @visibleForTesting
  static void initFontsForTesting() {
    try {
      _fontRegular = pw.Font.helvetica();
      _fontBold = pw.Font.helveticaBold();
      PdfCoverBuilder.fontRegular = _fontRegular;
      PdfCoverBuilder.fontBold = _fontBold;
      PdfSommaireBuilder.fontRegular = _fontRegular;
      PdfSommaireBuilder.fontBold = _fontBold;
      PdfRegulatoryBuilder.fontRegular = _fontRegular;
      PdfRegulatoryBuilder.fontBold = _fontBold;
      PdfExecutiveSummaryBuilder.fontRegular = _fontRegular;
      PdfExecutiveSummaryBuilder.fontBold = _fontBold;
      PdfStatisticsBuilder.fontRegular = _fontRegular;
      PdfStatisticsBuilder.fontBold = _fontBold;
      PdfRenseignementsBuilder.fontRegular = _fontRegular;
      PdfRenseignementsBuilder.fontBold = _fontBold;
      PdfDescriptionBuilder.fontRegular = _fontRegular;
      PdfDescriptionBuilder.fontBold = _fontBold;
      PdfEquipementsSynthesisBuilder.fontRegular = _fontRegular;
      PdfEquipementsSynthesisBuilder.fontBold = _fontBold;
      PdfObservationsRecapBuilder.fontRegular = _fontRegular;
      PdfObservationsRecapBuilder.fontBold = _fontBold;
      PdfAuditInstallationsBuilder.fontRegular = _fontRegular;
      PdfAuditInstallationsBuilder.fontBold = _fontBold;
      PdfClassementFoudreBuilder.fontRegular = _fontRegular;
      PdfClassementFoudreBuilder.fontBold = _fontBold;
      PdfMesuresEssaisBuilder.fontRegular = _fontRegular;
      PdfMesuresEssaisBuilder.fontBold = _fontBold;
      PdfPhotosSchemasBuilder.fontRegular = _fontRegular;
      PdfPhotosSchemasBuilder.fontBold = _fontBold;

    } catch (_) {
      // Déjà initialisé
    }
  }

  @visibleForTesting
  static List<PdfEquipementItem> collectEquipementsMTForTesting(
    AuditInstallationsElectriques? audit,
  ) => PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);
  static final pw.MemoryImage _placeholder1x1 = pw.MemoryImage(
    Uint8List.fromList(<int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]),
  );

  static Future<pw.MemoryImage?> loadAndOptimizeImage(
    String path, {
    PdfPhotoContext photoContext = PdfPhotoContext.equipmentObs,
    int? maxWidth,
    int? maxHeight,
    int? quality,
    bool saveFilesToDisk = true,
  }) => _loadAndOptimizeImage(
    path,
    photoContext: photoContext,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    quality: quality,
    saveFilesToDisk: saveFilesToDisk,
  );

  static Future<pw.MemoryImage?> _loadAndOptimizeImage(
    String path, {
    PdfPhotoContext photoContext = PdfPhotoContext.equipmentObs,
    int? maxWidth,
    int? maxHeight,
    int? quality,
    bool saveFilesToDisk = true,
  }) async {
    // ── Passe 1 (Pagination) : Utilisation du Placeholder 1x1 ultra-rapide (Zero-Load) ──
    if (!saveFilesToDisk) return _placeholder1x1;

    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    final targetWidth = maxWidth ?? photoContext.maxWidth;
    final targetHeight = maxHeight ?? photoContext.maxHeight;
    final targetQuality = quality ?? photoContext.quality;

    try {
      final resolvedPath = await AppImageUtils.resolvePathAsync(trimmed);
      if (resolvedPath == null) return null;
      final file = File(resolvedPath);
      if (!await file.exists()) return null;

      // ── Cache Session Mémoire (Déduplication d'instance XObject dans le PDF) ──
      final sessionCacheKey =
          '${resolvedPath}_${targetWidth}_${targetHeight}_$targetQuality';
      final inMemoryInstance = _sessionMemoryImageCache[sessionCacheKey];
      if (inMemoryInstance != null) {
        return inMemoryInstance;
      }

      pw.MemoryImage cacheAndReturn(Uint8List imgBytes) {
        final mem = pw.MemoryImage(imgBytes);
        _sessionMemoryImageCache[sessionCacheKey] = mem;
        return mem;
      }

      // ── Cache Disque de la Photo Optimisée (Évite les décodages Skia natifs répétés) ──
      final tempDir = await getTemporaryDirectory();
      final cacheFileName =
          'img_cache_${resolvedPath.hashCode}_${targetWidth}_${targetHeight}_$targetQuality.jpg';
      final cacheFile = File('${tempDir.path}/$cacheFileName');

      if (await cacheFile.exists()) {
        try {
          final cachedBytes = await cacheFile.readAsBytes();
          if (cachedBytes.isNotEmpty) {
            return cacheAndReturn(cachedBytes);
          }
        } catch (_) {}
      }

      // ── Tentative 1 : Compression via compressWithFile ──
      try {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          file.path,
          minWidth: targetWidth,
          minHeight: targetHeight,
          quality: targetQuality,
          format: CompressFormat.jpeg,
        ).timeout(const Duration(seconds: 10));

        if (compressedBytes != null && compressedBytes.isNotEmpty) {
          try {
            await cacheFile.writeAsBytes(compressedBytes);
          } catch (_) {}
          return cacheAndReturn(compressedBytes);
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ compressWithFile échoué pour $resolvedPath: $e. Passage à compressWithList...');
        }
      }

      // ── Tentative 2 : Fallback via compressWithList ──
      try {
        final rawBytes = await file.readAsBytes();
        if (rawBytes.isEmpty) return null;

        final compressedBytes = await FlutterImageCompress.compressWithList(
          rawBytes,
          minWidth: targetWidth,
          minHeight: targetHeight,
          quality: targetQuality,
          format: CompressFormat.jpeg,
        ).timeout(const Duration(seconds: 10));

        if (compressedBytes.isNotEmpty) {
          try {
            await cacheFile.writeAsBytes(compressedBytes);
          } catch (_) {}
          return cacheAndReturn(compressedBytes);
        }
        return cacheAndReturn(rawBytes);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ compressWithList échoué pour $resolvedPath: $e.');
        }
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return cacheAndReturn(bytes);
    } catch (_) {
      return null;
    }
  }


  static Future<PdfChunkSectionResult> _addPhotosSectionChunked(
    Mission mission,
    String missionId,
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
    Map<String, int> trackedPages, {
    String? nomSite,
    String? numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
    bool saveFilesToDisk = true,
  }) =>
      PdfPhotosSchemasBuilder.addPhotosSectionChunked(
        mission,
        missionId,
        audit,
        description,
        trackedPages,
        nomSite: nomSite,
        numeroRapport: numeroRapport,
        pageOffset: pageOffset,
        overrideTotalPages: overrideTotalPages,
        saveFilesToDisk: saveFilesToDisk,
        innerPageThemeBuilder: _buildInnerPageTheme,
        pageHeaderBuilder: _buildPageHeaderWidget,
        imageLoader: _loadAndOptimizeImage,
      );

  static void _addSchemaSection(
    pw.Document pdf,
    Mission mission,
    Map<String, int> trackedPages, {
    String? nomSite,
    String? numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
  }) =>
      PdfPhotosSchemasBuilder.addSchemaSection(
        pdf,
        mission,
        trackedPages,
        nomSite: nomSite,
        numeroRapport: numeroRapport,
        pageOffset: pageOffset,
        overrideTotalPages: overrideTotalPages,
        innerPageThemeBuilder: _buildInnerPageTheme,
        pageHeaderBuilder: _buildPageHeaderWidget,
      );


  // ──────────────────────────────────────────────────────────────
  //  UTILITAIRES PDF (cellules, lignes, titres...)
  // ──────────────────────────────────────────────────────────────


  static String _normalizeText(String text) {
    if (text.isEmpty) return text;
    text = text.replaceAll(RegExp(r'§\s*'), 'art ');

    const replacements = <String, String>{
      // Guillemets typographiques
      '«': '"', '»': '"', '“': '"', '”': '"',
      '‘': "'", '’': "'",
      // Tirets longs
      '—': '-', '–': '-', '…': '...',
      // Symboles mathématiques
      '≥': '>=', '≤': '<=', '≠': '!=',
      '±': '+/-', '∞': 'inf', '√': 'racine',
      '→': '->', '←': '<-', '↔': '<->',
      '∑': 'Somme', '∆': 'Delta', 'Φ': 'Phi',
      'θ': 'theta',
      // Symboles électriques
      'Ω': 'Ohm', 'μ': 'u', 'Σ': 'Sigma',
      // Exposants/indices
      '²': '2', '³': '3', '¹': '1',
      '₁': '1', '₂': '2', '₃': '3', '₄': '4',
      // Monétaires
      '€': 'EUR', '£': 'GBP', '¥': 'JPY',
    };

    var result = text;
    replacements.forEach((k, v) => result = result.replaceAll(k, v));
    return result;
  }

  static pw.Widget _sectionBox(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: headerColor,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Text(
        _normalizeText(title),
        style: pw.TextStyle(
          font: _fontBold,
          fontSize: fsH1,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static pw.Widget _subTitle(
    String title, {
    double topPadding = 4,
    double bottomPadding = 2,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: pw.Text(
        _normalizeText(title),
        style: pw.TextStyle(
          font: _fontBold,
          fontSize: fsH3,
          fontWeight: pw.FontWeight.bold,
          color: accentColor,
        ),
      ),
    );
  }

  static pw.Widget _bodyText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _normalizeText(text),
        style: pw.TextStyle(
          font: _fontRegular,
          fontSize: fsBody,
          color: darkGrey,
          lineSpacing: 2.0,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  static pw.Widget _bulletItem(String text) {
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
              _normalizeText(text),
              style: pw.TextStyle(
                font: _fontRegular,
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

  /// Formate les intitulés d'en-tête de colonnes contenant une unité de mesure entre parenthèses
  /// pour garantir que l'unité "(unité)" forme un bloc indivisible précédé d'un espace.
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

  static pw.Widget _cell(
    String text, {
    required bool isHeader,
    PdfColor? color,
    int colspan = 1,
    bool centered = false,
  }) {
    final displayText = isHeader ? formatHeaderUnit(text) : text;
    return pw.Container(
      color: color,
      alignment: centered ? pw.Alignment.center : pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        _normalizeText(displayText),
        style: pw.TextStyle(
          fontSize: isHeader ? fsSmall : fsSmall,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.white : darkGrey),
        ),
        textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: accentColor),
      children: headers
          .map((h) => _cell(h, isHeader: true, centered: true))
          .toList(),
    );
  }

  static pw.TableRow _tableDataRow(
    List<String> data, {
    required bool alt,
    bool centered = false,
  }) {
    return pw.TableRow(
      decoration: alt ? pw.BoxDecoration(color: tableRowAlt) : null,
      children: data
          .map((d) => _cell(d, isHeader: false, centered: centered))
          .toList(),
    );
  }

  static Future<PdfChunkSectionResult> _addSyntheseEquipementsSectionChunked(
    Mission mission,
    AuditInstallationsElectriques audit,
    DescriptionInstallations? desc,
    Map<String, int> trackedPages, {
    required String nomSite,
    required String numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
    bool saveFilesToDisk = true,
  }) async {
    final chunkFiles = <File>[];
    final tempDir = await getTemporaryDirectory();
    int currentOffset = pageOffset;

    // 1. Couverture Section Synthèse Récapitulative des Équipements
    final coverDoc = pw.Document(
      title: 'Synthese Equipements Cover - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    coverDoc.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
          showWatermark: true,
        ),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) => [
          pw.SizedBox(height: 295),
          pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 350, height: 2, color: accentColor),
                pw.SizedBox(height: 24),
                PageTracker(
                  key: 'liste_recap_equipements',
                  registry: trackedPages,
                  offset: currentOffset,
                  child: pw.Text(
                    'SYNTHÈSE RÉCAPITULATIVE DES ÉQUIPEMENTS',
                    style: pw.TextStyle(
                      font: _fontBold,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: headerColor,
                      letterSpacing: 1.0,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  mission.nomClient.toUpperCase(),
                  style: pw.TextStyle(
                    font: _fontRegular,
                    fontSize: 13,
                    color: accentColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 24),
                pw.Container(width: 350, height: 2, color: accentColor),
              ],
            ),
          ),
        ],
      ),
    );
    final coverBytes = await coverDoc.save();
    if (saveFilesToDisk) {
      final coverFile = File(
        '${tempDir.path}/pdf_chunk_equipements_cover_${mission.id}.pdf',
      );
      await coverFile.writeAsBytes(coverBytes);
      chunkFiles.add(coverFile);
    }
    currentOffset += coverDoc.document.pdfPageList.pages.length;

    // Helper interne pour effectuer le rendu par sous-lots (micro-chunking)
    Future<void> renderEquipementsSubBatches({
      required List<PdfEquipementItem> items,
      required String sectionKey,
      required String sectionTitle,
      required String chunkPrefix,
      bool isMT = false,
    }) async {
      if (items.isEmpty) {
        final emptyDoc = pw.Document(
          title: '$sectionTitle (Vide) - ${mission.nomClient}',
          author: 'KES INSPECTIONS AND PROJECTS',
          compress: saveFilesToDisk,
        );
        emptyDoc.addPage(
          pw.MultiPage(
            maxPages: 10000,
            pageTheme: _buildInnerPageTheme(
              pageOffset: currentOffset,
              overrideTotalPages: overrideTotalPages,
            ),
            header: (ctx) => _buildPageHeaderWidget(
              nomClient: mission.nomClient,
              nomSite: nomSite,
              numeroRapport: numeroRapport,
            ),
            build: (ctx) => [
              PageTracker(
                key: sectionKey,
                registry: trackedPages,
                offset: currentOffset,
                child: _subSectionBar(sectionTitle),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.4),
                ),
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  'Aucun équipement répertorié',
                  style: pw.TextStyle(
                    font: _fontRegular,
                    fontSize: fsSmall,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );
        final emptyBytes = await emptyDoc.save();
        if (saveFilesToDisk) {
          final emptyFile = File(
            '${tempDir.path}/pdf_chunk_${chunkPrefix}_empty_${mission.id}.pdf',
          );
          await emptyFile.writeAsBytes(emptyBytes);
          chunkFiles.add(emptyFile);
        }
        currentOffset += emptyDoc.document.pdfPageList.pages.length;
        return;
      }

      final doc = pw.Document(
        title: '$sectionTitle - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );

      doc.addPage(
        pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(
            pageOffset: currentOffset,
            overrideTotalPages: overrideTotalPages,
          ),
          header: (ctx) => _buildPageHeaderWidget(
            nomSite: nomSite,
            numeroRapport: numeroRapport,
          ),
          build: (ctx) => [
            PageTracker(
              key: sectionKey,
              registry: trackedPages,
              offset: currentOffset,
              child: _subSectionBar(sectionTitle),
            ),
            pw.SizedBox(height: 5),
            ..._buildEquipementsTable(
              items,
              startNumber: 1,
              showTableHeader: true,
              isMT: isMT,
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      if (saveFilesToDisk) {
        final file = File(
          '${tempDir.path}/pdf_chunk_${chunkPrefix}_${mission.id}.pdf',
        );
        await file.writeAsBytes(bytes);
        chunkFiles.add(file);
      }
      currentOffset += doc.document.pdfPageList.pages.length;
    }

    // 2. Équipements MT
    final equipementsMT = _collectEquipementsMT(audit);
    await renderEquipementsSubBatches(
      items: equipementsMT,
      sectionKey: 'liste_recap_equipements_mt',
      sectionTitle: '1. Équipements moyenne tension',
      chunkPrefix: 'equipements_mt',
      isMT: true,
    );

    // 3. Équipements BT
    final equipementsBT = _collectEquipementsBT(audit, desc);
    await renderEquipementsSubBatches(
      items: equipementsBT,
      sectionKey: 'liste_recap_equipements_bt',
      sectionTitle: '2. Équipements basse tension',
      chunkPrefix: 'equipements_bt',
      isMT: false,
    );

    // 4. Équipements aux sources d'alimentation non identifiées
    final unknownSources = _collectEquipementsUnknownSource(audit);
    if (unknownSources.isNotEmpty) {
      final sourcesUnknownDoc = pw.Document(
        title: 'Equipements Sources Inconnues - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );

      sourcesUnknownDoc.addPage(
        pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(
            pageOffset: currentOffset,
            overrideTotalPages: overrideTotalPages,
          ),
          header: (ctx) => _buildPageHeaderWidget(
            nomSite: nomSite,
            numeroRapport: numeroRapport,
          ),
          build: (ctx) => [
            PageTracker(
              key: 'liste_recap_equipements_sources_inconnues',
              registry: trackedPages,
              offset: currentOffset,
              child: _sectionBox('LISTE RÉCAPITULATIVE DES ÉQUIPEMENTS AUX SOURCES D’ALIMENTATION NON IDENTIFIÉES'),
            ),
            pw.SizedBox(height: 8),
            ..._buildUnknownSourcesTable(
              unknownSources,
              startNumber: 1,
              showTableHeader: true,
            ),
          ],
        ),
      );

      final sourcesBytes = await sourcesUnknownDoc.save();
      if (saveFilesToDisk) {
        final sourcesFile = File(
          '${tempDir.path}/pdf_chunk_equipements_sources_inconnues_${mission.id}.pdf',
        );
        await sourcesFile.writeAsBytes(sourcesBytes);
        chunkFiles.add(sourcesFile);
      }
      currentOffset += sourcesUnknownDoc.document.pdfPageList.pages.length;
    }

    return PdfChunkSectionResult(
      files: chunkFiles,
      totalPages: currentOffset - pageOffset,
    );
  }

  static Future<PdfChunkSectionResult> _addListeRecapitulativeSectionChunked(
    Mission mission,
    AuditInstallationsElectriques audit,
    Map<String, int> trackedPages, {
    required String nomSite,
    required String numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
    bool saveFilesToDisk = true,
  }) async {
    final chunkFiles = <File>[];
    final tempDir = await getTemporaryDirectory();
    int currentOffset = pageOffset;

    // 1. Page de Garde de la Synthèse Récapitulative
    final coverDoc = pw.Document(
      title: 'Recap Cover - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    coverDoc.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
          showWatermark: true,
        ),
        header: (ctx) => _buildPageHeaderWidget(
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) => [
          pw.SizedBox(height: 295),
          pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 350, height: 2, color: accentColor),
                pw.SizedBox(height: 24),
                PageTracker(
                  key: 'liste_recap',
                  registry: trackedPages,
                  offset: currentOffset,
                  child: pw.Text(
                    'SYNTHÈSE RÉCAPITULATIVE DES OBSERVATIONS',
                    style: pw.TextStyle(
                      font: _fontBold,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: headerColor,
                      letterSpacing: 1.0,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  mission.nomClient.toUpperCase(),
                  style: pw.TextStyle(
                    font: _fontRegular,
                    fontSize: 13,
                    color: accentColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 24),
                pw.Container(width: 350, height: 2, color: accentColor),
              ],
            ),
          ),
        ],
      ),
    );
    final coverBytes = await coverDoc.save();
    if (saveFilesToDisk) {
      final coverFile = File(
        '${tempDir.path}/pdf_chunk_recap_cover_${mission.id}.pdf',
      );
      await coverFile.writeAsBytes(coverBytes);
      chunkFiles.add(coverFile);
    }
    currentOffset += coverDoc.document.pdfPageList.pages.length;

    // 2. Moyenne Tension Récap (Découpé par tranche de 15 groupes de zones max)
    final obsMT = _collectObservationsMT(audit);
    final zoneGroupsMT = _groupByZoneLocalEquip(obsMT);

    if (zoneGroupsMT.isEmpty) {
      final mtDoc = pw.Document(
        title: 'Recap MT Empty - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      mtDoc.addPage(
        pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(
            pageOffset: currentOffset,
            overrideTotalPages: overrideTotalPages,
          ),
          header: (ctx) => _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSite,
            numeroRapport: numeroRapport,
          ),
          build: (ctx) => [
            PageTracker(
              key: 'liste_recap_mt',
              registry: trackedPages,
              offset: currentOffset,
              child: _subSectionBar('1. Moyenne tension'),
            ),
            pw.SizedBox(height: 5),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor, width: 0.4),
              ),
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Aucune observation',
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: fsSmall,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
      final mtBytes = await mtDoc.save();
      if (saveFilesToDisk) {
        final mtFile = File(
          '${tempDir.path}/pdf_chunk_recap_mt_empty_${mission.id}.pdf',
        );
        await mtFile.writeAsBytes(mtBytes);
        chunkFiles.add(mtFile);
      }
      currentOffset += mtDoc.document.pdfPageList.pages.length;
    } else {
      const int batchSize = 15;
      for (int i = 0; i < zoneGroupsMT.length; i += batchSize) {
        final subZoneGroups = zoneGroupsMT.sublist(
          i,
          (i + batchSize).clamp(0, zoneGroupsMT.length),
        );
        final obsSubList = subZoneGroups
            .expand((zg) => zg.localGroups)
            .expand((lg) => lg.equipGroups)
            .expand((eg) => eg.items)
            .toList();

        final mtDoc = pw.Document(
          title: 'Recap MT Chunk ${i ~/ batchSize} - ${mission.nomClient}',
          author: 'KES INSPECTIONS AND PROJECTS',
          compress: saveFilesToDisk,
        );
        final mtWidgets = <pw.Widget>[];
        if (i == 0) {
          mtWidgets.add(
            PageTracker(
              key: 'liste_recap_mt',
              registry: trackedPages,
              offset: currentOffset,
              child: _subSectionBar('1. Moyenne tension'),
            ),
          );
          mtWidgets.add(pw.SizedBox(height: 5));
        }
        mtWidgets.addAll(_buildObsRecapTableUnifie(obsSubList));

        mtDoc.addPage(
          pw.MultiPage(
            maxPages: 10000,
            pageTheme: _buildInnerPageTheme(
              pageOffset: currentOffset,
              overrideTotalPages: overrideTotalPages,
            ),
            header: (ctx) => _buildPageHeaderWidget(
              nomClient: mission.nomClient,
              nomSite: nomSite,
              numeroRapport: numeroRapport,
            ),
            build: (ctx) => mtWidgets,
          ),
        );
        final mtBytes = await mtDoc.save();
        if (saveFilesToDisk) {
          final mtFile = File(
            '${tempDir.path}/pdf_chunk_recap_mt_${i ~/ batchSize}_${mission.id}.pdf',
          );
          await mtFile.writeAsBytes(mtBytes);
          chunkFiles.add(mtFile);
        }
        currentOffset += mtDoc.document.pdfPageList.pages.length;
      }
    }

    // 3. Basse Tension Récap (Découpé par tranche de 15 groupes de zones max)
    final obsBT = _collectObservationsBT(audit);
    final zoneGroupsBT = _groupByZoneLocalEquip(obsBT);

    if (zoneGroupsBT.isEmpty) {
      final btDoc = pw.Document(
        title: 'Recap BT Empty - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      btDoc.addPage(
        pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(
            pageOffset: currentOffset,
            overrideTotalPages: overrideTotalPages,
          ),
          header: (ctx) => _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSite,
            numeroRapport: numeroRapport,
          ),
          build: (ctx) => [
            PageTracker(
              key: 'liste_recap_bt',
              registry: trackedPages,
              offset: currentOffset,
              child: _subSectionBar('2. Basse tension'),
            ),
            pw.SizedBox(height: 5),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor, width: 0.4),
              ),
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Aucune observation',
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: fsSmall,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
      final btBytes = await btDoc.save();
      if (saveFilesToDisk) {
        final btFile = File(
          '${tempDir.path}/pdf_chunk_recap_bt_empty_${mission.id}.pdf',
        );
        await btFile.writeAsBytes(btBytes);
        chunkFiles.add(btFile);
      }
      currentOffset += btDoc.document.pdfPageList.pages.length;
    } else {
      const int batchSize = 15;
      for (int i = 0; i < zoneGroupsBT.length; i += batchSize) {
        final subZoneGroups = zoneGroupsBT.sublist(
          i,
          (i + batchSize).clamp(0, zoneGroupsBT.length),
        );
        final obsSubList = subZoneGroups
            .expand((zg) => zg.localGroups)
            .expand((lg) => lg.equipGroups)
            .expand((eg) => eg.items)
            .toList();

        final btDoc = pw.Document(
          title: 'Recap BT Chunk ${i ~/ batchSize} - ${mission.nomClient}',
          author: 'KES INSPECTIONS AND PROJECTS',
          compress: saveFilesToDisk,
        );
        final btWidgets = <pw.Widget>[];
        if (i == 0) {
          btWidgets.add(
            PageTracker(
              key: 'liste_recap_bt',
              registry: trackedPages,
              offset: currentOffset,
              child: _subSectionBar('2. Basse tension'),
            ),
          );
          btWidgets.add(pw.SizedBox(height: 5));
        }
        btWidgets.addAll(_buildObsRecapTableUnifie(obsSubList));

        btDoc.addPage(
          pw.MultiPage(
            maxPages: 10000,
            pageTheme: _buildInnerPageTheme(
              pageOffset: currentOffset,
              overrideTotalPages: overrideTotalPages,
            ),
            header: (ctx) => _buildPageHeaderWidget(
              nomClient: mission.nomClient,
              nomSite: nomSite,
              numeroRapport: numeroRapport,
            ),
            build: (ctx) => btWidgets,
          ),
        );
        final btBytes = await btDoc.save();
        if (saveFilesToDisk) {
          final btFile = File(
            '${tempDir.path}/pdf_chunk_recap_bt_${i ~/ batchSize}_${mission.id}.pdf',
          );
          await btFile.writeAsBytes(btBytes);
          chunkFiles.add(btFile);
        }
        currentOffset += btDoc.document.pdfPageList.pages.length;
      }
    }

    return PdfChunkSectionResult(
      files: chunkFiles,
      totalPages: currentOffset - pageOffset,
    );
  }

  static Future<Map<dynamic, pw.MemoryImage?>> _preloadEquipmentPhotos(
    List<dynamic> items, {
    bool loadImages = true,
  }) async {
    final cache = <dynamic, pw.MemoryImage?>{};
    if (!loadImages) return cache;

    for (final item in items) {
      if (item is CoffretArmoire) {
        for (final src in [
          ...item.photosInternes,
          ...item.photos,
          ...item.photosExternes,
        ]) {
          final trimmed = src.trim();
          if (trimmed.isEmpty) continue;
          final img = await _loadAndOptimizeImage(
            trimmed,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: loadImages,
          );
          if (img != null) {
            cache[item] = img;
            break;
          }
        }
      } else if (item is Cellule) {
        final candidates = <String>[
          if (item.photo != null && item.photo!.trim().isNotEmpty)
            item.photo!.trim(),
          ...item.photos.map((p) => p.trim()).where((p) => p.isNotEmpty),
        ];
        for (final rawPath in candidates) {
          final img = await _loadAndOptimizeImage(
            rawPath,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: loadImages,
          );
          if (img != null) {
            cache[item] = img;
            break;
          }
        }
      } else if (item is TransformateurMTBT) {
        final candidates = <String>[
          if (item.photo != null && item.photo!.trim().isNotEmpty)
            item.photo!.trim(),
          ...item.photos.map((p) => p.trim()).where((p) => p.isNotEmpty),
        ];
        for (final rawPath in candidates) {
          final img = await _loadAndOptimizeImage(
            rawPath,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: loadImages,
          );
          if (img != null) {
            cache[item] = img;
            break;
          }
        }
      } else if (item is MoyenneTensionLocal) {
        for (final rawPath in item.photos.map((p) => p.trim()).where((p) => p.isNotEmpty)) {
          final img = await _loadAndOptimizeImage(
            rawPath,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: loadImages,
          );
          if (img != null) {
            cache[item] = img;
            break;
          }
        }
      } else if (item is BasseTensionLocal) {
        for (final rawPath in item.photos.map((p) => p.trim()).where((p) => p.isNotEmpty)) {
          final img = await _loadAndOptimizeImage(
            rawPath,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: loadImages,
          );
          if (img != null) {
            cache[item] = img;
            break;
          }
        }
      }
    }
    return cache;
  }

  static Future<Map<dynamic, pw.MemoryImage?>> _preloadCoffretsList(
    List<CoffretArmoire> coffrets, {
    List<Cellule>? cellules,
    List<TransformateurMTBT>? transformateurs,
    List<dynamic>? locaux,
    bool loadImages = true,
  }) async {
    final list = <dynamic>[
      ...coffrets,
      ...?cellules,
      ...?transformateurs,
      ...?locaux,
    ];
    return _preloadEquipmentPhotos(list, loadImages: loadImages);
  }

  static Future<Map<dynamic, pw.MemoryImage?>> _preloadZoneMTCoffrets(
    MoyenneTensionZone zone, {
    bool loadImages = true,
  }) async {
    final list = <dynamic>[...zone.coffrets];
    for (final local in zone.locaux) {
      list.addAll(local.coffrets);
      list.addAll(local.cellules);
      list.addAll(local.transformateurs);
    }
    return _preloadEquipmentPhotos(list, loadImages: loadImages);
  }

  static Future<Map<dynamic, pw.MemoryImage?>> _preloadZoneBTCoffrets(
    BasseTensionZone zone, {
    bool loadImages = true,
  }) async {
    final coffrets = <CoffretArmoire>[...zone.coffretsDirects];
    for (final local in zone.locaux) {
      coffrets.addAll(local.coffrets);
    }
    return _preloadCoffretsList(coffrets, loadImages: loadImages);
  }

  static Future<PdfChunkSectionResult> _addAuditSectionChunked(
    Mission mission,
    AuditInstallationsElectriques audit,
    Map<String, int> trackedPages, {
    required String nomSite,
    required String numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
    bool saveFilesToDisk = true,
    DescriptionInstallations? description,
  }) async {
    final chunkFiles = <File>[];
    final tempDir = await getTemporaryDirectory();
    int currentOffset = pageOffset;
    final desc = description ?? HiveService.getDescriptionInstallationsByMissionId(mission.id);
    final photoRegistry = _buildPhotoNumberRegistry(audit, desc);

    final bool hasNoAuditContent =
        audit.moyenneTensionLocaux.isEmpty &&
        audit.moyenneTensionZones.isEmpty &&
        audit.basseTensionZones.isEmpty;

    // 1. Page de Garde / Titre de l'Audit
    final coverDoc = pw.Document(
      title: 'Audit Cover - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    coverDoc.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
          showWatermark: true,
        ),
        header: (ctx) => _buildPageHeaderWidget(
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) => [
          pw.SizedBox(height: 295),
          pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 350, height: 2, color: accentColor),
                pw.SizedBox(height: 24),
                PageTracker(
                  key: 'audit',
                  registry: trackedPages,
                  offset: currentOffset,
                  child: pw.Text(
                    'AUDIT DES INSTALLATIONS ELECTRIQUES',
                    style: pw.TextStyle(
                      font: _fontBold,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: headerColor,
                      letterSpacing: 1.0,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  mission.nomClient.toUpperCase(),
                  style: pw.TextStyle(
                    font: _fontRegular,
                    fontSize: 13,
                    color: accentColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 24),
                pw.Container(width: 350, height: 2, color: accentColor),
                if (hasNoAuditContent) ...[
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Aucune installation enregistrée dans cet audit.',
                    style: pw.TextStyle(
                      font: _fontRegular,
                      fontSize: 10,
                      color: darkGrey,
                      fontStyle: pw.FontStyle.italic,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    final coverBytes = await coverDoc.save();
    if (saveFilesToDisk) {
      final coverFile = File(
        '${tempDir.path}/pdf_chunk_audit_cover_${mission.id}.pdf',
      );
      await coverFile.writeAsBytes(coverBytes);
      chunkFiles.add(coverFile);
    }
    currentOffset += coverDoc.document.pdfPageList.pages.length;

    // 2. MT Locaux Directs (si présents, découpés par micro-lots de 5 locaux max)
    if (audit.moyenneTensionLocaux.isNotEmpty) {
      final mtCoffrets = <CoffretArmoire>[];
      final mtCellules = <Cellule>[];
      final mtTransfos = <TransformateurMTBT>[];
      final mtLocaux = <dynamic>[];
      for (final local in audit.moyenneTensionLocaux) {
        mtLocaux.add(local);
        mtCoffrets.addAll(local.coffrets);
        mtCellules.addAll(local.cellules);
        mtTransfos.addAll(local.transformateurs);
      }
      final mtPhotoCache = await _preloadCoffretsList(
        mtCoffrets,
        cellules: mtCellules,
        transformateurs: mtTransfos,
        locaux: mtLocaux,
        loadImages: saveFilesToDisk,
      );

      const int mtBatchSize = 5;
      final totalMtBatches = (audit.moyenneTensionLocaux.length / mtBatchSize).ceil();

      for (int b = 0; b < totalMtBatches; b++) {
        final startIdx = b * mtBatchSize;
        final endIdx = ((b + 1) * mtBatchSize).clamp(0, audit.moyenneTensionLocaux.length);
        final batchLocaux = audit.moyenneTensionLocaux.sublist(startIdx, endIdx);

        final mtDoc = pw.Document(
          title: 'Audit MT Directs Part ${b + 1}/$totalMtBatches - ${mission.nomClient}',
          author: 'KES INSPECTIONS AND PROJECTS',
          compress: saveFilesToDisk,
        );
        final widgets = <pw.Widget>[];
        if (b == 0) {
          widgets.add(
            PageTracker(
              key: 'audit_mt',
              registry: trackedPages,
              offset: currentOffset,
              child: _subSectionBar('MOYENNE TENSION — LOCAUX DIRECTS'),
            ),
          );
        }
        for (int i = 0; i < batchLocaux.length; i++) {
          if (i > 0 || b > 0) widgets.add(pw.NewPage());
          widgets.addAll(
            _buildLocalMT(
              batchLocaux[i],
              trackedPages,
              photoCache: mtPhotoCache,
              saveFilesToDisk: saveFilesToDisk,
              photoRegistry: photoRegistry,
              missionId: mission.id,
            ),
          );
        }
        mtDoc.addPage(
          pw.MultiPage(
            maxPages: 10000,
            pageTheme: _buildInnerPageTheme(
              pageOffset: currentOffset,
              overrideTotalPages: overrideTotalPages,
            ),
            header: (ctx) => _buildPageHeaderWidget(
              nomClient: mission.nomClient,
              nomSite: nomSite,
              numeroRapport: numeroRapport,
            ),
            build: (ctx) => _sanitizeChunkWidgets(widgets),
          ),
        );
        final mtBytes = await mtDoc.save();
        if (saveFilesToDisk) {
          final mtFile = File(
            '${tempDir.path}/pdf_chunk_audit_mt_p${b + 1}_${mission.id}.pdf',
          );
          await mtFile.writeAsBytes(mtBytes);
          chunkFiles.add(mtFile);
        }
        currentOffset += mtDoc.document.pdfPageList.pages.length;
      }
      mtPhotoCache.clear();
    }

    // 3. Zones MT (1 chunk autonome par Zone MT)
    for (var zIdx = 0; zIdx < audit.moyenneTensionZones.length; zIdx++) {
      final zone = audit.moyenneTensionZones[zIdx];
      final zonePhotoCache = await _preloadZoneMTCoffrets(
        zone,
        loadImages: saveFilesToDisk,
      );

      final zoneDoc = pw.Document(
        title: 'Audit Zone MT ${zone.nom} - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      final widgets = <pw.Widget>[];
      widgets.addAll(
        _buildZone(zone.nom, zone.observationsLibres, trackedPages, photoRegistry: photoRegistry, missionId: mission.id),
      );
      int elemIdx = 0;
      for (int i = 0; i < zone.locaux.length; i++) {
        if (elemIdx > 0) widgets.add(pw.NewPage());
        widgets.addAll(
          _buildLocalMT(
            zone.locaux[i],
            trackedPages,
            photoCache: zonePhotoCache,
            saveFilesToDisk: saveFilesToDisk,
            photoRegistry: photoRegistry,
            missionId: mission.id,
          ),
        );
        elemIdx++;
      }
      for (int i = 0; i < zone.coffrets.length; i++) {
        if (elemIdx > 0) widgets.add(pw.NewPage());
        widgets.addAll(
          _buildCoffret(
            zone.coffrets[i],
            trackedPages,
            zone.nom,
            missionId: mission.id,
            photoCache: zonePhotoCache,
            photoRegistry: photoRegistry,
          ),
        );
        elemIdx++;
      }
      zoneDoc.addPage(
        pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(
            pageOffset: currentOffset,
            overrideTotalPages: overrideTotalPages,
          ),
          header: (ctx) => _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSite,
            numeroRapport: numeroRapport,
          ),
          build: (ctx) => _sanitizeChunkWidgets(widgets),
        ),
      );
      final zoneBytes = await zoneDoc.save();
      if (saveFilesToDisk) {
        final zoneFile = File(
          '${tempDir.path}/pdf_chunk_audit_mt_z${zIdx}_${mission.id}.pdf',
        );
        await zoneFile.writeAsBytes(zoneBytes);
        chunkFiles.add(zoneFile);
      }
      currentOffset += zoneDoc.document.pdfPageList.pages.length;
      zonePhotoCache.clear();
    }

    // 4. Zones BT (1 chunk autonome par Zone BT)
    for (var zIdx = 0; zIdx < audit.basseTensionZones.length; zIdx++) {
      final zone = audit.basseTensionZones[zIdx];
      final zonePhotoCache = await _preloadZoneBTCoffrets(
        zone,
        loadImages: saveFilesToDisk,
      );

      final zoneDoc = pw.Document(
        title: 'Audit Zone BT ${zone.nom} - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      final widgets = <pw.Widget>[];
      widgets.addAll(
        _buildZone(zone.nom, zone.observationsLibres, trackedPages, photoRegistry: photoRegistry, missionId: mission.id),
      );
      int elemIdx = 0;
      for (int i = 0; i < zone.coffretsDirects.length; i++) {
        if (elemIdx > 0) widgets.add(pw.NewPage());
        widgets.addAll(
          _buildCoffret(
            zone.coffretsDirects[i],
            trackedPages,
            zone.nom,
            missionId: mission.id,
            photoCache: zonePhotoCache,
            photoRegistry: photoRegistry,
          ),
        );
        elemIdx++;
      }
      for (int i = 0; i < zone.locaux.length; i++) {
        if (elemIdx > 0) widgets.add(pw.NewPage());
        widgets.addAll(
          _buildLocalBT(
            zone.locaux[i],
            trackedPages,
            photoCache: zonePhotoCache,
            photoRegistry: photoRegistry,
            missionId: mission.id,
          ),
        );
        elemIdx++;
      }
      zoneDoc.addPage(
        pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(
            pageOffset: currentOffset,
            overrideTotalPages: overrideTotalPages,
          ),
          header: (ctx) => _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSite,
            numeroRapport: numeroRapport,
          ),
          build: (ctx) => _sanitizeChunkWidgets(widgets),
        ),
      );
      final zoneBytes = await zoneDoc.save();
      if (saveFilesToDisk) {
        final zoneFile = File(
          '${tempDir.path}/pdf_chunk_audit_bt_z${zIdx}_${mission.id}.pdf',
        );
        await zoneFile.writeAsBytes(zoneBytes);
        chunkFiles.add(zoneFile);
      }
      currentOffset += zoneDoc.document.pdfPageList.pages.length;
      zonePhotoCache.clear();
    }

    return PdfChunkSectionResult(
      files: chunkFiles,
      totalPages: currentOffset - pageOffset,
    );
  }

  static List<pw.Widget> _sanitizeChunkWidgets(List<pw.Widget> input) {
    final result = <pw.Widget>[];
    for (final w in input) {
      if (w is pw.NewPage) {
        if (result.isEmpty) continue;
        if (result.last is pw.NewPage) continue;
        if (result.last is pw.SizedBox) {
          result.removeLast();
          if (result.isNotEmpty && result.last is pw.NewPage) continue;
        }
        result.add(w);
      } else if (w is pw.SizedBox) {
        if (result.isEmpty || result.last is pw.NewPage) continue;
        result.add(w);
      } else {
        result.add(w);
      }
    }
    while (result.isNotEmpty && (result.last is pw.NewPage || result.last is pw.SizedBox)) {
      result.removeLast();
    }
    return result;
  }

  static Future<_GeneratedReportResult> _generateReportPass({
    required Mission mission,
    required String missionId,
    required AuditInstallationsElectriques? audit,
    required DescriptionInstallations? description,
    required dynamic classements,
    required dynamic classementsZones,
    required dynamic mesures,
    required dynamic foudres,
    required dynamic renseignements,
    required dynamic currentUser,
    required String nomSiteHeader,
    required String numeroRapportDoc,
    required Directory tempDir,
    int? overrideTotalPages,
    DateTime? generationDate,
    bool saveFilesToDisk = true,
    PdfProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final allChunkFiles = <File>[];
    final trackedPages = <String, int>{};
    final photoRegistry = _buildPhotoNumberRegistry(audit, description);

    await _preloadCoverImages(mission, saveFilesToDisk: saveFilesToDisk);

    final sommaireEntries = _collectSommaireEntries(
      mission: mission,
      rg: renseignements,
      desc: description,
      audit: audit,
      mesures: mesures,
      foudres: foudres,
    );

    // Pre-flight réel du Sub-chunk 1.1 pour mesurer sans estimation le nombre de pages initial
    final preflightP1_1 = pw.Document(
      title:
          'Couverture, Intervenants & Sommaire Preflight - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    final jsaPreflight = HiveService.getJSAByMissionId(mission.id);
    preflightP1_1.addPage(
      pw.Page(
        pageTheme: _buildCoverPageTheme(),
        build: (ctx) => _buildCoverPage(
          mission,
          renseignements,
          ctx,
          numeroRapport: numeroRapportDoc,
        ),
      ),
    );
    preflightP1_1.addPage(
      pw.Page(
        pageTheme: _buildInnerPageTheme(
          pageOffset: 0,
          overrideTotalPages: overrideTotalPages,
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeaderWidget(
              nomClient: mission.nomClient,
              nomSite: nomSiteHeader,
              numeroRapport: numeroRapportDoc,
            ),
            pw.SizedBox(height: 8),
            _buildIntervenantsEtResponsabilitesPage(
              jsaPreflight,
              renseignements,
              currentUser,
              trackedPages,
              0,
              reportGenerationDate: generationDate,
              mission: mission,
            ),
          ],
        ),
      ),
    );
    _addSommairePages(
      preflightP1_1,
      sommaireEntries,
      trackedPages,
      nomClient: mission.nomClient,
      nomSite: nomSiteHeader,
      numeroRapport: numeroRapportDoc,
      pageOffset: 0,
      overrideTotalPages: overrideTotalPages,
    );

    await preflightP1_1.save();
    final int subChunk11Pages =
        preflightP1_1.document.pdfPageList.pages.length;
    int currentOffset = subChunk11Pages;

    // ── Sub-chunk 1.2 : Objet, Périmètre & Mesures de sécurité ──
    if (saveFilesToDisk) {
      onProgress?.call(
        0.18,
        'Génération du périmètre et des mesures de sécurité...',
      );
    }
    await Future.delayed(Duration.zero);
    cancellationToken?.throwIfCancelled();
    final pdfP1_2 = pw.Document(
      title: 'Périmètre & Sécurité - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfP1_2.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
        ),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => [
          PageTracker(
            key: 'objet',
            registry: trackedPages,
            offset: currentOffset,
            child: _sectionBox('OBJET DE LA VÉRIFICATION'),
          ),
          pw.SizedBox(height: 10),
          _bodyText(
            'La mission a pour objet de déceler les non-conformités pouvant affecter la sécurité des personnes et des biens, et de s\'assurer du bon état de conservation des installations. '
            'Afin de présenter l\'état des lieux de l\'existant, les points sur lesquels les installations s\'écartent des normes et textes applicables, et de proposer des actions correctives.\n\n'
            'D\'une manière générale, la vérification a été étendue à l\'ensemble des installations électriques présentées et accessibles dans l\'établissement, depuis les sources jusqu\'aux points d\'utilisation.',
          ),
          pw.SizedBox(height: 10),
          _bodyText('Ainsi sont exclus du champ de la vérification\u00a0:'),
          _bulletItem(
            'Les dispositions administratives, organisationnelles et techniques relatives à l\'information et à la formation du personnel (prescriptions au personnel) lors de l\'exploitation courante, de travaux ou d\'interventions sur les installations, ainsi que les mesures de sécurité qui en découlent\u00a0;',
          ),
          _bulletItem(
            'Les dispositions administratives relatives aux documents à tenir à la disposition des autorités publiques\u00a0;',
          ),
          _bulletItem(
            'L\'examen des matériels électriques en présentation ou en démonstration et destinés à la vente\u00a0;',
          ),
          _bulletItem(
            'Les matériels stockés ou en réserve, ou signalés comme n\'étant plus mis en œuvre. Du fait que les installations sont examinées en tenant compte des contraintes d\'exploitation et de sécurité propres à chaque établissement et indiquées en début de vérification au personnel chargé de la vérification, celle-ci est limitée dans certains cas à l\'état apparent des installations.',
          ),
          pw.SizedBox(height: 12),
          PageTracker(
            key: 'objet_normes',
            registry: trackedPages,
            offset: currentOffset,
            child: _subTitle('1. Références normatives et réglementaires'),
          ),
          pw.SizedBox(height: 5),
          _buildNormesTable(),
          pw.SizedBox(height: 12),
          PageTracker(
            key: 'objet_materiel',
            registry: trackedPages,
            offset: currentOffset,
            child: _subTitle('2. Matériel utilisé'),
          ),
          pw.SizedBox(height: 5),
          _buildMaterielTable(),
          pw.NewPage(),
          PageTracker(
            key: 'perimetre',
            registry: trackedPages,
            offset: currentOffset,
            child: _sectionBox('PERIMETRE DE LA MISSION'),
          ),
          pw.SizedBox(height: 14),
          _buildPerimetreTable(mission, renseignements, jsa: jsaPreflight),
          pw.NewPage(),
          PageTracker(
            key: 'rappel',
            registry: trackedPages,
            offset: currentOffset,
            child: _sectionBox('RAPPEL DES RESPONSABILITÉS DE L\'EMPLOYEUR'),
          ),
          pw.SizedBox(height: 4),
          _bodyText(
            'KES INSPECTIONS AND PROJECTS a le plaisir de vous transmettre le présent rapport de vérification de vos installations électriques, établi à la suite des constats réalisés sur site.\n'
            'Ce document présente les observations effectuées par le vérificateur à partir des éléments et moyens mis à sa disposition.\n'
            'Il identifie les points de non-conformité constatés au regard des exigences réglementaires, et formule, le cas échéant, les recommandations techniques nécessaires à leur mise en conformité.',
          ),
          pw.SizedBox(height: 2),
          PageTracker(
            key: 'rappel_accompagnement',
            registry: trackedPages,
            offset: currentOffset,
            child: _subTitle('1. Responsabilité et accompagnement', topPadding: 4, bottomPadding: 2),
          ),
          _bodyText(
            'Dans le cadre de la mission, il appartient à l\'employeur de désigner une personne qualifiée et informée des installations, chargée d\'accompagner le vérificateur durant l\'intervention. '
            'Cette personne doit pouvoir faciliter l\'accès à l\'ensemble des locaux, appareillages et équipements à contrôler.\n'
            'L\'employeur reste responsable du bon fonctionnement, de la sécurité et de la disponibilité des installations tout au long de la vérification. '
            'Les informations et documents techniques fournis sous sa responsabilité doivent permettre la réalisation des contrôles dans de bonnes conditions.',
          ),
          pw.SizedBox(height: 2),
          PageTracker(
            key: 'rappel_conditions',
            registry: trackedPages,
            offset: currentOffset,
            child: _subTitle('2. Conditions de réalisation', topPadding: 4, bottomPadding: 2),
          ),
          _bodyText(
            'Afin d\'assurer le bon déroulement des opérations, l\'employeur doit\u00a0:',
          ),
          _bulletItem(
            'Veiller à ce que la vérification soit réalisée dans des conditions de sécurité optimales, en particulier lors des accès en zone électrique\u00a0;',
          ),
          _bulletItem(
            'Mettre en œuvre les procédures nécessaires aux mises hors tension permettant d\'effectuer les mesures et essais en toute sécurité\u00a0;',
          ),
          _bulletItem(
            'Garantir au vérificateur l\'accès à l\'ensemble des équipements à contrôler, sans risque de chute ou d\'incident.',
          ),
          pw.SizedBox(height: 2),
          _bodyText(
            'Si certaines vérifications n\'ont pu être effectuées (impossibilité d\'accès, absence d\'agents habilités, contraintes d\'exploitation, documentation manquante, etc.), '
            'KES INSPECTIONS AND PROJECTS en mentionnera la cause dans le rapport.\n'
            'Dans le cas des installations de moyenne ou haute tension, la mise hors tension et les manœuvres associées relèvent exclusivement de la responsabilité de l\'employeur ou de son représentant habilité.',
          ),
          pw.SizedBox(height: 2),
          PageTracker(
            key: 'rappel_complementaires',
            registry: trackedPages,
            offset: currentOffset,
            child: _subTitle('3. Vérifications complémentaires', topPadding: 4, bottomPadding: 2),
          ),
          _bodyText(
            'Lorsque des éléments du poste ou de l\'installation n\'ont pu être contrôlés lors de la visite initiale, une intervention complémentaire pourra être programmée à la demande de l\'employeur.\n'
            'Cette mission additionnelle fera alors l\'objet d\'une planification et d\'un rapport spécifique.',
          ),
          pw.SizedBox(height: 2),
          PageTracker(
            key: 'rappel_maintenance',
            registry: trackedPages,
            offset: currentOffset,
            child: _subTitle(
              '4. Surveillance et maintenance des installations électriques',
              topPadding: 4,
              bottomPadding: 2,
            ),
          ),
          _bodyText(
            'La vérification de conformité des installations électriques ne constitue qu\'un des éléments concourant à la sécurité des personnes et des biens. Conformément à la norme et aux textes réglementaires applicables, '
            'le chef d\'établissement doit mettre en place une organisation pour les opérations de surveillance et la maintenance des installations électriques. '
            'C\'est dans le cadre de ces opérations que les dispositions doivent être prises afin de remédier aux défectuosités constatées pendant la vérification ou celles qui peuvent se manifester après la vérification.',
          ),
          pw.SizedBox(height: 2),
          PageTracker(
            key: 'rappel_formation',
            registry: trackedPages,
            offset: currentOffset,
            child: _subTitle(
              '5. Formation du personnel intervenant sur les installations et à proximité',
              topPadding: 4,
              bottomPadding: 2,
            ),
          ),
          _bodyText(
            'Conformément aux dispositions réglementaires en vigueur, l\'employeur doit s\'assurer que le personnel appelé à intervenir sur ou à proximité des installations électriques dispose d\'une habilitation électrique adaptée au domaine de tension concerné '
            'et à la nature des opérations à réaliser.',
          ),
          pw.NewPage(),
          PageTracker(
            key: 'mesures_securite',
            registry: trackedPages,
            offset: currentOffset,
            child: _sectionBox('MESURES DE SÉCURITÉ AUTOUR DES INSTALLATIONS'),
          ),
          pw.SizedBox(height: 8),
          _bodyText('Suivant la réglementation applicable\u00a0:'),
          _bulletItem(
            'Article 5 \u2013 Arrêté 039/MTPS/IMT du 26 novembre 1984 fixant les mesures générales d\'hygiène et de sécurité sur les lieux de travail\u00a0;',
          ),
          _bulletItem(
            'NFC 18-510\u00a0: Opérations sur les ouvrages et installations électriques et dans un environnement électrique \u2013 Prévention du risque électrique.',
          ),
          pw.SizedBox(height: 5),
          _bodyText(
            'Le personnel doit avoir suivi avec succès une formation en habilitation électrique en fonction du domaine de tension.',
          ),
          pw.SizedBox(height: 5),
          if (_imgHabilitation != null)
            pw.Container(
              width: double.infinity,
              child: pw.Image(_imgHabilitation!, fit: pw.BoxFit.fitWidth),
            )
          else
            pw.SizedBox(),
          pw.SizedBox(height: 12),
          _bodyText(
            'Il est rappelé que des dispositions de sécurité particulières et parfaitement définies doivent être prises par le chef de l\'établissement '
            'pour toute intervention de maintenance, réglage, nettoyage sur ou à proximité des installations électriques.\n\n'
            'L\'accès aux locaux et armoires électriques doit être interdit aux personnes non autorisées.',
          ),
          pw.SizedBox(height: 8),
          if (_imgAccesGauche != null ||
              _imgAccesDroite1 != null ||
              _imgAccesDroite2 != null)
            pw.Center(
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (_imgAccesGauche != null)
                    pw.Container(
                      height: 85,
                      child: pw.Image(_imgAccesGauche!, fit: pw.BoxFit.contain),
                    ),
                  if (_imgAccesGauche != null &&
                      (_imgAccesDroite1 != null || _imgAccesDroite2 != null))
                    pw.SizedBox(width: 12),
                  if (_imgAccesDroite1 != null)
                    pw.Container(
                      height: 85,
                      child: pw.Image(
                        _imgAccesDroite1!,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  if (_imgAccesDroite1 != null && _imgAccesDroite2 != null)
                    pw.SizedBox(width: 12),
                  if (_imgAccesDroite2 != null)
                    pw.Container(
                      height: 85,
                      child: pw.Image(
                        _imgAccesDroite2!,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                ],
              ),
            ),
          pw.SizedBox(height: 12),
          _bodyText(
            'En effet, une installation, bien que déclarée conforme en phase d\'exploitation, peut lors d\'opérations, par exemple d\'entretien, '
            'nécessiter des précautions spéciales du fait de la présence à proximité de pièces nues sous tension '
            '(cas des locaux réservés aux électriciens et dans lesquels la réglementation n\'interdit pas la présence de pièces nues sous tension).',
          ),
          pw.SizedBox(height: 7),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PageTracker(
                key: 'mesures_technicien',
                registry: trackedPages,
                offset: currentOffset,
                child: _subTitle(
                  '1. Technicien en maintenance des installations',
                ),
              ),
              pw.SizedBox(height: 5),
              _bodyText(
                'Il est fortement recommandé à l\'employeur de faire participer les employés à des séances de formation sur les modules suivants\u00a0:',
              ),
              _bulletItem(
                'Connaissance des normes en électricité (NC 244 C15 00\u2026)\u00a0;',
              ),
              _bulletItem('Maintenance des installations électriques.'),
            ],
          ),
          pw.NewPage(),
          PageTracker(
            key: 'mesures_engagement',
            registry: trackedPages,
            offset: currentOffset,
            child: _sectionBox('ENGAGEMENT DE KES INSPECTIONS AND PROJECTS'),
          ),
          pw.SizedBox(height: 8),
          _bodyText(
            'KES INSPECTIONS AND PROJECTS s\'engage à réaliser ses vérifications dans le strict respect des normes et règlements applicables, '
            'avec le souci constant de la sécurité, de la fiabilité technique et de l\'impartialité des constats.',
          ),
        ],
      ),
    );
    final bytesP1_2 = await pdfP1_2.save();
    if (saveFilesToDisk) {
      final chunkP1_2 = File('${tempDir.path}/pdf_chunk_p1_2_$missionId.pdf');
      await chunkP1_2.writeAsBytes(bytesP1_2);
      allChunkFiles.add(chunkP1_2);
    }
    currentOffset += pdfP1_2.document.pdfPageList.pages.length;

    // ── Sub-chunk 1.3 : Résumé exécutif & Analyse statistique ──
    if (saveFilesToDisk) {
      onProgress?.call(
        0.28,
        'Génération du résumé exécutif et des statistiques...',
      );
    }
    await Future.delayed(Duration.zero);
    cancellationToken?.throwIfCancelled();

    // Génération 100% locale et déterministe du résumé exécutif (aucun appel réseau IA)
    final snapshot = ExecutiveSummarySnapshot.fromMission(missionId);
    final summaryData =
        MissionExecutiveSummaryService.buildDeterministicFallback(
          missionId,
          snapshot,
        );

    final pdfP1_3 = pw.Document(
      title: 'Résumé Exécutif & Stats - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfP1_3.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
        ),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => [
          ..._buildResumeExecutif(
            mission,
            trackedPages,
            numeroRapportDoc,
            summaryData: summaryData,
            offset: currentOffset,
          ),
          pw.NewPage(),
          ..._buildAnalyseStatistique(
            mission,
            trackedPages,
            numeroRapportDoc,
            offset: currentOffset,
          ),
        ],
      ),
    );
    final bytesP1_3 = await pdfP1_3.save();
    if (saveFilesToDisk) {
      final chunkP1_3 = File('${tempDir.path}/pdf_chunk_p1_3_$missionId.pdf');
      await chunkP1_3.writeAsBytes(bytesP1_3);
      allChunkFiles.add(chunkP1_3);
    }
    currentOffset += pdfP1_3.document.pdfPageList.pages.length;

    // ── Sub-chunk 1.4 : Renseignements généraux & Description des installations ──
    if (saveFilesToDisk) {
      onProgress?.call(
        0.38,
        'Génération de la description des installations...',
      );
    }
    await Future.delayed(Duration.zero);
    cancellationToken?.throwIfCancelled();
    final pdfP1_4 = pw.Document(
      title: 'Description Installations - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfP1_4.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
        ),
        build: (ctx) => [
          _buildRenseignementsGeneraux(
            mission,
            renseignements,
            trackedPages,
            offset: currentOffset,
          ),
        ],
      ),
    );
    pdfP1_4.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
          pageFormat: PdfPageFormat.a4.landscape,
        ),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => _buildDescriptionInstallationsMulti(
          description,
          audit,
          trackedPages,
          offset: currentOffset,
        ),
      ),
    );
    final bytesP1_4 = await pdfP1_4.save();
    if (saveFilesToDisk) {
      final chunkP1_4 = File('${tempDir.path}/pdf_chunk_p1_4_$missionId.pdf');
      await chunkP1_4.writeAsBytes(bytesP1_4);
      allChunkFiles.add(chunkP1_4);
    }
    currentOffset += pdfP1_4.document.pdfPageList.pages.length;

    // ── Section 6, 7 & 8 : Synthèse des Équipements, Synthèse des Observations et Audit par zone ──
    if (audit != null) {
      final double progressSynthese = saveFilesToDisk ? 0.45 : 0.15;
      onProgress?.call(progressSynthese, 'Génération de la synthèse des équipements...');
      await Future.delayed(Duration.zero);

      final equipementsResult = await _addSyntheseEquipementsSectionChunked(
        mission,
        audit,
        description,
        trackedPages,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
        pageOffset: currentOffset,
        overrideTotalPages: overrideTotalPages,
        saveFilesToDisk: saveFilesToDisk,
      );
      if (saveFilesToDisk) allChunkFiles.addAll(equipementsResult.files);
      currentOffset += equipementsResult.totalPages;

      final double progressRecap = saveFilesToDisk ? 0.48 : 0.22;
      onProgress?.call(progressRecap, 'Génération de la synthèse récapitulative des observations...');
      await Future.delayed(Duration.zero);

      final recapResult = await _addListeRecapitulativeSectionChunked(
        mission,
        audit,
        trackedPages,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
        pageOffset: currentOffset,
        overrideTotalPages: overrideTotalPages,
        saveFilesToDisk: saveFilesToDisk,
      );
      if (saveFilesToDisk) allChunkFiles.addAll(recapResult.files);
      currentOffset += recapResult.totalPages;

      final double progressAudit = saveFilesToDisk ? 0.60 : 0.30;
      onProgress?.call(progressAudit, 'Audit détaillé des zones MT et BT...');
      await Future.delayed(Duration.zero);

      final auditResult = await _addAuditSectionChunked(
        mission,
        audit,
        trackedPages,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
        pageOffset: currentOffset,
        overrideTotalPages: overrideTotalPages,
        saveFilesToDisk: saveFilesToDisk,
      );
      if (saveFilesToDisk) allChunkFiles.addAll(auditResult.files);
      currentOffset += auditResult.totalPages;
    }

    // ── Sub-chunk 2.1 : Classement, Foudre, Mesures & Essais, Signatures ──
    final double progressClassement = saveFilesToDisk ? 0.75 : 0.38;
    onProgress?.call(
      progressClassement,
      'Génération du classement, foudre et signatures...',
    );
    await Future.delayed(Duration.zero);
    // ── Sub-chunk 2.1a : Classement ──
    await Future.delayed(Duration.zero);
    cancellationToken?.throwIfCancelled();
    final pdfClassement = pw.Document(
      title: 'Classement - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfClassement.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
        ),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => _buildClassementEmplacementsMulti(
          classements,
          classementsZones,
          trackedPages,
          offset: currentOffset,
          audit: audit,
        ),
      ),
    );
    final bytesClassement = await pdfClassement.save();
    if (saveFilesToDisk) {
      final chunk = File('${tempDir.path}/pdf_chunk_classement_$missionId.pdf');
      await chunk.writeAsBytes(bytesClassement);
      allChunkFiles.add(chunk);
    }
    currentOffset += pdfClassement.document.pdfPageList.pages.length;

    // ── Sub-chunk 2.1b : Foudre ──
    await Future.delayed(Duration.zero);
    cancellationToken?.throwIfCancelled();
    final pdfFoudre = pw.Document(
      title: 'Foudre - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfFoudre.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
          pageFormat: PdfPageFormat.a4.landscape,
        ),
        build: (ctx) => _buildFoudre(
          audit,
          foudres,
          trackedPages,
          afficherTableauFoudre: mission.afficherTableauFoudre,
          offset: currentOffset,
          desc: description,
          photoRegistry: photoRegistry,
        ),
      ),
    );
    final bytesFoudre = await pdfFoudre.save();
    if (saveFilesToDisk) {
      final chunk = File('${tempDir.path}/pdf_chunk_foudre_$missionId.pdf');
      await chunk.writeAsBytes(bytesFoudre);
      allChunkFiles.add(chunk);
    }
    currentOffset += pdfFoudre.document.pdfPageList.pages.length;

    // ── Sub-chunk 2.1c : Mesures & Essais ──
    if (mesures != null) {
      await Future.delayed(Duration.zero);
      cancellationToken?.throwIfCancelled();
      final pdfMesures = pw.Document(
        title: 'Mesures & Essais - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      await _addMesuresEssaisPages(
        pdfMesures,
        mesures,
        trackedPages,
        pageOffset: currentOffset,
        overrideTotalPages: overrideTotalPages,
        desc: description,
        saveFilesToDisk: saveFilesToDisk,
        audit: audit,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
      );
      final bytesMesures = await pdfMesures.save();
      if (saveFilesToDisk) {
        final chunk = File('${tempDir.path}/pdf_chunk_mesures_$missionId.pdf');
        await chunk.writeAsBytes(bytesMesures);
        allChunkFiles.add(chunk);
      }
      currentOffset += pdfMesures.document.pdfPageList.pages.length;
    }

    // ── Sub-chunk 2.1d : Signatures ──
    await Future.delayed(Duration.zero);
    cancellationToken?.throwIfCancelled();
    final pdfSignatures = pw.Document(
      title: 'Signatures - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfSignatures.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
        ),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => [
          pw.SizedBox(height: 283),
          _buildSignaturePage(
            renseignements,
            currentUser?.fullName,
            trackedPages,
            currentOffset,
          ),
        ],
      ),
    );
    final bytesSignatures = await pdfSignatures.save();
    if (saveFilesToDisk) {
      final chunk = File('${tempDir.path}/pdf_chunk_signatures_$missionId.pdf');
      await chunk.writeAsBytes(bytesSignatures);
      allChunkFiles.add(chunk);
    }
    currentOffset += pdfSignatures.document.pdfPageList.pages.length;

    // ── Sub-chunk 2.2 : Page de garde Photos & Schéma ──
    final double progressPhotosGarde = saveFilesToDisk ? 0.82 : 0.39;
    onProgress?.call(
      progressPhotosGarde,
      'Génération de la section schéma et garde des photos...',
    );
    await Future.delayed(Duration.zero);
    final pdfP2_2 = pw.Document(
      title: 'Garde Photos & Schéma - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfP2_2.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(
          pageOffset: currentOffset,
          overrideTotalPages: overrideTotalPages,
          showWatermark: true,
        ),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => [
          pw.SizedBox(height: 295),
          pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 350, height: 2, color: accentColor),
                pw.SizedBox(height: 24),
                PageTracker(
                  key: 'photos',
                  registry: trackedPages,
                  offset: currentOffset,
                  child: pw.Text(
                    'PHOTOS',
                    style: pw.TextStyle(
                      font: _fontBold,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: headerColor,
                      letterSpacing: 1.0,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  nomSiteHeader.isNotEmpty
                      ? nomSiteHeader.toUpperCase()
                      : mission.nomClient.toUpperCase(),
                  style: pw.TextStyle(
                    font: _fontRegular,
                    fontSize: 13,
                    color: accentColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 24),
                pw.Container(width: 350, height: 2, color: accentColor),
              ],
            ),
          ),
        ],
      ),
    );
    final bytesP2_2 = await pdfP2_2.save();
    if (saveFilesToDisk) {
      final chunkP2_2 = File('${tempDir.path}/pdf_chunk_p2_2_$missionId.pdf');
      await chunkP2_2.writeAsBytes(bytesP2_2);
      allChunkFiles.add(chunkP2_2);
    }
    currentOffset += pdfP2_2.document.pdfPageList.pages.length;

    // ── Section 13 : Photos Chunked ──
    final double progressPhotosChunked = saveFilesToDisk ? 0.87 : 0.40;
    onProgress?.call(
      progressPhotosChunked,
      'Traitement et compression des photos d\'illustration...',
    );
    await Future.delayed(Duration.zero);
    final photoResult = await _addPhotosSectionChunked(
      mission,
      missionId,
      audit,
      description,
      trackedPages,
      nomSite: nomSiteHeader,
      numeroRapport: numeroRapportDoc,
      pageOffset: currentOffset,
      overrideTotalPages: overrideTotalPages,
      saveFilesToDisk: saveFilesToDisk,
    );
    if (saveFilesToDisk) allChunkFiles.addAll(photoResult.files);
    currentOffset += photoResult.totalPages;

    // ── Sub-chunk 2.3 : Schéma d'exploitation (Placé à la FIN du document si schemaOption == 'oui') ──
    final hasSchema = mission.schemaOption?.trim().toLowerCase() == 'oui';
    if (hasSchema) {
      await Future.delayed(Duration.zero);
      cancellationToken?.throwIfCancelled();
      final pdfSchema = pw.Document(
        title: 'Schéma - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      _addSchemaSection(
        pdfSchema,
        mission,
        trackedPages,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
        pageOffset: currentOffset,
        overrideTotalPages: overrideTotalPages,
      );
      final bytesSchema = await pdfSchema.save();
      if (saveFilesToDisk) {
        final chunkSchema = File(
          '${tempDir.path}/pdf_chunk_schema_$missionId.pdf',
        );
        await chunkSchema.writeAsBytes(bytesSchema);
        allChunkFiles.add(chunkSchema);
      }
      currentOffset += pdfSchema.document.pdfPageList.pages.length;
    }

    // ── Sub-chunk Final : Quatrième de couverture (Dernière page absolue du rapport) ──
    final pdfFinal = pw.Document(
      title: 'Quatrième de couverture - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfFinal.addPage(PdfFinalPageBuilder.buildPage());
    final bytesFinal = await pdfFinal.save();
    if (saveFilesToDisk) {
      final chunkFinal = File('${tempDir.path}/pdf_chunk_final_$missionId.pdf');
      await chunkFinal.writeAsBytes(bytesFinal);
      allChunkFiles.add(chunkFinal);
    }
    currentOffset += pdfFinal.document.pdfPageList.pages.length;

    final totalReportPages = currentOffset;

    // ── Sub-chunk 1.1 : Couverture, Intervenants & Sommaire (Généré en dernier) ──
    await Future.delayed(Duration.zero);
    cancellationToken?.throwIfCancelled();
    if (saveFilesToDisk) {
      onProgress?.call(
        0.92,
        'Génération du sommaire dynamique et finalisation...',
      );
      final pdfP1_1 = pw.Document(
        title: 'Couverture, Intervenants & Sommaire - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      final jsaP1_1 = HiveService.getJSAByMissionId(mission.id);
      pdfP1_1.addPage(
        pw.Page(
          pageTheme: _buildCoverPageTheme(),
          build: (ctx) => _buildCoverPage(
            mission,
            renseignements,
            ctx,
            numeroRapport: numeroRapportDoc,
          ),
        ),
      );
      pdfP1_1.addPage(
        pw.Page(
          pageTheme: _buildInnerPageTheme(
            pageOffset: 0,
            overrideTotalPages: totalReportPages,
          ),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPageHeaderWidget(
                nomClient: mission.nomClient,
                nomSite: nomSiteHeader,
                numeroRapport: numeroRapportDoc,
              ),
              pw.SizedBox(height: 8),
              _buildIntervenantsEtResponsabilitesPage(
                jsaP1_1,
                renseignements,
                currentUser,
                trackedPages,
                0,
                reportGenerationDate: generationDate,
                mission: mission,
              ),
            ],
          ),
        ),
      );
      _addSommairePages(
        pdfP1_1,
        sommaireEntries,
        trackedPages,
        nomClient: mission.nomClient,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
        pageOffset: 0,
        overrideTotalPages: totalReportPages,
      );
      final chunkP1_1 = File('${tempDir.path}/pdf_chunk_p1_1_$missionId.pdf');
      final bytesP1_1 = await pdfP1_1.save();
      await chunkP1_1.writeAsBytes(bytesP1_1);

      allChunkFiles.insert(0, chunkP1_1);
    }

    return _GeneratedReportResult(
      files: allChunkFiles,
      trackedPages: trackedPages,
      totalReportPages: totalReportPages,
    );
  }

  /// Génère le nom de fichier officiel pour le rapport PDF de Vérification Électrique.
  /// Format : `Rapport_Verif_elec_<client>_<site>_<année>_<timestamp>.pdf` (ou sans site si non renseigné)
  static String buildElectricalReportFileName(
    String nomClient, {
    String? nomSite,
    DateTime? date,
    int? timestamp,
  }) {
    final now = date ?? DateTime.now();
    final year = now.year;
    final ts = timestamp ?? now.millisecondsSinceEpoch;
    final sanitizedClient = nomClient.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final sanitizedSite = nomSite != null && nomSite.trim().isNotEmpty
        ? nomSite.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        : '';
    final sitePart = sanitizedSite.isNotEmpty ? '_$sanitizedSite' : '';
    return 'Rapport_Verif_elec_$sanitizedClient${sitePart}_${year}_$ts.pdf';
  }

  static Future<File?> generateMissionReport(
    String missionId, {
    PdfProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    List<File> allChunkFiles = [];
    Directory? sessionDir;
    clearSessionCache();
    try {
      cancellationToken?.throwIfCancelled();
      onProgress?.call(0.02, 'Initialisation des ressources et des polices...');
      await _loadImages();
      await _loadFonts();

      // Permettre au Thread UI de traiter les callbacks de progression
      await Future.delayed(Duration.zero);
      cancellationToken?.throwIfCancelled();

      onProgress?.call(0.05, 'Chargement des données de la mission...');
      final mission = HiveService.getMissionById(missionId);
      if (mission == null) return null;

      final description = HiveService.getDescriptionInstallationsByMissionId(
        missionId,
      );
      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      final classements = HiveService.getEmplacementsByMissionId(missionId);
      final classementsZones = HiveService.getClassementsZonesByMissionId(
        missionId,
      );
      if (audit != null) {
        final knownZoneNames = classementsZones.map((cz) => cz.nomZone.trim().toLowerCase()).toSet();
        void checkAndAddZone(String nom, String? classementZoneId) {
          final zNom = nom.trim().toLowerCase();
          if (zNom.isEmpty || knownZoneNames.contains(zNom)) return;

          ClassementZone? cz;
          if (classementZoneId != null && classementZoneId.isNotEmpty) {
            cz = HiveService.getClassementZoneById(classementZoneId);
          }
          cz ??= HiveService.getClassementZoneByNom(missionId, nom.trim());
          if (cz != null) {
            classementsZones.add(cz);
            knownZoneNames.add(zNom);
          }
        }

        for (final z in audit.moyenneTensionZones) {
          checkAndAddZone(z.nom, z.classementZoneId);
        }
        for (final z in audit.basseTensionZones) {
          checkAndAddZone(z.nom, z.classementZoneId);
        }
      }
      final mesures = HiveService.getMesuresEssaisByMissionId(missionId);
      final foudres = HiveService.getFoudreObservationsByMissionId(missionId);
      final renseignements = HiveService.getRenseignementsGenerauxByMissionId(
        missionId,
      );
      final currentUser = HiveService.getCurrentUser();

      final nomSiteHeader = renseignements?.nomSite.isNotEmpty == true
          ? renseignements!.nomSite
          : (mission.nomSite ?? '');
      final systemTempDir = await getTemporaryDirectory();
      final generationDate = DateTime.now();
      final effectiveReportDate = mission.dateRapport ?? generationDate;
      _currentReportDate = effectiveReportDate;
      final String numeroRapportDoc = 'KES/IP/VE/${effectiveReportDate.year}/001';
      final sessionTimestamp = cancellationToken?.generationId ?? generationDate.millisecondsSinceEpoch.toString();
      sessionDir = Directory(
        '${systemTempDir.path}/pdf_session_${missionId}_$sessionTimestamp',
      );
      await sessionDir.create(recursive: true);
      cancellationToken?.throwIfCancelled();

      // ── Passe 1 : Calcul préliminaire de la pagination totale et enregistrement des clés ──
      onProgress?.call(
        0.10,
        'Calcul préliminaire de la pagination et du sommaire...',
      );
      await Future.delayed(Duration.zero);

      final pass1Result = await _generateReportPass(
        mission: mission,
        missionId: missionId,
        audit: audit,
        description: description,
        classements: classements,
        classementsZones: classementsZones,
        mesures: mesures,
        foudres: foudres,
        renseignements: renseignements,
        currentUser: currentUser,
        nomSiteHeader: nomSiteHeader,
        numeroRapportDoc: numeroRapportDoc,
        tempDir: sessionDir,
        generationDate: generationDate,
        saveFilesToDisk: false,
        cancellationToken: cancellationToken,
      );

      final totalReportPages = pass1Result.totalReportPages;
      cancellationToken?.throwIfCancelled();

      // ── Passe 2 : Génération finale avec numérotation Page X / N et enregistrement sur disque ──
      onProgress?.call(
        0.15,
        'Génération des fichiers PDF avec pagination Page / $totalReportPages...',
      );
      await Future.delayed(Duration.zero);

      final pass2Result = await _generateReportPass(
        mission: mission,
        missionId: missionId,
        audit: audit,
        description: description,
        classements: classements,
        classementsZones: classementsZones,
        mesures: mesures,
        foudres: foudres,
        renseignements: renseignements,
        currentUser: currentUser,
        nomSiteHeader: nomSiteHeader,
        numeroRapportDoc: numeroRapportDoc,
        tempDir: sessionDir,
        overrideTotalPages: totalReportPages,
        generationDate: generationDate,
        saveFilesToDisk: true,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );

      allChunkFiles = pass2Result.files;
      cancellationToken?.throwIfCancelled();

      // ── Assembly final par fusion binaire ──
      onProgress?.call(
        0.96,
        'Fusion binaire haute performance du document final...',
      );
      final fileName = buildElectricalReportFileName(
        mission.nomClient,
        nomSite: mission.nomSite,
        date: effectiveReportDate,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      final outputFile = File('${systemTempDir.path}/$fileName');

      final finalPdfFile = await PdfMergerService.mergePdfFiles(
        allChunkFiles,
        outputFile,
        deleteChunksAfterMerge: false,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );

      cancellationToken?.throwIfCancelled();

      if (kDebugMode && await finalPdfFile.exists()) {
        final double sizeMb = (await finalPdfFile.length()) / (1024 * 1024);
        debugPrint(
          '⚡ [PDF Compression] Rapport généré avec succès avec compression adaptative : ${sizeMb.toStringAsFixed(2)} Mo ($totalReportPages pages)',
        );
      }

      onProgress?.call(1.0, 'Génération du rapport terminée avec succès.');
      return finalPdfFile;
    } catch (e, stackTrace) {
      if (e is ReportGenerationCancelledException) {
        if (kDebugMode) {
          print('🛑 [PDF Generation Cancelled] ${e.toString()}');
        }
        rethrow;
      }
      if (kDebugMode) {
        print('❌ Erreur lors de la génération du rapport PDF: $e\n$stackTrace');
      }
      return null;
    } finally {
      // Nettoyage final exhaustif de tous les fichiers chunks et du dossier de session temporaire
      for (final chunkFile in allChunkFiles) {
        try {
          if (chunkFile.existsSync()) {
            chunkFile.deleteSync();
          }
        } catch (_) {}
      }
      if (sessionDir != null) {
        try {
          if (await sessionDir.exists()) {
            await sessionDir.delete(recursive: true);
          }
        } catch (_) {}
      }
      clearSessionCache();
    }
  }

  static String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  static Future<void> shareReport(File file) async {
    try {
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Rapport d\'Audit Electrique PDF',
        text: 'Veuillez trouver ci-joint le rapport d\'audit electrique.',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur partage PDF: $e');
      }
    }
  }

  static Future<void> deleteReport(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur suppression PDF: $e');
      }
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  HELPERS PUBLICS REUTILISABLES PAR LES MODULES DEDIES (EX: PdfReportLightService)
  // ──────────────────────────────────────────────────────────────

  static pw.PageTheme buildCoverPageTheme() => _buildCoverPageTheme();
  static pw.PageTheme buildInnerPageTheme() => _buildInnerPageTheme();
  static pw.Widget buildCoverPage(
    Mission mission,
    RenseignementsGeneraux? rg,
    pw.Context ctx, {
    String? subTitleOverride,
    String? numeroRapport,
  }) => _buildCoverPage(
    mission,
    rg,
    ctx,
    subTitleOverride: subTitleOverride,
    numeroRapport: numeroRapport,
  );
  static pw.Widget buildPageHeaderWidget({
    String? nomClient,
    String? nomSite,
    String? numeroRapport,
  }) => _buildPageHeaderWidget(
    nomClient: nomClient,
    nomSite: nomSite,
    numeroRapport: numeroRapport,
  );
  static void addSommairePages(
    pw.Document pdf,
    List<SommaireEntry> entries,
    Map<String, int> trackedPages, {
    String? nomClient,
    String? nomSite,
    String? numeroRapport,
  }) => _addSommairePages(
    pdf,
    entries,
    trackedPages,
    nomClient: nomClient,
    nomSite: nomSite,
    numeroRapport: numeroRapport,
  );
  static pw.Widget sectionBox(String title) => _sectionBox(title);
  static pw.Widget subTitle(String title) => _subTitle(title);
  static pw.TableRow tableHeaderRow(List<String> headers) =>
      _tableHeaderRow(headers);
  static pw.TableRow tableDataRow(List<String> data, {required bool alt}) =>
      _tableDataRow(data, alt: alt);
  static pw.Widget cell(
    String text, {
    required bool isHeader,
    PdfColor? color,
    int colspan = 1,
    bool centered = false,
  }) => _cell(
    text,
    isHeader: isHeader,
    color: color,
    colspan: colspan,
    centered: centered,
  );
  static Future<void> loadImages() => _loadImages();
  static Future<void> loadFonts() => _loadFonts();
  static pw.Font get fontRegular => _fontRegular;
  static pw.Font get fontBold => _fontBold;
  static pw.MemoryImage? get logoKesImage => _logoKesImage;
  static pw.MemoryImage? get firstPageFooterImage => _firstPageFooterImage;
  static String formatDate(DateTime d) => _formatDate(d);
}

// ================================================================
//  Classes internes (mises à jour)
// ================================================================

class _GeneratedReportResult {
  final List<File> files;
  final Map<String, int> trackedPages;
  final int totalReportPages;
  _GeneratedReportResult({
    required this.files,
    required this.trackedPages,
    required this.totalReportPages,
  });
}

