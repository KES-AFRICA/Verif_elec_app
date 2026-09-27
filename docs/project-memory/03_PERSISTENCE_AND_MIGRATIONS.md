# 03_PERSISTENCE_AND_MIGRATIONS.md — Persistance Locale & Migrations Hive

> **Module** : KES Inspection App — Pilier 3  
> **Dernière révision** : 27 Septembre 2026  
> **Source de vérité** : `lib/services/hive_service.dart`, `lib/models/*.g.dart`, `lib/services/trash_service.dart`

---

## 1. LES 18 BOÎTES DE STOCKAGE HIVE (`Hive.openBox`)

Fichier source : [lib/services/hive_service.dart](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/hive_service.dart#L95-L127)

| Nom de la Boîte | Type Générique | Rôle & Contenu |
|---|---|---|
| `verificateurs` | `<Verificateur>` | Inspecteurs enregistrés localement, mots de passe hachés bcrypt |
| `missions` | `<Mission>` | Métadonnées de mission, dates, périmètre, statuts |
| `current_user` | `dynamic` (sans type) | Session de l'utilisateur actif (`email`, `isLoggedIn`) |
| `description_installations` | `<DescriptionInstallations>` | Fiche générale, caractéristiques sources MT/BT, postes |
| `audit_installations_electriques` | `<AuditInstallationsElectriques>` | Arborescence complète MT et BT |
| `classement_locaux` | `<ClassementEmplacement>` | Locaux à risques d'incendie, influences externes |
| `classement_zones` | `<ClassementZone>` | Classification des zones géographiques du site |
| `foudre_observations` | `<Foudre>` | Fiches paratonnerres PDA et parafoudres |
| `mesures_essais` | `<MesuresEssais>` | Campagnes de mesures (Terre, Continuités, Isolements, DDR) |
| `lighting_inspections` | `<LightingInspection>` | Relevés photométriques et conformité luminaires |
| `renseignements_generaux` | `<RenseignementsGeneraux>` | Données administratives, contacts et habilitations |
| `jsa` | `<JSA>` | Évaluation des risques de sécurité et EPI |
| `coffret_drafts` | `dynamic` | Brouillons d'équipements en cours de saisie |
| `local_drafts` | `dynamic` | Brouillons de locaux en cours de configuration |
| `last_reports` | `<LastReport>` | Historique des rapports PDF/Excel édités |
| `trash_items` | `<TrashItem>` | Corbeille logique avec purge automatique à 90 jours |
| `backup_queue` | `dynamic` | File d'attente des sauvegardes en attente de synchro cloud |
| `executive_summary_cache` | `dynamic` | Cache des synthèses narratives générées par IA |

---

## 2. REGISTRE OFFICIEL ET IMMUABLE DES TYPEIDS HIVE

> **RÈGLE CRITIQUE** : Les `typeId` ci-dessous sont **gravés dans le marbre**. Il est formellement interdit de réassigner, supprimer ou modifier un `typeId` existant sous peine de corrompre immédiatement l'ensemble des missions historiques des clients.

| TypeId | Modèle Dart | Fichier Source |
|---|---|---|
| `0` | `Verificateur` | `lib/models/verificateur.dart` |
| `1` | `Mission` | `lib/models/mission.dart` |
| `2` | `DescriptionInstallations` | `lib/models/description_installations.dart` |
| `3` | `AuditInstallationsElectriques` | `lib/models/audit_installations_electriques.dart` |
| `4` | `MoyenneTensionLocal` | `lib/models/audit_installations_electriques.dart` |
| `5` | `MoyenneTensionZone` | `lib/models/audit_installations_electriques.dart` |
| `6` | `BasseTensionZone` | `lib/models/audit_installations_electriques.dart` |
| `7` | `BasseTensionLocal` | `lib/models/audit_installations_electriques.dart` |
| `8` | `ElementControle` | `lib/models/audit_installations_electriques.dart` |
| `9` | `Cellule` | `lib/models/audit_installations_electriques.dart` |
| `10` | `TransformateurMTBT` | `lib/models/audit_installations_electriques.dart` |
| `11` | `CoffretArmoire` | `lib/models/audit_installations_electriques.dart` |
| `12` | `Alimentation` | `lib/models/audit_installations_electriques.dart` |
| `13` | `PointVerification` | `lib/models/audit_installations_electriques.dart` |
| `14` | `ClassementEmplacement` | `lib/models/classement_locaux.dart` |
| `15` | `Foudre` | `lib/models/foudre.dart` |
| `16` | `MesuresEssais` | `lib/models/mesures_essais.dart` |
| `17` | `ConditionMesure` | `lib/models/mesures_essais.dart` |
| `18` | `EssaiDemarrageAuto` | `lib/models/mesures_essais.dart` |
| `19` | `TestArretUrgence` | `lib/models/mesures_essais.dart` |
| `20` | `PriseTerre` | `lib/models/mesures_essais.dart` |
| `21` | `AvisMesuresTerre` | `lib/models/mesures_essais.dart` |
| `22` | `EssaiDeclenchementDifferentiel` | `lib/models/mesures_essais.dart` |
| `23` | `ContinuiteResistance` | `lib/models/mesures_essais.dart` |
| `24` | `ObservationLibre` | `lib/models/audit_installations_electriques.dart` |
| `25` | `InstallationItem` | `lib/models/description_installations.dart` |
| `34` | `RenseignementsGeneraux` | `lib/models/renseignements_generaux.dart` |
| `35` | `TrashItem` | `lib/models/trash_item.dart` |
| `39` | `JSA` | `lib/models/jsa.dart` |
| `40` à `45` | Sous-entités JSA (Inspecteur, PlanUrgence, Dangers, Exigences, EPI, Verif) | `lib/models/jsa.dart` |
| `46` | `ClassementZone` | `lib/models/classement_zone.dart` |
| `50` | `LastReport` | `lib/models/last_report.dart` |
| `60` à `62` | `LightingInspection`, `NonConformingLuminaire`, `LuminaireQA` | `lib/models/lighting_inspection.dart` |
| `63` | `EssaiIsolement` | `lib/models/mesures_essais.dart` |
| `64` | `DepartEquipement` | `lib/models/audit_installations_electriques.dart` |
| `65` | `CircuitTerminalEquipement` | `lib/models/audit_installations_electriques.dart` |
| `66` | `CpiTest` | `lib/models/mesures_essais.dart` |

---

## 3. RÈGLE D'OR DE RÉTROCOMPATIBILITÉ ET MIGRATIONS SILENCIEUSES

### 1. Ajout d'un Nouveau Champ
Lorsqu'un champ doit être ajouté à un modèle Hive existant :
1. Choisir le prochain index `@HiveField` libre strictly supérieur aux précédents.
2. Le champ doit impérativement être **nullable** (`String?`, `int?`, `List<String>?`) ou posséder une **`defaultValue`** garantie.
3. Ne **jamais modifier le numéro d'index** d'un champ déjà en production.
4. Exécuter `dart run build_runner build --delete-conflicting-outputs` pour régénérer l'adaptateur `.g.dart`.

### 2. Migrations Silencieuses Idempotentes au Démarrage
Certaines évolutions structurelles nécessitent un assainissement des données stockées.  
Elles sont regroupées dans `HiveService` et invoquées au démarrage dans [main.dart](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/main.dart#L33-L35) :
- `migratePointsVerificationPriorite()` : garantit que toute anomalie possède une priorité valide (1, 2 ou 3).
- `migrateFromOldFields()` : convertit l'ancienne cellule unique / transfo unique d'un local vers les listes `cellules = []` et `transformateurs = []`.
- `autoPurgeExpiredItems(retentionDays: 90)` dans [TrashService](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/trash_service.dart#L125-L127) : purge logique des éléments supprimés depuis plus de 90 jours.

### 3. Getters Résilients et Fallbacks Métier
Dans les modèles, des getters encapsulent la lecture historique pour préserver l'affichage même si un champ est null :
- `effectiveSectionCablePhase` : lit `sectionCablePhase`, sinon bascule sur le champ historique `sectionCables`.
- `effectiveSectionCableNeutre` : lit `sectionCableNeutre`, sinon bascule sur la phase, sinon sur `sectionCables`.
- `effectiveMarque` : lit `marque`, sinon bascule sur la chaîne concaténée `marqueAnnee`.
- `isDepartPrisAvecProtection` : dérive l'état directement du `typeProtection` de tête avec fallback sur le booléen legacy.
- **Résolution centralisée du récepteur** : [PdfCoverBuilder.resolveRecepteurInfo](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/pdf/builders/pdf_cover_builder.dart) unifie la résolution du récepteur pour Vérif Électrique et Q18 :
  - Priorise les champs dynamiques de `Mission` : `@HiveField(49)` `recepteurCivilite`, `@HiveField(50)` `recepteurNom`, `@HiveField(51)` `recepteurFonction`.
  - Fallback automatique sur `@HiveField(47)` `recepteurRapport` et sur la boîte `RenseignementsGeneraux` historique.
  - Extraction chirurgicale des préfixes de civilité (`M.`, `Monsieur`, `Mme`, `Madame`) pour éviter les duplications (ex. « Monsieur Monsieur »).
  - Formatage en majuscules strictes pour le nom et la fonction (`TOUPPERCASE`), civilité par défaut `Monsieur`.

---

## 4. HISTORIQUE RÉCENT DES CHAMPS DU MODÈLE MISSION (`TypeId 1`)

| Index `@HiveField` | Nom du Champ | Type | Valeur par défaut | Description & Rôle |
|---|---|---|---|---|
| `47` | `recepteurRapport` | `String?` | `null` | Destinataire du rapport (champ texte libre historique) |
| `48` | `lieuIntervention` | `String?` | `null` | Lieu précis de l'intervention ou du site |
| `49` | `recepteurCivilite` | `String?` | `null` | Civilité normalisée (`Monsieur`, `Madame`, etc.) |
| `50` | `recepteurNom` | `String?` | `null` | Nom et prénom du destinataire |
| `51` | `recepteurFonction` | `String?` | `null` | Fonction officielle (ex: `Directeur Technique`) |
| `52` | `recepteurEmail` | `String?` | `null` | Adresse email du destinataire |
| `53` | `recepteurTelephone` | `String?` | `null` | Numéro de téléphone du destinataire |
| `54` | `docRapportQ18` | `bool` | `false` | Activation de la génération du rapport thermographique Q18 |
| `55` | `centralePhotovoltaique` | `String?` | `'sans_objet'` | Présence centrale PV (`sans_objet`, `sans_stockage`, `avec_stockage`) |
| `56` | `qrCodeQ18` | `String?` | `null` | Chemin local de l'image QR Code dédiée au rapport Q18 |

