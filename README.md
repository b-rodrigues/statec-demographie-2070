# STATEC — Projections démographiques du Luxembourg à l'horizon 2070

[![Licence: EUPL v1.2 FR](https://img.shields.io/badge/Licence-EUPL%20v1.2%20FR-blue.svg)](LICENSE)
[![R: Shiny](https://img.shields.io/badge/R-Shiny%20%7C%20bslib%20%7C%20plotly-1e3a8a.svg)](app.R)
[![Nix Flake](https://img.shields.io/badge/Nix-Flake%20Ready-7e57c2.svg)](flake.nix)

Application R Shiny interactive dédiée à l'exploration des projections démographiques et économiques de long terme du Luxembourg à l'horizon 2070, fondées sur la publication officielle du STATEC :

> **STATEC Analyses 02/26** — *Projections démographiques du Luxembourg : Vers un million d'habitants d'ici 2070*, par Gabriel Gomes et François Peltier (2026).

---

## 1. Objectifs du tableau de bord

Le tableau de bord permet aux décideurs publics, journalistes, chercheurs, étudiants et citoyens d'appréhender de manière visuelle et interactive les enjeux cruciaux du Luxembourg d'ici 2070 :
- **Un million d'habitants d'ici 2070 ?** Explorer comment différentes hypothèses de productivité et d'investissement mènent à une population comprise entre 944 000 et 1 067 000 habitants.
- **Rôle central de la migration :** Comprendre pourquoi la migration est le moteur quasi-exclusif de la croissance démographique à long terme, en particulier dès 2050 lorsque le solde naturel devient négatif.
- **Vieillissement inévitable :** Analyser le triplement de la population des seniors (65 ans et plus) et l'évolution du ratio de dépendance (49 % à 58 %).
- **Comparaison STATEC vs Eurostat :** Visualiser comment et pourquoi deux institutions officielles aboutissent à des profils démographiques différents (modélisation économique endogène vs extrapolation tendancielle).

---

## 2. Structure du projet

```text
statec-demographie-2070/
├── app.R                             # Application Shiny principale (en français)
├── flake.nix                         # Environnement de développement reproductible Nix Flake
├── flake.lock                        # Verrouillage exact des dépendances logicielles
├── LICENSE                           # Licence Publique de l'Union Européenne (EUPL v1.2 FR)
├── README.md                         # Documentation générale et guide d'exécution
├── DICTIONNAIRE_DONNEES.md           # Dictionnaire exhaustif des variables et indicateurs
├── scripts/                          # Scripts reproductibles d'acquisition et de traitement
│   ├── 01_fetch_lustat.R             # Téléchargement API SDMX LUSTAT (historique officiel)
│   ├── 02_fetch_eurostat.R           # Téléchargement API Eurostat EUROPOP2025 (proj_25n)
│   ├── 03_extract_statec_projections.R # Structuration des tableaux et trajectoires du rapport
│   ├── 04_build_unified_data.R       # Assemblage du dataset Tidy unifié (data/projections_clean.rds)
│   └── extract_svg_trajectories.py   # Extraction vectorielle haute précision des courbes InDesign
├── data/                             # Données brutes et jeux de données nettoyés
│   ├── projections_clean.rds / .csv  # Dataset unifié Tidy pour l'application
│   ├── statec_scenarios_summary.rds  # Tableau 4 officiel (synthèse 2070)
│   ├── statec_trajectories.rds       # Séries temporelles complètes (2000-2070)
│   ├── statec_milestones_indicators.rds # Jalons d'âge moyen et de dépendance (Tableaux 2 & 3)
│   ├── statec_sensitivities.rds      # Synthèse des sensibilités économiques et démographiques
│   ├── eurostat_indicators.rds       # Indicateurs officiels EUROPOP2025
│   ├── eurostat_pyramid.rds          # Pyramide des âges par âge simple EUROPOP2025
│   ├── historical_population.rds     # Population historique observée (LUSTAT DF_B1100)
│   ├── historical_components.rds     # Soldes naturel et migratoire historiques (LUSTAT DF_B2103)
│   └── historical_migration_flows.rds# Flux bruts arrivées/départs (LUSTAT DF_B2400)
├── R/                                # Modules de l'application Shiny
│   ├── load_data.R                   # Fonctions de chargement et mise en cache
│   ├── calculations.R                # Calculs d'écarts, taux de croissance et formatage français
│   └── charts.R                      # Fonctions de visualisation interactive Plotly
└── tests/                            # Tests automatisés avec testthat
    ├── test_data_integrity.R         # Tests d'intégrité, de conformité des totaux et des sources
    └── test_shiny_server.R           # Tests de bon fonctionnement du serveur Shiny
```

---

## 3. Installation et exécution

### A. Avec Nix (recommandé pour une reproductibilité absolue)

Le projet dispose d'un environnement Nix complet comprenant R 4.4+, toutes les bibliothèques R nécessaires (`shiny`, `bslib`, `bsicons`, `plotly`, `ggplot2`, `DT`, `dplyr`, `tidyr`, `readr`, `testthat`, `rsconnect`, etc.) et les utilitaires système (`poppler-utils`).

1. Entrer dans le shell de développement :
   ```bash
   nix develop
   ```

2. Lancer l'application :
   ```bash
   Rscript -e "shiny::runApp()"
   ```
   L'application s'ouvre localement sur `http://127.0.0.1:port`.

### B. Avec une installation R standard

Installez les packages R requis :
```r
install.packages(c(
  "shiny", "bslib", "bsicons", "plotly", "ggplot2", "DT",
  "dplyr", "tidyr", "readr", "scales", "testthat", "rsconnect"
))
```

Puis lancez :
```r
shiny::runApp()
```

---

## 4. Tests automatisés de conformité

Le projet intègre une suite de **45 tests unitaires et d'intégrité** (`testthat`) qui valident automatiquement :
- L'exactitude des 4 scénarios STATEC par rapport au Tableau 4 du rapport.
- Les populations 2070 (SC1 : 944 039 ; SC2 : 966 018 ; SC3 : 1 022 428 ; SC4 : 1 066 516).
- L'étiquetage distinct des données observées vs projetées.
- La séparation claire entre Eurostat et le STATEC.
- Le bon fonctionnement des réactifs et sorties du serveur Shiny.

Pour exécuter la suite de tests :
```bash
nix develop --command Rscript -e "testthat::test_dir('tests')"
```

---

## 5. Déploiement sur shinyapps.io

Le package `rsconnect` est inclus dans l'environnement. Pour déployer l'application sur [shinyapps.io](https://www.shinyapps.io/) :

```r
library(rsconnect)

# Configurer vos identifiants shinyapps.io
rsconnect::setAccountInfo(
  name = "<VOTRE_COMPTE>",
  token = "<VOTRE_TOKEN>",
  secret = "<VOTRE_SECRET>"
)

# Déployer l'application
rsconnect::deployApp(
  appName = "statec-demographie-2070",
  appFiles = c(
    "app.R",
    "R/load_data.R",
    "R/calculations.R",
    "R/charts.R",
    "data/projections_clean.rds",
    "data/statec_scenarios_summary.rds",
    "data/statec_milestones_indicators.rds",
    "data/statec_trajectories.rds",
    "data/statec_sensitivities.rds",
    "data/eurostat_indicators.rds",
    "data/eurostat_pyramid.rds",
    "data/historical_population.rds",
    "data/historical_components.rds",
    "data/historical_migration_flows.rds",
    "data/historical_pyramid.rds",
    "LICENSE"
  )
)
```

---

## 6. Avertissement méthodologique et intégrité du modèle

Conformément à la déontologie scientifique et aux instructions du STATEC :
1. **Pas de recalcul arbitraire :** Le système complet d'équations macro-économétriques du STATEC (système non-linéaire couplant fonction de Cobb-Douglas, équation de salaires et attractivité en PPA) n'ayant pas été publié sous forme de code ouvert ré-exécutable, l'application se concentre sur l'exploration fidèle de l'ensemble des scénarios et analyses de sensibilité **officiellement publiés et validés**.
2. **Ratio de dépendance démographique :** Ce ratio est calculé sur la base de la population résidente (65+ / 20-64 ans). Il ne prend pas en compte les travailleurs frontaliers non résidents qui cotisent au régime de sécurité sociale luxembourgeois, et ne doit donc pas être interprété comme une mesure directe du déficit ou de la viabilité des retraites.

---

## 7. Licence

Ce projet est publié sous la **Licence Publique de l'Union Européenne v. 1.2 (EUPL v1.2 FR)**.  
Consultez le fichier [`LICENSE`](LICENSE) pour le texte officiel complet en français.
