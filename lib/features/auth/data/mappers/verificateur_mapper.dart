// lib/features/auth/data/mappers/verificateur_mapper.dart
import 'package:inspec_app/models/verificateur.dart';
import '../../domain/entities/verificateur_entity.dart';

class VerificateurMapper {
  static VerificateurEntity toEntity(Verificateur model) {
    return VerificateurEntity(
      id: model.id,
      nom: model.nom,
      prenom: model.prenom,
      email: model.email,
      password: model.password,
      matricule: model.matricule,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static Verificateur toModel(VerificateurEntity entity) {
    return Verificateur(
      id: entity.id,
      nom: entity.nom,
      prenom: entity.prenom,
      email: entity.email,
      password: entity.password,
      matricule: entity.matricule,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
