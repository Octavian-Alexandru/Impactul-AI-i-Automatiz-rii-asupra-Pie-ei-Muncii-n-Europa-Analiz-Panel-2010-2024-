# scripts/inspect_skills.R
source("scripts/common.R")
library(readxl)

file_path <- "data/raw/digital_skills.csv.xlsx"

if (file.exists(file_path)) {
  sheets <- excel_sheets(file_path)
  message("Sheet-uri disponibile:")
  print(sheets)
  
  # Cautam "overall digital skills" in sheet-urile de la 30 in sus
  # Printam exact sheet-ul care contine "Individuals with basic or above basic overall digital skills"
  for (i in 30:length(sheets)) {
    sh_name <- sheets[i]
    if (sh_name == "Summary") next
    
    try({
       df_head <- read_excel(file_path, sheet = sh_name, n_max = 10, col_names = FALSE, .name_repair = "minimal")
       
       row7 <- as.character(df_head[7, 3])
       
       if (grepl("overall digital skills", row7, ignore.case = TRUE)) {
           message(paste("!!! FOUND in", sh_name, "!!!\n", row7))
       }
    }, silent = TRUE)
  }
} else {
  message("Fisierul nu exista.")
}
