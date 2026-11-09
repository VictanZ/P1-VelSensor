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



% Resumen por nivel y diferenciacion entre exceso de vel seguro o dudoso segun incertidumbre

niveles = unique(T.nivel);
matriz_inc = [];

for k = 1:numel(niveles)
    nv = niveles(k);
    fila = (Tabla_Estadisticas_manual.Nivel == nv); % fila de este nivel en la tabla de s02

    if ~any(fila)
        continue % nivel descartado en s02 (pocas muestras)
    end

    mascara = (T.nivel == nv);

    media = Tabla_Estadisticas_manual.Media(fila);
    s_rep = Tabla_Estadisticas_manual.Desv_tipica(fila); % dispersion entre pasadas (repetibilidad)
    u_instr = mean(T.sigma_v(mascara)); % incertidumbre media del instrumento
    er_d_pct = 100 * er_d; % es el mismo en todas las pasadas
    er_t_pct = 100 * mean(er_t(mascara));
    cociente = s_rep / u_instr; % cuantas veces mayor es la dispersion que el error del sensor

    nueva_fila = [nv, media, er_d_pct, er_t_pct, u_instr, s_rep, cociente];
    matriz_inc = [matriz_inc; nueva_fila];
end

Tabla_Incertidumbre = array2table(matriz_inc);
nombresInc = {'Nivel', 'Media', 'Er_d_pct', 'Er_t_pct', 'U_instrumento', 'Desv_repetibilidad', 'Cociente'};
Tabla_Incertidumbre.Properties.VariableNames = nombresInc;
disp(Tabla_Incertidumbre);

% Exceso de velocidad teniendo en cuenta la incertidumbre
exceso_seguro = (T.Vel_Teorica - T.U_v) > param.v_max; % supera el limite incluso restando U
exceso_dudoso = abs(T.Vel_Teorica - param.v_max) <= T.U_v; % esta pegada al limite, no se puede asegurar
T.exceso_seguro = exceso_seguro;
T.exceso_dudoso = exceso_dudoso;

fprintf("Pasadas con exceso nominal (v > limite): %.0f \n", sum(T.Vel_Teorica > param.v_max));
fprintf("  de ellas, exceso seguro: %.0f , dudoso: %.0f \n", sum(exceso_seguro), sum(exceso_dudoso));

if any(exceso_dudoso)
    disp(T(exceso_dudoso, {'ensayo', 'n_pasada', 'Vel_Teorica', 'U_v'}));
end






%Figuras

colores = lines(numel(niveles));
ruta_figuras = fullfile(param.ruta_figuras, 'graficas_P1');

if ~isfolder(ruta_figuras)
    mkdir(ruta_figuras);
end

% Figura 1: velocidad de cada pasada con su incertidumbre
fig_inc_pasadas = figure("Name", "Velocidad de cada pasada con incertidumbre");
hold on

for k = 1:numel(niveles)
    mascara = (T.nivel == niveles(k));
    x_pasada = find(mascara); % posicion global de cada pasada en T
    errorbar(x_pasada, T.Vel_Teorica(mascara), T.U_v(mascara), '.', 'Color', colores(k, :), 'MarkerFaceColor', colores(k, :), 'DisplayName', sprintf("Nivel %d", niveles(k)));
end

yline(param.v_max, 'r--', 'Límite de velocidad', 'HandleVisibility', 'off');
hold off;
title("Velocidad de cada pasada con su incertidumbre expandida (k = 2)", sprintf("Incertidumbre media: ± %.4f m/s (las barras casi no se ven a esta escala)", mean(T.U_v)));
xlabel("Nº de pasada (orden global)");
ylabel("Velocidad (m/s)");
legend('Location', 'best');
grid on;

% Figura 2: de donde viene la incertidumbre
fig_inc_contrib = figure("Name", "Contribuciones a la incertidumbre");
tl = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile; % panel izquierdo: distancia frente a tiempo
bar(Tabla_Incertidumbre.Nivel, [Tabla_Incertidumbre.Er_d_pct, Tabla_Incertidumbre.Er_t_pct]);
set(gca, 'YScale', 'log'); % escala log: si no, la barra del tiempo ni se veria
xlabel("Nivel");
ylabel("Error relativo (%)");
legend("Distancia (d)", "Tiempo (dt)", 'Location', 'best');
title("Que domina el error del sensor");
grid on;

nexttile; % panel derecho: error del sensor frente a dispersion entre pasadas
bar(Tabla_Incertidumbre.Nivel, [Tabla_Incertidumbre.U_instrumento, Tabla_Incertidumbre.Desv_repetibilidad]);
set(gca, 'YScale', 'log');
xlabel("Nivel");
ylabel("Velocidad (m/s)");
legend("Instrumento (sigma_v medio)", "Dispersion entre pasadas", 'Location', 'best');
title("Instrumento vs dispersion real");
grid on;

title(tl, "Origen de la incertidumbre");

% Figura 3: Monte Carlo frente a la formula analitica
fig_inc_mc = figure("Name", "Monte Carlo");
tl2 = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

for j = 1:2
    ip = idx_mc(j);
    nexttile;
    histogram(v_sim(:, j), 60, 'Normalization', 'pdf', 'DisplayName', 'Monte Carlo');
    hold on
    x_pdf = linspace(min(v_sim(:, j)), max(v_sim(:, j)), 200);
    plot(x_pdf, normpdf(x_pdf, T.Vel_Teorica(ip), T.sigma_v(ip)), 'r-', 'LineWidth', 1.5, 'DisplayName', 'Formula analitica');
    hold off;
    xlabel("Velocidad (m/s)");
    ylabel("Densidad de probabilidad");
    title(sprintf("Pasada %s: v = %.4f ± %.4f m/s", etiquetas_mc(j), T.Vel_Teorica(ip), T.sigma_v(ip)));
    legend('Location', 'best');
    grid on;
end

title(tl2, "Propagacion por Monte Carlo (N = 1e5)");

exportgraphics(fig_inc_pasadas, fullfile(ruta_figuras, "inc_errorbar_pasadas.png"), 'Resolution', 300);
exportgraphics(fig_inc_contrib, fullfile(ruta_figuras, "inc_contribuciones.png"), 'Resolution', 300);
exportgraphics(fig_inc_mc, fullfile(ruta_figuras, "inc_montecarlo.png"), 'Resolution', 300);



ruta_salida = fullfile(param.ruta_resultados, 'P1_incertidumbre.mat');
save(ruta_salida, 'T', 'Tabla_Incertidumbre', 'mc', 'idx_mc', 'sigma_d', 'param')
