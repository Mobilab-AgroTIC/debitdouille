# ================================================================================
# Analyse statistique comparative : Méthode PCNT vs Méthode 4-20mA
# ================================================================================
# Objectif : Caractériser et comparer deux méthodes de mesure de débit
# Analyser l'impact de la tension de la pompe sur les résultats
# ================================================================================

# Chargement des packages nécessaires
if (!require("tidyverse")) install.packages("tidyverse")
if (!require("car")) install.packages("car")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("gridExtra")) install.packages("gridExtra")
if (!require("broom")) install.packages("broom")
if (!require("GGally")) install.packages("GGally")

library(tidyverse)
library(car)
library(ggplot2)
library(gridExtra)
library(broom)
library(GGally)

# Configuration graphique
theme_set(theme_minimal(base_size = 12))

# ================================================================================
# 1. IMPORTATION ET PRÉPARATION DES DONNÉES
# ================================================================================
setwd('data')
getwd()
# Lecture des données avec le bon séparateur et encodage
data <- read.csv2("comparaisonPCNT_vs_4-20.csv",
                  header = TRUE,
                  dec = ",",
                  sep = ";",
                  skip = 1,  # Sauter la ligne des unités
                  stringsAsFactors = FALSE,
                  fileEncoding = "UTF-8-BOM")  # Gérer le BOM

# Renommer les colonnes proprement
colnames(data) <- c("Pression", "PCNT", "Methode_4_20", "Voltage_pompe")

# Nettoyer et convertir les données
data <- data %>%
  filter(!is.na(PCNT) & PCNT != "" & !is.na(Methode_4_20)) %>%
  mutate(
    Pression = as.numeric(gsub(",", ".", Pression)),
    PCNT = as.numeric(gsub(",", ".", PCNT)),
    Methode_4_20 = as.numeric(gsub(",", ".", Methode_4_20)),
    Voltage_pompe = as.numeric(gsub(",", ".", Voltage_pompe))
  ) %>%
  mutate(
    Voltage_pompe_facteur = factor(Voltage_pompe),
    Difference = PCNT - Methode_4_20,
    Difference_pct = (PCNT - Methode_4_20) / Methode_4_20 * 100,
    Moyenne = (PCNT + Methode_4_20) / 2
  )

# Afficher un aperçu des données
cat("\n=== APERÇU DES DONNÉES ===\n")
print(head(data, 10))
cat("\nDimensions:", nrow(data), "observations x", ncol(data), "variables\n")
cat("\nStructure des données:\n")
str(data)

# Résumé statistique global
cat("\n=== RÉSUMÉ STATISTIQUE GLOBAL ===\n")
print(summary(data %>% select(PCNT, Methode_4_20, Voltage_pompe, Difference)))

# ================================================================================
# 2. STATISTIQUES DESCRIPTIVES PAR MÉTHODE ET PAR VOLTAGE
# ================================================================================

cat("\n=== STATISTIQUES DESCRIPTIVES PAR MÉTHODE ===\n")

# Reformater en format long pour faciliter l'analyse
data_long <- data %>%
  pivot_longer(cols = c(PCNT, Methode_4_20),
               names_to = "Methode",
               values_to = "Debit")

# Statistiques globales par méthode
stats_methode <- data_long %>%
  group_by(Methode) %>%
  summarise(
    N = n(),
    Moyenne = mean(Debit, na.rm = TRUE),
    Mediane = median(Debit, na.rm = TRUE),
    Ecart_type = sd(Debit, na.rm = TRUE),
    CV = sd(Debit, na.rm = TRUE) / mean(Debit, na.rm = TRUE) * 100,
    Min = min(Debit, na.rm = TRUE),
    Max = max(Debit, na.rm = TRUE),
    Q1 = quantile(Debit, 0.25, na.rm = TRUE),
    Q3 = quantile(Debit, 0.75, na.rm = TRUE)
  )
print(stats_methode)

# Statistiques par voltage et par méthode
cat("\n=== STATISTIQUES PAR VOLTAGE ET MÉTHODE ===\n")
stats_voltage_methode <- data_long %>%
  group_by(Voltage_pompe, Methode) %>%
  summarise(
    N = n(),
    Moyenne = mean(Debit, na.rm = TRUE),
    Ecart_type = sd(Debit, na.rm = TRUE),
    CV = sd(Debit, na.rm = TRUE) / mean(Debit, na.rm = TRUE) * 100,
    .groups = "drop"
  )
print(stats_voltage_methode)

