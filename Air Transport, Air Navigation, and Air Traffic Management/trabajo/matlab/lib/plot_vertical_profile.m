function plot_vertical_profile(tr, F, R, dPhase, file1, file2)
% Plots the vertical profile: (1) altitude vs distance for each phase (SID,
% en-route, arrival+approach) with the minimum / maximum altitudes of the
% horizontal study; (2) whole route: altitude, speeds, thrust ratio and
% vertical speed.
% Input:  tr = trace (SI); F = fixes (d NM, alt_min, alt_max); R = results
%         (r_toc, r_tod); dPhase = [d end of SID, d end of en-route] (NM);
%         file1, file2 = output PNG files
M2FT = 1/0.3048; M2NM = 1/1852; MPS2KTS = 3600/1852; MPS2FPM = 60/0.3048;
X_PAD_FRAC = 0.02; Y_HEADROOM = 1.15; MACH_COLOR = [0 0.6 0];
XLBL = 'Distancia desde el DER 36R (NM)';
r = tr.r*M2NM; h = tr.h*M2FT; d = [F.d];
lim = [0, dPhase, max(d)]; ttl = {'Salida (SID NANDO3R)', 'En-ruta (NANDO - ZUKKO)', 'Llegada ERREZ1A + ILS 21'};
f = figure('Visible', 'off', 'Theme', 'light', 'Position', [0 0 950 900]);
t = tiledlayout(f, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:3
    ax = nexttile(t); hold on; grid on; ax.YAxis.Exponent = 0;
    x = [lim(k), lim(k+1)] + [-1 1]*X_PAD_FRAC*(lim(k+1) - lim(k));
    s = r >= x(1) & r <= x(2); j = d >= lim(k) - 1e-6 & d <= lim(k+1) + 1e-6;
    hp = plot(r(s), h(s), 'b-', 'LineWidth', 1.6);
    hl = plot_fix_limits(d(j), [F(j).alt_min], [F(j).alt_max], {F(j).name});
    mark_toc_tod(R);
    xlim(x); ylim([0, Y_HEADROOM*max([max(h(s)), hl(1).YData, hl(2).YData])]); title(ttl{k});
end
xlabel(t, XLBL); ylabel(t, 'Altitud (ft)');
lg = legend(ax, [hp, hl], 'Perfil BADA', 'Altitud mínima', 'Altitud máxima', 'Orientation', 'horizontal');
title(lg, 'Sin marca = sin límite en la carta', 'FontWeight', 'normal'); lg.Layout.Tile = 'south';
exportgraphics(f, file1, 'Resolution', 150, 'BackgroundColor', 'white'); close(f);

f = figure('Visible', 'off', 'Theme', 'light', 'Position', [0 0 950 950]);
t = tiledlayout(f, 4, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(t); plot(r, h, 'b-', 'LineWidth', 1.5); grid on; hold on; ax.YAxis.Exponent = 0;
mark_toc_tod(R); ylim([0, Y_HEADROOM*max(h)]); ylabel('Altitud (ft)');
title(t, 'Perfil vertical LEMD 36R - LLBG 21 (B738, BADA 3.14)');
ax(2) = nexttile(t); plot(r, tr.cas*MPS2KTS, 'b-', r, tr.V*MPS2KTS, 'r-', 'LineWidth', 1.2); grid on;
yyaxis right; plot(r, tr.M, 'Color', MACH_COLOR, 'LineWidth', 1.2); ylim([0 1]); ylabel('Mach');
ax(2).YAxis(2).Color = MACH_COLOR; yyaxis left; ylabel('Velocidad (kt)');
legend('IAS (CAS)', 'TAS', 'Mach', 'Location', 'northoutside', 'Orientation', 'horizontal');
ax(3) = nexttile(t); plot(r, 100*tr.Tr, 'b-', 'LineWidth', 1.2); grid on; ylabel('Empuje T/T_{max} (%)'); ylim([0, 100*Y_HEADROOM]);
ax(4) = nexttile(t); plot(r, tr.hdot*MPS2FPM, 'r-', 'LineWidth', 1.2); grid on; ylabel('Vel. vertical (fpm)');
linkaxes(ax, 'x'); xlim(ax(1), [0, max(r)]); xlabel(t, XLBL);
exportgraphics(f, file2, 'Resolution', 150, 'BackgroundColor', 'white'); close(f);
end

function mark_toc_tod(R)
xline(R.r_toc, 'k:', 'TOC', 'LabelVerticalAlignment', 'middle', 'LabelHorizontalAlignment', 'right', 'HandleVisibility', 'off');
xline(R.r_tod, 'k:', 'TOD', 'LabelVerticalAlignment', 'middle', 'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
end
