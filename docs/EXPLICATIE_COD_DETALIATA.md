# Explicatie Detaliata a Codului Sursă (Analiza Codului)

Acest document disecă cele mai importante părți din codul sursă R. Folosiți-l pentru a răspunde la întrebări de tipul "Ce face funcția asta?" sau "De ce ai scris așa?".

## Script: `01_data_cleaning.R` (Curățarea)

### Pipelines (`%>%`)
Vei vedea peste tot operatorul `%>%` (se citește "și apoi"). Este specific pachetului `dplyr` din `tidyverse`.
```r
df_final <- df_raw %>%
  select(1, 4) %>%
  filter(!is.na(Valoare))
```
**Traducere:** "Ia tabelul brut, APOI selectează coloanele 1 și 4, APOI filtrează valorile care nu sunt NA". Fără acest operator, codul ar fi plin de paranteze imbricate greu de citit.

### `left_join(..., by = "geo_label")`
Este echivalentul SQL `LEFT JOIN`. Păstrează toate rândurile din tabelul din stânga (principal) și aduce informații din cel din dreapta unde se potrivește cheia (`geo_label`). Dacă nu găsește potrivire, pune `NA`.

### `mutate(EMP_TECH = as.numeric(EMP_TECH))`
Eurostat pune uneori simboluri (":", "d") în loc de numere. Când citim Excel-ul, R crede că acea coloană e Text ("character").
Funcția `as.numeric` forțează convertirea la număr. Ce nu poate converti (simbolurile), transformă automat în `NA` (valoare lipsă), generând acel "Warning: NAs introduced by coercion" pe care îl vedem în consolă. E un comportament așteptat și corect.

---

## Script: `03_econometric_models.R` (Modele)

### `lm(formula = EMP_TECH ~ DESI_AI + STEM_GRAD, data = df)`
Funcția de bază pentru regresie liniară (**Linear Model**).
Formula se citește: "Explică EMP_TECH în funcție de (~) DESI_AI și (+) STEM_GRAD".

### Transformarea Logaritmică (`log()`)
```r
df$ln_GDP_CAP <- log(df$GDP_CAP)
```
**De ce?** PIB-ul are distribuție asimetrică (câteva țări foarte bogate trag media în sus). Logaritmarea "turtește" distribuția, făcând-o mai apropiată de o curbă Gauss (normală), ceea ce este o cerință pentru regresia OLS corectă. De asemenea, permite interpretarea coeficienților ca elasticități (%).

---

## Script: `04_ml_models.R` (Machine Learning)

### `cv.glmnet(...)`
Aceasta este funcția "magică" pentru Lasso și Ridge.
*   **`alpha = 1`**: Înseamnă Lasso.
*   **`alpha = 0`**: Înseamnă Ridge.
*   **`cv` (Cross-Validation)**: Împarte datele automat în 10 bucăți (folds). Antrenează pe 9, testează pe 1. Repetă asta de 10 ori pentru a găsi cel mai bun parametru `lambda` (cât de mult să "pedepsească" modelul).

### Matricea (`model.matrix`)
Algoritmul `glmnet` nu acceptă dataframe-uri direct (ca `lm`), ci vrea o matrice numerică.
Funcția `model.matrix(EMP_TECH ~ ., data = df)` transformă automat tot tabelul într-o matrice, și se ocupă de variabilele categorice (Dummy encoding) dacă există.

---

## Sfaturi pentru Prezentare (Tips & Tricks)
1.  **Dacă te întreabă de "Warning-uri"**: "Sunt cauzate de conversia datelor lipsă din Eurostat, le-am tratat prin filtrare sau imputare, deci nu afectează rezultatul final."
2.  **Dacă te întreabă de ce ai puține observații (27)**: "Lucrăm la nivel macroeconomic (țări UE). E un studiu Cross-Sectional. Pentru mai multe date ar fi trebuit un studiu Panel (pe mai mulți ani), dar datele de AI sunt disponibile consistent doar pentru 2023."
3.  **Dacă te întreabă de diferența OLS vs ML**: "OLS explică fenomenele (cauzalitate), ML face predicții și selecție de variabile (corelație). Am folosit ambele pentru a valida robustețea rezultatelor."
