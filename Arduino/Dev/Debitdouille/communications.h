// communications.h

#ifndef _COMMUNICATIONS_h
#define _COMMUNICATIONS_h

#if defined(ARDUINO) && ARDUINO >= 100
	#include "arduino.h"
#else
	#include "WProgram.h"
#endif


#include <TinyGPS++.h>
#include <Ticker.h>  // Pour les timers asynchrones



//GPS

extern TinyGPSPlus gps;
extern Ticker timer_display_gps;
extern volatile bool FLAG_GPS;
extern float sat, lon, llat, sspeed;
extern uint8_t set_gps_only[50];

void updateGPS(HardwareSerial& gpsSerial);
void gps_display();
void init_GPS_neo7M(HardwareSerial& gpsSerial, uint8_t* MSG, uint8_t len);

//Bluetooth





#endif

