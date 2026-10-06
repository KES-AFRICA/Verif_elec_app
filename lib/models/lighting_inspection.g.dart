// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lighting_inspection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LuminaireQuestionAnswerAdapter
    extends TypeAdapter<LuminaireQuestionAnswer> {
  @override
  final int typeId = 62;

  @override
  LuminaireQuestionAnswer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LuminaireQuestionAnswer(
      questionIndex: fields[0] == null ? 1 : fields[0] as int,
      isConform: fields[1] == null ? true : fields[1] as bool,
      commentaire: fields[2] as String?,
      photoPaths: (fields[3] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, LuminaireQuestionAnswer obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.questionIndex)
      ..writeByte(1)
      ..write(obj.isConform)
      ..writeByte(2)
      ..write(obj.commentaire)
      ..writeByte(3)
      ..write(obj.photoPaths);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LuminaireQuestionAnswerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NonConformingLuminaireAdapter
    extends TypeAdapter<NonConformingLuminaire> {
  @override
  final int typeId = 61;

  @override
  NonConformingLuminaire read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NonConformingLuminaire(
      id: fields[0] == null ? '' : fields[0] as String,
      repereLocalisation: fields[1] as String?,
      answers: (fields[2] as List?)?.cast<LuminaireQuestionAnswer>() ?? [],
      createdAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, NonConformingLuminaire obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.repereLocalisation)
      ..writeByte(2)
      ..write(obj.answers)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NonConformingLuminaireAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LightingInspectionAdapter extends TypeAdapter<LightingInspection> {
  @override
  final int typeId = 60;

  @override
  LightingInspection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LightingInspection(
      id: fields[0] == null ? '' : fields[0] as String,
      missionId: fields[1] == null ? '' : fields[1] as String,
      batimentLocal: fields[2] == null ? '' : fields[2] as String,
      typeLuminaire: fields[3] == null ? '' : fields[3] as String,
      dateVerification: fields[4] == null ? DateTime.now() : fields[4] as DateTime,
      nbLuminairesConformes: fields[5] == null ? 0 : fields[5] as int,
      nonConformingLuminaires:
          (fields[6] as List?)?.cast<NonConformingLuminaire>() ?? [],
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LightingInspection obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.missionId)
      ..writeByte(2)
      ..write(obj.batimentLocal)
      ..writeByte(3)
      ..write(obj.typeLuminaire)
      ..writeByte(4)
      ..write(obj.dateVerification)
      ..writeByte(5)
      ..write(obj.nbLuminairesConformes)
      ..writeByte(6)
      ..write(obj.nonConformingLuminaires)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LightingInspectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
