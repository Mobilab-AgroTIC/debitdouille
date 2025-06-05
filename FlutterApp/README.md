# Flutter Débitdouille

Cette application Flutter affiche en temps réel les données envoyées en Bluetooth par le module ESP32 "Débitdouille". Un thème sombre est utilisé et plusieurs pages (connexion, calibration et réglages) sont disponibles via le menu.

## Prérequis
- [Flutter](https://docs.flutter.dev/get-started/install) doit être installé sur votre machine.

## Installation
1. Ouvrir un terminal dans ce dossier.
2. Récupérer les dépendances :
   ```
   flutter pub get
   ```
3. Lancer l'application sur un émulateur ou un appareil connecté :
   ```
   flutter run
   ```

La page principale montre la pression, la vitesse et jusqu'à six débitmètres. Un bouton permet de simuler la réception d'une trame JSON.
