import numpy as np
import pandas as pd
import serial
import time
import os

PUERTO = 'COM3'
BAUDIOS = 115200


Carpeta_Destino = r"C:\Users\victa\Desktop\Proyectos\Carpetas Proyectos\Proyecto 1 - VelSensor\Datos.Telemetría"

lista_pasadas = np.array([])
lista_dt = np.array([])
lista_segundo = np.array([])
lista_ultimavel = np.array([])
lista_nivelmotor = np.array([])


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



def main():

    #Puerto serie
    #Bloque with para que se cierre automaticamente si hay un error o interrumpo
    with serial.Serial(PUERTO, BAUDIOS, timeout=1) as ser:   #Si en 1 segundo no lee nada continua con el programa, evita que se quede esperando. Se asgina la conexion a la variable ser
        print("Puerto abierto:", ser.name)

        time.sleep(2)               # El bootloader y setup() necesitan un par de segundos
        ser.reset_input_buffer()    # Descarta lo recibido durante el arranque
        ser.readline()              # Descarta primera linea cortada


        ruta_archivo_actual = crear_nuevo_archivo()    #Crea el arhcivo nuevo y me da la ruta
        archivo_actual = open(ruta_archivo_actual, "a")    # Abre el archivo en modo append
        archivo_actual.write("n.de pasada,dt,segundo,velocidad,nivelmotor\n") 


        while True:
            linea_cruda = ser.readline()
            if not linea_cruda:
                continue

            linea = linea_cruda.decode('utf-8', errors='ignore').strip()   #Pasa los bytes a texto

            Datos = parsear_trama(linea)

            if Datos:
                lista_pasadas.append(Datos[0])  
                lista_dt.append(Datos[1])
                lista_segundo.append(Datos[2])
                lista_ultimavel.append(Datos[3])
                lista_nivelmotor.append(Datos[4])

                texto_limpio = ",".join(map(str, Datos))     # Convierte todos los números a texto de golpe y los une con comas, sin corchetes:
                archivo_actual.write(f"{texto_limpio}\n")
                archivo_actual.flush()                  # Guarda los datos en disco inmediatamente, asi no me arriesgo a perderlos si se cierra
                #Al hacerlo con "Datos" en vez de "linea", ya me aseguro de que no esten corruptos, este todo y tal

                if Datos[1] == 20 and len(lista_pasadas) == 20:   # Doble comprobacion para asegurarme de que coinciden
                    print("20 lecturas disponibles, realizando analisis")

                    MediaVel = np.mean(lista_ultimavel)
                    DesviacionEstandarVel = np.std(lista_ultimavel)

                    conteos = np.bincount(lista_nivelmotor)
                    ModaNivelMotor = np.argmax(conteos)
                        #O import statistics as stat , moda = stat.mode(datos)


                    print(f"Velocidad media actual: {MediaVel:.4f}\n")
                    print(f"Desviacion estándar de la velocidad: {DesviacionEstandarVel:.4f}")
                    print(f"Nivel de motor más repetido: {ModaNivelMotor}")
                


            # ==============================================================================
            # ¿POR QUÉ USAR CSV.WRITER AQUÍ
            # 
            # Si tu función 'parsear_trama' te devuelve una lista de Python (por ejemplo: 
            # [1, 0.5, 12.4, 30.1, 2]), usar f"{Datos}" escribirá literalmente los corchetes 
            # y los espacios en tu documento:
            # "[1, 0.5, 12.4, 30.1, 2]"
            # 
            # Esto rompe el formato CSV. Cuando intentes abrir este archivo en MATLAB o Excel 
            # para analizar la dinámica del sistema, los corchetes ensuciarán los números y 
            # tendrás que limpiarlos de nuevo.
            # 
            # La herramienta csv.writer toma la lista de datos y la escribe eliminando los 
            # corchetes y usando solo las comas necesarias,
            #  Detecta las comas conflictivas y aísla el texto automáticamente ("Motor 1, fallo") para que permanezca en su columna correspondiente.
            # Permite crear los títulos de columna pasando una simple lista: writer.writerow(["Tiempo", "Velocidad", "Altitud"]):
            #
            #
            # CÓMO SERÍAN LAS LÍNEAS DE CÓDIGO PARA USARLO:
            #
            # 1   import csv         # <-- 1. Añade esto al principio del todo junto al resto de imports


            # 2. Abre el archivo con newline='' y crea el escritor CSV
            #            archivo_actual = open(ruta_archivo_actual, "a", newline='') 
            #           escritor_csv = csv.writer(archivo_actual)


            # 3.  Escribe la primera fila con los nombres de las columnas
            #            escritor_csv.writerow(["Pasadas", "dt_ms", "Tiempo_s", "Velocidad", "Nivel_Motor"])


            # 4.   if archivo_actual:
            #                   escritor_csv.writerow(Datos)     Escribe la lista limpia en el CSV
            # ==============================================================================
                




if __name__ == "__main__":
    main()        # Solo se lanza si el archivo se ejecuta directamente
