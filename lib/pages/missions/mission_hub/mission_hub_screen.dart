import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_detail_screen.dart';
import 'package:inspec_app/pages/missions/lighting/lighting_mission_detail_screen.dart';
import 'package:inspec_app/pages/missions/logo/client_logo_screen.dart';
import 'package:inspec_app/pages/missions/jsa/jsa_standalone_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/intervenants_service.dart';
import 'package:inspec_app/pages/missions/create_mission_screen.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';

/// Écran d'accueil de la Mission (Mission Hub)
/// Refonte UX/UI haut de gamme avec animations d'entrée, Hero Header immersif,
/// cartes dynamiques et modales interactives.
class MissionHubScreen extends StatefulWidget {
  final Mission mission;
  final Verificateur user;

  const MissionHubScreen({
    super.key,
    required this.mission,
    required this.user,
  });

  @override
  State<MissionHubScreen> createState() => _MissionHubScreenState();
}

class _MissionHubScreenState extends State<MissionHubScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _globalProgress = 0.0;
  int _completedModulesCount = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animController.forward();
    _computeProgress();

    // ✅ Enrôlement idempotent de l'utilisateur actuel dans la JSA
    IntervenantsService.ensureCurrentUserInJSA(widget.mission.id);
  }

  Future<void> _computeProgress() async {
    // 1. Module JSA (25%)
    final isJsaDone = HiveService.isJsaCompleted(widget.mission.id);
    final jsaVal = isJsaDone ? 0.25 : 0.0;

    // 2. Module Logo Client (25%)
    final hasLogo = widget.mission.logoClient != null &&
        widget.mission.logoClient!.isNotEmpty;
    final logoVal = hasLogo ? 0.25 : 0.0;

    // 3. Module Éclairage (25%)
    final lightingInspections =
        HiveService.getLightingInspectionsByMissionId(widget.mission.id);
    final lightingVal = lightingInspections.isNotEmpty ? 0.25 : 0.0;

    // 4. Module Électrique (25%)
    double electricVal = 0.0;
    final seqProgress = await SequenceProgressService.getProgress(widget.mission.id);
    final completedSteps = (seqProgress['completedSteps'] as List<dynamic>?) ?? [];
    if (widget.mission.status == 'terminee' || completedSteps.contains(5)) {
      electricVal = 0.25;
    } else if (completedSteps.isNotEmpty) {
      final ratio = (completedSteps.length / 5.0).clamp(0.0, 1.0);
      electricVal = ratio * 0.25;
    }

    final totalRatio = (jsaVal + logoVal + lightingVal + electricVal).clamp(0.0, 1.0);

    int count = 0;
    if (isJsaDone) count++;
    if (hasLogo) count++;
    if (lightingInspections.isNotEmpty) count++;
    if (electricVal >= 0.25 || widget.mission.status == 'terminee') count++;

    if (mounted) {
      setState(() {
        _globalProgress = totalRatio;
        _completedModulesCount = count;
      });
    }
  }

  Future<void> _handleEditMission(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateMissionScreen(
          currentUser: widget.user,
          missionToEdit: widget.mission,
        ),
      ),
    );
    if (result == true) {
      _computeProgress();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isJsaDone = HiveService.isJsaCompleted(widget.mission.id);
    final hasLogo = widget.mission.logoClient != null &&
        widget.mission.logoClient!.isNotEmpty;

    final progressPercent = _globalProgress;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. En-tête Immersif (SliverAppBar) avec Hero Banner
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryBlue,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    tooltip: 'Éditer la mission',
                    onPressed: () => _handleEditMission(context),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeaderBackground(
                context,
                isJsaDone: isJsaDone,
                completedModules: _completedModulesCount,
                progressPercent: progressPercent,
              ),
            ),
          ),

          // 2. Liste des Modules avec animations d'entrée en cascade
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // Section Label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MODULES DE LA MISSION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          color: isDarkMode ? Colors.grey.shade400 : AppTheme.greyDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isJsaDone
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isJsaDone
                                  ? Icons.shield_rounded
                                  : Icons.lock_clock_rounded,
                              size: 13,
                              color: isJsaDone ? Colors.green.shade700 : Colors.amber.shade900,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isJsaDone ? 'Sécurisée' : 'JSA Requise',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isJsaDone ? Colors.green.shade700 : Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grille / Colonne des Modules
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      return Column(
                        children: [
                          // Carte 1 : JSA (Prerequis Obligatoire)
                          _buildStaggeredItem(
                            index: 0,
                            child: _buildJsaCard(context, isJsaDone),
                          ),
                          const SizedBox(height: 16),

                          // Cartes 2 & 3 : Électrique & Éclairage (Responsive)
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildStaggeredItem(
                                    index: 1,
                                    child: _buildElectricCard(context, isJsaDone),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStaggeredItem(
                                    index: 2,
                                    child: _buildLightingCard(context, isJsaDone),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildStaggeredItem(
                              index: 1,
                              child: _buildElectricCard(context, isJsaDone),
                            ),
                            const SizedBox(height: 16),
                            _buildStaggeredItem(
                              index: 2,
                              child: _buildLightingCard(context, isJsaDone),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Carte 4 : Logo Client
                          _buildStaggeredItem(
                            index: 3,
                            child: _buildClientLogoCard(context, hasLogo),
                          ),
                          const SizedBox(height: 30),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constructeur de l'arrière-plan du Hero Header
  Widget _buildHeroHeaderBackground(
    BuildContext context, {
    required bool isJsaDone,
    required int completedModules,
    required double progressPercent,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Bleu nuit KES profond
            Color(0xFF2563EB), // Bleu roi vibrant
            Color(0xFF3B82F6), // Bleu lumineux
          ],
        ),
      ),
      child: Stack(
        children: [
          // Cercles décoratifs d'arrière-plan
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Contenu principal du Hero Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Name & Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.mission.nomClient,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Site Location
                  if (widget.mission.nomSite != null &&
                      widget.mission.nomSite!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Color(0xFF93C5FD),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.mission.nomSite!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFBFDBFE),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Barre de Progression Global Mission
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.task_alt_rounded,
                                  size: 16,
                                  color: isJsaDone ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Progression globale',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${(progressPercent * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isJsaDone ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Applique l'animation d'entrée en cascade sur chaque élément
  Widget _buildStaggeredItem({required int index, required Widget child}) {
    final start = (index * 0.15).clamp(0.0, 0.7);
    final end = (start + 0.35).clamp(0.0, 1.0);

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }

  // ── CARTES DES MODULES (MODERNES) ──

  /// Carte 1 : JSA (Analyse de Sécurité)
  Widget _buildJsaCard(BuildContext context, bool isJsaDone) {
    return _PremiumModuleCard(
      title: 'JSA - Analyse de Sécurité',
      subtitle: isJsaDone
          ? 'Analyse des risques et consignes de sécurité validées. Vous pouvez accéder aux volets d\'inspection.'
          : 'Analyse des risques, EPI, plan d\'urgence et consignes obligatoires avant d\'effectuer les inspections.',
      badgeText: isJsaDone ? '1. JSA Validée' : '1. Prérequis Obligatoire',
      badgeColor: isJsaDone ? const Color(0xFF16A34A) : const Color(0xFFD97706),
      badgeBgColor: isJsaDone
          ? const Color(0xFFDCFCE7)
          : const Color(0xFFFEF3C7),
      gradientColors: isJsaDone
          ? [const Color(0xFFECFDF5), Colors.white]
          : [const Color(0xFFFFFBEB), Colors.white],
      icon: isJsaDone ? Icons.verified_user_rounded : Icons.health_and_safety_rounded,
      iconColor: isJsaDone ? const Color(0xFF15803D) : const Color(0xFFB45309),
      iconBgColor: isJsaDone ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
      isLocked: false,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JsaStandaloneScreen(
              mission: widget.mission,
            ),
          ),
        );
        await _computeProgress();
      },
    );
  }

  /// Carte 2 : Vérification Électrique
  Widget _buildElectricCard(BuildContext context, bool isJsaDone) {
    return _PremiumModuleCard(
      title: 'Vérification électrique',
      subtitle: isJsaDone
          ? 'Audit complet des installations électriques MT/BT, transformateurs, armoires et mesures de sécurité.'
          : 'Complétez et validez d\'abord la JSA pour déverrouiller le volet de vérification électrique.',
      badgeText: isJsaDone ? '2. Audit Électrique' : 'Verrouillé - JSA requise',
      badgeColor: isJsaDone ? AppTheme.primaryBlue : Colors.grey.shade600,
      badgeBgColor: isJsaDone
          ? AppTheme.primaryBlue.withValues(alpha: 0.1)
          : Colors.grey.shade200,
      gradientColors: isJsaDone
          ? [const Color(0xFFEFF6FF), Colors.white]
          : [Colors.grey.shade100, Colors.grey.shade50],
      icon: isJsaDone ? Icons.bolt_rounded : Icons.lock_outline_rounded,
      iconColor: isJsaDone ? AppTheme.primaryBlue : Colors.grey.shade500,
      iconBgColor: isJsaDone
          ? AppTheme.primaryBlue.withValues(alpha: 0.15)
          : Colors.grey.shade300,
      isLocked: !isJsaDone,
      onTap: () async {
        if (!isJsaDone) {
          _showLockedBottomSheet('la vérification électrique');
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MissionDetailScreen(
              mission: widget.mission,
              user: widget.user,
            ),
          ),
        );
        await _computeProgress();
      },
    );
  }

  /// Carte 3 : Vérification Éclairage
  Widget _buildLightingCard(BuildContext context, bool isJsaDone) {
    return _PremiumModuleCard(
      title: 'Vérification éclairage',
      subtitle: isJsaDone
          ? 'Contrôle de conformité des luminaires, détection des non-conformités et état de fonctionnement.'
          : 'Complétez et validez d\'abord la JSA pour déverrouiller le module éclairage.',
      badgeText: isJsaDone ? '3. Module Éclairage' : 'Verrouillé - JSA requise',
      badgeColor: isJsaDone ? const Color(0xFFD97706) : Colors.grey.shade600,
      badgeBgColor: isJsaDone
          ? const Color(0xFFFEF3C7)
          : Colors.grey.shade200,
      gradientColors: isJsaDone
          ? [const Color(0xFFFFFBEB), Colors.white]
          : [Colors.grey.shade100, Colors.grey.shade50],
      icon: isJsaDone ? Icons.lightbulb_rounded : Icons.lock_outline_rounded,
      iconColor: isJsaDone ? const Color(0xFFB45309) : Colors.grey.shade500,
      iconBgColor: isJsaDone ? const Color(0xFFFDE68A) : Colors.grey.shade300,
      isLocked: !isJsaDone,
      onTap: () async {
        if (!isJsaDone) {
          _showLockedBottomSheet('la vérification éclairage');
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LightingMissionDetailScreen(
              mission: widget.mission,
            ),
          ),
        );
        await _computeProgress();
      },
    );
  }

  /// Carte 4 : Logo & QR Code du Client (avec prévisualisation réelle s'ils existent)
  Widget _buildClientLogoCard(BuildContext context, bool hasLogo) {
    final logoPath = widget.mission.logoClient;
    final logoFile = (hasLogo && logoPath != null) ? File(logoPath) : null;
    final qrPath = widget.mission.qrCodeClient;
    final qrFile = (qrPath != null && qrPath.isNotEmpty) ? File(qrPath) : null;
    final qrQ18Path = widget.mission.qrCodeQ18;
    final qrQ18File = (qrQ18Path != null && qrQ18Path.isNotEmpty) ? File(qrQ18Path) : null;

    final hasQr = qrFile != null && qrFile.existsSync();
    final hasQrQ18 = qrQ18File != null && qrQ18File.existsSync();
    final hasLogoFile = logoFile != null && logoFile.existsSync();

    String subtitleText = 'Gestion et personnalisation du logo et des QR Codes pour tous les rapports.';
    if (hasLogoFile && hasQr && hasQrQ18) {
      subtitleText = 'Logo, QR Code Vérif. Élec et QR Code Q18 configurés. Intégrés automatiquement sur vos rapports.';
    } else if (hasLogoFile && (hasQr || hasQrQ18)) {
      subtitleText = 'Logo et QR Code configurés. Ils seront positionnés automatiquement sur tous les rapports (PDF & Word).';
    } else if (hasLogoFile) {
      subtitleText = 'Logo configuré, QR Code manquant. Le logo apparaîtra automatiquement sur la page de garde.';
    } else if (hasQr || hasQrQ18) {
      subtitleText = 'QR Code configuré, Logo manquant. Le QR Code apparaîtra automatiquement sur la page de garde.';
    }

    String badgeTxt = '4. Logo & QR Codes';
    if (hasLogoFile && (hasQr || hasQrQ18)) {
      badgeTxt = hasQr && hasQrQ18 ? '4. Complet (Logo + 2 QR)' : '4. Configuré (Logo + QR)';
    } else if (hasLogoFile || hasQr || hasQrQ18) {
      badgeTxt = '4. Partiellement Configuré';
    }

    return _PremiumModuleCard(
      title: 'Logo & QR Code du client',
      subtitle: subtitleText,
      badgeText: badgeTxt,
      badgeColor: (hasLogoFile || hasQr || hasQrQ18) ? const Color(0xFF4F46E5) : const Color(0xFF6366F1),
      badgeBgColor: const Color(0xFFEEF2FF),
      gradientColors: const [Color(0xFFF5F3FF), Colors.white],
      icon: Icons.perm_media_rounded,
      iconColor: const Color(0xFF4338CA),
      iconBgColor: const Color(0xFFE0E7FF),
      isLocked: false,
      customPreviewWidget: hasLogoFile
          ? Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(logoFile, fit: BoxFit.contain),
              ),
            )
          : null,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientLogoScreen(
              mission: widget.mission,
            ),
          ),
        );
        await _computeProgress();
      },
    );
  }

  /// Modal Bottom Sheet moderne affiché lors du tap sur un module verrouillé
  void _showLockedBottomSheet(String moduleName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 32,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Module Verrouillé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'L\'Analyse de Sécurité (JSA) est un prérequis obligatoire avant d\'accéder à $moduleName.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JsaStandaloneScreen(
                          mission: widget.mission,
                        ),
                      ),
                    ).then((_) => _computeProgress());
                  },
                  icon: const Icon(Icons.shield_rounded, size: 18),
                  label: const Text(
                    'COMPLÉTER LA JSA MAINTENANT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Carte de Module Premium avec micro-animations tactiles (scale on press)
class _PremiumModuleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBgColor;
  final List<Color> gradientColors;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isLocked;
  final Widget? customPreviewWidget;
  final VoidCallback onTap;

  const _PremiumModuleCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBgColor,
    required this.gradientColors,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.isLocked,
    this.customPreviewWidget,
    required this.onTap,
  });

  @override
  State<_PremiumModuleCard> createState() => _PremiumModuleCardState();
}