# Statistiques sur les différences
cat("\n=== STATISTIQUES SUR LES DIFFÉRENCES (PCNT - 4-20mA) ===\n")
stats_diff <- data %>%
  group_by(Voltage_pompe) %>%
  summarise(
    N = n(),
    Diff_moyenne = mean(Difference, na.rm = TRUE),
    Diff_mediane = median(Difference, na.rm = TRUE),
    Diff_ET = sd(Difference, na.rm = TRUE),
    Diff_pct_moyenne = mean(Difference_pct, na.rm = TRUE),
    Diff_pct_ET = sd(Difference_pct, na.rm = TRUE),
    .groups = "drop"
  )
print(stats_diff)

# ================================================================================
# 3. TESTS DE NORMALITÉ
# ================================================================================

cat("\n=== TESTS DE NORMALITÉ (Shapiro-Wilk) ===\n")

# Test global sur chaque méthode
shapiro_pcnt <- shapiro.test(data$PCNT)
shapiro_420 <- shapiro.test(data$Methode_4_20)
shapiro_diff <- shapiro.test(data$Difference)

cat("\nPCNT: W =", round(shapiro_pcnt$statistic, 4),
    ", p-value =", format.pval(shapiro_pcnt$p.value, digits = 3))
cat("\n4-20mA: W =", round(shapiro_420$statistic, 4),
    ", p-value =", format.pval(shapiro_420$p.value, digits = 3))
cat("\nDifférence: W =", round(shapiro_diff$statistic, 4),
    ", p-value =", format.pval(shapiro_diff$p.value, digits = 3))

# Tests par voltage
cat("\n\n=== TESTS DE NORMALITÉ PAR VOLTAGE ===\n")
normalite_par_voltage <- data %>%
  group_by(Voltage_pompe) %>%
  summarise(
    N = n(),
    Shapiro_PCNT_W = shapiro.test(PCNT)$statistic,
    Shapiro_PCNT_p = shapiro.test(PCNT)$p.value,
    Shapiro_420_W = shapiro.test(Methode_4_20)$statistic,
    Shapiro_420_p = shapiro.test(Methode_4_20)$p.value,
    .groups = "drop"
  )
print(normalite_par_voltage)

# ================================================================================
# 4. TEST DE COMPARAISON APPARIÉE : PCNT vs 4-20mA
# ================================================================================

cat("\n=== TEST T APPARIÉ (PCNT vs 4-20mA) ===\n")

# Test t apparié
test_t_apparie <- t.test(data$PCNT, data$Methode_4_20, paired = TRUE)
print(test_t_apparie)

cat("\nInterprétation:")
if (test_t_apparie$p.value < 0.05) {
  cat("\n→ Il existe une différence significative entre les deux méthodes (p < 0.05)")
} else {
  cat("\n→ Pas de différence significative entre les deux méthodes (p >= 0.05)")
}

# Test de Wilcoxon (non-paramétrique)
cat("\n\n=== TEST DE WILCOXON APPARIÉ (alternative non-paramétrique) ===\n")
test_wilcoxon <- wilcox.test(data$PCNT, data$Methode_4_20, paired = TRUE)
print(test_wilcoxon)

# ================================================================================
# 5. ANALYSE DE CORRÉLATION
# ================================================================================

cat("\n=== ANALYSE DE CORRÉLATION ENTRE LES DEUX MÉTHODES ===\n")

# Corrélation de Pearson
cor_pearson <- cor.test(data$PCNT, data$Methode_4_20, method = "pearson")
print(cor_pearson)

# Corrélation de Spearman (non-paramétrique)
cor_spearman <- cor.test(data$PCNT, data$Methode_4_20, method = "spearman")
cat("\nCorrélation de Spearman (non-paramétrique):\n")
print(cor_spearman)

# Régression linéaire
modele_regression <- lm(Methode_4_20 ~ PCNT, data = data)
cat("\n=== RÉGRESSION LINÉAIRE : 4-20mA ~ PCNT ===\n")
print(summary(modele_regression))

# ================================================================================
# 6. ANALYSE BLAND-ALTMAN
# ================================================================================

cat("\n=== ANALYSE BLAND-ALTMAN ===\n")

# Calcul des limites d'agrément
moyenne_diff <- mean(data$Difference, na.rm = TRUE)
sd_diff <- sd(data$Difference, na.rm = TRUE)
limite_sup <- moyenne_diff + 1.96 * sd_diff
limite_inf <- moyenne_diff - 1.96 * sd_diff

cat("\nBiais moyen (PCNT - 4-20mA):", round(moyenne_diff, 4), "L/min")
cat("\nÉcart-type des différences:", round(sd_diff, 4), "L/min")
cat("\nLimites d'agrément à 95%:")
cat("\n  Limite inférieure:", round(limite_inf, 4), "L/min")
cat("\n  Limite supérieure:", round(limite_sup, 4), "L/min")

