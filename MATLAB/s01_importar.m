parametros_P1   % Trae el Struct de parametros (param.)

ficheros = dir(fullfile('datos', 'Registro_*.csv'));
resultados = table();

if isempty(ficheros)
    disp("Carpeta vacia")

else
    for k = 1:numel(ficheros)
        ruta = fullfile(ficheros(k).folder, ficheros(k).name);
        Tk = readtable(ruta);   %Guarda en tabla temporal
        Tk.ensayo = repmat(string(ficheros(k).name), height(Tk), 1);   %hace una columna más para el nombre del fichero al que corresponde, con repmat hace que se lo ponga a todas las fila
        resultados = [resultados; Tk];  % Añade las nuevas filas abajo del resto
    end
end

Filas_NaN = sum(any(ismissing(resultados), 2)); % Matriz con 1 donde habia NaN, devuelve columna con un 1 si habia un NaN y suma

resultados_filtrados = rmmissing(resultados); % Elimina las filas con NaN

Vel_Teorica = param.sep_media./(resultados_filtrados{:,"dt"}/1000000);
Diff_Vel = Vel_Teorica - resultados_filtrados{: , "velocidad"};
[Diff_Vel_Max, i_Diff_Vel_Max] = max(abs(Diff_Vel));
Diff_Vel_Max_Porcentaje = Diff_Vel_Max*100/ Vel_Teorica(i_Diff_Vel_Max);
Diff_Vel_Max;