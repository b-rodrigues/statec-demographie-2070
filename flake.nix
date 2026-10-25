{
  description = "STATEC Projections démographiques 2070 - Dashboard Shiny";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://rstats-on-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0="
    ];
  };

  inputs = {
    nixpkgs.url = "github:rstats-on-nix/nixpkgs/2026-09-04";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        rEnv = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            shiny
            bslib
            bsicons
            plotly
            ggplot2
            scales
            DT
            readr
            readxl
            dplyr
            tidyr
            purrr
            stringr
            janitor
            jsonlite
            knitr
            rmarkdown
            testthat
            curl
            httr2
            rsconnect
          ];
        };

        pythonEnv = pkgs.python3.withPackages (
          ps: with ps; [
            openpyxl 
          ]
        );
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            rEnv
            pkgs.quarto
            pkgs.pandoc
            pkgs.poppler-utils
            pythonEnv
          ];
          QUARTO_R = "${rEnv}/bin/R";
        };
      }
    );
}