# Proportion de points dans les limites
prop_dans_limites <- sum(data$Difference >= limite_inf &
                          data$Difference <= limite_sup, na.rm = TRUE) /
                     nrow(data) * 100
cat("\nProportion de points dans les limites:", round(prop_dans_limites, 2), "%")

# ================================================================================
# 7. ANALYSE DE L'EFFET DU VOLTAGE : ANOVA
# ================================================================================

cat("\n\n=== ANOVA : EFFET DU VOLTAGE SUR LES MÉTHODES ===\n")

# ANOVA pour PCNT
cat("\nANOVA pour la méthode PCNT:\n")
anova_pcnt <- aov(PCNT ~ Voltage_pompe_facteur, data = data)
print(summary(anova_pcnt))

# ANOVA pour 4-20mA
cat("\nANOVA pour la méthode 4-20mA:\n")
anova_420 <- aov(Methode_4_20 ~ Voltage_pompe_facteur, data = data)
print(summary(anova_420))

# ANOVA pour la différence
cat("\nANOVA pour la différence (PCNT - 4-20mA):\n")
anova_diff <- aov(Difference ~ Voltage_pompe_facteur, data = data)
print(summary(anova_diff))

# Test de Levene pour l'homogénéité des variances
cat("\n=== TEST DE LEVENE (homogénéité des variances) ===\n")
levene_pcnt <- leveneTest(PCNT ~ Voltage_pompe_facteur, data = data)
cat("\nPCNT:\n")
print(levene_pcnt)

levene_420 <- leveneTest(Methode_4_20 ~ Voltage_pompe_facteur, data = data)
cat("\n4-20mA:\n")
print(levene_420)

# Tests post-hoc (Tukey) si ANOVA significative
cat("\n=== TESTS POST-HOC (Tukey HSD) ===\n")

if (summary(anova_pcnt)[[1]]$`Pr(>F)`[1] < 0.05) {
  cat("\nTests post-hoc pour PCNT:\n")
  tukey_pcnt <- TukeyHSD(anova_pcnt)
  print(tukey_pcnt)
}

if (summary(anova_420)[[1]]$`Pr(>F)`[1] < 0.05) {
  cat("\nTests post-hoc pour 4-20mA:\n")
  tukey_420 <- TukeyHSD(anova_420)
  print(tukey_420)
}

if (summary(anova_diff)[[1]]$`Pr(>F)`[1] < 0.05) {
  cat("\nTests post-hoc pour la différence:\n")
  tukey_diff <- TukeyHSD(anova_diff)
  print(tukey_diff)
}

# ================================================================================
# 8. ANOVA À MESURES RÉPÉTÉES (modèle mixte)
# ================================================================================

cat("\n\n=== ANOVA À MESURES RÉPÉTÉES ===\n")

# Préparer les données en format long avec ID
data_long_id <- data %>%
  mutate(ID = row_number()) %>%
  pivot_longer(cols = c(PCNT, Methode_4_20),
               names_to = "Methode",
               values_to = "Debit")

# ANOVA à mesures répétées
# Facteurs: Méthode (intra-sujet) et Voltage (inter-sujet)
anova_rm <- aov(Debit ~ Methode * Voltage_pompe_facteur + Error(ID/Methode),
                data = data_long_id)
cat("\nANOVA à mesures répétées (Méthode × Voltage):\n")
print(summary(anova_rm))

# Test de sphéricité n'est pas nécessaire ici car seulement 2 niveaux pour Méthode

# ================================================================================
# 9. ANALYSE DE VARIANCE PAR VOLTAGE
# ================================================================================

cat("\n=== COEFFICIENT DE VARIATION PAR VOLTAGE ===\n")
cv_par_voltage <- data %>%
  group_by(Voltage_pompe) %>%
  summarise(
    CV_PCNT = sd(PCNT) / mean(PCNT) * 100,
    CV_420 = sd(Methode_4_20) / mean(Methode_4_20) * 100,
    Ratio_CV = CV_PCNT / CV_420,
    .groups = "drop"
  )
print(cv_par_voltage)

# Test F pour comparer les variances
cat("\n=== TESTS F POUR COMPARER LES VARIANCES ===\n")
var_tests <- data %>%
  group_by(Voltage_pompe) %>%
  summarise(
    F_stat = var(PCNT) / var(Methode_4_20),
    p_value = var.test(PCNT, Methode_4_20)$p.value,
    .groups = "drop"
  )
print(var_tests)

