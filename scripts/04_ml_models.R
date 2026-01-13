# ==============================================================================
# 04_ml_models.R
# Scop: Ridge/Lasso/ElasticNet + comparatie cu OLS folosind acelasi Train/Test
#       + indicatori RMSE/MAE/MAPE/R2/Adj R2 (Req 5a-5c)
#       + optional: RF/GBM/SVR (Req 5d)
# ==============================================================================

source("scripts/common.R")

library(tidyverse)
library(glmnet)

# 1. Incarcare date
processed_path <- "data/processed/"
df <- readRDS(file.path(processed_path, "analysis_data_enriched.rds"))

output_tabs <- "output/tables/"
if (!dir.exists(output_tabs)) dir.create(output_tabs, recursive = TRUE)

message("--- Start Machine Learning (Regularizare + Train/Test) ---")

# ==============================================================================
# 1b. Fallback: daca Region nu exista, il construim (nu e obligatoriu pt ML,
# dar pastram consistenta si evitam surprize)
# ==============================================================================
if (!("Region" %in% names(df))) {
  message("WARNING: Region nu exista in dataset. O construim automat din geo (fallback).")
  east_countries <- c("BG", "CZ", "EE", "HR", "HU", "LT", "LV", "PL", "RO", "SI", "SK")
  df$Region <- ifelse(df$geo %in% east_countries, "East", "West")
  df$Region <- factor(df$Region, levels = c("West", "East"))
}

# ==============================================================================
# 2. Split Train/Test (aceeasi samanta ca la OLS)
# ==============================================================================
set.seed(123)
n <- nrow(df)
idx_train <- sample(seq_len(n), size = floor(0.8 * n), replace = FALSE)

train <- df[idx_train, ]
test  <- df[-idx_train, ]

# ==============================================================================
# 3. Pregatirea datelor
# ==============================================================================
var_dep <- "EMP_TECH"
vars_indep <- c("DESI_AI", "STEM_GRAD", "GOV_RD", "GDP_CAP", "DIG_SKILLS", "WAGE_EDU")

df_train <- train %>% select(all_of(c(var_dep, vars_indep))) %>% na.omit()
df_test  <- test  %>% select(all_of(c(var_dep, vars_indep))) %>% na.omit()

x_train <- as.matrix(df_train[, vars_indep])
y_train <- df_train[[var_dep]]

x_test <- as.matrix(df_test[, vars_indep])
y_test <- df_test[[var_dep]]

# ==============================================================================
# 4. Metrics
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

