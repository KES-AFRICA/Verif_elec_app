# 02_DOMAIN_AND_DATA_MODEL.md — Modèle Métier Électrique & Entités

> **Module** : KES Inspection App — Pilier 2  
> **Dernière révision** : 27 Septembre 2026  
> **Source de vérité** : `lib/models/`, `lib/services/equipment_number_service.dart`, `lib/services/dispositions_constructives_registry.dart`, `lib/services/pdf/builders/pdf_cover_builder.dart`

---

## 1. HIÉRARCHIE MÉTIER CANONIQUE DU PROJET

L'arborescence des données telle qu'implémentée dans le code source réel est la suivante :

```text
Mission (lib/models/mission.dart)
 │  ├── Métadonnées administratives (Client, Site, Lieu, Adresse, Dates)
 │  ├── Récepteur du rapport unifié (Civilite, Nom, Fonction, Email, Telephone + legacy recepteurRapport)
 │  ├── Classement Réglementaire hiérarchique (Installations classées, IGH, ERP Généraux, ERP Spécialisés)
 │  ├── Options documentaires & Rapports (docRapportQ18, qrCodeClient, qrCodeQ18)
 │  ├── Caractéristiques spéciales du site (centralePhotovoltaique : sans_objet / sans_stockage / avec_stockage)
 │  │
 ├── RenseignementsGénéraux (lib/models/renseignements_generaux.dart)
 │    ├── Données administratives et contacts d'exploitation
 │    ├── Intervenants & Responsables (Inspecteurs, Matricules, DG Responsable, Accompagnateurs)
 │    ├── Habilitations électriques (Titres, Validité, Organisme de formation)
 │    └── Documents d'exploitation collectés (Schémas, Registre sécurité, Plans)
 │
 ├── DescriptionInstallations (lib/models/description_installations.dart)
 │    ├── Caractéristiques d'alimentation MT & BT (Postes, comptages, tensions)
 │    ├── Régimes de Neutre normalisés (TT, TN-C, TN-S, IT)
 │    ├── Sources de remplacement / secours (Groupes électrogènes, onduleurs ASI)
 │    └── Liste des équipements généraux déclarés [InstallationItem]
 │
 ├── AuditInstallationsElectriques (lib/models/audit_installations_electriques.dart)
 │    │
 │    ├── MOYENNE TENSION (HTA)
 │    │    ├── MoyenneTensionLocaux []
 │    │    │    ├── Dispositions constructives [ElementControle]
 │    │    │    ├── Conditions d'exploitation [ElementControle]
 │    │    │    ├── Cellules MT [Cellule] (Arrivée, Protection, Interrupteur, Disjoncteur)
 │    │    │    ├── Transformateurs MT/BT [TransformateurMTBT] (Huile/Sec, Buchholz, DGPT2, UCC)
 │    │    │    └── Coffrets BT situés en local MT [CoffretArmoire]
 │    │    └── MoyenneTensionZones [] -> Locaux MT [], Coffrets []
 │    │
 │    └── BASSE TENSION (BT)
 │         └── BasseTensionZones []
 │              ├── CoffretsDirects [CoffretArmoire]
 │              └── Locaux BT [] (Local TGBT, Local GE, Local Onduleur)
 │                   └── Coffrets [CoffretArmoire]
 │                        ├── Identifiants (equipmentId immuable, numeroEquipement N°)
 │                        ├── Désignation (Nom, Repère, Domaine de tension, Statut)
 │                        ├── Source d'alimentation [Alimentation] (Source identifiée / non identifiée)
 │                        ├── Protection de tête (Disjoncteur, Interdifférentiel, Calibre, Pdc, DDR)
 │                        ├── Départs divisionnaires [DepartEquipement]
 │                        ├── Circuits terminaux [CircuitTerminalEquipement]
 │                        ├── Points de vérification normatifs [PointVerification]
 │                        └── Observations libres [ObservationLibre]
 │
 ├── ClassementZone & ClassementEmplacement (lib/models/classement_locaux.dart, classement_zone.dart)
 │    └── Classification des locaux techniques, influences externes (BE2, incendie, ATEX, poussières)
 │
 ├── Foudre (lib/models/foudre.dart)
 │    └── Paratonnerres PDA, parafoudres de tête/terminaux, compteurs d'orages, conducteurs descente
 │
 ├── MesuresEssais (lib/models/mesures_essais.dart)
 │    ├── PrisesTerre (Mesure Ohms ≤ 100 Ω, barrette de mesure, état des puits)
 │    ├── ContinuitéRésistance (Liaisons équipotentielles masses et conducteurs PE ≤ 2 Ω)
 │    ├── EssaisIsolement (Points de mesure A et B, Phase/Neutre/PE sous 500V/1000V ≥ 0.5 MΩ)
 │    ├── EssaisDéclenchementDifférentiel (Sensibilité assignée IΔn mA, temps de coupure ms)
 │    ├── CpiTests (Contrôleurs permanents d'isolement en schéma IT)
 │    ├── TestsArrêtUrgence (Coupures générales d'urgence ou mention explicite "Absent")
 │    └── EssaisDémarrageAuto (Groupes électrogènes de secours, temps de prise en charge)
 │
 └── JSA (Job Safety Analysis) (lib/models/jsa.dart)
      └── Analyse des risques de chantier, EPI obligatoires, plan de prévention et d'évacuation
```