# ================================================================================
# 10. VISUALISATIONS
# ================================================================================

cat("\n=== GÉNÉRATION DES GRAPHIQUES ===\n")

# 1. Boxplots comparatifs
p1 <- ggplot(data_long, aes(x = Methode, y = Debit, fill = Methode)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 0.5) +
  labs(title = "Comparaison des deux méthodes de mesure",
       subtitle = "Distribution globale des débits",
       x = "Méthode de mesure",
       y = "Débit (L/min)") +
  scale_fill_brewer(palette = "Set2") +
  theme(legend.position = "none")

# 2. Boxplots par voltage
p2 <- ggplot(data_long, aes(x = factor(Voltage_pompe), y = Debit, fill = Methode)) +
  geom_boxplot(alpha = 0.7) +
  labs(title = "Comparaison des méthodes par tension de pompe",
       x = "Voltage pompe (V)",
       y = "Débit (L/min)",
       fill = "Méthode") +
  scale_fill_brewer(palette = "Set2")

# 3. Graphique de corrélation
p3 <- ggplot(data, aes(x = PCNT, y = Methode_4_20)) +
  geom_point(alpha = 0.5, aes(color = factor(Voltage_pompe))) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
  geom_smooth(method = "lm", se = TRUE, color = "blue") +
  labs(title = "Corrélation entre les deux méthodes",
       subtitle = paste0("r = ", round(cor_pearson$estimate, 3),
                        ", p ", ifelse(cor_pearson$p.value < 0.001, "< 0.001",
                                      paste0("= ", round(cor_pearson$p.value, 3)))),
       x = "Méthode PCNT (L/min)",
       y = "Méthode 4-20mA (L/min)",
       color = "Voltage (V)") +
  scale_color_brewer(palette = "Set1") +
  coord_fixed()

# 4. Bland-Altman plot
p4 <- ggplot(data, aes(x = Moyenne, y = Difference)) +
  geom_point(alpha = 0.5, aes(color = factor(Voltage_pompe))) +
  geom_hline(yintercept = moyenne_diff, color = "blue", linetype = "solid", size = 1) +
  geom_hline(yintercept = limite_sup, color = "red", linetype = "dashed") +
  geom_hline(yintercept = limite_inf, color = "red", linetype = "dashed") +
  annotate("text", x = max(data$Moyenne) * 0.95, y = moyenne_diff,
           label = paste0("Biais: ", round(moyenne_diff, 3)), vjust = -0.5) +
  annotate("text", x = max(data$Moyenne) * 0.95, y = limite_sup,
           label = paste0("+1.96 SD: ", round(limite_sup, 3)), vjust = -0.5) +
  annotate("text", x = max(data$Moyenne) * 0.95, y = limite_inf,
           label = paste0("-1.96 SD: ", round(limite_inf, 3)), vjust = 1.5) +
  labs(title = "Bland-Altman Plot",
       subtitle = "Analyse de concordance entre les méthodes",
       x = "Moyenne des deux méthodes (L/min)",
       y = "Différence (PCNT - 4-20mA) (L/min)",
       color = "Voltage (V)") +
  scale_color_brewer(palette = "Set1")

# 5. Distribution des différences
p5 <- ggplot(data, aes(x = Difference)) +
  geom_histogram(aes(y = after_stat(density)), bins = 30,
                 fill = "steelblue", alpha = 0.7) +
  geom_density(color = "red", size = 1) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "darkgreen", size = 1) +
  labs(title = "Distribution des différences (PCNT - 4-20mA)",
       x = "Différence (L/min)",
       y = "Densité")

# 6. Évolution par voltage
p6 <- ggplot(data_long, aes(x = Voltage_pompe, y = Debit, color = Methode)) +
  geom_point(alpha = 0.3, position = position_jitter(width = 0.1)) +
  stat_summary(fun = mean, geom = "line", size = 1) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.2) +
  labs(title = "Évolution des débits en fonction du voltage",
       x = "Voltage pompe (V)",
       y = "Débit (L/min)",
       color = "Méthode") +
  scale_color_brewer(palette = "Set1")

