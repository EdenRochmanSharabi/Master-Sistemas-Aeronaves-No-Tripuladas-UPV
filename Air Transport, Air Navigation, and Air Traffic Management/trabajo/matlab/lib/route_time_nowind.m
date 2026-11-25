function wp = route_time_nowind(wp, tas)
% No-wind case: GS = TAS, cumulative time from the leg distances.
% Input:  wp (needs dist in m), tas in kt
% Output: wp with tas, gs, GS and time (s, cumulative)
NM2m = 1852;
wp(1).time = 0;
for i = 1:numel(wp)
    wp(i).tas = tas; wp(i).gs = tas; wp(i).GS = tas;
    wp(i).head = wp(i).track;
    if i > 1
        wp(i).time = wp(i-1).time + wp(i).dist / NM2m / tas * 3600;
    end
end
end
