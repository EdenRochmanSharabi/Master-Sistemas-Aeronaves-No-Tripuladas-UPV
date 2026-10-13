"""Busca datos personales en los archivos del repositorio (texto, HTML y PDF).

Uso: python3 revisar_datos_personales.py [archivos...]   (sin argumentos: todo el repo)
Sale con código 1 si encuentra algo.

Detecta: correos, teléfonos españoles, DNI/NIE, IBAN, metadatos de PDF con correos
y, si existe la variable de entorno DATOS_PERSONALES (un término por línea; en GitHub
es un secreto, así la lista no es pública), cualquiera de esos términos.
Excepciones en .github/datos_permitidos.txt (un texto por línea).
"""
import os
import re
import subprocess
import sys

PATRONES = {
    "correo": re.compile(r"[\w.%+-]+@[\w-]+(?:\.[\w-]+)*\.[a-z]{2,}", re.I),
    "teléfono": re.compile(r"(?<![\d.,])(?:\+34[\s.-]?)?[679]\d{2}[\s.-]?\d{3}[\s.-]?\d{3}(?![\d.,])"),
    "DNI/NIE": re.compile(r"\b(?:\d{8}|[XYZ]\d{7})[A-HJ-NP-TV-Z]\b"),
    "IBAN": re.compile(r"\bES\d{2}(?:\s?\d{4}){5}\b"),
}
BASE64 = re.compile(r"data:[\w/+.-]+;base64,[A-Za-z0-9+/=]+")
TEXTO = {".md", ".txt", ".html", ".htm", ".csv", ".json", ".tex", ".py", ".yml", ".yaml", ".svg"}


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout


def leer(ruta):
    ext = os.path.splitext(ruta)[1].lower()
    if ext == ".pdf":
        texto = subprocess.run(["pdftotext", "-q", ruta, "-"], capture_output=True, text=True).stdout
        meta = subprocess.run(["pdfinfo", ruta], capture_output=True, text=True).stdout
        return texto + "\n" + meta
    if ext in TEXTO:
        with open(ruta, encoding="utf8", errors="ignore") as fh:
            return BASE64.sub("", fh.read())  # las imágenes incrustadas no son texto
    return ""  # binarios (imágenes, zip...) no se revisan


def main():
    raiz = git("rev-parse", "--show-toplevel").strip()
    os.chdir(raiz)
    archivos = sys.argv[1:] or [f for f in git("-c", "core.quotepath=false", "ls-files", "-z").split("\0") if f]
    archivos = [f for f in archivos if os.path.isfile(f) and not f.startswith(".github/")]
    permitidos = set()
    if os.path.exists(".github/datos_permitidos.txt"):
        permitidos = {l.strip().lower() for l in open(".github/datos_permitidos.txt", encoding="utf8")
                      if l.strip() and not l.startswith("#")}
    propios = [t.strip() for t in os.environ.get("DATOS_PERSONALES", "").splitlines() if t.strip()]

    hallazgos = []
    for f in archivos:
        texto = leer(f)
        if not texto:
            continue
        for tipo, patron in PATRONES.items():
            for m in set(patron.findall(texto)):
                if m.lower() not in permitidos:
                    hallazgos.append((f, tipo, m))
        bajo = texto.lower()
        for t in propios:
            if t.lower() in bajo:
                hallazgos.append((f, "dato personal de la lista", t[:2] + "…"))  # no se imprime entero

    if hallazgos:
        print("Posibles datos personales encontrados:")
        for f, tipo, m in sorted(hallazgos):
            print(f"  {f}: {tipo}: {m}")
        print("\nSi es un falso positivo, añade el texto a .github/datos_permitidos.txt")
        sys.exit(1)
    print(f"Sin datos personales en {len(archivos)} archivos.")


if __name__ == "__main__":
    main()
