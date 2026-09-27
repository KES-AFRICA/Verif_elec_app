# 06_ADR_AND_FORENSIC_REGISTER.md — Décisions Architecturales & Registre Forensic

> **Module** : KES Inspection App — Pilier 6  
> **Dernière révision** : 27 Septembre 2026  
> **Source de vérité** : Historique Git, Registre d'erreurs, `test/features/`

---

## 1. REGISTRE DES DÉCISIONS ARCHITECTURALES (ADR)

### ADR-001 — Migration Clean Architecture & Découpage en 3 Couches
- **Date** : Juillet 2026
- **Contexte** : Le code historique couplait directement les widgets Flutter avec les boîtes Hive, rendant les tests unitaires impossibles sans mock complet de la persistance.
- **Décision** : Séparer l'application en modules Feature-First comprenant `domain/` (entités pures, use cases), `data/` (repositories, mappers, sources Hive) et `presentation/` (Riverpod, écrans).
- **Conséquences** : Tests unitaires instantanés et découplés, réactivité via Riverpod, zéro fuite de types Hive dans l'interface.

### ADR-002 — Moteur PDF V3 par Micro-Lots et Découpage 2-Passes
- **Date** : Août 2026
- **Contexte** : Les rapports volumineux (ex. Cimencam, Camrail : 100+ pages, 300+ photos) provoquaient des crashs système par manque de mémoire (Out-Of-Memory) sur les smartphones de terrain.
- **Décision** : Abandonner le document monolithique unique. Mettre en place un pré-calcul en mémoire (Passe 1) pour mesurer exactement le sommaire, générer des tronçons indépendants sur disque (Passe 2) avec injection du total global, puis fusionner via `PdfMergerService`.
- **Conséquences** : Consommation mémoire plafonnée quel que soit le volume de pages, suppression totale des OOM sur le terrain.

### ADR-003 — Refactorisation de `PdfReportService` en Façade & 13 Builders
- **Date** : Septembre 2026
- **Contexte** : `PdfReportService.dart` avait dépassé 21 000 lignes de code, rendant toute maintenance risquée et l'IDE instable.
- **Décision** : Éclater le fichier en 13 builders spécialisés coordonnés par `PdfReportContext` et `PdfReportStyles` dans `lib/services/pdf/builders/`.
- **Conséquences** : Code clair, lisible et testable unitairement, tout en conservant une façade publique inchangée pour le reste de l'application.

### ADR-004 — Centralisation de la Numérotation des Équipements
- **Date** : Septembre 2026
- **Contexte** : Lors de suppressions ou de tris, des doublons ou des trous apparaissaient dans la numérotation des armoires, et des tensions ("400V") ou années ("2024") s'infiltraient dans le compteur séquentiel.
- **Décision** : Créer [EquipmentNumberService](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/equipment_number_service.dart) avec validation numérique stricte (`parseNumericSequence`) et assignation monotone croissante au-delà du maximum existant.
- **Conséquences** : Immuabilité absolue de la numérotation N° à travers toute la mission (locaux MT, zones, BT et brouillons).

### ADR-005 — Moteur de Rapport Q18 APSAD D18 V1 & Preflight Zero-Load
- **Date** : 26-27 Septembre 2026
- **Contexte** : La génération du rapport thermographique Q18 (APSAD D18) intègre jusqu'à 16 sections normatives et un volume massif de photos thermographiques. Le chargement simultané des images en mémoire lors du pré-calcul des pages provoquait des dépassements de mémoire vive (OOM) et des fichiers PDF atteignant 18 Mo.
- **Décision** :
  1. Structurer le moteur [PdfQ18ReportService](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/pdf/q18/pdf_q18_report_service.dart) en 7 builders modulaires dans `lib/services/pdf/q18/builders/`.
  2. Implémenter le pattern **Preflight Zero-Load** dans [Q18PhotosBuilder](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/pdf/q18/builders/q18_photos_builder.dart) : en Passe 1 (`isPreflight: true`), mesurer l'encombrement des pages de photos via des conteneurs factices sans décoder les octets d'images.
  3. Appliquer une compression adaptative des photographies (`_prepareCompressedPhotos` avec seuils 700 Ko / 1200x900 px) avant l'injection en Passe 2.
- **Conséquences** : Consommation mémoire divisée par 4, taille du document final réduite de >75 % (de 18 Mo à moins de 4 Mo), pagination au millimètre sans débordement.

### ADR-006 — Unification de la Couverture PDF & Résolution Centralisée du Récepteur
- **Date** : 27 Septembre 2026
- **Contexte** : Les rapports « Vérification Électrique » et « Q18 » présentaient des formats de page de garde divergents pour le bloc récepteur (civilité, nom, fonction) et l'intégration des QR codes, entraînant des duplications de logique et des inconsistances visuelles.
- **Décision** : Centraliser l'algorithme d'inférence et de formatage du récepteur dans une méthode canonique réutilisable [PdfCoverBuilder.resolveRecepteurInfo](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/pdf/builders/pdf_cover_builder.dart).
  - Épuration des préfixes redondants (`M.`, `Monsieur`, `Mme`).
  - Passage en majuscules strictes (`TOUPPERCASE`) des noms et fonctions.
  - Civilité par défaut (`Monsieur`).
  - Fallback sécurisé en cascade : champs typés de `Mission` -> champ legacy `recepteurRapport` -> boîte `renseignements_generaux`.
  - Support de QR codes dédiés distincts : `qrCodeClient` (rapport Vérif Élec) et `qrCodeQ18` (rapport thermographique Q18).
