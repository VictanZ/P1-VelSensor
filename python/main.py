import numpy as np
import serial
import time
import os
from collections import deque
import matplotlib.pyplot as plt


PUERTO = "COM3"
BAUDIOS = 115200


Carpeta_Destino = r"C:\Users\victa\Desktop\Proyectos\Carpetas Proyectos\Proyecto 1 - VelSensor\Datos.Telemetría"

lista_pasadas = []
lista_dt = []
lista_segundo = []
lista_ultimavel = []
lista_nivelmotor = []



def crear_nuevo_archivo():

    if not os.path.exists(Carpeta_Destino):   #Verifica si existe la carpeta, si no la crea
        os.makedirs(Carpeta_Destino)

    contador = 1
    while True:
        nombre_archivo = f"Registro_{contador}.csv"
        ruta_completa = os.path.join(Carpeta_Destino, nombre_archivo)

        if not os.path.exists(ruta_completa):    # Si este archivo no existe lo devuelve para usarlo en la nueva toma de datos
            return ruta_completa
        
        else: contador += 1


def parsear_trama(linea: str):
    partes = linea.split(",")
    if len(partes) != 5:            # Descarta linea incompleta
        return None
    try:
        return [
            int(partes[0]),             # Hay que pasar los textos a valroes int y float para hacer la estadistica mas adelante
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

N = 10
ventana_pasadas = deque([0]*N, maxlen=N)
ventana_vel = deque([0.0]*N, maxlen=N)

plt.ion()                      # permite refrescar sin bloquear el bucle
fig, ax = plt.subplots()
lineafig, = ax.plot(list(ventana_pasadas), list(ventana_vel), lw=1.3)
ax.set_ylim(0, 2)
ax.set_xlabel("Muestra"); ax.set_ylabel("Velocidad (m/s)")
ax.grid(alpha=0.3)


def main():



    ruta_archivo_actual = crear_nuevo_archivo()    #Crea el arhcivo nuevo y me da la ruta
    #Puerto serie
    #Bloque with para que se cierre automaticamente si hay un error o interrumpo
    with serial.Serial(PUERTO, BAUDIOS, timeout=1) as ser, open(ruta_archivo_actual, "a") as archivo_actual:   #Si en 1 segundo no lee nada continua con el programa, evita que se quede esperando. Se asgina la conexion a la variable ser
        print("Puerto abierto:", ser.name)
        archivo_actual.write("n.de pasada,dt,segundo,velocidad,nivelmotor\n") 

        time.sleep(2)               # El bootloader y setup() necesitan un par de segundos
        ser.reset_input_buffer()    # Descarta lo recibido durante el arranque
        ser.readline()              # Descarta primera linea cortada

        Tramas_descartadas = 0
        Tramas_validas = 0
        n_datos = 0
        Datos_suficientes = False
        



        while True:
            linea_cruda = ser.readline()
            if not linea_cruda:
                plt.pause(0.01)
                continue

            linea = linea_cruda.decode('utf-8', errors='ignore').strip()   #Pasa los bytes a texto

            Datos = parsear_trama(linea)

            if Datos:

                Tramas_validas += 1
                n_datos += 1

                lista_pasadas.append(Datos[0])  
                lista_dt.append(Datos[1])
                lista_segundo.append(Datos[2])
                lista_ultimavel.append(Datos[3])
                lista_nivelmotor.append(Datos[4])

                texto_limpio = ",".join(map(str, Datos))     # Convierte todos los números a texto de golpe y los une con comas, sin corchetes:
                archivo_actual.write(f"{texto_limpio}\n")
                archivo_actual.flush()                  # Guarda los datos en disco inmediatamente, asi no me arriesgo a perderlos si se cierra
                #Al hacerlo con "Datos" en vez de "linea", ya me aseguro de que no esten corruptos, este todo y tal


                ventana_pasadas.append(Datos[0])  #Para pintar en la grafica y que salgan los num correctos
                ventana_vel.append(Datos[3])
            
                lineafig.set_xdata(ventana_pasadas)
                lineafig.set_ydata(ventana_vel)
                ax.set_xlim(ventana_pasadas[0], ventana_pasadas[-1])   #volver a poner los limites del recuadr, si no las nuevas pasadas saldrian por la derechafuera de vision)
            
                fig.canvas.draw()           # Dibuja los nuevos datos en la pantalla
                fig.canvas.flush_events()   # Procesa los eventos de la ventana para que no se cuelgue




                if n_datos == 10:
                    n_datos = 0

                    np_lista_ultimavel = np.array(lista_ultimavel)    #Paso a array de np, no puedo declararlo al inciio asi porque no funcionaria appen, habria que hacerlo de otra forma mas lenta
                    np_lista_nivelmotor = np.array(lista_nivelmotor) 
                    
                    MediaVel = np.mean(np_lista_ultimavel)
                    DesviacionEstandarVel = np.std(np_lista_ultimavel, ddof=1)    # Divide entre n-1 en vez de n (desviacion muestral)

                    conteos = np.bincount(np_lista_nivelmotor)
                    ModaNivelMotor = np.argmax(conteos)
                        #O import statistics as stat , moda = stat.mode(datos)

                    print(f"Estadistica tras {len(lista_pasadas)} pasadas")
                    print(f"Velocidad: {MediaVel:.2f} ± {DesviacionEstandarVel:.4f}\n")
                    print(f"Tramas validas: {Tramas_validas}, Tramas descartadas: {Tramas_descartadas}")
                    print(f"Nivel de motor más repetido: {ModaNivelMotor}")
                    
            else: 
                Tramas_descartadas += 1
                archivo_actual.write("Nan,Nan,Nan,Nan,Nan\n")
                archivo_actual.flush() 








if __name__ == "__main__":
    main()        # Solo se lanza si el archivo se ejecuta directamente