calc_metrics <- function(actual, pred, k) {
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
# 5. Model econometric optim (pentru comparatie ML vs OLS optim)
# ==============================================================================
if (!("ln_GDP_CAP" %in% names(df))) {
  df$ln_GDP_CAP <- log(df$GDP_CAP)
}

if (!("Region" %in% names(train))) {
  stop("Region lipseste din train; nu pot estima modelele OLS cu dummy.")
}

ols_m1 <- lm(EMP_TECH ~ DESI_AI + Region, data = train)
ols_m2 <- lm(EMP_TECH ~ DESI_AI + STEM_GRAD + ln_GDP_CAP + GOV_RD + Region, data = train)
ols_m4 <- lm(EMP_TECH ~ DESI_AI * STEM_GRAD + ln_GDP_CAP + Region, data = train)
ols_m6 <- lm(EMP_TECH ~ DESI_AI + I(DESI_AI^2) + STEM_GRAD + ln_GDP_CAP + GOV_RD + Region,
             data = train)

ols_models <- list(
  m1 = ols_m1,
  m2 = ols_m2,
  m4 = ols_m4,
  m6_poly = ols_m6
)

ols_fit <- data.frame(
  Model = names(ols_models),
  Adj_R2 = sapply(ols_models, function(m) summary(m)$adj.r.squared),
  BIC = sapply(ols_models, BIC),
  row.names = NULL
)

ols_best_name <- ols_fit$Model[order(ols_fit$BIC, -ols_fit$Adj_R2)][1]
ols_best_model <- ols_models[[ols_best_name]]

preds_ols_best <- predict(ols_best_model, newdata = test)
k_ols_best <- length(coef(ols_best_model)) - 1

# ==============================================================================
# 6. Ridge (alpha = 0)
# ==============================================================================
set.seed(123)
cv_ridge <- cv.glmnet(x_train, y_train, alpha = 0)
best_lambda_ridge <- cv_ridge$lambda.min
message(paste("Lambda optim Ridge:", best_lambda_ridge))

model_ridge <- glmnet(x_train, y_train, alpha = 0, lambda = best_lambda_ridge)

# ==============================================================================
# 7. Lasso (alpha = 1)
# ==============================================================================
set.seed(123)
cv_lasso <- cv.glmnet(x_train, y_train, alpha = 1)
best_lambda_lasso <- cv_lasso$lambda.min
message(paste("Lambda optim Lasso:", best_lambda_lasso))

model_lasso <- glmnet(x_train, y_train, alpha = 1, lambda = best_lambda_lasso)

message("Coeficientii Lasso (feature selection):")
print(coef(model_lasso))

# ==============================================================================
# 8. Elastic Net (alpha = 0.5) - Req 5a
# ==============================================================================
set.seed(123)
cv_elnet <- cv.glmnet(x_train, y_train, alpha = 0.5)
best_lambda_elnet <- cv_elnet$lambda.min
message(paste("Lambda optim ElasticNet:", best_lambda_elnet))

model_elnet <- glmnet(x_train, y_train, alpha = 0.5, lambda = best_lambda_elnet)

# ==============================================================================
# 9. Comparatie performanta pe TEST: OLS vs Ridge vs Lasso vs ElasticNet
# ==============================================================================
ols_model <- lm(EMP_TECH ~ ., data = df_train)
preds_ols <- predict(ols_model, newdata = df_test)

preds_ridge <- as.numeric(predict(model_ridge, s = best_lambda_ridge, newx = x_test))
preds_lasso <- as.numeric(predict(model_lasso, s = best_lambda_lasso, newx = x_test))
preds_elnet <- as.numeric(predict(model_elnet, s = best_lambda_elnet, newx = x_test))

k_ols <- length(coef(ols_model)) - 1
k_ridge <- sum(as.matrix(coef(model_ridge))[-1, 1] != 0)
k_lasso <- sum(as.matrix(coef(model_lasso))[-1, 1] != 0)
k_elnet <- sum(as.matrix(coef(model_elnet))[-1, 1] != 0)

res_list <- list(
  data.frame(
    Model = paste0("OLS Optimal (", ols_best_name, ")"),
    calc_metrics(y_test, preds_ols_best, k_ols_best)
  ),
  data.frame(Model = "OLS Full", calc_metrics(y_test, preds_ols, k_ols)),
  data.frame(Model = "Ridge", calc_metrics(y_test, preds_ridge, k_ridge)),
  data.frame(Model = "Lasso", calc_metrics(y_test, preds_lasso, k_lasso)),
  data.frame(Model = "ElasticNet", calc_metrics(y_test, preds_elnet, k_elnet))
)

# ==============================================================================
# 10. Optional: modele avansate (Req 5d)
# ==============================================================================
if (requireNamespace("randomForest", quietly = TRUE)) {
  set.seed(123)
  rf_model <- randomForest::randomForest(x = x_train, y = y_train)
  rf_pred <- predict(rf_model, x_test)
  res_list <- append(res_list, list(
    data.frame(Model = "RandomForest", calc_metrics(y_test, rf_pred, ncol(x_train)))
  ))
} else {
  message("RandomForest nu este instalat. Sar peste modelul RF.")
}

if (requireNamespace("gbm", quietly = TRUE)) {
  set.seed(123)
  train_gbm <- as.data.frame(x_train)
  train_gbm$y <- y_train
  gbm_model <- gbm::gbm(
    y ~ .,
    data = train_gbm,
    distribution = "gaussian",
    n.trees = 500,
    interaction.depth = 3,
    shrinkage = 0.05,
    n.minobsinnode = 5,
    verbose = FALSE
  )
  test_gbm <- as.data.frame(x_test)
  gbm_pred <- predict(gbm_model, newdata = test_gbm, n.trees = gbm_model$n.trees)
  res_list <- append(res_list, list(
    data.frame(Model = "GradientBoosting", calc_metrics(y_test, gbm_pred, ncol(x_train)))
  ))
} else {
  message("GBM nu este instalat. Sar peste modelul Gradient Boosting.")
}

if (requireNamespace("e1071", quietly = TRUE)) {
  set.seed(123)
  svm_model <- e1071::svm(x = x_train, y = y_train, kernel = "radial", scale = TRUE)
  svm_pred <- predict(svm_model, x_test)
  res_list <- append(res_list, list(
    data.frame(Model = "SVR", calc_metrics(y_test, svm_pred, ncol(x_train)))
  ))
} else {
  message("e1071 nu este instalat. Sar peste modelul SVR.")
}

res_comparatie <- bind_rows(res_list)

print(res_comparatie)
write.csv(res_comparatie, file.path(output_tabs, "ml_comparison_test.csv"), row.names = FALSE)

message("Analiza ML finalizata.")
