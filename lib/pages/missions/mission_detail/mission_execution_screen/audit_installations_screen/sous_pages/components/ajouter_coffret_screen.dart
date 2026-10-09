import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/gallery_photo_service.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/essais_declenchement_screen.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';
import 'package:inspec_app/services/normative_reference_service.dart';
import 'package:inspec_app/utils/image_compress_helper.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/persistence_queue.dart';
import 'package:inspec_app/services/equipment_number_service.dart';
import 'package:inspec_app/features/mesures_essais/presentation/providers/mesures_essais_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:convert';
import 'package:inspec_app/core/utils/source_status_resolver.dart';
import 'dart:async';
import 'observation_enrichie_widget.dart';
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:inspec_app/components/normative_search_suggestions_widget.dart';
import 'package:inspec_app/services/normative_search_service.dart';
import 'package:inspec_app/services/equipment_source_search_service.dart';
import 'package:inspec_app/utils/observation_text_normalizer.dart';
import 'package:inspec_app/services/ip_ik_evaluator_service.dart';
import 'package:inspec_app/services/equipment_type_transition_service.dart';
import 'package:inspec_app/services/document_generation/essai_declenchement_helper.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/essai_declenchement_modal.dart';

// ================================================================
// EXTENSION RESPONSIVE
// ================================================================
extension ScreenSize on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 600;
  
  double get fontSizeXXL => isSmallScreen ? 18 : (isMediumScreen ? 20 : 22);
  double get fontSizeXL => isSmallScreen ? 16 : (isMediumScreen ? 17 : 18);
  double get fontSizeL => isSmallScreen ? 14 : (isMediumScreen ? 15 : 16);
  double get fontSizeM => isSmallScreen ? 13 : (isMediumScreen ? 14 : 15);
  double get fontSizeS => isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
  double get fontSizeXS => isSmallScreen ? 11 : (isMediumScreen ? 12 : 13);
  
  double get spacingXXL => isSmallScreen ? 24 : (isMediumScreen ? 28 : 32);
  double get spacingXL => isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);
  double get spacingL => isSmallScreen ? 14 : (isMediumScreen ? 15 : 16);
  double get spacingM => isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
  double get spacingS => isSmallScreen ? 8 : (isMediumScreen ? 10 : 12);
  double get spacingXS => isSmallScreen ? 6 : (isMediumScreen ? 7 : 8);
  
  double get iconSizeXL => isSmallScreen ? 22 : (isMediumScreen ? 24 : 26);
  double get iconSizeL => isSmallScreen ? 18 : (isMediumScreen ? 20 : 22);
  double get iconSizeM => isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);
  double get iconSizeS => isSmallScreen ? 14 : (isMediumScreen ? 15 : 16);
  double get iconSizeXS => isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
}

// ================================================================
// ÉTAPE 1 : INFORMATIONS DE BASE + PHOTOS + OBSERVATIONS MULTIPLES
// ================================================================
class _EtapeInformationsBase extends StatefulWidget {
  final TextEditingController nomController;
  final TextEditingController repereController;
  final TextEditingController numeroEquipementController;
  final String? selectedType;
  final Function(String?) onTypeChanged;
  final bool typeValid;
  final bool numeroEquipementValid;
  final bool nomValid;
  final bool repereValid;
  final VoidCallback onValidateNom;
  final VoidCallback onValidateNumeroEquipement;
  final VoidCallback onValidateRepere;
  final List<String> photosExterne;
  final List<String> photosInterne;
  final Function() onPrendrePhotoExterne;
  final Function() onChoisirPhotoExterne;
  final Function() onPrendrePhotoInterne;
  final Function() onChoisirPhotoInterne;
  final bool isLoadingPhotosExterne;
  final bool isLoadingPhotosInterne;
  final Function(int) onSupprimerPhotoExterne;
  final Function(int) onSupprimerPhotoInterne;
  final bool isInZone;

  // Système d'observations multiples (comme dans ajouter_local_screen)
  final bool addObservation;
  final Function(bool) onAddObservationChanged;
  final TextEditingController observationController;
  final List<String> observationPhotos;
  final List<ObservationLibre> observationsExistantes;
  final VoidCallback onPrendrePhotoObservation;
  final VoidCallback onChoisirPhotoObservation;
  final Function([String?, String?, String?, String?]) onAjouterObservation;
  final Function(int) onSupprimerObservation;

  const _EtapeInformationsBase({
    required this.nomController,
    required this.numeroEquipementController,
    required this.repereController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.typeValid,
    required this.nomValid,
    required this.repereValid,
    required this.numeroEquipementValid,
    required this.onValidateNumeroEquipement,
    required this.onValidateNom,
    required this.onValidateRepere,
    required this.photosExterne,
    required this.photosInterne,
    required this.onPrendrePhotoExterne,
    required this.onChoisirPhotoExterne,
    required this.onPrendrePhotoInterne,
    required this.onChoisirPhotoInterne,
    required this.isLoadingPhotosExterne,
    required this.isLoadingPhotosInterne,
    required this.onSupprimerPhotoExterne,
    required this.onSupprimerPhotoInterne,
    required this.isInZone,
    required this.addObservation,
    required this.onAddObservationChanged,
    required this.observationController,
    required this.observationPhotos,
    required this.observationsExistantes,
    required this.onPrendrePhotoObservation,
    required this.onChoisirPhotoObservation,
    required this.onAjouterObservation,
    required this.onSupprimerObservation,
  });

  @override
  State<_EtapeInformationsBase> createState() => _EtapeInformationsBaseState();
}

class _EtapeInformationsBaseState extends State<_EtapeInformationsBase> {
  final PageController _photosExterneController = PageController();
  final PageController _photosInterneController = PageController();
  int _currentExterneIndex = 0;
  int _currentInterneIndex = 0;

  String? _pendingPointVerificationKey;
  String? _pendingReferenceNormative;
  String? _pendingFamilleRisque;
  String? _pendingCriticite;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: [
        _buildModernHeader(context, 'Informations de base', 1, 4),
        SizedBox(height: context.spacingXL),
        
        if (widget.isInZone)
          Container(
            padding: EdgeInsets.all(context.spacingS),
            margin: EdgeInsets.only(bottom: context.spacingM),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(context.spacingS),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: context.iconSizeS),
                SizedBox(width: context.spacingS),
                Flexible(
                  child: Text(
                    'Cet équipement sera ajouté dans un local',
                    style: TextStyle(fontSize: context.fontSizeXS, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        
        _buildModernTextField(
          context,
          controller: widget.nomController,
          label: 'Nom de l\'équipement',
          icon: Icons.label_outline,
          isValid: widget.nomValid,
          onChanged: (_) => widget.onValidateNom(),
        ),
        SizedBox(height: context.spacingM),
      
        _buildModernTextField(
          context,
          controller: widget.numeroEquipementController,
          label: 'Numéro de l\'équipement (Auto)',
          icon: Icons.numbers_outlined,
          isValid: true,
          readOnly: true,
          onChanged: (_) {},
          isRequired: false,
        ),
        SizedBox(height: context.spacingM),
        
        _buildModernTextField(
          context,
          controller: widget.repereController,
          label: 'Repère',
          icon: Icons.location_on_sharp,
          isValid: widget.repereValid,
          onChanged: (_) => widget.onValidateRepere(),
        ),
        SizedBox(height: context.spacingM),
        
        _buildModernTypeSelector(context),
        SizedBox(height: context.spacingXL),
        
        _buildModernPhotoCarousel(
          context,
          title: 'PHOTO EXTERNE (obligatoire)',
          photos: widget.photosExterne,
          controller: _photosExterneController,
          currentIndex: _currentExterneIndex,
          onPageChanged: (index) => setState(() => _currentExterneIndex = index),
          isLoading: widget.isLoadingPhotosExterne,
          onPrendrePhoto: widget.onPrendrePhotoExterne,
          onChoisirPhoto: widget.onChoisirPhotoExterne,
          onSupprimerPhoto: widget.onSupprimerPhotoExterne,
          isRequired: true,
        ),
        SizedBox(height: context.spacingXL),
        
        _buildModernPhotoCarousel(
          context,
          title: 'PHOTO INTERNE (obligatoire)',
          photos: widget.photosInterne,
          controller: _photosInterneController,
          currentIndex: _currentInterneIndex,
          onPageChanged: (index) => setState(() => _currentInterneIndex = index),
          isLoading: widget.isLoadingPhotosInterne,
          onPrendrePhoto: widget.onPrendrePhotoInterne,
          onChoisirPhoto: widget.onChoisirPhotoInterne,
          onSupprimerPhoto: widget.onSupprimerPhotoInterne,
          isRequired: true,
        ),

        SizedBox(height: context.spacingL),

        // ── CARTE D'OBSERVATIONS MULTIPLES (comme dans ajouter_local_screen) ──
        _buildObservationsCard(context),

        SizedBox(height: context.spacingXXL),
      ],
    );
  }

  // ==================== MÉTHODES EXISTANTES (non modifiées) ====================
  Widget _buildModernHeader(BuildContext context, String title, int currentStep, int totalSteps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: context.iconSizeXL * 1.2,
              height: context.iconSizeXL * 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(context.spacingS),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: context.spacingS,
                    offset: Offset(0, context.spacingXS),
                  ),
                ],
              ),
              child: Icon(Icons.edit_note, color: Colors.white, size: context.iconSizeM),
            ),
            SizedBox(width: context.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                  ),
                  SizedBox(height: context.spacingXS),
                  Text(
                    'Étape $currentStep sur $totalSteps',
                    style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingM),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildModernTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isValid,
    required Function(String) onChanged,
    bool isRequired = true,
    bool readOnly = false,
  }) {
    final showBorderError = isRequired && !isValid;
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: readOnly
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: context.spacingS,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        onChanged: readOnly ? null : onChanged,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: context.fontSizeM,
          color: readOnly ? Colors.grey.shade800 : Colors.black,
          fontWeight: readOnly ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(
            color: showBorderError ? Colors.red.shade400 : Colors.grey.shade600,
            fontSize: context.fontSizeM,
          ),
          prefixIcon: Icon(
            icon,
            color: showBorderError
                ? Colors.red.shade400
                : (readOnly ? Colors.grey.shade600 : AppTheme.primaryBlue),
            size: context.iconSizeM,
          ),
          suffixIcon: readOnly
              ? Icon(Icons.lock_outline, color: Colors.grey.shade500, size: context.iconSizeS)
              : (isValid
                  ? Icon(Icons.check_circle, color: Colors.green, size: context.iconSizeS)
                  : (showBorderError
                      ? Icon(Icons.error_outline, color: Colors.red.shade300, size: context.iconSizeS)
                      : null)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.spacingM), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.spacingM),
            borderSide: BorderSide(
              color: showBorderError ? Colors.red.shade300 : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.spacingM),
            borderSide: BorderSide(
              color: showBorderError ? Colors.red.shade400 : AppTheme.primaryBlue,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingM),
        ),
      ),
    );
  }

  Widget _buildModernTypeSelector(BuildContext context) {
    const types = ['INVERSEUR', 'ARMOIRE', 'COFFRET', 'TGBT'];
    final validValue = (widget.selectedType != null && types.contains(widget.selectedType)) 
        ? widget.selectedType 
        : null;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.spacingL, context.spacingM, context.spacingL, context.spacingS),
            child: Row(
              children: [
                Icon(Icons.category_outlined, color: AppTheme.primaryBlue, size: context.iconSizeM),
                SizedBox(width: context.spacingS),
                Flexible(
                  child: Text(
                    'Type d\'équipement',
                    style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                  ),
                ),
                Text(' *', style: TextStyle(color: Colors.red, fontSize: context.fontSizeL)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
                border: Border.all(
                  color: !widget.typeValid ? Colors.red.shade300 : Colors.grey.shade300,
                  width: !widget.typeValid ? 1.5 : 1,
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: validValue,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryBlue, size: context.iconSizeM),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(context.spacingM),
                hint: Row(
                  children: [
                    Icon(Icons.search, size: context.iconSizeS, color: Colors.grey.shade500),
                    SizedBox(width: context.spacingS),
                    Flexible(
                      child: Text(
                        'Sélectionnez un type',
                        style: TextStyle(fontSize: context.fontSizeM, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingM),
                ),
                style: TextStyle(fontSize: context.fontSizeM, color: AppTheme.darkBlue, fontWeight: FontWeight.w500),
                items: types.map((t) => DropdownMenuItem<String>(
                  value: t,
                  child: Row(
                    children: [
                      Container(
                        width: context.spacingS,
                        height: context.spacingS,
                        decoration: BoxDecoration(
                          color: widget.selectedType == t ? AppTheme.primaryBlue : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.selectedType == t ? AppTheme.primaryBlue : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: widget.selectedType == t ? Icon(Icons.check, size: context.spacingXS, color: Colors.white) : null,
                      ),
                      SizedBox(width: context.spacingS),
                      Expanded(child: Text(t, style: TextStyle(fontSize: context.fontSizeM))),
                    ],
                  ),
                )).toList(),
                onChanged: widget.onTypeChanged,
                selectedItemBuilder: (BuildContext context) {
                  return types.map<Widget>((t) {
                    return Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: context.iconSizeS),
                        SizedBox(width: context.spacingS),
                        Expanded(child: Text(t, style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w500, color: AppTheme.darkBlue))),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
          ),
          if (!widget.typeValid)
            Padding(
              padding: EdgeInsets.only(left: context.spacingL, bottom: context.spacingM),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: context.iconSizeXS),
                  SizedBox(width: context.spacingXS),
                  Text('Sélectionnez un type', style: TextStyle(color: Colors.red, fontSize: context.fontSizeXS)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernPhotoCarousel(
    BuildContext context, {
    required String title,
    required List<String> photos,
    required PageController controller,
    required int currentIndex,
    required Function(int) onPageChanged,
    required bool isLoading,
    required Function() onPrendrePhoto,
    required Function() onChoisirPhoto,
    required Function(int) onSupprimerPhoto,
    bool isRequired = false,
  }) {
    final photoHeight = context.screenHeight * 0.2;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(
              children: [
                Icon(Icons.photo_camera_outlined, color: AppTheme.primaryBlue, size: context.iconSizeM),
                SizedBox(width: context.spacingS),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (photos.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.spacingL),
                    ),
                    child: Text(
                      '${photos.length}',
                      style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                    ),
                  ),
              ],
            ),
          ),
          
          if (isLoading)
            SizedBox(
              height: photoHeight,
              width: double.infinity,
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
            )
          else if (photos.isEmpty)
            Container(
              height: photoHeight,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: context.spacingL),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
                border: Border.all(color: isRequired ? Colors.red.shade300 : Colors.grey.shade200, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: context.iconSizeXL * 1.2,
                    color: isRequired ? Colors.red.shade400 : Colors.grey.shade400,
                  ),
                  SizedBox(height: context.spacingS),
                  Text(
                    isRequired ? 'Photo obligatoire' : 'Aucune photo',
                    style: TextStyle(color: isRequired ? Colors.red : Colors.grey.shade600, fontSize: context.fontSizeS),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Container(
                  height: photoHeight,
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: context.spacingL),
                  child: PageView.builder(
                    controller: controller,
                    onPageChanged: onPageChanged,
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: context.spacingXS),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(context.spacingS),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(context.spacingS),
                              child: SafeFileImage(path: photos[index], fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: context.spacingS,
                            right: context.spacingS + context.spacingXS,
                            child: GestureDetector(
                              onTap: () => onSupprimerPhoto(index),
                              child: Container(
                                padding: EdgeInsets.all(context.spacingXS),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: context.iconSizeS,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: context.spacingS,
                            left: context.spacingS + context.spacingXS,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(context.spacingL),
                              ),
                              child: Text(
                                '${index + 1}/${photos.length}',
                                style: TextStyle(
                                  fontSize: context.fontSizeXS,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (photos.length > 1)
                  Padding(
                    padding: EdgeInsets.only(top: context.spacingS, bottom: context.spacingS),
                    child: SmoothPageIndicator(
                      controller: controller,
                      count: photos.length,
                      effect: WormEffect(
                        dotWidth: context.spacingS,
                        dotHeight: context.spacingS,
                        activeDotColor: AppTheme.primaryBlue,
                        dotColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
              ],
            ),
          
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: _buildModernPhotoButton(
                    context,
                    icon: Icons.camera_alt,
                    label: 'Prendre',
                    onTap: onPrendrePhoto,
                  ),
                ),
                SizedBox(width: context.spacingS),
                Expanded(
                  child: _buildModernPhotoButton(
                    context,
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: onChoisirPhoto,
                    isSecondary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPhotoButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.spacingS),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.spacingS),
          decoration: BoxDecoration(
            gradient: isSecondary ? null : LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: isSecondary ? Colors.grey.shade100 : null,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: isSecondary ? Border.all(color: Colors.grey.shade300) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: context.iconSizeS, color: isSecondary ? Colors.grey.shade700 : Colors.white),
              SizedBox(width: context.spacingS),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: isSecondary ? Colors.grey.shade700 : Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== NOUVELLE CARTE OBSERVATIONS MULTIPLES ====================
  Widget _buildObservationsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(children: [
              Icon(Icons.notes_outlined, color: AppTheme.primaryBlue, size: context.iconSizeM),
              SizedBox(width: context.spacingS),
              Text('Observations', style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue)),
            ]),
          ),

          // Toggle Oui/Non
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacingL),
            child: Container(
              padding: EdgeInsets.all(context.spacingM),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.spacingS)),
              child: Row(children: [
                Expanded(child: Text('Ajouter une observation ?', style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w500, color: Colors.grey.shade800))),
                _buildToggleBtn(context, 'Oui', widget.addObservation, () => widget.onAddObservationChanged(true), Colors.green),
                SizedBox(width: context.spacingS),
                _buildToggleBtn(context, 'Non', !widget.addObservation, () => widget.onAddObservationChanged(false), Colors.red),
              ]),
            ),
          ),

          // Liste des observations existantes
          if (widget.observationsExistantes.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(context.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Observations enregistrées', style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  SizedBox(height: context.spacingS),
                  ...widget.observationsExistantes.asMap().entries.map((e) => _buildObsExistante(context, e.value, e.key)),
                ],
              ),
            ),

          // Formulaire d'ajout d'une nouvelle observation
          if (widget.addObservation)
            Padding(
              padding: EdgeInsets.all(context.spacingL),
              child: Column(children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.spacingS), border: Border.all(color: Colors.grey.shade200)),
                  child: TextFormField(
                    controller: widget.observationController,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: context.fontSizeS),
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Saisissez votre observation...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: context.fontSizeS),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(context.spacingM),
                    ),
                    maxLines: 3,
                  ),
                ),
                NormativeSearchSuggestionsWidget(
                  queryText: widget.observationController.text,
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
                SizedBox(height: context.spacingM),
                Row(children: [
                  Expanded(child: _buildPhotoBtn(context, Icons.camera_alt, 'Photo', widget.onPrendrePhotoObservation, false)),
                  SizedBox(width: context.spacingS),
                  Expanded(child: _buildPhotoBtn(context, Icons.photo_library, 'Galerie', widget.onChoisirPhotoObservation, true)),
                ]),
                if (widget.observationPhotos.isNotEmpty)
                  Container(
                    height: context.screenHeight * 0.1,
                    margin: EdgeInsets.only(top: context.spacingM),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.observationPhotos.length,
                      itemBuilder: (ctx, i) => Container(
                        width: context.screenWidth * 0.2,
                        margin: EdgeInsets.only(right: context.spacingS),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(context.spacingS)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(context.spacingS),
                          child: SafeFileImage(path: widget.observationPhotos[i], fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: context.spacingL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onAjouterObservation(
                        _pendingPointVerificationKey,
                        _pendingReferenceNormative,
                        _pendingFamilleRisque,
                        _pendingCriticite,
                      );
                      setState(() {
                        _pendingPointVerificationKey = null;
                        _pendingReferenceNormative = null;
                        _pendingFamilleRisque = null;
                        _pendingCriticite = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: context.spacingM),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                    ),
                    child: Text('Ajouter cette observation', style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),

          SizedBox(height: context.spacingL),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(BuildContext context, String label, bool isSelected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(context.spacingXL),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Text(label, style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildObsExistante(BuildContext context, ObservationLibre obs, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
      padding: EdgeInsets.all(context.spacingM),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.spacingS), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(obs.texte, style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade800)),
                if (obs.hasNormativeReference) ...[
                  SizedBox(height: context.spacingXS),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade200)),
                    child: Text('Réf : ${obs.referenceNormative}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.observationController.text = obs.texte;
                    widget.observationPhotos.clear();
                    widget.observationPhotos.addAll(obs.photos);
                    _pendingPointVerificationKey = obs.pointVerificationKey;
                    _pendingReferenceNormative = obs.referenceNormative;
                    _pendingFamilleRisque = obs.familleRisque;
                    _pendingCriticite = obs.criticite;
                    widget.observationsExistantes.removeAt(index);
                    widget.onAddObservationChanged(true);
                  });
                },
                child: Padding(
                  padding: EdgeInsets.only(right: context.spacingS),
                  child: Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: context.iconSizeS),
                ),
              ),
              GestureDetector(
                onTap: () => widget.onSupprimerObservation(index),
                child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: context.iconSizeS),
              ),
            ],
          ),
        ]),
        if (obs.photos.isNotEmpty) ...[
          SizedBox(height: context.spacingS),
          SizedBox(
            height: context.screenHeight * 0.08,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: obs.photos.length,
              itemBuilder: (ctx, i) => Container(
                width: context.screenWidth * 0.15,
                margin: EdgeInsets.only(right: context.spacingS),
                child: ClipRRect(borderRadius: BorderRadius.circular(context.spacingXS), child: SafeFileImage(path: obs.photos[i], fit: BoxFit.cover)),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildPhotoBtn(BuildContext context, IconData icon, String label, VoidCallback onTap, bool isSecondary) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: context.iconSizeS),
      label: Text(label, style: TextStyle(fontSize: context.fontSizeS)),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSecondary ? Colors.grey.shade700 : AppTheme.primaryBlue,
        side: BorderSide(color: isSecondary ? Colors.grey.shade300 : AppTheme.primaryBlue.withOpacity(0.5)),
        padding: EdgeInsets.symmetric(vertical: context.spacingM),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
      ),
    );
  }
}

// ================================================================
// ÉTAPE 2 : INFORMATIONS GÉNÉRALES (inchangée)
// ================================================================
class _EtapeInformationsGenerales extends StatefulWidget {
  final String? equipmentType;
  final bool? alimenteeParTransformateur;
  final Function(bool?) onAlimenteeParTransformateurChanged;
  final String? transformateurId;
  final String? transformateurNomComplet;
  final Function(String?, String?) onTransformateurChanged;
  final List<MissionTransformateurOption> availableTransformateurs;
  final bool? presenceCPI;
  final Function(bool?) onPresenceCPIChanged;
  final bool zoneAtex;
  final Function(bool?) onZoneAtexChanged;
  final bool identificationArmoire;
  final Function(bool?) onIdentificationArmoireChanged;
  final bool signalisationDanger;
  final Function(bool?) onSignalisationDangerChanged;
  final bool presenceSchema;
  final Function(bool?) onPresenceSchemaChanged;
  final bool presenceParafoudre;
  final Function(bool?) onPresenceParafoudreChanged;
  final bool verificationThermographie;
  final Function(bool?) onVerificationThermographieChanged;
  final String? presenceDefautThermo;
  final Function(String?) onPresenceDefautThermoChanged;
  final String domaineTension;
  final Function(String?) onDomaineTensionChanged;
  final bool domaineTensionValid;
  
  final List<ElementControle> observationsParafoudre;
  final VoidCallback onAddParafoudreObservation;
  final Function(int) onDeleteParafoudreObservation;
  final Future<String?> Function(File, String) onSavePhoto;

  final ParsedIpIk? repereParsedIpIk;
  final TextEditingController? indiceIpIkController;
  final int departuresCount;
  final int terminalCircuitsCount;

  const _EtapeInformationsGenerales({
    this.equipmentType,
    this.repereParsedIpIk,
    required this.alimenteeParTransformateur,
    required this.onAlimenteeParTransformateurChanged,
    this.transformateurId,
    this.transformateurNomComplet,
    required this.onTransformateurChanged,
    this.availableTransformateurs = const [],
    required this.presenceCPI,
    required this.onPresenceCPIChanged,
    required this.zoneAtex,
    required this.onZoneAtexChanged,
    required this.identificationArmoire,
    required this.onIdentificationArmoireChanged,
    required this.signalisationDanger,
    required this.onSignalisationDangerChanged,
    required this.presenceSchema,
    required this.onPresenceSchemaChanged,
    required this.presenceParafoudre,
    required this.onPresenceParafoudreChanged,
    required this.verificationThermographie,
    required this.onVerificationThermographieChanged,
    required this.presenceDefautThermo,
    required this.onPresenceDefautThermoChanged,
    required this.domaineTension,
    required this.onDomaineTensionChanged,
    required this.domaineTensionValid,
    required this.observationsParafoudre,
    required this.onAddParafoudreObservation,
    required this.onDeleteParafoudreObservation,
    required this.onSavePhoto,
    this.indiceIpIkController,
    this.departuresCount = 0,
    this.terminalCircuitsCount = 0,
  });

  @override
  State<_EtapeInformationsGenerales> createState() => _EtapeInformationsGeneralesState();
}

class _EtapeInformationsGeneralesState extends State<_EtapeInformationsGenerales> {
  bool _addParafoudreObservation = false;
  late final TextEditingController _ipDigitsController;
  late final TextEditingController _ikDigitsController;
  bool _isSyncingFromParent = false;
  bool _isSyncingToParent = false;

  @override
  void initState() {
    super.initState();
    final parsed = ParsedIpIk.parse(widget.indiceIpIkController?.text);
    _ipDigitsController = TextEditingController(text: parsed.ipDigits ?? '');
    _ikDigitsController = TextEditingController(text: parsed.ikDigits ?? '');

    _ipDigitsController.addListener(_onDigitsChanged);
    _ikDigitsController.addListener(_onDigitsChanged);

    widget.indiceIpIkController?.addListener(_onParentControllerChanged);
  }

