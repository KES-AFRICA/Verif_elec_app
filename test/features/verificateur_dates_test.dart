import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/features/auth/domain/entities/verificateur_entity.dart';
import 'package:inspec_app/features/auth/data/mappers/verificateur_mapper.dart';

void main() {
  group('Verificateur Dates & Retrocompatibility Tests', () {
    test('Test A: Nouvel utilisateur avec createdAt et updatedAt initialisés', () {
      final now = DateTime.now();
      final user = Verificateur(
        id: 'user_1',
        nom: 'Mbappe',
        prenom: 'Kylian',
        email: 'kylian@kes.com',
        password: 'hash',
        matricule: 'KES-001',
        createdAt: now,
        updatedAt: now,
      );

      expect(user.createdAt, equals(now));
      expect(user.updatedAt, equals(now));

      // Modification du profil via copyWith
      final updatedTime = now.add(const Duration(minutes: 10));
      final modifiedUser = user.copyWith(
        nom: 'Mbappe Lottin',
        updatedAt: updatedTime,
      );

      // Vérification : createdAt préservé, updatedAt modifié
      expect(modifiedUser.createdAt, equals(now));
      expect(modifiedUser.updatedAt, equals(updatedTime));
      expect(modifiedUser.nom, equals('Mbappe Lottin'));
    });

    test('Test B: Utilisateur historique sans updatedAt (JSON/Hive legacy)', () {
      final legacyJson = {
        'id': 'legacy_user',
        'nom': 'Nono',
        'prenom': 'Jean',
        'email': 'jean@kes.com',
        'password': 'old_hash',
        'matricule': 'KES-LEGACY',
        'created_at': '2023-01-15T08:00:00.000Z',
        // Pas de 'updated_at'
      };

      final user = Verificateur.fromJson(legacyJson);
      expect(user.id, 'legacy_user');
      expect(user.createdAt, DateTime.parse('2023-01-15T08:00:00.000Z'));
      expect(user.updatedAt, isNull, reason: 'Ne doit pas inventer une date arbitraire pour un compte historique');

      // Conversion vers Entity et retour
      final entity = VerificateurMapper.toEntity(user);
      expect(entity.updatedAt, isNull);

      final backToModel = VerificateurMapper.toModel(entity);
      expect(backToModel.updatedAt, isNull);
      expect(backToModel.createdAt, user.createdAt);
    });

    test('toJson et fromJson préservent fidèlement updatedAt si renseigné', () {
      final created = DateTime.parse('2024-05-01T10:00:00.000Z');
      final updated = DateTime.parse('2024-06-01T12:00:00.000Z');
      final user = Verificateur(
        id: 'u2',
        nom: 'Talla',
        prenom: 'Eric',
        email: 'eric@kes.com',
        password: 'pwd',
        matricule: 'KES-002',
        createdAt: created,
        updatedAt: updated,
      );

      final json = user.toJson();
      expect(json['created_at'], '2024-05-01T10:00:00.000Z');
      expect(json['updated_at'], '2024-06-01T12:00:00.000Z');

      final restored = Verificateur.fromJson(json);
      expect(restored.createdAt, created);
      expect(restored.updatedAt, updated);
    });
  });
}
