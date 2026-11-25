function C = check_profile(tr, F)
% Compares the computed vertical profile with the altitude and IAS limits of
% every fix of the route (SID, en-route, STAR, approach).
% Input:  tr = trace from build_profile (SI); F = fix struct array from
%         load_phase_table (d NM, alt_min, alt_max ft, ias_max kt)
% Output: C = struct array: name, d, h_ft, cas_kt, alt_min, alt_max, ias_max, ok
M2FT = 1/0.3048; M2NM = 1/1852; MPS2KTS = 3600/1852;
[r, i] = unique(tr.r*M2NM);
for k = 1:numel(F)
    C(k).name = F(k).name; C(k).d_NM = F(k).d; %#ok<AGROW>
    C(k).h_ft = interp1(r, tr.h(i)*M2FT, F(k).d);
    C(k).cas_kt = interp1(r, tr.cas(i)*MPS2KTS, F(k).d);
    C(k).alt_min = F(k).alt_min; C(k).alt_max = F(k).alt_max; C(k).ias_max = F(k).ias_max;
    C(k).ok = (isnan(F(k).alt_min) || C(k).h_ft >= F(k).alt_min - 5) && ...
              (isnan(F(k).alt_max) || C(k).h_ft <= F(k).alt_max + 5) && ...
              (isnan(F(k).ias_max) || C(k).cas_kt <= F(k).ias_max + 1);
end
end
