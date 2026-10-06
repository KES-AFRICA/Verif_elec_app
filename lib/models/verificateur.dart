// lib/models/verificateur.dart
import 'package:hive/hive.dart';

part 'verificateur.g.dart';

@HiveType(typeId: 0)
class Verificateur extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  String prenom;

  @HiveField(3)
  String email;        // ← Email comme identifiant principal

  @HiveField(4)
  String password;

  @HiveField(5)
  String matricule;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  Verificateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    required this.matricule,
    required this.createdAt,
    this.updatedAt,
  });

  factory Verificateur.fromJson(Map<String, dynamic> json) {
    return Verificateur(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      matricule: json['matricule'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'password': password,
      'matricule': matricule,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Verificateur copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? password,
    String? matricule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Verificateur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      password: password ?? this.password,
      matricule: matricule ?? this.matricule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullName => '$prenom $nom';
}