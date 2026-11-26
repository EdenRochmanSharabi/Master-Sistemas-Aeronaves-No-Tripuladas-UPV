function plot_vertical_limits(wp, ttl, pngfile)
% Distance/altitude plot of the minimum and maximum altitude at each fix.
% Input: wp (alt_min, alt_max, Total_dist in m), ttl = title, pngfile = output
f = figure('Visible','off', 'Theme','light'); hold on; grid on;
h = plot_fix_limits([wp.Total_dist] / 1852, [wp.alt_min], [wp.alt_max], {wp.name});
ylim([0, 1.15*max([h.YData])]);
xlabel('Distancia (NM)'); ylabel('Altitud (ft)'); title(ttl);
lg = legend(h, 'Altitud mínima', 'Altitud máxima', 'Location', 'southoutside', 'Orientation', 'horizontal');
title(lg, 'Sin marca = sin límite en la carta', 'FontWeight', 'normal');
exportgraphics(f, pngfile, 'Resolution', 150, 'BackgroundColor', 'white'); close(f);
end
