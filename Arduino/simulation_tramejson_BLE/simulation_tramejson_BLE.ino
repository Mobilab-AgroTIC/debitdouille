#include <Arduino.h>
#include <ArduinoJson.h>
#include <EEPROM.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define EEPROM_SIZE 512
#define COEFF_COUNT 7 
#define EEPROM_TAG_ADDR 0
#define EEPROM_TAG_VALUE 1
#define EEPROM_COEFF_START 1

// UUID personnalisés pour BLE
#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890ab"
#define CHARACTERISTIC_UUID "abcdefab-1234-1234-1234-abcdefabcdef"

struct Coeff {
  float A;
  float B;
};

Coeff pression = {1.0, 0.0};
Coeff dg[3] = {{1.0, 0.0}, {1.0, 0.0}, {1.0, 0.0}};
Coeff dd[3] = {{1.0, 0.0}, {1.0, 0.0}, {1.0, 0.0}};


BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

void saveCoefficientToEEPROM(String id, Coeff value);

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("Client BLE connecté !");
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("Client BLE déconnecté !");
    delay(100);  // Petit délai pour laisser le système se stabiliser
    pServer->getAdvertising()->start();  // Redémarre l'advertising
    Serial.println("BLE advertising relancé !");
  }
};


class CoeffCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pChar) override {
    String value = String(pChar->getValue().c_str());
    Serial.println("Reçu BLE : " + value);

    if (value == "coeff") {
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
      pChar->setValue(jsonStr.c_str());
      pChar->notify();
      Serial.println("Trame coeff envoyée : " + jsonStr);
      return;
    }

    // Sinon, gestion d'une mise à jour de coefficient
    StaticJsonDocument<256> doc;
    DeserializationError err = deserializeJson(doc, value);
    if (err) {
      Serial.println("Erreur JSON reçu : " + String(err.c_str()));
      return;
    }

    if (doc["update"] != 1) return;
    String id = doc["id"];
    float A = doc["A"];
    float B = doc["B"];

    if (id == "P") {
      pression = {A, B};
    } else if (id.startsWith("DG")) {
      int i = id.substring(2).toInt() - 1;
      if (i >= 0 && i < 3) dg[i] = {A, B};
    } else if (id.startsWith("DD")) {
      int i = id.substring(2).toInt() - 1;
      if (i >= 0 && i < 3) dd[i] = {A, B};
    }
    saveCoefficientToEEPROM(id, {A, B});
    Serial.println("MAJ Coeff " + id + " A=" + String(A) + " B=" + String(B));
  }
};

void setup() {
  Serial.begin(115200);
  EEPROM.begin(EEPROM_SIZE);
  loadCoefficientsFromEEPROM();

  BLEDevice::init("debitdouille");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE
  );
  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new CoeffCallbacks());

  pService->start();
  pServer->getAdvertising()->start();
  Serial.println("BLE prêt !");
  randomSeed(analogRead(0));
}

void loop() {
  if (deviceConnected) {
    StaticJsonDocument<256> doc;

    float p = applyCoeff(randomFloat(1.0, 4.0, 2), pression);
    float v = randomFloat(3.0, 9.0, 1);
    doc["P"] = String(applyCoeff(randomFloat(1.0, 4.0, 2), pression), 2);
    doc["V"] = String(randomFloat(3.0, 9.0, 1), 2);
    
    for (int i = 0; i < 3; i++) {
      float g = applyCoeff(randomFloat(0.1, 3.0, 2), dg[i]);
      float d = applyCoeff(randomFloat(0.1, 3.0, 2), dd[i]);
      doc["DG" + String(i + 1)] = String(g, 2);
      doc["DD" + String(i + 1)] = String(d, 2);
    }


    String jsonStr;
    serializeJson(doc, jsonStr);
    pCharacteristic->setValue(jsonStr.c_str());
    pCharacteristic->notify();
    Serial.println("Trame envoyée : " + jsonStr);
  }

  delay(1000);
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
  byte tag = EEPROM.read(EEPROM_TAG_ADDR);
  if (tag != EEPROM_TAG_VALUE) {
    Serial.println("Première utilisation : initialisation des coefficients...");
    pression = {1.0, 0.0};
    for (int i = 0; i < 3; i++) {
      dg[i] = {1.0, 0.0};
      dd[i] = {1.0, 0.0};
    }
    EEPROM.put(EEPROM_COEFF_START, pression);
    for (int i = 0; i < 3; i++) {
      EEPROM.put(EEPROM_COEFF_START + sizeof(Coeff) * (i + 1), dg[i]);
      EEPROM.put(EEPROM_COEFF_START + sizeof(Coeff) * (i + 4), dd[i]);
    }
    EEPROM.write(EEPROM_TAG_ADDR, EEPROM_TAG_VALUE);
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
    EEPROM.commit();
    Serial.println("Sauvegardé EEPROM pour " + id);
  }
}
