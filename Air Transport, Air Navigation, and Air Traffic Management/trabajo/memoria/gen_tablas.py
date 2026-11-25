#!/usr/bin/env python3
"""Tablas LaTeX (tablas/*.tex) y macros (tablas/nums.tex) a partir de csv/ (volcado de matlab/out/*.xlsx)."""
import csv, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
CSV = os.path.join(HERE, 'csv'); OUT = os.path.join(HERE, 'tablas')
os.makedirs(OUT, exist_ok=True)

def rd(name):
    with open(os.path.join(CSV, name + '.csv'), newline='', encoding='utf-8') as f:
        rows = list(csv.reader(f))
    return [dict(zip(rows[0], r)) for r in rows[1:]]

def num(s):
    try: return float(s)
    except (ValueError, TypeError): return float('nan')

def f(x, nd=1):
    x = num(x) if isinstance(x, str) else x
    if x is None or (isinstance(x, float) and math.isnan(x)): return '--'
    s = f'{x:,.{nd}f}'.replace(',', '\\,').replace('.', ',')
    return s.replace('-', '$-$', 1) if s.startswith('-') else s

def i0(x):
    x = num(x) if isinstance(x, str) else x
    return '--' if math.isnan(x) else f(x, 0)

def hms(sec):
    sec = int(round(sec)); return f'{sec//3600}:{(sec%3600)//60:02d}:{sec%60:02d}'

def tex(s):
    s = s.replace('&', r'\&').replace('%', r'\%').replace('_', r'\_').replace('#', r'\#')
    return s.replace('→', r'$\rightarrow$').replace('≤', r'$\le$')

def write(name, body):
    with open(os.path.join(OUT, name + '.tex'), 'w', encoding='utf-8') as fh: fh.write(body)

def longtable(cols, align, rows, caption, label, font=r'\footnotesize'):
    n = len(cols); head = ' & '.join(cols) + r'\\'
    s = [r'\begingroup' + font + r'\setlength{\tabcolsep}{2.8pt}', r'\begin{longtable}{' + align + '}',
         r'\caption{' + caption + r'}\label{' + label + r'}\\', r'\toprule', head, r'\midrule', r'\endfirsthead',
         r'\multicolumn{%d}{l}{\small\itshape (continuación)}\\' % n, r'\toprule', head, r'\midrule', r'\endhead',
         r'\midrule', r'\multicolumn{%d}{r}{\small\itshape continúa}\\' % n, r'\endfoot',
         r'\bottomrule', r'\endlastfoot']
    s += [' & '.join(r) + r'\\' for r in rows]
    s += [r'\end{longtable}', r'\endgroup']
    return '\n'.join(s) + '\n'

def tabular(cols, align, rows, caption, label, font=r'\footnotesize', pos='htbp'):
    s = [r'\begin{table}[' + pos + ']', r'\centering', font + r'\setlength{\tabcolsep}{3.5pt}',
         r'\caption{' + caption + r'}\label{' + label + r'}',
         r'\begin{tabular}{' + align + '}', r'\toprule', ' & '.join(cols) + r'\\', r'\midrule']
    s += [' & '.join(r) + r'\\' for r in rows]
    s += [r'\bottomrule', r'\end{tabular}', r'\end{table}']
    return '\n'.join(s) + '\n'

N = {}

# ---------------------------------------------------------------- en-ruta
e0 = rd('enroute-sinviento'); e1 = rd('enroute-conviento'); ex = rd('enroute-viento-extra')
rows = [[r['Numero'], r['Nombre'], f(r['Latitud'], 4), f(r['Longitud'], 4), f(r['Derrota'], 1),
         f(r['Distancia (NM)'], 2), f(r['Distancia total (NM)'], 2),
         i0(r['Direccion viento']) + '/' + i0(r['Velocidad viento']), i0(r['GS']),
         i0(r['Tiempo total (s)']), hms(num(r['Tiempo total (s)']))] for r in e0]
