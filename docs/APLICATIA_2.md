# Aplicatia 2: analiza panel (2014-2023)

## 2. Definirea modelului si variabilele (cu transformari)

Model panel (tara i, an t):
EMP_TECH_it = alpha_i + delta_t + beta1*DESI_AI_it + beta2*STEM_GRAD_it
             + beta3*ln(GDP_CAP)_it + beta4*GOV_RD_it + beta5*DIG_SKILLS_it + u_it

Optional (daca este disponibil pentru anii din panel):
EMP_TECH_it = ... + beta6*WAGE_EDU_it + u_it

Unde:
- alpha_i: efect fix pe tara (heterogenitate neobservata).
- delta_t: efect fix pe an (socuri comune).
- u_it: eroare idiosincratica.

Variabile incluse:
- EMP_TECH: % angajati in sectoare high-tech (variabila dependenta).
- DESI_AI: % firme care folosesc AI.
- STEM_GRAD: absolventi STEM la 1000 locuitori.
- GOV_RD: cheltuieli guvernamentale R&D (% PIB).
- GDP_CAP: PIB pe cap de locuitor (EUR/PPS).
- DIG_SKILLS: % populatie cu competenta digitala basic+.
- WAGE_EDU (optional): castig orar in educatie (NACE P).
- Region (dummy East/West) poate fi folosita doar in modele pooled/RE; in FE este coliniara.

Transformari aplicate:
- ln_GDP_CAP = log(GDP_CAP) pentru a reduce asimetria distributiei.
- ln_EMP_TECH = log(EMP_TECH) pentru o specificatie log-level (optional).
- Region (East/West) derivata din codul geo.

Dataset panel: `data/processed/panel_data.rds` (generat de `scripts/06_panel_setup.R`).

## 3. Selectia FE vs RE (teste specifice)
Pentru alegerea dintre modele cu efecte fixe (FE) si efecte aleatoare (RE) se folosesc:
- F test (FE vs pooled): testeaza daca efectele individuale sunt semnificative.
- LM test Breusch-Pagan (RE vs pooled): testeaza daca RE este preferabil fata de pooled.
- Hausman test (FE vs RE): daca p-value este mic, FE este preferat (RE este inconsistent).

Script: `scripts/07_panel_model_selection.R`  
Output: `output/tables/panel_model_tests.txt` si `output/tables/panel_model_tests.csv`.
