function wp = read_enroute_wp(xmlfile, firstFix, lastFix)
% Imports the fixes between firstFix and lastFix (both included) from a
% SimBrief LIDO flight plan. SimBrief's own TOC/TOD points are skipped.
% Input:
%   xmlfile  = path to the SimBrief XML
%   firstFix = ident of the first fix (e.g. 'NANDO')
%   lastFix  = ident of the last fix  (e.g. 'ZUKKO')
% Output:
%   wp = struct array (see fill_wp) with name, lat, lon, wind, wdir filled
fp = xml2struct(xmlfile);
n  = numel(fp.OFP.navlog.fix);
ids = cell(1, n);
for i = 1:n, ids{i} = fp.OFP.navlog.fix{1, i}.ident.Text; end
i1 = find(strcmp(ids, firstFix), 1);
i2 = find(strcmp(ids, lastFix), 1);
assert(~isempty(i1) && ~isempty(i2) && i1 < i2, 'Fixes not found in plan');
k = 0;
for i = i1:i2
    if any(strcmp(ids{i}, {'TOC', 'TOD'})), continue; end
    k = k + 1;
    wp(k) = fill_wp(fp, i); %#ok<AGROW>
end
end