  void _onDigitsChanged() {
    if (_isSyncingFromParent) return;
    _isSyncingToParent = true;
    final formatted = ParsedIpIk.formatFromDigits(
      _ipDigitsController.text,
      _ikDigitsController.text,
    );
    if (widget.indiceIpIkController != null &&
        widget.indiceIpIkController!.text != formatted) {
      widget.indiceIpIkController!.text = formatted;
    }
    _isSyncingToParent = false;
  }

  void _onParentControllerChanged() {
    if (_isSyncingToParent) return;
    final parsed = ParsedIpIk.parse(widget.indiceIpIkController?.text);
    _isSyncingFromParent = true;
    final newIp = parsed.ipDigits ?? '';
    final newIk = parsed.ikDigits ?? '';
    if (_ipDigitsController.text != newIp) {
      _ipDigitsController.text = newIp;
    }
    if (_ikDigitsController.text != newIk) {
      _ikDigitsController.text = newIk;
    }
    _isSyncingFromParent = false;
  }

  @override
  void dispose() {
    widget.indiceIpIkController?.removeListener(_onParentControllerChanged);
    _ipDigitsController.dispose();
    _ikDigitsController.dispose();
    super.dispose();
  }

  void _previsualiserPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SafeFileImage(path: photos[index], fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyCountTile(BuildContext context, {required String label, required int count}) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(context.spacingM),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndiceIpIkRepereTile(BuildContext context) {
    final repere = widget.repereParsedIpIk ?? const ParsedIpIk();
    final hasIndice = repere.hasIpOrIk;
    final ipText = hasIndice ? (repere.ipDigits ?? '') : '';
    final ikText = hasIndice ? (repere.ikDigits ?? '') : '';

    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indice IP/IK du repère',
            style: TextStyle(
              fontSize: context.fontSizeM,
              fontWeight: FontWeight.w500,
              color: AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Champ IP préfixé
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'IP',
                          style: TextStyle(
                            fontSize: context.fontSizeM,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ipText,
                          style: TextStyle(
                            fontSize: context.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Champ IK préfixé
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'IK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ikText,
                          style: TextStyle(
                            fontSize: context.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!hasIndice) ...[
            const SizedBox(height: 6),
            Text(
              "Absence de l'indice dans le repère",
              style: TextStyle(
                fontSize: context.fontSizeS,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndiceIpIkTile(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indice IP / IK',
            style: TextStyle(
              fontSize: context.fontSizeM,
              fontWeight: FontWeight.w500,
              color: AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Champ IP préfixé
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'IP',
                          style: TextStyle(
                            fontSize: context.fontSizeM,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _ipDigitsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            hintText: '55',
                            hintStyle: TextStyle(color: Colors.grey),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                          style: TextStyle(
                            fontSize: context.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Champ IK préfixé
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'IK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _ikDigitsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            hintText: '08',
                            hintStyle: TextStyle(color: Colors.grey),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                          style: TextStyle(
                            fontSize: context.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOuiNonChoiceTile(
    BuildContext context, {
    required String label,
    required bool? value,
    required Function(bool?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fontSizeM,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildChoiceBtn(
                context,
                label: 'Oui',
                isSelected: value == true,
                color: Colors.green,
                onTap: () => onChanged(value == true ? null : true),
              ),
              const SizedBox(width: 6),
              _buildChoiceBtn(
                context,
                label: 'Non',
                isSelected: value == false,
                color: Colors.red,
                onTap: () => onChanged(value == false ? null : false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceBtn(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? (label == 'Oui' ? Icons.check_circle : Icons.cancel)
                  : (label == 'Oui' ? Icons.check_circle_outline : Icons.cancel_outlined),
              size: 16,
              color: isSelected ? color : Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThermoDefectTile(BuildContext context) {
    final currentVal = widget.presenceDefautThermo ?? (widget.verificationThermographie ? 'Sans objet' : null);
    final isHistoricalSansObjet = currentVal == 'Sans objet';
    final isChecked = currentVal == 'Oui';

    return Container(
      margin: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHistoricalSansObjet
            ? Colors.grey.shade100
            : (isChecked ? Colors.green.shade50 : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHistoricalSansObjet
              ? Colors.grey.shade400
              : (isChecked ? Colors.green.shade300 : Colors.grey.shade300),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (currentVal == 'Sans objet') {
            widget.onPresenceDefautThermoChanged('Oui');
          } else if (currentVal == 'Oui') {
            widget.onPresenceDefautThermoChanged('Non');
          } else {
            widget.onPresenceDefautThermoChanged('Oui');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Checkbox(
              value: isHistoricalSansObjet ? null : isChecked,
              tristate: isHistoricalSansObjet,
              onChanged: (bool? val) {
                if (currentVal == 'Sans objet') {
                  widget.onPresenceDefautThermoChanged('Oui');
                } else if (currentVal == 'Oui') {
                  widget.onPresenceDefautThermoChanged('Non');
                } else {
                  widget.onPresenceDefautThermoChanged('Oui');
                }
              },
              activeColor: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Présence de défaut thermo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (isHistoricalSansObjet)
                    Text(
                      '(Non renseigné historiquement - Sans objet)',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    )
                  else
                    Text(
                      isChecked ? 'Défaut thermo présent (Oui)' : 'Aucun défaut thermo (Non)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isChecked ? Colors.green.shade800 : Colors.grey.shade700,
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

  Widget _buildTransformateurSelect(BuildContext context) {
    final available = widget.availableTransformateurs;
    final currentId = widget.transformateurId;
    final currentNom = widget.transformateurNomComplet;

    final hasCurrentInList = currentId != null &&
        currentId.isNotEmpty &&
        available.any((opt) => opt.id == currentId);

    final dropdownItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text(
          'Non renseigné',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      ),
      if (currentId != null && currentId.isNotEmpty && !hasCurrentInList)
        DropdownMenuItem<String?>(
          value: currentId,
          child: Text(
            currentNom != null && currentNom.isNotEmpty
                ? '$currentNom (Historique)'
                : 'Transformateur ($currentId)',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ...available.map((opt) {
        return DropdownMenuItem<String?>(
          value: opt.id,
          child: Text(
            opt.dropdownLabel,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    ];

    final selectedItemWidgets = <Widget>[
      Text(
        'Non renseigné',
        style: TextStyle(
          fontSize: context.fontSizeM,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      if (currentId != null && currentId.isNotEmpty && !hasCurrentInList)
        Text(
          currentNom != null && currentNom.isNotEmpty
              ? currentNom
              : 'Transformateur ($currentId)',
          style: TextStyle(
            fontSize: context.fontSizeM,
            fontWeight: FontWeight.w500,
            color: AppTheme.darkBlue,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ...available.map((opt) {
        return Text(
          opt.transformerName,
          style: TextStyle(
            fontSize: context.fontSizeM,
            fontWeight: FontWeight.w500,
            color: AppTheme.darkBlue,
          ),
          overflow: TextOverflow.ellipsis,
        );
      }),
    ];

    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: context.spacingS,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: AppTheme.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Transformateur d\'alimentation',
                style: TextStyle(
                  fontSize: context.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: (currentId != null && currentId.isNotEmpty) ? currentId : null,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryBlue, size: context.iconSizeM),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(context.spacingS),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
              ),
            ),
            items: dropdownItems,
            selectedItemBuilder: (BuildContext context) => selectedItemWidgets,
            onChanged: (String? selectedId) {
              if (selectedId == null || selectedId.isEmpty) {
                widget.onTransformateurChanged(null, null);
              } else {
                MissionTransformateurOption? match;
                for (final opt in available) {
                  if (opt.id == selectedId) {
                    match = opt;
                    break;
                  }
                }
                final nom = match != null
                    ? match.transformerName
                    : (currentNom ?? selectedId);
                widget.onTransformateurChanged(selectedId, nom);
              }
            },
          ),
          if (available.isEmpty && (currentId == null || currentId.isEmpty)) ...[
            const SizedBox(height: 6),
            Text(
              'Aucun transformateur MT configuré dans la mission pour le moment.',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: [
        _buildModernHeader(context, 'Informations générales', 3, 6),
        SizedBox(height: context.spacingXL),
        
        _buildOuiNonChoiceTile(
          context,
          label: 'Installation alimentée par le transformateur',
          value: widget.alimenteeParTransformateur,
          onChanged: widget.onAlimenteeParTransformateurChanged,
        ),
        if (widget.alimenteeParTransformateur == true)
          _buildTransformateurSelect(context),
        if (widget.equipmentType?.toUpperCase().contains('INVERSEUR') != true)
          _buildOuiNonChoiceTile(
            context,
            label: 'Présence CPI',
            value: widget.presenceCPI,
            onChanged: widget.onPresenceCPIChanged,
          ),

        _buildModernCheckbox(context, 'Zone ATEX', widget.zoneAtex, widget.onZoneAtexChanged),
        _buildModernCheckbox(context, 'Identification de l\'armoire', widget.identificationArmoire, widget.onIdentificationArmoireChanged),
        _buildModernCheckbox(context, 'Signalisation de danger électrique', widget.signalisationDanger, widget.onSignalisationDangerChanged),
        _buildModernCheckbox(context, 'Présence de schéma électrique', widget.presenceSchema, widget.onPresenceSchemaChanged),
        _buildModernCheckbox(context, 'Présence de parafoudre', widget.presenceParafoudre, widget.onPresenceParafoudreChanged),
        _buildModernCheckbox(context, 'Vérification par thermographie infrarouge', widget.verificationThermographie, widget.onVerificationThermographieChanged),
        
        if (widget.verificationThermographie) ...[
          const SizedBox(height: 4),
          _buildThermoDefectTile(context),
        ],

        if (widget.equipmentType?.toUpperCase().contains('INVERSEUR') != true) ...[
          _buildReadOnlyCountTile(context, label: 'Récapitulatif nombre de départ', count: widget.departuresCount),
          _buildReadOnlyCountTile(context, label: 'Récapitulatif nombre de circuit terminaux', count: widget.terminalCircuitsCount),
        ],
        _buildIndiceIpIkRepereTile(context),
        _buildIndiceIpIkTile(context),

        
        SizedBox(height: context.spacingXL),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: !widget.domaineTensionValid ? Colors.red.shade300 : Colors.grey.shade300,
              width: !widget.domaineTensionValid ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: widget.domaineTension.isNotEmpty ? widget.domaineTension : '230/400',
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryBlue, size: context.iconSizeM),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(context.spacingS),
            decoration: const InputDecoration(
              labelText: 'Domaine',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(fontSize: context.fontSizeM, color: AppTheme.darkBlue, fontWeight: FontWeight.w500),
            items: const [
              DropdownMenuItem<String>(value: '230/400', child: Text('230/400')),
              DropdownMenuItem<String>(value: '400/690', child: Text('400/690')),
              DropdownMenuItem<String>(value: 'Autre', child: Text('Autre')),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) widget.onDomaineTensionChanged(newValue);
            },
          ),
        ),
        
        SizedBox(height: context.spacingXL),
        
        _buildParafoudreObservationsSection(context),
        
        SizedBox(height: context.spacingXXL),
      ],
    );
  }

  Widget _buildModernHeader(BuildContext context, String title, int currentStep, int totalSteps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: context.iconSizeXL * 1.2,
              height: context.iconSizeXL * 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(context.spacingS),
                boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: context.spacingS, offset: Offset(0, context.spacingXS))],
              ),
              child: Icon(Icons.info_outline, color: Colors.white, size: context.iconSizeM),
            ),
            SizedBox(width: context.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                  SizedBox(height: context.spacingXS),
                  Text('Étape $currentStep sur $totalSteps', style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingM),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildModernCheckbox(BuildContext context, String label, bool value, Function(bool?) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2))],
      ),
      child: CheckboxListTile(
        title: Text(label, style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingM)),
      ),
    );
  }

  Widget _buildParafoudreObservationsSection(BuildContext context) {
    if (!widget.presenceParafoudre) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.orange, size: context.iconSizeM),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('Observations état du parafoudre', style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue))),
              ],
            ),
          ),
          if (widget.observationsParafoudre.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacingL),
              child: Column(
                children: widget.observationsParafoudre.asMap().entries.map((entry) {
                  final index = entry.key;
                  final element = entry.value;
                  return Container(
                    margin: EdgeInsets.only(bottom: context.spacingL),
                    padding: EdgeInsets.all(context.spacingM),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(context.spacingS),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Observation n°${index + 1}',
                              style: TextStyle(
                                fontSize: context.fontSizeS,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => widget.onDeleteParafoudreObservation(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ObservationEnrichieWidget(
                          element: element,
                          onChanged: () {
                            element.priorite = null; // S'assurer que le parafoudre n'a pas de priorité
                            setState(() {});
                            final parentState = context.findAncestorStateOfType<_AjouterCoffretScreenState>();
                            parentState?._saveDraft();
                          },
                          color: Colors.orange,
                          onSavePhoto: widget.onSavePhoto,
                          showPriority: false,
                          sectionType: 'parafoudre',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onAddParafoudreObservation,
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text('AJOUTER UNE OBSERVATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: EdgeInsets.symmetric(vertical: context.spacingM),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BOUTON UNIFIÉ : ESSAI DE DÉCLENCHEMENT DIFFÉRENTIEL
// ================================================================
Widget buildEssaiDeclenchementButton({
  required BuildContext context,
  required String missionId,
  required String elementId,
  required String equipementId,
  required String zone,
  required String repere,
  required String designation,
  String? circuitName,
  required String precision,
  required String typeDispositif,
  required String calibre,
  required String ddr,
  required VoidCallback onEssaiChanged,
}) {
  final mesures = HiveService.getMesuresEssaisByMissionId(missionId);
  EssaiDeclenchementDifferentiel? existingEssai;
  if (mesures != null) {
    for (final e in mesures.essaisDeclenchement) {
      if (EssaiDeclenchementHelper.isSameBlock(
        essai: e,
        targetElementId: elementId,
        equipementId: equipementId,
        precision: precision,
        circuitName: circuitName,
      )) {
        existingEssai = e;
        break;
      }
    }
  }

  final bool hasEssai = existingEssai != null;

  return Container(
    margin: const EdgeInsets.only(top: 14),
    width: double.infinity,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await EssaiDeclenchementModal.show(
            context,
            missionId: missionId,
            elementId: elementId,
            equipementId: equipementId,
            zone: zone,
            repere: repere,
            designation: designation,
            circuitName: circuitName,
            precision: precision,
            typeDispositif: typeDispositif,
            calibre: calibre,
            ddr: ddr,
            existingEssai: existingEssai,
          );
          onEssaiChanged();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: hasEssai
                ? const Color(0xFFE8F5E9)
                : AppTheme.primaryBlue.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasEssai
                  ? Colors.green.shade600
                  : AppTheme.primaryBlue.withOpacity(0.5),
              width: hasEssai ? 1.6 : 1.2,
            ),
            boxShadow: hasEssai
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hasEssai
                      ? Colors.green.shade100
                      : AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasEssai ? Icons.check_circle : Icons.speed,
                  size: 20,
                  color: hasEssai
                      ? Colors.green.shade700
                      : AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hasEssai
                    ? Text(
                        'Essai réalisé',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.green.shade900,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Essai de déclenchement',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Test différentiel ($ddr mA)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasEssai
                      ? Colors.green.shade700
                      : AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasEssai ? Icons.visibility : Icons.add,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasEssai ? 'Voir' : 'Tester',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ================================================================
// ÉTAPE 3 : ALIMENTATIONS (avec option "Aucun" et unité A)
// ================================================================
class _EtapeAlimentations extends StatefulWidget {
  final String? selectedType;
  final List<Alimentation> alimentations;
  final Alimentation? protectionTete;
  final VoidCallback onDataChanged;
  final List<String> sourcesDisponibles;
  final bool departPrisAvecProtection;
  final ValueChanged<bool>? onDepartPrisAvecProtectionChanged;
  final VoidCallback? onAddSortie;
  final Function(int index)? onDeleteSortie;
  final String missionId;
  final String? currentEquipmentId;
  final String? equipmentNom;
  final String? zoneName;
  final String? repereName;
  final String? sourceNomComplet;
  final String? sourceDepartId;
  final Function(String? equipmentId, String displayName, String? departId)? onSourceSelected;

  const _EtapeAlimentations({
    super.key,
    required this.selectedType,
    required this.alimentations,
    required this.protectionTete,
    required this.departPrisAvecProtection,
    this.onDepartPrisAvecProtectionChanged,
    required this.onDataChanged,
    required this.sourcesDisponibles,
    this.onAddSortie,
    this.onDeleteSortie,
    required this.missionId,
    this.currentEquipmentId,
    this.equipmentNom,
    this.zoneName,
    this.repereName,
    this.sourceNomComplet,
    this.sourceDepartId,
    this.onSourceSelected,
  });

  @override
  State<_EtapeAlimentations> createState() => _EtapeAlimentationsState();
}

class _EtapeAlimentationsState extends State<_EtapeAlimentations> {
  int _currentSubSlide = 0;

  int get currentSubSlide => _currentSubSlide;

  bool nextSubSlide() {
    if (widget.selectedType == 'INVERSEUR' && _currentSubSlide == 0) {
      setState(() {
        _currentSubSlide = 1;
      });
      return true;
    }
    return false;
  }

  bool previousSubSlide() {
    if (widget.selectedType == 'INVERSEUR' && _currentSubSlide == 1) {
      setState(() {
        _currentSubSlide = 0;
      });
      return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant _EtapeAlimentations oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedType != oldWidget.selectedType) {
      _currentSubSlide = 0;
    }
  }

  static const List<String> _typeProtectionOptions = [
    'Disjoncteur',
    'Sectionneur',
    'Interrupteur',
    'Interrupteur sectionneur',
    'Interrupteur différentiel',
    'Disjoncteur différentiel',
    'Sectionneur porte-fusible',
    'Coupe-circuit(porte-fusible)',
  ];

  static const List<String> _marqueDisjoncteurOptions = [
    'ABB',
    'C&S Electric',
    'Chint',
    'Eaton',
    'Fuji Electric',
    'Gewiss',
    'Hager',
    'Hyundai Electric',
    'LS Electric',
    'Legrand',
    'Lovato Electric',
    'Mitsubishi Electric',
    'Noark',
    'Schneider Electric',
    'Schrack Technik',
    'Siemens',
    'Socomec',
    'TOMZN',
    'Terasaki',
    'Inconnu',
  ];

  static const List<String> _courbeOptions = [
    'Courbe-B',
    'Courbe-C',
    'Courbe-D',
    'Courbe-K',
    'Courbe-Z',
    'Courbe-MA',
  ];

  static const List<String> _ddrOptions = [
    '10',
    '30',
    '100',
    '300',
    '500',
  ];

  static const List<String> _sourceOptions = [
    'Inverseur',
    'Armoire',
    'Coffret',
    'TGBT',
  ];

  final List<String> _sectionCableOptions = const [
    '1.5 mm²', '2.5 mm²', '4 mm²', '6 mm²', '10 mm²', '16 mm²',
    '25 mm²', '35 mm²', '50 mm²', '70 mm²', '95 mm²', '120 mm²',
    '150 mm²', '185 mm²', '240 mm²', '300 mm²',
  ];

  static const List<String> _natureCableOptions = [
    'Cuivre',
    'Aluminium',
  ];

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (int i = 0; i < widget.alimentations.length; i++) {
      final a = widget.alimentations[i];
      _controllers['alim${i}_nb_cables'] = TextEditingController(text: a.effectiveNombreCables ?? '');
      _controllers['alim${i}_pdc'] = TextEditingController(text: a.pdcKA);
      _controllers['alim${i}_icc3'] = TextEditingController(text: a.icc3Max ?? '');
      _controllers['alim${i}_calibre'] = TextEditingController(text: a.calibre);
      _controllers['alim${i}_source'] = TextEditingController(text: a.source);
    }
    if (widget.protectionTete != null) {
      _controllers['prot_nb_cables'] = TextEditingController(text: widget.protectionTete!.effectiveNombreCables ?? '');
      _controllers['prot_pdc'] = TextEditingController(text: widget.protectionTete!.pdcKA);
      _controllers['prot_icc3'] = TextEditingController(text: widget.protectionTete!.icc3Max ?? '');
      _controllers['prot_calibre'] = TextEditingController(text: widget.protectionTete!.calibre);
      _controllers['prot_source'] = TextEditingController(text: widget.protectionTete!.source);
    }
  }

  TextEditingController _getController(String key, String initialValue) {
    return _controllers.putIfAbsent(key, () => TextEditingController(text: initialValue));
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _updateAlimentation(Alimentation a, String field, String value, {int index = 0, bool isProtectionTete = false}) {
    setState(() {
      switch (field) {
        case 'typeProtection':
          a.typeProtection = value;
          a.sourceKnown = SourceStatusResolver.resolve(value);
          if (index == 0) {
            final String norm = value.trim().toLowerCase();
            final bool hasProtection = norm.isNotEmpty && norm != '-aucun-' && norm != 'aucun' && norm != '-';
            widget.onDepartPrisAvecProtectionChanged?.call(hasProtection);
          }
          break;
        case 'courbe': a.courbe = value; break;
        case 'ddr': a.ddr = value; break;
        case 'pdcKA':
          a.pdcKA = value;
          final key = isProtectionTete ? 'prot_pdc' : 'alim${index}_pdc';
          if (_controllers.containsKey(key) && _controllers[key]!.text != value) _controllers[key]!.text = value;
          break;
        case 'icc3Max':
          a.icc3Max = value;
          final key = isProtectionTete ? 'prot_icc3' : 'alim${index}_icc3';
          if (_controllers.containsKey(key) && _controllers[key]!.text != value) _controllers[key]!.text = value;
          break;
        case 'calibre':
          a.calibre = value;
          final key = isProtectionTete ? 'prot_calibre' : 'alim${index}_calibre';
          if (_controllers.containsKey(key) && _controllers[key]!.text != value) _controllers[key]!.text = value;
          break;
        case 'nombreCables':
          final trimmed = value.trim();
          a.nombreCables = trimmed.isEmpty ? null : trimmed;
          final parsed = int.tryParse(trimmed);
          if (parsed != null && parsed > 0) {
            a.conducteursPhase = parsed;
          } else if (trimmed.isEmpty) {
            a.conducteursPhase = (a.sectionCable.trim().isNotEmpty && a.sectionCable.trim() != '-') ? 1 : null;
          }
          final key = isProtectionTete ? 'prot_nb_cables' : 'alim${index}_nb_cables';
          if (_controllers.containsKey(key) && _controllers[key]!.text != value) _controllers[key]!.text = value;
          break;
        case 'sectionCable':
        case 'sectionCablePhase':
          a.sectionCable = value;
          if (value.trim().isNotEmpty && value.trim() != '-') {
            a.conducteursPhase ??= 1;
            final key = isProtectionTete ? 'prot_cond_phase' : 'alim${index}_cond_phase';
            if (_controllers.containsKey(key)) _controllers[key]!.text = a.conducteursPhase.toString();
          } else {
            a.conducteursPhase = null;
          }
          break;
        case 'conducteursPhase':
          a.conducteursPhase = int.tryParse(value);
          if (a.conducteursPhase != null && a.conducteursPhase! > 0) {
            a.nombreCables = a.conducteursPhase.toString();
            final keyNb = isProtectionTete ? 'prot_nb_cables' : 'alim${index}_nb_cables';
            if (_controllers.containsKey(keyNb) && _controllers[keyNb]!.text != a.nombreCables) {
              _controllers[keyNb]!.text = a.nombreCables!;
            }
          }
          final keyCondP = isProtectionTete ? 'prot_cond_phase' : 'alim${index}_cond_phase';
          if (_controllers.containsKey(keyCondP) && _controllers[keyCondP]!.text != value) _controllers[keyCondP]!.text = value;
          break;
        case 'sectionCableNeutre':
          a.sectionCableNeutre = value;
          if (value.trim().isNotEmpty && value.trim() != '-') {
            a.conducteursNeutre ??= 1;
            final key = isProtectionTete ? 'prot_cond_neutre' : 'alim${index}_cond_neutre';
            if (_controllers.containsKey(key)) _controllers[key]!.text = a.conducteursNeutre.toString();
          } else {
            a.conducteursNeutre = null;
          }
          break;
        case 'conducteursNeutre':
          a.conducteursNeutre = int.tryParse(value);
          final keyCondN = isProtectionTete ? 'prot_cond_neutre' : 'alim${index}_cond_neutre';
          if (_controllers.containsKey(keyCondN) && _controllers[keyCondN]!.text != value) _controllers[keyCondN]!.text = value;
          break;
        case 'source':
          a.source = value;
          final key = isProtectionTete ? 'prot_source' : 'alim${index}_source';
          if (_controllers.containsKey(key) && _controllers[key]!.text != value) _controllers[key]!.text = value;
          break;
        case 'natureCable':
          a.natureCable = value.trim().isEmpty ? null : value.trim();
          break;
        case 'sourceKnown': a.sourceKnown = value; break;
        case 'marqueDisjoncteur': a.marqueDisjoncteur = value; break;
      }
      widget.onDataChanged();
    });
  }

  void _updateProtectionTete(String field, String value) {
    if (widget.protectionTete != null) {
      setState(() {
        switch (field) {
          case 'typeProtection':
            widget.protectionTete!.typeProtection = value;
            widget.protectionTete!.sourceKnown = SourceStatusResolver.resolve(value);
            final String norm = value.trim().toLowerCase();
            final bool hasProtection = norm.isNotEmpty && norm != '-aucun-' && norm != 'aucun' && norm != '-';
            widget.onDepartPrisAvecProtectionChanged?.call(hasProtection);
            break;
          case 'courbe': widget.protectionTete!.courbe = value; break;
          case 'ddr': widget.protectionTete!.ddr = value; break;
          case 'pdcKA': widget.protectionTete!.pdcKA = value; break;
          case 'icc3Max': widget.protectionTete!.icc3Max = value; break;
          case 'calibre': widget.protectionTete!.calibre = value; break;
          case 'nombreCables':
            final trimmed = value.trim();
            widget.protectionTete!.nombreCables = trimmed.isEmpty ? null : trimmed;
            final parsed = int.tryParse(trimmed);
            if (parsed != null && parsed > 0) {
              widget.protectionTete!.conducteursPhase = parsed;
            } else if (trimmed.isEmpty) {
              widget.protectionTete!.conducteursPhase = (widget.protectionTete!.sectionCable.trim().isNotEmpty && widget.protectionTete!.sectionCable.trim() != '-') ? 1 : null;
            }
            final key = 'prot_nb_cables';
            if (_controllers.containsKey(key) && _controllers[key]!.text != value) _controllers[key]!.text = value;
            break;
          case 'sectionCable':
          case 'sectionCablePhase':
            widget.protectionTete!.sectionCable = value;
            if (value.trim().isNotEmpty && value.trim() != '-') {
              widget.protectionTete!.conducteursPhase ??= 1;
              const key = 'prot_cond_phase';
              if (_controllers.containsKey(key)) _controllers[key]!.text = widget.protectionTete!.conducteursPhase.toString();
            } else {
              widget.protectionTete!.conducteursPhase = null;
            }
            break;
          case 'conducteursPhase':
            widget.protectionTete!.conducteursPhase = int.tryParse(value);
            if (widget.protectionTete!.conducteursPhase != null && widget.protectionTete!.conducteursPhase! > 0) {
              widget.protectionTete!.nombreCables = widget.protectionTete!.conducteursPhase.toString();
              const keyNb = 'prot_nb_cables';
              if (_controllers.containsKey(keyNb) && _controllers[keyNb]!.text != widget.protectionTete!.nombreCables) {
                _controllers[keyNb]!.text = widget.protectionTete!.nombreCables!;
              }
            }
            const keyCondP = 'prot_cond_phase';
            if (_controllers.containsKey(keyCondP) && _controllers[keyCondP]!.text != value) _controllers[keyCondP]!.text = value;
            break;
          case 'sectionCableNeutre':
            widget.protectionTete!.sectionCableNeutre = value;
            if (value.trim().isNotEmpty && value.trim() != '-') {
              widget.protectionTete!.conducteursNeutre ??= 1;
              const key = 'prot_cond_neutre';
              if (_controllers.containsKey(key)) _controllers[key]!.text = widget.protectionTete!.conducteursNeutre.toString();
            } else {
              widget.protectionTete!.conducteursNeutre = null;
            }
            break;
          case 'conducteursNeutre':
            widget.protectionTete!.conducteursNeutre = int.tryParse(value);
            const keyCondN = 'prot_cond_neutre';
            if (_controllers.containsKey(keyCondN) && _controllers[keyCondN]!.text != value) _controllers[keyCondN]!.text = value;
            break;
          case 'natureCable':
            widget.protectionTete!.natureCable = value.trim().isEmpty ? null : value.trim();
            break;
          case 'source': widget.protectionTete!.source = value; break;
          case 'sourceKnown': widget.protectionTete!.sourceKnown = value; break;
          case 'marqueDisjoncteur': widget.protectionTete!.marqueDisjoncteur = value; break;
        }
        widget.onDataChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ValueKey('alim_subslide_${_currentSubSlide}_${widget.selectedType}'),
      padding: EdgeInsets.all(context.spacingL),
      children: [
        _buildModernHeader(context, 'Alimentations', 3, 4),
        SizedBox(height: context.spacingXL),
        
        if (widget.selectedType == 'INVERSEUR') ...[
          if (_currentSubSlide == 0) ...[
            if (widget.alimentations.length >= 2) ...[
              _buildAlimentationCard(context, 'ALIMENTATION 1', widget.alimentations[0], (field, value) => _updateAlimentation(widget.alimentations[0], field, value), index: 0),
              SizedBox(height: context.spacingM),
              _buildAlimentationCard(context, 'ALIMENTATION 2', widget.alimentations[1], (field, value) => _updateAlimentation(widget.alimentations[1], field, value), index: 1),
            ],
          ] else ...[
            ...() {
              final cards = <Widget>[];
              final sortiesCount = widget.alimentations.length - 2;
              for (int i = 2; i < widget.alimentations.length; i++) {
                final sortieNumber = i - 1;
                final cardTitle = sortiesCount > 1 ? 'SORTIE INVERSEUR $sortieNumber' : 'SORTIE INVERSEUR';
                final aliment = widget.alimentations[i];
                cards.add(
                  _buildAlimentationCard(
                    context,
                    cardTitle,
                    aliment,
                    (field, value) => _updateAlimentation(aliment, field, value),
                    index: i,
                    canDelete: i >= 3,
                    onDelete: () => widget.onDeleteSortie?.call(i),
                  ),
                );
                cards.add(SizedBox(height: context.spacingM));
              }
              return cards;
            }(),
            SizedBox(height: context.spacingS),
            Center(
              child: OutlinedButton.icon(
                onPressed: widget.onAddSortie,
                icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                label: const Text(
                  '+ Ajouter une sortie',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: BorderSide(color: Colors.orange.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ] else ...[
          if (widget.alimentations.isNotEmpty)
            _buildAlimentationCard(context, 'ORIGINE DE LA SOURCE', widget.alimentations[0], (field, value) => _updateAlimentation(widget.alimentations[0], field, value), index: 0),
          if (widget.protectionTete != null)
            _buildProtectionTeteCard(context),
        ],
        SizedBox(height: context.spacingXXL),
      ],
    );
  }

  Widget _buildModernHeader(BuildContext context, String title, int currentStep, int totalSteps) {
    final String stepSubtitle = widget.selectedType == 'INVERSEUR'
        ? (_currentSubSlide == 0 ? 'Alimentations · 1/2' : 'Sorties inverseur · 2/2')
        : 'Étape $currentStep sur $totalSteps';

    final String displayTitle = widget.selectedType == 'INVERSEUR'
        ? 'Alimentations & Sorties Inverseur'
        : title;

    final double progressValue = widget.selectedType == 'INVERSEUR'
        ? ((currentStep - 1) + (_currentSubSlide + 1) / 2.0) / totalSteps
        : currentStep / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: context.iconSizeXL * 1.2,
              height: context.iconSizeXL * 1.2,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade300]),
                borderRadius: BorderRadius.circular(context.spacingS),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: context.spacingS, offset: Offset(0, context.spacingXS))],
              ),
              child: Icon(Icons.power, color: Colors.white, size: context.iconSizeM),
            ),
            SizedBox(width: context.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(displayTitle, style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                  SizedBox(height: context.spacingXS),
                  Text(stepSubtitle, style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingM),
        LinearProgressIndicator(
          value: progressValue,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildAlimentationCard(
    BuildContext context,
    String title,
    Alimentation a,
    Function(String field, String value) onChanged, {
    bool isProtectionTete = false,
    bool isDepartPrisAvecProtection = true,
    int index = 0,
    bool canDelete = false,
    VoidCallback? onDelete,
  }) {
    final bool effectiveIsDepartPrisAvecProtection = (widget.selectedType == 'INVERSEUR' && index < 2)
        ? true
        : isDepartPrisAvecProtectionFromType(a.typeProtection);

    final nbCablesCtrl = _getController(isProtectionTete ? 'prot_nb_cables' : 'alim${index}_nb_cables', a.effectiveNombreCables ?? '');
    final sourceCtrl = _getController(isProtectionTete ? 'prot_source' : 'alim${index}_source', a.source);
    final pdcCtrl = _getController(isProtectionTete ? 'prot_pdc' : 'alim${index}_pdc', a.pdcKA);
    final icc3Ctrl = _getController(isProtectionTete ? 'prot_icc3' : 'alim${index}_icc3', a.icc3Max ?? '');
    final calibreCtrl = _getController(isProtectionTete ? 'prot_calibre' : 'alim${index}_calibre', a.calibre);

    final typeProtVal = a.typeProtection;
    final typeProtectionItems = [..._typeProtectionOptions];
    if (typeProtVal.isNotEmpty && !typeProtectionItems.contains(typeProtVal)) {
      typeProtectionItems.insert(0, typeProtVal);
    }

    final courbeVal = a.courbe ?? '';
    final courbeItems = [..._courbeOptions];
    if (courbeVal.isNotEmpty && !courbeItems.contains(courbeVal)) {
      courbeItems.insert(0, courbeVal);
    }

    final ddrVal = a.ddr ?? '';
    final ddrItems = [..._ddrOptions];
    if (ddrVal.isNotEmpty && !ddrItems.contains(ddrVal)) {
      ddrItems.insert(0, ddrVal);
    }

    final marqueDisjVal = a.marqueDisjoncteur ?? '';
    final marqueDisjoncteurItems = [..._marqueDisjoncteurOptions];
    if (marqueDisjVal.isNotEmpty && !marqueDisjoncteurItems.contains(marqueDisjVal)) {
      marqueDisjoncteurItems.insert(0, marqueDisjVal);
    }

    final bool isLocked = (!isProtectionTete && index == 0 && widget.sourceDepartId != null && widget.sourceDepartId!.isNotEmpty);

    return Container(
      padding: isProtectionTete ? EdgeInsets.zero : EdgeInsets.all(context.spacingM),
      decoration: isProtectionTete
          ? null
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.spacingM),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty || (canDelete && onDelete != null)) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(context.spacingS)),
                    child: Text(title, style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                  ),
                if (canDelete && onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20),
                    tooltip: 'Supprimer cette sortie',
                    onPressed: onDelete,
                  ),
              ],
            ),
            SizedBox(height: context.spacingM),
          ],
          if (!isProtectionTete && index == 0 && widget.selectedType != 'INVERSEUR') ...[
            _buildDepartPrisSansProtectionControl(context, effectiveIsDepartPrisAvecProtection, (field, val) => onChanged(field, val)),
            SizedBox(height: context.spacingS),
          ],
          if (isLocked) ...[
            Container(
              margin: EdgeInsets.only(bottom: context.spacingS),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Caractéristiques électriques verrouillées (alimentées par le départ sélectionné)',
                      style: TextStyle(
                        fontSize: context.fontSizeXS,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.selectedType == 'INVERSEUR') ...[
            _buildModernTextField(
              context,
              label: 'Origine de la source',
              controller: sourceCtrl,
              onChanged: (v) => onChanged('source', v),
            ),
            SizedBox(height: context.spacingS),
          ] else if (widget.selectedType != 'INVERSEUR' && !isProtectionTete && index == 0) ...[
            _EquipmentSourceAutocompleteField(
              label: 'Origine de la source',
              initialText: a.source.isNotEmpty ? a.source : (widget.sourceNomComplet ?? ''),
              missionId: widget.missionId,
              currentEquipmentId: widget.currentEquipmentId,
              onSelected: (result) {
                void clearElectricalFields() {
                  onChanged('nombreCables', '');
                  onChanged('typeProtection', '');
                  onChanged('marqueDisjoncteur', '');
                  onChanged('courbe', '');
                  onChanged('pdcKA', '');
                  onChanged('icc3Max', '');
                  onChanged('calibre', '');
                  onChanged('ddr', '');
                  onChanged('sectionCable', '');
                  onChanged('sectionCableNeutre', '');
                  onChanged('natureCable', '');
                }

                if (result != null) {
                  onChanged('source', result.displayName);
                  if (result.isDepart && result.depart != null) {
                    final dep = result.depart!;
                    onChanged('nombreCables', dep.effectiveNombreCables ?? '');
                    onChanged('typeProtection', dep.typeProtection);
                    onChanged('marqueDisjoncteur', dep.marque);
                    onChanged('courbe', dep.courbe);
                    onChanged('pdcKA', dep.pdcKA);
                    onChanged('icc3Max', dep.icc3Max);
                    onChanged('calibre', dep.calibre);
                    onChanged('ddr', dep.ddr);
                    onChanged('sectionCable', dep.sectionCable);
                    onChanged('sectionCableNeutre', dep.effectiveSectionCableNeutre);
                    onChanged('natureCable', dep.natureCable ?? '');

                    widget.onSourceSelected?.call(result.equipmentId, result.displayName, dep.id);
                  } else {
                    clearElectricalFields();
                    widget.onSourceSelected?.call(result.equipmentId, result.displayName, null);
                  }
                } else {
                  onChanged('source', '');
                  clearElectricalFields();
                  widget.onSourceSelected?.call(null, '', null);
                }
              },
              onTextChanged: (text) {
                final trimmed = text.trim();
                if (trimmed != a.source) {
                  onChanged('source', trimmed);
                  if (widget.sourceDepartId != null && widget.sourceDepartId!.isNotEmpty) {
                    onChanged('nombreCables', '');
                    onChanged('typeProtection', '');
                    onChanged('marqueDisjoncteur', '');
                    onChanged('courbe', '');
                    onChanged('pdcKA', '');
                    onChanged('icc3Max', '');
                    onChanged('calibre', '');
                    onChanged('ddr', '');
                    onChanged('sectionCable', '');
                    onChanged('sectionCableNeutre', '');
                  }
                  widget.onSourceSelected?.call(null, trimmed, null);
                }
              },
            ),
            SizedBox(height: context.spacingS),
          ],
          if (isProtectionTete || widget.selectedType != 'INVERSEUR' || (widget.selectedType == 'INVERSEUR' && index >= 2)) ...[
            _buildModernDropdown(
              context,
              label: 'Type de protection',
              value: typeProtVal,
              items: typeProtectionItems,
              onChanged: (v) {
                onChanged('typeProtection', v);
              },
              readOnly: isLocked,
            ),
            SizedBox(height: context.spacingS),

            if (effectiveIsDepartPrisAvecProtection) ...[
              _buildModernDropdown(context, label: 'Marque de disjoncteur', value: marqueDisjVal, items: marqueDisjoncteurItems, onChanged: (v) => onChanged('marqueDisjoncteur', v), readOnly: isLocked),
              SizedBox(height: context.spacingS),
              _buildModernDropdown(context, label: 'Courbe', value: courbeVal, items: courbeItems, onChanged: (v) => onChanged('courbe', v), readOnly: isLocked),
              SizedBox(height: context.spacingS),

              _buildModernTextFieldWithSuffix(
                context,
                label: 'PDC',
                suffix: 'kA',
                controller: pdcCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))],
                onChanged: (v) => onChanged('pdcKA', v),
                readOnly: isLocked,
              ),
              SizedBox(height: context.spacingS),
              _buildModernTextFieldWithSuffix(
                context,
                label: 'Icc3 max',
                suffix: 'kA',
                controller: icc3Ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))],
                onChanged: (v) => onChanged('icc3Max', v),
                readOnly: isLocked,
              ),
              SizedBox(height: context.spacingS),
              _buildModernTextFieldWithSuffix(context, label: 'Calibre', suffix: 'A', controller: calibreCtrl, onChanged: (v) => onChanged('calibre', v), readOnly: isLocked),
              SizedBox(height: context.spacingS),
              Builder(
                builder: (context) {
                  final bool isDdrAllowed = EssaiDeclenchementHelper.isDdrApplicable(a.typeProtection);
                  return _buildModernDropdown(
                    context,
                    label: isDdrAllowed ? 'DDR IΔn (mA)' : 'DDR IΔn (mA) — Non applicable',
                    value: ddrVal,
                    items: ddrItems,
                    onChanged: (v) => onChanged('ddr', v),
                    readOnly: isLocked,
                    disabled: !isDdrAllowed,
                    disabledHint: 'Non applicable (Non différentiel)',
                  );
                },
              ),
              SizedBox(height: context.spacingS),
            ],
          ],
          _buildModernDropdown(context, label: 'Section de câble phase', value: a.sectionCable, items: _sectionCableOptions, onChanged: (v) => onChanged('sectionCable', v), readOnly: isLocked),
          if (a.sectionCable.trim().isNotEmpty && a.sectionCable.trim() != '-') ...[
            SizedBox(height: context.spacingS),
            _buildModernTextField(
              context,
              label: 'Nombre de conducteurs phase',
              controller: _getController(isProtectionTete ? 'prot_cond_phase' : 'alim${index}_cond_phase', (a.conducteursPhase ?? 1).toString()),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => onChanged('conducteursPhase', v),
              readOnly: isLocked,
            ),
          ],
          SizedBox(height: context.spacingS),
          _buildModernDropdown(context, label: 'Section de câble neutre', value: a.effectiveSectionCableNeutre, items: _sectionCableOptions, onChanged: (v) => onChanged('sectionCableNeutre', v), readOnly: isLocked),
          if (a.effectiveSectionCableNeutre.trim().isNotEmpty && a.effectiveSectionCableNeutre.trim() != '-') ...[
            SizedBox(height: context.spacingS),
            _buildModernTextField(
              context,
              label: 'Nombre de conducteurs neutre',
              controller: _getController(isProtectionTete ? 'prot_cond_neutre' : 'alim${index}_cond_neutre', (a.conducteursNeutre ?? 1).toString()),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => onChanged('conducteursNeutre', v),
              readOnly: isLocked,
            ),
          ],
          SizedBox(height: context.spacingS),
          _buildModernDropdown(
            context,
            label: 'Nature du câble',
            value: a.natureCable ?? '',
            items: _natureCableOptions,
            onChanged: (v) => onChanged('natureCable', v),
            readOnly: isLocked,
          ),
          SizedBox(height: context.spacingS),
          _buildModernTextField(
            context,
            label: 'Nombre de câble',
            controller: nbCablesCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => onChanged('nombreCables', v),
            readOnly: isLocked,
          ),
          ...() {
            final bool isSortieInverseur = widget.selectedType == 'INVERSEUR' && index >= 2;
            final bool isProtTeteEligible = widget.selectedType != 'INVERSEUR' && isProtectionTete;
            if ((isSortieInverseur || isProtTeteEligible) &&
                EssaiDeclenchementHelper.isEligibleForEssai(typeProtection: a.typeProtection, ddr: a.ddr)) {
              final precision = isSortieInverseur
                  ? EssaiDeclenchementHelper.precisionSortieInverseur
                  : EssaiDeclenchementHelper.precisionProtectionTete;
              final elementId = isSortieInverseur
                  ? '${widget.currentEquipmentId}_sortie_${a.alimentationId}'
                  : '${widget.currentEquipmentId}_prot_tete';
              final circuitName = isSortieInverseur
                  ? (a.source.trim().isNotEmpty ? a.source.trim() : 'Sortie inverseur ${index - 1}')
                  : 'Protection de tête';
              return [
                SizedBox(height: context.spacingM),
                buildEssaiDeclenchementButton(
                  context: context,
                  missionId: widget.missionId,
                  elementId: elementId,
                  equipementId: widget.currentEquipmentId ?? '',
                  zone: widget.zoneName ?? '',
                  repere: widget.repereName ?? '',
                  designation: widget.equipmentNom ?? 'Équipement',
                  circuitName: circuitName,
                  precision: precision,
                  typeDispositif: a.typeProtection,
                  calibre: a.calibre,
                  ddr: a.ddr ?? '',
                  onEssaiChanged: () => setState(() {}),
                ),
              ];
            }
            return <Widget>[];
          }(),
        ],
      ),
    );
  }

  Widget _buildDepartPrisSansProtectionControl(
    BuildContext context,
    bool isDepartPrisAvecProtection,
    Function(String field, String value) onChanged,
  ) {
    final bool isDepartPrisSansProtection = !isDepartPrisAvecProtection;

    return Container(
      decoration: BoxDecoration(
        color: isDepartPrisSansProtection
            ? Colors.red.shade50
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(
          color: isDepartPrisSansProtection
              ? Colors.red.shade200
              : Colors.green.shade200,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Départ pris sans protection',
              style: TextStyle(
                fontSize: context.fontSizeS,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDepartPrisSansProtection
                    ? Colors.red.shade300
                    : Colors.green.shade300,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton OUI (Rouge)
                GestureDetector(
                  onTap: () {
                    if (!isDepartPrisSansProtection) {
                      onChanged('typeProtection', '-Aucun-');
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDepartPrisSansProtection
                          ? Colors.red.shade600
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Oui',
                      style: TextStyle(
                        fontSize: context.fontSizeS,
                        fontWeight: FontWeight.bold,
                        color: isDepartPrisSansProtection
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                // Bouton NON (Vert)
                GestureDetector(
                  onTap: () {
                    if (isDepartPrisSansProtection) {
                      onChanged('typeProtection', 'Disjoncteur');
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: !isDepartPrisSansProtection
                          ? Colors.green.shade600
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Non',
                      style: TextStyle(
                        fontSize: context.fontSizeS,
                        fontWeight: FontWeight.bold,
                        color: !isDepartPrisSansProtection
                            ? Colors.white
                            : Colors.grey.shade700,
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

  Widget _buildProtectionTeteCard(BuildContext context) {
    final String? protType = widget.protectionTete?.typeProtection;
    final bool effectiveIsDepartPrisAvecProtection = widget.selectedType == 'INVERSEUR'
        ? true
        : isDepartPrisAvecProtectionFromType(protType);
    final bool isPresent = effectiveIsDepartPrisAvecProtection;

    return Container(
      padding: EdgeInsets.all(context.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacingS,
                  vertical: context.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(context.spacingS),
                ),
                child: Text(
                  'PROTECTION DE TÊTE',
                  style: TextStyle(
                    fontSize: context.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Text(
                  isPresent ? 'Présent' : 'Absent',
                  style: TextStyle(
                    fontSize: context.fontSizeXS,
                    fontWeight: FontWeight.bold,
                    color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (widget.protectionTete != null) ...[
            SizedBox(height: context.spacingM),
            _buildAlimentationCard(
              context,
              '',
              widget.protectionTete!,
              (field, value) => _updateProtectionTete(field, value),
              isProtectionTete: true,
              isDepartPrisAvecProtection: effectiveIsDepartPrisAvecProtection,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(color: readOnly ? Colors.amber.shade50.withOpacity(0.5) : Colors.grey.shade50, borderRadius: BorderRadius.circular(context.spacingS), border: Border.all(color: readOnly ? Colors.amber.shade300 : Colors.grey.shade300)),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(fontSize: context.fontSizeS, color: readOnly ? Colors.amber.shade900 : null, fontWeight: readOnly ? FontWeight.bold : FontWeight.normal),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: context.fontSizeS, color: readOnly ? Colors.amber.shade900 : Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
        ),
      ),
    );
  }

  Widget _buildModernTextFieldWithSuffix(
    BuildContext context, {
    required String label,
    required String suffix,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(color: readOnly ? Colors.amber.shade50.withOpacity(0.5) : Colors.grey.shade50, borderRadius: BorderRadius.circular(context.spacingS), border: Border.all(color: readOnly ? Colors.amber.shade300 : Colors.grey.shade300)),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        enabled: !readOnly,
        style: TextStyle(fontSize: context.fontSizeS, color: readOnly ? Colors.amber.shade900 : Colors.black87, fontWeight: readOnly ? FontWeight.bold : FontWeight.normal),
        keyboardType: keyboardType ?? const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: context.fontSizeS, color: readOnly ? Colors.amber.shade900 : Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
          suffixIcon: readOnly ? Icon(Icons.lock_outline, size: 16, color: Colors.amber.shade900) : null,
          suffixText: suffix,
          suffixStyle: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: readOnly ? Colors.amber.shade900 : Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildReadOnlySourceField(BuildContext context, {required String label, required String value}) {
    final isKnown = value == 'Connue';
    final color = isKnown ? Colors.teal.shade800 : Colors.orange.shade800;
    final bg = isKnown ? Colors.teal.shade50 : Colors.orange.shade50;
    final border = isKnown ? Colors.teal.shade200 : Colors.orange.shade200;
    final icon = isKnown ? Icons.check_circle_outline : Icons.help_outline;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fontSizeXS,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: context.fontSizeS,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: border),
            ),
            child: Text(
              isKnown ? 'Déduit du type de protection' : 'Déduit (Aucune protection)',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    bool readOnly = false,
    bool disabled = false,
    String? disabledHint,
  }) {
    final bool isEffectivelyDisabled = readOnly || disabled;
    final Color bgColor = disabled
        ? Colors.grey.shade100
        : (readOnly ? Colors.amber.shade50.withOpacity(0.5) : Colors.grey.shade50);
    final Color borderColor = disabled
        ? Colors.grey.shade300
        : (readOnly ? Colors.amber.shade300 : Colors.grey.shade300);
    final Color labelColor = disabled
        ? Colors.grey.shade400
        : (readOnly ? Colors.amber.shade900 : Colors.grey.shade600);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonFormField<String>(
        value: value.isNotEmpty ? value : null,
        isExpanded: true,
        icon: Icon(
          disabled
              ? Icons.block
              : (readOnly ? Icons.lock_outline : Icons.arrow_drop_down),
          size: isEffectivelyDisabled ? 16 : 24,
          color: labelColor,
        ),
        hint: Text(
          disabled ? (disabledHint ?? 'Non applicable') : 'Sélectionnez...',
          style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade400),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: context.fontSizeS, color: labelColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
        ),
        items: [
          DropdownMenuItem<String>(
            value: '',
            child: Text('— Aucun —', style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
          ),
          ...items.map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: context.fontSizeS,
                  color: disabled ? Colors.grey.shade600 : (readOnly ? Colors.amber.shade900 : null),
                  fontWeight: readOnly ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
        onChanged: isEffectivelyDisabled ? null : (v) => onChanged(v ?? ''),
      ),
    );
  }

  String _getLocalisationForIsolement() {
    final state = context.findAncestorStateOfType<_AjouterCoffretScreenState>();
    if (state != null) {
      final parentType = state.widget.parentType;
      final isMoyenneTension = state.widget.isMoyenneTension;
      final isInZone = state.widget.isInZone;
      final zoneIndex = state.widget.zoneIndex;
      final parentIndex = state.widget.parentIndex;
      final missionId = state.widget.mission.id;

      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      if (audit != null) {
        String loc = '';
        if (parentType == 'local') {
          if (isMoyenneTension) {
            if (isInZone && zoneIndex != null && zoneIndex < audit.moyenneTensionZones.length) {
              final zone = audit.moyenneTensionZones[zoneIndex];
              if (parentIndex < zone.locaux.length) loc = zone.locaux[parentIndex].nom;
            } else if (parentIndex < audit.moyenneTensionLocaux.length) {
              loc = audit.moyenneTensionLocaux[parentIndex].nom;
            }
          } else if (zoneIndex != null && zoneIndex < audit.basseTensionZones.length) {
            final zone = audit.basseTensionZones[zoneIndex];
            if (parentIndex < zone.locaux.length) loc = zone.locaux[parentIndex].nom;
          }
        } else {
          if (isMoyenneTension && parentIndex < audit.moyenneTensionZones.length) {
            loc = audit.moyenneTensionZones[parentIndex].nom;
          } else if (!isMoyenneTension && parentIndex < audit.basseTensionZones.length) {
            loc = audit.basseTensionZones[parentIndex].nom;
          }
        }
        if (loc.isNotEmpty) return loc;
      }
    }
    return 'Localisation non définie';
  }


}

// ================================================================
// ÉTAPE 4 : POINTS DE VÉRIFICATION (avec photos)
// ================================================================
class _EtapePointsVerification extends StatefulWidget {
  final String missionId;
  final bool isEdition;
  final List<PointVerification> pointsVerification;
  final Map<int, List<String>> pointSuggestions;
  final Map<int, bool> pointLoading;
  final Map<int, bool> hasObservation;
  final Function(int, String) onObservationChanged;
  final Function(int, String, PointVerification) onUseSuggestion;
  final Function(int, bool) onObservationToggleChanged;
  final Future<String?> Function(File, String) onSavePhoto;
  final String? indiceIpIk;

  const _EtapePointsVerification({
    super.key,
    required this.missionId,
    required this.isEdition,
    required this.pointsVerification,
    required this.pointSuggestions,
    required this.pointLoading,
    required this.hasObservation,
    required this.onObservationChanged,
    required this.onUseSuggestion,
    required this.onObservationToggleChanged,
    required this.onSavePhoto,
    this.indiceIpIk,
  });

  @override
  State<_EtapePointsVerification> createState() => _EtapePointsVerificationState();
}

class _EtapePointsVerificationState extends State<_EtapePointsVerification> {
  final PageController _slideController = PageController();
  int _currentSlide = 0;
  
  late List<List<PointVerification>> _pointsSlides;
  final Map<int, bool> _showReferenceNormative = {};

  @override
  void initState() {
    super.initState();
    _buildSlides();
    for (int i = 0; i < widget.pointsVerification.length; i++) {
      final pv = widget.pointsVerification[i];
      pv.observations ??= [];
      if (pv.observations!.isEmpty && pv.observation != null && pv.observation!.isNotEmpty) {
        pv.observations!.add(ElementControle(
          elementControle: pv.pointVerification,
          conforme: false,
          priorite: pv.priorite,
          observation: pv.observation,
          photos: List.from(pv.photos),
        ));
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncIpIkPoints();
    });
  }

  @override
  void didUpdateWidget(covariant _EtapePointsVerification oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indiceIpIk != widget.indiceIpIk) {
      _syncIpIkPoints();
    }
  }

  void _syncIpIkPoints() {
    final parentState = context.findAncestorStateOfType<_AjouterCoffretScreenState>();
    final tempCoffret = CoffretArmoire(
      qrCode: parentState?._qrCodeController.text ?? '',
      nom: parentState?._nomController.text ?? '',
      type: parentState?._selectedType ?? 'COFFRET',
      indiceIpIk: parentState?._indiceIpIkController.text.trim(),
      repere: parentState?._repereController.text.trim(),
      pointsVerification: widget.pointsVerification,
    );
    IpIkEvaluatorService.syncIpIkPoint(
      coffret: tempCoffret,
      missionId: widget.missionId,
      parentName: parentState?._getParentLocationName(),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _buildSlides() {
    _pointsSlides = [];
    for (int i = 0; i < widget.pointsVerification.length; i += 3) {
      final end = (i + 3).clamp(0, widget.pointsVerification.length);
      _pointsSlides.add(widget.pointsVerification.sublist(i, end));
    }
  }

  int get _totalSlides => _pointsSlides.length;
  bool get _isLastSlide => _currentSlide == _totalSlides - 1;

  bool _isCurrentSlideValid() {
    if (widget.isEdition) return true;
    if (_pointsSlides.isEmpty) return true;
    final currentPoints = _pointsSlides[_currentSlide];
    for (var point in currentPoints) {
      if (point.conformite.trim().isEmpty) return false;
      if (point.conformite == 'non' || point.conformite == 'na') {
        point.priorite ??= 3;
        if (point.conformite == 'non') {
          final pointIndex = _getPointIndex(point);
          if (IpIkEvaluatorService.isIpIkPoint(point.pointVerification)) {
            // Pour le point IP/IK automatique, l'observation est générée dynamiquement
            if (point.observation == null || point.observation!.trim().isEmpty) return false;
          } else {
            final hasObservation = widget.hasObservation[pointIndex] ?? false;
            if (!hasObservation) return false;
            if (point.observation == null || point.observation!.trim().isEmpty) return false;
          }
        }
      }
    }
    return true;
  }

  int _getPointIndex(PointVerification point) => widget.pointsVerification.indexOf(point);

  void nextSlide() {
    if (!widget.isEdition && !_isCurrentSlideValid()) {
      for (var point in _pointsSlides[_currentSlide]) {
        if (point.conformite.trim().isEmpty) {
          _showError('Veuillez renseigner la conformité pour tous les points du slide avant de continuer');
          return;
        }
        if (point.conformite == 'non') {
          final pointIndex = _getPointIndex(point);
          if (IpIkEvaluatorService.isIpIkPoint(point.pointVerification)) {
            if (point.observation == null || point.observation!.trim().isEmpty) {
              _showError('Veuillez renseigner l\'indice IP/IK ou vérifier le classement du repère');
              return;
            }
          } else {
            final hasObservation = widget.hasObservation[pointIndex] ?? false;
            if (!hasObservation) {
              _showError('L\'observation est obligatoire quand la conformité est "Non"');
              return;
            }
            if (point.observation == null || point.observation!.trim().isEmpty) {
              _showError('Veuillez saisir une observation pour le point non conforme');
              return;
            }
          }
        }
      }
      return;
    }
    if (!_isLastSlide) {
      _slideController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousSlide() {
    if (_currentSlide > 0) {
      _slideController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  bool canGoNext() {
    if (!widget.isEdition && !_isCurrentSlideValid()) return false;
    return _isLastSlide;
  }

  void _ajouterAutrePoint() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajouter un point de vérification'),
        content: TextFormField(controller: controller, autofocus: true, maxLines: 3, decoration: const InputDecoration(hintText: 'Saisissez le libellé du point à ajouter...', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () { final texte = controller.text.trim(); if (texte.isNotEmpty) Navigator.pop(context, texte); }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue), child: const Text('Ajouter')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final newPoint = PointVerification(pointVerification: result, conformite: '', observation: null, referenceNormative: null, priorite: null);
      setState(() {
        widget.pointsVerification.add(newPoint);
      });
      _buildSlides();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_slideController.hasClients) {
          _slideController.animateToPage(_totalSlides - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          setState(() => _currentSlide = _totalSlides - 1);
        }
      });
      final parentState = context.findAncestorStateOfType<_AjouterCoffretScreenState>();
      parentState?._saveDraft();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_totalSlides == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: context.iconSizeXL * 1.5, color: Colors.green),
            SizedBox(height: context.spacingM),
            Text('Aucun point à vérifier', style: TextStyle(fontSize: context.fontSizeL, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(context.spacingL),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.spacingS, offset: const Offset(0, 2))]),
          child: Row(
            children: [
              Container(
                width: context.iconSizeXL, height: context.iconSizeXL,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade400]), borderRadius: BorderRadius.circular(context.spacingS)),
                child: Icon(Icons.checklist, color: Colors.white, size: context.iconSizeM),
              ),
              SizedBox(width: context.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Points de vérification', style: TextStyle(fontSize: context.fontSizeXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                    Text('${widget.pointsVerification.length} points - Slide ${_currentSlide + 1}/$_totalSlides', style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingS),
          child: LinearProgressIndicator(value: (_currentSlide + 1) / _totalSlides, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(Colors.green), minHeight: 3, borderRadius: BorderRadius.circular(2)),
        ),
        Expanded(
          child: PageView.builder(
            controller: _slideController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentSlide = index),
            itemCount: _totalSlides,
            itemBuilder: (context, slideIndex) {
              final slidePoints = _pointsSlides[slideIndex];
              final startIndex = slideIndex * 3;
              final isLastSlide = slideIndex == _totalSlides - 1;
              return ListView(
                padding: EdgeInsets.all(context.spacingL),
                children: [
                  ...slidePoints.asMap().entries.map((entry) {
                    final pointIndex = startIndex + entry.key;
                    return _buildModernPointCard(context, entry.value, pointIndex);
                  }),
                  if (isLastSlide) ...[
                    SizedBox(height: context.spacingM),
                    Container(
                      padding: EdgeInsets.all(context.spacingM),
                      child: OutlinedButton.icon(
                        onPressed: _ajouterAutrePoint,
                        icon: Icon(Icons.add_circle_outline, size: context.iconSizeM, color: AppTheme.primaryBlue),
                        label: Text('AUTRE', style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: context.spacingM), side: BorderSide(color: AppTheme.primaryBlue, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS))),
                      ),
                    ),
                    SizedBox(height: context.spacingL),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _addObservationToPoint(PointVerification point) {
    final pointIndex = _getPointIndex(point);
    setState(() {
      point.observations ??= [];
      point.observations!.add(ElementControle(
        elementControle: point.pointVerification,
        conforme: false,
        priorite: point.conformite == 'non' ? 3 : null,
        observation: '',
      ));
      if (pointIndex >= 0) {
        widget.hasObservation[pointIndex] = true;
      }
    });
    _syncPointObservations(point);
  }

  void _deleteObservationFromPoint(PointVerification point, int obsIndex) {
    final pointIndex = _getPointIndex(point);
    setState(() {
      point.observations?.removeAt(obsIndex);
      if (point.observations == null || point.observations!.isEmpty) {
        if (pointIndex >= 0) {
          widget.hasObservation[pointIndex] = false;
        }
      }
    });
    _syncPointObservations(point);
  }

  void _syncPointObservations(PointVerification point) {
    if (point.observations != null && point.observations!.isNotEmpty) {
      point.observation = point.observations!.first.observation;
      point.priorite = point.observations!.first.priorite;
      point.photos = List.from(point.observations!.first.photos);
    } else {
      point.observation = null;
      point.priorite = null;
      point.photos = [];
    }
    final parentState = context.findAncestorStateOfType<_AjouterCoffretScreenState>();
    if (parentState != null) {
      parentState._hasUnsavedChanges = true;
      parentState._scheduleAutoSave();
    }
  }

  Widget _buildModernPointCard(BuildContext context, PointVerification point, int pointIndex) {
    final hasObservation = widget.hasObservation[pointIndex] ?? false;
    final showReference = _showReferenceNormative[pointIndex] ?? false;
    
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingL),
      padding: EdgeInsets.all(context.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: context.iconSizeL, height: context.iconSizeL, decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.spacingS)),
              child: Center(child: Text('${pointIndex + 1}', style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.bold, color: Colors.green.shade700)))),
              SizedBox(width: context.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(point.pointVerification, style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: AppTheme.darkBlue, height: 1.3)),
                    if (point.pointVerification.contains('IP/IK')) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (widget.indiceIpIk != null && widget.indiceIpIk!.trim().isNotEmpty)
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (widget.indiceIpIk != null && widget.indiceIpIk!.trim().isNotEmpty)
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (widget.indiceIpIk != null && widget.indiceIpIk!.trim().isNotEmpty)
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              size: 14,
                              color: (widget.indiceIpIk != null && widget.indiceIpIk!.trim().isNotEmpty)
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (widget.indiceIpIk != null && widget.indiceIpIk!.trim().isNotEmpty)
                                  ? 'Indice IP/IK renseigné : ${widget.indiceIpIk}'
                                  : 'Indice IP/IK non renseigné au Slide 3',
                              style: TextStyle(
                                fontSize: context.fontSizeS,
                                fontWeight: FontWeight.w600,
                                color: (widget.indiceIpIk != null && widget.indiceIpIk!.trim().isNotEmpty)
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacingM),
          _buildConformiteToggle(context, point, pointIndex),
          SizedBox(height: context.spacingS),
          _buildReferenceNormativeToggle(context, point, pointIndex, showReference),
          SizedBox(height: context.spacingM),
          _buildObservationToggle(context, pointIndex, hasObservation),
          if (hasObservation) ...[
            SizedBox(height: context.spacingS),
            Column(
              children: [
                if (point.observations != null)
                  ...point.observations!.asMap().entries.map((entry) {
                    final obsIndex = entry.key;
                    final element = entry.value;
                    return Container(
                      margin: EdgeInsets.only(bottom: context.spacingM),
                      padding: EdgeInsets.all(context.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(context.spacingS),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Observation n°${obsIndex + 1}',
                                style: TextStyle(
                                  fontSize: context.fontSizeS,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _deleteObservationFromPoint(point, obsIndex),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ObservationEnrichieWidget(
                            key: ValueKey('obs_${pointIndex}_${obsIndex}_${element.elementControle}_${element.hashCode}'),
                            element: element,
                            onChanged: () {
                              setState(() {});
                              _syncPointObservations(point);
                            },
                            color: AppTheme.primaryBlue,
                            onSavePhoto: widget.onSavePhoto,
                            showPriority: point.conformite == 'non',
                            sectionType: 'points_verification',
                          ),
                        ],
                      ),
                    );
                  }),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _addObservationToPoint(point),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('AJOUTER UNE OBSERVATION', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.5)),
                      padding: EdgeInsets.symmetric(vertical: context.spacingM),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConformiteToggle(BuildContext context, PointVerification point, int pointIndex) {
    if (IpIkEvaluatorService.isIpIkPoint(point.pointVerification)) {
      final isConforme = point.conformite.toLowerCase().trim() == 'oui';
      if (!isConforme) {
        widget.hasObservation[pointIndex] = true;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isConforme ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isConforme ? Colors.green.shade300 : Colors.red.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConforme ? Icons.check_circle : Icons.cancel,
                  color: isConforme ? Colors.green.shade700 : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isConforme ? 'Conforme' : 'Non conforme',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: context.fontSizeM,
                    color: isConforme ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Automatique',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            if (point.observation != null && point.observation!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Observation : ${point.observation}',
                style: TextStyle(
                  fontSize: context.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final isValid = point.normalizedConformite.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Conformité *', style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: isValid ? Colors.grey.shade700 : Colors.red)),
        SizedBox(height: context.spacingS),
        Row(
          children: [
            Expanded(child: _buildConformiteButton(context, label: 'Oui', isSelected: point.normalizedConformite == 'oui', color: Colors.green, onTap: () {
              setState(() { point.conformite = 'oui'; point.referenceNormative = null; });
              widget.onObservationToggleChanged(pointIndex, false);
            })),
            SizedBox(width: context.spacingS),
            Expanded(child: _buildConformiteButton(context, label: 'Non', isSelected: point.normalizedConformite == 'non', color: Colors.red, onTap: () {
              setState(() { point.conformite = 'non'; point.priorite ??= 3; });
              final reference = NormativeReferenceService.getReferenceForPoint(point.pointVerification);
              if (reference != null) point.referenceNormative = reference;
              widget.onObservationToggleChanged(pointIndex, true);
            })),
            SizedBox(width: context.spacingS),
            Expanded(child: _buildConformiteButton(context, label: 'NA', isSelected: point.normalizedConformite == 'na', color: Colors.grey.shade600, onTap: () {
              setState(() { point.conformite = 'na'; point.priorite ??= 3; point.referenceNormative = null; });
              widget.onObservationToggleChanged(pointIndex, false);
            })),
          ],
        ),
        if (!isValid) Padding(padding: EdgeInsets.only(top: context.spacingXS), child: Text('Veuillez sélectionner Oui ou Non', style: TextStyle(fontSize: context.fontSizeXS, color: Colors.red))),
      ],
    );
  }

  Widget _buildConformiteButton(BuildContext context, {required String label, required bool isSelected, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: context.spacingM),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(context.spacingS),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? (label == 'Oui' ? Icons.check_circle : Icons.cancel) : (label == 'Oui' ? Icons.check_circle_outline : Icons.cancel_outlined), size: context.iconSizeS, color: isSelected ? color : Colors.grey.shade500),
            SizedBox(width: context.spacingS),
            Text(label, style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceNormativeToggle(BuildContext context, PointVerification point, int pointIndex, bool showReference) {
    final hasReference = point.referenceNormative != null && point.referenceNormative!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showReferenceNormative[pointIndex] = !showReference),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
            decoration: BoxDecoration(color: showReference ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.transparent, borderRadius: BorderRadius.circular(context.spacingL)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(showReference ? Icons.article : Icons.article_outlined, size: context.iconSizeXS, color: hasReference ? Colors.blue : (showReference ? AppTheme.primaryBlue : Colors.grey.shade500)),
                SizedBox(width: context.spacingXS),
                Text('Référence normative', style: TextStyle(fontSize: context.fontSizeXS, color: hasReference ? Colors.blue : (showReference ? AppTheme.primaryBlue : Colors.grey.shade500), fontWeight: hasReference ? FontWeight.bold : FontWeight.w500)),
                if (hasReference) Container(margin: const EdgeInsets.only(left: 6), width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                Icon(showReference ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: context.iconSizeXS, color: hasReference ? Colors.blue : (showReference ? AppTheme.primaryBlue : Colors.grey.shade500)),
              ],
            ),
          ),
        ),
        if (showReference)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(top: context.spacingS),
            child: Container(
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(context.spacingS), border: Border.all(color: hasReference ? Colors.blue.shade200 : Colors.grey.shade200, width: hasReference ? 1.5 : 1)),
              child: TextFormField(
                initialValue: point.referenceNormative ?? '',
                style: TextStyle(fontSize: context.fontSizeS, color: hasReference ? Colors.blue.shade800 : Colors.grey.shade700),
                readOnly: true,
                decoration: InputDecoration(hintText: hasReference ? 'Référence préremplie' : 'Aucune référence', hintStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade400), border: InputBorder.none, contentPadding: EdgeInsets.all(context.spacingM)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildObservationToggle(BuildContext context, int pointIndex, bool hasObservation) {
    final point = widget.pointsVerification[pointIndex];
    final isConformiteNon = point.conformite == 'non';
    return Row(
      children: [
        Flexible(child: Text('Ajouter une observation ?', style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w500, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis)),
        SizedBox(width: context.spacingS),
        GestureDetector(
          onTap: () {
            if (isConformiteNon) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('L\'observation est obligatoire quand la conformité est "Non"'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)));
              return;
            }
            widget.onObservationToggleChanged(pointIndex, true);
          },
          child: Container(padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS), decoration: BoxDecoration(color: hasObservation ? Colors.green.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(context.spacingL), border: Border.all(color: hasObservation ? Colors.green : Colors.grey.shade300, width: hasObservation ? 2 : 1)), child: Text('Oui', style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.w600, color: hasObservation ? Colors.green : Colors.grey.shade600))),
        ),
        SizedBox(width: context.spacingS),
        GestureDetector(
          onTap: isConformiteNon ? null : () => widget.onObservationToggleChanged(pointIndex, false),
          child: Container(padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS), decoration: BoxDecoration(color: !hasObservation && !isConformiteNon ? Colors.red.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(context.spacingL), border: Border.all(color: (!hasObservation && !isConformiteNon) ? Colors.red : Colors.grey.shade300, width: (!hasObservation && !isConformiteNon) ? 2 : 1)), child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Non', style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.w600, color: isConformiteNon ? Colors.grey.shade400 : (!hasObservation ? Colors.red : Colors.grey.shade600))),
            if (isConformiteNon) Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_outline, size: context.fontSizeXS, color: Colors.grey.shade400)),
          ])),
        ),
      ],
    );
  }

}

// ================================================================
// WIDGET PRINCIPAL : AjouterCoffretScreen
// ================================================================
class AjouterCoffretScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final String parentType;
  final int parentIndex;
  final bool isMoyenneTension;
  final int? zoneIndex;
  final CoffretArmoire? coffret;
  final int? coffretIndex;
  final bool isInZone;
  final String? qrCode;

  final bool isCloning;

  const AjouterCoffretScreen({
    super.key,
    required this.mission,
    required this.parentType,
    required this.parentIndex,
    required this.isMoyenneTension,
    this.zoneIndex,
    this.coffret,
    this.coffretIndex,
    this.isInZone = false,
    this.qrCode,
    this.isCloning = false,
  });

  bool get isEdition => coffret != null && !isCloning;

  @override
  ConsumerState<AjouterCoffretScreen> createState() => _AjouterCoffretScreenState();
}

class _AjouterCoffretScreenState extends ConsumerState<AjouterCoffretScreen> {
  final _formKey = GlobalKey<FormState>();
  late final String _draftEquipmentId;
  final _nomController = TextEditingController();
  final _numeroEquipementController = TextEditingController();
  final _repereController = TextEditingController();
  String? _selectedType;
  final _qrCodeController = TextEditingController();
  bool _isQrCodeValid = false;

  bool? _alimenteeParTransformateur;
  String? _transformateurId;
  String? _transformateurNomComplet;
  List<MissionTransformateurOption> _availableTransformateurs = [];
  bool? _presenceCPI;
  bool _zoneAtex = false;
  String _domaineTension = '';
  bool _identificationArmoire = false;
  bool _numeroEquipementValid = false;
  bool _signalisationDanger = false;
  bool _presenceSchema = false;
  bool _presenceParafoudre = false;
  bool _verificationThermographie = false;
  String? _presenceDefautThermo;

  List<Alimentation> _alimentations = [];
  Alimentation? _protectionTete;
  List<PointVerification> _pointsVerification = [];

  final _indiceIpIkController = TextEditingController();
  List<DepartEquipement> _departures = [];
  List<CircuitTerminalEquipement> _terminalCircuits = [];
  String? _sourceEquipementId;
  String? _sourceNomComplet;
  String? _sourceDepartId;

  List<String> _coffretPhotosExterne = [];
  List<String> _coffretPhotosInterne = [];
  bool _isLoadingPhotosExterne = false;
  bool _isLoadingPhotosInterne = false;
  
  List<ElementControle> _observationsParafoudre = [];

  final ImagePicker _picker = ImagePicker();

  static const String _baseUrl = "http://192.168.0.217:8000";
  Map<int, List<String>> _pointSuggestions = {};
  Map<int, bool> _pointLoading = {};
  Map<int, Timer?> _pointDebounceTimers = {};
  Map<int, bool> _hasObservation = {};

  bool _nomValid = false;
  bool _typeValid = false;
  bool _repereValid = false;
  bool _alimentationsValid = true;
  bool _pointsValid = false;
  bool _domaineTensionValid = false;
  bool _accessible = true;

  bool get _departPrisAvecProtection {
    if (_selectedType == 'INVERSEUR') return true;
    final mainProt = _protectionTete?.typeProtection ??
        (_alimentations.isNotEmpty ? _alimentations.first.typeProtection : null);
    if (mainProt != null) {
      return isDepartPrisAvecProtectionFromType(mainProt);
    }
    return false;
  }

  bool _photosExterneValid = false;
  bool _photosInterneValid = false;

  final PageController _mainPageController = PageController();
  int _currentStep = 0;
  
  GlobalKey<_EtapePointsVerificationState>? _etapePointsKey;
  GlobalKey<_EtapeAlimentationsState>? _etapeAlimentationsKey;
  GlobalKey<_EtapeDepartsEtCircuitsState>? _etapeDepartsCircuitsKey;

  bool _isSaving = false;
  final ValueNotifier<bool> _isAutoSavingNotifier = ValueNotifier<bool>(false);
  bool get _isAutoSaving => _isAutoSavingNotifier.value;
  final ValueNotifier<bool> _lastAutoSaveErrorNotifier = ValueNotifier<bool>(false);
  bool get _lastAutoSaveError => _lastAutoSaveErrorNotifier.value;
  bool _hasUnsavedChanges = false;
  Timer? _autoSaveTimer;
  String? _draftQrCode;

  // NOUVEAU : système d'observations multiples (comme dans ajouter_local_screen)
  final _observationController = TextEditingController();
  final List<String> _observationPhotos = [];
  final List<ObservationLibre> _observationsLibresCoffret = [];
  bool _addObservation = false;

  @override
  void initState() {
    super.initState();
    _draftEquipmentId = (widget.isCloning || widget.coffret == null)
        ? 'equip_${DateTime.now().microsecondsSinceEpoch}'
        : widget.coffret!.equipmentId;
    _etapePointsKey = GlobalKey<_EtapePointsVerificationState>();
    _etapeAlimentationsKey = GlobalKey<_EtapeAlimentationsState>();
    _etapeDepartsCircuitsKey = GlobalKey<_EtapeDepartsEtCircuitsState>();
    _indiceIpIkController.addListener(() {
      setState(() {});
      _scheduleAutoSave();
    });
    _availableTransformateurs = HiveService.getAllTransformateurOptionsForMission(widget.mission.id);
    _autoFillRepere();
    
    if (widget.qrCode != null) {
      _qrCodeController.text = widget.qrCode!;
      _validateQrCode(widget.qrCode!);
      _draftQrCode = widget.qrCode;
    }
    if (widget.isEdition) {
      _chargerDonneesExistantes();
    } else if (widget.isCloning && widget.coffret != null) {
      _chargerDonneesExistantes();
      _autoFillNumeroEquipement();
    } else {
      _initializeAlimentations();
      _autoFillNumeroEquipement();
      if (_draftQrCode != null && _draftQrCode!.isNotEmpty) {
        _loadDraftByQrCode(_draftQrCode!);
      }
    }

    _nomController.addListener(() {
      _hasUnsavedChanges = true;
      _scheduleAutoSave();
    });
    _repereController.addListener(() {
      _hasUnsavedChanges = true;
      _scheduleAutoSave();
    });
    _numeroEquipementController.addListener(() {
      _hasUnsavedChanges = true;
      _scheduleAutoSave();
    });
  }

  Future<void> _loadDraftByQrCode(String qrCode) async {
    final draft = HiveService.getCoffretDraftByQrCode(qrCode);
    if (draft != null) {
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(widget.mission.id, draft);
      setState(() {
        _nomController.text = draft.nom;
        _numeroEquipementController.text = draft.numeroEquipement ?? '';
        _repereController.text = draft.repere ?? '';
        if (_numeroEquipementController.text.trim().isEmpty) _autoFillNumeroEquipement();
        _selectedType = draft.type;
        _accessible = draft.accessible;
        _alimenteeParTransformateur = draft.alimenteeParTransformateur;
        _transformateurId = draft.transformateurId;
        _transformateurNomComplet = draft.transformateurNomComplet;
        _presenceCPI = (draft.type == 'INVERSEUR') ? null : draft.presenceCPI;
        _zoneAtex = draft.zoneAtex;
        _domaineTension = draft.domaineTension;
        _identificationArmoire = draft.identificationArmoire;
        _signalisationDanger = draft.signalisationDanger;
        _presenceSchema = draft.presenceSchema;
        _presenceParafoudre = draft.presenceParafoudre;
        _verificationThermographie = draft.verificationThermographie;
        _presenceDefautThermo = draft.presenceDefautThermo;
        _indiceIpIkController.text = draft.indiceIpIk ?? '';
        _departures = List.from(draft.effectiveDepartures.map((d) => d.copyWith()));
        _terminalCircuits = List.from(draft.effectiveTerminalCircuits.map((c) => c.copyWith()));
        _sourceEquipementId = draft.sourceEquipementId;
        _sourceNomComplet = draft.sourceNomComplet;
        _sourceDepartId = draft.sourceDepartId;
        _alimentations = List.from(draft.alimentations);
        _protectionTete = draft.protectionTete;
        _pointsVerification = List.from(draft.pointsVerification.map((point) => PointVerification(
          pointVerification: point.pointVerification,
          conformite: point.conformite,
          observation: point.observation,
          referenceNormative: point.referenceNormative,
          photos: List.from(point.photos),
          observations: point.observations != null
              ? List.from(point.observations!.map((e) => ElementControle(
                    elementControle: e.elementControle,
                    conforme: e.conforme,
                    observation: e.observation,
                    priorite: e.priorite,
                    photos: List.from(e.photos),
                    referenceNormative: e.referenceNormative,
                    estNA: e.estNA,
                  )))
              : null,
        )));
        if (_selectedType == 'INVERSEUR') {
          DispositionsConstructivesRegistry.ensureCompleteInverseurChecklist(_pointsVerification);
        } else {
          DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(_pointsVerification);
        }
        _coffretPhotosExterne = draft.photos.where((p) => p.contains('externe')).toList();
        _coffretPhotosInterne = draft.photos.where((p) => p.contains('interne')).toList();
        _currentStep = draft.currentStep;
        _observationsParafoudre = List.from(draft.observationsParafoudreEnrichies ?? []);
        if (_observationsParafoudre.isEmpty && draft.observationsParafoudre.isNotEmpty) {
          for (var obs in draft.observationsParafoudre) {
            _observationsParafoudre.add(ElementControle(
              elementControle: obs.texte,
              conforme: false,
              observation: obs.texte,
              photos: List.from(obs.photos),
            ));
          }
        }
        // Charger les observations multiples
        if (draft.observationsLibres.isNotEmpty) {
          _observationsLibresCoffret.clear();
          _observationsLibresCoffret.addAll(draft.observationsLibres);
        }
        for (int i = 0; i < _pointsVerification.length; i++) {
          final point = _pointsVerification[i];
          if (point.conformite == 'non') {
            _hasObservation[i] = true;
          } else if (point.conformite == 'na') {
            _hasObservation[i] = point.observation != null && point.observation!.isNotEmpty;
          } else {
            _hasObservation[i] = point.observation != null && point.observation!.isNotEmpty;
          }
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mainPageController.hasClients) _mainPageController.jumpToPage(_currentStep);
        });
        _validateNom(_nomController.text);
        _validateType(_selectedType);
        _validateRepere(_repereController.text);
        _validateDomaineTension(_domaineTension);
        _validatePhotosExterne();
        _validatePhotosInterne();
        _validatePoints();
      });
    }
  }

  Future<void> _loadDraft() async {
    if (_draftQrCode == null || _draftQrCode!.isEmpty) return;
    final draftData = HiveService.getCoffretDraftData(_draftQrCode!);
    if (draftData != null) {
      final draft = draftData['coffret'] as CoffretArmoire;
      final savedStep = draftData['currentStep'] as int? ?? 0;
      setState(() {
        _nomController.text = draft.nom;
        _numeroEquipementController.text = draft.numeroEquipement ?? '';
        _repereController.text = draft.repere ?? '';
        if (_numeroEquipementController.text.trim().isEmpty) _autoFillNumeroEquipement();
        _selectedType = draft.type;
        _alimenteeParTransformateur = draft.alimenteeParTransformateur;
        _transformateurId = draft.transformateurId;
        _transformateurNomComplet = draft.transformateurNomComplet;
        _presenceCPI = (draft.type == 'INVERSEUR') ? null : draft.presenceCPI;
        _zoneAtex = draft.zoneAtex;
        _domaineTension = draft.domaineTension;
        _identificationArmoire = draft.identificationArmoire;
        _signalisationDanger = draft.signalisationDanger;
        _presenceSchema = draft.presenceSchema;
        _presenceParafoudre = draft.presenceParafoudre;
        _verificationThermographie = draft.verificationThermographie;
        _presenceDefautThermo = draft.presenceDefautThermo;
        _alimentations = List.from(draft.alimentations);
        _protectionTete = draft.protectionTete;
        _pointsVerification = List.from(draft.pointsVerification.map((point) => PointVerification(
          pointVerification: point.pointVerification,
          conformite: point.conformite,
          observation: point.observation,
          referenceNormative: point.referenceNormative,
          photos: List.from(point.photos),
          observations: point.observations != null
              ? List.from(point.observations!.map((e) => ElementControle(
                    elementControle: e.elementControle,
                    conforme: e.conforme,
                    observation: e.observation,
                    priorite: e.priorite,
                    photos: List.from(e.photos),
                    referenceNormative: e.referenceNormative,
                    estNA: e.estNA,
                  )))
              : null,
        )));
        if (_selectedType == 'INVERSEUR') {
          DispositionsConstructivesRegistry.ensureCompleteInverseurChecklist(_pointsVerification);
        } else {
          DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(_pointsVerification);
        }
        if (draft.photosExternes.isNotEmpty || draft.photosInternes.isNotEmpty) {
          _coffretPhotosExterne = List.from(draft.photosExternes);
          _coffretPhotosInterne = List.from(draft.photosInternes);
        } else if (draft.photos.isNotEmpty) {
          _coffretPhotosExterne = draft.photos.where((p) => p.contains('externe')).toList();
          _coffretPhotosInterne = draft.photos.where((p) => p.contains('interne')).toList();
          if (_coffretPhotosExterne.isEmpty && _coffretPhotosInterne.isEmpty) _coffretPhotosExterne = List.from(draft.photos);
        }
        // Charger observations multiples
        if (draft.observationsLibres.isNotEmpty) {
          _observationsLibresCoffret.clear();
          _observationsLibresCoffret.addAll(draft.observationsLibres);
        }
        _currentStep = savedStep;
        _validatePhotosExterne();
        _validatePhotosInterne();
        for (int i = 0; i < _pointsVerification.length; i++) {
          final point = _pointsVerification[i];
          if (point.conformite == 'non') _hasObservation[i] = true;
          else if (point.conformite == 'na') _hasObservation[i] = point.observation != null && point.observation!.isNotEmpty;
          else _hasObservation[i] = point.observation != null && point.observation!.isNotEmpty;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mainPageController.hasClients) _mainPageController.jumpToPage(_currentStep);
        });
        _validateNom(_nomController.text);
        _validateNumeroEquipement(_numeroEquipementController.text);
        _validateType(_selectedType);
        _validateRepere(_repereController.text);
        _validateDomaineTension(_domaineTension);
        _validatePoints();
      });
    }
  }

  void _scheduleAutoSave() {
    if (!mounted) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (widget.isEdition && widget.coffret != null) {
        _autoSaveEdition();
      } else {
        _saveDraft();
      }
    });
  }

  Future<void> flushAutoSave() async {
    if (_autoSaveTimer != null && _autoSaveTimer!.isActive) {
      _autoSaveTimer!.cancel();
      _autoSaveTimer = null;
      if (widget.isEdition && widget.coffret != null) {
        await _autoSaveEdition();
      } else {
        await _saveDraft();
      }
    }
  }

  CoffretArmoire _buildCurrentCoffret({String? forcedStatut}) {
    final toutesPhotos = [..._coffretPhotosExterne, ..._coffretPhotosInterne];
    final now = DateTime.now().toUtc();
    return CoffretArmoire(
      id: widget.coffret?.equipmentId ?? _draftEquipmentId,
      createdAt: widget.coffret?.createdAt ?? (widget.isEdition ? null : now),
      updatedAt: now,
      qrCode: _qrCodeController.text.trim(),
      nom: _nomController.text.trim(),
      type: _selectedType ?? '',
      accessible: _accessible,
      departPrisAvecProtection: _departPrisAvecProtection,
      numeroEquipement: _numeroEquipementController.text.trim().isEmpty ? null : _numeroEquipementController.text.trim(),
      repere: _repereController.text.trim().isEmpty ? null : _repereController.text.trim(),
      alimenteeParTransformateur: _alimenteeParTransformateur,
      transformateurId: _transformateurId,
      transformateurNomComplet: _transformateurNomComplet,
      presenceCPI: (_selectedType == 'INVERSEUR') ? null : _presenceCPI,
      zoneAtex: _zoneAtex,
      domaineTension: _domaineTension,
      identificationArmoire: _identificationArmoire,
      signalisationDanger: _signalisationDanger,
      presenceSchema: _presenceSchema,
      presenceParafoudre: _presenceParafoudre,
      verificationThermographie: _verificationThermographie,
      presenceDefautThermo: _presenceDefautThermo,
      indiceIpIk: _indiceIpIkController.text.trim().isEmpty ? null : _indiceIpIkController.text.trim(),
      indiceIpIkRepere: _resolveRepereIpIk().hasIpOrIk ? _resolveRepereIpIk().toString() : null,
      departures: List.from(_departures),
      terminalCircuits: List.from(_terminalCircuits),
      sourceEquipementId: _sourceEquipementId,
      sourceNomComplet: _sourceNomComplet,
      sourceDepartId: _sourceDepartId,
      alimentations: List.from(_alimentations),
      protectionTete: _protectionTete,
      pointsVerification: List.from(_pointsVerification),
      observationsLibres: List.from(_observationsLibresCoffret),
      photos: toutesPhotos,
      photosExternes: List.from(_coffretPhotosExterne),
      photosInternes: List.from(_coffretPhotosInterne),
      observationsParafoudre: const [],
      observationsParafoudreEnrichies: List.from(_observationsParafoudre),
      statut: forcedStatut ?? widget.coffret?.statut ?? (_pointsValid ? 'complet' : 'incomplet'),
      currentStep: _currentStep,
    );
  }

  Future<bool> _autoSaveEdition() async {
    if (!mounted || widget.coffret == null) return false;
    _isAutoSavingNotifier.value = true;
    _lastAutoSaveErrorNotifier.value = false;
    try {
      final nouveauCoffret = _buildCurrentCoffret();
      final ok = await HiveService.updateCoffretById(
        missionId: widget.mission.id,
        equipmentId: widget.coffret!.equipmentId,
        updatedCoffret: nouveauCoffret,
        oldNom: widget.coffret!.nom,
        allowClearDepartures: true,
        allowClearCircuits: true,
      );
      if (mounted) {
        _isAutoSavingNotifier.value = false;
        _lastAutoSaveErrorNotifier.value = !ok;
        if (ok) {
          _hasUnsavedChanges = false;
        }
      }
      return ok;
    } catch (e) {
      if (kDebugMode) print('⚠️ [AUTO SAVE EDITION EXCEPTION] $e');
      if (mounted) {
        _isAutoSavingNotifier.value = false;
        _lastAutoSaveErrorNotifier.value = true;
      }
      return false;
    }
  }

  void _addParafoudreObservation() {
    setState(() {
      _observationsParafoudre.add(ElementControle(
        elementControle: 'État du parafoudre',
        conforme: false,
        priorite: 3,
        observation: '',
      ));
    });
    _saveDraft();
  }

  void _deleteParafoudreObservation(int index) {
    setState(() { _observationsParafoudre.removeAt(index); });
    _saveDraft();
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    if (widget.isEdition && widget.coffret != null) return;
    for (var obs in _observationsParafoudre) {
      obs.priorite = null;
    }
    String qrCode = _qrCodeController.text.trim();
    if (qrCode.isEmpty) {
      qrCode = 'TEMP_${DateTime.now().millisecondsSinceEpoch}';
      _qrCodeController.text = qrCode;
      _draftQrCode = qrCode;
    }
    final toutesPhotos = [..._coffretPhotosExterne, ..._coffretPhotosInterne];
    final now = DateTime.now().toUtc();
    final draft = CoffretArmoire(
      id: widget.coffret?.equipmentId,
      createdAt: widget.coffret?.createdAt ?? (widget.isEdition ? null : now),
      updatedAt: now,
      qrCode: qrCode,
      nom: _nomController.text.trim(),
      type: _selectedType ?? '',
      accessible: _accessible,
      departPrisAvecProtection: _departPrisAvecProtection,
      numeroEquipement: _numeroEquipementController.text.trim().isEmpty ? null : _numeroEquipementController.text.trim(),
      repere: _repereController.text.trim().isEmpty ? null : _repereController.text.trim(),
      alimenteeParTransformateur: _alimenteeParTransformateur,
      transformateurId: _transformateurId,
      transformateurNomComplet: _transformateurNomComplet,
      presenceCPI: _presenceCPI,
      zoneAtex: _zoneAtex,
      domaineTension: _domaineTension,
      identificationArmoire: _identificationArmoire,
      signalisationDanger: _signalisationDanger,
      presenceSchema: _presenceSchema,
      presenceParafoudre: _presenceParafoudre,
      verificationThermographie: _verificationThermographie,
      presenceDefautThermo: _presenceDefautThermo,
      indiceIpIk: _indiceIpIkController.text.trim().isEmpty ? null : _indiceIpIkController.text.trim(),
      indiceIpIkRepere: _resolveRepereIpIk().hasIpOrIk ? _resolveRepereIpIk().toString() : null,
      departures: _departures,
      terminalCircuits: _terminalCircuits,
      sourceEquipementId: _sourceEquipementId,
      sourceNomComplet: _sourceNomComplet,
      sourceDepartId: _sourceDepartId,
      alimentations: _alimentations,
      protectionTete: _protectionTete,
      pointsVerification: _pointsVerification,
      observationsLibres: List.from(_observationsLibresCoffret),
      photos: toutesPhotos,
      photosExternes: List.from(_coffretPhotosExterne),
      photosInternes: List.from(_coffretPhotosInterne),
      statut: 'incomplet',
      currentStep: _currentStep,
      observationsParafoudre: const [],
      observationsParafoudreEnrichies: _observationsParafoudre,
    );
    await HiveService.saveCoffretDraft(
      missionId: widget.mission.id,
      parentType: widget.parentType,
      parentIndex: widget.parentIndex,
      isMoyenneTension: widget.isMoyenneTension,
      zoneIndex: widget.zoneIndex,
      coffret: draft,
      currentStep: _currentStep,
    );
    _hasUnsavedChanges = false;
  }

  void _autoFillRepere() {
    if (widget.isEdition) return;
    String parentName = '';
    final audit = HiveService.getAuditInstallationsByMissionId(widget.mission.id);
    if (audit != null) {
      if (widget.parentType == 'local') {
        if (widget.isMoyenneTension) {
          if (widget.isInZone && widget.zoneIndex != null && widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.parentIndex < zone.locaux.length) parentName = zone.locaux[widget.parentIndex].nom;
          } else if (widget.parentIndex < audit.moyenneTensionLocaux.length) parentName = audit.moyenneTensionLocaux[widget.parentIndex].nom;
        } else if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.parentIndex < zone.locaux.length) parentName = zone.locaux[widget.parentIndex].nom;
        }
      } else if (widget.parentType == 'zone_mt' || widget.parentType == 'zone_bt') {
        if (widget.isMoyenneTension && widget.parentIndex < audit.moyenneTensionZones.length) parentName = audit.moyenneTensionZones[widget.parentIndex].nom;
        else if (!widget.isMoyenneTension && widget.parentIndex < audit.basseTensionZones.length) parentName = audit.basseTensionZones[widget.parentIndex].nom;
      }
    }
    if (parentName.isNotEmpty) {
      _repereController.text = parentName;
      _validateRepere(parentName);
    }
  }

  String _getParentLocationName() {
    final audit = HiveService.getAuditInstallationsByMissionId(widget.mission.id);
    if (audit == null) return _repereController.text.trim();
    if (widget.parentType == 'local') {
      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null && widget.zoneIndex! < audit.moyenneTensionZones.length) {
          final zone = audit.moyenneTensionZones[widget.zoneIndex!];
          if (widget.parentIndex < zone.locaux.length) return zone.locaux[widget.parentIndex].nom;
        } else if (widget.parentIndex < audit.moyenneTensionLocaux.length) return audit.moyenneTensionLocaux[widget.parentIndex].nom;
      } else if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
        final zone = audit.basseTensionZones[widget.zoneIndex!];
        if (widget.parentIndex < zone.locaux.length) return zone.locaux[widget.parentIndex].nom;
      }
    } else if (widget.parentType == 'zone_mt' || widget.parentType == 'zone_bt') {
      if (widget.isMoyenneTension && widget.parentIndex < audit.moyenneTensionZones.length) return audit.moyenneTensionZones[widget.parentIndex].nom;
      else if (!widget.isMoyenneTension && widget.parentIndex < audit.basseTensionZones.length) return audit.basseTensionZones[widget.parentIndex].nom;
    }
    return _repereController.text.trim();
  }

  ParsedIpIk _resolveRepereIpIk() {
    return IpIkEvaluatorService.resolveRepereIpIk(
      missionId: widget.mission.id,
      parentName: _getParentLocationName(),
      repere: _repereController.text.trim(),
    );
  }

  ({String zone, String repere}) _resolveCurrentLocation() {
    final audit = HiveService.getAuditInstallationsByMissionId(widget.mission.id);
    return EssaiDeclenchementHelper.resolveZoneAndRepere(
      audit: audit,
      parentType: widget.parentType,
      parentIndex: widget.parentIndex,
      zoneIndex: widget.zoneIndex,
      isMoyenneTension: widget.isMoyenneTension,
      fallbackRepere: _repereController.text.trim(),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _isAutoSavingNotifier.dispose();
    _lastAutoSaveErrorNotifier.dispose();
    _pointDebounceTimers.forEach((key, timer) => timer?.cancel());
    _nomController.dispose();
    _numeroEquipementController.dispose();
    _repereController.dispose();
    _qrCodeController.dispose();
    _indiceIpIkController.dispose();
    _observationController.dispose();
    _mainPageController.dispose();
    super.dispose();
  }

  void _validateNom(String value) { setState(() => _nomValid = value.trim().isNotEmpty); _scheduleAutoSave(); }
  void _validateNumeroEquipement(String value) { setState(() => _numeroEquipementValid = true); _scheduleAutoSave(); }
  void _autoFillNumeroEquipement() {
    if (_numeroEquipementController.text.trim().isNotEmpty) return;
    final next = HiveService.getNextNumeroEquipement(widget.mission.id);
    _numeroEquipementController.text = next.toString();
    _validateNumeroEquipement(next.toString());
  }
  void _validateType(String? value) { setState(() => _typeValid = value != null && value.isNotEmpty); _scheduleAutoSave(); }
  void _validateRepere(String value) { setState(() => _repereValid = value.trim().isNotEmpty); _scheduleAutoSave(); }
  void _validateDomaineTension(String? value) {
    String finalValue = value ?? '';
    if (finalValue.isEmpty && _domaineTension.isNotEmpty) finalValue = _domaineTension;
    if (finalValue.isEmpty && _domaineTensionValid == false) finalValue = '230/400';
    setState(() { _domaineTension = finalValue; _domaineTensionValid = finalValue.isNotEmpty; });
    _scheduleAutoSave();
  }
  void _validateAlimentations() { setState(() => _alimentationsValid = true); _scheduleAutoSave(); }
  void _validatePoints() {
    bool isValid = true;
    for (var point in _pointsVerification) { if (point.conformite.isEmpty) { isValid = false; break; } }
    setState(() => _pointsValid = isValid);
    _scheduleAutoSave();
  }

  bool _validateAllFields({bool isFinishing = false}) {
    bool allValid = true;
    if (_nomController.text.trim().isEmpty) { _nomValid = false; allValid = false; }
    if (_selectedType == null || _selectedType!.isEmpty) { _typeValid = false; allValid = false; }
    if (_repereController.text.trim().isEmpty) { _repereValid = false; allValid = false; }
    if (_accessible) {
      _alimentationsValid = true;
      _validatePoints();
      if ((!widget.isEdition || isFinishing) && !_pointsValid) allValid = false;
      if (_domaineTension.isEmpty) { _domaineTensionValid = false; allValid = false; }
      if (_coffretPhotosExterne.isEmpty) { _photosExterneValid = false; allValid = false; _showError('La photo EXTERNE est obligatoire'); } else { _photosExterneValid = true; }
      if (_coffretPhotosInterne.isEmpty) { _photosInterneValid = false; allValid = false; _showError('La photo INTERNE est obligatoire'); } else { _photosInterneValid = true; }
    } else {
      _alimentationsValid = true;
      _pointsValid = true;
      _domaineTensionValid = true;
    }
    setState(() {});
    _scheduleAutoSave();
    return allValid;
  }

  void _validateQrCode(String qrCode) {
    if (qrCode.isEmpty) { setState(() => _isQrCodeValid = false); return; }
    final existing = HiveService.findCoffretByQrCode(widget.mission.id, qrCode);
    _isQrCodeValid = widget.isEdition ? true : existing == null;
    _scheduleAutoSave();
  }
  void _validatePhotosExterne() { setState(() { _photosExterneValid = _coffretPhotosExterne.isNotEmpty; }); _scheduleAutoSave(); }
  void _validatePhotosInterne() { setState(() { _photosInterneValid = _coffretPhotosInterne.isNotEmpty; }); _scheduleAutoSave(); }

  void _chargerDonneesExistantes() {
    final coffret = widget.coffret!;
    EquipmentNumberService.ensureEquipmentIdentityAndNumber(widget.mission.id, coffret);
    _nomController.text = coffret.nom;
    _numeroEquipementController.text = coffret.numeroEquipement ?? '';
    _selectedType = coffret.type;
    _accessible = coffret.accessible;
    _repereController.text = coffret.repere ?? '';
    _alimenteeParTransformateur = coffret.alimenteeParTransformateur;
    _transformateurId = coffret.transformateurId;
    _transformateurNomComplet = coffret.transformateurNomComplet;
    _presenceCPI = coffret.presenceCPI;
    _zoneAtex = coffret.zoneAtex;
    _domaineTension = coffret.domaineTension.isNotEmpty ? coffret.domaineTension : '230/400';
    _domaineTensionValid = _domaineTension.isNotEmpty;
    _identificationArmoire = coffret.identificationArmoire;
    _signalisationDanger = coffret.signalisationDanger;
    _presenceSchema = coffret.presenceSchema;
    _presenceParafoudre = coffret.presenceParafoudre;
    _verificationThermographie = coffret.verificationThermographie;
    _presenceDefautThermo = coffret.presenceDefautThermo;
    _indiceIpIkController.text = coffret.indiceIpIk ?? '';
    _departures = List.from(coffret.effectiveDepartures.map((d) => d.copyWith()));
    _terminalCircuits = List.from(coffret.effectiveTerminalCircuits.map((c) => c.copyWith()));
    _sourceEquipementId = coffret.sourceEquipementId;
    _sourceNomComplet = coffret.sourceNomComplet;
    _sourceDepartId = coffret.sourceDepartId;
    _observationsParafoudre = List.from(coffret.observationsParafoudreEnrichies ?? []);
    if (_observationsParafoudre.isEmpty && coffret.observationsParafoudre.isNotEmpty) {
      for (var obs in coffret.observationsParafoudre) {
        _observationsParafoudre.add(ElementControle(
          elementControle: obs.texte,
          conforme: false,
          observation: obs.texte,
          photos: List.from(obs.photos),
        ));
      }
    }
    _alimentations = List.from(coffret.alimentations);
    if (_selectedType == 'INVERSEUR') {
      while (_alimentations.length < 3) {
        _alimentations.add(Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''));
      }
    }
    _protectionTete = coffret.protectionTete;
    _pointsVerification = List.from(coffret.pointsVerification.map((point) => PointVerification(
      pointVerification: point.pointVerification,
      conformite: point.conformite,
      observation: point.observation,
      referenceNormative: point.referenceNormative,
      photos: List.from(point.photos),
      observations: point.observations != null
          ? List.from(point.observations!.map((e) => ElementControle(
                elementControle: e.elementControle,
                conforme: e.conforme,
                observation: e.observation,
                priorite: e.priorite,
                photos: List.from(e.photos),
                referenceNormative: e.referenceNormative,
                estNA: e.estNA,
              )))
          : null,
    )));
    if (_selectedType == 'INVERSEUR') {
      DispositionsConstructivesRegistry.ensureCompleteInverseurChecklist(_pointsVerification);
    } else {
      DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(_pointsVerification);
    }
    // Observations multiples
    if (coffret.observationsLibres.isNotEmpty) {
      _observationsLibresCoffret.clear();
      _observationsLibresCoffret.addAll(coffret.observationsLibres);
    }
    if (coffret.photosExternes.isNotEmpty || coffret.photosInternes.isNotEmpty) {
      _coffretPhotosExterne = List.from(coffret.photosExternes);
      _coffretPhotosInterne = List.from(coffret.photosInternes);
    } else if (coffret.photos.isNotEmpty) {
      _coffretPhotosExterne = coffret.photos.where((p) => p.contains('externe')).toList();
      _coffretPhotosInterne = coffret.photos.where((p) => p.contains('interne')).toList();
      if (_coffretPhotosExterne.isEmpty && _coffretPhotosInterne.isEmpty) _coffretPhotosExterne = List.from(coffret.photos);
    }
    _validatePhotosExterne();
    _validatePhotosInterne();
    for (int i = 0; i < _pointsVerification.length; i++) {
      final point = _pointsVerification[i];
      if (point.normalizedConformite == 'non') _hasObservation[i] = true;
      else _hasObservation[i] = point.observation != null && point.observation!.isNotEmpty;
    }
    _initializeForCoffretType(_selectedType);
    _validateNom(coffret.nom);
    _validateNumeroEquipement(coffret.numeroEquipement ?? '');
    _validateType(coffret.type);
    _validateRepere(coffret.repere ?? '');
    _validateAlimentations();
    _validatePoints();
    _validateDomaineTension(coffret.domaineTension);
  }

  // ==================== NOUVELLES MÉTHODES POUR OBSERVATIONS MULTIPLES ====================
  Future<void> _prendrePhotoObservation() async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null) {
      await GalleryPhotoService.saveToGallery(File(photo.path));
      final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations_coffret');
      if (savedPath != null) setState(() => _observationPhotos.add(savedPath));
    }
  }

  Future<void> _choisirPhotoObservation() async {
    final photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (photo != null) {
      final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations_coffret');
      if (savedPath != null) setState(() => _observationPhotos.add(savedPath));
    }
  }

  void _ajouterObservation([
    String? pointKey,
    String? refNormative,
    String? famille,
    String? crit,
  ]) {
    final rawTexte = _observationController.text.trim();
    if (rawTexte.isEmpty) return;
    final texte = ObservationTextNormalizer.normalize(rawTexte) ?? rawTexte;
    setState(() {
      _observationsLibresCoffret.add(ObservationLibre(
        texte: texte,
        photos: List.from(_observationPhotos),
        pointVerificationKey: pointKey,
        referenceNormative: refNormative,
        familleRisque: famille,
        criticite: crit,
      ));
      _observationController.clear();
      _observationPhotos.clear();
      _addObservation = false;
    });
    _saveDraft();
  }

  // ==================== FIN NOUVELLES MÉTHODES ====================

  Future<void> _prendrePhotoExterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        await GalleryPhotoService.saveToGallery(File(photo.path));
        if (mounted) setState(() => _isLoadingPhotosExterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_externe');
        if (mounted) setState(() { _coffretPhotosExterne.add(savedPath); _validatePhotosExterne(); _isLoadingPhotosExterne = false; });
      }
    } catch (e) { if (mounted) setState(() => _isLoadingPhotosExterne = false); _showError('Erreur photo externe: $e'); }
  }

  Future<void> _choisirPhotoExterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        if (mounted) setState(() => _isLoadingPhotosExterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_externe');
        if (mounted) setState(() { _coffretPhotosExterne.add(savedPath); _validatePhotosExterne(); _isLoadingPhotosExterne = false; });
      }
    } catch (e) { if (mounted) setState(() => _isLoadingPhotosExterne = false); _showError('Erreur sélection photo externe: $e'); }
  }

  Future<void> _prendrePhotoInterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        await GalleryPhotoService.saveToGallery(File(photo.path));
        if (mounted) setState(() => _isLoadingPhotosInterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_interne');
        if (mounted) setState(() { _coffretPhotosInterne.add(savedPath); _validatePhotosInterne(); _isLoadingPhotosInterne = false; });
      }
    } catch (e) { if (mounted) setState(() => _isLoadingPhotosInterne = false); _showError('Erreur photo interne: $e'); }
  }

  Future<void> _choisirPhotoInterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        if (mounted) setState(() => _isLoadingPhotosInterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_interne');
        if (mounted) setState(() { _coffretPhotosInterne.add(savedPath); _validatePhotosInterne(); _isLoadingPhotosInterne = false; });
      }
    } catch (e) { if (mounted) setState(() => _isLoadingPhotosInterne = false); _showError('Erreur sélection photo interne: $e'); }
  }

  Future<String> _savePhotoToAppDirectory(File photoFile, String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/audit_photos/$subDir');
    if (!await photosDir.exists()) await photosDir.create(recursive: true);
    final fileName = '${subDir}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${photosDir.path}/$fileName';
    await ImageCompressHelper.compressImage(photoFile, newPath);
    return newPath;
  }

  void _supprimerPhotoExterne(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () { Navigator.pop(context); setState(() { _coffretPhotosExterne.removeAt(index); _validatePhotosExterne(); }); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
        ],
      ),
    );
  }

  void _supprimerPhotoInterne(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () { Navigator.pop(context); setState(() { _coffretPhotosInterne.removeAt(index); _validatePhotosInterne(); }); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
        ],
      ),
    );
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));

  void _addSortieInverseur() {
    setState(() {
      _alimentations.add(Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''));
      _hasUnsavedChanges = true;
    });
    _scheduleAutoSave();
  }

  void _deleteSortieInverseur(int index) {
    if (index < 2 || index >= _alimentations.length) return;
    if (_alimentations.length <= 3) return; // Conserver au moins 1 sortie
    setState(() {
      _alimentations.removeAt(index);
      _hasUnsavedChanges = true;
    });
    _scheduleAutoSave();
  }

  void _initializeAlimentations() {
    _alimentations = [];
    _protectionTete = null;
    if (_domaineTension.isEmpty && !widget.isEdition) { _domaineTension = '230/400'; _domaineTensionValid = true; }
  }

  void _onTypeChanged(String? newType) {
    setState(() {
      _selectedType = newType;
      if (newType == 'INVERSEUR') {
        _presenceCPI = null;
      }
      _validateType(newType);
      _initializeForCoffretType(newType);
    });
    _scheduleAutoSave();
  }

  void _initializeForCoffretType(String? type) {
    if (type == null) return;
    if (!widget.isEdition && _pointsVerification.isEmpty) {
      final points = HiveService.getPointsVerificationForCoffret(type);
      _pointsVerification = points.map((point) {
        final meta = DispositionsConstructivesRegistry.getCoffretMetadata(point, coffretType: type);
        return PointVerification(
          pointVerification: point,
          conformite: '',
          observation: null,
          referenceNormative: meta?.referenceNormative,
          familleRisque: meta?.familleRisque,
          criticite: meta?.criticite,
          priorite: null,
        );
      }).toList();

      if (type == 'INVERSEUR') {
        DispositionsConstructivesRegistry.ensureCompleteInverseurChecklist(_pointsVerification);
      } else {
        DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(_pointsVerification);
      }

      for (var p in _pointsVerification) {
        p.conformite = '';
      }

      _hasObservation.clear();
      for (int i = 0; i < _pointsVerification.length; i++) _hasObservation[i] = false;
      _alimentations.clear();
      _protectionTete = null;
      if (type == 'INVERSEUR') {
        _alimentations.addAll([
          Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''),
          Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''),
          Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''),
        ]);
      } else {
        _alimentations.add(Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''));
        _protectionTete = Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: '');
      }
    } else {
      // Transition dynamique de type (en création ou en édition)
      final dummy = CoffretArmoire(
        qrCode: _qrCodeController.text.trim(),
        nom: _nomController.text,
        repere: _repereController.text,
        type: type,
        statut: 'en_cours',
        pointsVerification: _pointsVerification,
        alimentations: _alimentations,
        protectionTete: _protectionTete,
        departures: _departures,
        terminalCircuits: _terminalCircuits,
        presenceCPI: _presenceCPI,
      );

      EquipmentTypeTransitionService.normalizeEquipmentForType(dummy, type);

      _pointsVerification = dummy.pointsVerification;
      _alimentations = dummy.alimentations;
      _protectionTete = dummy.protectionTete;
      _departures = dummy.departures ?? [];
      _terminalCircuits = dummy.terminalCircuits ?? [];
      _presenceCPI = dummy.presenceCPI;

      for (var p in _pointsVerification) {
        final meta = DispositionsConstructivesRegistry.getCoffretMetadata(
          p.pointVerification,
          coffretType: type,
        );
        if (meta != null) {
          p.referenceNormative ??= meta.referenceNormative;
          p.familleRisque ??= meta.familleRisque;
          p.criticite ??= meta.criticite;
        }
      }

      _hasObservation.clear();
      for (int i = 0; i < _pointsVerification.length; i++) {
        _hasObservation[i] = _pointsVerification[i].observation?.trim().isNotEmpty == true;
      }
    }
  }

  Future<void> _transfererEssais(String ancienNom, String nouveauNom) async {
    try {
      final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();
      for (var essai in mesures.essaisDeclenchement) { if (essai.coffret == ancienNom) essai.coffret = nouveauNom; }
      await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).saveMesures(mesures);
    } catch (e) { _showError('Erreur transfert essais'); }
  }

  void _onPointObservationChanged(int index, String text) {
    if (text.length >= 3) {
      _pointDebounceTimers[index]?.cancel();
      _pointDebounceTimers[index] = Timer(const Duration(milliseconds: 500), () async {
        try {
          final res = await http.post(Uri.parse('$_baseUrl/api/v1/autocomplete'), headers: {'Content-Type': 'application/json'}, body: json.encode({'query': text, 'max_results': 5})).timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) { final data = json.decode(res.body) as Map<String, dynamic>; setState(() => _pointSuggestions[index] = List<String>.from(data['suggestions'] ?? [])); }
        } catch (e) {}
      });
    } else { setState(() => _pointSuggestions[index]?.clear()); }
  }

  void _onUsePointSuggestion(int index, String suggestion, PointVerification point) { point.observation = suggestion; setState(() => _pointSuggestions[index]?.clear()); }

  void _onObservationToggleChanged(int index, bool value) {
    final point = _pointsVerification[index];
    if (!value && point.normalizedConformite == 'non') { _showError('L\'observation est obligatoire quand la conformité est "Non"'); return; }
    setState(() {
      _hasObservation[index] = value;
      if (!value) {
        point.observation = null;
        point.priorite = null;
        point.photos = [];
        point.observations = [];
      } else {
        point.observations ??= [];
        if (point.observations!.isEmpty) {
          point.observations!.add(ElementControle(
            elementControle: point.pointVerification,
            conforme: false,
            priorite: point.normalizedConformite == 'non' ? 3 : null,
            observation: '',
          ));
        }
      }
    });
    _hasUnsavedChanges = true;
    _scheduleAutoSave();
  }

  void _sauvegarder({bool isFinishing = false}) async {
    if (_isSaving) return;
    if (!_validateAllFields(isFinishing: isFinishing)) { _showError('Veuillez remplir tous les champs obligatoires'); return; }
    
    setState(() => _isSaving = true);

    if (kDebugMode) {
      print('💾 [SAVE PIPELINE] === START SAVE OPERATION ===');
      print('💾 [SAVE PIPELINE] Mission ID: ${widget.mission.id}');
      print('💾 [SAVE PIPELINE] Is Edition: ${widget.isEdition}');
      print('💾 [SAVE PIPELINE] Equipment ID: ${widget.coffret?.equipmentId}');
      print('💾 [SAVE PIPELINE] Type: $_selectedType | Nom: ${_nomController.text.trim()} | Repère: ${_repereController.text.trim()}');
      print('💾 [SAVE PIPELINE] Points de vérification count: ${_pointsVerification.length}');
      print('💾 [SAVE PIPELINE] Current Slide Step: $_currentStep');
    }

    for (var obs in _observationsParafoudre) {
      obs.priorite = null;
    }
    final evalCoffret = CoffretArmoire(
      qrCode: _qrCodeController.text.trim(),
      nom: _nomController.text.trim(),
      type: _selectedType!,
      indiceIpIk: _indiceIpIkController.text.trim().isEmpty ? null : _indiceIpIkController.text.trim(),
      indiceIpIkRepere: _resolveRepereIpIk().hasIpOrIk ? _resolveRepereIpIk().toString() : null,
      repere: _repereController.text.trim().isEmpty ? null : _repereController.text.trim(),
      pointsVerification: _pointsVerification,
    );
    IpIkEvaluatorService.syncIpIkPoint(
      coffret: evalCoffret,
      missionId: widget.mission.id,
      parentName: _getParentLocationName(),
    );
    try {
      final statut = _pointsValid ? 'complet' : (widget.coffret?.statut ?? 'incomplet');
      final nouveauCoffret = _buildCurrentCoffret(forcedStatut: statut);
      nouveauCoffret.currentStep = 0;

      if (kDebugMode) {
        print('💾 [SAVE PIPELINE] Model constructed successfully: ${nouveauCoffret.nom} (${nouveauCoffret.equipmentId})');
      }

      if (widget.isEdition && widget.coffret != null && widget.coffret!.nom != _nomController.text.trim()) await _transfererEssais(widget.coffret!.nom, _nomController.text.trim());
      bool success = false;
      if (widget.isEdition) success = await _updateCoffret(nouveauCoffret);
      else {
        if (widget.parentType == 'local') {
          if (widget.isMoyenneTension) {
            if (widget.isInZone && widget.zoneIndex != null) success = await _addCoffretToLocalInMoyenneTensionZone(nouveauCoffret);
            else success = await HiveService.addCoffretToMoyenneTensionLocal(missionId: widget.mission.id, localIndex: widget.parentIndex, coffret: nouveauCoffret, qrCode: widget.qrCode!);
          } else success = await HiveService.addCoffretToBasseTensionLocal(missionId: widget.mission.id, zoneIndex: widget.zoneIndex ?? 0, localIndex: widget.parentIndex, coffret: nouveauCoffret);
        } else {
          if (widget.isMoyenneTension) success = await HiveService.addCoffretToMoyenneTensionZone(missionId: widget.mission.id, zoneIndex: widget.parentIndex, coffret: nouveauCoffret);
          else success = await HiveService.addCoffretToBasseTensionZone(missionId: widget.mission.id, zoneIndex: widget.parentIndex, coffret: nouveauCoffret);
        }
      }

      if (kDebugMode) {
        print('💾 [SAVE PIPELINE] Operation success status: $success');
      }

      if (success) {
        // VÉRIFICATION FORENSIQUE POST-SAUVEGARDE (Read-back physique direct dans Hive)
        final verifiedCoffret = HiveService.findCoffretByIdOrQrCode(
          missionId: widget.mission.id,
          equipmentId: nouveauCoffret.equipmentId,
          qrCode: nouveauCoffret.qrCode,
        );
        if (verifiedCoffret == null) {
          if (kDebugMode) {
            print('❌ [READ-BACK VERIFICATION FAILED] Équipement ${nouveauCoffret.equipmentId} (${nouveauCoffret.nom}) introuvable dans Hive après sauvegarde !');
          }
          _showError('Erreur de persistance : la confirmation d\'écriture en base locale a échoué. Vos données restent dans le formulaire.');
          return;
        }

        await HiveService.deleteCoffretDraft(_draftQrCode ?? _qrCodeController.text.trim());
        if (widget.isEdition) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Équipement mis à jour avec succès'), backgroundColor: Colors.green));
          Navigator.pop(context, nouveauCoffret);
        } else {
          String localisation = '';
          final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
          if (widget.parentType == 'local') {
            if (widget.isMoyenneTension) {
              if (widget.isInZone && widget.zoneIndex != null && widget.zoneIndex! < audit.moyenneTensionZones.length) {
                final zone = audit.moyenneTensionZones[widget.zoneIndex!];
                if (widget.parentIndex < zone.locaux.length) localisation = zone.locaux[widget.parentIndex].nom;
              } else if (widget.parentIndex < audit.moyenneTensionLocaux.length) localisation = audit.moyenneTensionLocaux[widget.parentIndex].nom;
            } else if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
              final zone = audit.basseTensionZones[widget.zoneIndex!];
              if (widget.parentIndex < zone.locaux.length) localisation = zone.locaux[widget.parentIndex].nom;
            }
          } else {
            if (widget.isMoyenneTension && widget.parentIndex < audit.moyenneTensionZones.length) localisation = audit.moyenneTensionZones[widget.parentIndex].nom;
            else if (!widget.isMoyenneTension && widget.parentIndex < audit.basseTensionZones.length) localisation = audit.basseTensionZones[widget.parentIndex].nom;
          }
          final String repereEffective = (nouveauCoffret.repere != null && nouveauCoffret.repere!.trim().isNotEmpty)
              ? nouveauCoffret.repere!.trim()
              : (localisation.isNotEmpty ? localisation : 'Localisation non définie');

          // Synchronisation du nom et repère des essais liés à cet équipement
          try {
            final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();
            bool hasEssaisToUpdate = false;
            for (final es in mesures.essaisDeclenchement) {
              if (es.equipementId == nouveauCoffret.equipmentId) {
                if (es.coffret != nouveauCoffret.nom) {
                  es.coffret = nouveauCoffret.nom;
                  hasEssaisToUpdate = true;
                }
                if (es.localisation != repereEffective) {
                  es.localisation = repereEffective;
                  hasEssaisToUpdate = true;
                }
              }
            }
            if (hasEssaisToUpdate) {
              await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).saveMesures(mesures);
            }
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Équipement créé avec succès'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, nouveauCoffret);
        }
      } else {
        if (kDebugMode) {
          print('❌ [SAVE PIPELINE ERROR] Échec de la méthode de persistance (success == false)');
        }
        _showError('Erreur lors de la sauvegarde : Équipement non localisé ou rejeté par la persistance');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ [SAVE PIPELINE EXCEPTION] Exception attrapée dans _sauvegarder: $e');
        print(stack);
      }
      _showError('Erreur de sauvegarde : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter sans sauvegarder ?'),
        content: const Text('Les modifications non sauvegardées seront perdues.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Quitter')),
        ],
      ),
    );
  }

  Future<void> _handleExit() async {
    await flushAutoSave();
    if (widget.isEdition && widget.coffret != null) {
      if (_hasUnsavedChanges || _isAutoSavingNotifier.value) {
        await _autoSaveEdition();
      }
      if (mounted) {
        Navigator.pop(context, _buildCurrentCoffret());
      }
    } else {
      if (_hasUnsavedChanges) {
        _showExitConfirmation();
      } else {
        Navigator.pop(context);
      }
    }
  }
  
  Future<bool> _addCoffretToLocalInMoyenneTensionZone(CoffretArmoire coffret) async {
    try {
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      if (widget.zoneIndex != null && widget.zoneIndex! < audit.moyenneTensionZones.length) {
        final zone = audit.moyenneTensionZones[widget.zoneIndex!];
        if (widget.parentIndex < zone.locaux.length) { zone.locaux[widget.parentIndex].coffrets.add(coffret); await HiveService.saveAuditInstallations(audit); return true; }
      }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> _updateCoffret(CoffretArmoire newCoffret) async {
    try {
      if (widget.coffret != null) {
        newCoffret.id = widget.coffret!.equipmentId;
        if (kDebugMode) {
          print('💾 [SAVE PIPELINE] Attempting updateCoffretById for EquipmentId=${widget.coffret!.equipmentId}...');
        }
        final ok = await HiveService.updateCoffretById(
          missionId: widget.mission.id,
          equipmentId: widget.coffret!.equipmentId,
          updatedCoffret: newCoffret,
          oldNom: widget.coffret!.nom,
          allowClearDepartures: true,
          allowClearCircuits: true,
        );
        if (ok) {
          if (kDebugMode) {
            print('✅ [SAVE PIPELINE] updateCoffretById returned true!');
          }
          return true;
        }
        if (kDebugMode) {
          print('⚠️ [SAVE PIPELINE] updateCoffretById returned false. Falling back to container/index search...');
        }
      }
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      CoffretArmoire? target; bool found = false;
      if (widget.parentType == 'local') {
        if (widget.isMoyenneTension) {
          if (widget.isInZone && widget.zoneIndex != null && widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.parentIndex < zone.locaux.length && widget.coffretIndex! < zone.locaux[widget.parentIndex].coffrets.length) { target = zone.locaux[widget.parentIndex].coffrets[widget.coffretIndex!]; found = true; }
          } else if (widget.parentIndex < audit.moyenneTensionLocaux.length && widget.coffretIndex! < audit.moyenneTensionLocaux[widget.parentIndex].coffrets.length) { target = audit.moyenneTensionLocaux[widget.parentIndex].coffrets[widget.coffretIndex!]; found = true; }
        } else if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.parentIndex < zone.locaux.length && widget.coffretIndex! < zone.locaux[widget.parentIndex].coffrets.length) { target = zone.locaux[widget.parentIndex].coffrets[widget.coffretIndex!]; found = true; }
        }
      } else {
        if (widget.isMoyenneTension && widget.parentIndex < audit.moyenneTensionZones.length && widget.coffretIndex! < audit.moyenneTensionZones[widget.parentIndex].coffrets.length) { target = audit.moyenneTensionZones[widget.parentIndex].coffrets[widget.coffretIndex!]; found = true; }
        else if (!widget.isMoyenneTension && widget.parentIndex < audit.basseTensionZones.length && widget.coffretIndex! < audit.basseTensionZones[widget.parentIndex].coffretsDirects.length) { target = audit.basseTensionZones[widget.parentIndex].coffretsDirects[widget.coffretIndex!]; found = true; }
      }
      if (found && target != null) {
        if (widget.coffret != null && target.equipmentId != widget.coffret!.equipmentId) {
          if (kDebugMode) {
            print('ℹ️ [SAVE PIPELINE] Aligning target equipmentId with widget expected equipmentId (was ${target.equipmentId} -> now ${widget.coffret!.equipmentId})');
          }
        }
        target.id = newCoffret.equipmentId;
        target.createdAt = target.createdAt ?? newCoffret.createdAt;
        target.updatedAt = DateTime.now().toUtc();
        target.qrCode = newCoffret.qrCode;
        target.nom = newCoffret.nom;
        target.type = newCoffret.type;
        target.accessible = newCoffret.accessible;
        target.departPrisAvecProtection = newCoffret.departPrisAvecProtection;
        target.description = newCoffret.description;
        target.repere = newCoffret.repere;
        target.alimenteeParTransformateur = newCoffret.alimenteeParTransformateur;
        target.transformateurId = newCoffret.transformateurId;
        target.transformateurNomComplet = newCoffret.transformateurNomComplet;
        target.presenceCPI = (newCoffret.type == 'INVERSEUR') ? null : newCoffret.presenceCPI;
        target.zoneAtex = newCoffret.zoneAtex;
        target.domaineTension = newCoffret.domaineTension;
        target.identificationArmoire = newCoffret.identificationArmoire;
        target.signalisationDanger = newCoffret.signalisationDanger;
        target.presenceSchema = newCoffret.presenceSchema;
        target.presenceParafoudre = newCoffret.presenceParafoudre;
        target.verificationThermographie = newCoffret.verificationThermographie;
        target.presenceDefautThermo = newCoffret.presenceDefautThermo;
        target.indiceIpIk = newCoffret.indiceIpIk;
        target.departures = List.from(newCoffret.effectiveDepartures);
        target.terminalCircuits = List.from(newCoffret.effectiveTerminalCircuits);
        target.sourceEquipementId = newCoffret.sourceEquipementId;
        target.sourceNomComplet = newCoffret.sourceNomComplet;
        target.sourceDepartId = newCoffret.sourceDepartId;
        target.alimentations = newCoffret.alimentations;
        target.protectionTete = newCoffret.protectionTete;
        target.pointsVerification = newCoffret.pointsVerification;
        target.photos = newCoffret.photos;
        target.numeroEquipement = newCoffret.numeroEquipement;
        target.statut = newCoffret.statut;
        target.currentStep = newCoffret.currentStep;
        target.photosExternes = newCoffret.photosExternes;
        target.photosInternes = newCoffret.photosInternes;
        target.observationsLibres = newCoffret.observationsLibres;
        target.observationsParafoudre = newCoffret.observationsParafoudre;
        await PersistenceQueue.enqueue('audit_${widget.mission.id}', () async {
          await HiveService.saveAuditInstallations(audit, skipDescriptionSync: true);
        });
        return true;
      }
      if (kDebugMode) {
        print('❌ [SAVE PIPELINE] Equipment target not found in index search fallback');
      }
      return false;
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ [SAVE PIPELINE EXCEPTION] Exception in _updateCoffret: $e');
        print(stack);
      }
      rethrow;
    }
  }

  Future<void> _handleNext() async {
    await flushAutoSave();
    final lastStepIndex = _selectedType == 'INVERSEUR' ? 4 : 5;
    if (_currentStep == 0) {
      if (!_nomValid) { _showError('Veuillez saisir le nom de l\'équipement'); return; }
      if (!_typeValid) { _showError('Veuillez sélectionner le type d\'équipement'); return; }
      if (!_repereValid) { _showError('Veuillez saisir le repère'); return; }
      if (!_photosExterneValid) { _showError('La photo EXTERNE est obligatoire'); return; }
      if (!_photosInterneValid) { _showError('La photo INTERNE est obligatoire'); return; }
      _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentStep == 1) {
      if (_accessible == false) {
        _sauvegarder();
      } else {
        _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } else if (_currentStep == 2) {
      _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentStep == 3) {
      final alimState = _etapeAlimentationsKey?.currentState;
      if (alimState != null && alimState.nextSubSlide()) {
        setState(() {});
      } else {
        _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } else if (_currentStep == 4 && _selectedType != 'INVERSEUR') {
      final departsState = _etapeDepartsCircuitsKey?.currentState;
      if (departsState != null && departsState.nextSubSlide()) {
        setState(() {});
      } else {
        _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } else if (_currentStep == lastStepIndex) {
      final pointsState = _etapePointsKey?.currentState;
      if (pointsState != null) {
        if (pointsState.canGoNext()) _sauvegarder(isFinishing: true);
        else pointsState.nextSlide();
      } else {
        _sauvegarder(isFinishing: true);
      }
    }
  }

  Future<void> _handlePrevious() async {
    await flushAutoSave();
    final lastStepIndex = _selectedType == 'INVERSEUR' ? 4 : 5;
    if (_currentStep == 3) {
      final alimState = _etapeAlimentationsKey?.currentState;
      if (alimState != null && alimState.previousSubSlide()) {
        setState(() {});
      } else {
        _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } else if (_currentStep == 4 && _selectedType != 'INVERSEUR') {
      final departsState = _etapeDepartsCircuitsKey?.currentState;
      if (departsState != null && departsState.previousSubSlide()) {
        setState(() {});
      } else {
        _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } else if (_currentStep == lastStepIndex) {
      final pointsState = _etapePointsKey?.currentState;
      if (pointsState != null && pointsState._currentSlide > 0) pointsState.previousSlide();
      else _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentStep > 0) {
      _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  String _getNextButtonText() {
    final lastStepIndex = _selectedType == 'INVERSEUR' ? 4 : 5;
    if (_currentStep == 1 && _accessible == false) {
      return 'Enregistrer';
    }
    if (_currentStep == lastStepIndex) {
      final pointsState = _etapePointsKey?.currentState;
      if (pointsState != null && pointsState.canGoNext()) return 'Terminer';
      return 'Suivant';
    }
    return _currentStep == lastStepIndex ? 'Terminer' : 'Suivant';
  }

  void _onPresenceParafoudreChanged(bool? value) {
    setState(() { _presenceParafoudre = value ?? false; if (!_presenceParafoudre) _observationsParafoudre.clear(); });
    _saveDraft();
  }

  int _getTotalSteps() => _accessible ? (_selectedType == 'INVERSEUR' ? 5 : 6) : 2;

  Widget _buildSlideAccessibiliteEquipement() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accessibilité de l\'équipement',
            style: TextStyle(
              fontSize: context.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette information est requise avant de poursuivre l\'inspection.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          Text(
            'Cet équipement est-il accessible ?',
            style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAccessibiliteEquipementOption(
                  label: 'Oui',
                  icon: Icons.check_circle_outline,
                  selected: _accessible == true,
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      _accessible = true;
                    });
                    _saveDraft();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAccessibiliteEquipementOption(
                  label: 'Non',
                  icon: Icons.cancel_outlined,
                  selected: _accessible == false,
                  color: Colors.red,
                  onTap: () {
                    setState(() {
                      _accessible = false;
                    });
                    _saveDraft();
                  },
                ),
              ),
            ],
          ),
          if (_accessible == false) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'L\'équipement sera enregistré comme inaccessible et marqué "À revérifier". '
                      'Aucun point de vérification ne sera requis.',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessibiliteEquipementOption({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey.shade400, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToStep(int targetStep) {
    if (_isSaving) return;
    if (targetStep < 0 || targetStep >= _getTotalSteps()) return;
    if (targetStep == _currentStep) return;

    if (!widget.isEdition && targetStep > _currentStep) {
      if (_currentStep == 0) {
        if (!_nomValid) { _showError('Veuillez saisir le nom de l\'équipement'); return; }
        if (!_typeValid) { _showError('Veuillez sélectionner le type d\'équipement'); return; }
        if (!_repereValid) { _showError('Veuillez saisir le repère'); return; }
        if (!_photosExterneValid) { _showError('La photo EXTERNE est obligatoire'); return; }
        if (!_photosInterneValid) { _showError('La photo INTERNE est obligatoire'); return; }
      }
    }

    FocusScope.of(context).unfocus();

    if (_mainPageController.hasClients) {
      _mainPageController.animateToPage(
        targetStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildStepCircle(int index) {
    final isCurrent = index == _currentStep;
    final isCompleted = index < _currentStep;
    final isActive = index <= _currentStep;
    final canNavigate = widget.isEdition || index <= _currentStep;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canNavigate ? () => _navigateToStep(index) : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(2),
          child: Container(
            width: context.iconSizeL,
            height: context.iconSizeL,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppTheme.primaryBlue
                  : isCompleted
                      ? AppTheme.primaryBlue.withOpacity(0.85)
                      : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent
                    ? AppTheme.primaryBlue
                    : isCompleted
                        ? AppTheme.primaryBlue
                        : Colors.grey.shade400,
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted && !isCurrent
                  ? Icon(Icons.check, color: Colors.white, size: context.iconSizeS)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade600,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        fontSize: context.fontSizeS,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader(int totalSteps) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.spacingS,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int index = 0; index < totalSteps; index++) ...[
            _buildStepCircle(index),
            if (index < totalSteps - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: EdgeInsets.symmetric(horizontal: context.spacingXS),
                  color: index < _currentStep ? AppTheme.primaryBlue : Colors.grey.shade300,
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = _getTotalSteps();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit();
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(widget.isEdition ? 'Modifier l\'équipement' : 'Ajouter un équipement', style: TextStyle(fontSize: context.fontSizeL)),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleExit,
            ),
          actions: [
            if (widget.isEdition) ...[
              ValueListenableBuilder<bool>(
                valueListenable: _isAutoSavingNotifier,
                builder: (context, isAutoSaving, _) {
                  if (isAutoSaving) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    );
                  }
                  return ValueListenableBuilder<bool>(
                    valueListenable: _lastAutoSaveErrorNotifier,
                    builder: (context, lastError, _) {
                      if (lastError) {
                        return IconButton(
                          icon: const Icon(Icons.sync_problem, color: Colors.amber),
                          tooltip: 'Erreur de sauvegarde automatique - Cliquer pour réessayer',
                          onPressed: _autoSaveEdition,
                        );
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.0),
                        child: Center(
                          child: Icon(Icons.cloud_done, size: 18, color: Colors.white70),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(icon: const Icon(Icons.check), onPressed: _sauvegarder, tooltip: 'Enregistrer les modifications'),
            ],
          ],
        ),
        body: Column(
          children: [
            _buildStepperHeader(totalSteps),
            Expanded(
              child: PageView(
                controller: _mainPageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _EtapeInformationsBase(
                    nomController: _nomController,
                    numeroEquipementController: _numeroEquipementController,
                    repereController: _repereController,
                    selectedType: _selectedType,
                    onTypeChanged: _onTypeChanged,
                    typeValid: _typeValid,
                    nomValid: _nomValid,
                    numeroEquipementValid: _numeroEquipementValid,
                    repereValid: _repereValid,
                    onValidateNom: () => _validateNom(_nomController.text),
                    onValidateRepere: () => _validateRepere(_repereController.text),
                    onValidateNumeroEquipement: () => _validateNumeroEquipement(_numeroEquipementController.text),
                    photosExterne: _coffretPhotosExterne,
                    photosInterne: _coffretPhotosInterne,
                    onPrendrePhotoExterne: _prendrePhotoExterne,
                    onChoisirPhotoExterne: _choisirPhotoExterne,
                    onPrendrePhotoInterne: _prendrePhotoInterne,
                    onChoisirPhotoInterne: _choisirPhotoInterne,
                    isLoadingPhotosExterne: _isLoadingPhotosExterne,
                    isLoadingPhotosInterne: _isLoadingPhotosInterne,
                    onSupprimerPhotoExterne: _supprimerPhotoExterne,
                    onSupprimerPhotoInterne: _supprimerPhotoInterne,
                    isInZone: widget.isInZone,
                    addObservation: _addObservation,
                    onAddObservationChanged: (v) => setState(() => _addObservation = v),
                    observationController: _observationController,
                    observationPhotos: _observationPhotos,
                    observationsExistantes: _observationsLibresCoffret,
                    onPrendrePhotoObservation: _prendrePhotoObservation,
                    onChoisirPhotoObservation: _choisirPhotoObservation,
                    onAjouterObservation: _ajouterObservation,
                    onSupprimerObservation: (i) => setState(() => _observationsLibresCoffret.removeAt(i)),
                  ),
                  _buildSlideAccessibiliteEquipement(),
                  if (_selectedType != null && _accessible)
                    _EtapeInformationsGenerales(
                      equipmentType: _selectedType,
                      repereParsedIpIk: _resolveRepereIpIk(),
                      indiceIpIkController: _indiceIpIkController,
                      departuresCount: _departures.length,
                      terminalCircuitsCount: _terminalCircuits.length,
                      alimenteeParTransformateur: _alimenteeParTransformateur,
                      onAlimenteeParTransformateurChanged: (v) {
                        setState(() => _alimenteeParTransformateur = v);
                        _scheduleAutoSave();
                      },
                      transformateurId: _transformateurId,
                      transformateurNomComplet: _transformateurNomComplet,
                      onTransformateurChanged: (id, nom) {
                        setState(() {
                          _transformateurId = id;
                          _transformateurNomComplet = nom;
                        });
                        _scheduleAutoSave();
                      },
                      availableTransformateurs: _availableTransformateurs,
                      presenceCPI: _presenceCPI,
                      onPresenceCPIChanged: (v) {
                        setState(() => _presenceCPI = (_selectedType == 'INVERSEUR') ? null : v);
                        _scheduleAutoSave();
                      },
                      zoneAtex: _zoneAtex,
                      onZoneAtexChanged: (v) => setState(() => _zoneAtex = v ?? false),
                      identificationArmoire: _identificationArmoire,
                      onIdentificationArmoireChanged: (v) => setState(() => _identificationArmoire = v ?? false),
                      signalisationDanger: _signalisationDanger,
                      onSignalisationDangerChanged: (v) => setState(() => _signalisationDanger = v ?? false),
                      presenceSchema: _presenceSchema,
                      onPresenceSchemaChanged: (v) => setState(() => _presenceSchema = v ?? false),
                      presenceParafoudre: _presenceParafoudre,
                      onPresenceParafoudreChanged: _onPresenceParafoudreChanged,
                      verificationThermographie: _verificationThermographie,
                      onVerificationThermographieChanged: (v) {
                        final newVal = v ?? false;
                        setState(() {
                          _verificationThermographie = newVal;
                          if (newVal) {
                            _presenceDefautThermo ??= 'Non';
                          } else {
                            _presenceDefautThermo = null;
                          }
                        });
                      },
                      presenceDefautThermo: _presenceDefautThermo,
                      onPresenceDefautThermoChanged: (v) => setState(() => _presenceDefautThermo = v),
                      domaineTension: _domaineTension,
                      onDomaineTensionChanged: (v) { if (v != null && mounted) { setState(() { _domaineTension = v; _validateDomaineTension(v); }); } },
                      domaineTensionValid: _domaineTensionValid,
                      observationsParafoudre: _observationsParafoudre,
                      onAddParafoudreObservation: _addParafoudreObservation,
                      onDeleteParafoudreObservation: _deleteParafoudreObservation,
                      onSavePhoto: (file, section) async {
                        return await _savePhotoToAppDirectory(file, section);
                      },
                    ),
                  if (_selectedType != null && _accessible)
                    _EtapeAlimentations(
                      key: _etapeAlimentationsKey,
                      selectedType: _selectedType,
                      alimentations: _alimentations,
                      protectionTete: _protectionTete,
                      departPrisAvecProtection: _departPrisAvecProtection,
                      missionId: widget.mission.id,
                      currentEquipmentId: widget.coffret?.equipmentId ?? _draftEquipmentId,
                      equipmentNom: _nomController.text.trim().isNotEmpty ? _nomController.text.trim() : 'Équipement',
                      zoneName: _resolveCurrentLocation().zone,
                      repereName: _resolveCurrentLocation().repere,
                      sourceNomComplet: _sourceNomComplet,
                      sourceDepartId: _sourceDepartId,
                      onSourceSelected: (equipId, displayName, departId) {
                        setState(() {
                          _sourceEquipementId = equipId;
                          _sourceNomComplet = displayName;
                          _sourceDepartId = departId;
                        });
                        _scheduleAutoSave();
                      },
                      onDepartPrisAvecProtectionChanged: (val) {
                        setState(() {});
                        _scheduleAutoSave();
                      },
                      onDataChanged: () { _validateAlimentations(); setState(() {}); },
                      sourcesDisponibles: _getSourcesDisponibles(),
                      onAddSortie: _addSortieInverseur,
                      onDeleteSortie: _deleteSortieInverseur,
                    ),
                  if (_selectedType != null && _selectedType != 'INVERSEUR' && _accessible)
                    _EtapeDepartsEtCircuits(
                      key: _etapeDepartsCircuitsKey,
                      departures: _departures,
                      terminalCircuits: _terminalCircuits,
                      missionId: widget.mission.id,
                      currentEquipmentId: widget.coffret?.equipmentId ?? _draftEquipmentId,
                      equipmentNom: _nomController.text.trim().isNotEmpty ? _nomController.text.trim() : 'Équipement',
                      zoneName: _resolveCurrentLocation().zone,
                      repereName: _resolveCurrentLocation().repere,
                      equipmentType: _selectedType,
                      onDataChanged: () {
                        _hasUnsavedChanges = true;
                        _scheduleAutoSave();
                      },
                    ),
                  if (_selectedType != null && _pointsVerification.isNotEmpty && _accessible)
                    _EtapePointsVerification(
                      key: _etapePointsKey,
                      missionId: widget.mission.id,
                      isEdition: widget.isEdition,
                      pointsVerification: _pointsVerification,
                      pointSuggestions: _pointSuggestions,
                      pointLoading: _pointLoading,
                      hasObservation: _hasObservation,
                      onObservationChanged: _onPointObservationChanged,
                      onUseSuggestion: _onUsePointSuggestion,
                      onObservationToggleChanged: _onObservationToggleChanged,
                      onSavePhoto: _savePhotoToAppDirectory,
                      indiceIpIk: _indiceIpIkController.text.trim(),
                    ),
                ].whereType<Widget>().toList(),
              ),
            ),
            Container(
              padding: EdgeInsets.all(context.spacingL),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.spacingS, offset: const Offset(0, -2))]),
              child: Row(
                children: [
                  if (_currentStep > 0) Expanded(child: OutlinedButton(onPressed: _handlePrevious, style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: context.spacingM), side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS))), child: Text('Précédent', style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: Colors.grey.shade700)))),
                  if (_currentStep > 0) SizedBox(width: context.spacingM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: context.spacingM),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                        elevation: 2,
                      ),
                      child: Text(_getNextButtonText(), style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

List<String> _getSourcesDisponibles() {
  return ['Inverseur', 'Armoire', 'Coffret', 'TGBT'];
}

// ================================================================
// RECHERCHE DYNAMIQUE D'ÉQUIPEMENT SOURCE
// ================================================================
class _EquipmentSourceAutocompleteField extends StatefulWidget {
  final String label;
  final String initialText;
  final String missionId;
  final String? currentEquipmentId;
  final String? hintText;
  final String? defaultBadgeText;
  final Function(EquipmentSearchResult?) onSelected;
  final Function(String)? onTextChanged;

  const _EquipmentSourceAutocompleteField({
    required this.label,
    required this.initialText,
    required this.missionId,
    this.currentEquipmentId,
    this.hintText,
    this.defaultBadgeText,
    required this.onSelected,
    this.onTextChanged,
  });

  @override
  State<_EquipmentSourceAutocompleteField> createState() => _EquipmentSourceAutocompleteFieldState();
}

class _EquipmentSourceAutocompleteFieldState extends State<_EquipmentSourceAutocompleteField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<EquipmentSearchResult> _suggestions = [];
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    final initial = (widget.initialText == 'Inconnu' || widget.initialText == 'Source inconnue')
        ? ''
        : widget.initialText;
    _controller = TextEditingController(text: initial);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _showOverlay) {
      setState(() {
        _showOverlay = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _EquipmentSourceAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText) {
      final initial = (widget.initialText == 'Inconnu' || widget.initialText == 'Source inconnue')
          ? ''
          : widget.initialText;
      if (initial != _controller.text) {
        _controller.text = initial;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    final trimmed = query.trim();
    widget.onTextChanged?.call(trimmed);

    if (trimmed.isEmpty) {
      widget.onSelected(null);
      setState(() {
        _suggestions = [];
        _showOverlay = false;
      });
      return;
    }

    final results = EquipmentSourceSearchService.searchSources(
      missionId: widget.missionId,
      query: trimmed,
      excludeEquipmentId: widget.currentEquipmentId,
    );
    setState(() {
      _suggestions = results;
      _showOverlay = _focusNode.hasFocus && results.isNotEmpty;
    });
  }

  Color _getTypeBadgeColor(String type) {
    final upper = type.toUpperCase();
    if (upper.contains('TGBT')) return Colors.blue.shade700;
    if (upper.contains('ARMOIRE')) return Colors.indigo.shade700;
    if (upper.contains('COFFRET')) return Colors.teal.shade700;
    if (upper.contains('INVERSEUR')) return Colors.amber.shade900;
    return AppTheme.primaryBlue;
  }

  Color _getTypeBadgeBg(String type) {
    final upper = type.toUpperCase();
    if (upper.contains('TGBT')) return Colors.blue.shade50;
    if (upper.contains('ARMOIRE')) return Colors.indigo.shade50;
    if (upper.contains('COFFRET')) return Colors.teal.shade50;
    if (upper.contains('INVERSEUR')) return Colors.amber.shade50;
    return Colors.grey.shade100;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _controller.text.trim().isEmpty;

    return TapRegion(
      onTapOutside: (_) {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
        if (_showOverlay) {
          setState(() {
            _showOverlay = false;
          });
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: context.fontSizeS,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
              if (isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        widget.defaultBadgeText ?? 'Source inconnue (par défaut)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focusNode.hasFocus ? AppTheme.primaryBlue : Colors.grey.shade300,
                width: _focusNode.hasFocus ? 1.8 : 1,
              ),
              boxShadow: _focusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Rechercher la source (laisser vide si inconnue)...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _focusNode.hasFocus ? AppTheme.primaryBlue : Colors.grey.shade400,
                ),
                suffixIcon: !isEmpty
                    ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.black54),
                        ),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: TextStyle(
                fontSize: context.fontSizeM,
                color: AppTheme.darkBlue,
                fontWeight: FontWeight.w600,
              ),
              onChanged: _onQueryChanged,
              onTap: () {
                if (_controller.text.trim().isNotEmpty) {
                  _onQueryChanged(_controller.text);
                }
              },
            ),
          ),

          // LISTE RHO/SUGGESTIONS MODERNES EN OVERLAY FLOTTANT
          if (_showOverlay && _suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 230),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    final badgeBg = _getTypeBadgeBg(item.type);
                    final badgeColor = _getTypeBadgeColor(item.type);

                    return InkWell(
                      onTap: () {
                        _controller.text = item.displayName;
                        widget.onSelected(item);
                        widget.onTextChanged?.call(item.displayName);
                        _focusNode.unfocus();
                        setState(() {
                          _showOverlay = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: badgeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nom,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.darkBlue,
                                    ),
                                  ),
                                  if (item.localisation != null && item.localisation!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            item.localisation!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// SLIDE 5 : IDENTIFICATION DES DÉPARTS ET CIRCUITS TERMINAUX
// ================================================================
class _EtapeDepartsEtCircuits extends StatefulWidget {
  final List<DepartEquipement> departures;
  final List<CircuitTerminalEquipement> terminalCircuits;
  final String missionId;
  final String? currentEquipmentId;
  final String? equipmentType;
  final String? equipmentNom;
  final String? zoneName;
  final String? repereName;
  final VoidCallback onDataChanged;

  const _EtapeDepartsEtCircuits({
    super.key,
    required this.departures,
    required this.terminalCircuits,
    required this.missionId,
    this.currentEquipmentId,
    this.equipmentType,
    this.equipmentNom,
    this.zoneName,
    this.repereName,
    required this.onDataChanged,
  });

  @override
  State<_EtapeDepartsEtCircuits> createState() => _EtapeDepartsEtCircuitsState();
}

class _EtapeDepartsEtCircuitsState extends State<_EtapeDepartsEtCircuits> {
  int _currentSubSlide = 0; // 0: Départs, 1: Circuits Terminaux
  String? _expandedDepartId;
  String? _expandedCircuitId;

  String _getEquipmentGrammarDu() {
    final t = (widget.equipmentType ?? '').trim().toUpperCase();
    if (t == 'TGBT') {
      return 'DU TGBT';
    } else if (t == 'ARMOIRE') {
      return "DE L'ARMOIRE";
    } else if (t == 'COFFRET') {
      return 'DU COFFRET';
    } else if (t == 'INVERSEUR') {
      return "DE L'INVERSEUR";
    }
    return "DE CET ÉQUIPEMENT";
  }

  int get currentSubSlide => _currentSubSlide;

  @override
  void initState() {
    super.initState();
    // Par défaut, à l'ouverture du Slide 5, toutes les cartes sont fermées (collapsed)
    _expandedDepartId = null;
    _expandedCircuitId = null;
  }

  bool nextSubSlide() {
    if (_currentSubSlide == 0) {
      setState(() {
        _currentSubSlide = 1;
      });
      return true;
    }
    return false;
  }

  bool previousSubSlide() {
    if (_currentSubSlide == 1) {
      setState(() {
        _currentSubSlide = 0;
      });
      return true;
    }
    return false;
  }

  static const List<String> _typeProtectionOptions = [
    'Disjoncteur',
    'Sectionneur',
    'Interrupteur',
    'Interrupteur sectionneur',
    'Interrupteur différentiel',
    'Disjoncteur différentiel',
    'Sectionneur porte-fusible',
    'Coupe-circuit(porte-fusible)',
  ];

  static const List<String> _marqueOptions = [
    'ABB',
    'C&S Electric',
    'Chint',
    'Eaton',
    'Fuji Electric',
    'Gewiss',
    'Hager',
    'Hyundai Electric',
    'LS Electric',
    'Legrand',
    'Lovato Electric',
    'Mitsubishi Electric',
    'Noark',
    'Schneider Electric',
    'Schrack Technik',
    'Siemens',
    'Socomec',
    'TOMZN',
    'Terasaki',
    'Inconnu',
  ];

  static const List<String> _courbeOptions = [
    'Courbe-B',
    'Courbe-C',
    'Courbe-D',
    'Courbe-K',
    'Courbe-Z',
    'Courbe-MA',
  ];

  static const List<String> _ddrOptions = [
    '10',
    '30',
    '100',
    '300',
    '500',
  ];

  static const List<String> _sectionCableOptions = [
    '1.5 mm²', '2.5 mm²', '4 mm²', '6 mm²', '10 mm²', '16 mm²',
    '25 mm²', '35 mm²', '50 mm²', '70 mm²', '95 mm²', '120 mm²',
    '150 mm²', '185 mm²', '240 mm²', '300 mm²',
  ];

  static const List<String> _natureCableOptions = [
    'Cuivre',
    'Aluminium',
  ];

  Future<void> _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.fontSizeM, color: AppTheme.darkBlue),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: Colors.grey.shade700, fontSize: context.fontSizeS),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
    required Color color,
    required String buttonLabel,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_tree_outlined, size: 36, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: context.fontSizeM,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: context.fontSizeS,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 20),
            label: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDepartSubSlide = _currentSubSlide == 0;
    final int listLength = isDepartSubSlide ? widget.departures.length : widget.terminalCircuits.length;
    final bool isEmpty = listLength == 0;
    final int totalItemCount = isEmpty ? 2 : listLength + 2;

    return ListView.builder(
      padding: EdgeInsets.all(context.spacingL),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(
                context,
                isDepartSubSlide
                    ? 'Identification des Départs'
                    : 'Identification des Circuits Terminaux',
                5,
                6,
              ),
              SizedBox(height: context.spacingM),

              // BARRE D'ONGLETS / SOUS-SLIDES DÉDIÉS
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentSubSlide = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _currentSubSlide == 0 ? AppTheme.primaryBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _currentSubSlide == 0
                                ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '1. Départs (${widget.departures.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: context.fontSizeS,
                                color: _currentSubSlide == 0 ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentSubSlide = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _currentSubSlide == 1 ? Colors.teal.shade700 : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _currentSubSlide == 1
                                ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '2. Circuits (${widget.terminalCircuits.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: context.fontSizeS,
                                color: _currentSubSlide == 1 ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.spacingL),

              if (isDepartSubSlide)
                _buildSectionHeader(
                  context,
                  title: 'IDENTIFICATION DES DÉPARTS ISSUS ${_getEquipmentGrammarDu()}',
                  count: widget.departures.length,
                  color: Colors.blue.shade800,
                )
              else
                _buildSectionHeader(
                  context,
                  title: 'IDENTIFICATION DES CIRCUITS TERMINAUX ISSUS ${_getEquipmentGrammarDu()}',
                  count: widget.terminalCircuits.length,
                  color: Colors.teal.shade800,
                ),
              SizedBox(height: context.spacingM),
            ],
          );
        }

        if (isEmpty && index == 1) {
          if (isDepartSubSlide) {
            return _buildEmptyState(
              context,
              title: 'Aucun départ enregistré',
              subtitle: 'Ajoutez les départs électriques issus de cet équipement pour documenter votre inspection.',
              color: Colors.blue.shade800,
              buttonLabel: '+ Ajouter un départ',
              onAdd: () {
                final newDepart = DepartEquipement(identification: '');
                setState(() {
                  widget.departures.add(newDepart);
                  _expandedDepartId = newDepart.id;
                });
                widget.onDataChanged();
              },
            );
          } else {
            return _buildEmptyState(
              context,
              title: 'Aucun circuit terminal enregistré',
              subtitle: 'Ajoutez les circuits terminaux issus de cet équipement pour documenter votre inspection.',
              color: Colors.teal.shade800,
              buttonLabel: '+ Ajouter un circuit terminal',
              onAdd: () {
                final newCircuit = CircuitTerminalEquipement(identification: '');
                setState(() {
                  widget.terminalCircuits.add(newCircuit);
                  _expandedCircuitId = newCircuit.id;
                });
                widget.onDataChanged();
              },
            );
          }
        }

        if (index == listLength + 1) {
          return Column(
            children: [
              SizedBox(height: context.spacingS),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (isDepartSubSlide) {
                      final newDepart = DepartEquipement(identification: '');
                      setState(() {
                        widget.departures.add(newDepart);
                        _expandedDepartId = newDepart.id;
                      });
                    } else {
                      final newCircuit = CircuitTerminalEquipement(identification: '');
                      setState(() {
                        widget.terminalCircuits.add(newCircuit);
                        _expandedCircuitId = newCircuit.id;
                      });
                    }
                    widget.onDataChanged();
                  },
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: isDepartSubSlide ? AppTheme.primaryBlue : Colors.teal,
                  ),
                  label: Text(
                    isDepartSubSlide ? '+ Ajouter un départ' : '+ Ajouter un circuit terminal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDepartSubSlide ? AppTheme.primaryBlue : Colors.teal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: BorderSide(
                      color: isDepartSubSlide ? AppTheme.primaryBlue : Colors.teal,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              SizedBox(height: context.spacingXXL),
            ],
          );
        }

        final itemIndex = index - 1;
        if (isDepartSubSlide) {
          return Padding(
            padding: EdgeInsets.only(bottom: context.spacingM),
            child: _buildDepartCard(context, widget.departures[itemIndex], itemIndex),
          );
        } else {
          return Padding(
            padding: EdgeInsets.only(bottom: context.spacingM),
            child: _buildTerminalCircuitCard(context, widget.terminalCircuits[itemIndex], itemIndex),
          );
        }
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required int count, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: context.fontSizeS,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartCard(BuildContext context, DepartEquipement dep, int index) {
    if (dep.id.trim().isEmpty) {
      dep.id = 'dep_${widget.currentEquipmentId ?? "equip"}_${index}_${DateTime.now().millisecondsSinceEpoch}';
    }
    final isExpanded = _expandedDepartId == dep.id;
    final bool isEligible = EssaiDeclenchementHelper.isEligibleForEssai(typeProtection: dep.typeProtection, ddr: dep.ddr);
    final circuitDesignation = dep.identification.trim().isNotEmpty ? dep.identification.trim() : 'Départ ${index + 1}';
    final mesures = HiveService.getMesuresEssaisByMissionId(widget.missionId);
    final hasEssai = isEligible && (mesures?.essaisDeclenchement.any((e) =>
        EssaiDeclenchementHelper.isSameBlock(
          essai: e,
          targetElementId: dep.id,
          equipementId: widget.currentEquipmentId,
          precision: EssaiDeclenchementHelper.precisionDepart,
          circuitName: circuitDesignation,
        )) ?? false);

    final typeProtItems = [..._typeProtectionOptions];
    if (dep.typeProtection.isNotEmpty && !typeProtItems.contains(dep.typeProtection)) {
      typeProtItems.insert(0, dep.typeProtection);
    }
    final marqueItems = [..._marqueOptions];
    if (dep.marque.isNotEmpty && !marqueItems.contains(dep.marque)) {
      marqueItems.insert(0, dep.marque);
    }
    final courbeItems = [..._courbeOptions];
    if (dep.courbe.isNotEmpty && !courbeItems.contains(dep.courbe)) {
      courbeItems.insert(0, dep.courbe);
    }
    final ddrItems = [..._ddrOptions];
    if (dep.ddr.isNotEmpty && !ddrItems.contains(dep.ddr)) {
      ddrItems.insert(0, dep.ddr);
    }

    // Préparation des badges de résumé pour la carte fermée
    final summarySpecs = [
      if (dep.typeProtection.isNotEmpty) dep.typeProtection,
      if (dep.calibre.isNotEmpty) '${dep.calibre}A',
      if (dep.courbe.isNotEmpty) dep.courbe,
      if (dep.pdcKA.isNotEmpty) '${dep.pdcKA}kA',
    ].join(' • ');

    final cableSpecs = [
      if (dep.sectionCable.isNotEmpty) 'Phase: ${dep.sectionCable}',
      if (dep.effectiveSectionCableNeutre.isNotEmpty && dep.sectionCableNeutre != null) 'Neutre: ${dep.effectiveSectionCableNeutre}',
      if (dep.nombreCables != null && dep.nombreCables!.isNotEmpty) 'Nbr: ${dep.nombreCables}',
    ].join(' | ');

    return Container(
      key: ValueKey(dep.id),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? AppTheme.primaryBlue.withOpacity(0.5) : Colors.grey.shade200,
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? AppTheme.primaryBlue.withOpacity(0.06) : Colors.black.withOpacity(0.02),
            blurRadius: isExpanded ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN-TÊTE COMPACTÉ / ACCORDÉON
          InkWell(
            onTap: () {
              setState(() {
                _expandedDepartId = isExpanded ? null : dep.id;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Départ ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: context.fontSizeS,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dep.identification.isNotEmpty ? dep.identification : 'Sans identification',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: context.fontSizeS,
                            color: dep.identification.isNotEmpty ? AppTheme.darkBlue : Colors.grey.shade400,
                            fontStyle: dep.identification.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isExpanded ? Icons.edit_note : Icons.edit_outlined,
                              color: isExpanded ? AppTheme.primaryBlue : Colors.grey.shade600,
                              size: 20,
                            ),
                            tooltip: 'Modifier',
                            onPressed: () {
                              setState(() {
                                _expandedDepartId = isExpanded ? null : dep.id;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            tooltip: 'Supprimer',
                            onPressed: () {
                              _confirmDelete(
                                context,
                                title: 'Supprimer ce départ ?',
                                message: 'Cette action supprimera définitivement les informations saisies pour le Départ ${index + 1}.',
                                onConfirm: () {
                                  final deletedId = dep.id;
                                  setState(() {
                                    widget.departures.removeWhere((d) => d.id == dep.id);
                                    if (_expandedDepartId == dep.id) {
                                      _expandedDepartId = null;
                                    }
                                  });
                                  if (deletedId.trim().isNotEmpty) {
                                    HiveService.cleanupOrphanDepartSources(widget.missionId, deletedId);
                                  }
                                  widget.onDataChanged();
                                },
                              );
                            },
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isExpanded && (summarySpecs.isNotEmpty || cableSpecs.isNotEmpty || isEligible)) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (hasEssai)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Essai réalisé',
                                  style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        else if (isEligible)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.speed, size: 12, color: AppTheme.primaryBlue),
                                const SizedBox(width: 4),
                                Text(
                                  'Essai différentiel (${dep.ddr} mA)',
                                  style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        if (summarySpecs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              summarySpecs,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                            ),
                          ),
                        if (cableSpecs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              cableSpecs,
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // CONTENU DÉPLIÉ DU FORMULAIRE
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protection de tête du départ :',
                        style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Présent')),
                              selected: dep.protectionTete == 'Présent',
                              selectedColor: Colors.green.shade100,
                              onSelected: (sel) {
                                setState(() { dep.protectionTete = sel ? 'Présent' : 'Absent'; });
                                widget.onDataChanged();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Absent')),
                              selected: dep.protectionTete == 'Absent',
                              selectedColor: Colors.red.shade100,
                              onSelected: (sel) {
                                setState(() { dep.protectionTete = sel ? 'Absent' : 'Présent'; });
                                widget.onDataChanged();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: dep.identification,
                    decoration: InputDecoration(
                      labelText: 'Identification du départ',
                      hintText: 'Ex: Départ éclairage atelier',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade700),
                    ),
                    style: TextStyle(fontSize: context.fontSizeS),
                    onChanged: (v) {
                      dep.identification = v;
                      widget.onDataChanged();
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: dep.typeProtection.isNotEmpty ? dep.typeProtection : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Type de protection', isDense: true, border: OutlineInputBorder()),
                    items: typeProtItems.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) { setState(() { dep.typeProtection = v ?? ''; }); widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: dep.marque.isNotEmpty ? dep.marque : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Marque', isDense: true, border: OutlineInputBorder()),
                    items: marqueItems.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) { setState(() { dep.marque = v ?? ''; }); widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: dep.courbe.isNotEmpty ? dep.courbe : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Courbe', isDense: true, border: OutlineInputBorder()),
                    items: courbeItems.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) { setState(() { dep.courbe = v ?? ''; }); widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: dep.pdcKA,
                    decoration: const InputDecoration(labelText: 'PDC (kA)', suffixText: 'kA', isDense: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) { dep.pdcKA = v; widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: dep.icc3Max,
                    decoration: const InputDecoration(labelText: 'Icc3 max (kA)', suffixText: 'kA', isDense: true, border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))],
                    onChanged: (v) { dep.icc3Max = v; widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: dep.calibre,
                    decoration: const InputDecoration(labelText: 'Calibre (A)', suffixText: 'A', isDense: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) { dep.calibre = v; widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  Builder(
                    builder: (context) {
                      final bool isDdrAllowed = EssaiDeclenchementHelper.isDdrApplicable(dep.typeProtection);
                      return DropdownButtonFormField<String>(
                        value: dep.ddr.isNotEmpty ? dep.ddr : null,
                        isExpanded: true,
                        icon: Icon(
                          isDdrAllowed ? Icons.arrow_drop_down : Icons.block,
                          color: isDdrAllowed ? Colors.grey.shade700 : Colors.grey.shade400,
                          size: isDdrAllowed ? 24 : 16,
                        ),
                        decoration: InputDecoration(
                          labelText: isDdrAllowed ? 'DDR IΔn (mA)' : 'DDR IΔn (mA) — Non applicable',
                          labelStyle: TextStyle(
                            fontSize: context.fontSizeS,
                            color: isDdrAllowed ? Colors.grey.shade700 : Colors.grey.shade400,
                          ),
                          hintText: !isDdrAllowed ? 'Non applicable (Non différentiel)' : null,
                          isDense: true,
                          border: const OutlineInputBorder(),
                          filled: !isDdrAllowed,
                          fillColor: !isDdrAllowed ? Colors.grey.shade100 : null,
                        ),
                        items: ddrItems.map((e) => DropdownMenuItem(value: e, child: Text('$e mA', overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: isDdrAllowed ? (v) { setState(() { dep.ddr = v ?? ''; }); widget.onDataChanged(); } : null,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: dep.sectionCable.isNotEmpty ? dep.sectionCable : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Section de câble phase (mm²)', isDense: true, border: OutlineInputBorder()),
                    items: _sectionCableOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      setState(() {
                        dep.sectionCable = v ?? '';
                        if (dep.sectionCable.trim().isNotEmpty && dep.sectionCable.trim() != '-') {
                          dep.conducteursPhase ??= 1;
                        } else {
                          dep.conducteursPhase = null;
                        }
                      });
                      widget.onDataChanged();
                    },
                  ),
                  if (dep.sectionCable.trim().isNotEmpty && dep.sectionCable.trim() != '-') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: ValueKey('dep_${dep.id}_cond_phase_${dep.conducteursPhase}'),
                      initialValue: (dep.conducteursPhase ?? 1).toString(),
                      decoration: const InputDecoration(
                        labelText: 'Nombre de conducteurs phase',
                        hintText: 'Ex: 1, 2, 3...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        dep.conducteursPhase = int.tryParse(v.trim());
                        widget.onDataChanged();
                      },
                    ),
                  ],
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: dep.effectiveSectionCableNeutre.isNotEmpty ? dep.effectiveSectionCableNeutre : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Section de câble neutre (mm²)', isDense: true, border: OutlineInputBorder()),
                    items: _sectionCableOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      setState(() {
                        dep.sectionCableNeutre = v ?? '';
                        if (dep.sectionCableNeutre!.trim().isNotEmpty && dep.sectionCableNeutre!.trim() != '-') {
                          dep.conducteursNeutre ??= 1;
                        } else {
                          dep.conducteursNeutre = null;
                        }
                      });
                      widget.onDataChanged();
                    },
                  ),
                  if (dep.effectiveSectionCableNeutre.trim().isNotEmpty && dep.effectiveSectionCableNeutre.trim() != '-') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: ValueKey('dep_${dep.id}_cond_neutre_${dep.conducteursNeutre}'),
                      initialValue: (dep.conducteursNeutre ?? 1).toString(),
                      decoration: const InputDecoration(
                        labelText: 'Nombre de conducteurs neutre',
                        hintText: 'Ex: 1, 2, 3...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        dep.conducteursNeutre = int.tryParse(v.trim());
                        widget.onDataChanged();
                      },
                    ),
                  ],
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: dep.natureCable != null && dep.natureCable!.isNotEmpty ? dep.natureCable : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Nature du câble', isDense: true, border: OutlineInputBorder()),
                    items: _natureCableOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      setState(() {
                        dep.natureCable = v ?? '';
                      });
                      widget.onDataChanged();
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    key: ValueKey('dep_${dep.id}_nb_cables_${dep.effectiveNombreCables}'),
                    initialValue: dep.effectiveNombreCables ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Nombre de câble',
                      hintText: 'Ex: 1, 2, 3...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final trimmed = v.trim();
                      dep.nombreCables = trimmed.isEmpty ? null : trimmed;
                      final parsed = int.tryParse(trimmed);
                      if (parsed != null && parsed > 0) {
                        dep.conducteursPhase = parsed;
                      } else if (trimmed.isEmpty) {
                        dep.conducteursPhase = (dep.sectionCable.trim().isNotEmpty && dep.sectionCable.trim() != '-') ? 1 : null;
                      }
                      widget.onDataChanged();
                    },
                  ),
                  if (isEligible) ...[
                    const SizedBox(height: 16),
                    buildEssaiDeclenchementButton(
                      context: context,
                      missionId: widget.missionId,
                      elementId: dep.id,
                      equipementId: widget.currentEquipmentId ?? '',
                      circuitName: circuitDesignation,
                      zone: widget.zoneName ?? '',
                      repere: widget.repereName ?? '',
                      designation: widget.equipmentNom ?? 'Équipement',
                      precision: EssaiDeclenchementHelper.precisionDepart,
                      typeDispositif: dep.typeProtection,
                      calibre: dep.calibre,
                      ddr: dep.ddr,
                      onEssaiChanged: () => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalCircuitCard(BuildContext context, CircuitTerminalEquipement ct, int index) {
    if (ct.id.trim().isEmpty) {
      ct.id = 'ct_${widget.currentEquipmentId ?? "equip"}_${index}_${DateTime.now().millisecondsSinceEpoch}';
    }
    final isExpanded = _expandedCircuitId == ct.id;
    final bool isEligible = EssaiDeclenchementHelper.isEligibleForEssai(typeProtection: ct.typeProtection, ddr: ct.ddr);
    final circuitDesignation = ct.identification.trim().isNotEmpty ? ct.identification.trim() : 'Circuit ${index + 1}';
    final mesures = HiveService.getMesuresEssaisByMissionId(widget.missionId);
    final hasEssai = isEligible && (mesures?.essaisDeclenchement.any((e) =>
        EssaiDeclenchementHelper.isSameBlock(
          essai: e,
          targetElementId: ct.id,
          equipementId: widget.currentEquipmentId,
          precision: EssaiDeclenchementHelper.precisionCircuit,
          circuitName: circuitDesignation,
        )) ?? false);

    final typeProtItems = [..._typeProtectionOptions];
    if (ct.typeProtection.isNotEmpty && !typeProtItems.contains(ct.typeProtection)) {
      typeProtItems.insert(0, ct.typeProtection);
    }
    final marqueItems = [..._marqueOptions];
    if (ct.marque.isNotEmpty && !marqueItems.contains(ct.marque)) {
      marqueItems.insert(0, ct.marque);
    }
    final courbeItems = [..._courbeOptions];
    if (ct.courbe.isNotEmpty && !courbeItems.contains(ct.courbe)) {
      courbeItems.insert(0, ct.courbe);
    }
    final ddrItems = [..._ddrOptions];
    if (ct.ddr.isNotEmpty && !ddrItems.contains(ct.ddr)) {
      ddrItems.insert(0, ct.ddr);
    }

    final summarySpecs = [
      if (ct.typeProtection.isNotEmpty) ct.typeProtection,
      if (ct.calibre.isNotEmpty) '${ct.calibre}A',
      if (ct.courbe.isNotEmpty) ct.courbe,
      if (ct.pdcKA.isNotEmpty) '${ct.pdcKA}kA',
    ].join(' • ');

    final cableSpecs = [
      if (ct.sectionCable.isNotEmpty) 'Phase: ${ct.sectionCable}',
      if (ct.effectiveSectionCableNeutre.isNotEmpty && ct.sectionCableNeutre != null) 'Neutre: ${ct.effectiveSectionCableNeutre}',
      if (ct.nombreCables != null && ct.nombreCables!.isNotEmpty) 'Nbr: ${ct.nombreCables}',
    ].join(' | ');

    return Container(
      key: ValueKey(ct.id),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? Colors.teal.shade700.withOpacity(0.5) : Colors.grey.shade200,
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? Colors.teal.shade700.withOpacity(0.06) : Colors.black.withOpacity(0.02),
            blurRadius: isExpanded ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN-TÊTE COMPACTÉ / ACCORDÉON
          InkWell(
            onTap: () {
              setState(() {
                _expandedCircuitId = isExpanded ? null : ct.id;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Circuit ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: context.fontSizeS,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ct.identification.isNotEmpty ? ct.identification : 'Sans identification',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: context.fontSizeS,
                            color: ct.identification.isNotEmpty ? AppTheme.darkBlue : Colors.grey.shade400,
                            fontStyle: ct.identification.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isExpanded ? Icons.edit_note : Icons.edit_outlined,
                              color: isExpanded ? Colors.teal.shade700 : Colors.grey.shade600,
                              size: 20,
                            ),
                            tooltip: 'Modifier',
                            onPressed: () {
                              setState(() {
                                _expandedCircuitId = isExpanded ? null : ct.id;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            tooltip: 'Supprimer',
                            onPressed: () {
                              _confirmDelete(
                                context,
                                title: 'Supprimer ce circuit ?',
                                message: 'Cette action supprimera définitivement les informations saisies pour le Circuit ${index + 1}.',
                                onConfirm: () {
                                  setState(() {
                                    widget.terminalCircuits.removeWhere((c) => c.id == ct.id);
                                    if (_expandedCircuitId == ct.id) {
                                      _expandedCircuitId = null;
                                    }
                                  });
                                  widget.onDataChanged();
                                },
                              );
                            },
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isExpanded && (summarySpecs.isNotEmpty || cableSpecs.isNotEmpty || isEligible)) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (hasEssai)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Essai réalisé',
                                  style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        else if (isEligible)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.teal.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.speed, size: 12, color: Colors.teal.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Essai différentiel (${ct.ddr} mA)',
                                  style: TextStyle(fontSize: 11, color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        if (summarySpecs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              summarySpecs,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                            ),
                          ),
                        if (cableSpecs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Text(
                              cableSpecs,
                              style: TextStyle(fontSize: 11, color: Colors.teal.shade900, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // CONTENU DÉPLIÉ DU FORMULAIRE
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Circuit terminal de tête :',
                        style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Oui')),
                              selected: ct.protectionTete == 'Oui' || ct.protectionTete == 'Présent',
                              selectedColor: Colors.green.shade100,
                              onSelected: (sel) {
                                setState(() { ct.protectionTete = sel ? 'Oui' : 'Non'; });
                                widget.onDataChanged();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Non')),
                              selected: ct.protectionTete == 'Non' || ct.protectionTete == 'Absent',
                              selectedColor: Colors.red.shade100,
                              onSelected: (sel) {
                                setState(() { ct.protectionTete = sel ? 'Non' : 'Oui'; });
                                widget.onDataChanged();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _HybridCircuitIdentificationField(
                    initialValue: ct.identification,
                    onChanged: (v) {
                      ct.identification = v;
                      widget.onDataChanged();
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: ct.typeProtection.isNotEmpty ? ct.typeProtection : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Type de protection', isDense: true, border: OutlineInputBorder()),
                    items: typeProtItems.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) { setState(() { ct.typeProtection = v ?? ''; }); widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: ct.marque.isNotEmpty ? ct.marque : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Marque', isDense: true, border: OutlineInputBorder()),
                    items: marqueItems.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) { setState(() { ct.marque = v ?? ''; }); widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: ct.courbe.isNotEmpty ? ct.courbe : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Courbe', isDense: true, border: OutlineInputBorder()),
                    items: courbeItems.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) { setState(() { ct.courbe = v ?? ''; }); widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: ct.pdcKA,
                    decoration: const InputDecoration(labelText: 'PDC (kA)', suffixText: 'kA', isDense: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) { ct.pdcKA = v; widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: ct.icc3Max,
                    decoration: const InputDecoration(labelText: 'Icc3 max (kA)', suffixText: 'kA', isDense: true, border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))],
                    onChanged: (v) { ct.icc3Max = v; widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: ct.calibre,
                    decoration: const InputDecoration(labelText: 'Calibre (A)', suffixText: 'A', isDense: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) { ct.calibre = v; widget.onDataChanged(); },
                  ),
                  const SizedBox(height: 12),

                  Builder(
                    builder: (context) {
                      final bool isDdrAllowed = EssaiDeclenchementHelper.isDdrApplicable(ct.typeProtection);
                      return DropdownButtonFormField<String>(
                        value: ct.ddr.isNotEmpty ? ct.ddr : null,
                        isExpanded: true,
                        icon: Icon(
                          isDdrAllowed ? Icons.arrow_drop_down : Icons.block,
                          color: isDdrAllowed ? Colors.grey.shade700 : Colors.grey.shade400,
                          size: isDdrAllowed ? 24 : 16,
                        ),
                        decoration: InputDecoration(
                          labelText: isDdrAllowed ? 'DDR IΔn (mA)' : 'DDR IΔn (mA) — Non applicable',
                          labelStyle: TextStyle(
                            fontSize: context.fontSizeS,
                            color: isDdrAllowed ? Colors.grey.shade700 : Colors.grey.shade400,
                          ),
                          hintText: !isDdrAllowed ? 'Non applicable (Non différentiel)' : null,
                          isDense: true,
                          border: const OutlineInputBorder(),
                          filled: !isDdrAllowed,
                          fillColor: !isDdrAllowed ? Colors.grey.shade100 : null,
                        ),
                        items: ddrItems.map((e) => DropdownMenuItem(value: e, child: Text('$e mA', overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: isDdrAllowed ? (v) { setState(() { ct.ddr = v ?? ''; }); widget.onDataChanged(); } : null,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: ct.sectionCable.isNotEmpty ? ct.sectionCable : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Section de câble phase (mm²)', isDense: true, border: OutlineInputBorder()),
                    items: _sectionCableOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      setState(() {
                        ct.sectionCable = v ?? '';
                        if (ct.sectionCable.trim().isNotEmpty && ct.sectionCable.trim() != '-') {
                          ct.conducteursPhase ??= 1;
                        } else {
                          ct.conducteursPhase = null;
                        }
                      });
                      widget.onDataChanged();
                    },
                  ),
                  if (ct.sectionCable.trim().isNotEmpty && ct.sectionCable.trim() != '-') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: ValueKey('ct_${ct.id}_cond_phase_${ct.conducteursPhase}'),
                      initialValue: (ct.conducteursPhase ?? 1).toString(),
                      decoration: const InputDecoration(
                        labelText: 'Nombre de conducteurs phase',
                        hintText: 'Ex: 1, 2, 3...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        ct.conducteursPhase = int.tryParse(v.trim());
                        widget.onDataChanged();
                      },
                    ),
                  ],
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: ct.effectiveSectionCableNeutre.isNotEmpty ? ct.effectiveSectionCableNeutre : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Section de câble neutre (mm²)', isDense: true, border: OutlineInputBorder()),
                    items: _sectionCableOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      setState(() {
                        ct.sectionCableNeutre = v ?? '';
                        if (ct.sectionCableNeutre!.trim().isNotEmpty && ct.sectionCableNeutre!.trim() != '-') {
                          ct.conducteursNeutre ??= 1;
                        } else {
                          ct.conducteursNeutre = null;
                        }
                      });
                      widget.onDataChanged();
                    },
                  ),
                  if (ct.effectiveSectionCableNeutre.trim().isNotEmpty && ct.effectiveSectionCableNeutre.trim() != '-') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: ValueKey('ct_${ct.id}_cond_neutre_${ct.conducteursNeutre}'),
                      initialValue: (ct.conducteursNeutre ?? 1).toString(),
                      decoration: const InputDecoration(
                        labelText: 'Nombre de conducteurs neutre',
                        hintText: 'Ex: 1, 2, 3...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        ct.conducteursNeutre = int.tryParse(v.trim());
                        widget.onDataChanged();
                      },
                    ),
                  ],
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: ct.natureCable != null && ct.natureCable!.isNotEmpty ? ct.natureCable : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Nature du câble', isDense: true, border: OutlineInputBorder()),
                    items: _natureCableOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      setState(() {
                        ct.natureCable = v ?? '';
                      });
                      widget.onDataChanged();
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    key: ValueKey('ct_${ct.id}_nb_cables_${ct.effectiveNombreCables}'),
                    initialValue: ct.effectiveNombreCables ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Nombre de câble',
                      hintText: 'Ex: 1, 2, 3...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final trimmed = v.trim();
                      ct.nombreCables = trimmed.isEmpty ? null : trimmed;
                      final parsed = int.tryParse(trimmed);
                      if (parsed != null && parsed > 0) {
                        ct.conducteursPhase = parsed;
                      } else if (trimmed.isEmpty) {
                        ct.conducteursPhase = (ct.sectionCable.trim().isNotEmpty && ct.sectionCable.trim() != '-') ? 1 : null;
                      }
                      widget.onDataChanged();
                    },
                  ),
                  if (isEligible) ...[
                    const SizedBox(height: 16),
                    buildEssaiDeclenchementButton(
                      context: context,
                      missionId: widget.missionId,
                      elementId: ct.id,
                      equipementId: widget.currentEquipmentId ?? '',
                      circuitName: circuitDesignation,
                      zone: widget.zoneName ?? '',
                      repere: widget.repereName ?? '',
                      designation: widget.equipmentNom ?? 'Équipement',
                      precision: EssaiDeclenchementHelper.precisionCircuit,
                      typeDispositif: ct.typeProtection,
                      calibre: ct.calibre,
                      ddr: ct.ddr,
                      onEssaiChanged: () => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, String title, int currentStep, int totalSteps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: context.iconSizeXL * 1.2,
              height: context.iconSizeXL * 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(context.spacingS),
              ),
              child: Icon(Icons.alt_route, color: Colors.white, size: context.iconSizeM),
            ),
            SizedBox(width: context.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                  SizedBox(height: context.spacingXS),
                  Text('Étape $currentStep sur $totalSteps', style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingM),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}

// ================================================================
// CHAMP HYBRIDE TEXTE / SELECTION — IDENTIFICATION DU CIRCUIT
// ================================================================
class _HybridCircuitIdentificationField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _HybridCircuitIdentificationField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_HybridCircuitIdentificationField> createState() => _HybridCircuitIdentificationFieldState();
}

class _HybridCircuitIdentificationFieldState extends State<_HybridCircuitIdentificationField> {
  late TextEditingController _controller;
  static const List<String> _options = ['Éclairage', 'Climatisation', 'Prise de courant'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _HybridCircuitIdentificationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectOption(String option) {
    setState(() {
      _controller.text = option;
    });
    widget.onChanged(option);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          style: TextStyle(fontSize: context.fontSizeS),
          decoration: InputDecoration(
            labelText: 'Identification du circuit',
            hintText: 'Saisir ou sélectionner l\'identification...',
            isDense: true,
            border: const OutlineInputBorder(),
            labelStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade700),
            suffixIcon: PopupMenuButton<String>(
              icon: Icon(Icons.arrow_drop_down_circle_outlined, color: AppTheme.primaryBlue, size: 20),
              tooltip: 'Sélectionner une option prédéfinie',
              onSelected: _selectOption,
              itemBuilder: (context) => _options.map((opt) {
                return PopupMenuItem<String>(
                  value: opt,
                  child: Text(opt, style: TextStyle(fontSize: context.fontSizeS)),
                );
              }).toList(),
            ),
          ),
          onChanged: (v) => widget.onChanged(v),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: _options.map((opt) {
            final isSelected = _controller.text.trim().toLowerCase() == opt.toLowerCase();
            return ActionChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
              side: BorderSide(
                color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
              ),
              label: Text(
                opt,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade800,
                ),
              ),
              onPressed: () => _selectOption(opt),
            );
          }).toList(),
        ),
      ],
    );
  }
}