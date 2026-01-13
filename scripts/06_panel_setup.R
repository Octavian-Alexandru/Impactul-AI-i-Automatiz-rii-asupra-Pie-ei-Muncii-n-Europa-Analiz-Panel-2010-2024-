# ==============================================================================
# 06_panel_setup.R
# Scop: Construirea datasetului panel (tara-an) pentru analiza econometrica.
# ==============================================================================

source("scripts/common.R")

library(tidyverse)
library(readxl)

raw_path <- "data/raw"
processed_path <- "data/processed"
if (!dir.exists(processed_path)) dir.create(processed_path, recursive = TRUE)

# Intervalul de timp dorit
start_year <- 2014
end_year <- 2023

# Daca TRUE, foloseste intersectia anilor comuni tuturor variabilelor principale
use_common_years <- TRUE

country_mapping <- data.frame(
  geo_label = c("Belgium", "Bulgaria", "Czechia", "Denmark", "Germany", "Estonia",
                "Ireland", "Greece", "Spain", "France", "Croatia", "Italy", "Cyprus",
                "Latvia", "Lithuania", "Luxembourg", "Hungary", "Malta", "Netherlands",
                "Austria", "Poland", "Portugal", "Romania", "Slovenia", "Slovakia",
                "Finland", "Sweden"),
  geo = c("BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES", "FR", "HR", "IT",
          "CY", "LV", "LT", "LU", "HU", "MT", "NL", "AT", "PL", "PT", "RO", "SI",
          "SK", "FI", "SE")
)

east_countries <- c("BG", "CZ", "EE", "HR", "HU", "LT", "LV", "PL", "RO", "SI", "SK")

read_panel_series <- function(file, sheet, skip, value_name) {
  full_path <- file.path(raw_path, file)
  if (!file.exists(full_path)) {
    warning(paste("Fisier lipsa:", file))
    return(NULL)
  }

  df_raw <- read_excel(full_path, sheet = sheet, skip = skip, .name_repair = "minimal")
  names(df_raw)[1] <- "geo_label"

  year_cols <- names(df_raw)[grepl("^\\d{4}$", names(df_raw))]
  if (length(year_cols) == 0) {
    warning(paste("Nu am gasit coloane de tip an in:", file))
    return(NULL)
  }

  df_long <- df_raw %>%
    select(geo_label, all_of(year_cols)) %>%
    pivot_longer(cols = all_of(year_cols), names_to = "year", values_to = value_name) %>%
    mutate(
      year = as.integer(year),
      "{value_name}" := suppressWarnings(as.numeric(.data[[value_name]]))
    ) %>%
    filter(!is.na(geo_label)) %>%
    filter(!grepl("European Union", geo_label)) %>%
    filter(!grepl("Euro area", geo_label)) %>%
    left_join(country_mapping, by = "geo_label") %>%
    filter(!is.na(geo)) %>%
    select(geo, year, all_of(value_name))

  df_long
}

message("--- Start configurare panel ---")

emp_tech <- read_panel_series(
  file = "employment_tech.csv.xlsx",
  sheet = "Sheet 6",
  skip = 8,
  value_name = "EMP_TECH"
)

desi_ai <- read_panel_series(
  file = "desi_ai.csv.xlsx",
  sheet = "Sheet 9",
  skip = 10,
  value_name = "DESI_AI"
)

stem_grad <- read_panel_series(
  file = "stem_graduates.csv.xlsx",
  sheet = "Sheet 1",
  skip = 9,
  value_name = "STEM_GRAD"
)

gov_rd <- read_panel_series(
  file = "gov_rd_expenditure.csv.xlsx",
  sheet = "Sheet 2",
  skip = 7,
  value_name = "GOV_RD"
)

gdp_cap <- read_panel_series(
  file = "gdp_per_capita.csv.xlsx",
  sheet = "Sheet 1",
  skip = 8,
  value_name = "GDP_CAP"
)

dig_skills <- read_panel_series(
  file = "digital_skills.csv.xlsx",
  sheet = "Sheet 33",
  skip = 9,
  value_name = "DIG_SKILLS"
)

wage_edu <- read_panel_series(
  file = "wages_education.csv.xlsx",
  sheet = "Sheet 3",
  skip = 11,
  value_name = "WAGE_EDU"
)

primary_series <- list(
  EMP_TECH = emp_tech,
  DESI_AI = desi_ai,
  STEM_GRAD = stem_grad,
  GOV_RD = gov_rd,
  GDP_CAP = gdp_cap,
  DIG_SKILLS = dig_skills
)

primary_series <- primary_series[!sapply(primary_series, is.null)]

years_list <- lapply(primary_series, function(df) sort(unique(df$year)))
if (length(years_list) == 0) {
  stop("Nu am putut identifica ani pentru variabilele principale.")
}

common_years <- Reduce(intersect, years_list)
common_years <- common_years[common_years >= start_year & common_years <= end_year]

panel_years <- if (use_common_years) common_years else seq(start_year, end_year)
if (length(panel_years) == 0) {
  stop("Nu exista ani comuni in intervalul specificat.")
}

panel_base <- expand_grid(geo = country_mapping$geo, year = panel_years)

panel <- panel_base %>%
  left_join(emp_tech, by = c("geo", "year")) %>%
  left_join(desi_ai, by = c("geo", "year")) %>%
  left_join(stem_grad, by = c("geo", "year")) %>%
  left_join(gov_rd, by = c("geo", "year")) %>%
  left_join(gdp_cap, by = c("geo", "year")) %>%
  left_join(dig_skills, by = c("geo", "year"))

if (!is.null(wage_edu)) {
  panel <- panel %>% left_join(wage_edu, by = c("geo", "year"))
}

panel <- panel %>%
  mutate(
    Region = ifelse(geo %in% east_countries, "East", "West"),
    Region = factor(Region, levels = c("West", "East")),
    ln_GDP_CAP = ifelse(GDP_CAP > 0, log(GDP_CAP), NA_real_),
    ln_EMP_TECH = ifelse(EMP_TECH > 0, log(EMP_TECH), NA_real_)
  ) %>%
  arrange(geo, year)

message(paste("Panel final:", nrow(panel), "observatii,", length(unique(panel$year)), "ani."))

saveRDS(panel, file = file.path(processed_path, "panel_data.rds"))
write.csv(panel, file = file.path(processed_path, "panel_data.csv"), row.names = FALSE)

message("Dataset panel salvat in data/processed/panel_data.rds")
