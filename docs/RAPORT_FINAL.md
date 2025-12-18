# IMPACUL INTELIGENȚEI ARTIFICIALE ȘI AUTOMATIZĂRII ASUPRA PIEȚEI MUNCII ÎN EUROPA
## Analiză Transversală (2022-2023)

### 1. Introducere și Obiective

Acest proiect își propune să cuantifice impactul adoptării tehnologiilor de Inteligență Artificială (AI) asupra ocupării forței de muncă în sectoarele de înaltă tehnologie (High-Tech) din Uniunea Europeană. Intr-o perioadă de transformare digitală accelerată, întrebarea centrală este dacă AI funcționează ca un substitut pentru munca umană sau ca un catalizator pentru crearea de noi joburi specializate.

**Obiective specifice:**
1. Analiza corelației dintre adoptarea AI la nivel de întreprindere și rata de angajare în high-tech.
2. Identificarea rolului competențelor digitale și al educației STEM ca factori mediatori.
3. Testarea ipotezei că țările cu investiții mai mari în R&D au o reziliență mai mare pe piața muncii.

---

### 2. Metodologie și Date

Analiza se bazează pe un set de date **Cross-Sectional** integrat din surse Eurostat, acoperind cele 27 de state membre UE. Variabilele cheie utilizate sunt:

| Variabilă | Sursă (Eurostat) | Anul Datelor | Descriere |
| :--- | :--- | :--- | :--- |
| **EMP_TECH** (Dependentă) | `htec_emp_nat2` | 2023 | Procentul angajaților în sectoare High-Tech din total angajați. |
| **DESI_AI** (Independentă) | `isoc_eb_ai` | 2023 | Procentul întreprinderilor (10+ angajați) care utilizează orice tehnologie AI. |
| **DIG_SKILLS** | `isoc_sk_dskl_i21` | 2023 | Procentul indivizilor cu competențe digitale cel puțin de bază. |
| **STEM_GRAD** | `educ_uoe_grad04` | 2022 | Absolvenți de studii terțiare în știință și tehnologie (la mia de locuitori). |
| **GOV_RD** | `gba_nabsfin07` | 2022 | Alocări bugetare guvernamentale pentru R&D (% din PIB). |
| **GDP_CAP** | `sdg_08_10` | 2023 | PIB pe cap de locuitor (Euro reali). |
| **WAGE_EDU** | `earn_ses_hourly` | 2018 | Salariul mediu în sectorul educației (Proxy pentru atractivitate/calitate). |

Metodele econometrice utilizate includ Regresia Liniară Multiplă (OLS) pentru inferență statistică și Regularizarea (Lasso/Ridge) pentru selecția variabilelor.

---

### 3. Rezultate Empirice

#### 3.1. Analiza Corelațională
Matricea de corelație (vezi `output/figures_final/01_correlation_matrix.png`) relevă:
*   O corelație pozitivă puternică între **GDP_CAP** și **DESI_AI**, sugerând că țările bogate sunt primele care adoptă AI.
*   O corelație semnificativă între **STEM_GRAD** și **EMP_TECH**, indicând că oferta de muncă calificată este un predictor crucial pentru dezvoltarea sectorului tech.

#### 3.2. Modelul Econometric (OLS)
Rezultatele regresiei indică o relație complexă:

*   **Coeficientul DESI_AI**: În modelele simple, apare o relație pozitivă slabă. Totuși, când controlăm pentru PIB per capita (GDP_CAP), impactul direct al AI devine nesemnificativ statistic sau ușor negativ.
*   **Interpretare**: Aceasta sugerează că **adopția AI este o consecință a dezvoltării economice**, nu neapărat cauza directă a angajărilor în masă momentan.
*   **Rolul Educației**: Variabila **STEM_GRAD** rămâne robustă și pozitivă în majoritatea specificațiilor. Creșterea numărului de absolvenți STEM este cel mai sigur mod de a crește ocuparea în High-Tech.

#### 3.3. Selecția Variabilelor (Machine Learning)
Analiza Lasso (care penalizează coeficienții irelevanți) a confirmat importanța variabilelor structurale:
1.  **STEM_GRAD** (Absolvenți STEM)
2.  **WAGE_EDU** (Salarii/Calitate Educație)

Acestea au fost singurele variabile consistent selectate ca având putere predictivă reală, sugerând că infrastructura umană este mai importantă decât simpla achiziție de software AI.

---

### 4. Concluzii și Recomandări

1.  **AI nu fură joburi, dar nici nu le creează "automat"**: Nu am găsit dovezi că adoptarea AI duce la șomaj în sectorul tech, dar nici că generează automat creștere masivă de personal, independent de alți factori.
2.  **Focus pe Educație**: Politicile publice ar trebui să se concentreze prioritar pe creșterea numărului de absolvenți STEM. Aceasta este variabila cu cel mai mare impact pozitiv asupra pieței muncii digitale.
3.  **Digital Divide**: Există un decalaj major între Vest și Est (vizibil în graficele generate). Țările cu PIB mic au și competențe digitale reduse, riscând să rămână în urmă în era AI.

### 5. Anexe Vizuale
*   Găsiți graficele detaliate în directorul `output/figures_final/`.
