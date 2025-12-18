# ==============================================================================
# 99_verify_all.R
# Scop: Rularea secventiala a intregului pipeline pentru a verifica functionarea.
# ==============================================================================

run_script <- function(script_name) {
  script_path <- file.path("scripts", script_name)
  message(paste("\n\n>>> Rulaseaza:", script_name, "<<<\n"))
  tryCatch({
    source(script_path)
    message(paste(">>> SUCCES:", script_name))
  }, error = function(e) {
    message(paste(">>> EROARE la:", script_name))
    message(e)
  })
}

# Ordinea de executie
scripts <- c(
  "00_setup.R",
  "01_data_cleaning.R",
  "02_eda.R",
  "03_econometric_models.R",
  "04_ml_models.R"
)

# Executie
for (s in scripts) {
  run_script(s)
}

message("\n\n=======================================================")
message(" VERIFICARE COMPLETA. Verifica folderul output/ pentru rezultate.")
message("=======================================================")
