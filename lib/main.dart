// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspec_app/pages/missions/home_screen.dart';
import 'package:inspec_app/pages/register_screen.dart';
import 'package:inspec_app/services/ai/mission_executive_summary_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/login_screen.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;
import 'package:inspec_app/features/auth/data/mappers/verificateur_mapper.dart';
import 'package:inspec_app/features/auth/domain/usecases/check_login_status_use_case.dart';
import 'package:inspec_app/features/auth/domain/usecases/get_current_user_use_case.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:inspec_app/features/backup/presentation/widgets/global_backup_progress_overlay.dart';
import 'package:inspec_app/features/backup/presentation/providers/backup_providers.dart';
import 'dart:async';

import 'package:inspec_app/config/api_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Hive
  await HiveService.init();

  // Clés API IA chargées depuis la configuration locale non-suivie par Git
  MissionExecutiveSummaryService.geminiApiKey = ApiKeys.geminiApiKey;
  MissionExecutiveSummaryService.groqApiKey = ApiKeys.groqApiKey;

  // Migration silencieuse des données existantes
  await HiveService.migratePointsVerificationPriorite();

  // Initialiser l'injection de dépendances
  await di.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vérif Elec',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      builder: (context, child) {
        return GlobalBackupProgressOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = di.sl<CheckLoginStatusUseCase>()();
    final verificateurEntity = di.sl<GetCurrentUserUseCase>()();

    if (isLoggedIn && verificateurEntity != null) {
      final currentUserModel = VerificateurMapper.toModel(verificateurEntity);

      // Déclencher immédiatement l'auto-sync et la sauvegarde de rattrapage au démarrage de l'app !
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          ref
              .read(backupOrchestratorProvider)
              .initAutoSyncEngine(currentUserModel.matricule),
        );
      });

      return HomeScreen(user: currentUserModel);
    } else {
      return const LoginScreen();
    }
  }
}
