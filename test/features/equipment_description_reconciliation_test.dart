import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    HiveService.registerAdapters();

    await Hive.openBox<AuditInstallationsElectriques>('audit_installations_electriques');
    await Hive.openBox<DescriptionInstallations>('description_installations');
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Reconciliation engine creates, updates, deletes equipment items idempotently without duplicates', () async {
    const missionId = 'mission_test_123';

    final auditBox = Hive.box<AuditInstallationsElectriques>('audit_installations_electriques');
    final descBox = Hive.box<DescriptionInstallations>('description_installations');

    // 1. Initial State: Create Audit with 1 Local containing 1 Cellule & 1 Transfo
    final cellule1 = Cellule(
      fonction: 'Arrivée',
      type: 'IM',
      marqueModeleAnnee: 'Schneider 2020',
      tensionAssignee: '24',
      pouvoirCoupure: '16',
      numerotation: 'C01',
      parafoudres: 'Sans',
      syncId: 'cell_001',
      gamme: 'SM6',
      tensionService: '20',
    );
    final transfo1 = TransformateurMTBT(
      typeTransformateur: 'Huile',
      marqueAnnee: 'Schneider 2020',
      puissanceAssignee: '630',
      tensionPrimaireSecondaire: '20kV/400V',
      relaisBuchholz: 'Présent',
      typeRefroidissement: 'ONAN',
      regimeNeutre: 'TNC',
      syncId: 'transfo_001',
      intensiteNominale: '909',
    );

    final local1 = MoyenneTensionLocal(
      nom: 'Poste MT 1',
      type: 'LOCAL_TRANSFORMATEUR',
      cellules: [cellule1],
      transformateurs: [transfo1],
    );

    final audit = AuditInstallationsElectriques(
      missionId: missionId,
      moyenneTensionLocaux: [local1],
      updatedAt: DateTime.now(),
    );

    await auditBox.put(missionId, audit);

    // 2. Perform Sync / Reconciliation
    await InstallationDescriptionSyncService.syncAuditToDescription(audit);

    // Verify Description was created under missionId key
    final desc = descBox.get(missionId);
    expect(desc, isNotNull);
    expect(desc!.alimentationMoyenneTension.length, equals(1));
    expect(desc.alimentationBasseTension.length, equals(1));

    expect(desc.alimentationMoyenneTension.first.data['auditCelluleId'], equals('cell_001'));
    expect(desc.alimentationMoyenneTension.first.data['Gamme De Cellule'], equals('SM6'));
    expect(desc.alimentationMoyenneTension.first.data['Tension de service'], equals('20'));

    expect(desc.alimentationBasseTension.first.data['auditTransformateurId'], equals('transfo_001'));
    expect(desc.alimentationBasseTension.first.data['Puissance Transformateur'], equals('630'));
    expect(desc.alimentationBasseTension.first.data['Tension primaire / secondaire'], equals('20kV/400V'));
    expect(desc.alimentationBasseTension.first.data['Tension primaire/secondaire'], equals('20kV/400V'));
    expect(desc.alimentationBasseTension.first.data['TENSION PRIMAIRE/SECONDAIRE'], equals('20kV/400V'));

    // 3. Idempotence test: Running sync again creates 0 duplicates
    await InstallationDescriptionSyncService.syncAuditToDescription(audit);
    final descAfterSecondSync = descBox.get(missionId);
    expect(descAfterSecondSync!.alimentationMoyenneTension.length, equals(1));
    expect(descAfterSecondSync.alimentationBasseTension.length, equals(1));

    // 4. Update equipment test: Modify cell & transfo values
    cellule1.gamme = 'Premset';
    cellule1.tensionService = '30';
    transfo1.puissanceAssignee = '1000';
    transfo1.tensionPrimaireSecondaire = '15kV/400V';

    await InstallationDescriptionSyncService.syncAuditToDescription(audit);
    final descAfterUpdate = descBox.get(missionId);
    expect(descAfterUpdate!.alimentationMoyenneTension.first.data['Gamme De Cellule'], equals('Premset'));
    expect(descAfterUpdate.alimentationMoyenneTension.first.data['Tension de service'], equals('30'));
    expect(descAfterUpdate.alimentationBasseTension.first.data['Puissance Transformateur'], equals('1000'));
    expect(descAfterUpdate.alimentationBasseTension.first.data['TENSION PRIMAIRE/SECONDAIRE'], equals('15kV/400V'));

    // 5. Deletion test: Remove Cellule from local
    local1.cellules.clear();
    await InstallationDescriptionSyncService.syncAuditToDescription(audit);
    final descAfterDelete = descBox.get(missionId);
    expect(descAfterDelete!.alimentationMoyenneTension.length, equals(0));
    expect(descAfterDelete.alimentationBasseTension.length, equals(1)); // Transfo stays!
  });
}
