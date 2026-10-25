# R/calculations.R
# Fonctions de calcul, formatage français et analyses comparatives

library(dplyr)
library(scales)

# Formatage des nombres à la française (espace pour les milliers, virgule pour les décimales)
format_fr <- function(x, digits = 0) {
  if (is.null(x) || length(x) == 0 || all(is.na(x))) return("-")
  format(round(x, digits), big.mark = " ", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

format_pct <- function(x, digits = 1) {
  if (is.null(x) || length(x) == 0 || all(is.na(x))) return("-")
  paste0(format(round(x, digits), decimal.mark = ",", trim = TRUE), " %")
}

# Calcul des KPI de l'onglet 1 pour une année donnée
get_headline_kpi <- function(data, target_year = 2070) {
  # Population observée la plus récente (2025)
  obs_2025 <- data$hist_pop %>%
    filter(year == 2025, sex == "Total") %>%
    pull(population)
  if (length(obs_2025) == 0) obs_2025 <- 690959
  
  if (target_year == 2070) {
    s_sc1 <- data$summary_scenarios %>% filter(scenario_id == "SC1")
    s_sc4 <- data$summary_scenarios %>% filter(scenario_id == "SC4")
    
    pop_min <- s_sc1$population_2070
    pop_max <- s_sc4$population_2070
    mig_min <- s_sc1$net_migration_2070
    mig_max <- s_sc4$net_migration_2070
    dep_min <- s_sc4$old_age_dep_ratio_65_20_64
    dep_max <- s_sc1$old_age_dep_ratio_65_20_64
    age_m_min <- 46.1
    age_m_max <- 47.9
  } else {
    traj_yr <- data$trajectories %>%
      filter(indicator == "population", year == target_year, scenario_id %in% c("SC1", "SC2", "SC3", "SC4"))
    pop_min <- min(traj_yr$value, na.rm = TRUE)
    pop_max <- max(traj_yr$value, na.rm = TRUE)
    
    mig_yr <- data$trajectories %>%
      filter(indicator == "solde_migratoire", year == target_year, scenario_id %in% c("SC1", "SC2", "SC3", "SC4"))
    mig_min <- min(mig_yr$value, na.rm = TRUE)
    mig_max <- max(mig_yr$value, na.rm = TRUE)
    
    m_yr <- data$milestones %>% filter(year == target_year)
    dep_min <- min(m_yr$ratio_dependance_65_20_64, na.rm = TRUE)
    dep_max <- max(m_yr$ratio_dependance_65_20_64, na.rm = TRUE)
    age_m_min <- min(m_yr$age_moyen, na.rm = TRUE)
    age_m_max <- max(m_yr$age_moyen, na.rm = TRUE)
  }
  
  list(
    obs_pop_2025 = obs_2025,
    target_year = target_year,
    pop_min = pop_min,
    pop_max = pop_max,
    pop_gap_abs = pop_max - pop_min,
    pop_gap_pct = (pop_max - pop_min) / pop_min * 100,
    growth_since_2025_min = (pop_min - obs_2025) / obs_2025 * 100,
    growth_since_2025_max = (pop_max - obs_2025) / obs_2025 * 100,
    mig_min = mig_min,
    mig_max = mig_max,
    dep_min = dep_min,
    dep_max = dep_max,
    age_m_min = age_m_min,
    age_m_max = age_m_max
  )
}

# Tableau comparatif des écarts entre scénarios STATEC et Eurostat pour les années jalons
get_comparison_table <- function(data) {
  # STATEC
  st_pop <- data$trajectories %>%
    filter(indicator == "population", year %in% c(2025, 2030, 2040, 2050, 2060, 2070)) %>%
    filter(scenario_id %in% c("SC1", "SC2", "SC3", "SC4")) %>%
    select(year, scenario_id, value) %>%
    tidyr::pivot_wider(names_from = scenario_id, values_from = value)
  
  # Eurostat
  es_pop <- data$eurostat_ind %>%
    filter(indicator == "population", year %in% c(2025, 2030, 2040, 2050, 2060, 2070)) %>%
    select(year, EUROPOP2025 = value)
  
  comp <- st_pop %>%
    inner_join(es_pop, by = "year") %>%
    mutate(
      ecart_sc1_eurostat = SC1 - EUROPOP2025,
      ecart_sc4_eurostat = SC4 - EUROPOP2025,
      ecart_sc4_sc1 = SC4 - SC1
    ) %>%
    arrange(year)
  
  comp
}
