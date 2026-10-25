# R/charts.R
# Fonctions de génération des graphiques interactifs Plotly

library(plotly)
library(dplyr)
library(scales)

# Palette de couleurs officielles du projet
PALETTE_SCENARIOS <- c(
  "OBS" = "#1e3a8a",          # Bleu nuit institutionnel pour l'observé
  "SC1" = "#ef4444",          # Rouge (Faible productivité)
  "SC2" = "#f97316",          # Orange (Investissement intensif)
  "SC3" = "#0d9488",          # Sarcelle/Teal (Innovation importée)
  "SC4" = "#2563eb",          # Bleu royal (Forte productivité)
  "EUROPOP2025" = "#4b5563"   # Gris anthracite pour Eurostat
)

# Noms lisibles des scénarios
LABELS_SCENARIOS <- c(
  "OBS" = "Observé (STATEC LUSTAT)",
  "SC1" = "Scénario 1 : Faible productivité",
  "SC2" = "Scénario 2 : Investissement intensif",
  "SC3" = "Scénario 3 : Innovation importée",
  "SC4" = "Scénario 4 : Forte productivité",
  "EUROPOP2025" = "Eurostat Baseline (EUROPOP2025)"
)

# 1. Graphique de la vue d'ensemble : Trajectoire de population 2000-2070
plot_overview_trajectory <- function(data, target_year = 2070, show_eurostat = TRUE) {
  traj <- data$trajectories %>% filter(indicator == "population")
  
  # Historique observé (2000-2025)
  hist <- traj %>% filter(scenario_id == "OBS", year <= 2025)
  
  p <- plot_ly()
  
  # Ligne observée solide
  p <- p %>% add_lines(
    data = hist,
    x = ~year,
    y = ~value,
    name = "Historique observé (STATEC)",
    line = list(color = PALETTE_SCENARIOS["OBS"], width = 3.5),
    hovertemplate = "<b>Année :</b> %{x}<br><b>Population observée :</b> %{y:,.0f} hab.<extra></extra>"
  )
  
  # Projections des 4 scénarios STATEC
  for (sc in c("SC1", "SC2", "SC3", "SC4")) {
    sc_data <- traj %>% filter(scenario_id == sc)
    p <- p %>% add_lines(
      data = sc_data,
      x = ~year,
      y = ~value,
      name = LABELS_SCENARIOS[sc],
      line = list(color = PALETTE_SCENARIOS[sc], width = 2.5, dash = if (sc %in% c("SC2", "SC3")) "dash" else "solid"),
      hovertemplate = paste0("<b>Année :</b> %{x}<br><b>", LABELS_SCENARIOS[sc], " :</b> %{y:,.0f} hab.<extra></extra>")
    )
  }
  
  # Eurostat EUROPOP2025
  if (show_eurostat) {
    es_data <- data$eurostat_ind %>% filter(indicator == "population")
    p <- p %>% add_lines(
      data = es_data,
      x = ~year,
      y = ~value,
      name = LABELS_SCENARIOS["EUROPOP2025"],
      line = list(color = PALETTE_SCENARIOS["EUROPOP2025"], width = 2.2, dash = "dot"),
      hovertemplate = "<b>Année :</b> %{x}<br><b>Eurostat EUROPOP2025 :</b> %{y:,.0f} hab.<extra></extra>"
    )
  }
  
  # Ligne de référence du million d'habitants
  p <- p %>% add_segments(
    x = 2000, xend = 2070,
    y = 1000000, yend = 1000000,
    name = "Cap du million d'habitants",
    line = list(color = "#9ca3af", width = 1.5, dash = "dash"),
    hoverinfo = "text",
    text = "Seuil symbolique : 1 000 000 habitants"
  )
  
  # Ligne verticale sur l'année sélectionnée
  if (!is.null(target_year) && target_year >= 2025) {
    p <- p %>% add_segments(
      x = target_year, xend = target_year,
      y = 400000, yend = 1200000,
      showlegend = FALSE,
      line = list(color = "#b91c1c", width = 1.2, dash = "dot"),
      hoverinfo = "none"
    )
  }
  
  p %>% layout(
    title = list(text = "<b>Trajectoire de la population du Luxembourg (2000–2070)</b>", x = 0.05),
    xaxis = list(title = "Année", dtick = 10, gridcolor = "#f3f4f6"),
    yaxis = list(title = "Population totale (nombre d'habitants)", tickformat = " ", gridcolor = "#e5e7eb"),
    legend = list(orientation = "h", y = -0.2),
    hovermode = "x unified",
    paper_bgcolor = "#ffffff",
    plot_bgcolor = "#ffffff"
  )
}

