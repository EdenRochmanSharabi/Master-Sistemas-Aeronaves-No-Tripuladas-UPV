function [x, S, tr] = fly_leg(ac, x, L)
% Integrates ONE vertical leg with the BADA total energy model (bada_leg)
% by explicit Euler steps in time until the first end condition is met.
% The last step is shortened so the end condition is met exactly.
% Input:
%   ac = BADA aircraft struct
%   x  = state at the start: t (s), r (m along the route), h (m), V (TAS m/s), W (N)
%   L  = leg definition, struct with fields:
%        name, desc   = label and description for the tables
%        type         = 'SPD' | 'PTH';  known = 'Tr' | 'idle' | 'dVdr';  value
%        phase        = drag configuration (see bada_leg)
%        hold         = 'cas' (L.cas in kt), 'mach' (L.mach) or 'none'
%        FPA          = flight path angle (deg), PTH legs
%        esf          = [] or imposed energy share factor (acceleration legs)
%        hcross       = crossover altitude (ft)
%        stop         = struct with any of: h (ft), r (NM, route distance),
%                       cas (kt), mach. The leg ends at the first one reached.
%        dt           = time step (s), default 1
% Output:
%   x  = state at the end of the leg
%   S  = summary of the leg (one row of the results table)
%   tr = trace: arrays t, r, h, V, cas, M, Tr, hdot, Vdot, W (SI)
KTS2MPS = 1852/3600; FT2M = 0.3048; NM2M = 1852;
if ~isfield(L, 'dt') || isempty(L.dt), L.dt = 1; end
if ~isfield(L, 'esf'), L.esf = []; end
if ~isfield(L, 'FPA'), L.FPA = 0; end
x.V = held_speed(x, L);
n = 0; N = 200000; done = false;
tr = struct('t',zeros(1,0),'r',[],'h',[],'V',[],'cas',[],'M',[],'Tr',[],'hdot',[],'Vdot',[],'W',[]);
while ~done
    n = n + 1; if n > N, error('fly_leg: leg %s does not reach its end condition', L.name); end
    cas = tas2cas(x.V, x.h);
    [~, Tr, ~, ~, Wdot, hdot, Vdot, ~, M] = bada_leg(ac, x.W, x.h, cas, L.phase, L.type, L.FPA, L.known, L.value, L.hcross, L.esf);
    tr.t(n) = x.t; tr.r(n) = x.r; tr.h(n) = x.h; tr.V(n) = x.V; tr.cas(n) = cas; tr.M(n) = M;
    tr.Tr(n) = Tr; tr.hdot(n) = hdot; tr.Vdot(n) = Vdot; tr.W(n) = x.W;
    % --- time to the end conditions ------------------------------------------
    gam = asin(max(-1, min(1, hdot / x.V)));
    dt = L.dt; tol = 1e-3;
    if isfield(L.stop, 'h')
        dh = L.stop.h*FT2M - x.h;
        if abs(dh) < 0.5 || dh*hdot < 0 && n > 1, done = true; end
        if hdot ~= 0 && dh*hdot > 0, dt = min(dt, dh/hdot); end
    end
    if isfield(L.stop, 'r')
        dr = L.stop.r*NM2M - x.r; vg = x.V*cos(gam);
        if dr < 1, done = true; end
        dt = min(dt, max(dr/vg, tol));
    end
    if isfield(L.stop, 'cas')
        dV = cas2tas(L.stop.cas*KTS2MPS, x.h) - x.V;
        if abs(dV) < 0.05 || (dV*Vdot < 0 && n > 1), done = true; end
        if Vdot ~= 0 && dV*Vdot > 0, dt = min(dt, dV/Vdot); end
    end
    if isfield(L.stop, 'mach')
        [~, ~, ~, a] = getAtmosphericData(x.h); dV = L.stop.mach*a - x.V;
        if abs(dV) < 0.05 || (dV*Vdot < 0 && n > 1), done = true; end
        if Vdot ~= 0 && dV*Vdot > 0, dt = min(dt, dV/Vdot); end
    end
    if done, break; end
    if strcmp(L.type,'SPD') && isfield(L.stop,'h') && isempty(L.esf) && hdot*(L.stop.h*FT2M - x.h) <= 0
        error('fly_leg: leg %s cannot reach %g ft (vertical speed %.0f fpm)', L.name, L.stop.h, hdot/0.00508);
    end
    dt = max(dt, tol);
    % --- Euler step ---------------------------------------------------------
    x.r = x.r + x.V*cos(gam)*dt;
    x.h = x.h + hdot*dt;
    x.V = x.V + Vdot*dt;
    x.W = x.W + Wdot*dt;
    x.t = x.t + dt;
    x.V = held_speed(x, L);
