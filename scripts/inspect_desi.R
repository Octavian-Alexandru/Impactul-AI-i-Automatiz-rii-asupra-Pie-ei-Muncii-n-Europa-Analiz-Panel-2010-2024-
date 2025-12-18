# Concluzie Inspectie:
# Sheet 9: "All enterprises (10 persons employed or more)" + "Enterprises using at least one of the AI technologies"
# Aceasta este cea mai reprezentativa metrica pentru "AI Adoption" la nivel national.

source("scripts/common.R")
library(readxl)

file_path <- "data/raw/desi_ai.csv.xlsx"

if (file.exists(file_path)) {
  sheets <- excel_sheets(file_path)
  message("Sheet-uri disponibile:")
  print(sheets)
  
  # Loop prin primele 10 sheet-uri pentru identificarea indicatorului corect
  for (i in 1:length(sheets)) {
    sh_name <- sheets[i]
    if (sh_name == "Summary") next
    
    try({
       # Citim header-ul
       df_head <- read_excel(file_path, sheet = sh_name, n_max = 12, col_names = FALSE, .name_repair = "minimal")
       
       # Verificam randurile de metadata
       size_class <- as.character(df_head[6, 3])
       indicator <- as.character(df_head[8, 3])
       
       message(paste(sh_name, "| Size:", substr(size_class, 1, 20), "| Ind:", substr(indicator, 1, 50)))
    }, silent = TRUE)
  }
} else {
  message("Fisierul nu exista.")
}
