function wp = build_procedure(P)
% Builds a waypoint struct array from a procedure table.
% Input:  P = cell array, one row per point:
%         {name, 'latStr', 'lonStr', altMinChart, iasMaxChart, description [, altMaxChart]}
%         altMinChart / iasMaxChart / altMaxChart = NaN when the chart gives no limit
% Output: wp = struct array with name, lat, lon, desc and chart limits
for i = 1:size(P,1)
    w = create_wp();
    w.name = P{i,1};
    if isnumeric(P{i,2}), w.lat = P{i,2}; w.lon = P{i,3};   % already decimal degrees
    else, w.lat = dms2deg(P{i,2}); w.lon = dms2deg(P{i,3}); end
    w.desc = P{i,6};
    w.alt_chart = P{i,4}; w.ias_chart = P{i,5}; w.alt_max_chart = NaN;
    if size(P,2) >= 7, w.alt_max_chart = P{i,7}; end
    w.alt_min = 0; w.alt_max = 0; w.ias_min = 0; w.ias_max = 0;
    w.slope = NaN; w.Total_dist = 0; w.GS = 0;
    wp(i) = w; %#ok<AGROW>
end
end
