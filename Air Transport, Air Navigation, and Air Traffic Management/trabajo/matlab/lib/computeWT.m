function [GS, track, latD, lonD] = computeWT(lat1, lon1, lat2, lon2, windSpeed, windDir, tas)
% Solves the wind triangle for ONE leg flown at constant heading.
% The heading is set equal to the desired course (initial great-circle
% azimuth from point 1 to point 2) and held for the time needed to cover
% the leg distance at the cruise TAS. Wind pushes the aircraft off the
% planned line, so the effective destination differs from (lat2,lon2).
% Input:
%   lat1, lon1     = start point (deg)
%   lat2, lon2     = desired destination (deg)
%   windSpeed      = wind speed during the leg (kt)
%   windDir        = wind direction the wind blows FROM (deg), as in LIDO
%   tas            = (optional) true airspeed in kt, default 450
% Output:
%   GS, track      = effective ground speed (kt) and track (deg)
%   latD, lonD     = effective destination reached (deg)
if nargin < 7, tas = 450; end
NM2m = 1852;
[d, head] = orto_distazi(lat1, lon1, lat2, lon2);   % d in m, head in deg
windTo = windDir + 180;                             % LIDO gives "from"
tasVec  = tas       * [cosd(head);   sind(head)];   % [North; East]
windVec = windSpeed * [cosd(windTo); sind(windTo)];
gsVec   = tasVec + windVec;
GS      = norm(gsVec);
track   = mod(atan2d(gsVec(2), gsVec(1)), 360);
t_h     = (d / NM2m) / tas;                         % hours flying
[latD, lonD] = orto_reckon(lat1, lon1, GS * t_h * NM2m, track);
end
