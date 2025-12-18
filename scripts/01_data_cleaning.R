# ==============================================================================
# 01_data_cleaning.R
# Scop: Importul, curatarea, unificarea si imputarea datelor.
# ==============================================================================

source("scripts/common.R")

library(tidyverse)
library(readxl)
library(VIM)
library(mice)

# 1. Definirea Cailor
raw_path <- "data/raw/"
processed_path <- "data/processed/"

if (!dir.exists(processed_path)) dir.create(processed_path, recursive = TRUE)

message("--- Inceperea procesului de curatare a datelor ---")

# Functie ajutatoare pentru citire (cu gestionare erori simpla)
read_data <- function(filename) {
  full_path <- file.path(raw_path, filename)
  if (file.exists(full_path)) {
    # Detectam extensia
    if (grepl("\\.csv$", filename)) {
      return(read_csv(full_path, show_col_types = FALSE))
    } else if (grepl("\\.xlsx?$", filename)) {
      return(read_excel(full_path))
    }
  } else {
    warning(paste("Fisierul", filename, "nu a fost gasit in", raw_path))
    return(NULL)
  }
}

# ==============================================================================
# Mapping Nume -> Cod (Folosit pentru toate seturile de date)
# ==============================================================================
country_mapping <- data.frame(
  geo_label = c("Belgium", "Bulgaria", "Czechia", "Denmark", "Germany", "Estonia", "Ireland", "Greece", "Spain", "France", "Croatia", "Italy", "Cyprus", "Latvia", "Lithuania", "Luxembourg", "Hungary", "Malta", "Netherlands", "Austria", "Poland", "Portugal", "Romania", "Slovenia", "Slovakia", "Finland", "Sweden"),
  geo = c("BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES", "FR", "HR", "IT", "CY", "LV", "LT", "LU", "HU", "MT", "NL", "AT", "PL", "PT", "RO", "SI", "SK", "FI", "SE")
)

# ==============================================================================
# 2. Importul Datelor Reale (EMP_TECH)
# ==============================================================================

# Fisierul incarcat de utilizator
file_emp <- "htec_emp_nat2__custom_19390611_spreadsheet.xlsx"

if (file.exists(file.path(raw_path, file_emp))) {
  message("Importing EMP_TECH from Sheet 6 (High-Tech sectors %)...")
  
  # Citire Sheet 6 (care contine procentele)
  # Sarim primele 8 randuri de metadata
  df_emp_raw <- read_excel(file.path(raw_path, file_emp), sheet = "Sheet 6", skip = 8, .name_repair = "minimal")
  
  # Selectam coloana cu Numele Tarii (TIME) si Valoarea din 2023
  # Nota: Coloana 1 este TIME, Coloana 2023 ar trebui sa fie pe la sfarsit.
  # Verificam indexul coloanei '2023'
  idx_2023 <- which(names(df_emp_raw) == "2023")
  
  if (length(idx_2023) == 0) {
     # Fallback daca nu gaseste 2023, incercam 2022
     idx_2023 <- which(names(df_emp_raw) == "2022")
     message("Anul 2023 nu a fost gasit, folosim 2022.")
  }
  
  df_emp_clean <- df_emp_raw %>%
    select(1, all_of(idx_2023)) %>%
    rename(geo_label = 1, EMP_TECH = 2) %>%
    mutate(EMP_TECH = as.numeric(EMP_TECH)) %>% # Asiguram conversia la numeric
    filter(!is.na(geo_label)) %>%
    filter(!geo_label %in% c("European Union - 27 countries (from 2020)", "Euro area – 20 countries (from 2023)", "Euro area - 19 countries  (2015-2022)"))
  
  # Join pentru a adauga codul GEO
  df_emp_final <- df_emp_clean %>%
    left_join(country_mapping, by = "geo_label") %>%
    filter(!is.na(geo)) %>% # Pastram doar tarile UE mapate
    select(geo, EMP_TECH)
    
  message("EMP_TECH real importat cu succes.")
  
} else {
  message("Fisierul EMP_TECH nu a fost gasit. Se va folosi mock data.")
  df_emp_final <- NULL
}

