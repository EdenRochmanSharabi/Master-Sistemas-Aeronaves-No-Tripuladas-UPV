% MAIN_VERTICAL  Vertical profile LEMD 36R -> LLBG 21 with BADA 3.14 (B738).
% Section 6 of the assignment: SPD/PTH legs of climb, cruise and descent,
% TOC/TOD, cruise speed (MRC) and altitude (BADA hmax), crossover altitude,
% and fuel for two cruise speeds and two cruise altitudes.
% Needs the tables written by main_sid, main_enroute and main_star_app.
clear; clc;
here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
lib  = fullfile(root, 'Bada-matlab-Fatzip');
addpath(fullfile(here,'lib'), fullfile(lib,'kgbx-lib','bada'), fullfile(lib,'kgbx-lib','geo'), ...
        fullfile(lib,'kgbx-lib','kml'), fullfile(lib,'matlab_utilities'), fullfile(here,'lib','xml2struct_r2026'));
out = fullfile(here, 'out');
G = 9.80665;

% --- Aircraft: B737-800, BADA 3.14 ------------------------------------------
ac = LoadAircraftBADA(fullfile(lib,'BADA_3.14','bada_314_96b6f733f5b65f32a5e7','B738__.OPF'));

% --- Route fixes and limits from the horizontal study ----------------------
% (shared fixes NANDO, ZUKKO, TOPPU are kept once, with the limits of the
%  procedure table, not the en-route one)
sid = load_phase_table(fullfile(out,'SID-NANDO3R.xlsx'), 0);
enr = load_phase_table(fullfile(out,'enroute-sinviento.xlsx'), sid(end).d);
arr = load_phase_table(fullfile(out,'LLEGADA-ERREZ1A.xlsx'), enr(end).d);
apr = load_phase_table(fullfile(out,'APR-ILS21.xlsx'), arr(end).d);
fix = [sid, enr(2:end-1), arr, apr(2:end)]; d_total = fix(end).d;
dof = @(n) fix(strcmp({fix.name}, n)).d;        % route distance of a fix (NM)

% --- Parameters of the profile ----------------------------------------------
fp = xml2struct(fullfile(root,'simbrief','LEMDLLBG_XML_1793965869.xml'));
P.m_tow = str2double(fp.OFP.weights.est_tow.Text);      % kg, SimBrief estimated TOW
P.elev  = 1998;                                         % ft, LEMD (AD 2 LEMD)
P.v2    = round(1.2*ac.aero.takeoff.Vstall*sqrt(P.m_tow/ac.mass.m_ref)); % kt, BADA Vstall(TO) x 1.2, mass-corrected
P.h_thrred = 1500; P.h_acc = 3000;                      % ft AAL, LEMD AD 2.21 noise abatement
P.tr_to = 1.0; P.tr_clb = NaN;                          % take-off Tr; climb Tr is computed (BADA 3.8 Cpow,red, Cred = 0.15)
P.cas_clb = 300; P.M_clb = 0.78;                        % BADA APF B738 climb (HI mass): 300 kt / M0.78
P.cas_des = 290; P.M_des = 0.78;                        % BADA APF B738 descent: M0.78 / 290 kt
P.h_cruise = maxCruiseAlt(d_total, ac.envelope.hmax);   % ft, BADA cruise ceiling hmax (6.3.2)
P.hcross_clb = CrossOverAltitude(P.cas_clb, P.M_clb, P.h_cruise);   % ft (6.3.3)
P.hcross_des = CrossOverAltitude(P.cas_des, P.M_des, P.h_cruise);
hcross_mo    = CrossOverAltitude(ac.envelope.Vmo, ac.envelope.Mmo, P.h_cruise);
P.sid = sid; P.dt = 1;
% Descent schedule: lower envelope of the STAR / ILS limits (main_star_app),
% 250 kt below FL100, approach speeds for category C (PANS-OPS: final approach 115-160 kt)
v_ref = round(1.3*ac.aero.landing.Vstall + 5);          % kt, Vref = 1.3 Vstall(LD) + 5 (course formula)
v_fap = 150;                                            % kt, final approach range cat C 115-160 (>= Vref)
D = {'ZUKKO', 13000, P.cas_des, 'descent',  'D4',   'fin del descenso en ralentí (ZUKKO máx. 13000 ft)'; ...
     'KONFO', 10000, 250,       'descent',  'D3',   'PTH decelerando 290 → 250 kt hasta KONFO (10000-11000 ft)'; ...
     'ERREZ',  9000, 250,       'descent',  'D2.1', 'PTH KONFO → ERREZ (@9000 ft)'; ...
     'LEGOH',  9000, 250,       'descent',  'D2.2', 'tramo plano a 9000 ft ERREZ-IVONA-RAPIV-ALIQA-LEGOH'; ...
     'ANOZA',  5000, 250,       'descent',  'D2.3', 'PTH LEGOH → ANOZA (mín. 5000 ft)'; ...
     'TOPPU',  4000, 250,       'descent',  'D2.4', 'PTH ANOZA → TOPPU (mín. 4000 ft)'; ...
     'GALGA',  2600, 185,       'approach', 'D2.5', 'PTH TOPPU → GALGA (IF, 2600 ft), IAS ≤ 185 kt (límite de la carta en el segmento intermedio), flaps 15'; ...
     'BG074',  2600, v_fap,     'approach', 'D2.6', 'segmento intermedio a 2600 ft hasta el FAP, deceleración a la velocidad de aproximación final'; ...
     'THR21',   183, v_ref,     'landing',  'D1',   'senda ILS 3 grados hasta el umbral (183 ft), Vref, flaps 30'};
