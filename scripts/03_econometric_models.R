# ==============================================================================
# 03_econometric_models.R
# Scop: OLS + diagnostic + Train/Test + functional forms (log-log, polynomial)
#       + dummy/interactions + model selection + scenario de prognoza
# ==============================================================================

source("scripts/common.R")

library(tidyverse)
library(lmtest)
library(sandwich)
library(car)
library(stargazer)

# 1. Incarcare date
processed_path <- "data/processed/"
df <- readRDS(file.path(processed_path, "analysis_data_enriched.rds"))

output_tabs <- "output/tables/"
if (!dir.exists(output_tabs)) dir.create(output_tabs, recursive = TRUE)

message("--- Start Modelare Econometrica (Train/Test + functional forms) ---")

# ==============================================================================
# 1b. Fallback: daca Region nu exista in RDS, o construim aici
# ==============================================================================
if (!("Region" %in% names(df))) {
  message("WARNING: Region nu exista in dataset. O construim automat din geo (fallback).")
  east_countries <- c("BG", "CZ", "EE", "HR", "HU", "LT", "LV", "PL", "RO", "SI", "SK")
  df$Region <- ifelse(df$geo %in% east_countries, "East", "West")
  df$Region <- factor(df$Region, levels = c("West", "East"))
}

# ==============================================================================
# 1c. Asiguram variabilele log (pentru modelele alternative)
# ==============================================================================
if (!("ln_GDP_CAP" %in% names(df))) {
  df$ln_GDP_CAP <- log(df$GDP_CAP)
}

df <- df %>%
  mutate(
    ll_EMP_TECH = log1p(EMP_TECH),
    ll_DESI_AI = log1p(DESI_AI),
    ll_STEM_GRAD = log1p(STEM_GRAD),
    ll_GOV_RD = log1p(GOV_RD),
    ll_GDP_CAP = log1p(GDP_CAP)
  )

# ==============================================================================
# 2. Helpers metrics (Req 3c)
# ==============================================================================
rmse <- function(actual, pred) sqrt(mean((actual - pred)^2, na.rm = TRUE))
mae  <- function(actual, pred) mean(abs(actual - pred), na.rm = TRUE)
mape <- function(actual, pred) {
  denom <- pmax(abs(actual), .Machine$double.eps)
  mean(abs((actual - pred) / denom), na.rm = TRUE) * 100
}
r2 <- function(actual, pred) {
  ss_res <- sum((actual - pred)^2, na.rm = TRUE)
  ss_tot <- sum((actual - mean(actual, na.rm = TRUE))^2, na.rm = TRUE)
  if (is.na(ss_tot) || ss_tot == 0) return(NA_real_)
  1 - (ss_res / ss_tot)
}
adj_r2 <- function(r2_value, n, k) {
  if (is.na(r2_value)) return(NA_real_)
  if (n - k - 1 <= 0) return(NA_real_)
  1 - (1 - r2_value) * (n - 1) / (n - k - 1)
}

calc_test_metrics <- function(actual, pred, k) {
  ok <- is.finite(actual) & is.finite(pred)
  actual <- actual[ok]
  pred <- pred[ok]
  n <- length(actual)
  r2_val <- r2(actual, pred)
  data.frame(
    RMSE_Test = rmse(actual, pred),
    MAE_Test = mae(actual, pred),
    MAPE_Test = mape(actual, pred),
    R2_Test = r2_val,
    Adj_R2_Test = adj_r2(r2_val, n, k)
  )
}

# ==============================================================================
# 3. Train/Test split 80/20 (Req 3c)
# ==============================================================================
set.seed(123)
n <- nrow(df)
idx_train <- sample(seq_len(n), size = floor(0.8 * n), replace = FALSE)

train <- df[idx_train, ]
test  <- df[-idx_train, ]

# ==============================================================================
# 4. Definirea modelelor OLS (antrenare pe TRAIN)
# ==============================================================================
m1 <- lm(EMP_TECH ~ DESI_AI + Region, data = train)

m2 <- lm(EMP_TECH ~ DESI_AI + STEM_GRAD + ln_GDP_CAP + GOV_RD + Region, data = train)

m3 <- lm(EMP_TECH ~ PC1_Digital + ln_GDP_CAP + Region, data = train)

m4 <- lm(EMP_TECH ~ DESI_AI * STEM_GRAD + ln_GDP_CAP + Region, data = train)

# Log-log (Req 4a) - folosim log1p pentru stabilitate la valori mici
m5_loglog <- lm(ll_EMP_TECH ~ ll_DESI_AI + ll_STEM_GRAD + ll_GDP_CAP + ll_GOV_RD + Region,
                data = train)

# Polinomial (Req 4a)
m6_poly <- lm(EMP_TECH ~ DESI_AI + I(DESI_AI^2) + STEM_GRAD + ln_GDP_CAP + GOV_RD + Region,
              data = train)

models <- list(
  m1 = m1,
  m2 = m2,
  m3 = m3,
  m4 = m4,
  m5_loglog = m5_loglog,
  m6_poly = m6_poly
)

# ==============================================================================
# 5. Raportare coeficienti (TRAIN) - Stargazer
# ==============================================================================
stargazer(m1, m2, m3, m4, type = "text",
          title = "Rezultatele Regresiei OLS (TRAIN) (Variabila Dep: EMP_TECH)",
          out = file.path(output_tabs, "regression_results_train.txt"))

