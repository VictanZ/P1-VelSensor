function [f0, u_f, contrib] = propagar(fun, x, u_x)

% [f0, u_f, contrib] = propagarIncertidumbre(@(p) p(1)/p(2), [d dt], [u_d u_dt])
% fun : handle que recibe UN vector p con todas las entradas
% x, u_x : valores de las entradas y sus incertidumbres típicas
% f0 : valor de la función en x
% u_f : incertidumbre típica combinada del resultado
% contrib : fracción de la varianza (0..1) que aporta cada entrada
arguments
    fun (1, 1) function_handle
    x (1, :) double
    u_x (1, :) double {mustBeNonnegative}
end
assert(numel(x) == numel(u_x), "x y u_x deben tener el mismo tamaño");
f0 = fun(x); % Valor central.
c = zeros(size(x)); % Coeficientes de sensibilidad ∂f/∂xi.
for i = 1:numel(x)
    h = max(abs(x(i)) * 1e-6, 1e-12); % Paso pequeño RELATIVO al valor (y nunca 0).
    xp = x; xp(i) = x(i) + h; % x desplazado solo en la componente i...
    xm = x; xm(i) = x(i) - h; % ...hacia arriba y hacia abajo.
    c(i) = (fun(xp) - fun(xm)) / (2 * h); % Derivada CENTRADA: más precisa que la
end % de un solo lado.
termino = (c .* u_x) .^ 2; % Contribución de cada entrada a la varianza.
u_f = sqrt(sum(termino));
contrib = termino / sum(termino);
end
