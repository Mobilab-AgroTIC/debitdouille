// 
// 
// 

#include "communications.h"
#include "config.h"
#include <Ticker.h>  // Pour les timers asynchrones


//GPS
TinyGPSPlus gps;
Ticker timer_display_gps;  // Créer un timer pour mesurer le débit chaque seconde

volatile bool FLAG_GPS;

float sat = 0, lon = 0, llat = 0, sspeed = 0;

void updateGPS(HardwareSerial& gpsSerial) {
    while (gpsSerial.available()) {
        gps.encode(gpsSerial.read());
    }

    if (gps.location.isValid()) {
        sat = gps.satellites.value();
        lon = gps.location.lng() * 1000000;
        llat = gps.location.lat() * 1000000;
        sspeed = gps.speed.kmph();
    }
    else {
        // Optionnel: gérer la perte de signal ici
    }
}


void gps_display() {
    FLAG_GPS = true;
}