---

## 2. RÈGLE CRITIQUE D'ISOLATION MT (MOYENNE TENSION) VS BT (BASSE TENSION)

C'est un invariant absolu du moteur métier :
1. **Périmètre MT** : Cellules MT, Transformateurs MT/BT, postes de transformation, locaux MT.
2. **Périmètre BT** : TGBT, Armoires de distribution, Coffrets divisionnaires, Inverseurs, Départs et circuits terminaux.
3. **Cas de l'armoire BT en local MT** :  
   Un équipement BT situé physiquement dans un local MT (ex: coffret d'éclairage ou auxiliaires du poste) **demeure un équipement Basse Tension**. Il est compté dans les métriques BT et jamais dans les indicateurs MT du rapport ou du dashboard.

---

## 3. IDENTIFIANTS TECHNIQUES VS NUMÉROTATION MÉTIER

| Entité | Identifiant Technique Immuable | Identifiant Métier Affiché | Règle de Continuité & Génération |
|---|---|---|---|
| **CoffretArmoire** | `equipmentId` (ex: `equip_1727192837_4829104`) | `numeroEquipement` (ex: `"1"`, `"2"`, `"415"`) | Géré par [EquipmentNumberService](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/equipment_number_service.dart). Séquence entière monotone croissante unique à toute la mission. Rejette les bruits (`400V`, `2024`). |
| **BasseTensionLocal** | `localId` (ex: `local_1727192837_928172`) | `nom` (ex: `"LOCAL TGBT PRINCIPAL"`) | Généré à la création par timestamp + stableHash du nom. |
| **MoyenneTensionLocal** | `localId` | `nom` (ex: `"POSTE LIVRAISON MT 20kV"`) | Idem. |
| **DepartEquipement** | `id` (ex: `dep_legacy_Ecl_16A_Disj_2.5`) | `identification` (ex: `"Départ Éclairage Hall"`) | `_resolveStableDepartId` garantit la stabilité même si la liste est réordonnée. |
| **CircuitTerminalEquipement** | `id` (ex: `ct_legacy_Prises_20A_Disj_2.5`) | `identification` (ex: `"Circuit Prises Bureau 1"`) | `_resolveStableCircuitId`. |
| **Alimentation** | `alimentationId` (ex: `alim_1727192837_8912`) | N/A | Généré à la création ou lors de la première persistance. |

> **Règle Absolue** : Ne JAMAIS utiliser l'index d'une liste (`list[index]`) comme clé technique ou pour résoudre une relation entre deux équipements.

---

## 4. GLOSSAIRE MÉTIER ÉLECTROTECHNIQUE & FONCTIONNEL

- **Cellule MT** : Enveloppe métallique blindée contenant les organes de coupure et de protection HTA (interrupteur, disjoncteur à vide/SF6, fusibles combinés, sectionneur de terre). Modèle : [Cellule](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/models/audit_installations_electriques.dart#L485-L650).
- **Transformateur MT/BT** : Appareil abaisseur de tension (ex: 20 kV / 400 V). Deux technologies : Immergé dans l'huile diélectrique (protégé par relais Buchholz ou DGPT2) ou Sec enrobé. Modèle : [TransformateurMTBT](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/models/audit_installations_electriques.dart#L750-L950).
- **TGBT (Tableau Général Basse Tension)** : Point central de distribution BT aval transformateur ou groupe électrogène.
- **Inverseur de Source** : Organe permettant de commuter l'alimentation d'un jeu de barres entre la source normale (Réseau/Transfo) et la source de secours (Groupe électrogène). Modélisé dans `CoffretArmoire` avec `type == 'INVERSEUR'`, doté de 2 entrées (`alimentationsInverseurEntree`) et de sorties dédiées (`sortiesInverseur`).
- **Départ** : Circuit divisionnaire issu des barres d'un tableau pour alimenter un sous-tableau ou une charge importante. Modèle : [DepartEquipement](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/models/audit_installations_electriques.dart#L1683-L1835).
- **DDR (Dispositif Différentiel Résiduel)** : Organe de protection contre les défauts d'isolement et les contacts indirects, caractérisé par sa sensibilité en courant (30 mA pour locaux humides/prises, 300 mA pour risque incendie, 500 mA ou 1A à 3A temporisé pour sélectivité de tête).
- **Régime de Neutre (Schéma des Liaisons à la Terre - SLT)** :
  - `TT` : Neutre à la terre, masses à la terre. Coupure obligatoire au premier défaut par DDR.
  - `TN-C` / `TN-S` : Neutre à la terre, masses reliées au conducteur de protection (PE/PEN). Coupure par surintensité (disjoncteur/fusible).
  - `IT` : Neutre isolé ou impédant. Non-coupure au premier défaut surveillé par un CPI (Contrôleur Permanent d'Isolement).
