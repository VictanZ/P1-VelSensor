clear; close all; clc;

load(fullfile('resultados', 'P1_estadistica.mat'), 'T', 'Tabla_Estadisticas_manual', 'Tabla_Excesos', 'V_global', 'param');
addpath(genpath('lib'));

% Propagacion analitica
dt = T.dt_us * 1e-6;    %  tiempo de cada pasada en segundos
sigma_t = param.resol_micros * 1e-6; % resolucion del reloj pasada a segundos
sigma_d = sqrt(param.sep_desv ^ 2 + (param.resol_calibre / (2 * sqrt(3))) ^ 2);   % Incertidumbre de d con la dispersion de las medidas + la resolucion del calibre. Distrib tipo rectangular
er_d = sigma_d / param.sep_media;  % Error relativo de la dsitancia entre sensores
er_t = sigma_t ./ dt;   % Error relativo de el tiempo    vector, a cada elemento
er_v = sqrt(er_d^2 + er_t.^2);    % Error relativo total
T.sigma_v = er_v .* T.Vel_Teorica;  % Pasado a m/s por la velocidad de cada pasada
T.U_v = param.k_cobertura * T.sigma_v;   %Incertidumbre expandida  (k = 2 --> 95% confianza)

% Comparacion de propagacion de incertidumbre. Fórmula analítica vs diferencias finitas
[v1, s1, contrib] = propagar(@(p) p(1) ./ p(2), [param.sep_media, dt(1)], [sigma_d, sigma_t]);
fprintf("v: %.6f vs %.6f m/s\n", v1, T.Vel_Teorica(1));
fprintf("diferencia en sigma_v: %.2e m/s\n", s1 - T.sigma_v(1));
fprintf("contribución: d %.2f %%, dt %.3f %%\n", 100 * contrib);


% Monte Carlo: simular mcuhas veces d y dt con su error y ver cuanto varia v

rng(1); % semilla fija: sale siempre lo mismo
N = 1e5; % numero de simulaciones

idx_mc = zeros(1, 2);
[~, idx_mc(1)] = min(T.Vel_Teorica); % pasada mas lenta
[~, idx_mc(2)] = max(T.Vel_Teorica); % pasada mas rapida
etiquetas_mc = ["mas lenta", "mas rapida"];

mc = cell(1, 2); % estadistica de cada simulacion
v_sim = zeros(N, 2); % columna 1 = lenta, columna 2 = rapida

for j = 1:2
    ip = idx_mc(j); % fila de T de esta pasada
    d_sim = param.sep_media + sigma_d * randn(N, 1); % d con su incertidumbre (aprox. normal)
    dt_sim = dt(ip) + sigma_t * randn(N, 1); % dt con su incertidumbre
    v_sim(:, j) = d_sim ./ dt_sim; % ./ porque divide elemento a elemento
    mc{j} = estadisticaBasica(v_sim(:, j)); % reutilizo mi funcion

    fprintf("MC pasada %s: media = %.5f m/s, sigma = %.2e m/s\n", etiquetas_mc(j), mc{j}.media, mc{j}.sigma);
    fprintf("Analitica       : v     = %.5f m/s, sigma = %.2e m/s\n", T.Vel_Teorica(ip), T.sigma_v(ip));
    % con N = 1e5 el MC tiene un ruido de ~0.2 %, asi que ese orden de diferencia es normal
    fprintf("Diferencia relativa de sigma: %.2f %%\n\n", 100 * (mc{j}.sigma - T.sigma_v(ip)) / T.sigma_v(ip));
end
