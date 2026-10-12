clear; close all; clc;

load(fullfile('resultados', 'P1_estadistica.mat'), 'T', 'Tabla_Estadisticas_manual', 'Tabla_Excesos', 'V_global', 'param')

ruta_figuras = fullfile("figuras", "graficas_P1");
if ~isfolder(ruta_figuras)
    mkdir(ruta_figuras);
end

ensayos = unique(T.ensayo);
niveles = unique(T.nivel);
colores = lines(numel(niveles));
for e = 1:numel(ensayos)
    fig_vel_pasada(e) = figure("Name", "Velocidad de cada pasada del ensayo" + ensayos(e));
    plot(T.n_pasada(T.ensayo == ensayos(e)),  T.Vel_Teorica(T.ensayo == ensayos(e)), 'black-', 'HandleVisibility', 'off')   %Linea negra que une todos los puntos en orden (lo primero para que quede debajo)
    hold on;
    for k = 1:numel(niveles)
        leyenda{k} = sprintf("Pasadas Nivel %d", niveles(k));
        mascara = (T.nivel == niveles(k)) & (T.ensayo == ensayos(e));
        plot(T.n_pasada(mascara), T.Vel_Teorica(mascara), '.', 'Color', colores(k,:), 'MarkerSize', 15);
        ylim([0 2]);
    end
    xlabel("n pasada");
    ylabel("Velocidad");
    hold off;
    legend(leyenda, 'Location', 'best');
end



fig_vel_nivel = figure("Name", "Velocidad de cada nivel");
hold on
ylim([0 2])
for k = 1:numel(niveles)   % de 1 a 5
    leyenda{k} = sprintf("Pasadas Nivel %d", niveles(k));
    plot(T.Vel_Teorica(T.nivel == niveles(k)), '.-', 'Color', colores(k,:), 'MarkerSize', 15);
end
hold off
xlabel("Pasada (Orden dentro del nivel)");
ylabel("velocidad");
legend(leyenda, 'Location', 'best');
