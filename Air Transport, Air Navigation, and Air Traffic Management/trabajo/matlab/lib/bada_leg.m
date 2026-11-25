function [T, Tr, D, V, Wdot, hdot, Vdot, ESF, M] = bada_leg(ac, W, h, cas, phase, leg_type, FPA, known, value, hcross, esf)
% One instant of a vertical leg with the BADA 3 Total Energy Model.
% Adapted from kgbx-lib/bada/BADA_jet3.m (same equations, BADA 3 User
% Manual 3.2, 3.5, 3.7, 3.8, 3.9) with these changes:
%   - no global variables; the crossover altitude is an input
%   - known = 'idle': Tr = BADA descent thrust coefficient (idle descent)
%   - optional energy share factor (BADA: 0.3 for acceleration in climb)
%   - PTH legs return the REQUIRED Tr without clamping (Tr < 0 means that
%     speed brakes or a shallower FPA are needed, section 6.2.3)
%   - idle fuel flow (Cf3, Cf4) whenever Tr <= idle thrust (BADA 3.9.3)
% Input:
%   ac       = aircraft struct from LoadAircraftBADA
%   W        = weight (N);  h = altitude (m);  cas = calibrated airspeed (m/s)
%   phase    = drag configuration: 'takeoff' (flap 5), 'initialclimb' (flap 1),
%              'climb' (clean), 'cruise' (clean, cruise fuel correction),
%              'descent' (clean, idle), 'approach' (flap 15), 'landing' (flap 30)
%   leg_type = 'SPD' (constant CAS/Mach) or 'PTH' (constant flight path angle)
%   FPA      = flight path angle (deg), PTH legs only (negative = descent)
%   known    = second degree of freedom: 'Tr' (thrust ratio), 'idle', 'red' (BADA
%              reduced climb power, value ignored; SPD only), or
%              'dVdr' (dV/dr along the ground, 1/m; PTH only)
%   value    = value of the known variable (SI)
%   hcross   = crossover altitude (ft) used to choose the ESF (const CAS / Mach)
%   esf      = [] (BADA value) or an imposed energy share factor
% Output:
%   T = thrust (N); Tr = T/Tmax; D = drag (N); V = TAS (m/s);
%   Wdot = fuel flow (N/s, negative); hdot = vertical speed (m/s);
%   Vdot = dV/dt (m/s2); ESF = energy share factor; M = Mach
G = 9.80665; KTS2MPS = 1852/3600; FT2M = 0.3048; HTROP = 36000;   % ft
kappa = 1.4; R = 287.05287; Beta = -0.0065;
if nargin < 11, esf = []; end

V = cas2tas(cas, h);
[rho, ~, temp, a] = getAtmosphericData(h);
M = V / a;

% --- thrust / fuel coefficients and drag configuration (BADA 3.7, 3.9) ------
if h > ac.enginethrust.h_des*FT2M, Ctidle = ac.enginethrust.Ctcdeshigh;
else,                               Ctidle = ac.enginethrust.Ctcdeslow; end
Cf = 1; cfg = 'cruise';
switch phase
    case 'cruise',   Cf = ac.fuel.Cfcr;
    case 'descent'
    case 'climb'
    case 'approach', cfg = 'approach';
    case 'landing',  cfg = 'landing';
    otherwise,       cfg = phase;                 % 'takeoff', 'initialclimb'
end
e = ac.enginethrust;
Tmax = e.Ctc1 * (1 - h/(e.Ctc2*FT2M) + e.Ctc3/FT2M^2 * h^2);   % max climb thrust, ISA
D = ac.aero.(cfg).Cd0 * 0.5*rho*V^2*ac.aero.S + 2*ac.aero.(cfg).Cd2 * W^2 / (rho*V^2*ac.aero.S);

% --- energy share factor (BADA 3.8) -----------------------------------------
dT = temp - 288.15;
if ~isempty(esf)
    ESF = esf;
elseif h < HTROP*FT2M && h < hcross*FT2M        % constant CAS, below tropopause
    ESF = (1 + kappa*R*Beta/(2*G)*M^2*(temp-dT)/temp + (1+(kappa-1)/2*M^2)^(-1/(kappa-1)) ...
          * ((1+(kappa-1)/2*M^2)^(kappa/(kappa-1)) - 1))^(-1);
elseif h < HTROP*FT2M                            % constant Mach, below tropopause
    ESF = (1 + kappa*R*Beta/(2*G)*M^2*(temp-dT)/temp)^(-1);
elseif h < hcross*FT2M                           % constant CAS, above tropopause
    ESF = (1 + (1+(kappa-1)/2*M^2)^(-1/(kappa-1)) * ((1+(kappa-1)/2*M^2)^(kappa/(kappa-1)) - 1))^(-1);
else
    ESF = 1;                                     % constant Mach, above tropopause
end

% --- leg equations (total energy model, BADA 3.2) --------------------------
switch leg_type
    case 'SPD'
        switch known
            case 'Tr',   Tr = value;
            case 'idle', Tr = Ctidle;
            case 'red'    % BADA 3.8 reduced climb power: Cpow,red multiplies the excess power
                Cred = 0.15;                                   % jets (BADA 3.14 manual, 5.11)
                if h >= 0.8*ac.envelope.hmax*FT2M, Cpow = 1;   % Cred = 0 above 0.8 hmax
                else, Cpow = 1 - Cred*(ac.mass.m_max - W/G)/(ac.mass.m_max - ac.mass.m_min); end
                Tr = (D + Cpow*(Tmax - D)) / Tmax;             % thrust giving (T-D) = Cpow (Tmax-D)
            otherwise,   error('bada_leg: SPD legs need known = Tr, idle or red');
        end
        T = Tr * Tmax;
        Vdot = (1 - ESF) * (T - D) * G / W;
        hdot = ESF * (T - D) * V / W;
    case 'PTH'
        hdot = V * sind(FPA);
        switch known
            case {'Tr', 'idle'}
                if strcmp(known, 'Tr'), Tr = value; else, Tr = Ctidle; end
                T = Tr * Tmax;
                Vdot = G * ((T - D)/W - sind(FPA));
            case 'dVdr'
                Vdot = value * V * cosd(FPA);
                T = D + W*sind(FPA) + W/G*Vdot;
                Tr = T / Tmax;
            otherwise, error('bada_leg: PTH legs need known = Tr, idle or dVdr');
        end
        if abs(T - D) < 1, ESF = 0; else, ESF = W*sind(FPA)/(T - D); end
    otherwise
        error('bada_leg: leg type must be SPD or PTH');
end

% --- fuel flow (BADA 3.9): nominal, or minimum (idle) when Tr <= idle ------
f = ac.fuel;
if Tr > Ctidle
    eta  = f.Cf1*G/60000 * (1 + V/(f.Cf2*KTS2MPS));    % N/(s*N)
    Wdot = -eta * T * Cf;
else
    Wdot = -f.Cf3*G/60 * (1 - h/(f.Cf4*FT2M));          % idle
end
end
