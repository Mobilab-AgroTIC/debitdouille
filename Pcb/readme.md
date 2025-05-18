# Débitdouille – Électronique

> Gestion de la partie électronique du projet Débitdouille.

---

## 📑 Description

La partie électronique de **Débitdouille** est responsable de :
- L'acquisition de mesures physiques (débit, pression).
- La gestion de l'alimentation.
- La communication avec l'application.

---

## 🖧 Architecture Électronique

```text
+-------------------------------+
|           Capteurs            |
| - 2 x Débitmètres SIKA         |
| - 1 x Capteur de pression      |
+--------------+----------------+
               |
      +--------v--------+
      |  Microcontrôleur  |
      |     ESP32         |
      +--------+--------+
               |
      +--------v--------+
      |   Module de comm  |
      |    (Wi-Fi / BLE)  |
      +------------------+
```
## 📋 Historique des Versions

### [v1.1] - A venir
- Protection contre l'inversion de polarité 12V
- Ajout résistane pullup 
- Ajout ports débitmètres supplémentaires
- Routage : cloutage, largeur de piste 

### [v1.0] - 2025-05-12
- Première version en production.
- Schéma validé.
- Déploiement du PCB v1.
- Tests fonctionnels réalisés.

## 👥 Auteur et contributeurs 

Christophe Auvergne CA34