import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/services/gallery_photo_service.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import 'package:inspec_app/utils/observation_text_normalizer.dart';

class AddNonConformingLuminaireSheet extends StatefulWidget {
  final NonConformingLuminaire? initialLuminaire;

  const AddNonConformingLuminaireSheet({super.key, this.initialLuminaire});

  @override
  State<AddNonConformingLuminaireSheet> createState() =>
      _AddNonConformingLuminaireSheetState();
}

class _AddNonConformingLuminaireSheetState
    extends State<AddNonConformingLuminaireSheet> {
  late List<LuminaireQuestionAnswer> _answers;
  late List<TextEditingController> _commentControllers;
  late List<bool>
  _isChoiceSet; // Suivi explicite de réponse par question (3 éléments par slide)

  int _currentStep = 0; // 0, 1, 2, 3 (4 slides de 3 questions = 12 points)
  final ImagePicker _picker = ImagePicker();

  static const List<String> _questionsText = [
    '1. État général du luminaire',
    '2. Fixation correcte et stable',
    '3. Protection contre les contacts directs',
    '4. Absence d\'échauffement ou de brûlure',
    '5. Absence de corrosion ou d\'encrassement',
    '6. Indice IP adapté au local',
    '7. Conducteurs correctement raccordés',
    '8. Présence de la mise à la terre',
    '9. Allumage correct',
    '10. Extinction correcte',
    '11. Absence de scintillement',
    '12. Accessibilité pour la maintenance',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.initialLuminaire != null &&
        widget.initialLuminaire!.answers.isNotEmpty) {
      _answers = widget.initialLuminaire!.answers
          .map(
            (a) => LuminaireQuestionAnswer(
              questionIndex: a.questionIndex,
              isConform: a.isConform,
              commentaire: a.commentaire,
              photoPaths: List.from(a.photoPaths),
            ),
          )
          .toList();
      _isChoiceSet = List.generate(12, (_) => true);
    } else {
      _answers = List.generate(
        12,
        (i) => LuminaireQuestionAnswer(
          questionIndex: i + 1,
          isConform: true,
          commentaire: '',
        ),
      );
      // Mode création : aucun choix sélectionné par défaut (les deux boutons sont non sélectionnés)
      _isChoiceSet = List.generate(12, (_) => false);
    }

    // 12 contrôleurs indépendants
    _commentControllers = List.generate(
      12,
      (i) => TextEditingController(text: _answers[i].commentaire),
    );
  }

  @override
  void dispose() {
    for (final controller in _commentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Condition stricte : Les 3 éléments du slide courant doivent être cochés/validés
  bool _areAllCurrentSlideElementsAnswered(int step) {
    final startIndex = step * 3;
    final endIndex = startIndex + 3;

    for (int i = startIndex; i < endIndex; i++) {
      if (!_isChoiceSet[i]) return false;
      // Si marqué non conforme, exiger une observation ou une photo
      if (!_answers[i].isConform) {
        final comment = _commentControllers[i].text.trim();
        if (comment.isEmpty && _answers[i].photoPaths.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  /// Explication des éléments manquants sur le slide courant
  String? _getCurrentSlideError(int step) {
    final startIndex = step * 3;
    final endIndex = startIndex + 3;

    for (int i = startIndex; i < endIndex; i++) {
      if (!_isChoiceSet[i]) {
        return 'Veuillez cocher/répondre à la question n°${i + 1}.';
      }
      if (!_answers[i].isConform) {
        final comment = _commentControllers[i].text.trim();
        if (comment.isEmpty && _answers[i].photoPaths.isEmpty) {
          return 'Veuillez saisir une observation ou une photo pour le point n°${i + 1}.';
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final canProceed = _areAllCurrentSlideElementsAnswered(_currentStep);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
            // ── Header du Bottom Sheet (Inspiré de AjouterLocalScreen) ──
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialLuminaire != null
                              ? 'Modifier le luminaire'
                              : 'Contrôle du luminaire non conforme',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Étape ${_currentStep + 1} sur 4 (Questions ${_currentStep * 3 + 1} à ${_currentStep * 3 + 3})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Progress Bar ──
            LinearProgressIndicator(
              value: (_currentStep + 1) / 4.0,
              backgroundColor: AppTheme.greyLight,
              color: AppTheme.primaryBlue,
              minHeight: 4,
            ),

            // ── Scrollable Body des 3 Questions du Slide ──
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (
                      int i = _currentStep * 3;
                      i < (_currentStep + 1) * 3;
                      i++
                    ) ...[
                      _buildQuestionCardItem(i),
                      if (i < (_currentStep + 1) * 3 - 1)
                        const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // ── Bar de Navigation (Style & Couleurs de AjouterLocalScreen) ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _currentStep--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Précédent'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        if (!canProceed) {
                          final errorMsg = _getCurrentSlideError(_currentStep);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                errorMsg ??
                                    'Veuillez cocher les 3 éléments du slide courant.',
                              ),
                              backgroundColor: Colors.orange.shade800,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        if (_currentStep < 3) {
                          setState(() {
                            _currentStep++;
                          });
                        } else {
                          _saveAndClose();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canProceed
                            ? AppTheme.primaryBlue
                            : Colors.grey.shade400,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_currentStep < 3 ? 'Suivant' : 'Enregistrer'),
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

  /// Carte Question avec Choix (Conforme / Non conforme) & Zone Commentaire+Photo style Coffret
  Widget _buildQuestionCardItem(int index) {
    final answer = _answers[index];
    final questionTitle = _questionsText[index];
    final controller = _commentControllers[index];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !_isChoiceSet[index]
              ? Colors.grey.shade300
              : (answer.isConform
                    ? Colors.green.shade300
                    : Colors.red.shade300),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              questionTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),

            // ── Choix Conforme / Non Conforme (Boutons bascules M3) ──
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Conforme'),
                    selected: _isChoiceSet[index] && answer.isConform,
                    selectedColor: Colors.green.shade100,
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(
                      color: (_isChoiceSet[index] && answer.isConform)
                          ? Colors.green.shade600
                          : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: (_isChoiceSet[index] && answer.isConform)
                          ? Colors.green.shade800
                          : AppTheme.textDark,
                      fontWeight: (_isChoiceSet[index] && answer.isConform)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isChoiceSet[index] = true;
                          answer.isConform = true;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Non conforme'),
                    selected: _isChoiceSet[index] && !answer.isConform,
                    selectedColor: Colors.red.shade100,
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(
                      color: (_isChoiceSet[index] && !answer.isConform)
                          ? Colors.red.shade600
                          : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: (_isChoiceSet[index] && !answer.isConform)
                          ? Colors.red.shade800
                          : AppTheme.textDark,
                      fontWeight: (_isChoiceSet[index] && !answer.isConform)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isChoiceSet[index] = true;
                          answer.isConform = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Widget Observation Enrichie (Commentaire + Photos Style Coffret/Équipement) ──
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: ValueKey('comment_field_$index'),
                      controller: controller,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      onChanged: (val) {
                        answer.commentaire = val;
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: !answer.isConform
                            ? 'Saisissez votre observation... *'
                            : 'Observations optionnelles...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Boutons Photo (Appareil Photo / Galerie)
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _pickPhoto(answer, ImageSource.camera),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Photo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _pickPhoto(answer, ImageSource.gallery),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Galerie',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (answer.photoPaths.isNotEmpty)
                          Text(
                            '${answer.photoPaths.length} photo(s)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                      ],
                    ),

                    // Miniatures des photos
                    if (answer.photoPaths.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: answer.photoPaths.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, pIndex) {
                            final path = answer.photoPaths[pIndex];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(path),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.image, size: 20),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        answer.photoPaths.removeAt(pIndex);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
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
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Prise / Sélection de photo avec persistance pérenne dans audit_photos
  Future<void> _pickPhoto(
    LuminaireQuestionAnswer answer,
    ImageSource source,
  ) async {
    final XFile? photo = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (photo != null) {
      if (source == ImageSource.camera) {
        await GalleryPhotoService.saveToGallery(File(photo.path));
      }

      // Persistance physique pérenne dans le répertoire applicatif audit_photos
      String permanentPath = photo.path;
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final photosDir = Directory('${appDir.path}/audit_photos/luminaires');
        if (!photosDir.existsSync()) {
          photosDir.createSync(recursive: true);
        }
        final ext = photo.path.split('.').last;
        final newFileName = 'lum_${DateTime.now().microsecondsSinceEpoch}.$ext';
        final targetFile = File('${photosDir.path}/$newFileName');
        await File(photo.path).copy(targetFile.path);
        permanentPath = targetFile.path;
      } catch (e) {
        // Fallback sur le chemin initial en cas d'erreur I/O
        permanentPath = photo.path;
      }

      setState(() {
        answer.photoPaths.add(permanentPath);
      });
    }
  }

  /// Validation et fermeture
  void _saveAndClose() {
    for (int i = 0; i < 12; i++) {
      final text = _commentControllers[i].text.trim();
      _answers[i].commentaire =
          ObservationTextNormalizer.normalize(text) ?? text;
    }

    final newId = 'lum_${DateTime.now().microsecondsSinceEpoch}';
    final luminaire = NonConformingLuminaire(
      id: widget.initialLuminaire?.id ?? newId,
      repereLocalisation: widget.initialLuminaire?.repereLocalisation,
      answers: _answers,
      createdAt: widget.initialLuminaire?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(luminaire);
  }
}
