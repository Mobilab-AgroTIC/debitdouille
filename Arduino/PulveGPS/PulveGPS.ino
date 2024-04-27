#include <Wire.h>
#include <TinyGPS++.h>

#define RXD2 16
#define TXD2 17

HardwareSerial neogps(1);

TinyGPSPlus gps;



void setup() {
  Serial.begin(115200);
  neogps.begin(9600, SERIAL_8N1, RXD2, TXD2);

}

void loop() {
   
  while (neogps.available())
  {
    gps.encode(neogps.read());
  }

  if (gps.location.isValid() == 1){
    Serial.print("Sats : ");
    Serial.println(gps.satellites.value());
    Serial.print("lon : ");
    Serial.println(gps.location.lng(),4);
    Serial.print("lat : ");
    Serial.println(gps.location.lat(),4);
    Serial.print("vitessse : ");
    Serial.println(gps.speed.kmph());
    Serial.print("Altitude : ");
    Serial.println(gps.altitude.meters(), 0);
  }else{
    Serial.println("Finding satellites");
  }

}
