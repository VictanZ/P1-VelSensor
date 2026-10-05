#include <Arduino.h>

constexpr uint8_t PIN_A = 4;
constexpr uint8_t PIN_B = 5;

void setup()
{
    Serial.begin(115200);
    pinMode(PIN_A, INPUT);
    pinMode(PIN_B, INPUT);
}

void loop()
{
    Serial.print(digitalRead(PIN_A));
    Serial.print(" ");
    Serial.println(digitalRead(PIN_B));
    delay(100);
}