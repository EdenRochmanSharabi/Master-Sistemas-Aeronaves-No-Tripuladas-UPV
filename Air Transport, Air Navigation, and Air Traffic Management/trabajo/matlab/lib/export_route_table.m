function export_route_table(file, wp, w0)
% Writes the route table (course Excel format, Figure 2) to sheet 'Ruta' of file.xlsx.
% Input:  file = name without extension, wp = struct array; optional w0 = the
%         no-wind route: wp is then the wind case and sheet 'Comparación' is added
DEC_COORD = 6; DEC_ANGLE = 1; DEC_NM = 2;
m2NM = 1/1852;
xlsx = [file '.xlsx'];
if isfile(xlsx), delete(xlsx); end
hdr = {'Número','Nombre','Latitud (°)','Longitud (°)','Altitud mínima (ft)','Altitud máxima (ft)', ...
       'Derrota (°)','Distancia (NM)','Distancia total (NM)','Dirección del viento (°)', ...
       'Velocidad del viento (kt)','GS (kt)','Tiempo total (s)'};
c = [hdr; cell(numel(wp), numel(hdr))];
for i = 1:numel(wp)
    c(i+1,:) = {i, wp(i).name, round(wp(i).lat, DEC_COORD), round(wp(i).lon, DEC_COORD), ...
        wp(i).alt_min, wp(i).alt_max, round(wp(i).track, DEC_ANGLE), ...
        round(wp(i).dist*m2NM, DEC_NM), round(wp(i).Total_dist*m2NM, DEC_NM), ...
        round(wp(i).wdir), round(wp(i).wind), round(wp(i).GS), round(wp(i).time)};
end
writecell(c, xlsx, 'Sheet', 'Ruta');
if nargin == 3, write_comparison(xlsx, w0, wp); end
end

function write_comparison(xlsx, w0, w1)
% Sheet 'Comparación': no-wind vs wind case (fields of route_time_wind), fix by fix.
DEC_COORD = 6; DEC_ANGLE = 1; DEC_NM = 2;
m2NM = 1/1852;
hdr = {'Fijo','Distancia total sin viento (NM)','Tiempo sin viento (s)','Rumbo (°)', ...
       'Derrota real (°)','GS (kt)','Latitud real (°)','Longitud real (°)','Desviación (NM)', ...
       'Distancia total con viento (NM)','Tiempo con viento d/TAS (s)','Tiempo con viento d/GS (s)'};
c = [hdr; cell(numel(w1), numel(hdr))];
for i = 1:numel(w1)
    c(i+1,:) = {w1(i).name, round(w0(i).Total_dist*m2NM, DEC_NM), round(w0(i).time), ...
        round(w1(i).head, DEC_ANGLE), round(w1(i).track, DEC_ANGLE), round(w1(i).GS), ...
        round(w1(i).lat_real, DEC_COORD), round(w1(i).lon_real, DEC_COORD), ...
        round(w1(i).dev_m*m2NM, DEC_NM), round(w1(i).Total_dist*m2NM, DEC_NM), ...
        round(w1(i).time), round(w1(i).time_gs)};
end
writecell(c, xlsx, 'Sheet', 'Comparación');
end
