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

Ticker mesure_debit_timer;  // Cr�er un timer pour mesurer le d�bit chaque seconde
volatile bool FLAG_DEBITMETRE;

// Instances des 4 d�bitm�tres
const char* debit_name[] = { "Droit", "Gauche", "CentreDroit", "CentreGauche" };

float debitmetres_valeurs[4];
int NbImpulsionsDebitmetre1 = 1000;  //Pulses debitmetre gauche
int NbImpulsionsDebitmetre2 = 1000;  //Pulses debitmetre droit
int NbImpulsionsDebitmetre3 = 1000;  //Pulses debitmetre centre droit
int NbImpulsionsDebitmetre4 = 1000;  //Pulses debitmetre centre gauche
int NbImpulsionsDebitmetreArray[] = { NbImpulsionsDebitmetre1, NbImpulsionsDebitmetre2, NbImpulsionsDebitmetre3, NbImpulsionsDebitmetre4 }; // Pulses pour chaque d�bitm�tre

//facteur de conversion impulsion d�bit 
#define PCNT_H_LIM_VAL 20000 // Limite haute du compteur pour tous les d�bitm�tres

// Initialisation des 4 d�bitm�tres
Debitmetre_t debitmetre[] = {
  {0, 0, 0, PCNT_UNIT_0, PCNT_CHANNEL_0, PIN_DEBITMETRE1, portMUX_INITIALIZER_UNLOCKED, NULL},
  {0, 0, 0, PCNT_UNIT_1, PCNT_CHANNEL_0, PIN_DEBITMETRE2, portMUX_INITIALIZER_UNLOCKED, NULL},
  {0, 0, 0, PCNT_UNIT_2, PCNT_CHANNEL_0, PIN_DEBITMETRE3, portMUX_INITIALIZER_UNLOCKED, NULL},
  {0, 0, 0, PCNT_UNIT_3, PCNT_CHANNEL_0, PIN_DEBITMETRE4, portMUX_INITIALIZER_UNLOCKED, NULL},
};

// Fonction de gestion d'interruption pour chaque d�bitm�tre
void IRAM_ATTR pcnt_event_handler(void* arg)
{
    Debitmetre_t* debitmetre = (Debitmetre_t*)arg;
    uint32_t intr_status = 0;
    // R�cup�re le statut d'interruption pour l'unit�
    pcnt_get_event_status(debitmetre->unit, &intr_status);

    // Si l'interruption est caus�e par une limite haute atteinte
    if (intr_status & PCNT_EVT_H_LIM) {
        portENTER_CRITICAL_ISR(&debitmetre->timer_mux);
        debitmetre->overflow_cnt++;
        portEXIT_CRITICAL_ISR(&debitmetre->timer_mux);
    }
    // Nettoie l'interruption pour l'unit�
    pcnt_counter_clear(debitmetre->unit);
}

// Initialisation d'un d�bitm�tre
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
    pcnt_event_enable(debitmetre->unit, PCNT_EVT_H_LIM);  // D�clenchement si d�passement de la limite
    pcnt_counter_resume(debitmetre->unit);

    esp_timer_create_args_t timer_args = {
        .callback = pcnt_get_counter,
        .arg = debitmetre,
        .name = "flowmeter timer"
    };

    if (esp_timer_create(&timer_args, &debitmetre->timer_handle) != ESP_OK)
    {
        Serial.printf("Erreur lors de la cr�ation du timer pour le d�bitm�tre GPIO : %d\n", debitmetre->gpio_pin);
    }
}

// Fonction pour convertir les impulsions en d�bit en L/min
double convert_impulsion_debit(uint8_t id_debitmetre, uint16_t impulsions) {
    // Conversion des impulsions en fr�quence (Hz)
    // https://fr.aliexpress.com/item/33011866648.html
    // Ici, on suppose que le temps �coul� est de 1 seconde entre chaque lecture
    double frequence = impulsions;  // Si la p�riode de mesure est 1 seconde
    // Conversion de la fr�quence en d�bit en L/min selon la formule du capteur
    double debit = frequence / NbImpulsionsDebitmetreArray[id_debitmetre];  // Q = F / 21
    return debit;
}

// R�cup�ration de la valeur du compteur pour un d�bitm�tre
void pcnt_get_counter(void* p)
{
    Debitmetre_t* debitmetre = (Debitmetre_t*)p;
    pcnt_counter_pause(debitmetre->unit);  // Pause du compteur
    pcnt_get_counter_value(debitmetre->unit, (int16_t*)&debitmetre->result);  // R�cup�re la valeur
    debitmetre->flow = convert_impulsion_debit(debitmetre->unit, debitmetre->result);  // Conversion des impulsions en d�bit (L/min)
    pcnt_counter_clear(debitmetre->unit);  // Remise � z�ro du compteur apr�s r�cup�ration
    pcnt_counter_resume(debitmetre->unit); // Reprise du comptage
}



