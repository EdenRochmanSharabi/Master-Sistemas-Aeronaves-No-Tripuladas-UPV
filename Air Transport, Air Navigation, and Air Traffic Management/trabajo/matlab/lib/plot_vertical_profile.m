function plot_vertical_profile(tr, F, R, dPhase, file1, file2)
% Plots the vertical profile: (1) altitude vs distance for each phase (SID,
% en-route, arrival+approach) with the minimum / maximum altitudes of the
% horizontal study; (2) whole route: altitude, speeds and thrust ratio.
% Input:  tr = trace (SI); F = fixes (d NM, alt_min, alt_max); R = results
%         (r_toc, r_tod); dPhase = [d end of SID, d end of en-route] (NM);
%         file1, file2 = output PNG files
M2FT = 1/0.3048; M2NM = 1/1852; MPS2KTS = 3600/1852;
r = tr.r*M2NM; h = tr.h*M2FT; d = [F.d]; amin = [F.alt_min]; amax = [F.alt_max];
amax(amax >= 40000) = NaN;                        % "no limit" is not drawn
lim = [0, dPhase, max(d)]; ttl = {'Salida (SID NANDO3R)', 'En-ruta (NANDO - ZUKKO)', 'Llegada ERREZ1A + ILS 21'};
f = figure('Visible', 'off', 'Theme', 'light', 'Position', [0 0 1100 900]);
for k = 1:3
    subplot(3,1,k); hold on; grid on;
    s = r >= lim(k) - 1e-6 & r <= lim(k+1) + 1e-6; j = d >= lim(k) - 1e-6 & d <= lim(k+1) + 1e-6;
    plot(r(s), h(s), 'b-', 'LineWidth', 1.6);
    plot(d(j), amin(j), 'g-o', 'LineWidth', 1); plot(d(j), amax(j), 'r--s', 'LineWidth', 1);
    text(d(j), amin(j), strcat({' '}, {F(j).name}), 'FontSize', 6, 'Rotation', 60);
    for q = [R.r_toc, R.r_tod]
        if q >= lim(k) && q <= lim(k+1), xline(q, 'k:'); end
    end
    xlim([lim(k) lim(k+1)]); xlabel('Distancia desde el DER 36R (NM)'); ylabel('Altitud (ft)');
    title(ttl{k}); legend('Perfil BADA', 'Altitud mínima', 'Altitud máxima', 'Location', 'best');
end
exportgraphics(f, file1, 'Resolution', 150, 'BackgroundColor', 'white'); close(f);

f = figure('Visible', 'off', 'Theme', 'light', 'Position', [0 0 1100 900]);
subplot(3,1,1); plot(r, h, 'b-', 'LineWidth', 1.5); grid on; hold on;
xline(R.r_toc, 'k:', 'TOC'); xline(R.r_tod, 'k:', 'TOD'); ylabel('Altitud (ft)'); title('Perfil vertical LEMD 36R - LLBG 21 (B738, BADA 3.14)');
subplot(3,1,2); plot(r, tr.cas*MPS2KTS, 'b-', r, tr.V*MPS2KTS, 'r-', 'LineWidth', 1.2); grid on; hold on;
yyaxis right; plot(r, tr.M, 'g-'); ylabel('Mach'); yyaxis left; ylabel('Velocidad (kt)'); legend('IAS (CAS)', 'TAS', 'Mach', 'Location', 'best');
subplot(3,1,3); plot(r, 100*tr.Tr, 'b-', 'LineWidth', 1.2); grid on; hold on; ylabel('Tr = T/Tmax (%)');
yyaxis right; plot(r, tr.hdot/0.00508, 'r-'); ylabel('Velocidad vertical (fpm)'); xlabel('Distancia desde el DER 36R (NM)');
legend('Empuje relativo', 'VS', 'Location', 'best');
exportgraphics(f, file2, 'Resolution', 150, 'BackgroundColor', 'white'); close(f);
end
