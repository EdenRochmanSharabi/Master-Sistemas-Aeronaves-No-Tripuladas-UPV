function plot_enroute_map(w0, w1, detailTo, pngfile)
% Map of the planned fixes and of the real positions reached with wind, with
% a separate detail panel from the first fix to detailTo.
% Input:  w0 = planned route (name, lat, lon); w1 = wind case (lat_real,
%         lon_real); detailTo = name of the last fix of the detail panel
MAP_PAD_DEG = 2; DETAIL_PAD_DEG = 0.15;
iDet = 1:find(strcmp({w0.name}, detailTo), 1);
lat = [w0.lat]; lon = [w0.lon];
f = figure('Visible', 'off', 'Theme', 'light', 'Position', [0 0 1150 480]);
t = tiledlayout(f, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(t, [1 2]); h = draw(ax, w0, w1, setdiff(1:numel(w0), iDet), 0.18);
xlim(ax, [min(lon), max(lon)] + [-1 1]*MAP_PAD_DEG); ylim(ax, [min(lat), max(lat)] + [-1 1]*MAP_PAD_DEG);
det = [min(lon(iDet)), min(lat(iDet)), max(lon(iDet)), max(lat(iDet))] + [-1 -1 1 1]*DETAIL_PAD_DEG;
rectangle(ax, 'Position', [det(1:2), det(3:4) - det(1:2)], 'EdgeColor', [0.4 0.4 0.4]);
text(ax, det(1), det(4), 'detalle', 'FontSize', 9, 'VerticalAlignment', 'bottom');
xlabel(ax, 'Longitud (°)'); ylabel(ax, 'Latitud (°)'); title(ax, ['Ruta ', w0(1).name, ' - ', w0(end).name]);
legend(ax, h, 'Ruta planificada (fijos)', 'Posiciones reales con viento (computeWT)', 'Location', 'southwest');
ai = nexttile(t); draw(ai, w0, w1, iDet, 0.03);
xlim(ai, det([1 3])); ylim(ai, det([2 4]));
xlabel(ai, 'Longitud (°)'); title(ai, ['Detalle ', w0(1).name, ' - ', detailTo]);
exportgraphics(f, pngfile, 'Resolution', 150, 'BackgroundColor', 'white'); close(f);
end

function h = draw(ax, w0, w1, labelled, dy)
VALIGN = {'top', 'bottom'};
hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on'); set(ax, 'FontSize', 10);
h = [plot(ax, [w0.lon], [w0.lat], 'b-o', 'LineWidth', 1.8, 'MarkerSize', 5, 'MarkerFaceColor', 'b'), ...
     plot(ax, [w1.lon_real], [w1.lat_real], 'r--x', 'LineWidth', 1.0, 'MarkerSize', 7)];
for i = labelled
    up = mod(i, 2) == 1; s = 2*up - 1;
    text(ax, w0(i).lon, w0(i).lat + s*dy, w0(i).name, 'FontSize', 9, 'Rotation', s*55, ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', VALIGN{up + 1});
end
end
