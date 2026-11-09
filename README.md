# Medidor de Velocidad por Infrarrojos y Pipeline de Telemetría

Este proyecto parte de algo muy sencillo: medir la velocidad de giro con dos sensores infrarrojos y regular un motor por PWM con Arduino. La idea principal era complicarlo un poco para juntar varias herramientas en un mismo flujo de trabajo, usando **Fusion 360** para la parte mecánica, **C++** para el control del hardware, **Python** para la captura de datos y **MATLAB** para el análisis estadístico y de incertidumbre.

---

## Partes del proyecto

### 1. Diseño 3D y mecánica (Fusion 360)
* **Soporte compacto**: Estructura impresa en 3D donde van montados el Arduino, los dos sensores IR a distancia fija, la pantalla OLED, los botones y las guías del cableado.
* **Transmisión y correa en TPU**: El motor mueve el sistema mediante una reducción por poleas. La cinta que da vueltas está impresa en **TPU** con dentado tipo **GT2** para engancharse a los platos como una correa e incluye un pequeño saliente que corta el haz de los sensores en cada pasada.

### 2. Firmware y control (C++ / Arduino)
* **Captura de tiempos**: Medición del tiempo de paso entre sensores (`dt`) mediante interrupciones por hardware y programación no bloqueante con `millis()` y `micros()`.
* **Control e interfaz**: Regulación del motor en 5 niveles de PWM con dos pulsadores, avisos acústicos con un buzzer (cambio de nivel y exceso de velocidad) y visualización de datos en una pantalla OLED por I2C.
* **Telemetría**: Envío de los datos de cada vuelta por puerto serie mediante una trama en formato CSV (`pasada, dt, segundo, velocidad, nivel`).

### 3. Adquisición de datos y simulación (Python)
* **Lectura y registro (`main.py`)**: Recibe las tramas CSV desde el puerto serie, filtra posibles lecturas corruptas y las guarda en tiempo real en archivos numerados (`Registro_*.csv`).
* **Monitorización**: Grafica en vivo las últimas 10 vueltas con `matplotlib` y muestra por consola un resumen estadístico básico cada 10 pasadas válidas.
* **Simulador (`Simulacion_datos.py`)**: Emula el puerto serie generando tramas CSV sintéticas (con un $5\%$ de fallos intencionados) para poder probar los scripts sin tener la placa conectada.

### 4. Análisis estadístico e incertidumbre (MATLAB)
Se ejecuta de forma automatizada desde `run_P1.m` y procesa todos los ensayos guardados:
* **Limpieza y estadística descriptiva (`s01` y `s02`)**: Importa los CSV, descarta filas con `NaN`, recalcula la velocidad teórica y obtiene medias, desviaciones típicas, intervalos de confianza al $95\%$ y registros de exceso de velocidad por cada nivel de PWM.
* **Visualización (`s03`)**: Genera y exporta las gráficas de evolución por ensayo, histogramas, diagramas de caja (`boxplot`) y una regresión polinómica de la velocidad frente al PWM.
* **Incertidumbre y validación (`s04`)**: Se planteó a mano la propagación analítica de errores teniendo en cuenta la dispersión del calibre y la resolución temporal del Arduino. Para contrastar estos cálculos manuales, se añadieron con ayuda de IA dos métodos más avanzados: una función de propagación numérica por diferencias finitas y una simulación de Monte Carlo de $10^5$ iteraciones, verificando que el cálculo analítico y las simulaciones dan prácticamente el mismo resultado.

---

## Estructura de archivos

* `main.cpp`: Firmware del microcontrolador en C++.
* `main.py` / `Simulacion_datos.py` / `prueba.py`: Scripts de Python para captura por puerto serie, simulación de tramas y pruebas iniciales.
* `run_P1.m` y `parametros_P1.m`: Script principal que lanza el pipeline de MATLAB y archivo de constantes físicas/rutas.
* `s01_importar.m` / `s02_estadistica.m` / `s03_graficas.m` / `s04_incertidumbre.m`: Módulos de importación, estadística, gráficas e incertidumbre en MATLAB.

---

## Uso rápido

1. Ejecutar `main.py` con el Arduino conectado (o `Simulacion_datos.py` en modo virtual) para generar los archivos `Registro_*.csv`.
2. Colocar los CSV obtenidos en la carpeta `datos/` y ejecutar `run_P1.m` en MATLAB para generar automáticamente las tablas de resultados (`.mat`), el log de consola y todas las gráficas en `figuras/graficas_P1/`.