# ==============================================================================
# 03_econometric_models.R
# Scop: Constructia modelelor de regresie OLS si diagnosticarea lor.
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

message("--- Start Modelare Econometrica ---")

# 2. Definirea Modelelor
# Model 1: Simplu (Impactul AI asupra Ocuparii Tech)
m1 <- lm(EMP_TECH ~ DESI_AI, data = df)

# Model 2: Complet (Cu variabile de control)
m2 <- lm(EMP_TECH ~ DESI_AI + STEM_GRAD + ln_GDP_CAP + GOV_RD, data = df)

# Model 3: Ajustat (Exemplu: eliminare GOV_RD daca e nesemnificativ sau folosire PC1)
m3 <- lm(EMP_TECH ~ PC1_Digital + ln_GDP_CAP, data = df)

# Model 4: Interactiuni (Non-liniaritate)
m4 <- lm(EMP_TECH ~ DESI_AI * STEM_GRAD + ln_GDP_CAP, data = df)

# 3. Raportare Rezultate (Stargazer)
stargazer(m1, m2, m3, m4, type = "text", 
          title = "Rezultatele Regresiei OLS (Variabila Dep: Ocupare Tech)",
          out = file.path(output_tabs, "regression_results.txt"))

# 4. Diagnosticare (pentru Modelul 2)
message("Diagnosticare Model Complet (m2)...")

# A. Normalitatea Reziduurilor (Jarque-Bera)
resid_m2 <- residuals(m2)
# Nota: shapiro.test este mai comun in R base
st_shapiro <- shapiro.test(resid_m2)
print(st_shapiro)

# B. Homoscedasticitate (Breusch-Pagan)
test_bp <- bptest(m2)
print(test_bp)

# C. Multicoliniaritate (VIF)
vif_res <- vif(m2)
print(vif_res)

# D. Testul RESET (Ramsey) pentru forma functionala
reset_res <- resettest(m2, power = 2:3, type = "regressor")
print(reset_res)

# 5. Scenariu de Prognoza (What-If)
# "Ce se intampla daca DESI_AI creste cu 10% pentru toate tarile?"
new_data <- df
new_data$DESI_AI <- new_data$DESI_AI * 1.10
# Recalculam PC1 daca e folosit (aproximativ sau exact daca pastram obiectul PCA)
# Aici facem o predictie simpla pe m2 (care foloseste DESI_AI direct)

pred_baseline <- predict(m2, newdata = df)
pred_scenario <- predict(m2, newdata = new_data)

mean_increase <- mean(pred_scenario - pred_baseline)
message(paste("Crestere medie estimata a ocuparii Tech la un boost de 10% AI:", round(mean_increase, 4)))

message("Modelarea clasica finalizata.")
