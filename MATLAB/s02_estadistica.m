clear; close all; clc;

parametros_P1;

load(fullfile(param.ruta_resultados, 'P1_datos.mat'), 'T', 'Filas_NaN');  %Aunque s01 devolvia param, lo he pasado aparte
addpath(genpath('lib')) ;


V_global = estadisticaBasica(T.Vel_Teorica);
fprintf("n = %.0f , media = %.4f, desv. tipica = %.4f, Coef. Variacion = %.4f %%, Error típico = %.4f, Intervalo de Confianza (95%%) = [%.4f, %.4f]", V_global.n, V_global.media, V_global.sigma, V_global.cv_pct, V_global.sem, V_global.ic95);
% Escribir dos veces % dentro de la cadena de texto para que no lo confunda con un valor
