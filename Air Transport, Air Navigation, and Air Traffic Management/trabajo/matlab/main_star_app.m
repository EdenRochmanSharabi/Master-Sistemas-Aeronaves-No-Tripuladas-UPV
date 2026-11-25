% MAIN_STAR_APP  Arrival ERREZ1A (ZUKKO -> TOPPU) + ILS RWY 21 at LLBG
% (AIP Israel eAIP AIRAC 001/2026: TRANS 21-26 of 18 MAY 23, IAC-21ILS-4 of 31 OCT 24).
clear; clc;
here = fileparts(mfilename('fullpath'));
lib  = fullfile(here, '..', 'Bada-matlab-Fatzip');
addpath(fullfile(here,'lib'), fullfile(lib,'kgbx-lib','geo'), fullfile(lib,'kgbx-lib','kml'));
out = fullfile(here,'out');

% name, lat, lon, "at or above" alt (ft), max IAS (kt), description, max alt (ft)
% "@9000" in the chart is min = max = 9000; "-13000" is max only.
P = { ...
 'ZUKKO', '323342N',   '0335657E',   NaN,   NaN, 'IF, ERREZ1A start (max 13000)', 13000; ...
 'KONFO', '322542N',   '0340656E',   10000, NaN, 'TF 133.4T (10000-11000)',      11000; ...
 'ERREZ', '323301.1N', '0343259.9E', 9000,  NaN, 'TF 071.5T, left turn (@9000)', 9000; ...
 'IVONA', '323604.3N', '0344400.0E', 9000,  NaN, 'TF 071.8T (@9000)',            9000; ...
 'RAPIV', '323512N',   '0345554E',   9000,  NaN, 'TF 094.9T, right turn (@9000)',9000; ...
 'ALIQA', '323449.8N', '0350148.1E', 9000,  250, 'TF 094.9T (@9000, max 250)',   9000; ...
 'LEGOH', '323353.1N', '0351520.5E', 9000,  250, 'TF 094.9T (@9000, max 250)',   9000; ...
 'ANOZA', '321750.95N','0350452.30E',5000,  250, 'TF 209.0T, right turn (min 5000)', NaN; ...
 'TOPPU', '321507.8N', '0350306.5E', 4000,  250, 'TF 209.0T (min 4000); then ATC / comm failure: direct GALGA', NaN; ...
 'GALGA', '320925N',   '0345924E',   2600,  NaN, 'IF ILS 21 (min 2600)',         NaN; ...
 'BG074', '320736.81N','0345813.95E',2600,  NaN, 'FAP ILS 21 (7.4 DME BN)',      NaN; ...
 'THR21', '320105.25N','0345400.81E',183,   NaN, 'RWY 21 threshold',             NaN};
wp = build_procedure(P);
wp = route_distances(wp);                 % distance flown along the whole path
wpCum = wp;                               % keep "flown" distance for the plots
wp = to_remaining_dist(wp);               % tables: distance remaining to THR21
wp = apply_chart_limits(wp, 40000, 350);

iT = find(strcmp({wp.name},'TOPPU')); iG = find(strcmp({wp.name},'GALGA'));
wp_llegada = wp(1:iT);                    % STAR/transition phase
wp_apr     = wp(iT:end);                  % approach phase (from TOPPU)
cum = wpCum; for i=1:numel(cum), cum(i).alt_min = wp(i).alt_min; cum(i).alt_max = wp(i).alt_max; end

% --- Missed approach (chart): CA 204 to 1000 ft, DF GEMDA @5000, max 190 ----
M = {'THR21','320105.25N','0345400.81E',183,NaN,'MAPt',NaN; ...
     'GEMDA','320326N','0345948E',5000,190,'DF, missed approach, @5000',5000};
wp_missed = route_distances(apply_chart_limits(build_procedure(M),40000,350));

% --- Outputs ------------------------------------------------------------------
attr = create_attr();
attr.label = 'LEMD-LLBG llegada ERREZ1A';   kmlwrite_polyline(wp_llegada, fullfile(out,'LEMD-LLBG-llegada.kml'), attr);
attr.label = 'LLBG ILS 21 aproximacion';    kmlwrite_polyline(wp_apr,     fullfile(out,'LEMD-LLBG-apr-ILS21.kml'), attr);
attr.label = 'LLBG ILS 21 frustrada';       kmlwrite_polyline(wp_missed,  fullfile(out,'LEMD-LLBG-frustrada-ILS21.kml'), attr);
export_proc_table(fullfile(out,'LLEGADA-ERREZ1A'), wp_llegada, 'Distancia restante a THR21 (NM)');
export_proc_table(fullfile(out,'APR-ILS21'),       wp_apr,     'Distancia restante a THR21 (NM)');
export_proc_table(fullfile(out,'FRUSTRADA-ILS21'), wp_missed,  'Distancia total desde THR21 (NM)');
plot_vertical_limits(cum(1:iT),  'Llegada ERREZ1A - perfil vertical mín./máx.', fullfile(out,'LLEGADA-vertical.png'));
plot_vertical_limits(cum(iT:end),'ILS 21 - perfil vertical mín./máx.',          fullfile(out,'APR-ILS21-vertical.png'));

