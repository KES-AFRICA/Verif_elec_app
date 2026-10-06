import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/features/description_installations/presentation/providers/description_installations_provider.dart';

import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/radio_selection_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/installation_detail.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/paratonnerre_screen.dart';

class DescriptionInstallationsScreen extends ConsumerStatefulWidget {
  final Mission mission;

  const DescriptionInstallationsScreen({
    super.key,
    required this.mission,
  });

  @override
  ConsumerState<DescriptionInstallationsScreen> createState() => _DescriptionInstallationsScreenState();
}

class _DescriptionInstallationsScreenState extends ConsumerState<DescriptionInstallationsScreen> {
  // Map pour stocker l'état de remplissage de chaque section
  Map<String, bool> _sectionStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAllSectionsStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-vérifier l'état quand on revient sur cette page
    _checkAllSectionsStatus();
  }

  Future<void> _checkAllSectionsStatus() async {
    setState(() => _isLoading = true);
    
    try {
      // Récupérer la description via le provider
      ref.invalidate(descriptionInstallationsProvider(widget.mission.id));
      final desc = await ref.read(descriptionInstallationsProvider(widget.mission.id).notifier).load();

      final sectionsWithCards = [
        'alimentation_moyenne_tension',
        'alimentation_basse_tension',
        'groupe_electrogene',
        'alimentation_carburant',
        'inverseur',
        'stabilisateur',
        'onduleurs',
      ];
      
      final tempStatus = <String, bool>{};
      tempStatus['alimentation_site_mt'] = desc.isSectionComplete('alimentation_site_mt');
      for (var section in sectionsWithCards) {
        tempStatus[section] = desc.isSectionComplete(section);
      }
      
      // 2. Vérifier les sélections radio
      tempStatus['regime_neutre'] = desc.regimeNeutre != null && desc.regimeNeutre!.isNotEmpty;
      tempStatus['eclairage_securite'] = desc.eclairageSecurite != null && desc.eclairageSecurite!.isNotEmpty;
      tempStatus['modifications_installations'] = desc.modificationsInstallations != null && desc.modificationsInstallations!.isNotEmpty;
      tempStatus['note_calcul'] = desc.noteCalcul != null && desc.noteCalcul!.isNotEmpty;
      tempStatus['registre_securite'] = desc.registreSecurite != null && desc.registreSecurite!.isNotEmpty;
      
      // 3. Vérifier la section paratonnerre
      tempStatus['paratonnerre'] = (desc.presenceParatonnerre != null && desc.presenceParatonnerre!.isNotEmpty) ||
                                   (desc.analyseRisqueFoudre != null && desc.analyseRisqueFoudre!.isNotEmpty) ||
                                   (desc.etudeTechniqueFoudre != null && desc.etudeTechniqueFoudre!.isNotEmpty);
      
      setState(() {
        _sectionStatus = tempStatus;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur vérification sections: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDetail(BuildContext context, String title, String sectionKey, List<String> champs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstallationDetailScreen(
          mission: widget.mission,
          title: title,
          sectionKey: sectionKey,
          champs: champs,
        ),
      ),
    ).then((_) => _checkAllSectionsStatus()); // Re-vérifier au retour
  }

  void _navigateToRadioSelection(BuildContext context, String title, String field, List<String> options) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RadioSelectionScreen(
          mission: widget.mission,
          title: title,
          field: field,
          options: options,
        ),
      ),
    ).then((_) => _checkAllSectionsStatus()); // Re-vérifier au retour
  }

  void _navigateToParatonnerre(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParatonnerreScreen(mission: widget.mission),
      ),
    ).then((_) => _checkAllSectionsStatus()); // Re-vérifier au retour
  }

  bool _isSectionNotEmpty(String sectionKey) {
    return _sectionStatus[sectionKey] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          children: [
            _buildListTile(
              context,
              'Caractéristiques de l\'alimentation moyenne tension',
              Icons.bolt_outlined,
              'alimentation_moyenne_tension',
              ['TYPE DE CELLULE', 'TENSION ASSIGNEE(KV)', 'POUVOIR DE COUPURE ASSIGNE(KA)', 'SECTION DU CABLE(mm2)', 'NATURE DU RESEAU', 'OBSERVATIONS'],
            ),
            
            _buildListTile(
              context,
              'Caractéristiques de l\'alimentation basse tension sortie transformateur',
              Icons.bolt_outlined,
              'alimentation_basse_tension',
              ['PUISSANCE TRANSFORMATEUR (KVA)', 'TYPE DE TRANSFORMATEUR', 'INTENSITE NOMINALE', 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', 'SECTION DU CABLE', 'TENSION PRIMAIRE/SECONDAIRE', 'COUPLAGE', 'PCC AMONT EN MVA', 'UCC EN %', 'IK3 MAX(KA)', 'OBSERVATIONS'],
            ),
            
            _buildListTile(
              context,
              'Caractéristiques du groupe électrogène',
              Icons.electrical_services_outlined,
              'groupe_electrogene',
              ['IDENTIFICATION', 'MARQUE', 'TYPE', 'N° SERIE', 'PUISSANCE (KVA)', 'INTENSITE', 'ANNEE DE FABRICATION', 'CALIBRE DU DISJONCTEUR', 'SECTION DU CABLE'],
            ),
            
            _buildListTile(
              context,
              'Alimentation du groupe électrogène en carburant',
              Icons.local_gas_station_outlined,
              'alimentation_carburant',
              ['IDENTIFICATION DU GE', 'MODE', 'CAPACITE', 'CUVE DE RETENTION', 'INDICATEUR DE NIVEAU', 'MISE A LA TERRE', 'ANNEE DE FABRICATION'],
            ),
            
            _buildListTile(
              context,
              'Caractéristiques de l\'inverseur',
              Icons.swap_horiz_outlined,
              'inverseur',
              ['IDENTIFICATION DU GE', 'MARQUE', 'TYPE', 'N° SERIE', 'INTENSITE (A)', 'REGLAGES'],
            ),
            
            _buildListTile(
              context,
              'Caractéristiques du stabilisateur',
              Icons.tune_outlined,
              'stabilisateur',
              ['MARQUE', 'TYPE', 'N° SERIE', 'ANNEE DE FABRICATION', 'ANNEE D\'INSTALLATION', 'PUISSANCE (KVA)', 'INTENSITE (A)', 'ENTREE', 'SORTIE'],
            ),
            
            _buildListTile(
              context,
              'Caractéristiques des onduleurs',
              Icons.power_outlined,
              'onduleurs',
              ['MARQUE', 'TYPE', 'N° SERIE', 'PUISSANCE (KVA)', 'INTENSITE (A)', 'NOMBRE DE PHASE'],
            ),

            _buildRadioTile(
              context,
              'Régime de neutre',
              Icons.settings_input_component_outlined,
              'regime_neutre',
              ['IT', 'TT', 'TN'],
            ),
            
            _buildRadioTile(
              context,
              'Eclairage de sécurité',
              Icons.emergency_outlined,
              'eclairage_securite',
              ['Présent', 'Non présent', 'Incomplèt'],
            ),
            
            _buildRadioTile(
              context,
              'Modifications apportées aux installations',
              Icons.construction_outlined,
              'modifications_installations',
              ['Oui', 'Non'],
            ),
            
            _buildRadioTile(
              context,
              'Note de calcul des installations électriques',
              Icons.calculate_outlined,
              'note_calcul',
              ['Non transmis', 'Transmis'],
            ),
            
            _buildRadioTile(
              context,
              'Registre de sécurité',
              Icons.security_outlined,
              'registre_securite',
              ['Absent', 'Présent'],
            ),

            _buildSimpleTile(
              context,
              'Protection des installations contre la foudre',
              Icons.flash_on_outlined,
              _navigateToParatonnerre,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, String title, IconData icon, String sectionKey, List<String> champs) {
    final isNotEmpty = _isSectionNotEmpty(sectionKey);
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isNotEmpty ? Colors.green.shade50 : null,
            border: isNotEmpty
                ? Border(
                    left: BorderSide(color: Colors.green, width: 4),
                  )
                : null,
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: isNotEmpty ? Colors.green : AppTheme.primaryBlue,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isNotEmpty ? Colors.green.shade800 : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNotEmpty)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: isNotEmpty ? Colors.green.shade400 : Colors.grey.shade500,
                ),
              ],
            ),
            onTap: () => _navigateToDetail(context, title, sectionKey, champs),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade300),
      ],
    );
  }

  Widget _buildRadioTile(BuildContext context, String title, IconData icon, String field, List<String> options) {
    final isNotEmpty = _isSectionNotEmpty(field);
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isNotEmpty ? Colors.green.shade50 : null,
            border: isNotEmpty
                ? Border(
                    left: BorderSide(color: Colors.green, width: 4),
                  )
                : null,
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: isNotEmpty ? Colors.green : AppTheme.primaryBlue,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isNotEmpty ? Colors.green.shade800 : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNotEmpty)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: isNotEmpty ? Colors.green.shade400 : Colors.grey.shade500,
                ),
              ],
            ),
            onTap: () => _navigateToRadioSelection(context, title, field, options),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade300),
      ],
    );
  }

  Widget _buildSimpleTile(BuildContext context, String title, IconData icon, Function onTap) {
    final isNotEmpty = _isSectionNotEmpty('paratonnerre');
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isNotEmpty ? Colors.green.shade50 : null,
            border: isNotEmpty
                ? Border(
                    left: BorderSide(color: Colors.green, width: 4),
                  )
                : null,
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: isNotEmpty ? Colors.green : AppTheme.primaryBlue,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isNotEmpty ? Colors.green.shade800 : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNotEmpty)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: isNotEmpty ? Colors.green.shade400 : Colors.grey.shade500,
                ),
              ],
            ),
            onTap: () => onTap(context),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade300),
      ],
    );
  }
}