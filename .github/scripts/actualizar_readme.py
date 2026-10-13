"""Regenera README.md: lista de últimos archivos subidos y de asignaturas."""
import os
import subprocess

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


def main():
    asignaturas = sorted((d for d in os.listdir(".") if os.path.isdir(d) and not d.startswith(".")), key=str.lower)
    recientes = archivos_recientes()
    if recientes:
        filas = [f"- {dia} · [{os.path.basename(f)}](<{f}>) · {os.path.dirname(f) or 'raíz'}" for _, dia, f in recientes]
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


if __name__ == "__main__":
    main()
