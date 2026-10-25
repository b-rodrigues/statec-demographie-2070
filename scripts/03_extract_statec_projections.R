# scripts/03_extract_statec_projections.R
# Structuration des projections officielles du STATEC (Analyses 02/26)

library(dplyr)
library(tidyr)
library(readr)

message("=== [1/4] Structuration du Tableau 4 (Résumé officiel des 4 scénarios en 2070) ===")

tableau_4 <- tibble(
  scenario_id = c("SC1", "SC2", "SC3", "SC4"),
  scenario_name = c(
    "Scénario 1 : Faible productivité, faible investissement",
    "Scénario 2 : Faible productivité, fort investissement",
    "Scénario 3 : Forte productivité, faible investissement",
    "Scénario 4 : Forte productivité, fort investissement"
  ),
  ptf_growth = c(0.0, 0.0, 0.8, 0.8), # Progrès technique (%)
  investment_rate = c("Faible (16%)", "Fort (20%)", "Faible (16%)", "Fort (20%)"),
  pib_growth_pct = c(0.80, 1.10, 1.80, 2.20), # Croissance potentielle PIB moy 2025-2070
  prod_growth_pct = c(0.40, 0.60, 1.10, 1.30), # Croissance productivité moy 2025-2070
  emp_growth_pct = c(0.80, 0.90, 1.10, 1.30), # Croissance emploi moy 2025-2070
  wage_ratio_ppa_pct = c(109, 118, 142, 152), # Ratio salaire PPA en 2070
  net_migration_2070 = c(3284, 3692, 6084, 7454), # Solde migratoire en 2070
  national_employment_2070 = c(338074, 349117, 378616, 401296),
  crossborder_employment_2070 = c(397407, 421673, 476589, 525466),
  total_employment_2070 = c(735481, 770790, 855205, 926762),
  population_2070 = c(944039, 966018, 1022428, 1066516), # Population totale 2070
  old_age_dep_ratio_65_20_64 = c(58, 56, 52, 49) # Ratio dépendance (65+/20-64) en 2070 (%)
)

saveRDS(tableau_4, "data/statec_scenarios_summary.rds")
write_csv(tableau_4, "data/statec_scenarios_summary.csv")
message("-> statec_scenarios_summary.rds sauvegardé")

message("=== [2/4] Structuration des Tableaux 2 et 3 (Âge moyen et dépendance 2025-2070) ===")

tableau_2_age_moyen <- tibble(
  scenario_id = rep(c("SC1", "SC2", "SC3", "SC4"), each = 6),
  year = rep(c(2025, 2030, 2040, 2050, 2060, 2070), times = 4),
  age_moyen = c(
    # SC1
    40.1, 41.0, 42.8, 44.9, 46.6, 47.9,
    # SC2
    40.1, 41.0, 42.7, 44.7, 46.3, 47.6,
    # SC3
    40.1, 41.0, 42.7, 44.5, 45.8, 46.7,
    # SC4
    40.1, 41.0, 42.6, 44.3, 45.4, 46.1
  )
)

tableau_3_dependance <- tibble(
  scenario_id = rep(c("SC1", "SC2", "SC3", "SC4"), each = 6),
  year = rep(c(2025, 2030, 2040, 2050, 2060, 2070), times = 4),
  ratio_dependance_65_20_64 = c(
    # SC1
    24, 27, 33, 40, 49, 58,
    # SC2
    24, 27, 33, 39, 48, 56,
    # SC3
    24, 27, 33, 38, 46, 52,
    # SC4
    24, 27, 33, 38, 44, 49
  )
)

milestones_indicators <- tableau_2_age_moyen %>%
  inner_join(tableau_3_dependance, by = c("scenario_id", "year"))

saveRDS(milestones_indicators, "data/statec_milestones_indicators.rds")
write_csv(milestones_indicators, "data/statec_milestones_indicators.csv")
message("-> statec_milestones_indicators.rds sauvegardé")

message("=== [3/4] Trajectoires annuelles calibrées 2000-2070 ===")

# Importer les trajectoires extraites par Python
raw_traj <- read_csv("data/statec_extracted_trajectories.csv", show_col_types = FALSE)

# Compléter avec l'historique LUSTAT officiel pour 2000-2025
hist_pop <- readRDS("data/historical_population.rds") %>%
  filter(sex == "Total", year >= 2000, year <= 2025) %>%
  mutate(
    scenario_id = "OBS",
    scenario_name = "Observé (STATEC LUSTAT)",
    indicator = "population",
    value = population,
    data_type = "observed"
  ) %>%
  select(year, scenario_id, scenario_name, indicator, value, data_type)

