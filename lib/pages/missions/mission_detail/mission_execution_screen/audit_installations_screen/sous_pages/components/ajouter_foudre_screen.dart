// ajouter_foudre_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/utils/observation_text_normalizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/features/foudre/presentation/providers/foudre_provider.dart';
import 'package:inspec_app/components/normative_search_suggestions_widget.dart';
import 'package:inspec_app/services/normative_search_service.dart';

class AjouterFoudreScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final Foudre? observation;

  const AjouterFoudreScreen({
    super.key,
    required this.mission,
    this.observation,
  });

  bool get isEdition => observation != null;

  @override
  ConsumerState<AjouterFoudreScreen> createState() => _AjouterFoudreScreenState();
}

class _AjouterFoudreScreenState extends ConsumerState<AjouterFoudreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observationController = TextEditingController();
  int _niveauPriorite = 2; // Par défaut priorité moyenne

  String? _selectedRefNormative;
  String? _selectedFamilleRisque;
  String? _selectedCriticite;

  @override
  void initState() {
    super.initState();
    if (widget.isEdition) {
      _observationController.text = widget.observation!.observation;
      _niveauPriorite = widget.observation!.niveauPriorite;
    }
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      try {
        final rawTexte = _observationController.text.trim();
        final observationTexte = ObservationTextNormalizer.normalize(rawTexte) ?? rawTexte;
        
        if (widget.isEdition) {
          // Mise à jour
          final success = await ref.read(foudreObservationsProvider(widget.mission.id).notifier).updateObservation(
            foudreId: widget.observation!.key,
            observation: observationTexte,
            niveauPriorite: _niveauPriorite,
          );
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Observation mise à jour'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else {
            _showError('Erreur lors de la mise à jour');
          }
        } else {
          // Création
          final success = await ref.read(foudreObservationsProvider(widget.mission.id).notifier).addObservation(
            observation: observationTexte,
            niveauPriorite: _niveauPriorite,
          );
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Observation créée'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else {
            _showError('Erreur lors de la création');
          }
        }
      } catch (e) {
        _showError('Erreur: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildPriorityCard(int niveau, String titre, String description, Color couleur) {
    final isSelected = _niveauPriorite == niveau;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? couleur : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _niveauPriorite = niveau;
          });
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: couleur.withOpacity(isSelected ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: couleur,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'P$niveau',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: couleur,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? couleur : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: couleur),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdition ? 'Modifier l\'observation' : 'Nouvelle observation'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _sauvegarder,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ListView(
            children: [
              // Titre section
              Text(
                'OBSERVATION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 1.1,
                ),
              ),
              SizedBox(height: 12),
              
              // Champ observation
              TextFormField(
                controller: _observationController,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Décrivez l\'observation...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir une observation';
                  }
                  if (value.trim().length < 10) {
                    return 'L\'observation doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              NormativeSearchSuggestionsWidget(
                queryText: _observationController.text,
                selectedReferenceNormative: _selectedRefNormative,
                selectedFamilleRisque: _selectedFamilleRisque,
                selectedCriticite: _selectedCriticite,
                onSelect: (res) {
                  setState(() {
                    _selectedRefNormative = res.referenceNormative;
                    _selectedFamilleRisque = res.familleRisque;
                    _selectedCriticite = res.criticite;
                  });
                },
                onUnlink: () {
                  setState(() {
                    _selectedRefNormative = null;
                    _selectedFamilleRisque = null;
                    _selectedCriticite = null;
                  });
                },
              ),
              
              SizedBox(height: 32),
              
              // Titre section priorité
              Text(
                'NIVEAU DE PRIORITÉ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 1.1,
                ),
              ),
              SizedBox(height: 12),
              
              // Cartes de priorité
              _buildPriorityCard(
                1,
                'PRIORITÉ BASSE',
                'Observation à prendre en compte lors des prochains audits',
                Colors.blue,
              ),
              
              _buildPriorityCard(
                2,
                'PRIORITÉ MOYENNE',
                'Observation importante à traiter rapidement',
                Colors.orange,
              ),
              
              _buildPriorityCard(
                3,
                'PRIORITÉ HAUTE',
                'Observation critique nécessitant une attention immédiate',
                Colors.red,
              ),
              
              SizedBox(height: 24),
              
              // Informations sur la date
              if (widget.isEdition) ...[
                Divider(),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Créée le',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _formatDate(widget.observation!.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Dernière modification',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _formatDate(widget.observation!.updatedAt),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              
              
              // Bouton de sauvegarde
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.isEdition ? 'Mettre à jour' : 'Enregistrer l\'observation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }
}