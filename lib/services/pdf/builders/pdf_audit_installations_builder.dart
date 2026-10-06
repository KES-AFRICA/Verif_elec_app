import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_description_builder.dart';
import 'package:inspec_app/services/ip_ik_evaluator_service.dart';
import 'package:inspec_app/services/equipment_type_transition_service.dart';
import 'package:inspec_app/utils/normative_reference_cleaner.dart';

/// Builder responsable de l'Audit des Installations Électriques (Moyenne Tension et Basse Tension)
class PdfAuditInstallationsBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  static const double fsH1 = PdfReportStyles.fsH1;
  static const double fsH2 = PdfReportStyles.fsH2;
  static const double fsH3 = PdfReportStyles.fsH3;
  static const double fsBody = PdfReportStyles.fsBody;
  static const double fsSmall = PdfReportStyles.fsSmall;

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
  static pw.MemoryImage get _placeholder1x1 => placeholder1x1;

  // Pure helpers
  static pw.Font _getCriticiteFont(String criticite) {
    final c = criticite.trim().toLowerCase();
    if (c.contains('critique') || c.contains('majeur') || c.contains('mineur')) {
      return fontBold;
    }
    return fontRegular;
  }

  static ({String du, String deCe}) _getEquipmentGrammar(String? type) {
    final t = (type ?? '').trim().toUpperCase();
    if (t == 'TGBT') {
      return (du: 'DU TGBT', deCe: 'DE CE TGBT');
    } else if (t == 'ARMOIRE') {
      return (du: "DE L'ARMOIRE", deCe: 'DE CETTE ARMOIRE');
    } else if (t == 'COFFRET') {
      return (du: 'DU COFFRET', deCe: 'DE CE COFFRET');
    } else if (t == 'INVERSEUR') {
      return (du: "DE L'INVERSEUR", deCe: "DE L'INVERSEUR");
    } else if (t == 'CELLULE') {
      return (du: 'DE LA CELLULE', deCe: 'DE CETTE CELLULE');
    } else if (t == 'TRANSFORMATEUR') {
      return (du: 'DU TRANSFORMATEUR', deCe: 'DE CE TRANSFORMATEUR');
    }
    return (du: "DE L'ÉQUIPEMENT", deCe: "DE CET ÉQUIPEMENT");
  }

  static String getIndiceIpIkLabel(String? type) {
    final t = (type ?? '').trim().toUpperCase();
    if (t == 'INVERSEUR') return "Indice IP/IK de l'Inverseur";
    if (t == 'ARMOIRE') return "Indice IP/IK de l'Armoire";
    if (t == 'COFFRET') return "Indice IP/IK du Coffret";
    if (t == 'TGBT') return "Indice IP/IK du TGBT";
    return "Indice IP/IK de l'équipement";
  }

  static String getIdentificationLabel(String? type) {
    final t = (type ?? '').trim().toUpperCase();
    if (t == 'INVERSEUR') return "Identification de l'inverseur";
    if (t == 'TGBT') return "Identification du TGBT";
    if (t == 'COFFRET') return "Identification du coffret";
    if (t == 'ARMOIRE') return "Identification de l'armoire";
    return "Identification de l'équipement";
  }

  static String getProtectionTeteLabel(String? type) {
    final t = (type ?? '').trim().toUpperCase();
    if (t == 'TGBT') return "Protection de tête du TGBT";
    if (t == 'COFFRET') return "Protection de tête du coffret";
    if (t == 'ARMOIRE') return "Protection de tête de l'armoire";
    return "Protection de tête de coffret/Armoire";
  }

  static pw.Widget _resultBox(String text) {
    final lower = text.toLowerCase();
    final isOk = lower.contains('satisfaisant') && !lower.contains('non');
    final isSansObjet = lower.contains('sans objet');
    final bg = isSansObjet
        ? PdfReportStyles.sansObjetColor
        : (isOk ? PdfReportStyles.conformeColor : PdfReportStyles.nonConformeColor);
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: fsBody)),
    );
  }

  static String _formatEquipmentTitle(String name, String type) {
    final trimmedName = name.trim();
    final trimmedType = type.trim();
    if (trimmedName.isEmpty && trimmedType.isEmpty) return 'Équipement';
    if (trimmedType.isEmpty) return trimmedName;
    if (trimmedName.isEmpty) return trimmedType.toUpperCase();

    final pattern = RegExp('^${RegExp.escape(trimmedType)}\\s*:\\s*', caseSensitive: false);
    if (pattern.hasMatch(trimmedName)) {
      return trimmedName;
    }

    return '${trimmedType.toUpperCase()} : $trimmedName';
  }

  static String _normalizeText(String text) {
    if (text.isEmpty) return text;
    text = text.replaceAll(RegExp(r'§\s*'), 'art ');

    const replacements = <String, String>{
      '«': '"', '»': '"', '“': '"', '”': '"',
      '‘': "'", '’': "'",
      '—': '-', '–': '-', '…': '...',
      '≥': '>=', '≤': '<=', '≠': '!=',
      '±': '+/-', '∞': 'inf', '√': 'racine',
      '→': '->', '←': '<-', '↔': '<->',
      '∑': 'Somme', '∆': 'Delta', 'Φ': 'Phi',
      'θ': 'theta',
    };
    replacements.forEach((key, val) {
      text = text.replaceAll(key, val);
    });
    return text;
  }

  // Exact internal delegates
  static Map<String, int> _buildPhotoNumberRegistry(
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
  ) => buildPhotoNumberRegistry(audit, description);

  static String _formatPhotoNumbers(List<int> numbers) => formatPhotoNumbers(numbers);

  static pw.Widget _buildPhotoIndicatorWidget(
    List<String> photoPaths,
    Map<String, int>? photoRegistry,
  ) => buildPhotoIndicatorWidget(photoPaths, photoRegistry);

  static List<pw.Widget> _buildAuditContentOrdered(
    AuditInstallationsElectriques audit,
    Map<String, int> trackedPages, {
    Map<String, int>? photoRegistry,
    DescriptionInstallations? description,
  }) => buildAuditContentOrdered(audit, trackedPages, photoRegistry: photoRegistry, description: description);

  static List<pw.Widget> _buildZone(
    String nom,
    List<ObservationLibre> obs,
    Map<String, int> trackedPages, {
    Map<String, int>? photoRegistry,
    String? missionId,
  }) => buildZone(nom, obs, trackedPages, photoRegistry: photoRegistry, missionId: missionId);

  static pw.Widget _buildObsZoneTable(
    String zone,
    List<ObservationLibre> obs, {
    Map<String, int>? photoRegistry,
  }) => buildObsZoneTable(zone, obs, photoRegistry: photoRegistry);

  static List<pw.MemoryImage> _resolveLocalPhotos(
    dynamic local, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
  }) => resolveLocalPhotos(local, photoCache: photoCache);

  static pw.Widget _buildLocalPhotosZone(
    List<pw.MemoryImage> images, {
    String placeholderText = 'Aucune photo du local',
  }) => buildLocalPhotosZone(images, placeholderText: placeholderText);

  static List<pw.Widget> _buildLocalMT(
    MoyenneTensionLocal local,
    Map<String, int> trackedPages, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
    bool saveFilesToDisk = true,
    Map<String, int>? photoRegistry,
    String? missionId,
  }) => buildLocalMT(local, trackedPages, photoCache: photoCache, saveFilesToDisk: saveFilesToDisk, photoRegistry: photoRegistry, missionId: missionId);

  static List<pw.Widget> _buildLocalBT(
    BasseTensionLocal local,
    Map<String, int> trackedPages, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
    Map<String, int>? photoRegistry,
    String? missionId,
  }) => buildLocalBT(local, trackedPages, photoCache: photoCache, photoRegistry: photoRegistry, missionId: missionId);

  static pw.Widget _subSectionBar(String title) => subSectionBar(title);
  static pw.Widget _localNameBar(String title) => localNameBar(title);

  static List<pw.Widget> _buildDispositionsTable(
    List<ElementControle> elements,
    String titre, {
    String? localType,
    Map<String, int>? photoRegistry,
  }) => buildDispositionsTable(elements, titre, localType: localType, photoRegistry: photoRegistry);

  static pw.Widget _buildAlimentationSiteMtTable(DescriptionInstallations desc) => buildAlimentationSiteMtTable(desc);

  static List<pw.Widget> _buildCelluleSection(
    Cellule cellule, {
    String? localName,
    Map<dynamic, pw.MemoryImage?>? photoCache,
    bool saveFilesToDisk = true,
    Map<String, int>? photoRegistry,
  }) => buildCelluleSection(cellule, localName: localName, photoCache: photoCache, saveFilesToDisk: saveFilesToDisk, photoRegistry: photoRegistry);

  static List<pw.Widget> _buildTransformateurSection(
    TransformateurMTBT transfo, {
    String? localName,
    Map<dynamic, pw.MemoryImage?>? photoCache,
    bool saveFilesToDisk = true,
    Map<String, int>? photoRegistry,
  }) => buildTransformateurSection(transfo, localName: localName, photoCache: photoCache, saveFilesToDisk: saveFilesToDisk, photoRegistry: photoRegistry);

  static pw.Widget _buildCpiTable(List<InstallationItem> cpiItems) => buildCpiTable(cpiItems);
  static pw.Widget _buildCpiTestContent(String testResult) => buildCpiTestContent(testResult);

  static List<pw.Widget> _buildCoffret(
    CoffretArmoire coffret,
    Map<String, int> trackedPages,
    String parentName, {
    String? missionId,
    Map<dynamic, pw.MemoryImage?>? photoCache,
    Map<String, int>? photoRegistry,
  }) => buildCoffret(coffret, trackedPages, parentName, missionId: missionId, photoCache: photoCache, photoRegistry: photoRegistry);

  static pw.Widget _buildPointsVerificationTable(
    List<PointVerification> points, {
    String? coffretType,
    Map<String, int>? photoRegistry,
  }) => buildPointsVerificationTable(points, coffretType: coffretType, photoRegistry: photoRegistry);

  static pw.Widget _buildSimpleObsTable(
    List<ObservationLibre> obs,
    String titre, {
    Map<String, int>? photoRegistry,
  }) => buildSimpleObsTable(obs, titre, photoRegistry: photoRegistry);

  static pw.Widget _valueCell(
    String text, {
    pw.Alignment alignment = pw.Alignment.center,
    pw.TextAlign textAlign = pw.TextAlign.center,
  }) => valueCell(text, alignment: alignment, textAlign: textAlign);

  static pw.Widget _protectionCell(String typeProtection, String? marque) =>
      buildProtectionCell(typeProtection, marque);

  static String formatSectionWithConducteurs(String? section, int? conducteurs) {
    final cleanSec = PdfReportStyles.stripUnitFromValue(section, 'mm²').trim();
    if (cleanSec.isEmpty || cleanSec == '-') return '-';
    if (conducteurs != null && conducteurs > 0) {
      return '$conducteurs × $cleanSec';
    }
    return cleanSec;
  }

  static pw.Widget buildProtectionCell(
    String typeProtection,
    String? marque, {
    pw.Font? fontRegular,
  }) {
    final fRegular = fontRegular ?? PdfAuditInstallationsBuilder.fontRegular;
    final typeClean = typeProtection.trim();
    final marqueClean = marque?.trim() ?? '';

    if (typeClean.isEmpty || typeClean.toLowerCase() == '-aucun-' || typeClean.toLowerCase() == 'aucun' || typeClean == '-') {
      return valueCell('absent');
    }

    if (marqueClean.isEmpty) {
      return pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              typeClean,
              style: pw.TextStyle(font: fRegular, fontSize: PdfReportStyles.fsSmall),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              '(Non défini)',
              style: pw.TextStyle(
                font: fRegular,
                fontSize: PdfReportStyles.fsSmall,
                color: PdfColors.red,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );
    }

    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            typeClean,
            style: pw.TextStyle(font: fRegular, fontSize: PdfReportStyles.fsSmall),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            '($marqueClean)',
            style: pw.TextStyle(font: fRegular, fontSize: PdfReportStyles.fsSmall),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _thCell(String text) => thCell(text);

  static String _formatTypeProtectionWithMarque(String typeProtection, String? marqueDisjoncteur) =>
      formatTypeProtectionWithMarque(typeProtection, marqueDisjoncteur);

  static Map<String, int> buildPhotoNumberRegistry(
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
  ) {
    final registry = <String, int>{};
    final seenPaths = <String>{};
    int photoCounter = 1;

    void addPath(String? path) {
      if (path == null) return;
      final trimmed = path.trim();
      if (trimmed.isNotEmpty && !seenPaths.contains(trimmed)) {
        seenPaths.add(trimmed);
        registry[trimmed] = photoCounter++;
      }
    }

    void addPaths(List<String>? paths) {
      if (paths == null) return;
      for (final p in paths) {
        addPath(p);
      }
    }

    void processCoffret(CoffretArmoire c) {
      addPaths(c.photosExternes);
      addPaths(c.photos);
      addPaths(c.photosInternes);
      for (final pv in c.pointsVerification) {
        addPaths(pv.photos);
      }
      for (final obs in c.observationsLibres) {
        addPaths(obs.photos);
      }
      final pfEnrichies = c.observationsParafoudreEnrichies;
      if (pfEnrichies != null) {
        for (final obs in pfEnrichies) {
          addPaths(obs.photos);
        }
      }
    }

    void processCellule(Cellule cell) {
      addPath(cell.photo);
      addPaths(cell.photos);
      for (final ev in cell.elementsVerifies) {
        addPaths(ev.photos);
      }
      if (cell.observations != null) {
        for (final el in cell.observations!) {
          addPaths(el.photos);
        }
      }
    }

    void processTransfo(TransformateurMTBT transfo) {
      addPath(transfo.photo);
      addPaths(transfo.photos);
      for (final ev in transfo.elementsVerifies) {
        addPaths(ev.photos);
      }
      if (transfo.observations != null) {
        for (final el in transfo.observations!) {
          addPaths(el.photos);
        }
      }
    }

    void processLocalMT(MoyenneTensionLocal l) {
      addPaths(l.photos);
      if (l.dispositionsConstructives != null) {
        for (final d in l.dispositionsConstructives!) {
          addPaths(d.photos);
        }
      }
      if (l.conditionsExploitation != null) {
        for (final c in l.conditionsExploitation!) {
          addPaths(c.photos);
        }
      }
      for (final obs in l.observationsLibres) {
        addPaths(obs.photos);
      }
      for (final cell in l.cellules) {
        processCellule(cell);
      }
      for (final transfo in l.transformateurs) {
        processTransfo(transfo);
      }
      for (final coffret in l.coffrets) {
        processCoffret(coffret);
      }
    }

    void processLocalBT(BasseTensionLocal l) {
      addPaths(l.photos);
      if (l.dispositionsConstructives != null) {
        for (final d in l.dispositionsConstructives!) {
          addPaths(d.photos);
        }
      }
      if (l.conditionsExploitation != null) {
        for (final c in l.conditionsExploitation!) {
          addPaths(c.photos);
        }
      }
      for (final obs in l.observationsLibres) {
        addPaths(obs.photos);
      }
      for (final coffret in l.coffrets) {
        processCoffret(coffret);
      }
    }

    // 1. Description Section
    if (description != null) {
      void addDescItems(List<InstallationItem>? items) {
        if (items == null) return;
        for (final item in items) {
          addPaths(item.photoPaths);
        }
      }

      addDescItems(description.alimentationMoyenneTension);
      addDescItems(description.alimentationBasseTension);
      addDescItems(description.groupeElectrogene);
      addDescItems(description.alimentationCarburant);
      addDescItems(description.inverseur);
      addDescItems(description.stabilisateur);
      addDescItems(description.onduleurs);
    }

    // 2. Audit Général
    if (audit != null) {
      addPaths(audit.photos);

      // 3. MT Locaux Directs
      for (final local in audit.moyenneTensionLocaux) {
        processLocalMT(local);
      }

      // 4. MT Zones
      for (final zone in audit.moyenneTensionZones) {
        addPaths(zone.photos);
        for (final obs in zone.observationsLibres) {
          addPaths(obs.photos);
        }
        for (final coffret in zone.coffrets) {
          processCoffret(coffret);
        }
        for (final local in zone.locaux) {
          processLocalMT(local);
        }
      }

      // 5. BT Zones
      for (final zone in audit.basseTensionZones) {
        addPaths(zone.photos);
        for (final obs in zone.observationsLibres) {
          addPaths(obs.photos);
        }
        for (final coffret in zone.coffretsDirects) {
          processCoffret(coffret);
        }
        for (final local in zone.locaux) {
          processLocalBT(local);
        }
      }
    }

    return registry;
  }

  static String formatPhotoNumbers(List<int> numbers) {
    if (numbers.isEmpty) return '';
    final sorted = numbers.toSet().toList()..sort();
    if (sorted.length == 1) {
      return 'Photo ${sorted.first}';
    }

    final rangeStrings = <String>[];
    int start = sorted.first;
    int prev = sorted.first;

    for (int i = 1; i < sorted.length; i++) {
      final curr = sorted[i];
      if (curr == prev + 1) {
        prev = curr;
      } else {
        if (start == prev) {
          rangeStrings.add('$start');
        } else if (prev == start + 1) {
          rangeStrings.add('$start, $prev');
        } else {
          rangeStrings.add('$start–$prev');
        }
        start = curr;
        prev = curr;
      }
    }

    if (start == prev) {
      rangeStrings.add('$start');
    } else if (prev == start + 1) {
      rangeStrings.add('$start, $prev');
    } else {
      rangeStrings.add('$start–$prev');
    }

    return 'Photos ${rangeStrings.join(', ')}';
  }

  static pw.Widget buildPhotoIndicatorWidget(
    List<String> photoPaths,
    Map<String, int>? photoRegistry,
  ) {
    if (photoPaths.isEmpty || photoRegistry == null || photoRegistry.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final numbers = <int>[];
    for (final path in photoPaths) {
      final trimmed = path.trim();
      if (trimmed.isNotEmpty && photoRegistry.containsKey(trimmed)) {
        numbers.add(photoRegistry[trimmed]!);
      }
    }

    if (numbers.isEmpty) return pw.SizedBox.shrink();

    final labelText = _formatPhotoNumbers(numbers);
    if (labelText.isEmpty) return pw.SizedBox.shrink();

    const cameraSvg =
        '<svg width="10" height="8" viewBox="0 0 16 14" fill="none" xmlns="http://www.w3.org/2000/svg">'
        '<path d="M5.5 1.5L4.2 3.5H2C1.17 3.5 0.5 4.17 0.5 5V11.5C0.5 12.33 1.17 13 2 13H14C14.83 13 15.5 12.33 15.5 11.5V5C15.5 4.17 14.83 3.5 14 3.5H11.8L10.5 1.5H5.5Z" stroke="#1D4ED8" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>'
        '<circle cx="8" cy="8.25" r="2.75" stroke="#1D4ED8" stroke-width="1.3"/>'
        '</svg>';

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 3),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFEFF6FF),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFBFDBFE), width: 0.5),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SvgImage(svg: cameraSvg, width: 8, height: 7),
          pw.SizedBox(width: 3),
          pw.Text(
            labelText,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 7.5,
              color: PdfColor.fromInt(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }

  @visibleForTesting
  static String formatPhotoNumbersForTest(List<int> numbers) =>
      _formatPhotoNumbers(numbers);

  @visibleForTesting
  static Map<String, int> buildPhotoNumberRegistryForTest(
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
  ) =>
      _buildPhotoNumberRegistry(audit, description);



  // ──────────────────────────────────────────────────────────────
  //  AUDIT DES INSTALLATIONS ELECTRIQUES
  // ──────────────────────────────────────────────────────────────

  static List<pw.Widget> buildAuditContentOrdered(
    AuditInstallationsElectriques audit,
    Map<String, int> trackedPages, {
    Map<String, int>? photoRegistry,
    DescriptionInstallations? description,
  }) {
    final widgets = <pw.Widget>[];
    final reg = photoRegistry ?? _buildPhotoNumberRegistry(audit, description);

    // 1. Locaux MT directs (hors zone) — PREMIER local sur la même page que le titre
    if (audit.moyenneTensionLocaux.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(pw.NewPage());
      widgets.add(_subSectionBar('MOYENNE TENSION — LOCAUX DIRECTS'));

      for (int i = 0; i < audit.moyenneTensionLocaux.length; i++) {
        final local = audit.moyenneTensionLocaux[i];
        // Pas de NewPage pour le premier local (i == 0)
        if (i > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalMT(local, trackedPages, photoRegistry: reg, missionId: audit.missionId));
      }
    }

    // 2. Zones MT
    for (var zone in audit.moyenneTensionZones) {
      widgets.add(pw.NewPage());
      widgets.addAll(
        _buildZone(zone.nom, zone.observationsLibres, trackedPages, photoRegistry: reg, missionId: audit.missionId),
      );

      int elementIndex = 0;
      // Locaux dans la zone : le premier sur la même page que la zone (élément 0)
      for (int i = 0; i < zone.locaux.length; i++) {
        final local = zone.locaux[i];
        if (elementIndex > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalMT(local, trackedPages, photoRegistry: reg, missionId: audit.missionId));
        elementIndex++;
      }

      // Coffrets de la zone
      for (int i = 0; i < zone.coffrets.length; i++) {
        final coffret = zone.coffrets[i];
        if (elementIndex > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildCoffret(coffret, trackedPages, zone.nom, photoRegistry: reg, missionId: audit.missionId));
        elementIndex++;
      }
    }

    // 3. Zones BT
    for (var zone in audit.basseTensionZones) {
      widgets.add(pw.NewPage());
      widgets.addAll(
        _buildZone(zone.nom, zone.observationsLibres, trackedPages, photoRegistry: reg, missionId: audit.missionId),
      );

      int elementIndex = 0;
      // Coffrets directs de la zone : le premier sur la même page que la zone (élément 0)
      for (int i = 0; i < zone.coffretsDirects.length; i++) {
        final coffret = zone.coffretsDirects[i];
        if (elementIndex > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildCoffret(coffret, trackedPages, zone.nom, photoRegistry: reg, missionId: audit.missionId));
        elementIndex++;
      }

      // Locaux BT
      for (int i = 0; i < zone.locaux.length; i++) {
        final local = zone.locaux[i];
        if (elementIndex > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalBT(local, trackedPages, photoRegistry: reg, missionId: audit.missionId));
        elementIndex++;
      }
    }

    if (widgets.isEmpty) {
      widgets.add(PdfReportStyles.bodyText('Aucune installation enregistree.'));
    }

    return widgets;
  }

  static List<pw.Widget> buildZone(
    String nom,
    List<ObservationLibre> obs,
    Map<String, int> trackedPages, {
    Map<String, int>? photoRegistry,
    String? missionId,
  }) {
    String ipIkText = 'Non classée';
    if (missionId != null && missionId.trim().isNotEmpty) {
      final parsed = IpIkEvaluatorService.resolveZoneIpIk(missionId, nom);
      if (parsed.hasIpOrIk) {
        if (parsed.ip != null && parsed.ik != null) {
          ipIkText = '${parsed.ip}/${parsed.ik}';
        } else if (parsed.ip != null) {
          ipIkText = parsed.ip!;
        } else if (parsed.ik != null) {
          ipIkText = parsed.ik!;
        }
      }
    }

    final widgets = <pw.Widget>[
      pw.SizedBox(height: 8),
      PageTracker(
        key: 'audit_zone_$nom',
        registry: trackedPages,
        child: pw.Container(
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
        ),
      ),
    ];

    widgets.add(pw.SizedBox(height: 5));
    widgets.add(_buildObsZoneTable(nom, obs, photoRegistry: photoRegistry));

    widgets.add(pw.SizedBox(height: 5));
    return widgets;
  }

  static pw.Widget buildObsZoneTable(
    String zone,
    List<ObservationLibre> obs, {
    Map<String, int>? photoRegistry,
  }) {
    final rows = <pw.TableRow>[
      // En-tête (avec Items centré et Titre à gauche en majuscule)
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.white),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Items',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: PdfReportStyles.fsSmall,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              'OBSERVATIONS RELATIVES A ${zone.toUpperCase()}',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: PdfReportStyles.fsSmall,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    ];

    if (obs.isEmpty) {
      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '-',
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 4,
              ),
              child: pw.Text(
                'Rien à signaler',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: PdfReportStyles.fsSmall,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      rows.addAll(
        obs.asMap().entries.map(
          (e) => pw.TableRow(
            decoration: pw.BoxDecoration(
              color: e.key.isEven ? PdfColors.white : PdfReportStyles.tableRowAlt,
            ),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '${e.key + 1}',
                  style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 4,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      e.value.texte,
                      style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                    ),
                    _buildPhotoIndicatorWidget(e.value.photos, photoRegistry),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.8),
        1: pw.FlexColumnWidth(6.4),
      },
      children: rows,
    );
  }

  static List<pw.MemoryImage> resolveLocalPhotos(
    dynamic local, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
  }) {
    final images = <pw.MemoryImage>[];

    if (photoCache != null && photoCache.containsKey(local)) {
      final cached = photoCache[local];
      if (cached != null) {
        images.add(cached);
        return images;
      }
    }

    final rawPhotos = (local.photos as List?)?.cast<String>() ?? [];
    for (final src in rawPhotos) {
      final trimmed = src.trim();
      if (trimmed.isEmpty) continue;
      try {
        final resolved = AppImageUtils.resolvePathSync(trimmed);
        if (resolved != null) {
          final f = File(resolved);
          if (f.existsSync() && f.lengthSync() < 500000) {
            final bytes = f.readAsBytesSync();
            if (bytes.isNotEmpty) {
              images.add(pw.MemoryImage(bytes));
            }
          }
        }
      } catch (_) {}
    }

    return images;
  }

  static pw.Widget buildLocalPhotosZone(
    List<pw.MemoryImage> images, {
    String placeholderText = 'Aucune photo du local',
  }) {
    // ── Cas 0 photo : Zone réservée préservée avec placeholder ──
    if (images.isEmpty) {
      return pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 4, bottom: 6),
        child: pw.Container(
          width: 170,
          height: 95,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF9F9F9),
            border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.4),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          alignment: pw.Alignment.center,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                placeholderText,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget buildPhotoBox(pw.MemoryImage img, double width, double height) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.4),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        padding: const pw.EdgeInsets.all(3),
        child: pw.Image(
          img,
          width: width,
          height: height,
          fit: pw.BoxFit.contain,
        ),
      );
    }

    // ── Cas 1 photo ──
    if (images.length == 1) {
      return pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 4, bottom: 6),
        child: buildPhotoBox(images[0], 280, 190),
      );
    }

    // ── Cas 2 photos ──
    if (images.length == 2) {
      return pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 4, bottom: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            buildPhotoBox(images[0], 225, 155),
            pw.SizedBox(width: 10),
            buildPhotoBox(images[1], 225, 155),
          ],
        ),
      );
    }

    // ── Cas 3 photos ──
    if (images.length == 3) {
      return pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 4, bottom: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            buildPhotoBox(images[0], 150, 110),
            pw.SizedBox(width: 8),
            buildPhotoBox(images[1], 150, 110),
            pw.SizedBox(width: 8),
            buildPhotoBox(images[2], 150, 110),
          ],
        ),
      );
    }

    // ── Cas N photos (>= 4) ──
    final rows = <pw.Widget>[];
    for (int i = 0; i < images.length; i += 2) {
      final chunk = images.sublist(i, (i + 2).clamp(0, images.length));
      rows.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            buildPhotoBox(chunk[0], 225, 150),
            if (chunk.length > 1) ...[
              pw.SizedBox(width: 10),
              buildPhotoBox(chunk[1], 225, 150),
            ],
          ],
        ),
      );
      if (i + 2 < images.length) {
        rows.add(pw.SizedBox(height: 8));
      }
    }

    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 4, bottom: 6),
      child: pw.Column(
        children: rows,
      ),
    );
  }

  static List<pw.Widget> buildLocalMT(
    MoyenneTensionLocal local,
    Map<String, int> trackedPages, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
    bool saveFilesToDisk = true,
    Map<String, int>? photoRegistry,
    String? missionId,
  }) {
    final widgets = <pw.Widget>[
      PageTracker(
        key: 'audit_local_${local.nom}',
        registry: trackedPages,
        child: _localNameBar(local.nom.toUpperCase()),
      ),
      pw.SizedBox(height: 5),
    ];

    // Infos générales du local (toujours affichées)
    final typeLabelMT = HiveService.getLocalTypes()[local.type] ?? local.type;
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FlexColumnWidth(3),
        },
        children: [
          PdfReportStyles.tableDataRow(['Type de local', typeLabelMT], alt: false),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 5));

    // Zone photo du local (toujours affichée : photos ou zone réservée 0 photo)
    final localImages = _resolveLocalPhotos(local, photoCache: photoCache);
    widgets.add(_buildLocalPhotosZone(localImages, placeholderText: 'Aucune photo du local'));

    // Local inaccessible : mention claire dans le rapport
    if (local.accessible == false) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            border: pw.Border.all(color: PdfColors.red200),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.red,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    '[!] LOCAL INACCESSIBLE — NON INSPECTÉ',
                    style: pw.TextStyle(
                      color: PdfColors.red,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Ce local n'a pas pu être inspecté lors de la visite. "
                "Une nouvelle vérification est nécessaire pour couvrir cet emplacement.",
                style: pw.TextStyle(
                  color: PdfColors.red700,
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
      return widgets;
    }

    DispositionsConstructivesRegistry.ensureCompleteLocalChecklists(
      dispositionsConstructives: local.dispositionsConstructives,
      conditionsExploitation: local.conditionsExploitation,
    );
    if (local.dispositionsConstructives.isNotEmpty) {
      widgets.addAll(
        _buildDispositionsTable(
          local.dispositionsConstructives,
          'DISPOSITIONS CONSTRUCTIVES DU LOCAL TECHNIQUE MOYENNE TENSION',
          localType: local.type,
          photoRegistry: photoRegistry,
        ),
      );
    }
    if (local.conditionsExploitation.isNotEmpty) {
      if (local.dispositionsConstructives.isNotEmpty) {
        widgets.add(pw.NewPage());
      }
      widgets.addAll(
        _buildDispositionsTable(
          local.conditionsExploitation,
          'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ DU LOCAL MOYENNE TENSION',
          localType: local.type,
          photoRegistry: photoRegistry,
        ),
      );
    }

    for (int i = 0; i < local.cellules.length; i++) {
      widgets.add(pw.NewPage());
      widgets.addAll(
        _buildCelluleSection(
          local.cellules[i],
          localName: local.nom,
          photoCache: photoCache,
          saveFilesToDisk: saveFilesToDisk,
          photoRegistry: photoRegistry,
        ),
      );
    }
    for (int i = 0; i < local.transformateurs.length; i++) {
      widgets.add(pw.NewPage());
      widgets.addAll(
        _buildTransformateurSection(
          local.transformateurs[i],
          localName: local.nom,
          photoCache: photoCache,
          saveFilesToDisk: saveFilesToDisk,
          photoRegistry: photoRegistry,
        ),
      );
    }

    for (int i = 0; i < local.coffrets.length; i++) {
      widgets.add(pw.NewPage());
      widgets.addAll(
        _buildCoffret(
          local.coffrets[i],
          trackedPages,
          local.nom,
          photoCache: photoCache,
          photoRegistry: photoRegistry,
          missionId: missionId,
        ),
      );
    }

    return widgets;
  }

  static List<pw.Widget> buildLocalBT(
    BasseTensionLocal local,
    Map<String, int> trackedPages, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
    Map<String, int>? photoRegistry,
    String? missionId,
  }) {
    final widgets = <pw.Widget>[
      PageTracker(
        key: 'audit_local_${local.nom}',
        registry: trackedPages,
        child: _localNameBar(local.nom.toUpperCase()),
      ),
      pw.SizedBox(height: 5),
    ];

    // Infos générales du local (toujours affichées)
    final typeLabelMT = HiveService.getLocalTypes()[local.type] ?? local.type;
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FlexColumnWidth(3),
        },
        children: [
          PdfReportStyles.tableDataRow(['Type de local', typeLabelMT], alt: false),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 5));

    // Zone photo du local (toujours affichée : photos ou zone réservée 0 photo)
    final localImages = _resolveLocalPhotos(local, photoCache: photoCache);
    widgets.add(_buildLocalPhotosZone(localImages, placeholderText: 'Aucune photo du local'));

    // Local inaccessible : mention claire dans le rapport
    if (local.accessible == false) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            border: pw.Border.all(color: PdfColors.red200),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.red,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    '[!] LOCAL INACCESSIBLE — NON INSPECTÉ',
                    style: pw.TextStyle(
                      color: PdfColors.red,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Ce local n'a pas pu être inspecté lors de la visite. "
                "Une nouvelle vérification est nécessaire pour couvrir cet emplacement.",
                style: pw.TextStyle(
                  color: PdfColors.red700,
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
      return widgets;
    }

    final isGE = local.type == 'LOCAL_GROUPE_ELECTROGENE';
    final isBT = !isGE;

    if (isGE &&
        local.dispositionsConstructives != null &&
        local.conditionsExploitation != null) {
      DispositionsConstructivesRegistry.ensureCompleteGELocalChecklists(
        dispositionsConstructives: local.dispositionsConstructives!,
        conditionsExploitation: local.conditionsExploitation!,
      );
    } else if (isBT &&
        local.dispositionsConstructives != null &&
        local.conditionsExploitation != null) {
      DispositionsConstructivesRegistry.ensureCompleteBTLocalChecklists(
        dispositionsConstructives: local.dispositionsConstructives!,
        conditionsExploitation: local.conditionsExploitation!,
      );
    }

    final dispTitle = isGE
        ? 'DISPOSITIONS CONSTRUCTIVES DU LOCAL TECHNIQUE GROUPE ÉLECTROGENE'
        : 'DISPOSITIONS CONSTRUCTIVES DU LOCAL TECHNIQUE BASSE TENSION';
    final condTitle = isGE
        ? 'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ LOCAL GROUPE ÉLECTROGENE'
        : 'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ LOCAL BASSE TENSION';

    if (local.dispositionsConstructives != null &&
        local.dispositionsConstructives!.isNotEmpty) {
      widgets.addAll(
        _buildDispositionsTable(
          local.dispositionsConstructives!,
          dispTitle,
          localType: local.type,
          photoRegistry: photoRegistry,
        ),
      );
    }
    if (local.conditionsExploitation != null &&
        local.conditionsExploitation!.isNotEmpty) {
      if (local.dispositionsConstructives != null &&
          local.dispositionsConstructives!.isNotEmpty) {
        widgets.add(pw.NewPage());
      }
      widgets.addAll(
        _buildDispositionsTable(
          local.conditionsExploitation!,
          condTitle,
          localType: local.type,
          photoRegistry: photoRegistry,
        ),
      );
    }

    for (int i = 0; i < local.coffrets.length; i++) {
      widgets.add(pw.NewPage());
      widgets.addAll(
        _buildCoffret(
          local.coffrets[i],
          trackedPages,
          local.nom,
          photoCache: photoCache,
          photoRegistry: photoRegistry,
          missionId: missionId,
        ),
      );
    }

    return widgets;
  }

  // En-tête de sous-section épuré textuel (sans bloc graphique)
  static pw.Widget subSectionBar(String title) {
    return PdfReportStyles.subTitle(title);
  }

  // Barre de nom de local (vert clair — comme la trame)
  static pw.Widget localNameBar(String title) {
    return pw.Container(
      width: double.infinity,
      color: PdfColor.fromInt(0xFFD8EAD3), // vert très clair
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: PdfReportStyles.fsH3,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF1E4620),
        ),
      ), // vert foncé
    );
  }

  static List<pw.Widget> buildDispositionsTable(
    List<ElementControle> elements,
    String titre, {
    String? localType,
    Map<String, int>? photoRegistry,
  }) {
    const tableColumnWidths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.4), // POINTS DE VÉRIFICATION
      1: pw.FlexColumnWidth(
        1.2,
      ), // CONFORMITÉ (garantit CONFORMITÉ sur 1 seule ligne)
      2: pw.FlexColumnWidth(1.4), // RÉF. NORMATIVE
      3: pw.FlexColumnWidth(1.4), // FAMILLE DE RISQUE
      4: pw.FlexColumnWidth(0.9), // CRITICITÉ
      5: pw.FlexColumnWidth(1.7), // OBSERVATION
    };

    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {0: pw.FlexColumnWidth(9.0)},
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                titre,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsH3,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );

    final headerTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'POINTS DE VÉRIFICATION',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'CONFORMITÉ',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'RÉF. NORMATIVE',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'FAMILLE DE RISQUE',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'CRITICITÉ',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'OBSERVATION',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );

    final rows = <pw.TableRow>[];
    for (int idx = 0; idx < elements.length; idx++) {
      final el = elements[idx];
      String conf;
      PdfColor confColor;
      if (el.estNA) {
        conf = 'Sans objet';
        confColor = PdfColor.fromInt(0xFFE0E0E0);
      } else if (el.conforme == null) {
        conf = '-';
        confColor = PdfReportStyles.tableRowAlt;
      } else if (el.conforme == true) {
        conf = 'Oui';
        confColor = PdfReportStyles.conformeColor;
      } else {
        conf = 'Non';
        confColor = PdfReportStyles.nonConformeColor;
      }

      // Condition d'affichage : Renseignement uniquement si la conformité est "Non" (conforme == false)
      final isNonConforme = el.conforme == false && !el.estNA;
      final meta = DispositionsConstructivesRegistry.getMetadata(
        el.elementControle,
        localType: localType,
      );
      final rawRef = meta?.referenceNormative ?? el.referenceNormative ?? '';
      final cleanedRef = NormativeReferenceCleaner.clean(rawRef);
      final refNorm = isNonConforme ? (cleanedRef == '-' ? '' : cleanedRef) : '';
      final familleRisque = isNonConforme
          ? (meta?.familleRisque ?? el.familleRisque ?? '')
          : '';
      final criticite = isNonConforme
          ? (meta?.criticite ?? el.criticite ?? '')
          : '';

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: idx.isEven ? PdfColors.white : PdfReportStyles.tableRowAlt,
          ),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                el.elementControle,
                style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
              ),
            ),
            pw.Container(
              color: confColor,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                conf,
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                refNorm,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: PdfReportStyles.fsSmall - 0.5,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                familleRisque,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: PdfReportStyles.fsSmall - 0.5,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                criticite,
                style: pw.TextStyle(
                  font: _getCriticiteFont(criticite),
                  fontSize: PdfReportStyles.fsSmall - 0.5,
                  color: PdfReportStyles.getCriticitePdfColor(criticite),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    el.observation ?? '',
                    style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                    textAlign: pw.TextAlign.center,
                  ),
                  _buildPhotoIndicatorWidget(el.photos, photoRegistry),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final dataTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: rows,
    );

    return [titleTable, headerTable, dataTable];
  }

  static pw.Widget buildAlimentationSiteMtTable(DescriptionInstallations desc) =>
      PdfDescriptionBuilder.buildAlimentationSiteMtTable(desc);

  static List<pw.Widget> buildCelluleSection(
    Cellule cellule, {
    String? localName,
    Map<dynamic, pw.MemoryImage?>? photoCache,
    bool saveFilesToDisk = true,
    Map<String, int>? photoRegistry,
  }) {
    DispositionsConstructivesRegistry.ensureCompleteCelluleChecklist(
      cellule.elementsVerifies,
    );
    String safe(String v) => v.trim().isEmpty ? '-' : v;

    final hasNom = cellule.nom != null && cellule.nom!.trim().isNotEmpty;
    final candidatePhotos = <String>[
      if (cellule.photo != null && cellule.photo!.trim().isNotEmpty)
        cellule.photo!.trim(),
      ...cellule.photos.map((p) => p.trim()).where((p) => p.isNotEmpty),
    ];
    final hasPhoto = candidatePhotos.isNotEmpty;

    pw.MemoryImage? photoImg;
    if (hasPhoto) {
      if (photoCache != null && photoCache.containsKey(cellule)) {
        photoImg = photoCache[cellule];
      }
      if (photoImg == null && !saveFilesToDisk) {
        photoImg = _placeholder1x1;
      }
      if (photoImg == null && saveFilesToDisk) {
        for (final src in candidatePhotos) {
          try {
            final resolved = AppImageUtils.resolvePathSync(src);
            if (resolved != null) {
              final f = File(resolved);
              if (f.existsSync()) {
                final bytes = f.readAsBytesSync();
                if (bytes.isNotEmpty) {
                  photoImg = pw.MemoryImage(bytes);
                  break;
                }
              }
            }
          } catch (_) {}
        }
      }
    }

    pw.TableRow tableDataRowInfo(
      String label,
      String value, {
      required bool alt,
    }) {
      return pw.TableRow(
        decoration: alt ? pw.BoxDecoration(color: PdfReportStyles.tableRowAlt) : null,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      );
    }

    const tableColumnWidths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.4), // POINTS DE VÉRIFICATION
      1: pw.FlexColumnWidth(1.2), // CONFORMITÉ
      2: pw.FlexColumnWidth(1.4), // RÉF. NORMATIVE
      3: pw.FlexColumnWidth(1.4), // FAMILLE DE RISQUE
      4: pw.FlexColumnWidth(0.9), // CRITICITÉ
      5: pw.FlexColumnWidth(1.7), // OBSERVATION
    };

    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {0: pw.FlexColumnWidth(9.0)},
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'CELLULE MOYENNE TENSION',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsH3,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
        if (hasNom)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(left: 6, right: 6, bottom: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  cellule.nom!.trim(),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: PdfReportStyles.fsH3,
                    color: PdfReportStyles.headerColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
      ],
    );

    final infoTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.6),
        1: pw.FlexColumnWidth(2.8),
      },
      children: [
        tableDataRowInfo(
          'Repère',
          safe(cellule.getEffectiveRepere(localName)),
          alt: false,
        ),
        tableDataRowInfo(
          'Fonction de la cellule',
          safe(cellule.fonction),
          alt: false,
        ),
        if (cellule.celluleDepart != null && cellule.celluleDepart!.trim().isNotEmpty)
          tableDataRowInfo(
            'Cellule départ',
            safe(cellule.celluleDepart!),
            alt: false,
          ),
        tableDataRowInfo('Type de cellule', safe(cellule.type), alt: false),
        tableDataRowInfo(
          'Marque',
          safe(cellule.effectiveMarque),
          alt: false,
        ),
        tableDataRowInfo(
          'Modèle',
          safe(cellule.effectiveModele),
          alt: false,
        ),
        tableDataRowInfo(
          'Année de fabrication',
          safe(cellule.effectiveAnnee),
          alt: false,
        ),
        tableDataRowInfo(
          'Tension service (kV)',
          safe(PdfReportStyles.stripUnitFromValue(cellule.tensionService, 'kV')),
          alt: false,
        ),
        tableDataRowInfo(
          'Tension assignée (kV)',
          safe(PdfReportStyles.stripUnitFromValue(cellule.tensionAssignee, 'kV')),
          alt: false,
        ),
        tableDataRowInfo(
          'Pouvoir de coupure assigné (kA)',
          safe(PdfReportStyles.stripUnitFromValue(cellule.pouvoirCoupure, 'kA')),
          alt: false,
        ),
        tableDataRowInfo(
          'Intensité (A)',
          safe(PdfReportStyles.stripUnitFromValue(cellule.calibreDisjoncteur, 'A')),
          alt: false,
        ),
        tableDataRowInfo(
          'Section de câble phase (mm²)',
          safe(formatSectionWithConducteurs(cellule.effectiveSectionCablePhase, cellule.effectiveConducteursPhase)),
          alt: false,
        ),
        if (cellule.effectiveSectionCableNeutre != null &&
            cellule.effectiveSectionCableNeutre!.isNotEmpty &&
            cellule.effectiveSectionCableNeutre != '-')
          tableDataRowInfo(
            'Section de câble neutre (mm²)',
            safe(formatSectionWithConducteurs(cellule.effectiveSectionCableNeutre, cellule.effectiveConducteursNeutre)),
            alt: false,
          ),
        tableDataRowInfo(
          'Nature du réseau',
          safe(cellule.natureReseau ?? ''),
          alt: false,
        ),
        tableDataRowInfo(
          'Numérotation / repérage cellule',
          safe(cellule.numerotation),
          alt: false,
        ),
        tableDataRowInfo(
          "Parafoudres installés sur l'arrivée",
          safe(cellule.parafoudres),
          alt: false,
        ),
        if (cellule.observations != null && cellule.observations!.isNotEmpty) ...[
          () {
            final realObsText = cellule.observations!
                .map((o) {
                  if (o.observation != null && o.observation!.trim().isNotEmpty) {
                    return o.observation!.trim();
                  }
                  final ec = o.elementControle.trim();
                  if (ec.isNotEmpty && !ec.toLowerCase().startsWith('observation ')) {
                    return ec;
                  }
                  return '';
                })
                .where((s) => s.isNotEmpty)
                .join(', ');
            if (realObsText.isNotEmpty) {
              return tableDataRowInfo(
                'Observations',
                realObsText,
                alt: false,
              );
            }
            return pw.TableRow(children: [pw.SizedBox(), pw.SizedBox()]);
          }(),
        ],
      ],
    );

    final topSectionTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(6.0),
        1: pw.FlexColumnWidth(3.0),
      },
      children: [
        pw.TableRow(
          children: [
            infoTable,
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: photoImg != null
                  ? pw.Image(
                      photoImg,
                      width: 165,
                      height: 240,
                      fit: pw.BoxFit.contain,
                    )
                  : pw.SizedBox(width: 165, height: 240),
            ),
          ],
        ),
      ],
    );

    final headerTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'POINTS DE VÉRIFICATION',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'CONFORMITÉ',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'RÉF. NORMATIVE',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'FAMILLE DE RISQUE',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'CRITICITÉ',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'OBSERVATION',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );

    final dataRows = <pw.TableRow>[];
    for (int idx = 0; idx < cellule.elementsVerifies.length; idx++) {
      final el = cellule.elementsVerifies[idx];
      String conf;
      PdfColor confColor;
      if (el.estNA) {
        conf = 'Sans objet';
        confColor = PdfColor.fromInt(0xFFE0E0E0);
      } else if (el.conforme == null) {
        conf = '-';
        confColor = PdfReportStyles.tableRowAlt;
      } else if (el.conforme == true) {
        conf = 'Oui';
        confColor = PdfReportStyles.conformeColor;
      } else {
        conf = 'Non';
        confColor = PdfReportStyles.nonConformeColor;
      }

      final isNonConforme = el.conforme == false && !el.estNA;
      final cleanedRef = NormativeReferenceCleaner.clean(el.referenceNormativeEffective ?? '');
      final refNorm = isNonConforme ? (cleanedRef == '-' ? '' : cleanedRef) : '';
      final familleRisque = isNonConforme
          ? (el.familleRisqueEffective ?? '')
          : '';
      final criticite = isNonConforme ? (el.criticiteEffective ?? '') : '';

      dataRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: idx.isEven ? PdfColors.white : PdfReportStyles.tableRowAlt,
          ),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                el.elementControle,
                style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
              ),
            ),
            pw.Container(
              color: confColor,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                conf,
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                refNorm,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: PdfReportStyles.fsSmall - 0.5,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                familleRisque,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: PdfReportStyles.fsSmall - 0.5,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                criticite,
                style: pw.TextStyle(
                  font: _getCriticiteFont(criticite),
                  fontSize: PdfReportStyles.fsSmall - 0.5,
                  color: PdfReportStyles.getCriticitePdfColor(criticite),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    el.observation ?? '',
                    style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                    textAlign: pw.TextAlign.center,
                  ),
                  _buildPhotoIndicatorWidget(el.photos, photoRegistry),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final dataTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: dataRows,
    );

    final complianceBanner = pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfReportStyles.accentColor,
      ),
      child: pw.Text(
        'VERIFICATION DE CONFORMITE DE LA CELLULE',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: PdfReportStyles.fsSmall,
          color: PdfColors.white,
        ),
      ),
    );

    return [
      pw.SizedBox(height: 6),
      titleTable,
      topSectionTable,
      complianceBanner,
      headerTable,
      dataTable,
      pw.SizedBox(height: 5),
    ];
  }

  static List<pw.Widget> buildTransformateurSection(
    TransformateurMTBT transfo, {
    String? localName,
    Map<dynamic, pw.MemoryImage?>? photoCache,
    bool saveFilesToDisk = true,
    Map<String, int>? photoRegistry,
  }) {
    DispositionsConstructivesRegistry.ensureCompleteTransformateurChecklist(
      transfo.elementsVerifies,
    );
    String safe(String v) => v.trim().isEmpty ? '-' : v;

    final candidatePhotos = <String>[
      if (transfo.photo != null && transfo.photo!.trim().isNotEmpty)
        transfo.photo!.trim(),
      ...transfo.photos.map((p) => p.trim()).where((p) => p.isNotEmpty),
    ];
    final hasPhoto = candidatePhotos.isNotEmpty;

    pw.MemoryImage? photoImg;
    if (hasPhoto) {
      if (photoCache != null && photoCache.containsKey(transfo)) {
        photoImg = photoCache[transfo];
      }
      if (photoImg == null && !saveFilesToDisk) {
        photoImg = _placeholder1x1;
      }
      if (photoImg == null && saveFilesToDisk) {
        for (final src in candidatePhotos) {
          try {
            final resolved = AppImageUtils.resolvePathSync(src);
            if (resolved != null) {
              final f = File(resolved);
              if (f.existsSync()) {
                final bytes = f.readAsBytesSync();
                if (bytes.isNotEmpty) {
                  photoImg = pw.MemoryImage(bytes);
                  break;
                }
              }
            }
          } catch (_) {}
        }
      }
    }

    pw.TableRow tableDataRowInfo(
      String label,
      String value, {
      required bool alt,
    }) {
      return pw.TableRow(
        decoration: alt ? pw.BoxDecoration(color: PdfReportStyles.tableRowAlt) : null,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      );
    }

    const tableColumnWidths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.4), // POINTS DE VÉRIFICATION
      1: pw.FlexColumnWidth(1.2), // CONFORMITÉ
      2: pw.FlexColumnWidth(1.4), // RÉF. NORMATIVE
      3: pw.FlexColumnWidth(1.4), // FAMILLE DE RISQUE
      4: pw.FlexColumnWidth(0.9), // CRITICITÉ
      5: pw.FlexColumnWidth(1.7), // OBSERVATION
    };

    final hasNom = transfo.nom != null && transfo.nom!.trim().isNotEmpty;

    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {0: pw.FlexColumnWidth(9.0)},
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'TRANSFORMATEUR MT/BT',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsH3,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
        if (hasNom)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(left: 6, right: 6, bottom: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  transfo.nom!.trim(),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: PdfReportStyles.fsH3,
                    color: PdfReportStyles.headerColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
      ],
    );

    final infoTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.6),
        1: pw.FlexColumnWidth(2.8),
      },
      children: [
        tableDataRowInfo(
          'Repère',
          safe(transfo.getEffectiveRepere(localName)),
          alt: false,
        ),
        tableDataRowInfo(
          'Type de transformateur',
          safe(transfo.typeTransformateur),
          alt: false,
        ),
        if (transfo.isImmerge &&
            transfo.typeImmersion != null &&
            transfo.typeImmersion!.trim().isNotEmpty)
          tableDataRowInfo(
            'Type d\'immersion',
            safe(transfo.typeImmersion!),
            alt: false,
          ),
        tableDataRowInfo(
          'Marque',
          safe(transfo.effectiveMarque),
          alt: false,
        ),
        tableDataRowInfo(
          'Année de fabrication',
          safe(transfo.effectiveAnneeFabrication),
          alt: false,
        ),
        tableDataRowInfo(
          'Puissance assignée (kVA)',
          safe(PdfReportStyles.stripUnitFromValue(transfo.puissanceAssignee, 'kVA')),
          alt: false,
        ),
        tableDataRowInfo(
          'Tension primaire / secondaire',
          safe(transfo.tensionPrimaireSecondaire),
          alt: false,
        ),
        tableDataRowInfo(
          'Intensité nominale (A)',
          safe(PdfReportStyles.stripUnitFromValue(transfo.intensiteNominale, 'A')),
          alt: false,
        ),
        tableDataRowInfo(
          'Calibre du disjoncteur sortie transformateur (A)',
          safe(PdfReportStyles.stripUnitFromValue(transfo.calibreDisjoncteur, 'A')),
          alt: false,
        ),
        tableDataRowInfo(
          'Courant de réglage du disjoncteur (A)',
          safe(PdfReportStyles.stripUnitFromValue(transfo.courantReglageDisjoncteur, 'A')),
          alt: false,
        ),
        tableDataRowInfo(
          'Section de câble phase (mm²)',
          safe(formatSectionWithConducteurs(transfo.effectiveSectionCablePhase, transfo.effectiveConducteursPhase)),
          alt: false,
        ),
        tableDataRowInfo(
          'Section de câble neutre (mm²)',
          safe(formatSectionWithConducteurs(transfo.effectiveSectionCableNeutre, transfo.effectiveConducteursNeutre)),
          alt: false,
        ),
        tableDataRowInfo('Couplage', safe(transfo.couplage ?? ''), alt: false),
        tableDataRowInfo(
          'Type de réseau',
          safe(transfo.typeReseau ?? ''),
          alt: false,
        ),
        tableDataRowInfo(
          'PCC amont (MVA)',
          safe(PdfReportStyles.stripUnitFromValue(transfo.pccAmont, 'MVA')),
          alt: false,
        ),
        tableDataRowInfo(
          'Puissance',
          safe(transfo.puissanceUcc ?? ''),
          alt: false,
        ),
        tableDataRowInfo(
          'IK3 MAX (kA)',
          safe(PdfReportStyles.stripUnitFromValue(transfo.ik3Max, 'kA')),
          alt: false,
        ),
        if (transfo.typeImmersion == InstallationFieldsRegistry.immersionConservateur)
          tableDataRowInfo(
            'Présence du relais Buchholz',
            safe(transfo.relaisBuchholz),
            alt: false,
          )
        else if (transfo.typeImmersion == InstallationFieldsRegistry.immersionHermetique)
          tableDataRowInfo(
            'Présence de DGPT2',
            safe(transfo.presenceDGPT2 ?? ''),
            alt: false,
          )
        else ...[
          if (transfo.relaisBuchholz.trim().isNotEmpty)
            tableDataRowInfo(
              'Présence du relais Buchholz',
              safe(transfo.relaisBuchholz),
              alt: false,
            ),
          if (transfo.presenceDGPT2 != null && transfo.presenceDGPT2!.trim().isNotEmpty)
            tableDataRowInfo(
              'Présence de DGPT2',
              safe(transfo.presenceDGPT2!),
              alt: false,
            ),
        ],
        tableDataRowInfo(
          'Type de refroidissement',
          safe(transfo.typeRefroidissement),
          alt: false,
        ),
        tableDataRowInfo(
          'Régime du neutre',
          safe(transfo.regimeNeutre),
          alt: false,
        ),
        if (transfo.observations != null && transfo.observations!.isNotEmpty)
          tableDataRowInfo(
            'Observations',
            safe(
              transfo.observations!
                  .map(
                    (o) => (o.observation != null && o.observation!.isNotEmpty)
                        ? o.observation!
                        : o.elementControle,
                  )
                  .where((s) => s.isNotEmpty)
                  .join(', '),
            ),
            alt: false,
          ),
      ],
    );

    final topSectionTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(6.0),
        1: pw.FlexColumnWidth(3.0),
      },
      children: [
        pw.TableRow(
          children: [
            infoTable,
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: photoImg != null
                  ? pw.Image(
                      photoImg,
                      width: 165,
                      height: 260,
                      fit: pw.BoxFit.contain,
                    )
                  : pw.SizedBox(width: 165, height: 260),
            ),
          ],
        ),
      ],
    );

    final headerTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'POINTS DE VÉRIFICATION',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'CONFORMITÉ',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'RÉF. NORMATIVE',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'FAMILLE DE RISQUE',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'CRITICITÉ',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'OBSERVATION',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );

    final dataRows = <pw.TableRow>[];
    for (int idx = 0; idx < transfo.elementsVerifies.length; idx++) {
      final el = transfo.elementsVerifies[idx];
      String conf;
      PdfColor confColor;
      if (el.estNA) {
        conf = 'Sans objet';
        confColor = PdfColor.fromInt(0xFFE0E0E0);
      } else if (el.conforme == null) {
        conf = '-';
        confColor = PdfReportStyles.tableRowAlt;
      } else if (el.conforme == true) {
        conf = 'Oui';
        confColor = PdfReportStyles.conformeColor;
      } else {
        conf = 'Non';
        confColor = PdfReportStyles.nonConformeColor;
      }

      final isNonConforme = el.conforme == false && !el.estNA;
      final cleanedRef = NormativeReferenceCleaner.clean(el.referenceNormativeEffective ?? '');
      final refNorm = isNonConforme ? (cleanedRef == '-' ? '' : cleanedRef) : '';
      final familleRisque = isNonConforme
          ? (el.familleRisqueEffective ?? '')
          : '';
      final criticite = isNonConforme ? (el.criticiteEffective ?? '') : '';

      dataRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: idx.isEven ? PdfColors.white : PdfReportStyles.tableRowAlt,
          ),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                el.elementControle,
                style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
              ),
            ),
            pw.Container(
              color: confColor,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                conf,
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                refNorm,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: PdfReportStyles.fsSmall - 0.5,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                familleRisque,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: PdfReportStyles.fsSmall - 0.5,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                criticite,
                style: pw.TextStyle(
                  font: _getCriticiteFont(criticite),
                  fontSize: PdfReportStyles.fsSmall - 0.5,
                  color: PdfReportStyles.getCriticitePdfColor(criticite),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    el.observation ?? '',
                    style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                    textAlign: pw.TextAlign.center,
                  ),
                  _buildPhotoIndicatorWidget(el.photos, photoRegistry),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final dataTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: dataRows,
    );

    final complianceBanner = pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfReportStyles.accentColor,
      ),
      child: pw.Text(
        'VERIFICATION DE CONFORMITE DU TRANSFORMATEUR',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: PdfReportStyles.fsSmall,
          color: PdfColors.white,
        ),
      ),
    );

    return [
      pw.SizedBox(height: 6),
      titleTable,
      topSectionTable,
      complianceBanner,
      headerTable,
      dataTable,
      pw.SizedBox(height: 5),
    ];
  }

  static pw.Widget buildCpiTable(List<InstallationItem> cpiItems) =>
      PdfDescriptionBuilder.buildCpiTable(cpiItems);

  static pw.Widget buildCpiTestContent(String testResult) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 6),
        pw.Text(
          'ESSAI DE DÉCLENCHEMENT DU CPI',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: PdfReportStyles.fsSmall + 0.5,
            color: PdfColor.fromHex('1B365D'),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'L\'essai consiste à simuler, au moyen d\'une résistance calibrée, un défaut d\'isolement sur le réseau IT surveillé, et à vérifier que le Contrôleur Permanent d\'Isolement détecte ce défaut et déclenche l\'alarme (locale et/ou à distance) au seuil de réglage configuré, sans provoquer de coupure de l\'installation. L\'essai est satisfaisant si l\'alarme se déclenche au seuil attendu et si son report (local et/ou à distance) est correctement transmis.',
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: PdfReportStyles.fsSmall,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'VÉRIFICATION DU REPORT D\'ALARME',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: PdfReportStyles.fsSmall + 0.5,
            color: PdfColor.fromHex('1B365D'),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Le report d\'alarme (voyant local, report GTB/GTC, ou tout autre dispositif de signalisation à distance) est contrôlé conjointement afin de s\'assurer que le personnel d\'exploitation est effectivement informé en cas de premier défaut d\'isolement, condition indispensable à la sécurité en régime IT (absence de coupure automatique au premier défaut).',
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: PdfReportStyles.fsSmall,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 10),
        _resultBox(testResult),
      ],
    );
  }

  static List<pw.Widget> buildCoffret(
    CoffretArmoire coffret,
    Map<String, int> trackedPages,
    String parentName, {
    String? missionId,
    Map<dynamic, pw.MemoryImage?>? photoCache,
    Map<String, int>? photoRegistry,
  }) {
    final widgets = <pw.Widget>[];
    String safe(String v) => v.trim().isEmpty ? 'Non renseigné' : v;
    pw.MemoryImage? photoInterne = photoCache?[coffret];
    if (photoInterne == null && photoCache == null) {
      for (final src in [
        ...coffret.photosInternes,
        ...coffret.photos,
        ...coffret.photosExternes,
      ]) {
        final trimmed = src.trim();
        if (trimmed.isEmpty) continue;
        try {
          final resolved = AppImageUtils.resolvePathSync(trimmed);
          if (resolved != null) {
            final f = File(resolved);
            // Charger l'image uniquement si elle pèse moins de 150 Ko
            if (f.existsSync() && f.lengthSync() < 150000) {
              final bytes = f.readAsBytesSync();
              if (bytes.isNotEmpty) {
                photoInterne = pw.MemoryImage(bytes);
                break;
              }
            }
          }
        } catch (_) {}
      }
    }

    // Helper functions for characteristics
    pw.TableRow tableRowChar(String label, String value) {
      return pw.TableRow(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      );
    }

    pw.TableRow tableRowCharBool(String label, bool value) {
      final color = value ? PdfReportStyles.conformeColor : PdfReportStyles.nonConformeColor;
      final text = value ? 'Oui' : 'Non';
      return pw.TableRow(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
            ),
          ),
          pw.Container(
            color: color,
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(
              text,
              style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
            ),
          ),
        ],
      );
    }

    pw.TableRow tableRowThermoDefect(String label, String? state) {
      PdfColor color;
      String text;
      if (state == 'Oui') {
        color = PdfReportStyles.conformeColor;
        text = 'Oui';
      } else if (state == 'Non') {
        color = PdfReportStyles.nonConformeColor;
        text = 'Non';
      } else {
        color = PdfReportStyles.sansObjetColor;
        text = 'Sans objet';
      }
      return pw.TableRow(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
            ),
          ),
          pw.Container(
            color: color,
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(
              text,
              style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
            ),
          ),
        ],
      );
    }

    pw.TableRow tableRowCustomColor(String label, String value, PdfColor bgColor) {
      return pw.TableRow(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
            ),
          ),
          pw.Container(
            color: bgColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      );
    }

    // ══════════════════════════════════════════════════════════════════════
    // TABLEAU 1 : Titre + Caractéristiques + Photo
    // ══════════════════════════════════════════════════════════════════════
    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.8),
        1: pw.FlexColumnWidth(6.4),
      },
      children: [
        pw.TableRow(
          children: [
            // Left cell: Number (gray background, centered, bold)
            pw.Container(
              color: PdfColor.fromInt(0xFFECECEC),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                coffret.numeroEquipement?.isNotEmpty == true
                    ? coffret.numeroEquipement!
                    : '-',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsH3,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Right cell: Name (white background, left-aligned, bold)
            pw.Container(
              color: PdfColors.white,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                _formatEquipmentTitle(coffret.nom, coffret.type),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsH3,
                  color: PdfReportStyles.headerColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    // Résolution et conformité des indices IP/IK (Repère et Équipement)
    ParsedIpIk repereParsed = const ParsedIpIk();
    if (missionId != null && missionId.isNotEmpty) {
      repereParsed = IpIkEvaluatorService.resolveRepereIpIk(
        missionId: missionId,
        coffret: coffret,
        parentName: parentName,
      );
    } else if (coffret.indiceIpIkRepere != null && coffret.indiceIpIkRepere!.trim().isNotEmpty) {
      repereParsed = ParsedIpIk.parse(coffret.indiceIpIkRepere);
    }

    final bool hasRepereIndice = repereParsed.hasIpOrIk;
    final String repereDisplay = hasRepereIndice ? repereParsed.toString() : 'Absent';
    final PdfColor repereBgColor = hasRepereIndice
        ? PdfReportStyles.conformeColor
        : PdfReportStyles.nonConformeColor;

    final bool hasEquipIndice =
        coffret.indiceIpIk != null && coffret.indiceIpIk!.trim().isNotEmpty;
    final String equipDisplay = hasEquipIndice ? coffret.indiceIpIk!.trim() : 'Absent';
    final bool isEquipConforme = hasEquipIndice &&
        hasRepereIndice &&
        IpIkEvaluatorService.comparerIndicesIpIk(
          coffret.indiceIpIk,
          repereParsed.toString(),
        );
    final PdfColor equipBgColor = isEquipConforme
        ? PdfReportStyles.conformeColor
        : PdfReportStyles.nonConformeColor;

    final charTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.4),
        1: pw.FlexColumnWidth(1.7),
      },
      children: [
        tableRowChar(
          'Repère',
          coffret.repere?.isNotEmpty == true ? coffret.repere! : '-',
        ),
        if (coffret.alimenteeParTransformateur != null)
          tableRowCharBool(
            'Installation alimentée par le transformateur',
            coffret.alimenteeParTransformateur!,
          ),
        if (coffret.presenceCPI != null && coffret.type != 'INVERSEUR')
          tableRowCharBool(
            'Présence CPI',
            coffret.presenceCPI!,
          ),
        tableRowCharBool('Zone ATEX', coffret.zoneAtex),
        tableRowChar('Domaine de tension', safe(coffret.domaineTension)),
        tableRowCharBool(
          getIdentificationLabel(coffret.type),
          coffret.identificationArmoire,
        ),
        tableRowCharBool(
          'Signalisation de danger électrique présente et visible',
          coffret.signalisationDanger,
        ),
        tableRowCharBool(
          'Présence de schéma électrique',
          coffret.presenceSchema,
        ),
        tableRowCharBool('Présence de parafoudre', coffret.presenceParafoudre),
        tableRowCharBool(
          'Vérification par thermographie infrarouge',
          coffret.verificationThermographie,
        ),
        tableRowCustomColor(
          'Indice IP/IK du repère',
          repereDisplay,
          repereBgColor,
        ),
        tableRowCustomColor(
          getIndiceIpIkLabel(coffret.type),
          equipDisplay,
          equipBgColor,
        ),
        if (coffret.type == 'INVERSEUR') ...[
          tableRowChar(
            'Nombre de sorties inverseur',
            '${coffret.sortiesInverseur.length}',
          ),
        ],
        if (coffret.type != 'INVERSEUR') ...[
          tableRowChar(
            'Récapitulatif nombre de départ',
            '${coffret.effectiveDepartures.length}',
          ),
          tableRowChar(
            'Récapitulatif nombre de circuit terminaux',
            '${coffret.effectiveTerminalCircuits.length}',
          ),
        ],
      ],
    );

    final topSectionTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(5.1),
        1: pw.FlexColumnWidth(3.2),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(child: charTable),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: photoInterne != null
                  ? pw.Image(
                      photoInterne,
                      width: 185,
                      height: 175,
                      fit: pw.BoxFit.contain,
                    )
                  : pw.Text(
                      'Aucune photo',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: PdfReportStyles.fsSmall,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );

    if ((coffret as dynamic).accessible == false) {
      widgets.add(
        PageTracker(
          key: 'audit_coffret_${parentName}_${coffret.nom}',
          registry: trackedPages,
          child: titleTable,
        ),
      );
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            border: pw.Border.all(color: PdfColors.red200),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.red,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    '[!] ÉQUIPEMENT INACCESSIBLE — NON INSPECTÉ',
                    style: pw.TextStyle(
                      color: PdfColors.red,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Cet équipement n'a pas pu être inspecté lors de la visite. "
                "Aucun point de contrôle n'a pu être vérifié.",
                style: pw.TextStyle(
                  color: PdfColors.red900,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      );

      widgets.add(pw.SizedBox(height: 6));
      if (photoInterne != null) {
        widgets.add(
          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Image(
                photoInterne,
                width: 250,
                height: 180,
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          pw.Center(
            child: pw.Container(
              width: 170,
              height: 95,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF9F9F9),
                border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.4),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "Aucune photo de l'équipement",
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        );
      }

      return widgets;
    }

    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PageTracker(
            key: 'audit_coffret_${parentName}_${coffret.nom}',
            registry: trackedPages,
            child: titleTable,
          ),
          topSectionTable,
        ],
      ),
    );

    // ══════════════════════════════════════════════════════════════════════
    // OBSERVATION DU SLIDE 1 (DESCRIPTION DE L'ÉQUIPEMENT)
    // ══════════════════════════════════════════════════════════════════════
    if (coffret.description != null && coffret.description!.trim().isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFFFF3E0),
            border: pw.Border.all(
              color: PdfColor.fromInt(0xFFE65100),
              width: 0.5,
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Observation : ',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfColor.fromInt(0xFFE65100),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  _normalizeText(coffret.description!.trim()),
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: PdfReportStyles.fsSmall,
                    color: PdfReportStyles.darkGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ══════════════════════════════════════════════════════════════════════
    // TABLEAU 2 : Alimentations (+ Protection de tête si présente)
    // ══════════════════════════════════════════════════════════════════════
    if (coffret.alimentations.isNotEmpty || coffret.protectionTete != null || !coffret.isDepartPrisAvecProtection) {
      widgets.add(pw.SizedBox(height: 3));
      final grammar = _getEquipmentGrammar(coffret.type);
      final String sourceBannerTitle = coffret.type == 'INVERSEUR'
          ? "IDENTIFICATION DES SOURCES D'ALIMENTATION ET DES SORTIES DE L'INVERSEUR"
          : "IDENTIFICATION DE LA SOURCE D'ALIMENTATION ET DU DISPOSITIF DE TETE ${grammar.du}";
      widgets.add(
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.accentColor,
          ),
          child: pw.Text(
            sourceBannerTitle,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: PdfReportStyles.fsSmall,
              color: PdfColors.white,
            ),
          ),
        ),
      );
      final List<pw.Widget> tables = <pw.Widget>[];

      if (coffret.alimentations.isNotEmpty) {
        if (coffret.type == 'INVERSEUR') {
          // ══════════════════════════════════════════════════════════════════
          // INVERSEUR : 1. Tableau ORIGINE DE LA SOURCE (Alimentation 1 & 2 - MAX 2 LIGNES)
          // ══════════════════════════════════════════════════════════════════
          final entrees = coffret.alimentationsInverseurEntree;
          if (entrees.isNotEmpty) {
            final alimentRows = <pw.TableRow>[];
            alimentRows.add(
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE8F0FB),
                ),
                children: [
                  _thCell("Origine de la source d'alimentation"),
                  _thCell('Type protection'),
                  _thCell('Courbe'),
                  _thCell('PDC (kA)'),
                  _thCell('Icc3 max (kA)'),
                  _thCell('Calibre (A)'),
                  _thCell('DDR (I\u0394n(mA))'),
                  _thCell('Section de câble phase (mm²)'),
                  _thCell('Section de câble neutre (mm²)'),
                  _thCell('Nature du câble'),
                ],
              ),
            );

            for (int i = 0; i < entrees.length; i++) {
              final a = entrees[i];
              final String sVal = a.source.trim();
              final String label = (sVal.isNotEmpty && sVal.toLowerCase() != 'inconnu')
                  ? sVal
                  : 'Source inconnue';
              alimentRows.add(
                pw.TableRow(
                  children: [
                    _valueCell(label),
                    _protectionCell(a.typeProtection, a.marqueDisjoncteur),
                    _valueCell(a.courbe != null && a.courbe!.isNotEmpty ? a.courbe! : '-'),
                    _valueCell(a.pdcKA.isNotEmpty ? a.pdcKA : '-'),
                    _valueCell(a.icc3Max != null && a.icc3Max!.isNotEmpty ? a.icc3Max! : '-'),
                    _valueCell(PdfReportStyles.stripUnitFromValue(a.calibre, 'A')),
                    _valueCell(PdfReportStyles.stripUnitFromValue(a.ddr, 'mA')),
                    _valueCell(formatSectionWithConducteurs(a.effectiveSectionCablePhase, a.effectiveConducteursPhase)),
                    _valueCell(formatSectionWithConducteurs(a.effectiveSectionCableNeutre, a.effectiveConducteursNeutre)),
                    _valueCell(a.natureCable != null && a.natureCable!.isNotEmpty ? a.natureCable! : '-'),
                  ],
                ),
              );
            }

            tables.add(
              pw.Table(
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
                border: pw.TableBorder(
                  left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                  right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                  bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                  top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                  verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                  horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.6),
                  1: pw.FlexColumnWidth(1.3),
                  2: pw.FlexColumnWidth(0.65),
                  3: pw.FlexColumnWidth(0.65),
                  4: pw.FlexColumnWidth(0.75),
                  5: pw.FlexColumnWidth(0.65),
                  6: pw.FlexColumnWidth(0.85),
                  7: pw.FlexColumnWidth(0.85),
                  8: pw.FlexColumnWidth(0.85),
                  9: pw.FlexColumnWidth(0.85),
                },
                children: alimentRows,
              ),
            );
          }

          // ══════════════════════════════════════════════════════════════════
          // INVERSEUR : 2. NOUVEAU TABLEAU DÉDIÉ "SORTIE INVERSEUR" (DYNAMIQUE : 1 à N LIGNES)
          // ══════════════════════════════════════════════════════════════════
          final sorties = coffret.sortiesInverseur;
          if (sorties.isNotEmpty) {
            if (tables.isNotEmpty) {
              tables.add(pw.SizedBox(height: 3));
            }

            final sortieRows = <pw.TableRow>[];
            sortieRows.add(
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE8F0FB),
                ),
                children: [
                  _thCell('SORTIE INVERSEUR'),
                  _thCell('Type protection'),
                  _thCell('Courbe'),
                  _thCell('PDC (kA)'),
                  _thCell('Icc3 max (kA)'),
                  _thCell('Calibre (A)'),
                  _thCell('DDR (I\u0394n(mA))'),
                  _thCell('Section de câble phase (mm²)'),
                  _thCell('Section de câble neutre (mm²)'),
                  _thCell('Nature du câble'),
                ],
              ),
            );

            for (int i = 0; i < sorties.length; i++) {
              final s = sorties[i];
              final String sVal = s.source.trim();
              final String label = (sVal.isNotEmpty && sVal.toLowerCase() != 'inconnu')
                  ? sVal
                  : 'Source inconnue';
              sortieRows.add(
                pw.TableRow(
                  children: [
                    _valueCell(label),
                    _protectionCell(s.typeProtection, s.marqueDisjoncteur),
                    _valueCell(s.courbe != null && s.courbe!.isNotEmpty ? s.courbe! : '-'),
                    _valueCell(s.pdcKA.isNotEmpty ? s.pdcKA : '-'),
                    _valueCell(s.icc3Max != null && s.icc3Max!.isNotEmpty ? s.icc3Max! : '-'),
                    _valueCell(PdfReportStyles.stripUnitFromValue(s.calibre, 'A')),
                    _valueCell(PdfReportStyles.stripUnitFromValue(s.ddr, 'mA')),
                    _valueCell(formatSectionWithConducteurs(s.effectiveSectionCablePhase, s.effectiveConducteursPhase)),
                    _valueCell(formatSectionWithConducteurs(s.effectiveSectionCableNeutre, s.effectiveConducteursNeutre)),
                    _valueCell(s.natureCable != null && s.natureCable!.isNotEmpty ? s.natureCable! : '-'),
                  ],
                ),
              );
            }

            tables.add(
              pw.Table(
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
                border: pw.TableBorder(
                  left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                  right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                  bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                  top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                  verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                  horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.6),
                  1: pw.FlexColumnWidth(1.3),
                  2: pw.FlexColumnWidth(0.65),
                  3: pw.FlexColumnWidth(0.65),
                  4: pw.FlexColumnWidth(0.75),
                  5: pw.FlexColumnWidth(0.65),
                  6: pw.FlexColumnWidth(0.85),
                  7: pw.FlexColumnWidth(0.85),
                  8: pw.FlexColumnWidth(0.85),
                  9: pw.FlexColumnWidth(0.85),
                },
                children: sortieRows,
              ),
            );
          }
        } else {
          // AUTRES ÉQUIPEMENTS (TGBT, ARMOIRE, COFFRET CLASSIQUE)
          final alimentRows = <pw.TableRow>[];

          alimentRows.add(
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
              children: [
                _thCell("Origine de la source d'alimentation"),
                _thCell('Type protection'),
                _thCell('Courbe'),
                _thCell('PDC (kA)'),
                _thCell('Icc3 max (kA)'),
                _thCell('Calibre (A)'),
                _thCell('DDR (I\u0394n(mA))'),
                _thCell('Section de câble phase (mm²)'),
                _thCell('Section de câble neutre (mm²)'),
                _thCell('Nature du câble'),
              ],
            ),
          );

          final alimsToDisplay = EquipmentTypeTransitionService.filterAlimentationsForDisplay(
            coffret.alimentations,
            coffret.type,
          );
          for (final a in alimsToDisplay) {
            final String rawSource = a.source.trim().isNotEmpty
                ? a.source.trim()
                : (coffret.sourceNomComplet ?? '').trim();
            final String label = (rawSource.isNotEmpty && rawSource.toLowerCase() != 'inconnu')
                ? rawSource
                : 'Source inconnue';
            alimentRows.add(
              pw.TableRow(
                children: [
                  _valueCell(label),
                  _protectionCell(a.typeProtection, a.marqueDisjoncteur),
                  _valueCell(a.courbe != null && a.courbe!.isNotEmpty ? a.courbe! : '-'),
                  _valueCell(a.pdcKA.isNotEmpty ? a.pdcKA : '-'),
                  _valueCell(a.icc3Max != null && a.icc3Max!.isNotEmpty ? a.icc3Max! : '-'),
                  _valueCell(PdfReportStyles.stripUnitFromValue(a.calibre, 'A')),
                  _valueCell(PdfReportStyles.stripUnitFromValue(a.ddr, 'mA')),
                  _valueCell(formatSectionWithConducteurs(a.effectiveSectionCablePhase, a.effectiveConducteursPhase)),
                  _valueCell(formatSectionWithConducteurs(a.effectiveSectionCableNeutre, a.effectiveConducteursNeutre)),
                  _valueCell(a.natureCable != null && a.natureCable!.isNotEmpty ? a.natureCable! : '-'),
                ],
              ),
            );
          }

          tables.add(
            pw.Table(
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
              border: pw.TableBorder(
                left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
                horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.6),
                1: pw.FlexColumnWidth(1.3),
                2: pw.FlexColumnWidth(0.65),
                3: pw.FlexColumnWidth(0.65),
                4: pw.FlexColumnWidth(0.75),
                5: pw.FlexColumnWidth(0.65),
                6: pw.FlexColumnWidth(0.85),
                7: pw.FlexColumnWidth(0.85),
                8: pw.FlexColumnWidth(0.85),
                9: pw.FlexColumnWidth(0.85),
              },
              children: alimentRows,
            ),
          );
        }
      }

      if (coffret.type != 'INVERSEUR' && (coffret.protectionTete != null || !coffret.isDepartPrisAvecProtection)) {
        final pt = coffret.protectionTete ?? Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: '');
        final bool isAvecProtection = coffret.isDepartPrisAvecProtection;

        final String statusLabel = isAvecProtection ? 'Présent' : 'Absent';

        final pw.Widget protectionTeteTable = pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder(
            left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.6),
            1: pw.FlexColumnWidth(1.3),
            2: pw.FlexColumnWidth(0.65),
            3: pw.FlexColumnWidth(0.65),
            4: pw.FlexColumnWidth(0.75),
            5: pw.FlexColumnWidth(0.65),
            6: pw.FlexColumnWidth(0.85),
            7: pw.FlexColumnWidth(0.85),
            8: pw.FlexColumnWidth(0.85),
            9: pw.FlexColumnWidth(0.85),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE8F0FB),
              ),
              children: [
                _thCell(getProtectionTeteLabel(coffret.type)),
                _thCell('Type protection'),
                _thCell('Courbe'),
                _thCell('PDC (kA)'),
                _thCell('Icc3 max (kA)'),
                _thCell('Calibre (A)'),
                _thCell('DDR (I\u0394n(mA))'),
                _thCell('Section de câble phase (mm²)'),
                _thCell('Section de câble neutre (mm²)'),
                _thCell('Nature du câble'),
              ],
            ),
            pw.TableRow(
              children: [
                _valueCell(statusLabel),
                isAvecProtection ? _protectionCell(pt.typeProtection, pt.marqueDisjoncteur) : _valueCell('absent'),
                _valueCell(isAvecProtection ? ((pt.courbe != null && pt.courbe!.isNotEmpty) ? pt.courbe! : '-') : '-'),
                _valueCell(isAvecProtection ? (pt.pdcKA.isNotEmpty ? pt.pdcKA : '-') : '-'),
                _valueCell(isAvecProtection ? ((pt.icc3Max != null && pt.icc3Max!.isNotEmpty) ? pt.icc3Max! : '-') : '-'),
                _valueCell(isAvecProtection ? PdfReportStyles.stripUnitFromValue(pt.calibre, 'A') : '-'),
                _valueCell(isAvecProtection ? PdfReportStyles.stripUnitFromValue(pt.ddr, 'mA') : '-'),
                _valueCell(formatSectionWithConducteurs(pt.effectiveSectionCablePhase, pt.effectiveConducteursPhase)),
                _valueCell(formatSectionWithConducteurs(pt.effectiveSectionCableNeutre, pt.effectiveConducteursNeutre)),
                _valueCell(isAvecProtection ? ((pt.natureCable != null && pt.natureCable!.isNotEmpty) ? pt.natureCable! : '-') : '-'),
              ],
            ),
          ],
        );

        if (tables.isNotEmpty) {
          tables.add(pw.SizedBox(height: 3));
        }
        tables.add(protectionTeteTable);
      }

      widgets.addAll(tables);
    }

    // ══════════════════════════════════════════════════════════════════════
    // TABLEAU DÉPARTS ISSUS DE CE TGBT/ARMOIRE/COFFRET
    // ══════════════════════════════════════════════════════════════════════
    if (coffret.type != 'INVERSEUR' && coffret.effectiveDepartures.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      final grammar = _getEquipmentGrammar(coffret.type);
      widgets.add(
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.accentColor,
          ),
          child: pw.Text(
            'IDENTIFICATION DES DÉPARTS ISSUS ${grammar.deCe}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: PdfReportStyles.fsSmall,
              color: PdfColors.white,
            ),
          ),
        ),
      );
      final departRows = <pw.TableRow>[];
      departRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE8F0FB),
          ),
          children: [
            _thCell('Protection de tête du depart'),
            _thCell('Identification du depart'),
            _thCell('Type protection'),
            _thCell('Courbe'),
            _thCell('PDC (kA)'),
            _thCell('Icc3 max (kA)'),
            _thCell('Calibre (A)'),
            _thCell('DDR (I\u0394n (mA))'),
            _thCell('Section de câble phase (mm²)'),
            _thCell('Section de câble neutre (mm²)'),
            _thCell('Nature du câble'),
          ],
        ),
      );
      for (final dep in coffret.effectiveDepartures) {
        departRows.add(
          pw.TableRow(
            children: [
              _valueCell(dep.protectionTete.isNotEmpty ? dep.protectionTete : '-'),
              _valueCell(dep.identification.isNotEmpty ? dep.identification : '-'),
              _protectionCell(dep.typeProtection, dep.marque),
              _valueCell(dep.courbe.isNotEmpty ? dep.courbe : '-'),
              _valueCell(dep.pdcKA.isNotEmpty ? dep.pdcKA : '-'),
              _valueCell(dep.icc3Max.isNotEmpty ? dep.icc3Max : '-'),
              _valueCell(PdfReportStyles.stripUnitFromValue(dep.calibre, 'A')),
              _valueCell(PdfReportStyles.stripUnitFromValue(dep.ddr, 'mA')),
              _valueCell(formatSectionWithConducteurs(dep.effectiveSectionCablePhase, dep.effectiveConducteursPhase)),
              _valueCell(formatSectionWithConducteurs(dep.effectiveSectionCableNeutre, dep.effectiveConducteursNeutre)),
              _valueCell(dep.natureCable != null && dep.natureCable!.isNotEmpty ? dep.natureCable! : '-'),
            ],
          ),
        );
      }
      widgets.add(
        pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder(
            left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.95),
            1: pw.FlexColumnWidth(1.05),
            2: pw.FlexColumnWidth(1.2),
            3: pw.FlexColumnWidth(0.55),
            4: pw.FlexColumnWidth(0.55),
            5: pw.FlexColumnWidth(0.65),
            6: pw.FlexColumnWidth(0.55),
            7: pw.FlexColumnWidth(0.75),
            8: pw.FlexColumnWidth(0.75),
            9: pw.FlexColumnWidth(0.75),
            10: pw.FlexColumnWidth(0.75),
          },
          children: departRows,
        ),
      );
    }

    // ══════════════════════════════════════════════════════════════════════
    // TABLEAU CIRCUITS TERMINAUX ISSUS DE CE TGBT/ARMOIRE/COFFRET
    // ══════════════════════════════════════════════════════════════════════
    if (coffret.type != 'INVERSEUR' && coffret.effectiveTerminalCircuits.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      final grammar = _getEquipmentGrammar(coffret.type);
      widgets.add(
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.accentColor,
          ),
          child: pw.Text(
            'IDENTIFICATION DES CIRCUITS TERMINAUX ISSUS ${grammar.deCe}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: PdfReportStyles.fsSmall,
              color: PdfColors.white,
            ),
          ),
        ),
      );
      final circuitRows = <pw.TableRow>[];
      circuitRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE8F0FB),
          ),
          children: [
            _thCell('Protection de tête du circuit'),
            _thCell('Identification du circuit'),
            _thCell('Type protection'),
            _thCell('Courbe'),
            _thCell('PDC (kA)'),
            _thCell('Icc3 max (kA)'),
            _thCell('Calibre (A)'),
            _thCell('DDR (I\u0394n (mA))'),
            _thCell('Section de câble phase (mm²)'),
            _thCell('Section de câble neutre (mm²)'),
            _thCell('Nature du câble'),
          ],
        ),
      );
      for (final ct in coffret.effectiveTerminalCircuits) {
        circuitRows.add(
          pw.TableRow(
            children: [
              _valueCell(ct.protectionTete.isNotEmpty ? ct.protectionTete : '-'),
              _valueCell(ct.identification.isNotEmpty ? ct.identification : '-'),
              _protectionCell(ct.typeProtection, ct.marque),
              _valueCell(ct.courbe.isNotEmpty ? ct.courbe : '-'),
              _valueCell(ct.pdcKA.isNotEmpty ? ct.pdcKA : '-'),
              _valueCell(ct.icc3Max.isNotEmpty ? ct.icc3Max : '-'),
              _valueCell(PdfReportStyles.stripUnitFromValue(ct.calibre, 'A')),
              _valueCell(PdfReportStyles.stripUnitFromValue(ct.ddr, 'mA')),
              _valueCell(formatSectionWithConducteurs(ct.effectiveSectionCablePhase, ct.effectiveConducteursPhase)),
              _valueCell(formatSectionWithConducteurs(ct.effectiveSectionCableNeutre, ct.effectiveConducteursNeutre)),
              _valueCell(ct.natureCable != null && ct.natureCable!.isNotEmpty ? ct.natureCable! : '-'),
            ],
          ),
        );
      }
      widgets.add(
        pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder(
            left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
            horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.95),
            1: pw.FlexColumnWidth(1.05),
            2: pw.FlexColumnWidth(1.2),
            3: pw.FlexColumnWidth(0.55),
            4: pw.FlexColumnWidth(0.55),
            5: pw.FlexColumnWidth(0.65),
            6: pw.FlexColumnWidth(0.55),
            7: pw.FlexColumnWidth(0.75),
            8: pw.FlexColumnWidth(0.75),
            9: pw.FlexColumnWidth(0.75),
            10: pw.FlexColumnWidth(0.75),
          },
          children: circuitRows,
        ),
      );
    }

    // ══════════════════════════════════════════════════════════════════════
    // POINTS DE VÉRIFICATION
    // ══════════════════════════════════════════════════════════════════════
    if (coffret.pointsVerification.isNotEmpty) {
      if (coffret.type == 'INVERSEUR') {
        DispositionsConstructivesRegistry.ensureCompleteInverseurChecklist(
          coffret.pointsVerification,
        );
      } else {
        DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(
          coffret.pointsVerification,
        );
      }

      // Synchronisation déterministe du point IP/IK avec la règle métier
      IpIkEvaluatorService.syncIpIkPoint(
        coffret: coffret,
        missionId: missionId ?? '',
        parentName: parentName,
      );
      widgets.add(pw.SizedBox(height: 3));
      final grammar = _getEquipmentGrammar(coffret.type);
      widgets.add(
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.accentColor,
          ),
          child: pw.Text(
            'VERIFICATION DE CONFORMITE ${grammar.du}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: PdfReportStyles.fsSmall,
              color: PdfColors.white,
            ),
          ),
        ),
      );
      final pointsToDisplay = EquipmentTypeTransitionService.filterPointsForDisplay(
        coffret.pointsVerification,
        coffret.type,
      );
      widgets.add(
        _buildPointsVerificationTable(
          pointsToDisplay,
          coffretType: coffret.type,
          photoRegistry: photoRegistry,
        ),
      );
    }

    // ══════════════════════════════════════════════════════════════════════
    // OBSERVATIONS LIBRES
    // ══════════════════════════════════════════════════════════════════════
    if (coffret.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(
        _buildSimpleObsTable(
          coffret.observationsLibres,
          'Observations',
          photoRegistry: photoRegistry,
        ),
      );
    }

    return widgets;
  }

  static String formatTypeProtectionWithMarque(String typeProtection, String? marqueDisjoncteur) {
    if (typeProtection.trim().isEmpty || typeProtection == '-') return 'absent';
    if (marqueDisjoncteur != null && marqueDisjoncteur.trim().isNotEmpty) {
      return '$typeProtection\n(${marqueDisjoncteur.trim()})';
    }
    return '$typeProtection\n(Non défini)';
  }

  /// Cellule valeur (police normale, centrée horizontalement et verticalement)
  static pw.Widget valueCell(
    String text, {
    pw.Alignment alignment = pw.Alignment.center,
    pw.TextAlign textAlign = pw.TextAlign.center,
  }) => pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    child: pw.Text(
      text,
      style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
      textAlign: textAlign,
    ),
  );

  /// En-tête tableau (fond bleu clair, gras, centré)
  static pw.Widget thCell(String text) => pw.Container(
    color: PdfColor.fromInt(0xFFE8F0FB),
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    alignment: pw.Alignment.center,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: fontBold,
        fontSize: PdfReportStyles.fsSmall,
        color: PdfReportStyles.headerColor,
      ),
      textAlign: pw.TextAlign.center,
    ),
  );

  static pw.Widget buildPointsVerificationTable(
    List<PointVerification> points, {
    String? coffretType,
    Map<String, int>? photoRegistry,
  }) {
    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.4), // POINTS DE VÉRIFICATION
        1: pw.FlexColumnWidth(1.2), // CONFORMITÉ
        2: pw.FlexColumnWidth(1.4), // RÉF. NORMATIVE
        3: pw.FlexColumnWidth(1.4), // FAMILLE DE RISQUE
        4: pw.FlexColumnWidth(0.9), // CRITICITÉ
        5: pw.FlexColumnWidth(1.7), // OBSERVATION
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            _thCell('POINTS DE VÉRIFICATION'),
            _thCell('CONFORMITÉ'),
            _thCell('RÉF. NORMATIVE'),
            _thCell('FAMILLE DE RISQUE'),
            _thCell('CRITICITÉ'),
            _thCell('OBSERVATION'),
          ],
        ),
        ...points.asMap().entries.map((e) {
          final pv = e.value;
          final conf = pv.conformite.toLowerCase().trim();
          final isConf = conf == 'oui';
          final isNA =
              conf == 'na' ||
              conf == 'non_applicable' ||
              conf == 'sans_objet' ||
              conf == 'n/a' ||
              conf == 'sans objet';
          final isNonConf = !isConf && !isNA;

          final confColor = isNA
              ? PdfColor.fromInt(0xFFE0E0E0)
              : (isConf ? PdfReportStyles.conformeColor : PdfReportStyles.nonConformeColor);
          final confText = isNA ? 'Sans objet' : (isConf ? 'Oui' : 'Non');

          final meta = DispositionsConstructivesRegistry.getCoffretMetadata(
            pv.pointVerification,
            coffretType: coffretType,
          );
          final rawRef = meta?.referenceNormative ?? pv.referenceNormative ?? '';
          final cleanedRef = NormativeReferenceCleaner.clean(rawRef);
          final refNorm = isNonConf ? (cleanedRef == '-' ? '' : cleanedRef) : '';
          final familleRisque = isNonConf ? (meta?.familleRisque ?? '') : '';
          final criticite = isNonConf ? (meta?.criticite ?? '') : '';

          final obsText = pv.observations != null && pv.observations!.isNotEmpty
              ? pv.observations!
                    .map((obs) => obs.observation ?? '')
                    .where((s) => s.isNotEmpty)
                    .join('\n')
              : (pv.observation ?? '');

          final allPvPhotos = <String>[...pv.photos];
          if (pv.observations != null) {
            for (final obs in pv.observations!) {
              allPvPhotos.addAll(obs.photos);
            }
          }

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: e.key.isEven ? PdfColors.white : PdfReportStyles.tableRowAlt,
            ),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 3,
                ),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  pv.pointVerification,
                  style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsSmall),
                ),
              ),
              pw.Container(
                color: confColor,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 3,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  confText,
                  style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 3,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  refNorm,
                  style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 3,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  familleRisque,
                  style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 3,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  criticite,
                  style: pw.TextStyle(
                    font: _getCriticiteFont(criticite),
                    fontSize: PdfReportStyles.fsSmall,
                    color: PdfReportStyles.getCriticitePdfColor(criticite),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 3,
                ),
                alignment: pw.Alignment.center,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      obsText,
                      style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                      textAlign: pw.TextAlign.center,
                    ),
                    _buildPhotoIndicatorWidget(allPvPhotos, photoRegistry),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget buildSimpleObsTable(
    List<ObservationLibre> obs,
    String titre, {
    Map<String, int>? photoRegistry,
  }) {
    pw.Widget obsCell(ObservationLibre o) {
      return pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              o.texte,
              style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
              textAlign: pw.TextAlign.center,
            ),
            _buildPhotoIndicatorWidget(o.photos, photoRegistry),
          ],
        ),
      );
    }

    final hasAnyNormRef = obs.any((o) => o.hasNormativeReference);
    if (hasAnyNormRef) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(0.5),
          1: const pw.FlexColumnWidth(3.5),
          2: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
            children: [
              PdfReportStyles.cell('N°', isHeader: true),
              PdfReportStyles.cell(titre, isHeader: true),
              PdfReportStyles.cell('Réf. Normative', isHeader: true),
            ],
          ),
          ...obs.asMap().entries.map(
            (e) => pw.TableRow(
              decoration: pw.BoxDecoration(
                color: e.key.isEven ? PdfColors.white : PdfReportStyles.tableRowAlt,
              ),
              children: [
                PdfReportStyles.cell('${e.key + 1}', isHeader: false),
                obsCell(e.value),
                PdfReportStyles.cell(
                  NormativeReferenceCleaner.clean(e.value.referenceNormative ?? '-'),
                  isHeader: false,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [PdfReportStyles.cell('N°', isHeader: true), PdfReportStyles.cell(titre, isHeader: true)],
        ),
        ...obs.asMap().entries.map(
          (e) => pw.TableRow(
            decoration: pw.BoxDecoration(
              color: e.key.isEven ? PdfColors.white : PdfReportStyles.tableRowAlt,
            ),
            children: [
              PdfReportStyles.cell('${e.key + 1}', isHeader: false),
              obsCell(e.value),
            ],
          ),
        ),
      ],
    );
  }


}
