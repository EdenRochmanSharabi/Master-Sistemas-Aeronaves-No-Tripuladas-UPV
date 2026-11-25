function wp = apply_restrictions(wp, elev_ft, grad, lastGradFix, altMaxDefault, iasMaxDefault)
% Computes minimum/maximum altitude and IAS limits at every fix.
%  - alt_min = max(chart "at or above" limit, minimum-gradient altitude).
%    The gradient (fraction, e.g. 0.055) is applied from the first fix up to
%    lastGradFix; after it the previous minimum is held.
%  - alt_max = altMaxDefault when the chart gives none.
%  - ias_max = chart limit if any, else 250 kt below 10000 ft (else default).
% Input:  wp (with Total_dist in m and alt_chart/ias_chart), elev_ft = start
%         elevation (ft), grad, lastGradFix = name of the last fix with
%         gradient, altMaxDefault (ft), iasMaxDefault (kt)
% Output: wp with alt_min, alt_max, ias_min, ias_max, slope
m2ft = 1/0.3048;
iLast = find(strcmp({wp.name}, lastGradFix), 1);
for i = 1:numel(wp)
    if i <= iLast
        gradAlt = elev_ft + grad * wp(i).Total_dist * m2ft;
    else
        gradAlt = wp(i-1).alt_min;
    end
    c = wp(i).alt_chart; if isnan(c), c = 0; end
    wp(i).alt_min = round(max([gradAlt, c]));
    wp(i).alt_max = altMaxDefault;
    if ~isnan(wp(i).alt_max_chart), wp(i).alt_max = wp(i).alt_max_chart; end
    wp(i).ias_min = 0;
    if ~isnan(wp(i).ias_chart)
        wp(i).ias_max = wp(i).ias_chart;
    elseif wp(i).alt_min < 10000
        wp(i).ias_max = 250;
    else
        wp(i).ias_max = iasMaxDefault;
    end
    if i > 1 && wp(i).dist > 0
        wp(i).slope = (wp(i).alt_min - wp(i-1).alt_min) / (wp(i).dist*m2ft) * 100;
    end
end
end
