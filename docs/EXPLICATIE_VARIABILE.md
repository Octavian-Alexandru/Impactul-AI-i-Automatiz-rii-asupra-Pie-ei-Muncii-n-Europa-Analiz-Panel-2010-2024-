# Explicarea Variabilelor și a Datelor Eurostat

Acest document detaliază ce informații specifice căutăm în fișierele Eurostat și de ce sunt esențiale pentru modelul econometric.

## 1. Analiza Fișierului `h_tec_emp_nat2` (Ocuparea în High-Tech)

Fișierul pe care l-ai încărcat ("*Employed persons in technology and knowledge-intensive sectors*") este complex pentru că Eurostat exportă combinații multiple de date în același Excel.

### De ce a fost ales Sheet 6?
Eurostat împarte datele astfel:
- **Sheet 1-2**: Total economie (toate sectoarele) -> Nu ne ajută, e 100% sau numărul total de angajați.
- **Sheet 3-4**: Agricultură, etc.
- **Sheet 5-6**: **High-technology sectors** (Sectoare de înaltă tehnologie). **Aici este ținta noastră.**

Diferența dintre *Sheet 5* și *Sheet 6* este de obicei unitatea de măsură:
- **Sheet 5** (probabil): Mii de persoane (valori absolute). Ex: 300.000 angajați.
- **Sheet 6** (probabil): **Procent din totalul ocupării** (valori relative). Ex: 5.6%.

**De ce ne trebuie procentul (Sheet 6)?**
Pentru că țările diferă masiv ca mărime. Germania are milioane de angajați în Tech, Malta are mii. Dacă am folosi valori absolute, modelul ar arăta doar că "țările mari au mulți angajați". Folosind procentul (`EMP_TECH`), vedem **densitatea** sectorului tehnologic, indiferent de mărimea țării.

---

## 2. Dicționarul Complet al Variabilelor

Pentru a construi modelul econometric `Y = f(X, Control)`, avem nevoie de următorii indicatori.

### Variabile Dependente (Y) - Ce vrem să explicăm?

#### **A. EMP_TECH (Ocuparea în High-Tech)**
- **Ce reprezintă:** Cât la sută din forța de muncă lucrează în domenii avansate (IT, Telecom, Biotech, R&D).
- **Rol în model:** Este efectul principal. Vrem să vedem dacă digitalizarea (AI) crește acest procent.
- **Sursa:** Fișierul xlsx analizat deja.
- **Unitate:** % din total ocupare.

#### **B. WAGE_EDU (Salariile în Educație)**
- **Ce reprezintă:** Câștigul orar brut/net în sectorul "P - Education".
- **Rol în model:** Vrem să testăm ipoteza „bolii costurilor” (Baumol) și dacă digitalizarea pune presiune pe salariile din sectoarele tradiționale.
- **Fișier:** `earn_ses_hourly` (Structure of Earnings Survey).
- **Ce căutăm:** Salariul pentru sectorul NACE "Education", Total angajați.

### Variabile Independente (X) - Cauzele principale

#### **DESI_AI (Indicele Digitalizării / AI)**
- **Ce reprezintă:** Un scor care arată cât de avansată e o țară la capitolul digital (Connectivitate, Capital Uman, Integrarea Tehnologiei).
- **Rol în model:** Variabila cheie. Arată gradul de "expunere la AI".
- **Ce căutăm:** Scorul agregat DESI sau sub-componenta "Integration of Digital Technology".

#### **STEM_GRAD (Absolvenți STEM)**
- **Ce reprezintă:** Numărul de absolvenți de facultate (Science, Technology, Engineering, Math) la 1000 de locuitori.
- **Rol în model:** Oferta de muncă calificată. Firmele nu pot adopta AI dacă nu au specialiști.
- **Ce căutăm:** Absolvenți nivel terțiar (ISCED 5-8), domenii STEM.

#### **GOV_RD (Cheltuieli Cercetare-Dezvoltare)**
- **Ce reprezintă:** Cât investește statul în R&D (% din PIB).
- **Rol în model:** Arată suportul structural pentru inovație.

### Variabile de Control (Z) - Factori de context

#### **GDP_CAP (PIB pe cap de locuitor)**
- **Ce reprezintă:** Bogăția generală a țării.
- **Rol în model:** Control esențial. Țările bogate au și tech mult, și salarii mari. Trebuie să "izolăm" efectul bogăției pentru a vedea efectul pur al tehnologiei.
- **Transformare:** Se aplică logaritm (`log(GDP)`) pentru a corecta scara.

#### **DIG_SKILLS (Competențe Digitale)**
- **Ce reprezintă:** % din populație cu competențe digitale "Basic or above".
- **Rol în model:** Capacitatea populației generale de a folosi tehnologia.