write('tab_enr_sinviento', longtable(
    ['N.º', 'Fijo', 'Lat (°)', 'Lon (°)', 'Derrota (°)', '$d$ (NM)', '$D$ (NM)', 'Viento (°/kt)', 'GS (kt)', '$t$ (s)', '$t$ (h:m:s)'],
    'rlrrrrrrrrr', rows,
    'Fase en-ruta NANDO--ZUKKO sin viento (\\texttt{enroute-sinviento.xlsx}). $d$: distancia desde el fijo anterior; $D$: acumulada; viento: previsión LIDO en el fijo (dirección de procedencia/intensidad); $t$: tiempo acumulado a TAS 450 kt. Los límites de altitud de las aerovías no figuran: véase \\S\\ref{sec:enr-pendiente}.',
    'tab:enr0', font=r'\scriptsize'))

rows = []
for r, x in zip(e1, ex):
    assert r['Nombre'] == x['Nombre']
    rows.append([r['Numero'], r['Nombre'], f(x['Rumbo'], 1), f(r['Derrota'], 1), f(r['GS'], 1),
                 f(r['Distancia (NM)'], 2), f(r['Distancia total (NM)'], 2), f(x['Desv_NM'], 2),
                 i0(r['Tiempo total (s)']), i0(x['t_dGS_s'])])
write('tab_enr_conviento', longtable(
    ['N.º', 'Fijo', 'Rumbo (°)', 'Derrota real (°)', 'GS (kt)', '$d$ (NM)', '$D$ (NM)', 'Desv. (NM)', '$t_{d/\\mathrm{TAS}}$ (s)', '$t_{d/\\mathrm{GS}}$ (s)'],
    'rlrrrrrrrr', rows,
    'Fase en-ruta con viento (\\texttt{enroute-conviento.xlsx}; rumbo, desviación y $t_{d/\\mathrm{GS}}$ obtenidos con las mismas funciones). Cada tramo parte de la posición real alcanzada al final del anterior; $d$ es la distancia desde esa posición al siguiente fijo planificado y Desv.\\ la distancia entre la posición real al final del tramo y el fijo. $t_{d/\\mathrm{TAS}}$ es el criterio literal del enunciado (tiempo volado a rumbo constante); $t_{d/\\mathrm{GS}}$ el criterio alternativo.',
    'tab:enr1', font=r'\scriptsize'))

D0 = num(e0[-1]['Distancia total (NM)']); T0 = num(e0[-1]['Tiempo total (s)'])
D1 = num(e1[-1]['Distancia total (NM)']); T1 = num(e1[-1]['Tiempo total (s)']); T1g = num(ex[-1]['t_dGS_s'])
gs1 = [num(r['GS']) for r in e1[1:]]
N.update(enrFijos=len(e0), enrDist=f(D0, 1), enrTnoW=hms(T0), enrTnoWh=f(T0/3600, 2),
         enrDistW=f(D1, 1), enrTW=hms(T1), enrTWh=f(T1/3600, 2), enrTWg=hms(T1g), enrTWgh=f(T1g/3600, 2),
         enrGSmin=f(min(gs1), 0), enrGSmax=f(max(gs1), 0), enrGSmed=f(D1/(T1g/3600), 0),
         enrDevMax=f(max(num(x['Desv_NM']) for x in ex), 1),
         enrDevMaxFix=max(ex, key=lambda x: num(x['Desv_NM']))['Nombre'],
         enrDevZukko=f(ex[-1]['Desv_NM'], 2), enrDiffW=f((T0-T1)/60, 0), enrDiffWg=f((T0-T1g)/60, 0),
         enrDeltaD=f(D0-D1, 1), enrWcaMax=f(max(abs(num(x['WCA_equiv'])) for x in ex), 1))
