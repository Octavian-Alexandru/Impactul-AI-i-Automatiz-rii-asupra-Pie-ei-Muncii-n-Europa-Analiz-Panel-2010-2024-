# ==============================================================================
# 07_panel_model_selection.R
# Scop: Testarea alegerii intre FE si RE (F test, LM test, Hausman).
# ==============================================================================

source("scripts/common.R")

library(tidyverse)
library(plm)

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

pooled <- plm(form, data = pdata, model = "pooling")
fe_ind <- plm(form, data = pdata, model = "within", effect = "individual")
re_ind <- plm(form, data = pdata, model = "random", effect = "individual")

safe_test <- function(expr) {
  tryCatch(expr, error = function(e) {
    warning(e$message)
    return(NULL)
  })
}

ftest_ind <- safe_test(pFtest(fe_ind, pooled))
lmtest_re <- safe_test(plmtest(pooled, type = "bp"))
hausman <- safe_test(phtest(fe_ind, re_ind))

sink(file.path(output_tabs, "panel_model_tests.txt"))
cat("=== Panel model selection tests (FE vs RE) ===\n\n")
cat("Model formula:\n")
print(form)
cat("\n--- F test (FE vs pooled) ---\n")
print(ftest_ind)
cat("\n--- LM test (RE vs pooled) ---\n")
print(lmtest_re)
cat("\n--- Hausman test (FE vs RE) ---\n")
print(hausman)
sink()

to_row <- function(test, name) {
  if (is.null(test)) return(NULL)
  param <- test$parameter
  df_val <- if (is.null(param)) NA_character_ else paste(unname(param), collapse = ";")
  data.frame(
    Test = name,
    Statistic = unname(test$statistic),
    DF = df_val,
    P_Value = test$p.value,
    stringsAsFactors = FALSE
  )
}

tests_tbl <- bind_rows(
  to_row(ftest_ind, "F test (FE vs pooled)"),
  to_row(lmtest_re, "LM test (RE vs pooled)"),
  to_row(hausman, "Hausman (FE vs RE)")
)

write.csv(tests_tbl, file.path(output_tabs, "panel_model_tests.csv"), row.names = FALSE)

message("Testele FE vs RE au fost salvate in output/tables/panel_model_tests.txt")