- **Conséquences** : Uniformité visuelle parfaite entre tous les rapports officiels KES, zéro duplication de code, rétrocompatibilité totale avec les anciennes missions.

---

## 2. REGISTRE DES RISQUES DE RÉGRESSION PAR ZONE SENSIBLE

| Zone Critique | Risque Principal | Cause Potentielle | Mode de Vérification Obligatoire |
|---|---|---|---|
| **Hive / Persistence** | Crash au démarrage ou désérialisation null | Réutilisation d'un `@HiveField` ou non-respect de la nullabilité | `test/features/data_integrity_audit_test.dart` |
| **Équipements & Départs** | Mélange d'équipements ou perte de liaisons amont/aval | Utilisation d'un index de liste au lieu d'`equipmentId` ou `departId` | `test/features/equipment_departures_circuits_forensic_test.dart` |
| **Numérotation N°** | Saut de numérotation ou séquence faussée | Saisie d'une chaîne contenant des chiffres interprétée comme séquence | `test/features/equipment_number_test.dart` |
| **Pagination PDF** | Numéros de page décalés ou faux compteurs locaux | Omission d'`offset` dans `PageTracker` ou usage de `ctx.pagesCount` | `test/features/pdf_report_full_simulation_test.dart` |
| **Moteur Q18 & Photos** | OOM ou décalage de sommaire en micro-lots | Chargement prématuré des photos en Passe 1 ou oubli de Preflight Zero-Load | `test/services/pdf_q18_report_service_test.dart` |
| **Récepteur Couverture** | Bloc récepteur vide ou affichage "null" | Court-circuit des getters ou omission du fallback `RenseignementsGeneraux` | `test/features/mission/recepteur_and_departs_synthesis_test.dart` |
| **Statistiques MT / BT** | Données polluées ou dénominateurs faussés | Inclusion d'un coffret BT situé en local MT dans les statistiques MT | `test/features/mt_bt_equipment_separation_forensic_test.dart` |
| **Import / Export** | Rejet d'une archive valide ou perte de photos | Mauvais calcul du hash SHA-256 ou chemins de photos absolus | `test/features/backup_system_overhaul_test.dart` |

---

## 3. PROBLÈMES CONNUS & PIÈGES FORENSIC RÉSOLUS

### 1. Collision de Timestamps en Microsecondes
- **Symptôme historique** : Deux équipements créés lors d'une boucle rapide de test unitaire recevaient le même identifiant de secours.
- **Cause racine** : `DateTime.now().microsecondsSinceEpoch` peut renvoyer la même valeur sur des itérations exécutées dans le même cycle CPU.
- **Solution définitive** : Combiner systématiquement le timestamp avec une entropie hashée du nom ou de la signature (`stableHash`).

### 2. Piège de l'Offset dans `PageTracker`
- **Symptôme historique** : Dans le sommaire PDF, un chapitre commençant à la page 52 affichait « Page 3 ».
- **Cause racine** : Le builder de ce chapitre n'injectait pas `currentOffset` dans l'instance de `PageTracker`, comptant les pages relativement à son chunk local.
- **Règle absolue** : Tout widget tracé dans le sommaire doit obligatoirement recevoir et appliquer `offset: currentOffset`.

### 3. Piège du Court-Circuit dans la Résolution du Récepteur
- **Symptôme historique** : Sur des missions historiques, la civilité affichait par défaut `Monsieur` mais le nom et la fonction restaient vides même si `recepteurRapport` était renseigné.
- **Cause racine** : Les getters résilients de `Mission` (`effectiveRecepteurCivilite` ou `effectiveRecepteurFonction`) renvoyaient une chaîne non nulle (`'Monsieur'` ou `''`), empêchant l'opérateur `??` de déclencher le fallback vers `recepteurRapport`.
- **Solution définitive** : Dans `PdfCoverBuilder.resolveRecepteurInfo`, tester explicitement si le nom et la fonction issus des champs typés sont vides (`trim().isEmpty`) avant de décider d'exploiter la chaîne `recepteurRapport` ou les données de `RenseignementsGeneraux`.

### 4. OOM et Taille Excessive lors du Rendu Q18 avec 50+ Photos
- **Symptôme historique** : Génération Q18 échouant sur Android ou produisant des PDF de 18 Mo pour quelques dizaines de clichés thermographiques.
- **Cause racine** : La passe 1 de pre-flight décodait et chargeait toutes les images en mémoire, et les clichés étaient injectés dans le PDF sans ré-échantillonnage préalable.
- **Solution définitive** : Pattern **Preflight Zero-Load** (conteneurs virtuels avec layout identique sans décodage d'image en passe 1) + compression asynchrone des photos (`_prepareCompressedPhotos`) plafonnant la résolution à 1200x900 px et la qualité JPEG à 80 %.

### 5. Verrouillage Fichier sous Windows lors des Builds Android
- **Symptôme** : Échec `mergeReleaseNativeLibs` avec `AccessDeniedException` sur des fichiers `.so`.
- **Cause racine** : Processus Gradle ou antivirus maintenant un descripteur de fichier ouvert.
- **Solution** : Toujours exécuter `.\gradlew --stop` dans le dossier `android/` avant de relancer le packaging.
