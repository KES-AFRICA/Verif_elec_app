// test/services/pdf_q18_report_service_test.dart

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/pdf/builders/pdf_cover_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_conclusion_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_dangers_synthesis_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_identification_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_perimetre_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_photos_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_regulatory_builder.dart';
import 'package:inspec_app/services/pdf/q18/pdf_q18_report_service.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

void main() {
  group('Q18 Report Service & Builders Tests (APSAD D18)', () {
    late Mission sampleMission;
    late RenseignementsGeneraux sampleRg;
    late Q18DataSnapshot sampleSnapshot;

    setUp(() {
      sampleMission = Mission(
        id: 'mission_q18_test_001',
        nomClient: 'CIMENCAM',
        nomSite: 'Usine de Nomayos',
        status: 'en_cours',
        createdAt: DateTime(2026, 2, 10),
        updatedAt: DateTime(2026, 2, 10),
        dateIntervention: DateTime(2026, 2, 10),
      );

      sampleRg = RenseignementsGeneraux(
        missionId: 'mission_q18_test_001',
        etablissement: 'CIMENCAM S.A.',
        installation: 'Usine de broyage et ensachage',
        activite: 'Production de ciments industriels',
        nomSite: 'Site Industriel de Nomayos',
        dateDebut: DateTime(2026, 2, 10),
        dateFin: DateTime(2026, 2, 12),
        dureeJours: 3,
        registreControle: 'Présenté',
        compteRendu: [],
        accompagnateurs: [],
        verificateurs: [],
        updatedAt: DateTime(2026, 2, 12),
      );

      const quantities = Q18InstallationsQuantities(
        nbLocauxTechniquesHTA: 2,
        nbTransformateurs: 3,
        transformateursPuissanceText: '1250 kVA, 1600 kVA',
        nbCellules: 6,
        nbLocauxGE: 1,
        nbGroupesElectrogenes: 1,
        groupesPuissanceText: '800 kVA',
        nbInverseurs: 1,
        nbLocauxTechniquesBT: 4,
        nbTGBT: 2,
        nbArmoires: 12,
        nbCoffrets: 35,
        presenceParatonnerre: true,
        presenceParafoudreInverseur: 'Présent (1/1)',
        presenceParafoudreTGBT: 'Présent (2/2)',
        presenceParafoudreArmoire: 'Partiel (8/12)',
        presenceParafoudreCoffret: 'Absent (0/35)',
        presenceCentralePhotovoltaique: 'Sans objet (0)',
      );

      final perimetreCouverts = [
        const Q18PerimetreItem(
          zone: 'Poste HT/BT Principal',
          repere: 'Local Transfo 1 & 2',
          equipements: 'Cellules HTA, 2 Transfos 1250kVA, TGBT Normal',
          isCouvert: true,
        ),
        const Q18PerimetreItem(
          zone: 'Bâtiment Broyage',
          repere: 'Salle électrique Broyeur',
          equipements: 'Armoires départs moteurs, Coffrets de commande',
          isCouvert: true,
        ),
      ];

      final exclusions = [
        const Q18PerimetreItem(
          zone: 'Silo Ciment 4',
          repere: 'Passerelle supérieure',
          equipements: 'Coffret dépoussiéreur',
          isCouvert: false,
          motifExclusion: 'Travaux en hauteur en cours, accès consigné',
        ),
      ];

      final documents = [
        const Q18DocumentConsulteItem(index: 1, titre: 'Schémas unifilaires des tableaux généraux', isDisponible: true),
        const Q18DocumentConsulteItem(index: 2, titre: 'Registre de sécurité et carnet d\'entretien', isDisponible: true),
        const Q18DocumentConsulteItem(index: 3, titre: 'Rapport de vérification périodique N-1', isDisponible: true),
        const Q18DocumentConsulteItem(index: 4, titre: 'Compte-rendu Q18 de l\'exercice précédent', isDisponible: false),
        const Q18DocumentConsulteItem(index: 5, titre: 'Plans de zonage ATEX / BE2', isDisponible: false),
        const Q18DocumentConsulteItem(index: 6, titre: 'Fiches techniques et notices de conformité', isDisponible: true),
      ];

      final dangers = [
        const Q18DangerItem(
          index: 1,
          zone: 'Poste HTA',
          repere: 'TGBT-N',
          designation: 'Jeu de barres principal',
          dangerConstate: 'Échauffement anormal constaté sur la connexion Phase 2 (78°C sous 350A)',
          familleDeRisque: 'Échauffement et connexions défectueuses',
          niveau: Q18DangerLevel.dangerAvere,
        ),
        const Q18DangerItem(
          index: 2,
          zone: 'Bâtiment Broyage',
          repere: 'ARM-BR01',
          designation: 'Armoire broyeur',
          dangerConstate: 'Presse-étoupes manquants sur arrivée câble puissance, pénétration de poussières',
          familleDeRisque: 'Protection contre les contacts directs / IP',
          niveau: Q18DangerLevel.degradation,
        ),
        const Q18DangerItem(
          index: 3,
          zone: 'Atelier Mécanique',
          repere: 'COF-AT02',
          designation: 'Coffret prises',
          dangerConstate: 'Repérage des départs effacé sur plastron',
          familleDeRisque: 'Identification et repérage',
          niveau: Q18DangerLevel.horsPerimetreApsad,
        ),
      ];

      sampleSnapshot = Q18DataSnapshot(
        mission: sampleMission,
        renseignements: sampleRg,
        numeroRapportQ18: 'KES/IP/Q18/2026/001',
        numeroRapportVerifElec: 'KES/IP/VE/2026/001',
        dateRapportEffective: DateTime(2026, 2, 15),
        dateProchaineVisite: DateTime(2027, 2, 12),
        lieuIntervention: 'Nomayos (Yaoundé)',
        intervenantsNoms: ['André FOUDA (KES - Vérificateur)', 'Jean ETOUNDI (KES - Ingénieur)'],
        dateVisiteLabel: 'Dates des visites de vérification',
        dateVisiteValue: 'Du 10/02/2026 au 12/02/2026',
        clientName: 'CIMENCAM',
        siteName: 'Usine de Nomayos',
        adresseSite: 'Nomayos (Yaoundé)',
        typeMission: 'Vérification périodique',
        quantities: quantities,
        perimetreCouverts: perimetreCouverts,
        exclusionsPerimetre: exclusions,
        documentsConsultes: documents,
        dangers: dangers,
        countDangerAvere: 1,
        countDegradation: 1,
        countHorsPerimetre: 1,
        countPointSensible: 0,
        hasDangerAvere: true,
        appreciationGlobale: 'Insuffisant',
        avisSyntheseText: 'Présence d\'un échauffement critique sur jeu de barres TGBT nécessitant intervention immédiate.',
        photoEntries: [
          PdfPhotoEntry(
            filePath: '',
            description: 'Échauffement connexion TGBT',
            repere: 'TGBT-N',
            isObservation: true,
            badgeLabel: 'Danger avéré',
          ),
        ],
      );
    });

    test('1. Nomenclature officielle des noms de fichier Q18', () {
      final fileName = PdfQ18ReportService.buildQ18ReportFileName(sampleMission);
      expect(fileName, startsWith('Rapport_Q18_'));
      expect(fileName, contains('CIMENCAM'));
      expect(fileName, contains('Usine_de_Nomayos'));
      expect(fileName, contains('2026'));
      expect(fileName, endsWith('.pdf'));
    });

    test('2. Niveaux de gravité normalisés APSAD D18', () {
      expect(Q18DangerLevel.dangerAvere.label, equals('Danger avéré'));
      expect(Q18DangerLevel.degradation.label, equals('Dégradation'));
      expect(Q18DangerLevel.horsPerimetreApsad.label, equals('Non-conformité hors périmètre APSAD'));
      expect(Q18DangerLevel.pointSensible.label, equals('Point sensible / observation'));
    });

    test('3. Q18IdentificationBuilder - Sections 1 (10 lignes) et 4 (4.1 & 4.2)', () {
      final tracked = <String, int>{};
      final s1Widgets = Q18IdentificationBuilder.buildSection1Identification(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s1Widgets.isNotEmpty, isTrue);

      // Vérification des 10 lignes de données du tableau de la Section 1 (1 en-tête + 10 données = 11)
      final s1Table = s1Widgets.whereType<pw.Table>().first;
      expect(s1Table.children.length, equals(11));

      final s4Widgets = Q18IdentificationBuilder.buildSection4Presentation(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
        trackedPages: tracked,
        pageOffset: 0,
      );
      expect(s4Widgets.isNotEmpty, isTrue);

      // Section 4 contient les tableaux pour 4.1 et 4.2
      final s4Tables = s4Widgets.whereType<pw.Table>().toList();
      expect(s4Tables.length, equals(2));
      // Tableau 4.1 : 5 lignes (en-tête + 4 rubriques)
      expect(s4Tables[0].children.length, equals(5));
      // Tableau 4.2 : 17 lignes (en-tête + 16 postes)
      expect(s4Tables[1].children.length, equals(17));
    });

    test('4. Q18RegulatoryBuilder - Sections 2, 3 (8 textes), 7 (9 points), 8 (4 niveaux), 9 (9 typologies)', () {
      final s2 = Q18RegulatoryBuilder.buildSection2ObjetCadre(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s2.isNotEmpty, isTrue);
      // Section 2 est épurée aux 2 paragraphes de référence (pas de pavé d'alerte orange)
      expect(s2.whereType<pw.Paragraph>().length, equals(2));

      final s3 = Q18RegulatoryBuilder.buildSection3CadreReglementaire(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s3.isNotEmpty, isTrue);
      final s3Table = s3.whereType<pw.Table>().first;
      // 1 en-tête + 8 textes de référence = 9 lignes
      expect(s3Table.children.length, equals(9));

      final s7 = Q18RegulatoryBuilder.buildSection7Methodologie(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s7.isNotEmpty, isTrue);
      final s7Table = s7.whereType<pw.Table>().first;
      // 1 en-tête + 9 points de contrôle = 10 lignes
      expect(s7Table.children.length, equals(10));

      final s8 = Q18RegulatoryBuilder.buildSection8ClassificationDangers(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s8.isNotEmpty, isTrue);
      final s8Table = s8.whereType<pw.Table>().first;
      // 1 en-tête + 4 niveaux de danger = 5 lignes
      expect(s8Table.children.length, equals(5));

      final s9 = Q18RegulatoryBuilder.buildSection9TypologieDangers(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s9.isNotEmpty, isTrue);
      final s9Table = s9.whereType<pw.Table>().first;
      // 1 en-tête + 9 typologies de danger = 10 lignes
      expect(s9Table.children.length, equals(10));
    });

    test('5. Q18PerimetreBuilder - Section 5 (4 colonnes & Sans Objet) et Section 6 (6 documents)', () {
      final tracked = <String, int>{};
      final s5 = Q18PerimetreBuilder.buildSection5Perimetre(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
        trackedPages: tracked,
        pageOffset: 2,
      );
      expect(s5.isNotEmpty, isTrue);
      // Section 5.1 a un tableau avec 4 colonnes et alignement vertical complet
      final s51Table = s5.whereType<pw.Table>().first;
      expect(s51Table.children.length, equals(3)); // En-tête + 2 items
      expect(s51Table.defaultVerticalAlignment, equals(pw.TableCellVerticalAlignment.full));

      // Test de Section 5.2 avec liste d'exclusions vide => Affiche simplement "- Sans Objet"
      final emptyExclusionsSnapshot = Q18DataSnapshot(
        mission: sampleMission,
        renseignements: sampleRg,
        numeroRapportQ18: 'KES/IP/Q18/2026/001',
        numeroRapportVerifElec: 'KES/IP/VE/2026/001',
        dateRapportEffective: DateTime(2026, 2, 15),
        dateProchaineVisite: DateTime(2027, 2, 12),
        lieuIntervention: 'Nomayos (Yaoundé)',
        quantities: sampleSnapshot.quantities,
        perimetreCouverts: sampleSnapshot.perimetreCouverts,
        exclusionsPerimetre: const [], // Vide !
        documentsConsultes: sampleSnapshot.documentsConsultes,
        dangers: sampleSnapshot.dangers,
        countDangerAvere: 0,
        countDegradation: 0,
        countHorsPerimetre: 0,
        countPointSensible: 0,
        hasDangerAvere: false,
        appreciationGlobale: 'Satisfaisant',
        avisSyntheseText: '',
        photoEntries: const [],
      );
      final s5Empty = Q18PerimetreBuilder.buildSection5Perimetre(
        emptyExclusionsSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s5Empty.isNotEmpty, isTrue);
      final hasSansObjet = s5Empty.any(
        (w) => (w is pw.Padding && w.child is pw.Text && (w.child as pw.Text).text.toPlainText().contains('- Sans Objet')) ||
               (w is pw.Column && w.children.any((c) => c is pw.Padding && c.child is pw.Text && (c.child as pw.Text).text.toPlainText().contains('- Sans Objet'))),
      );
      expect(hasSansObjet, isTrue);

      final s6 = Q18PerimetreBuilder.buildSection6DocumentsConsultes(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s6.isNotEmpty, isTrue);
      final s6Table = s6.whereType<pw.Table>().first;
      // 1 en-tête + 6 documents consultés = 7 lignes
      expect(s6Table.children.length, equals(7));
      expect(s6Table.defaultVerticalAlignment, equals(pw.TableCellVerticalAlignment.full));
    });

    test('6. Q18DangersSynthesisBuilder - Sections 10 et 11', () {
      final s10 = Q18DangersSynthesisBuilder.buildSection10Dangers(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s10.isNotEmpty, isTrue);

      final s11 = Q18DangersSynthesisBuilder.buildSection11Statistiques(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s11.isNotEmpty, isTrue);
    });

    test('7. Q18ConclusionBuilder - Sections 12, 13, 14, 15', () {
      final s12 = Q18ConclusionBuilder.buildSection12AvisGlobal(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s12.isNotEmpty, isTrue);

      final s13 = Q18ConclusionBuilder.buildSection13LeveeDangers(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s13.isNotEmpty, isTrue);

      final s14 = Q18ConclusionBuilder.buildSection14ProchaineEcheance(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s14.isNotEmpty, isTrue);

      final s15 = Q18ConclusionBuilder.buildSection15Signature(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s15.isNotEmpty, isTrue);
    });

    test('8. Q18PhotosBuilder - Section 16', () {
      final emptyWidgets = Q18PhotosBuilder.buildSection16Photos(
        [],
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(emptyWidgets.isNotEmpty, isTrue);

      final populatedWidgets = Q18PhotosBuilder.buildSection16Photos(
        sampleSnapshot.photoEntries,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(populatedWidgets.isNotEmpty, isTrue);
    });

    test('9. Génération PDF binaire complète du rapport Q18 (Pass 1 et 2)', () async {
      final pdf = pw.Document();

      // Page de garde
      pdf.addPage(
        pw.Page(
          pageTheme: PdfReportStyles.buildCoverPageTheme(
            pw.Font.helvetica(),
            pw.Font.helveticaBold(),
          ),
          build: (ctx) => pw.Center(
            child: pw.Text(
              'RAPPORT Q18 TEST',
              style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 20),
            ),
          ),
        ),
      );

      // MultiPage avec toutes les sections
      pdf.addPage(
        pw.MultiPage(
          pageTheme: PdfReportStyles.buildInnerPageTheme(
            fontRegular: pw.Font.helvetica(),
            fontBold: pw.Font.helveticaBold(),
            overrideTotalPages: 5,
            showWatermark: false,
          ),
          build: (ctx) => [
            ...Q18IdentificationBuilder.buildSection1Identification(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18RegulatoryBuilder.buildSection2ObjetCadre(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18RegulatoryBuilder.buildSection3CadreReglementaire(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18IdentificationBuilder.buildSection4Presentation(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18PerimetreBuilder.buildSection5Perimetre(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18PerimetreBuilder.buildSection6DocumentsConsultes(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18RegulatoryBuilder.buildSection7Methodologie(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18RegulatoryBuilder.buildSection8ClassificationDangers(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18RegulatoryBuilder.buildSection9TypologieDangers(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18DangersSynthesisBuilder.buildSection10Dangers(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18DangersSynthesisBuilder.buildSection11Statistiques(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18ConclusionBuilder.buildSection12AvisGlobal(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18ConclusionBuilder.buildSection13LeveeDangers(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18ConclusionBuilder.buildSection14ProchaineEcheance(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18ConclusionBuilder.buildSection15Signature(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      expect(bytes.isNotEmpty, isTrue);
      // Signature PDF standard : %PDF-
      expect(bytes.length, greaterThan(1000));
      final headerStr = String.fromCharCodes(bytes.sublist(0, 5));
      expect(headerStr, equals('%PDF-'));
    });

    test('10. MultiPage avec plus de 20 pages sans TooManyPagesException', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          maxPages: 10000,
          pageTheme: PdfReportStyles.buildInnerPageTheme(
            fontRegular: pw.Font.helvetica(),
            fontBold: pw.Font.helveticaBold(),
            showWatermark: false,
          ),
          build: (ctx) => [
            for (int i = 0; i < 30; i++) ...[
              pw.Text('Page $i'),
              if (i < 29) pw.NewPage(),
            ],
          ],
        ),
      );

      final bytes = await pdf.save();
      expect(pdf.document.pdfPageList.pages.length, equals(30));
      expect(bytes.isNotEmpty, isTrue);
    });

    test('11. Intégration complète : buildDocumentForTesting avec Sommaire en page 2 et PageTracker', () async {
      final trackedPages = <String, int>{};
      final fonts = (
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
      final assets = (
        logoKes: null as pw.MemoryImage?,
        watermark: null as pw.MemoryImage?,
        watermarkWhite: null as pw.MemoryImage?,
      );

      // Passe 1 : peuplement de trackedPages
      final doc1 = PdfQ18ReportService.buildDocumentForTesting(
        data: sampleSnapshot,
        fonts: fonts,
        assets: assets,
        overrideTotalPages: null,
        trackedPages: trackedPages,
      );
      final bytes1 = await doc1.save();
      expect(bytes1.isNotEmpty, isTrue);

      // Vérifie la présence des clés de traçage de pages
      expect(trackedPages.containsKey('q18_s1'), isTrue);
      expect(trackedPages.containsKey('q18_s2'), isTrue);
      expect(trackedPages.containsKey('q18_s3'), isTrue);
      expect(trackedPages.containsKey('q18_s4'), isTrue);
      expect(trackedPages.containsKey('q18_s4_1'), isTrue);
      expect(trackedPages.containsKey('q18_s4_2'), isTrue);
      expect(trackedPages.containsKey('q18_s5'), isTrue);
      expect(trackedPages.containsKey('q18_s5_1'), isTrue);
      expect(trackedPages.containsKey('q18_s6'), isTrue);
      expect(trackedPages.containsKey('q18_s7'), isTrue);
      expect(trackedPages.containsKey('q18_s8'), isTrue);
      expect(trackedPages.containsKey('q18_s9'), isTrue);
      expect(trackedPages.containsKey('q18_s10'), isTrue);
      expect(trackedPages.containsKey('q18_s11'), isTrue);
      expect(trackedPages.containsKey('q18_s12'), isTrue);
      expect(trackedPages.containsKey('q18_s13'), isTrue);
      expect(trackedPages.containsKey('q18_s14'), isTrue);
      expect(trackedPages.containsKey('q18_s15'), isTrue);
      expect(trackedPages.containsKey('q18_s16'), isTrue);

      // Section 1 démarre en page 3 (Page 1 = Couverture, Page 2 = Sommaire)
      expect(trackedPages['q18_s1'], equals(3));

      // Passe 2 : document final avec totalPages et trackedPages résolu
      final totalPages = doc1.document.pdfPageList.pages.length;
      expect(totalPages, greaterThanOrEqualTo(5));

      final doc2 = PdfQ18ReportService.buildDocumentForTesting(
        data: sampleSnapshot,
        fonts: fonts,
        assets: assets,
        overrideTotalPages: totalPages,
        trackedPages: trackedPages,
      );
      final bytes2 = await doc2.save();
      expect(bytes2.isNotEmpty, isTrue);
      expect(bytes2.length, greaterThan(2000));
    });

    test('12. Section 10 : Regroupement hiérarchique 4-niveaux et centrage sans répétition visuelle', () {
      final multiDangers = [
        // Zone A -> Local 1 -> TGBT 01 -> 3 observations
        const Q18DangerItem(
          index: 1,
          zone: 'Zone A',
          repere: 'Local 1',
          designation: 'TGBT 01',
          dangerConstate: 'Observation 1 multi-lignes\navec détail supplémentaire',
          familleDeRisque: 'Échauffement',
          niveau: Q18DangerLevel.dangerAvere,
        ),
        const Q18DangerItem(
          index: 2,
          zone: 'Zone A',
          repere: 'Local 1',
          designation: 'TGBT 01',
          dangerConstate: 'Observation 2 courte',
          familleDeRisque: 'Protection différentielle',
          niveau: Q18DangerLevel.degradation,
        ),
        const Q18DangerItem(
          index: 3,
          zone: 'Zone A',
          repere: 'Local 1',
          designation: 'TGBT 01',
          dangerConstate: 'Observation 3 très longue description de l\'anomalie constatée sur le jeu de barres principal',
          familleDeRisque: 'Conducteurs endommagés',
          niveau: Q18DangerLevel.dangerAvere,
        ),
        // Zone A -> Local 1 -> Armoire A -> 2 observations
        const Q18DangerItem(
          index: 4,
          zone: 'Zone A',
          repere: 'Local 1',
          designation: 'Armoire A',
          dangerConstate: 'Observation 4',
          familleDeRisque: 'Connexions desserrées',
          niveau: Q18DangerLevel.degradation,
        ),
        const Q18DangerItem(
          index: 5,
          zone: 'Zone A',
          repere: 'Local 1',
          designation: 'Armoire A',
          dangerConstate: 'Observation 5',
          familleDeRisque: 'Encombrement',
          niveau: Q18DangerLevel.pointSensible,
        ),
        // Zone A -> Local 2 -> Constat directement sur le local (Local 2 -> Local 2)
        const Q18DangerItem(
          index: 6,
          zone: 'Zone A',
          repere: 'Local 2',
          designation: '', // Constat direct sur local => Designation = Local 2
          dangerConstate: 'Observation 6 : Porte coupe-feu bloquée',
          familleDeRisque: 'Matériel non adapté',
          niveau: Q18DangerLevel.dangerAvere,
        ),
        // Zone B -> Équipement hors local directement rattaché à Zone B
        const Q18DangerItem(
          index: 7,
          zone: 'Zone B',
          repere: '', // Hors local => Repère = Zone B
          designation: 'Coffret extérieur',
          dangerConstate: 'Observation 7',
          familleDeRisque: 'Défaut de mise à la terre',
          niveau: Q18DangerLevel.dangerAvere,
        ),
        // Élément sans zone (Zone vide)
        const Q18DangerItem(
          index: 8,
          zone: '', // Sans zone => Cellule vide
          repere: 'Poste isolé',
          designation: 'Disjoncteur général',
          dangerConstate: 'Observation 8',
          familleDeRisque: 'Surcharge',
          niveau: Q18DangerLevel.degradation,
        ),
      ];

      final snapshot = Q18DataSnapshot(
        mission: sampleMission,
        numeroRapportQ18: 'KES/IP/Q18/2026/001',
        numeroRapportVerifElec: 'KES/IP/VE/2026/001',
        dateRapportEffective: DateTime(2026, 2, 15),
        dateProchaineVisite: DateTime(2027, 2, 12),
        lieuIntervention: 'Douala',
        quantities: sampleSnapshot.quantities,
        perimetreCouverts: sampleSnapshot.perimetreCouverts,
        exclusionsPerimetre: sampleSnapshot.exclusionsPerimetre,
        documentsConsultes: sampleSnapshot.documentsConsultes,
        dangers: multiDangers,
        countDangerAvere: 4,
        countDegradation: 3,
        countHorsPerimetre: 0,
        countPointSensible: 1,
        hasDangerAvere: true,
        appreciationGlobale: 'Insuffisant',
        avisSyntheseText: '',
        photoEntries: const [],
      );

      final widgets = Q18DangersSynthesisBuilder.buildSection10Dangers(
        snapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );

      expect(widgets.isNotEmpty, isTrue);
      final table = widgets.whereType<pw.Table>().first;
      // 1 en-tête + 8 observations = 9 lignes
      expect(table.children.length, equals(9));
      expect(table.defaultVerticalAlignment, equals(pw.TableCellVerticalAlignment.full));
    });

    test('13. Section 11 : Tableau 3 colonnes sans blocs de couleur et avec ligne Total', () {
      final widgets = Q18DangersSynthesisBuilder.buildSection11Statistiques(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );

      expect(widgets.isNotEmpty, isTrue);
      final table = widgets.whereType<pw.Table>().isNotEmpty
          ? widgets.whereType<pw.Table>().first
          : widgets.whereType<pw.Column>().first.children.whereType<pw.Table>().first;
      // 1 en-tête + 4 niveaux de danger + 1 ligne Total = 6 lignes
      expect(table.children.length, equals(6));
      expect(table.defaultVerticalAlignment, equals(pw.TableCellVerticalAlignment.full));

      // Ligne d'en-tête : 3 colonnes
      final headerRow = table.children.first;
      expect(headerRow.children.length, equals(3));

      // Ligne de données : 3 colonnes, la 3e est vide
      final dataRow1 = table.children[1];
      expect(dataRow1.children.length, equals(3));
      final col3 = dataRow1.children[2] as pw.Container;
      expect(col3.child is pw.SizedBox, isTrue);

      // Ligne Total : 3 colonnes, la 3e est vide
      final totalRow = table.children.last;
      expect(totalRow.children.length, equals(3));
      final totalCol3 = totalRow.children[2] as pw.Container;
      expect(totalCol3.child is pw.SizedBox, isTrue);
    });

    test('14. Section 12 : Cas 1 vs Cas 2 exclusifs et cases à cocher avec couleur sur le check seul', () {
      // Cas 1 : 0 danger avéré, 0 dégradation => Uniquement Cas 1 visible
      final cas1Snapshot = Q18DataSnapshot(
        mission: sampleMission,
        numeroRapportQ18: 'KES/IP/Q18/2026/001',
        numeroRapportVerifElec: 'KES/IP/VE/2026/001',
        dateRapportEffective: DateTime(2026, 2, 15),
        dateProchaineVisite: DateTime(2027, 2, 12),
        lieuIntervention: 'Douala',
        quantities: sampleSnapshot.quantities,
        perimetreCouverts: sampleSnapshot.perimetreCouverts,
        exclusionsPerimetre: const [],
        documentsConsultes: sampleSnapshot.documentsConsultes,
        dangers: const [],
        countDangerAvere: 0,
        countDegradation: 0,
        countHorsPerimetre: 0,
        countPointSensible: 0,
        hasDangerAvere: false,
        appreciationGlobale: 'Satisfaisant',
        avisSyntheseText: '',
        photoEntries: const [],
      );

      final cas1Widgets = Q18ConclusionBuilder.buildSection12AvisGlobal(
        cas1Snapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );

      final cas1Texts = cas1Widgets
          .whereType<pw.Text>()
          .map((t) => t.text.toPlainText())
          .toList();
      expect(cas1Texts.any((t) => t.contains('Absence de danger identifié')), isTrue);
      expect(cas1Texts.any((t) => t.contains('Cas n°1 :')), isFalse);
      expect(cas1Texts.any((t) => t.contains('Danger(s) identifié(s)')), isFalse);

      // Cas 2 : Danger avéré > 0 => Uniquement Cas 2 visible
      final cas2Snapshot = Q18DataSnapshot(
        mission: sampleMission,
        numeroRapportQ18: 'KES/IP/Q18/2026/001',
        numeroRapportVerifElec: 'KES/IP/VE/2026/001',
        dateRapportEffective: DateTime(2026, 2, 15),
        dateProchaineVisite: DateTime(2027, 2, 12),
        lieuIntervention: 'Douala',
        quantities: sampleSnapshot.quantities,
        perimetreCouverts: sampleSnapshot.perimetreCouverts,
        exclusionsPerimetre: const [],
        documentsConsultes: sampleSnapshot.documentsConsultes,
        dangers: sampleSnapshot.dangers,
        countDangerAvere: 2,
        countDegradation: 1,
        countHorsPerimetre: 0,
        countPointSensible: 0,
        hasDangerAvere: true,
        appreciationGlobale: 'Insuffisant',
        avisSyntheseText: '',
        photoEntries: const [],
      );

      final cas2Widgets = Q18ConclusionBuilder.buildSection12AvisGlobal(
        cas2Snapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );

      final cas2Texts = cas2Widgets
          .whereType<pw.Text>()
          .map((t) => t.text.toPlainText())
          .toList();
      expect(cas2Texts.any((t) => t.contains('Danger(s) identifié(s)')), isTrue);
      expect(cas2Texts.any((t) => t.contains('Cas n°2 :')), isFalse);
      expect(cas2Texts.any((t) => t.contains('Absence de danger identifié')), isFalse);
    });

    test('15. Section 15 : Visa et Signature avec Fait à Douala et gestion singulier / pluriel', () {
      // Cas 1 vérificateur
      final singleVerifSnapshot = Q18DataSnapshot(
        mission: sampleMission,
        numeroRapportQ18: 'KES/IP/Q18/2026/001',
        numeroRapportVerifElec: 'KES/IP/VE/2026/001',
        dateRapportEffective: DateTime(2026, 2, 15),
        dateProchaineVisite: DateTime(2027, 2, 12),
        lieuIntervention: 'Douala',
        intervenantsNoms: ['TEUFACK ANDELSON'],
        quantities: sampleSnapshot.quantities,
        perimetreCouverts: sampleSnapshot.perimetreCouverts,
        exclusionsPerimetre: const [],
        documentsConsultes: sampleSnapshot.documentsConsultes,
        dangers: const [],
        countDangerAvere: 0,
        countDegradation: 0,
        countHorsPerimetre: 0,
        countPointSensible: 0,
        hasDangerAvere: false,
        appreciationGlobale: 'Satisfaisant',
        avisSyntheseText: '',
        photoEntries: const [],
      );

      final singleWidgets = Q18ConclusionBuilder.buildSection15Signature(
        singleVerifSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(singleWidgets.isNotEmpty, isTrue);

      // Cas plusieurs vérificateurs
      final multiVerifSnapshot = Q18DataSnapshot(
        mission: sampleMission,
        numeroRapportQ18: 'KES/IP/Q18/2026/001',
        numeroRapportVerifElec: 'KES/IP/VE/2026/001',
        dateRapportEffective: DateTime(2026, 2, 15),
        dateProchaineVisite: DateTime(2027, 2, 12),
        lieuIntervention: 'Douala',
        intervenantsNoms: ['TEUFACK ANDELSON', 'KOUAM ERIC', 'FOTSING ALAIN'],
        quantities: sampleSnapshot.quantities,
        perimetreCouverts: sampleSnapshot.perimetreCouverts,
        exclusionsPerimetre: const [],
        documentsConsultes: sampleSnapshot.documentsConsultes,
        dangers: const [],
        countDangerAvere: 0,
        countDegradation: 0,
        countHorsPerimetre: 0,
        countPointSensible: 0,
        hasDangerAvere: false,
        appreciationGlobale: 'Satisfaisant',
        avisSyntheseText: '',
        photoEntries: const [],
      );

      final multiWidgets = Q18ConclusionBuilder.buildSection15Signature(
        multiVerifSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(multiWidgets.isNotEmpty, isTrue);
    });

    test('16. Liaison fonctionnelle Rapport Q18 précédent entre Mission, Section 1 et Section 6', () {
      // Mission avec docRapportQ18 = true
      final missionWithQ18 = Mission(
        id: 'mission_with_q18',
        nomClient: 'CLIENT_A',
        status: 'en_cours',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        docRapportQ18: true,
      );

      final snapshotWithQ18 = Q18DataSnapshot(
        mission: missionWithQ18,
        numeroRapportQ18: 'KES/IP/Q18/2026/001',
        numeroRapportVerifElec: 'KES/IP/VE/2026/001',
        dateRapportEffective: DateTime(2026, 2, 15),
        dateProchaineVisite: DateTime(2027, 2, 12),
        lieuIntervention: 'Douala',
        quantities: sampleSnapshot.quantities,
        perimetreCouverts: sampleSnapshot.perimetreCouverts,
        exclusionsPerimetre: const [],
        documentsConsultes: [
          const Q18DocumentConsulteItem(index: 4, titre: 'Rapport Q18 précédent, le cas échéant', isDisponible: true),
        ],
        dangers: const [],
        countDangerAvere: 0,
        countDegradation: 0,
        countHorsPerimetre: 0,
        countPointSensible: 0,
        hasDangerAvere: false,
        hasQ18Precedent: true,
        appreciationGlobale: 'Satisfaisant',
        avisSyntheseText: '',
        photoEntries: const [],
      );

      final s1 = Q18IdentificationBuilder.buildSection1Identification(
        snapshotWithQ18,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s1.isNotEmpty, isTrue);

      final s6 = Q18PerimetreBuilder.buildSection6DocumentsConsultes(
        snapshotWithQ18,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s6.isNotEmpty, isTrue);
    });

    test('17. Prise en charge de la centrale photovoltaïque (Oui / Non / Sans objet par défaut)', () {
      final missionDefaut = Mission(
        id: 'test_pv_default',
        nomClient: 'Client PV',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'en_cours',
      );
      expect(missionDefaut.centralePhotovoltaique, equals('sans_objet'));

      final missionOui = Mission(
        id: 'test_pv_oui',
        nomClient: 'Client PV',
        centralePhotovoltaique: 'oui',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'en_cours',
      );
      expect(missionOui.centralePhotovoltaique, equals('oui'));

      final missionNon = Mission(
        id: 'test_pv_non',
        nomClient: 'Client PV',
        centralePhotovoltaique: 'non',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'en_cours',
      );
      expect(missionNon.centralePhotovoltaique, equals('non'));

      // Test de sérialisation JSON
      final json = missionDefaut.toJson();
      expect(json['centrale_photovoltaique'], equals('sans_objet'));
      final fromJsonMission = Mission.fromJson(json);
      expect(fromJsonMission.centralePhotovoltaique, equals('sans_objet'));
    });

    test('18. Optimisation Section 16 : Preflight Zero-Load et injection des photos compressées', () {
      final samplePhotos = [
        PdfPhotoEntry(
          filePath: 'non_existent_1.jpg',
          description: 'Câble détérioré',
          repere: 'TGBT-01',
          isObservation: true,
          badgeLabel: 'Danger avéré',
        ),
        PdfPhotoEntry(
          filePath: 'non_existent_2.jpg',
          description: 'Absence d\'obturateur',
          repere: 'TD-02',
          isObservation: true,
          badgeLabel: 'Dégradation',
        ),
      ];

      // 1. Passe Preflight (Zero-Load) : aucune image en mémoire
      final preflightWidgets = Q18PhotosBuilder.buildSection16Photos(
        samplePhotos,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
        isPreflight: true,
      );
      expect(preflightWidgets.isNotEmpty, isTrue);

      // 2. Passe Rendu (avec Map d'images compressées)
      final dummyCompressedBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
        0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
        0x00, 0xBF, 0x00, 0xFF, 0xD9
      ]);
      final compressedMemImage = pw.MemoryImage(dummyCompressedBytes);
      final photoImagesMap = <String, pw.MemoryImage>{
        'non_existent_1.jpg': compressedMemImage,
        'non_existent_2.jpg': compressedMemImage,
      };

      final renderWidgets = Q18PhotosBuilder.buildSection16Photos(
        samplePhotos,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
        photoImages: photoImagesMap,
        isPreflight: false,
      );
      expect(renderWidgets.isNotEmpty, isTrue);

      // Structure et nombre d'éléments identiques entre Preflight et Rendu final
      expect(renderWidgets.length, equals(preflightWidgets.length));
    });

    test('19. Page de garde Q18 unifiée avec Verif Elec (en-tête client, tableau 5 colonnes, N° Q18 et QR Code)', () async {
      final missionWithQr = Mission(
        id: 'test_q18_cover',
        nomClient: 'CIMENCAM S.A.',
        recepteurCivilite: 'Monsieur',
        recepteurNom: 'Marc DUBOIS',
        recepteurFonction: 'Directeur d\'Usine',
        qrCodeQ18: 'path/to/qrcode_q18.png',
        qrCodeClient: 'path/to/qrcode_client.png',
        status: 'en_cours',
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      );

      final snapshot = Q18DataSnapshot(
        mission: missionWithQr,
        numeroRapportQ18: 'KES/IP/Q18/2026/042',
        numeroRapportVerifElec: 'KES/IP/VE/2026/042',
        dateRapportEffective: DateTime(2026, 3, 15),
        dateProchaineVisite: DateTime(2027, 3, 14),
        lieuIntervention: 'Douala - Bonabéri',
        quantities: sampleSnapshot.quantities,
        perimetreCouverts: sampleSnapshot.perimetreCouverts,
        exclusionsPerimetre: const [],
        documentsConsultes: sampleSnapshot.documentsConsultes,
        dangers: const [],
        countDangerAvere: 0,
        countDegradation: 0,
        countHorsPerimetre: 0,
        countPointSensible: 0,
        hasDangerAvere: false,
        appreciationGlobale: 'Satisfaisant',
        avisSyntheseText: '',
        photoEntries: const [],
      );

      final fonts = (
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
      final assets = (
        logoKes: null as pw.MemoryImage?,
        watermark: null as pw.MemoryImage?,
        watermarkWhite: null as pw.MemoryImage?,
      );

      final trackedPages = <String, int>{};
      final doc = PdfQ18ReportService.buildDocumentForTesting(
        data: snapshot,
        fonts: fonts,
        assets: assets,
        overrideTotalPages: 5,
        trackedPages: trackedPages,
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
      expect(bytes.length, greaterThan(2000));

      // Vérifier le support du champ qrCodeQ18 sur Mission
      expect(missionWithQr.qrCodeQ18, equals('path/to/qrcode_q18.png'));
      final json = missionWithQr.toJson();
      expect(json['qr_code_q18'], equals('path/to/qrcode_q18.png'));
      final rehydrated = Mission.fromJson(json);
      expect(rehydrated.qrCodeQ18, equals('path/to/qrcode_q18.png'));
    });

    test('20. Résolution dynamique et unifiée du Récepteur (civilité, fonction majuscules et repli recepteurRapport)', () {
      // Cas 1 : Mission avec champ historique recepteurRapport = 'LE DIRECTEUR GÉNÉRAL'
      final m1 = Mission(
        id: 'm1',
        nomClient: 'CIMENCAM',
        status: 'en_cours',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recepteurRapport: 'LE DIRECTEUR GÉNÉRAL',
      );
      final r1 = PdfCoverBuilder.resolveRecepteurInfo(mission: m1);
      expect(r1.attentionTitle, equals("A l'attention de Monsieur"));
      expect(r1.fonctionAffichee, equals('LE DIRECTEUR GÉNÉRAL'));

      // Cas 2 : Mission avec champ recepteurRapport = 'M. Le Directeur Général'
      final m2 = Mission(
        id: 'm2',
        nomClient: 'CIMENCAM',
        status: 'en_cours',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recepteurRapport: 'M. Le Directeur Général',
      );
      final r2 = PdfCoverBuilder.resolveRecepteurInfo(mission: m2);
      expect(r2.attentionTitle, equals("A l'attention de Monsieur"));
      expect(r2.fonctionAffichee, equals('LE DIRECTEUR GÉNÉRAL'));

      // Cas 3 : Mission avec champ recepteurRapport sur RenseignementsGeneraux
      final m3 = Mission(
        id: 'm3',
        nomClient: 'CIMENCAM',
        status: 'en_cours',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final rg3 = RenseignementsGeneraux.create('m3')
        ..etablissement = 'CIMENCAM'
        ..recepteurRapport = 'Directeur Général';
      final r3 = PdfCoverBuilder.resolveRecepteurInfo(mission: m3, rg: rg3);
      expect(r3.attentionTitle, equals("A l'attention de Monsieur"));
      expect(r3.fonctionAffichee, equals('DIRECTEUR GÉNÉRAL'));

      // Cas 4 : Madame avec fonction
      final m4 = Mission(
        id: 'm4',
        nomClient: 'CIMENCAM',
        status: 'en_cours',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recepteurCivilite: 'Madame',
        recepteurFonction: 'Directrice Administrative',
      );
      final r4 = PdfCoverBuilder.resolveRecepteurInfo(mission: m4);
      expect(r4.attentionTitle, equals("A l'attention de Madame"));
      expect(r4.fonctionAffichee, equals('DIRECTRICE ADMINISTRATIVE'));

      // Cas 5 : Aucun récepteur renseigné -> repli strict
      final m5 = Mission(
        id: 'm5',
        nomClient: 'CIMENCAM',
        status: 'en_cours',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final r5 = PdfCoverBuilder.resolveRecepteurInfo(mission: m5);
      expect(r5.attentionTitle, equals("A l'attention de Mme/M."));
      expect(r5.fonctionAffichee, equals('XXXXXXXXXXXXXXX'));
    });
  });
}

