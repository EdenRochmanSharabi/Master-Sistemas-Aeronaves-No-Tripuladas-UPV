% XLSX2CSV  Vuelca matlab/out/*.xlsx a memoria/csv/*.csv para gen_tablas.py.
% Anade enroute-viento-extra.csv (rumbo, desviacion, t = d/GS: mismas
% funciones que main_enroute) y simbrief.csv (datos del plan LIDO).
here = fileparts(mfilename('fullpath')); root = fullfile(here, '..');
mat = fullfile(root, 'matlab'); lib = fullfile(root, 'Bada-matlab-Fatzip');
addpath(fullfile(mat,'lib'), fullfile(lib,'kgbx-lib','geo'), fullfile(lib,'kgbx-lib','kml'), ...
        fullfile(mat,'lib','xml2struct_r2026'), fullfile(lib,'simbrief-flightplan-example'));
o = fullfile(here, 'csv'); if ~exist(o, 'dir'), mkdir(o); end

f = dir(fullfile(mat, 'out', '*.xlsx'));
for i = 1:numel(f)
    c = readcell(fullfile(f(i).folder, f(i).name));
    m = cellfun(@(v) ~ischar(v) && ~isstring(v) && ~isnumeric(v) && ~islogical(v), c); c(m) = {''};
    [~, n] = fileparts(f(i).name);
    writecell(c, fullfile(o, [n '.csv']), 'QuoteStrings', true);
end

xml = fullfile(root, 'simbrief', 'LEMDLLBG_XML_1793965869.xml');
wp = route_distances(read_enroute_wp(xml, 'NANDO', 'ZUKKO'));
w1 = route_time_wind(wp, 450);
c = {'Nombre','Rumbo','Derrota_real','GS','WCA_equiv','Lat_real','Lon_real','Desv_NM','t_dTAS_s','t_dGS_s'};
for i = 1:numel(w1)
    c(end+1,:) = {w1(i).name, w1(i).head, w1(i).track, w1(i).GS, w1(i).track - w1(i).head, ...
                  w1(i).lat_real, w1(i).lon_real, w1(i).dev_m/1852, w1(i).time, w1(i).time_gs}; %#ok<SAGROW>
end
writecell(c, fullfile(o, 'enroute-viento-extra.csv'), 'QuoteStrings', true);

fp = xml2struct(xml); g = fp.OFP.general; w = fp.OFP.weights; fu = fp.OFP.fuel; t = fp.OFP.times;
c = {'airac', fp.OFP.params.airac.Text; 'route', g.route.Text; 'costindex', g.costindex.Text; ...
     'stepclimb_string', g.stepclimb_string.Text; 'route_distance', g.route_distance.Text; ...
     'cruise_mach', g.cruise_mach.Text; 'cruise_tas', g.cruise_tas.Text; 'passengers', g.passengers.Text; ...
     'est_tow', w.est_tow.Text; 'est_ldw', w.est_ldw.Text; 'max_tow', w.max_tow.Text; 'max_zfw', w.max_zfw.Text; ...
     'enroute_burn', fu.enroute_burn.Text; 'est_time_enroute', t.est_time_enroute.Text};
writecell([c(:,1)'; c(:,2)'], fullfile(o, 'simbrief.csv'), 'QuoteStrings', true);
disp(c');
