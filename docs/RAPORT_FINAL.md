# Impactul AI si automatizarii asupra pietei muncii in Europa
## Aplicatia 1: analiza transversala (2022-2023)

### 1. Introducere si obiective
Scopul este estimarea impactului adoptarii AI asupra ocuparii in sectorul high-tech in UE,
prin modele econometrice clasice si comparatie cu tehnici de machine learning. Obiective:
1) identificarea determinantilor principali ai EMP_TECH, 2) validarea modelului si
selectia specificatiei optime, 3) evaluarea capacitatii predictive, 4) scenarii.

#### 1.1. Context teoretic si literatura recenta (Req 1a)
Adoptarea AI poate afecta ocuparea prin mecanisme de substitutie si complementaritate:
tehnologia reduce cererea pentru task-uri de rutina, dar creste cererea pentru skill-uri
avansate si pentru activitati inovative. In termeni macro, efectul net depinde de capitalul
uman, structura productiva, cheltuielile de R&D si nivelul de dezvoltare.

Literatura recenta (2019-2024) de completat cu 5-10 articole:
- TODO: adauga 5-10 articole recente relevante (autor, an, titlu, jurnal).

Surse online (context, non-academice):
- https://www.nexford.edu/insights/how-will-ai-affect-jobs
- https://www.goldmansachs.com/insights/articles/how-will-ai-affect-the-global-workforce

Fundamente teoretice (context, nu substituie cerinta de literatura recenta):
- Autor, D. H. (2015). Why Are There Still So Many Jobs? Journal of Economic Perspectives.
- Autor, D. H., Levy, F., and Murnane, R. J. (2003). QJE.
- Acemoglu, D., and Restrepo, P. (2020). Journal of Political Economy.
- Graetz, G., and Michaels, G. (2018). Review of Economics and Statistics.

#### 1.2. Ipoteze si traducere in model empiric (Req 1b)
Model de baza (cross-section, tara i):
EMP_TECH_i = beta0 + beta1*DESI_AI_i + beta2*STEM_GRAD_i + beta3*ln(GDP_CAP)_i
             + beta4*GOV_RD_i + beta5*DIG_SKILLS_i + beta6*WAGE_EDU_i + u_i

Ipoteze de semn:
- beta1 > 0 (AI este asociata cu ocupare tech, conditionat pe control).
- beta2 > 0 (capitalul uman STEM creste ocuparea tech).
- beta3 > 0 (dezvoltarea economica sustine sectoarele high-tech).
- beta4 > 0 (R&D public sustine inovatia).
- beta5 > 0 (skill-urile digitale cresc absorbtia tehnologiilor).

Extinderi predictive: regularizare (Lasso/Ridge/Elastic Net) si modele non-liniare
pentru a testa robustetea in afara esantionului.

### 2. Date si variabile
Analiza este cross-sectional, cu 27 tari UE (2022-2023; unele variabile au ultimul an disponibil).
Datasetul integrat este in `data/processed/analysis_data_enriched.rds`.

#### 2.1. Variabile, unitati, surse si periodicitate (Req 2a)
| Variabila   | Definitie scurta | Unitate | Sursa (cod) | An folosit |
|------------|-------------------|---------|-------------|------------|
| EMP_TECH   | % angajati in sectoare high-tech | % total ocupare | Eurostat `htec_emp_nat` | 2023 (fallback 2022) |
| DESI_AI    | % firme care folosesc AI (>=10 angajati) | % | Eurostat/DESI `isoc_eb_ai` | 2023 |
| STEM_GRAD  | Absolventi STEM (tertiar) | la 1000 locuitori | Eurostat `educ_uoe_grad04` | 2022 (fallback 2021) |
| GOV_RD     | Cheltuieli guvernamentale R&D | % PIB | Eurostat `gba_nabsfin` | 2023 (fallback 2022) |
| GDP_CAP    | PIB pe cap de locuitor | EUR/PPS | Eurostat `sdg_08_10` / World Bank | 2023 (fallback 2022) |
| DIG_SKILLS | Populatie cu skill-uri digitale basic+ | % populatie | Eurostat `isoc_sk_dskl_i21` | 2023 (fallback 2021) |
| WAGE_EDU   | Castig orar in educatie (NACE P) | EUR/ora | Eurostat `earn_ses_hourly` | 2018 (ultimul an disponibil in fisier) |