rows = [['Distancia recorrida (NM)', f(D0, 1), f(D1, 1), f(D1, 1)],
        ['Velocidad usada en el tiempo', 'TAS = 450 kt', 'TAS = 450 kt', 'GS (%s--%s kt)' % (f(min(gs1), 0), f(max(gs1), 0))],
        ['Tiempo NANDO--ZUKKO', hms(T0), hms(T1), hms(T1g)],
        ['Tiempo (h)', f(T0/3600, 2), f(T1/3600, 2), f(T1g/3600, 2)],
        ['Diferencia respecto al caso sin viento (min)', '--', f((T1-T0)/60, 1), f((T1g-T0)/60, 1)]]
write('tab_enr_comp', tabular(['', 'Sin viento', 'Con viento, $t=d/\\mathrm{TAS}$', 'Con viento, $t=d/\\mathrm{GS}$'], 'lrrr', rows,
    'Comparación de los tiempos de la fase en-ruta (valores finales de las tablas \\ref{tab:enr0} y \\ref{tab:enr1}).', 'tab:enrcomp', font=r'\footnotesize'))

# ---------------------------------------------------------------- procedimientos
def proc_table(name, label, caption, distcol, pend=True):
    rows = []
    for r in rd(name):
        slope = r.get('Pendiente min (%)', '')
        row = [r['Numero'], r['Nombre'], f(r['Latitud'], 4), f(r['Longitud'], 4), i0(r['Altitud minima (ft)']),
               i0(r['Altitud maxima (ft)']), i0(r['IAS maxima (kt)']), f(r['Derrota'], 1), f(r['Distancia (NM)'], 2), f(r[distcol], 2)]
        if pend: row.append(f(slope, 2) if slope else '--')
        row.append(r'\scriptsize ' + tex(r['Descripcion']))
        rows.append(row)
    cols = ['N.º', 'Fijo', 'Lat (°)', 'Lon (°)', r'\makecell{Alt mín\\(ft)}', r'\makecell{Alt máx\\(ft)}', r'\makecell{IAS máx\\(kt)}',
            r'\makecell{Derrota\\(°)}', r'\makecell{$d$\\(NM)}', r'\makecell{$D$\\(NM)}' if pend else r'\makecell{$D_{\mathrm{rest}}$\\(NM)}']
    al = 'rlrrrrrrrr'
    if pend: cols.append(r'\makecell{Pend.\\(\%)}'); al += 'r'
    cols.append('Descripción (carta)'); al += r'>{\raggedright\arraybackslash}p{3.4cm}'
    return longtable(cols, al, rows, caption, label, font=r'\scriptsize')

write('tab_sid', proc_table('SID-NANDO3R', 'tab:sid',
    'SID NANDO3R desde el DER 36R (\\texttt{SID-NANDO3R.xlsx}). Alt mín = máx(límite «a o por encima» de la carta, altitud de la pendiente mínima del 5,5\\,\\% desde 1998 ft hasta MD824); IAS máx = límite de la carta, 250 kt por debajo de 10\\,000 ft o 350 kt (sin límite). $D$: distancia acumulada desde el DER; Pend.: pendiente mínima del tramo deducida de las altitudes mínimas.',
    'Distancia total (NM)'))
write('tab_llegada', proc_table('LLEGADA-ERREZ1A', 'tab:llegada',
    'Transición ERREZ1A de ZUKKO a TOPPU (\\texttt{LLEGADA-ERREZ1A.xlsx}). $D_{\\mathrm{rest}}$: distancia restante hasta THR 21 por la ILS 21. «@9000» en la carta se codifica como mínimo = máximo = 9000 ft; 40\\,000 ft y 350 kt indican ausencia de límite.',
    'Distancia restante a THR21 (NM)', pend=False))
write('tab_ils', proc_table('APR-ILS21', 'tab:ils',
    'Aproximación de precisión ILS RWY 21 desde TOPPU (\\texttt{APR-ILS21.xlsx}).', 'Distancia restante a THR21 (NM)', pend=False))