hist_comp <- readRDS("data/historical_components.rds") %>%
  filter(year >= 2000, year <= 2025, indicator %in% c("solde_migratoire", "solde_naturel", "accroissement_total")) %>%
  mutate(
    scenario_id = "OBS",
    scenario_name = "Observé (STATEC LUSTAT)",
    data_type = "observed"
  ) %>%
  select(year, scenario_id, scenario_name, indicator, value, data_type)

# Trajectoires projetées :
# Pour assurer une continuité parfaite de chaque scénario depuis 2025 jusqu'en 2070 :
# Les années 2026-2028 (projection moyen terme commune à tous les scénarios) sont intégrées à chaque scénario.
mt_common <- raw_traj %>%
  filter(scenario_id == "OBS_MT", year >= 2026, year <= 2028)

proj_scenarios <- raw_traj %>%
  filter(scenario_id %in% c("SC1", "SC2", "SC3", "SC4"))

# Ajouter les points 2026-2028 à chaque scénario s'ils démarrent en 2029
expanded_scenarios <- bind_rows(
  lapply(c("SC1", "SC2", "SC3", "SC4"), function(sid) {
    sname <- case_when(
      sid == "SC1" ~ "Scénario 1 : Faible productivité, faible investissement",
      sid == "SC2" ~ "Scénario 2 : Faible productivité, fort investissement",
      sid == "SC3" ~ "Scénario 3 : Forte productivité, faible investissement",
      sid == "SC4" ~ "Scénario 4 : Forte productivité, fort investissement"
    )
    mt_for_s <- mt_common %>%
      mutate(scenario_id = sid, scenario_name = sname)
    bind_rows(mt_for_s, proj_scenarios %>% filter(scenario_id == sid)) %>%
      distinct(year, indicator, .keep_all = TRUE)
  })
) %>%
  mutate(
    source = "STATEC (Analyses 02/26)",
    data_type = "projected"
  )

# Calcul du solde naturel pour les scénarios projetés :
# Solde naturel = Accroissement de la population - Solde migratoire
proj_pop <- expanded_scenarios %>% filter(indicator == "population")
proj_mig <- expanded_scenarios %>% filter(indicator == "solde_migratoire")

# Pour calculer l'accroissement 2026 sans valeur manquante, on inclut le point 2025 dans le calcul du lag :
pop_2025_val <- hist_pop %>% filter(year == 2025) %>% pull(value)

proj_natural <- proj_pop %>%
  arrange(scenario_id, year) %>%
  group_by(scenario_id) %>%
  mutate(
    prev_val = lag(value, default = pop_2025_val),
    accroissement_total = value - prev_val
  ) %>%
  ungroup() %>%
  inner_join(proj_mig %>% select(year, scenario_id, solde_migratoire = value), by = c("year", "scenario_id")) %>%
  mutate(
    solde_naturel = accroissement_total - solde_migratoire
  ) %>%
  select(year, scenario_id, scenario_name, solde_naturel, accroissement_total) %>%
  pivot_longer(cols = c(solde_naturel, accroissement_total), names_to = "indicator", values_to = "value") %>%
  filter(!is.na(value)) %>%
  mutate(source = "STATEC (Analyses 02/26)", data_type = "projected")

# Assemblage des trajectoires
statec_trajectories <- bind_rows(
  hist_pop %>% mutate(source = "STATEC (Observé)"),
  hist_comp %>% mutate(source = "STATEC (Observé)"),
  expanded_scenarios,
  proj_natural
) %>%
  arrange(indicator, scenario_id, year)

saveRDS(statec_trajectories, "data/statec_trajectories.rds")
write_csv(statec_trajectories, "data/statec_trajectories.csv")
message("-> statec_trajectories.rds sauvegardé (", nrow(statec_trajectories), " lignes)")

message("=== [4/4] Analyses de sensibilité économiques et démographiques (p. 56 et 67) ===")

