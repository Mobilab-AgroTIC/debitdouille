/*
 Name:		Debitdouille.ino
 Created:	3/28/2025 7:32:26 AM
 Author:	nicol
*/
#include "config.h"

#include "communications.h"
#include "sensors.h"
#include "BluetoothSerial.h"
#include "Arduino.h"
#include <algorithm>
#include <Wire.h>
#include <Preferences.h>


// -----------------------------
String device_name = "débitdouille";
// -----------------------------
HardwareSerial neogps(1);

Preferences preferences;

unsigned long startMillis;
unsigned long currentMillis;
const unsigned long period = 1000;
unsigned long startMillisPressure;
unsigned long currentMillisPressure;
const unsigned long periodPressure = 20;
String  bluetoothMsg = "";  //Message sent through Bluetooth
String messageRecu;
unsigned int valeurRecue;

//#define USE_PIN // Uncomment this to use PIN during pairing. The pin is specified on the line below
const char* pin = "1234"; // Change this to more secure PIN.

///////////////////////////////////

int correctionManometreA = 70;  //Correction manometreA (coeff)
int correctionManometreB = 70;  //Correction manometre (constante)

unsigned int constDeb1;
unsigned int constDeb2;
unsigned int constManA;
unsigned int constManB;

// variables for sensor
float voltage;

char receivedChars[32];  // Variable to store the received data
char message[16];        // Variable to store the part before the ':'
char value[16];          // Variable to store the part after the ':'

bool newData = false;

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

#if !defined(CONFIG_BT_SPP_ENABLED)
#error Serial Bluetooth not available or not enabled. It is only available for the ESP32 chip.
#endif

BluetoothSerial SerialBT;

void setup() {
    Serial.begin(BAUDRATE_DEBUG);
    neogps.begin(BAUDRATE_GPS, SERIAL_8N1, RXD2, TXD2);
    SerialBT.begin(device_name); //Bluetooth device name
    Serial.printf("The device with name \"%s\" is started.\nNow you can pair it with Bluetooth!\n", device_name.c_str());
    //Serial.printf("The device with name \"%s\" and MAC address %s is started.\nNow you can pair it with Bluetooth!\n", device_name.c_str(), SerialBT.getMacString()); // Use this after the MAC method is implemented
#ifdef USE_PIN
    SerialBT.setPin(pin);
    Serial.println("Using PIN");
#endif

    //TIMERS
    //  Initialisation des 4 débitmètres
    pcnt_init_all_debitmetres();
    mesure_debit_timer.attach(1.0, mesure_debit);  // Mesure toutes les 1 secondes
    //  Pression
    mesure_pression_timer.attach(1.0, mesure_pression);
    //  Initialisation GPS
    timer_display_gps.attach(2.0, gps_display); // Affichage toutes les 2 secondes
    //  Envoi bluetooth




    //Récupération des constantes et stockage
    preferences.begin("constantes", false);
    constDeb1 = preferences.getUInt("constDeb1", 0);
    constDeb2 = preferences.getUInt("constDeb2", 0);
    constManA = preferences.getUInt("constManA", 0);
    constManB = preferences.getUInt("constManB", 0);
    preferences.end();

    if (constDeb1 != 0) {
        NbImpulsionsDebitmetre1 = constDeb1;
    }
    if (constDeb2 != 0) {
        NbImpulsionsDebitmetre2 = constDeb2;
    }
    if (constManA != 0) {
        correctionManometreA = constManA;
    }
    if (constManB != 0) {
        correctionManometreB = constManB;
    }
}

