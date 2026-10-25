# tests/test_shiny_server.R
# Tests unitaires du serveur Shiny avec shiny::testServer

library(testthat)
library(shiny)

root_dir <- if (file.exists("app.R")) "." else ".."

test_that("Le serveur Shiny s'initialise et réagit correctement aux sélecteurs", {
  # Sourcing within root dir context
  old_wd <- setwd(root_dir)
  on.exit(setwd(old_wd), add = TRUE)
  
  source("app.R")
  
  testServer(server, {
    # 1. Test onglet Vue d'ensemble
    session$setInputs(overview_year = 2070, overview_show_eurostat = TRUE)
    expect_true(!is.null(output$overview_kpi_ui))
    expect_true(!is.null(output$overview_plot))
    
    # Changer l'année à 2040
    session$setInputs(overview_year = 2040)
    expect_true(!is.null(output$overview_kpi_ui))
    
    # 2. Test onglet Explorer les scénarios
    session$setInputs(
      selected_scenarios = c("SC1", "SC4"),
      scenario_indicator = "population",
      compare_base_sc1 = FALSE
    )
    expect_true(!is.null(output$scenario_plot))
    expect_true(!is.null(output$table_scenarios_summary))
    
    # Test avec comparaison à SC1
    session$setInputs(compare_base_sc1 = TRUE)
    expect_true(!is.null(output$scenario_plot))
    
    # 3. Test onglet Migrations
    session$setInputs(mig_scenario = "SC4")
    expect_true(!is.null(output$decomposition_plot))
    expect_true(!is.null(output$flows_history_plot))
    
    # 4. Test onglet Vieillissement
    session$setInputs(pyramid_year = 2050)
    expect_true(!is.null(output$pyramid_plot))
    expect_true(!is.null(output$table_mean_age))
    expect_true(!is.null(output$table_dep_ratio))
    
    # 5. Test onglet Comparaison Eurostat
    expect_true(!is.null(output$eurostat_comparison_plot))
    expect_true(!is.null(output$table_eurostat_diff))
    
    # 6. Test tableau des sensibilités
    expect_true(!is.null(output$table_all_sensitivities))
  })
})
