function export_proc_table(file, wp, distLabel)
% Writes a procedure table (SID/STAR/approach) to file.xlsx.
% Input: file = name w/o extension, wp = struct array,
%        distLabel = 'Distancia total (NM)' (SID) or 'Distancia restante (NM)'
m2NM = 1/1852;
hdr = {'Numero','Nombre','Latitud','Longitud','Altitud minima (ft)','Altitud maxima (ft)', ...
       'IAS minima (kt)','IAS maxima (kt)','Derrota','Distancia (NM)', distLabel, ...
       'Pendiente min (%)','Descripcion'};
c = [hdr; cell(numel(wp), numel(hdr))];
for i = 1:numel(wp)
    c(i+1,:) = {i, wp(i).name, wp(i).lat, wp(i).lon, wp(i).alt_min, wp(i).alt_max, ...
        wp(i).ias_min, wp(i).ias_max, wp(i).track, wp(i).dist*m2NM, ...
        wp(i).Total_dist*m2NM, wp(i).slope, wp(i).desc};
end
writecell(c, [file '.xlsx']);
end
