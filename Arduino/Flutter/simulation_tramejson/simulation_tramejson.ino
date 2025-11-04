#include <BluetoothSerial.h>
#include <ArduinoJson.h>

BluetoothSerial SerialBT;

void setup() {
  Serial.begin(115200);
  SerialBT.begin("debitdouille");  // Nom visible depuis l'appli Flutter
  Serial.println("Bluetooth prêt !");
  randomSeed(analogRead(0));       // Pour randomiser les valeurs
}

void loop() {
  // Génération de données aléatoires
  float pression = randomFloat(1.00, 4.00, 2);
  float dg1 = randomFloat(0.10, 3.00, 2);
  float dd1 = randomFloat(0.10, 3.00, 2);
  float vitesse = randomFloat(3.0, 9.0, 1);

  StaticJsonDocument<256> doc;
  doc["P"] = pression;
  doc["DG1"] = dg1;
  doc["DD1"] = dd1;

  // Débits supplémentaires parfois présents
  if (random(0, 2)) doc["DG2"] = randomFloat(0.10, 3.00, 2);
  if (random(0, 2)) doc["DD2"] = randomFloat(0.10, 3.00, 2);
  if (random(0, 3) == 0) doc["DG3"] = randomFloat(0.10, 3.00, 2);
  if (random(0, 4) == 0) doc["DD4"] = randomFloat(0.10, 3.00, 2);

  doc["V"] = vitesse;

  String jsonStr;
  serializeJson(doc, jsonStr);

  SerialBT.println(jsonStr);  // Envoi via Bluetooth
  Serial.println("Trame envoyée : " + jsonStr);

  delay(1000); // Pause de 2 secondes
}

// Fonction utilitaire pour random float avec x décimales
float randomFloat(float min, float max, int decimals) {
  float value = min + ((float)random(0, 10000) / 10000.0) * (max - min);
  float scale = pow(10, decimals);
  return roundf(value * scale) / scale;
}
