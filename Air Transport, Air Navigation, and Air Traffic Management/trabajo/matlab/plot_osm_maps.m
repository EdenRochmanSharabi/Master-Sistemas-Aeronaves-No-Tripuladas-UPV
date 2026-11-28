% PLOT_OSM_MAPS  Capturas sobre mapa base OpenStreetMap a partir de los KML de out/.
% Teselas con cache en matlab/osm_cache (un GET por tesela, una sola vez).
clear; clc;
here = fileparts(mfilename('fullpath'));
OUT_DIR   = fullfile(here, 'out');
FIG_DIR   = fullfile(here, '..', 'memoria', 'fig');
CACHE_DIR = fullfile(here, 'osm_cache');
TILE_URL  = 'https://tile.openstreetmap.org/%d/%d/%d.png';
USER_AGENT = 'tnyca-osm-maps/1.0 (academic report, cached tiles)';
TILE_PX = 256; MAX_TILES = 20; MAX_ZOOM = 17; ASPECT = 1.5; PAD = 0.12;
FIG_W_IN = 6.3; DPI = 300; FONT_PT = 7;
ATTRIBUTION = '© OpenStreetMap contributors';
GAP_S = 0.2;

% nombre, titulo, {[kml linea, color, estilo]}, kml de fijos, regex fijos sin etiqueta, fijos de encuadre
C1 = [0 0.35 0.75]; C2 = [0.85 0.33 0.1];
V = { ...
 'osm-ruta-completa', 'Ruta completa LEMD-LLBG', {{'enroute-sinviento', C1, '-', 'Sin viento'}, {'enroute-conviento', C2, '--', 'Con viento'}}, 'enroute-sinviento', '^$', {}; ...
 'osm-sid-nando3r', 'SID NANDO3R', {{'SID-NANDO3R', C1, '-', 'SID NANDO3R'}}, 'SID-NANDO3R', '^$', {}; ...
 'osm-llegada-ils21', 'Llegada ERREZ1A e ILS 21', {{'LEMD-LLBG-llegada', C1, '-', 'ERREZ1A'}, {'LEMD-LLBG-apr-ILS21', C2, '-', 'ILS 21'}}, {'LEMD-LLBG-llegada','LEMD-LLBG-apr-ILS21'}, '^$', {}; ...
 'osm-rnpy21-arco-rf', 'RNP Y 21, arco RF', {{'LEMD-LLBG-apr-RNPY21', C1, '-', 'RNP Y 21'}}, 'LEMD-LLBG-apr-RNPY21', '^$', {'BG217','BG216'}; ...
 'osm-frustrada-ils21', 'Frustrada ILS 21', {{'LEMD-LLBG-frustrada-ILS21', C1, '-', 'Frustrada ILS 21'}}, 'LEMD-LLBG-frustrada-ILS21', '^MAT\d+$', {}};

if ~isfolder(CACHE_DIR), mkdir(CACHE_DIR); end
opts = weboptions('UserAgent', USER_AGENT, 'Timeout', 30);
for k = 1:size(V,1)
  [name, ttl, lines, fixfiles, skip, focus] = V{k,:};
  fixes = struct('name', {}, 'lat', {}, 'lon', {});
  for f = cellstr(fixfiles), fixes = [fixes, read_kml(OUT_DIR, f{1}).fixes]; end %#ok<AGROW>
  [~, ia] = unique({fixes.name}, 'stable'); fixes = fixes(ia);
  for j = 1:numel(lines), lines{j}{5} = read_kml(OUT_DIR, lines{j}{1}).line; end
  fprintf(2, '%s [devlog] plot_osm_maps.view name=%s lines=%d fixes=%d\n', datestr(now,'HH:MM:SS'), name, numel(lines), numel(fixes));
  draw_view(OUT_DIR, FIG_DIR, name, ttl, lines, fixes, skip, focus, struct('url', TILE_URL, 'opts', opts, ...
    'cache', CACHE_DIR, 'tile', TILE_PX, 'maxTiles', MAX_TILES, 'maxZoom', MAX_ZOOM, 'aspect', ASPECT, 'pad', PAD, ...
    'figW', FIG_W_IN, 'dpi', DPI, 'font', FONT_PT, 'attr', ATTRIBUTION, 'gap', GAP_S));
