# Changelog V2.0

Cette carte est une proposition d'amélioration de la base existante sans toutefois être une refonte complète.  
Elle permet de tester des fonctionnalités pour les débitmètres et capteurs de pression.  Elle intègre aussi des protections simples (polarité court-circuit) pour protéger l'électronique. 
Rétrocompatible avec l'ancien système, à l'exception du pin mapping du microcontrôleur.

---

## Power

- Entrée via jack DC (avantage : pas d'inversion possible) ou bornier à vis
- Ajout d'une diode de protection contre la polarité inversée
- Fusible réarmable 500 mA continu
- Régulateur DCDC à découpage 5V 2A
- Contrôle de l'alimentation 12V (sortie on/off) avec BTS7004

---

## Microcontrôleur (µC)

- ESP32-C6 SuperMini avec connecteur IPEX
- Attention : aucun pin de disponible en réserve

---

## Capteur de pression

- Alimentation 5V, sortie analogique 3.3V (les pins de l’ESP ne sont pas tolérants au 5V)
- Possibilité d’ajout de capteur 4-20 mA (moins de bruit)
- Pads de sélection pour choisir l’un ou l’autre

---

## Débitmètre

- Possibilité d’en connecter 4
- Bornier 4 fils compatible SIKA
- Le fil non utilisé est une sortie 4-20 mA → Voir multiplexer ADC  
  → Proposition : interroger tous les débitmètres en 4-20 mA via un multiplexeur analogique ? À tester
- Jumper de sélection alimentation : 5V / 12V
- Jumper de sélection : PNP / NPN / push-pull avec résistance de 2.5 kΩ
- Ajout de résistance pour limiter le courant dans la LED de l’opto
- Pull-up de la sortie opto en 3.3V (les pins de l’ESP ne sont pas tolérants au 5V)

---

## Multiplexeur ADC

- À tester
- Prend en charge 4 voies
- Pad de sélection de l’alimentation (3.3V en routine)
- Pad de sélection d’adresse I2C → voir connecteur d’extension
- Lecture des 4 débitmètres ou des capteurs de pression en 4-20 mA

---

## Connecteur d’extension I2C

- Connecteur Grove simple pour ajouter un capteur
- Connecteur d’extension pour débitmètres :
  - Cette carte sera un esclave I2C
  - Alimentera les 4 débitmètres
  - Intégrera un composant de lecture (Mux ADC si 4-20 mA choisi)  
    → Utilité de pouvoir sélectionner l’adresse I2C du Mux, autre solution en I2C ?

---

## GPS

- Sélection de l’alimentation

---

## Général

- Pads de test
- LED d’alimentation (debug facile et peu coûteux)
- Trous de fixation
- Boîtier

---

## Non implémenté

- Pas de possibilité de tester un débitmètre à ultrasons (manque de pins)
- Pas de double empreinte ESP
- Pas de double empreinte GPS ou intégration directe

---

## À prévoir pour la prochaine version V2.1

- Remplacement de l’ESP par une version plus intégrée et avec plus de pins
- L’ESP doit pouvoir lire et reporter l’ensemble des tensions de la carte à des fins de dépannage
- Choix de l’architecture capteur de pression
- Choix de l’architecture débitmètre
- Gain de place : dimuntion à 2 debitmètres, les autres sur extension ?
- connecteurs débitmètres ? 
