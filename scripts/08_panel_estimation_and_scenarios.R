# ==============================================================================
# 08_panel_estimation_and_scenarios.R
# Scop: Estimare model panel ales (RE), teste pe reziduuri, scenarii de prognoza.
# ==============================================================================

source("scripts/common.R")

library(tidyverse)
library(plm)
library(lmtest)
library(sandwich)

processed_path <- "data/processed"
panel_path <- file.path(processed_path, "panel_data.rds")
output_tabs <- "output/tables"
if (!dir.exists(output_tabs)) dir.create(output_tabs, recursive = TRUE)

if (!file.exists(panel_path)) {
  stop("Dataset panel lipseste. Ruleaza scripts/06_panel_setup.R mai intai.")
}

df <- readRDS(panel_path)

vars <- c("EMP_TECH", "DESI_AI", "STEM_GRAD", "ln_GDP_CAP", "GOV_RD", "DIG_SKILLS")
df_model <- df %>%
  select(geo, year, all_of(vars)) %>%
  drop_na()

if (nrow(df_model) == 0) {
  stop("Nu exista observatii complete pentru modelul panel.")
}

message(paste("Panel folosit:", nrow(df_model), "observatii.",
              "Ani:", paste(sort(unique(df_model$year)), collapse = ", ")))

pdata <- pdata.frame(df_model, index = c("geo", "year"))

form <- EMP_TECH ~ DESI_AI + STEM_GRAD + ln_GDP_CAP + GOV_RD + DIG_SKILLS

re_model <- plm(form, data = pdata, model = "random", effect = "individual")

# Salvare rezultate estimare
sink(file.path(output_tabs, "panel_re_summary.txt"))
cat("=== Panel RE model summary ===\n\n")
print(summary(re_model))
cat("\n--- Robust SE (HC1) ---\n")
print(coeftest(re_model, vcov = vcovHC(re_model, type = "HC1")))
sink()

# Teste pe reziduuri
resid_re <- residuals(re_model)

shapiro_res <- if (length(resid_re) >= 3 && length(resid_re) <= 5000) {
  shapiro.test(resid_re)
} else {
  NULL
}

bp_res <- tryCatch(bptest(re_model), error = function(e) NULL)
dw_res <- tryCatch(pdwtest(re_model), error = function(e) NULL)
bg_res <- tryCatch(pbgtest(re_model), error = function(e) NULL)

sink(file.path(output_tabs, "panel_residual_tests.txt"))
cat("=== Panel residual diagnostics ===\n\n")
cat("--- Shapiro (normalitate) ---\n")
print(shapiro_res)
cat("\n--- Breusch-Pagan (heteroscedasticitate) ---\n")
print(bp_res)
cat("\n--- Durbin-Watson (autocorelatie) ---\n")
print(dw_res)
cat("\n--- Breusch-Godfrey (autocorelatie) ---\n")
print(bg_res)
sink()

# Scenariu: +10% DESI_AI in tarile East, pe ultimul an disponibil
east_countries <- c("BG", "CZ", "EE", "HR", "HU", "LT", "LV", "PL", "RO", "SI", "SK")
year_ref <- max(df_model$year, na.rm = TRUE)

scenario_data <- df_model %>% filter(year == year_ref)
if (nrow(scenario_data) > 0) {
  X_base <- model.matrix(form, data = scenario_data)
  pred_base <- as.numeric(X_base %*% coef(re_model))

  scenario_data$DESI_AI <- ifelse(
    scenario_data$geo %in% east_countries,
    scenario_data$DESI_AI * 1.10,
    scenario_data$DESI_AI
  )

  X_scen <- model.matrix(form, data = scenario_data)
  pred_scen <- as.numeric(X_scen %*% coef(re_model))

  mean_increase_east <- mean(
    (pred_scen - pred_base)[scenario_data$geo %in% east_countries],
    na.rm = TRUE
  )
  mean_increase_all <- mean(pred_scen - pred_base, na.rm = TRUE)

  scenario_res <- data.frame(
    Scenario = "AI +10% in East",
    Year = year_ref,
    Mean_Increase_East = mean_increase_east,
    Mean_Increase_All = mean_increase_all
  )

  write.csv(scenario_res, file.path(output_tabs, "panel_scenario_results.csv"), row.names = FALSE)
} else {
  warning("Nu exista observatii pentru scenariu.")
}

message("Estimare RE, teste pe reziduuri si scenariu panel finalizate.")
