# app.R
# Dashboard interactif des projections démographiques du Luxembourg à l'horizon 2070
# Basé sur l'étude STATEC Analyses 02/26 (Gabriel Gomes & François Peltier)
# Licence : EUPL v1.2 FR

library(shiny)
library(bslib)
library(bsicons)
library(plotly)
library(DT)
library(dplyr)
library(tidyr)
library(readr)
library(scales)

# Chargement des modules R
source("R/load_data.R")
source("R/calculations.R")
source("R/charts.R")

# Chargement des données pré-nettoyées
app_data <- load_dashboard_data("data")

# Thème bslib personnalisé moderne et accessible
app_theme <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  primary = "#1e3a8a",       # Bleu nuit STATEC
  secondary = "#0d9488",     # Teal
  success = "#10b981",
  info = "#0284c7",
  warning = "#f59e0b",
  danger = "#ef4444",
  base_font = font_google("Inter"),
  heading_font = font_google("Open Sans")
)

# Interface Utilisateur (UI)
ui <- page_navbar(
  theme = app_theme,
  title = div(
    span(style = "font-weight: 700; color: #1e3a8a; font-size: 1.25rem;", "STATEC | "),
    span(style = "font-weight: 400; color: #374151;", "Projections démographiques 2070")
  ),
  id = "nav_tabs",
  navbar_options = navbar_options(underline = TRUE),
  
  # ===========================================================================
  # Onglet 1 : Vue d'ensemble
  # ===========================================================================
  nav_panel(
    title = "Vue d'ensemble",
    icon = bs_icon("speedometer2"),
    
    layout_sidebar(
      sidebar = sidebar(
        title = "Paramètres de visualisation",
        width = 300,
        selectInput(
          inputId = "overview_year",
          label = "Année cible d'analyse :",
          choices = c(2025, 2030, 2040, 2050, 2060, 2070),
          selected = 2070
        ),
        checkboxInput(
          inputId = "overview_show_eurostat",
          label = "Afficher Eurostat (EUROPOP2025)",
          value = TRUE
        ),
        hr(),
        p(style = "font-size: 0.85rem; color: #6b7280;",
          bs_icon("info-circle"),
          " Le STATEC présente quatre scénarios équiprobables sans en désigner un comme central. Les projections reflètent les interactions entre productivité, attractivité et solde migratoire."
        )
      ),
      
      # Cartes KPI
      uiOutput("overview_kpi_ui"),
      
      card(
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Trajectoire de la population résidente (2000–2070)"),
          span(class = "badge bg-primary", "Source : STATEC & Eurostat")
        ),
        card_body(
          plotlyOutput("overview_plot", height = "480px")
        )
      ),
      
      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header("Pourquoi les scénarios divergent-ils ?"),
          card_body(
            p("La divergence démographique à long terme découle principalement de la ",
              strong("productivité horaire"), " et de son impact sur la compétitivité salariale :"),
            tags$ul(
              tags$li(strong("Scénarios 3 & 4 (Haute productivité) :"), " Les gains de progrès technique (+0,8 % par an) soutiennent des salaires relatifs plus élevés en parité de pouvoir d'achat (PPA), préservent l'attractivité du Luxembourg et attirent un flux migratoire net suffisant pour faire franchir au pays le cap du million d'habitants."),
              tags$li(strong("Scénarios 1 & 2 (Faible productivité) :"), " Une productivité atone érode l'avantage salarial relatif par rapport aux pays limitrophes, réduisant les flux migratoires futurs. La population plafonne alors sous les 970 000 habitants.")
            )
          )
        ),
        card(
          card_header("Repères clés à l'horizon 2070"),
          card_body(
            tags$ul(
              tags$li("En 2070, la population s'établirait entre ", strong("944 000"), " (Scénario 1) et ", strong("1 067 000"), " habitants (Scénario 4)."),
              tags$li("La croissance annuelle moyenne passe durablement ", strong("sous le seuil de 1 % dès les années 2040"), "."),
              tags$li("À partir de ", strong("2050"), ", le solde naturel devient ", strong("négatif"), " dans l'ensemble des scénarios : la croissance repose alors exclusivement sur l'immigration."),
              tags$li("Le nombre de personnes âgées de 65 ans et plus ", strong("triple presque"), ", passant de 105 000 en 2025 à près de 288 000 en 2070.")
            )
          )
        )
      )
    )
  ),
  
  # ===========================================================================
  # Onglet 2 : Explorer les scénarios
  # ===========================================================================
  nav_panel(
    title = "Explorer les scénarios",
    icon = bs_icon("sliders"),
    
    layout_sidebar(
      sidebar = sidebar(
        title = "Sélection des scénarios",
        width = 320,
        checkboxGroupInput(
          inputId = "selected_scenarios",
          label = "Scénarios STATEC à comparer :",
          choices = c(
            "Scénario 1 : Faible productivité" = "SC1",
            "Scénario 2 : Investissement intensif" = "SC2",
            "Scénario 3 : Innovation importée" = "SC3",
            "Scénario 4 : Forte productivité" = "SC4"
          ),
          selected = c("SC1", "SC2", "SC3", "SC4")
        ),
        selectInput(
          inputId = "scenario_indicator",
          label = "Indicateur à afficher :",
          choices = c(
            "Population totale" = "population",
            "Solde migratoire annuel" = "solde_migratoire",
            "Emploi total" = "emploi_total"
          ),
          selected = "population"
        ),
        checkboxInput(
          inputId = "compare_base_sc1",
          label = "Afficher l'écart absolu au Scénario 1",
          value = FALSE
        ),
        downloadButton("download_filtered_data", "Télécharger les données (CSV)", class = "btn-outline-primary btn-sm w-100")
      ),
      
      card(
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Comparateur dynamique des scénarios macro-démographiques"),
          span(class = "badge bg-secondary", "Trajectoires 2000–2070")
        ),
        card_body(
          plotlyOutput("scenario_plot", height = "440px")
        )
      ),
      
      card(
        card_header("Résumé macroéconomique et démographique en 2070 (Tableau officiel 4)"),
        card_body(
          DTOutput("table_scenarios_summary")
        )
      )
    )
  ),
  
  # ===========================================================================
  # Onglet 3 : Migrations et dynamique
  # ===========================================================================
  nav_panel(
    title = "Migrations & Dynamique",
    icon = bs_icon("arrow-left-right"),
    
    layout_sidebar(
      sidebar = sidebar(
        title = "Paramètres d'analyse",
        width = 300,
        selectInput(
          inputId = "mig_scenario",
          label = "Scénario STATEC pour la décomposition :",
          choices = c(
            "Scénario 1 (Faible productivité)" = "SC1",
            "Scénario 2 (Investissement intensif)" = "SC2",
            "Scénario 3 (Innovation importée)" = "SC3",
            "Scénario 4 (Forte productivité)" = "SC4"
          ),
          selected = "SC4"
        ),
        hr(),
        p(style = "font-size: 0.85rem; color: #4b5563;",
          strong("Transmission économique :"),
          " Productivité → Salaires relatifs PPA → Attractivité pour la main-d'œuvre étrangère → Solde migratoire.")
      ),
      
      card(
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Décomposition de la croissance démographique annuelle : Solde naturel vs Solde migratoire"),
          span(class = "badge bg-info text-dark", "1990–2070")
        ),
        card_body(
          plotlyOutput("decomposition_plot", height = "440px")
        ),
        card_footer(
          p(class = "mb-0 text-muted", style = "font-size: 0.85rem;",
            bs_icon("exclamation-triangle-fill", class = "text-warning me-1"),
            strong("Inflexion structurelle : "), "Dans tous les scénarios, le solde naturel (naissances - décès) devient négatif à partir de 2050. Dès lors, le Luxembourg dépend entièrement de l'immigration pour maintenir sa population active et sa démographie.")
        )
      ),
      
      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header("Flux migratoires bruts observés (1967–2025)"),
          card_body(
            plotlyOutput("flows_history_plot", height = "320px")
          )
        ),
        card(
          card_header("Choc sans migration dès 2040 (Analyse de sensibilité)"),
          card_body(
            p("Le STATEC a modélisé une variante extrême dans laquelle le solde migratoire deviendrait ", strong("nul dès 2040"), " :"),
            tags$ul(
              tags$li("La population totale chuterait à ", strong("720 371 habitants"), " en 2070 (au lieu de 944 000 à 1 066 000)."),
              tags$li("L'emploi total se contracterait drastiquement (seulement 228 708 emplois nationaux)."),
              tags$li("Le ratio de dépendance des seniors exploserait à ", strong("80 %"), "."),
              tags$li("La croissance du PIB potentiel tomberait à ", strong("0,4 %"), " (SC1) voire deviendrait négative.")
            )
          )
        )
      )
    )
  ),
  
  # ===========================================================================
  # Onglet 4 : Vieillissement de la population
  # ===========================================================================
  nav_panel(
    title = "Vieillissement",
    icon = bs_icon("hourglass-split"),
    
    layout_sidebar(
      sidebar = sidebar(
        title = "Structure d'âge",
        width = 300,
        selectInput(
          inputId = "pyramid_year",
          label = "Année projetée à comparer avec 2025 :",
          choices = c(2030, 2040, 2050, 2060, 2070),
          selected = 2070
        ),
        hr(),
        p(style = "font-size: 0.85rem; color: #6b7280;",
          "La pyramide montre le passage d'une structure en 'cloche' équilibrée par l'immigration active en 2025 à une structure vieillie en 2070.")
      ),
      
      layout_columns(
        col_widths = c(7, 5),
        card(
          card_header("Pyramide des âges interactive (2025 vs Année choisie)"),
          card_body(
            plotlyOutput("pyramid_plot", height = "500px")
          )
        ),
        card(
          card_header("Indicateurs de vieillissement démographique"),
          card_body(
            h6(class = "text-primary", "Âge moyen de la population (Tableau 2) :"),
            DTOutput("table_mean_age"),
            hr(),
            h6(class = "text-primary mt-3", "Ratio de dépendance démographique (65+ / 20-64 ans) :"),
            DTOutput("table_dep_ratio")
          ),
          card_footer(
            p(class = "mb-0 text-muted", style = "font-size: 0.8rem;",
              bs_icon("info-circle-fill", class = "text-primary me-1"),
              strong("Note méthodologique : "), "Le ratio de dépendance démographique mesure le rapport entre résidents âgés de 65+ et résidents en âge de travailler (20-64 ans). ",
              strong("Il ne mesure pas directement la viabilité financière du système de pension"), ", car il ne comptabilise pas les centaines de milliers de travailleurs frontaliers cotisants non résidents.")
          )
        )
      )
    )
  ),
  
  # ===========================================================================
  # Onglet 5 : Comparer STATEC et Eurostat
  # ===========================================================================
  nav_panel(
    title = "Comparer STATEC & Eurostat",
    icon = bs_icon("globe-europe-africa"),
    
    layout_sidebar(
      sidebar = sidebar(
        title = "Comparaison institutionnelle",
        width = 300,
        p(style = "font-size: 0.9rem;",
          "Eurostat (EUROPOP2025) et le STATEC partagent le point de départ de 2025 (environ 691 000 habitants), mais reposent sur des méthodologies fondamentalement distinctes.")
      ),
      
      card(
        card_header("Comparaison des trajectoires : Scénarios STATEC vs Eurostat EUROPOP2025"),
        card_body(
          plotlyOutput("eurostat_comparison_plot", height = "420px")
        )
      ),
      
      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header("Tableau des écarts de population (Milliers de personnes)"),
          card_body(
            DTOutput("table_eurostat_diff")
          )
        ),
        card(
          card_header("Divergences méthodologiques fondamentales"),
          card_body(
            tags$ul(
              tags$li(strong("Extrapolation tendancielle (Eurostat) :"), " Eurostat traite la migration comme une variable exogène projetée à partir des tendances récentes. En cas de choc économique récent, la projection subit de fortes révisions d'une parution à l'autre (ex. EUROPOP2019 vs 2023 vs 2025)."),
              tags$li(strong("Modélisation éco-démographique endogène (STATEC) :"), " Le STATEC endogénéise le solde migratoire en fonction des différentiels de productivité et des salaires relatifs en PPA. La migration répond aux besoins d'emploi réels de l'économie."),
              tags$li(strong("Résultat en 2070 :"), " Eurostat anticipe 962 500 habitants, soit un niveau très proche du Scénario 2 du STATEC (966 000 hab.), mais avec un vieillissement encore plus marqué en raison d'un flux migratoire jeune plus faible en fin de période.")
            )
          )
        )
      )
    )
  ),
  
  # ===========================================================================
  # Onglet 6 : Méthodologie & Sources
  # ===========================================================================
  nav_panel(
    title = "Méthodologie & Modèle",
    icon = bs_icon("journal-text"),
    
    div(class = "container py-3",
      accordion(
        open = c("acc_modele", "acc_sensibilites"),
        accordion_panel(
          title = "Comment le modèle éco-démographique du STATEC fonctionne-t-il ?",
          value = "acc_modele",
          p("Le modèle du STATEC innove par rapport aux exercices précédents en ", strong("endogénéisant la croissance du PIB potentiel"), " :"),
          div(class = "p-3 my-2 bg-light border rounded text-center font-monospace",
            "Productivité horaire (PTF + Capital) → Salaires relatifs (PPA) → Attractivité économique → Solde migratoire → Emploi et Population active → PIB potentiel"
          ),
          p("Cette chaîne d'interaction est circulaire : les gains de productivité rendent le Luxembourg attractif face à la Grande Région, ce qui attire des travailleurs étrangers (dont une partie s'installe comme résidents et l'autre comme frontaliers), élargissant la base de production."),
          p(strong("Projection vs Prévision : "), "Ces trajectoires ne sont pas des prédictions infaillibles, mais des scénarios conditionnels destinés à éclairer les choix de politiques publiques à long terme (pensions, aménagement du territoire, logement, infrastructures).")
        ),
        accordion_panel(
          title = "Synthèse complète des analyses de sensibilité officielles",
          value = "acc_sensibilites",
          p("Le STATEC a testé la robustesse de ses résultats face à des chocs économiques et démographiques :"),
          DTOutput("table_all_sensitivities")
        ),
        accordion_panel(
          title = "Registre officiel des sources et licence",
          value = "acc_sources",
          p(strong("Publication principale : "), a(href = "https://statistiques.public.lu/fr/publications/series/analyses/2026/analyses-02-26.html", target = "_blank", "Analyses 02/26 — Projections démographiques du Luxembourg : Vers un million d'habitants d'ici 2070 (Gabriel Gomes & François Peltier, STATEC, 2026).")),
          p(strong("Données historiques : "), a(href = "https://lustat.statec.lu/", target = "_blank", "STATEC LUSTAT (Tables DF_B1100, DF_B1102, DF_B2103, DF_B2400).")),
          p(strong("Projections européennes : "), a(href = "https://ec.europa.eu/eurostat/web/population-demography/population-projections", target = "_blank", "Eurostat EUROPOP2025 (Tables proj_25np et proj_25ndbi).")),
          p(strong("Licence : "), "Ce projet est distribué sous la ", a(href = "LICENSE", target = "_blank", "Licence Publique de l'Union Européenne (EUPL v1.2 FR)"), ".")
        )
      )
    )
  )
)

