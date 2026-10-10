param = struct();
param.sep_medidas_mm = [84.1 84 84 84 84.1]; % mm
param.sep_medidas_m = param.sep_medidas_mm / 1000; % m
param.sep_media = mean(param.sep_medidas_m);
param.sep_desv = std(param.sep_medidas_m);

param.resol_micros = 0.000004; % segundos = 4 microsegundos, es un dato del el arduino UNO
param.v_min = 0.2; % m/s
param.v_max = 2; % m/s

param.PWM = [0, 64 * 100/255, 128 * 100/255, 192 * 100/255, 100]; % Porcentaje de potencia
param.num_niveles = numel(param.PWM); % Numero de objetos, size devuelve 1 * 5

param.ruta_datos = fullfile('datos', 'Registro_*.csv');
param.ruta_figuras = fullfile('figuras');
param.ruta_resultados = fullfile('resultados');
