function [legs, tr, R] = build_profile(ac, P)
% Vertical profile (climb - cruise - descent) of the whole route, section 6:
%  - climb: C1/C2 at V2+20 (noise abatement), C3 accelerations / speed-limited
%    climbs imposed by the SID, C4 constant IAS to the crossover, C5 constant
%    Mach to the cruise altitude. All SPD legs with fixed thrust. If a chart
%    maximum altitude is reached before its fix a level leg is inserted.
%  - cruise: level, constant Mach (MRC), T = D. The TOD is found iterating on
%    the mass at TOD (the idle descent length depends on it).
%  - descent: D4 idle SPD (Mach, then IAS) down to the first STAR fix, then PTH
%    legs (fixed FPA and dV/dr, Tr unknown) through the STAR/approach schedule.
% Input:  ac = BADA aircraft; P = parameters (see main_vertical): m_tow (kg),
%         elev (ft), v2 (kt), h_thrred, h_acc (ft AAL), tr_to, tr_clb, cas_clb,
%         M_clb, hcross_clb, cas_des, M_des, hcross_des, h_cruise (ft), M_cruise,
%         sid (fix struct array with d, alt_max, ias_max), des (descent schedule
%         cell: name, d NM, h ft, cas kt, config, leg label, description), dt (s)
% Output: legs = struct array, one row per leg (see fly_leg); tr = whole trace;
%         R = r_toc, r_tod (NM), fuel_climb/cruise/descent/total (kg), t_total (s),
%             m_toc, m_tod, m_ldg (kg)
G = 9.80665; FT2M = 0.3048; KTS2MPS = 1852/3600; M2FT = 1/FT2M; M2NM = 1/1852;
legs = []; tr = [];
x = struct('t', 0, 'r', 0, 'h', P.elev*FT2M, 'V', 0, 'W', P.m_tow*G);
base = struct('hcross', P.hcross_clb, 'dt', P.dt, 'esf', [], 'FPA', 0, 'hold', 'none', 'value', []);

% ========================= CLIMB ============================================
% C1 / C2: V2+20 at take-off thrust up to the thrust reduction height, then
% at climb thrust up to the acceleration height (noise abatement, AD 2.21)
L = base; L.type = 'SPD'; L.known = 'Tr'; L.hold = 'cas'; L.cas = P.v2 + 20;
L.name = 'C1'; L.desc = sprintf('Ascenso inicial a V2+20 = %d kt, empuje de despegue, flaps TO', L.cas);
L.phase = 'takeoff'; L.value = P.tr_to; L.stop = struct('h', P.elev + P.h_thrred); go(L);
L.name = 'C2'; L.desc = 'V2+20 con empuje de ascenso (reducción por ruido), flaps 1';
L.phase = 'initialclimb'; L.known = 'red'; L.value = 0; L.stop = struct('h', P.elev + P.h_acc); go(L);

