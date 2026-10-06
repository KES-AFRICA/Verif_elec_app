// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_installations_electriques.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuditInstallationsElectriquesAdapter
    extends TypeAdapter<AuditInstallationsElectriques> {
  @override
  final int typeId = 3;

  @override
  AuditInstallationsElectriques read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditInstallationsElectriques(
      missionId: fields[0] as String,
      updatedAt: fields[1] as DateTime,
      createdAt: fields[20] as DateTime?,
      moyenneTensionLocaux: (fields[2] as List?)?.cast<MoyenneTensionLocal>(),
      moyenneTensionZones: (fields[3] as List?)?.cast<MoyenneTensionZone>(),
      basseTensionZones: (fields[4] as List?)?.cast<BasseTensionZone>(),
      photos: (fields[15] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AuditInstallationsElectriques obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.missionId)
      ..writeByte(1)
      ..write(obj.updatedAt)
      ..writeByte(20)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.moyenneTensionLocaux)
      ..writeByte(3)
      ..write(obj.moyenneTensionZones)
      ..writeByte(4)
      ..write(obj.basseTensionZones)
      ..writeByte(15)
      ..write(obj.photos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditInstallationsElectriquesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoyenneTensionLocalAdapter extends TypeAdapter<MoyenneTensionLocal> {
  @override
  final int typeId = 4;

  @override
  MoyenneTensionLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoyenneTensionLocal(
      id: fields[40] as String?,
      nom: fields[0] as String,
      type: fields[1] as String,
      createdAt: fields[41] as DateTime?,
      updatedAt: fields[42] as DateTime?,
      dispositionsConstructives: (fields[2] as List?)?.cast<ElementControle>(),
      conditionsExploitation: (fields[3] as List?)?.cast<ElementControle>(),
      cellule: fields[4] as Cellule?,
      transformateur: fields[5] as TransformateurMTBT?,
      coffrets: (fields[6] as List?)?.cast<CoffretArmoire>(),
      observationsLibres: (fields[7] as List?)?.cast<ObservationLibre>(),
      photos: (fields[8] as List?)?.cast<String>(),
      cellules: (fields[30] as List?)?.cast<Cellule>(),
      transformateurs: (fields[31] as List?)?.cast<TransformateurMTBT>(),
      accessible: fields[32] as bool?,
      aReverifier: fields[33] as bool?,
      isRiskZone: fields[34] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, MoyenneTensionLocal obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.dispositionsConstructives)
      ..writeByte(3)
      ..write(obj.conditionsExploitation)
      ..writeByte(4)
      ..write(obj.cellule)
      ..writeByte(5)
      ..write(obj.transformateur)
      ..writeByte(6)
      ..write(obj.coffrets)
      ..writeByte(7)
      ..write(obj.observationsLibres)
      ..writeByte(8)
      ..write(obj.photos)
      ..writeByte(30)
      ..write(obj.cellules)
      ..writeByte(31)
      ..write(obj.transformateurs)
      ..writeByte(32)
      ..write(obj.accessible)
      ..writeByte(33)
      ..write(obj.aReverifier)
      ..writeByte(34)
      ..write(obj.isRiskZone)
      ..writeByte(40)
      ..write(obj.id)
      ..writeByte(41)
      ..write(obj.createdAt)
      ..writeByte(42)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoyenneTensionLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoyenneTensionZoneAdapter extends TypeAdapter<MoyenneTensionZone> {
  @override
  final int typeId = 5;

  @override
  MoyenneTensionZone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoyenneTensionZone(
      id: fields[40] as String?,
      nom: fields[0] as String,
      description: fields[1] as String?,
      createdAt: fields[41] as DateTime?,
      updatedAt: fields[42] as DateTime?,
      coffrets: (fields[2] as List?)?.cast<CoffretArmoire>(),
      observationsLibres: (fields[3] as List?)?.cast<ObservationLibre>(),
      photos: (fields[4] as List?)?.cast<String>(),
      locaux: (fields[5] as List?)?.cast<MoyenneTensionLocal>(),
      classementZoneId: fields[6] as String?,
      isRiskZone: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, MoyenneTensionZone obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.coffrets)
      ..writeByte(3)
      ..write(obj.observationsLibres)
      ..writeByte(4)
      ..write(obj.photos)
      ..writeByte(5)
      ..write(obj.locaux)
      ..writeByte(6)
      ..write(obj.classementZoneId)
      ..writeByte(7)
      ..write(obj.isRiskZone)
      ..writeByte(40)
      ..write(obj.id)
      ..writeByte(41)
      ..write(obj.createdAt)
      ..writeByte(42)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoyenneTensionZoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BasseTensionZoneAdapter extends TypeAdapter<BasseTensionZone> {
  @override
  final int typeId = 6;

  @override
  BasseTensionZone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BasseTensionZone(
      id: fields[40] as String?,
      nom: fields[0] as String,
      description: fields[1] as String?,
      createdAt: fields[41] as DateTime?,
      updatedAt: fields[42] as DateTime?,
      locaux: (fields[2] as List?)?.cast<BasseTensionLocal>(),
      coffretsDirects: (fields[3] as List?)?.cast<CoffretArmoire>(),
      observationsLibres: (fields[4] as List?)?.cast<ObservationLibre>(),
      photos: (fields[5] as List?)?.cast<String>(),
      classementZoneId: fields[6] as String?,
      isRiskZone: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, BasseTensionZone obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.locaux)
      ..writeByte(3)
      ..write(obj.coffretsDirects)
      ..writeByte(4)
      ..write(obj.observationsLibres)
      ..writeByte(5)
      ..write(obj.photos)
      ..writeByte(6)
      ..write(obj.classementZoneId)
      ..writeByte(7)
      ..write(obj.isRiskZone)
      ..writeByte(40)
      ..write(obj.id)
      ..writeByte(41)
      ..write(obj.createdAt)
      ..writeByte(42)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BasseTensionZoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BasseTensionLocalAdapter extends TypeAdapter<BasseTensionLocal> {
  @override
  final int typeId = 7;

  @override
  BasseTensionLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BasseTensionLocal(
      id: fields[40] as String?,
      nom: fields[0] as String,
      type: fields[1] as String,
      createdAt: fields[41] as DateTime?,
      updatedAt: fields[42] as DateTime?,
      dispositionsConstructives: (fields[2] as List?)?.cast<ElementControle>(),
      conditionsExploitation: (fields[3] as List?)?.cast<ElementControle>(),
      coffrets: (fields[4] as List?)?.cast<CoffretArmoire>(),
      observationsLibres: (fields[5] as List?)?.cast<ObservationLibre>(),
      photos: (fields[6] as List?)?.cast<String>(),
      accessible: fields[7] as bool?,
      aReverifier: fields[8] as bool?,
      cellules: (fields[9] as List?)?.cast<Cellule>(),
      transformateurs: (fields[10] as List?)?.cast<TransformateurMTBT>(),
      isRiskZone: fields[11] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, BasseTensionLocal obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.dispositionsConstructives)
      ..writeByte(3)
      ..write(obj.conditionsExploitation)
      ..writeByte(4)
      ..write(obj.coffrets)
      ..writeByte(5)
      ..write(obj.observationsLibres)
      ..writeByte(6)
      ..write(obj.photos)
      ..writeByte(7)
      ..write(obj.accessible)
      ..writeByte(8)
      ..write(obj.aReverifier)
      ..writeByte(9)
      ..write(obj.cellules)
      ..writeByte(10)
      ..write(obj.transformateurs)
      ..writeByte(11)
      ..write(obj.isRiskZone)
      ..writeByte(40)
      ..write(obj.id)
      ..writeByte(41)
      ..write(obj.createdAt)
      ..writeByte(42)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BasseTensionLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ElementControleAdapter extends TypeAdapter<ElementControle> {
  @override
  final int typeId = 8;

  @override
  ElementControle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ElementControle(
      elementControle: fields[0] as String,
      conforme: fields[1] as bool?,
      observation: fields[2] as String?,
      priorite: fields[3] as int?,
      photos: (fields[4] as List?)?.cast<String>(),
      referenceNormative: fields[5] as String?,
      estNA: fields[6] as bool?,
      familleRisque: fields[7] as String?,
      criticite: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ElementControle obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.elementControle)
      ..writeByte(1)
      ..write(obj.conforme)
      ..writeByte(2)
      ..write(obj.observation)
      ..writeByte(3)
      ..write(obj.priorite)
      ..writeByte(4)
      ..write(obj.photos)
      ..writeByte(5)
      ..write(obj.referenceNormative)
      ..writeByte(6)
      ..write(obj.estNA)
      ..writeByte(7)
      ..write(obj.familleRisque)
      ..writeByte(8)
      ..write(obj.criticite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementControleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CelluleAdapter extends TypeAdapter<Cellule> {
  @override
  final int typeId = 9;

  @override
  Cellule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cellule(
      fonction: fields[0] as String,
      type: fields[1] as String,
      marqueModeleAnnee: fields[2] as String,
      tensionAssignee: fields[3] as String,
      pouvoirCoupure: fields[4] as String,
      numerotation: fields[5] as String,
      parafoudres: fields[6] as String,
      createdAt: fields[23] as DateTime?,
      updatedAt: fields[24] as DateTime?,
      elementsVerifies: (fields[7] as List?)?.cast<ElementControle>(),
      photos: (fields[8] as List?)?.cast<String>(),
      gamme: fields[9] as String?,
      calibreDisjoncteur: fields[10] as String?,
      sectionCables: fields[11] as String?,
      natureReseau: fields[12] as String?,
      observations: (fields[13] as List?)?.cast<ElementControle>(),
      presenceIacm: fields[14] as String?,
      syncId: fields[15] as String?,
      tensionService: fields[16] as String?,
      nom: fields[17] as String?,
      photo: fields[18] as String?,
      repere: fields[19] as String?,
      marque: fields[20] as String?,
      modele: fields[21] as String?,
      annee: fields[22] as String?,
      sectionCablePhase: fields[25] as String?,
      sectionCableNeutre: fields[26] as String?,
      conducteursPhase: fields[27] as int?,
      conducteursNeutre: fields[28] as int?,
      celluleDepart: fields[29] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Cellule obj) {
    writer
      ..writeByte(30)
      ..writeByte(0)
      ..write(obj.fonction)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.marqueModeleAnnee)
      ..writeByte(3)
      ..write(obj.tensionAssignee)
      ..writeByte(4)
      ..write(obj.pouvoirCoupure)
      ..writeByte(5)
      ..write(obj.numerotation)
      ..writeByte(6)
      ..write(obj.parafoudres)
      ..writeByte(7)
      ..write(obj.elementsVerifies)
      ..writeByte(8)
      ..write(obj.photos)
      ..writeByte(9)
      ..write(obj.gamme)
      ..writeByte(10)
      ..write(obj.calibreDisjoncteur)
      ..writeByte(11)
      ..write(obj.sectionCables)
      ..writeByte(12)
      ..write(obj.natureReseau)
      ..writeByte(13)
      ..write(obj.observations)
      ..writeByte(14)
      ..write(obj.presenceIacm)
      ..writeByte(15)
      ..write(obj.syncId)
      ..writeByte(16)
      ..write(obj.tensionService)
      ..writeByte(17)
      ..write(obj.nom)
      ..writeByte(18)
      ..write(obj.photo)
      ..writeByte(19)
      ..write(obj.repere)
      ..writeByte(20)
      ..write(obj.marque)
      ..writeByte(21)
      ..write(obj.modele)
      ..writeByte(22)
      ..write(obj.annee)
      ..writeByte(23)
      ..write(obj.createdAt)
      ..writeByte(24)
      ..write(obj.updatedAt)
      ..writeByte(25)
      ..write(obj.sectionCablePhase)
      ..writeByte(26)
      ..write(obj.sectionCableNeutre)
      ..writeByte(27)
      ..write(obj.conducteursPhase)
      ..writeByte(28)
      ..write(obj.conducteursNeutre)
      ..writeByte(29)
      ..write(obj.celluleDepart);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CelluleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransformateurMTBTAdapter extends TypeAdapter<TransformateurMTBT> {
  @override
  final int typeId = 10;

  @override
  TransformateurMTBT read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransformateurMTBT(
      typeTransformateur: fields[0] as String,
      marqueAnnee: fields[1] as String,
      puissanceAssignee: fields[2] as String,
      tensionPrimaireSecondaire: fields[3] as String,
      relaisBuchholz: fields[4] as String,
      typeRefroidissement: fields[5] as String,
      regimeNeutre: fields[6] as String,
      createdAt: fields[26] as DateTime?,
      updatedAt: fields[27] as DateTime?,
      elementsVerifies: (fields[7] as List?)?.cast<ElementControle>(),
      photos: (fields[8] as List?)?.cast<String>(),
      calibreDisjoncteur: fields[9] as String?,
      sectionCables: fields[10] as String?,
      observations: (fields[11] as List?)?.cast<ElementControle>(),
      syncId: fields[12] as String?,
      intensiteNominale: fields[13] as String?,
      couplage: fields[14] as String?,
      typeReseau: fields[15] as String?,
      pccAmont: fields[16] as String?,
      puissanceUcc: fields[17] as String?,
      ik3Max: fields[18] as String?,
      nom: fields[19] as String?,
      photo: fields[20] as String?,
      repere: fields[21] as String?,
      marque: fields[22] as String?,
      anneeFabrication: fields[23] as String?,
      typeImmersion: fields[24] as String?,
      presenceDGPT2: fields[25] as String?,
      sectionCablePhase: fields[28] as String?,
      sectionCableNeutre: fields[29] as String?,
      conducteursPhase: fields[30] as int?,
      conducteursNeutre: fields[31] as int?,
      courantReglageDisjoncteur: fields[32] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransformateurMTBT obj) {
    writer
      ..writeByte(33)
      ..writeByte(0)
      ..write(obj.typeTransformateur)
      ..writeByte(1)
      ..write(obj.marqueAnnee)
      ..writeByte(2)
      ..write(obj.puissanceAssignee)
      ..writeByte(3)
      ..write(obj.tensionPrimaireSecondaire)
      ..writeByte(4)
      ..write(obj.relaisBuchholz)
      ..writeByte(5)
      ..write(obj.typeRefroidissement)
      ..writeByte(6)
      ..write(obj.regimeNeutre)
      ..writeByte(7)
      ..write(obj.elementsVerifies)
      ..writeByte(8)
      ..write(obj.photos)
      ..writeByte(9)
      ..write(obj.calibreDisjoncteur)
      ..writeByte(10)
      ..write(obj.sectionCables)
      ..writeByte(11)
      ..write(obj.observations)
      ..writeByte(12)
      ..write(obj.syncId)
      ..writeByte(13)
      ..write(obj.intensiteNominale)
      ..writeByte(14)
      ..write(obj.couplage)
      ..writeByte(15)
      ..write(obj.typeReseau)
      ..writeByte(16)
      ..write(obj.pccAmont)
      ..writeByte(17)
      ..write(obj.puissanceUcc)
      ..writeByte(18)
      ..write(obj.ik3Max)
      ..writeByte(19)
      ..write(obj.nom)
      ..writeByte(20)
      ..write(obj.photo)
      ..writeByte(21)
      ..write(obj.repere)
      ..writeByte(22)
      ..write(obj.marque)
      ..writeByte(23)
      ..write(obj.anneeFabrication)
      ..writeByte(24)
      ..write(obj.typeImmersion)
      ..writeByte(25)
      ..write(obj.presenceDGPT2)
      ..writeByte(26)
      ..write(obj.createdAt)
      ..writeByte(27)
      ..write(obj.updatedAt)
      ..writeByte(28)
      ..write(obj.sectionCablePhase)
      ..writeByte(29)
      ..write(obj.sectionCableNeutre)
      ..writeByte(30)
      ..write(obj.conducteursPhase)
      ..writeByte(31)
      ..write(obj.conducteursNeutre)
      ..writeByte(32)
      ..write(obj.courantReglageDisjoncteur);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransformateurMTBTAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CoffretArmoireAdapter extends TypeAdapter<CoffretArmoire> {
  @override
  final int typeId = 11;

  @override
  CoffretArmoire read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CoffretArmoire(
      id: fields[28] as String?,
      qrCode: fields[0] as String,
      nom: fields[1] as String,
      type: fields[2] as String,
      description: fields[3] as String?,
      repere: fields[4] as String?,
      zoneAtex: fields[5] == null ? false : fields[5] as bool,
      domaineTension: fields[6] == null ? '' : fields[6] as String,
      identificationArmoire: fields[7] == null ? false : fields[7] as bool,
      signalisationDanger: fields[8] == null ? false : fields[8] as bool,
      presenceSchema: fields[9] == null ? false : fields[9] as bool,
      presenceParafoudre: fields[10] == null ? false : fields[10] as bool,
      verificationThermographie:
          fields[11] == null ? false : fields[11] as bool,
      presenceDefautThermo: fields[24] as String?,
      alimenteeParTransformateur: fields[26] as bool?,
      transformateurId: fields[38] as String?,
      transformateurNomComplet: fields[39] as String?,
      presenceCPI: fields[27] as bool?,
      departPrisAvecProtection: fields[29] as bool?,
      createdAt: fields[30] as DateTime?,
      updatedAt: fields[31] as DateTime?,
      indiceIpIk: fields[32] as String?,
      indiceIpIkRepere: fields[40] as String?,
      departures: (fields[33] as List?)?.cast<DepartEquipement>(),
      terminalCircuits:
          (fields[34] as List?)?.cast<CircuitTerminalEquipement>(),
      sourceEquipementId: fields[35] as String?,
      sourceNomComplet: fields[36] as String?,
      sourceDepartId: fields[37] as String?,
      alimentations: (fields[12] as List?)?.cast<Alimentation>(),
      protectionTete: fields[13] as Alimentation?,
      pointsVerification: (fields[14] as List?)?.cast<PointVerification>(),
      observationsLibres: (fields[15] as List?)?.cast<ObservationLibre>(),
      photos: (fields[16] as List?)?.cast<String>(),
      statut: fields[18] as String,
      currentStep: fields[19] as int,
      numeroEquipement: fields[17] as String?,
      photosExternes: (fields[20] as List?)?.cast<String>(),
      photosInternes: (fields[21] as List?)?.cast<String>(),
      observationsParafoudre: (fields[22] as List?)?.cast<ObservationLibre>(),
      observationsParafoudreEnrichies:
          (fields[23] as List?)?.cast<ElementControle>(),
    ).._accessible = fields[25] == null ? true : fields[25] as bool?;
  }

  @override
  void write(BinaryWriter writer, CoffretArmoire obj) {
    writer
      ..writeByte(41)
      ..writeByte(0)
      ..write(obj.qrCode)
      ..writeByte(1)
      ..write(obj.nom)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.repere)
      ..writeByte(5)
      ..write(obj.zoneAtex)
      ..writeByte(6)
      ..write(obj.domaineTension)
      ..writeByte(7)
      ..write(obj.identificationArmoire)
      ..writeByte(8)
      ..write(obj.signalisationDanger)
      ..writeByte(9)
      ..write(obj.presenceSchema)
      ..writeByte(10)
      ..write(obj.presenceParafoudre)
      ..writeByte(11)
      ..write(obj.verificationThermographie)
      ..writeByte(12)
      ..write(obj.alimentations)
      ..writeByte(13)
      ..write(obj.protectionTete)
      ..writeByte(14)
      ..write(obj.pointsVerification)
      ..writeByte(15)
      ..write(obj.observationsLibres)
      ..writeByte(16)
      ..write(obj.photos)
      ..writeByte(17)
      ..write(obj.numeroEquipement)
      ..writeByte(18)
      ..write(obj.statut)
      ..writeByte(19)
      ..write(obj.currentStep)
      ..writeByte(20)
      ..write(obj.photosExternes)
      ..writeByte(21)
      ..write(obj.photosInternes)
      ..writeByte(22)
      ..write(obj.observationsParafoudre)
      ..writeByte(23)
      ..write(obj.observationsParafoudreEnrichies)
      ..writeByte(24)
      ..write(obj.presenceDefautThermo)
      ..writeByte(25)
      ..write(obj._accessible)
      ..writeByte(26)
      ..write(obj.alimenteeParTransformateur)
      ..writeByte(27)
      ..write(obj.presenceCPI)
      ..writeByte(28)
      ..write(obj.id)
      ..writeByte(29)
      ..write(obj.departPrisAvecProtection)
      ..writeByte(30)
      ..write(obj.createdAt)
      ..writeByte(31)
      ..write(obj.updatedAt)
      ..writeByte(32)
      ..write(obj.indiceIpIk)
      ..writeByte(33)
      ..write(obj.departures)
      ..writeByte(34)
      ..write(obj.terminalCircuits)
      ..writeByte(35)
      ..write(obj.sourceEquipementId)
      ..writeByte(36)
      ..write(obj.sourceNomComplet)
      ..writeByte(37)
      ..write(obj.sourceDepartId)
      ..writeByte(38)
      ..write(obj.transformateurId)
      ..writeByte(39)
      ..write(obj.transformateurNomComplet)
      ..writeByte(40)
      ..write(obj.indiceIpIkRepere);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoffretArmoireAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlimentationAdapter extends TypeAdapter<Alimentation> {
  @override
  final int typeId = 12;

  @override
  Alimentation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Alimentation(
      id: fields[15] as String?,
      typeProtection: fields[0] as String,
      courbe: fields[6] as String?,
      ddr: fields[7] as String?,
      pdcKA: fields[1] as String,
      calibre: fields[2] as String,
      sectionCable: fields[3] as String,
      photos: (fields[4] as List?)?.cast<String>(),
      source: fields[5] as String,
      sourceKnown: fields[8] as String?,
      marqueDisjoncteur: fields[9] as String?,
      icc3Max: fields[10] as String?,
      nombreCables: fields[11] as String?,
      sectionCableNeutre: fields[12] as String?,
      conducteursPhase: fields[13] as int?,
      conducteursNeutre: fields[14] as int?,
      natureCable: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Alimentation obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.typeProtection)
      ..writeByte(1)
      ..write(obj.pdcKA)
      ..writeByte(2)
      ..write(obj.calibre)
      ..writeByte(3)
      ..write(obj.sectionCable)
      ..writeByte(4)
      ..write(obj.photos)
      ..writeByte(5)
      ..write(obj.source)
      ..writeByte(6)
      ..write(obj.courbe)
      ..writeByte(7)
      ..write(obj.ddr)
      ..writeByte(8)
      ..write(obj.sourceKnown)
      ..writeByte(9)
      ..write(obj.marqueDisjoncteur)
      ..writeByte(10)
      ..write(obj.icc3Max)
      ..writeByte(11)
      ..write(obj.nombreCables)
      ..writeByte(12)
      ..write(obj.sectionCableNeutre)
      ..writeByte(13)
      ..write(obj.conducteursPhase)
      ..writeByte(14)
      ..write(obj.conducteursNeutre)
      ..writeByte(15)
      ..write(obj.id)
      ..writeByte(16)
      ..write(obj.natureCable);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlimentationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PointVerificationAdapter extends TypeAdapter<PointVerification> {
  @override
  final int typeId = 13;

  @override
  PointVerification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PointVerification(
      pointVerification: fields[0] as String,
      conformite: fields[1] as String,
      observation: fields[2] as String?,
      referenceNormative: fields[3] as String?,
      priorite: fields[4] as int?,
      photos: (fields[5] as List?)?.cast<String>(),
      observations: (fields[6] as List?)?.cast<ElementControle>(),
      criticite: fields[7] as String?,
      familleRisque: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PointVerification obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.pointVerification)
      ..writeByte(1)
      ..write(obj.conformite)
      ..writeByte(2)
      ..write(obj.observation)
      ..writeByte(3)
      ..write(obj.referenceNormative)
      ..writeByte(4)
      ..write(obj.priorite)
      ..writeByte(5)
      ..write(obj.photos)
      ..writeByte(6)
      ..write(obj.observations)
      ..writeByte(7)
      ..write(obj.criticite)
      ..writeByte(8)
      ..write(obj.familleRisque);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointVerificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ObservationLibreAdapter extends TypeAdapter<ObservationLibre> {
  @override
  final int typeId = 24;

  @override
  ObservationLibre read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ObservationLibre(
      texte: fields[0] as String,
      photos: (fields[1] as List?)?.cast<String>(),
      dateCreation: fields[2] as DateTime?,
      dateModification: fields[3] as DateTime?,
      pointVerificationKey: fields[4] as String?,
      referenceNormative: fields[5] as String?,
      familleRisque: fields[6] as String?,
      criticite: fields[7] as String?,
      isAutoLinked: fields[8] == null ? false : fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ObservationLibre obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.texte)
      ..writeByte(1)
      ..write(obj.photos)
      ..writeByte(2)
      ..write(obj.dateCreation)
      ..writeByte(3)
      ..write(obj.dateModification)
      ..writeByte(4)
      ..write(obj.pointVerificationKey)
      ..writeByte(5)
      ..write(obj.referenceNormative)
      ..writeByte(6)
      ..write(obj.familleRisque)
      ..writeByte(7)
      ..write(obj.criticite)
      ..writeByte(8)
      ..write(obj.isAutoLinked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObservationLibreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DepartEquipementAdapter extends TypeAdapter<DepartEquipement> {
  @override
  final int typeId = 64;

  @override
  DepartEquipement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DepartEquipement(
      id: fields[0] as String?,
      protectionTete: fields[1] as String,
      identification: fields[2] as String,
      typeProtection: fields[3] as String,
      marque: fields[4] as String,
      courbe: fields[5] as String,
      pdcKA: fields[6] as String,
      icc3Max: fields[7] as String,
      calibre: fields[8] as String,
      sectionCable: fields[9] as String,
      ddr: fields[10] as String,
      nombreCables: fields[11] as String?,
      sectionCableNeutre: fields[12] as String?,
      conducteursPhase: fields[13] as int?,
      conducteursNeutre: fields[14] as int?,
      natureCable: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DepartEquipement obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.protectionTete)
      ..writeByte(2)
      ..write(obj.identification)
      ..writeByte(3)
      ..write(obj.typeProtection)
      ..writeByte(4)
      ..write(obj.marque)
      ..writeByte(5)
      ..write(obj.courbe)
      ..writeByte(6)
      ..write(obj.pdcKA)
      ..writeByte(7)
      ..write(obj.icc3Max)
      ..writeByte(8)
      ..write(obj.calibre)
      ..writeByte(9)
      ..write(obj.sectionCable)
      ..writeByte(10)
      ..write(obj.ddr)
      ..writeByte(11)
      ..write(obj.nombreCables)
      ..writeByte(12)
      ..write(obj.sectionCableNeutre)
      ..writeByte(13)
      ..write(obj.conducteursPhase)
      ..writeByte(14)
      ..write(obj.conducteursNeutre)
      ..writeByte(15)
      ..write(obj.natureCable);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartEquipementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CircuitTerminalEquipementAdapter
    extends TypeAdapter<CircuitTerminalEquipement> {
  @override
  final int typeId = 65;

  @override
  CircuitTerminalEquipement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CircuitTerminalEquipement(
      id: fields[0] as String?,
      protectionTete: fields[1] as String,
      identification: fields[2] as String,
      typeProtection: fields[3] as String,
      marque: fields[4] as String,
      courbe: fields[5] as String,
      pdcKA: fields[6] as String,
      icc3Max: fields[7] as String,
      calibre: fields[8] as String,
      sectionCable: fields[9] as String,
      ddr: fields[10] as String,
      nombreCables: fields[11] as String?,
      sectionCableNeutre: fields[12] as String?,
      conducteursPhase: fields[13] as int?,
      conducteursNeutre: fields[14] as int?,
      natureCable: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CircuitTerminalEquipement obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.protectionTete)
      ..writeByte(2)
      ..write(obj.identification)
      ..writeByte(3)
      ..write(obj.typeProtection)
      ..writeByte(4)
      ..write(obj.marque)
      ..writeByte(5)
      ..write(obj.courbe)
      ..writeByte(6)
      ..write(obj.pdcKA)
      ..writeByte(7)
      ..write(obj.icc3Max)
      ..writeByte(8)
      ..write(obj.calibre)
      ..writeByte(9)
      ..write(obj.sectionCable)
      ..writeByte(10)
      ..write(obj.ddr)
      ..writeByte(11)
      ..write(obj.nombreCables)
      ..writeByte(12)
      ..write(obj.sectionCableNeutre)
      ..writeByte(13)
      ..write(obj.conducteursPhase)
      ..writeByte(14)
      ..write(obj.conducteursNeutre)
      ..writeByte(15)
      ..write(obj.natureCable);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CircuitTerminalEquipementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