P.des = [D(:,1), cellfun(dof, D(:,1), 'UniformOutput', false), D(:,2:end)];

% --- Cruise speed (MRC, 6.3.1) at the mean cruise mass: two passes ----------
m_cru = P.m_tow - 2500;
for pass = 1:2
    C = cruise_speeds(ac, P.h_cruise, m_cru); P.M_cruise = C.M_mrc;
    [legs, tr, R] = build_profile(ac, P);
    m_cru = (R.m_toc + R.m_tod)/2;
end
chk = check_profile(tr, fix);

% --- Outputs ------------------------------------------------------------------
writetable(struct2table(legs), fullfile(out,'VERTICAL-tramos.xlsx'));
writetable(struct2table(chk),  fullfile(out,'VERTICAL-comprobacion.xlsx'));
plot_vertical_profile(tr, fix, R, [sid(end).d, enr(end).d], ...
    fullfile(out,'VERTICAL-perfil-fases.png'), fullfile(out,'VERTICAL-perfil-completo.png'));
f = figure('Visible','off', 'Theme','light'); plot(C.M, C.mileage*1000, 'b-', 'LineWidth', 1.5); hold on; grid on;
plot(C.M_mrc, max(C.mileage)*1000, 'rx', C.M_lrc, 0.99*max(C.mileage)*1000, 'bx', 'MarkerSize', 10, 'LineWidth', 2);
xlabel('Mach'); ylabel('Alcance específico (NM / 1000 kg)'); legend('BADA B738', 'MRC', 'LRC', 'Location', 'southeast');
title(sprintf('Crucero a %.0f ft, masa %.0f kg', P.h_cruise, m_cru)); exportgraphics(f, fullfile(out,'VERTICAL-MRC.png'), 'BackgroundColor', 'white'); close(f);

fprintf('B738  TOW %.0f kg (SimBrief)  V2 %d kt  hmax %.0f ft  Vmo/Mmo %g/%g\n', P.m_tow, P.v2, ac.envelope.hmax, ac.envelope.Vmo, ac.envelope.Mmo);
fprintf('Crossover: ascenso %.0f/M%.2f -> %.0f ft | descenso %.0f/M%.2f -> %.0f ft | Vmo/Mmo -> %.0f ft\n', ...
    P.cas_clb, P.M_clb, P.hcross_clb, P.cas_des, P.M_des, P.hcross_des, hcross_mo);
