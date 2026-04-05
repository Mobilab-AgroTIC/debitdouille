// PlatformIO/Arduino IDE : installer "NimBLE-Arduino"
#include <NimBLEDevice.h>
#include <ArduinoJson.h>

static NimBLEServer* pServer;
static NimBLECharacteristic* pNotifyChar;

// Remplace par des UUIDs à toi (garde le format)
#define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
#define NOTIFY_CHAR_UUID    "12345678-1234-5678-1234-56789abcdef1"
#define WRITE_CHAR_UUID     "12345678-1234-5678-1234-56789abcdef2"

void setup() {
  Serial.begin(115200);

  NimBLEDevice::init("Debitdouille-ESP32"); // Nom visible en scan BLE
  NimBLEDevice::setPower(ESP_PWR_LVL_P9);   // Optionnel : puissance TX

  pServer = NimBLEDevice::createServer();

  auto service = pServer->createService(SERVICE_UUID);

  // Caractéristique NOTIFY (envoi trames JSON)
  pNotifyChar = service->createCharacteristic(
      NOTIFY_CHAR_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
  );

  // Caractéristique WRITE (réception commandes, ex: calibration)
  auto pWriteChar = service->createCharacteristic(
      WRITE_CHAR_UUID,
      NIMBLE_PROPERTY::WRITE
  );
  pWriteChar->setCallbacks(new struct : NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* c) override {
      std::string s = c->getValue();
      Serial.print("Reçu WRITE: ");
      Serial.println(s.c_str());
      // TODO: parser le JSON reçu côté ESP32 (coeff, etc.)
    }
  });

  service->start();

  // Advertising
  auto adv = NimBLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  adv->start();
  Serial.println("Advertising BLE démarré");
}

void loop() {
  // Exemple d’envoi d’une trame JSON toutes les 500 ms
  StaticJsonDocument<256> doc;
  doc["P"]   = 2.3;  // pression bar
  doc["DG1"] = 1.2;  doc["DG2"] = 1.3;  doc["DG3"] = 1.1;  doc["DG4"] = 1.0;
  doc["DD1"] = 1.0;  doc["DD2"] = 1.5;  doc["DD3"] = 1.4;  doc["DD4"] = 1.2;
  doc["V"]   = 8.7;  // km/h

  char buf[256];
  size_t n = serializeJson(doc, buf, sizeof(buf));

  pNotifyChar->setValue((uint8_t*)buf, n);
  pNotifyChar->notify();    // ← envoi vers l’appli (flutter_blue_plus)

  delay(500);
}