write('tab_rnp', proc_table('APR-RNPY21', 'tab:rnp',
    'Aproximación de no precisión RNP Y RWY 21 desde TOPPU (\\texttt{APR-RNPY21.xlsx}). ARC1 y ARC2 son puntos auxiliares del arco RF BG217--BG216 (centro BG999, radio 2,55 NM, paso 10°).',
    'Distancia restante a THR21 (NM)', pend=False))
write('tab_frustrada', proc_table('FRUSTRADA-ILS21', 'tab:frustrada',
    'Aproximación frustrada ILS RWY 21 (\\texttt{FRUSTRADA-ILS21.xlsx}), común a la RNP Y 21. $D$: distancia acumulada desde THR21. Se modela solo el tramo THR21 $\\rightarrow$ GEMDA (suposición~17).',
    'Distancia total desde THR21 (NM)'))

sid = rd('SID-NANDO3R'); arr = rd('LLEGADA-ERREZ1A'); ils = rd('APR-ILS21'); rnp = rd('APR-RNPY21')
N.update(sidDist=f(sid[-1]['Distancia total (NM)'], 1), sidN=len(sid), sidCA=f(sid[1]['Distancia (NM)'], 2),
         sidMDVIIIIIIValt=i0(sid[5]['Altitud minima (ft)']), sidMDOIVVIIalt=i0(sid[2]['Altitud minima (ft)']),
         sidMDOIVVIIIalt=i0(sid[3]['Altitud minima (ft)']), sidMDOIVIXalt=i0(sid[4]['Altitud minima (ft)']),
         sidMDVIIIIIIVD=f(sid[5]['Distancia total (NM)'], 1),
         arrDist=f(num(arr[0]['Distancia restante a THR21 (NM)']) - num(arr[-1]['Distancia restante a THR21 (NM)']), 1),
         arrTotal=f(arr[0]['Distancia restante a THR21 (NM)'], 1), arrToppuRest=f(arr[-1]['Distancia restante a THR21 (NM)'], 1),
         misDist=f(rd('FRUSTRADA-ILS21')[-1]['Distancia total desde THR21 (NM)'], 1),
         ilsN=len(ils), rnpN=len(rnp), rnpDist=f(rnp[0]['Distancia restante a THR21 (NM)'], 1),
         rnpArc=f(sum(num(r['Distancia (NM)']) for r in rnp[7:10]), 2),
         rnpGintuLeg=f(rnp[1]['Distancia (NM)'], 1), ilsGalgaLeg=f(ils[1]['Distancia (NM)'], 1),
         ilsFapLeg=f(ils[2]['Distancia (NM)'], 2), ilsFinal=f(ils[3]['Distancia (NM)'], 2), rnpFinal=f(rnp[-1]['Distancia (NM)'], 2),
         ilsGPdeg=f(math.degrees(math.atan((2600-183)*0.3048/(num(ils[3]['Distancia (NM)'])*1852))), 2))

# ---------------------------------------------------------------- vertical
tr = rd('VERTICAL-tramos')
rows = [[tex(r['tramo']), r['tipo'], tex(r['subtipo']), tex(r['conocidas']), tex(r['incognitas']), tex(r['config']),
         r'\scriptsize ' + tex(r['descripcion'])] for r in tr]
write('tab_vert_def', longtable(['Tramo', 'Tipo', 'Subtipo', 'Conocidas', 'Incógnitas', 'Config.', 'Descripción'],
    r'lll>{\raggedright\arraybackslash}p{2.5cm}ll>{\raggedright\arraybackslash}p{4.3cm}', rows,
    'Definición de los tramos del perfil vertical (\\texttt{VERTICAL-tramos.xlsx}): tipo (SPD/PTH), segundo grado de libertad (subtipo), variables conocidas e incógnitas y configuración aerodinámica BADA.',
    'tab:vdef', font=r'\scriptsize'))