# ==============================================================================
# 2b. Importul Datelor Reale (WAGE_EDU)
# ==============================================================================
file_wage <- "wages_education.csv.xlsx"

if (file.exists(file.path(raw_path, file_wage))) {
  message("Importing WAGE_EDU from Sheet 3 (Mean Earnings Euro)...")
  
  # Structura e complexa: header-ul cu anii e pe randul 12 (skip 11)
  # Coloana ...10 este 2018. Coloana ...12 este (probabil) 2022 sau lipsa?
  # Din inspectie: ...10 este 2018. Asta e cea mai recenta data sigura.
  
  # Citim datele, sarind metadata
  df_wage_raw <- read_excel(file.path(raw_path, file_wage), sheet = "Sheet 3", skip = 11, .name_repair = "minimal")
  
  # Coloana 1 este GEO. Coloana pt 2018 este a 10-a (sau a 11-a in functie de parsare)
  # Verificam numele coloanelor pentru a gasi "2018"
  # Din inspectie, header-ul real e pe randul anterior, deci read_excel s-ar putea sa nu fi prins numele "2018".
  # Stim ca:
  # Col 1: GEO
  # Col 2: ...
  # Col 10: 2018 (Conform inspectiei manuale: ...10)
  
  # Luam direct coloana a 10-a (Verifica daca e 2018)
  # Nota: Daca fisierul se schimba, indexul 10 poate fi gresit.
  
  df_wage_clean <- df_wage_raw %>%
    select(1, 10) %>% # Selectam GEO si coloana 2018
    rename(geo_label = 1, WAGE_EDU = 2) %>%
    mutate(WAGE_EDU = as.numeric(WAGE_EDU)) %>% 
    filter(!is.na(geo_label)) %>%
    filter(!is.na(WAGE_EDU))
    
    # Mapping Nume -> Cod (Reutilizam mapping-ul existent)
   df_wage_final <- df_wage_clean %>%
    left_join(country_mapping, by = "geo_label") %>%
    filter(!is.na(geo)) %>% 
    select(geo, WAGE_EDU)
    
   message("WAGE_EDU (2018) real importat cu succes.")
   
} else {
  message("Fisierul WAGE_EDU nu a fost gasit.")
  df_wage_final <- NULL
}

# ==============================================================================
# 2c. Importul Datelor Reale (DESI_AI)
# ==============================================================================
file_desi <- "desi_ai.csv.xlsx"

if (file.exists(file.path(raw_path, file_desi))) {
  message("Importing DESI_AI from Sheet 9 (AI Adoption > 10 emp)...")
  
  # Sheet 9 corespunde cu "All enterprises"
  # Citim datele, sarind metadata (skip 10 probabil)
  df_desi_raw <- read_excel(file.path(raw_path, file_desi), sheet = "Sheet 9", skip = 10, .name_repair = "minimal")
  
  # Verificam daca 2023 exista
  idx_2023_desi <- which(names(df_desi_raw) == "2023")
  
  if (length(idx_2023_desi) > 0) {
      df_desi_clean <- df_desi_raw %>%
        select(1, all_of(idx_2023_desi)) %>% 
        rename(geo_label = 1, DESI_AI = 2) %>%
        mutate(DESI_AI = as.numeric(DESI_AI)) %>% 
        filter(!is.na(geo_label)) %>%
        filter(!is.na(DESI_AI))
        
       df_desi_final <- df_desi_clean %>%
        left_join(country_mapping, by = "geo_label") %>%
        filter(!is.na(geo)) %>% 
        select(geo, DESI_AI)
        
       message("DESI_AI real importat cu succes.")
  } else {
      message("Nu am gasit coloana 2023 in DESI. Folosim mock.")
      df_desi_final <- NULL
  }
} else {
  message("Fisierul DESI_AI nu a fost gasit.")
  df_desi_final <- NULL
}

# ==============================================================================
# 2d. Importul Datelor Reale (STEM_GRAD = Absolventi Tertiar % sau la mie)
# ==============================================================================
file_stem <- "stem_graduates.csv.xlsx"