# 7. Résidus du modèle de régression
p7 <- ggplot(data.frame(
  Fitted = fitted(modele_regression),
  Residuals = residuals(modele_regression),
  Voltage = factor(data$Voltage_pompe)
), aes(x = Fitted, y = Residuals)) +
  geom_point(aes(color = Voltage), alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  geom_smooth(se = TRUE, color = "blue") +
  labs(title = "Graphique des résidus (régression linéaire)",
       x = "Valeurs ajustées",
       y = "Résidus",
       color = "Voltage (V)")

# 8. QQ-plots de normalité
p8 <- grid.arrange(
  ggplot(data, aes(sample = PCNT)) +
    stat_qq() +
    stat_qq_line(color = "red") +
    labs(title = "QQ-Plot PCNT", x = "Quantiles théoriques", y = "Quantiles observés"),

  ggplot(data, aes(sample = Methode_4_20)) +
    stat_qq() +
    stat_qq_line(color = "red") +
    labs(title = "QQ-Plot 4-20mA", x = "Quantiles théoriques", y = "Quantiles observés"),

  ggplot(data, aes(sample = Difference)) +
    stat_qq() +
    stat_qq_line(color = "red") +
    labs(title = "QQ-Plot Différence", x = "Quantiles théoriques", y = "Quantiles observés"),

  ncol = 3
)

# Sauvegarde des graphiques
ggsave("graphique_comparaison_methodes.png", p1, width = 10, height = 6, dpi = 300)
ggsave("graphique_boxplots_par_voltage.png", p2, width = 12, height = 6, dpi = 300)
ggsave("graphique_correlation.png", p3, width = 10, height = 8, dpi = 300)
ggsave("graphique_bland_altman.png", p4, width = 12, height = 8, dpi = 300)
ggsave("graphique_distribution_differences.png", p5, width = 10, height = 6, dpi = 300)
ggsave("graphique_evolution_voltage.png", p6, width = 12, height = 6, dpi = 300)
ggsave("graphique_residus.png", p7, width = 10, height = 6, dpi = 300)
ggsave("graphique_normalite.png", p8, width = 15, height = 5, dpi = 300)

cat("\nGraphiques sauvegardés dans le dossier data/\n")

# Afficher les graphiques principaux
print(p1)
print(p2)
print(p3)
print(p4)
print(p5)
print(p6)

# ================================================================================
# 11. SYNTHÈSE ET CONCLUSIONS
# ================================================================================

cat("\n\n")
cat("================================================================================\n")
cat("                        SYNTHÈSE DE L'ANALYSE\n")
cat("================================================================================\n\n")

cat("1. COMPARAISON GLOBALE DES MÉTHODES:\n")
cat("   - Différence moyenne (PCNT - 4-20mA):", round(moyenne_diff, 4), "L/min\n")
cat("   - Test t apparié: p-value =", format.pval(test_t_apparie$p.value, digits = 3), "\n")
cat("   - Corrélation de Pearson: r =", round(cor_pearson$estimate, 3),
    "(p", format.pval(cor_pearson$p.value, digits = 3), ")\n")
cat("   - R² de la régression:", round(summary(modele_regression)$r.squared, 4), "\n\n")

cat("2. CONCORDANCE (Bland-Altman):\n")
cat("   - Biais:", round(moyenne_diff, 4), "L/min\n")
cat("   - Limites d'agrément 95%: [", round(limite_inf, 4), ";",
    round(limite_sup, 4), "] L/min\n")
cat("   - Proportion dans les limites:", round(prop_dans_limites, 2), "%\n\n")

cat("3. EFFET DU VOLTAGE:\n")
cat("   - ANOVA PCNT: p-value =",
    format.pval(summary(anova_pcnt)[[1]]$`Pr(>F)`[1], digits = 3), "\n")
cat("   - ANOVA 4-20mA: p-value =",
    format.pval(summary(anova_420)[[1]]$`Pr(>F)`[1], digits = 3), "\n")
cat("   - ANOVA Différence: p-value =",
    format.pval(summary(anova_diff)[[1]]$`Pr(>F)`[1], digits = 3), "\n\n")

cat("4. INTERPRÉTATION:\n")
if (test_t_apparie$p.value < 0.05) {
  cat("   ➔ Différence significative entre les deux méthodes\n")
} else {
  cat("   ➔ Pas de différence significative entre les deux méthodes\n")
}

if (cor_pearson$estimate > 0.95 & cor_pearson$p.value < 0.001) {
  cat("   ➔ Excellente corrélation entre les méthodes\n")
} else if (cor_pearson$estimate > 0.90) {
  cat("   ➔ Très bonne corrélation entre les méthodes\n")
} else {
  cat("   ➔ Corrélation modérée entre les méthodes\n")
}

if (summary(anova_diff)[[1]]$`Pr(>F)`[1] < 0.05) {
  cat("   ➔ L'écart entre les méthodes varie significativement avec le voltage\n")
} else {
  cat("   ➔ L'écart entre les méthodes reste constant quel que soit le voltage\n")
}

cat("\n================================================================================\n")
cat("                    ANALYSE TERMINÉE AVEC SUCCÈS\n")
cat("================================================================================\n")