rows = []; notes = {}
for r in tr:
    nota = r['nota'].strip(); mark = ''
    if nota:
        notes.setdefault(nota, len(notes) + 1); mark = r'$^{%s}$' % ('abc'[notes[nota]-1])
    rows.append([tex(r['tramo']) + mark, i0(r['h_ini_ft']), i0(r['h_fin_ft']), i0(r['cas_ini_kt']), i0(r['cas_fin_kt']),
                 i0(r['tas_ini_kt']), i0(r['tas_fin_kt']), f(r['M_fin'], 3), i0(r['vs_med_fpm']), f(r['FPA_deg'], 2),
                 f(r['Tr_med_pct'], 1), f(r['dist_NM'], 1), f(r['t_min'], 1), i0(r['fuel_kg']), i0(r['masa_fin_kg'])])
foot = ' '.join(r'$^{%s}$\,%s.' % ('abc'[v-1], tex(k)) for k, v in notes.items())
write('tab_vert_num', longtable(['Tramo', '$h_i$ (ft)', '$h_f$ (ft)', 'IAS$_i$', 'IAS$_f$', 'TAS$_i$', 'TAS$_f$', '$M_f$', 'VS (fpm)', 'FPA (°)', '$T_r$ (\\%)', '$d$ (NM)', '$t$ (min)', 'Comb. (kg)', '$m_f$ (kg)'],
    'lrrrrrrrrrrrrrr', rows,
    'Parámetros de cada tramo (\\texttt{VERTICAL-tramos.xlsx}): altitud, IAS y TAS (kt) inicial y final, Mach final, velocidad vertical media, ángulo de trayectoria medio, empuje relativo medio $T_r=T/T_{\\max}$, distancia, duración, combustible y masa final. ' + foot,
    'tab:vnum', font=r'\scriptsize'))

def leg(n): return next(r for r in tr if r['tramo'] == n)
clb = [r for r in tr if r['tramo'].startswith('C')]; cru = [r for r in tr if r['tramo'].startswith('K')]
des = [r for r in tr if r['tramo'].startswith('D')]   # como build_profile: K3 (vuelo nivelado) es crucero
toc = num(clb[-1]['dist_fin_NM']); tod = num(cru[-1]['dist_fin_NM'])
fuel = lambda L: sum(num(r['fuel_kg']) for r in L); tmin = lambda L: sum(num(r['t_min']) for r in L)
N.update(vTOC=f(toc, 1), vTOD=f(tod, 1), vNlegs=len(tr), vNclb=len(clb), vNcru=len(cru), vNdes=len(des),
         vFuelClb=i0(fuel(clb)), vFuelCru=i0(fuel(cru)), vFuelDes=i0(fuel(des)), vFuelTot=i0(fuel(tr)),
         vTime=hms(tmin(tr)*60), vTimeh=f(tmin(tr)/60, 2), vTclb=f(tmin(clb), 1), vTdes=f(tmin(des), 1),
         vMldg=i0(tr[-1]['masa_fin_kg']), vMtoc=i0(clb[-1]['masa_fin_kg']), vMtod=i0(cru[-1]['masa_fin_kg']),
         vMcruMed=i0((num(clb[-1]['masa_fin_kg']) + num(cru[-1]['masa_fin_kg']))/2),
         vHcru=i0(leg('K2')['h_fin_ft']), vMcru=f(leg('K2')['M_fin'], 3), vIAScru=i0(leg('K2')['cas_fin_kt']), vTAScru=i0(leg('K2')['tas_fin_kt']),
         vHcrossClb=i0(leg('C4')['h_fin_ft']), vHcrossDes=i0(leg('D4.1')['h_fin_ft']),
         vVIIpIIO=i0(leg('C1')['cas_ini_kt']), vVref=i0(leg('D1')['cas_fin_kt']), vVfap=i0(leg('D2.6')['cas_fin_kt']),
         vTrKIIini=f(leg('K2')['Tr_max_pct'], 1), vTrKIIfin=f(leg('K2')['Tr_min_pct'], 1), vTrCII=f(leg('C2')['Tr_med_pct'], 1),
         vTrCIVmax=f(leg('C4')['Tr_max_pct'], 1), vTrIdle=f(leg('D4.1')['Tr_med_pct'], 2),
         vTrDIII=f(leg('D3')['Tr_med_pct'], 1), vTrDIIIV=f(leg('D2.4')['Tr_med_pct'], 1),
         vVSCI=i0(leg('C1')['vs_med_fpm']), vVSDIVI=i0(leg('D4.1')['vs_med_fpm']), vVSDIVII=i0(leg('D4.2')['vs_med_fpm']),
         vFPADI=f(leg('D1')['FPA_deg'], 2), vFPADIII=f(leg('D3')['FPA_deg'], 2), vFPADIIIII=f(leg('D2.3')['FPA_deg'], 2),
         vMDVIIIIIIVh=i0(leg('C3.4')['h_fin_ft']), vMDOIVVIIIh=i0(leg('C3.2')['h_fin_ft']), vCruiseLen=f(num(leg('K2')['dist_NM']), 1),
         vDIVIlen=f(leg('D4.1')['dist_NM'], 1), vDIVIIlen=f(leg('D4.2')['dist_NM'], 1), vKIlen=f(leg('K1')['dist_NM'], 1), vKIIIlen=f(leg('K3')['dist_NM'], 1),
         vCItop=i0(leg('C1')['h_fin_ft']), vCIItop=i0(leg('C2')['h_fin_ft']), vCIIIVh=i0(leg('C3.5')['h_fin_ft']),
         vTotalD=f(tr[-1]['dist_fin_NM'], 1), vDesLen=f(num(tr[-1]['dist_fin_NM']) - tod, 1))

