function wp = apply_chart_limits(wp, altMaxDefault, iasMaxDefault)
% Altitude/speed limits taken only from the chart (no climb gradient),
% used for arrivals and approaches. Altitude min/max come from the chart
% (an "@" limit is given as min = max); missing max altitude = altMaxDefault;
% IAS max = chart value, else 250 kt below 10000 ft, else iasMaxDefault.
% Input:  wp (alt_chart, alt_max_chart, ias_chart), defaults in ft / kt
% Output: wp with alt_min, alt_max, ias_min, ias_max
for i = 1:numel(wp)
    wp(i).alt_min = wp(i).alt_chart; if isnan(wp(i).alt_min), wp(i).alt_min = 0; end
    wp(i).alt_max = wp(i).alt_max_chart; if isnan(wp(i).alt_max), wp(i).alt_max = altMaxDefault; end
    wp(i).ias_min = 0;
    if ~isnan(wp(i).ias_chart),   wp(i).ias_max = wp(i).ias_chart;
    elseif wp(i).alt_min < 10000 && ~(isnan(wp(i).alt_chart) && wp(i).alt_max_chart >= 10000)
        wp(i).ias_max = 250;   % (fix with no min altitude but max >= FL100, e.g. ZUKKO, is not limited)
    else,                         wp(i).ias_max = iasMaxDefault; end
end
end
