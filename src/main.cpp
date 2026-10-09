#include <Arduino.h>
#include <Wire.h>
#include <U8g2lib.h>
U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE);

// CONSTANTES

// Pines
constexpr uint8_t Pin_IR_A = 2;
constexpr uint8_t Pin_IR_B = 3;
constexpr uint8_t Pin_Motor = 9;
constexpr uint8_t Pin_Boton_Subir = 6;
constexpr uint8_t Pin_Boton_Bajar = 7;
constexpr uint8_t Pin_Buzzer = 8;
// Sensores
constexpr float d = 0.084f; // metros
// Motor
constexpr uint8_t Num_Niveles = 5;
constexpr uint8_t PWM_Niveles[Num_Niveles] = {0, 64, 128, 192, 255};
// Tiempo
constexpr uint32_t Rebote_IR = 50000UL;        // Microsegundos para sensor IR (50ms)
constexpr uint32_t Timeout_Pasada = 3000000UL; // (3s)

constexpr uint16_t Rebote_Botones = 40;        // Milisegundos
constexpr uint16_t Pulso_Simultaneo_min = 50;  // Diferencia entre pulso de cada boton para que cuente
constexpr uint16_t Pulso_Simultaneo_max = 500; // Tiempo minimo entre encendidos, para no ejecutar vrias veces al mantener

constexpr uint16_t Refresco_OLED = 150;

constexpr uint16_t Buzzer_Boton = 20;   // Al cambiar de nivel de potencia
constexpr uint16_t Buzzer_Exceso = 150; // Al detectar exceso de vel

constexpr uint16_t TiemposubidaNivel = 100;
constexpr uint16_t TiempobajadaNivel = 100;

// Velocidad
constexpr float Limite_Vel = 1.0f; // m/s
// Botones
bool Boton_1;
bool Boton_2;

bool Clic_1;
bool Clic_2;

// VARIABLES GLOBALES

// Estado de la medicion
uint8_t N_Pasadas = 0;
float UltimaVel = 0.0f;
float MaxVel = 0.0f;

// Estado del Sistema
bool Sistema_Encendido = false;
uint8_t Nivel_Motor_Actual = 0;
bool MedicionNueva = false;
uint8_t NivelAnterior = 0;
uint16_t DuracionBuzzerActual = 0;

// Temporizadores
uint32_t t_Actual_MS;

uint32_t UltimoCambioEstado = 0;
uint32_t t_Ultimo_Refresco_OLED = 0;
uint32_t t_Buzzer_endendido = 0;
bool Buzzer_Activo = false;

uint32_t Ultimocambioboton1 = 0;
uint32_t Ultimocambioboton2 = 0;

uint32_t ultimasubida = 0;
uint32_t ultimabajada = 0;

// Compartidas con las ISR: SIEMPRE volatile, SIEMPRE lectura atómica
volatile uint32_t tA = 0;
volatile uint32_t tB = 0;
volatile bool hayA = false, hayB = false;

// DECLARAR FUNCIONES
void isrSensorA();
void isrSensorB();
bool leerTiemposPasada(uint32_t &a, uint32_t &b);
void gestionarBotones();
void gestionarMotor();
void procesarMedicion();
void enviarTelemetria(uint32_t dt, float Segundo);
void actualizarOLED();
void gestionarBuzzer();

// SETUP

void setup()
{
  Serial.begin(115200);
  u8g2.begin();

  pinMode(Pin_IR_A, INPUT_PULLUP);
  pinMode(Pin_IR_B, INPUT_PULLUP);
  pinMode(Pin_Motor, OUTPUT);
  pinMode(Pin_Boton_Subir, INPUT_PULLUP);
  pinMode(Pin_Boton_Bajar, INPUT_PULLUP);
  pinMode(Pin_Buzzer, OUTPUT);

  attachInterrupt(digitalPinToInterrupt(Pin_IR_A), isrSensorA, FALLING);
  attachInterrupt(digitalPinToInterrupt(Pin_IR_B), isrSensorB, FALLING);
}

// LOOP

void loop()
{
  gestionarBotones(); // encendido/apagado del sistema + nivel de motor
  gestionarMotor();
  if (Sistema_Encendido)
  {
    procesarMedicion();
    actualizarOLED();
    gestionarBuzzer();
  }
}

// DEFINIR FUNCONES
void isrSensorA()
{
  uint32_t ahora = micros();
  if (ahora - tA > Rebote_IR)
  {
    tA = ahora;
    hayA = true;
  }
};

void isrSensorB()
{
  uint32_t ahora = micros();
  if (ahora - tB > Rebote_IR)
  {
    tB = ahora;
    hayB = true;
  }
};

bool leerTiemposPasada(uint32_t &a, uint32_t &b)
{

  noInterrupts(); // Para que tA no se reescriba mientras se lee (no pasa nada son microsegundos)
  a = tA;
  b = tB;
  interrupts();

  if (hayA && hayB)
  {

    hayA = false;
    hayB = false;

    return true;
  }
  else
  {

    if (hayA && micros() - a > Timeout_Pasada)
    {

      hayA = false;
    }

    if (hayB && micros() - b > Timeout_Pasada)
    {
      hayB = false;
    }
    return false;
  }
}

