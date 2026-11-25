function deg = dms2deg(s)
% Converts an AIP coordinate string to decimal degrees.
% Accepts 'ddmmss.sN' / 'dddmmss.sW' (ENAIRE) and applies sign for S/W.
% Input:  s = char, e.g. '403537.1N' or '0033217.6W'
% Output: deg = double, decimal degrees (negative for S and W)
s = strtrim(s);
hemi = s(end);
assert(any(hemi == 'NSEW'), 'Bad coordinate: %s', s);
body = s(1:end-1);
k = find(body == '.', 1); if isempty(k), k = numel(body) + 1; end   % end of integer part
secs = str2double(body(k-2:end));
mins = str2double(body(k-4:k-3));
d    = str2double(body(1:k-5));
deg  = d + mins/60 + secs/3600;
if any(hemi == 'SW'), deg = -deg; end
end
