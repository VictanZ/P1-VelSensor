import numpy as np
import pandas as pd
import random  # <--- Añadido para generar datos aleatorios
import time
import os
from collections import deque
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

# Ya no necesitamos configurar PUERTO ni BAUDIOS reales
Carpeta_Destino = r"C:\Users\victa\Desktop\Proyectos\Carpetas Proyectos\Proyecto 1 - VelSensor\Datos.Telemetría"

lista_pasadas = []
lista_dt = []
lista_segundo = []
lista_ultimavel = []
lista_nivelmotor = []

def crear_nuevo_archivo():
    if not os.path.exists(Carpeta_Destino):   
        os.makedirs(Carpeta_Destino)

    contador = 1
    while True:
        nombre_archivo = f"Registro_{contador}.csv"
        ruta_completa = os.path.join(Carpeta_Destino, nombre_archivo)

        if not os.path.exists(ruta_completa):    
            return ruta_completa
        else: 
            contador += 1

def parsear_trama(linea: str):
    partes = linea.split(",")
    if len(partes) != 5:            
        return None
    try:
        return [
            int(partes[0]),             
            int(partes[1]),
            float(partes[2]),
            float(partes[3]),
            int(partes[4])
        ]
    except ValueError:
        print("Datos con tipo incorrecto")
        return None
    except Exception:
        return None

# --- SIMULADOR DE PUERTO SERIE ---
class SimuladorSerial:
    def __init__(self):
        self.name = "PUERTO_VIRTUAL_SIMULADO"
        self.numero_pasada = 0
        self.tiempo_acumulado = 0.0

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass

    def readline(self):
        # Simula el retraso del sensor real enviando datos (~100ms por lectura)
        time.sleep(0.8)
        
        # 5% de probabilidad de generar una trama corrupta o incompleta
        if random.random() < 0.05:
            return b"trama,corrupta,incompleta\n"
            
        self.numero_pasada += 1
        dt = random.randint(10, 50)  # dt simulado en ms
        self.tiempo_acumulado += dt / 1000.0  # segundos acumulados
        velocidad = random.uniform(0.6, 1.3)  # velocidad dentro del rango (0.6 a 1.3)
        nivel_motor = random.randint(1, 5)  # niveles de motor del 1 al 5
        
        # El simulador devuelve bytes terminados en nueva línea, igual que serial.Serial
        cadena_simulada = f"{self.numero_pasada},{dt},{self.tiempo_acumulado:.3f},{velocidad:.3f},{nivel_motor}\n"
        return cadena_simulada.encode('utf-8')

N = 10
ventana_pasadas = deque([0]*N, maxlen=N)
ventana_vel = deque([0.0]*N, maxlen=N)

plt.ion()                      
fig, ax = plt.subplots()
lineafig, = ax.plot(list(ventana_pasadas), list(ventana_vel), lw=1.3)
ax.set_ylim(0, 2)
ax.set_xlabel("Muestra")
ax.set_ylabel("Velocidad (m/s)")
ax.grid(alpha=0.3)

def main():
    ruta_archivo_actual = crear_nuevo_archivo()    
    
    # Cambiado serial.Serial por nuestro SimuladorSerial personalizado
    with SimuladorSerial() as ser, open(ruta_archivo_actual, "a") as archivo_actual:   
        print("Puerto abierto:", ser.name)
        archivo_actual.write("n.de pasada,dt,segundo,velocidad,nivelmotor\n") 

        time.sleep(2)               
        # Nota: Los métodos de limpieza de buffer del puerto real no hacen nada aquí,
        # pero los dejamos declarados para no alterar la estructura de tu código.

        Tramas_descartadas = 0
        Tramas_validas = 0
        n_datos = 0
        Datos_suficientes = False
        
        while True:
            linea_cruda = ser.readline()
            if not linea_cruda:
                continue

            linea = linea_cruda.decode('utf-8', errors='ignore').strip()   

            Datos = parsear_trama(linea)

            if Datos:
                Tramas_validas += 1
                n_datos += 1

                lista_pasadas.append(Datos[0])  
                lista_dt.append(Datos[1])
                lista_segundo.append(Datos[2])
                lista_ultimavel.append(Datos[3])
                lista_nivelmotor.append(Datos[4])

                texto_limpio = ",".join(map(str, Datos))     
                archivo_actual.write(f"{texto_limpio}\n")
                archivo_actual.flush()                  

                ventana_pasadas.append(Datos[0])  
                ventana_vel.append(Datos[3])
            
                lineafig.set_xdata(list(ventana_pasadas))
                lineafig.set_ydata(list(ventana_vel))
                
                x_min, x_max = ventana_pasadas[0], ventana_pasadas[-1]
                if x_min == x_max:
                    ax.set_xlim(x_min - 1, x_max + 1)
                else:
                    ax.set_xlim(x_min, x_max)
            
                plt.pause(0.001)        

                if n_datos == 10:
                    n_datos = 0
                    Datos_suficientes = True

                if Datos_suficientes:
                    Datos_suficientes = False

                    np_lista_ultimavel = np.array(lista_ultimavel)    
                    np_lista_nivelmotor = np.array(lista_nivelmotor) 
                    
                    MediaVel = np.mean(np_lista_ultimavel)
                    DesviacionEstandarVel = np.std(np_lista_ultimavel)

                    conteos = np.bincount(np_lista_nivelmotor)
                    ModaNivelMotor = np.argmax(conteos)

                    print(f"\nEstadistica tras {len(lista_pasadas)} pasadas")
                    print(f"Velocidad: {MediaVel:.2f} ± {DesviacionEstandarVel:.4f}")
                    print(f"Tramas validas: {Tramas_validas}, Tramas descartadas: {Tramas_descartadas}")
                    print(f"Nivel de motor más repetido: {ModaNivelMotor}")
                    
            else: 
                Tramas_descartadas += 1
                archivo_actual.write("Nan,Nan,Nan,Nan,Nan\n")
                archivo_actual.flush()

if __name__ == "__main__":
    main()