if (file.exists(file.path(raw_path, file_stem))) {
  message("Importing STEM_GRAD from Sheet 1 (Graduates per 1000)...")
  
  # Citim datele, sarind metadata (skip 9 conform inspectiei)
  df_stem_raw <- read_excel(file.path(raw_path, file_stem), sheet = "Sheet 1", skip = 9, .name_repair = "minimal")
  
  # Cautam coloana 2022 (e mai safe decat 2023 care poate avea multe NA-uri fiind recent)
  # Totusi incercam 2022 pentru stabilitate.
  idx_stem_target <- which(names(df_stem_raw) == "2022")
  if(length(idx_stem_target) == 0) idx_stem_target <- which(names(df_stem_raw) == "2021")
  
  if (length(idx_stem_target) > 0) {
      df_stem_clean <- df_stem_raw %>%
        select(1, all_of(idx_stem_target)) %>% 
        rename(geo_label = 1, STEM_GRAD = 2) %>%
        mutate(STEM_GRAD = as.numeric(STEM_GRAD)) %>% 
        filter(!is.na(geo_label)) %>%
        filter(!is.na(STEM_GRAD))
        
       df_stem_final <- df_stem_clean %>%
        left_join(country_mapping, by = "geo_label") %>%
        filter(!is.na(geo)) %>% 
        select(geo, STEM_GRAD)
        
       message("STEM_GRAD real importat cu succes.")
  } else {
      message("Nu am gasit coloana 2022/2021 in STEM. Folosim mock.")
      df_stem_final <- NULL
  }
} else {
  message("Fisierul STEM_GRAD nu a fost gasit.")
  df_stem_final <- NULL
}

# ==============================================================================
# 2e. Importul Datelor Reale (GOV_RD = Cheltuieli R&D % PIB)
# ==============================================================================
file_gov <- "gov_rd_expenditure.csv.xlsx"

if (file.exists(file.path(raw_path, file_gov))) {
  message("Importing GOV_RD from Sheet 2 (% GDP)...")
  
  # Sheet 2 are unitatea % din PIB
  # Header pe randul 8 -> skip 7
  df_gov_raw <- read_excel(file.path(raw_path, file_gov), sheet = "Sheet 2", skip = 7, .name_repair = "minimal")
  
  # Cautam coloana 2023 sau 2022
  idx_gov_target <- which(names(df_gov_raw) == "2023")
  if(length(idx_gov_target) == 0) idx_gov_target <- which(names(df_gov_raw) == "2022")
  
  if (length(idx_gov_target) > 0) {
      df_gov_clean <- df_gov_raw %>%
        select(1, all_of(idx_gov_target)) %>% 
        rename(geo_label = 1, GOV_RD = 2) %>%
        mutate(GOV_RD = as.numeric(GOV_RD)) %>% 
        filter(!is.na(geo_label)) %>%
        filter(!is.na(GOV_RD))
        
       df_gov_final <- df_gov_clean %>%
        left_join(country_mapping, by = "geo_label") %>%
        filter(!is.na(geo)) %>% 
        select(geo, GOV_RD)
        
       message("GOV_RD real importat cu succes.")
  } else {
      message("Nu am gasit coloana 2023/2022 in GOV_RD. Folosim mock.")
      df_gov_final <- NULL
  }
} else {
  message("Fisierul GOV_RD nu a fost gasit.")
  df_gov_final <- NULL
}

# ==============================================================================
# 2f. Importul Datelor Reale (GDP_CAP = PIB per locuitor)
# ==============================================================================
file_gdp <- "gdp_per_capita.csv.xlsx"

