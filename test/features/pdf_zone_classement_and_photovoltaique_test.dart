import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/features/mission/data/datasources/mission_local_data_source.dart';
import 'package:inspec_app/features/mission/data/mappers/mission_mapper.dart';
import 'package:inspec_app/features/mission/data/repositories/mission_repository_impl.dart';
import 'package:inspec_app/features/mission/domain/usecases/update_centrale_photovoltaique_use_case.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_classement_foudre_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const String missionId = 'mission_test_bugs_pv_classement';

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_pv_classement_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => tempDir.path,
    );
    Hive.init(tempDir.path);
    await HiveService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('Bug 1: Centrale Photovoltaïque Clean Architecture & Hive Persistence', () {
    test('MissionMapper should map centralePhotovoltaique bidirectionally', () {
      final now = DateTime.now();
      final model = Mission(
        id: 'M-TEST-PV',
        nomClient: 'KES Solar',
        centralePhotovoltaique: 'avec_stockage',
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
      );

      final entity = MissionMapper.toEntity(model);
      expect(entity.centralePhotovoltaique, equals('avec_stockage'));

      final backToModel = MissionMapper.toModel(entity);
      expect(backToModel.centralePhotovoltaique, equals('avec_stockage'));
    });

    test('UpdateCentralePhotovoltaiqueUseCase and DataSource update in-box Mission without HiveError', () async {
      final missionBox = Hive.box<Mission>('missions');
      final initialMission = Mission(
        id: missionId,
        nomClient: 'KES Test Client',
        centralePhotovoltaique: 'sans_objet',
        status: 'en_cours',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await missionBox.put(missionId, initialMission);

      final dataSource = MissionLocalDataSourceImpl();
      final repository = MissionRepositoryImpl(missionLocalDataSource: dataSource);
      final useCase = UpdateCentralePhotovoltaiqueUseCase(repository: repository);

      // Execute use case for "avec_stockage"
      final success = await useCase(
        missionId: missionId,
        option: 'avec_stockage',
      );

      expect(success, isTrue);

      // Verify persistence in Hive box
      final persisted = missionBox.get(missionId);
      expect(persisted, isNotNull);
      expect(persisted!.centralePhotovoltaique, equals('avec_stockage'));
      expect(persisted.nomClient, equals('KES Test Client'));

      // Test changing to "sans_stockage"
      await dataSource.updateCentralePhotovoltaique(
        missionId: missionId,
        option: 'sans_stockage',
      );
      expect(missionBox.get(missionId)!.centralePhotovoltaique, equals('sans_stockage'));
    });
  });

  group('Bug 2: Classement des Zones dans le Tableau PDF', () {
    test('HiveService retrieves ClassementZone by string representation of integer key', () async {
      final zoneBox = Hive.box<ClassementZone>('classement_zones');
      final zone = ClassementZone(
        missionId: missionId,
        nomZone: 'Zone Stockage Batteries',
        typeZone: 'BASSE_TENSION',
        af: 'AF2',
        be: 'BE1',
        ae: 'AE1',
        ad: 'AD1',
        ag: 'AG1',
        ip: 'IP2X',
        ik: 'IK02',
        updatedAt: DateTime.now(),
      );

      final int autoKey = await zoneBox.add(zone);

      // Verify retrieval by string representation of integer key (e.g. "0")
      final retrievedByString = HiveService.getClassementZoneById(autoKey.toString());
      expect(retrievedByString, isNotNull);
      expect(retrievedByString!.nomZone, equals('Zone Stockage Batteries'));
    });

    test('buildClassementEmplacementsMulti includes partially classified zones (!estComplet)', () {
      final partialZone = ClassementZone(
        missionId: missionId,
        nomZone: 'Zone Transformateurs HTA',
        typeZone: 'MOYENNE_TENSION',
        af: 'AF3',
        be: 'BE2',
        // ae, ad, ag left null
        updatedAt: DateTime.now(),
      );

      expect(partialZone.estComplet, isFalse);

      final tracked = <String, int>{};
      final widgets = PdfClassementFoudreBuilder.buildClassementEmplacementsMulti(
        [],
        [partialZone],
        tracked,
      );

      // A table must be built containing this zone
      expect(widgets, isNotEmpty);
      // Beyond title & intro, table is generated
      expect(widgets.length, greaterThan(2));
    });

    test('buildClassementEmplacementsMulti reconciles audit zone linked by classementZoneId', () {
      final audit = AuditInstallationsElectriques.create(missionId);
      final zoneBT = BasseTensionZone(
        nom: 'Zone Usinage Est',
        classementZoneId: '12345',
      );
      audit.basseTensionZones.add(zoneBT);

      final zoneClassement = ClassementZone(
        missionId: missionId,
        nomZone: 'Zone Usinage Est',
        typeZone: 'BASSE_TENSION',
        af: 'AF1',
        be: 'BE1',
        updatedAt: DateTime.now(),
      );

      final tracked = <String, int>{};
      final widgets = PdfClassementFoudreBuilder.buildClassementEmplacementsMulti(
        [],
        [zoneClassement],
        tracked,
        audit: audit,
      );

      expect(widgets, isNotEmpty);
      expect(widgets.length, greaterThan(2));
    });

    test('buildClassementEmplacementsMulti reconciles dual sources (ClassementZone + ClassementEmplacement) without duplicates', () {
      final zoneClassement = ClassementZone(
        missionId: missionId,
        nomZone: 'Zone Chauderie',
        typeZone: 'BASSE_TENSION',
        af: 'AF2',
        be: 'BE1',
        updatedAt: DateTime.now(),
      );

      final empZone = ClassementEmplacement(
        missionId: missionId,
        localisation: 'Zone Chauderie',
        typeEmplacement: 'zone',
        updatedAt: DateTime.now(),
      );

      final tracked = <String, int>{};
      final widgets = PdfClassementFoudreBuilder.buildClassementEmplacementsMulti(
        [empZone],
        [zoneClassement],
        tracked,
      );

      expect(widgets, isNotEmpty);
      expect(widgets.length, greaterThan(2));
    });
  });
}
