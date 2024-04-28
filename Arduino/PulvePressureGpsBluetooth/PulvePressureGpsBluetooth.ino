#include "BluetoothSerial.h"
#include "Arduino.h"
#include <algorithm>
#include <Wire.h>
#include <TinyGPS++.h>

HardwareSerial neogps(1);

TinyGPSPlus gps;

// pin connexions
#define PIN_PRESSURE 34
#define RXD2 16
#define TXD2 17

unsigned long startMillis;
unsigned long currentMillis;
const unsigned long period = 1000;
String  bluetoothMsg = "";

//#define USE_PIN // Uncomment this to use PIN during pairing. The pin is specified on the line below
const char *pin = "1234"; // Change this to more secure PIN.

String device_name = "PulvePressure";

int calib = 415;

const int n = 20; // Nombre de valeurs à prendre en compte
int mesures[n];   // Tableau pour stocker les mesures
int ind = 0;    // Indice actuel dans le tableau

// variables for sensor
int val, prescbar;
float pressure, voltage, sat, lon, llat, sspeed;

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

#if !defined(CONFIG_BT_SPP_ENABLED)
#error Serial Bluetooth not available or not enabled. It is only available for the ESP32 chip.
#endif

BluetoothSerial SerialBT;

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
}

void loop() {
currentMillis = millis();
if(currentMillis - startMillis >= period) // Calcule et envoie toutes les 1 secondes environ
  {
    // Remplissage du tableau
    while (ind < n) {
      mesures[ind] = analogRead(PIN_PRESSURE); // Lecture de la valeur du capteur
      delay(20); // Attendez 20ms avant la prochaine lecture
  
  
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
      Serial.print("Mediane: ");
      Serial.println(mediane);
      //Serial.print("Moyenne sans outliers: ");
      //Serial.println(moyenneFiltree);
      
      pressure = ((mediane-calib)*2.400/4096.000)*4+1;
      
//      Serial.print("Val :");
//      Serial.println(val);
//      Serial.print("pressure :");
//      Serial.println(pressure,3);
  
      ind++; // Incrémentez l'indice
    }
  
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
    bluetoothMsg = String(pressure) + ";" + String(sat) + ";" + String(lon) + ";" + String(llat) + ";" + String(sspeed);
    SerialBT.println(bluetoothMsg);
    Serial.println(bluetoothMsg);
    startMillis = currentMillis;;
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
