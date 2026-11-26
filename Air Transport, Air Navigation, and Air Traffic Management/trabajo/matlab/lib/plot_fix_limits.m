function h = plot_fix_limits(d, amin, amax, names)
% Draws the minimum / maximum altitude of each fix on the current axes and
% labels the fixes. Chart "no limit" values (minimum 0 ft, maximum 40000 ft,
% the defaults of apply_chart_limits / the main_* scripts) are not drawn.
% Input:  d (NM), amin, amax (ft), names (cell array of fix names)
% Output: h = [minimum line, maximum line] for the legend
NO_MIN_FT = 0; NO_MAX_FT = 40000;
CROWD_FRAC = 0.03;                     % fixes closer than this share of the x range alternate labels
LABEL_ROT = 60; LABEL_FONT = 8;
amin(amin <= NO_MIN_FT) = NaN; amax(amax >= NO_MAX_FT) = NaN;
h = [plot(d, amin, '-o',  'Color', [0 0.6 0],   'LineWidth', 1.5), ...
     plot(d, amax, '--s', 'Color', [0.85 0 0], 'LineWidth', 1.5)];
y = amax; y(isnan(y)) = amin(isnan(y));
crowd = CROWD_FRAC * (max(d) - min(d)); up = false; last = -Inf;
for i = find(~isnan(y))
    up = d(i) - last >= crowd || ~up; last = d(i);
    if up, text(d(i), y(i), [' ' names{i}], 'FontSize', LABEL_FONT, 'Rotation', LABEL_ROT, 'VerticalAlignment', 'bottom');
    else,  text(d(i), y(i), [' ' names{i}], 'FontSize', LABEL_FONT, 'Rotation', -LABEL_ROT, 'VerticalAlignment', 'top'); end
end
end
