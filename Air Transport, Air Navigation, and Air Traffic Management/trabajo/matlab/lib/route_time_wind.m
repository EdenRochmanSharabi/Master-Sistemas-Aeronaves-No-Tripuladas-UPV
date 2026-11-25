function wv = route_time_wind(wp, tas)
% Wind case: flies each leg at constant heading (= desired course) and
% calls computeWT. Every leg starts from the point reached at the end of
% the previous one, not from the planned fix. The wind used on a leg is
% the forecast of the planned fix where the leg starts.
% Input:  wp = planned route (lat/lon/wind/wdir), tas in kt
% Output: wv = copy of wp with tas, head, gs/GS, track, dist (m, from the
%         real start point), time (s) and lat_real/lon_real/dev_m
NM2m = 1852;
wv = wp;
pos = [wp(1).lat, wp(1).lon];
wv(1).time = 0; wv(1).tas = tas; wv(1).gs = tas; wv(1).GS = tas;
wv(1).lat_real = pos(1); wv(1).lon_real = pos(2); wv(1).dev_m = 0;
wv(1).time_gs = 0;
for i = 2:numel(wp)
    [d, az] = orto_distazi(pos(1), pos(2), wp(i).lat, wp(i).lon);
    [GS, trk, latD, lonD] = computeWT(pos(1), pos(2), wp(i).lat, wp(i).lon, ...
                                      wp(i-1).wind, wp(i-1).wdir, tas);
    wv(i).tas = tas; wv(i).head = az; wv(i).gs = GS; wv(i).GS = GS;
    wv(i).track = trk; wv(i).dist = d;
    wv(i).time    = wv(i-1).time    + d / NM2m / tas * 3600;  % time flown
    wv(i).time_gs = wv(i-1).time_gs + d / NM2m / GS  * 3600;  % d / GS
    wv(i).Total_dist = wv(i-1).Total_dist + d;
    pos = [latD, lonD];
    wv(i).lat_real = latD; wv(i).lon_real = lonD;
    wv(i).dev_m = orto_distazi(latD, lonD, wp(i).lat, wp(i).lon);
end
end
