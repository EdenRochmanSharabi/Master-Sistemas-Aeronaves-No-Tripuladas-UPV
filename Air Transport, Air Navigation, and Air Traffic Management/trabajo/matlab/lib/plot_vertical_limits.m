function plot_vertical_limits(wp, ttl, pngfile)
% Distance/altitude plot of the minimum and maximum altitude at each fix.
% Input: wp (alt_min, alt_max, Total_dist in m), ttl = title, pngfile = output
NO_LIMIT_FT = 40000;                              % altMaxDefault of the main_* scripts
d = [wp.Total_dist] / 1852; amin = [wp.alt_min]; amax = [wp.alt_max];
amax(amax >= NO_LIMIT_FT) = NaN;
f = figure('Visible','off', 'Theme','light'); hold on; grid on;
plot(d, amin, '-o', 'LineWidth', 1.5);
plot(d, amax, '--s', 'LineWidth', 1.5);
text(d, amin, strcat({' '}, {wp.name}), 'FontSize', 7, 'Rotation', 45);
ylim([0, 1.15*max([amin, amax])]);
xlabel('Distancia (NM)'); ylabel('Altitud (ft)'); title(ttl);
legend('Altitud mínima', 'Altitud máxima (sin marca = sin límite)', 'Location', 'best');
exportgraphics(f, pngfile, 'Resolution', 150, 'BackgroundColor', 'white'); close(f);
end
