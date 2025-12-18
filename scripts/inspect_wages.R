# Concluzie Inspectie:
# Sheet 3: "Mean earnings in euro" (ce ne intereseaza).
# Structura:
# Col 1: GEO
# Col "...2": 2002
# Col "...4": 2006
# Col "...6": 2010
# Col "...8": 2014
# Col "...10": 2018
# Col "...12": 2022 (Probabil, trebuie verificat)

source("scripts/common.R")
library(readxl)

file_path <- "data/raw/wages_education.csv.xlsx"

if (file.exists(file_path)) {
  sheets <- excel_sheets(file_path)
  message("Sheet-uri disponibile:")
  print(sheets)
  
       # Verificam anii din coloane (randul 12 din fisier, adica al 2-lea din citire daca skip=10)
       df_years <- read_excel(file_path, sheet = "Sheet 3", skip = 10, n_max = 3)
       print(df_years[2, ]) # Randul cu anii

} else {
  message("Fisierul nu exista.")
}
