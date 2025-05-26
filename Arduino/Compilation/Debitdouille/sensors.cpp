// 
// 
// 

#include "sensors.h"
#include "config.h"
#include "driver/pcnt.h"  //
#include "esp_timer.h"  
#include <Ticker.h>  // Pour les timers asynchrones





///////////////////////////////////////
//          FLOW SENSOR
///////////////////////////////////////

Ticker mesure_debit_timer;  // Créer un timer pour mesurer le débit chaque seconde
volatile bool FLAG_DEBITMETRE;

// Instances des 4 débitmètres
const char* debit_name[] = { "Droit", "Gauche", "CentreDroit", "CentreGauche" };

float debitmetres_valeurs[4];
int NbImpulsionsDebitmetre1 = 1000;  //Pulses debitmetre gauche
int NbImpulsionsDebitmetre2 = 1000;  //Pulses debitmetre droit
int NbImpulsionsDebitmetre3 = 1000;  //Pulses debitmetre centre droit
int NbImpulsionsDebitmetre4 = 1000;  //Pulses debitmetre centre gauche
int NbImpulsionsDebitmetreArray[] = { NbImpulsionsDebitmetre1, NbImpulsionsDebitmetre2, NbImpulsionsDebitmetre3, NbImpulsionsDebitmetre4 }; // Pulses pour chaque débitmètre

//facteur de conversion impulsion débit 
#define PCNT_H_LIM_VAL 20000 // Limite haute du compteur pour tous les débitmètres

// Initialisation des 4 débitmètres
Debitmetre_t debitmetre[] = {
  {0, 0, 0, PCNT_UNIT_0, PCNT_CHANNEL_0, PIN_DEBITMETRE1, portMUX_INITIALIZER_UNLOCKED, NULL},
  {0, 0, 0, PCNT_UNIT_1, PCNT_CHANNEL_0, PIN_DEBITMETRE2, portMUX_INITIALIZER_UNLOCKED, NULL},
  {0, 0, 0, PCNT_UNIT_2, PCNT_CHANNEL_0, PIN_DEBITMETRE3, portMUX_INITIALIZER_UNLOCKED, NULL},
  {0, 0, 0, PCNT_UNIT_3, PCNT_CHANNEL_0, PIN_DEBITMETRE4, portMUX_INITIALIZER_UNLOCKED, NULL},
};

// Fonction de gestion d'interruption pour chaque débitmètre
void IRAM_ATTR pcnt_event_handler(void* arg)
{
    Debitmetre_t* debitmetre = (Debitmetre_t*)arg;
    uint32_t intr_status = 0;
    // Récupère le statut d'interruption pour l'unité
    pcnt_get_event_status(debitmetre->unit, &intr_status);

    // Si l'interruption est causée par une limite haute atteinte
    if (intr_status & PCNT_EVT_H_LIM) {
        portENTER_CRITICAL_ISR(&debitmetre->timer_mux);
        debitmetre->overflow_cnt++;
        portEXIT_CRITICAL_ISR(&debitmetre->timer_mux);
    }
    // Nettoie l'interruption pour l'unité
    pcnt_counter_clear(debitmetre->unit);
}

// Initialisation d'un débitmètre
void pcnt_init_debitmetre(Debitmetre_t* debitmetre)
{
    pinMode(debitmetre->gpio_pin, INPUT);
    pcnt_config_t pcnt_config = {
        .pulse_gpio_num = debitmetre->gpio_pin,
        .ctrl_gpio_num = -1,
        .lctrl_mode = PCNT_MODE_KEEP,
        .hctrl_mode = PCNT_MODE_KEEP,
        .pos_mode = PCNT_COUNT_INC,
        .neg_mode = PCNT_COUNT_INC,
        .counter_h_lim = PCNT_H_LIM_VAL,
        .counter_l_lim = 0,
        .unit = debitmetre->unit,
        .channel = debitmetre->channel
    };

    pcnt_unit_config(&pcnt_config);
    pcnt_isr_register(pcnt_event_handler, debitmetre, 0, NULL);
    pcnt_set_filter_value(debitmetre->unit, 2000);  // Filtrage des glitches
    pcnt_filter_enable(debitmetre->unit);
    pcnt_counter_pause(debitmetre->unit);
    pcnt_counter_clear(debitmetre->unit);
    pcnt_event_enable(debitmetre->unit, PCNT_EVT_H_LIM);  // Déclenchement si dépassement de la limite
    pcnt_counter_resume(debitmetre->unit);

    esp_timer_create_args_t timer_args = {
        .callback = pcnt_get_counter,
        .arg = debitmetre,
        .name = "flowmeter timer"
    };

    if (esp_timer_create(&timer_args, &debitmetre->timer_handle) != ESP_OK)
    {
        Serial.printf("Erreur lors de la création du timer pour le débitmètre GPIO : %d\n", debitmetre->gpio_pin);
    }
}

