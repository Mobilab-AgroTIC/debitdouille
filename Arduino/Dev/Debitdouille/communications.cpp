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


// Fonction pour envoyer une commande UBX au GPS
void init_GPS_neo7M(HardwareSerial& gpsSerial, uint8_t* MSG, uint8_t len) {
    for (uint8_t i = 0; i < len; i++) {
        gpsSerial.write(MSG[i]);
        delay(5);
    }
}

// Commande pour forcer GPS/QZSS only (NEO-7M limitation)
uint8_t set_gps_only[] = {
  0xB5, 0x62, // UBX header
  0x06, 0x3E, // CFG-GNSS
  0x24, 0x00, // length = 36
  0x00,       // msgVer
  0x04,       // numTrkChHw
  0x10,       // numTrkChUse
  0x01,       // numConfigBlocks

  // GPS
  0x00,       // gnssId (0 = GPS)
  0x00,       // resTrkCh
  0x10,       // maxTrkCh
  0x01,       // enable
  0x01,       // flags

  // SBAS
  0x01, 0x00, 0x03, 0x00, 0x01,

  // QZSS
  0x05, 0x00, 0x01, 0x00, 0x01,

  // Reserved (fill to 36 bytes)
  0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00
};