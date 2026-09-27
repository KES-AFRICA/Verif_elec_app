// verify_project_memory.dart
// Script de vérification de l'intégrité de la mémoire projet KES Inspection App
// Usage : dart run docs/project-memory/verify_project_memory.dart
// Ce script vérifie que les fichiers de mémoire sont présents, cohérents et à jour.

import 'dart:io';

void main() async {
  print('🔍 KES Inspection App — Vérification de la Mémoire Projet');
  print('=' * 60);

  int errors = 0;
  int warnings = 0;

  // --- 1. Vérification des fichiers de mémoire obligatoires ---
  final memoryFiles = [
    'docs/project-memory/00_INDEX.md',
    'docs/project-memory/01_ARCHITECTURE_AND_STATE.md',
    'docs/project-memory/02_DOMAIN_AND_DATA_MODEL.md',
    'docs/project-memory/03_PERSISTENCE_AND_MIGRATIONS.md',
    'docs/project-memory/04_REPORTING_AND_STATISTICS.md',
    'docs/project-memory/05_BACKUP_IMPORT_EXPORT_MEDIA.md',
    'docs/project-memory/06_ADR_AND_FORENSIC_REGISTER.md',
    'docs/project-memory/07_UI_UX_FORMS.md',
  ];

  print('\n📂 Vérification des fichiers de mémoire...');
  for (final path in memoryFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      print('  ❌ MANQUANT : $path');
      errors++;
    } else {
      final size = file.lengthSync();
      if (size < 500) {
        print('  ⚠️  VIDE/TROP COURT : $path (${size} octets — contenu attendu > 500 octets)');
        warnings++;
      } else {
        print('  ✅ OK : $path (${(size / 1024).toStringAsFixed(1)} Ko)');
      }
    }
  }

  // --- 2. Vérification des fichiers Hive critiques ---
  final hiveCriticalModels = [
    'lib/models/mission.dart',
    'lib/models/audit_installations_electriques.dart',
    'lib/models/mesures_essais.dart',
    'lib/models/foudre.dart',
    'lib/models/jsa.dart',
  ];

  print('\n🗄️  Vérification des modèles Hive critiques...');
  for (final path in hiveCriticalModels) {
    final file = File(path);
    if (!file.existsSync()) {
      print('  ❌ MANQUANT : $path');
      errors++;
    } else {
      // Vérifier qu'il y a des annotations @HiveType et @HiveField
      final content = file.readAsStringSync();
      if (!content.contains('@HiveType') || !content.contains('@HiveField')) {
        print('  ⚠️  ANNOTATIONS HIVE MANQUANTES : $path');
        warnings++;
      } else {
        print('  ✅ OK : $path');
      }
    }
  }

  // --- 3. Vérification des services critiques ---
  final criticalServices = [
    'lib/services/hive_service.dart',
    'lib/services/equipment_number_service.dart',
    'lib/services/pdf/pdf_report_service.dart',
    'lib/services/statistics/analytics_engine.dart',
    'lib/core/di/injection_container.dart',
  ];

  print('\n⚙️  Vérification des services critiques...');
  for (final path in criticalServices) {
    final file = File(path);
    if (!file.existsSync()) {
      print('  ❌ MANQUANT : $path');
      errors++;
    } else {
      print('  ✅ OK : $path');
    }
  }

  // --- 4. Vérification des tests critiques ---
  final criticalTests = [
    'test/features/equipment_number_test.dart',
    'test/features/data_integrity_audit_test.dart',
    'test/services/pdf_q18_report_service_test.dart',
  ];

  print('\n🧪 Vérification des suites de tests critiques...');
  for (final path in criticalTests) {
    final file = File(path);
    if (!file.existsSync()) {
      print('  ⚠️  ABSENT : $path (test critique non trouvé)');
      warnings++;
    } else {
      print('  ✅ OK : $path');
    }
  }

  // --- 5. Vérification de AGENTS.md ---
  print('\n📋 Vérification de AGENTS.md...');
  final agentsMd = File('.agents/AGENTS.md');
  if (!agentsMd.existsSync()) {
    print('  ❌ MANQUANT : .agents/AGENTS.md');
    errors++;
  } else {
    final content = agentsMd.readAsStringSync();
    if (content.contains('project-memory') || content.contains('00_INDEX')) {
      print('  ✅ AGENTS.md référence bien la mémoire projet');
    } else {
      print('  ⚠️  AGENTS.md ne référence pas encore docs/project-memory/');
      warnings++;
    }
  }

  // --- 6. Vérification de la clé api_keys.dart.example ---
  print('\n🔐 Vérification de la sécurité...');
  if (File('lib/config/api_keys.dart').existsSync()) {
    // Vérifier qu'il n'est pas suivi par git
    final result = await Process.run('git', ['check-ignore', 'lib/config/api_keys.dart']);
    if (result.exitCode == 0) {
      print('  ✅ lib/config/api_keys.dart est bien dans .gitignore');
    } else {
      print('  ❌ DANGER : lib/config/api_keys.dart n\'est PAS dans .gitignore ! Secrets exposés !');
      errors++;
    }
  } else {
    print('  ℹ️  lib/config/api_keys.dart absent (normal si non configuré localement)');
  }

  if (File('lib/config/api_keys.dart.example').existsSync()) {
    print('  ✅ lib/config/api_keys.dart.example présent');
  } else {
    print('  ⚠️  lib/config/api_keys.dart.example manquant (exemple de configuration absent)');
    warnings++;
  }

  // --- Résumé ---
  print('\n' + '=' * 60);
  print('📊 RÉSUMÉ DE VÉRIFICATION');
  print('  Erreurs critiques : $errors');
  print('  Avertissements    : $warnings');
  if (errors == 0 && warnings == 0) {
    print('\n  🎉 Mémoire projet intègre ! Prêt à travailler.');
    exit(0);
  } else if (errors == 0) {
    print('\n  ✅ Pas d\'erreurs critiques, mais des points d\'attention existent.');
    exit(0);
  } else {
    print('\n  ❌ Des erreurs critiques ont été détectées. Consulter les messages ci-dessus.');
    exit(1);
  }
}