% C3 .. C5: driven by the SID limits (IAS max at fixes, 250 kt below 10000 ft,
% max altitudes), the climb IAS, the crossover and the cruise altitude
k = 0;
while x.h*M2FT < P.h_cruise - 1
    r = x.r*M2NM; h = x.h*M2FT; cas = tas2cas(x.V, x.h)/KTS2MPS;
    up = P.sid([P.sid.d] > r + 1e-3);                 % fixes not yet passed (> 1.9 m ahead)
    cas_tgt = min([P.cas_clb, up.ias_max]); if h < 10000, cas_tgt = min(cas_tgt, 250); end
    h_tgt = min([P.h_cruise, up.alt_max]);
    iS = find([up.ias_max] <= cas_tgt + 1e-9, 1);     % fix whose IAS limit binds
    iH = find([up.alt_max] <= h_tgt + 1e-9, 1);       % fix whose max altitude binds
    stop = struct(); rr = [];
    if ~isempty(iS) && cas_tgt < P.cas_clb, rr(end+1) = up(iS).d; end
    if ~isempty(iH) && h_tgt < P.h_cruise,  rr(end+1) = up(iH).d; end
    if ~isempty(rr), stop.r = min(rr); end
    if isempty(iS), lim = '10000 ft'; else, lim = up(iS).name; end
    L = base; L.known = 'red'; L.value = 0; L.phase = 'climb';   % BADA 3.8 reduced climb power
    if cas < cas_tgt - 1                               % acceleration, BADA ESF = 0.3
        k = k + 1; L.name = sprintf('C3.%d', k); L.type = 'SPD'; L.esf = 0.3;
        L.desc = sprintf('Aceleración %.0f → %.0f kt IAS a empuje de ascenso (ESF 0,3)', cas, cas_tgt);
        stop.cas = cas_tgt; if h_tgt < P.h_cruise, stop.h = h_tgt; end
    elseif h >= h_tgt - 1 && h_tgt < P.h_cruise        % level until the limiting fix
        k = k + 1; L.name = sprintf('C3.%d', k); L.type = 'PTH'; L.known = 'dVdr'; L.value = 0;
        L.desc = sprintf('Tramo plano a %.0f ft hasta %s (altitud máxima de la carta)', h_tgt, up(iH).name);
        stop = struct('r', up(iH).d);
    else                                               % constant IAS / Mach climb
        L.type = 'SPD';
        if cas_tgt < P.cas_clb
            k = k + 1; L.name = sprintf('C3.%d', k); L.hold = 'cas'; L.cas = cas_tgt;
            L.desc = sprintf('Ascenso a IAS constante %.0f kt (límite de velocidad hasta %s)', cas_tgt, lim);
            stop.h = h_tgt; if h < 10000 && cas_tgt == 250 && isempty(iS), stop.h = min(h_tgt, 10000); end
        elseif h < P.hcross_clb - 1
            L.name = 'C4'; L.hold = 'cas'; L.cas = P.cas_clb; stop.h = min(h_tgt, P.hcross_clb);
            L.desc = sprintf('Ascenso a IAS constante %.0f kt hasta la altitud de cruce', P.cas_clb);
        else
            L.name = 'C5'; L.hold = 'mach'; L.mach = P.M_clb; stop.h = h_tgt;
            L.desc = sprintf('Ascenso a Mach constante %.2f hasta la altitud de crucero', P.M_clb);
        end
    end
    L.stop = stop; go(L);
end
R.r_toc = x.r*M2NM; R.m_toc = x.W/G; n_clb = numel(legs);

% ========================= CRUISE ===========================================
% K1: level acceleration / deceleration from the climb Mach to the cruise Mach
[~, ~, ~, a] = getAtmosphericData(x.h);
if abs(P.M_cruise - x.V/a) > 0.002
    L = base; L.type = 'PTH'; L.phase = 'cruise'; L.name = 'K1'; L.stop = struct('mach', P.M_cruise);
    if P.M_cruise > x.V/a, L.known = 'Tr'; L.value = 0.95; L.desc = sprintf('Aceleración en nivel M%.2f → M%.3f (MRC), empuje máximo de crucero', x.V/a, P.M_cruise);
    else,                  L.known = 'idle';             L.desc = sprintf('Deceleración en nivel M%.2f → M%.3f (MRC), ralentí', x.V/a, P.M_cruise); end
    go(L);
end
% K2: cruise at constant altitude and Mach until the TOD. The length of the
% top of the descent (K3 + D4, idle) depends on the mass at TOD: iterate.
xk = x; legs_k = legs; tr_k = tr; d_zukko = P.des{1,2}; W_tod = x.W;
for it = 1:5
    [Ld, ~] = run_top_descent(W_tod);
    r_tod = d_zukko - Ld;
    if r_tod < R.r_toc, error('build_profile: route too short for %g ft (TOD before TOC)', P.h_cruise); end
    x = xk; legs = legs_k; tr = tr_k;
    L = base; L.type = 'PTH'; L.known = 'dVdr'; L.value = 0; L.phase = 'cruise'; L.dt = 10;
    L.name = 'K2'; L.desc = sprintf('Crucero a %.0f ft y Mach %.3f constante (MRC) hasta el K3 / TOD', P.h_cruise, P.M_cruise);
    L.stop = struct('r', r_tod); go(L);
    if abs(x.W - W_tod) < 20*G, break; end             % mass at TOD converged (20 kg)
    W_tod = x.W;
end
Ls = top_descent_legs(); isK3 = cellfun(@(Lt) strcmp(Lt.name, 'K3'), Ls);
for i = find(isK3), go(Ls{i}); end                  % K3 is level flight: cruise, not descent
R.r_tod = x.r*M2NM; R.m_tod = x.W/G; n_cru = numel(legs);

