# scripts/02_fetch_eurostat.R
# Téléchargement et structuration des projections EUROPOP2025 d'Eurostat pour le Luxembourg

library(jsonlite)
library(dplyr)
library(tidyr)
library(readr)

message("=== [1/2] Traitement des indicateurs et soldes EUROPOP2025 (proj_25ndbi) ===")

url_dbi <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/proj_25ndbi?geo=LU&projection=BSL"
raw_dbi_file <- "data/eurostat_dbi.json"

if (!file.exists(raw_dbi_file)) {
  download.file(url_dbi, raw_dbi_file, quiet = TRUE)
}

js_dbi <- fromJSON(raw_dbi_file)
times_dbi <- names(js_dbi$dimension$time$category$index)
indics_dbi <- names(js_dbi$dimension$indic_de$category$index)

indic_map_dbi <- unlist(js_dbi$dimension$indic_de$category$index)
time_map_dbi <- unlist(js_dbi$dimension$time$category$index)

grid_dbi <- expand_grid(
  indic_de = indics_dbi,
  year = as.integer(times_dbi)
) %>%
  mutate(
    indic_idx = as.integer(indic_map_dbi[indic_de]),
    time_idx = as.integer(time_map_dbi[as.character(year)]),
    flat_idx = as.character(indic_idx * length(times_dbi) + time_idx),
    value = as.numeric(sapply(flat_idx, function(k) {
      v <- js_dbi$value[[k]]
      if (is.null(v)) NA_real_ else as.numeric(v)
    }))
  ) %>%
  filter(!is.na(value), year >= 2025, year <= 2070) %>%
  select(year, indicator = indic_de, value) %>%
  arrange(year, indicator)

# Associer des libellés clairs
indic_labels <- tibble(
  indicator = c("JAN", "NMIGRAT", "LBIRTH", "DEATH", "OLDDEP1", "OLDDEP3", "MEDAGEPOP",
                "PC_Y0_14", "PC_Y15_64", "PC_Y20_64", "PC_Y65_MAX", "PC_Y80_MAX",
                "YOUNGDEP1", "YOUNGDEP3"),
  indicator_fr = c("population", "solde_migratoire", "naissances", "deces",
                   "ratio_dependance_65_15_64", "ratio_dependance_65_20_64", "age_median",
                   "part_0_14", "part_15_64", "part_20_64", "part_65_plus", "part_80_plus",
                   "ratio_jeunes_0_14_15_64", "ratio_jeunes_0_19_20_64"),
  unit = c("personnes", "personnes", "personnes", "personnes", "%", "%", "annees",
           "%", "%", "%", "%", "%", "%", "%")
)

eurostat_indicators <- grid_dbi %>%
  inner_join(indic_labels, by = "indicator") %>%
  select(year, indicator_fr, value) %>%
  pivot_wider(names_from = indicator_fr, values_from = value) %>%
  mutate(
    solde_naturel = naissances - deces,
    accroissement_total = solde_naturel + solde_migratoire,
    source = "Eurostat (EUROPOP2025)",
    scenario_id = "EUROPOP2025",
    scenario_name = "Eurostat Baseline (EUROPOP2025)"
  ) %>%
  pivot_longer(
    cols = c(population, solde_migratoire, naissances, deces, solde_naturel,
             accroissement_total, ratio_dependance_65_15_64, ratio_dependance_65_20_64,
             age_median, part_0_14, part_15_64, part_20_64, part_65_plus, part_80_plus),
    names_to = "indicator",
    values_to = "value"
  ) %>%
  arrange(year, indicator)

saveRDS(eurostat_indicators, "data/eurostat_indicators.rds")
write_csv(eurostat_indicators, "data/eurostat_indicators.csv")
message("-> eurostat_indicators.rds sauvegardé (", nrow(eurostat_indicators), " lignes)")

message("=== [2/2] Traitement de la pyramide par âge et sexe (proj_25np) ===")

url_np <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/proj_25np?geo=LU&projection=BSL"
raw_np_file <- "data/eurostat_test.json"

if (!file.exists(raw_np_file)) {
  download.file(url_np, raw_np_file, quiet = TRUE)
}

js_np <- fromJSON(raw_np_file)
times_np <- names(js_np$dimension$time$category$index)
ages_np <- names(js_np$dimension$age$category$index)
sexes_np <- names(js_np$dimension$sex$category$index)

# On filtre sur les âges simples Y0 à Y99 et Y_GE100, et pour les sexes M et F
single_ages <- ages_np[grepl("^Y[0-9]+$|^Y_GE100$", ages_np)]

sex_map_np <- unlist(js_np$dimension$sex$category$index)
age_map_np <- unlist(js_np$dimension$age$category$index)
time_map_np <- unlist(js_np$dimension$time$category$index)

grid_np <- expand_grid(
  sex = c("M", "F"),
  age = single_ages,
  year = c(2025, 2030, 2040, 2050, 2060, 2070)
) %>%
  mutate(
    sex_idx = as.integer(sex_map_np[sex]),
    age_idx = as.integer(age_map_np[age]),
    time_idx = as.integer(time_map_np[as.character(year)]),
    flat_idx = as.character((sex_idx * length(ages_np) + age_idx) * length(times_np) + time_idx),
    value = as.numeric(sapply(flat_idx, function(k) {
      v <- js_np$value[[k]]
      if (is.null(v)) NA_real_ else as.numeric(v)
    })),
    age_numeric = as.integer(gsub("[^0-9]", "", age)),
    sex_fr = ifelse(sex == "M", "Hommes", "Femmes"),
    source = "Eurostat (EUROPOP2025)"
  ) %>%
  select(year, sex = sex_fr, age = age_numeric, value, source) %>%
  arrange(year, sex, age)

saveRDS(grid_np, "data/eurostat_pyramid.rds")
write_csv(grid_np, "data/eurostat_pyramid.csv")
message("-> eurostat_pyramid.rds sauvegardé (", nrow(grid_np), " lignes)")

message("Extraction Eurostat terminée avec succès !")
