import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_coffret_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class QrScanCoffretScreen extends StatefulWidget {
  final Mission mission;
  final String parentType;
  final int parentIndex;
  final bool isMoyenneTension;
  final int? zoneIndex;
  final bool isInZone;

  const QrScanCoffretScreen({
    super.key,
    required this.mission,
    required this.parentType,
    required this.parentIndex,
    required this.isMoyenneTension,
    this.zoneIndex,
    this.isInZone = false,
  });

  @override
  State<QrScanCoffretScreen> createState() => _QrScanCoffretScreenState();
}

class _QrScanCoffretScreenState extends State<QrScanCoffretScreen> {
  late MobileScannerController cameraController;
  String? _scannedQrCode;
  bool _isProcessing = false;
  bool _qrCodeDetected = false;
  bool _scannerReady = true;
  dynamic _existingCoffret;
  bool _isExistingDraft = false;
  bool _isExistingCompleted = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
    _scannerReady = true; 
  }

  @override
  void dispose() {
    cameraController.stop();
    // Ne pas disposer immédiatement pour éviter les erreurs
    Future.delayed(const Duration(milliseconds: 200), () {
      cameraController.dispose();
    });
    super.dispose();
  }

  void _onQrCodeDetect(BarcodeCapture barcodeCapture) {
    if (_isProcessing || _qrCodeDetected) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final Barcode barcode = barcodes.first;
      final String? qrCode = barcode.rawValue;
      
      if (qrCode != null && qrCode.isNotEmpty && qrCode != _scannedQrCode) {
        setState(() {
          _isProcessing = true;
        });

        cameraController.stop();
        
        Future.delayed(const Duration(milliseconds: 100), () {
          _processQrCodeDetection(qrCode);
        });
      }
    }
  }

  Future<void> _processQrCodeDetection(String qrCode) async {
    try {
      final draft = HiveService.getCoffretDraftByQrCode(qrCode);
      final completedCoffret = HiveService.findCoffretByQrCode(
        widget.mission.id,
        qrCode,
      );
      
      if (draft != null && draft.statut == 'incomplet') {
        setState(() {
          _existingCoffret = draft;
          _isExistingDraft = true;
          _isExistingCompleted = false;
          _isProcessing = false;
          _qrCodeDetected = true;
          _scannedQrCode = qrCode;
        });
        return;
      }
      
      if (completedCoffret != null) {
        setState(() {
          _existingCoffret = completedCoffret;
          _isExistingDraft = false;
          _isExistingCompleted = true;
          _isProcessing = false;
          _qrCodeDetected = true;
          _scannedQrCode = qrCode;
        });
        return;
      }
      
      setState(() {
        _existingCoffret = null;
        _isExistingDraft = false;
        _isExistingCompleted = false;
        _isProcessing = false;
        _qrCodeDetected = true;
        _scannedQrCode = qrCode;
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur processQrCodeDetection: $e');
      }
      _showError('Erreur lors du traitement du QR code');
      _resetScanner();
    }
  }

  Future<void> _continuerAvecQrCode() async {
    if (_scannedQrCode == null) return;

    if (_isExistingDraft && _existingCoffret != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AjouterCoffretScreen(
            mission: widget.mission,
            parentType: widget.parentType,
            parentIndex: widget.parentIndex,
            isMoyenneTension: widget.isMoyenneTension,
            zoneIndex: widget.zoneIndex,
            coffret: null,
            isInZone: widget.isInZone,
            qrCode: _scannedQrCode,
          ),
        ),
      ).then((value) {
        if (!mounted) return;
        if (value == true || value is CoffretArmoire) {
          Navigator.pop(context, true);
        } else {
          _resetScanner();
        }
      });
      return;
    }
    
    if (_isExistingCompleted && _existingCoffret != null) {
      // Proposer de charger les données dans le nouvel emplacement
      await _proposerChargementEquipementExistant(_existingCoffret!);
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterCoffretScreen(
          mission: widget.mission,
          parentType: widget.parentType,
          parentIndex: widget.parentIndex,
          isMoyenneTension: widget.isMoyenneTension,
          zoneIndex: widget.zoneIndex,
          coffret: null,
          isInZone: widget.isInZone,
          qrCode: _scannedQrCode,
        ),
      ),
    ).then((value) {
      if (!mounted) return;
      if (value == true || value is CoffretArmoire) {
        Navigator.pop(context, true);
      } else {
        _resetScanner();
      }
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('SCANNER AUTRE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Quand un QR déjà finalisé est scanné dans un nouveau local/zone,
  /// on propose à l'utilisateur de charger ses données pour les sauvegarder
  /// dans le nouvel emplacement (copie des informations vers le nouveau parent).
  Future<void> _proposerChargementEquipementExistant(
      CoffretArmoire existing) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 26),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Équipement existant',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L\'équipement "${existing.nom}" a déjà été inspecté.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'Voulez-vous charger ses données dans ce nouvel emplacement ? '
                'Toutes les informations seront pré-remplies.',
                style: TextStyle(fontSize: 13, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              _resetScanner();
            },
            child: const Text('Scanner autre QR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Charger les données',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      // Cloner l'équipement pour le nouvel emplacement :
      // - Nouvel ID technique unique
      // - QR code scanné
      // - Photos purgées (externes, internes, points) pour éliminer toute contamination inter-zones
      final clonedForNewLocation = CoffretArmoire(
        id: 'equip_${DateTime.now().microsecondsSinceEpoch}',
        qrCode: _scannedQrCode ?? '',
        nom: existing.nom,
        type: existing.type,
        accessible: existing.accessible,
        departPrisAvecProtection: existing.departPrisAvecProtection,
        repere: existing.repere,
        domaineTension: existing.domaineTension,
        alimenteeParTransformateur: existing.alimenteeParTransformateur,
        transformateurId: existing.transformateurId,
        transformateurNomComplet: existing.transformateurNomComplet,
        presenceCPI: existing.presenceCPI,
        zoneAtex: existing.zoneAtex,
        indiceIpIk: existing.indiceIpIk,
        indiceIpIkRepere: existing.indiceIpIkRepere,
        sourceEquipementId: existing.sourceEquipementId,
        sourceNomComplet: existing.sourceNomComplet,
        sourceDepartId: existing.sourceDepartId,
        alimentations: List.from(existing.alimentations),
        protectionTete: existing.protectionTete,
        departures: List.from(existing.effectiveDepartures.map((d) => d.copyWith(id: 'dep_${DateTime.now().microsecondsSinceEpoch}_${d.identification}'))),
        terminalCircuits: List.from(existing.effectiveTerminalCircuits.map((c) => c.copyWith(id: 'ct_${DateTime.now().microsecondsSinceEpoch}_${c.identification}'))),
        pointsVerification: List.from(existing.pointsVerification.map((pv) => PointVerification(
          pointVerification: pv.pointVerification,
          conformite: pv.conformite,
          observation: pv.observation,
          referenceNormative: pv.referenceNormative,
          priorite: pv.priorite,
          photos: [],
          observations: pv.observations != null
              ? List.from(pv.observations!.map((e) => ElementControle(
                    elementControle: e.elementControle,
                    conforme: e.conforme,
                    observation: e.observation,
                    priorite: e.priorite,
                    photos: [],
                    referenceNormative: e.referenceNormative,
                    estNA: e.estNA,
                  )))
              : null,
        ))),
        photos: [],
        photosExternes: [],
        photosInternes: [],
        observationsLibres: List.from(existing.observationsLibres.map((o) => ObservationLibre(
          texte: o.texte,
          photos: [],
          pointVerificationKey: o.pointVerificationKey,
          referenceNormative: o.referenceNormative,
          familleRisque: o.familleRisque,
          criticite: o.criticite,
        ))),
        observationsParafoudreEnrichies: List.from((existing.observationsParafoudreEnrichies ?? []).map((o) => ElementControle(
          elementControle: o.elementControle,
          conforme: o.conforme,
          observation: o.observation,
          priorite: o.priorite,
          photos: [],
        ))),
        statut: 'incomplet',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AjouterCoffretScreen(
            mission: widget.mission,
            parentType: widget.parentType,
            parentIndex: widget.parentIndex,
            isMoyenneTension: widget.isMoyenneTension,
            zoneIndex: widget.zoneIndex,
            isInZone: widget.isInZone,
            qrCode: _scannedQrCode,
            coffret: clonedForNewLocation,
            coffretIndex: null,
            isCloning: true,
          ),
        ),
      ).then((value) {
        if (!mounted) return;
        if (value == true || value is CoffretArmoire) {
          Navigator.pop(context, true);
        } else {
          _resetScanner();
        }
      });
    }
  }

  void _resetScanner() {
    setState(() {
      _scannedQrCode = null;
      _qrCodeDetected = false;
      _existingCoffret = null;
      _isExistingDraft = false;
      _isExistingCompleted = false;
      _isProcessing = false;
      _scannerReady = false;
    });
    
    _reinitializeScanner();
  }

  void _reinitializeScanner() async {

    setState(() {
      _scannerReady = false;
    });

    try {
      await cameraController.stop();
      await cameraController.dispose();
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      cameraController = MobileScannerController();

      await Future.delayed(const Duration(milliseconds: 100));

      await cameraController.start();
      
      if (mounted) {
        setState(() {
          _scannerReady = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur réinitialisation scanner: $e');
      }
      cameraController = MobileScannerController();
      if (mounted) {
        setState(() {
          _scannerReady = true;
        });
      }
    }
  }

  void _enterQrCodeManually() {
    if (!kDebugMode) return;
    final TextEditingController manualController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisir le QR code manuellement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: manualController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Entrez le code QR',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _processQrCodeManuel(value);
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Le QR code doit être unique pour chaque coffret',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final value = manualController.text;
              if (value.isNotEmpty) {
                Navigator.pop(context);
                _processQrCodeManuel(value);
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _processQrCodeManuel(String qrCode) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final draft = HiveService.getCoffretDraftByQrCode(qrCode);
      final completedCoffret = HiveService.findCoffretByQrCode(
        widget.mission.id,
        qrCode,
      );
      
      if (draft != null && draft.statut == 'incomplet') {
        setState(() {
          _existingCoffret = draft;
          _isExistingDraft = true;
          _isExistingCompleted = false;
          _isProcessing = false;
          _qrCodeDetected = true;
          _scannedQrCode = qrCode;
        });
        return;
      }
      
      if (completedCoffret != null) {
        setState(() {
          _existingCoffret = completedCoffret;
          _isExistingDraft = false;
          _isExistingCompleted = true;
          _isProcessing = false;
          _qrCodeDetected = true;
          _scannedQrCode = qrCode;
        });
        return;
      }
      
      setState(() {
        _existingCoffret = null;
        _isExistingDraft = false;
        _isExistingCompleted = false;
        _isProcessing = false;
        _qrCodeDetected = true;
        _scannedQrCode = qrCode;
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur processQrCodeManuel: $e');
      }
      _showError('Erreur: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _toggleTorch() {
    cameraController.toggleTorch();
  }

  void _switchCamera() {
    cameraController.switchCamera();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: _qrCodeDetected ? Colors.green : Colors.blue,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
                top: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
                top: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
                bottom: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
                bottom: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodeDetectedPanel() {
    final isDraft = _isExistingDraft;
    final isCompleted = _isExistingCompleted;
    final isNew = !isDraft && !isCompleted;
    
    String title;
    String subtitle;
    IconData icon;
    Color color;
    
    if (isDraft) {
      title = 'BROUILLON DÉTECTÉ';
      subtitle = 'Ce QR code correspond à un équipement non finalisé.\nVous pouvez poursuivre la saisie.';
      icon = Icons.drafts_outlined;
      color = Colors.orange;
    } else if (isCompleted) {
      title = 'ÉQUIPEMENT FINALISÉ';
      subtitle = 'Cet équipement a déjà été complété et ne peut plus être modifié.\nVeuillez scanner un autre QR code.';
      icon = Icons.check_circle;
      color = Colors.red;
    } else {
      title = 'NOUVEAU QR CODE';
      subtitle = 'Ce QR code n\'est pas encore utilisé.\nVous pouvez créer un nouvel équipement.';
      icon = Icons.qr_code_scanner;
      color = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 64),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _scannedQrCode!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetScanner,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scanner autre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isCompleted ? null : _continuerAvecQrCode,
                  icon: Icon(isNew ? Icons.add : Icons.edit),
                  label: Text(isNew ? 'Créer' : (isDraft ? 'Continuer' : 'Impossible')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? Colors.grey.shade600 : (isDraft ? Colors.orange : AppTheme.primaryBlue),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerInstructions() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Scannez le QR code du coffret',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Placez le code QR dans le cadre ci-dessus',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _toggleTorch,
            tooltip: 'Torche',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
            tooltip: 'Changer caméra',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_qrCodeDetected && _scannerReady)
            MobileScanner(
              controller: cameraController,
              onDetect: _onQrCodeDetect,
              fit: BoxFit.cover,
            )
          else if (!_qrCodeDetected && !_scannerReady)
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initialisation du scanner...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          _buildScannerOverlay(),
          if (!_qrCodeDetected && !_isProcessing && _scannerReady)
            _buildScannerInstructions(),
          if (_isProcessing)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Traitement du QR code...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          if (_qrCodeDetected && _scannedQrCode != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildQrCodeDetectedPanel(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: (!_qrCodeDetected && kDebugMode)
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _enterQrCodeManually,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Saisir manuellement (Debug)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}