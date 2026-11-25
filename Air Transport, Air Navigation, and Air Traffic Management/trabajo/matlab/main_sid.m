% MAIN_SID  Departure LEMD RWY 36R, RNAV SID NANDO3R (AIP Espana SID 7, 30-OCT-25).
clear; clc;
here = fileparts(mfilename('fullpath'));
lib  = fullfile(here, '..', 'Bada-matlab-Fatzip');
addpath(fullfile(here,'lib'), fullfile(lib,'kgbx-lib','geo'), fullfile(lib,'kgbx-lib','kml'));
out = fullfile(here,'out');

% --- Procedure data, read from the official chart ---------------------------
% name, lat, lon, "at or above" altitude (ft), max IAS (kt), description
P = { ...
 'DER36R', '403157.44N', '0033333.77W', NaN,   NaN, 'End of RWY 36R (AD 2 LEMD)'; ...
 'CA2500', '403157.44N', '0033333.77W', 2500,  NaN, 'CA leg 360 to 2500 ft (position computed, see below)'; ...
 'MD047',  '403537.1N',  '0033217.6W',  3000,  210, 'CF 015.3'; ...
 'MD048',  '404513.2N',  '0032133.3W',  7000,  220, 'TF 040.4'; ...
 'MD049',  '404212.4N',  '0031619.9W',  8000,  NaN, 'TF 127.1'; ...
 'MD824',  '402410.7N',  '0030649.4W',  13000, 240, 'TF 158.0 (end of 5.5% min gradient)'; ...
 'MD922',  '400758.5N',  '0024825.3W',  13000, NaN, 'TF 138.9'; ...
 'NANDO',  '395919.9N',  '0021028.4W',  13000, NaN, 'TF 106.3, fly-over'};
GRAD = 0.055; ELEV = 1998;   % min climb gradient 5.5% (chart); ARP elevation ft (AD 2 LEMD)
wp = build_procedure(P);

% --- CA leg: climb on heading 360 until 2500 ft at the minimum gradient -----
dCA = (2500 - ELEV) / GRAD * 0.3048;               % metres from DER
[wp(2).lat, wp(2).lon] = orto_reckon(wp(1).lat, wp(1).lon, dCA, 360);

wp = route_distances(wp);
wp = apply_restrictions(wp, ELEV, GRAD, 'MD824', 40000, 350);

% --- Outputs ---------------------------------------------------------------
attr = create_attr(); attr.label = 'NANDO3R';
kmlwrite_polyline(wp, fullfile(out,'SID-NANDO3R.kml'), attr);
export_proc_table(fullfile(out,'SID-NANDO3R'), wp, 'Distancia total (NM)');
plot_vertical_limits(wp, 'SID NANDO3R - perfil vertical mínimo/máximo', fullfile(out,'SID-NANDO3R-vertical.png'));
fprintf('SID NANDO3R: %d puntos, %.1f NM\n', numel(wp), wp(end).Total_dist/1852);
for i=1:numel(wp), fprintf('%-7s trk %5.1f  d %5.1f NM  tot %5.1f  alt %5d-%d  IAS<=%d\n', ...
   wp(i).name, wp(i).track, wp(i).dist/1852, wp(i).Total_dist/1852, wp(i).alt_min, wp(i).alt_max, wp(i).ias_max); end
