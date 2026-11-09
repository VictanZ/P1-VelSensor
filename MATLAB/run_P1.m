% Ejecutar todo el analisis desde los CSV crudos
clear; close all; clc;
cd(fileparts(mfilename('fullpath'))); % mfilename('fullpath') = ruta de este archivo, fileparts se queda con la carpeta. Asi funciona aunque lo ejecute desde otro sitio
addpath(genpath('lib'));

parametros_P1; % creo param para usar sus rutas aqui

for carpeta = [string(param.ruta_resultados), string(fullfile(param.ruta_figuras, 'graficas_P1'))]
    if ~isfolder(carpeta), mkdir(carpeta); end
end


% Registro de la consola en un archivo
ruta_log = fullfile(param.ruta_resultados, 'log_P1.txt');
if isfile(ruta_log), delete(ruta_log); end % diary añade al final, asi que borro el anterior para empezar limpio
diary(ruta_log); diary on; % guarda en el archivo todo lo que salga por consola (cada script hace clc, y asi no se pierde)

tic; % cronometro interno. Sin guardarlo en variable, porque el clear de cada script la borraria. Me dirá el tiempo en ejecutar todo

try
    s01_importar; % CSV crudos -> P1_datos.mat
    s02_estadistica; % estadistica global y por nivel -> P1_estadistica.mat
    s03_graficas; % graficas -> figuras/graficas_P1
    s04_incertidumbre; % incertidumbre y Monte Carlo -> P1_incertidumbre.mat
catch ME % Error en algun script
    fprintf("\nFALLO en %s (linea %d): %s\n", ME.stack(1).name, ME.stack(1).line, ME.message);  %Archivo , linea y mensaje del error
    diary off; % cierro el registro antes de salir
    rethrow(ME); % relanzo el error para que se vea en rojo y no pase como si nada
end

fprintf("\nPipeline completo en %.1f s\n", toc); % toc = segundos desde el tic
diary off; % cierro el registro
