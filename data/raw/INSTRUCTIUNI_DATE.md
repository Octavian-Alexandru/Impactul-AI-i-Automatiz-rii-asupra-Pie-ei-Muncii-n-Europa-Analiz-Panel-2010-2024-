# Instrucțiuni pentru Descărcarea Datelor

Pentru a rula proiectul, trebuie să descărcați seturile de date de pe Eurostat și World Bank și să le salvați în folderul `data/raw`.

## 1. Structura Fișierelor

Vă rugăm să salvați fișierele cu următoarele nume exacte (format CSV sau Excel):

| Variabilă           | Cod Eurostat / Sursă                                           | Nume Fișier Recomandat    | Descriere                           |
| -------------------- | --------------------------------------------------------------- | -------------------------- | ----------------------------------- |
| **EMP_TECH**   | `htec_emp_nat`                                                | `employment_tech.csv`    | Ocuparea în sectoare high-tech     |
| **WAGE_EDU**   | `earn_ses_hourly`                                             | `wages_education.csv`    | Câștiguri salariale în educație |
| **DESI_AI**    | *Digital Economy and Society Index<br />**isoc_eb_ai*** | `desi_ai.csv`            | Indicatori DESI / Digitalizare      |
| **STEM_GRAD**  | `educ_uoe_grad04`                                             | `stem_graduates.csv`     | Absolvenți trețiar STEM           |
| **GOV_RD**     | `gba_nabsfin`                                                 | `gov_rd_expenditure.csv` | Cheltuieli guvernamentale R&D       |
| **GDP_CAP**    | World Bank / Eurostat (`sdg_08_10`)                           | `gdp_per_capita.csv`     | PIB per capita (PPS)                |
| **DIG_SKILLS** | isoc_sk_dskl_i21                                                | `digital_skills.csv`     | Competențe digitale indivizi       |

## 2. Pași pentru Descărcare (Eurostat)

1. Mergeți pe [Eurostat Data Browser](https://ec.europa.eu/eurostat/databrowser/).
2. Căutați codul din tabel (ex: `htec_emp_nat`).
3. Filtrați datele:
   - **Timp**: Selectați tot intervalul 2014-2024 (sau cât mai recent).
   - **Geopolitic**: Selectați `EU27_2020` și toate țările individuale.
4. Descărcați ca **Spreadsheet (Excel)** sau **CSV** (SDMX-CSV este preferabil pentru structură, dar și tabelar e ok).
5. Mutați fișierul descărcat în folderul `data/raw/` din acest proiect și redenumiți-l conform tabelului de mai sus.

## 3. Notă Importanță

Scriptul de curățare (`01_data_cleaning.R`) va căuta aceste fișiere. Dacă aveți nume diferite, va trebui să modificați calea în script.
