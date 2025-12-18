# Proiect Econometrie: Impactul AI asupra Pieței Muncii

Acest proiect analizează impactul adoptării Inteligenței Artificiale asupra ocupării și salariilor în Uniunea Europeană (2014-2024), folosind modele econometrice (OLS) și tehnici de Machine Learning (Lasso/Ridge), implementate în R.

## Structura Proiectului

```
.
├── data/
│   ├── raw/          # Locatia pentru fisierele CSV descarcate (Vezi INSTRUCTIUNI_DATE.md)
│   └── processed/    # Datele curatate generate automat
├── scripts/
│   ├── 00_setup.R           # Instalare pachete
│   ├── 01_data_cleaning.R   # Curatare data + Mock Data Generator
│   ├── 02_eda.R             # Analiza exploratorie (Clustering, PCA)
│   ├── 03_econometric_models.R # Regresie OLS si diagnostic
│   ├── 04_ml_models.R       # Machine Learning (Ridge/Lasso)
│   └── 99_verify_all.R      # Ruleaza tot procesul cap-coada
├── output/           # Rezultate (tabele si grafice)
└── docs/             # Documentatie suplimentara
```

## Cum să rulezi proiectul

### 1. Cerințe Preliminare
Trebuie să ai instalat [R](https://cran.r-project.org/) și, recomandat, [RStudio](https://posit.co/download/rstudio-desktop/).

### 2. Configurare
Deschide acest folder în RStudio (sau setează-l ca working directory `setwd("...")`).
Rulează scriptul de setup pentru a instala pachetele necesare:
```r
source("scripts/00_setup.R")
```

### 3. Datele
Proiectul necesită date reale de la Eurostat.
**Citește `data/raw/INSTRUCTIUNI_DATE.md`** pentru lista exactă a fișierelor necesare.
*Notă*: Dacă nu adaugi date, scriptul `01_data_cleaning.R` va genera date sintetice (random) pentru a demonstra funcționalitatea codului.

### 4. Execuție (Terminal)
Deoarece R nu este în PATH, folosește calea completă către executabil:

```powershell
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" scripts/99_verify_all.R
```

Sau pentru un script individual:
```powershell
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" scripts/01_data_cleaning.R
```

Procesul de instalare a pachetelor (`00_setup.R`) rulează deja în background și va crea folderul `r_libs`.


### 5. Rezultate
Vezi folderul `output/figures` pentru grafice (Cluster Plot, Harta corelații) și `output/tables` pentru rezultatele regresiei și comparatia ML.
