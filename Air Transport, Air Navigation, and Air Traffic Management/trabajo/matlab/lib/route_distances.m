function wp = route_distances(wp)
% Fills track, dist and Total_dist for every fix. Convention (as in the
% course Excel table): each fix holds the data of the leg ARRIVING at it.
% Input:  wp = struct array with lat/lon
% Output: wp with track (deg), dist (m) and Total_dist (m)
wp(1).track = 0; wp(1).dist = 0; wp(1).Total_dist = 0;
for i = 2:numel(wp)
    [s, az] = orto_distazi(wp(i-1).lat, wp(i-1).lon, wp(i).lat, wp(i).lon);
    wp(i).track = az;
    wp(i).dist = s;
    wp(i).Total_dist = wp(i-1).Total_dist + s;
end
end
