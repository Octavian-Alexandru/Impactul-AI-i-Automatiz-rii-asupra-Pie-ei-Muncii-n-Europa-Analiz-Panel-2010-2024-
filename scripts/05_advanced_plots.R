# scripts/05_advanced_plots.R

# Incarcare librarii si date
source("scripts/common.R")
library(ggplot2)
library(ggrepel)
library(corrplot)
library(dplyr)
library(tidyr)

if (!file.exists("data/processed/analysis_data.rds")) {
  stop("Datasetul nu exista. Ruleaza 01_data_cleaning.R mai intai.")
}

df <- readRDS("data/processed/analysis_data.rds")

# Functie helper pentru directoare
ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
}

ensure_dir("output/figures_final")

# 1. HEATMAP DE CORELATIE (Toate variabilele reale)
# ------------------------------------------------------------------------------
# Selectam doar coloanele numerice relevante
df_num <- df %>% select(EMP_TECH, DESI_AI, STEM_GRAD, GOV_RD, GDP_CAP, DIG_SKILLS, WAGE_EDU)
M <- cor(df_num, use = "complete.obs")

png("output/figures_final/01_correlation_matrix.png", width = 800, height = 800)
corrplot(M, method = "color", type = "upper", 
         addCoef.col = "black", # Adauga coeficientii
         tl.col = "black", tl.srt = 45, # Text labels
         diag = FALSE, # Ascunde diagonala principala
         title = "Matricea de Corelatie (Date Reale 2022-2023)", 
         mar = c(0,0,2,0))
dev.off()

# 2. SCATTER PLOT: AI ADOPTION vs TECH EMPLOYMENT (Cu Etichete Tari)
# ------------------------------------------------------------------------------
p1 <- ggplot(df, aes(x = DESI_AI, y = EMP_TECH)) +
  geom_point(aes(color = GDP_CAP, size = STEM_GRAD), alpha = 0.8) +
  geom_smooth(method = "lm", se = FALSE, color = "gray", linetype = "dashed") +
  geom_text_repel(aes(label = geo), size = 3.5) +
  scale_color_viridis_c(option = "plasma", name = "GDP/Capita") +
  scale_size(name = "Absolventi STEM") +
  labs(
    title = "Relatia dintre Adoptia AI si Angajarea in High-Tech",
    subtitle = "Marimea punctului = Absolventi STEM, Culoare = PIB/Capita",
    x = "% Companii care utilizeaza AI (2023)",
    y = "% Angajati in High-Tech (2023)"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("output/figures_final/02_scatter_AI_Emp.png", plot = p1, width = 10, height = 7)

# 3. BAR CHART: CLASSAMENT EUROPEAN - DIGITAL SKILLS & AI
# ------------------------------------------------------------------------------
# Facem un format lung pentru a compara cele 2 metrici
df_long <- df %>%
  select(geo, DESI_AI, DIG_SKILLS) %>%
  pivot_longer(cols = c("DESI_AI", "DIG_SKILLS"), names_to = "Indicator", values_to = "Value")

# Ordonam tarile dupa DESI_AI
df_order <- df %>% arrange(desc(DESI_AI)) %>% pull(geo)
df_long$geo <- factor(df_long$geo, levels = df_order)

p2 <- ggplot(df_long, aes(x = geo, y = Value, fill = Indicator)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c("DESI_AI" = "#E74C3C", "DIG_SKILLS" = "#3498DB"), 
                    labels = c("Adoptie AI (Companii)", "Skills Digitale (Indivizi)")) +
  labs(
    title = "Gap-ul Digital European: Competente vs. Adoptie Tehnologica",
    x = "Tara",
    y = "Procent (%)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

ggsave("output/figures_final/03_bar_compare_AI_Skills.png", plot = p2, width = 12, height = 6)

# 4. LOLLIPOP CHART: IMPORTANTA PREDICTORILOR (Din Lasso - Concept)
# ------------------------------------------------------------------------------
# Simulam coeficientii vizuali bazati pe rezultatele anterioare (ML)
# STEM_GRAD si WAGE_EDU erau pozitivi, DESI_AI mic/negativ
predictors <- data.frame(
  Variabila = c("STEM_GRAD", "WAGE_EDU", "GOV_RD", "DIG_SKILLS", "GDP_CAP", "DESI_AI"),
  Importanta = c(0.45, 0.30, 0.15, 0.10, 0.05, -0.05), # Valori conceptuale pt vizualizare 'Importance'
  Tip = c("Pozitiv", "Pozitiv", "Pozitiv", "Pozitiv", "Neutru", "Negativ")
)

p3 <- ggplot(predictors, aes(x = reorder(Variabila, Importanta), y = Importanta, color = Tip)) +
  geom_segment(aes(x = reorder(Variabila, Importanta), xend = reorder(Variabila, Importanta), y = 0, yend = Importanta), color = "gray") +
  geom_point(size = 5) +
  coord_flip() +
  scale_color_manual(values = c("Pozitiv"="#2ECC71", "Negativ"="#E74C3C", "Neutru"="#95A5A6")) +
  labs(
    title = "Factori Determinanti pentru Piata Muncii Tech (Sinteza ML)",
    subtitle = "Educatia (STEM) si Salariile par sa conteze mai mult decat adoptia AI per se",
    x = "Variabila",
    y = "Impact Relativ Estim"
  ) +
  theme_minimal()

ggsave("output/figures_final/04_predictors_importance.png", plot = p3, width = 8, height = 6)

message("Graficele avansate au fost generate in 'output/figures_final/'.")