co = rd('VERTICAL-consumo')
rows = [[i0(r['h_crucero_ft']), r['velocidad'], f(r['Mach'], 3), f(r['TOC_NM'], 1), f(r['TOD_NM'], 1), f(r['crucero_NM'], 1),
         f(r['fuel_ascenso_kg'], 1), f(r['fuel_crucero_kg'], 1), f(r['fuel_descenso_kg'], 1), f(r['fuel_total_kg'], 1), f(r['tiempo_h'], 2), hms(num(r['tiempo_h'])*3600)] for r in co]
rows = [r[:-1] for r in rows]
write('tab_consumo', tabular(['$h$ (ft)', 'Vel.', 'Mach', 'TOC (NM)', 'TOD (NM)', 'Crucero (NM)', 'Asc. (kg)', 'Cru. (kg)', 'Des. (kg)', 'Total (kg)', '$t$ (h)'],
    'rlrrrrrrrrr', rows,
    'Consumo y tiempo de vuelo (DER 36R a THR 21) para dos altitudes y dos velocidades de crucero (\\texttt{VERTICAL-consumo.xlsx}), misma masa de referencia de crucero.',
    'tab:consumo', font=r'\scriptsize'))
c = {(i0(r['h_crucero_ft']), r['velocidad']): r for r in co}
h1 = i0(co[0]['h_crucero_ft']); h2 = i0(co[2]['h_crucero_ft'])
N.update(cHI=h1, cHII=h2, cMRCI=i0(c[(h1,'MRC')]['fuel_total_kg']), cLRCI=i0(c[(h1,'LRC')]['fuel_total_kg']),
         cMRCII=i0(c[(h2,'MRC')]['fuel_total_kg']), cLRCII=i0(c[(h2,'LRC')]['fuel_total_kg']),
         cMachLRCI=f(c[(h1,'LRC')]['Mach'], 3), cMachMRCII=f(c[(h2,'MRC')]['Mach'], 3), cMachLRCII=f(c[(h2,'LRC')]['Mach'], 3),
         cTMRCI=f(c[(h1,'MRC')]['tiempo_h'], 2), cTLRCI=f(c[(h1,'LRC')]['tiempo_h'], 2), cTMRCII=f(c[(h2,'MRC')]['tiempo_h'], 2), cTLRCII=f(c[(h2,'LRC')]['tiempo_h'], 2),
         cDiffLRCI=i0(num(c[(h1,'LRC')]['fuel_total_kg']) - num(c[(h1,'MRC')]['fuel_total_kg'])),
         cDiffH=i0(num(c[(h2,'MRC')]['fuel_total_kg']) - num(c[(h1,'MRC')]['fuel_total_kg'])),
         cDiffTLRCI=f((num(c[(h1,'MRC')]['tiempo_h']) - num(c[(h1,'LRC')]['tiempo_h']))*60, 0),
         cTOCII=f(c[(h2,'MRC')]['TOC_NM'], 1))

