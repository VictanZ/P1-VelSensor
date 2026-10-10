parametros_P1   % Trae el Struct de parametros (param.)

ficheros = dir(fullfile('datos', 'Registro_*.csv'));

if isempty(ficheros)
    error('s01:sinFicheros', 'No hay ficheros que coincidan con %s', param.ruta_datos);
end

nombresColumnas = {'n_pasada', 'dt_us', 't_s', 'v_fw_mps', 'nivel'};
resultados = table();

for k = 1:numel(ficheros)
    ruta = fullfile(ficheros(k).folder, ficheros(k).name);
    Tk = readtable(ruta);   %Guarda en tabla temporal
    Tk.Properties.VariableNames = nombresColumnas; 
    Tk.ensayo = repmat(string(ficheros(k).name), height(Tk), 1);   %hace una columna más para el nombre del fichero al que corresponde, con repmat hace que se lo ponga a todas las fila
    resultados = [resultados; Tk];  % Añade las nuevas filas abajo del resto
end

Filas_NaN = sum(any(ismissing(resultados), 2)); % Matriz con 1 donde habia NaN, devuelve columna con un 1 si habia un NaN y suma

T = rmmissing(resultados); % Elimina las filas con NaN

T.Vel_Teorica = param.sep_media./(T.dt_us/1000000);


dif_v = T.Vel_Teorica - T.v_fw_mps;
[dif_max, i_max] = max(abs(dif_v));
dif_max_pct = 100 * dif_max / T.Vel_Teorica(i_max);

fprintf('Ficheros leidos : %d\n', numel(ficheros));
fprintf('Filas leidas    : %d\n', height(resultados));
fprintf('Filas con Nan   : %d\n', Filas_NaN);
fprintf('Pasadas validas : %d\n\n', height(T));



fprintf('Diferencia maxima firmware vs recalculada: %.4f m/s (%.2f %%)\n\n', dif_max, dif_max_pct);

fprintf('Velocidad del firmware (comparar con Python):\n');
fprintf('  media = %.4f   sigma = %.4f   max = %.4f   min = %.4f  (m/s)\n',mean(T.v_fw_mps), std(T.v_fw_mps), max(T.v_fw_mps), min(T.v_fw_mps));


ruta_salida = fullfile(param.ruta_resultados, 'P1_datos.mat');
save(ruta_salida, 'T', 'Filas_NaN', 'param');
fprintf('\nGuardado en %s\n', ruta_salida);