#include <BluetoothSerial.h>
#include <ArduinoJson.h>
#include <EEPROM.h>

BluetoothSerial SerialBT;

#define EEPROM_SIZE 512
#define COEFF_COUNT 7 
#define EEPROM_TAG_ADDR 0
#define EEPROM_TAG_VALUE 1
#define EEPROM_COEFF_START 1  // Juste après le tag

// Coefficients A et B (pression + DG1 à DG3, DD1 à DD3)
struct Coeff {
  float A;
  float B;
};

Coeff pression = {1.0, 0.0};
Coeff dg[3] = {{1.0, 0.0}, {1.0, 0.0}, {1.0, 0.0}};
Coeff dd[3] = {{1.0, 0.0}, {1.0, 0.0}, {1.0, 0.0}};

void setup() {
  Serial.begin(115200);
  
  EEPROM.begin(EEPROM_SIZE);
  loadCoefficientsFromEEPROM();

  SerialBT.begin("debitdouille");
  Serial.println("Bluetooth prêt !");
  randomSeed(analogRead(0));
}

void loop() {
  // Si on reçoit un message Bluetooth
  if (SerialBT.available()) {
    String received = SerialBT.readStringUntil('\n');
    received.trim();
    Serial.println("Reçu : " + received);

    if (received == "coeff") {
      sendCoefficients();
    } else {
      handleCoefficientUpdate(received);
    }
  }

  sendSensorData();
  delay(1000);
}

void sendSensorData() {
  StaticJsonDocument<256> doc;

  float p = applyCoeff(randomFloat(1.0, 4.0, 2), pression);
  float v = randomFloat(3.0, 9.0, 1);
  doc["P"] = p;
  doc["V"] = v;

  for (int i = 0; i < 3; i++) {
    float g = applyCoeff(randomFloat(0.1, 3.0, 2), dg[i]);
    float d = applyCoeff(randomFloat(0.1, 3.0, 2), dd[i]);
    doc["DG" + String(i + 1)] = g;
    doc["DD" + String(i + 1)] = d;
  }

  String jsonStr;
  serializeJson(doc, jsonStr);
  SerialBT.println(jsonStr);
  Serial.println("Trame envoyée : " + jsonStr);
}

void sendCoefficients() {
  StaticJsonDocument<512> doc;
  doc["coeff"] = 1;

  JsonObject cp = doc.createNestedObject("pression");
  cp["A"] = pression.A;
  cp["B"] = pression.B;

  for (int i = 0; i < 3; i++) {
    JsonObject g = doc.createNestedObject("DG" + String(i + 1));
    g["A"] = dg[i].A;
    g["B"] = dg[i].B;

    JsonObject d = doc.createNestedObject("DD" + String(i + 1));
    d["A"] = dd[i].A;
    d["B"] = dd[i].B;
  }

  String jsonStr;
  serializeJson(doc, jsonStr);
  SerialBT.println(jsonStr);
  Serial.println("Trame coeff envoyée : " + jsonStr);
}

void handleCoefficientUpdate(String jsonStr) {
  StaticJsonDocument<256> doc;
  DeserializationError err = deserializeJson(doc, jsonStr);
  if (err) {
    Serial.println("Erreur JSON : " + String(err.c_str()));
    return;
  }

  if (doc["update"] != 1) return;

  String id = doc["id"];
  float A = doc["A"];
  float B = doc["B"];

  if (id == "P") {
    pression = {A, B};
  } else if (id.startsWith("DG")) {
    int index = id.substring(2).toInt() - 1;
    if (index >= 0 && index < 3) dg[index] = {A, B};
  } else if (id.startsWith("DD")) {
    int index = id.substring(2).toInt() - 1;
    if (index >= 0 && index < 3) dd[index] = {A, B};
  }
  saveCoefficientToEEPROM(id, {A, B});
  Serial.println("Coefficient mis à jour pour " + id + ": A=" + String(A) + ", B=" + String(B));
}

float applyCoeff(float value, Coeff c) {
  return c.A * value + c.B;
}

float randomFloat(float min, float max, int decimals) {
  float value = min + ((float)random(0, 10000) / 10000.0) * (max - min);
  float scale = pow(10, decimals);
  return roundf(value * scale) / scale;
}

void loadCoefficientsFromEEPROM() {
  EEPROM.begin(EEPROM_SIZE);
  byte tag = EEPROM.read(EEPROM_TAG_ADDR);

  if (tag != EEPROM_TAG_VALUE) {
    Serial.println("Première utilisation : initialisation des coefficients par défaut...");
    // Valeurs par défaut : A = 1, B = 0
    pression = {1.0, 0.0};
    for (int i = 0; i < 3; i++) {
      dg[i] = {1.0, 0.0};
      dd[i] = {1.0, 0.0};
    }

    // Sauvegarde en EEPROM
    EEPROM.put(EEPROM_COEFF_START, pression);
    for (int i = 0; i < 3; i++) {
      EEPROM.put(EEPROM_COEFF_START + sizeof(Coeff) * (i + 1), dg[i]);
      EEPROM.put(EEPROM_COEFF_START + sizeof(Coeff) * (i + 4), dd[i]);
    }

    EEPROM.write(EEPROM_TAG_ADDR, EEPROM_TAG_VALUE);  // Tag mis à 1
    EEPROM.commit();
  } else {
    EEPROM.get(EEPROM_COEFF_START, pression);
    for (int i = 0; i < 3; i++) {
      EEPROM.get(EEPROM_COEFF_START + sizeof(Coeff) * (i + 1), dg[i]);
      EEPROM.get(EEPROM_COEFF_START + sizeof(Coeff) * (i + 4), dd[i]);
    }
    Serial.println("Coefficients chargés depuis EEPROM.");
  }
}



void saveCoefficientToEEPROM(String id, Coeff value) {
  int index = -1;
  if (id == "P") index = 0;
  else if (id.startsWith("DG")) index = id.substring(2).toInt();
  else if (id.startsWith("DD")) index = id.substring(2).toInt() + 3;

  if (index >= 0 && index < COEFF_COUNT) {
    EEPROM.put(index * sizeof(Coeff), value);
    EEPROM.commit();  // Sauvegarde réelle
    Serial.println("Sauvegardé dans l'EEPROM pour " + id);
  }
}