fprintf('Total ZUKKO->THR21: %.1f NM | llegada %.1f NM\n', wpCum(end).Total_dist/1852, wpCum(iT).Total_dist/1852);
for i=1:numel(wp), fprintf('%-6s trk %6.1f  d %5.1f NM  rest %5.1f  alt %5d-%5d  IAS<=%d\n', ...
   wp(i).name, wp(i).track, wp(i).dist/1852, wp(i).Total_dist/1852, wp(i).alt_min, wp(i).alt_max, wp(i).ias_max); end
fprintf('Frustrada THR21->GEMDA: %.1f NM\n', wp_missed(2).dist/1852);

% ============================ RNP Y RWY 21 (non-precision) ===================
% Link TOPPU -> GINTU (IAF) is NOT published: ATC instructions are assumed.
% Source: IAC 21RNPY-3 (AIRAC AMDT 001/2026). BG217 -> BG216 is an RF arc.
cLat = dms2deg('320504.6N'); cLon = dms2deg('0345310.0E'); rArc = 2.55;   % centre BG999
[~, bA] = orto_distazi(cLat, cLon, dms2deg('320503.8N'), dms2deg('0345610.0E'));   % centre -> BG217
[~, bB] = orto_distazi(cLat, cLon, dms2deg('320350.7N'), dms2deg('0345547.7E'));   % centre -> BG216
ARC = add_arc_points(cLat, cLon, rArc, bA, bB, true, 10, 'ARC', 1200, 185);
PR = [ P(strcmp(P(:,1),'TOPPU'),:); ...
 {'GINTU', '320448N',   '0350958E',   6000, NaN, 'IAF RNP Y 21 (link from TOPPU by ATC, assumed)', NaN; ...
  'RABIN', '320732N',   '0350721E',   4000, NaN, 'TF 320.8T',                 NaN; ...
  'OFFIK', '321131.5N', '0350048.2E', 3500, NaN, 'TF 305.7T',                 NaN; ...
  'VATAT', '321300.0N', '0345613.0E', 3500, 210, 'TF 290.7T',                 NaN; ...
  'NAMIM', '320915N',   '0345609E',   2500, 185, 'IF, TF 180.9T',             NaN; ...
  'BG217', '320503.8N', '0345610.0E', 1200, 185, 'TF 179.5T',                 NaN}; ...
 [ARC, repmat({NaN},size(ARC,1),1)]; ...
 {'BG216', '320350.7N', '0345547.7E', 1200, 185, 'FAF, RF arc r=2.55 NM, right', NaN; ...
  'THR21', '320105.2N', '0345400.8E', 183,  190, 'MAPt, TF 208.8T',             NaN}];
wpR = build_procedure(PR);
wpR = route_distances(wpR); cumR = wpR;
wpR = to_remaining_dist(wpR);
wpR = apply_chart_limits(wpR, 40000, 350);
for i=1:numel(cumR), cumR(i).alt_min = wpR(i).alt_min; cumR(i).alt_max = wpR(i).alt_max; end

attr = create_attr(); attr.label = 'LLBG RNP Y 21 aproximacion';
kmlwrite_polyline(wpR, fullfile(out,'LEMD-LLBG-apr-RNPY21.kml'), attr);
export_proc_table(fullfile(out,'APR-RNPY21'), wpR, 'Distancia restante a THR21 (NM)');
plot_vertical_limits(cumR, 'RNP Y 21 - perfil vertical mín./máx.', fullfile(out,'APR-RNPY21-vertical.png'));
fprintf('\nRNP Y 21 desde TOPPU: %d puntos, %.1f NM (ILS 21 desde TOPPU: %.1f NM)\n', numel(wpR), cumR(end).Total_dist/1852, wp(iT).Total_dist/1852);
for i=1:numel(wpR), fprintf('%-6s trk %6.1f  d %5.2f NM  rest %5.1f  alt %5d-%5d  IAS<=%d\n', ...
   wpR(i).name, wpR(i).track, wpR(i).dist/1852, wpR(i).Total_dist/1852, wpR(i).alt_min, wpR(i).alt_max, wpR(i).ias_max); end