# 2. Graphique de l'explorateur de scénarios
plot_scenario_explorer <- function(data, scenarios_selected, indicator = "population", compare_base = FALSE) {
  traj <- data$trajectories %>%
    filter(indicator == !!indicator, scenario_id %in% c("OBS", scenarios_selected))
  
  if (compare_base && "SC1" %in% scenarios_selected && indicator %in% c("population", "solde_migratoire", "emploi_total")) {
    base_traj <- traj %>%
      filter(scenario_id == "SC1") %>%
      select(year, base_val = value)
    
    diff_data <- traj %>%
      filter(scenario_id != "OBS") %>%
      inner_join(base_traj, by = "year") %>%
      mutate(
        ecart_abs = value - base_val,
        ecart_pct = ifelse(base_val > 0, (value - base_val) / base_val * 100, 0)
      )
    
    p <- plot_ly()
    for (sc in setdiff(scenarios_selected, "SC1")) {
      sc_d <- diff_data %>% filter(scenario_id == sc)
      p <- p %>% add_lines(
        data = sc_d,
        x = ~year,
        y = ~ecart_abs,
        name = paste("Écart :", LABELS_SCENARIOS[sc], "vs SC1"),
        line = list(color = PALETTE_SCENARIOS[sc], width = 2.5),
        hovertemplate = "<b>Année :</b> %{x}<br><b>Écart absolu :</b> +%{y:,.0f}<extra></extra>"
      )
    }
    
    p <- p %>% layout(
      title = list(text = paste("<b>Écart absolu par rapport au Scénario 1 (Faible productivité)</b>"), x = 0.05),
      xaxis = list(title = "Année", dtick = 5, gridcolor = "#f3f4f6"),
      yaxis = list(title = "Différence (personnes)", tickformat = " ", gridcolor = "#e5e7eb"),
      legend = list(orientation = "h", y = -0.2),
      hovermode = "x unified"
    )
    return(p)
  }
  
  # Affichage normal de la trajectoire de l'indicateur sélectionné
  unit_label <- case_when(
    indicator %in% c("population", "solde_migratoire", "emploi_total") ~ "Personnes",
    indicator == "taux_croissance_annuel" ~ "%",
    TRUE ~ "Valeur"
  )
  
  p <- plot_ly()
  for (sc in c("OBS", scenarios_selected)) {
    sc_d <- traj %>% filter(scenario_id == sc)
    if (nrow(sc_d) > 0) {
      is_obs <- (sc == "OBS")
      p <- p %>% add_lines(
        data = sc_d,
        x = ~year,
        y = ~value,
        name = LABELS_SCENARIOS[sc],
        line = list(
          color = PALETTE_SCENARIOS[sc],
          width = if (is_obs) 3.5 else 2.5,
          dash = if (is_obs) "solid" else if (sc %in% c("SC2", "SC3")) "dash" else "solid"
        ),
        hovertemplate = paste0("<b>Année :</b> %{x}<br><b>", LABELS_SCENARIOS[sc], " :</b> %{y:,.0f} ", unit_label, "<extra></extra>")
      )
    }
  }
  
  p %>% layout(
    title = list(text = paste0("<b>Évolution : ", indicator, " selon les scénarios retenus</b>"), x = 0.05),
    xaxis = list(title = "Année", dtick = 5, gridcolor = "#f3f4f6"),
    yaxis = list(title = unit_label, tickformat = " ", gridcolor = "#e5e7eb"),
    legend = list(orientation = "h", y = -0.2),
    hovermode = "x unified",
    paper_bgcolor = "#ffffff",
    plot_bgcolor = "#ffffff"
  )
}

