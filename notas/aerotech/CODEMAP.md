# CODEMAP (notas/aerotech)
Code lives in the local project dir (notas/aertech, iCloud); only tracking files are in this repo. The grades CSV is not published (names of classmates).
- notas_parcial1.csv: source data (alumno,nota); empty nota = no presentado (null).
- config.json: csv path, pass mark, output names.
- graficos.py: load_config, load_grades, compute_stats, plot, stats_tex, main (--json, --highlight). Writes graficos.png and stats.tex.
- graficos.tex: LaTeX report, \input{stats.tex}; caption still has "(5)" typed by hand.
- test_graficos.py: asserts on a small frame and on the real CSV (143/139/117).