# Serveur de l'application (Server)
server <- function(input, output, session) {
  
  # --- 1. Onglet Vue d'ensemble ---
  
  output$overview_kpi_ui <- renderUI({
    yr <- as.integer(input$overview_year)
    kpis <- get_headline_kpi(app_data, target_year = yr)
    
    layout_columns(
      col_widths = c(3, 3, 3, 3),
      value_box(
        title = paste("Population projetée en", yr),
        value = paste(format_fr(kpis$pop_min), "à", format_fr(kpis$pop_max)),
        showcase = bs_icon("people-fill"),
        theme = "primary",
        p(class = "mb-0", style = "font-size: 0.85rem;",
          paste0("Croissance depuis 2025 : +", format_pct(kpis$growth_since_2025_min), " à +", format_pct(kpis$growth_since_2025_max)))
      ),
      value_box(
        title = "Écart entre scénarios extrêmes",
        value = paste("+", format_fr(kpis$pop_gap_abs)),
        showcase = bs_icon("arrows-expand"),
        theme = "info",
        p(class = "mb-0", style = "font-size: 0.85rem;", paste0("Différence relative : +", format_pct(kpis$pop_gap_pct)))
      ),
      value_box(
        title = paste("Solde migratoire annuel en", yr),
        value = paste(format_fr(kpis$mig_min), "à", format_fr(kpis$mig_max)),
        showcase = bs_icon("arrow-left-right"),
        theme = "success",
        p(class = "mb-0", style = "font-size: 0.85rem;", "Flux net de nouveaux résidents")
      ),
      value_box(
        title = paste("Ratio de dépendance (65+ / 20-64)"),
        value = paste(kpis$dep_min, "% à", kpis$dep_max, "%"),
        showcase = bs_icon("hourglass-split"),
        theme = "warning",
        p(class = "mb-0", style = "font-size: 0.85rem;", paste("Âge moyen :", kpis$age_m_min, "à", kpis$age_m_max, "ans"))
      )
    )
  })
  
  output$overview_plot <- renderPlotly({
    plot_overview_trajectory(
      data = app_data,
      target_year = as.integer(input$overview_year),
      show_eurostat = input$overview_show_eurostat
    )
  })
  
  # --- 2. Onglet Explorer les scénarios ---
  
  output$scenario_plot <- renderPlotly({
    sc_sel <- input$selected_scenarios
    if (length(sc_sel) == 0) sc_sel <- "SC1"
    
    plot_scenario_explorer(
      data = app_data,
      scenarios_selected = sc_sel,
      indicator = input$scenario_indicator,
      compare_base = input$compare_base_sc1
    )
  })
  
  output$table_scenarios_summary <- renderDT({
    df_t4 <- app_data$summary_scenarios %>%
      select(
        Scénario = scenario_name,
        `Progrès tech.` = ptf_growth,
        Investissement = investment_rate,
        `Croissance PIB moy.` = pib_growth_pct,
        `Productivité moy.` = prod_growth_pct,
        `Emploi moy.` = emp_growth_pct,
        `Ratio PPA 2070` = wage_ratio_ppa_pct,
        `Solde migr. 2070` = net_migration_2070,
        `Emploi national` = national_employment_2070,
        `Emploi frontalier` = crossborder_employment_2070,
        `Population 2070` = population_2070,
        `Dépendance 65+/20-64` = old_age_dep_ratio_65_20_64
      )
    
    datatable(
      df_t4,
      options = list(pageLength = 4, dom = "t", scrollX = TRUE),
      rownames = FALSE
    ) %>%
      formatCurrency(c("Solde migr. 2070", "Emploi national", "Emploi frontalier", "Population 2070"), currency = "", mark = " ", digits = 0) %>%
      formatString(c("Croissance PIB moy.", "Productivité moy.", "Emploi moy.", "Ratio PPA 2070", "Dépendance 65+/20-64", "Progrès tech."), suffix = " %")
  })
  
  output$download_filtered_data <- downloadHandler(
    filename = function() {
      paste0("projections_statec_", input$scenario_indicator, "_", Sys.Date(), ".csv")
    },
    content = function(file) {
      sc_sel <- input$selected_scenarios
      res <- app_data$trajectories %>%
        filter(indicator == input$scenario_indicator, scenario_id %in% c("OBS", sc_sel))
      write_csv(res, file)
    }
  )
  
  # --- 3. Onglet Migrations ---
  
  output$decomposition_plot <- renderPlotly({
    plot_migration_decomposition(
      data = app_data,
      scenario_selected = input$mig_scenario
    )
  })
  
  output$flows_history_plot <- renderPlotly({
    flows <- app_data$hist_flows
    p <- plot_ly(data = flows, x = ~year, y = ~value, color = ~flow_type, colors = c("#ef4444", "#3b82f6", "#10b981")) %>%
      add_lines(line = list(width = 2)) %>%
      layout(
        title = "Arrivées, Départs et Solde net annuel (1967–2025)",
        xaxis = list(title = "Année", dtick = 10, gridcolor = "#f3f4f6"),
        yaxis = list(title = "Personnes", tickformat = " ", gridcolor = "#e5e7eb"),
        legend = list(orientation = "h", y = -0.2),
        hovermode = "x unified"
      )
    p
  })
  
  # --- 4. Onglet Vieillissement ---
  
  output$pyramid_plot <- renderPlotly({
    plot_age_pyramid(
      data = app_data,
      target_year = as.integer(input$pyramid_year)
    )
  })
  
  output$table_mean_age <- renderDT({
    df_m <- app_data$milestones %>%
      select(scenario_id, year, age_moyen) %>%
      tidyr::pivot_wider(names_from = scenario_id, values_from = age_moyen) %>%
      rename(Année = year, `Scénario 1` = SC1, `Scénario 2` = SC2, `Scénario 3` = SC3, `Scénario 4` = SC4)
    
    datatable(df_m, options = list(pageLength = 6, dom = "t"), rownames = FALSE) %>%
      formatString(c("Scénario 1", "Scénario 2", "Scénario 3", "Scénario 4"), suffix = " ans")
  })
  
  output$table_dep_ratio <- renderDT({
    df_d <- app_data$milestones %>%
      select(scenario_id, year, ratio_dependance_65_20_64) %>%
      tidyr::pivot_wider(names_from = scenario_id, values_from = ratio_dependance_65_20_64) %>%
      rename(Année = year, `Scénario 1` = SC1, `Scénario 2` = SC2, `Scénario 3` = SC3, `Scénario 4` = SC4)
    
    datatable(df_d, options = list(pageLength = 6, dom = "t"), rownames = FALSE) %>%
      formatString(c("Scénario 1", "Scénario 2", "Scénario 3", "Scénario 4"), suffix = " %")
  })
  
  # --- 5. Onglet Comparaison Eurostat ---
  
  output$eurostat_comparison_plot <- renderPlotly({
    plot_eurostat_comparison_chart(app_data)
  })
  
  output$table_eurostat_diff <- renderDT({
    comp <- get_comparison_table(app_data) %>%
      select(
        Année = year,
        `Eurostat (EUROPOP)` = EUROPOP2025,
        `Scénario 1 (Bas)` = SC1,
        `Scénario 4 (Haut)` = SC4,
        `Écart SC1 vs Eurostat` = ecart_sc1_eurostat,
        `Écart SC4 vs Eurostat` = ecart_sc4_eurostat
      )
    
    datatable(comp, options = list(pageLength = 6, dom = "t", scrollX = TRUE), rownames = FALSE) %>%
      formatCurrency(2:6, currency = "", mark = " ", digits = 0)
  })
  
  # --- 6. Table de toutes les sensibilités ---
  
  output$table_all_sensitivities <- renderDT({
    sens <- app_data$sensitivities %>%
      select(
        Type = type_sensibilite,
        `Scénario réf.` = scenario_reference,
        Variante = variante,
        `PIB moy.` = pib_growth,
        `Productivité moy.` = prod_growth,
        `Emploi moy.` = emp_growth,
        `Ratio PPA` = wage_ratio_ppa,
        `Solde migr. 2070` = net_migration_2070,
        `Population 2070` = population_2070,
        `Dépendance 2070` = old_age_dep_ratio
      )
    
    datatable(sens, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE) %>%
      formatCurrency(c("Solde migr. 2070", "Population 2070"), currency = "", mark = " ", digits = 0) %>%
      formatString(c("PIB moy.", "Productivité moy.", "Emploi moy.", "Dépendance 2070"), suffix = " %")
  })
}

# Lancement de l'application
shinyApp(ui = ui, server = server)