Variabile derivate: Region (dummy East/West), ln_GDP_CAP, ln_EMP_TECH, PC1_Digital (PCA),
Cluster (K-Means). Acestea sunt generate in pipeline-ul de procesare/EDA.

#### 2.2. Analiza exploratorie (Req 2b, 2e optional)
Statistici descriptive: `output/tables/descriptive_stats.csv`.
Grafice distributii: `output/figures/distributions_hist.png` si `output/figures/distributions_boxplot.png`.
Corelatii: `output/figures/correlation_matrix.png` (EDA) si `output/figures_final/01_correlation_matrix.png`.
Clustering: `output/figures/kmeans_elbow.png` si `output/figures/kmeans_clusters.png`.
PCA: `output/figures/pca_variables.png` (PC1 folosita ca index sintetic).

#### 2.3. Transformari si tratarea valorilor lipsa (Req 2c)
- Imputare: media europeana pentru NA, apoi kNN (k=5) daca mai raman lipsa.
- Logaritmare: ln_GDP_CAP si ln_EMP_TECH in dataset, log1p in modelele log-log.
- Standardizare pentru clustering (DESI_AI, DIG_SKILLS, STEM_GRAD, GOV_RD).
- Dummy Region (East/West), interactiuni si termeni polinomiali in modele alternative.

#### 2.4. Split train/test (Req 2d)
Datele sunt impartite 80/20 (seed 123) pentru evaluare out-of-sample in OLS si ML.

#### 2.5. Surse date panel (Req 1, panel setup)
Pentru componenta panel (tara-an) am folosit aceleasi surse si fisiere din `data/raw/`,
conform `data/raw/INSTRUCTIUNI_DATE.md`:
- EMP_TECH: Eurostat `htec_emp_nat` (`employment_tech.csv.xlsx`)
- DESI_AI: Eurostat `isoc_eb_ai` (`desi_ai.csv.xlsx`)
- STEM_GRAD: Eurostat `educ_uoe_grad04` (`stem_graduates.csv.xlsx`)
- GOV_RD: Eurostat `gba_nabsfin` (`gov_rd_expenditure.csv.xlsx`)
- GDP_CAP: Eurostat `sdg_08_10` / World Bank (`gdp_per_capita.csv.xlsx`)
- DIG_SKILLS: Eurostat `isoc_sk_dskl_i21` (`digital_skills.csv.xlsx`)
- WAGE_EDU: Eurostat `earn_ses_hourly` (`wages_education.csv.xlsx`)

### 3. Modelare econometrica clasica (Req 3)
#### 3.1. Specificatii OLS si determinanti (Req 3a)
Au fost estimate mai multe modele OLS (m1-m4) pentru a identifica determinantii:
- DESI_AI (adoptare AI)
- STEM_GRAD (capital uman)
- ln_GDP_CAP (nivel de dezvoltare)
- GOV_RD (cheltuieli R&D)
- Region (dummy East/West)
- interactiuni (DESI_AI * STEM_GRAD)

Interpretare generala (din `output/tables/regression_results_train.txt`):
factorii structurali (STEM_GRAD, ln_GDP_CAP) raman cei mai robusti, in timp ce efectul
direct al AI se reduce dupa controlul pentru PIB si capital uman, ceea ce sugereaza
ca AI este mai degraba corelat cu dezvoltarea economica decat cauza directa a ocuparii.

#### 3.2. Validarea modelului si corectii (Req 3b)
Modelul optim este ales pe criterii econometrice (BIC minim, apoi Adj R2 maxim) dintre
modelele care includ DESI_AI, folosind `output/tables/ols_model_fit.csv`.
Sunt testate ipotezele clasice (rezultate in `output/tables/ols_diagnostics.txt`):
- normalitatea reziduurilor (Shapiro),
- heteroscedasticitate (Breusch-Pagan),
- multicoliniaritate (VIF),
- specificatie functionala (RESET).

Daca se detecteaza heteroscedasticitate, se folosesc erori standard robuste (HC1),
raportate in `output/tables/ols_coefficients_robust.txt`.

#### 3.3. Performanta predictiva out-of-sample (Req 3c)
S-a folosit split 80/20 train/test. Performanta este evaluata cu RMSE, MAE, MAPE,
R2 si Adj R2 pe test (vezi `output/tables/ols_test_metrics.csv`).

