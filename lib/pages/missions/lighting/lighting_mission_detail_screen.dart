import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/lighting/lighting_inspection_form_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:intl/intl.dart';

import 'package:inspec_app/services/trash_service.dart';
import 'package:inspec_app/pages/missions/lighting/lighting_summary_screen.dart';

class LightingMissionDetailScreen extends StatefulWidget {
  final Mission mission;

  const LightingMissionDetailScreen({
    Key? key,
    required this.mission,
  }) : super(key: key);

  @override
  State<LightingMissionDetailScreen> createState() =>
      _LightingMissionDetailScreenState();
}

class _LightingMissionDetailScreenState
    extends State<LightingMissionDetailScreen> {
  List<LightingInspection> _inspections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  void _loadInspections() {
    setState(() => _isLoading = true);
    final list =
        HiveService.getLightingInspectionsByMissionId(widget.mission.id);
    setState(() {
      _inspections = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: isSmallScreen ? 20 : 24, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Vérification Éclairage',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: _inspections.isNotEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'pdf_report_btn',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LightingSummaryScreen(mission: widget.mission),
                      ),
                    );
                  },
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  tooltip: 'Générer le rapport PDF',
                  child: const Icon(Icons.description),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'add_inspection_btn',
                  onPressed: _openCreateForm,
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.white,
                  tooltip: 'Nouvelle inspection',
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Carte Client / Site Équivalente à BasseTensionScreen (avec vrai statut Hive) ──
              _buildHeaderClientCard(isSmallScreen),

              const SizedBox(height: 20),

              // ── 2. Segmentation Nette Visuelle Client vs Liste ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INSPECTIONS RÉALISÉES (${_inspections.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_inspections.length} local(aux)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── 3. Liste des Inspections Éclairage (Affichage Complet sans tronquage) ──
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_inspections.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _inspections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final inspection = _inspections[index];
                    return _buildLocalInspectionCard(inspection, isSmallScreen);
                  },
                ),
              const SizedBox(height: 80), // Espace FAB
            ],
          ),
        ),
      ),
    );
  }

  /// Carte Client / Site avec récupération du statut exact en temps réel depuis Hive
  Widget _buildHeaderClientCard(bool isSmallScreen) {
    // Récupération dynamique de la version fraîche de la mission dans Hive pour éviter tout statut biaisé
    final currentMission = HiveService.getMissionById(widget.mission.id) ?? widget.mission;
    final status = currentMission.status;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 14.0 : 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLIENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppTheme.greyDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentMission.nomClient,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(status),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Site : ${currentMission.nomSite ?? "Non précisé"}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Badge de statut de mission réassorti
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'terminee':
      case 'terminée':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'TERMINÉE';
        break;
      case 'en_cours':
      case 'en cours':
        bg = AppTheme.primaryBlue.withValues(alpha: 0.1);
        fg = AppTheme.primaryBlue;
        label = 'EN COURS';
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        label = 'EN ATTENTE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  /// Carte d'Inspection avec affichage complet de TOUTES les informations (rien n'est coupé)
  Widget _buildLocalInspectionCard(
      LightingInspection inspection, bool isSmallScreen) {
    final isConforme = inspection.nbLuminairesNonConformes == 0;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConforme ? Colors.grey.shade200 : Colors.red.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openEditForm(inspection),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isConforme
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.meeting_room_outlined,
                      color: isConforme ? Colors.green.shade800 : Colors.red.shade800,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                inspection.batimentLocal,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isConforme
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                inspection.status.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type : ${inspection.typeLuminaire}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vérifié le ${dateFormat.format(inspection.dateVerification)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') _openEditForm(inspection);
                      if (val == 'delete') _confirmDelete(inspection);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '${inspection.nbLuminairesConformes} conformes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 14,
                        color: inspection.nbLuminairesNonConformes > 0
                            ? Colors.red.shade800
                            : AppTheme.greyDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${inspection.nbLuminairesNonConformes} non conformes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: inspection.nbLuminairesNonConformes > 0
                              ? Colors.red.shade800
                              : AppTheme.greyDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state quand aucune inspection n'existe
  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune inspection d\'éclairage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Démarrez votre première vérification d\'éclairage pour ce site en cliquant sur le bouton ci-dessous.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openCreateForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle inspection'),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateForm() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LightingInspectionFormScreen(
          missionId: widget.mission.id,
        ),
      ),
    );
    if (result == true) {
      _loadInspections();
    }
  }

  void _openEditForm(LightingInspection inspection) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LightingInspectionFormScreen(
          missionId: widget.mission.id,
          inspectionToEdit: inspection,
        ),
      ),
    );
    if (result == true) {
      _loadInspections();
    }
  }

  void _confirmDelete(LightingInspection inspection) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déplacer dans la corbeille ?'),
        content: Text(
            'Voulez-vous déplacer l\'inspection éclairage du local "${inspection.batimentLocal}" dans la corbeille ?\n\nVous pourrez la restaurer ultérieurement depuis la corbeille.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await TrashService.moveLightingInspectionToTrash(inspection);
              await HiveService.deleteLightingInspection(inspection.id);
              _loadInspections();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message ?? 'Inspection déplacée dans la corbeille.'),
                    backgroundColor: result.success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
            child: const Text('Déplacer dans la corbeille'),
          ),
        ],
      ),
    );
  }
}
