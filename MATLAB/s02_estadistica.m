clear; close all; clc;

parametros_P1;

load(fullfile(param.ruta_resultados, 'P1_datos.mat'), 'T', 'Filas_NaN');  %Aunque s01 devolvia param, lo he pasado aparte
addpath(genpath('lib')) ;


V_global = estadisticaBasica(T.Vel_Teorica);
fprintf("Estadsitica global:\n Muestras = %.0f , Media = %.4f, desv. tipica = %.4f, Coef. Variacion = %.4f %%, Error típico = %.4f, Intervalo de Confianza (95%%) = [%.4f, %.4f] \n\n", V_global.n, V_global.media, V_global.sigma, V_global.cv_pct, V_global.sem, V_global.ic95);
% Escribir dos veces % dentro de la cadena de texto para que no lo confunda con un valor

%Clasificacion por niveles

niveles = unique(T.nivel);   % 0 1 2 3 4 (datos arduino)  o 1 2 3 4 5  (simulacion python)
min_nivel = min(niveles); 
V_nivel = {};

matriz_datos = []; 

for k = 1:numel(niveles)    % 1:5
    nv = niveles(k);
    % T.nivel == nv;  % Da columna de verdadero y falso
    if sum(T.nivel == nv) < 2
        fprintf("Datos insuficientes para el nivel %.0f \n", nv)
    else
        % Índice dinámico: 
        % Si nv = 0 y min = 0 -> idx = 1
        % Si nv = 1 y min = 1 -> idx = 1
        idx = nv - min_nivel + 1;   % El primer indice siempre es 1, indep de si los niveles empiezan en 0 o 1

        V_nivel{idx} = estadisticaBasica(T.Vel_Teorica(T.nivel == nv));
        fprintf("Estadistica para el nivel %.0f: Muestras: %.0f, Media = %.4f, desv. tipica = %.4f, Coef. Variacion = %.4f %%, Error típico = %.4f, Intervalo de Confianza (95%%) = [%.4f, %.4f] \n\n", nv, V_nivel{idx}.n, V_nivel{idx}.media, V_nivel{idx}.sigma, V_nivel{idx}.cv_pct, V_nivel{idx}.sem, V_nivel{idx}.ic95);

        nueva_fila = [nv, param.PWM(nv + (min_nivel == 0)), V_nivel{idx}.n, V_nivel{idx}.media, V_nivel{idx}.sigma, V_nivel{idx}.cv_pct, V_nivel{idx}.sem, V_nivel{idx}.ic95(1), V_nivel{idx}.ic95(2)];  
        matriz_datos = [matriz_datos; nueva_fila];   % Añade la nueva fila bajo el resto de la matriz
    end
end

Tabla_Estadisticas_manual = array2table(matriz_datos);  % Si uso solo table(matriz_datos) genera todo en una sola columna

nombresColumnas = {'Nivel', 'PWM', 'Muestras', 'Media', 'Desv_tipica', 'Coef_Var', 'Error_Tipico', 'Intervalo_Confianza(lim_inferior)', 'Intervalo_Confianza(lim_superior)'};
Tabla_Estadisticas_manual.Properties.VariableNames = nombresColumnas; 

disp(Tabla_Estadisticas_manual);

% OTRA FORMA, sirve como comprobacion: 
Tabla_Estadisticas_automatica = groupsummary(T, 'nivel', {'mean','std'}, 'Vel_Teorica'); % T = tabla de datos, nivel = clasificacion, mean y std = valores a calcualr, Vel_Teorica = Datos sobre lso que relalizar
disp(Tabla_Estadisticas_automatica);

