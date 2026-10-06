import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/services/gallery_photo_service.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_zone_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/utils/image_compress_helper.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:inspec_app/components/normative_search_suggestions_widget.dart';
import 'package:inspec_app/utils/observation_text_normalizer.dart';

class AjouterZoneScreen extends StatefulWidget {
  final Mission mission;
  final bool isMoyenneTension;
  final dynamic zone; // Pour l'édition
  final int? zoneIndex; // Pour l'édition
  final VoidCallback? onZoneCreated; // Callback après création d'une zone

  const AjouterZoneScreen({
    super.key,
    required this.mission,
    required this.isMoyenneTension,
    this.zone,
    this.zoneIndex,
    this.onZoneCreated,
  });

  bool get isEdition => zone != null;

  @override
  State<AjouterZoneScreen> createState() => _AjouterZoneScreenState();
}

class _AjouterZoneScreenState extends State<AjouterZoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isRiskZone = false;

  // Photos de la zone
  List<String> _zonePhotos = [];
  bool _isLoadingPhotos = false;
  
  // Observations libres - Toggle Oui/Non
  bool _addObservation = false; // Par défaut Non
  final _observationController = TextEditingController();
  List<String> _observationPhotos = [];
  final List<ObservationLibre> _observationsExistantes = [];

  String? _pendingPointVerificationKey;
  String? _pendingReferenceNormative;
  String? _pendingFamilleRisque;
  String? _pendingCriticite;

  @override
  void initState() {
    super.initState();
    if (widget.isEdition) {
      _chargerDonneesExistantes();
    }
  }
  
  void _chargerDonneesExistantes() {
    final zone = widget.zone!;
    _nomController.text = zone.nom;
    _isRiskZone = (zone is MoyenneTensionZone || zone is BasseTensionZone) ? (zone.isRiskZone ?? false) : false;
    
    // Charger les observations existantes
    _observationsExistantes.addAll(zone.observationsLibres);
    
    // Charger les photos de la zone
    if (zone.photos.isNotEmpty) {
      _zonePhotos = List.from(zone.photos);
    }
  }

  // ===== MÉTHODES POUR GESTION DES PHOTOS DE LA ZONE =====

  Future<void> _prendrePhotoZone() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      // BUG #1 FIX: vérifier mounted après tout await (le widget peut être disposé)
      if (!mounted) return;
      if (photo != null) {
        await GalleryPhotoService.saveToGallery(File(photo.path));
        setState(() => _isLoadingPhotos = true);
        try {
          final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'zones');
          if (!mounted) return;
          setState(() {
            _zonePhotos.add(savedPath);
            _isLoadingPhotos = false;
          });
        } catch (saveError) {
          if (!mounted) return;
          setState(() => _isLoadingPhotos = false);
          _showError('Erreur lors de la sauvegarde de la photo: $saveError');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPhotos = false);
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoZoneDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (!mounted) return;
      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        try {
          final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'zones');
          if (!mounted) return;
          setState(() {
            _zonePhotos.add(savedPath);
            _isLoadingPhotos = false;
          });
        } catch (saveError) {
          if (!mounted) return;
          setState(() => _isLoadingPhotos = false);
          _showError('Erreur: $saveError');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPhotos = false);
      _showError('Erreur lors de la sélection: $e');
    }
  }

  // ===== MÉTHODES POUR GESTION DES PHOTOS D'OBSERVATION =====

  Future<void> _prendrePhotoObservation() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (!mounted) return;
      if (photo != null) {
        await GalleryPhotoService.saveToGallery(File(photo.path));
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        if (!mounted) return;
        setState(() {
          _observationPhotos.add(savedPath);
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoObservationDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (!mounted) return;
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        if (!mounted) return;
        setState(() {
          _observationPhotos.add(savedPath);
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur lors de la sélection: $e');
    }
  }

  Future<String> _savePhotoToAppDirectory(File photoFile, String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/audit_photos/$subDir');
    
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    
    final fileName = '${subDir}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${photosDir.path}/$fileName';
    
    await ImageCompressHelper.compressImage(photoFile, newPath);
    return newPath;
  }

  void _previsualiserPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SafeFileImage(
                  path: photos[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _supprimerPhoto(photos, index);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _supprimerPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                photos.removeAt(index);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(String title, List<String> photos, Function prendrePhoto, Function choisirPhoto) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${photos.length}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        
        if (_isLoadingPhotos && title.contains('zone'))
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (photos.isEmpty)
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: isSmallScreen ? 40 : 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'Aucune photo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _previsualiserPhoto(photos, index),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SafeFileImage(
                          path: photos[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _supprimerPhoto(photos, index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => prendrePhoto(),
                icon: Icon(Icons.camera_alt, size: isSmallScreen ? 18 : 20),
                label: Text(
                  'Prendre',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => choisirPhoto(),
                icon: Icon(Icons.photo_library, size: isSmallScreen ? 18 : 20),
                label: Text(
                  'Galerie',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: isSmallScreen ? 20 : 24),
      ],
    );
  }

  // ===== GESTION DES OBSERVATIONS AVEC TOGGLE OUI/NON =====

  Widget _buildObservationsSection() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OBSERVATIONS SUR LA ZONE',
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),

        // Observations existantes
        if (_observationsExistantes.isNotEmpty)
          ..._observationsExistantes.asMap().entries.map((entry) {
            final index = entry.key;
            final observation = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
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
                              Text(
                                observation.texte,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                              if (observation.hasNormativeReference) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Text(
                                    'Réf : ${observation.referenceNormative}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: isSmallScreen ? 18 : 20),
                              onPressed: () {
                                setState(() {
                                  _observationController.text = observation.texte;
                                  _observationPhotos = List.from(observation.photos);
                                  _pendingPointVerificationKey = observation.pointVerificationKey;
                                  _pendingReferenceNormative = observation.referenceNormative;
                                  _pendingFamilleRisque = observation.familleRisque;
                                  _pendingCriticite = observation.criticite;
                                  _observationsExistantes.removeAt(index);
                                  _addObservation = true;
                                });
                              },
                              constraints: BoxConstraints(
                                minWidth: isSmallScreen ? 32 : 40,
                                minHeight: isSmallScreen ? 32 : 40,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red, size: isSmallScreen ? 18 : 20),
                              onPressed: () => _supprimerObservationExistante(index),
                              constraints: BoxConstraints(
                                minWidth: isSmallScreen ? 32 : 40,
                                minHeight: isSmallScreen ? 32 : 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (observation.photos.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Text(
                            'Photos associées (${observation.photos.length})',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: observation.photos.length,
                            itemBuilder: (context, photoIndex) {
                              return GestureDetector(
                                onTap: () => _previsualiserPhoto(observation.photos, photoIndex),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SafeFileImage(
                                      path: observation.photos[photoIndex],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),

        // Toggle Oui/Non pour ajouter une nouvelle observation
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Oui/Non
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ajouter une observation ?',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    // Bouton Oui
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _addObservation = true;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 14 : 18,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: _addObservation ? const Color(0xFFDCFCE7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _addObservation ? const Color(0xFF22C55E) : Colors.grey.shade300,
                            width: _addObservation ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          'Oui',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: _addObservation ? const Color(0xFF15803D) : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton Non
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _addObservation = false;
                          _observationController.clear();
                          _observationPhotos.clear();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 14 : 18,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: !_addObservation ? const Color(0xFFFEE2E2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: !_addObservation ? const Color(0xFFEF4444) : Colors.grey.shade300,
                            width: !_addObservation ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          'Non',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: !_addObservation ? const Color(0xFFB91C1C) : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
 
                // Champs d'observation (affichés uniquement si Oui)
                if (_addObservation) ...[
                  SizedBox(height: isSmallScreen ? 14 : 18),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _observationController,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Observation',
                        labelStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        ),
                        hintText: 'Saisissez votre observation...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),

                  NormativeSearchSuggestionsWidget(
                    queryText: _observationController.text,
                    selectedReferenceNormative: _pendingReferenceNormative,
                    selectedFamilleRisque: _pendingFamilleRisque,
                    selectedCriticite: _pendingCriticite,
                    onSelect: (res) {
                      setState(() {
                        _pendingPointVerificationKey = res.key;
                        _pendingReferenceNormative = res.referenceNormative;
                        _pendingFamilleRisque = res.familleRisque;
                        _pendingCriticite = res.criticite;
                      });
                    },
                    onUnlink: () {
                      setState(() {
                        _pendingPointVerificationKey = null;
                        _pendingReferenceNormative = null;
                        _pendingFamilleRisque = null;
                        _pendingCriticite = null;
                      });
                    },
                  ),
 
                  SizedBox(height: isSmallScreen ? 16 : 20),
 
                  // Photos pour la nouvelle observation
                  _buildPhotosSection(
                    'Photos pour cette observation',
                    _observationPhotos,
                    _prendrePhotoObservation,
                    _choisirPhotoObservationDepuisGalerie,
                  ),
 
                  SizedBox(height: isSmallScreen ? 12 : 16),
 
                  ElevatedButton(
                    onPressed: _ajouterObservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ajouter cette observation',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _ajouterObservation() {
    final rawTexte = _observationController.text.trim();
    if (rawTexte.isEmpty) {
      _showError('Veuillez saisir une observation');
      return;
    }
    final texte = ObservationTextNormalizer.normalize(rawTexte) ?? rawTexte;

    setState(() {
      _observationsExistantes.add(ObservationLibre(
        texte: texte,
        photos: List.from(_observationPhotos),
        pointVerificationKey: _pendingPointVerificationKey,
        referenceNormative: _pendingReferenceNormative,
        familleRisque: _pendingFamilleRisque,
        criticite: _pendingCriticite,
      ));
      _observationController.clear();
      _observationPhotos.clear();
      _pendingPointVerificationKey = null;
      _pendingReferenceNormative = null;
      _pendingFamilleRisque = null;
      _pendingCriticite = null;
      _addObservation = false; // Réinitialiser le toggle à Non après ajout
    });
    
    _showSuccess('Observation ajoutée');
  }

  void _supprimerObservationExistante(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'observation', style: TextStyle(fontSize: 16)),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette observation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _observationsExistantes.removeAt(index);
              });
              _showSuccess('Observation supprimée');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ===== FIN GESTION OBSERVATIONS =====

  void _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      try {
        dynamic zone;
        
        if (widget.isMoyenneTension) {
          zone = MoyenneTensionZone(
            id: widget.isEdition ? widget.zone.zoneId : null,
            nom: _nomController.text.trim(),
            coffrets: widget.isEdition ? widget.zone.coffrets : [],
            observationsLibres: _observationsExistantes,
            photos: _zonePhotos,
            locaux: widget.isEdition ? widget.zone.locaux : [],
            isRiskZone: _isRiskZone,
          );
        } else {
          zone = BasseTensionZone(
            id: widget.isEdition ? widget.zone.zoneId : null,
            nom: _nomController.text.trim(),
            locaux: widget.isEdition ? widget.zone.locaux : [],
            coffretsDirects: widget.isEdition ? widget.zone.coffretsDirects : [],
            observationsLibres: _observationsExistantes,
            photos: _zonePhotos,
            isRiskZone: _isRiskZone,
          );
        }

        bool success;
        if (widget.isEdition) {
          success = await _updateZone(zone);
        } else {
          if (widget.isMoyenneTension) {
            success = await HiveService.addMoyenneTensionZone(
              missionId: widget.mission.id,
              zone: zone as MoyenneTensionZone,
            );
          } else {
            success = await HiveService.addBasseTensionZone(
              missionId: widget.mission.id,
              zone: zone as BasseTensionZone,
            );
          }
        }

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.isEdition ? 'Zone modifiée' : 'Zone ajoutée'),
                backgroundColor: Colors.green,
              ),
            );
            
            if (!widget.isEdition) {
              // Appeler le callback si fourni
              if (widget.onZoneCreated != null) {
                widget.onZoneCreated!();
              }
              
              // Synchroniser les classements
              await HiveService.syncClassementsZonesFromAudit(widget.mission.id);
              
              if (!mounted) return; // BUG #1 FIX: vérifier mounted
              
              // Récupérer le classement créé
              final classement = await HiveService.getOrCreateClassementZone(
                missionId: widget.mission.id,
                nomZone: _nomController.text.trim(),
                typeZone: widget.isMoyenneTension ? 'MT' : 'BT',
              );
              
              if (!mounted) return; // BUG #1 FIX: vérifier mounted
              
              // BUG #2 + #3 FIX: utiliser pushReplacement au lieu de pop+push
              // Cela remplace AjouterZoneScreen par ClassementZoneScreen dans la pile.
              // MoyenneTensionScreen reprendra la main UNIQUEMENT quand
              // ClassementZoneScreen fera son propre pop → navigation cohérente.
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassementZoneScreen(
                    mission: widget.mission,
                    classement: classement,
                  ),
                ),
              );
            } else {
              Navigator.pop(context, true);
            }
          }
        } else {
          _showError('Erreur lors de la sauvegarde');
        }
      } catch (e) {
        _showError('Erreur: $e');
      }
    }
  }

  Future<bool> _updateZone(dynamic zone) async {
    return await HiveService.updateZoneById(
      missionId: widget.mission.id,
      zoneId: widget.zone.zoneId,
      updatedZone: zone,
      isMoyenneTension: widget.isMoyenneTension,
      fallbackIndex: widget.zoneIndex,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isMultiline = false, bool isRequired = false}) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
          alignLabelWithHint: isMultiline,
          floatingLabelStyle: const TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          hintText: label.contains('Nom') ? 'Ex: Sous-sol 1, RDC, Étage 2...' : null,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: label.contains('Nom') 
              ? Icon(Icons.location_on_rounded, color: AppTheme.primaryBlue.withOpacity(0.7), size: 20) 
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
        maxLines: isMultiline ? 4 : 1,
        validator: isRequired ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Veuillez saisir un nom';
          }
          return null;
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Fond gris-bleu très doux moderne
        appBar: AppBar(
          title: Text(
            widget.isEdition ? 'Modifier la Zone' : 'Ajouter une Zone',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.check, size: 24),
                onPressed: _sauvegarder,
                tooltip: 'Enregistrer',
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 16 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre indicatif
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                  child: Text(
                    'INFORMATIONS GÉNÉRALES',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                
                // Nom de la zone
                _buildTextField(_nomController, 'Nom de la zone*', isRequired: true),
                const SizedBox(height: 16),
      
                // Zone à risque ?
                _buildRiskZoneSelector(),
                const SizedBox(height: 16),

                // Photos de la zone
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: _buildPhotosSection(
                      'Photos de la zone',
                      _zonePhotos,
                      _prendrePhotoZone,
                      _choisirPhotoZoneDepuisGalerie,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
      
                // Observations libres
                if (!widget.isEdition) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: _buildObservationsSection(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Bouton d'enregistrement
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _sauvegarder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(double.infinity, isSmallScreen ? 48 : 56),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, size: isSmallScreen ? 18 : 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.isEdition ? 'MODIFIER LA ZONE' : 'AJOUTER LA ZONE',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskZoneSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: _isRiskZone ? Colors.orange.shade700 : AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Zone à risque ?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isRiskZone = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isRiskZone ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                      ),
                      child: Center(
                        child: Text(
                          'Non',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: !_isRiskZone ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isRiskZone = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isRiskZone ? Colors.orange.shade700 : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                      ),
                      child: Center(
                        child: Text(
                          'Oui',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isRiskZone ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _observationController.dispose();
    super.dispose();
  }
}