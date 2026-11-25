function calibrar_marcar()
% Calibra cada carta AIP (lat/lon -> coordenadas de pagina) con su reticula y
% escribe build/<id>.tex (carta original de fondo + ruta en TikZ) y
% build/calibracion.txt. Lo lanza build.sh (que antes renderiza las cartas a
% PNG y extrae las etiquetas con pdftotext). Coordenadas de pagina en bp
% (1/72 in), origen arriba-izquierda, igual que pdftotext -bbox-layout.
here  = fileparts(mfilename('fullpath'));
build = fullfile(here, 'build');
out   = fullfile(here, '..', 'matlab', 'out');
DPI   = 200;
MM    = 25.4/72;                       % bp -> mm

rd  = @(f) readtable(fullfile(out, f), 'VariableNamingRule', 'preserve');
sid = rd('SID-NANDO3R.xlsx');  lle = rd('LLEGADA-ERREZ1A.xlsx');
ils = rd('APR-ILS21.xlsx');    rnp = rd('APR-RNPY21.xlsx');
ruta = @(T, nombres, estilo) struct('estilo', estilo, 'nombres', {nombres}, 'll', coords(T, nombres));

C = {};
% ---------- SID NANDO3R (LEMD SID 7, p.1; A3 apaisada 1191 x 842) ----------
c = struct('id', 'SID_7_NANDO3R', 'pdf', '../cartas/LEMD/SID_7.pdf', 'W', 1191, 'H', 842);
% pdftotext no lee bien estas etiquetas: posiciones medidas a mano (bp).
% meridianos [lon, x arriba, x abajo]; paralelos [lat, y izq, y der]. Las lineas
% de 30' (sin etiqueta) se interpolan y se aceptan solo si se detectan.
c.grid = grid_manual([-6 223.3 204.5; -5 459.8 448.8; -4 696.1 693.1; -3 932.5 937.8], ...
                     [41 277.3 286.0; 40 592.6 601.0], [107 800], [78 1150]);
c.clip   = [78 107 1150 800];
c.tramos = {ruta(sid, sid.Nombre, 'solid')};
c.circ   = sid.Nombre;
c.etiq   = {{'CA2500', 'CA 2500 ft', 'west', 6, 8}};
c.leyenda = {735, 83, 'west'};
C{end+1} = c;

% ---------- TRANS ERREZ1A (LLBG TRANS 21-26, p.1; A4 girada 595 x 842) ----------
c = struct('id', 'LLBG_TRANS_ERREZ1A', 'pdf', '../cartas/LLBG/LL_AD_2_LLBG_TRANS-21-26-1.pdf', 'W', 595.276, 'H', 841.89);
[c.grid, c.clip] = grid_auto(fullfile(build, [c.id '.html']));
c.tramos = {ruta(lle, lle.Nombre, 'solid')};
c.circ   = lle.Nombre;
c.etiq   = {};
c.leyenda = {95, 822, 'west'};
C{end+1} = c;

% ---------- STAR (solo ZUKKO-KONFO, tramo comun) ----------
c = struct('id', 'LLBG_STAR_ZUKKO-KONFO', 'pdf', '../cartas/LLBG/LL_AD_2_LLBG_STAR-21-26-1_V2_en.pdf', 'W', 595.276, 'H', 841.89);
[c.grid, c.clip] = grid_auto(fullfile(build, [c.id '.html']));
c.tramos = {ruta(lle, {'ZUKKO'; 'KONFO'}, 'solid')};
c.circ   = {'ZUKKO'; 'KONFO'};
c.etiq   = {};
c.leyenda = {95, 809, 'west'};
C{end+1} = c;

