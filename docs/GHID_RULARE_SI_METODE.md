# Ghid de Rulare și Metode Analitice

Acest ghid este destinat colegilor care vor să ruleze proiectul pe propriul calculator sau să înțeleagă detaliile tehnice pentru prezentare și examen.

## A. Cum rulezi proiectul?

### Cerințe preliminare (Prerequisites)
Ai nevoie de **R** și ** RStudio** instalate.

### Pasul 1: Verificare
Asigură-te că ai toate fișierele Excel în folderul `data/raw/` (descarcate de pe Eurostat).
Proiectul verifică automat existența lor, dar dacă lipsesc, va folosi date simulate (ceea ce nu vrei la examen).

### Pasul 2: Rulare Pipeline Complet
Cel mai simplu mod este să rulezi scriptul "Master": `scripts/99_verify_all.R`.
Acesta va rula secvențial toate celelalte scripturi:

1.  Deschide `scripts/99_verify_all.R` în RStudio.
2.  Apasă butonul **Source** (sau `Ctrl+Shift+S`).
3.  Așteaptă câteva secunde/minute.
4.  Verifică consola pentru mesajul final "VERIFICARE COMPLETA".

### Pasul 3: Unde sunt rezultatele?
*   **Grafice**: Deschide folderul `output/figures_final/`. Aici găsești PNG-urile pentru prezentare.
*   **Tabele Regresie**: În fișierul `output/regression_results.txt` ai output-ul formatat academic (Stargazer).

---

## B. Metodele Analitice Explicate (ELI5)

### 1. Curățarea Datelor (Data Cleaning)
*   **Problema**: Datele Eurostat vin în format "Human Readable" (cu titluri pompoase, rânduri goale, note de subsol), nu "Machine Readable".
*   **Soluția noastră**: Folosim librăria `readxl` cu parametrii `skip` (sărim rândurile inutile) și `select` (păstrăm doar coloanele de interes - Anul 2023). Facem `left_join` pentru a lipi informațiile (ca un VLOOKUP masiv în Excel, dar automat).

### 2. Clustering (K-Means)
*   **Ce este?** Un algoritm nesupervizat care grupează țările în "familii".
*   **Cum merge?** Îi dăm calculatorului datele (PIB, AI, Educație) și el găsește singur tipare.
*   **Interpretare**: Dacă vedem că România e în cluster cu Bulgaria și Grecia, iar Germania cu Franța, înseamnă că structura economiei noastre seamănă cu a lor.

### 3. Regresia OLS (Ordinary Least Squares)
*   **Modelul**: $Y = \beta_0 + \beta_1 X_1 + \epsilon$
    *   $Y$ (Dependenta): Câți oameni lucrează în Tech (`EMP_TECH`).
    *   $X$ (Independenta): Cât AI folosesc firmele (`DESI_AI`).
    *   $\beta_1$ (Coeficientul): "Sfântul Graal". Dacă $\beta_1 > 0$ și semnificativ (p < 0.05), am dovedit că AI crește angajarea. Dacă e negativ, o scade.
*   **De ce Multivariate?** Nu putem uita de PIB (`GDP_CAP`). Dacă țările bogate au și mult AI și mulți programatori, simpla corelație e înșelătoare. Introducând PIB în model, "controlăm" pentru bogăție și vedem efectul *pur* al AI-ului.

### 4. Machine Learning: Lasso & Ridge (Regularizare)
*   **Problema**: Când ai multe variabile care spun cam același lucru (ex: PIB și Salarii și Digital Skills), regresia clasică "se amețește" (Multicoliniaritate). Coeficienții devin instabili (uriași sau cu semn greșit).
*   **Soluția Lasso (L1)**: Adaugă o "penalizare" matematică pentru complexitate. Forțează coeficienții variabilelor inutile să devină **exact ZERO**.
    *   *Avantaj*: Face selecție de variabile (ne spune care contează cu adevărat).
*   **Soluția Ridge (L2)**: Micșorează toți coeficienții spre zero, dar nu îi anulează.
    *   *Avantaj*: Bun când ai variabile corelate pe care vrei să le păstrezi pe toate.

### 5. Ce am descoperit? (Spoiler pentru Examen)
Analiza noastră arată că, deși AI-ul este corelat cu angajarea în tech, factorul dominant este de fapt **Educația (Absolvenți STEM)** și **Salariile**. Odată ce ținem cont de educație, impactul direct al AI scade.
Concluzia de policy: "Nu cumpărați doar softuri AI, investiți în facultăți de informatică!"