class _PremiumModuleCardState extends State<_PremiumModuleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : widget.gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isLocked
                  ? Colors.black.withValues(alpha: 0.03)
                  : widget.badgeColor.withValues(alpha: 0.10),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: widget.isLocked
                ? (isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade200)
                : widget.badgeColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de la Carte (Icône/Aperçu + Titre/Badge + Chevron)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Miniature personnalisée ou Icône de module
                      widget.customPreviewWidget ??
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.iconBgColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              widget.icon,
                              size: 24,
                              color: widget.iconColor,
                            ),
                          ),
                      const SizedBox(width: 14),

                      // Badge & Titre
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: widget.badgeBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.badgeText,
                                style: TextStyle(
                                  color: widget.badgeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.isLocked
                                    ? Colors.grey.shade500
                                    : (isDarkMode ? Colors.white : AppTheme.textDark),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Flèche ou Cadenas
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.isLocked
                              ? Colors.grey.shade200
                              : widget.badgeColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isLocked
                              ? Icons.lock_rounded
                              : Icons.chevron_right_rounded,
                          size: 18,
                          color: widget.isLocked
                              ? Colors.grey.shade600
                              : widget.badgeColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description du module
                  Text(
                    widget.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: widget.isLocked
                          ? Colors.grey.shade500
                          : (isDarkMode
                              ? Colors.grey.shade400
                              : AppTheme.textLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
