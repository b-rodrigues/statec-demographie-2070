# scripts/04_build_unified_data.R
# Consolidation du jeu de données Tidy unifié (STATEC Observé, STATEC Scénarios 1-4, Eurostat EUROPOP2025)

library(dplyr)
library(tidyr)
library(readr)

message("=== Consolidation du jeu de données unifié ===")

# 1. Trajectoires STATEC
statec_traj <- readRDS("data/statec_trajectories.rds") %>%
  mutate(
    age_group = "Total",
    sex = "Total",
    unit = case_when(
      indicator %in% c("population", "solde_migratoire", "solde_naturel", "accroissement_total", "emploi_total") ~ "personnes",
      indicator == "taux_croissance_annuel" ~ "%",
      TRUE ~ "indice"
    )
  )

# 2. Eurostat EUROPOP2025
eurostat_ind <- readRDS("data/eurostat_indicators.rds") %>%
  filter(indicator %in% c("population", "solde_migratoire", "solde_naturel", "accroissement_total",
                          "ratio_dependance_65_20_64", "ratio_dependance_65_15_64", "age_median")) %>%
  mutate(
    age_group = "Total",
    sex = "Total",
    unit = case_when(
      indicator %in% c("population", "solde_migratoire", "solde_naturel", "accroissement_total") ~ "personnes",
      indicator %in% c("ratio_dependance_65_20_64", "ratio_dependance_65_15_64") ~ "%",
      indicator == "age_median" ~ "années",
      TRUE ~ "indice"
    ),
    data_type = "projected"
  )

# 3. Tableau 4 STATEC indicateurs transversaux 2070
tableau_4 <- readRDS("data/statec_scenarios_summary.rds")
t4_long <- tableau_4 %>%
  pivot_longer(
    cols = c(pib_growth_pct, prod_growth_pct, emp_growth_pct, wage_ratio_ppa_pct,
             national_employment_2070, crossborder_employment_2070, old_age_dep_ratio_65_20_64),
    names_to = "indicator",
    values_to = "value"
  ) %>%
  mutate(
    year = 2070,
    source = "STATEC (Analyses 02/26)",
    age_group = "Total",
    sex = "Total",
    unit = case_when(
      indicator %in% c("national_employment_2070", "crossborder_employment_2070") ~ "personnes",
      indicator == "wage_ratio_ppa_pct" ~ "% (PPA)",
      TRUE ~ "%"
    ),
    data_type = "projected"
  ) %>%
  select(year, source, scenario_id, scenario_name, indicator, age_group, sex, value, unit, data_type)

# Fusion globale
unified_clean <- bind_rows(
  statec_traj %>% select(year, source, scenario_id, scenario_name, indicator, age_group, sex, value, unit, data_type),
  eurostat_ind %>% select(year, source, scenario_id, scenario_name, indicator, age_group, sex, value, unit, data_type),
  t4_long
) %>%
  arrange(indicator, scenario_id, year)

saveRDS(unified_clean, "data/projections_clean.rds")
write_csv(unified_clean, "data/projections_clean.csv")

message("-> Jeu de données consolidé data/projections_clean.rds sauvegardé (", nrow(unified_clean), " lignes)")
