# tests/test_data_integrity.R
# Tests automatisés d'intégrité et de conformité des données du dashboard STATEC 2070

library(testthat)
library(dplyr)

data_dir <- if (dir.exists("data")) "data" else if (dir.exists("../data")) "../data" else "../../data"

test_that("Tous les 4 scénarios STATEC sont présents avec leurs valeurs exactes en 2070", {
  t4 <- readRDS(file.path(data_dir, "statec_scenarios_summary.rds"))
  expect_equal(nrow(t4), 4)
  expect_setequal(t4$scenario_id, c("SC1", "SC2", "SC3", "SC4"))
  
  # Vérification des populations 2070 officielles (Tableau 4)
  expect_equal(t4$population_2070[t4$scenario_id == "SC1"], 944039)
  expect_equal(t4$population_2070[t4$scenario_id == "SC2"], 966018)
  expect_equal(t4$population_2070[t4$scenario_id == "SC3"], 1022428)
  expect_equal(t4$population_2070[t4$scenario_id == "SC4"], 1066516)
  
  # Vérification des soldes migratoires 2070
  expect_equal(t4$net_migration_2070[t4$scenario_id == "SC1"], 3284)
  expect_equal(t4$net_migration_2070[t4$scenario_id == "SC2"], 3692)
  expect_equal(t4$net_migration_2070[t4$scenario_id == "SC3"], 6084)
  expect_equal(t4$net_migration_2070[t4$scenario_id == "SC4"], 7454)
  
  # Vérification des ratios de dépendance 65+/20-64 en 2070 (%)
  expect_equal(t4$old_age_dep_ratio_65_20_64[t4$scenario_id == "SC1"], 58)
  expect_equal(t4$old_age_dep_ratio_65_20_64[t4$scenario_id == "SC2"], 56)
  expect_equal(t4$old_age_dep_ratio_65_20_64[t4$scenario_id == "SC3"], 52)
  expect_equal(t4$old_age_dep_ratio_65_20_64[t4$scenario_id == "SC4"], 49)
})

test_that("Les jalons d'âge moyen et de ratio de dépendance sont conformes aux Tableaux 2 et 3", {
  m <- readRDS(file.path(data_dir, "statec_milestones_indicators.rds"))
  expect_equal(nrow(m), 24) # 4 scénarios * 6 années jalons
  
  # En 2025, l'âge moyen est de 40.1 ans pour tous les scénarios
  m_2025 <- m %>% filter(year == 2025)
  expect_true(all(m_2025$age_moyen == 40.1))
  expect_true(all(m_2025$ratio_dependance_65_20_64 == 24))
  
  # En 2070, l'âge moyen s'échelonne de 46.1 (SC4) à 47.9 (SC1)
  expect_equal(m$age_moyen[m$scenario_id == "SC1" & m$year == 2070], 47.9)
  expect_equal(m$age_moyen[m$scenario_id == "SC4" & m$year == 2070], 46.1)
})

test_that("Les séries Eurostat et STATEC sont distinctes et étiquetées sans ambiguïté", {
  clean <- readRDS(file.path(data_dir, "projections_clean.rds"))
  sources <- unique(clean$source)
  expect_true("Eurostat (EUROPOP2025)" %in% sources)
  expect_true(any(grepl("STATEC", sources)))
  
  # Vérifier que Eurostat en 2070 vaut 962 648
  es_2070 <- clean %>%
    filter(source == "Eurostat (EUROPOP2025)", indicator == "population", year == 2070)
  expect_equal(es_2070$value, 962648)
})

test_that("Les observations historiques ne sont pas qualifiées de projections", {
  clean <- readRDS(file.path(data_dir, "projections_clean.rds"))
  hist <- clean %>% filter(year < 2026, grepl("STATEC", source))
  expect_true(all(hist$data_type %in% c("observed", "medium_term_projection")))
  expect_false(any(hist$data_type == "projected" & hist$year <= 2025))
})

test_that("Les trajectoires de population sont continues et sans valeurs manquantes silencieuses", {
  traj <- readRDS(file.path(data_dir, "statec_trajectories.rds"))
  pop_sc1 <- traj %>% filter(scenario_id == "SC1", indicator == "population")
  expect_true(all(!is.na(pop_sc1$value)))
  expect_equal(nrow(pop_sc1), 45) # 2026 à 2070
})

test_that("Les sensibilités économiques et démographiques reproduisent fidèlement les tableaux p. 56 et 67", {
  sens <- readRDS(file.path(data_dir, "statec_sensitivities.rds"))
  expect_equal(nrow(sens), 26)
  
  # Scénario solde migratoire nul dès 2040 (p. 67)
  zero_mig <- sens %>% filter(variante == "Solde migratoire nul dès 2040")
  expect_equal(nrow(zero_mig), 2)
  expect_true(all(zero_mig$population_2070 == 720371))
  expect_true(all(zero_mig$old_age_dep_ratio == 80))
  expect_true(all(zero_mig$net_migration_2070 == 0))
})
