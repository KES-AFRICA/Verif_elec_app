# 04_REPORTING_AND_STATISTICS.md — Reporting Multi-Format & Moteurs Statistiques

> **Module** : KES Inspection App — Pilier 4  
> **Dernière révision** : 27 Septembre 2026  
> **Source de vérité** : `lib/services/pdf/`, `lib/services/pdf/q18/`, `lib/services/excel/`, `lib/services/word_report_service.dart`, `lib/services/statistics/`

---

## 1. ARCHITECTURE PDF V3 (MOTEUR PAR MICRO-LOTS À 2-PASSES)

Fichier orchestrateur : [lib/services/pdf/pdf_report_service.dart](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/pdf/pdf_report_service.dart#L3569-L3742)

Pour éliminer définitivement les crashs mémoire (Out-Of-Memory) lors de l'édition de rapports d'usines lourdes (100+ pages, 300+ photographies haute résolution), la génération PDF est découpeé en micro-lots indépendants assemblés par fusion binaire.

```text
                                  DEMANDE DE GÉNÉRATION PDF
                                              │
                      ┌───────────────────────┴───────────────────────┐
                      ▼                                               ▼
         PASSE 1 : PRE-FLIGHT EN MÉMOIRE             PASSE 2 : ÉCRITURE SUR DISQUE (CHUNKS)
         - Construit le Sommaire dynamique           - Injecte overrideTotalPages = totalReportPages
           pour calculer son encombrement réel       - Chaque builder écrit son fichier .pdf temporaire
         - Parcourt tous les chunks avec             - Footer : Page (pageNumber + offset) / totalReportPages
           l'offset cumulé                           - Micro-lots photos max 3 pages par lot (Anti-OOM)
         - Enregistre trackedPages[key]                               │
                      │                                               ▼
                      └─────────────────────────────────► FUSION BINAIRE HAUTE PERFORMANCE
                                                          - PdfMergerService.mergePdfFiles()
                                                          - Assemblage séquentiel direct sans ré-encodage
                                                          - Nettoyage final des fichiers temporaires
```

### Registre des 13 Builders Spécialisés (`lib/services/pdf/builders/`)
1. **`PdfCoverBuilder`** : Page de garde officielle KES, intervenants, client, site, date de mission. Intègre `resolveRecepteurInfo` pour la résolution dynamique centralisée.
2. **`PdfSommaireBuilder`** : Sommaire dynamique multi-pages synchronisé avec la table `trackedPages`.
3. **`PdfRegulatoryBuilder`** : Cadre réglementaire, textes de lois, appareils de mesures étalonnés.
4. **`PdfExecutiveSummaryBuilder`** : Synthèse exécutive, criticité globale du site, facteurs clés.
5. **`PdfStatisticsBuilder`** : Histogrammes et courbe de Pareto déterministes.
6. **`PdfRenseignementsBuilder`** : Tableaux des renseignements administratifs et techniques.
7. **`PdfDescriptionBuilder`** : Description générale MT/BT, postes, régimes de neutre, groupes de secours.
8. **`PdfEquipementsSynthesisBuilder`** : Tableaux unifiés des équipements MT et BT (12 colonnes standardisées).
9. **`PdfObservationsRecapBuilder`** : Liste récapitulative des non-conformités sous forme de cartes d'équipements fermées.
10. **`PdfAuditInstallationsBuilder`** : Grilles détaillées par local, zone et coffret.
11. **`PdfClassementFoudreBuilder`** : Fiches de classement des locaux à risques (BE2, ATEX) et audit foudre.
12. **`PdfMesuresEssaisBuilder`** : Tableaux paysage des mesures physiques (Terre, continuités, isolement, DDR).
13. **`PdfPhotosSchemasBuilder`** : Planches de photos probantes et schémas unifilaires.
14. **`PdfFinalPageBuilder`** : Page de clôture, signatures, cachets et coordonnées KES.

---

## 2. MOTEUR DU RAPPORT RÉGLEMENTAIRE Q18 (APSAD D18 V1)

Fichier orchestrateur : [lib/services/pdf/q18/pdf_q18_report_service.dart](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/pdf/q18/pdf_q18_report_service.dart)  
Emplacement : `lib/services/pdf/q18/`

Le rapport Q18 atteste de la conformité des installations au regard du risque d'incendie et d'explosion selon le Traité de prévention des risques **APSAD D18**.

### Architecture & Pipeline d'Exécution
1. **Collecte & Snapshot Certifié (`Q18DataCollector`)** :  
   Produit un objet immuable `Q18DataSnapshot` agrégeant les données de Mission, Audit, Description, Mesures et Renseignements Généraux.
2. **Classification Déterministe des Dangers (`_mapFindingToQ18Level`)** :  
   - `Danger avéré` : Anomalies critiques ou risques avérés d'échauffement / incendie / défaut d'isolement.
   - `Dégradation` : Anomalies modérées à surveiller.
   - `Hors périmètre` : Non-conformités réglementaires hors scope direct incendie D18.
   - `Point sensible` : Recommandations d'exploitation et maintenance.
3. **Les 7 Builders Spécialisés Q18 (`lib/services/pdf/q18/builders/`)** :  
   - `Q18IdentificationBuilder` : Section 1 (Identification de la mission, 10 rubriques) et Section 4 (Présentation du site & installations : 4.1 alimentation/postes, 4.2 inventaire des armoires).
   - `Q18RegulatoryBuilder` : Section 2 (Objet et cadre), Section 3 (Cadre réglementaire & 8 textes), Section 7 (Méthodologie & 9 points de vérification), Section 8 (Classification des dangers), Section 9 (Typologie des dangers & 9 familles).
   - `Q18PerimetreBuilder` : Section 5 (Périmètre & limites de la mission, 4 colonnes), Section 6 (Documents consultés & 6 pièces justificatives dont rapport Q18 précédent).
   - `Q18DangersSynthesisBuilder` : Section 10 (Synthèse hiérarchique 4-niveaux Zone -> Local -> Équipement -> Constats), Section 11 (Récapitulatif statistique 3 colonnes).
   - `Q18ConclusionBuilder` : Section 12 (Avis global & conditions exclusives Cas n°1 vs Cas n°2), Section 13 (Conditions de levée), Section 14 (Prochaine échéance), Section 15 (Visa & signature avec gestion singulier/pluriel et "Fait à [Lieu]").
   - `Q18PhotosBuilder` : Section 16 (Planche photographique avec badges de niveau D18).
4. **Stratégie Haute Performance Anti-OOM (Preflight Zero-Load & Compression)** :  
   - **Passe Preflight** : Les widgets de la planche photos sont mesurés avec `isPreflight: true` sans charger aucune image en mémoire (Zero-Load), garantissant une réactivité immédiate du dialogue et prévenant les OOM.
   - **Compression Adaptative Préliminaire** : `_prepareCompressedPhotos` compresse toutes les photos par lots hors du thread UI avant la Passe 2. La taille finale du PDF est ainsi divisée par 4 ou plus (ex: de 18 Mo à moins de 4 Mo pour 47 pages).
5. **Page de Garde Unifiée avec Verif Elec** :  
   - En-tête supérieur droit : `CLIENT`, Nom client en majuscules, `A l'attention de [Civilité]`, `[FONCTION EN MAJUSCULES]`.
   - Résolution partagée via `PdfCoverBuilder.resolveRecepteurInfo(mission: mission, rg: rg)` avec support de la saisie libre, extraction des préfixes (`M.`, `Monsieur`, `Mme`, `Madame`) et repli automatique.
   - Tableau inférieur 5 colonnes identique avec affichage du **Numéro de rapport Q18** (`data.numeroRapportQ18`).
   - Encart QR Code 70x70 pt avec rendu prioritaire de `mission.qrCodeQ18`.

---

## 2. GÉNÉRATION EXCEL (`ExcelReportService`)

Fichier source : [lib/services/excel/excel_report_service.dart](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/excel/excel_report_service.dart)  
Moteur : **Syncfusion Flutter XlsIO**.

Le classeur produit contient **2 feuilles normalisées** qui partagent rigoureusement les mêmes métriques et le même filtrage que le rapport PDF :
- **Feuille 1 : « Annexe des équipements »**  
  Tableau unifié de 12 colonnes : `Zone | Repère | N° | Désignation | Type | Départs issus | Vérifié | Présence du parafoudre | Vérification thermo | Observation | Date de réserve | Date de rapport`.
- **Feuille 2 : « Annexe des observations »**  
  Tableau exhaustif de toutes les non-conformités constatées, classées par sévérité, localisation, référence normative et priorité.

---

## 3. GÉNÉRATION WORD (`WordReportService`)

Fichier source : [lib/services/word_report_service.dart](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/word_report_service.dart)  
Moteur : **`docs_gee`** (génération native OOXML `.docx`).

Produit un document Word structuré reprenant l'intégralité des sections du rapport avec styles typographiques aux couleurs KES (Bleu KES `#1E3A8A`, Bleu d'accent `#2563EB`, alternance zébrée `#F8FAFC`).

---

## 4. MOTEURS STATISTIQUES DÉTERMINISTES (`lib/services/statistics/`)

Le reporting et le tableau de bord de l'application s'appuient sur **16 moteurs déterministes** éliminant toute variation aléatoire :

### 1. Analyse Pareto sur les 10 Catégories Canoniques de Défauts
Classement décroissant des anomalies pour identifier les 20 % de causes générant 80 % des risques :
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

### 2. Répartition selon les 5 Familles Canoniques de Risques
1. `Erreur d'exploitation / maintenance`
2. `Électrisation / électrocution`
3. `Dégradation des canalisations et matériels`
4. `Surintensité / court-circuit`
5. `Échauffement / surcharge / risque d'incendie`

### 3. Isolation Absolue MT / BT dans les Statistiques
- Le dénominateur MT comprend uniquement les entités MT (Locaux MT, Cellules, Transfos).
- Le dénominateur BT comprend uniquement les entités BT (TGBT, Armoires, Coffrets, Inverseurs, Départs).
- Tout équipement BT localisé dans un poste MT est comptabilisé exclusivement dans la population BT.