void loop() {
    // Gestion GPS
    while (neogps.available()) {
        gps.encode(neogps.read());
    }



    //  Lecture debitmètre 
    if(FLAG_DEBITMETRE) {
        //Print optionnel
        #if debug_debitmetre==true
        slogln("Debits:");
        #endif
        for (int i = 0; i < 4; i++) {
            Debitmetre_t* d = &debitmetre[i];
        #if debug_debitmetre==true
            slogf("\t%s (GPIO %d) : %.2f L/min\n", debit_name[i], d->gpio_pin, d->flow);
        #endif
            //traitement valeur 

        }
        //reset flag 
        FLAG_DEBITMETRE = false;  // Réinitialiser l'indicateur
    }



    //SEMI ASYNC
    //  Lecture GPS 
    if (FLAG_GPS) {
        updateGPS(neogps);
        // Utilise sat, lon, llat, sspeed comme tu veux
#if debug_gps==true
        if (gps.location.isValid()) {
            Serial.print("Satellites: "); Serial.println(sat);
            Serial.print("Longitude: "); Serial.println(lon);
            Serial.print("Latitude: "); Serial.println(llat);
            Serial.print("Speed (km/h): "); Serial.println(sspeed);
        }
        else {
            Serial.println("Finding satellites");
        }
#endif
        //reset flag 
        FLAG_GPS = false;  // Réinitialiser l'indicateur
    }

    if (FLAG_PRESSION) {
        //Lecture sync
        lecture_calc_pression(correctionManometreA, correctionManometreB);
#if debug_pression==true
        Serial.print("Pression : "); Serial.println(pressure);
#endif
        FLAG_PRESSION = false;
    }

    



    currentMillis = millis();
    if (currentMillis - startMillis >= period) // Calcule et envoie toutes les 1 secondes environ
    {
        unsigned long tempsPasse = currentMillis - startMillis;

      //  // PRESSION





        bluetoothMsg = "A;" + String(pressure) + ";" + String(sat) + ";" + String(lon) + ";" + String(llat) + ";" + String(sspeed) + ";" + String(debitmetres_valeurs[0]) + ";" + String(debitmetres_valeurs[1]);
        SerialBT.println(bluetoothMsg);
        Serial.print("bluetoothMsg :");
        Serial.println(bluetoothMsg);
        startMillis = currentMillis;;
    }

    recvWithEndMarker();
    if (newData) {
        Serial.println(messageRecu);
        parseData();
        newData = false;
    }
    // Read received messages
    if (messageRecu == "cns") {
        Serial.println("OK");
        //Récupération des constantes et envoie en bluetooth
        preferences.begin("constantes", false);
        constDeb1 = preferences.getUInt("constDeb1", 0);
        constDeb2 = preferences.getUInt("constDeb2", 0);
        constManA = preferences.getUInt("constManA", 0);
        constManB = preferences.getUInt("constManB", 0);

        preferences.end();
        if (constDeb1 != 0) {
            NbImpulsionsDebitmetre1 = constDeb1;
        }
        if (constDeb2 != 0) {
            NbImpulsionsDebitmetre2 = constDeb2;
        }
        if (constManA) {
            correctionManometreA = constManA;
        }
        if (constManB) {
            correctionManometreB = constManB;
        }
        bluetoothMsg = "B;" + String(NbImpulsionsDebitmetre1) + ";" + String(NbImpulsionsDebitmetre2) + ";" + String(correctionManometreA) + ";" + String(correctionManometreB);
        SerialBT.println(bluetoothMsg);
        Serial.println(bluetoothMsg);
        //    Serial.println(messageRecu);
        messageRecu = "";
        //    Serial.println(messageRecu);
    }
    //if (messageRecu == "gauche") {
    //    Serial.println(valeurRecue);
    //    //Ecriture de la constante gauche
    //    preferences.begin("constantes", false);
    //    preferences.putUInt("constDeb1", valeurRecue);
    //    preferences.end();
    //    messageRecu = "cns";
    //}
    //if (messageRecu == "droit") {
    //    Serial.println(valeurRecue);
    //    //Ecriture de la constante gauche
    //    preferences.begin("constantes", false);
    //    preferences.putUInt("constDeb2", valeurRecue);
    //    preferences.end();
    //    messageRecu = "cns";
    //}
    //if (messageRecu == "manoA") {
    //    Serial.println(valeurRecue);
    //    //Ecriture de la constante gauche
    //    preferences.begin("constantes", false);
    //    preferences.putUInt("constManA", valeurRecue);
    //    preferences.end();
    //    messageRecu = "cns";
    //}
    //if (messageRecu == "manoB") {
    //    Serial.println(valeurRecue);
    //    //Ecriture de la constante gauche
    //    preferences.begin("constantes", false);
    //    preferences.putUInt("constManB", valeurRecue);
    //    preferences.end();
    //    messageRecu = "cns";
    //}
}

// Function to receive data with an end marker
void recvWithEndMarker() {
    static byte ndx = 0;
    char endMarker = '\n';
    char rc;

    while (SerialBT.available() > 0 && newData == false) {
        rc = SerialBT.read();

        /*    if (rc != endMarker){
              messageRecu += String(rc);
            }
            else{
              messageRecu = "";
            }
        */    if (rc != endMarker) {
            receivedChars[ndx] = rc;
            ndx++;
            if (ndx >= sizeof(receivedChars) - 1) {
                ndx = sizeof(receivedChars) - 1;
            }
        }
        else {
            receivedChars[ndx] = '\0'; // terminate the string
            ndx = 0;
            newData = true;
        }
    }
}

// Function to parse the received data
void parseData() {
    char* strtokIndx; // this is used by strtok() as an index

    strtokIndx = strtok(receivedChars, ":"); // get the first part - the message
    strcpy(message, strtokIndx); // copy it to message variable

    strtokIndx = strtok(NULL, ":"); // get the second part - the value
    strcpy(value, strtokIndx); // copy it to value variable
    messageRecu = message;
    valeurRecue = atoi(value);
    // Now you can use the 'message' and 'value' variables
    Serial.print("Message: ");
    Serial.println(messageRecu);
    Serial.print("Value: ");
    Serial.println(valeurRecue);
}