// Fonction pour convertir les impulsions en débit en L/min
double convert_impulsion_debit(uint8_t id_debitmetre, uint16_t impulsions) {
    // Conversion des impulsions en fréquence (Hz)
    // https://fr.aliexpress.com/item/33011866648.html
    // Ici, on suppose que le temps écoulé est de 1 seconde entre chaque lecture
    double frequence = impulsions;  // Si la période de mesure est 1 seconde
    // Conversion de la fréquence en débit en L/min selon la formule du capteur
    double debit = frequence / NbImpulsionsDebitmetreArray[id_debitmetre];  // Q = F / 21
    return debit;
}

// Récupération de la valeur du compteur pour un débitmètre
void pcnt_get_counter(void* p)
{
    Debitmetre_t* debitmetre = (Debitmetre_t*)p;
    pcnt_counter_pause(debitmetre->unit);  // Pause du compteur
    pcnt_get_counter_value(debitmetre->unit, (int16_t*)&debitmetre->result);  // Récupère la valeur
    debitmetre->flow = convert_impulsion_debit(debitmetre->unit, debitmetre->result);  // Conversion des impulsions en débit (L/min)
    pcnt_counter_clear(debitmetre->unit);  // Remise à zéro du compteur après récupération
    pcnt_counter_resume(debitmetre->unit); // Reprise du comptage
}



// Fonction qui sera appelée chaque seconde pour mesurer les débits
void mesure_debit() {
    for (int i = 0; i < 4; i++) {
        Debitmetre_t* d = &debitmetre[i];
        pcnt_get_counter(d); // Lire la valeur pour chaque débitmètre
        debitmetres_valeurs[i] = d->flow;
    }
    FLAG_DEBITMETRE = true;
}

// Initialisation de tous les débitmètres
void pcnt_init_all_debitmetres()
{
    for (int i = 0; i < 4; i++) {  // Nous n'avons que 4 unités PCNT disponibles
        pcnt_init_debitmetre(&debitmetre[i]);
    }
}



///////////////////////////////////////
//          PRESSURE
///////////////////////////////////////
volatile bool FLAG_PRESSION;
Ticker mesure_pression_timer;  // Créer un timer pour mesurer le débit chaque seconde
float pressure;
const int n = 20; // Nombre de valeurs à prendre en compte
int mesures[n];
int calib = 415;

void mesure_pression() {
    FLAG_PRESSION = true;
}

;
void lecture_calc_pression(int correctionManometreA, int correctionManometreB) {
    pressure = 0.0;
    int ind = 0;    // Indice actuel dans le tableau


    while (ind < n) {
        mesures[ind] = analogRead(PIN_PRESSURE); // Lecture de la valeur du capteur

        // Calcul de la médiane et de la moyenne
        int mediane = calculerMedian();
        float moyenneFiltree = calculerMoyenneSansOutliers();
        /*
        Serial.println("Valeurs du tableau :");
        for (int i = 0; i < n; i++) {
            Serial.print(mesures[i]);
            Serial.print(" ");
        }
        Serial.println();*/

        // Affichage des résultats
//        Serial.print("Mediane: ");
//        Serial.println(mediane);
        //Serial.print("Moyenne sans outliers: ");
        //Serial.println(moyenneFiltree);

        pressure = (((((mediane - calib) * 2.400 / 4096.000) * 4) - (correctionManometreB / 100.000)) / (correctionManometreA / 100.000));
#if debug_calc_pressure==true
        Serial.print("Val :");
        Serial.println(mesures[ind]); 
        Serial.print("pressure :");
        Serial.println(pressure, 3);
        Serial.print("correctionManometreA :");
        Serial.println(correctionManometreA);
        Serial.print("correctionManometreB :");
        Serial.println(correctionManometreB);
#endif
        ind++; // Incrémentez l'indice
    }

    // Réinitialisation pour la prochaine série de mesures
    ind = 0;

}


// Fonction pour calculer la médiane
int calculerMedian() {
    int valeursTriees[n];
    memcpy(valeursTriees, mesures, sizeof(mesures));
    std::sort(valeursTriees, valeursTriees + n);
    return valeursTriees[n / 2];
}

// Fonction pour calculer la moyenne sans les outliers
float calculerMoyenneSansOutliers() {
    int mediane = calculerMedian();
    int somme = 0;
    int nombreDeValeurs = 0;
    for (int i = 0; i < n; i++) {
        if (abs(mesures[i] - mediane) <= 2) {
            somme += mesures[i];
            nombreDeValeurs++;
        }
    }
    return somme / (float)nombreDeValeurs;
}
