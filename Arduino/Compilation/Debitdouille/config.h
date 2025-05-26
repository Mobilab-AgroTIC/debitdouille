#pragma once

////////////////////////////////////
////////		PARAMETRAGE
////////////////////////////////////

#define VERSION "1.1"

#define BAUDRATE_DEBUG		115200UL//Baudrate Serial
#define BAUDRATE_GPS		9600UL//Baudrate Serial
#define debug_serial		true
#define debug_debitmetre	true
#define debug_pressure		true
#define debug_calc_pressure	false
#define debug_gps			true


#define ON				1
#define OFF				0



////////////////////////////////////
////////		PINS
////////////////////////////////////
#define PIN_DEBITMETRE1 34
#define PIN_DEBITMETRE2 33
#define PIN_DEBITMETRE3 32
#define PIN_DEBITMETRE4 31


// pin connexions
#define PIN_PRESSURE 34

//GPS pins
#define RXD2 16
#define TXD2 17


////////////////////////////////////
////////		Fonctions
////////////////////////////////////
//slog make the Serial.print run only if the QUIET argument of the command vector is not set
//Log make the Serial.print run only if the QUIET argument of the command vector is not set
#define slog(x) ((!debug_serial) ? 0 : Serial.print(x));
#define slogln(x) ((!debug_serial) ? 0 : Serial.println(x));
#define slogf(x, ...) ((!debug_serial) ? 0 : Serial.printf(x,__VA_ARGS__));
