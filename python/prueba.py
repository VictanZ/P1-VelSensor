import serial, numpy, pandas, matplotlib
print("Todo instalado")

import numpy as np
import pandas as pd
import serial
import time

def main():
    while True:
        linea_prueba = "8,100000,4.56,1.02,4"

        linea_depurada = linea_prueba.strip()
        linea_separada = linea_depurada.split(",")
        print(linea_separada)


        lista_ultimavel = np.array([1.23, 1.02, 0.998, 1.34, 0.943])
        lista_nivelmotor = np.array([3, 2, 2, 5, 1])

        MediaVel = np.mean(lista_ultimavel)
        DesviacionEstandarVel = np.std(lista_ultimavel)

        conteos = np.bincount(lista_nivelmotor)
        ModaNivelMotor = np.argmax(conteos)
            #O import statistics as stat , moda = stat.mode(datos)


        print(f"Velocidad media actual: {MediaVel:.4f}\n")
        print(f"Desviacion estándar de la velocidad: {DesviacionEstandarVel:.4f}")
        print(f"Nivel de motor más repetido: {ModaNivelMotor}")
                

        break

if __name__ == "__main__":
    main()        # Solo se lanza si el archivo se ejecuta directamente
