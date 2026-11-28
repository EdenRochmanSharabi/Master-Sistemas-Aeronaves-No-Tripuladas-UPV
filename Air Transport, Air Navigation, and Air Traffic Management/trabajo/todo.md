# Lo que me queda del trabajo TNyCA (ruta LEMD → LLBG)

Entrega: **22-dic-2026** en PoliformaT (no se prorroga). Examen 2 (13-ene-2027) incluye el trabajo.

## Lo importante: comprobar el en-ruta
Es lo único que me bloquea el cierre. ENAV pide login, Grecia da 403 y Chipre no carga desde aquí. Probar con EUROCONTROL EAD Basic (registro gratuito), que reúne los AIP de Italia, Grecia y Chipre.

- [ ] Italia / Grecia / Chipre (ENR 3 y ENR 4): comprobar que existen y sus coordenadas:
  IBREP, ADEXI, OLLEK, NEVIK, PLH, TIPUS, OTREX, AMAXI, SIT, VANZA, PIKOG.
- [ ] Comprobar las aerovías UL144, UM978 y L609 (de PIKOG a ZUKKO) y los tramos de ruta libre.
- [ ] Apuntar los límites de altitud (mínima y máxima) de cada aerovía.
- [ ] Con eso: rellenar `alt_min` / `alt_max` en `matlab/main_enroute.m`, volver a ejecutar los cuatro `main_*`, regenerar tablas y memoria.
- [ ] Si algo no existe o cambia de nombre (SimBrief iba con AIRAC 2503, que está obsoleto), rehacer ese tramo.
- [ ] Punto exacto donde la ruta cruza de la FIR de España a la de Francia (entre PTC y SOTAX): sacarlo del AIP Francia y marcarlo.

## Cartas
- [ ] Añadir a `cartas/` los extractos de ENR: ENR 3.2 de ENAIRE (T257) y ENR 4.4 de AIP Francia (ETOIL, XATOS, RISEP, SOTAX); el resto depende de la verificación de arriba.
- [ ] **AIRAC 002 (26-nov-2026) ya está en vigor.** Mirar si cambian SID 7 (NANDO3R), STAR/TRANS, ILS 21 y RNP Y 21 (Israel AMDT 002/2026). Si cambian: bajar las nuevas, ejecutar `cartas_marcadas/build.sh` y los `main_*`, y regenerar la memoria. El siguiente ciclo empieza el 24-dic.
- [ ] Mirar la carta RNP Y 21 marcada: tiene un error real de unos 0,5 mm, no los 0,16 mm que salen del ajuste. Revisar que el arco RF cae bien.

## Memoria (PDF)
- [ ] Leerla entera y decir qué cambiar. Tiene 40 páginas.
- [ ] Capturas de Google Earth de la ruta completa, la SID, la llegada con la ILS y el arco RF (los KML están en `matlab/out/`). Ya hay vistas sobre OpenStreetMap, pero el enunciado pide Google Earth.
- [ ] Revisar las suposiciones y comprobar que están todas bien explicadas.
- [ ] D2.4 (ANOZA → TOPPU) sigue pidiendo empuje bajo ralentí (aerofrenos): está justificado en la memoria, decidir si basta.
- [ ] Comentar la errata de la carta ILS 21 (latitud de GALGA 31°09'25" en una tabla, es 32°09'25"), ya anotada en el apéndice D.
- [ ] Opcional: virajes de paso con puntos auxiliares (fly-by) en los fijos con giro grande, comparar velocidades con la base de prestaciones de Eurocontrol, perfil vertical de la RNP Y.

## Preguntas / decisiones mías
- [ ] Preguntar al profesor si el tiempo con viento va con d/TAS (3:52:35) o d/GS (3:38:39). Tengo ambos calculados, solo cambia cuál sale como principal.
- [ ] Decidir si dejo el criterio literal d/TAS como principal si no contesta.

## Entrega
- [ ] Juntar y comprobar: PDF de la memoria, cartas marcadas, `.kml`, programas Matlab y tablas Excel.
- [ ] Comprobar que el código corre desde cero (BADA 3.14 va aparte, no se entrega con el código).
- [ ] Subir a PoliformaT antes del 22-dic.
