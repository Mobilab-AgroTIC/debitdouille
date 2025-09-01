#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

void setup() {
  BLEDevice::init("debitdouille");
  BLEServer *pServer = BLEDevice::createServer();

  BLEService *pService = pServer->createService("12345678-1234-1234-1234-1234567890ab");
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
    "abcd1234-1234-1234-1234-abcdefabcdef",
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );

  pCharacteristic->setValue("Hello depuis l'ESP32 !");
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();
  Serial.println("BLE lancé");
}

void loop() {
  // tu peux notifier ici si besoin
}
