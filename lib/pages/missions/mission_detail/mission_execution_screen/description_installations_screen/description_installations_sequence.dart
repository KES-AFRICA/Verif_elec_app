// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/description_installations_sequence.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/alimentation_site_mt_sequence_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/description_installations_form.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/paratonnerre_sequence_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/radio_sequence_screen.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/core/providers/description_installations_providers.dart';

class DescriptionInstallationsSequenceScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final VoidCallback onPreviousStep;
  final VoidCallback onNextStep;
  final int? initialSectionIndex;
  final VoidCallback? onSubStepChanged;

  const DescriptionInstallationsSequenceScreen({
    super.key,
    required this.mission,
    required this.onPreviousStep,
    required this.onNextStep,
    this.initialSectionIndex,
    this.onSubStepChanged,
  });

  @override
  ConsumerState<DescriptionInstallationsSequenceScreen> createState() =>
      DescriptionInstallationsSequenceScreenState();
}

class DescriptionInstallationsSequenceScreenState
    extends ConsumerState<DescriptionInstallationsSequenceScreen> {
  int _currentStep = 0;
  Map<String, bool> _progress = {};
  bool _isLoading = true;
  bool _isFirstLoad = true;

  late PageController _pageController;

  List<Map<String, dynamic>> get _sections => [
    {
      'key': 'alimentation_site_mt',
      'title': 'Alimentation du site Moyen Tension',
      'shortTitle': 'Alim. site MT',
      'icon': Icons.bolt_outlined,
      'color': const Color(0xFFE67E22),
      'isAlimentationSiteMt': true,
    },
    {
      'key': 'alimentation_moyenne_tension',
      'title': 'Caractéristiques de l\'alimentation moyenne tension',
      'shortTitle': 'Alimentation MT',
      'icon': Icons.bolt_outlined,
      'color': const Color(0xFFE67E22),
      'champs': [
        'Gamme De Cellule',
        'Type De Cellule',
        'Tension de service',
        'Tension assignée',
        'Section Du Cable',
        'Nature Du Reseau',
        'Observations',
      ],
      'requiredFields': [''],
      'isList': true,
    },
    {
      'key': 'alimentation_basse_tension',
      'title':
          'Caractéristiques de l\'alimentation basse tension sortie transformateur',
      'shortTitle': 'Alimentation BT',
      'icon': Icons.bolt_outlined,
      'color': const Color(0xFF2980B9),
      'champs': [
        'Puissance Transformateur',
        'Type de transformateur',
        'Intensité nominale',
        'Calibre Du Disjoncteur Sortie Transformateur',
        'Section Du Cable',
        'Tension primaire / secondaire',
        'Couplage',
        'Type de réseau',
        'PCC amont',
        'Puissance UCC',
        'IK3 MAX',
        'Observations',
      ],
      'requiredFields': [''],
      'isList': true,
    },
    {
      'key': 'groupe_electrogene',
      'title': 'Caractéristiques du groupe électrogène',
      'shortTitle': 'Groupe électrogène',
      'icon': Icons.electrical_services_outlined,
      'color': const Color(0xFF27AE60),
      'champs': [
        'Identification',
        'Marque',
        'Type',
        'N° Serie',
        'Puissance (Kva)',
        'Intensite',
        'Annee De Fabrication',
        'Calibre Du Disjoncteur',
        'Section Du Cable',
      ],
      'requiredFields': [''],
      'isList': true,
    },
    {
      'key': 'alimentation_carburant',
      'title': 'Alimentation du groupe électrogène en carburant',
      'shortTitle': 'Alim. carburant',
      'icon': Icons.local_gas_station_outlined,
      'color': const Color(0xFF8E44AD),
      'champs': [
        'Identification du GE',
        'Mode',
        'Capacite',
        'Cuve De Retention',
        'Indicateur De Niveau',
        'Mise A La Terre',
        'Annee De Fabrication',
      ],
      'requiredFields': [''],
      'isList': true,
    },
    {
      'key': 'inverseur',
      'title': 'Caractéristiques de l\'inverseur',
      'shortTitle': 'Inverseur',
      'icon': Icons.swap_horiz_outlined,
      'color': const Color(0xFFC0392B),
      'champs': [
        'Identification du GE',
        'Marque',
        'Type',
        'N° Serie',
        'Intensite (A)',
        'Reglages',
      ],
      'requiredFields': [''],
      'isList': true,
    },
    {
      'key': 'stabilisateur',
      'title': 'Caractéristiques du stabilisateur',
      'shortTitle': 'Stabilisateur',
      'icon': Icons.tune_outlined,
      'color': const Color(0xFFD35400),
      'champs': [
        'Marque',
        'Type',
        'N° Serie',
        'Annee De Fabrication',
        'Annee D\'Installation',
        'Puissance (Kva)',
        'Intensite (A)',
        'Entree',
        'Sortie',
      ],
      'requiredFields': [''],
      'isList': true,
    },
    {
      'key': 'onduleurs',
      'title': 'Caractéristiques des onduleurs',
      'shortTitle': 'Onduleurs',
      'icon': Icons.battery_charging_full_outlined,
      'color': const Color(0xFF16A085),
      'champs': [
        'Marque',
        'Type',
        'N° Serie',
        'Puissance (Kva)',
        'Intensite (A)',
        'Tension D\'Entree',
        'Tension De Sortie',
        'Observations',
      ],
      'requiredFields': [''],
      'isList': true,
    },
    {
      'key': 'regime_neutre',
      'title': 'Schéma de Liaison à la Terre (SLT) ou Régime de neutre',
      'shortTitle': 'Régime de neutre',
      'icon': Icons.gavel_outlined,
      'color': const Color(0xFF2C3E50),
      'options': ['IT', 'TT', 'TN'],
      'isRadio': true,
    },
    {
      'key': 'eclairage_securite',
      'title': 'Éclairage de sécurité',
      'shortTitle': 'Éclairage sécurité',
      'icon': Icons.emergency_outlined,
      'color': const Color(0xFFF39C12),
      'options': ['Présent', 'Non présent', 'Incomplet'],
      'isRadio': true,
    },
    {
      'key': 'modifications_installations',
      'title': 'Modifications apportées aux installations',
      'shortTitle': 'Modifications',
      'icon': Icons.construction_outlined,
      'color': const Color(0xFF2C3E50),
      'options': ['Oui', 'Non'],
      'isRadio': true,
    },
    {
      'key': 'note_calcul',
      'title': 'Note de calcul des installations électriques',
      'shortTitle': 'Note calcul',
      'icon': Icons.calculate_outlined,
      'color': const Color(0xFF3498DB),
      'options': ['Non transmis', 'Transmis'],
      'isRadio': true,
    },
    {
      'key': 'paratonnerre',
      'title': 'Présence de paratonnerre',
      'shortTitle': 'Paratonnerre',
      'icon': Icons.flash_on_outlined,
      'color': const Color(0xFFF1C40F),
      'fields': [
        'presence_paratonnerre',
        'analyse_risque_foudre',
        'etude_technique_foudre',
      ],
      'isParatonnerre': true,
    },
    {
      'key': 'registre_securite',
      'title': 'Registre de sécurité',
      'shortTitle': 'Registre sécurité',
      'icon': Icons.security_outlined,
      'color': const Color(0xFFE74C3C),
      'options': ['Non transmis', 'Transmis'],
      'isRadio': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentPosition(int position, {String? sectionKey}) async {
    try {
      final keyToSave = sectionKey ??
          (_sections.length > position ? _sections[position]['key'] as String? : null);
      await SequenceProgressService.saveStepData(
        widget.mission.id,
        'description_current_step',
        position,
      );
      if (keyToSave != null) {
        await SequenceProgressService.saveStepData(
          widget.mission.id,
          'description_current_section_key',
          keyToSave,
        );
      }
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  Future<int> _getSavedPosition() async {
    try {
      final saved = await SequenceProgressService.getStepData(
        widget.mission.id,
        'description_current_step',
      );
      return saved ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<String?> _getSavedSectionKey() async {
    try {
      final saved = await SequenceProgressService.getStepData(
        widget.mission.id,
        'description_current_section_key',
      );
      return saved is String ? saved : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);

    try {
      final getDescUseCase = ref.read(getDescriptionInstallationsUseCaseProvider);
      final descEntity = await getDescUseCase(widget.mission.id);
      final progress = descEntity.getProgress();
      final savedPosition = await _getSavedPosition();
      final savedKey = await _getSavedSectionKey();

      int targetStep = -1;

      if (widget.initialSectionIndex != null) {
        targetStep = widget.initialSectionIndex!;
      } else if (savedKey != null) {
        targetStep = _sections.indexWhere((s) => s['key'] == savedKey);
      }

      if (targetStep == -1) {
        if (_isFirstLoad) {
          // Sur les missions existantes qui ont des données renseignées dans les sections aval
          // mais où 'alimentation_site_mt' (index 0) n'a pas encore été renseigné,
          // on privilégie l'ouverture sur la première section ayant déjà du contenu ou la section enregistrée.
          final hasCompletedSubsequent = progress.entries.any(
            (e) => e.key != 'alimentation_site_mt' && e.value == true,
          );

          if (savedPosition > 0 && savedPosition < _sections.length) {
            targetStep = savedPosition;
          } else if (hasCompletedSubsequent && progress['alimentation_site_mt'] != true) {
            // Si des sections suivantes sont complétées, démarrer sur la première section complétée
            targetStep = _sections.indexWhere(
              (s) => progress[s['key']] == true,
            );
            if (targetStep == -1) targetStep = 0;
          } else {
            for (int i = 0; i < _sections.length; i++) {
              final section = _sections[i];
              final key = section['key'] as String;
              if (!progress.containsKey(key) || !progress[key]!) {
                targetStep = i;
                break;
              }
            }
          }
        } else {
          targetStep = savedPosition;
        }
      }

      if (targetStep < 0 || targetStep >= _sections.length) {
        targetStep = 0;
      }

      _isFirstLoad = false;

      if (!mounted) return;

      _pageController = PageController(initialPage: targetStep);

      setState(() {
        _progress = progress;
        _currentStep = targetStep;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        _pageController = PageController(initialPage: 0);
        setState(() => _isLoading = false);
      }
    }
  }

  bool get isFirstSlide => _currentStep == 0;
  bool get isLastSlide => _currentStep == _sections.length - 1;

  void jumpToSection(dynamic sectionKeyOrIndex) {
    int targetIndex = -1;
    if (sectionKeyOrIndex is String) {
      targetIndex = _sections.indexWhere((s) => s['key'] == sectionKeyOrIndex);
    } else if (sectionKeyOrIndex is int) {
      targetIndex = sectionKeyOrIndex;
    }

    if (targetIndex >= 0 && targetIndex < _sections.length) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetIndex);
      }
      setState(() {
        _currentStep = targetIndex;
      });
      _saveCurrentPosition(targetIndex, sectionKey: _sections[targetIndex]['key'] as String?);
    }
  }

  bool next() {
    FocusScope.of(context).unfocus();
    if (_currentStep < _sections.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return true; // Reste sur la description
    } else {
      return false; // Étape terminée, passe à la suite
    }
  }

  bool previous() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return true; // Reste sur la description
    } else {
      return false; // Permet de reculer à l'étape précédente globale
    }
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();

    if (_currentStep < _sections.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onNextStep();
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();

    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onPreviousStep();
    }
  }

  void _onSectionComplete(String sectionKey) async {
    setState(() {
      _progress[sectionKey] = true;
    });

    try {
      final getDescUseCase = ref.read(getDescriptionInstallationsUseCaseProvider);
      final descEntity = await getDescUseCase(widget.mission.id);
      final freshProgress = descEntity.getProgress();
      if (mounted) {
        setState(() {
          _progress = freshProgress;
        });
      }
    } catch (e) {
      // Ignorer
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentSection = _sections[_currentStep];
    final completed = _progress.values.where((v) => v).length;
    final percentage = (_sections.isNotEmpty)
        ? (completed / _sections.length * 100).round()
        : 0;
    final sectionColor = currentSection['color'] as Color;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(isSmallScreen ? 10 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.primaryBlue.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
              boxShadow: [
                BoxShadow(
                  color: sectionColor.withOpacity(0.3),
                  blurRadius: isSmallScreen ? 8 : 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            isSmallScreen ? 12 : 14,
                          ),
                        ),
                        child: Icon(
                          currentSection['icon'] as IconData,
                          color: Colors.white,
                          size: isSmallScreen ? 22 : 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSection['title'] as String,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              'Catégorie ${_currentStep + 1}/${_sections.length}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progression',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 5 : 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _sections.isNotEmpty
                              ? completed / _sections.length
                              : 0,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: isSmallScreen ? 4 : 5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sections.length,
              onPageChanged: (index) {
                if (_currentStep != index) {
                  setState(() => _currentStep = index);
                  _saveCurrentPosition(index);
                  if (widget.onSubStepChanged != null) widget.onSubStepChanged!();
                }
              },
              itemBuilder: (context, index) {
                final section = _sections[index];
                return _buildSectionWidget(
                  section,
                  _progress[section['key']] ?? false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWidget(Map<String, dynamic> section, bool isComplete) {
    if (section['isList'] == true) {
      return DescriptionInstallationsForm(
        key: ValueKey('section_${section['key']}'),
        mission: widget.mission,
        title: section['title'],
        sectionKey: section['key'],
        champs: List<String>.from(section['champs']),
        onComplete: _onSectionComplete,
        isComplete: isComplete,
        onTerminate: _onFormTerminate,
      );
    } else if (section['isRadio'] == true) {
      return RadioSequenceScreen(
        key: ValueKey('section_${section['key']}'),
        mission: widget.mission,
        title: section['title'],
        field: section['key'],
        options: List<String>.from(section['options']),
        onComplete: _onSectionComplete,
        isComplete: isComplete,
      );
    } else if (section['isAlimentationSiteMt'] == true) {
      return AlimentationSiteMtSequenceScreen(
        key: ValueKey('section_${section['key']}'),
        mission: widget.mission,
        onComplete: _onSectionComplete,
        isComplete: isComplete,
      );
    } else if (section['isParatonnerre'] == true) {
      return ParatonnerreSequenceScreen(
        key: ValueKey('section_${section['key']}'),
        mission: widget.mission,
        onComplete: _onSectionComplete,
        isComplete: isComplete,
      );
    }

    return const Center(child: Text('Type de section non supporté'));
  }

  void _onFormTerminate() {
    if (_currentStep < _sections.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