end

function k = read_kml(dir_, base)
% Primera linea (LineString) y fijos (Placemark sin LineString) de un KML.
txt = fileread(fullfile(dir_, [base '.kml']));
chunks = strsplit(txt, '<Placemark>'); chunks(1) = [];
k.fixes = struct('name', {}, 'lat', {}, 'lon', {}); k.line = [];
for i = 1:numel(chunks)
  c = chunks{i};
  ls = regexp(c, '<LineString>.*?<coordinates>(.*?)</coordinates>', 'tokens', 'once');
  if ~isempty(ls)
    k.line = reshape(sscanf(ls{1}, '%f,%f,%f'), 3, [])';
    continue
  end
  nm = regexp(c, '<name>(.*?)</name>', 'tokens', 'once');
  pt = regexp(c, '<coordinates>(.*?)</coordinates>', 'tokens', 'once');
  v = sscanf(pt{1}, '%f,%f,%f');
  k.fixes(end+1) = struct('name', strtrim(nm{1}), 'lat', v(2), 'lon', v(1));
end
end

function draw_view(outDir, figDir, name, ttl, lines, fixes, skip, focus, S)
pts = cellfun(@(l) l{5}, lines, 'UniformOutput', false); pts = vertcat(pts{:});
allLat = pts(:,2); allLon = pts(:,1);
if ~isempty(focus)
  m = fixes(ismember({fixes.name}, focus)); allLat = [m.lat]'; allLon = [m.lon]';
end
[z, box] = pick_zoom(allLat, allLon, S);
img = fetch_mosaic(box, z, S);
fig = figure('Visible', 'off', 'Units', 'inches', 'Position', [0 0 S.figW S.figW/S.aspect], 'Color', 'w');
ax = axes(fig, 'Position', [0 0 1 1]); hold(ax, 'on');
image(ax, [box.tx0*S.tile, (box.tx1+1)*S.tile], [box.ty0*S.tile, (box.ty1+1)*S.tile], img);
set(ax, 'XLim', box.x, 'YLim', box.y, 'XTick', [], 'YTick', [], 'YDir', 'reverse', 'DataAspectRatio', [1 1 1]);
h = gobjects(1, numel(lines));
for j = 1:numel(lines)
  [x, y] = merc(lines{j}{5}(:,2), lines{j}{5}(:,1), z, S.tile);
  h(j) = plot(ax, x, y, lines{j}{3}, 'Color', lines{j}{2}, 'LineWidth', 1.6, 'DisplayName', lines{j}{4});
end
keep = fixes(cellfun(@isempty, regexp({fixes.name}, skip, 'once')));
[fx, fy] = merc([keep.lat], [keep.lon], z, S.tile);
hf = plot(ax, fx, fy, 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 4, 'DisplayName', 'Fijo');
place_labels(ax, keep, fx, fy, box, S);
lg = legend(ax, [h hf], 'Location', 'northwest', 'FontSize', S.font, 'Box', 'on'); title(lg, ttl);
text(ax, box.x(2), box.y(2), [' ' S.attr ' '], 'Units', 'data', 'HorizontalAlignment', 'right', ...
  'VerticalAlignment', 'bottom', 'FontSize', S.font - 1, 'BackgroundColor', [1 1 1 0.8], 'Margin', 1);
exportgraphics(fig, fullfile(outDir, [name '.png']), 'Resolution', S.dpi);
copyfile(fullfile(outDir, [name '.png']), fullfile(figDir, [name '.png']));
close(fig);
end

function [x, y] = merc(lat, lon, z, tile)
n = tile * 2^z;
x = (lon + 180) / 360 * n;
y = (1 - asinh(tan(deg2rad(lat))) / pi) / 2 * n;
end

