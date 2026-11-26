% MAIN_ENROUTE  En-route phase NANDO -> ZUKKO, without and with wind.
clear; clc;
here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
lib  = fullfile(root, 'Bada-matlab-Fatzip');
addpath(fullfile(here,'lib'), fullfile(lib,'kgbx-lib','geo'), fullfile(lib,'kgbx-lib','kml'), ...
        fullfile(here,'lib','xml2struct_r2026'), fullfile(lib,'simbrief-flightplan-example'));
out = fullfile(here,'out');
TAS = 450;   % kt, cruise speed required by the assignment

% --- Horizontal profile from the SimBrief LIDO plan -----------------------
wp = read_enroute_wp(fullfile(root,'simbrief','LEMDLLBG_XML_1793965869.xml'), 'NANDO', 'ZUKKO');
for i = 1:numel(wp)           % extra fields used by the Excel table
    wp(i).alt_min = NaN;      % TODO: ATS route limits, pending AIP check
    wp(i).alt_max = NaN;
    wp(i).time = 0; wp(i).GS = 0; wp(i).Total_dist = 0;
end
wp = route_distances(wp);

% --- Case 1: no wind -------------------------------------------------------
w0 = route_time_nowind(wp, TAS);
% --- Case 2: wind (constant heading per leg, computeWT) --------------------
w1 = route_time_wind(wp, TAS);

% --- Outputs ----------------------------------------------------------------
attr = create_attr(); attr.label = 'LEMD-LLBG en-ruta';
kmlwrite_polyline(w0, fullfile(out,'enroute-sinviento.kml'), attr);
attr.label = 'LEMD-LLBG en-ruta con viento (posiciones reales)';
wreal = w1; for i=1:numel(wreal), wreal(i).lat = w1(i).lat_real; wreal(i).lon = w1(i).lon_real; end
kmlwrite_polyline(wreal, fullfile(out,'enroute-conviento.kml'), attr);
export_route_table(fullfile(out,'enroute-sinviento'), w0);
export_route_table(fullfile(out,'enroute-conviento'), w1);
plot_enroute_map(w0, w1, 'LASPO', fullfile(out,'enroute-mapa.png'));

fprintf('Fixes: %d | Distancia planificada: %.1f NM\n', numel(wp), w0(end).Total_dist/1852);
fprintf('Sin viento : %.0f s = %.2f h\n', w0(end).time, w0(end).time/3600);
fprintf('Con viento : %.0f s = %.2f h (t=d/TAS) | %.2f h (d/GS)\n', ...
        w1(end).time, w1(end).time/3600, w1(end).time_gs/3600);
fprintf('Desviacion max en un fijo: %.2f NM\n', max([w1.dev_m])/1852);
