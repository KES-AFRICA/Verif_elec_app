import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/file_storage_service.dart';
import 'package:inspec_app/services/hive_service.dart';

enum AssetType { logo, qrCode, qrCodeQ18 }

/// Écran de gestion du Logo et des QR Codes (Vérif. Élec & Rapport Q18) d'une Mission
class ClientLogoScreen extends StatefulWidget {
  final Mission mission;

  const ClientLogoScreen({
    super.key,
    required this.mission,
  });

  @override
  State<ClientLogoScreen> createState() => _ClientLogoScreenState();
}

class _ClientLogoScreenState extends State<ClientLogoScreen> {
  File? _logoFile;
  File? _qrCodeFile;
  File? _qrCodeQ18File;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  void _loadAssets() {
    if (widget.mission.logoClient != null &&
        widget.mission.logoClient!.isNotEmpty) {
      final file = File(widget.mission.logoClient!);
      if (file.existsSync()) {
        _logoFile = file;
      }
    }
    if (widget.mission.qrCodeClient != null &&
        widget.mission.qrCodeClient!.isNotEmpty) {
      final file = File(widget.mission.qrCodeClient!);
      if (file.existsSync()) {
        _qrCodeFile = file;
      }
    }
    if (widget.mission.qrCodeQ18 != null &&
        widget.mission.qrCodeQ18!.isNotEmpty) {
      final file = File(widget.mission.qrCodeQ18!);
      if (file.existsSync()) {
        _qrCodeQ18File = file;
      }
    }
    setState(() {});
  }

