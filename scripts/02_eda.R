# ==============================================================================
# 02_eda.R
# Scop: Analiza exploratorie (EDA), Clustering (K-Means) si PCA.
# ==============================================================================

source("scripts/common.R")

library(tidyverse)
library(cluster)
library(factoextra)
library(corrplot)

# 1. Incarcare date
processed_path <- "data/processed/"
df <- readRDS(file.path(processed_path, "analysis_data.rds"))

output_figs <- "output/figures/"
if (!dir.exists(output_figs)) dir.create(output_figs, recursive = TRUE)

message("--- Start Analiza Exploratorie ---")

# 2. Statistici Descriptive
print(summary(df))

# Matricea de corelatie
numeric_vars <- df %>% select_if(is.numeric)
cor_matrix <- cor(numeric_vars, use = "complete.obs")

png(file.path(output_figs, "correlation_matrix.png"), width = 800, height = 800)
corrplot(cor_matrix, method = "circle", type = "upper", tl.col = "black", tl.srt = 45)
dev.off()

# 3. Clustering (K-Means) - Cerința 2.e
# Standardizare
df_scaled <- df %>%
  select(DESI_AI, DIG_SKILLS, STEM_GRAD, GOV_RD) %>%
  scale()

rownames(df_scaled) <- df$geo

# Determinarea numarului optim de clustere (Metoda Elbow)
png(file.path(output_figs, "kmeans_elbow.png"))
fviz_nbclust(df_scaled, kmeans, method = "wss")
dev.off()

# Rulare K-Means (k=3 asumat conform ipotezei din raport)
set.seed(123)
km_res <- kmeans(df_scaled, centers = 3, nstart = 25)

# Vizualizare Clustere
png(file.path(output_figs, "kmeans_clusters.png"))
fviz_cluster(km_res, data = df_scaled,
             palette = "jco",
             ggtheme = theme_minimal(),
             main = "Clustering State UE (Digital Maturity)")
dev.off()

# Adaugare cluster in datasetul principal
df$Cluster <- as.factor(km_res$cluster)

# 4. PCA (Analiza Componentelor Principale)
res_pca <- prcomp(df_scaled, scale = FALSE)

# Vizualizare contributii variabile
png(file.path(output_figs, "pca_variables.png"))
fviz_pca_var(res_pca,
             col.var = "contrib",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE)
dev.off()

# Extragere prima componenta (Index Sintetic)
df$PC1_Digital <- res_pca$x[,1]

# Salvare dataset actualizat (cu Clustere si PC1)
saveRDS(df, file = file.path(processed_path, "analysis_data_enriched.rds"))

message("EDA, Clustering si PCA finalizate. Grafice salvate in output/figures/")
