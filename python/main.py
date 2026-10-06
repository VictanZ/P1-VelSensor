import numpy as np
import pandas as pd
import serial
import time


lista_pasadas = []
lista_dt = []
lista_segundo = []
lista_ultimavel = []
lista_nivelmotor = []


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
    with serial.Serial("COM3", 115200, timeout=1) as ser:   #Si en 1 segundo no lee nada continua con el programa, evita que se quede esperando. Se asgina la conexion a la variable ser
        print("Puerto abierto:", ser.name)

        time.sleep(2)               # El bootloader y setup() necesitan un par de segundos
        ser.reset_input_buffer()    # Descarta lo recibido durante el arranque
        ser.readline()              # Descarta primera linea cortada

        while True:
            linea_cruda = ser.readline()
            if not linea_cruda:
                continue

            linea = linea_cruda.decode('utf-8', errors='ignore').strip()   #Pasa los bytesa texto

            Datos = parsear_trama(linea)

            if Datos:
                lista_pasadas.append(Datos[0])
                lista_dt.append(Datos[1])
                lista_segundo.append(Datos[2])
                lista_ultimavel.append(Datos[3])
                lista_nivelmotor.append(Datos[4])



if __name__ == "__main__":
    main()        # Solo se lanza si el archivo se ejecuta directamente
