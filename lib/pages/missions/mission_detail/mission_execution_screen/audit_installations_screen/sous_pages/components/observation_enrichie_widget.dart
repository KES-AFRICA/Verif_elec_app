import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/services/gallery_photo_service.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/components/normative_search_suggestions_widget.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_coffret_screen.dart';
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:inspec_app/utils/observation_text_normalizer.dart';

class ObservationEnrichieWidget extends StatefulWidget {
  final ElementControle element;
  final VoidCallback onChanged;
  final Color color;
  final Future<String?> Function(File, String) onSavePhoto;
  final List<String> suggestions;
  final bool showPriority;
  final String sectionType;
  final bool enableNormativeSearch;

  const ObservationEnrichieWidget({
    super.key,
    required this.element,
    required this.onChanged,
    required this.color,
    required this.onSavePhoto,
    this.suggestions = const [],
    this.showPriority = true,
    required this.sectionType,
    this.enableNormativeSearch = false,
  });

  @override
  State<ObservationEnrichieWidget> createState() =>
      _ObservationEnrichieWidgetState();
}

class _ObservationEnrichieWidgetState extends State<ObservationEnrichieWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _prendrePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) {
      // Sauvegarde parallèle et indépendante de l'original dans la Galerie du téléphone
      await GalleryPhotoService.saveToGallery(File(photo.path));

