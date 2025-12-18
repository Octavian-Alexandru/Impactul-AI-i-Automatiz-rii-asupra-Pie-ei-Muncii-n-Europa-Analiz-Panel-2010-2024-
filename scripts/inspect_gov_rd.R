# scripts/inspect_gov_rd.R
source("scripts/common.R")
library(readxl)

file_path <- "data/raw/gov_rd_expenditure.csv.xlsx"

if (file.exists(file_path)) {
  sheets <- excel_sheets(file_path)
  message("Sheet-uri disponibile:")
  print(sheets)
  
  # Verificam anii din Sheet 2
  message("\n--- Inspecting contents of Sheet 2 (Percentage of GDP) ---")
  try({
       # Citim o bucata mai mare din header (randurile 8-12)
       df_chunk <- read_excel(file_path, sheet = "Sheet 2", skip = 7, n_max = 5, col_names = FALSE)
       print(df_chunk) 

  }, silent = TRUE)
} else {
  message("Fisierul nu exista.")
}
