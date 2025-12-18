# Concluzie Inspectie:
# Sheet 1: Graduates in tertiary education, per thousand inhabitants.
# Coloana "2023" exista.
# Fisierul se numeste "stem_graduates", deci presupunem ca filtrele au fost selectate corect la download.

source("scripts/common.R")
library(readxl)

file_path <- "data/raw/stem_graduates.csv.xlsx"

if (file.exists(file_path)) {
  sheets <- excel_sheets(file_path)
  message("Sheet-uri disponibile:")
  print(sheets)
  
  # Verificam anii din header (randul 10 in fisier, adica header in df_head printat anterior)
  message("\n--- Years Row ---")
  df_years <- read_excel(file_path, sheet = "Sheet 1", skip = 9, n_max = 5)
  print(names(df_years)) # Asta ne va arata "TIME", "2014", ... "2022" etc

} else {
  message("Fisierul nu exista.")
}
