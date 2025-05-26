#include "BluetoothSerial.h"
#include "Arduino.h"
#include <algorithm>
#include <Wire.h>
#include <TinyGPS++.h>
#include <Preferences.h>
#include "driver/pcnt.h"

HardwareSerial neogps(1);
Preferences preferences;
TinyGPSPlus gps;

// Configuration des broches
#define PIN_PRESSURE 34
#define RXD2 16
#define TXD2 17
#define DEBITMETRE1_PIN 32
#define DEBITMETRE2_PIN 33

// Constantes
const unsigned long period = 1000;
const unsigned long periodPressure = 20;
const int n = 20; // Nombre de valeurs pour le filtre médian

// Variables PCNT
pcnt_unit_t pcntUnit1 = PCNT_UNIT_0;
pcnt_unit_t pcntUnit2 = PCNT_UNIT_1;
int16_t count1 = 0;
int16_t count2 = 0;

// Variables globales
String bluetoothMsg = "";
String messageRecu;
unsigned int valeurRecue;
int calib = 415;
int NbImpulsionsDebitmetre1 = 4000;
int NbImpulsionsDebitmetre2 = 4000;
int correctionManometreA = 70;
int correctionManometreB = 70;
int mesures[n];
int ind = 0;
float debit1, debit2, pressure, sat, lon, llat, sspeed;

// Configuration Bluetooth
const char *pin = "1234";
String device_name = "Calvet";
BluetoothSerial SerialBT;

void setupPCNT() {
    // Configuration du PCNT pour le débitmètre 1
    pcnt_config_t pcntConfig1 = {
        .pulse_gpio_num = DEBITMETRE1_PIN,
        .ctrl_gpio_num = PCNT_PIN_NOT_USED,
        .pos_mode = PCNT_COUNT_INC,
        .neg_mode = PCNT_COUNT_DIS,
        .counter_h_lim = 32767,
        .counter_l_lim = -32768,
        .unit = pcntUnit1,
        .channel = PCNT_CHANNEL_0,
    };
    pcnt_unit_config(&pcntConfig1);
    
    // Configuration du PCNT pour le débitmètre 2
    pcnt_config_t pcntConfig2 = {
        .pulse_gpio_num = DEBITMETRE2_PIN,
        .ctrl_gpio_num = PCNT_PIN_NOT_USED,
        .pos_mode = PCNT_COUNT_INC,
        .neg_mode = PCNT_COUNT_DIS,
        .counter_h_lim = 32767,
        .counter_l_lim = -32768,
        .unit = pcntUnit2,
        .channel = PCNT_CHANNEL_0,
    };
    pcnt_unit_config(&pcntConfig2);
    
    // Démarrer les compteurs
    pcnt_counter_pause(pcntUnit1);
    pcnt_counter_clear(pcntUnit1);
    pcnt_counter_resume(pcntUnit1);
    
    pcnt_counter_pause(pcntUnit2);
    pcnt_counter_clear(pcntUnit2);
    pcnt_counter_resume(pcntUnit2);
}

void setup() {
    Serial.begin(115200);
    neogps.begin(9600, SERIAL_8N1, RXD2, TXD2);
    SerialBT.begin(device_name);
    
    // Initialisation PCNT
    setupPCNT();
    
    // Configuration des broches
    pinMode(DEBITMETRE1_PIN, INPUT_PULLUP);
    pinMode(DEBITMETRE2_PIN, INPUT_PULLUP);
    
    // Récupération des préférences
    preferences.begin("constantes", false);
    int constDeb1 = preferences.getUInt("constDeb1", 0);
    int constDeb2 = preferences.getUInt("constDeb2", 0);
    int constManA = preferences.getUInt("constManA", 0);
    int constManB = preferences.getUInt("constManB", 0);
    preferences.end();
    
    if (constDeb1 != 0) NbImpulsionsDebitmetre1 = constDeb1;
    if (constDeb2 != 0) NbImpulsionsDebitmetre2 = constDeb2;
    if (constManA != 0) correctionManometreA = constManA;
    if (constManB != 0) correctionManometreB = constManB;
}

void loop() {
    static unsigned long lastMillis = 0;
    unsigned long currentMillis = millis();
    
    if (currentMillis - lastMillis >= period) {
        // Lecture des compteurs PCNT
        pcnt_get_counter_value(pcntUnit1, &count1);
        pcnt_get_counter_value(pcntUnit2, &count2);
        
        // Calcul des débits (L/min)
        debit1 = (count1 * 60000.0) / (currentMillis - lastMillis) / NbImpulsionsDebitmetre1;
        debit2 = (count2 * 60000.0) / (currentMillis - lastMillis) / NbImpulsionsDebitmetre2;
        
        // Réinitialisation des compteurs
        pcnt_counter_clear(pcntUnit1);
        pcnt_counter_clear(pcntUnit2);
        
        // Lecture pression
        if (ind < n) {
            mesures[ind] = analogRead(PIN_PRESSURE);
            ind++;
        } else {
            int mediane = calculerMedian();
            pressure = (((((mediane-calib)*2.400/4096.000)*4)-(correctionManometreB/100.000)) / (correctionManometreA/100.000);
            ind = 0;
        }
        
        // Lecture GPS
        while (neogps.available()) {
            gps.encode(neogps.read());
        }
        
        if (gps.location.isValid()) {
            sat = gps.satellites.value();
            lon = gps.location.lng()*1000000;
            llat = gps.location.lat()*1000000;
            sspeed = gps.speed.kmph();
        }
        
        // Envoi Bluetooth
        bluetoothMsg = "A;" + String(pressure) + ";" + String(sat) + ";" + String(lon) + ";" + String(llat) + ";" + String(sspeed) + ";" + String(debit1) + ";" + String(debit2);
        SerialBT.println(bluetoothMsg);
        
        lastMillis = currentMillis;
    }
    
    // Gestion des messages Bluetooth
    recvWithEndMarker();
    if (newData) {
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
    if (messageRecu == "gauche") {
      Serial.println(valeurRecue);
      //Ecriture de la constante gauche
      preferences.begin("constantes", false);
      preferences.putUInt("constDeb1", valeurRecue);
      preferences.end();
      messageRecu = "cns";
    }
    if (messageRecu == "droit") {
      Serial.println(valeurRecue);
      //Ecriture de la constante gauche
      preferences.begin("constantes", false);
      preferences.putUInt("constDeb2", valeurRecue);
      preferences.end();
      messageRecu = "cns";
    }
    if (messageRecu == "manoA") {
      Serial.println(valeurRecue);
      //Ecriture de la constante gauche
      preferences.begin("constantes", false);
      preferences.putUInt("constManA", valeurRecue);
      preferences.end();
      messageRecu = "cns";
    }
    if (messageRecu == "manoB") {
      Serial.println(valeurRecue);
      //Ecriture de la constante gauche
      preferences.begin("constantes", false);
      preferences.putUInt("constManB", valeurRecue);
      preferences.end();
      messageRecu = "cns";
    }
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
      } else {
        receivedChars[ndx] = '\0'; // terminate the string
        ndx = 0;
        newData = true;
      }
    }
  }
  
  // Function to parse the received data
  void parseData() {
    char * strtokIndx; // this is used by strtok() as an index
    
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