stargazer(m5_loglog, m6_poly, type = "text",
          title = "Forme Functionale Alternative (TRAIN)",
          out = file.path(output_tabs, "regression_results_train_alt.txt"))

# ==============================================================================
# 6. Evaluare out-of-sample pe TEST (Req 3c)
# ==============================================================================
pred_m1 <- predict(m1, newdata = test)
pred_m2 <- predict(m2, newdata = test)
pred_m3 <- predict(m3, newdata = test)
pred_m4 <- predict(m4, newdata = test)
pred_m5_ll <- predict(m5_loglog, newdata = test)
pred_m5 <- expm1(pred_m5_ll)
pred_m6 <- predict(m6_poly, newdata = test)

test_metrics <- bind_rows(
  cbind(Model = "m1", calc_test_metrics(test$EMP_TECH, pred_m1, k = length(coef(m1)) - 1)),
  cbind(Model = "m2", calc_test_metrics(test$EMP_TECH, pred_m2, k = length(coef(m2)) - 1)),
  cbind(Model = "m3", calc_test_metrics(test$EMP_TECH, pred_m3, k = length(coef(m3)) - 1)),
  cbind(Model = "m4", calc_test_metrics(test$EMP_TECH, pred_m4, k = length(coef(m4)) - 1)),
  cbind(Model = "m5_loglog", calc_test_metrics(test$EMP_TECH, pred_m5, k = length(coef(m5_loglog)) - 1)),
  cbind(Model = "m6_poly", calc_test_metrics(test$EMP_TECH, pred_m6, k = length(coef(m6_poly)) - 1))
)

print(test_metrics)
write.csv(test_metrics, file.path(output_tabs, "ols_test_metrics.csv"), row.names = FALSE)

# ==============================================================================
# 7. Criterii econometrice (bonitate) pentru selectie (TRAIN)
# ==============================================================================
fit_metrics <- data.frame(
  Model = names(models),
  R2 = sapply(models, function(m) summary(m)$r.squared),
  Adj_R2 = sapply(models, function(m) summary(m)$adj.r.squared),
  AIC = sapply(models, AIC),
  BIC = sapply(models, BIC),
  row.names = NULL
)

print(fit_metrics)
write.csv(fit_metrics, file.path(output_tabs, "ols_model_fit.csv"), row.names = FALSE)

# Selectie model optim (criterii econometrice: BIC minim, apoi Adj_R2 maxim)
# Folosim doar modele care includ DESI_AI pentru consistenta scenariului.
models_level <- c("m1", "m2", "m4", "m6_poly")
fit_level <- fit_metrics %>% filter(Model %in% models_level)
best_model_name <- fit_level$Model[order(fit_level$BIC, -fit_level$Adj_R2)][1]
best_model <- models[[best_model_name]]

best_by_rmse <- test_metrics$Model[order(test_metrics$RMSE_Test)][1]

message(paste("Model optim (criterii econometrice):", best_model_name))
message(paste("Model optim (predictiv, RMSE):", best_by_rmse))

# ==============================================================================
# 8. Diagnosticare (pe modelul optim) + corectii
# ==============================================================================
message(paste("Diagnosticare model optim:", best_model_name))

diag_path <- file.path(output_tabs, "ols_diagnostics.txt")
sink(diag_path)
cat("Diagnostics for model:", best_model_name, "\n\n")
print(summary(best_model))

resid_best <- residuals(best_model)

cat("\n--- Shapiro (normalitate) ---\n")
print(shapiro.test(resid_best))

cat("\n--- Breusch-Pagan (heteroscedasticitate) ---\n")
bp_res <- bptest(best_model)
print(bp_res)

cat("\n--- VIF (multicoliniaritate) ---\n")
print(vif(best_model))

cat("\n--- RESET (forma functionala) ---\n")
print(resettest(best_model, power = 2:3, type = "regressor"))
sink()

robust_path <- file.path(output_tabs, "ols_coefficients_robust.txt")
sink(robust_path)
cat("Robust SE (HC1) for model:", best_model_name, "\n\n")
print(coeftest(best_model, vcov = vcovHC(best_model, type = "HC1")))
sink()

# ==============================================================================
# 9. Scenariu What-If (Req 4b) pe modelul optim
# ==============================================================================
message("Scenariu What-If: +10% DESI_AI doar in tarile din East (pe TEST)...")

predict_best <- function(newdata) {
  pred <- predict(best_model, newdata = newdata)
  if (best_model_name == "m5_loglog") {
    return(expm1(pred))
  }
  pred
}

scenario_data <- test
scenario_data$DESI_AI <- ifelse(scenario_data$Region == "East",
                                scenario_data$DESI_AI * 1.10,
                                scenario_data$DESI_AI)

pred_baseline <- predict_best(test)
pred_scenario <- predict_best(scenario_data)

mean_increase_east <- mean(
  (pred_scenario - pred_baseline)[test$Region == "East"],
  na.rm = TRUE
)

scenario_res <- data.frame(
  Scenario = "AI +10% in East",
  Model = best_model_name,
  Mean_Increase_East = mean_increase_east
)

write.csv(scenario_res, file.path(output_tabs, "scenario_results.csv"), row.names = FALSE)
message(paste("Crestere medie estimata a EMP_TECH in EAST:", round(mean_increase_east, 4)))

message("Modelarea clasica finalizata.")
