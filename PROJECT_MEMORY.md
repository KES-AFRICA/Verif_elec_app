# PROJECT_MEMORY.md — Boussole Opérationnelle & Mémoire Vivante de KES Inspection App

> **Projet** : KES Inspection App (`inspec_app`)  
> **Organisation** : Kamer Engineering Solutions (KES Inspections & Projects)  
> **Dernière révision** : 27 Septembre 2026  
> **Rôle du document** : Point d'entrée unique de chargement rapide pour tout agent intervenant sur le projet. Ce document synthétise l'état actuel de l'application, les commandements inviolables et oriente vers les 6 piliers documentaires détaillés dans `docs/project-memory/`.

---

## SOMMAIRE

1. [CURRENT PROJECT STATE](#1-current-project-state)
2. [DO NOT BREAK (Les 10 Commandements Inviolables)](#2-do-not-break-les-10-commandements-inviolables)
3. [NEW AGENT / NEW SESSION PROTOCOL (Démarrage en 10 étapes)](#3-new-agent--new-session-protocol-démarrage-en-10-étapes)
4. [CARTOGRAPHIE DU SYSTÈME & FLUX DE BOUT EN BOUT](#4-cartographie-du-système--flux-de-bout-en-bout)
5. [INDEX DES 6 PILIERS TECHNIQUES DÉTAILLÉS](#5-index-des-6-piliers-techniques-détaillés)
6. [TASK COMPLETION & MEMORY AUTO-UPDATE PROTOCOL](#6-task-completion--memory-auto-update-protocol)

---

## 1. CURRENT PROJECT STATE

| Axe | État Réel Validé |
|---|---|
| **Framework & Langage** | Flutter (Canal Stable), Dart SDK `^3.9.2`. Respect strict de `flutter_lints ^5.0.0`. |
| **Persistance Locale** | Hive `^2.2.3` & `hive_flutter ^1.1.0`. **18 boîtes Hive actives**, **45+ TypeAdapters enregistrés**. Modèle `Mission` étendu jusqu'à `@HiveField(56)` (`centralePhotovoltaique`, `qrCodeQ18`, récepteurs normalisés). Migrations silencieuses idempotentes au démarrage. |
| **State Management & DI** | Flutter Riverpod `^2.5.1` (`StateNotifierProvider.family`, `AsyncValue`, `ref.watch`). Injection de dépendances via GetIt `^8.0.3` (`injection_container.dart`). |
| **Architecture** | Clean Architecture modulaire Feature-First (`lib/features/` : Auth, Mission, Audit, Description, Foudre, Mesures, JSA, Backup). |
| **Moteur PDF (V3 & Q18 V1)** | Architecture micro-lots 2-passes :<br>• **Vérification Électrique** : 13 builders spécialisés, pagination absolue `Page X / N`, pre-flight réel du sommaire.<br>• **Q18 APSAD D18 (V1)** : 7 builders modulaires couvrant 16 sections normatives, **Preflight Zero-Load** pour les photos thermographiques, compression adaptative d'images (<4 Mo au lieu de 18 Mo).<br>• **Couverture unifiée** : [PdfCoverBuilder.resolveRecepteurInfo](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/pdf/builders/pdf_cover_builder.dart) harmonise le récepteur (civilité, nom, fonction en majuscules) et supporte les QR codes dédiés (`qrCodeClient`, `qrCodeQ18`). |
| **Moteur Excel** | Syncfusion XlsIO `^33.2.13`. 2 feuilles normalisées (*« Annexe des équipements »* et *« Annexe des observations »*) réutilisant la logique et les métriques du PDF. |
| **Moteur Word** | `docs_gee ^1.0.1`. Structure miroir du rapport technique. |
| **Import / Export** | Format signé SHA-256 V4 (`INSPEC_BACKUP_V4`), rétrocompatible V1/V2/V3. Export unitaire ou global, archive ZIP, synchronisation cloud d'arrière-plan `BackupQueueService` vers Microsoft 365. |
| **Statistiques Métier** | 16 moteurs déterministes dans `lib/services/statistics/` (Pareto, 10 catégories de défauts, 5 familles de risques, isolation stricte MT vs BT). |
| **Tests & Régression** | **160+ suites de tests automatisés** dans `test/features/` et `test/services/` simulant des missions industrielles réelles de production (Cimencam, Camrail, Guinness, Q18 complet). |
| **Chantier Actif & Dette** | **V1 finalisée et hautement stable**. Dette modérée : consolidation continue de la structure Word sur le pattern des builders PDF. |

---

## 2. DO NOT BREAK (Les 10 Commandements Inviolables)

Toute intervention sur le projet **doit impérativement respecter ces 10 commandements sous peine de corruption ou régression grave** :

1. **ZÉRO PERTE DE DONNÉES HISTORIQUES** :  
   Les anciennes missions stockées sur le terminal des inspecteurs doivent s'ouvrir, se lire et s'exporter sans crash ni altération. Tout ajout de champ dans un modèle Hive doit être **nullable (`String?`)** ou avoir une **valeur par défaut (`defaultValue: ...`)** et se placer en fin d'index `@HiveField`.
2. **REGISTRE HIVE TYPEID SACRÉ** :  
   Ne **JAMAIS** modifier un `@HiveField(id)` existant et ne **JAMAIS** réassigner un `typeId` d'adaptateur. Se référer au registre officiel dans [03_PERSISTENCE_AND_MIGRATIONS.md](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/docs/project-memory/03_PERSISTENCE_AND_MIGRATIONS.md).
3. **NE JAMAIS CONFONDRE IDENTIFIANT TECHNIQUE ET INDEX DE LISTE** :  
   Un index de liste (`items[i]`) n'a aucune stabilité. L'identité technique d'un coffret, d'un local ou d'un départ repose **exclusivement sur son identifiant technique stable** (`equipmentId`, `localId`, `departId`).
4. **NUMÉROTATION SÉQUENTIELLE MONOTONE DES ÉQUIPEMENTS** :  
   Gérée exclusivement par [EquipmentNumberService](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/equipment_number_service.dart). Indexation entière strictement croissante (`1, 2, 3...`) unique à travers toute la mission. Rejet strict des bruits de saisie (`400V`, `2024`).
5. **ISOLATION STRICTE MT (Moyenne Tension) / BT (Basse Tension)** :  
   Un équipement BT (armoire, coffret, onduleur) physiquement implanté dans un local MT **reste un équipement BT**. Il ne doit jamais être comptabilisé dans les agrégats ou indicateurs statistiques MT.
6. **NE JAMAIS ESTIMER EMPIRIQUEMENT LA HAUTEUR D'UN SOMMAIRE PDF** :  
   La pagination PDF repose sur la Passe 1 de pre-flight qui compile réellement le sommaire en mémoire. Ne jamais deviner arbitrairement son nombre de pages.
7. **FOOTER PDF : USAGE STRICT D'OVERRIDE TOTAL PAGES** :  
   Dans les footers de chunks PDF, ne jamais utiliser `ctx.pagesCount` (compteur local du tronçon). Toujours utiliser `(ctx.pageNumber + pageOffset) / $overrideTotalPages`.
8. **ACCORD GRAMMATICAL & RÉSOLUTION HARMONISÉE DU RÉCEPTEUR** :  
   - Toute mention de source dans l'UI, le PDF ou l'Excel doit être accordée au féminin : **`Identifiée`** ou **`Non identifiée`**.  
   - Tout affichage de récepteur sur une couverture de rapport officiel doit passer par [PdfCoverBuilder.resolveRecepteurInfo](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/pdf/builders/pdf_cover_builder.dart) pour garantir l'harmonisation visuelle et le fallback résilient sans duplication de civilité.
9. **INTÉGRITÉ SHA-256 ET ARCHIVAGE ZIP** :  
   Toute modification du format de sauvegarde doit préserver la rétrocompatibilité d'importation des versions antérieures (V1, V2, V3) et vérifier la somme de contrôle SHA-256.
10. **RÈGLES ABSOLUES GIT & SÉCURITÉ** :  
    - **Aucun commit automatique (`git commit`)** : fournir uniquement le texte Markdown du commit en français avec pré-syntaxe obligatoire (`[CREATE]`, `[UPD]`, `[DLT]`).  
    - **Aucune clé API dans Git** : `lib/config/api_keys.dart` doit rester exclu par `.gitignore`.

---

## 3. NEW AGENT / NEW SESSION PROTOCOL (Démarrage en 10 étapes)

Lorsqu'un agent ou développeur démarre une session sur le projet KES, il doit exécuter ce protocole avant d'écrire la moindre ligne de code :

```text
1. LIRE .agents/AGENTS.md                  -> S'imprégner de la constitution et des règles invariables.
2. LIRE PROJECT_MEMORY.md (ce fichier)     -> Connaître CURRENT PROJECT STATE et DO NOT BREAK.
3. LIRE LE MODULE TECHNIQUE CIBLÉ          -> Consulter docs/project-memory/ correspondant au besoin.
4. INSPECTER LE CODE RÉEL                  -> Localiser les fichiers concernés (Model, Repository, Provider, UI, PDF).
5. CARTOGRAPHIER LA DÉPENDANCE             -> Identifier les répercussions (Audit -> Description -> Statistiques -> PDF/Excel).
6. FORMULER LA STRATÉGIE CHIRURGICALE      -> Privilégier un diff ciblé sans reformater le code sain environnant.
7. IMPLÉMENTER SANS CASSER LE LEGACY       -> Conserver les fallbacks et getters rétrocompatibles.
8. VÉRIFIER                                -> Exécuter 'dart analyze' et 'flutter test <chemin_du_test>'.
9. METTRE À JOUR LA MÉMOIRE                -> Si la connaissance durable change, actualiser ce fichier et le module lié.
10. PROPOSER LE COMMIT EN FRANÇAIS         -> Proposer le message Markdown [CREATE], [UPD] ou [DLT].
```

---

## 4. CARTOGRAPHIE DU SYSTÈME & FLUX DE BOUT EN BOUT

### Cycle de vie d'une mutation de données
```text
[Formulaire UI / Step] ──(Saisie inspecteur)
         │
         ▼
[Provider Riverpod] ──────(StateNotifier / AsyncValue)
         │
         ▼
[Domain Use Case] ────────(Logique métier pure)
         │
         ▼
[Data Repository] ────────(Conversion Entity <-> HiveModel via Mapper)
         │
         ▼
[Hive DataSource / Box] ──(Écriture synchrone / asynchrone persistée)
         │
         ├────────────────────────────────────────────────┐
         ▼                                                ▼
[InstallationDescriptionSyncService]            [BackupQueueService]
(Sync automatique Transformateurs,             (Empilement silencieux pour
 Cellules et Régimes de neutre)                 sauvegarde M365 en tâche de fond)
         │
         ▼
[Moteurs Statistiques (x16)] ──► Utilisé par :
                                 ├── Dashboard analytique UI
                                 ├── Rapport PDF V3 (Builders)
                                 ├── Classeur Excel (Syncfusion)
                                 └── Rapport Word (docs_gee)
```

---

## 5. INDEX DES 6 PILIERS TECHNIQUES DÉTAILLÉS

Pour toute précision sur une zone spécifique du code, consulter les modules exhaustifs situés dans `docs/project-memory/` :

| Fichier | Périmètre & Contenu |
|---|---|
| [01_ARCHITECTURE_AND_STATE.md](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/docs/project-memory/01_ARCHITECTURE_AND_STATE.md) | Clean Architecture, Feature-First, Riverpod, Injection GetIt, formulaires dynamiques, cycle de vie, navigation séquentielle. |
| [02_DOMAIN_AND_DATA_MODEL.md](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/docs/project-memory/02_DOMAIN_AND_DATA_MODEL.md) | Hiérarchie canonique Mission -> Zone -> Local -> Équipement -> Départs, règle MT vs BT, identifiants stables, glossaire exhaustif vérifié. |
| [03_PERSISTENCE_AND_MIGRATIONS.md](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/docs/project-memory/03_PERSISTENCE_AND_MIGRATIONS.md) | Registre immuable des 18 boîtes Hive et 45+ TypeIds, stratégie de migrations silencieuses idempotentes, gestion des nullables, corbeille 90j. |
| [04_REPORTING_AND_STATISTICS.md](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/docs/project-memory/04_REPORTING_AND_STATISTICS.md) | Architecture PDF V3 par micro-lots 2-passes, 13 builders, Excel Syncfusion (2 feuilles unifiées), Word docs_gee, 16 moteurs statistiques déterministes. |
| [05_BACKUP_IMPORT_EXPORT_MEDIA.md](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/docs/project-memory/05_BACKUP_IMPORT_EXPORT_MEDIA.md) | Formats V1 à V4 (.inspec / ZIP), contrôle d'intégrité SHA-256, synchronisation d'arrière-plan Cloud M365, cycle de vie et compression des photos. |
| [06_ADR_AND_FORENSIC_REGISTER.md](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/docs/project-memory/06_ADR_AND_FORENSIC_REGISTER.md) | Décisions Architecturales (ADR), historique des évolutions fonctionnelles, registre des risques de régression, problèmes connus & pièges résolus. |

---

## 6. TASK COMPLETION & MEMORY AUTO-UPDATE PROTOCOL

À la fin de chaque tâche ou évolution significative, l'agent doit exécuter ce protocole de clôture :

1. **Vérification du code & Tests** :
   ```bash
   dart analyze lib/
   flutter test test/features/...
   ```
2. **Évaluation de l'impact mémoire** :
   Poser la question : *« Cette modification change-t-elle la connaissance durable du système pour les futurs agents ? »*  
   - Nouveau champ Hive ? -> Mettre à jour `02_DOMAIN_AND_DATA_MODEL.md` et `03_PERSISTENCE_AND_MIGRATIONS.md`.  
   - Nouveau builder ou format de rapport ? -> Mettre à jour `04_REPORTING_AND_STATISTICS.md`.  
   - Nouvelle décision ou piège résolu ? -> Mettre à jour `06_ADR_AND_FORENSIC_REGISTER.md`.  
   - Changement d'état global ? -> Mettre à jour la section [CURRENT PROJECT STATE](#1-current-project-state) ci-dessus.
3. **Mise à jour du Graphe de Connaissances** :
   ```bash
   graphify update .
   ```
4. **Restitution au développeur** :
   Fournir le bilan des modifications, l'état des tests, le statut de mise à jour de la mémoire et le message de commit en français formaté en Markdown.
