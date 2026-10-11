clear; close all; clc;

parametros_P1;

load(fullfile(param.ruta_resultados, 'P1_datos.mat'), 'T', 'Filas_NaN');  %Aunque s01 devolvia param, lo he pasado aparte
addpath(genpath('lib')) ;


