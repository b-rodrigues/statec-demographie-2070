# Dictionnaire des données — Projections démographiques STATEC 2070

Ce dictionnaire documente chaque variable intégrée dans les jeux de données consolidés (`data/projections_clean.rds` et `data/projections_clean.csv`) ainsi que les tables spécialisées.

Licence : [EUPL v1.2 FR](LICENSE)  
Dernière mise à jour : 25 octobre 2026

---

## 1. Schéma du jeu de données unifié (`data/projections_clean.csv`)

| Champ | Type | Description | Valeurs possibles / Format |
|---|---|---|---|
| `year` | Entier | Année de référence (observée ou projetée) | 1960 à 2070 |
| `source` | Texte | Organisme et publication source | `STATEC (Observé)`, `STATEC (Analyses 02/26)`, `Eurostat (EUROPOP2025)` |
| `scenario_id` | Texte | Identifiant unique du scénario ou de la série | `OBS`, `SC1`, `SC2`, `SC3`, `SC4`, `EUROPOP2025` |
| `scenario_name` | Texte | Intitulé complet et explicite du scénario | Voir section 2 |
| `indicator` | Texte | Code de la variable / indicateur | Voir section 3 |
| `age_group` | Texte | Tranche d'âge concernée | `Total`, `0-14`, `15-64`, `20-64`, `65+`, etc. |
| `sex` | Texte | Sexe | `Total`, `Hommes`, `Femmes` |
| `value` | Numérique | Valeur observée ou projetée | Nombre entier ou décimal |
| `unit` | Texte | Unité de mesure | `personnes`, `%`, `% (PPA)`, `années` |
| `data_type` | Texte | Statut épistémologique de la donnée | `observed` (observé), `medium_term_projection` (moyen terme), `projected` (projection long terme) |

---

## 2. Définition des scénarios officiels

| `scenario_id` | Intitulé officiel | Hypothèse PTF | Taux d'investissement | Hypothèse de salaire relatif PPA en 2070 |
|---|---|---|---|---|
| `OBS` | Observé (STATEC LUSTAT) | - | - | Historique constaté |
| `SC1` | Scénario 1 : Faible productivité, faible investissement | 0,0 % par an | Faible (16 % du PIB) | 108,7 % (érosion de la compétitivité) |
| `SC2` | Scénario 2 : Faible productivité, fort investissement | 0,0 % par an | Fort (20 % du PIB) | 118,0 % |
| `SC3` | Scénario 3 : Forte productivité, faible investissement | 0,8 % par an | Faible (16 % du PIB) | 142,0 % |
| `SC4` | Scénario 4 : Forte productivité, fort investissement | 0,8 % par an | Fort (20 % du PIB) | 152,0 % (avantage salarial préservé) |
| `EUROPOP2025`| Eurostat Baseline (EUROPOP2025) | Exogène | Exogène | Extrapolation tendancielle exogène |

---

## 3. Répertoire des variables et indicateurs

### A. Démographie générale et population
- **`population`** : Population résidente totale au 1er janvier / 31 décembre.  
  *Unité :* personnes.  
  *Sources :* STATEC LUSTAT Table DF_B1100 (historique) ; STATEC Analyses 02/26 Graphique 14 & Tableau 4 (projections).
- **`solde_migratoire`** : Différence annuelle nette entre les arrivées (immigrations) et les départs (émigrations).  
  *Unité :* personnes.  
  *Sources :* STATEC Analyses 02/26 Graphique 13 & Tableau 4 ; Eurostat Table `proj_25ndbi` (`NMIGRAT`).
- **`naissances`** : Nombre annuel de naissances vivantes.  
  *Unité :* personnes.  
  *Sources :* STATEC DF_B2103 (`SL01`) ; Eurostat `proj_25ndbi` (`LBIRTH`).
- **`deces`** : Nombre annuel de décès enregistrés.  
  *Unité :* personnes.  
  *Sources :* STATEC DF_B2103 (`SL02`) ; Eurostat `proj_25ndbi` (`DEATH`).
