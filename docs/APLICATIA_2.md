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

Interpretare (pe panelul curent 2021-2023):
- F test (FE vs pooled) are p-value = 5.66e-06 => efectele individuale sunt semnificative.
- LM test (RE vs pooled) are p-value = 9.35e-05 => modelul RE este preferabil fata de pooled.
- Hausman (FE vs RE) are p-value = 0.627 => nu respingem RE (RE este acceptabil).

## 4. Estimare model ales, teste pe reziduuri, scenarii
Model adecvat: RE (random effects), conform testelor de la punctul 3.

Script: `scripts/08_panel_estimation_and_scenarios.R`  
Output:
- `output/tables/panel_re_summary.txt` (estimare + erori robuste)
- `output/tables/panel_residual_tests.txt` (Shapiro, Breusch-Pagan, DW, BG)
- `output/tables/panel_scenario_results.csv` (scenariu)

Scenariu: +10% DESI_AI in tarile East, pe ultimul an disponibil din panel.

Interpretare rezultate (panel curent 2021-2023):
- Model RE: ln_GDP_CAP este semnificativ pozitiv; GOV_RD este semnificativ negativ in acest esantion.
- Teste reziduuri: Shapiro (p=0.60), BP (p=0.11), DW (p=0.23), BG (p=0.816) => nu indica probleme majore.
- Scenariu (+10% DESI_AI in East, 2023): crestere medie estimata ~0.0059 p.p. in East,
  ~0.0024 p.p. overall.

## 5. Interpretare econometrica si economica (testarea ipotezelor)
Semnificatie econometrica (H0: beta = 0):
- ln_GDP_CAP: coeficient pozitiv si semnificativ (p=0.015, robust) => respingem H0.
- GOV_RD: coeficient negativ si semnificativ (p=0.040, robust) => respingem H0.
- DESI_AI, STEM_GRAD, DIG_SKILLS: coeficienti nesemnificativi => nu respingem H0.
- Modelul global este semnificativ (chisq p=0.0002), cu R^2 ~0.33 (adj ~0.26).

Interpretare economica:
- ln_GDP_CAP: +1% PIB/capita este asociat cu ~+0.013 p.p. in EMP_TECH, ceteris paribus.
- GOV_RD: +1 p.p. din PIB la R&D public se asociaza cu ~-1.62 p.p. EMP_TECH in acest esantion
  (posibil efect de compositie/crowding-out sau perioada scurta).
- DESI_AI: efect foarte mic si nesemnificativ pe termen scurt; compatibil cu scenariul de prognoza
  (impact mediu foarte redus).
- STEM_GRAD si DIG_SKILLS: semn pozitiv, dar nesemnificativ statistic in panelul curent.

Validarea ipotezelor pe reziduuri:
- Nu se observa devieri majore de la normalitate, heteroscedasticitate sau autocorelatie.

Limitari:
- Panel scurt (T=2), rezultate sensibile la perioada si specificatie.
- RE presupune exogenitatea efectelor individuale fata de regresori.

## 6. Discutii si validare in raport cu literatura
Comparare cu ipotezele initiale:
- Ipoteza AI -> ocupare tech (beta1 > 0) nu este confirmata statistic in panelul curent.
- Capitalul uman si skill-urile digitale au semn pozitiv, dar nu sunt semnificative in esantionul scurt.
- Dezvoltarea economica (ln_GDP_CAP) ramane determinant robust, compatibil cu teoria.

Validare cu literatura:
- Literatura despre automatizare si roboti sugereaza efecte mixte pe ocupare, dependente de structura economiei
  (Autor, 2015; Acemoglu & Restrepo, 2020; Graetz & Michaels, 2018). Rezultatul nostru privind DESI_AI
  nesemnificativ este compatibil cu ideea ca efectele sunt conditionate de capitalul uman si nivelul de dezvoltare.
- Rezultatul pozitiv al ln_GDP_CAP sustine interpretarea ca tarile mai dezvoltate concentreaza ocuparea high-tech.

Semnificatia rezultatelor:
- Exista semnale ca variabilele structurale (dezvoltare economica) explica mai mult variatia EMP_TECH
  decat adoptia AI pe termen scurt in panelul 2021-2023.

Limitari:
- Panel foarte scurt (doar 2 ani), risc de instabilitate a coeficientilor.
- Posibila endogenitate (AI poate fi cauza si efect al dezvoltarii).
- Lipsa unor variabile institutionale/sectoriale care pot influenta ocuparea tech.

Directii pentru cercetari viitoare:
- Extinderea panelului pe interval mai lung si includerea de variabile institutionale (ESG/SGI, politici educationale).
- Modele cu efecte fixe pe timp si eventual instrumente (IV) pentru a trata endogenitatea.
- Compararea cu modele non-liniare si tehnici ML pe panel (random forest panel, GMM).