# 3. Décomposition démographique : Solde naturel vs Solde migratoire
plot_migration_decomposition <- function(data, scenario_selected = "SC4") {
  # Historique observé (2000-2025)
  hist_comp <- data$hist_comp %>%
    filter(year >= 2000, indicator %in% c("solde_naturel", "solde_migratoire")) %>%
    mutate(scenario_name = "Observé (STATEC)")
  
  # Scénario projeté sélectionné (2026-2070)
  sc_comp <- data$trajectories %>%
    filter(scenario_id == scenario_selected, indicator %in% c("solde_naturel", "solde_migratoire"))
  
  all_comp <- bind_rows(hist_comp, sc_comp) %>%
    tidyr::pivot_wider(names_from = indicator, values_from = value) %>%
    mutate(accroissement = solde_naturel + solde_migratoire)
  
  p <- plot_ly(data = all_comp, x = ~year)
  
  # Barre Solde naturel
  p <- p %>% add_bars(
    y = ~solde_naturel,
    name = "Solde naturel (Naissances - Décès)",
    marker = list(color = "#3b82f6"),
    hovertemplate = "<b>Année :</b> %{x}<br><b>Solde naturel :</b> %{y:,.0f}<extra></extra>"
  )
  
  # Barre Solde migratoire
  p <- p %>% add_bars(
    y = ~solde_migratoire,
    name = "Solde migratoire net",
    marker = list(color = "#10b981"),
    hovertemplate = "<b>Année :</b> %{x}<br><b>Solde migratoire :</b> %{y:,.0f}<extra></extra>"
  )
  
  # Ligne de l'accroissement total
  p <- p %>% add_lines(
    y = ~accroissement,
    name = "Accroissement démographique total",
    line = list(color = "#111827", width = 2.5),
    hovertemplate = "<b>Année :</b> %{x}<br><b>Accroissement total :</b> %{y:,.0f}<extra></extra>"
  )
  
  # Ligne zéro
  p <- p %>% add_segments(
    x = 2000, xend = 2070, y = 0, yend = 0,
    showlegend = FALSE,
    line = list(color = "#374151", width = 1)
  )
  
  sc_label <- LABELS_SCENARIOS[scenario_selected]
  p %>% layout(
    title = list(text = paste("<b>Décomposition de la croissance démographique :", sc_label, "</b>"), x = 0.05),
    barmode = "relative",
    xaxis = list(title = "Année", dtick = 5, gridcolor = "#f3f4f6"),
    yaxis = list(title = "Variation annuelle de la population (personnes)", tickformat = " ", gridcolor = "#e5e7eb"),
    legend = list(orientation = "h", y = -0.2),
    hovermode = "x unified",
    paper_bgcolor = "#ffffff",
    plot_bgcolor = "#ffffff"
  )
}

