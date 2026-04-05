// sensors.h

#ifndef _SENSORS_h
#define _SENSORS_h

#if defined(ARDUINO) && ARDUINO >= 100
	#include "arduino.h"
#else
	#include "WProgram.h"
#endif



#include "driver/pcnt.h" // Pour utiliser le compteur de pulses (PCNT)
#include "esp_timer.h"   // Pour utiliser les timers d'ESP32
#include <Ticker.h>  // Pour les timers asynchrones


extern volatile bool FLAG_SYNC_SENSORS;
extern Ticker mesure_debit_timer, mesure_pression_timer;  // Créer un timer pour mesurer le débit chaque seconde


// Structure pour chaque débitmètre
typedef struct {
    uint32_t overflow_cnt;
    volatile double flow;
    uint16_t result;
    pcnt_unit_t unit;
    pcnt_channel_t channel;
    uint8_t gpio_pin;
    portMUX_TYPE timer_mux;
    esp_timer_handle_t timer_handle;
} Debitmetre_t;
// Déclaration de l'instance des débitmètres pour accès global
extern Debitmetre_t debitmetre[4];
extern volatile bool FLAG_DEBITMETRE;
extern const char* debit_name[];
extern float debitmetres_valeurs[4];
extern int NbImpulsionsDebitmetre1;  //Pulses debitmetre gauche
extern int NbImpulsionsDebitmetre2;  //Pulses debitmetre droit
extern int NbImpulsionsDebitmetre3;  //Pulses debitmetre centre droit
extern int NbImpulsionsDebitmetre4;  //Pulses debitmetre centre gauche
extern int NbImpulsionsDebitmetreArray[4]; // Pulses pour chaque débitmètre


// Initialisation de tous les débitmètres
double convert_impulsion_debit(uint8_t id_debitmetre, uint16_t impulsions);

void pcnt_init_all_debitmetres();
void mesure_debit();
// Récupération de la valeur du compteur pour un débitmètre
void pcnt_get_counter(void* p);



//PRESSURE
extern volatile bool FLAG_PRESSION;
extern float pressure;
extern int mesures[];

void mesure_pression();
void lecture_calc_pression(int correctionManometreA, int correctionManometreB);
int calculerMedian();
float calculerMoyenneSansOutliers();

#endif


