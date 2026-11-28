function export_proc_table(file, wp, distLabel)
% Writes a procedure table (SID/STAR/approach) to file.xlsx, in a sheet named as the file.
% Input: file = name w/o extension, wp = struct array,
%        distLabel = 'Distancia total (NM)' (SID) or 'Distancia restante (NM)'
DEC_COORD = 6; DEC_ANGLE = 1; DEC_NM = 2; DEC_SLOPE = 2;
m2NM = 1/1852;
xlsx = [file '.xlsx'];
if isfile(xlsx), delete(xlsx); end
[~, sheet] = fileparts(file);
hdr = {'Número','Nombre','Latitud (°)','Longitud (°)','Altitud mínima (ft)','Altitud máxima (ft)', ...
       'IAS mínima (kt)','IAS máxima (kt)','Derrota (°)','Distancia (NM)', distLabel, ...
       'Pendiente mínima (%)','Descripción'};
c = [hdr; cell(numel(wp), numel(hdr))];
for i = 1:numel(wp)
    c(i+1,:) = {i, wp(i).name, round(wp(i).lat, DEC_COORD), round(wp(i).lon, DEC_COORD), ...
        wp(i).alt_min, wp(i).alt_max, wp(i).ias_min, wp(i).ias_max, round(wp(i).track, DEC_ANGLE), ...
        round(wp(i).dist*m2NM, DEC_NM), round(wp(i).Total_dist*m2NM, DEC_NM), ...
        round(wp(i).slope, DEC_SLOPE), wp(i).desc};
end
writecell(c, xlsx, 'Sheet', sheet);
end