# 4. Pyramide des âges interactive (2025 vs Année choisie)
plot_age_pyramid <- function(data, target_year = 2070, scenario_id = "SC4") {
  # Base Eurostat ou STATEC par grand groupe d'âge
  # On utilise la pyramide Eurostat proj_25np par âge simple pour un niveau de détail exceptionnel
  pyr <- data$eurostat_pyr %>%
    filter(year %in% c(2025, target_year))
  
  pyr_2025 <- pyr %>% filter(year == 2025)
  pyr_target <- pyr %>% filter(year == target_year)
  
  # Hommes en négatif pour affichage à gauche, Femmes à droite
  p <- plot_ly()
  
  # 2025 (Couleur claire en arrière-plan)
  p <- p %>% add_bars(
    data = pyr_2025 %>% filter(sex == "Hommes"),
    x = ~(-value), y = ~age,
    orientation = "h",
    name = "Hommes (2025)",
    marker = list(color = "#93c5fd", opacity = 0.6),
    hovertemplate = "<b>Hommes 2025 (âge %{y}) :</b> %{customdata:,.0f}<extra></extra>",
    customdata = ~value
  )
  
  p <- p %>% add_bars(
    data = pyr_2025 %>% filter(sex == "Femmes"),
    x = ~value, y = ~age,
    orientation = "h",
    name = "Femmes (2025)",
    marker = list(color = "#fca5a5", opacity = 0.6),
    hovertemplate = "<b>Femmes 2025 (âge %{y}) :</b> %{customdata:,.0f}<extra></extra>",
    customdata = ~value
  )
  
  # Année cible (Couleur foncée au premier plan)
  p <- p %>% add_bars(
    data = pyr_target %>% filter(sex == "Hommes"),
    x = ~(-value), y = ~age,
    orientation = "h",
    name = paste0("Hommes (", target_year, ")"),
    marker = list(color = "#1e40af"),
    hovertemplate = paste0("<b>Hommes ", target_year, " (âge %{y}) :</b> %{customdata:,.0f}<extra></extra>"),
    customdata = ~value
  )
  
  p <- p %>% add_bars(
    data = pyr_target %>% filter(sex == "Femmes"),
    x = ~value, y = ~age,
    orientation = "h",
    name = paste0("Femmes (", target_year, ")"),
    marker = list(color = "#b91c1c"),
    hovertemplate = paste0("<b>Femmes ", target_year, " (âge %{y}) :</b> %{customdata:,.0f}<extra></extra>"),
    customdata = ~value
  )
  
  p %>% layout(
    title = list(text = paste0("<b>Pyramide des âges du Luxembourg : 2025 vs ", target_year, "</b>"), x = 0.05),
    barmode = "overlay",
    bargap = 0.05,
    xaxis = list(
      title = "Effectifs (Hommes à gauche | Femmes à droite)",
      tickvals = seq(-6000, 6000, by = 2000),
      ticktext = c("6 000", "4 000", "2 000", "0", "2 000", "4 000", "6 000"),
      gridcolor = "#e5e7eb"
    ),
    yaxis = list(title = "Âge", dtick = 10, gridcolor = "#f3f4f6"),
    legend = list(orientation = "h", y = -0.15),
    paper_bgcolor = "#ffffff",
    plot_bgcolor = "#ffffff"
  )
}

# 5. Comparaison STATEC vs Eurostat (Population et Solde migratoire)
plot_eurostat_comparison_chart <- function(data) {
  # Population
  st_pop <- data$trajectories %>%
    filter(indicator == "population", scenario_id %in% c("SC1", "SC2", "SC3", "SC4"))
  es_pop <- data$eurostat_ind %>%
    filter(indicator == "population")
  
  p <- plot_ly()
  
  # Eurostat
  p <- p %>% add_lines(
    data = es_pop,
    x = ~year,
    y = ~value,
    name = "Eurostat EUROPOP2025 (Baseline)",
    line = list(color = PALETTE_SCENARIOS["EUROPOP2025"], width = 3.5, dash = "solid"),
    hovertemplate = "<b>Eurostat :</b> %{y:,.0f} hab.<extra></extra>"
  )
  
  # STATEC Scenarios
  for (sc in c("SC1", "SC2", "SC3", "SC4")) {
    sc_d <- st_pop %>% filter(scenario_id == sc)
    p <- p %>% add_lines(
      data = sc_d,
      x = ~year,
      y = ~value,
      name = LABELS_SCENARIOS[sc],
      line = list(color = PALETTE_SCENARIOS[sc], width = 2.2, dash = if (sc == "SC2") "dash" else "solid"),
      hovertemplate = paste0("<b>", LABELS_SCENARIOS[sc], " :</b> %{y:,.0f} hab.<extra></extra>")
    )
  }
  
  p %>% layout(
    title = list(text = "<b>Comparaison des trajectoires de population : STATEC vs Eurostat (2025–2070)</b>", x = 0.05),
    xaxis = list(title = "Année", dtick = 5, gridcolor = "#f3f4f6"),
    yaxis = list(title = "Population totale (personnes)", tickformat = " ", gridcolor = "#e5e7eb"),
    legend = list(orientation = "h", y = -0.2),
    hovermode = "x unified",
    paper_bgcolor = "#ffffff",
    plot_bgcolor = "#ffffff"
  )
}