% ---------- ILS 21 (IAC 21-4, p.1; A4 vertical) ----------
c = struct('id', 'LLBG_IAC_ILS21', 'pdf', '../cartas/LLBG/LL_AD_2_LLBG_IAC_21-4_V3_en.pdf', 'W', 595.22, 'H', 842);
[c.grid, c.clip] = grid_auto(fullfile(build, [c.id '.html']));
c.tramos = {ruta(ils, {'TOPPU'; 'GALGA'}, 'dashed'), ruta(ils, {'GALGA'; 'BG074'; 'THR21'}, 'solid')};
c.circ   = ils.Nombre;
c.etiq   = {{'TOPPU-GALGA', 'enlace asumido (fallo com., carta TRANS)', 'east', -4, 0}};
c.leyenda = {95, 814, 'west'};
C{end+1} = c;

% ---------- RNP Y 21 (IAC RNPY21, p.1; A4 vertical) ----------
c = struct('id', 'LLBG_IAC_RNPY21', 'pdf', '../cartas/LLBG/LL_AD_2_LLBG_IAC_RNPY21_en.pdf', 'W', 595.276, 'H', 841.89);
[c.grid, c.clip] = grid_auto(fullfile(build, [c.id '.html']));
arc = arco_rf(rnp, 'BG217', 'BG216', dms(32,05,04.6), dms(34,53,10.0), 2.55);   % centro BG999, r = 2,55 NM
c.tramos = {ruta(rnp, {'TOPPU'; 'GINTU'}, 'dashed'), ...
            ruta(rnp, {'GINTU'; 'RABIN'; 'OFFIK'; 'VATAT'; 'NAMIM'; 'BG217'}, 'solid'), ...
            struct('estilo', 'solid', 'nombres', {{}}, 'll', arc), ...
            ruta(rnp, {'BG216'; 'THR21'}, 'solid')};
c.circ   = setdiff(rnp.Nombre, {'ARC1'; 'ARC2'}, 'stable');
c.etiq   = {{'TOPPU-GINTU', 'enlace asumido (ATC)', 'west', 4, 0}};
c.leyenda = {95, 821, 'west'};
c.sin_lineas = true;   % esta carta solo dibuja las lineas de 32N y 35E; el resto son marcas del borde
C{end+1} = c;

% ---------- calibrar y escribir ----------
fid = fopen(fullfile(build, 'calibracion.txt'), 'w');
pr = @(varargin) arrayfun(@(f) fprintf(f, varargin{:}), [1 fid], 'UniformOutput', false);
for k = 1:numel(C)
    c = C{k};
    pr('\n=== %s ===\n', c.id);
    img = imread(fullfile(build, [c.id '-1.png']));
    dk  = 1 - double(max(img, [], 3))/255;     % "oscuridad gris": lineas negras/grises, no colores
    assert(abs(size(img,2)/c.W - DPI/72) < 0.01, 'tamano de pagina inesperado en %s', c.id);
    pxpt = size(img, 2)/c.W;
    G = c.grid;
    for i = 1:numel(G)
        G(i) = detectar_linea(dk, pxpt, G(i));
        nota = tern(G(i).ok, '', '-> DESCARTADA');
        if ~G(i).ok && isfield(c, 'sin_lineas')          % reticula sin lineas: recta entre las dos etiquetas
            G(i) = linea_etiquetas(G(i)); nota = '-> recta entre etiquetas del marco';
        end
        pr('  linea %s %8.4f: %3d puntos, rms %.2f bp %s\n', G(i).tipo, G(i).val, G(i).n, G(i).rms, nota);
    end
    G = G([G.ok]);
    D = G([G.n] > 0);
    d = [arrayfun(@(L) evalpol(L, L.s0) - L.p0, D), arrayfun(@(L) evalpol(L, L.s1) - L.p1, D)];
    pr('  linea detectada - centro de etiqueta: media %+.2f bp, std %.2f bp, max %.2f bp (n=%d)\n', mean(d), std(d), max(abs(d)), numel(d));
    [P, nM, nP] = intersecciones(G);
    if size(P,1) < 4, pr('  NO CALIBRABLE: solo %d intersecciones\n', size(P,1)); continue; end
    M = ajustar_modelo(P, nM, nP);
    pr('  %d meridianos x %d paralelos -> %d intersecciones; modelo %s\n', nM, nP, size(P,1), M.desc);
    pr('  RMS ajuste %.2f bp = %.2f mm (max %.2f mm); RMS leave-one-out %.2f mm\n', M.rms, M.rms*MM, M.max*MM, M.loo*MM);
    escribir_tex(fullfile(build, [c.id '.tex']), c, M);
