clc; clear; close all;

%% General mission data
PL = 5; % Payload in kg
R_m = 10 * 1000; % Mission radius [m]
Vh_max = 19; % Maximum horizontal cruise speed [m/s]
Vv_max = 5; % Maximum vertical speed [m/s]
Vv_min = -3; % Minimum vertial speed [m/s]
fuselageFineness = 1;
h0 = 0; % Initial height [m]
hc = 120; % Cruise height [m]
Dmax = 0.4; % Maximum propeller diameter [m]
nprop = 4; % Number of rotors

PropulsionSystem = 2; % Variable to choose the propulsion system (1=FC/2=Batt)

%% Definition of the velocities per phase of flight

% Take-off
Vh_TO = 0; % Horizontal speed [m/s]
Vv_TO = Vv_max; % Vertical speed [m/s]

% Cruise
Vh_c = Vh_max; % Horizontal speed [m/s]
Vv_c = 0; % Vertical speed [m/s]

% Landing
Vh_l = 0; % Horizontal speed [m/s]
Vv_l = Vv_min; % Vertical speed [m/s]

%% Data required for the force equilibrium
MTOM = PL / 0.2; % Vehicle mass [kg]
dVhdt = 0; % Horizontal acceleration [m/s^2]
dVvdt = 0; % Vertical acceleration [m/s^2]

c.gamma = 1.4; % Specific heat constant of air
c.R = 287; % Ideal gas constant for air [J/kg K]
c.T = 25 + 273.15; % Air temperature [K]
c.p = 101325; % Atmospheric pressure [Pa]
c.rho = c.p / (c.R * c.T); % Air density [kg/m^3]
c.mu = 1.837e-5; % Air dynamic viscosity at 25ºC [Pa s]
c.M_ref = 6.14; % kg dji M200 v2
c.S_ref = 0.174724; % m^2
c.FF = 1 + (60 / fuselageFineness^3) + (fuselageFineness / 400); % Fuselage form factor [-]

%% Flat-plate approximation: drag per phase of flight
% (dragPlate: Stop empirica, cubo, Cf de placa plana, ver funciones al final)
V_TO = hypot(Vv_TO, Vh_TO);
V_c = hypot(Vv_c, Vh_c);
V_l = hypot(Vv_l, Vh_l);
D_TO = dragPlate(V_TO, MTOM, c);
D_c = dragPlate(V_c, MTOM, c);
D_l = dragPlate(V_l, MTOM, c);

%% Theta and thrust calculation (balance de fuerzas)

m = MTOM; % Mass towards destination [kg]
[T_TO_go, theta_TO_go] = balance(m, Vh_TO, Vv_TO, dVhdt, dVvdt, D_TO);
[T_c_go, theta_c_go] = balance(m, Vh_c, Vv_c, dVhdt, dVvdt, D_c);
[T_l_go, theta_l_go] = balance(m, Vh_l, Vv_l, dVhdt, dVvdt, D_l);

m = MTOM - PL; % Mass back from destination [kg]
% La resistencia depende de MTOM (superficie), no de la masa instantanea
[T_TO_back, theta_TO_back] = balance(m, Vh_TO, Vv_TO, dVhdt, dVvdt, D_TO);
[T_c_back, theta_c_back] = balance(m, Vh_c, Vv_c, dVhdt, dVvdt, D_c);
[T_l_back, theta_l_back] = balance(m, Vh_l, Vv_l, dVhdt, dVvdt, D_l);

fprintf('\n=== Equilibrio de fuerzas (MTOM = %.1f kg) ===\n', MTOM);
fprintf('%-12s %8s %10s %8s %10s\n', 'Fase', 'T_ida[N]', 'theta_ida', 'T_vta[N]', 'theta_vta');
fprintf('%-12s %8.1f %9.2f° %8.1f %9.2f°\n', 'Despegue', T_TO_go, theta_TO_go, T_TO_back, theta_TO_back);
fprintf('%-12s %8.1f %9.2f° %8.1f %9.2f°\n', 'Crucero', T_c_go, theta_c_go, T_c_back, theta_c_back);
fprintf('%-12s %8.1f %9.2f° %8.1f %9.2f°\n', 'Aterrizaje', T_l_go, theta_l_go, T_l_back, theta_l_back);
fprintf('Resistencia: D_TO = %.1f N, D_c = %.1f N, D_l = %.1f N\n', D_TO, D_c, D_l);