void gestionarBotones()
{
  Clic_1 = digitalRead(Pin_Boton_Subir); // Lectura cruda
  Clic_2 = digitalRead(Pin_Boton_Bajar);

  if (Clic_1 == false) // Hay clic
  {
    Boton_1 = false;
    Ultimocambioboton1 = millis();
  }
  if (Clic_1 == true && millis() - Ultimocambioboton1 > Rebote_Botones)
  {
    Boton_1 = true;
  }

  if (Clic_2 == false)
  {
    Boton_2 = false;
    Ultimocambioboton2 = millis();
  }
  if (Clic_2 == true && millis() - Ultimocambioboton2 > Rebote_Botones)
  {
    Boton_2 = true;
  }

  uint32_t intervalobotones; // Tiempo entre clics
  if (Ultimocambioboton1 > Ultimocambioboton2)
  {
    intervalobotones = Ultimocambioboton1 - Ultimocambioboton2;
  }
  else
  {
    intervalobotones = Ultimocambioboton2 - Ultimocambioboton1;
  }

  // Cambio encendido y apagado con clic simultaneo
  if (intervalobotones < Pulso_Simultaneo_min && millis() - t_Actual_MS > Pulso_Simultaneo_max)
  {
    Sistema_Encendido = !Sistema_Encendido;
    t_Actual_MS = millis();
  }
  else if (Sistema_Encendido)
  {
    if (Boton_1 == LOW && Nivel_Motor_Actual < 4 && millis() - ultimasubida > TiemposubidaNivel)
    {
      ultimasubida = millis();
      Nivel_Motor_Actual++;
    }
    else if (Boton_2 == LOW && Nivel_Motor_Actual > 0 && millis() - ultimabajada > TiempobajadaNivel)
    {
      ultimabajada = millis();
      Nivel_Motor_Actual--;
    }
  }
}

void gestionarMotor()
{
  if (Sistema_Encendido)
  {
    analogWrite(Pin_Motor, PWM_Niveles[Nivel_Motor_Actual]);
  }
  else
  {
    analogWrite(Pin_Motor, PWM_Niveles[0]);
  }
}

void procesarMedicion()
{
  uint32_t a;
  uint32_t b;
  if (leerTiemposPasada(a, b) && b > a)
  {
    uint32_t dt = (b - a);
    UltimaVel = d / (dt / 1000000.0); // Con a  y b no se reescribe a mitad de ejecucion por interrupt, /1000000 para pasar a segundos  --> m/s
    MedicionNueva = true;
    N_Pasadas++;
    float Segundo = millis() / 1000.0;
    if (UltimaVel > MaxVel)
    {
      MaxVel = UltimaVel;
    }
    enviarTelemetria(dt, Segundo);
  }
  else
  {
  }
}

void enviarTelemetria(uint32_t dt, float Segundo)
{
  Serial.print(N_Pasadas);
  Serial.print(",");
  Serial.print(dt);
  Serial.print(",");
  Serial.print(Segundo);
  Serial.print(",");
  Serial.print(UltimaVel);
  Serial.print(",");
  Serial.print(Nivel_Motor_Actual);
  Serial.println();
}

void actualizarOLED()
{
  if (millis() - t_Ultimo_Refresco_OLED > Refresco_OLED)
  {
    t_Ultimo_Refresco_OLED = millis();

    u8g2.clearBuffer();
    u8g2.setFont(u8g2_font_6x10_tf);

    u8g2.setCursor(2, 30);
    u8g2.print("Vel: ");
    u8g2.print(UltimaVel);
    u8g2.print(" m/s");

    u8g2.setCursor(2, 48);
    u8g2.print("Max: ");
    u8g2.print(MaxVel);
    u8g2.print(" m/s");

    u8g2.setCursor(80, 36);
    u8g2.print("Vuelta: ");

    u8g2.setCursor(80, 20);
    u8g2.print(N_Pasadas);

    u8g2.sendBuffer();
  }
}

void gestionarBuzzer()
{
  if (MedicionNueva)
  {
    MedicionNueva = false;
    if (UltimaVel > Limite_Vel && !Buzzer_Activo)
    {
      digitalWrite(Pin_Buzzer, HIGH);
      t_Buzzer_endendido = millis();
      Buzzer_Activo = true;
      DuracionBuzzerActual = Buzzer_Exceso;
    }
  }

  if (Nivel_Motor_Actual != NivelAnterior)
  {
    NivelAnterior = Nivel_Motor_Actual;
    if (!Buzzer_Activo)
    {

      digitalWrite(Pin_Buzzer, HIGH);
      t_Buzzer_endendido = millis();
      Buzzer_Activo = true;
      DuracionBuzzerActual = Buzzer_Boton;
    }
  }

  // Apagado comun para ambas cosas:
  if (Buzzer_Activo && millis() - t_Buzzer_endendido > DuracionBuzzerActual)
  {
    digitalWrite(Pin_Buzzer, LOW);
    Buzzer_Activo = false;
  }
}