sensitivities <- tibble(
  type_sensibilite = c(
    # Économiques Scénario 4
    rep("Économique", 7),
    # Économiques Scénario 1
    rep("Économique", 7),
    # Démographiques Scénario 4
    rep("Démographique", 6),
    # Démographiques Scénario 1
    rep("Démographique", 6)
  ),
  scenario_reference = c(
    rep("Scénario 4 (Forte productivité)", 7),
    rep("Scénario 1 (Faible productivité)", 7),
    rep("Scénario 4 (Forte productivité)", 6),
    rep("Scénario 1 (Faible productivité)", 6)
  ),
  variante = c(
    # Éco SC4
    "Scénario 4 (Référence)", "Hausse du coût de la vie relatif", "Baisse du coût de la vie relatif",
    "1/3 nouveaux trav. résidents", "2/3 nouveaux trav. résidents", "Taux d'activité bas", "Taux d'activité haut",
    # Éco SC1
    "Scénario 1 (Référence)", "Hausse du coût de la vie relatif", "Baisse du coût de la vie relatif",
    "1/3 nouveaux trav. résidents", "2/3 nouveaux trav. résidents", "Taux d'activité bas", "Taux d'activité haut",
    # Démo SC4
    "Scénario 4 (Référence)", "Solde migratoire nul dès 2040", "Fécondité basse", "Fécondité haute", "Mortalité basse", "Mortalité haute",
    # Démo SC1
    "Scénario 1 (Référence)", "Solde migratoire nul dès 2040", "Fécondité basse", "Fécondité haute", "Mortalité basse", "Mortalité haute"
  ),
  pib_growth = c(
    # Éco SC4
    2.2, 1.9, 2.8, 2.3, 2.1, 2.1, 2.3,
    # Éco SC1
    0.8, 0.6, 1.0, 0.9, 0.7, 0.8, 0.9,
    # Démo SC4
    2.2, 1.6, 2.2, 2.3, 2.2, 2.2,
    # Démo SC1
    0.8, 0.4, 0.8, 0.9, 0.8, 0.8
  ),
  prod_growth = c(
    # Éco SC4
    1.3, 1.4, 1.1, 1.3, 1.3, 1.3, 1.2,
    # Éco SC1
    0.4, 0.4, 0.3, 0.4, 0.4, 0.4, 0.4,
    # Démo SC4
    1.3, 1.4, 1.3, 1.3, 1.3, 1.3,
    # Démo SC1
    0.4, 0.5, 0.4, 0.4, 0.4, 0.4
  ),
  emp_growth = c(
    # Éco SC4
    1.3, 0.8, 2.0, 1.4, 1.2, 1.2, 1.5,
    # Éco SC1
    0.8, 0.5, 1.1, 0.9, 0.6, 0.7, 0.9,
    # Démo SC4
    1.3, 0.4, 1.2, 1.4, 1.3, 1.3,
    # Démo SC1
    0.8, 0.2, 0.7, 0.8, 0.8, 0.8
  ),
  wage_ratio_ppa = c(
    # Éco SC4
    152, 105, 193, 152, 153, 153, 152,
    # Éco SC1
    108.7, 73.0, 140.0, 109.0, 109.0, 109.0, 109.0,
    # Démo SC4
    152, 159, 153, 152, 152, 152,
    # Démo SC1
    108.7, 109.5, 109.0, 108.4, 108.7, 108.7
  ),
  net_migration_2070 = c(
    # Éco SC4
    7454, 4174, 13356, 7057, 7874, 9793, 5982,
    # Éco SC1
    3284, 2724, 4622, 3156, 3429, 3733, 2761,
    # Démo SC4
    7454, 0, 7218, 7782, 7462, 7482,
    # Démo SC1
    3284, 0, 3210, 3389, 3287, 3293
  ),
  population_2070 = c(
    # Éco SC4
    1066516, 975305, 1205150, 1058503, 1076971, 1178459, 970387,
    # Éco SC1
    944039, 910157, 996038, 940873, 948534, 1002530, 878142,
    # Démo SC4
    1066516, 720371, 998788, 1166108, 1088262, 1014004,
    # Démo SC1
    944039, 720371, 884616, 1031778, 965494, 891632
  ),
  old_age_dep_ratio = c(
    # Éco SC4
    49, 55, 43, 50, 49, 45, 54,
    # Éco SC1
    58, 60, 54, 58, 57, 55, 61,
    # Démo SC4
    49, 80, 51, 47, 53, 41,
    # Démo SC1
    58, 80, 60, 55, 61, 48
  )
)

saveRDS(sensitivities, "data/statec_sensitivities.rds")
write_csv(sensitivities, "data/statec_sensitivities.csv")
message("-> statec_sensitivities.rds sauvegardé (", nrow(sensitivities), " variantes)")

message("Extraction et structuration des projections STATEC terminées !")
