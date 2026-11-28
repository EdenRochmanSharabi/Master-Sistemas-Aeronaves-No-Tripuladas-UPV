function F = load_phase_table(file, d0)
% Reads a phase table written by export_proc_table / export_route_table
% and returns the fixes with their distance along the WHOLE route and the
% altitude / speed limits computed in the horizontal study.
% Input:  file = .xlsx path; d0 = route distance (NM) of the first fix
% Output: F = struct array: name, d (NM from departure), alt_min, alt_max (ft),
%         ias_max (kt; NaN when the table has no IAS column)
c = readcell(file); hdr = string(c(1,:)); c = c(2:end,:);
col = @(s) find(contains(hdr, s, 'IgnoreCase', true), 1);
iN = col('Nombre'); iMin = col('Altitud mínima'); iMax = col('Altitud máxima');
iIas = col('IAS máxima'); iTot = col('Distancia total'); iRem = col('restante');
n = size(c,1);
num = @(v) ifelse(ismissing_(v), NaN, v);
for i = 1:n
    F(i).name = c{i,iN}; %#ok<AGROW>
    F(i).alt_min = num(c{i,iMin}); F(i).alt_max = num(c{i,iMax});
    if isempty(iIas), F(i).ias_max = NaN; else, F(i).ias_max = num(c{i,iIas}); end
    if ~isempty(iTot), F(i).d = d0 + c{i,iTot};
    else,              F(i).d = d0 + c{1,iRem} - c{i,iRem}; end   % remaining -> flown
end
end

function b = ismissing_(v), b = ~isnumeric(v) || isempty(v) || any(ismissing(v)); end
function r = ifelse(c, a, b), if c, r = a; else, r = b; end, end
