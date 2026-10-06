// lib/features/auth/domain/entities/verificateur_entity.dart
class VerificateurEntity {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String password;
  final String matricule;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VerificateurEntity({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    required this.matricule,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$prenom $nom';
}