ck = rd('VERTICAL-comprobacion')
rows = [[r['name'], f(r['d_NM'], 1), i0(r['h_ft']), i0(r['cas_kt']), i0(r['alt_min']), i0(r['alt_max']), i0(r['ias_max']),
         'sí' if r['ok'] == '1' else r'\textbf{NO}'] for r in ck]
write('tab_comprobacion', longtable(['Fijo', '$D$ (NM)', '$h$ perfil (ft)', 'IAS perfil (kt)', 'Alt mín (ft)', 'Alt máx (ft)', 'IAS máx (kt)', 'Cumple'],
    'lrrrrrrc', rows,
    'Comprobación del perfil vertical en los fijos de la ruta (\\texttt{VERTICAL-comprobacion.xlsx}): altitud e IAS interpoladas del perfil frente a los límites del estudio horizontal (-- = sin límite; los de las aerovías están pendientes de verificar).',
    'tab:chk', font=r'\scriptsize'))
def fix(n): return next(r for r in ck if r['name'] == n)
N.update(chkN=len(ck), chkOK=sum(1 for r in ck if r['ok'] == '1'),
         chkZukkoH=i0(fix('ZUKKO')['h_ft']), chkZukkoIAS=i0(fix('ZUKKO')['cas_kt']),
         chkMDVIIIIIIV=i0(fix('MD824')['h_ft']), chkMDVIIIIIIVmin=i0(fix('MD824')['alt_min']),
         chkNANDO=i0(fix('NANDO')['h_ft']), chkPIKOG=i0(fix('PIKOG')['h_ft']),
         vTODzukko=f(num(fix('ZUKKO')['d_NM']) - tod, 1))

sb = rd('simbrief')[0]
N.update(sbBurn=i0(sb['enroute_burn']), sbTOW=i0(sb['est_tow']), sbLDW=i0(sb['est_ldw']), sbTime=hms(num(sb['est_time_enroute'])),
         sbTimeh=f(num(sb['est_time_enroute'])/3600, 2), sbAirac=sb['airac'], sbDist=i0(sb['route_distance']), sbCI=sb['costindex'],
         sbSteps=sb['stepclimb_string'].replace('/', '/\\allowbreak '), sbDiffFuel=i0(fuel(tr) - num(sb['enroute_burn'])),
         sbDiffFuelPct=f(100*(fuel(tr) - num(sb['enroute_burn']))/num(sb['enroute_burn']), 1),
         sbDiffLDW=i0(num(tr[-1]['masa_fin_kg']) - num(sb['est_ldw'])), sbMZFW=i0(sb['max_zfw']), sbMTOW=i0(sb['max_tow']),
         sbPax=sb['passengers'], sbMach=sb['cruise_mach'], sbTAS=sb['cruise_tas'], sbRoute=tex(sb['route']))

with open(os.path.join(OUT, 'nums.tex'), 'w', encoding='utf-8') as fh:
    for k, v in N.items():
        fh.write(r'\newcommand{\%s}{%s}' % (k, v) + '\n')
print('tablas:', sorted(os.listdir(OUT)))
