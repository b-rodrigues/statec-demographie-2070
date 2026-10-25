# scripts/01_fetch_lustat.R
# Téléchargement et structuration des données démographiques historiques du STATEC (LUSTAT)

library(readr)
library(dplyr)
library(tidyr)
library(stringr)

message("=== [1/4] Téléchargement DF_B1100 (Population totale et par sexe) ===")
url_b1100 <- "https://lustat.statec.lu/rest/data/LU1,DF_B1100,1.0/all?format=csv"
df_b1100_raw <- read_csv(url_b1100, show_col_types = FALSE)

# Filtrer sur la population totale, hommes et femmes (au 31 décembre de chaque année)
# C01: Total, C03: Hommes, C06: Femmes
pop_hist_total <- df_b1100_raw %>%
  filter(SPECIFICATION %in% c("C01", "C03", "C06")) %>%
  mutate(
    year = as.integer(format(as.Date(TIME_PERIOD), "%Y")),
    sex = case_when(
      SPECIFICATION == "C01" ~ "Total",
      SPECIFICATION == "C03" ~ "Hommes",
      SPECIFICATION == "C06" ~ "Femmes"
    )
  ) %>%
  filter(!is.na(OBS_VALUE), year >= 1960) %>%
  select(year, sex, population = OBS_VALUE) %>%
  arrange(year, sex)

saveRDS(pop_hist_total, "data/historical_population.rds")
write_csv(pop_hist_total, "data/historical_population.csv")
message("-> historical_population.rds sauvegardé (", nrow(pop_hist_total), " lignes)")

message("=== [2/4] Téléchargement DF_B2103 (Mouvements naturel et migratoire) ===")
url_b2103 <- "https://lustat.statec.lu/rest/data/LU1,DF_B2103,1.0/all?format=csv"
df_b2103_raw <- read_csv(url_b2103, show_col_types = FALSE)

# SL01: Naissances, SL02: Décès, SL03: Excédent naturel, SL04: Excédent total,
# SL05: Excédent migratoire, SL06: Ajustement statistique, SL07: Population au 31.12
comp_hist <- df_b2103_raw %>%
  mutate(
    indicator = case_when(
      SPECIFICATION == "SL01" ~ "naissances",
      SPECIFICATION == "SL02" ~ "deces",
      SPECIFICATION == "SL03" ~ "solde_naturel",
      SPECIFICATION == "SL04" ~ "accroissement_total",
      SPECIFICATION == "SL05" ~ "solde_migratoire",
      SPECIFICATION == "SL06" ~ "ajustement_statistique",
      SPECIFICATION == "SL07" ~ "population_31_12",
      TRUE ~ NA_character_
    ),
    year = as.integer(TIME_PERIOD)
  ) %>%
  filter(!is.na(indicator), !is.na(OBS_VALUE), year >= 1960) %>%
  select(year, indicator, value = OBS_VALUE) %>%
  arrange(year, indicator)

saveRDS(comp_hist, "data/historical_components.rds")
write_csv(comp_hist, "data/historical_components.csv")
message("-> historical_components.rds sauvegardé (", nrow(comp_hist), " lignes)")

message("=== [3/4] Téléchargement DF_B2400 (Arrivées, départs, solde brut) ===")
url_b2400 <- "https://lustat.statec.lu/rest/data/LU1,DF_B2400,1.0/all?format=csv"
df_b2400_raw <- read_csv(url_b2400, show_col_types = FALSE)

# M01: Arrivées, M02: Départs, M03: Excédent des arrivées
# S01: Total (deux sexes), L01: Total toutes nationalités
flows_hist <- df_b2400_raw %>%
  filter(SEX == "S01", SPECIFICATION == "L01", POP_MOVEMENT %in% c("M01", "M02", "M03")) %>%
  mutate(
    flow_type = case_when(
      POP_MOVEMENT == "M01" ~ "immigrations",
      POP_MOVEMENT == "M02" ~ "emigrations",
      POP_MOVEMENT == "M03" ~ "solde_migratoire_brut"
    ),
    year = as.integer(TIME_PERIOD)
  ) %>%
  filter(!is.na(flow_type), !is.na(OBS_VALUE)) %>%
  select(year, flow_type, value = OBS_VALUE) %>%
  arrange(year, flow_type)

saveRDS(flows_hist, "data/historical_migration_flows.rds")
write_csv(flows_hist, "data/historical_migration_flows.csv")
message("-> historical_migration_flows.rds sauvegardé (", nrow(flows_hist), " lignes)")

message("=== [4/4] Téléchargement DF_B1102 (Structure par âge et sexe) ===")
url_b1102 <- "https://lustat.statec.lu/rest/data/LU1,DF_B1102,1.0/all?format=csv"
df_b1102_raw <- read_csv(url_b1102, show_col_types = FALSE)

# Récupérer les libellés officiels de CL_B1102_AGE
txt_cl_age <- paste(readLines("https://lustat.statec.lu/rest/codelist/LU1/CL_B1102_AGE/latest", warn = FALSE), collapse = "\n")
codes <- str_match_all(txt_cl_age, '<structure:Code id="([^"]+)">\\s*<common:Name xml:lang="fr">([^<]+)</common:Name>')[[1]]
age_dict <- tibble(AGE = codes[, 2], age_label = codes[, 3])

pyramid_hist <- df_b1102_raw %>%
  filter(SEX %in% c("A02", "A03")) %>% # Hommes et Femmes
  inner_join(age_dict, by = "AGE") %>%
  mutate(
    sex = ifelse(SEX == "A02", "Hommes", "Femmes"),
    year = as.integer(TIME_PERIOD)
  ) %>%
  # Conserver les groupes quinquennaux ou âges simples
  select(year, sex, age_code = AGE, age_label, value = OBS_VALUE) %>%
  arrange(year, sex, age_label)

saveRDS(pyramid_hist, "data/historical_pyramid.rds")
write_csv(pyramid_hist, "data/historical_pyramid.csv")
message("-> historical_pyramid.rds sauvegardé (", nrow(pyramid_hist), " lignes)")

message("Extraction LUSTAT terminée avec succès !")
