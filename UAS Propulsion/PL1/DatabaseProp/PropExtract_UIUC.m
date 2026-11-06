clc; clear; close all;

% --- Defensa por si existe una variable llamada 'regexp' que enmascara la función
if exist('regexp','var') == 1
    clear regexp
end

% === 1) Carpetas origen ===
folders = {
    'C:\Users\marco\OneDrive - UPV\2_Docencia\2025-2026\UAS_Propulsion\Trabajo_Academico\Resolucion\UIUC-propDB\volume-1\data'
    'C:\Users\marco\OneDrive - UPV\2_Docencia\2025-2026\UAS_Propulsion\Trabajo_Academico\Resolucion\UIUC-propDB\volume-2\data'
    'C:\Users\marco\OneDrive - UPV\2_Docencia\2025-2026\UAS_Propulsion\Trabajo_Academico\Resolucion\UIUC-propDB\volume-3\data'
    'C:\Users\marco\OneDrive - UPV\2_Docencia\2025-2026\UAS_Propulsion\Trabajo_Academico\Resolucion\UIUC-propDB\volume-4\data'
};

dJ = 0.05;        % paso de J
inch2m = 0.0254;  % pulgadas a metros

% === 2) Listar todos los archivos .txt de todas las carpetas ===
allFiles = [];
for k = 1:numel(folders)
    if ~isfolder(folders{k})
        warning('Carpeta no encontrada: %s', folders{k});
        continue;
    end
    files = dir(fullfile(folders{k}, '*.txt'));
    allFiles = [allFiles; files]; %#ok<AGROW>
end

if isempty(allFiles)
    error('No se encontraron archivos .txt en las carpetas indicadas.');
end

% === 3) Filtrar archivos que NO acaben en "_geom.txt" ===
maskKeep = ~endsWith({allFiles.name}, '_geom.txt', 'IgnoreCase', true);
allFiles = allFiles(maskKeep);

if isempty(allFiles)
    error('Tras filtrar *_geom.txt no quedan archivos para procesar.');
end

% === 4) Agrupar por set de datos (primeros 2 tokens separados por "_")
%     p.ej. "apce_12x8_0625od_4991.txt" -> grupo "apce_12x8"
baseNames = cell(numel(allFiles), 1);
for i = 1:numel(allFiles)
    [~, nm, ~] = fileparts(allFiles(i).name);
    % capturar "<token1>_<token2>" del principio del nombre
    % ^([^_]+_[^_]+)
    m = regexp(char(nm), '^([^_]+_[^_]+)', 'tokens', 'once');
    if ~isempty(m)
        baseNames{i} = m{1};
    else
        % si no cumple, usa el nombre sin extensión completo como clave
        baseNames{i} = nm;
    end
end

[groups, ~, gIdx] = unique(baseNames, 'stable');
fprintf('Se encontraron %d grupos de datos.\n', numel(groups));

