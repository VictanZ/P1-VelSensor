clear; close all; clc;

load(fullfile('resultados', 'P1_estadistica.mat'), 'T', 'Tabla_Estadisticas_manual', 'Tabla_Excesos', 'V_global', 'param');
addpath(genpath('lib'));

% Propagacion analitica
dt = T.dt_us * 1e-6;    %  tiempo de cada pasada en segundos
sigma_d = sqrt(param.sep_desv ^ 2 + (param.resol_calibre / (2 * sqrt(3))) ^ 2);   % Incertidumbre de d con la dispersion de las medidas + la resolucion del calibre. Distrib tipo rectangular
er_d = sigma_d / param.sep_media;  % Error relativo de la dsitancia entre sensores
er_t = param.resol_micros ./ dt;   % Error relativo de el tiempo    vector, a cada elemento
er_v = sqrt(er_d^2 + er_t.^2);    % Error relativo total
T.sigma_v = er_v .* T.Vel_Teorica;  % Pasado a m/s por la velocidad de cada pasada
T.U_v = param.k_cobertura * T.sigma_v;   %Incertidumbre expandida  (k = 2 --> 95% confianza)