# R/load_data.R
# Chargement optimisé et mise en cache des données du dashboard

load_dashboard_data <- function(data_dir = "data") {
  if (!dir.exists(data_dir)) {
    if (dir.exists("../data")) {
      data_dir <- "../data"
    } else {
      stop("Dossier de données introuvable.")
    }
  }
  
  list(
    # Données unifiées propres
    clean = readRDS(file.path(data_dir, "projections_clean.rds")),
    
    # Résumé officiel des 4 scénarios (Tableau 4)
    summary_scenarios = readRDS(file.path(data_dir, "statec_scenarios_summary.rds")),
    
    # Indicateurs jalons (âge moyen, ratio de dépendance, Tableaux 2 et 3)
    milestones = readRDS(file.path(data_dir, "statec_milestones_indicators.rds")),
    
    # Trajectoires temporelles complètes STATEC (2000-2070)
    trajectories = readRDS(file.path(data_dir, "statec_trajectories.rds")),
    
    # Analyses de sensibilité (économiques et démographiques, Tableaux p. 56 et 67)
    sensitivities = readRDS(file.path(data_dir, "statec_sensitivities.rds")),
    
    # Projections Eurostat EUROPOP2025
    eurostat_ind = readRDS(file.path(data_dir, "eurostat_indicators.rds")),
    eurostat_pyr = readRDS(file.path(data_dir, "eurostat_pyramid.rds")),
    
    # Données historiques LUSTAT
    hist_pop = readRDS(file.path(data_dir, "historical_population.rds")),
    hist_comp = readRDS(file.path(data_dir, "historical_components.rds")),
    hist_flows = readRDS(file.path(data_dir, "historical_migration_flows.rds")),
    hist_pyr = readRDS(file.path(data_dir, "historical_pyramid.rds"))
  )
}
