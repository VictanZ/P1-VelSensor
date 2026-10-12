clear; close all; clc;

load(fullfile(param.ruta_resultados), 'T', 'Tabla_Estadisticas_manual', 'Tabla_Excesos', 'V_global', 'param')

ruta_figuras = fullfile("figuras", "graficas_P1")
if ~isfolder(ruta_figuras)
    mkdir(ruta_figuras);
end