end
S = summary(L, tr, ac);
end

function V = held_speed(x, L)
% TAS that keeps the held CAS or Mach at the current altitude
KTS2MPS = 1852/3600;
switch L.hold
    case 'cas',  V = cas2tas(L.cas*KTS2MPS, x.h);
    case 'mach', [~, ~, ~, a] = getAtmosphericData(x.h); V = L.mach*a;
    otherwise,   V = x.V;
end
end

function S = summary(L, tr, ac)
% One table row with the parameters of the leg (units of the assignment)
MPS2KTS = 3600/1852; M2FT = 1/0.3048; M2NM = 1/1852; G = 9.80665;
S.tramo = L.name; S.descripcion = L.desc; S.tipo = L.type;
% sub-type: second degree of freedom, known and unknown variables (6.1)
switch [L.type '/' L.known]
    case {'SPD/Tr', 'SPD/red'}
        if isempty(L.esf), S.subtipo = 'Tr fijo';   S.conocidas = 'IAS o Mach, Tr';  S.incognitas = 'VS (ROCD), FPA';
        else,              S.subtipo = 'Tr fijo + ESF'; S.conocidas = sprintf('Tr, ESF=%.1f', L.esf); S.incognitas = 'VS, dV/dt (aceleración)'; end
    case 'SPD/idle', S.subtipo = 'Tr ralentí'; S.conocidas = 'IAS o Mach, Tr = ralentí (BADA)'; S.incognitas = 'VS (ROD), FPA';
    case 'PTH/dVdr', S.subtipo = 'dV/dr fijo'; S.conocidas = 'FPA, dV/dr (IAS inicial y final)'; S.incognitas = 'Tr';
    otherwise,       S.subtipo = 'Tr fijo';    S.conocidas = 'FPA, Tr';                      S.incognitas = 'dV/dt';
end
S.config = L.phase;
S.h_ini_ft = tr.h(1)*M2FT;      S.h_fin_ft = tr.h(end)*M2FT;
S.cas_ini_kt = tr.cas(1)*MPS2KTS; S.cas_fin_kt = tr.cas(end)*MPS2KTS;
S.tas_ini_kt = tr.V(1)*MPS2KTS;   S.tas_fin_kt = tr.V(end)*MPS2KTS;
S.M_ini = tr.M(1); S.M_fin = tr.M(end);
dtt = max(tr.t(end) - tr.t(1), 1e-9);
S.vs_med_fpm = (tr.h(end) - tr.h(1)) / dtt * M2FT * 60;
S.FPA_deg = atand((tr.h(end) - tr.h(1)) / max(tr.r(end) - tr.r(1), 1e-9));
S.Tr_med_pct = 100*mean(tr.Tr); S.Tr_min_pct = 100*min(tr.Tr); S.Tr_max_pct = 100*max(tr.Tr);
S.dist_NM = (tr.r(end) - tr.r(1)) * M2NM;
S.dist_ini_NM = tr.r(1) * M2NM; S.dist_fin_NM = tr.r(end) * M2NM;
S.t_min = dtt / 60;
S.fuel_kg = (tr.W(1) - tr.W(end)) / G;
S.masa_fin_kg = tr.W(end) / G;
S.nota = '';
if min(tr.h) < ac.enginethrust.h_des*0.3048, ct_idle = ac.enginethrust.Ctcdeslow; else, ct_idle = ac.enginethrust.Ctcdeshigh; end
if strcmp(L.type, 'PTH') && min(tr.Tr) < ct_idle
    S.nota = 'Tr requerido < ralentí BADA: frenos aerodinámicos o FPA menor'; end
if min(tr.Tr) < 0, S.nota = 'Tr<0: frenos aerodinámicos / FPA menor'; end
if max(tr.Tr) > 1, S.nota = 'Tr>1: empuje insuficiente'; end
end
