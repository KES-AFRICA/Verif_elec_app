import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/services/gallery_photo_service.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_emplacement_screen.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';
import 'package:inspec_app/utils/image_compress_helper.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/description_installations_form.dart';
import 'package:flutter/services.dart';
import 'observation_enrichie_widget.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';
import 'package:inspec_app/services/cellule_types_registry.dart';
import 'package:inspec_app/services/normative_search_service.dart';
import 'package:inspec_app/components/normative_search_suggestions_widget.dart';
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:inspec_app/services/local_type_transition_service.dart';
import 'package:inspec_app/utils/observation_text_normalizer.dart';

// Extension pour obtenir la taille de l'écran facilement
extension ScreenSize on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 600;
  bool get isLargeScreen => screenWidth >= 600;
  
  // Tailles de police responsives
  double get fontSizeXXXL => isSmallScreen ? 20 : (isMediumScreen ? 22 : 26);
  double get fontSizeXXL => isSmallScreen ? 18 : (isMediumScreen ? 20 : 22);
  double get fontSizeXL => isSmallScreen ? 16 : (isMediumScreen ? 17 : 18);
  double get fontSizeL => isSmallScreen ? 14 : (isMediumScreen ? 15 : 16);
  double get fontSizeM => isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
  double get fontSizeS => isSmallScreen ? 11 : (isMediumScreen ? 12 : 13);
  double get fontSizeXS => isSmallScreen ? 10 : (isMediumScreen ? 11 : 12);
  
  // Espacements responsifs
  double get spacingXXL => isSmallScreen ? 20 : (isMediumScreen ? 24 : 28);
  double get spacingXL => isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);
  double get spacingL => isSmallScreen ? 12 : (isMediumScreen ? 14 : 16);
  double get spacingM => isSmallScreen ? 10 : (isMediumScreen ? 11 : 12);
  double get spacingS => isSmallScreen ? 8 : (isMediumScreen ? 9 : 10);
  double get spacingXS => isSmallScreen ? 4 : (isMediumScreen ? 5 : 6);
  
  // Tailles d'icônes responsives
  double get iconSizeXL => isSmallScreen ? 20 : (isMediumScreen ? 22 : 24);
  double get iconSizeL => isSmallScreen ? 18 : (isMediumScreen ? 20 : 22);
  double get iconSizeM => isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);
  double get iconSizeS => isSmallScreen ? 14 : (isMediumScreen ? 15 : 16);
  double get iconSizeXS => isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
}

// ================================================================
// ÉTAPE 1 : INFORMATIONS GÉNÉRALES (Nom, Type, Photos, Observations)
// ================================================================
class _EtapeInformationsGenerales extends StatefulWidget {
  final TextEditingController nomController;
  final String? selectedType;
  final Function(String?) onTypeChanged;
  final List<String> localPhotos;
  final Function() onPrendrePhoto;
  final Function() onChoisirPhoto;
  final VoidCallback onSupprimerPhoto;
  final bool isLoadingPhotos;
  final bool addObservation;
  final Function(bool) onAddObservationChanged;
  final TextEditingController observationController;
  final List<ObservationLibre> observationsExistantes;
  final List<String> observationPhotos;
  final Function() onPrendrePhotoObservation;
  final Function() onChoisirPhotoObservation;
  final Function([String?, String?, String?, String?]) onAjouterObservation;
  final Function(int) onSupprimerObservationExistante;
  final bool nomValid;
  final bool typeValid;
  final VoidCallback onValidate;
  final bool isMoyenneTension;
  final bool isRiskZone;
  final ValueChanged<bool> onRiskZoneChanged;

  const _EtapeInformationsGenerales({
    required this.nomController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.localPhotos,
    required this.onPrendrePhoto,
    required this.onChoisirPhoto,
    required this.onSupprimerPhoto,
    required this.isLoadingPhotos,
    required this.addObservation,
    required this.onAddObservationChanged,
    required this.observationController,
    required this.observationsExistantes,
    required this.observationPhotos,
    required this.onPrendrePhotoObservation,
    required this.onChoisirPhotoObservation,
    required this.onAjouterObservation,
    required this.onSupprimerObservationExistante,
    required this.nomValid,
    required this.typeValid,
    required this.onValidate,
    required this.isMoyenneTension,
    required this.isRiskZone,
    required this.onRiskZoneChanged,
  });

  @override
  State<_EtapeInformationsGenerales> createState() => _EtapeInformationsGeneralesState();
}

class _EtapeInformationsGeneralesState extends State<_EtapeInformationsGenerales> {
  final PageController _photosController = PageController();
  int _currentPhotoIndex = 0;