end
fclose(fid);
end

% ======================= reticula =======================
function G = grid_manual(mer, par, yr, xr)
% Meridianos y paralelos etiquetados + candidatos intermedios/extrapolados (30').
G = struct('tipo', {}, 'val', {}, 'p0', {}, 'p1', {}, 's0', {}, 's1', {}, 'pol', {}, 'sm', {}, 'sh', {}, 'n', {}, 'rms', {}, 'ok', {});
G = [G, candidatos(mer, 'v', yr, xr)];
G = [G, candidatos(par, 'h', xr, yr)];
end

function L = candidatos(tab, tipo, sr, lim)
tab = sortrows(tab, 1);
d = diff(tab);                                   % paso entre lineas etiquetadas
ext = [tab(1,:) - d(1,:)/2; tab(end,:) + d(end,:)/2];
mid = (tab(1:end-1,:) + tab(2:end,:))/2;
tab = sortrows([tab; mid; ext], 1);
L = struct('tipo', {}, 'val', {}, 'p0', {}, 'p1', {}, 's0', {}, 's1', {}, 'pol', {}, 'sm', {}, 'sh', {}, 'n', {}, 'rms', {}, 'ok', {});
for i = 1:size(tab, 1)
    if min(tab(i,2:3)) < lim(1)+5 || max(tab(i,2:3)) > lim(2)-5, continue; end
    L(end+1) = struct('tipo', tipo, 'val', tab(i,1), 'p0', tab(i,2), 'p1', tab(i,3), 's0', sr(1)+4, 's1', sr(2)-4, ...
                      'pol', [], 'sm', 0, 'sh', 1, 'n', 0, 'rms', NaN, 'ok', false); %#ok<AGROW>
end
end

function [G, clip] = grid_auto(html)
% Etiquetas "dd°mm'" de pdftotext -bbox-layout emparejadas por valor: dos en
% la misma vertical -> linea 'v' (x = f(y)); dos en la misma horizontal -> 'h'.
txt = fileread(html, 'Encoding', 'UTF-8');
t = regexp(txt, '<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(\d{2})°(\d{2})(?:&apos;)?[NSEW]?</word>', 'tokens');
w = cellfun(@(q) str2double(q), t, 'UniformOutput', false); w = vertcat(w{:});   % xMin yMin xMax yMax deg min
val = w(:,5) + w(:,6)/60;  cx = (w(:,1)+w(:,3))/2;  cy = (w(:,2)+w(:,4))/2;
G = struct('tipo', {}, 'val', {}, 'p0', {}, 'p1', {}, 's0', {}, 's1', {}, 'pol', {}, 'sm', {}, 'sh', {}, 'n', {}, 'rms', {}, 'ok', {});
izq = []; der = []; arr = []; aba = [];
for v = unique(val)'
    idx = find(val == v);
    for a = idx'
        for b = idx'
            if abs(cx(a)-cx(b)) < 20 && cy(b)-cy(a) > 100           % a arriba, b abajo
                G(end+1) = struct('tipo', 'v', 'val', v, 'p0', cx(a), 'p1', cx(b), 's0', w(a,4)+3, 's1', w(b,2)-3, ...
                                  'pol', [], 'sm', 0, 'sh', 1, 'n', 0, 'rms', NaN, 'ok', false); %#ok<AGROW>
                arr(end+1) = w(a,4); aba(end+1) = w(b,2); %#ok<AGROW>
            elseif abs(cy(a)-cy(b)) < 20 && cx(b)-cx(a) > 100       % a izquierda, b derecha
                G(end+1) = struct('tipo', 'h', 'val', v, 'p0', cy(a), 'p1', cy(b), 's0', w(a,3)+3, 's1', w(b,1)-3, ...
                                  'pol', [], 'sm', 0, 'sh', 1, 'n', 0, 'rms', NaN, 'ok', false); %#ok<AGROW>
                izq(end+1) = w(a,3); der(end+1) = w(b,1); %#ok<AGROW>
            end
        end
    end
end
% el marco del mapa queda entre las etiquetas de los dos lados
clip = [max(izq)+2, max(arr)+2, min(der)-2, min(aba)-2];
end

% ======================= deteccion de lineas =======================
function L = detectar_linea(dk, pxpt, L)
% Linea 'v': x = f(y) (s = y); 'h': y = f(x) (s = x). La linea se muestrea por
% segmentos de SEG bp: se promedia el perfil transversal de todas las filas
% del segmento, alineadas sobre la posicion estimada, y se toma el maximo.
% Una linea fina y tenue se acumula; el relieve y los textos que la cruzan no.
% Dos pasadas: ventana ancha sobre la estimacion lineal, estrecha sobre el ajuste.
SEG = 20;
s = ((L.s0:SEG:L.s1-SEG) + SEG/2)';
for pasada = 1:2
    win = tern(pasada == 1, 10, 3);
    v = nan(size(s));
    for k = 1:numel(s)
        ss = (s(k)-SEG/2 : 1/pxpt : s(k)+SEG/2)';
        if pasada == 1, est = L.p0 + (L.p1-L.p0)*(ss-L.s0)/(L.s1-L.s0); else, est = evalpol(L, ss); end
        v(k) = pico_alineado(dk, pxpt, L.tipo, ss, est, win);
    end
    ok = ~isnan(v);
    if nnz(ok) < 6, L.ok = false; L.n = nnz(ok); return; end
    L = ajuste_robusto(L, s(ok), v(ok));
end
L.ok = L.n >= max(6, 0.4*numel(s)) && L.rms < 0.7;
end

function v = pico_alineado(dk, pxpt, tipo, ss, est, win)
nw = ceil(win*pxpt); off = -nw:nw; pf = zeros(1, numel(off)); cnt = 0; e = round(est*pxpt);
for k = 1:numel(ss)
    c = ceil(ss(k)*pxpt); idx = e(k) + off;
    if tipo == 'v'
        if c < 1 || c > size(dk,1) || idx(1) < 1 || idx(end) > size(dk,2), continue; end
        pf = pf + dk(c, idx);
    else
        if c < 1 || c > size(dk,2) || idx(1) < 1 || idx(end) > size(dk,1), continue; end
        pf = pf + dk(idx, c)';
    end
    cnt = cnt + 1;
end
if cnt < 5, v = NaN; return; end
pf = pf/cnt;
d = 3;   % respuesta de linea fina: resta el fondo a +-3 px (anula rellenos grises planos)
pf = [zeros(1,d), pf(1+d:end-d) - max(pf(1:end-2*d), pf(1+2*d:end)), zeros(1,d)];
[m, j] = max(pf);
if m < 0.05 || j <= d || j >= numel(pf)-d, v = NaN; return; end
den = pf(j-1) - 2*pf(j) + pf(j+1);                       % interpolacion parabolica
d = tern(den < -1e-6, max(-1, min(1, 0.5*(pf(j-1)-pf(j+1))/den)), 0);
v = (mean(e) - 0.5 + off(j) + d)/pxpt;
end

function L = ajuste_robusto(L, s, v)
L.sm = (L.s0+L.s1)/2; L.sh = (L.s1-L.s0)/2;
t = (s-L.sm)/L.sh;  keep = true(size(t));
for it = 1:6
    p = polyfit(t(keep), v(keep), 2);
    r = v - polyval(p, t);
    thr = max(3*1.4826*median(abs(r(keep))), 0.3);
    keep = abs(r) < thr;
end
L.pol = p; L.n = nnz(keep); L.rms = sqrt(mean(r(keep).^2));
end

function v = evalpol(L, s), v = polyval(L.pol, (s-L.sm)/L.sh); end

function L = linea_etiquetas(L)
L.sm = (L.s0+L.s1)/2; L.sh = (L.s1-L.s0)/2;
L.pol = [0, (L.p1-L.p0)/2, (L.p0+L.p1)/2];
L.n = 0; L.rms = NaN; L.ok = true;
end

function [P, nM, nP] = intersecciones(G)
V = G([G.tipo] == 'v'); Hh = G([G.tipo] == 'h');
nM = numel(V); nP = numel(Hh); P = [];
for i = 1:numel(V)
    for j = 1:numel(Hh)
        x = Hh(j).sm; y = V(i).sm;
        for it = 1:30, y = evalpol(Hh(j), x); x = evalpol(V(i), y); end
        if x < Hh(j).s0-5 || x > Hh(j).s1+5 || y < V(i).s0-5 || y > V(i).s1+5, continue; end
        P(end+1,:) = [V(i).val, Hh(j).val, x, y]; %#ok<AGROW>  (valor linea v, valor linea h, x, y)
    end
end
end

% ======================= modelo lat/lon -> pagina =======================
function M = ajustar_modelo(P, nM, nP)
% P = [val_v, val_h, x, y]. La linea 'v' es un meridiano (lon) salvo en las
% cartas giradas (TRANS/STAR), donde es un paralelo: se decide por el valor.
eslon = @(v) v < 0 | v > 33.3;   % lon: W (negativa) o 33,5-36 E; lat: 31-33 o 39-42
if ~eslon(P(1,1)), lat = P(:,1); lon = P(:,2); dlat = min(nM-1,2); dlon = min(nP-1,2);
else,                     lon = P(:,1); lat = P(:,2); dlon = min(nM-1,2); dlat = min(nP-1,2); end
M.lon0 = mean(lon); M.lat0 = mean(lat);
[I, J] = meshgrid(0:dlon, 0:dlat); sel = (I+J) <= 2;
M.I = I(sel)'; M.J = J(sel)';
M.desc = sprintf('%d terminos (lon^i lat^j, i<=%d, j<=%d, i+j<=2)', numel(M.I), dlon, dlat);
A = diseno(M, lat, lon);
M.ax = A\P(:,3); M.ay = A\P(:,4);
r = [A*M.ax - P(:,3), A*M.ay - P(:,4)];
M.rms = sqrt(mean(sum(r.^2, 2))); M.max = max(sqrt(sum(r.^2, 2)));
n = size(P,1); e = zeros(n,1);
for k = 1:n
    m = true(n,1); m(k) = false;
    e(k) = norm([A(k,:)*(A(m,:)\P(m,3)) - P(k,3), A(k,:)*(A(m,:)\P(m,4)) - P(k,4)]);
end
M.loo = sqrt(mean(e.^2));
end

function A = diseno(M, lat, lon)
A = zeros(numel(lat), numel(M.I));
for k = 1:numel(M.I), A(:,k) = (lon-M.lon0).^M.I(k) .* (lat-M.lat0).^M.J(k); end
end

function xy = proyectar(M, ll)      % ll = [lat lon] -> [x y] (bp, origen arriba-izq)
A = diseno(M, ll(:,1), ll(:,2));
xy = [A*M.ax, A*M.ay];
end

% ======================= ruta =======================
function ll = coords(T, nombres)
[tf, i] = ismember(nombres, T.Nombre);
assert(all(tf), 'fijo no encontrado: %s', strjoin(nombres(~tf), ','));
ll = [T.Latitud(i), T.Longitud(i)];
end

function ll = arco_rf(T, nIni, nFin, latC, lonC, rNM)
% Puntos del arco RF (giro a derechas) entre dos fijos, por marcaciones desde el centro.
R = 3440.065;  d = rNM/R;
b = @(ll) mod(atan2d(sind(ll(2)-lonC)*cosd(ll(1)), cosd(latC)*sind(ll(1)) - sind(latC)*cosd(ll(1))*cosd(ll(2)-lonC)), 360);
b0 = b(coords(T, {nIni}));  b1 = b(coords(T, {nFin}));
if b1 < b0, b1 = b1 + 360; end
brg = linspace(b0, b1, 16)';
lat = asind(sind(latC)*cos(d) + cosd(latC)*sin(d)*cosd(brg));
lon = lonC + atan2d(sind(brg)*sin(d)*cosd(latC), cos(d) - sind(latC)*sind(lat));
ll = [lat lon];
end

function v = dms(d, m, s), v = d + m/60 + s/3600; end

% ======================= TikZ =======================
function escribir_tex(file, c, M)
f = fopen(file, 'w');
fprintf(f, '%% Generado por calibrar_marcar.m: %s con la ruta calculada encima.\n', c.id);
fprintf(f, '\\documentclass{article}\n\\usepackage[paperwidth=%.3fbp,paperheight=%.3fbp,margin=0pt]{geometry}\n', c.W, c.H);
fprintf(f, '\\usepackage{graphicx,tikz}\n\\pagestyle{empty}\n\\begin{document}\\noindent\n');
fprintf(f, '\\begin{tikzpicture}[remember picture,overlay,x=1bp,y=1bp]\n');
fprintf(f, '\\node[anchor=south west,inner sep=0pt] at (current page.south west) {\\includegraphics[page=1]{%s}};\n', c.pdf);
fprintf(f, '\\begin{scope}[shift={(current page.south west)}]\n');
fprintf(f, '\\clip (%.2f,%.2f) rectangle (%.2f,%.2f);\n', c.clip(1), c.H-c.clip(2), c.clip(3), c.H-c.clip(4));
todos = struct('nombre', {}, 'xy', {});
for t = c.tramos
    t = t{1}; xy = proyectar(M, t.ll); xy(:,2) = c.H - xy(:,2);
    fprintf(f, '\\draw[red,line width=1.2pt,line join=round,%s] %s;\n', t.estilo, ...
            strjoin(arrayfun(@(i) sprintf('(%.2f,%.2f)', xy(i,1), xy(i,2)), 1:size(xy,1), 'UniformOutput', false), ' -- '));
    for i = 1:numel(t.nombres), todos(end+1) = struct('nombre', t.nombres{i}, 'xy', xy(i,:)); end %#ok<AGROW>
    if numel(t.nombres) == 2, todos(end+1) = struct('nombre', [t.nombres{1} '-' t.nombres{2}], 'xy', mean(xy)); end %#ok<AGROW>
end
for n = c.circ'
    p = todos(strcmp({todos.nombre}, n{1})); p = p(1);
    fprintf(f, '\\draw[red,line width=0.8pt] (%.2f,%.2f) circle (3bp);\n', p.xy);
end
for e = c.etiq
    e = e{1}; p = todos(strcmp({todos.nombre}, e{1})); p = p(1);
    fprintf(f, '\\node[red,font=\\sffamily\\fontsize{5}{6}\\selectfont,anchor=%s,inner sep=1pt,fill=white,fill opacity=0.7,text opacity=1] at (%.2f,%.2f) {%s};\n', ...
            e{3}, p.xy(1)+e{4}, p.xy(2)-e{5}, e{2});
end
fprintf(f, '\\end{scope}\n');
fprintf(f, '\\node[red,font=\\sffamily\\fontsize{6}{7}\\selectfont,anchor=%s,inner sep=2pt,draw=red,line width=0.3pt,fill=white] at ([shift={(%.2f,%.2f)}]current page.south west) {Ruta marcada por el alumno -- trabajo TNyCA -- la l\\''inea roja es la ruta calculada};\n', ...
        c.leyenda{3}, c.leyenda{1}, c.H - c.leyenda{2});
fprintf(f, '\\end{tikzpicture}\n\\end{document}\n');
fclose(f);
end

function r = tern(c, a, b), if c, r = a; else, r = b; end, end