### 4. Extinderea modelului si scenarii (Req 4)
#### 4.1. Forme functionale alternative (Req 4a)
Au fost estimate:
- model log-log (m5_loglog) pentru interpretare elasticitati,
- model polinomial (m6_poly) pentru non-linearitati,
plus dummy de regiune si termen de interactiune.
Aceste transformari imbunatatesc interpretarea economica (elasticitati) si pot reduce
probleme de forma functionala sau heteroscedasticitate.

#### 4.2. Scenariu de prognoza (Req 4b)
Pe modelul optim (cu DESI_AI), s-a construit scenariul: +10% DESI_AI doar in tarile East.
Ipoteze: ceteris paribus, stabilitate a coeficientilor, efect linear pe termen scurt.
Rezultatul numeric este salvat in `output/tables/scenario_results.csv`.

### 5. Regularizare si ML (Req 5)
#### 5.1. Regularizare (Req 5a)
Sunt aplicate Ridge, Lasso si Elastic Net (glmnet) cu selectie automata a lui lambda.

#### 5.2. Comparatii ML vs econometric (Req 5b)
Comparatia se face pe setul de test cu RMSE/MAE/MAPE/R2/Adj R2 in
`output/tables/ml_comparison_test.csv`, incluzand explicit modelul OLS optim
(selectat dupa BIC si Adj R2). Astfel se observa daca modelele predictive
imbunatatesc acuratetea fata de specificatia econometrica considerata optima.

#### 5.3. Explicativ vs predictiv (Req 5c)
OLS este orientat pe interpretare (semnificatie economica, semn si marime coeficienti),
in timp ce modelele ML optimizeaza predictia prin regularizare (bias-variance tradeoff).
In practica, OLS clarifica mecanismul economic, iar ML valideaza robustetea predictiva.

#### 5.4. Metode avansate (Optional, Req 5d)
In script sunt incluse optiuni pentru Random Forest, Gradient Boosting si SVR, rulate
doar daca pachetele sunt instalate, pentru a evidentia diferentele dintre abordari.

### 6. Discutii si validarea rezultatelor (Req 6)
#### 6.1. Raportare la ipoteze si literatura (Req 6a)
Rezultatele sustin ipoteza ca adoptarea AI este asociata cu nivelul de dezvoltare si
capitalul uman. Literatura despre automatizare arata efecte mixte: substitutie pentru
task-uri de rutina si complementaritate pentru skill-uri avansate (Autor, 2015;
Autor, Levy si Murnane, 2003). Studiile despre roboti sugereaza efecte negative locale
asupra ocuparii, dar si potentiale castiguri de productivitate pe termen mediu
(Acemoglu si Restrepo, 2020; Graetz si Michaels, 2018). Acest cadru explica de ce
STEM_GRAD si GDP_CAP raman determinanti principali, iar efectul direct al DESI_AI
devine secundar dupa controlul pentru dezvoltare.

#### 6.2. Convergente si discrepante econometric vs ML (Req 6b)
Convergenta: variabilele de capital uman sunt importante in ambele abordari.
Discrepanta: modelele ML pot reduce rolul direct al DESI_AI daca acesta este explicat
de corelatii cu PIB sau skill-uri, accentuand predictia peste interpretare.

#### 6.3. Limitari si directii viitoare (Req 6c)
Limitari: esantion mic (27 tari), analiza cross-sectional, potentiala endogenitate
(AI poate fi cauza si efect al dezvoltarii), erori de masurare si bias de selectie.
Directii viitoare: extindere pe panel (ani multipli), modele non-liniare si cauzale
IV/DiD, validare externa, explorarea metodelor ML avansate cu tuning sistematic.

### 7. Reproducere
Toate analizele sunt implementate in R. Ruleaza `scripts/99_verify_all.R` pentru a
genera tabelele si graficele mentionate mai sus.

### Referinte (selectie)
- TODO: adauga 5-10 articole 2019-2024 relevante pentru cerinta 1a.
- Acemoglu, D., and Restrepo, P. (2020). Robots and Jobs: Evidence from US Labor Markets. Journal of Political Economy.
- Autor, D. H. (2015). Why Are There Still So Many Jobs? The History and Future of Workplace Automation. Journal of Economic Perspectives.
- Autor, D. H., Levy, F., and Murnane, R. J. (2003). The Skill Content of Recent Technological Change. Quarterly Journal of Economics.
- Graetz, G., and Michaels, G. (2018). Robots at Work. Review of Economics and Statistics.