%% Estudio de sensibilidad frente a la MTOM (apartado 2)
% Fuselaje fijo (el de MTOM = 25 kg): la resistencia D_TO, D_c, D_l no cambia, solo cambia la masa
MTOMv = 5:5:35;
Ts = zeros(3, numel(MTOMv)); ths = Ts;
for k = 1:numel(MTOMv)
    Mk = MTOMv(k);
    [Ts(1,k), ths(1,k)] = balance(Mk, Vh_TO, Vv_TO, dVhdt, dVvdt, D_TO);
    [Ts(2,k), ths(2,k)] = balance(Mk, Vh_c, Vv_c, dVhdt, dVvdt, D_c);
    [Ts(3,k), ths(3,k)] = balance(Mk, Vh_l, Vv_l, dVhdt, dVvdt, D_l);
end
% Figura con el formato de la plantilla: empuje (izq.) y theta en rad (dcha.)
f1 = figure('Position', [100 100 900 520]);
col = lines(4);
yyaxis left; hold on;
plot(MTOMv, Ts(1,:), '-o', 'Color', col(1,:), 'LineWidth', 1.5);
plot(MTOMv, Ts(2,:), '-o', 'Color', col(2,:), 'LineWidth', 1.5);
plot(MTOMv, Ts(3,:), '-o', 'Color', col(3,:), 'LineWidth', 1.5);
ylabel('Empuje [N]'); ax = gca; ax.YAxis(1).Color = 'k';
yyaxis right;
plot(MTOMv, deg2rad(ths(2,:)), '-o', 'Color', col(4,:), 'LineWidth', 1.5);
ylabel('Ángulo de inclinación [rad]'); ax.YAxis(2).Color = 'k';
grid on; xlabel('MTOM [kg]'); title('Equilibrio de fuerzas');
legend({'T_{to} (despegue)', 'T (crucero)', 'T_{l} (aterrizaje)', '\theta (crucero; 0 en despegue y aterrizaje)'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
exportgraphics(f1, 'fig_sensibilidad_MTOM.png', 'Resolution', 200);

%% Selección de propeller (versión con archivos .mat promediados)
% Se evalua en crucero (ida, caso de mayor empuje). Empuje por helice = T/nprop.
% J = Vh/(n D) con Vh = velocidad de crucero.
folderMat = 'DatabaseProp';
Tprop = T_c_go / nprop; % Empuje requerido por helice [N]
V = Vh_c;

matFiles = dir(fullfile(folderMat, '*.mat'));
if isempty(matFiles)
    error('No se encontraron archivos .mat en: %s', folderMat);
end

res = repmat(struct('name', '', 'D', NaN, 'n', NaN, 'J', NaN, 'CT', NaN, 'eta', NaN, 'ok', false), numel(matFiles), 1);
for i = 1:numel(matFiles)
    file_path = fullfile(matFiles(i).folder, matFiles(i).name);
    res(i) = evalProp(file_path, Tprop, V, c.rho);
    res(i).name = erase(matFiles(i).name, '.mat');
end

% Helices validas: alcanzan el empuje dentro del rango ensayado y D <= Dmax
valid = [res.ok] & [res.D] <= Dmax;
if ~any(valid), error('Ninguna helice valida (D <= Dmax y alcanza el empuje requerido)'); end
score = nan(numel(res), 1); score(valid) = [res(valid).eta];
[~, idx] = max(score);
fprintf('\n=== Seleccion sobre toda la base de datos (D <= %.2f m) ===\n', Dmax);
fprintf('%d de %d helices alcanzan T = %.1f N/rotor con D <= Dmax. Mejor: %s (D=%.4f m, n=%.1f rps, J=%.3f, eta=%.3f)\n', ...
    nnz(valid), numel(res), Tprop, res(idx).name, res(idx).D, res(idx).n, res(idx).J, res(idx).eta);

%% Las 3 helices del enunciado
names3 = {'apce_16x8_avg', 'PER3_9x9_avg', 'gwsdd_11x7_avg'};
fprintf('\n=== Helices del enunciado, crucero: T = %.1f N/rotor, V = %.1f m/s ===\n', Tprop, V);
fprintf('%-16s %8s %8s %8s %8s %8s\n', 'Helice', 'D[m]', 'n[rps]', 'CT', 'J', 'eta');
f2 = figure('Position', [100 100 900 520]);
col = lines(3);
for k = 1:3
    r = res(strcmp({res.name}, names3{k}));
    assert(~isempty(r), 'No existe la helice %s', names3{k});
    fprintf('%-16s %8.4f %8.1f %8.4f %8.4f %8.4f\n', r.name, r.D, r.n, r.CT, r.J, r.eta);
    S = load(fullfile(folderMat, [names3{k} '.mat']));
    yyaxis left; hold on;
    plot(S.J, S.CT_avg, '-', 'Color', col(k,:), 'LineWidth', 1.5, 'DisplayName', [strrep(names3{k}, '_', '\_') '  C_T']);
    plot(r.J, r.CT, 'o', 'Color', col(k,:), 'MarkerFaceColor', col(k,:), 'MarkerSize', 8, 'HandleVisibility', 'off');
    yyaxis right; hold on;
    plot(S.J, S.eta_avg, '--', 'Color', col(k,:), 'LineWidth', 1.5, 'DisplayName', [strrep(names3{k}, '_', '\_') '  \eta']);
    plot(r.J, r.eta, 's', 'Color', col(k,:), 'MarkerFaceColor', col(k,:), 'MarkerSize', 8, 'HandleVisibility', 'off');
end
yyaxis left; ylabel('C_T [-]'); ax = gca; ax.YAxis(1).Color = 'k'; ylim([-0.02 0.14]);
yyaxis right; ylabel('Eficiencia propulsiva [-]'); ax.YAxis(2).Color = 'k'; ylim([-0.2 1]);
grid on; xlabel('J [-]'); xlim([0 1.2]);
title('3 hélices: C_T (continua, punto o) y \eta (discontinua, punto cuadrado) en crucero');
legend('Interpreter', 'tex', 'Location', 'southwest');
exportgraphics(f2, 'fig_helices_crucero.png', 'Resolution', 200);

%% Funciones locales

function D = dragPlate(V, MTOM, c)
% Resistencia de la aeronave [N] con aproximacion de placa plana (cubo)
Stop = c.S_ref * (MTOM / c.M_ref)^(2/3); % Superficie superior [m^2]
L = sqrt(Stop); % Longitud caracteristica [m]
Swet = 6 * Stop; % Superficie mojada (cubo) [m^2]
M = V / sqrt(c.gamma * c.R * c.T);
if V == 0, D = 0; return; end % sin viento relativo no hay resistencia
Re = c.rho * V * L / c.mu;
Cf = 0.455 / (log10(Re)^2.58 * (1 + 0.144 * M^2)^0.65);
Cd0 = Cf * c.FF * Swet / Stop;
D = 0.5 * c.rho * Stop * V^2 * Cd0;
end

function [Thrust, theta] = balance(mass, V_horizontal, V_vertical, a_horizontal, a_vertical, Drag)
% Equilibrio de fuerzas en ejes absolutos X (horizontal) y Z (vertical):
%   m*ah = T sin(theta) - D cos(gamma)
%   m*av = T cos(theta) - m g - D sin(gamma)
g = 9.81;
gam = atan2(V_vertical, V_horizontal); % Angulo de trayectoria
A = mass * a_horizontal + Drag * cos(gam); % T sin(theta)
B = mass * a_vertical + mass * g + Drag * sin(gam); % T cos(theta)
Thrust = hypot(A, B); % Empuje total [N]
theta = atan2d(A, B); % Angulo de asiento [deg]
end

function r = evalProp(file_path, Tp, V, rho)
% Punto de operacion de una helice para dar el empuje Tp a velocidad V.
% T = CT(J) rho n^2 D^4 y n = V/(J D)  =>  CT(J)/J^2 = Tp/(rho V^2 D^2), monotona en J.
S = load(file_path);
r = struct('name', '', 'D', NaN, 'n', NaN, 'J', NaN, 'CT', NaN, 'eta', NaN, 'ok', false);
if ~all(isfield(S, {'J', 'CT_avg', 'D_m'})), return; end
J = S.J(:); CT = S.CT_avg(:); D = S.D_m;
if ~isscalar(D) || ~isfinite(D) || D <= 0, return; end % p. ej. pl_triturbo_avg tiene D_m = NaN
if isfield(S, 'eta_avg')
    eta = S.eta_avg(:);
elseif isfield(S, 'CP_avg')
    eta = CT .* J ./ S.CP_avg(:);
else
    return;
end
r.D = D;
good = isfinite(J) & isfinite(CT) & isfinite(eta) & J > 0; % descarta NaN y J = 0
[J, iu] = unique(J(good)); CT = CT(good); CT = CT(iu); eta = eta(good); eta = eta(iu);
if numel(J) < 2, return; end
g = @(x) interp1(J, CT, x) ./ x.^2 - Tp / (rho * V^2 * D^2);
sg = sign(g(J)); k = find(sg(1:end-1) .* sg(2:end) <= 0, 1); % primer cambio de signo
if isempty(k), return; end % empuje fuera del rango ensayado
Js = fzero(g, [J(k) J(k+1)]);
r.J = Js;
r.n = V / (Js * D);
r.CT = interp1(J, CT, Js);
r.eta = interp1(J, eta, Js);
r.ok = true;
end