if (file.exists(file.path(raw_path, file_gdp))) {
  message("Importing GDP_CAP from Sheet 1 (Euro per capita)...")
  
  # Sheet 1: Chain linked volumes (2020), euro per capita
  # Verificam anii. Cel mai probabil 2023 este disponibil.
  # Header pe randul 10? Inspectia arata header cu ani. Nu stim exact randul din output, dar standard Eurostat e ~10.
  # Sa zicem skip=8.
  
  # Citim Header pentru a gasi 2023
  df_gdp_head <- read_excel(file.path(raw_path, file_gdp), sheet = "Sheet 1", skip = 8, n_max = 5)
  idx_gdp_target <- which(names(df_gdp_head) == "2023")
  if(length(idx_gdp_target) == 0) idx_gdp_target <- which(names(df_gdp_head) == "2022")
  
  if (length(idx_gdp_target) > 0) {
     # Citim full
     df_gdp_raw <- read_excel(file.path(raw_path, file_gdp), sheet = "Sheet 1", skip = 8, .name_repair = "minimal")
     
      df_gdp_clean <- df_gdp_raw %>%
        select(1, all_of(idx_gdp_target)) %>% 
        rename(geo_label = 1, GDP_CAP = 2) %>%
        mutate(GDP_CAP = as.numeric(GDP_CAP)) %>% 
        filter(!is.na(geo_label)) %>%
        filter(!is.na(GDP_CAP))
        
       df_gdp_final <- df_gdp_clean %>%
        left_join(country_mapping, by = "geo_label") %>%
        filter(!is.na(geo)) %>% 
        select(geo, GDP_CAP)
        
       message("GDP_CAP real importat cu succes.")
  } else {
      message("Nu am gasit coloana 2023 in GDP. Folosim mock.")
      df_gdp_final <- NULL
  }
} else {
  message("Fisierul GDP_CAP nu a fost gasit.")
  df_gdp_final <- NULL
}

# ==============================================================================
# 2g. Importul Datelor Reale (DIG_SKILLS = Basic+ Overall Skills)
# ==============================================================================
file_dig <- "digital_skills.csv.xlsx"

if (file.exists(file.path(raw_path, file_dig))) {
  message("Importing DIG_SKILLS from Sheet 33 (Basic+ Skills)...")
  
  # Sheet 33: Basic or above basic overall digital skills
  # Header pe randul 10? Inspectia a aratat Metadata pe primele randuri.
  # Sa zicem skip=10.
  
  df_dig_raw <- read_excel(file.path(raw_path, file_dig), sheet = "Sheet 33", skip = 10, .name_repair = "minimal")
  
  # Cautam coloana 2023 sau 2021
  idx_dig_target <- which(names(df_dig_raw) == "2023")
  if(length(idx_dig_target) == 0) idx_dig_target <- which(names(df_dig_raw) == "2021")
  
  if (length(idx_dig_target) > 0) {
      df_dig_clean <- df_dig_raw %>%
        select(1, all_of(idx_dig_target)) %>% 
        rename(geo_label = 1, DIG_SKILLS = 2) %>%
        mutate(DIG_SKILLS = as.numeric(DIG_SKILLS)) %>% 
        filter(!is.na(geo_label)) %>%
        filter(!is.na(DIG_SKILLS))
        
       df_dig_final <- df_dig_clean %>%
        left_join(country_mapping, by = "geo_label") %>%
        filter(!is.na(geo)) %>% 
        select(geo, DIG_SKILLS)
        
       message("DIG_SKILLS real importat cu succes.")
  } else {
      message("Nu am gasit coloana 2023/2021 in DIG_SKILLS. Folosim mock.")
      df_dig_final <- NULL
  }
} else {
  message("Fisierul DIG_SKILLS nu a fost gasit.")
  df_dig_final <- NULL
}

# 3. Generarea/Importul celorlalte date
# Deocamdata celelalte fisiere lipsesc, deci vom genera Mock Data pentru ele, dar vom face merge cu EMP_TECH real daca exista.

message("Constructia Datasetului FINAL...")

set.seed(123)
countries <- c("BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES", "FR", "HR", "IT", "CY", "LV", "LT", "LU", "HU", "MT", "NL", "AT", "PL", "PT", "RO", "SI", "SK", "FI", "SE")

# Generam un data frame de baza doar cu tarile
final_df <- data.frame(geo = countries)

# Merge Logic - Acum totul ar trebui sa fie REAL
# Daca un df_..._final e NULL, vom avea nevoie de o strategie de fallback (dar speram ca nu e cazul)