for g = 1:numel(groups)
    key = groups{g};
    fprintf('\n--- Grupo: %s ---\n', key);
    idx = find(gIdx == g);

    % Contenedores de series (cada archivo -> una serie)
    J_series   = {};
    CT_series  = {};
    CP_series  = {};
    eta_series = {};

    % Diámetro (m). Si varios ficheros del grupo difieren, se usa el primero válido.
    D_m = NaN;

    for ii = 1:numel(idx)
        fStruct = allFiles(idx(ii));
        filePath = fullfile(fStruct.folder, fStruct.name);
        fname = char(fStruct.name);

        % === 5) Extraer diámetro del nombre (número con decimal antes de 'x')
        %    ejemplos válidos: "apce_12x6_0634od_5993", "ance_8.5x7_2876cm_4008"
        %    patrón: guion_bajo + (entero o decimal) + 'x'
        tok = regexp(fname, '_([0-9]+(?:\.[0-9]+)?)x', 'tokens', 'once');
        if ~isempty(tok)
            D_in = str2double(tok{1});
            if ~isnan(D_in)
                D_m = D_in * inch2m;
            end
        else
            % fallback: buscar el número (entero o decimal) antes de 'x' en cualquier parte
            tok2 = regexp(fname, '([0-9]+(?:\.[0-9]+)?)x', 'tokens', 'once');
            if ~isempty(tok2)
                D_in = str2double(tok2{1});
                if ~isnan(D_in)
                    D_m = D_in * inch2m;
                end
            else
                % no interrumpe el flujo, pero avisa una sola vez por grupo
                if isnan(D_m)
                    warning('No se pudo extraer el diámetro en: %s', fname);
                end
            end
        end

        % === 6) Verificar cabecera y leer datos ===
        fid = fopen(filePath, 'r');
        if fid == -1
            warning('No se pudo abrir: %s', filePath);
            continue;
        end
        header = '';
        % leer líneas hasta encontrar una no vacía (cabecera)
        while ~feof(fid) && isempty(strtrim(header))
            header = fgetl(fid);
            if ~ischar(header); header = ''; break; end
        end
        fclose(fid);

        if isempty(header) || ~(contains(header,'J') && contains(header,'CT') ...
                && contains(header,'CP') && contains(header,'eta'))
            warning('Cabecera no válida en: %s. Se descarta.', fname);
            continue;
        end

        % Leer datos (4 columnas: J CT CP eta) separados por espacios/tabs
        data = readmatrix(filePath);
        if size(data,2) < 4
            warning('Archivo con columnas insuficientes: %s. Se descarta.', fname);
            continue;
        end

        J  = data(:,1);
        CT = data(:,2);
        CP = data(:,3);
        et = data(:,4);

        % Limpieza: quitar filas con NaN en las columnas necesarias
        good = ~(isnan(J) | isnan(CT) | isnan(CP) | isnan(et));
        J = J(good); CT = CT(good); CP = CP(good); et = et(good);

        if isempty(J)
            warning('Archivo sin datos válidos: %s. Se descarta.', fname);
            continue;
        end

        % Ordenar por J y promediar duplicados exactos dentro del archivo
        [Ju, ~, ic] = unique(J);
        CTu = accumarray(ic, CT, [], @mean);
        CPu = accumarray(ic, CP, [], @mean);
        etu = accumarray(ic, et, [], @mean);

        [Ju, ord] = sort(Ju);
        CTu = CTu(ord); CPu = CPu(ord); etu = etu(ord);

        % Guardar serie
        J_series{end+1}   = Ju;   %#ok<SAGROW>
        CT_series{end+1}  = CTu;  %#ok<SAGROW>
        CP_series{end+1}  = CPu;  %#ok<SAGROW>
        eta_series{end+1} = etu;  %#ok<SAGROW>
    end

    nSeries = numel(J_series);
    if nSeries == 0
        warning('Grupo %s sin series válidas. Se omite.', key);
        continue;
    end

    % === 7) Rejilla común de J con paso 0.05 (promedio entre archivos del grupo)
    % Usamos rango global y promedio con omitnan: si una serie no cubre un punto, no contribuye.
    jmin = ceil(min(cellfun(@(v) min(v), J_series))/dJ)*dJ;
    jmax = floor(max(cellfun(@(v) max(v), J_series))/dJ)*dJ;
    if jmax < jmin
        warning('Rango J vacío en grupo %s. Se omite.', key);
        continue;
    end
    J_grid = (jmin:dJ:jmax).';

    CT_I  = nan(numel(J_grid), nSeries);
    CP_I  = nan(numel(J_grid), nSeries);
    eta_I = nan(numel(J_grid), nSeries);

    for k = 1:nSeries
        CT_I(:,k)  = interp1(J_series{k}, CT_series{k},  J_grid, 'linear', NaN);
        CP_I(:,k)  = interp1(J_series{k}, CP_series{k},  J_grid, 'linear', NaN);
        eta_I(:,k) = interp1(J_series{k}, eta_series{k}, J_grid, 'linear', NaN);
    end

    CT_avg  = mean(CT_I,  2, 'omitnan');
    CP_avg  = mean(CP_I,  2, 'omitnan');
    eta_avg = mean(eta_I, 2, 'omitnan');

    % Quitar puntos donde todo es NaN
    ok = ~(isnan(CT_avg) & isnan(CP_avg) & isnan(eta_avg));
    J_grid = J_grid(ok);
    CT_avg = CT_avg(ok);
    CP_avg = CP_avg(ok);
    eta_avg = eta_avg(ok);

    if isempty(J_grid)
        warning('Tras promediar no quedan puntos en el grupo %s. Se omite.', key);
        continue;
    end

    % === 8) Guardar .mat en carpeta actual
    outName = sprintf('%s_avg.mat', key);
    J = J_grid; %#ok<NASGU>
    save(outName, 'J','CT_avg','CP_avg','eta_avg','D_m');

    fprintf('  → Guardado: %s (D = %s m)\n', outName, mat2str(D_m,3));
end

disp('Procesamiento completado.');