function [z, box] = pick_zoom(lat, lon, S)
for z = S.maxZoom:-1:2
  [x, y] = merc(lat, lon, z, S.tile);
  w = max(max(x)-min(x), S.tile/4) * (1 + 2*S.pad); hgt = max(max(y)-min(y), S.tile/4) * (1 + 2*S.pad);
  w = max(w, hgt * S.aspect); hgt = w / S.aspect;
  cx = mean([min(x) max(x)]); cy = mean([min(y) max(y)]);
  box.x = cx + [-w w]/2; box.y = cy + [-hgt hgt]/2;
  box.tx0 = floor(box.x(1)/S.tile); box.tx1 = floor(box.x(2)/S.tile);
  box.ty0 = floor(box.y(1)/S.tile); box.ty1 = floor(box.y(2)/S.tile);
  if (box.tx1-box.tx0+1) * (box.ty1-box.ty0+1) <= S.maxTiles, return; end
end
end

function img = fetch_mosaic(box, z, S)
rows = cell(1, box.ty1-box.ty0+1);
for ty = box.ty0:box.ty1
  row = cell(1, box.tx1-box.tx0+1);
  for tx = box.tx0:box.tx1
    f = fullfile(S.cache, sprintf('%d_%d_%d.png', z, tx, ty));
    if ~isfile(f)
      fprintf(2, '%s [devlog] plot_osm_maps.fetch z=%d x=%d y=%d\n', datestr(now,'HH:MM:SS'), z, tx, ty);
      websave(f, sprintf(S.url, z, tx, ty), S.opts); pause(S.gap);
    end
    [t, cm] = imread(f);
    if ~isempty(cm), t = uint8(255 * ind2rgb(t, cm)); end
    row{tx-box.tx0+1} = t(:,:,1:3);
  end
  rows{ty-box.ty0+1} = horzcat(row{:});
end
img = vertcat(rows{:});
end

function place_labels(ax, keep, fx, fy, box, S)
span = diff(box.x);
cand = [1 0; -1 0; 0 1; 0 -1; 1 1; -1 1; 1 -1; -1 -1; 2 0; -2 0; 0 2; 0 -2; 2 2; -2 2; 2 -2; -2 -2; 4 0; -4 0; 0 4; 0 -4];
off = 0.012 * span;
al = {'left','right','center','center'}; va = {'middle','middle','top','bottom'};
half = 0.006 * span;
placed = [fx(:)-half, fy(:)-half, 2*half*ones(numel(fx),2)];
for i = 1:numel(keep)
  ok = false;
  for c = 1:size(cand,1)
    dx = cand(c,1); dy = cand(c,2);
    if dx == 0, side = 3 + (dy < 0); else, side = 1 + (dx < 0); end
    t = text(ax, fx(i) + dx*off, fy(i) + dy*off, keep(i).name, 'FontSize', S.font, 'HorizontalAlignment', al{side}, ...
      'VerticalAlignment', va{side}, 'BackgroundColor', [1 1 1 0.75], 'Margin', 0.5, 'Clipping', 'on');
    e = t.Extent;
    clash = any(e(1) < placed(:,1)+placed(:,3) & placed(:,1) < e(1)+e(3) & e(2) < placed(:,2)+placed(:,4) & placed(:,2) < e(2)+e(4));
    if ~clash && e(1) > box.x(1) && e(1)+e(3) < box.x(2) && e(2) > box.y(1) && e(2)+e(4) < box.y(2)
      placed(end+1,:) = e; ok = true; %#ok<AGROW>
      if c > 8, plot(ax, [fx(i) fx(i)+dx*off], [fy(i) fy(i)+dy*off], '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 0.5, 'HandleVisibility', 'off'); end
      break
    end
    delete(t);
  end
  if ~ok, fprintf(2, '%s [devlog] plot_osm_maps.label skipped=%s\n', datestr(now,'HH:MM:SS'), keep(i).name); end
end
end