  String? _pendingPointVerificationKey;
  String? _pendingReferenceNormative;
  String? _pendingFamilleRisque;
  String? _pendingCriticite;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: [
        _buildModernHeader(context, 'Informations générales', 1, 4),
        SizedBox(height: context.spacingXL),
        _buildModernTextField(context),
        SizedBox(height: context.spacingXL),
        _buildModernTypeSelector(context),
        SizedBox(height: context.spacingXL),
        _buildModernRiskZoneSelector(context),
        SizedBox(height: context.spacingXL),
        _buildModernPhotoCarousel(context),
        SizedBox(height: context.spacingXL),
        _buildModernObservationsCard(context),
        SizedBox(height: context.spacingXXL),
      ],
    );
  }

  Widget _buildModernRiskZoneSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.spacingL, context.spacingM, context.spacingL, context.spacingS),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: widget.isRiskZone ? Colors.orange.shade700 : AppTheme.primaryBlue,
                size: context.iconSizeM,
              ),
              SizedBox(width: context.spacingS),
              Flexible(
                child: Text(
                  'Local à risque ?',
                  style: TextStyle(
                    fontSize: context.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacingL),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(context.spacingS),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onRiskZoneChanged(false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: context.spacingM),
                      decoration: BoxDecoration(
                        color: !widget.isRiskZone ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(context.spacingS - 1)),
                      ),
                      child: Center(
                        child: Text(
                          'Non',
                          style: TextStyle(
                            fontSize: context.fontSizeM,
                            fontWeight: FontWeight.bold,
                            color: !widget.isRiskZone ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onRiskZoneChanged(true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: context.spacingM),
                      decoration: BoxDecoration(
                        color: widget.isRiskZone ? Colors.orange.shade700 : Colors.transparent,
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(context.spacingS - 1)),
                      ),
                      child: Center(
                        child: Text(
                          'Oui',
                          style: TextStyle(
                            fontSize: context.fontSizeM,
                            fontWeight: FontWeight.bold,
                            color: widget.isRiskZone ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                    style: TextStyle(
                      fontSize: context.fontSizeXXL,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  SizedBox(height: context.spacingXS),
                  Text(
                    'Étape $currentStep sur $totalSteps',
                    style: TextStyle(
                      fontSize: context.fontSizeS,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
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

  Widget _buildModernTextField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.nomController,
        onChanged: (_) => widget.onValidate(),
        style: TextStyle(fontSize: context.fontSizeM),
        decoration: InputDecoration(
          labelText: 'Nom du local',
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: context.fontSizeM),
          prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue, size: context.iconSizeM),
          suffixIcon: widget.nomValid 
              ? Icon(Icons.check_circle, color: Colors.green, size: context.iconSizeS)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.spacingM),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.spacingM),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.spacingM),
            borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingM),
        ),
      ),
    );
  }

  Widget _buildModernTypeSelector(BuildContext context) {
    
    final allTypes = HiveService.getLocalTypes();
    final filteredMap = HiveService.getLocalTypes(
      isMoyenneTension: widget.isMoyenneTension,
    );

    // Si la valeur actuelle n'est pas dans la liste filtrée (cas d'édition
    // d'un local créé dans un autre contexte), on l'ajoute pour éviter
    // l'assertion Flutter sur DropdownButton.
    if (widget.selectedType != null &&
        !filteredMap.containsKey(widget.selectedType)) {
      final label = allTypes[widget.selectedType] ?? widget.selectedType!;
      filteredMap[widget.selectedType!] = label;
    }

    final filteredTypes = filteredMap.entries.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: Offset(0, 2),
          ),
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
                    'Type de local',
                    style: TextStyle(
                      fontSize: context.fontSizeL,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
                Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: context.fontSizeL),
                ),
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
                value: widget.selectedType,
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
                        'Sélectionnez un type de local',
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
                items: filteredTypes.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Container(
                          width: context.spacingS,
                          height: context.spacingS,
                          decoration: BoxDecoration(
                            color: widget.selectedType == entry.key ? AppTheme.primaryBlue : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.selectedType == entry.key ? AppTheme.primaryBlue : Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: widget.selectedType == entry.key
                              ? Icon(Icons.check, size: context.spacingXS, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: context.spacingS),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: context.fontSizeM,
                              fontWeight: widget.selectedType == entry.key ? FontWeight.w600 : FontWeight.w400,
                              color: widget.selectedType == entry.key ? AppTheme.primaryBlue : Colors.grey.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: widget.onTypeChanged,
                selectedItemBuilder: (BuildContext context) {
                  return filteredTypes.map<Widget>((entry) {
                    return Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: context.iconSizeS),
                        SizedBox(width: context.spacingS),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w500, color: AppTheme.darkBlue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                  Flexible(
                    child: Text(
                      'Sélectionnez un type de local',
                      style: TextStyle(color: Colors.red, fontSize: context.fontSizeXS),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernPhotoCarousel(BuildContext context) {
    final photoHeight = context.screenHeight * 0.25;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: Offset(0, 2),
          ),
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
                    'Photos du local',
                    style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                  ),
                ),
                const Spacer(),
                if (widget.localPhotos.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.spacingL),
                    ),
                    child: Text(
                      '${widget.localPhotos.length} photo${widget.localPhotos.length > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                    ),
                  ),
              ],
            ),
          ),
          
          if (widget.isLoadingPhotos)
            Container(
              height: photoHeight,
              width: double.infinity,
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
            )
          else if (widget.localPhotos.isEmpty)
            Container(
              height: photoHeight,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: context.spacingL),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: context.iconSizeXL * 1.5, color: Colors.grey.shade400),
                  SizedBox(height: context.spacingM),
                  Flexible(
                    child: Text(
                      'Aucune photo',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: context.fontSizeM),
                    ),
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
                    controller: _photosController,
                    onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
                    itemCount: widget.localPhotos.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullScreenPhoto(widget.localPhotos, index),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: context.spacingXS),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.spacingS),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(context.spacingS),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SafeFileImage(path: widget.localPhotos[index], fit: BoxFit.cover),
                                Positioned(
                                  top: context.spacingS,
                                  right: context.spacingS,
                                  child: GestureDetector(
                                    onTap: () => _confirmDeletePhoto(index),
                                    child: Container(
                                      padding: EdgeInsets.all(context.spacingXS),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.delete_outline, color: Colors.white, size: context.iconSizeS),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.localPhotos.length > 1)
                  Padding(
                    padding: EdgeInsets.only(top: context.spacingS, bottom: context.spacingS),
                    child: SmoothPageIndicator(
                      controller: _photosController,
                      count: widget.localPhotos.length,
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
                    onTap: widget.onPrendrePhoto,
                  ),
                ),
                SizedBox(width: context.spacingS),
                Expanded(
                  child: _buildModernPhotoButton(
                    context,
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: widget.onChoisirPhoto,
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
                  style: TextStyle(
                    fontSize: context.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: isSecondary ? Colors.grey.shade700 : Colors.white,
                  ),
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

  Widget _buildModernObservationsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(
              children: [
                Icon(Icons.notes_outlined, color: AppTheme.primaryBlue, size: context.iconSizeM),
                SizedBox(width: context.spacingS),
                Flexible(
                  child: Text(
                    'Observations',
                    style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacingL),
            child: Container(
              padding: EdgeInsets.all(context.spacingM),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ajouter une observation ?',
                      style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                    ),
                  ),
                  _buildModernToggleButton(
                    context,
                    label: 'Oui',
                    isSelected: widget.addObservation,
                    onTap: () => widget.onAddObservationChanged(true),
                    color: Colors.green,
                  ),
                  SizedBox(width: context.spacingS),
                  _buildModernToggleButton(
                    context,
                    label: 'Non',
                    isSelected: !widget.addObservation,
                    onTap: () => widget.onAddObservationChanged(false),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          
          if (widget.observationsExistantes.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(context.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Observations existantes',
                    style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: context.spacingS),
                  ...widget.observationsExistantes.asMap().entries.map((entry) {
                    return _buildModernExistingObservation(context, entry.value, entry.key);
                  }),
                ],
              ),
            ),
          
          if (widget.addObservation)
            Padding(
              padding: EdgeInsets.all(context.spacingL),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.spacingS),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextFormField(
                      controller: widget.observationController,
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernPhotoButton(
                          context,
                          icon: Icons.camera_alt,
                          label: 'Photo',
                          onTap: widget.onPrendrePhotoObservation,
                        ),
                      ),
                      SizedBox(width: context.spacingS),
                      Expanded(
                        child: _buildModernPhotoButton(
                          context,
                          icon: Icons.photo_library,
                          label: 'Galerie',
                          onTap: widget.onChoisirPhotoObservation,
                          isSecondary: true,
                        ),
                      ),
                    ],
                  ),
                  if (widget.observationPhotos.isNotEmpty)
                    Container(
                      height: context.screenHeight * 0.1,
                      margin: EdgeInsets.only(top: context.spacingM),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.observationPhotos.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: context.screenWidth * 0.2,
                            margin: EdgeInsets.only(right: context.spacingS),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(context.spacingS)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(context.spacingS),
                              child: SafeFileImage(path: widget.observationPhotos[index], fit: BoxFit.cover),
                            ),
                          );
                        },
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
                ],
              ),
            ),
          
          SizedBox(height: context.spacingL),
        ],
      ),
    );
  }

  Widget _buildModernToggleButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(context.spacingXL),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildModernExistingObservation(BuildContext context, ObservationLibre observation, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      observation.texte,
                      style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade800),
                    ),
                    if (observation.hasNormativeReference) ...[
                      SizedBox(height: context.spacingXS),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          'Réf : ${observation.referenceNormative}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.observationController.text = observation.texte;
                    widget.observationPhotos.clear();
                    widget.observationPhotos.addAll(observation.photos);
                    _pendingPointVerificationKey = observation.pointVerificationKey;
                    _pendingReferenceNormative = observation.referenceNormative;
                    _pendingFamilleRisque = observation.familleRisque;
                    _pendingCriticite = observation.criticite;
                    widget.observationsExistantes.removeAt(index);
                    widget.onAddObservationChanged(true);
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(context.spacingXS),
                  margin: EdgeInsets.only(right: context.spacingS),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_outlined, size: context.iconSizeS, color: Colors.blue),
                ),
              ),
              GestureDetector(
                onTap: () => widget.onSupprimerObservationExistante(index),
                child: Container(
                  padding: EdgeInsets.all(context.spacingXS),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline, size: context.iconSizeS, color: Colors.red),
                ),
              ),
            ],
          ),
          if (observation.photos.isNotEmpty) ...[
            SizedBox(height: context.spacingS),
            Container(
              height: context.screenHeight * 0.08,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: observation.photos.length,
                itemBuilder: (context, photoIndex) {
                  return Container(
                    width: context.screenWidth * 0.18,
                    margin: EdgeInsets.only(right: context.spacingS),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(context.spacingS)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(context.spacingS),
                      child: SafeFileImage(path: observation.photos[photoIndex], fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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

  void _confirmDeletePhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la photo ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSupprimerPhoto();
              setState(() {
                if (_currentPhotoIndex >= widget.localPhotos.length) {
                  _currentPhotoIndex = widget.localPhotos.length - 1;
                }
                _photosController.jumpToPage(_currentPhotoIndex.clamp(0, widget.localPhotos.length - 1));
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ÉTAPE 2 : ÉLÉMENTS DE CONTRÔLE (Dispositions + Conditions)
// ================================================================
class _EtapeElementsControle extends StatefulWidget {
  final List<ElementControle> dispositionsConstructives;
  final List<ElementControle> conditionsExploitation;
  final Map<int, bool> hasObservation;
  final Map<int, List<String>> elementSuggestions;
  final Map<ElementControle, bool> conformeSelected;
  final Function(ElementControle, int, String) onElementChanged;
  final Function(ElementControle) onConformeChanged;
  final Function(int, bool, String) onObservationToggleChanged;
  final Function(ElementControle, int, String) onPrendrePhotoElement;
  final Function(ElementControle, int, String) onChoisirPhotoElement;
  final Function(ElementControle, int, int, String) onSupprimerPhotoElement;
  final Function(int, String, String) onObservationChanged;
  final Function(int, String, ElementControle, String) onUseSuggestion;
  final Function(String) onAjouterAutre; // Callback pour ajouter "Autre"
  final VoidCallback onRebuildSlides; // NOUVEAU : Callback pour reconstruire les slides après ajout
  final Future<String?> Function(File, String) onSavePhoto;
  final VoidCallback onAutoSave;

  const _EtapeElementsControle({
    super.key,
    required this.dispositionsConstructives,
    required this.conditionsExploitation,
    required this.hasObservation,
    required this.elementSuggestions,
    required this.conformeSelected,
    required this.onElementChanged,
    required this.onConformeChanged,
    required this.onObservationToggleChanged,
    required this.onPrendrePhotoElement,
    required this.onChoisirPhotoElement,
    required this.onSupprimerPhotoElement,
    required this.onObservationChanged,
    required this.onUseSuggestion,
    required this.onAjouterAutre,
    required this.onRebuildSlides,
    required this.onSavePhoto,
    required this.onAutoSave,
  });

  @override
  State<_EtapeElementsControle> createState() => _EtapeElementsControleState();
}

class _EtapeElementsControleState extends State<_EtapeElementsControle> {
  final PageController _slideController = PageController();
  
  int _currentSection = 0;
  int _currentSlide = 0;
  
  late List<List<ElementControle>> _dispositionsSlides;
  late List<List<ElementControle>> _conditionsSlides;

  @override
  void initState() {
    super.initState();
    _buildSlides();
  }

  void _buildSlides() {
    _dispositionsSlides = [];
    for (int i = 0; i < widget.dispositionsConstructives.length; i += 3) {
      _dispositionsSlides.add(widget.dispositionsConstructives.sublist(
        i, 
        (i + 3).clamp(0, widget.dispositionsConstructives.length)
      ));
    }
    
    _conditionsSlides = [];
    for (int i = 0; i < widget.conditionsExploitation.length; i += 3) {
      _conditionsSlides.add(widget.conditionsExploitation.sublist(
        i, 
        (i + 3).clamp(0, widget.conditionsExploitation.length)
      ));
    }
  }

  List<List<ElementControle>> get _currentSlides => 
      _currentSection == 0 ? _dispositionsSlides : _conditionsSlides;
  
  String get _currentSectionTitle => 
      _currentSection == 0 ? 'DISPOSITIONS CONSTRUCTIVES' : 'CONDITIONS D\'EXPLOITATION';
  
  Color get _currentSectionColor => 
      _currentSection == 0 ? const Color(0xFF2C3E50) : const Color(0xFF34495E);
  
  int get _totalSlides => _currentSlides.length;
  
  bool get _isLastSlide => _currentSlide == _totalSlides - 1;
  
  bool get _isFirstSlide => _currentSlide == 0;
  
  bool get _isLastSection => _currentSection == 1;
  
  bool get _canGoToNextSection => _currentSection == 0 && _isLastSlide;

  bool _isCurrentSlideValid() {
    if (_currentSlides.isEmpty) return true;
    
    final currentElements = _currentSlides[_currentSlide];
    for (var element in currentElements) {
      // Conformité obligatoire (Oui, Non, ou NA)
      final conformiteRemplie = element.conforme != null || element.estNA;
      if (!conformiteRemplie) return false;

      // Priorité obligatoire uniquement si Non ou NA
      final needsPriorite = element.conforme == false;
      if (needsPriorite && element.priorite == null) return false;

      final elementIndex = _getElementIndex(element);
      // Observation obligatoire si Non (pas pour NA)
      if (element.conforme == false) {
        if (widget.hasObservation[elementIndex] != true) return false;
        if (element.observation == null || element.observation!.trim().isEmpty) return false;
      } else if (!element.estNA) {
        // Oui : observation optionnelle mais si toggle activé, le champ doit être rempli
        if (widget.hasObservation[elementIndex] == true) {
          if (element.observation == null || element.observation!.trim().isEmpty) return false;
        }
      }
    }
    return true;
  }

  int _getElementIndex(ElementControle element) {
    if (_currentSection == 0) {
      return widget.dispositionsConstructives.indexOf(element);
    } else {
      return widget.dispositionsConstructives.length + widget.conditionsExploitation.indexOf(element);
    }
  }

  void nextSlide() {
    if (!_isCurrentSlideValid()) {
      _showError('Veuillez remplir tous les champs obligatoires de ce slide');
      return;
    }
    
    if (_isLastSlide) {
      if (_canGoToNextSection) {
        setState(() {
          _currentSection = 1;
          _currentSlide = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_slideController.hasClients) {
            _slideController.jumpToPage(0);
          }
        });
      }
    } else {
      if (_slideController.hasClients) {
        _slideController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  void previousSlide() {
    if (_isFirstSlide) {
      if (_currentSection == 1) {
        setState(() {
          _currentSection = 0;
          _currentSlide = _dispositionsSlides.length - 1;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_slideController.hasClients) {
            _slideController.jumpToPage(_dispositionsSlides.length - 1);
          }
        });
      }
    } else {
      if (_slideController.hasClients) {
        _slideController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
    );
  }

  bool canGoNext() {
    if (!_isCurrentSlideValid()) return false;
    if (_isLastSection && _isLastSlide) return true;
    return false;
  }

  bool canGoPrevious() {
    return _isFirstSlide && _currentSection == 0;
  }

  /// Méthode pour reconstruire les slides (appelée depuis le parent après ajout d'un élément)
  void rebuildSlides() {
    _buildSlides();
    setState(() {});
  }

  /// Positionner la section et le slide (slide index négatif pour signifier le dernier slide)
  void setSectionAndSlide(int section, int slideIndex) {
    setState(() {
      _currentSection = section;
      _buildSlides();
      if (slideIndex < 0) {
        _currentSlide = _totalSlides - 1;
      } else {
        _currentSlide = slideIndex;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_slideController.hasClients) {
        _slideController.jumpToPage(_currentSlide);
      }
    });
  }

  /// Méthode pour aller au dernier slide de la section courante
  void goToLastSlide() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_slideController.hasClients && _totalSlides > 0) {
        _slideController.jumpToPage(_totalSlides - 1);
        setState(() {
          _currentSlide = _totalSlides - 1;
        });
      }
    });
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
            Text('Aucun élément à contrôler', style: TextStyle(fontSize: context.fontSizeL, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // En-tête simplifié
        Container(
          padding: EdgeInsets.all(context.spacingL),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.spacingS, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: context.iconSizeXL * 1.2,
                height: context.iconSizeXL * 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(context.spacingS),
                ),
                child: Icon(Icons.checklist, color: Colors.white, size: context.iconSizeM),
              ),
              SizedBox(width: context.spacingM),
              Expanded(
                child: Text(
                  'Éléments de contrôle',
                  style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                ),
              ),
            ],
          ),
        ),
        
        // Titre de section avec compteur sur la même ligne
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingS),
          child: Row(
            children: [
              Container(
                width: 4,
                height: context.iconSizeL,
                decoration: BoxDecoration(
                  color: _currentSectionColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: context.spacingS),
              Expanded(
                child: Text(
                  _currentSectionTitle,
                  style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.bold, color: _currentSectionColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_currentSlide + 1}/${_totalSlides}',
                style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        
        // Barre de progression
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacingL),
          child: LinearProgressIndicator(
            value: (_currentSlide + 1) / _totalSlides,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_currentSectionColor),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Zone des éléments
        Expanded(
          child: PageView.builder(
            controller: _slideController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentSlide = index),
            itemCount: _totalSlides,
            itemBuilder: (context, slideIndex) {
              final slideElements = _currentSlides[slideIndex];
              
              return ListView(
                padding: EdgeInsets.all(context.spacingL),
                children: [
                  ...slideElements.map((element) {
                    final originalIndex = _currentSection == 0 
                        ? widget.dispositionsConstructives.indexOf(element)
                        : widget.conditionsExploitation.indexOf(element);
                    final globalIndex = _currentSection == 0 
                        ? originalIndex 
                        : widget.dispositionsConstructives.length + originalIndex;
                    
                    return _buildModernElementCard(
                      context,
                      element: element,
                      index: originalIndex,
                      globalIndex: globalIndex,
                      sectionType: _currentSection == 0 ? 'dispositions' : 'conditions',
                      color: _currentSectionColor,
                    );
                  }).toList(),
                  
                  // CORRECTION : Le bouton "Autre" n'apparaît que sur le DERNIER slide
                  if (_isLastSlide)
                    _buildAutreButton(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutreButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.spacingL),
      child: OutlinedButton.icon(
        onPressed: () async {
          // Appeler le callback pour ajouter un élément "Autre"
          await widget.onAjouterAutre(_currentSection == 0 ? 'dispositions' : 'conditions');
          // Après l'ajout, reconstruire les slides
          widget.onRebuildSlides();
        },
        icon: Icon(Icons.add_circle_outline, size: context.iconSizeM, color: AppTheme.primaryBlue),
        label: Text(
          'AUTRE',
          style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: context.spacingM),
          side: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
        ),
      ),
    );
  }

  Widget _buildModernElementCard(
    BuildContext context, {
    required ElementControle element,
    required int index,
    required int globalIndex,
    required String sectionType,
    required Color color,
  }) {
    final hasObservation = widget.hasObservation[globalIndex] ?? false;
    final suggestions = widget.elementSuggestions[index] ?? [];
    final isConformiteNon = element.conforme == false;
    
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingL),
      padding: EdgeInsets.all(context.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingL),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec numéro et titre
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.iconSizeL,
                height: context.iconSizeL,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.spacingS),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
              SizedBox(width: context.spacingS),
              Expanded(
                child: Text(
                  element.elementControle,
                  style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: AppTheme.darkBlue, height: 1.3),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          
          SizedBox(height: context.spacingL),
          
          // Ligne 1 : Conformité (seule, sur toute la largeur)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Conformité *',
                    style: TextStyle(
                      fontSize: context.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: element.conforme != null ? Colors.grey.shade700 : Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacingS),
              Row(
                children: [
                  Expanded(
                    child: _buildConformiteButton(
                      context,
                      label: 'Oui',
                      isSelected: element.conforme == true && !element.estNA,
                      color: Colors.green,
                      onTap: () {
                        setState(() {
                          element.conforme = true;
                          element.estNA = false;
                          element.priorite = null; // priorité non requise pour Oui
                          widget.onConformeChanged(element);
                          widget.onElementChanged(element, index, 'conformite');
                          widget.onObservationToggleChanged(globalIndex, false, sectionType);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: context.spacingS),
                  Expanded(
                    child: _buildConformiteButton(
                      context,
                      label: 'Non',
                      isSelected: element.conforme == false && !element.estNA,
                      color: Colors.red,
                      onTap: () {
                        setState(() {
                          element.conforme = false;
                          element.estNA = false;
                          element.priorite ??= 3; // défaut priorité 3
                          widget.onConformeChanged(element);
                          widget.onElementChanged(element, index, 'conformite');
                          widget.onObservationToggleChanged(globalIndex, true, sectionType);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: context.spacingS),
                  Expanded(
                    child: _buildConformiteButton(
                      context,
                      label: 'NA',
                      isSelected: element.estNA,
                      color: Colors.grey.shade600,
                      onTap: () {
                        setState(() {
                          element.conforme = null;
                          element.estNA = true;
                          element.priorite = null;
                          widget.onConformeChanged(element);
                          widget.onElementChanged(element, index, 'conformite');
                          widget.onObservationToggleChanged(globalIndex, false, sectionType);
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (element.conforme == null && !element.estNA)
                Padding(
                  padding: EdgeInsets.only(top: context.spacingXS),
                  child: Text(
                    'Veuillez sélectionner Oui, Non ou NA',
                    style: TextStyle(fontSize: context.fontSizeXS, color: Colors.red),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: context.spacingM),
          
          // Notion de priorité masquée de l'interface utilisateur (données et modèle conservés)
          /*
          if (element.conforme == false)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Priorité',
                    style: TextStyle(
                      fontSize: context.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacingS),
              _buildModernPrioriteSelector(context, element, color, index, sectionType),
            ],
          ),
          SizedBox(height: context.spacingM),
          */
          
          // Toggle Observation
          _buildModernObservationToggle(
            context, globalIndex, hasObservation, color, sectionType, isConformiteNon,
          ),
          
          if (hasObservation) ...[
            SizedBox(height: context.spacingS),
            ObservationEnrichieWidget(
              element: element,
              onChanged: () {
                setState(() {});
                widget.onAutoSave();
              },
              color: color,
              onSavePhoto: (file, section) async {
                return await widget.onSavePhoto(file, section);
              },
              suggestions: suggestions,
              showPriority: false,
              sectionType: sectionType,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernConformiteToggle(
    BuildContext context,
    ElementControle element,
    Color color,
    int index,
    int globalIndex,
    String sectionType,
  ) {
    final isValid = widget.conformeSelected[element] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Conformité *',
              style: TextStyle(
                fontSize: context.fontSizeS,
                fontWeight: FontWeight.w600,
                color: isValid ? Colors.grey.shade700 : Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingS),
        Row(
          children: [
            Expanded(
              child: _buildConformiteButton(
                context,
                label: 'Oui',
                isSelected: element.conforme == true,
                color: Colors.green,
                onTap: () {
                  setState(() {
                    element.conforme = true;
                    widget.onConformeChanged(element);
                    widget.onElementChanged(element, index, 'conformite');
                  });
                },
              ),
            ),
            SizedBox(width: context.spacingS),
            Expanded(
              child: _buildConformiteButton(
                context,
                label: 'Non',
                isSelected: element.conforme == false,
                color: Colors.red,
                onTap: () {
                  setState(() {
                    element.conforme = false;
                    widget.onConformeChanged(element);
                    widget.onElementChanged(element, index, 'conformite');
                    // Forcer l'observation à Oui
                    widget.onObservationToggleChanged(globalIndex, true, sectionType);
                  });
                },
              ),
            ),
          ],
        ),
        if (!isValid)
          Padding(
            padding: EdgeInsets.only(top: context.spacingXS),
            child: Text(
              'Veuillez sélectionner Oui ou Non',
              style: TextStyle(fontSize: context.fontSizeXS, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildConformiteButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: context.spacingM),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(context.spacingS),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected 
                  ? (label == 'Oui' ? Icons.check_circle : Icons.cancel)
                  : (label == 'Oui' ? Icons.check_circle_outline : Icons.cancel_outlined),
              size: context.iconSizeS,
              color: isSelected ? color : Colors.grey.shade500,
            ),
            SizedBox(width: context.spacingS),
            Text(
              label,
              style: TextStyle(
                fontSize: context.fontSizeM,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernConformiteSelector(
    BuildContext context, 
    ElementControle element, 
    Color color, 
    int index, 
    String sectionType, 
    bool isConformeSelected,
    int globalIndex,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(
          color: !isConformeSelected ? Colors.red.shade300 : Colors.transparent,
          width: !isConformeSelected ? 1.5 : 0,
        ),
      ),
      child: DropdownButtonFormField<bool?>(
        initialValue: isConformeSelected ? element.conforme : null,
        hint: Text('Sélectionnez *', style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade500)),
        onChanged: (bool? newValue) {
          if (newValue != null) {
            setState(() {
              element.conforme = newValue;
              widget.onConformeChanged(element);
              widget.onElementChanged(element, index, 'conformite');
              
              if (newValue == false) {
                widget.onObservationToggleChanged(globalIndex, true, sectionType);
              } else {
                widget.onObservationToggleChanged(globalIndex, false, sectionType);
              }
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Conformité *',
          labelStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
        ),
        items: [
          DropdownMenuItem(
            value: true,
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: context.iconSizeXS),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('Oui', style: TextStyle(fontSize: context.fontSizeS))),
              ],
            ),
          ),
          DropdownMenuItem(
            value: false,
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: context.iconSizeXS),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('Non', style: TextStyle(fontSize: context.fontSizeS))),
              ],
            ),
          ),
        ],
        isExpanded: true,
      ),
    );
  }

  Widget _buildModernPrioriteSelector(BuildContext context, ElementControle element, Color color, int index, String sectionType) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingS),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPrioriteButton(
              context,
              label: 'N1',
              tooltip: 'Basse priorité',
              isSelected: element.priorite == 1,
              color: Colors.blue,
              onTap: () {
                setState(() {
                  element.priorite = 1;
                  widget.onElementChanged(element, index, 'priorite');
                });
              },
            ),
          ),
          SizedBox(width: context.spacingXS),
          Expanded(
            child: _buildPrioriteButton(
              context,
              label: 'N2',
              tooltip: 'Moyenne priorité',
              isSelected: element.priorite == 2,
              color: Colors.orange,
              onTap: () {
                setState(() {
                  element.priorite = 2;
                  widget.onElementChanged(element, index, 'priorite');
                });
              },
            ),
          ),
          SizedBox(width: context.spacingXS),
          Expanded(
            child: _buildPrioriteButton(
              context,
              label: 'N3',
              tooltip: 'Haute priorité',
              isSelected: element.priorite == 3,
              color: Colors.red,
              onTap: () {
                setState(() {
                  element.priorite = 3;
                  widget.onElementChanged(element, index, 'priorite');
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioriteButton(
    BuildContext context, {
    required String label,
    required String tooltip,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.spacingM),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.flag : Icons.flag_outlined,
                size: context.iconSizeS,
                color: isSelected ? color : Colors.grey.shade500,
              ),
              SizedBox(height: context.spacingXS),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernObservationToggle(
  BuildContext context,
  int globalIndex,
  bool hasObservation,
  Color color,
  String sectionType,
  bool isConformiteNon,
) {
  return Row(
    children: [
      Flexible(
        child: Text(
          'Ajouter une observation ?',
          style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      SizedBox(width: context.spacingS),
      // Bouton Oui
      GestureDetector(
        onTap: () {
          // Si conformité = Non, on ne peut pas désactiver l'observation
          if (!isConformiteNon) {
            widget.onObservationToggleChanged(globalIndex, true, sectionType);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS),
          decoration: BoxDecoration(
            color: hasObservation ? Colors.green.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(context.spacingL),
            border: Border.all(
              color: hasObservation ? Colors.green : (isConformiteNon ? Colors.grey.shade300 : Colors.grey.shade300),
              width: hasObservation ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Oui',
                style: TextStyle(
                  fontSize: context.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: hasObservation ? Colors.green : (isConformiteNon ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
              if (isConformiteNon && !hasObservation)
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.lock_open,
                    size: context.fontSizeXS,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ),
      ),
      SizedBox(width: context.spacingS),
      // Bouton Non
      GestureDetector(
        onTap: isConformiteNon 
            ? null 
            : () => widget.onObservationToggleChanged(globalIndex, false, sectionType),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS),
          decoration: BoxDecoration(
            color: !hasObservation && !isConformiteNon
                ? Colors.red.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(context.spacingL),
            border: Border.all(
              color: !hasObservation && !isConformiteNon
                  ? Colors.red
                  : (isConformiteNon ? Colors.grey.shade300 : Colors.grey.shade300),
              width: !hasObservation && !isConformiteNon ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Non',
                style: TextStyle(
                  fontSize: context.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: isConformiteNon
                      ? Colors.grey.shade400
                      : (!hasObservation ? Colors.red : Colors.grey.shade600),
                ),
              ),
              if (isConformiteNon)
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.lock_outline,
                    size: context.fontSizeXS,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildModernObservationField({
    required BuildContext context,
    required ElementControle element,
    required int index,
    required int globalIndex,
    required String sectionType,
    required List<String> suggestions,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: element.observation == null || element.observation!.trim().isEmpty ? Colors.red.shade300 : Colors.transparent,
              width: element.observation == null || element.observation!.trim().isEmpty ? 1.5 : 0,
            ),
          ),
          child: TextFormField(
            initialValue: element.observation,
            style: TextStyle(fontSize: context.fontSizeS),
            onChanged: (value) {
              element.observation = value;
              widget.onObservationChanged(index, value, sectionType);
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Saisissez votre observation... *',
              hintStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(context.spacingM),
            ),
            maxLines: 2,
          ),
        ),

        if (suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: context.spacingS),
            padding: EdgeInsets.all(context.spacingS),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(context.spacingS),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suggestions', style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.bold, color: color)),
                SizedBox(height: context.spacingXS),
                ...suggestions.map((s) => GestureDetector(
                  onTap: () => widget.onUseSuggestion(index, s, element, sectionType),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: context.spacingXS),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: context.iconSizeXS, color: Colors.amber),
                        SizedBox(width: context.spacingS),
                        Expanded(
                          child: Text(s, style: TextStyle(fontSize: context.fontSizeXS, color: Colors.grey.shade700)),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildModernElementPhotos({
    required BuildContext context,
    required ElementControle element,
    required int index,
    required String sectionType,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera_outlined, size: context.iconSizeXS, color: color),
            SizedBox(width: context.spacingS),
            Flexible(
              child: Text(
                'Photos (${element.photos.length})',
                style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingS),
        
        if (element.photos.isNotEmpty)
          Container(
            height: context.screenHeight * 0.1,
            margin: EdgeInsets.only(bottom: context.spacingS),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: element.photos.length,
              itemBuilder: (context, photoIndex) {
                return Stack(
                  children: [
                    Container(
                      width: context.screenWidth * 0.2,
                      margin: EdgeInsets.only(right: context.spacingS),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(context.spacingS)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(context.spacingS),
                        child: SafeFileImage(path: element.photos[photoIndex], fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: context.spacingXS,
                      right: context.spacingS + context.spacingXS,
                      child: GestureDetector(
                        onTap: () => widget.onSupprimerPhotoElement(element, index, photoIndex, sectionType),
                        child: Container(
                          padding: EdgeInsets.all(context.spacingXS),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: context.iconSizeXS - 2, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        
        Row(
          children: [
            Expanded(
              child: _buildSmallIconButton(
                context,
                icon: Icons.camera_alt,
                label: 'Prendre',
                onTap: () => widget.onPrendrePhotoElement(element, index, sectionType),
                color: color,
              ),
            ),
            SizedBox(width: context.spacingS),
            Expanded(
              child: _buildSmallIconButton(
                context,
                icon: Icons.photo_library,
                label: 'Galerie',
                onTap: () => widget.onChoisirPhotoElement(element, index, sectionType),
                color: color,
                isSecondary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallIconButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
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
            color: isSecondary ? Colors.grey.shade100 : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(color: isSecondary ? Colors.grey.shade300 : color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: context.iconSizeXS, color: isSecondary ? Colors.grey.shade700 : color),
              SizedBox(width: context.spacingXS),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: context.fontSizeXS - 1, fontWeight: FontWeight.w600, color: isSecondary ? Colors.grey.shade700 : color),
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
}

// ================================================================
// ÉTAPE 3 : CELLULE ET TRANSFORMATEUR
// ================================================================

// ================================================================
// NOUVEAU WIDGET : CELLULES & TRANSFORMATEURS MULTIPLES
// ================================================================

class _EtapeCelluleTransformateurMulti extends StatefulWidget {
  final List<Cellule> cellules;
  final List<TransformateurMTBT> transformateurs;
  final Function(List<Cellule>) onCellulesChanged;
  final Function(List<TransformateurMTBT>) onTransformateursChanged;
  final VoidCallback onDataChanged;
  final VoidCallback? onFormStateChanged;
  final Future<String?> Function(File, String) onSavePhoto;
  final String? localNom;

  const _EtapeCelluleTransformateurMulti({
    super.key,
    required this.cellules,
    required this.transformateurs,
    required this.onCellulesChanged,
    required this.onTransformateursChanged,
    required this.onDataChanged,
    this.onFormStateChanged,
    required this.onSavePhoto,
    this.localNom,
  });

  @override
  State<_EtapeCelluleTransformateurMulti> createState() => _EtapeCelluleTransformateurMultiState();
}

class _EtapeCelluleTransformateurMultiState extends State<_EtapeCelluleTransformateurMulti> {
  static const List<String> _sectionCableOptions = [
    '0,5 mm²',
    '0,75 mm²',
    '1 mm²',
    '1,5 mm²',
    '2,5 mm²',
    '4 mm²',
    '6 mm²',
    '10 mm²',
    '16 mm²',
    '25 mm²',
    '35 mm²',
    '50 mm²',
    '70 mm²',
    '95 mm²',
    '120 mm²',
    '150 mm²',
    '185 mm²',
    '240 mm²',
    '300 mm²',
    '400 mm²',
    '500 mm²',
    '630 mm²',
  ];
  // ============================================================
  // ÉTAT LOCAL
  // ============================================================
  int _currentMode = 0; // 0 = Cellules, 1 = Transformateurs
  
  // Pour les formulaires d'édition (mode édition actif)
  bool _isEditing = false;
  bool _isEditingCellule = true; // true = cellule, false = transformateur
  int? _editingIndex;
  
  // Contrôleurs pour le formulaire cellule (réutilisés depuis l'existant)
  final _celluleNomController = TextEditingController();
  final _celluleFonctionController = TextEditingController();
  final _celluleTypeController = TextEditingController();
  final _celluleMarqueController = TextEditingController();
  final _celluleModeleController = TextEditingController();
  final _celluleAnneeController = TextEditingController();
  final _celluleTensionController = TextEditingController();
  final _cellulePouvoirController = TextEditingController();
  final _celluleNumerotationController = TextEditingController();
  final _celluleParafoudresController = TextEditingController();
  final _celluleCalibreDisjoncteurController = TextEditingController();
  final _celluleDepartController = TextEditingController();
  
  String? _celluleGamme;
  String? _celluleSectionCables;
  String? _celluleSectionCablePhase;
  String? _celluleSectionCableNeutre;
  final _celluleConducteursPhaseController = TextEditingController();
  final _celluleConducteursNeutreController = TextEditingController();
  bool _celluleNeutreManuallyModified = false;
  String? _celluleNatureReseau;
  String? _cellulePresenceIacm;
  String? _celluleTensionService;
  final _celluleTensionServiceCustomController = TextEditingController();
  final Set<String> _customSaisirFields = <String>{};
  String? _cellulePhoto;
  List<ElementControle> _celluleObservations = [];
  List<String> _cellulePhotos = [];
  String? _celluleSyncId;
  List<ElementControle> _celluleElements = [];
  
  // Contrôleurs pour le formulaire transformateur
  final _transfoNomController = TextEditingController();
  final _transfoTypeController = TextEditingController();
  final _transfoMarqueController = TextEditingController();
  final _transfoAnneeController = TextEditingController();
  final _transfoPuissanceController = TextEditingController();
  final _transfoTensionController = TextEditingController();
  final _transfoBuchholzController = TextEditingController();
  final _transfoTypeImmersionController = TextEditingController();
  final _transfoDgpt2Controller = TextEditingController();
  final _transfoRefroidissementController = TextEditingController();
  final _transfoRegimeController = TextEditingController();
  final _transfoCalibreDisjoncteurController = TextEditingController();
  final _transfoCourantReglageDisjoncteurController = TextEditingController();
  String? _transfoSectionCables;
  String? _transfoSectionCablePhase;
  String? _transfoSectionCableNeutre;
  final _transfoConducteursPhaseController = TextEditingController();
  final _transfoConducteursNeutreController = TextEditingController();
  bool _transfoNeutreManuallyModified = false;
  final _transfoIntensiteNominaleController = TextEditingController();
  String? _transfoCouplage;
  String? _transfoTypeReseau;
  final _transfoPccAmontController = TextEditingController();
  String? _transfoPuissanceUcc;
  final _transfoPuissanceUccController = TextEditingController();
  final _transfoIk3MaxController = TextEditingController();
  String? _transfoPhoto;
  List<String> _transfoPhotos = [];
  List<ElementControle> _transfoObservations = [];
  String? _transfoSyncId;
  List<ElementControle> _transfoElements = [];

  // Controllers d'observation par élément — garantit que le texte persiste
  // lors des reconstructions de widget (TextFormField initialValue ne suffit pas).
  final Map<ElementControle, TextEditingController> _obsControllersCellule = {};
  final Map<ElementControle, TextEditingController> _obsControllersTransfo = {};

  // Gestionnaire d'images et utilitaires
  final ImagePicker _picker = ImagePicker();

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFullScreenPhoto(List<String> photos, int index) {
    if (photos.isEmpty || index < 0 || index >= photos.length) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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

  Future<String> _savePhotoToAppDirectory(File photoFile, String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/mission_photos/$subDir');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photoFile.path.split('/').last}';
    final savedFile = await photoFile.copy('${mediaDir.path}/$fileName');
    return savedFile.path;
  }

  // Navigation slides pour le formulaire
  final PageController _slideController = PageController();
  int _currentSlide = 0;
  
  // Éléments vérifiés par défaut
  static List<String> get _celluleElementsParDefaut => DispositionsConstructivesRegistry.allCellulePoints;
  
  static List<String> get _transfoElementsParDefaut => DispositionsConstructivesRegistry.allTransformateurPoints;
  
  static const List<String> _presentAbsentOptions = ['Présent', 'Absent'];
  
  // Options pour les dropdowns du transformateur (certains champs)
  static const List<String> _ouiNonOptions = ['Oui', 'Non'];
  
  // ============================================================
  // INITIALISATION
  // ============================================================
  
  @override
  void initState() {
    super.initState();
    _resetCelluleForm();
    _resetTransformateurForm();
  }
  
  void _resetCelluleForm() {
    _celluleNomController.clear();
    _celluleFonctionController.clear();
    _celluleTypeController.clear();
    _celluleMarqueController.clear();
    _celluleModeleController.clear();
    _celluleAnneeController.clear();
    _celluleTensionController.clear();
    _cellulePouvoirController.clear();
    _celluleNumerotationController.text = '';
    _celluleParafoudresController.text = '';
    _celluleCalibreDisjoncteurController.clear();
    _celluleDepartController.clear();
    _celluleGamme = null;
    _celluleSectionCables = null;
    _celluleSectionCablePhase = null;
    _celluleSectionCableNeutre = null;
    _celluleConducteursPhaseController.clear();
    _celluleConducteursNeutreController.clear();
    _celluleNeutreManuallyModified = false;
    _celluleNatureReseau = null;
    _cellulePresenceIacm = null;
    _celluleTensionService = null;
    _celluleTensionServiceCustomController.clear();
    _customSaisirFields.remove('celluleTensionService');
    _customSaisirFields.remove('celluleTensionAssignee');
    _cellulePhoto = null;
    _celluleObservations = [];
    _cellulePhotos = [];
    _celluleSyncId = null;
    _celluleElements = _celluleElementsParDefaut.map((element) => ElementControle(
      elementControle: element,
      conforme: null,
      priorite: 3,
    )).toList();
  }
  
  void _resetTransformateurForm() {
    _transfoNomController.clear();
    _transfoTypeController.clear();
    _transfoMarqueController.clear();
    _transfoAnneeController.clear();
    _transfoPuissanceController.clear();
    _transfoTensionController.clear();
    _customSaisirFields.remove('transfoPuissanceAssignee');
    _customSaisirFields.remove('transfoTension');
    _customSaisirFields.remove('transfoPuissanceUcc');
    _customSaisirFields.remove('transfoRefroidissement');
    _transfoPuissanceUccController.clear();
    _transfoBuchholzController.text = '';
    _transfoTypeImmersionController.text = '';
    _transfoDgpt2Controller.text = '';
    _transfoRefroidissementController.text = '';
    _transfoRegimeController.text = '';
    _transfoCalibreDisjoncteurController.clear();
    _transfoCourantReglageDisjoncteurController.clear();
    _transfoSectionCables = null;
    _transfoSectionCablePhase = null;
    _transfoSectionCableNeutre = null;
    _transfoConducteursPhaseController.clear();
    _transfoConducteursNeutreController.clear();
    _transfoNeutreManuallyModified = false;
    _transfoIntensiteNominaleController.clear();
    _transfoCouplage = null;
    _transfoTypeReseau = null;
    _transfoPccAmontController.clear();
    _transfoPuissanceUcc = null;
    _transfoIk3MaxController.clear();
    _transfoPhoto = null;
    _transfoPhotos = [];
    _transfoObservations = [];
    _transfoSyncId = null;
    _transfoElements = _transfoElementsParDefaut.map((element) => ElementControle(
      elementControle: element,
      conforme: null,
      priorite: 3,
    )).toList();
  }
  
  void _chargerCellulePourEdition(Cellule cellule) {
    _celluleNomController.text = cellule.nom ?? '';
    _celluleFonctionController.text = cellule.fonction;
    _celluleTypeController.text = cellule.type;
    _celluleMarqueController.text = cellule.effectiveMarque;
    _celluleModeleController.text = cellule.effectiveModele;
    _celluleAnneeController.text = cellule.effectiveAnnee;
    _celluleTensionController.text = cellule.tensionAssignee;
    _cellulePouvoirController.text = cellule.pouvoirCoupure;
    _celluleNumerotationController.text = cellule.numerotation;
    _celluleParafoudresController.text = cellule.parafoudres;
    
    // Nouveaux champs
    _celluleCalibreDisjoncteurController.text = cellule.calibreDisjoncteur ?? '';
    _celluleDepartController.text = cellule.celluleDepart ?? '';
    _celluleGamme = cellule.gamme;
    _celluleSectionCables = cellule.sectionCables;
    _celluleSectionCablePhase = (cellule.effectiveSectionCablePhase?.isNotEmpty == true) ? cellule.effectiveSectionCablePhase : null;
    _celluleSectionCableNeutre = (cellule.effectiveSectionCableNeutre?.isNotEmpty == true) ? cellule.effectiveSectionCableNeutre : null;
    _celluleConducteursPhaseController.text = (cellule.effectiveConducteursPhase ?? 1).toString();
    _celluleConducteursNeutreController.text = (cellule.effectiveConducteursNeutre ?? 1).toString();
    _celluleNeutreManuallyModified = true;
    _celluleNatureReseau = cellule.natureReseau;
    _cellulePresenceIacm = cellule.presenceIacm;
    _celluleTensionService = cellule.tensionService;
    _celluleTensionServiceCustomController.text = cellule.tensionService ?? '';
    _customSaisirFields.remove('celluleTensionService');
    _customSaisirFields.remove('celluleTensionAssignee');
    _cellulePhoto = cellule.photo;
    _celluleObservations = List.from(cellule.observations ?? []);
    _cellulePhotos = List.from(cellule.photos);
    _celluleSyncId = cellule.syncId;
    
    _celluleElements = List.from(cellule.elementsVerifies);
    DispositionsConstructivesRegistry.ensureCompleteCelluleChecklist(_celluleElements);

    // Initialiser un controller par élément avec le texte d'observation existant
    for (final c in _obsControllersCellule.values) c.dispose();
    _obsControllersCellule.clear();
    for (final el in _celluleElements) {
      _obsControllersCellule[el] =
          TextEditingController(text: el.observation ?? '');
    }
  }
  
  void _chargerTransformateurPourEdition(TransformateurMTBT transfo) {
    _transfoNomController.text = transfo.nom ?? '';
    _transfoTypeController.text = transfo.typeTransformateur;
    _transfoMarqueController.text = transfo.effectiveMarque;
    _transfoAnneeController.text = transfo.effectiveAnneeFabrication;
    _transfoPuissanceController.text = transfo.puissanceAssignee;
    _transfoTensionController.text = transfo.tensionPrimaireSecondaire;
    _customSaisirFields.remove('transfoPuissanceAssignee');
    _customSaisirFields.remove('transfoTension');
    _transfoBuchholzController.text = transfo.relaisBuchholz;
    _transfoTypeImmersionController.text = transfo.typeImmersion ?? '';
    _transfoDgpt2Controller.text = transfo.presenceDGPT2 ?? '';
    _transfoRefroidissementController.text = transfo.typeRefroidissement;
    _transfoRegimeController.text = transfo.regimeNeutre;
    
    // Nouveaux champs
    _transfoCalibreDisjoncteurController.text = transfo.calibreDisjoncteur ?? '';
    _transfoCourantReglageDisjoncteurController.text = transfo.courantReglageDisjoncteur ?? '';
    _transfoSectionCables = transfo.sectionCables;
    _transfoSectionCablePhase = (transfo.effectiveSectionCablePhase?.isNotEmpty == true) ? transfo.effectiveSectionCablePhase : null;
    _transfoSectionCableNeutre = (transfo.effectiveSectionCableNeutre?.isNotEmpty == true) ? transfo.effectiveSectionCableNeutre : null;
    _transfoConducteursPhaseController.text = (transfo.effectiveConducteursPhase ?? 1).toString();
    _transfoConducteursNeutreController.text = (transfo.effectiveConducteursNeutre ?? 1).toString();
    _transfoNeutreManuallyModified = true;
    _transfoIntensiteNominaleController.text = transfo.intensiteNominale ?? '';
    _transfoCouplage = transfo.couplage;
    _transfoTypeReseau = transfo.typeReseau;
    _transfoPccAmontController.text = transfo.pccAmont ?? '';
    _transfoPuissanceUcc = transfo.puissanceUcc;
    _transfoPuissanceUccController.text = transfo.puissanceUcc ?? '';
    _transfoIk3MaxController.text = transfo.ik3Max ?? '';
    _transfoPhoto = transfo.photo;
    _transfoPhotos = List.from(transfo.photos);
    _transfoObservations = List.from(transfo.observations ?? []);
    _transfoSyncId = transfo.syncId;
    
    _transfoElements = List.from(transfo.elementsVerifies);
    DispositionsConstructivesRegistry.ensureCompleteTransformateurChecklist(_transfoElements);

    // Initialiser un controller par élément avec le texte d'observation existant
    for (final c in _obsControllersTransfo.values) c.dispose();
    _obsControllersTransfo.clear();
    for (final el in _transfoElements) {
      _obsControllersTransfo[el] =
          TextEditingController(text: el.observation ?? '');
    }
  }
  
  // ============================================================
  // GESTION DES SLIDES POUR FORMULAIRE
  // ============================================================
  
  List<List<ElementControle>> get _currentElementsSlides {
    final elements = _isEditingCellule ? _celluleElements : _transfoElements;
    final slides = <List<ElementControle>>[];
    for (int i = 0; i < elements.length; i += 3) {
      slides.add(elements.sublist(i, (i + 3).clamp(0, elements.length)));
    }
    return slides;
  }
  
  int get _totalSlides => 1 + _currentElementsSlides.length;
  bool get _isLastSlide => _currentSlide == _totalSlides - 1;
  
  void _nextSlide() {
    // Slide 0 = données (pas de validation conformité).
    // Slides 1..n = éléments de contrôle → conformité obligatoire.
    if (_currentSlide > 0) {
      final elementsSlides = _currentElementsSlides;
      final slideIndex = _currentSlide - 1; // offset car slide 0 = données
      if (slideIndex < elementsSlides.length) {
        final elements = elementsSlides[slideIndex];
        final nonRemplis = elements.where((e) => e.conforme == null && !e.estNA).toList();
        final sansPriorite = elements.where((e) => e.conforme == false && e.priorite == null).toList();
        for (var e in sansPriorite) {
          e.priorite = 3;
        }
        if (nonRemplis.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Veuillez renseigner la conformité de tous les éléments '
                '(${nonRemplis.length} non rempli${nonRemplis.length > 1 ? 's' : ''})',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
    }
    if (_slideController.hasClients && !_isLastSlide) {
      _slideController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousSlide() {
    if (_slideController.hasClients && _currentSlide > 0) {
      _slideController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // ============================================================
  // MÉTHODES CRUD - CELLULES
  // ============================================================
  
  void _ajouterCellule() {
    _resetCelluleForm();
    setState(() {
      _isEditing = true;
      _isEditingCellule = true;
      _editingIndex = null;
      _currentSlide = 0;
    });
    widget.onFormStateChanged?.call();
  }
  
  void _modifierCellule(int index) {
    _chargerCellulePourEdition(widget.cellules[index]);
    setState(() {
      _isEditing = true;
      _isEditingCellule = true;
      _editingIndex = index;
      _currentSlide = 0;
    });
    widget.onFormStateChanged?.call();
  }
  
  void _sauvegarderCellule() {
    final marque = _celluleMarqueController.text.trim();
    final modele = _celluleModeleController.text.trim();
    final annee = _celluleAnneeController.text.trim();
    final formattedMarqueModeleAnnee = [marque, modele, annee].where((s) => s.isNotEmpty).join(' / ');

    final newSyncId = _celluleSyncId ?? 'cellule_${DateTime.now().microsecondsSinceEpoch}';
    final nouvelleCellule = Cellule(
      fonction: _celluleFonctionController.text.trim(),
      type: _celluleTypeController.text.trim(),
      marqueModeleAnnee: formattedMarqueModeleAnnee,
      marque: marque,
      modele: modele,
      annee: annee,
      tensionAssignee: _celluleTensionController.text.trim(),
      pouvoirCoupure: _cellulePouvoirController.text.trim(),
      numerotation: _celluleNumerotationController.text,
      parafoudres: _celluleParafoudresController.text,
      elementsVerifies: _celluleElements,
      gamme: _celluleGamme,
      calibreDisjoncteur: _celluleCalibreDisjoncteurController.text.trim(),
      celluleDepart: _celluleDepartController.text.trim().isNotEmpty ? _celluleDepartController.text.trim() : null,
      sectionCables: _celluleSectionCablePhase ?? _celluleSectionCables,
      sectionCablePhase: _celluleSectionCablePhase,
      sectionCableNeutre: _celluleSectionCableNeutre,
      conducteursPhase: (_celluleSectionCablePhase != null && _celluleSectionCablePhase!.isNotEmpty && _celluleSectionCablePhase != '-')
          ? int.tryParse(_celluleConducteursPhaseController.text.trim())
          : null,
      conducteursNeutre: (_celluleSectionCableNeutre != null && _celluleSectionCableNeutre!.isNotEmpty && _celluleSectionCableNeutre != '-')
          ? int.tryParse(_celluleConducteursNeutreController.text.trim())
          : null,
      natureReseau: _celluleNatureReseau,
      presenceIacm: _cellulePresenceIacm,
      tensionService: _celluleTensionService,
      observations: _celluleObservations,
      photos: _cellulePhotos,
      syncId: newSyncId,
      nom: _celluleNomController.text.trim().isNotEmpty ? _celluleNomController.text.trim() : null,
      repere: (widget.localNom != null && widget.localNom!.trim().isNotEmpty) ? widget.localNom!.trim() : null,
      photo: _cellulePhoto,
    );
    
    final nouvellesCellules = List<Cellule>.from(widget.cellules);
    if (_editingIndex != null) {
      nouvellesCellules[_editingIndex!] = nouvelleCellule;
    } else {
      nouvellesCellules.add(nouvelleCellule);
    }
    
    widget.onCellulesChanged(nouvellesCellules);
    
    setState(() {
      _isEditing = false;
    });
    widget.onFormStateChanged?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_editingIndex != null ? 'Cellule modifiée' : 'Cellule ajoutée'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _supprimerCellule(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la cellule'),
        content: const Text('Voulez-vous vraiment supprimer cette cellule ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final nouvellesCellules = List<Cellule>.from(widget.cellules)..removeAt(index);
      widget.onCellulesChanged(nouvellesCellules);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cellule supprimée'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    }
  }


  // ============================================================
  // API PUBLIQUE — contrôle par le parent via les boutons principaux
  // ============================================================

  bool get isFormOpen => _isEditing;
  bool get isFormFirstSlide => _isEditing && _currentSlide == 0;
  bool get isFormLastSlide => _isEditing && _isLastSlide;
  bool get isEditingExisting => _isEditing && _editingIndex != null;
  String get formNextLabel => _isLastSlide ? 'Terminer' : 'Suivant';

  void sauvegarderEtFermer() {
    if (_isEditingCellule) {
      _sauvegarderCellule();
    } else {
      _sauvegarderTransformateur();
    }
  }

  void handleFormNext() {
    if (_isLastSlide) {
      // Valider la conformité de la dernière slide d'éléments avant de sauvegarder.
      if (_currentSlide > 0) {
        final elementsSlides = _currentElementsSlides;
        final slideIndex = _currentSlide - 1;
        if (slideIndex < elementsSlides.length) {
          final elements = elementsSlides[slideIndex];
          final nonRemplis = elements.where((e) => e.conforme == null && !e.estNA).toList();
          final sansPriorite = elements.where((e) => e.conforme == false && e.priorite == null).toList();
          if (nonRemplis.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Veuillez renseigner la conformité de tous les éléments (${nonRemplis.length} non rempli${nonRemplis.length > 1 ? 's' : ''})'),
              backgroundColor: Colors.orange, duration: const Duration(seconds: 2),
            ));
            widget.onFormStateChanged?.call();
            return;
          }
          if (sansPriorite.isNotEmpty) {
            for (var e in sansPriorite) {
              e.priorite = 3;
            }
          }
        }
      }
      if (_isEditingCellule) {
        _sauvegarderCellule();
      } else {
        _sauvegarderTransformateur();
      }
    } else {
      _nextSlide();
    }
    widget.onFormStateChanged?.call();
  }

  void handleFormPrevious() {
    _previousSlide();
    widget.onFormStateChanged?.call();
  }

  void cancelForm() {
    setState(() => _isEditing = false);
    widget.onFormStateChanged?.call();
  }
  
  // ============================================================
  // MÉTHODES CRUD - TRANSFORMATEURS
  // ============================================================
  
  void _ajouterTransformateur() {
    _resetTransformateurForm();
    setState(() {
      _isEditing = true;
      _isEditingCellule = false;
      _editingIndex = null;
      _currentSlide = 0;
    });
    widget.onFormStateChanged?.call();
  }
  
  void _modifierTransformateur(int index) {
    _chargerTransformateurPourEdition(widget.transformateurs[index]);
    setState(() {
      _isEditing = true;
      _isEditingCellule = false;
      _editingIndex = index;
      _currentSlide = 0;
    });
    widget.onFormStateChanged?.call();
  }
  
  void _sauvegarderTransformateur() {
    final marque = _transfoMarqueController.text.trim();
    final annee = _transfoAnneeController.text.trim();
    final formattedMarqueAnnee = [marque, annee].where((s) => s.isNotEmpty).join(' / ');

    final finalSyncId = _transfoSyncId ?? 'transfo_${DateTime.now().microsecondsSinceEpoch}';
    final nouveauTransformateur = TransformateurMTBT(
      typeTransformateur: _transfoTypeController.text.trim(),
      marqueAnnee: formattedMarqueAnnee,
      marque: marque,
      anneeFabrication: annee,
      puissanceAssignee: _transfoPuissanceController.text.trim(),
      tensionPrimaireSecondaire: _transfoTensionController.text.trim(),
      relaisBuchholz: _transfoBuchholzController.text,
      typeImmersion: _transfoTypeImmersionController.text.trim().isNotEmpty
          ? _transfoTypeImmersionController.text.trim()
          : null,
      presenceDGPT2: _transfoDgpt2Controller.text.trim().isNotEmpty
          ? _transfoDgpt2Controller.text.trim()
          : null,
      typeRefroidissement: _transfoRefroidissementController.text,
      regimeNeutre: _transfoRegimeController.text,
      elementsVerifies: _transfoElements,
      calibreDisjoncteur: _transfoCalibreDisjoncteurController.text.trim(),
      courantReglageDisjoncteur: _transfoCourantReglageDisjoncteurController.text.trim().isNotEmpty
          ? _transfoCourantReglageDisjoncteurController.text.trim()
          : null,
      sectionCables: _transfoSectionCablePhase ?? _transfoSectionCables,
      sectionCablePhase: _transfoSectionCablePhase,
      sectionCableNeutre: _transfoSectionCableNeutre,
      conducteursPhase: (_transfoSectionCablePhase != null && _transfoSectionCablePhase!.isNotEmpty && _transfoSectionCablePhase != '-')
          ? int.tryParse(_transfoConducteursPhaseController.text.trim())
          : null,
      conducteursNeutre: (_transfoSectionCableNeutre != null && _transfoSectionCableNeutre!.isNotEmpty && _transfoSectionCableNeutre != '-')
          ? int.tryParse(_transfoConducteursNeutreController.text.trim())
          : null,
      observations: _transfoObservations,
      syncId: finalSyncId,
      intensiteNominale: _transfoIntensiteNominaleController.text.trim(),
      couplage: _transfoCouplage,
      typeReseau: _transfoTypeReseau,
      pccAmont: _transfoPccAmontController.text.trim(),
      puissanceUcc: _transfoPuissanceUcc,
      ik3Max: _transfoIk3MaxController.text.trim(),
      nom: _transfoNomController.text.trim().isNotEmpty ? _transfoNomController.text.trim() : null,
      repere: (widget.localNom != null && widget.localNom!.trim().isNotEmpty) ? widget.localNom!.trim() : null,
      photo: _transfoPhoto,
      photos: _transfoPhotos,
    );
    
    final nouveauxTransformateurs = List<TransformateurMTBT>.from(widget.transformateurs);
    if (_editingIndex != null) {
      nouveauxTransformateurs[_editingIndex!] = nouveauTransformateur;
    } else {
      nouveauxTransformateurs.add(nouveauTransformateur);
    }
    
    widget.onTransformateursChanged(nouveauxTransformateurs);
    
    setState(() {
      _isEditing = false;
    });
    widget.onFormStateChanged?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_editingIndex != null ? 'Transformateur modifié' : 'Transformateur ajouté'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _supprimerTransformateur(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le transformateur'),
        content: const Text('Voulez-vous vraiment supprimer ce transformateur ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final nouveauxTransformateurs = List<TransformateurMTBT>.from(widget.transformateurs)..removeAt(index);
      widget.onTransformateursChanged(nouveauxTransformateurs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transformateur supprimé'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    }
  }
  
  void _annulerEdition() {
    setState(() {
      _isEditing = false;
    });
  }


  
  // ============================================================
  // CONSTRUCTEURS DE WIDGETS
  // ============================================================
  
  Widget _buildModeSelector(bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 380;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
      ),
      child: Row(
        children: [
          // Onglet CELLULES
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentMode = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? (isVerySmallScreen ? 10 : 12) : 14,
                  horizontal: isSmallScreen ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: _currentMode == 0 ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  boxShadow: _currentMode == 0
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: isSmallScreen ? 4 : 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Texte avec gestion du débordement
                    Flexible(
                      child: Text(
                        'CELLULES',
                        style: TextStyle(
                          fontSize: isSmallScreen ? (isVerySmallScreen ? 11 : 13) : 14,
                          fontWeight: FontWeight.w600,
                          color: _currentMode == 0 ? Colors.white : Colors.grey.shade700,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    // Badge compteur
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: _currentMode == 0
                            ? Colors.white.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                      ),
                      child: Text(
                        '${widget.cellules.length}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? (isVerySmallScreen ? 10 : 11) : 12,
                          fontWeight: FontWeight.bold,
                          color: _currentMode == 0 ? Colors.white : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Séparateur visuel entre les deux onglets
          Container(
            width: 1,
            height: isSmallScreen ? 24 : 28,
            color: Colors.grey.shade300,
          ),
          
          // Onglet TRANSFORMATEURS
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentMode = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? (isVerySmallScreen ? 10 : 12) : 14,
                  horizontal: isSmallScreen ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: _currentMode == 1 ? Colors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  boxShadow: _currentMode == 1
                      ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: isSmallScreen ? 4 : 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Texte avec gestion du débordement
                    Flexible(
                      child: Text(
                        'TRANSFORMATEURS',
                        style: TextStyle(
                          fontSize: isSmallScreen ? (isVerySmallScreen ? 11 : 13) : 14,
                          fontWeight: FontWeight.w600,
                          color: _currentMode == 1 ? Colors.white : Colors.grey.shade700,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    // Badge compteur (rouge si vide pour attirer l'attention)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: _currentMode == 1
                            ? Colors.white.withOpacity(0.2)
                            : (widget.transformateurs.isEmpty
                                ? Colors.red.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                      ),
                      child: Text(
                        '${widget.transformateurs.length}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? (isVerySmallScreen ? 10 : 11) : 12,
                          fontWeight: FontWeight.bold,
                          color: _currentMode == 1
                              ? Colors.white
                              : (widget.transformateurs.isEmpty
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ============================================================
  // LISTE DES CELLULES
  // ============================================================
  
  Widget _buildCellulesList(bool isSmallScreen) {
    if (widget.cellules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cell_tower, size: isSmallScreen ? 60 : 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Aucune cellule', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Ajoutez une cellule pour ce local', style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      itemCount: widget.cellules.length,
      itemBuilder: (context, index) {
        final cellule = widget.cellules[index];
        return _buildCelluleCard(cellule, index, isSmallScreen);
      },
    );
  }
  
  Widget _buildCelluleCard(Cellule cellule, int index, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 28 : 32,
                  height: isSmallScreen ? 28 : 32,
                  decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8)),
                  child: Center(
                    child: Text('${index + 1}', style: TextStyle(fontSize: isSmallScreen ? 11 : 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Expanded(
                  child: Text(
                    (cellule.nom != null && cellule.nom!.trim().isNotEmpty)
                        ? (cellule.type.isNotEmpty ? '${cellule.nom!.trim()} (${cellule.type})' : cellule.nom!.trim())
                        : (cellule.type.isNotEmpty ? cellule.type : 'Cellule'),
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: isSmallScreen ? 18 : 20, color: Colors.blue),
                  onPressed: () => _modifierCellule(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: isSmallScreen ? 18 : 20, color: Colors.red),
                  onPressed: () => _supprimerCellule(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                if (cellule.nom != null && cellule.nom!.trim().isNotEmpty)
                  _buildInfoRow('Nom de la cellule', cellule.nom!.trim(), isSmallScreen),
                if (cellule.photo != null && cellule.photo!.trim().isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          'Photo :',
                          style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: SafeFileImage(
                              path: cellule.photo!.trim(),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (cellule.fonction.isNotEmpty)
                  _buildInfoRow('Fonction', cellule.fonction, isSmallScreen),
                if (cellule.gamme != null && cellule.gamme!.isNotEmpty)
                  _buildInfoRow('Gamme', cellule.gamme!, isSmallScreen),
                if (cellule.marqueModeleAnnee.isNotEmpty)
                  _buildInfoRow('Marque/Modèle', cellule.marqueModeleAnnee, isSmallScreen),
                if (cellule.tensionAssignee.isNotEmpty)
                  _buildInfoRow('Tension assignée', cellule.tensionAssignee, isSmallScreen),
                if (cellule.calibreDisjoncteur != null && cellule.calibreDisjoncteur!.isNotEmpty)
                  _buildInfoRow('Calibre disjoncteur', cellule.calibreDisjoncteur!, isSmallScreen),
                if (cellule.effectiveSectionCablePhase != null && cellule.effectiveSectionCablePhase!.isNotEmpty && cellule.effectiveSectionCablePhase != '-')
                  _buildInfoRow(
                    'Section Phase',
                    cellule.effectiveConducteursPhase != null
                        ? '${cellule.effectiveConducteursPhase} × ${cellule.effectiveSectionCablePhase}'
                        : cellule.effectiveSectionCablePhase!,
                    isSmallScreen,
                  )
                else if (cellule.sectionCables != null && cellule.sectionCables!.isNotEmpty)
                  _buildInfoRow('Section câbles', cellule.sectionCables!, isSmallScreen),
                if (cellule.effectiveSectionCableNeutre != null && cellule.effectiveSectionCableNeutre!.isNotEmpty && cellule.effectiveSectionCableNeutre != '-')
                  _buildInfoRow(
                    'Section Neutre',
                    cellule.effectiveConducteursNeutre != null
                        ? '${cellule.effectiveConducteursNeutre} × ${cellule.effectiveSectionCableNeutre}'
                        : cellule.effectiveSectionCableNeutre!,
                    isSmallScreen,
                  ),
                if (cellule.natureReseau != null && cellule.natureReseau!.isNotEmpty)
                  _buildInfoRow('Nature réseau', '${cellule.natureReseau!}${cellule.presenceIacm == 'Oui' ? ' (IACM)' : ''}', isSmallScreen),
                if (cellule.observations != null && cellule.observations!.isNotEmpty)
                  _buildInfoRow('Observations', '${cellule.observations!.length} observation(s)', isSmallScreen, color: Colors.red.shade700),
                if (cellule.elementsVerifies.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: isSmallScreen ? 8 : 10),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8)),
                      child: Center(
                        child: Text(
                          '${cellule.elementsVerifies.length} élément(s) vérifié(s)',
                          style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey.shade700),
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
  
  // ============================================================
  // LISTE DES TRANSFORMATEURS
  // ============================================================
  
  Widget _buildTransformateursList(bool isSmallScreen) {
    if (widget.transformateurs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.transform, size: isSmallScreen ? 60 : 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Aucun transformateur', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Au moins un transformateur est requis', style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: Colors.orange.shade700)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      itemCount: widget.transformateurs.length,
      itemBuilder: (context, index) {
        final transfo = widget.transformateurs[index];
        return _buildTransformateurCard(transfo, index, isSmallScreen);
      },
    );
  }
  
  Widget _buildTransformateurCard(TransformateurMTBT transfo, int index, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 28 : 32,
                  height: isSmallScreen ? 28 : 32,
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8)),
                  child: Center(
                    child: Text('${index + 1}', style: TextStyle(fontSize: isSmallScreen ? 11 : 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Expanded(
                  child: Text(
                    transfo.typeTransformateur.isNotEmpty ? transfo.typeTransformateur : 'Transformateur',
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: isSmallScreen ? 18 : 20, color: Colors.orange),
                  onPressed: () => _modifierTransformateur(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: isSmallScreen ? 18 : 20, color: Colors.red),
                  onPressed: () => _supprimerTransformateur(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                if (transfo.marqueAnnee.isNotEmpty)
                  _buildInfoRow('Marque/Année', transfo.marqueAnnee, isSmallScreen),
                if (transfo.puissanceAssignee.isNotEmpty)
                  _buildInfoRow('Puissance', transfo.puissanceAssignee, isSmallScreen),
                if (transfo.regimeNeutre.isNotEmpty)
                  _buildInfoRow('Régime neutre', transfo.regimeNeutre, isSmallScreen),
                if (transfo.effectiveSectionCablePhase != null && transfo.effectiveSectionCablePhase!.isNotEmpty && transfo.effectiveSectionCablePhase != '-')
                  _buildInfoRow(
                    'Section Phase',
                    transfo.effectiveConducteursPhase != null
                        ? '${transfo.effectiveConducteursPhase} × ${transfo.effectiveSectionCablePhase}'
                        : transfo.effectiveSectionCablePhase!,
                    isSmallScreen,
                  )
                else if (transfo.sectionCables != null && transfo.sectionCables!.isNotEmpty)
                  _buildInfoRow('Section câbles', transfo.sectionCables!, isSmallScreen),
                if (transfo.effectiveSectionCableNeutre != null && transfo.effectiveSectionCableNeutre!.isNotEmpty && transfo.effectiveSectionCableNeutre != '-')
                  _buildInfoRow(
                    'Section Neutre',
                    transfo.effectiveConducteursNeutre != null
                        ? '${transfo.effectiveConducteursNeutre} × ${transfo.effectiveSectionCableNeutre}'
                        : transfo.effectiveSectionCableNeutre!,
                    isSmallScreen,
                  ),
                if (transfo.elementsVerifies.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: isSmallScreen ? 8 : 10),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8)),
                      child: Center(
                        child: Text(
                          '${transfo.elementsVerifies.length} élément(s) vérifié(s)',
                          style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey.shade700),
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
  
  // ============================================================
  // FORMULAIRE SLIDES (CELLULE)
  // ============================================================
  
  Widget _buildCelluleFormulaireSlides(bool isSmallScreen) {
    final elementsSlides = _currentElementsSlides;
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: isSmallScreen ? 18 : 20),
              SizedBox(width: isSmallScreen ? 8 : 10),
              Expanded(
                child: Text(
                  _editingIndex != null ? 'MODIFIER LA CELLULE' : 'NOUVELLE CELLULE',
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                ),
              ),
              Text('${_currentSlide + 1}/$_totalSlides', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.blue.shade600)),
              SizedBox(width: isSmallScreen ? 8 : 12),
              InkWell(
                onTap: _editingIndex != null ? sauvegarderEtFermer : cancelForm,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8, vertical: isSmallScreen ? 3 : 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_editingIndex != null ? Icons.check : Icons.close, size: isSmallScreen ? 14 : 16, color: Colors.blue.shade900),
                      const SizedBox(width: 4),
                      Text(
                        _editingIndex != null ? 'Terminer' : 'Fermer',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 10),
          child: LinearProgressIndicator(
            value: (_currentSlide + 1) / _totalSlides,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 3,
          ),
        ),
        
        Expanded(
          child: PageView.builder(
            controller: _slideController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentSlide = index);
              widget.onFormStateChanged?.call();
            },
            itemCount: _totalSlides,
            itemBuilder: (context, slideIndex) {
              if (slideIndex == 0) {
                return _buildCelluleDonneesSlide(isSmallScreen);
              } else {
                final elementSlideIndex = slideIndex - 1;
                if (elementSlideIndex < elementsSlides.length) {
                  return _buildElementsSlide(
                    elements: elementsSlides[elementSlideIndex],
                    isCellule: true,
                    isSmallScreen: isSmallScreen,
                  );
                }
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildCelluleDonneesSlide(bool isSmallScreen) {
    final typesGamme = CelluleGammes.getTypesForGamme(_celluleGamme);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1 : Identification
          _buildFormSectionHeader('IDENTIFICATION', isSmallScreen),
          SizedBox(height: isSmallScreen ? 8 : 10),
          _buildReadOnlyInfoField('Repère', (widget.localNom != null && widget.localNom!.trim().isNotEmpty) ? widget.localNom!.trim() : 'Nom du local non défini', isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(_celluleNomController, 'Nom de la cellule (ex: Cellule Arrivée 1)', isSmallScreen, optional: true),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildDropdown(
            _celluleFonctionController,
            'Fonction de la cellule',
            InstallationFieldsRegistry.fonctionCelluleOptions,
            isSmallScreen,
            optional: true,
            onSelected: (val) {
              setState(() {});
            },
          ),
          if (_celluleFonctionController.text.trim().toLowerCase() == 'cellule disjoncteur') ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildTextField(
              _celluleDepartController,
              'Cellule départ (ex: Départ Transfo 1, Départ Ligne)',
              isSmallScreen,
              optional: true,
            ),
          ],
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(_celluleMarqueController, 'Marque', isSmallScreen, optional: true),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(_celluleModeleController, 'Modèle', isSmallScreen, optional: true),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildDropdown(_celluleAnneeController, 'Année de fabrication', InstallationFieldsRegistry.generateYearsList(), isSmallScreen, optional: true),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildCellulePhotoPicker(isSmallScreen),
          
          SizedBox(height: isSmallScreen ? 20 : 26),
          
          // Section 2 : Caractéristiques techniques HTA
          _buildFormSectionHeader('CARACTÉRISTIQUES ALIMENTATION MT', isSmallScreen),
          SizedBox(height: isSmallScreen ? 8 : 10),
          // Type de cellule (indépendant)
          _buildDropdownVal(
            _celluleTypeController.text.isNotEmpty ? _celluleTypeController.text : null,
            'Type de cellule',
            CelluleTypesRegistry.getAvailableTypes(_celluleTypeController.text),
            isSmallScreen,
            (value) {
              setState(() {
                _celluleTypeController.text = value ?? '';
              });
            },
            optional: true,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildSelectOrCustomInput(
            fieldKey: 'celluleTensionService',
            label: 'Tension de service',
            standardOptions: InstallationFieldsRegistry.tensionDeServiceOptions,
            currentValue: _celluleTensionService,
            customController: _celluleTensionServiceCustomController,
            isSmallScreen: isSmallScreen,
            onValueChanged: (val) {
              setState(() {
                _celluleTensionService = val;
                if (_celluleTensionServiceCustomController.text != (val ?? '')) {
                  _celluleTensionServiceCustomController.text = val ?? '';
                }
              });
            },
            suffixText: 'kV',
            keyboardType: TextInputType.text,
            optional: true,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildSelectOrCustomInput(
            fieldKey: 'celluleTensionAssignee',
            label: 'Tension assignée',
            standardOptions: InstallationFieldsRegistry.tensionAssigneeOptions,
            currentValue: _celluleTensionController.text,
            customController: _celluleTensionController,
            isSmallScreen: isSmallScreen,
            onValueChanged: (val) {
              setState(() {
                if (_celluleTensionController.text != (val ?? '')) {
                  _celluleTensionController.text = val ?? '';
                }
              });
            },
            suffixText: 'kV',
            keyboardType: TextInputType.text,
            optional: true,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(
            _cellulePouvoirController,
            'Pouvoir de coupure',
            isSmallScreen,
            optional: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            suffixText: 'kA',
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(
            _celluleCalibreDisjoncteurController,
            'Calibre du disjoncteur',
            isSmallScreen,
            optional: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            suffixText: 'A',
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildDropdownVal(
            _celluleSectionCablePhase,
            'Section de câble phase',
            _sectionCableOptions,
            isSmallScreen,
            (value) {
              setState(() {
                _celluleSectionCablePhase = value;
                _celluleSectionCables = value;
                if (value != null && value.isNotEmpty && value != '-') {
                  if (_celluleConducteursPhaseController.text.trim().isEmpty) {
                    _celluleConducteursPhaseController.text = '1';
                  }
                } else {
                  _celluleConducteursPhaseController.text = '';
                }
              });
            },
            optional: true,
          ),
          if (_celluleSectionCablePhase != null && _celluleSectionCablePhase!.isNotEmpty && _celluleSectionCablePhase != '-') ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildTextField(
              _celluleConducteursPhaseController,
              'Nombre de conducteurs phase',
              isSmallScreen,
              optional: false,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildDropdownVal(
            _celluleNatureReseau,
            'Nature du réseau',
            const ['Souterrain', 'Aérien'],
            isSmallScreen,
            (value) {
              setState(() {
                _celluleNatureReseau = value;
                if (value != 'Aérien') {
                  _cellulePresenceIacm = null;
                }
              });
            },
            optional: true,
          ),
          
          if (_celluleNatureReseau == 'Aérien') ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildDropdownVal(
              _cellulePresenceIacm,
              'Présence d\'une IACM',
              const ['Oui', 'Non'],
              isSmallScreen,
              (value) => setState(() => _cellulePresenceIacm = value),
              optional: true,
            ),
          ],
          
          SizedBox(height: isSmallScreen ? 12 : 16),

          _buildDropdown(_celluleNumerotationController, 'Numérotation / repérage', _presentAbsentOptions, isSmallScreen, optional: true),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildDropdown(_celluleParafoudresController, 'Parafoudres installés sur l\'arrivée', _presentAbsentOptions, isSmallScreen, optional: true),
          
          SizedBox(height: isSmallScreen ? 20 : 26),
          
          // Section 3 : Observations
          _buildFormSectionHeader('OBSERVATIONS', isSmallScreen),
          SizedBox(height: isSmallScreen ? 8 : 10),
          
          if (_celluleObservations.isNotEmpty)
            Column(
              children: _celluleObservations.asMap().entries.map((entry) {
                final index = entry.key;
                final obsElement = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
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
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                _celluleObservations.removeAt(index);
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ObservationEnrichieWidget(
                        element: obsElement,
                        onChanged: () => setState(() {}),
                        color: Colors.blue,
                        onSavePhoto: widget.onSavePhoto,
                        showPriority: false,
                        sectionType: 'cellule',
                        enableNormativeSearch: true,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _celluleObservations.add(ElementControle(
                    elementControle: '',
                    conforme: null,
                    priorite: 1,
                  ));
                });
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text('AJOUTER UNE OBSERVATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellulePhotoPicker(bool isSmallScreen) {
    final hasPhoto = _cellulePhoto != null && _cellulePhoto!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photo de la cellule',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              '(Optionnel)',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hasPhoto)
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showFullScreenPhoto([_cellulePhoto!], 0),
                child: Container(
                  height: isSmallScreen ? 160 : 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SafeFileImage(
                      path: _cellulePhoto!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: _showCellulePhotoOptions,
                      tooltip: 'Remplacer la photo',
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _cellulePhoto = null),
                      tooltip: 'Supprimer la photo',
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _showCellulePhotoOptions,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: isSmallScreen ? 100 : 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: isSmallScreen ? 26 : 30, color: AppTheme.primaryBlue),
                  const SizedBox(height: 6),
                  Text(
                    'Ajouter une photo de la cellule',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showCellulePhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _prendrePhotoCellule();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(context);
                _choisirPhotoCelluleDepuisGalerie();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _prendrePhotoCellule() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        await GalleryPhotoService.saveToGallery(File(photo.path));
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'cellules');
        setState(() => _cellulePhoto = savedPath);
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoCelluleDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'cellules');
        setState(() => _cellulePhoto = savedPath);
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  Widget _buildTransfoPhotoPicker(bool isSmallScreen) {
    final hasPhoto = _transfoPhoto != null && _transfoPhoto!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photo du transformateur',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              '(Optionnel)',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hasPhoto)
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showFullScreenPhoto([_transfoPhoto!], 0),
                child: Container(
                  height: isSmallScreen ? 160 : 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SafeFileImage(
                      path: _transfoPhoto!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: _showTransfoPhotoOptions,
                      tooltip: 'Remplacer la photo',
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _transfoPhoto = null),
                      tooltip: 'Supprimer la photo',
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _showTransfoPhotoOptions,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: isSmallScreen ? 100 : 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: isSmallScreen ? 26 : 30, color: Colors.orange.shade800),
                  const SizedBox(height: 6),
                  Text(
                    'Ajouter une photo du transformateur',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showTransfoPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.orange.shade800),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _prendrePhotoTransfo();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.orange.shade800),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(context);
                _choisirPhotoTransfoDepuisGalerie();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _prendrePhotoTransfo() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        await GalleryPhotoService.saveToGallery(File(photo.path));
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'transformateurs');
        setState(() => _transfoPhoto = savedPath);
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoTransfoDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'transformateurs');
        setState(() => _transfoPhoto = savedPath);
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  Widget _buildFormSectionHeader(String title, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8, horizontal: isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: AppTheme.primaryBlue, width: 4)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkBlue,
        ),
      ),
    );
  }
  
  // ============================================================
  // FORMULAIRE SLIDES (TRANSFORMATEUR)
  // ============================================================
  
  Widget _buildTransformateurFormulaireSlides(bool isSmallScreen) {
    final elementsSlides = _currentElementsSlides;
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          color: Colors.orange.shade50,
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.orange, size: isSmallScreen ? 18 : 20),
              SizedBox(width: isSmallScreen ? 8 : 10),
              Expanded(
                child: Text(
                  _editingIndex != null ? 'MODIFIER LE TRANSFORMATEUR' : 'NOUVEAU TRANSFORMATEUR',
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                ),
              ),
              Text('${_currentSlide + 1}/$_totalSlides', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.orange.shade600)),
              SizedBox(width: isSmallScreen ? 8 : 12),
              InkWell(
                onTap: _editingIndex != null ? sauvegarderEtFermer : cancelForm,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8, vertical: isSmallScreen ? 3 : 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_editingIndex != null ? Icons.check : Icons.close, size: isSmallScreen ? 14 : 16, color: Colors.orange.shade900),
                      const SizedBox(width: 4),
                      Text(
                        _editingIndex != null ? 'Terminer' : 'Fermer',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 10),
          child: LinearProgressIndicator(
            value: (_currentSlide + 1) / _totalSlides,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 3,
          ),
        ),
        
        Expanded(
          child: PageView.builder(
            controller: _slideController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentSlide = index);
              widget.onFormStateChanged?.call();
            },
            itemCount: _totalSlides,
            itemBuilder: (context, slideIndex) {
              if (slideIndex == 0) {
                return _buildTransformateurDonneesSlide(isSmallScreen);
              } else {
                final elementSlideIndex = slideIndex - 1;
                if (elementSlideIndex < elementsSlides.length) {
                  return _buildElementsSlide(
                    elements: elementsSlides[elementSlideIndex],
                    isCellule: false,
                    isSmallScreen: isSmallScreen,
                  );
                }
                return const SizedBox.shrink();
              }
            },
          ),
        ),
        
      ],
    );
  }
  
  Widget _buildTransformateurDonneesSlide(bool isSmallScreen) {
    void recalculateIk3Max() {
      final ik3 = InstallationFieldsRegistry.calculateIk3Max(
        puissanceKva: _transfoPuissanceController.text,
        uccPercent: _transfoPuissanceUcc ?? '',
      );
      if (ik3.isNotEmpty) {
        _transfoIk3MaxController.text = ik3;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        children: [
          // 0. Repère & Nom du transformateur
          _buildReadOnlyInfoField('Repère', (widget.localNom != null && widget.localNom!.trim().isNotEmpty) ? widget.localNom!.trim() : 'Nom du local non défini', isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildTextField(_transfoNomController, 'Nom du transformateur (ex: Transfo T1)', isSmallScreen, optional: true),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 1. Type de transformateur
          _buildDropdownVal(
            _transfoTypeController.text.isNotEmpty ? _transfoTypeController.text : null,
            'Type de transformateur',
            InstallationFieldsRegistry.typeTransformateurOptions,
            isSmallScreen,
            (value) {
              setState(() {
                _transfoTypeController.text = value ?? '';
              });
            },
            optional: true,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Champ conditionnel : Type d'immersion & Protection (Buchholz / DGPT2)
          if (_transfoTypeController.text.trim().toUpperCase() == 'IMMERGÉ' ||
              _transfoTypeController.text.trim().toUpperCase() == 'IMMERGE') ...[
            _buildDropdownVal(
              _transfoTypeImmersionController.text.isNotEmpty ? _transfoTypeImmersionController.text : null,
              'Type d\'immersion',
              InstallationFieldsRegistry.typeImmersionOptions,
              isSmallScreen,
              (value) {
                setState(() {
                  _transfoTypeImmersionController.text = value ?? '';
                });
              },
              optional: true,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Protection conditionnelle basée sur le type d'immersion
            if (_transfoTypeImmersionController.text == InstallationFieldsRegistry.immersionConservateur) ...[
              _buildDropdown(_transfoBuchholzController, 'Présence de relais Bucholz', _ouiNonOptions, isSmallScreen, optional: true),
              SizedBox(height: isSmallScreen ? 12 : 16),
            ] else if (_transfoTypeImmersionController.text == InstallationFieldsRegistry.immersionHermetique) ...[
              _buildDropdown(_transfoDgpt2Controller, 'Présence de DGPT2', _ouiNonOptions, isSmallScreen, optional: true),
              SizedBox(height: isSmallScreen ? 12 : 16),
            ] else if (_transfoBuchholzController.text.isNotEmpty) ...[
              // Fallback mission ancienne : typeImmersion non renseigné mais valeur Buchholz existante
              _buildDropdown(_transfoBuchholzController, 'Présence de relais Bucholz', _ouiNonOptions, isSmallScreen, optional: true),
              SizedBox(height: isSmallScreen ? 12 : 16),
            ],
          ],

          // 2. Marque & Année de fabrication
          _buildTextField(_transfoMarqueController, 'Marque', isSmallScreen, optional: true),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildDropdown(_transfoAnneeController, 'Année de fabrication', InstallationFieldsRegistry.generateYearsList(), isSmallScreen, optional: true),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 3. Puissance assignée (kVA)
          _buildSelectOrCustomInput(
            fieldKey: 'transfoPuissanceAssignee',
            label: 'Puissance Transformateur',
            standardOptions: InstallationFieldsRegistry.puissanceTransformateurOptions,
            currentValue: _transfoPuissanceController.text,
            customController: _transfoPuissanceController,
            isSmallScreen: isSmallScreen,
            onValueChanged: (val) {
              setState(() {
                _transfoPuissanceController.text = val ?? '';
                recalculateIk3Max();
              });
            },
            suffixText: 'kVA',
            keyboardType: TextInputType.text,
            optional: true,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 4. Intensité nominale (A)
          _buildTextField(
            _transfoIntensiteNominaleController,
            'Intensité nominale',
            isSmallScreen,
            optional: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            suffixText: 'A',
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 5. Tension primaire / secondaire
          _buildSelectOrCustomInput(
            fieldKey: 'transfoTension',
            label: 'Tension MT / BT',
            standardOptions: InstallationFieldsRegistry.tensionPrimaireSecondaireOptions,
            currentValue: _transfoTensionController.text,
            customController: _transfoTensionController,
            isSmallScreen: isSmallScreen,
            onValueChanged: (val) {
              setState(() {
                _transfoTensionController.text = val ?? '';
              });
            },
            keyboardType: TextInputType.text,
            optional: true,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 6. Couplage
          _buildDropdownVal(
            _transfoCouplage,
            'Couplage',
            InstallationFieldsRegistry.couplageOptions,
            isSmallScreen,
            (value) => setState(() => _transfoCouplage = value),
            optional: true,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 7. Type de réseau
          _buildDropdownVal(
            _transfoTypeReseau,
            'Type de réseau',
            InstallationFieldsRegistry.typeReseauOptions,
            isSmallScreen,
            (value) {
              setState(() {
                _transfoTypeReseau = value;
                final pccSuggested = InstallationFieldsRegistry.getPccAmontForTypeReseau(value ?? '');
                if (pccSuggested.isNotEmpty || value == 'Réseau industriel') {
                  _transfoPccAmontController.text = pccSuggested;
                }
              });
            },
            optional: true,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 8. PCC amont
          _buildTextField(
            _transfoPccAmontController,
            'PCC amont',
            isSmallScreen,
            optional: true,
            suffixText: 'MVA',
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 9. Puissance UCC (%)
          _buildSelectOrCustomInput(
            fieldKey: 'transfoPuissanceUcc',
            label: 'Puissance UCC',
            standardOptions: InstallationFieldsRegistry.puissanceUccOptions,
            currentValue: _transfoPuissanceUcc,
            customController: _transfoPuissanceUccController,
            isSmallScreen: isSmallScreen,
            onValueChanged: (val) {
              setState(() {
                _transfoPuissanceUcc = val;
                _transfoPuissanceUccController.text = val ?? '';
                recalculateIk3Max();
              });
            },
            suffixText: '%',
            keyboardType: TextInputType.text,
            optional: true,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 10. IK3 MAX (kA)
          _buildTextField(
            _transfoIk3MaxController,
            'IK3 MAX',
            isSmallScreen,
            optional: true,
            suffixText: 'kA',
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 12. Type de refroidissement
          _buildSelectOrCustomInput(
            fieldKey: 'transfoRefroidissement',
            label: 'Type de refroidissement',
            standardOptions: InstallationFieldsRegistry.typeRefroidissementOptions,
            currentValue: _transfoRefroidissementController.text,
            customController: _transfoRefroidissementController,
            isSmallScreen: isSmallScreen,
            onValueChanged: (val) {
              setState(() {
                _transfoRefroidissementController.text = val ?? '';
              });
            },
            keyboardType: TextInputType.text,
            optional: true,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 13. Régime du neutre
          _buildDropdown(_transfoRegimeController, 'Régime du neutre', InstallationFieldsRegistry.regimeNeutreOptions, isSmallScreen, optional: true),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 14. Calibre du disjoncteur
          _buildTextField(
            _transfoCalibreDisjoncteurController,
            'Calibre du disjoncteur sortie transformateur',
            isSmallScreen,
            optional: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            suffixText: 'A',
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 14bis. Courant de réglage du disjoncteur
          _buildTextField(
            _transfoCourantReglageDisjoncteurController,
            'Courant de réglage du disjoncteur (Ir)',
            isSmallScreen,
            optional: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            suffixText: 'A',
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // 15. Section des câbles
          _buildDropdownVal(
            _transfoSectionCablePhase,
            'Section de câble phase',
            _sectionCableOptions,
            isSmallScreen,
            (value) {
              setState(() {
                _transfoSectionCablePhase = value;
                _transfoSectionCables = value;
                if (value != null && value.isNotEmpty && value != '-') {
                  if (_transfoConducteursPhaseController.text.trim().isEmpty) {
                    _transfoConducteursPhaseController.text = '1';
                  }
                  // Auto-remplissage Phase -> Neutre si non modifié manuellement
                  if (!_transfoNeutreManuallyModified) {
                    _transfoSectionCableNeutre = value;
                    if (_transfoConducteursNeutreController.text.trim().isEmpty) {
                      _transfoConducteursNeutreController.text = '1';
                    }
                  }
                } else {
                  _transfoConducteursPhaseController.text = '';
                }
              });
            },
            optional: true,
          ),
          if (_transfoSectionCablePhase != null && _transfoSectionCablePhase!.isNotEmpty && _transfoSectionCablePhase != '-') ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildTextField(
              _transfoConducteursPhaseController,
              'Nombre de conducteurs phase',
              isSmallScreen,
              optional: false,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildDropdownVal(
            _transfoSectionCableNeutre,
            'Section de câble neutre',
            _sectionCableOptions,
            isSmallScreen,
            (value) {
              setState(() {
                _transfoNeutreManuallyModified = true;
                _transfoSectionCableNeutre = value;
                if (value != null && value.isNotEmpty && value != '-') {
                  if (_transfoConducteursNeutreController.text.trim().isEmpty) {
                    _transfoConducteursNeutreController.text = '1';
                  }
                } else {
                  _transfoConducteursNeutreController.text = '';
                }
              });
            },
            optional: true,
          ),
          if (_transfoSectionCableNeutre != null && _transfoSectionCableNeutre!.isNotEmpty && _transfoSectionCableNeutre != '-') ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildTextField(
              _transfoConducteursNeutreController,
              'Nombre de conducteurs neutre',
              isSmallScreen,
              optional: false,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) {
                _transfoNeutreManuallyModified = true;
              },
            ),
          ],
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Photo du transformateur
          _buildTransfoPhotoPicker(isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 26),

          // Observations
          _buildFormSectionHeader('OBSERVATIONS', isSmallScreen),
          SizedBox(height: isSmallScreen ? 8 : 10),

          if (_transfoObservations.isNotEmpty)
            Column(
              children: _transfoObservations.asMap().entries.map((entry) {
                final index = entry.key;
                final obsElement = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
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
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                _transfoObservations.removeAt(index);
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ObservationEnrichieWidget(
                        element: obsElement,
                        onChanged: () => setState(() {}),
                        color: Colors.orange,
                        onSavePhoto: widget.onSavePhoto,
                        showPriority: false,
                        sectionType: 'transformateur',
                        enableNormativeSearch: true,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _transfoObservations.add(ElementControle(
                    elementControle: '',
                    conforme: null,
                    priorite: 3,
                  ));
                });
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text('AJOUTER UNE OBSERVATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ============================================================
  // ÉLÉMENTS VÉRIFIÉS (SLIDES COMMUN)
  // ============================================================
  
  Widget _buildElementsSlide({
    required List<ElementControle> elements,
    required bool isCellule,
    required bool isSmallScreen,
  }) {
    final color = isCellule ? Colors.blue : Colors.orange;
    
    return ListView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      children: elements.asMap().entries.map((entry) {
        final elementIndex = entry.key;
        final element = entry.value;
        final globalIndex = isCellule 
            ? _celluleElements.indexOf(element) 
            : _transfoElements.indexOf(element);
        
        return _buildElementCard(element, elementIndex, globalIndex, isCellule, color, isSmallScreen);
      }).toList(),
    );
  }
  
  Widget _buildElementCard(ElementControle element, int slideIndex, int globalIndex, bool isCellule, Color color, bool isSmallScreen) {
  return Container(
    margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      // ✅ Bordure rouge si non conforme
      border: Border.all(
        color: element.conforme == null ? Colors.red.shade300 : Colors.grey.shade200,
        width: element.conforme == null ? 1.5 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec numéro et titre
        Row(
          children: [
            Container(
              width: isSmallScreen ? 24 : 28,
              height: isSmallScreen ? 24 : 28,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Center(
                child: Text(
                  '${slideIndex + 1}',
                  style: TextStyle(fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Text(
                element.elementControle,
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // ✅ CONFORMITÉ - OBLIGATOIRE (pas de valeur par défaut)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Conformité *',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: element.conforme == null ? Colors.red : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 10),
            Row(
              children: [
                Expanded(
                  child: _buildConformiteButton(
                    label: 'Oui',
                    isSelected: element.conforme == true && !element.estNA,
                    color: Colors.green,
                    onTap: () => setState(() {
                      element.conforme = true;
                      element.estNA = false;
                      element.priorite = null; // priorité non requise pour Oui
                      if (element.observation != null && element.observation!.isEmpty) {
                        element.observation = null;
                      }
                    }),
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 10),
                Expanded(
                  child: _buildConformiteButton(
                    label: 'Non',
                    isSelected: element.conforme == false && !element.estNA,
                    color: Colors.red,
                    onTap: () => setState(() {
                      element.conforme = false;
                      element.estNA = false;
                      element.priorite ??= 3;
                    }),
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 10),
                Expanded(
                  child: _buildConformiteButton(
                    label: 'NA',
                    isSelected: element.estNA,
                    color: Colors.grey.shade600,
                    onTap: () => setState(() {
                      element.conforme = null;
                      element.estNA = true;
                      element.priorite = null;
                      element.observation = null;
                    }),
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
            if (element.conforme == null && !element.estNA)
              Padding(
                padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
                child: Text(
                  'Veuillez sélectionner Oui, Non ou NA',
                  style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.red),
                ),
              ),
          ],
        ),
        
        if (element.conforme == false) ...[
          SizedBox(height: isSmallScreen ? 12 : 16),
          ObservationEnrichieWidget(
            element: element,
            onChanged: () {
              setState(() {});
            },
            color: color,
            onSavePhoto: (file, section) async {
              return await widget.onSavePhoto(file, section);
            },
            suggestions: const [],
            showPriority: true,
            sectionType: isCellule ? 'cellule' : 'transformateur',
          ),
        ],
      ],
    ),
  );
}

// ✅ Version corrigée de _buildPrioriteButton avec label
Widget _buildPrioriteButton({
  required int niveau,
  required String label,
  required bool isSelected,
  required Color color,
  required VoidCallback onTap,
  required bool isSmallScreen,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
        border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.flag : Icons.flag_outlined,
              size: isSmallScreen ? 16 : 18,
              color: isSelected ? color : Colors.grey.shade500,
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
  // ============================================================
  // WIDGETS UTILITAIRES
  // ============================================================
  
  Widget _buildInfoRow(String label, String value, bool isSmallScreen, {Color? color}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 90 : 100,
            child: Text('$label:', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: color ?? Colors.black87), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReadOnlyInfoField(String label, String value, bool isSmallScreen, {IconData? icon}) {
    return TextFormField(
      initialValue: value.isNotEmpty ? value : 'Calculé automatiquement depuis le local',
      enabled: false,
      style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
      decoration: InputDecoration(
        labelText: '$label',
        labelStyle: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
        prefixIcon: icon != null ? Icon(icon, size: isSmallScreen ? 18 : 20, color: AppTheme.primaryBlue) : const Icon(Icons.location_on , size: 18, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10), borderSide: BorderSide(color: Colors.blue.shade200)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10), borderSide: BorderSide(color: Colors.blue.shade200)),
        contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 12 : 14),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool isSmallScreen, {
    IconData? icon,
    bool optional = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
    void Function(String)? onChanged,
  }) {
    final labelText = optional ? label : '$label *';
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey.shade600),
        prefixIcon: icon != null ? Icon(icon, size: isSmallScreen ? 18 : 20) : null,
        suffixText: suffixText,
        suffixStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10)),
        contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 12 : 14),
      ),
    );
  }

  Widget _buildSelectOrCustomInput({
    required String fieldKey,
    required String label,
    required List<String> standardOptions,
    required String? currentValue,
    required TextEditingController customController,
    required bool isSmallScreen,
    required void Function(String?) onValueChanged,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool optional = true,
  }) {
    final cleanVal = currentValue?.trim() ?? '';

    // Trouver si la valeur actuelle correspond à une option prédéfinie de la liste
    String? matchedStandard;
    if (cleanVal.isNotEmpty) {
      for (final opt in standardOptions) {
        final optTrimmed = opt.trim();
        if (cleanVal == optTrimmed) {
          matchedStandard = opt;
          break;
        }
        if (suffixText != null && suffixText.isNotEmpty) {
          if (cleanVal.toLowerCase() == '$optTrimmed $suffixText'.toLowerCase() ||
              cleanVal.toLowerCase() == '$optTrimmed$suffixText'.toLowerCase()) {
            matchedStandard = opt;
            break;
          }
        }
        // Comparaison insensible aux espaces (ex: '1000' vs '1 000')
        final cleanNoSpace = cleanVal.replaceAll(RegExp(r'\s+'), '').toLowerCase();
        final optNoSpace = optTrimmed.replaceAll(RegExp(r'\s+'), '').toLowerCase();
        if (cleanNoSpace == optNoSpace) {
          matchedStandard = opt;
          break;
        }
        if (suffixText != null && suffixText.isNotEmpty) {
          final optWithSuffixNoSpace = '$optNoSpace${suffixText.replaceAll(RegExp(r'\s+'), '').toLowerCase()}';
          if (cleanNoSpace == optWithSuffixNoSpace) {
            matchedStandard = opt;
            break;
          }
        }
      }
    }

    // Le mode "Saisir" est actif soit si l'utilisateur l'a explicitement choisi dans le select,
    // soit si la mission en cours possède déjà une donnée personnalisée/terrain hors liste prédéfinie
    final isCustomTerrain = cleanVal.isNotEmpty && matchedStandard == null;
    final isSaisirActive = _customSaisirFields.contains(fieldKey) || isCustomTerrain;
    final showInputField = isSaisirActive;

    // Déterminer la valeur sélectionnée dans le Dropdown
    final String dropdownValue;
    if (isSaisirActive) {
      dropdownValue = '__SAISIR__';
    } else if (matchedStandard != null) {
      dropdownValue = matchedStandard;
    } else {
      dropdownValue = '';
    }

    // Pré-remplir fidèlement le champ texte libre si une donnée terrain non-standard existe
    if (isCustomTerrain && customController.text.trim().isEmpty) {
      customController.text = cleanVal;
    }

    // Construire la liste déroulante : STRICTEMENT options standard + "Saisir"
    // Aucune altération ni doublon de liste, préservation totale
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(
        value: '',
        child: Text(
          '— Non renseigné —',
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      ...standardOptions.map(
        (opt) => DropdownMenuItem<String>(
          value: opt,
          child: Text(
            (suffixText != null && !opt.contains(suffixText)) ? '$opt $suffixText' : opt,
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
          ),
        ),
      ),
      DropdownMenuItem<String>(
        value: '__SAISIR__',
        child: Row(
          children: [
            const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryBlue),
            const SizedBox(width: 6),
            Text(
              'Saisir',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: dropdownValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: optional ? label : '$label *',
            labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10)),
            contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 12 : 14),
          ),
          items: items,
          onChanged: (val) {
            if (val == '__SAISIR__') {
              setState(() {
                _customSaisirFields.add(fieldKey);
                // Si on passe d'une option prédéfinie vers "Saisir", vider le champ libre pour la nouvelle saisie
                if (matchedStandard != null) {
                  customController.clear();
                  onValueChanged('');
                } else if (cleanVal.isNotEmpty) {
                  customController.text = cleanVal;
                  onValueChanged(cleanVal);
                }
              });
            } else if (val != null && val.isNotEmpty) {
              setState(() {
                _customSaisirFields.remove(fieldKey);
                customController.text = val;
                onValueChanged(val);
              });
            } else {
              setState(() {
                _customSaisirFields.remove(fieldKey);
                customController.clear();
                onValueChanged(null);
              });
            }
          },
        ),
        if (showInputField) ...[
          SizedBox(height: isSmallScreen ? 8 : 10),
          _buildTextField(
            customController,
            '$label (saisie libre)',
            isSmallScreen,
            optional: optional,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            suffixText: suffixText,
            onChanged: (text) => onValueChanged(text.trim()),
          ),
        ],
      ],
    );
  }
  
  Widget _buildDropdown(TextEditingController controller, String label, List<String> options, bool isSmallScreen, {bool optional = false, void Function(String?)? onSelected}) {
    final labelText = optional ? label : '$label *';
    final hasValue = controller.text.isNotEmpty;
    final effectiveOptions = List<String>.from(options);
    if (hasValue && !effectiveOptions.contains(controller.text)) {
      effectiveOptions.add(controller.text);
    }
    return DropdownButtonFormField<String>(
      initialValue: hasValue ? controller.text : '',
      isExpanded: true,
      hint: Text('Sélectionnez...', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade500)),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10)),
        contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 12 : 14),
      ),
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: Text('— Non renseigné —', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
        ),
        ...effectiveOptions.map((option) => DropdownMenuItem(value: option, child: Text(option, style: TextStyle(fontSize: isSmallScreen ? 13 : 14)))),
      ],
      onChanged: (value) {
        controller.text = value ?? '';
        onSelected?.call(value);
      },
    );
  }
  
  Widget _buildDropdownVal(String? value, String label, List<String> options, bool isSmallScreen, void Function(String?) onChanged, {bool optional = false}) {
    final labelText = optional ? label : '$label *';
    final hasValue = value != null && value.isNotEmpty;
    final effectiveOptions = List<String>.from(options);
    if (hasValue && !effectiveOptions.contains(value)) {
      effectiveOptions.add(value!);
    }
    return DropdownButtonFormField<String>(
      initialValue: hasValue ? value : '',
      isExpanded: true,
      hint: Text('Sélectionnez...', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade500)),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10)),
        contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 12 : 14),
      ),
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: Text('— Non renseigné —', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
        ),
        ...effectiveOptions.map((option) => DropdownMenuItem(value: option, child: Text(option, style: TextStyle(fontSize: isSmallScreen ? 13 : 14)))),
      ],
      onChanged: (val) => onChanged(val == '' ? null : val),
    );
  }
  
  Widget _buildConformiteButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? (label == 'Oui' ? Icons.check_circle : Icons.cancel) : Icons.circle_outlined,
                size: isSmallScreen ? 16 : 18,
                color: isSelected ? color : Colors.grey.shade500,
              ),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Text(label, style: TextStyle(fontSize: isSmallScreen ? 12 : 13, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
  
  
  // ============================================================
  // VALIDATION (au moins 1 transformateur)
  // ============================================================
  
  bool canGoNext() {
    return widget.transformateurs.isNotEmpty;
  }
  
  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================
  
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    // Si en mode édition, afficher le formulaire approprié
    if (_isEditing) {
      return _isEditingCellule
          ? _buildCelluleFormulaireSlides(isSmallScreen)
          : _buildTransformateurFormulaireSlides(isSmallScreen);
    }
    
    // Sinon, afficher le sélecteur de mode + la liste
    return Column(
      children: [
        _buildModeSelector(isSmallScreen),
        Expanded(
          child: _currentMode == 0
              ? _buildCellulesList(isSmallScreen)
              : _buildTransformateursList(isSmallScreen),
        ),
        // Bouton d'ajout flottant en bas à droite
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _currentMode == 0 ? _ajouterCellule : _ajouterTransformateur,
              icon: Icon(Icons.add, size: isSmallScreen ? 18 : 20),
              label: Text(
                _currentMode == 0 ? 'AJOUTER UNE CELLULE' : 'AJOUTER UN TRANSFORMATEUR',
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentMode == 0 ? Colors.blue : Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _celluleNomController.dispose();
    _celluleFonctionController.dispose();
    _celluleTypeController.dispose();
    _celluleMarqueController.dispose();
    _celluleModeleController.dispose();
    _celluleAnneeController.dispose();
    _celluleTensionController.dispose();
    _celluleTensionServiceCustomController.dispose();
    _cellulePouvoirController.dispose();
    _celluleNumerotationController.dispose();
    _celluleParafoudresController.dispose();
    _celluleCalibreDisjoncteurController.dispose();
    _celluleDepartController.dispose();
    _celluleConducteursPhaseController.dispose();
    _celluleConducteursNeutreController.dispose();
    _transfoNomController.dispose();
    _transfoTypeController.dispose();
    _transfoMarqueController.dispose();
    _transfoAnneeController.dispose();
    _transfoPuissanceController.dispose();
    _transfoPuissanceUccController.dispose();
    _transfoTensionController.dispose();
    _transfoBuchholzController.dispose();
    _transfoTypeImmersionController.dispose();
    _transfoDgpt2Controller.dispose();
    _transfoRefroidissementController.dispose();
    _transfoRegimeController.dispose();
    _transfoCalibreDisjoncteurController.dispose();
    _transfoCourantReglageDisjoncteurController.dispose();
    _transfoConducteursPhaseController.dispose();
    _transfoConducteursNeutreController.dispose();
    // Libérer les controllers d'observation
    for (final c in _obsControllersCellule.values) c.dispose();
    for (final c in _obsControllersTransfo.values) c.dispose();
    super.dispose();
  }
}


// ================================================================
// WIDGET PRINCIPAL : AjouterLocalScreen
// ================================================================

class AjouterLocalScreen extends StatefulWidget {
  final Mission mission;
  final bool isMoyenneTension;
  final dynamic local;
  final int? localIndex;
  final int? zoneIndex;
  final bool isInZone;
  final String? draftId;
  
  const AjouterLocalScreen({
    super.key,
    required this.mission,
    required this.isMoyenneTension,
    this.local,
    this.localIndex,
    this.zoneIndex,
    this.isInZone = false,
    this.draftId,
  });

  bool get isEdition => local != null;

  @override
  State<AjouterLocalScreen> createState() => _AjouterLocalScreenState();
}

  // ──────────────────────────────────────────────────
  // ARCHITECTURE DE FLOW
  // ──────────────────────────────────────────────────

  /// Les deux flows supportés.
  enum _LocalFlow { standard, long }

  /// Retourne le flow actif selon le type sélectionné.
  _LocalFlow get _flow {
    if (_selectedType == 'LOCAL_TRANSFORMATEUR' || _selectedType == 'LOCAL_MTBT') {
      return _LocalFlow.long;
    }
    return _LocalFlow.standard;
  }

  /// Nombre total d'étapes : standard = 3 (infos + accessibilité + éléments),
  /// long = 4 (infos + accessibilité + cellules/transfo + éléments).
  int get _totalSteps => _flow == _LocalFlow.long ? 4 : 3;

  // Indices d'étapes selon le flow
  // Standard : 0=infos, 1=accessibilité, 2=éléments
  // Long      : 0=infos, 1=accessibilité, 2=cellules/transfo, 3=éléments
  int get _stepInfos           => 0;
  int get _stepAccessibilite   => 1;
  int get _stepElements        => 2;
  int get _stepCellulesTransfo => 3; 

  String? _selectedType;

class _AjouterLocalScreenState extends State<AjouterLocalScreen> {


  final _formKey = GlobalKey<FormState>();

  GlobalKey<_EtapeElementsControleState>? _etapeElementsKey;

  final GlobalKey<_EtapeCelluleTransformateurMultiState> _etapeCelluleTransfoKey =
    GlobalKey<_EtapeCelluleTransformateurMultiState>();
      
  final _nomController = TextEditingController();

  bool? _accessible; 
  bool _isRiskZone = false;
  List<ElementControle> _dispositionsConstructives = [];
  List<ElementControle> _conditionsExploitation = [];
  
  final ImagePicker _picker = ImagePicker();
  
  List<String> _localPhotos = [];
  bool _isLoadingPhotos = false;
  
  final _observationController = TextEditingController();
  final List<String> _observationPhotos = [];
  final List<ObservationLibre> _observationsExistantes = [];

  List<Cellule> _cellules = [];
  List<TransformateurMTBT> _transformateurs = [];

  static const String _baseUrl = "http://192.168.0.217:8000";
  Map<int, List<String>> _elementSuggestions = {};
  Map<int, bool> _elementLoading = {};
  Map<int, Timer?> _elementDebounceTimers = {};
  
  Map<String, TextEditingController> _observationControllers = {};

  bool _nomValid = false;
  bool _typeValid = false;
  bool _localPhotosValid = true;
  bool _observationsValid = true;
  bool _dispositionsValid = false;
  bool _conditionsValid = false;
  bool _celluleDonneesValid = true;
  bool _transfoDonneesValid = true;
  bool _celluleElementsValid = true;
  bool _transfoElementsValid = true;
  
  bool _addObservation = false;
  final Map<int, bool> _hasObservation = {};
  
  final Map<ElementControle, bool> _conformeSelected = {};

  final PageController _mainPageController = PageController();
  int _currentStep = 0;

  bool _isLoading = false;

  String? _draftLocalId;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  int? _resolvedLocalIndex;

  @override
  void initState() {
    super.initState();
    _resolvedLocalIndex = widget.localIndex;
    _etapeElementsKey = GlobalKey<_EtapeElementsControleState>();

    // Un local aReverifier traité comme nouvelle création : ID temporaire unique
    final isReverification = widget.isEdition &&
        widget.local != null &&
        ((widget.local as dynamic).aReverifier == true);

    _draftLocalId = HiveService.getStableLocalDraftId(
      missionId: widget.mission.id,
      isMoyenneTension: widget.isMoyenneTension,
      zoneIndex: widget.zoneIndex,
      isInZone: widget.isInZone,
      localIndex: widget.localIndex,
      nomLocal: widget.local?.nom,
      customDraftId: isReverification ? 'TEMP_${DateTime.now().millisecondsSinceEpoch}' : widget.draftId,
    );

    if (HiveService.hasActiveLocalDraft(_draftLocalId!)) {
      _loadDraft();
    } else if (widget.isEdition && !isReverification) {
      _chargerDonneesExistantes();
      _nomValid = true;
      _typeValid = true;
      _localPhotosValid = true;
      _dispositionsValid = _validateElements(_dispositionsConstructives);
      _conditionsValid = _validateElements(_conditionsExploitation);
    } else {
      _initializeElementsControle();
      _accessible = true;
      if (widget.isMoyenneTension) {
        _selectedType = 'LOCAL_TRANSFORMATEUR';
        _typeValid = true;
        _initializeElementsForType('LOCAL_TRANSFORMATEUR');
      } else {
        _selectedType = 'LOCAL_TGBT';
        _typeValid = true;
        _initializeElementsForType('LOCAL_TGBT');
      }
    }
  }

  /// Sauvegarde immédiatement le local et ses équipements sur disque dans Hive
  /// et déclenche la synchronisation permanente vers DescriptionInstallations.
  Future<dynamic> _persisterEquipementEtLocalImmediatement() async {
    try {
      final nomLocal = _nomController.text.trim().isEmpty ? 'Nouveau Local' : _nomController.text.trim();
      if (_nomController.text.trim().isEmpty) {
        _nomController.text = nomLocal;
        _nomValid = true;
      }

      dynamic nouveauLocal;
      final String localId = (widget.local != null)
          ? (widget.local as dynamic).localId
          : (_draftLocalId ?? 'local_${DateTime.now().microsecondsSinceEpoch}');

      if (widget.isMoyenneTension) {
        final localData = _creerMoyenneTensionLocal();
        localData.id = localId;

        await HiveService.updateLocalById(
          missionId: widget.mission.id,
          localId: localId,
          updatedLocal: localData,
          isMoyenneTension: true,
          isInZone: widget.isInZone,
          fallbackZoneIndex: widget.zoneIndex,
          fallbackLocalIndex: _resolvedLocalIndex,
          skipDescriptionSync: true,
        );
        nouveauLocal = localData;
      } else {
        final localData = _creerBasseTensionLocal();
        localData.id = localId;

        await HiveService.updateLocalById(
          missionId: widget.mission.id,
          localId: localId,
          updatedLocal: localData,
          isMoyenneTension: false,
          isInZone: true,
          fallbackZoneIndex: widget.zoneIndex,
          fallbackLocalIndex: _resolvedLocalIndex,
          skipDescriptionSync: true,
        );
        nouveauLocal = localData;
      }

      // Synchronisation différée en arrière-plan sans bloquer le thread UI interactif
      Future.microtask(() {
        InstallationDescriptionSyncService.repairAndSyncDescriptions(widget.mission.id);
      });

      // Suppression de l'éventuel draft résiduel car le local est définitivement enregistré
      if (_draftLocalId != null && HiveService.hasActiveLocalDraft(_draftLocalId!)) {
        await HiveService.deleteLocalDraft(_draftLocalId!);
      }

      return nouveauLocal;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _persisterEquipementEtLocalImmediatement: $e');
      }
    }
  }

  Future<void> _loadDraft() async {
    final draftData = HiveService.getLocalDraftData(_draftLocalId!);
    if (draftData == null) return;
    
    final local = draftData['local'];
    final savedStep = draftData['currentStep'] as int? ?? 0;
    
    setState(() {
      // Informations de base
      _nomController.text = local.nom ?? '';
      _selectedType = local.type;
      if (_selectedType == null || _selectedType!.isEmpty) {
        _selectedType = widget.isMoyenneTension ? 'LOCAL_TRANSFORMATEUR' : 'LOCAL_TGBT';
      }
      _accessible = (local.accessible == false) ? false : true;
      _isRiskZone = (local is MoyenneTensionLocal || local is BasseTensionLocal) ? (local.isRiskZone ?? false) : false;
      _typeValid = true;
      _nomValid = (local.nom != null && local.nom!.isNotEmpty && local.nom != 'Sans nom');
      
      // Dispositions et conditions
      _dispositionsConstructives = List.from(local.dispositionsConstructives ?? []);
      _conditionsExploitation = List.from(local.conditionsExploitation ?? []);
      
      // Observations
      _observationsExistantes.clear();
      if (local.observationsLibres != null) {
        _observationsExistantes.addAll(local.observationsLibres);
      }
      
      // Photos
      _localPhotos.clear();
      if (local.photos != null && local.photos.isNotEmpty) {
        _localPhotos = List.from(local.photos);
      }
      _localPhotosValid = true;
      
      // CHARGEMENT DES CELLULES ET TRANSFORMATEURS
      if (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT') {
        if (local is MoyenneTensionLocal) {
          local.migrateFromOldFields();
          _cellules = List.from(local.cellules);
          _transformateurs = List.from(local.transformateurs);
        } else if (local is BasseTensionLocal) {
          _cellules = List.from(local.cellules);
          _transformateurs = List.from(local.transformateurs);
        }
      } else {
        _cellules.clear();
        _transformateurs.clear();
      }
      
      // RESTAURER L'ÉTAPE COURANTE
      _currentStep = savedStep;
      
      // Reconstruire conformeSelected et hasObservation
      _reconstructMaps();
      
      // POSITIONNER LE PAGE CONTROLLER
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mainPageController.hasClients) {
          _mainPageController.jumpToPage(_currentStep);
        }
        if (_currentStep == 1) {
          _etapeElementsKey?.currentState?.rebuildSlides();
        }
        if (_currentStep == 2 && (_selectedType == 'LOCAL_TRANSFORMATEUR' || _selectedType == 'LOCAL_MTBT')) {
          // Step 2 = cellules/transfo : pas besoin de rebuild spécifique
        }
      });
    });
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveDraft();
    });
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
  
    final nom = _nomController.text.trim();
    if (nom.isEmpty && _selectedType == null) {
      return;
    }
    final typeToSave = _selectedType ?? 'LOCAL_ELECTRIQUE';
    
    dynamic local;
    if (widget.isMoyenneTension) {
      local = _creerMoyenneTensionLocalAvecType(typeToSave);
    } else {
      local = _creerBasseTensionLocalAvecType(typeToSave);
    }
    
    // Inclure cellules/transfo pour tous les flow longs, quelle que soit la zone parente
    if (typeToSave == 'LOCAL_TRANSFORMATEUR' || typeToSave == 'LOCAL_MTBT') {
      if (local is MoyenneTensionLocal) {
        local.cellules = _cellules;
        local.transformateurs = _transformateurs;
      } else if (local is BasseTensionLocal) {
        local.cellules = _cellules;
        local.transformateurs = _transformateurs;
      }
    }
    
    await HiveService.saveLocalDraft(
      missionId: widget.mission.id,
      isMoyenneTension: widget.isMoyenneTension,
      zoneIndex: widget.zoneIndex,
      isInZone: widget.isInZone,
      local: local,
      currentStep: _currentStep, 
      localId: _draftLocalId,
    );
    
    _hasUnsavedChanges = false;
  }

  // Créer un local MT avec un type spécifié
  MoyenneTensionLocal _creerMoyenneTensionLocalAvecType(String type) {
    final now = DateTime.now().toUtc();
    final existingLocal = widget.isEdition && widget.local is MoyenneTensionLocal
        ? (widget.local as MoyenneTensionLocal)
        : null;
    return MoyenneTensionLocal(
      id: existingLocal?.localId,
      createdAt: existingLocal?.createdAt ?? (widget.isEdition ? null : now),
      updatedAt: now,
      nom: _nomController.text.trim().isEmpty ? 'Sans nom' : _nomController.text.trim(),
      type: type,
      dispositionsConstructives: _dispositionsConstructives,
      conditionsExploitation: _conditionsExploitation,
      observationsLibres: _observationsExistantes,
      photos: _localPhotos,
      cellules: _cellules,
      transformateurs: _transformateurs,
      coffrets: widget.isEdition && widget.local is MoyenneTensionLocal
          ? (widget.local as MoyenneTensionLocal).coffrets
          : [],
      accessible: _accessible ?? (widget.isEdition && existingLocal != null ? existingLocal.accessible : true),
      aReverifier: (_accessible == false),
      isRiskZone: _isRiskZone,
    );
  }

  void _reconstructMaps() {
    _conformeSelected.clear();
    for (var element in _dispositionsConstructives) {
      _conformeSelected[element] = element.conforme != null;
    }
    for (var element in _conditionsExploitation) {
      _conformeSelected[element] = element.conforme != null;
    }
    
    _hasObservation.clear();
    for (int i = 0; i < _dispositionsConstructives.length; i++) {
      final obs = _dispositionsConstructives[i].observation;
      _hasObservation[i] = obs != null && obs.isNotEmpty;
      if (_dispositionsConstructives[i].conforme == false) {
        _hasObservation[i] = true;
      }
    }
    for (int i = 0; i < _conditionsExploitation.length; i++) {
      final globalIndex = _dispositionsConstructives.length + i;
      final obs = _conditionsExploitation[i].observation;
      _hasObservation[globalIndex] = obs != null && obs.isNotEmpty;
      if (_conditionsExploitation[i].conforme == false) {
        _hasObservation[globalIndex] = true;
      }
    }
  }

  // Crée un local BT en snapshot avec le type [type] et les données courantes de l'état.
  // Les cellules et transformateurs sont toujours pris depuis l'état (_cellules, _transformateurs)
  // car _applyTypeTransition les a déjà mis à jour correctement.
  // Les coffrets sont préservés de l'existant de façon null-safe.
  BasseTensionLocal _creerBasseTensionLocalAvecType(String type) {
    final now = DateTime.now().toUtc();
    final existingLocal = widget.isEdition && widget.local is BasseTensionLocal
        ? (widget.local as BasseTensionLocal)
        : null;
    // Récupération sécurisée des coffrets depuis l'entité existante.
    // On ne touche jamais aux coffrets lors d'un changement de type.
    final List<CoffretArmoire> coffrets = existingLocal?.coffrets ?? [];
    return BasseTensionLocal(
      id: existingLocal?.localId,
      createdAt: existingLocal?.createdAt ?? (widget.isEdition ? null : now),
      updatedAt: now,
      nom: _nomController.text.trim().isEmpty ? 'Sans nom' : _nomController.text.trim(),
      type: type,
      dispositionsConstructives: _dispositionsConstructives,
      conditionsExploitation: _conditionsExploitation,
      observationsLibres: _observationsExistantes,
      photos: _localPhotos,
      accessible: _accessible ?? (widget.isEdition && existingLocal != null
          ? (existingLocal.accessible ?? true)
          : true),
      aReverifier: (_accessible == false),
      // _cellules et _transformateurs sont gérés par _applyTypeTransition et _loadDraft.
      // Pas besoin du flag isFlowLong ici : l'état est déjà cohérent.
      cellules: _cellules,
      transformateurs: _transformateurs,
      coffrets: coffrets,
      isRiskZone: _isRiskZone,
    );
  }

  void _chargerDonneesExistantes() {
    final local = widget.local!;
    _nomController.text = local.nom;
    _selectedType = local.type;
    _isRiskZone = (local is MoyenneTensionLocal || local is BasseTensionLocal) ? (local.isRiskZone ?? false) : false;
    _dispositionsConstructives = List.from(local.dispositionsConstructives);
    _conditionsExploitation = List.from(local.conditionsExploitation);
    _observationsExistantes.addAll(local.observationsLibres);

    if (local.photos.isNotEmpty) _localPhotos = List.from(local.photos);

    _accessible = local.accessible;
    if (local.accessible == false) {
      // On se positionne au step 1 (accessibilité) au lieu du step 0
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future.microtask(() {
          if (!mounted) return;
          if (_mainPageController.hasClients) {
            _mainPageController.jumpToPage(_stepAccessibilite);
          }
          setState(() => _currentStep = _stepAccessibilite);
        });
      });
    }
    
    // CHARGEMENT DES CELLULES ET TRANSFORMATEURS
    if (local.type == 'LOCAL_GROUPE_ELECTROGENE') {
      DispositionsConstructivesRegistry.ensureCompleteGELocalChecklists(
        dispositionsConstructives: _dispositionsConstructives,
        conditionsExploitation: _conditionsExploitation,
      );
    } else if (local.type == 'LOCAL_BT' || local.type == 'LOCAL_TGBT' || local.type == 'LOCAL_ONDULEUR' || local.type == 'LOCAL_ELECTRIQUE') {
      DispositionsConstructivesRegistry.ensureCompleteBTLocalChecklists(
        dispositionsConstructives: _dispositionsConstructives,
        conditionsExploitation: _conditionsExploitation,
      );
    } else if (local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT') {
      DispositionsConstructivesRegistry.ensureCompleteLocalChecklists(
        dispositionsConstructives: _dispositionsConstructives,
        conditionsExploitation: _conditionsExploitation,
      );
      if (local is MoyenneTensionLocal) {
        local.migrateFromOldFields();
        _cellules = List.from(local.cellules);
        _transformateurs = List.from(local.transformateurs);
      } else if (local is BasseTensionLocal) {
        _cellules = List.from(local.cellules);
        _transformateurs = List.from(local.transformateurs);
      }
      for (final cellule in _cellules) {
        DispositionsConstructivesRegistry.ensureCompleteCelluleChecklist(cellule.elementsVerifies);
      }
      for (final transfo in _transformateurs) {
        DispositionsConstructivesRegistry.ensureCompleteTransformateurChecklist(transfo.elementsVerifies);
      }
    }
    
    // Initialiser conformeSelected pour les éléments existants
    for (var element in _dispositionsConstructives) {
      _conformeSelected[element] = true;
    }
    for (var element in _conditionsExploitation) {
      _conformeSelected[element] = true;
    }
    
    // Initialiser hasObservation
    for (int i = 0; i < _dispositionsConstructives.length; i++) {
      _hasObservation[i] = _dispositionsConstructives[i].observation?.isNotEmpty == true;
    }
    for (int i = 0; i < _conditionsExploitation.length; i++) {
      _hasObservation[_dispositionsConstructives.length + i] = _conditionsExploitation[i].observation?.isNotEmpty == true;
    }
  }

  void _initializeElementsControle() {
    _dispositionsConstructives = [];
    _conditionsExploitation = [];
    _hasObservation.clear();
    _conformeSelected.clear();
  }

  void _validateNom(String value) {
    setState(() => _nomValid = value.trim().isNotEmpty);
    _scheduleAutoSave();
  }
  void _onTypeChanged(String? newType) {
    if (newType == null) return;
    setState(() {
      if (!widget.isEdition) {
        // Création : réinitialiser les checklists proprement pour le nouveau type.
        _selectedType = newType;
        _validateType(newType);
        _initializeElementsForType(newType);
      } else {
        // Édition : appliquer la transition en préservant les données existantes.
        _applyTypeTransition(newType);
      }
    });
    _scheduleAutoSave();
  }

  /// Initialise les checklists pour un type donné lors de la CRÉATION d'un local.
  /// Tous les points sont vierges (estNA = true, conforme = null).
  void _initializeElementsForType(String? type) {
    if (type == null) return;
    if (widget.isMoyenneTension) {
      LocalTypeTransitionService.initChecklistsForNewMTLocal(
        dispositionsConstructives: _dispositionsConstructives,
        conditionsExploitation: _conditionsExploitation,
        type: type,
      );
    } else {
      LocalTypeTransitionService.initChecklistsForNewBTLocal(
        dispositionsConstructives: _dispositionsConstructives,
        conditionsExploitation: _conditionsExploitation,
        type: type,
      );
    }
    _conformeSelected.clear();
    _hasObservation.clear();
    _validateType(type);
  }

  /// Applique un changement de type lors de l'EDITION d'un local.
  /// Préserve les données communes et normalise les checklists.
  void _applyTypeTransition(String newType) {
    final oldType = _selectedType ?? '';
    _selectedType = newType;
    _validateType(newType);

    if (oldType == newType) return;

    // Mettre à jour cellules/transformateurs selon la transition de flow
    final oldIsLong = LocalTypeTransitionService.isLongFlow(oldType);
    final newIsLong = LocalTypeTransitionService.isLongFlow(newType);
    if (!oldIsLong && newIsLong) {
      // standard -> long : préparer des listes vides (l'utilisateur les remplira)
      _cellules = [];
      _transformateurs = [];
    } else if (oldIsLong && !newIsLong) {
      // long -> standard : on vide (incompatibilité structurelle)
      _cellules = [];
      _transformateurs = [];
    }
    // long -> long ou standard -> standard : on conserve les listes en l'état

    // Normaliser les checklists selon le nouveau type en préservant les réponses existantes
    if (widget.isMoyenneTension) {
      DispositionsConstructivesRegistry.ensureCompleteLocalChecklists(
        dispositionsConstructives: _dispositionsConstructives,
        conditionsExploitation: _conditionsExploitation,
      );
    } else {
      switch (LocalTypeTransitionService.isLongFlow(newType) ? 'LONG' : _btChecklistFamilyForType(newType)) {
        case 'GE':
          DispositionsConstructivesRegistry.ensureCompleteGELocalChecklists(
            dispositionsConstructives: _dispositionsConstructives,
            conditionsExploitation: _conditionsExploitation,
          );
          break;
        case 'LONG':
          DispositionsConstructivesRegistry.ensureCompleteLocalChecklists(
            dispositionsConstructives: _dispositionsConstructives,
            conditionsExploitation: _conditionsExploitation,
          );
          break;
        default:
          DispositionsConstructivesRegistry.ensureCompleteBTLocalChecklists(
            dispositionsConstructives: _dispositionsConstructives,
            conditionsExploitation: _conditionsExploitation,
          );
          break;
      }
    }
    _reconstructMaps();
  }

  /// Retourne la famille de checklist BT pour un type donné.
  static String _btChecklistFamilyForType(String type) {
    if (type == 'LOCAL_GROUPE_ELECTROGENE') return 'GE';
    if (type == 'LOCAL_MTBT') return 'LONG';
    return 'STANDARD';
  }

  void _onConformeChanged(ElementControle element) {
    setState(() {
      _conformeSelected[element] = true;
      if (element.conforme == false) {
        element.priorite ??= 3;
      } else {
        element.priorite = null;
      }
      
      int? elementIndex;
      for (int i = 0; i < _dispositionsConstructives.length; i++) {
        if (_dispositionsConstructives[i] == element) {
          elementIndex = i;
          break;
        }
      }
      if (elementIndex == null) {
        for (int i = 0; i < _conditionsExploitation.length; i++) {
          if (_conditionsExploitation[i] == element) {
            elementIndex = _dispositionsConstructives.length + i;
            break;
          }
        }
      }
      if (element.conforme == false && elementIndex != null) {
        _hasObservation[elementIndex] = true;
      }
    });
    _scheduleAutoSave();
  }

  void _validateType(String? value) => setState(() => _typeValid = value != null && value.isNotEmpty);
  void _validateLocalPhotos() => setState(() => _localPhotosValid = true);

  void _validateObservations() {
    bool isValid = true;
    if (!widget.isEdition && _addObservation) {
      if (_observationController.text.trim().isEmpty && _observationsExistantes.isEmpty) isValid = false;
    }
    setState(() => _observationsValid = isValid);
  }

  bool _validateElements(List<ElementControle> elements) {
    if (elements.isEmpty) return false;
    for (var element in elements) {
      if (!(_conformeSelected[element] ?? false)) return false;
      if (element.conforme == false && element.priorite == null) {
        element.priorite = 3;
      }
    }
    return true;
  }

  

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _nomValid && _typeValid && (!_addObservation || _observationsValid);
      case 1:
        return true; // La navigation interne du widget gère la validation
      case 2:
        // Au moins un transformateur requis pour LOCAL_TRANSFORMATEUR uniquement
        if (_selectedType == 'LOCAL_TRANSFORMATEUR') {
          return _transformateurs.isNotEmpty;
        }
        // LOCAL_MTBT : tout est optionnel
        return true;
      default:
        return true;
    }
  }

  void _handleNext() {
    // ── Step 0 : Informations générales
    if (_currentStep == _stepInfos) {
      if (_canProceedToNextStep()) {
        _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _showError('Veuillez remplir tous les champs obligatoires');
      }
      return;
    }

    // ── Step 1 : Accessibilité
    if (_currentStep == _stepAccessibilite) {
      if (_accessible == null) {
        _showError('Veuillez indiquer si le local est accessible');
        return;
      }
      if (_accessible == false) {
        _sauvegarderInaccessible();
        return;
      }
      _etapeElementsKey?.currentState?.setSectionAndSlide(0, 0);
      _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    // ── Step 2 : Éléments de contrôle
    if (_currentStep == _stepElements) {
      final elementsState = _etapeElementsKey?.currentState;
      if (elementsState != null) {
        if (elementsState.canGoNext()) {
          // Dernière slide des éléments
          if (_flow == _LocalFlow.long) {
            // Flow long → aller aux cellules/transfo
            _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          } else {
            // Flow standard → sauvegarder
            _sauvegarder();
          }
        } else {
          elementsState.nextSlide();
        }
      }
      return;
    }

    // ── Step 3 : Cellules/Transfo (flow long uniquement)
    if (_flow == _LocalFlow.long && _currentStep == _stepCellulesTransfo) {
      final formState = _etapeCelluleTransfoKey.currentState;
      if (formState != null && formState.isFormOpen) {
        formState.handleFormNext();
        return;
      }

      _sauvegarder();
      return;
    }
  }

  void _handlePrevious() {
    // ── Step 3 : Cellules/Transfo → formulaire peut être ouvert
    if (_flow == _LocalFlow.long && _currentStep == _stepCellulesTransfo) {
      final formState = _etapeCelluleTransfoKey.currentState;
      if (formState != null && formState.isFormOpen) {
        if (formState.isFormFirstSlide) {
          if (formState.isEditingExisting) {
            formState.sauvegarderEtFermer();
          } else {
            formState.cancelForm();
          }
        } else {
          formState.handleFormPrevious();
        }
        return;
      }
      // Formulaire fermé → retour aux éléments (dernier slide)
      _etapeElementsKey?.currentState?.setSectionAndSlide(1, -1);
      _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    // ── Step 2 : Éléments de contrôle
    if (_currentStep == _stepElements) {
      final elementsState = _etapeElementsKey?.currentState;
      if (elementsState != null) {
        if (elementsState.canGoPrevious()) {
          // Tout début des éléments → retour à l'accessibilité
          _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        } else {
          elementsState.previousSlide();
        }
      }
      return;
    }

    // Tous les autres steps → page précédente
    if (_currentStep > 0) {
      _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _changerEtapeDirecte(int cible) {
    if (cible == _currentStep) return;

    // Si on va vers les Éléments de contrôle (_stepElements)
    if (cible == _stepElements) {
      if (_currentStep > _stepElements) {
        // Reculer depuis Cellules/Transfo -> dernier slide
        _etapeElementsKey?.currentState?.setSectionAndSlide(1, -1);
      } else {
        // Avancer depuis Infos/Accessibilité -> premier slide
        _etapeElementsKey?.currentState?.setSectionAndSlide(0, 0);
      }
    }

    if (_mainPageController.hasClients) {
      _mainPageController.animateToPage(
        cible,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getNextButtonText() {
    if (_currentStep == _stepAccessibilite && _accessible == false) return 'Enregistrer';
    if (_currentStep == _stepElements) {
      final elementsState = _etapeElementsKey?.currentState;
      if (elementsState != null && elementsState.canGoNext()) {
        return _flow == _LocalFlow.long ? 'Suivant' : 'Terminer';
      }
      return 'Suivant';
    }
    if (_flow == _LocalFlow.long && _currentStep == _stepCellulesTransfo) {
      final formState = _etapeCelluleTransfoKey.currentState;
      if (formState != null && formState.isFormOpen) return formState.formNextLabel;
      return 'Terminer';
    }
    return 'Suivant';
  }

  String _getPreviousButtonText() {
    if (_flow == _LocalFlow.long && _currentStep == _stepCellulesTransfo) {
      final formState = _etapeCelluleTransfoKey.currentState;
      if (formState != null && formState.isFormOpen && formState.isFormFirstSlide) {
        return formState.isEditingExisting ? 'Terminer' : 'Fermer';
      }
    }
    return 'Précédent';
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _elementDebounceTimers.forEach((key, timer) => timer?.cancel());
    _observationControllers.forEach((key, controller) => controller.dispose());
    _nomController.dispose();
    _observationController.dispose();
    _mainPageController.dispose();
    super.dispose();
  }

  void _onElementObservationChanged(int elementIndex, String text, String sectionType) {
    _elementDebounceTimers[elementIndex]?.cancel();
    if (text.length >= 3) {
      _elementDebounceTimers[elementIndex] = Timer(const Duration(milliseconds: 500), () async {
        await _getElementSuggestions(elementIndex, text, sectionType);
      });
    } else {
      setState(() => _elementSuggestions[elementIndex]?.clear());
    }
  }

  Future<void> _getElementSuggestions(int elementIndex, String query, String sectionType) async {
    if (query.length < 3) return;
    final body = <String, dynamic>{'query': query, 'max_results': 5};
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/autocomplete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        setState(() => _elementSuggestions[elementIndex] = List<String>.from(data['suggestions'] ?? []));
      }
    } catch (e) {
      print('Erreur suggestions pour élément $elementIndex: $e');
    }
  }

  void _useElementSuggestion(int elementIndex, String suggestion, ElementControle element, String sectionType) {
    final observationKey = '$sectionType-$elementIndex';
    element.observation = suggestion;
    if (_observationControllers.containsKey(observationKey)) {
      _observationControllers[observationKey]!.text = suggestion;
    }
    setState(() => _elementSuggestions[elementIndex]?.clear());
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _prendrePhotoLocal() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        await GalleryPhotoService.saveToGallery(File(photo.path));
        setState(() => _isLoadingPhotos = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'locaux');
        setState(() {
          _localPhotos.add(savedPath);
          _validateLocalPhotos();
        });
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _choisirPhotoLocalDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'locaux');
        setState(() {
          _localPhotos.add(savedPath);
          _validateLocalPhotos();
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _prendrePhotoObservation() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        await GalleryPhotoService.saveToGallery(File(photo.path));
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        setState(() => _observationPhotos.add(savedPath));
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoObservationDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        setState(() => _observationPhotos.add(savedPath));
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
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

  void _previsualiserPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)]),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: SafeFileImage(path: photos[index], fit: BoxFit.contain)),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
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
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                photos.removeAt(index);
                _validateLocalPhotos();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _ajouterObservation([
    String? pointKey,
    String? refNormative,
    String? famille,
    String? crit,
  ]) {
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
        pointVerificationKey: pointKey,
        referenceNormative: refNormative,
        familleRisque: famille,
        criticite: crit,
      ));
      _observationController.clear();
      _observationPhotos.clear();
      _addObservation = false;
      _validateObservations();
    });
  }

  void _supprimerObservationExistante(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'observation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette observation ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _observationsExistantes.removeAt(index);
                _validateObservations();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }



  void _onAjouterAutre(String sectionType) async {
    final result = await showDialog<ElementControle>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Ajouter un élément "Autre"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Saisissez la description de l\'élément à ajouter :',
                style: TextStyle(fontSize: context.fontSizeM),
              ),
              SizedBox(height: context.spacingM),
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ex: Présence de rongeurs...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final texte = controller.text.trim();
                if (texte.isNotEmpty) {
                  final nouvelElement = ElementControle(
                    elementControle: texte,
                    conforme: false,
                    priorite: 3,
                  );
                  Navigator.pop(context, nouvelElement);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _conformeSelected[result] = false;
        
        if (sectionType == 'dispositions') {
          _dispositionsConstructives.add(result);
          _hasObservation[_dispositionsConstructives.length - 1] = false;
        } else {
          _conditionsExploitation.add(result);
          _hasObservation[_dispositionsConstructives.length + _conditionsExploitation.length - 1] = false;
        }
      });
      
      // Reconstruire les slides dans l'étape éléments
      _etapeElementsKey?.currentState?.rebuildSlides();
      // Aller au dernier slide pour voir le nouvel élément
      _etapeElementsKey?.currentState?.goToLastSlide();
    }
  }

  Future<void> _prendrePhotoPourElement(ElementControle element, int elementIndex, String sectionType) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        await GalleryPhotoService.saveToGallery(File(photo.path));
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'element_photos');
        setState(() => element.photos.add(savedPath));
        await HiveService.addPhotoToElementControle(missionId: widget.mission.id, localisation: _nomController.text.trim(), elementIndex: elementIndex, cheminPhoto: savedPath, sectionType: sectionType);
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoPourElement(ElementControle element, int elementIndex, String sectionType) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'element_photos');
        setState(() => element.photos.add(savedPath));
        await HiveService.addPhotoToElementControle(missionId: widget.mission.id, localisation: _nomController.text.trim(), elementIndex: elementIndex, cheminPhoto: savedPath, sectionType: sectionType);
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  void _supprimerPhotoElement(ElementControle element, int elementIndex, int photoIndex, String sectionType) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => element.photos.removeAt(photoIndex));
              await HiveService.removePhotoFromElementControle(missionId: widget.mission.id, localisation: _nomController.text.trim(), elementIndex: elementIndex, photoIndex: photoIndex, sectionType: sectionType);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _validateCelluleTransfoDonnees() {
    setState(() {
      //  Au moins un transformateur est requis
      if (_selectedType == 'LOCAL_TRANSFORMATEUR') {
        _transfoElementsValid = _transformateurs.isNotEmpty;
      } else {
        _transfoElementsValid = true;
      }
      _celluleElementsValid = true; // Cellules optionnelles
    });
    _saveDraft();
  }

  /// Supprime le local inaccessible de Hive dès que l'utilisateur le marque accessible.
  /// Le brouillon prend le relai et devient le seul élément visible dans la liste.
  Future<void> _supprimerLocalOriginalPourReverification() async {
    if (widget.localIndex == null && widget.local == null) return;
    try {
      final localId = widget.local?.localId;
      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null) {
          await HiveService.deleteLocalFromZone(
            missionId: widget.mission.id,
            isMoyenneTension: true,
            zoneIndex: widget.zoneIndex,
            localIndex: widget.localIndex,
            localId: localId,
          );
        } else {
          await HiveService.deleteMoyenneTensionLocal(
            missionId: widget.mission.id,
            localIndex: widget.localIndex ?? 0,
            localId: localId,
          );
        }
      } else {
        if (widget.zoneIndex != null) {
          await HiveService.deleteLocalFromBasseTensionZone(
            missionId: widget.mission.id,
            zoneIndex: widget.zoneIndex!,
            localIndex: widget.localIndex ?? 0,
            localId: localId,
          );
        }
      }
      if (kDebugMode) print('✅ Local inaccessible supprimé pour révérification');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur suppression local révérification: $e');
    }
  }

  void _sauvegarder() async {
    if (!_nomValid || !_typeValid) {
      _showError('Veuillez remplir tous les champs obligatoires');
      _mainPageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final nouveauLocal = await _persisterEquipementEtLocalImmediatement();
      await InstallationDescriptionSyncService.repairAndSyncDescriptions(widget.mission.id);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdition ? 'Local modifié' : 'Local ajouté'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (widget.isEdition) {
        Navigator.pop(context, true);
      } else {
        await _allerAuClassement(nouveauLocal);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (kDebugMode) {
        print('❌ Erreur sauvegarde: $e');
      }
      _showError('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<void> _sauvegarderInaccessible() async {
    setState(() => _isLoading = true);
    try {
      // Créer le local avec accessible=false et aReverifier=true
      // Les éléments de contrôle sont vides, pas de cellules ni transformateurs.
      if (widget.isMoyenneTension) {
        final local = MoyenneTensionLocal(
          nom: _nomController.text.trim(),
          type: _selectedType ?? 'LOCAL_ELECTRIQUE',
          accessible: false,
          aReverifier: true,
          isRiskZone: _isRiskZone,
        );
        if (widget.isInZone && widget.zoneIndex != null) {
          // Vérifier doublon par nom
          final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
          final zone = audit.moyenneTensionZones[widget.zoneIndex!];
          final existingIndex = zone.locaux.indexWhere((l) => l.nom.trim() == local.nom.trim());
          if (existingIndex != -1) {
            await HiveService.updateLocalInMoyenneTensionZone(
              missionId: widget.mission.id, zoneIndex: widget.zoneIndex!,
              localIndex: existingIndex, local: local,
            );
          } else {
            await HiveService.addLocalToMoyenneTensionZone(
              missionId: widget.mission.id, zoneIndex: widget.zoneIndex!, local: local,
            );
          }
        } else {
          final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
          final existingIndex = audit.moyenneTensionLocaux.indexWhere((l) => l.nom.trim() == local.nom.trim());
          if (existingIndex != -1) {
            await HiveService.updateMoyenneTensionLocal(
              missionId: widget.mission.id, localIndex: existingIndex, local: local,
            );
          } else {
            await HiveService.addMoyenneTensionLocal(missionId: widget.mission.id, local: local);
          }
        }
      } else {
        final local = BasseTensionLocal(
          nom: _nomController.text.trim(),
          type: _selectedType ?? 'LOCAL_ELECTRIQUE',
          accessible: false,
          aReverifier: true,
          isRiskZone: _isRiskZone,
        );
        if (widget.zoneIndex != null) {
          final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          final existingIndex = zone.locaux.indexWhere((l) => l.nom.trim() == local.nom.trim());
          if (existingIndex != -1) {
            await HiveService.updateBasseTensionLocal(
              missionId: widget.mission.id, zoneIndex: widget.zoneIndex!,
              localIndex: existingIndex, local: local,
            );
          } else {
            await HiveService.addLocalToBasseTensionZone(
              missionId: widget.mission.id, zoneIndex: widget.zoneIndex!, local: local,
            );
          }
        }
      }

      // Supprimer le brouillon éventuel
      await HiveService.deleteLocalDraft(_draftLocalId!);
      setState(() => _isLoading = false);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors de la sauvegarde : $e');
    }
  }

  Future<void> _allerAuClassement(dynamic local) async {
    if (local == null) {
      _showError('Erreur: impossible de créer le classement pour ce local');
      Navigator.pop(context, true);
      return;
    }
    
    final bool estDansUneZone = widget.isInZone && widget.zoneIndex != null;
    
    if (estDansUneZone) {
      final choix = await _showChoixClassementDialog(local);
      
      if (choix == null) {
        if (mounted) Navigator.pop(context, true);
        return;
      }
      
      if (choix == 'heriter') {
        // Récupérer le ClassementZone complet
        final zoneClassement = await _getZoneParenteClassement();
        
        if (zoneClassement != null) {
          // Vérifier que la zone a bien un classement complet
          if (!zoneClassement.estComplet) {
            _showSnackBar(
              'La zone parente n\'a pas encore de classement complet. '
              'Veuillez d\'abord classer la zone, ou choisir un classement spécifique.',
              Colors.orange,
            );
            // Proposer de définir un classement spécifique à la place
            final choix2 = await _showChoixClassementDialog(local, zoneNonClassee: true);
            if (choix2 == 'specifique') {
              // Continuer vers classement spécifique
            } else {
              if (mounted) Navigator.pop(context, true);
              return;
            }
          } else {
            // Créer un classement qui hérite en COPIANT les valeurs
            final classement = ClassementEmplacement.createLocalHeritant(
              missionId: widget.mission.id,
              nomLocal: local.nom,
              zoneParente: zoneClassement.nomZone,
              zoneClassement: zoneClassement, // ← Passer l'objet complet
            );
            
            // Ajouter à la box
            final classementBox = Hive.box<ClassementEmplacement>('classement_locaux');
            await classementBox.add(classement);
            
            _showSnackBar('Classement hérité avec succès', Colors.green);
            Navigator.pop(context, true);
            return;
          }
        } else {
          _showSnackBar(
            'La zone parente n\'a pas encore de classement. '
            'Veuillez définir un classement spécifique.',
            Colors.orange,
          );
          // Continuer vers classement spécifique
        }
      }
      
      // Si on arrive ici, c'est qu'on va en classement spécifique
      final classement = await HiveService.getOrCreateClassementForLocal(
        missionId: widget.mission.id,
        localisation: local.nom,
        zone: 'Zone ${widget.zoneIndex! + 1}',
        typeLocal: local.type,
      );
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassementEmplacementScreen(
            mission: widget.mission,
            emplacement: classement,
          ),
        ),
      );
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      // Local hors zone : classement spécifique obligatoire
      final classement = await HiveService.getOrCreateClassementForLocal(
        missionId: widget.mission.id,
        localisation: local.nom,
        zone: null,
        typeLocal: local.type,
      );
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassementEmplacementScreen(
            mission: widget.mission,
            emplacement: classement,
          ),
        ),
      );
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
  
  
  // NOUVEAU : Dialogue de choix héritage/spécifique
  Future<String?> _showChoixClassementDialog(dynamic local, {bool zoneNonClassee = false}) async {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_outlined,
                  size: 30,
                  color: AppTheme.primaryBlue,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Classement du local',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                zoneNonClassee 
                  ? 'La zone parente n\'a pas encore de classement complet. Vous devez définir un classement spécifique pour ce local.'
                  : 'Ce local appartient à une zone. Comment souhaitez-vous définir son classement ?',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              
              // Option 1 : Hériter (seulement si la zone est classée)
              if (!zoneNonClassee)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, 'heriter'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.link, color: Colors.blue, size: 22),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hériter du classement de la zone',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Le local suivra automatiquement le classement de sa zone parente',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    color: Colors.blue.shade600,
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
              
              if (!zoneNonClassee) SizedBox(height: 12),
              
              // Option 2 : Spécifique
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: InkWell(
                  onTap: () => Navigator.pop(context, 'specifique'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.edit_note, color: Colors.orange, size: 22),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Définir un classement spécifique',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Vous pourrez définir des influences externes différentes de la zone',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.orange.shade600,
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
              
              SizedBox(height: 16),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<ClassementZone?> _getZoneParenteClassement() async {
    if (!widget.isInZone || widget.zoneIndex == null) return null;
    
    final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
    String? nomZone;
    
    if (widget.isMoyenneTension) {
      if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
        nomZone = audit.moyenneTensionZones[widget.zoneIndex!].nom;
      }
    } else {
      if (widget.zoneIndex! < audit.basseTensionZones.length) {
        nomZone = audit.basseTensionZones[widget.zoneIndex!].nom;
      }
    }
    
    if (nomZone == null) return null;
    
    // Synchroniser d'abord pour s'assurer que le classement existe
    await HiveService.syncClassementsZonesFromAudit(widget.mission.id);
    
    // Chercher le classement de la zone
    return HiveService.getClassementZoneByNom(widget.mission.id, nomZone);
  }

  MoyenneTensionLocal _creerMoyenneTensionLocal() {
    // LOCAL_TRANSFORMATEUR et LOCAL_MTBT ont tous les deux cellules et transformateurs
    final isFlowLong = _selectedType == 'LOCAL_TRANSFORMATEUR' || _selectedType == 'LOCAL_MTBT';
    final now = DateTime.now().toUtc();
    final existingLocal = widget.isEdition && widget.local is MoyenneTensionLocal ? (widget.local as MoyenneTensionLocal) : null;
    return MoyenneTensionLocal(
      id: existingLocal?.localId,
      createdAt: existingLocal?.createdAt ?? (widget.isEdition ? null : now),
      updatedAt: now,
      nom: _nomController.text.trim().isEmpty ? 'Sans nom' : _nomController.text.trim(),
      type: _selectedType!,
      dispositionsConstructives: _dispositionsConstructives,
      conditionsExploitation: _conditionsExploitation,
      observationsLibres: _observationsExistantes,
      photos: _localPhotos,
      cellules: isFlowLong ? _cellules : [],
      transformateurs: isFlowLong ? _transformateurs : [],
      accessible: _accessible ?? true,
      aReverifier: (_accessible == false),
      coffrets: widget.isEdition && widget.local != null ? (widget.local as MoyenneTensionLocal).coffrets : [],
      isRiskZone: _isRiskZone,
    );
  }

  BasseTensionLocal _creerBasseTensionLocal() {
    return _creerBasseTensionLocalAvecType(_selectedType!);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));
  }

  int _getTotalSteps() => _totalSteps;

  @override
  Widget build(BuildContext context) {
    final totalSteps = _getTotalSteps();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          _confirmerQuitter();
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(widget.isEdition ? 'Modifier le Local' : 'Ajouter un Local', style: TextStyle(fontSize: context.fontSizeL)),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _confirmerQuitter,
            ),
            actions: [
                if (widget.isEdition && !(widget.local?.aReverifier ?? false))
                IconButton(
                  icon: Icon(Icons.check, size: context.iconSizeM),
                  onPressed: _sauvegarder,
                  tooltip: 'Enregistrer les modifications',
                ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingM),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.spacingS, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: List.generate(totalSteps * 2 - 1, (i) {
                  if (i.isEven) {
                    final index = i ~/ 2;
                    final isActive = index <= _currentStep;
                    final isCompleted = index < _currentStep;
                    return GestureDetector(
                      onTap: widget.isEdition ? () => _changerEtapeDirecte(index) : null,
                      child: Container(
                        width: context.iconSizeL,
                        height: context.iconSizeL,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primaryBlue : Colors.grey.shade300,
                          shape: BoxShape.circle,
                          boxShadow: isActive ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.check, color: Colors.white, size: context.iconSizeS)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.fontSizeS,
                                  ),
                                ),
                        ),
                      ),
                    );
                  } else {
                    final lineIndex = i ~/ 2;
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.symmetric(horizontal: context.spacingXS),
                        decoration: BoxDecoration(
                          color: lineIndex < _currentStep ? AppTheme.primaryBlue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    );
                  }
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _mainPageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                  _saveDraft();
                },
                children: [
                  _EtapeInformationsGenerales(
                    nomController: _nomController,
                    selectedType: _selectedType,
                    onTypeChanged: _onTypeChanged,
                    isMoyenneTension: widget.isMoyenneTension,
                    localPhotos: _localPhotos,
                    onPrendrePhoto: _prendrePhotoLocal,
                    onChoisirPhoto: _choisirPhotoLocalDepuisGalerie,
                    onSupprimerPhoto: () {},
                    isLoadingPhotos: _isLoadingPhotos,
                    addObservation: _addObservation,
                    onAddObservationChanged: (value) {
                      setState(() {
                        _addObservation = value;
                        _validateObservations();
                      });
                    },
                    observationController: _observationController,
                    observationsExistantes: _observationsExistantes,
                    observationPhotos: _observationPhotos,
                    onPrendrePhotoObservation: _prendrePhotoObservation,
                    onChoisirPhotoObservation: _choisirPhotoObservationDepuisGalerie,
                    onAjouterObservation: ([key, ref, fam, crit]) => _ajouterObservation(key, ref, fam, crit),
                    onSupprimerObservationExistante: _supprimerObservationExistante,
                    nomValid: _nomValid,
                    typeValid: _typeValid,
                    onValidate: () => _validateNom(_nomController.text),
                    isRiskZone: _isRiskZone,
                    onRiskZoneChanged: (val) {
                      setState(() => _isRiskZone = val);
                      _scheduleAutoSave();
                    },
                  ),

                  _buildSlideAccessibilite(),

                  if (_selectedType != null)
                    _EtapeElementsControle(
                    key: _etapeElementsKey,
                    dispositionsConstructives: _dispositionsConstructives,
                    conditionsExploitation: _conditionsExploitation,
                    hasObservation: _hasObservation,
                    elementSuggestions: _elementSuggestions,
                    conformeSelected: _conformeSelected,
                    onElementChanged: (element, index, action) => setState(() {}),
                    onConformeChanged: _onConformeChanged,
                    onObservationToggleChanged: (index, value, section) => setState(() => _hasObservation[index] = value),
                    onPrendrePhotoElement: _prendrePhotoPourElement,
                    onChoisirPhotoElement: _choisirPhotoPourElement,
                    onSupprimerPhotoElement: _supprimerPhotoElement,
                    onObservationChanged: _onElementObservationChanged,
                    onUseSuggestion: _useElementSuggestion,
                    onAjouterAutre: _onAjouterAutre,
                    onRebuildSlides: () {
                      _etapeElementsKey?.currentState?.rebuildSlides();
                    },
                    onSavePhoto: (file, section) async {
                      return await _savePhotoToAppDirectory(file, section);
                    },
                    onAutoSave: () => _scheduleAutoSave(),
                  ),

                  if (_selectedType == 'LOCAL_TRANSFORMATEUR' || _selectedType == 'LOCAL_MTBT')
                  _EtapeCelluleTransformateurMulti(
                    key: _etapeCelluleTransfoKey,
                    localNom: _nomController.text,
                    cellules: _cellules,
                    transformateurs: _transformateurs,
                    onCellulesChanged: (nouvellesCellules) async {
                      setState(() { _cellules = nouvellesCellules; });
                      await _persisterEquipementEtLocalImmediatement();
                      _validateCelluleTransfoDonnees();
                    },
                    onTransformateursChanged: (nouveauxTransformateurs) async {
                      setState(() { _transformateurs = nouveauxTransformateurs; });
                      await _persisterEquipementEtLocalImmediatement();
                      _validateCelluleTransfoDonnees();
                    },
                    onDataChanged: () async {
                      await _persisterEquipementEtLocalImmediatement();
                      _validateCelluleTransfoDonnees();
                    },
                    onFormStateChanged: () => setState(() {}),
                    onSavePhoto: (file, section) async {
                      return await _savePhotoToAppDirectory(file, section);
                    },
                  ),
              ].whereType<Widget>().toList(),
            ),
          ),

            Container(
              padding: EdgeInsets.all(context.spacingL),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.spacingS, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handlePrevious,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: context.spacingM),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                        ),
                        child: Text(_getPreviousButtonText(), style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                      ),
                    ),
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

  Future<void> _confirmerQuitter() async {
    final quitter = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter sans sauvegarder ?'),
        content: const Text(
          'Les données saisies seront conservées comme brouillon. '
          'Voulez-vous quitter cette page ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Rester'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (quitter == true && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildSlideAccessibilite() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accessibilité du local',
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
            'Ce local est-il accessible ?',
            style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAccessibiliteOption(
                  label: 'Oui',
                  icon: Icons.check_circle_outline,
                  selected: _accessible == true,
                  color: Colors.green,
                  onTap: () async {
                    setState(() {
                      _accessible = true;
                      if (_dispositionsConstructives.isEmpty && _selectedType != null) {
                        _initializeElementsForType(_selectedType);
                      }
                    });
                    // Si c'est un local aReverifier : supprimer le local original de Hive
                    // pour que le brouillon soit visible sans doublon dans la liste
                    final isReverification = widget.isEdition &&
                        ((widget.local as dynamic?)?.aReverifier == true);
                    if (isReverification && widget.localIndex != null) {
                      await _supprimerLocalOriginalPourReverification();
                    }
                    _saveDraft();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAccessibiliteOption(
                  label: 'Non',
                  icon: Icons.cancel_outlined,
                  selected: _accessible == false,
                  color: Colors.red,
                  onTap: () => setState(() => _accessible = false),
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
                      'Le local sera enregistré comme inaccessible et marqué "À revérifier". '
                      'Aucun élément d\'inspection ne sera requis.',
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

  Widget _buildAccessibiliteOption({
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
}