- **`solde_naturel`** : Excédent naturel (naissances - décès). Devient structurellement négatif à partir de 2050 dans toutes les projections.  
  *Unité :* personnes.
- **`accroissement_total`** : Variation nette de la population résidente sur une année (solde naturel + solde migratoire).  
  *Unité :* personnes.

### B. Structure d'âge et vieillissement
- **`age_moyen`** : Âge moyen de la population résidente.  
  *Unité :* années.  
  *Sources :* STATEC Analyses 02/26 Tableau 2 (p. 32).
- **`age_median`** : Âge médian de la population (50 % de la population a un âge inférieur).  
  *Unité :* années.  
  *Sources :* Eurostat `proj_25ndbi` (`MEDAGEPOP`).
- **`ratio_dependance_65_20_64`** : Ratio de dépendance démographique des personnes âgées, défini comme le rapport entre la population de 65 ans et plus et la population en âge de travailler (20-64 ans) :  
  $$\text{Ratio} = \frac{\text{Pop}_{65+}}{\text{Pop}_{20-64}} \times 100$$  
  *Unité :* %.  
  *Précision méthodologique :* Ce ratio ne comptabilise que les résidents luxembourgeois et exclut les travailleurs frontaliers non résidents qui cotisent au régime de pension luxembourgeois. Il ne constitue donc pas une mesure directe de la soutenabilité financière des pensions.
- **`ratio_dependance_65_15_64`** : Variante internationale Eurostat du ratio de dépendance (65+ / 15-64 ans).  
  *Unité :* %.

### C. Macroéconomie et emploi
- **`pib_growth_pct`** : Taux de croissance annuel moyen du Produit Intérieur Brut (PIB) potentiel sur la période 2025–2070.  
  *Unité :* %.  
  *Sources :* STATEC Analyses 02/26 Tableau 4.
- **`prod_growth_pct`** : Croissance annuelle moyenne de la productivité horaire apparente du travail sur 2025–2070.  
  *Unité :* %.
- **`emp_growth_pct`** : Croissance annuelle moyenne de l'emploi total (résident + frontalier) sur 2025–2070.  
  *Unité :* %.
- **`wage_ratio_ppa_pct`** : Ratio des salaires moyens du Luxembourg par rapport à ses pays limitrophes (Allemagne, Belgique, France), corrigé des parités de pouvoir d'achat (PPA), à l'horizon 2070.  
  *Unité :* % (base 100 = égalité de pouvoir d'achat).
- **`emploi_total`** : Emploi total intérieur sur le territoire luxembourgeois (résidents + frontaliers).  
  *Unité :* personnes.
- **`national_employment_2070`** : Nombre de travailleurs résidents occupant un emploi au Luxembourg en 2070.  
  *Unité :* personnes.
- **`crossborder_employment_2070`** : Nombre de travailleurs frontaliers navetteurs en 2070.  
  *Unité :* personnes.

---

## 4. Variantes de sensibilité officielles (`data/statec_sensitivities.rds`)

Documentées aux pages 56 et 67 du rapport pour les Scénarios 1 et 4 :
- **Sensibilités économiques (p. 56) :**
  - *Hausse du coût de la vie relatif* : Renchérissement plus rapide du coût de la vie au Luxembourg (-47 points de PPA en 2070).
  - *Baisse du coût de la vie relatif* : Amélioration du coût relatif de la vie (+41 points de PPA en 2070).
  - *1/3 de nouveaux travailleurs étrangers résidents* : Réduction de la part des arrivants qui s'installent au Luxembourg.
  - *2/3 de nouveaux travailleurs étrangers résidents* : Augmentation de la part d'installation résidente.
  - *Taux d'activité bas / haut des seniors* : Allongement ou non de la durée de vie active.
- **Sensibilités démographiques (p. 67) :**
  - *Solde migratoire nul à partir de 2040* : Scénario d'arrêt complet de l'immigration nette.
  - *Fécondité basse / haute* : Hypothèse d'ICF en 2070 à 1,30 ou 1,70 enfant par femme (vs 1,50 en variante centrale).
  - *Mortalité basse / haute* : Espérance de vie en 2070 supérieure ou inférieure aux gains tendanciels.
