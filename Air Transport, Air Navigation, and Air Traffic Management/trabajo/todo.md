# Lo que me queda del trabajo TNyCA (ruta LEMD → LLBG)

Entrega: **22-dic-2026** en PoliformaT (no se prorroga). Examen 2 (13-ene-2027) incluye el trabajo.

## Lo importante: comprobar el en-ruta
Es lo único que me bloquea el cierre. ENAV pide login, Grecia da 403 y Chipre no carga desde aquí.

- [ ] Italia / Grecia / Chipre (ENR 3 y ENR 4): comprobar que existen y sus coordenadas:
  IBREP, ADEXI, OLLEK, NEVIK, PLH, TIPUS, OTREX, AMAXI, SIT, VANZA, PIKOG.
- [ ] Comprobar las aerovías UL144, UM978 y L609 (de PIKOG a ZUKKO) y los tramos de ruta libre.
- [ ] Apuntar los límites de altitud (mínima y máxima) de cada aerovía.
- [ ] Con eso: rellenar `alt_min` / `alt_max` en `matlab/main_enroute.m`, volver a ejecutar los cuatro `main_*`, regenerar tablas y memoria y quitar el cuadro rojo de «pendiente».
- [ ] Si algo no existe o cambia de nombre (SimBrief iba con AIRAC 2503, que está obsoleto), rehacer ese tramo.

## Cartas
- [ ] Cartas de la parte en ruta marcadas, o al menos una justificación en la memoria: ENR 3.2 de ENAIRE (T257) y ENR 4.4 de AIP Francia (ETOIL, XATOS, RISEP, SOTAX) ya las tengo; el resto depende de la verificación de arriba.
- [ ] **26-nov-2026 entra el AIRAC 002.** Mirar si cambian SID 7 (NANDO3R), STAR/TRANS, ILS 21 y RNP Y 21. Si cambian: bajar las nuevas, ejecutar `cartas_marcadas/build.sh` y los `main_*`, y regenerar la memoria.
- [ ] Mirar la carta RNP Y 21 marcada: tiene un error real de unos 0,5 mm, no los 0,16 mm que salen del ajuste. Revisar a ojo que el arco RF cae bien.

## Memoria (PDF)
- [ ] Leerla entera y decir qué cambiar. Tiene 37 páginas.
- [ ] Revisar las suposiciones y comprobar que están todas bien explicadas (SID, enlace TOPPU→GALGA, enlace TOPPU→GINTU asumido, ZUKKO sin límite de 250 kt, categoría C).
- [ ] El Vref calculado (~144 kt) queda por encima del rango de la categoría C (121–140 kt). Decidir si se comenta o se ajusta.
- [ ] Dos tramos de descenso (D3 y D2.4) piden un empuje por debajo de ralentí, es decir, aerofrenos. Explicarlo o rehacerlo.
- [ ] Tras el pulido del código: regenerar figuras y tablas (`memoria/xlsx2csv.m`, `gen_tablas.py`, `latexmk`) para que coincidan con los nuevos PNG y xlsx.
- [ ] Comentar la errata de la carta ILS 21 (latitud de GALGA 31°09'25" en una tabla, es 32°09'25"), ya anotada en el apéndice D.

## Preguntas / decisiones mías
- [ ] Preguntar al profesor si el tiempo con viento va con d/TAS (3:52:35) o d/GS (3:38:39). Tengo ambos calculados, solo cambia cuál sale como principal.
- [ ] Decidir si dejo el criterio literal d/TAS como principal si no contesta.

## Entrega
- [ ] Juntar y comprobar: PDF de la memoria, cartas marcadas, `.kml`, programas Matlab y tablas Excel.
- [ ] Comprobar que el código corre desde cero (BADA 3.14 va aparte, no se entrega con el código).
- [ ] Subir a PoliformaT antes del 22-dic.