// Fonction qui sera appel�e chaque seconde pour mesurer les d�bits
void mesure_debit() {
    for (int i = 0; i < 4; i++) {
        Debitmetre_t* d = &debitmetre[i];
        pcnt_get_counter(d); // Lire la valeur pour chaque d�bitm�tre
        debitmetres_valeurs[i] = d->flow;
    }
    FLAG_DEBITMETRE = true;
}

// Initialisation de tous les d�bitm�tres
void pcnt_init_all_debitmetres()
{
    for (int i = 0; i < 4; i++) {  // Nous n'avons que 4 unit�s PCNT disponibles
        pcnt_init_debitmetre(&debitmetre[i]);
    }
}



///////////////////////////////////////
//          PRESSURE
///////////////////////////////////////
volatile bool FLAG_PRESSION;
Ticker mesure_pression_timer;  // Cr�er un timer pour mesurer le d�bit chaque seconde
float pressure;
const int n = 20; // Nombre de valeurs � prendre en compte
int mesures[n];
int calib = 415;

void mesure_pression() {

    FLAG_PRESSION = true;
}

;
void lecture_calc_pression(int correctionManometreA, int correctionManometreB) {
    pressure = 0.0;
    int ind = 0;    // Indice actuel dans le tableau
    pinMode(PIN_PRESSURE, INPUT);
    delay(1);
    //Test de filtrage 150 kHz
    const int N = 97;//valeur ? voir commentaire ci-dessous :
    /*
 * Filtrage logiciel du bruit p�riodique (ex: 150 kHz) sur ESP32
 * On moyenne un nombre d'�chantillons tel que la dur�e totale
 * couvre un nombre entier de p�riodes du bruit, pour mieux l'att�nuer.
 * 
 * - analogPin : broche analogique � lire (exemple GPIO34)
 * - N : nombre de mesures � moyenner (ici 97 pour couvrir ~1 p�riode de 65 �s / 6,67 �s)
 * 
 * Mesurez d'abord le temps r�el d'un analogRead() sur votre carte pour ajuster N au mieux.
 */
    long somme = 0;
    //unsigned long time_analog, time_mesure;
    //time_mesure = millis();
    for (int i = 0; i < N; i++) {
        //time_analog = micros();
        somme += analogRead(PIN_PRESSURE);//65�s @ F-CPU = 80MHz
        //time_analog = micros() - time_analog;
    }
    int moyenne = somme / N;
    //time_mesure = millis()- time_mesure;
    //Serial.println(time_analog);
    //Serial.println(time_mesure);
    //Serial.println(moyenne);
    pressure = (((((moyenne - calib) * 2.400 / 4096.000) * 4) - (correctionManometreB / 100.000)) / (correctionManometreA / 100.000));

    //Ancienne m�thode 
//    while (ind < n) {
//        mesures[ind] = analogRead(PIN_PRESSURE); // Lecture de la valeur du capteur
//
//        // Calcul de la m�diane et de la moyenne
//        int mediane = calculerMedian();
//        float moyenneFiltree = calculerMoyenneSansOutliers();
//        /*
//        Serial.println("Valeurs du tableau :");
//        for (int i = 0; i < n; i++) {
//            Serial.print(mesures[i]);
//            Serial.print(" ");
//        }
//        Serial.println();*/
//
//        // Affichage des r�sultats
////        Serial.print("Mediane: ");
////        Serial.println(mediane);
//        //Serial.print("Moyenne sans outliers: ");
//        //Serial.println(moyenneFiltree);
//
//        pressure = (((((mediane - calib) * 2.400 / 4096.000) * 4) - (correctionManometreB / 100.000)) / (correctionManometreA / 100.000));
//#if debug_calc_pressure==true
//        Serial.print("Val :");
//        Serial.println(mesures[ind]); 
//        Serial.print("pressure :");
//        Serial.println(pressure, 3);
//        Serial.print("correctionManometreA :");
//        Serial.println(correctionManometreA);
//        Serial.print("correctionManometreB :");
//        Serial.println(correctionManometreB);
//#endif
//        ind++; // Incr�mentez l'indice
//    }
//
//    // R�initialisation pour la prochaine s�rie de mesures
//    ind = 0;

}


// Fonction pour calculer la m�diane
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
