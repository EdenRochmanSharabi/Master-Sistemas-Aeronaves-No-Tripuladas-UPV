clc; clear all; close all;

Vh = 19;
Vv = 0;

rho = 1.225;
m = 25;
g = 9.81; % Gravity constant [m/s^2]
nprop = 4;
Rprop = 0.15;
Sprop = pi * Rprop^2;
vi0 = sqrt((m * g / nprop) / (2 * rho * Sprop)); % Induced speed at hovering considering that each rotor holds mg/nprop

% Induced velocity calculation
if Vh == 0
    if Vv / vi0 > 0 % Ascenso a velocidad constante
        vi = vi0 * ((-Vv / vi0 + sqrt((Vv / vi0)^2 + 4))/2);
    elseif Vv / vi0 < -2 % Molinete frenante
        vi =  vi0 * ((-Vv / vi0 - sqrt((Vv / vi0)^2 - 4))/2);
    else % Condición para bajo Vv/Vh
        vi = 1.15 - 1.125 * (Vv / vi0) - 1.372 * (Vv / vi0)^2 ...
            - 1.718 * (Vv / vi0)^3 - 0.655 * (Vv / vi0)^4;
    end
else % Vuelo horizontal/ascendente
    error = 10;
    vi_v = [0,10,50,100];
    for i = 1:length(vi_v)
        error_v(i) = vi_v(i) / vi0 * sqrt((Vh / vi0)^2 + (Vv / vi0 + vi_v(i) / vi0)^2) - 1;
    end

    while abs(error) > 0.001
        vi = interp1(error_v,vi_v,0);
        error = vi / vi0 * sqrt((Vh / vi0)^2 + (Vv / vi0 + vi / vi0)^2) - 1;
        vi_v = [vi_v,vi];
        error_v = [error_v,error];
    end
end