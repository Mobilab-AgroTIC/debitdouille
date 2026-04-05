# À prévoir pour la prochaine version V2.1
## Erreur / améliorations constatées V2.0
- Silkscreen manquant prod ??? 
- changer la valeur de la résistance des capteurs 4-20 : utiliser toute la gamme de l'ADS1115 gain 1 = 2048mV => résistance de 100R pour lire 2V à 20mA
- détecter les alimentations pour ne pas allumer l'output quand il n'y a pas de 12V in 
- flyback diode connecteur debitmètre 
- pourquoi on retrouve du 5V sur le 12V quand on alimente par USB ? 
- pins Rx et Tx GPS pour le modèle 2 inversés

## é verifier 
- Remplacement de l’ESP par une version plus intégrée et avec plus de pins
- L’ESP doit pouvoir lire et reporter l’ensemble des tensions de la carte à des fins de dépannage
- Choix de l’architecture capteur de pression
- Choix de l’architecture débitmètre
- Gain de place : dimuntion à 2 debitmètres, les autres sur extension ?
- connecteurs débitmètres ? 
