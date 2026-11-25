function wp = to_remaining_dist(wp)
% Converts Total_dist from "distance flown" to "distance remaining to the
% last fix" (threshold). Needed for arrival/approach tables.
tot = wp(end).Total_dist;
for i = 1:numel(wp), wp(i).Total_dist = tot - wp(i).Total_dist; end
end
