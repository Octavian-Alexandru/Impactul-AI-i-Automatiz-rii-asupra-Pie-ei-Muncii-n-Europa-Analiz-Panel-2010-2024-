# scripts/inspect_excel.R
source("scripts/common.R")
library(readxl)

file_path <- "data/raw/htec_emp_nat2__custom_19390611_spreadsheet.xlsx"

if (file.exists(file_path)) {
  sheets <- excel_sheets(file_path)
  message("Sheet-uri disponibile:")
  print(sheets)
  
  # Citim liniile 9-20 din Sheet 6
  df6 <- read_excel(file_path, sheet = "Sheet 6", skip = 8, n_max = 12)
  message("\nLiniile 9-20 din Sheet 6 (Verificare valori):")
  print(df6)
} else {
  message("Fisierul nu exista.")
}
