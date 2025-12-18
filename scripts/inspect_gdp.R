# Concluzie Inspectie:
# Sheet 1: Chain linked volumes (2020), euro per capita.
# Este unitatea corecta (Euro reali per locuitor).

source("scripts/common.R")
library(readxl)

file_path <- "data/raw/gdp_per_capita.csv.xlsx"

if (file.exists(file_path)) {
  sheets <- excel_sheets(file_path)
  message("Sheet-uri disponibile:")
  print(sheets)
  
  # Loop prin primele 10 sheet-uri pentru identificarea unitatii de masura
  for (i in 1:length(sheets)) {
    sh_name <- sheets[i]
    if (sh_name == "Summary") next
    
    try({
       # Citim header-ul
       df_head <- read_excel(file_path, sheet = sh_name, n_max = 12, col_names = FALSE, .name_repair = "minimal")
       
       # Cautam Unit of measure (Euro per capita vs PPS?)
       unit <- as.character(df_head[6, 3]) 
       
       message(paste(sh_name, "| Unit:", substr(unit, 1, 50)))
    }, silent = TRUE)
  }
} else {
  message("Fisierul nu exista.")
}
