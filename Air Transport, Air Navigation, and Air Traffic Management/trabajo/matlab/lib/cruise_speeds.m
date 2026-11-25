function C = cruise_speeds(ac, h_ft, m_kg)
% MRC and LRC speeds at a given cruise altitude and mass (section 6.3.1).
% Level flight (T = D) is evaluated with the BADA model for every CAS
% between 0.5*Vmo and Vmo/Mmo; the fuel mileage (NM per kg) is maximum
% at MRC, and LRC is the first speed above MRC with 1 % less mileage.
% Same method as matlab_utilities/MAIN_Cost_Index.m, without integrating.
% Input:  ac = BADA aircraft; h_ft = cruise altitude (ft); m_kg = mass (kg)
% Output: C struct: M_mrc, cas_mrc (kt), tas_mrc (kt), M_lrc, cas_lrc, tas_lrc,
%         and the sweep arrays cas (kt), M, tas (kt), mileage (NM/kg), ff (kg/min)
KTS2MPS = 1852/3600; FT2M = 0.3048; G = 9.80665; NM2M = 1852;
h = h_ft*FT2M; W = m_kg*G;
cas = []; M = []; tas = []; ff = [];
for v = round(0.5*ac.envelope.Vmo):ac.envelope.Vmo
    [~, Tr, ~, V, Wdot, ~, ~, ~, Mm] = bada_leg(ac, W, h, v*KTS2MPS, 'cruise', 'PTH', 0, 'dVdr', 0, h_ft+1, []);
    if Mm > ac.envelope.Mmo, break; end
    if Tr > 0.95, break; end          % above max cruise thrust (BADA Ct = 0.95)
    cas(end+1) = v; M(end+1) = Mm; tas(end+1) = V/KTS2MPS; ff(end+1) = -Wdot/G*60; %#ok<AGROW>
end
mileage = tas*KTS2MPS*60 ./ (ff*NM2M);                % NM per kg
[mx, i] = max(mileage);
j = find(mileage <= 0.99*mx & (1:numel(mileage)) > i, 1); if isempty(j), j = numel(mileage); end
C = struct('M_mrc', M(i), 'cas_mrc', cas(i), 'tas_mrc', tas(i), ...
           'M_lrc', M(j), 'cas_lrc', cas(j), 'tas_lrc', tas(j), ...
           'cas', cas, 'M', M, 'tas', tas, 'mileage', mileage, 'ff', ff);
end
