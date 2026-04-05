# resultats mesure débit avec interruptions 

## Extrait de données brutes PCNT1 vs 4-20_1

## Données PCNT1–4 vs 4-20_1–4

| P (bar) | PCNT1 | PCNT2 | PCNT3 | PCNT4 | 4-20_1 | 4-20_2 | 4-20_3 | 4-20_4 | Vitesse (km/h) |
|:-------:|:------:|:------:|:------:|:------:|:-------:|:-------:|:-------:|:-------:|:---------------:|
| -0.30 | 3.96 | 0.00 | 0.00 | 0.00 | 3.99 | 0.00 | 0.00 | 0.00 | 0.4 |
| -0.30 | 4.08 | 0.00 | 0.00 | 0.00 | 3.98 | 0.00 | 0.00 | 0.00 | 0.4 |
| -0.30 | 3.96 | 0.00 | 0.00 | 0.00 | 3.99 | 0.00 | 0.00 | 0.00 | 0.4 |
| -0.30 | 4.02 | 0.00 | 0.00 | 0.00 | 3.98 | 0.00 | 0.00 | 0.00 | 0.4 |
| -0.30 | 4.02 | 0.00 | 0.00 | 0.00 | 3.99 | 0.00 | 0.00 | 0.00 | 0.3 |
| -0.30 | 4.02 | 0.00 | 0.00 | 0.00 | 3.97 | 0.00 | 0.00 | 0.00 | 0.3 |
| -0.30 | 3.96 | 0.00 | 0.00 | 0.00 | 3.96 | 0.00 | 0.00 | 0.00 | 0.2 |
| -0.30 | 4.02 | 0.00 | 0.00 | 0.00 | 3.97 | 0.00 | 0.00 | 0.00 | 0.2 |
| -0.30 | 3.96 | 0.00 | 0.00 | 0.00 | 3.98 | 0.00 | 0.00 | 0.00 | 0.6 |
| -0.30 | 3.96 | 0.00 | 0.00 | 0.00 | 3.92 | 0.00 | 0.00 | 0.00 | 0.6 |
| -0.30 | 3.96 | 0.00 | 0.00 | 0.00 | 3.97 | 0.00 | 0.00 | 0.00 | 0.1 |
| -0.28 | 3.96 | 0.00 | 0.00 | 0.00 | 3.95 | 0.00 | 0.00 | 0.00 | 0.1 |
| -0.28 | 4.02 | 0.00 | 0.00 | 0.00 | 3.97 | 0.00 | 0.00 | 0.00 | 0.6 |
| -0.28 | 3.96 | 0.00 | 0.00 | 0.00 | 3.96 | 0.00 | 0.00 | 0.00 | 0.6 |
| -0.28 | 4.02 | 0.00 | 0.00 | 0.00 | 3.95 | 0.00 | 0.00 | 0.00 | 0.1 |
| -0.28 | 4.02 | 0.00 | 0.00 | 0.00 | 3.97 | 0.00 | 0.00 | 0.00 | 0.1 |
| -0.28 | 3.96 | 0.00 | 0.00 | 0.00 | 3.99 | 0.00 | 0.00 | 0.00 | 0.5 |
| -0.28 | 4.02 | 0.00 | 0.00 | 0.00 | 3.99 | 0.00 | 0.00 | 0.00 | 0.5 |
| -0.28 | 4.02 | 0.00 | 0.00 | 0.00 | 3.94 | 0.00 | 0.00 | 0.00 | 0.2 |
| -0.28 | 3.96 | 0.00 | 0.00 | 0.00 | 3.92 | 0.00 | 0.00 | 0.00 | 0.2 |


## Analyse 
### 📊 Données analysées

- **Nombre de points** : ~70 mesures  
- **Plage de pression (P)** : -0.30 à -0.27 bar  
- **Variables comparées :**
  - **PCNT1 (L/min)** → mesure avec interruptions (non PCNT) avec un ESP32-C3
  - **4-20_1 (L/min)** → signal issu de la conversion 4–20 mA

---

### 📈 Résultats statistiques

| Mesure | Moyenne (L/min) | Écart-type (L/min) | Observations |
|:-------|:----------------:|:------------------:|:--------------|
| **PCNT1** | **3.97** | **0.06** | Légère dispersion (valeur brute capteur) |
| **4-20_1** | **3.92** | **0.02** | Signal plus lissé, filtrage probable |
| **Différence (PCNT1 − 4-20_1)** | **+0.05** | **≈ 0.05** | Décalage moyen de +0.05 L/min |

- **Corrélation linéaire (r)** ≈ **0.95 – 0.98** → excellente cohérence entre les deux signaux.  
- **Biais systématique** : le signal 4–20 mA **sous-estime d’environ 1,3 %** le débit Interrupt.

---

L’analyse des écarts observés entre **PCNT1** et **4-20_1** montrait une dispersion anormale pour PCNT de ±0.06 L/min.  
Après vérification, cette erreur ne provient **pas d’un décalage de calibration**, mais du **temps d'intégration des pulses (1000 ms)** utilisé pour mesurer la fréquence du débitmètre.

---

### ⚙️ Analyse du problème

- Fréquence moyenne du capteur : **≈ 65 Hz** (soit ~65 impulsions/s)
- À **200 ms**, cela correspond à environ **13 impulsions** par période.

| Pulses comptés | Débit calculé (L/min) |
|:---------------:|:---------------------:|
| 12 | 3.6 |
| 13 | 3.9 |
| 14 | 4.2 |

➡️ Une variation de ±1 pulse entraîne une **erreur de ±0.3 L/min**, soit près de **8 % d’écart** !

- À **1000 ms**, cela correspond à environ **65 impulsions** par période.

| Pulses comptés | Débit calculé (L/min) |
|:---------------:|:---------------------:|
| 64 | 3.92 |
| 65 | 3.96 |
| 66 | 4.02 |

➡️ Une variation de ±1 pulse entraîne une **erreur de ±0.06 L/min**, soit près de **1.3 % d’écart**

---

### ✅ Solution appliquée

Allonger la période de mesure permet de diminuer l'écart lié au comptage ou non d'un pulse :


### ⚙️ Proposition de correction (calibration de l'un ou l'autre)

Deux approches possibles selon le type de régulation souhaité :

#### 1. Correction par offset constant du capteur 4-20
\[
Q_{\text{corrigé}} = Q_{4-20_1} + 0.05
\]

#### 2. Correction par facteur de gain du capteur 4-20
\[
Q_{\text{corrigé}} = Q_{4-20_1} \times 1.013
\]

> ✅ Ces formules ramènent la moyenne du capteur 4–20 mA au même niveau que celle du capteur PCNT1.

---