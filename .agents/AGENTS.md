# AGENTS.md — Référentiel Opérationnel et Mémoire Vivante du Projet

> **Projet** : KES Inspection App (`inspec_app`)  
> **Organisation** : Kamer Engineering Solutions (KES Inspections & Projects)  
> **Type d'application** : Application mobile & tablette Flutter (Offline-First) d'audit technique, inspection réglementaire des installations électriques, foudre, éclairage et génération de rapports d'ingénierie certifiés.  
> **Dernière révision** : 27 Septembre 2026  
> **Rôle du document** : Mémoire opérationnelle vivante, constitution technique et guide d'action pour tout agent ou ingénieur intervenant sur la base de code.

---

## Sommaire

1. [Project Identity](#1-project-identity)
2. [Project Vision](#2-project-vision)
3. [Core Principles](#3-core-principles)
4. [Developer Preferences](#4-developer-preferences)
5. [Architecture](#5-architecture)
6. [Technology Stack](#6-technology-stack)
7. [Repository Structure](#7-repository-structure)
8. [Domain Model & Entities](#8-domain-model--entities)
9. [Business Rules](#9-business-rules)
10. [Data & Persistence (Hive)](#10-data--persistence-hive)
11. [Migration & Backward Compatibility](#11-migration--backward-compatibility)
12. [State Management (Riverpod)](#12-state-management-riverpod)
13. [Performance & Resource Management](#13-performance--resource-management)
14. [Security & Sensitive Data](#14-security--sensitive-data)
15. [Testing & Quality Assurance](#15-testing--quality-assurance)
16. [UI/UX Design System & Ergonomics](#16-uiux-design-system--ergonomics)
17. [Flutter & Dart Standards](#17-flutter--dart-standards)
18. [Electrical Engineering Domain & Norms](#18-electrical-engineering-domain--norms)
19. [Reporting & Document Generation (PDF V3, Excel, Word)](#19-reporting--document-generation-pdf-v3-excel-word)
20. [Import, Export & Backup System (V2)](#20-import-export--backup-system-v2)
21. [Known Issues & Forensic Gotchas](#21-known-issues--forensic-gotchas)
22. [Technical Debt](#22-technical-debt)
23. [Architectural Decisions Records (ADR)](#23-architectural-decisions-records-adr)
24. [Lessons Learned & Anti-Patterns](#24-lessons-learned--anti-patterns)
25. [Deprecated Decisions & Obsolete Practices](#25-deprecated-decisions--obsolete-practices)
26. [Current Priorities](#26-current-priorities)
27. [Workflow Rules & Agent Protocol](#27-workflow-rules--agent-protocol)
28. [Quality Gates & Verification Checklist](#28-quality-gates--verification-checklist)

---

## 1. Project Identity

- **Nom du projet** : `inspec_app` (affiché : *Inspection App (KES)*).
- **Entreprise** : Kamer Engineering Solutions (KES Inspections & Projects).
- **Public cible** : Inspecteurs et ingénieurs électrotechniciens intervenant sur sites industriels, tertiaires et d'infrastructures lourdes (usines, postes MT/BT, cimenteries, sites ferroviaires, brasseries, etc.).
- **Périmètre applicatif** :
  - Relevé exhaustif des installations Moyenne Tension (HTA) et Basse Tension (BT).
  - Contrôle réglementaire et normatif (NF C 15-100, NF C 13-100, NF C 13-200, NF C 17-102, NF C 18-510, APSAD D18).
  - Mesures physiques et essais (prises de terre, continuités PE, isolement sous 500V/1000V, seuils DDR, tests différentiels, arrêt d'urgence, démarrage GE, contrôleurs d'isolement CPI).
  - Évaluation des risques foudre et contrôle des installations de protection (paratonnerres, parafoudres).
  - Audit d'éclairage et sécurité des personnes (JSA - Job Safety Analysis).
  - Analyse statistique déterministe, classification Pareto et appréciation synthétique globale du risque d'exploitation.
  - Génération autonome sur site de livrables professionnels (Rapports PDF paginés de 50 à 150+ pages, classeurs Excel de données brutes, documents Word, et Rapport thermographique Q18 APSAD D18).

---

## 2. Project Vision

L'application vise l'autonomie opérationnelle complète de l'inspecteur en milieu hostile ou déconnecté :
1. **Zéro dépendance réseau sur le terrain** : Saisie, persistance, analyse statistique et édition de rapports certifiés doivent fonctionner à 100 % hors-ligne sur terminaux durcis (ex. Ulefone Armor X16).
2. **Qualité agence et rigueur légale des livrables** : Le rapport PDF n'est pas un export sommaire mais un document contractuel à valeur probante (mise en page soignée, pagination absolue, tableaux unifiés sans orphelins, métadonnées complètes, références normatives exactes).
3. **Assistance intelligente résiliente** : Intégration de modèles d'IA (Gemini / Groq) pour la synthèse narrative du rapport, avec bascule transparente et immédiate sur des moteurs déterministes locaux en mode hors-ligne.
4. **Intégrité absolue des données de mission** : Aucune donnée saisie ne doit jamais être perdue ou corrompue par une mise à jour d'écran, une synchronisation d'arrière-plan ou une migration de schéma.

---

## 3. Core Principles

- **Zero Data Loss** : Toute modification de modèle ou de stockage doit préserver les données existantes.
- **Offline-First & Local Authority** : Hive est la source de vérité locale synchrone et rapide.
- **Surgical Changes** : Privilégier les modifications ciblées (diffs chirurgicaux) plutôt que la réécriture de fichiers entiers.
- **Deterministic Analytics** : Les statistiques, classifications et calculs normatifs reposent sur des moteurs déterministes testables et non sur des heuristiques imprévisibles.
- **Never Lie, Never Guess** : Ne jamais inventer une référence normative, une valeur de mesure ou un état d'équipement. Si une information est absente, la qualifier explicitement comme telle (`Inconnu`, `Non renseigné`, `Sans objet`).
- **Separation of Concerns** : Séparation stricte entre Présentation, Logique métier, Accès aux données et Génération documentaire.

---

## 4. Developer Preferences

### Règles Absolues Git & Commits
1. **Langue des commits** : Rédiger impérativement les messages de commit en **français**.
2. **Pré-syntaxe obligatoire** :
   - `[CREATE]` : Ajout d'un nouveau fichier, fonctionnalité, moteur ou suite de tests.
   - `[UPD]` : Modification, refactorisation, correction de bug ou mise à jour d'un existant.
   - `[DLT]` : Suppression d'un fichier, composant ou code mort.
3. **Interdiction d'auto-commit** : **Ne jamais exécuter `git commit` automatiquement**. Quand un commit est prêt ou demandé, fournir exclusivement le texte du message de commit au format Markdown afin que le développeur le valide et l'exécute lui-même.

### Style de Code et Rigueur
- **Code technique en anglais** : Noms de classes, variables, méthodes, fichiers et commentaires techniques internes en anglais.
- **Textes utilisateur en français** : Libellés d'interface, messages d'erreurs, descriptions normatives et contenu des rapports PDF/Excel/Word en français irréprochable (avec accents et typographie soignée).
- **Typage fort & Null-Safety stricte** : Aucun opérateur `!` non justifié formellement. `late` réservé aux cycles de vie Flutter garantis (`initState`).
- **Analyse avant de coder** : Examiner systématiquement les dépendances, la chaîne d'appels et les tests existants avant toute modification.

---

## 5. Architecture

Le projet suit une **Clean Architecture modulaire orientée fonctionnalités (Feature-First)**, soutenue par un système de plugins et de moteurs de calcul spécialisés :

```text
lib/
├── core/                       # Briques transversales, DI (GetIt), observateurs
│   └── di/injection_container.dart
├── constants/                  # Constantes applicatives, thèmes globaux
│   └── app_theme.dart
├── config/                     # Configuration des secrets (api_keys.dart)
├── models/                     # Modèles Hive persistants (Data Layer legacy & partagé)
├── features/                   # Modules fonctionnels découpés en Clean Architecture
│   ├── auth/                   # Authentification, gestion de session vérificateurs
│   ├── mission/                # Cycle de vie des missions, création, sélection
│   ├── audit_installations/    # MT, BT, locaux, cellules, transformateurs, coffrets
│   ├── description_installations/ # Description générale du site, régimes de neutre
│   ├── mesures_essais/         # Prises de terre, continuités, isolement, DDR, CPI
│   ├── foudre/                 # Protection foudre, paratonnerres, parafoudres
│   ├── jsa/                    # Job Safety Analysis & sécurité des intervenants
│   └── backup/                 # File d'attente, synchronisation cloud, export/import
├── pages/                      # Écrans de navigation et formulaires de saisie de terrain
├── services/                   # Services métier transversaux
│   ├── hive_service.dart       # Initialisation des boîtes et adaptateurs Hive
│   ├── equipment_number_service.dart # Numérotation continue et immuable des coffrets
│   ├── equipment_source_search_service.dart # Résolution et similarité des sources
│   ├── installation_description_sync_service.dart # Synchronisation Audit -> Description
│   ├── normative_reference_service.dart # Registre des 496+ points normatifs
│   ├── trash_service.dart      # Corbeille sécurisée avec rétention 90 jours
│   ├── ai/                     # Intégration IA (Gemini/Groq) & cache des synthèses
│   ├── statistics/             # 16 Moteurs statistiques et analytiques déterministes
│   ├── pdf/                    # Moteurs de génération PDF V3 par micro-lots
│   │   ├── pdf_report_service.dart # Rapport Vérification Électrique (13 builders)
│   │   ├── q18/pdf_q18_report_service.dart # Rapport Thermographique Q18 APSAD D18 (7 builders)
│   │   ├── pdf_report_context.dart # Contexte immuable partagé (assets, fonts, data)
│   │   ├── pdf_report_styles.dart  # Charte graphique, palettes, métriques de table
│   │   └── builders/               # 13 constructeurs spécialisés par section
│   ├── excel/                  # Génération classeurs Excel (Syncfusion XlsIO)
│   └── word_report_service.dart# Génération de rapports Word
└── utils/                      # Compression d'images, normalisation de chaînes
```

---

## 6. Technology Stack

- **Framework** : Flutter (Canal stable, SDK Dart `^3.9.2`).
- **Persistance locale** : Hive `^2.2.3` & `hive_flutter ^1.1.0` (NoSQL binaire léger).
- **Génération d'adaptateurs** : `build_runner ^2.4.13` & `hive_generator ^2.0.1`.
- **Gestion d'état** : Flutter Riverpod `^2.5.1` (`StateNotifier`, `AsyncValue`, `ProviderScope`).
- **Injection de dépendances** : `get_it ^8.0.3`.
- **Moteur PDF** : `pdf ^3.11.3`, `printing ^5.14.3`, `pdf_merger ^0.0.6`, `syncfusion_flutter_pdf ^33.2.13`.
- **Moteur Excel** : `syncfusion_flutter_xlsio ^33.2.13`.
- **Sécurité & Cryptographie** : `flutter_secure_storage ^9.2.4`, `crypto ^3.0.7`, `bcrypt ^1.2.0`.
- **Gestion fichiers & médias** : `path_provider ^2.1.5`, `archive ^4.0.9`, `flutter_image_compress ^2.4.0`, `gal ^2.3.3`.
- **Intégration Matérielle & Scanning** : `mobile_scanner ^7.1.3`.
- **Background Tasks & Sync** : `workmanager ^0.6.0`, `connectivity_plus ^7.1.1`.
- **IA Générative** : Google Gemini API (`gemini-1.5-flash` / `pro`), Groq API (`llama-3.3-70b`).

---

## 7. Repository Structure

- `lib/` : Code source Dart de l'application.
- `assets/` :
  - `assets/icon/` : Logos et icônes applicatives.
  - `assets/images/` : Logos KES, tampons officiels, illustrations par défaut.
  - `assets/fonts/` : Polices TrueType (`Roboto-Regular.ttf`, `Roboto-Bold.ttf`) supportant la totalité des glyphes Unicode et caractères accentués français.
- `test/` :
  - `test/features/` : 130+ suites de tests unitaires et fonctionnels couvrant les règles métier, la synchronisation, les calculs de criticité et le rendu PDF.
  - `test/services/` : Tests des services transversaux (Excel, Word, Backup, Moteurs IA, Q18).
- `docs/superpowers/` : Spécifications techniques détaillées (`specs/`) et plans d'implémentation validés (`plans/`).
- `docs/project-memory/` : Référentiel des 8 piliers documentaires exhaustifs du projet.
- `graphify-out/` : Graphe de connaissances et dépendances architecturales du projet.

---

## 8. Domain Model & Entities

### Hiérarchie Métier Principale

```text
Mission (lib/models/mission.dart)
├── Métadonnées administratives (Client, Site, Lieu, Adresse, Dates)
├── Récepteur du rapport unifié (recepteurCivilite, recepteurNom, recepteurFonction, recepteurEmail, recepteurTelephone, recepteurRapport)
├── Classement Réglementaire hiérarchique (Installations classées, IGH, ERP Généraux, ERP Spécialisés)
├── Options documentaires & Rapports (docRapportQ18, qrCodeClient, qrCodeQ18)
├── Centrale photovoltaïque (sans_objet, sans_stockage, avec_stockage)
│
├── RenseignementsGénéraux (Client, Site, Dates, Inspecteurs, Habilitation Électrique)
├── DescriptionInstallations (Postes MT, Transfos, TGBT, Régimes de Neutre, Sources Secours)
├── AuditInstallationsElectriques
│   ├── MoyenneTensionLocaux [] -> Transformateurs [], Cellules MT [], Coffrets []
│   ├── MoyenneTensionZones []  -> Locaux [], Coffrets [], Points de contrôle
│   └── BasseTensionZones []    -> CoffretsDirects [], Locaux [] -> Coffrets []
│       └── CoffretArmoire
│           ├── Métadonnées (ID stable, numéro d'équipement N°, nom, repère, localisation)
│           ├── Caractéristiques (Source d'alimentation, protection amont, DDR, courbe disjoncteur)
│           ├── Départs (Départs terminaux, calibres, sections, répartiteurs)
│           └── Points de vérification (Constats, non-conformités, photos, références normatives)
├── ClassementEmplacement & ClassementZone (Locaux à risques d'incendie, BE2, atmosphères explosives)
├── Foudre (Paratonnerres, parafoudres, liaisons d'équipotentialité, conducteurs de descente)
├── MesuresEssais
│   ├── PrisesTerre (Valeurs en Ohms, barrettes de mesure, conformité seuil <= 100 Ohms)
│   ├── ContinuitéRésistance (Liaisons équipotentielles masses/PE <= 2 Ohms)
│   ├── EssaisIsolement (Points de mesure A/B, phase/neutre/terre >= 0.5 MOhm)
│   ├── EssaisDéclenchementDifférentiel (Sensibilité mA, temps de coupure ms)
│   ├── CpiTests (Contrôleurs permanents d'isolement en régime IT)
│   ├── TestsArrêtUrgence (Fonctionnement réel ou absence d'organe d'urgence)
│   └── EssaisDémarrageAuto (Groupes électrogènes, temps de prise en charge)
└── JSA (Job Safety Analysis : risques d'intervention, EPI requis, mesures de sécurité)
```

---

## 9. Business Rules

### 9.1 Régime de Neutre (Sous-section 9 de la Description)
- **4 Types normalisés** : `TT`, `TN-C`, `TN-S`, `IT`.
- **Règle séquentielle d'automatisation** : Pour chaque type de régime de neutre, vérifier s'il a été saisi dans le formulaire de description ; s'il n'est pas renseigné, inspecter la liste de **tous les transformateurs de l'audit** (`TransformateurMTBT.regimeNeutre`). S'il y existe, il est automatiquement coché et synchronisé sans écraser les régimes personnalisés (*« Autre »*).

### 9.2 Sources d'Alimentation et Départs
- **Accord grammatical** : Toute mention de source doit être strictement accordée au féminin : **`Identifiée`** ou **`Non identifiée`**.
- **Résolution hiérarchique** : Une source inconnue est détectée dès lors qu'elle est vide, contient `inconnue`, `non identifiée` ou ne correspond à aucun TGBT/Armoire/Départ répertorié.

### 9.3 Numérotation des Équipements
- **Déterminisme** : Géré exclusivement par `EquipmentNumberService`.
- **Continuité** : Indexation numérique entière strictement croissante (`1, 2, 3...`) unique à travers toute la mission (Locaux MT, Zones MT, Zones BT, Coffrets directs et Brouillons).
- **Protection contre l'explosion de séquence** : Rejet automatique des valeurs non entières (ex. `400V` ou années `2024` qui faussaient l'auto-incrément).

### 9.4 Arrêt d'Urgence et Organes de Coupure
- **Gestion conditionnelle** : Si le site ne dispose pas d'arrêt d'urgence, la saisie indique `Absent` et masque automatiquement les tests d'essais sans lever de fausse non-conformité de mesure.

### 9.5 Classement Réglementaire et Hiérarchie des Établissements (Renseignements Principaux)
- **4 Classements exclusifs normalisés** :
  1. `Installations classées` : 1 seul type (`Usines, Ateliers, Dépôts, Chantiers`), catégorie non applicable (`Sans objet (Non applicable)`).
  2. `IGH` (Immeubles de Grande Hauteur) : 8 types stricts (`GHA`, `GHO`, `GHR`, `GHS`, `GHU`, `GHW1`, `GHW2`, `GHZ`), catégorie non applicable (`Sans objet (Non applicable)`).
  3. `ERP Établissements Généraux` : 14 types normalisés (`Type J` à `Type Y`), 5 catégories d'effectif (`Première catégorie` à `Cinquième catégorie`).
  4. `ERP Établissements Spécialisés` : 8 types normalisés (`Type PA`, `Type CTS`, `Type SG`, `Type PS`, `Type GA`, `Type OA`, `EF`, `REF`), 5 catégories (`Première catégorie` à `Cinquième catégorie`).
- **Hiérarchie dynamique en cascade** : `Classement réglementaire` -> filtre les options disponibles pour `Type` -> filtre les options disponibles pour `Catégorie`. Si le classement change, les sélections incompatibles sont réinitialisées.
- **Inférence & Rétro-compatibilité historique** : Les missions antérieures créées sans classement parent déduisent automatiquement leur classement réglementaire via `RegulatoryClassificationService.inferClassificationFromLegacy`.
- **Rendu PDF V3** : Le tableau « 1. Renseignements principaux » présente un en-tête `Rubrique` | `Informations`. Les lignes `Type` et `Catégorie` sont divisées par une bordure verticale fine (0.4pt) avec le titre à gauche (en gras) et la description détaillée officielle à droite.

---

## 10. Data & Persistence (Hive)

### Boîtes de Stockage (`Boxes`)
| Nom de la Boîte | Type de Données Contenu |
|---|---|
| `missions` | `Mission` (Métadonnées, dates, statut, périmètre) |
| `renseignements_generaux` | `RenseignementsGeneraux` (Client, site, contacts) |
| `description_installations` | `DescriptionInstallations` (Caractéristiques globales) |
| `audit_installations_electriques` | `AuditInstallationsElectriques` (Arborescence MT/BT complète) |
| `classement_emplacement` | `ClassementEmplacement` (Locaux techniques et risques) |
| `classement_zone` | `ClassementZone` (Classification des locaux) |
| `foudre` | `Foudre` (Installations de protection foudre) |
| `mesures_essais` | `MesuresEssais` (Résistances, isolements, DDR, CPI) |
| `jsa` | `JSA` (Sécurité des intervenants) |
| `lighting_inspections` | `LightingInspection` (Audit photométrique) |
| `verificateurs` | `Verificateur` (Utilisateurs locaux et matricules) |
| `trash` | `TrashItem` (Éléments supprimés temporairement) |
| `backup_queue` | `BackupQueueItem` (Sauvegardes en attente de synchro) |
| `executive_summary_cache` | Cache des résumés générés par IA |

### Registre des Adaptateurs Hive (`TypeId`)
Les `TypeId` sont **strictement réservés et immuables** :
- `0`: VerificateurAdapter | `1`: MissionAdapter | `2`: DescriptionInstallationsAdapter | `3`: AuditInstallationsElectriquesAdapter
- `4`: MoyenneTensionLocalAdapter | `5`: MoyenneTensionZoneAdapter | `6`: BasseTensionZoneAdapter | `7`: BasseTensionLocalAdapter
- `8`: ElementControleAdapter | `9`: CelluleAdapter | `10`: TransformateurMTBTAdapter | `11`: CoffretArmoireAdapter
- `12`: AlimentationAdapter | `13`: PointVerificationAdapter | `14`: ClassementEmplacementAdapter | `15`: FoudreAdapter
- `16`: MesuresEssaisAdapter | `17`: ConditionMesureAdapter | `18`: EssaiDemarrageAutoAdapter | `19`: TestArretUrgenceAdapter
- `20`: PriseTerreAdapter | `21`: AvisMesuresTerreAdapter | `22`: EssaiDeclenchementDifferentielAdapter | `23`: ContinuiteResistanceAdapter
- `24`: ObservationLibreAdapter | `25`: InstallationItemAdapter | `34`: RenseignementsGenerauxAdapter | `35`: TrashItemAdapter
- `39`: JSAAdapter | `40` à `45`: JSA Sub-Adapters | `46`: ClassementZoneAdapter | `50`: LastReportAdapter
- `60` à `62`: Lighting Adapters | `63`: EssaiIsolementAdapter | `64`: DepartEquipementAdapter | `65`: CircuitTerminalEquipementAdapter | `66`: CpiTestAdapter

---

## 11. Migration & Backward Compatibility

1. **Règle d'Or Hive** :
   - Ne jamais réutiliser un `@HiveField(id)` existant.
   - Toujours ajouter les nouveaux champs en fin d'indexation avec une valeur par défaut ou un type nullable (`String?`, `List<String>?`).
2. **Migrations Silencieuses Idempotentes** :
   - Exécutées au démarrage dans `main.dart` via `HiveService.migrate*()`.
   - Les missions anciennes créées sans les nouveaux champs (ex: `formationHabilitationElectrique`, `perimetreMission`, nouveaux types de départs) s'ouvrent sans crash ni perte de données.
3. **Corbeille & Rétention** :
   - Suppression logique dans `trashBox` avec purge automatique des éléments ayant plus de 90 jours (`TrashService.autoPurgeExpiredItems`).

---

## 12. State Management (Riverpod)

- **Architecture réactive** :
  - Les écrans de saisie consomment des `ConsumerStatefulWidget` ou `ConsumerWidget`.
  - Utilisation de `ref.watch(provider(missionId))` pour l'écoute réactive.
  - Sauvegarde asynchrone non-bloquante déclenchée sur les mutations (`saveAudit`, `saveMesures`).
- **Isolation des Providers par Domaine** :
  - `auditInstallationsProvider` : Gestion de l'arborescence technique.
  - `mesuresEssaisProvider` : Gestion des campagnes de mesures physiques.
  - `foudreObservationsProvider` : Gestion du risque foudre.
  - `backupOrchestratorProvider` : État global de synchronisation et barre de progression transversale (`GlobalBackupProgressOverlay`).

---

## 13. Performance & Resource Management

1. **Génération PDF Hors Thread Principal (Isolates)** :
   - Les générations PDF et les compressions de gros volumes d'images s'exécutent impérativement hors du thread UI via `compute()` ou des isolats dédiés pour éliminer tout *frame drop* ou blocage d'interface.
2. **Gestion Anti-OOM (Out Of Memory)** :
   - Ne jamais charger l'intégralité des photographies brutes en mémoire simultanément.
   - Les photos sont chargées et redimensionnées à la volée par micro-lots de 3 pages maximum (`PdfPhotosSchemasBuilder`).
3. **Compression d'Images Réseau & Disque** :
   - Toute photo prise par l'appareil photo ou sélectionnée en galerie passe immédiatement par `flutter_image_compress` avant persistance et injection dans le PDF.

---

## 14. Security & Sensitive Data

- **Exclusion stricte des Secrets** :
  - Le fichier `lib/config/api_keys.dart` est exclu de Git (`.gitignore`).
  - Seul `lib/config/api_keys.dart.example` doit figurer sur le dépôt.
- **Stockage Sécurisé des Identifiants** :
  - Mots de passe vérificateurs hachés via `bcrypt`.
  - Tokens d'accès et jetons de synchronisation cloud stockés dans `flutter_secure_storage`.
- **Intégrité Cryptographique** :
  - Toute archive de sauvegarde exportée intègre un contrôle d'intégrité par empreinte SHA-256 (`INSPEC_BACKUP_V2`).

---

## 15. Testing & Quality Assurance

- **Harnais de Régression** : Plus de 100 suites de tests automatisés dans `test/features/` et `test/services/`.
- **Tests Unitaires Obligatoires** :
  - Toute modification de calcul statistique, de formule Pareto ou de synchronisation d'entité doit être accompagnée de son test unitaire dédié.
- **Simulation Réelle de Données Industrielles** :
  - Les tests s'appuient sur des structures de missions réelles de production (ex. audits réels Camrail Bessengué, Guinness Bassa, Cimencam).

---

## 16. UI/UX Design System & Ergonomics

- **Couleurs Principales** :
  - `primaryBlue` : `#2196F3` (Actions, boutons principaux).
  - `darkBlue` : `#1976D2` / `#1E3A8A` (En-têtes, titres, contrastes élevés).
  - `greyLight` : `#F5F5F5` (Fonds de champs et cartes neutres).
- **Ergonomie Terrain (Tactile & Chantier)** :
  - Cibles tactiles d'au moins 48x48 dp adaptées à une manipulation avec des gants d'inspection.
  - Saisie rapide assistée : sélecteurs de valeurs fréquentes avec option *« Autre / Saisir »*.
  - Accompagnement visuel de l'avancement : barres de progression circulaires par étape (`sequence_progress_service.dart`).

---

## 17. Flutter & Dart Standards

- Respect strict des recommandations officielles Flutter et règles de `flutter_lints ^5.0.0`.
- Constructeurs `const` appliqués systématiquement partout où le sous-arbre de widgets est immuable.
- Extraction de sous-widgets autonomes plutôt que de gigantesques méthodes `build()` imbriquées.
- Verrouillage d'orientation en mode portrait sur smartphone (`DeviceOrientation.portraitUp`) pour garantir la stabilité de l'affichage en mobilité.

---

## 18. Electrical Engineering Domain & Norms

### Références Normatives Clés
- **NF C 15-100 (Basse Tension)** : Règles de conception, réalisation et vérification des installations BT. Protection contre les contacts directs et indirects, dimensionnement des canalisations, calibres des disjoncteurs, sélectivité, différentiels 30 mA pour prises et locaux humides.
- **NF C 13-100 & NF C 13-200 (Haute Tension / HTA)** : Postes de livraison et installations MT. Distances d'isolement, verrouillage mécanique inter-cellules, DGPT2 / relais Buchholz sur transformateurs à huile, bacs de rétention étanches avec extincteur coupe-feu, signalisation de danger.
- **NF C 18-510** : Prescriptions de sécurité électrique, habilitation du personnel (B1V, B2V, BR, BC, H1V, H2V).
- **NF C 17-102** : Protection contre la foudre par paratonnerres à dispositif d'amorçage (PDA).
- **APSAD D18** : Contrôle des installations électriques par thermographie infrarouge.
- **Décret 88-1056** : Protection des travailleurs dans les établissements mettant en œuvre des courants électriques.

### 5 Familles Canoniques de Risques
1. `Erreur d'exploitation / maintenance`
2. `Électrisation / électrocution`
3. `Dégradation des canalisations et matériels`
4. `Surintensité / court-circuit`
5. `Échauffement / surcharge / risque d'incendie`

### 10 Catégories Canoniques de Défauts (Pareto)
1. `Interconnexion à la terre et protections différentielles`
2. `Dispositifs de protection contre les surintensités`
3. `Répartition des circuits et répartiteurs`
4. `Identification, repérage et documentation des circuits`
5. `Câblages, raccordements et canalisations`
6. `Intégrité des enveloppes, armoires et coffrets`
7. `Organes de coupure, d'isolement et d'urgence`
8. `Éclairage de sécurité et secours`
9. `Poste et équipements Moyenne Tension`
10. `Autres anomalies d'exploitation`

---

## 19. Reporting & Document Generation (PDF V3, Excel, Word)

### Architecture PDF V3 (Génération Découpée & Moteur 2-Passes)
Pour prévenir tout débordement mémoire sur des rapports de 100+ pages :
1. **Passe 1 (Pre-Flight & Calcul des Clés)** :
   - Construction réelle en mémoire du sous-document 1.1 (Couverture + Sommaire dynamique) pour obtenir son nombre exact de pages sans estimation arbitraire.
   - Parcours de tous les sous-chunks avec injection stricte de `offset` dans chaque instance de `PageTracker`.
   - Enregistrement des numéros de page absolus dans `trackedPages[key]`.
2. **Passe 2 (Génération Disque & Footer Absolu)** :
   - Injection du total global : footer formaté en `Page (ctx.pageNumber + pageOffset) / $overrideTotalPages`.
   - Écriture des fichiers temporaires `.pdf` sur le stockage applicatif.
3. **Fusion Binaire (`PdfMergerService`)** :
   - Assemblage séquentiel direct sans ré-encodage destructeur.

### Rapport Vérification Électrique (13 Builders Spécialisés)
- `PdfCoverBuilder` : Page de garde officielle KES, intervenants, client, site, récepteur dynamique, QR code.
- `PdfSommaireBuilder` : Sommaire dynamique multi-pages synchronisé.
- `PdfRegulatoryBuilder` : Normes applicables, matériels étalonnés, périmètre.
- `PdfExecutiveSummaryBuilder` : Synthèse exécutive, criticité globale, facteurs clés.
- `PdfStatisticsBuilder` : Courbe de Pareto, histogrammes, distribution des risques.
- `PdfRenseignementsBuilder` : Renseignements généraux administratifs et techniques.
- `PdfDescriptionBuilder` : Description générale MT/BT, postes, régimes de neutre.
- `PdfEquipementsSynthesisBuilder` : Tableaux de synthèse des équipements et sources.
- `PdfObservationsRecapBuilder` : Liste récapitulative unifiée des non-conformités.
- `PdfAuditInstallationsBuilder` : Grilles détaillées par local/zone/armoire.
- `PdfClassementFoudreBuilder` : Fiches de classement des locaux et audit foudre.
- `PdfMesuresEssaisBuilder` : Tableaux paysage de mesures de terre, continuités et isolements.
- `PdfPhotosSchemasBuilder` : Planches de photos probantes et schémas unifilaires.

### Rapport Thermographique Q18 APSAD D18 V1 (7 Builders Dédiés)
Moteur dédié [PdfQ18ReportService](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/pdf/q18/pdf_q18_report_service.dart) couvrant les 16 sections normatives du traité D18 :
- `Q18CoverBuilder` : Couverture unifiée avec Vérif Elec via `PdfCoverBuilder.resolveRecepteurInfo`, texte central adapté Q18 et support de `qrCodeQ18`.
- `Q18SommaireBuilder` : Sommaire 16 sections dynamique avec pagination absolue.
- `Q18AdminConditionsBuilder` : Sections 1 à 5 (Conditions générales, opérateur, site, matériel thermographique).
- `Q18ScopeEstablishmentBuilder` : Sections 6 à 9 (Classification, régimes de neutre, nature des installations).
- `Q18ExclusionsSyntheseBuilder` : Sections 10 à 13 (Exclusions, synthèse globale des anomalies thermiques, attestations).
- `Q18RecommendationsBuilder` : Sections 14 et 15 (Mesures d'urgence et prescriptions de maintenance).
- `Q18PhotosBuilder` : Section 16 (Planches de clichés thermographiques & visibles). Implémente le pattern **Preflight Zero-Load** en Passe 1 (conteneurs factices sans décodage mémoire) et une compression adaptative des clichés en Passe 2 (<4 Mo au total).

---

## 20. Import, Export & Backup System (V2)

- **Format V2 (`INSPEC_BACKUP_V2`)** :
  - Export complet ou unitaire d'une mission spécifique (`exporterMission(missionId)`).
  - Archive ZIP standard contenant les flux JSON structurés et le dossier complet des photographies compressées.
  - Contrôle d'intégrité strict par hachage SHA-256 à l'importation.
- **File d'Attente de Synchronisation (`BackupQueueService`)** :
  - Empilement automatique des missions modifiées dans `backup_queue`.
  - Dépilage et synchronisation en arrière-plan vers le Cloud (Microsoft OneDrive / Graph API) dès rétablissement de la connectivité réseau.

---

## 21. Known Issues & Forensic Gotchas

1. **Collision de `syncId` en microsecondes lors des tests unitaires** :
   - *Cause* : Deux équipements créés dans la même microseconde partageaient le même horodatage de secours.
   - *Règle* : Ne jamais dédoubler ou filtrer des entités de liste sur un identifiant basé sur le temps sans entropie UUID.
2. **Omission d'`offset` dans `PageTracker`** :
   - *Cause* : Si un builder n'injecte pas `currentOffset` dans `PageTracker`, la page enregistrée dans le sommaire est relative au chunk local (ex. page 2 au lieu de 45).
   - *Règle* : Tout widget de titre tracé dans le sommaire doit impérativement recevoir et transmettre `offset: currentOffset`.
3. **Usage interdit de `ctx.pagesCount` dans les Footers de Chunks** :
   - *Cause* : Affichait des compteurs locaux absurdes (ex: `Page 2 / 3` dans la section Mesures).
   - *Règle* : Le footer utilise uniquement `ctx.pageNumber + pageOffset` et la variable globale `overrideTotalPages`.
4. **Piège du Court-Circuit dans la Résolution du Récepteur** :
   - *Cause* : Les getters résilients retournant une valeur non-nulle (`'Monsieur'` ou `''`), l'opérateur `??` court-circuitait le fallback vers les données `recepteurRapport` et `RenseignementsGeneraux`.
   - *Règle* : Tester explicitement le contenu textuel (`isNotEmpty`) avant de décider d'ignorer la source historique.
5. **OOM et Explosion de Taille PDF en Q18** :
   - *Cause* : Chargement et décodage de toutes les photos thermiques dès la Passe 1 de pre-flight.
   - *Règle* : Appliquer le pattern **Preflight Zero-Load** (conteneurs virtuels avec layout préservé sans décodage d'image en Passe 1).
6. **Verrouillage de fichier sous Windows lors des builds Android (`mergeReleaseNativeLibs`)** :
   - *Cause* : Processus Gradle ou antivirus maintenant un handle ouvert sur des bibliothèques natives `.so`.
   - *Règle* : Toujours stopper les démons Gradle (`gradlew --stop`) avant les builds de packaging lourd.
7. **Perte et effacement silencieux lors de l'import/export de sous-modules (Luminaires)** :
   - *Cause* : Lors d'un import sans écrasement avec conflit de mission, `_remapMissionId` conservait les `item.id` de base, provoquant leur rejet silencieux par `box.containsKey()`. De plus, l'import avec écrasement purgeait la boîte locale même si l'archive importée ne contenait pas de luminaires.
   - *Règle* : Toujours réattribuer un nouvel ID unique lors du remapping de sous-modules stockés par ID primaire, et ne purger lors d'un import écrasé QUE si la collection importée est explicitement présente et non-vide.
8. **Disparition de photos prises sur le terrain (Cache OS temporaire)** :
   - *Cause* : Stockage direct du chemin renvoyé par l'appareil photo/galerie sans copie locale vers `audit_photos/`. Lors d'un nettoyage de cache Android/iOS ou d'un export `.inspec`, les photos disparaissaient.
   - *Règle* : Toute photo capturée doit être immédiatement copiée de façon synchrone dans `audit_photos/<module>/` avant d'être référencée dans le modèle.
9. **Normalisation centralisée des observations à la persistance** :
   - *Cause* : Les normalisations uniquement branchées sur les `TextEditingController` ou l'UI laissaient passer des textes non normalisés lors des flux directs ou des imports.
   - *Règle* : `ObservationTextNormalizer` doit être exécuté au niveau de la couche Data (`HiveService.save*` et `BackupService._import*`), avec garantie d'idempotence et préservation stricte des grandeurs physiques et références normatives.

---

## 22. Technical Debt

1. **Migration progressive des derniers écrans legacy vers Riverpod** :
   - Certaines sous-étapes secondaires utilisent encore des `StatefulWidget` locaux combinés à des appels de synchronisation manuels. Les migrer vers les `AsyncNotifier` dédiés au fur et à mesure des interventions.
2. **Consolidation du service Word (`word_report_service.dart`)** :
   - Alignement complet de sa structure sur le découpage par builders adopté avec succès sur le moteur PDF V3.

---

## 23. Architectural Decisions Records (ADR)

### ADR-001 : Migration Clean Architecture & Découpage en 3 Couches
- **Date** : Juillet 2026
- **Décision** : Séparer l'application en couches Domain (entités pures, use cases), Data (datasources Hive, mappers, repositories) et Presentation (widgets, providers).
- **Raison** : Éliminer le couplage direct des interfaces de saisie avec le stockage Hive et permettre une couverture de tests unitaires automatisés à 100 % sur la logique métier.

### ADR-002 : Architecture de Pagination Globale Centralisée et Découpage V3 du PDF
- **Date** : Août 2026
- **Décision** : Abandonner la génération PDF monolithique au profit d'un orchestrateur à 2 passes avec pre-flight réel du sommaire et fusion binaire par `PdfMergerService`.
- **Raison** : Résoudre définitivement les crashs mémoire (OOM) sur smartphones de terrain lors de l'édition de missions industrielles lourdes (ex. Cimencam, Camrail).

### ADR-003 : Refactorisation de `PdfReportService` en Façade & 13 Builders Spécialisés
- **Date** : Septembre 2026
- **Décision** : Éclater le fichier monolithique de 21 700 lignes en 13 builders spécialisés coordonnés par `PdfReportContext` et `PdfReportStyles`.
- **Raison** : Rendre le code maintenable, lisible, navigable et testable unitairement sans modifier d'un seul pixel le rendu final des livrables.

### ADR-004 : Centralisation de la Numérotation des Équipements
- **Date** : Septembre 2026
- **Décision** : Créer `EquipmentNumberService` avec validation numérique stricte et séquence monotone croissante.
- **Raison** : Garantir l'immuabilité et la cohérence de l'indexation N° à travers toute la mission sans interférence des bruits de saisie.

### ADR-005 : Moteur de Rapport Q18 APSAD D18 V1 & Preflight Zero-Load
- **Date** : Septembre 2026
- **Décision** : Structurer `PdfQ18ReportService` en 7 builders modulaires et implémenter le pattern Preflight Zero-Load dans `Q18PhotosBuilder` avec compression d'images adaptative.
- **Raison** : Prévenir les OOM lors de l'édition de rapports thermographiques lourds (50+ photos) et réduire la taille des PDF finaux de >75 % (<4 Mo).

### ADR-006 : Unification de la Couverture PDF & Résolution Centralisée du Récepteur
- **Date** : Septembre 2026
- **Décision** : Harmoniser la couverture de tous les livrables KES via `PdfCoverBuilder.resolveRecepteurInfo` et supporter des QR codes dédiés (`qrCodeClient`, `qrCodeQ18`).
- **Raison** : Assurer une identité graphique et une rigueur légale identiques sur l'ensemble des documents d'ingénierie KES.

---

## 24. Lessons Learned & Anti-Patterns

- **Anti-Pattern : Index de Liste comme Identifiant Technique** :
  - *Leçon* : Un index de liste change dès qu'un élément est trié, filtré ou supprimé. Utiliser toujours un identifiant stable (`id` UUID) pour chaque équipement, armoire, local ou point de contrôle.
- **Anti-Pattern : Estimation Empirique du Nombre de Pages** :
  - *Leçon* : Estimer qu'un sommaire fait « 1 ou 2 pages » selon la taille d'une liste conduit inévitablement à des décalages d'une page sur tout le rapport. Mesurer toujours la hauteur réelle du document lors d'une passe de pre-flight.
- **Anti-Pattern : Saisie Directe en Base sans Dépôt Intermédiaire** :
  - *Leçon* : Toute mutation directe d'un objet Hive partagé sans passer par une copie immuable ou un Use Case risque de corrompre l'état en cas d'annulation utilisateur.

---

## 25. Deprecated Decisions & Obsolete Practices

- **Remplacé** : L'accès direct aux Use Cases via `GetIt.I<UseCase>()` à l'intérieur des méthodes de build de widgets est déprécié au profit de l'injection par providers Riverpod (`ref.watch`).
- **Remplacé** : L'ancien format de sauvegarde V1 non signé est remplacé par le format V2 avec signature SHA-256 et support de l'export unitaire de mission.
- **Remplacé** : L'ancienne table monolithique de synthèse des observations avec cellules orphelines a été remplacée par l'affichage en cartes d'équipements fermées avec en-têtes répétés.

---

## 26. Current Priorities

1. **V1 stabilisée et prête pour la production** : Maintien de l'intégrité absolue des 160+ suites de tests automatisés couvrant les audits réels, le moteur PDF V3, le rapport Q18 V1 et la persistance Hive.
2. **Garantie d'harmonie visuelle et documentaire** : Uniformisation de la couverture (résolution des récepteurs et QR codes) et exactitude normative (NF C 15-100, NF C 13-100/200, APSAD D18).
3. **Prévention mémoire & performance terrain** : Respect strict du pattern Preflight Zero-Load et de la compression d'images lors de toute manipulation documentaire lourde.

---

## 27. Workflow Rules & Agent Protocol

À chaque intervention sur la base de code, tout agent doit exécuter rigoureusement ce protocole :

1. **Consulter `AGENTS.md` et `PROJECT_MEMORY.md`** : S'imprégner des contraintes critiques, règles invariables et de l'état actuel (`CURRENT PROJECT STATE` & `DO NOT BREAK`).
2. **Consulter le pilier documentaire dédié** : Si l'intervention touche un domaine spécifique (Modèle, Persistance, PDF, Backup), consulter le module correspondant dans `docs/project-memory/`.
3. **Auditer avant de modifier** : Analyser le code réel, retracer les dépendances et identifier les risques de régression.
4. **Appliquer des modifications chirurgicales** : Ne modifier que les lignes nécessaires sans reformater arbitrairement le code environnant.
5. **Vérification systématique** :
   - Lancer l'analyse statique : `dart analyze <fichiers_modifiés>`.
   - Exécuter les suites de tests unitaires concernées : `flutter test <chemins_des_tests>`.
6. **Mettre à jour le graphe de connaissances et la mémoire** :
   - Exécuter `graphify update .` après toute modification de code Dart.
   - Si la modification change la connaissance durable (nouveau champ, règle métier, format de rapport), mettre à jour `PROJECT_MEMORY.md` et le module associé dans `docs/project-memory/`.
7. **Livraison du Commit** :
   - Fournir uniquement le texte du message de commit en français au format Markdown avec le préfixe adéquat (`[CREATE]`, `[UPD]`, `[DLT]`).
   - **Ne jamais exécuter `git commit`**.

---

## 28. Quality Gates & Verification Checklist

Avant de considérer une tâche comme finalisée, valider les points suivants :

- [ ] **Compilation & Analyse** : `flutter analyze` / `dart analyze` passe sans aucune erreur.
- [ ] **Tests Automatisés** : `flutter test` passe à 100 % sur les fonctionnalités modifiées.
- [ ] **Intégrité des Données** : Rétrocompatibilité totale avec les missions antérieures (champs nullables, zéro perte de données existantes).
- [ ] **Pérennité Hive** : Aucun identifiant `@HiveField` n'a été modifié ou réassigné.
- [ ] **Pagination & Rendu PDF** : Aucune rupture de pagination, sommaire synchronisé, aucun dépassement ou coupure anormale de tableau.
- [ ] **Accord Grammatical & Rigueur** : Vocabulaire technique et accords vérifiés (`Source non identifiée / Identifiée`, etc.).
- [ ] **Mémoire Projet** : `PROJECT_MEMORY.md` et `docs/project-memory/` mis à jour si nécessaire.
- [ ] **Conformité des Commits** : Message de commit rédigé en français avec pré-syntaxe `[CREATE]`, `[UPD]`, `[DLT]`, sans exécution automatique de `git commit`.
