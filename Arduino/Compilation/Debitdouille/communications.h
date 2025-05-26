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

void updateGPS(HardwareSerial& gpsSerial);
void gps_display();


//Bluetooth





#endif

