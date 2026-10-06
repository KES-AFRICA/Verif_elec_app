// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verificateur.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VerificateurAdapter extends TypeAdapter<Verificateur> {
  @override
  final int typeId = 0;

  @override
  Verificateur read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Verificateur(
      id: fields[0] as String,
      nom: fields[1] as String,
      prenom: fields[2] as String,
      email: fields[3] as String,
      password: fields[4] as String,
      matricule: fields[5] as String,
      createdAt: (fields[6] as DateTime?) ?? DateTime.now(),
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Verificateur obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nom)
      ..writeByte(2)
      ..write(obj.prenom)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.password)
      ..writeByte(5)
      ..write(obj.matricule)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificateurAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
