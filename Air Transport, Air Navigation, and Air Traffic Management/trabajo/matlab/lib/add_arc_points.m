function R = add_arc_points(cLat, cLon, r_NM, brg1, brg2, clockwise, stepDeg, prefix, altMin, iasMax)
% Auxiliary points along a circular arc (RF leg), end points excluded.
% Rows are in the build_procedure format {name,lat,lon,altMin,iasMax,desc}.
% Input:  cLat,cLon = arc centre (deg); r_NM = radius (NM);
%         brg1,brg2 = bearings centre->start and centre->end (deg);
%         clockwise = true for a right turn; stepDeg = angular step (deg);
%         prefix = point name prefix; altMin (ft) and iasMax (kt) for the points
% Output: R = cell array of rows (empty if the arc is shorter than stepDeg)
if clockwise, span = mod(brg2 - brg1, 360); sgn = 1; else, span = mod(brg1 - brg2, 360); sgn = -1; end
n = floor(span / stepDeg);
R = cell(0, 6);
for k = 1:n
    b = mod(brg1 + sgn * k * stepDeg, 360);
    [la, lo] = orto_reckon(cLat, cLon, r_NM * 1852, b);
    R(end+1,:) = {sprintf('%s%d', prefix, k), la, lo, altMin, iasMax, sprintf('RF arc aux, brg %.0f from centre', b)}; %#ok<AGROW>
end
end
