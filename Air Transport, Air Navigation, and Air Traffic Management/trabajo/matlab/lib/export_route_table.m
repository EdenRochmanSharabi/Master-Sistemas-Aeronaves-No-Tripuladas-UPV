function export_route_table(file, wp)
% Writes the route table (course Excel format, Figure 2) to file.xlsx
% Input:  file = name without extension, wp = struct array
% Columns: number, name, lat, lon, min alt, max alt, track, leg dist (NM),
%          total dist (NM), wind dir, wind speed, GS, cumulative time (s)
m2NM = 1/1852;
hdr = {'Numero','Nombre','Latitud','Longitud','Altitud minima','Altitud maxima', ...
       'Derrota','Distancia (NM)','Distancia total (NM)','Direccion viento', ...
       'Velocidad viento','GS','Tiempo total (s)'};
c = [hdr; cell(numel(wp), numel(hdr))];
for i = 1:numel(wp)
    c(i+1,:) = {i, wp(i).name, wp(i).lat, wp(i).lon, wp(i).alt_min, wp(i).alt_max, ...
        wp(i).track, wp(i).dist*m2NM, wp(i).Total_dist*m2NM, wp(i).wdir, ...
        wp(i).wind, wp(i).GS, wp(i).time};
end
writecell(c, [file '.xlsx']);
end