  /// BottomSheet de choix de la source d'image pour Logo ou QR Code
  void _showImageSourceDialog(AssetType assetType) {
    final String title;
    switch (assetType) {
      case AssetType.logo:
        title = 'Importer un logo client';
        break;
      case AssetType.qrCode:
        title = 'Importer un QR Code (Vérif. Électrique)';
        break;
      case AssetType.qrCodeQ18:
        title = 'Importer un QR Code (Rapport Q18)';
        break;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez la source de l\'image',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Appareil Photo',
                    color: AppTheme.primaryBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSaveAsset(ImageSource.camera, assetType);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galerie Photos',
                    color: Colors.indigo.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSaveAsset(ImageSource.gallery, assetType);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sélection et sauvegarde de l'asset (Logo ou QR Code)
  Future<void> _pickAndSaveAsset(ImageSource source, AssetType assetType) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final sourceFile = File(pickedFile.path);

      if (assetType == AssetType.logo) {
        final savedFile = await FileStorageService.saveClientLogo(
          widget.mission.id,
          sourceFile,
        );
        widget.mission.logoClient = savedFile.path;
        await widget.mission.save();
        await HiveService.saveMission(widget.mission);

        setState(() {
          _logoFile = savedFile;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo client mis à jour avec succès !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (assetType == AssetType.qrCode) {
        final savedFile = await FileStorageService.saveClientQrCode(
          widget.mission.id,
          sourceFile,
        );
        widget.mission.qrCodeClient = savedFile.path;
        await widget.mission.save();
        await HiveService.saveMission(widget.mission);

        setState(() {
          _qrCodeFile = savedFile;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code de la mission mis à jour avec succès !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (assetType == AssetType.qrCodeQ18) {
        final savedFile = await FileStorageService.saveQ18QrCode(
          widget.mission.id,
          sourceFile,
        );
        widget.mission.qrCodeQ18 = savedFile.path;
        await widget.mission.save();
        await HiveService.saveMission(widget.mission);

        setState(() {
          _qrCodeQ18File = savedFile;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code du rapport Q18 mis à jour avec succès !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'importation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Suppression confirmée de l'asset
  Future<void> _confirmDeleteAsset(AssetType assetType) async {
    final title = assetType == AssetType.logo
        ? 'Supprimer le logo ?'
        : (assetType == AssetType.qrCode
            ? 'Supprimer le QR Code (Vérif. Élec) ?'
            : 'Supprimer le QR Code Q18 ?');
    final message = assetType == AssetType.logo
        ? 'Voulez-vous vraiment supprimer le logo client associé à la mission "${widget.mission.nomClient}" ?'
        : (assetType == AssetType.qrCode
            ? 'Voulez-vous vraiment supprimer le QR Code de vérification électrique associé à la mission "${widget.mission.nomClient}" ?'
            : 'Voulez-vous vraiment supprimer le QR Code du rapport Q18 associé à la mission "${widget.mission.nomClient}" ?');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: Colors.red.shade700, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'ANNULER',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('SUPPRIMER', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (assetType == AssetType.logo) {
        if (widget.mission.logoClient != null) {
          await FileStorageService.deleteClientLogo(widget.mission.logoClient!);
        }
        widget.mission.logoClient = null;
        await widget.mission.save();
        await HiveService.saveMission(widget.mission);

        setState(() {
          _logoFile = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo client supprimé'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (assetType == AssetType.qrCode) {
        if (widget.mission.qrCodeClient != null) {
          await FileStorageService.deleteClientQrCode(widget.mission.qrCodeClient!);
        }
        widget.mission.qrCodeClient = null;
        await widget.mission.save();
        await HiveService.saveMission(widget.mission);

        setState(() {
          _qrCodeFile = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code de la mission supprimé'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (assetType == AssetType.qrCodeQ18) {
        if (widget.mission.qrCodeQ18 != null) {
          await FileStorageService.deleteQ18QrCode(widget.mission.qrCodeQ18!);
        }
        widget.mission.qrCodeQ18 = null;
        await widget.mission.save();
        await HiveService.saveMission(widget.mission);

        setState(() {
          _qrCodeQ18File = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code du rapport Q18 supprimé'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Ouverture d'un fichier image en Plein Écran
  void _openFullScreenViewer(File file, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Text(
                '$title - ${widget.mission.nomClient}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Logo & QR Code du client',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.mission.nomClient,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Banner récapitulatif
                  _buildHeaderBanner(),

                  const SizedBox(height: 24),

                  // 2. Section Logo Client
                  _buildSectionHeader(
                    title: '1. Logo du Client',
                    subtitle: 'Image de marque positionnée sur la page de garde des rapports',
                    icon: Icons.branding_watermark_rounded,
                    iconColor: Colors.indigo.shade700,
                  ),
                  const SizedBox(height: 12),
                  if (_logoFile == null)
                    _buildEmptyCard(AssetType.logo)
                  else
                    _buildAssetCard(_logoFile!, AssetType.logo),

                  const SizedBox(height: 32),

                  // 3. Section QR Code Client / Mission
                  _buildSectionHeader(
                    title: '2. QR Code Vérification Électrique (Rapport Général)',
                    subtitle: 'Code de traçabilité intégré en bas de la page de garde du rapport de vérification',
                    icon: Icons.qr_code_2_rounded,
                    iconColor: Colors.teal.shade700,
                  ),
                  const SizedBox(height: 12),
                  if (_qrCodeFile == null)
                    _buildEmptyCard(AssetType.qrCode)
                  else
                    _buildAssetCard(_qrCodeFile!, AssetType.qrCode),

                  const SizedBox(height: 32),

                  // 4. Section QR Code Rapport Q18
                  _buildSectionHeader(
                    title: '3. QR Code du Rapport Q18 (APSAD D18)',
                    subtitle: 'Code de traçabilité officiel intégré dans le tableau de la page de garde du rapport Q18',
                    icon: Icons.qr_code_rounded,
                    iconColor: Colors.deepOrange.shade700,
                  ),
                  const SizedBox(height: 12),
                  if (_qrCodeQ18File == null)
                    _buildEmptyCard(AssetType.qrCodeQ18)
                  else
                    _buildAssetCard(_qrCodeQ18File!, AssetType.qrCodeQ18),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.perm_media_rounded,
              color: AppTheme.primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ressources Graphiques du Rapport',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Le logo et le QR Code sont automatiquement intégrés sur tous vos rapports générés (PDF & Word).',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Carte d'affichage d'état vide
  Widget _buildEmptyCard(AssetType assetType) {
    final String label;
    final String desc;
    final IconData icon;

    switch (assetType) {
      case AssetType.logo:
        label = 'Ajouter un logo';
        desc = 'Aucun logo client importé pour le moment';
        icon = Icons.add_photo_alternate_rounded;
        break;
      case AssetType.qrCode:
        label = 'Ajouter un QR Code';
        desc = 'Aucun QR Code Vérif. Élec importé pour le moment';
        icon = Icons.qr_code_scanner_rounded;
        break;
      case AssetType.qrCodeQ18:
        label = 'Ajouter le QR Code Q18';
        desc = 'Aucun QR Code Rapport Q18 importé pour cette mission';
        icon = Icons.qr_code_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showImageSourceDialog(assetType),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.file_upload_rounded, size: 20),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte d'affichage d'un asset configuré (Logo ou QR Code)
  Widget _buildAssetCard(File file, AssetType assetType) {
    final String title;
    switch (assetType) {
      case AssetType.logo:
        title = 'Logo Client';
        break;
      case AssetType.qrCode:
        title = 'QR Code Vérif. Électrique';
        break;
      case AssetType.qrCodeQ18:
        title = 'QR Code Rapport Q18';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Visualiseur d'image avec geste de clic pour le plein écran
          InkWell(
            onTap: () => _openFullScreenViewer(file, title),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 180,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Plein écran',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barre d'actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showImageSourceDialog(assetType),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Remplacer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmDeleteAsset(assetType),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