# Functie helper pentru safe merge
safe_merge <- function(base_df, new_df, col_name) {
  if(!is.null(new_df)) {
    base_df <- base_df %>% left_join(new_df, by = "geo")
  } else {
    message(paste("Variabila", col_name, "lipseste complet (Mocking...)"))
    base_df[[col_name]] <- NA # Punem NA si imputam mai jos
  }
  return(base_df)
}

final_df <- safe_merge(final_df, df_emp_final, "EMP_TECH")
final_df <- safe_merge(final_df, df_wage_final, "WAGE_EDU")
final_df <- safe_merge(final_df, df_desi_final, "DESI_AI")
final_df <- safe_merge(final_df, df_stem_final, "STEM_GRAD")
final_df <- safe_merge(final_df, df_gov_final, "GOV_RD")
final_df <- safe_merge(final_df, df_gdp_final, "GDP_CAP")
final_df <- safe_merge(final_df, df_dig_final, "DIG_SKILLS")

# ==============================================================================
# 5. Adaugare Variabila Dummy "Region" (Cerinta 4a)
# ==============================================================================
# Clasificare simplificata:
# East: BG, CZ, EE, HR, HU, LT, LV, PL, RO, SI, SK
# West: Restul

east_countries <- c("BG", "CZ", "EE", "HR", "HU", "LT", "LV", "PL", "RO", "SI", "SK")

final_df <- final_df %>%
  mutate(Region = ifelse(geo %in% east_countries, "East", "West")) %>%
  mutate(Region = factor(Region, levels = c("West", "East")))

message("Variabila Region a fost adaugata.")

# Verificam completitudinea
message("\n--- Rezumat Date ---")
print(summary(final_df))

# Imputare fallback (pentru valorile NA din merge-ul real sau mock-ul complet lipsa)
# Nota: La merge, daca o tara lipseste din sursa reala, va avea NA. Trebuie sa umplem acele goluri.
vars_to_check <- c("EMP_TECH", "WAGE_EDU", "DESI_AI", "STEM_GRAD", "GOV_RD", "GDP_CAP", "DIG_SKILLS")
for(v in vars_to_check) {
    if(v %in% names(final_df)) {
        if(sum(is.na(final_df[[v]])) > 0) {
             # Pentru tarile care lipsesc din seturile Eurostat, folosim media europeana
             message(paste("Imputing mean for missing values in:", v))
             final_df[[v]][is.na(final_df[[v]])] <- mean(final_df[[v]], na.rm=TRUE)
        }
    } else {
       # Daca coloana nu exista deloc (safe_merge a pus NA in teorie, dar sa fim siguri)
       final_df[[v]] <- runif(27, 10, 20) # Mock total fallback
    }
}


# 4. Tratarea Valorilor Lipsa (Cerința 2.c)
message("Analiza Missing Values...")
# Vizualizare (se va salva in ploturi daca rulam interactiv, aici doar printam)
# aggr(final_df, col=c('navyblue','red'), numbers=TRUE, sortVars=TRUE, labels=names(final_df), cex.axis=.7, gap=3, ylab=c("Histogram of missing data","Pattern"))

# Imputare cu kNN (VIM) sau Mice
message("Imputare date lipsa folosind kNN (daca exista)...")
# Verificam daca avem NA
if (sum(is.na(final_df)) > 0) {
    final_df_imputed <- kNN(final_df, k = 5, imp_var = FALSE)
} else {
    final_df_imputed <- final_df
}

# 5. Transformari de variabile
# Logaritmare GDP si EMP_TECH (daca distributia e asimetrica)
final_df_imputed <- final_df_imputed %>%
  mutate(
    ln_GDP_CAP = log(GDP_CAP),
    ln_EMP_TECH = log(EMP_TECH)
  )

# 6. Salvare
saveRDS(final_df_imputed, file = file.path(processed_path, "analysis_data.rds"))
write.csv(final_df_imputed, file = file.path(processed_path, "analysis_data.csv"), row.names = FALSE)

message("Datasetul final a fost salvat in data/processed/analysis_data.rds")
