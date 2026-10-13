"""Regenera README.md: lista de últimos archivos subidos y de asignaturas."""
import os
import subprocess
from urllib.parse import quote

PAGES = "https://edenrochmansharabi.github.io/Master-Sistemas-Aeronaves-No-Tripuladas-UPV/"
MAX_ARCHIVOS = 15  # ponytail: tope fijo; subirlo si se quiere ver más historial


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout


def archivos_recientes():
    ficheros = [f for f in git("-c", "core.quotepath=false", "ls-files", "-z").split("\0")
                if f and not f.startswith(".github/") and os.path.basename(f) != "README.md"]
    con_fecha = []
    for f in ficheros:
        fecha = git("log", "-1", "--format=%cs|%ct", "--", f).strip()
        if fecha:
            dia, marca = fecha.split("|")
            con_fecha.append((int(marca), dia, f))
    con_fecha.sort(reverse=True)
    return con_fecha[:MAX_ARCHIVOS]


INICIO, FIN = "<!-- html:inicio -->", "<!-- html:fin -->"


def enlaces_html_asignaturas(asignaturas):
    """En el README de cada asignatura, sección autogenerada con sus HTML publicados."""
    htmls = [f for f in git("-c", "core.quotepath=false", "ls-files", "-z", "*.html").split("\0") if f]
    for a in asignaturas:
        propios = sorted(f for f in htmls if f.startswith(a + "/"))
        ruta = os.path.join(a, "README.md")
        texto = open(ruta, encoding="utf8").read() if os.path.exists(ruta) else f"# {a}\n"
        if INICIO in texto:
            texto = texto[:texto.index(INICIO)].rstrip() + "\n" + texto[texto.index(FIN) + len(FIN):].lstrip("\n")
        if propios:
            filas = [f"- [{os.path.relpath(h, a)}]({PAGES}{quote(h)})" for h in propios]
            bloque = "\n".join([INICIO, "## Ver en el navegador", "", *filas, FIN])
            texto = texto.rstrip() + "\n\n" + bloque + "\n"
        with open(ruta, "w", encoding="utf8") as fh:
            fh.write(texto)


def main():
    asignaturas = sorted((d for d in os.listdir(".") if os.path.isdir(d) and not d.startswith(".")), key=str.lower)
    recientes = archivos_recientes()
    if recientes:
        filas = []
        for _, dia, f in recientes:
            enlace = f"[{os.path.basename(f)}](<{f}>)"
            if f.endswith(".html"):  # los HTML se abren publicados en GitHub Pages
                enlace = f"[{os.path.basename(f)}]({PAGES}{quote(f)}) (se abre en el navegador)"
            filas.append(f"- {dia} · {enlace} · {os.path.dirname(f) or 'raíz'}")
    else:
        filas = ["Todavía no hay archivos."]
    lineas = [
        "# Máster Universitario en Sistemas de Aeronaves no Tripuladas y Tecnologías Asociadas · UPV",
        "",
        "Apuntes de Eden R.S. para el máster de la Universitat Politècnica de València.",
        "",
        "## Archivos",
        "",
        "Últimos archivos subidos (se actualiza solo en cada subida):",
        "",
        *filas,
        "",
        "## Asignaturas",
        "",
        *[f"- [{a}](<{a}/>)" for a in asignaturas],
        "",
    ]
    with open("README.md", "w", encoding="utf8") as fh:
        fh.write("\n".join(lineas))
    enlaces_html_asignaturas(asignaturas)


if __name__ == "__main__":
    main()