      final savedPath = await widget.onSavePhoto(
        File(photo.path),
        widget.sectionType,
      );
      if (savedPath != null) {
        setState(() {
          widget.element.photos.add(savedPath);
        });
        widget.onChanged();
      }
    }
  }

  Future<void> _choisirPhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (photo != null) {
      final savedPath = await widget.onSavePhoto(
        File(photo.path),
        widget.sectionType,
      );
      if (savedPath != null) {
        setState(() {
          widget.element.photos.add(savedPath);
        });
        widget.onChanged();
      }
    }
  }

  void _supprimerPhoto(int photoIndex) {
    setState(() {
      widget.element.photos.removeAt(photoIndex);
    });
    widget.onChanged();
  }

  Widget _buildPrioriteButton(
    BuildContext context, {
    required String label,
    required String tooltip,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: context.spacingM),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.fontSizeS,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernPrioriteSelector(BuildContext context) {
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
              isSelected: widget.element.priorite == 1,
              color: Colors.blue,
              onTap: () {
                setState(() {
                  widget.element.priorite = 1;
                });
                widget.onChanged();
              },
            ),
          ),
          SizedBox(width: context.spacingXS),
          Expanded(
            child: _buildPrioriteButton(
              context,
              label: 'N2',
              tooltip: 'Moyenne priorité',
              isSelected: widget.element.priorite == 2,
              color: Colors.orange,
              onTap: () {
                setState(() {
                  widget.element.priorite = 2;
                });
                widget.onChanged();
              },
            ),
          ),
          SizedBox(width: context.spacingXS),
          Expanded(
            child: _buildPrioriteButton(
              context,
              label: 'N3',
              tooltip: 'Haute priorité',
              isSelected: widget.element.priorite == 3,
              color: Colors.red,
              onTap: () {
                setState(() {
                  widget.element.priorite = 3;
                });
                widget.onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernObservationField(BuildContext context) {
    final hasNoObservation = widget.element.observation == null || widget.element.observation!.trim().isEmpty;
    final showRequiredBorder = widget.showPriority && hasNoObservation;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: showRequiredBorder ? Colors.red.shade300 : Colors.grey.shade300,
              width: showRequiredBorder ? 1.5 : 1,
            ),
          ),
          child: TextFormField(
            initialValue: widget.element.observation,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: context.fontSizeS),
            onChanged: (value) {
              setState(() {
                widget.element.observation = ObservationTextNormalizer.normalize(value);
              });
              widget.onChanged();
            },
            decoration: InputDecoration(
              hintText: widget.showPriority ? 'Saisissez votre observation... *' : 'Saisissez votre observation...',
              hintStyle: TextStyle(
                fontSize: context.fontSizeS,
                color: Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(context.spacingM),
            ),
            maxLines: 2,
          ),
        ),
        if (widget.enableNormativeSearch)
          NormativeSearchSuggestionsWidget(
            queryText: widget.element.observation ?? '',
            selectedReferenceNormative: widget.element.referenceNormative,
            selectedFamilleRisque: widget.element.familleRisque,
            selectedCriticite: widget.element.criticite,
            onSelect: (res) {
              setState(() {
                widget.element.referenceNormative = res.referenceNormative;
                widget.element.familleRisque = res.familleRisque;
                widget.element.criticite = res.criticite;
              });
              widget.onChanged();
            },
            onUnlink: () {
              setState(() {
                widget.element.referenceNormative = null;
                widget.element.familleRisque = null;
                widget.element.criticite = null;
              });
              widget.onChanged();
            },
          ),
        if (widget.suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: context.spacingS),
            padding: EdgeInsets.all(context.spacingS),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(context.spacingS),
              border: Border.all(color: widget.color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggestions d\'observations',
                  style: TextStyle(
                    fontSize: context.fontSizeXS,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
                SizedBox(height: context.spacingXS),
                ...widget.suggestions.map(
                  (s) => GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.element.observation = s;
                      });
                      widget.onChanged();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.spacingXS,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: context.iconSizeXS,
                            color: Colors.amber,
                          ),
                          SizedBox(width: context.spacingS),
                          Expanded(
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: context.fontSizeXS,
                                color: Colors.grey.shade700,
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
          ),
      ],
    );
  }

  Widget _buildModernElementPhotos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: context.iconSizeXS,
              color: widget.color,
            ),
            SizedBox(width: context.spacingS),
            Flexible(
              child: Text(
                'Photos (${widget.element.photos.length})',
                style: TextStyle(
                  fontSize: context.fontSizeS,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingS),
        if (widget.element.photos.isNotEmpty)
          Container(
            height: context.screenHeight * 0.1,
            margin: EdgeInsets.only(bottom: context.spacingS),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.element.photos.length,
              itemBuilder: (context, photoIndex) {
                return Stack(
                  children: [
                    Container(
                      width: context.screenWidth * 0.2,
                      margin: EdgeInsets.only(right: context.spacingS),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(context.spacingS),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(context.spacingS),
                        child: SafeFileImage(
                          path: widget.element.photos[photoIndex],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _supprimerPhoto(photoIndex),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: context.iconSizeXS - 2,
                            color: Colors.white,
                          ),
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
              child: OutlinedButton.icon(
                onPressed: _prendrePhoto,
                icon: Icon(Icons.camera_alt_outlined, size: context.iconSizeXS),
                label: Text(
                  'Caméra',
                  style: TextStyle(fontSize: context.fontSizeXS),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.color,
                  side: BorderSide(color: widget.color.withOpacity(0.5)),
                  padding: EdgeInsets.symmetric(vertical: context.spacingS),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.spacingS),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.spacingS),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _choisirPhoto,
                icon: Icon(
                  Icons.photo_library_outlined,
                  size: context.iconSizeXS,
                ),
                label: Text(
                  'Galerie',
                  style: TextStyle(fontSize: context.fontSizeXS),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.color,
                  side: BorderSide(color: widget.color.withOpacity(0.5)),
                  padding: EdgeInsets.symmetric(vertical: context.spacingS),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.spacingS),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si l'élément requiert une priorité (non-conforme) et n'en a pas encore,
    // on assure la valeur par défaut dans le modèle de données sans l'exposer dans l'UI
    if (widget.showPriority && widget.element.priorite == null) {
      widget.element.priorite = 3;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notion de priorité masquée de l'interface utilisateur (données et modèle conservés)
        /*
        if (widget.showPriority) ...[
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
          _buildModernPrioriteSelector(context),
          SizedBox(height: context.spacingM),
        ],
        */
        _buildModernObservationField(context),
        SizedBox(height: context.spacingM),
        _buildModernElementPhotos(context),
      ],
    );
  }
}
