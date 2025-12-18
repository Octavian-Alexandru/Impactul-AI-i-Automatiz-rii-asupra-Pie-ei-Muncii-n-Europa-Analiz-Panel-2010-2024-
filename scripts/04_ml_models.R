# ==============================================================================
# 04_ml_models.R
# Scop: Implementare Ridge/Lasso si comparatie cu OLS.
# ==============================================================================

source("scripts/common.R")

library(tidyverse)
library(glmnet)
library(caret)

# 1. Incarcare date
processed_path <- "data/processed/"
df <- readRDS(file.path(processed_path, "analysis_data_enriched.rds"))
output_tabs <- "output/tables/"

message("--- Start Machine Learning (Regularizare) ---")

# 2. Pregatirea datelor
# Excludem coloanele nenumerice si variabila dependenta din matricea X
var_dep <- "EMP_TECH"
vars_indep <- c("DESI_AI", "STEM_GRAD", "GOV_RD", "GDP_CAP", "DIG_SKILLS", "WAGE_EDU")

# Gestionam missing values daca au mai ramas (deja tratate in pasul 1, dar just for safety)
df_model <- df %>% select(all_of(c(var_dep, vars_indep))) %>% na.omit()

x <- as.matrix(df_model[, vars_indep])
y <- df_model[[var_dep]]

# 3. Ridge Regression (alpha = 0)
set.seed(123)
cv_ridge <- cv.glmnet(x, y, alpha = 0) # Cross-validation pentru lambda
best_lambda_ridge <- cv_ridge$lambda.min
message(paste("Lambda optim Ridge:", best_lambda_ridge))

model_ridge <- glmnet(x, y, alpha = 0, lambda = best_lambda_ridge)

# 4. Lasso Regression (alpha = 1)
set.seed(123)
cv_lasso <- cv.glmnet(x, y, alpha = 1)
best_lambda_lasso <- cv_lasso$lambda.min
message(paste("Lambda optim Lasso:", best_lambda_lasso))

model_lasso <- glmnet(x, y, alpha = 1, lambda = best_lambda_lasso)

# Coeficientii Lasso (Feature Selection)
# Variabilele cu coeficient 0 au fost eliminate
coef_lasso <- coef(model_lasso)
print(coef_lasso)

# 5. Comparatie Performanta (OLS vs Ridge vs Lasso)
# Folosim Caret pentru o evaluare corecta pe tot setul (sau split)
# Pentru simplificare, calculam RMSE pe setul complet (in-sample)
# Intr-un scenariu ideal am face Train/Test split.

preds_ols <- predict(lm(EMP_TECH ~ ., data = df_model), newdata = df_model)
preds_ridge <- predict(model_ridge, s = best_lambda_ridge, newx = x)
preds_lasso <- predict(model_lasso, s = best_lambda_lasso, newx = x)

rmse <- function(actual, pred) { sqrt(mean((actual - pred)^2)) }

res_comparatie <- data.frame(
  Model = c("OLS Full", "Ridge", "Lasso"),
  RMSE = c(
    rmse(y, preds_ols),
    rmse(y, preds_ridge),
    rmse(y, preds_lasso)
  )
)

print(res_comparatie)
write.csv(res_comparatie, file.path(output_tabs, "ml_comparison.csv"), row.names = FALSE)

message("Analiza ML finalizata.")