% ========================= DESCENT ==========================================
for i = find(~isK3), go(Ls{i}); end
for i = 1:size(P.des,1) - 1                          % PTH legs between fixes
    d1 = P.des{i,2}; h1 = P.des{i,3}; c1 = P.des{i,4};
    d2 = P.des{i+1,2}; h2 = P.des{i+1,3}; c2 = P.des{i+1,4};
    V1 = cas2tas(c1*KTS2MPS, h1*FT2M); V2 = cas2tas(c2*KTS2MPS, h2*FT2M);
    L = base; L.type = 'PTH'; L.known = 'dVdr'; L.hcross = P.hcross_des;
    L.FPA = atand((h2 - h1)*FT2M / ((d2 - d1)/M2NM)); L.value = (V2 - V1) / ((d2 - d1)/M2NM);
    L.phase = P.des{i+1,5}; L.name = P.des{i+1,6}; L.desc = P.des{i+1,7}; L.stop = struct('r', d2);
    go(L);
end
R.t_total = x.t; R.m_ldg = x.W/G;
f = [legs.fuel_kg];
R.fuel_climb = sum(f(1:n_clb)); R.fuel_cruise = sum(f(n_clb+1:n_cru));
R.fuel_descent = sum(f(n_cru+1:end)); R.fuel_total = sum(f);
R.h_cruise = P.h_cruise; R.M_cruise = P.M_cruise;

% ----------------------------------------------------------------------------
    function go(Lg)                       % fly a leg and append it
        [x, S, t] = fly_leg(ac, x, Lg);
        if isempty(legs), legs = S; tr = t; else
            legs(end+1) = S;
            for fn = fieldnames(tr)', tr.(fn{1}) = [tr.(fn{1}), t.(fn{1})]; end
        end
    end
    function Ls = top_descent_legs()      % K3 (Mach change) + D4 (idle descent)
        Ls = {}; Lb = base; Lb.hcross = P.hcross_des; Lb.phase = 'descent';
        if abs(P.M_des - P.M_cruise) > 0.002
            L3 = Lb; L3.type = 'PTH'; L3.phase = 'cruise'; L3.name = 'K3'; L3.stop = struct('mach', P.M_des);
            if P.M_des < P.M_cruise, L3.known = 'idle'; L3.desc = sprintf('Deceleración en nivel M%.3f → M%.2f de descenso, ralentí', P.M_cruise, P.M_des);
            else, L3.known = 'Tr'; L3.value = 0.95; L3.desc = sprintf('Aceleración en nivel M%.3f → M%.2f de descenso', P.M_cruise, P.M_des); end
            Ls{end+1} = L3;
        end
        h_end = P.des{1,3};
        if P.h_cruise > P.hcross_des + 1
            L4 = Lb; L4.type = 'SPD'; L4.known = 'idle'; L4.hold = 'mach'; L4.mach = P.M_des; L4.name = 'D4.1';
            L4.desc = sprintf('Descenso en ralentí a Mach constante %.2f hasta la altitud de cruce', P.M_des);
            L4.stop = struct('h', max(P.hcross_des, h_end)); Ls{end+1} = L4;
        end
        if h_end < min(P.hcross_des, P.h_cruise)
            L4 = Lb; L4.type = 'SPD'; L4.known = 'idle'; L4.hold = 'cas'; L4.cas = P.cas_des; L4.name = 'D4.2';
            L4.desc = sprintf('Descenso en ralentí a IAS constante %.0f kt hasta %s (%.0f ft)', P.cas_des, P.des{1,1}, h_end);
            L4.stop = struct('h', h_end); Ls{end+1} = L4;
        end
    end
    function [Ld, Wend] = run_top_descent(W0)   % length (NM) of K3 + D4 from TOD
        [~, ~, ~, a0] = getAtmosphericData(P.h_cruise*FT2M);
        xd = struct('t', 0, 'r', 0, 'h', P.h_cruise*FT2M, 'V', P.M_cruise*a0, 'W', W0);
        Lt = top_descent_legs();
        for j = 1:numel(Lt), xd = fly_leg(ac, xd, Lt{j}); end
        Ld = xd.r*M2NM; Wend = xd.W;
    end
end
