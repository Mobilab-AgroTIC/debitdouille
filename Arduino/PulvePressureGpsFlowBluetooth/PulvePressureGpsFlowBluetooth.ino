#include "BluetoothSerial.h"
#include "Arduino.h"
#include <algorithm>
#include <Wire.h>
#include <TinyGPS++.h>
#include <Preferences.h>

// -----------------------------
String device_name = "Débitdouille";
// -----------------------------

HardwareSerial neogps(1);
Preferences preferences;

TinyGPSPlus gps;

// pin connexions
#define PIN_PRESSURE 34

//GPS pins
#define RXD2 16
#define TXD2 17

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
const char *pin = "1234"; // Change this to more secure PIN.


int calib = 415;

// Flowmeter
const byte debitmetre1 = 33; // broche utilisée pour déclencher l'interruption du debitmètre 1
const byte debitmetre2 = 32; // broche utilisée pour déclencher l'interruption du debitmètre 1
volatile long nbPulse1 = 0;  // compteur d'impulsions débitmètre 1
volatile long nbPulse2 = 0;  // compteur d'impulsions débitmètre 2
byte pulses1;
byte pulses2;
long NombreDimpulsions1 = 0;
long NombreDimpulsions2 = 0;
float debit1;
float debit2;
unsigned long timer;
int NbImpulsionsDebitmetre1 = 1000;  //Pulses debitmetre gauche
int NbImpulsionsDebitmetre2 = 1000;  //Pulses debitmetre droit
int correctionManometreA = 70;  //Correction manometreA (coeff)
int correctionManometreB = 70;  //Correction manometre (constante)

unsigned int constDeb1;
unsigned int constDeb2;
unsigned int constManA;
unsigned int constManB;

const int n = 20; // Nombre de valeurs à prendre en compte
int mesures[n];   // Tableau pour stocker les mesures
int ind = 0;    // Indice actuel dans le tableau

// variables for sensor
int val, prescbar;
float pressure, voltage, sat, lon, llat, sspeed;

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

void ICACHE_RAM_ATTR comptage1() {  // incremente nbPulse1 à chaque interruption
  nbPulse1++;
}
void ICACHE_RAM_ATTR comptage2() {  // incremente nbPulse1 à chaque interruption
  nbPulse2++;
}

void setup() {
  Serial.begin(115200);
  neogps.begin(9600, SERIAL_8N1, RXD2, TXD2);
  SerialBT.begin(device_name); //Bluetooth device name
  Serial.printf("The device with name \"%s\" is started.\nNow you can pair it with Bluetooth!\n", device_name.c_str());
  //Serial.printf("The device with name \"%s\" and MAC address %s is started.\nNow you can pair it with Bluetooth!\n", device_name.c_str(), SerialBT.getMacString()); // Use this after the MAC method is implemented
  #ifdef USE_PIN
    SerialBT.setPin(pin);
    Serial.println("Using PIN");
  #endif

  // Broche du débitmètre en INPUT_PULLUP
  pinMode(debitmetre1, INPUT_PULLUP);
  pinMode(debitmetre2, INPUT_PULLUP);
  // Mettre la broche du débimetre en interrupt, assignation de la fonction comptage et réglage en FALLING (NPN)
  attachInterrupt(digitalPinToInterrupt(debitmetre1), comptage1, CHANGE);  // a chaque interruption lance comptage1
  attachInterrupt(digitalPinToInterrupt(debitmetre2), comptage2, CHANGE);  // a chaque interruption lance comptage2

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
currentMillis = millis();
if(currentMillis - startMillis >= period) // Calcule et envoie toutes les 1 secondes environ
  {
    // Désactive les interruptions
    noInterrupts();
    // Récupère les valeurs pour le calcul
    pulses1 = nbPulse1;
    nbPulse1 = 0;
    pulses2 = nbPulse2;
    nbPulse2 = 0;
    // Réactive les interruptions
    interrupts();
        
    // 1000 pulse = 1L
    // L/min
    debit1 = 60000.0 / (currentMillis - startMillis) * pulses1 / NbImpulsionsDebitmetre1/2;
    debit2 = 60000.0 / (currentMillis - startMillis) * pulses2 / NbImpulsionsDebitmetre2/2;

    unsigned long tempsPasse = currentMillis - startMillis;
/*    Serial.print("Temps passe : ");
    Serial.println(tempsPasse);
    Serial.print("pulses 1 : ");
    Serial.println(pulses1);
    Serial.print("Debit 1 : ");
    Serial.println(debit1);
    
/*    currentMillisPressure = millis();
    if(currentMillisPressure - startMillisPressure >= periodPressure) // 
      {*/

        // Remplissage du tableau pression
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
        
        pressure = (((((mediane-calib)*2.400/4096.000)*4)-(correctionManometreB/100.000)) / (correctionManometreA/100.000));
        
        Serial.print("Val :");
        Serial.println(val);
        Serial.print("pressure :");
        Serial.println(pressure,3);
        Serial.print("correctionManometreA :");
        Serial.println(correctionManometreA);
        Serial.print("correctionManometreB :");
        Serial.println(correctionManometreB);
    
        ind++; // Incrémentez l'indice
      }
/*      startMillisPressure = currentMillisPressure;
    }*/
  
    // Réinitialisation pour la prochaine série de mesures
    ind = 0;
  
    while (neogps.available())
    {
      gps.encode(neogps.read());
    }
  
    if (gps.location.isValid() == 1){
//      Serial.print("Sats : ");
//      Serial.println(gps.satellites.value());
      sat = gps.satellites.value();
//      Serial.print("lon : ");
//      Serial.println(gps.location.lng(),6);
      lon = gps.location.lng()*1000000;
//      Serial.print("lat : ");
//      Serial.println(gps.location.lat(),6);
      llat = gps.location.lat()*1000000;
//      Serial.print("vitessse : ");
//      Serial.println(gps.speed.kmph());
      sspeed = gps.speed.kmph();
//      Serial.print("Altitude : ");
//      Serial.println(gps.altitude.meters(), 0);
    }else{
      Serial.println("Finding satellites");
    }
    bluetoothMsg = "A;" + String(pressure) + ";" + String(sat) + ";" + String(lon) + ";" + String(llat) + ";" + String(sspeed) + ";" + String(debit1) + ";" + String(debit2);
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
