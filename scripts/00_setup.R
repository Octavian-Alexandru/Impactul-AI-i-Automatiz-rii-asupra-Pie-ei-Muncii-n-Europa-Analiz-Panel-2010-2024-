# ==============================================================================
# 00_setup.R
# Scop: Instalarea si incarcarea pachetelor R necesare pentru proiect.
# ==============================================================================

# Lista pachetelor necesare
required_packages <- c(
  "tidyverse",  # Manipulare date (dplyr, tidyr, ggplot2)
  "readxl",     # Citire fisiere Excel
  "VIM",        # Vizualizare date lipsa
  "mice",       # Imputare date lipsa
  "cluster",    # Algoritmi de clustering
  "factoextra", # Vizualizare clustering si PCA
  "lmtest",     # Teste de diagnostic econometric
  "sandwich",   # Erori standard robuste
  "car",        # VIF si alte teste
  "stargazer",  # Tabele frumoase pentru raport
  "glmnet",     # Ridge, Lasso, Elastic Net
  "caret",      # Machine Learning workflow
  "corrplot"    # Vizualizare matrici de corelatie
)

# Definirea unei librarii locale in proiect pentru a evita erori de permisiuni
local_lib <- file.path(getwd(), "r_libs")
if (!dir.exists(local_lib)) dir.create(local_lib)
.libPaths(c(local_lib, .libPaths()))

message(paste("Utilizam libraria locala:", local_lib))

# Functie pentru instalare si incarcare
install_and_load <- function(packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE, lib.loc = local_lib)) {
      message(paste("Instalez pachetul:", pkg))
      # Setam repo-ul CRAN explicit pentru a evita prompt-ul
      install.packages(pkg, dependencies = TRUE, lib = local_lib, repos = "http://cran.us.r-project.org")
      
      # Incarcam din nou dupa instalare
      if(!require(pkg, character.only = TRUE, lib.loc = local_lib)) {
         warning(paste("Nu s-a putut incarca pachetul:", pkg))
      }
    } else {
      message(paste("Pachetul este deja instalat:", pkg))
    }
  }
}

# Executare
install_and_load(required_packages)

message("\n=======================================================")
message(" Configurare completa! Toate pachetele sunt pregatite.")
message("=======================================================")
