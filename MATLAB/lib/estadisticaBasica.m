function s = estadisticaBasica(v);
    arguments   % Comprobar la entrada (da error si no es correcta)
        v (:,1) double {mustBeFinite}
    end

    if numel(v) < 2
        error("estadisticaBasica: Datos insuficientes", 'Se necesitan al menos 2 datos (llegaron %d)', numel(v));
    end

    s = struct();

    s.n = numel(v);
    s.media = mean(v);
    s.sigma = std(v);   % Desviacion tipica muestral (divide por n-1)  dispersión de una medida individual
    s.cv_pct = 100 *s.sigma / s.media;        % Coef variacion σ/µ en porcentaje
    s.sem = s.sigma/sqrt(s.n);    % error típico (standard error of the mean), σ/√n  Precisión con la que se conoce la media
    t95 = tinv(0.975, s.n - 1);       % t de Student (necesita la toolbox)
    s.ic95   = s.media + t95 * s.sem * [-1 1]; 
    % s.ic95 = s.media + 1.96*s.sem*[-1 1];   % aproximacion para n > 30 (al 95%), para no tener que instalar toolbox. Devuelve dos valores el limite inferior y superior
end