fprintf('MRC a %.0f ft y %.0f kg: M%.3f (%.0f kt IAS, %.0f kt TAS) | LRC: M%.3f (%.0f kt IAS)\n', ...
    P.h_cruise, m_cru, C.M_mrc, C.cas_mrc, C.tas_mrc, C.M_lrc, C.cas_lrc);
fprintf('TOC a %.1f NM | TOD a %.1f NM (%.1f NM antes de ZUKKO, %.1f NM del umbral) | ruta %.1f NM\n', ...
    R.r_toc, R.r_tod, dof('ZUKKO') - R.r_tod, d_total - R.r_tod, d_total);
fprintf('Combustible: ascenso %.0f + crucero %.0f + descenso %.0f = %.0f kg | tiempo %.2f h | masa aterrizaje %.0f kg\n', ...
    R.fuel_climb, R.fuel_cruise, R.fuel_descent, R.fuel_total, R.t_total/3600, R.m_ldg);
fprintf('\n%-5s %-4s %-12s %7s %7s %5s %5s %6s %6s %6s %6s %6s %6s %s\n', 'Tramo','Tipo','Subtipo','h_ini','h_fin','IASi','IASf','TASf','VSmed','Tr%','FPA','dist','fuel','nota');
for i = 1:numel(legs), s = legs(i);
    fprintf('%-5s %-4s %-12s %7.0f %7.0f %5.0f %5.0f %6.0f %6.0f %6.1f %6.2f %6.1f %6.0f %s\n', s.tramo, s.tipo, s.subtipo, ...
        s.h_ini_ft, s.h_fin_ft, s.cas_ini_kt, s.cas_fin_kt, s.tas_fin_kt, s.vs_med_fpm, s.Tr_med_pct, s.FPA_deg, s.dist_NM, s.fuel_kg, s.nota);
end
bad = chk(~[chk.ok]);
if isempty(bad), fprintf('\nRestricciones de altitud/IAS: todas cumplidas en %d fijos.\n', numel(chk));
else, fprintf('\nRESTRICCIONES NO CUMPLIDAS:\n'); for i = 1:numel(bad), disp(bad(i)); end; end

% --- Fuel study: 2 cruise speeds x 2 cruise altitudes --------------------------
cases = {P.h_cruise, 'MRC'; P.h_cruise, 'LRC'; 31000, 'MRC'; 31000, 'LRC'};
T = table();
for i = 1:size(cases,1)
    Q = P; Q.h_cruise = cases{i,1};
    Q.hcross_clb = CrossOverAltitude(Q.cas_clb, Q.M_clb, Q.h_cruise); Q.hcross_des = CrossOverAltitude(Q.cas_des, Q.M_des, Q.h_cruise);
    Ci = cruise_speeds(ac, Q.h_cruise, m_cru);
    if strcmp(cases{i,2}, 'MRC'), Q.M_cruise = Ci.M_mrc; else, Q.M_cruise = Ci.M_lrc; end
    [~, ~, Ri] = build_profile(ac, Q);
    T = [T; table(Q.h_cruise, string(cases{i,2}), Q.M_cruise, Ri.r_toc, Ri.r_tod, Ri.r_tod - Ri.r_toc, ...
         Ri.fuel_climb, Ri.fuel_cruise, Ri.fuel_descent, Ri.fuel_total, Ri.t_total/3600, ...
         'VariableNames', {'h_crucero_ft','velocidad','Mach','TOC_NM','TOD_NM','crucero_NM','fuel_ascenso_kg','fuel_crucero_kg','fuel_descenso_kg','fuel_total_kg','tiempo_h'})]; %#ok<AGROW>
end
writetable(T, fullfile(out,'VERTICAL-consumo.xlsx'));
fprintf('\nConsumo por velocidad y altitud de crucero:\n'); disp(T);
