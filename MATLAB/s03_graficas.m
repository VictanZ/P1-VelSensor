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
    yline(max(T.Vel_Teorica(T.ensayo == ensayos(e))),'label', "Velocidad Maxima Registrada");
    yline(param.v_max,'label', "Límite de velocidad", 'Color', 'Red');
    title("Velocidad de cada pasada del ensayo " + ensayos((e)));
    xlabel("n pasada");
    ylabel("Velocidad (m/s)");
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
title("Velocidad de cada nivel");
xlabel("Pasada (Orden dentro del nivel)");
ylabel("Velocidad (m/s)");
legend(leyenda, 'Location', 'best');



PWM   = Tabla_Estadisticas_manual.PWM;
Media = Tabla_Estadisticas_manual.Media;

p = polyfit(PWM, Media, 2);
Ecuacion = sprintf("Ajuste: y = (%e)x^2 + (%.4f)x + (%.4f)", p(1), p(2), p(3));  % e pone el primer termino en notacion cientifica

x_curva = linspace(min(PWM),max(PWM), 100);
y_curva = polyval(p, x_curva);


y_ajuste = polyval(p, PWM);
SSres = sum((Media - y_ajuste).^2);          % lo que el modelo no explica
SStot = sum((Media - mean(Media)).^2);       % la variación total
R2 = 1 - SSres/SStot;

dist_inf = Media - Tabla_Estadisticas_manual.Intervalo_inf;
dist_sup = Tabla_Estadisticas_manual.Intervalo_sup - Media;


fig_vel_pwm = figure("Name", "Vel frente a el PWM usado");
errorbar(PWM, Media, dist_inf, dist_sup, 'ro', 'MarkerSize', 10, 'DisplayName', 'Media ± IC 95 %');
hold on;
plot(x_curva, y_curva, '-', 'DisplayName', Ecuacion);
title("Velocidad frente a PWM", sprintf("(R^2 = %.4f)", R2));
grid on;
xlabel("PWM (%)");
ylabel("Velocidad (m/s)");
legend('Location', 'best');
ylim([0 2]);

