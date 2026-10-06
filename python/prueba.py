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
        break

if __name__ == "__main__":
    main()        # Solo se lanza si el archivo se ejecuta directamente
