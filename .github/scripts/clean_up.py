"""clean-up: falla si encuentra texto prohibido en archivos (texto, HTML y PDF), nombres de archivo,
autores o mensajes de commit. Los patrones van codificados para que este archivo no contenga los propios términos.
Uso: python3 clean_up.py   (revisa todo lo versionado y los últimos 200 commits)"""
import base64, os, re, subprocess, sys
CI = re.compile(base64.b64decode("Y2xhdWRlfGFudGhyb3BpY3xcYmxsbXM/XGJ8bGFyZ2UgbGFuZ3VhZ2UgbW9kZWx8Y2hhdC0/Z3B0fFxiZ3B0Wy0gXT9cZHxvcGVuYWl8Z2VtaW5pfGNvcGlsb3R8Y28tYXV0aG9yZWQtYnl8Z2VuZXJhdGVkIHdpdGh8Z2VuZXJhZG8gY29ufGdlbmVyYWRvIHBvciAoPzppYXx1bmEgaWEpfGludGVsaWdlbmNpYSBhcnRpZmljaWFsfGlhIGdlbmVyYXRpdmF8YXJ0aWZpY2lhbCBpbnRlbGxpZ2VuY2V8YWktZ2VuZXJhdGVkfHN1YmFnZW50fHNvbm5ldHxcYm9wdXNcYnxcYmhhaWt1XGJ8ZmFibGUgNXxwb255dGFpbA==").decode(), re.I)
CS = re.compile(base64.b64decode("XGJJQVxifFxiQUlcYg==").decode())
TEXTO = {".md", ".txt", ".html", ".htm", ".css", ".js", ".json", ".py", ".svg", ".csv", ".yml", ".yaml", ".sh", ".tex"}
BASE64 = re.compile(r"data:[\w/+.-]+;base64,[A-Za-z0-9+/=]+")

def git(*a): return subprocess.run(["git", "-c", "core.quotepath=false", *a], capture_output=True, text=True, check=True).stdout

def texto(ruta):
    ext = os.path.splitext(ruta)[1].lower()
    if ext == ".pdf":
        return subprocess.run(["pdftotext", "-q", ruta, "-"], capture_output=True, text=True).stdout + subprocess.run(["pdfinfo", ruta], capture_output=True, text=True).stdout
    if ext in TEXTO:
        return BASE64.sub("", open(ruta, encoding="utf8", errors="ignore").read())
    return ""

def revisa(donde, t, hall):
    for rx in (CI, CS):
        m = rx.search(t)
        if m:
            a = max(0, m.start() - 30); hall.append("%s: «%s»" % (donde, t[a:m.end() + 30].replace("\n", " "))); break

os.chdir(git("rev-parse", "--show-toplevel").strip())
hall = []
for f in [f for f in git("ls-files", "-z").split("\0") if f]:
    if f.startswith(".github/") or not os.path.isfile(f): continue
    revisa("nombre " + f, os.path.basename(f), hall); revisa(f, texto(f), hall)
for c in git("log", "-200", "--format=%H%x1f%an <%ae>%x1f%B%x1e").split("\x1e"):
    if c.strip():
        h, autor, msg = (c.strip().split("\x1f") + ["", ""])[:3]; revisa("commit " + h[:8], autor + "\n" + msg, hall)
if hall:
    print("clean-up: BLOQUEADO"); print("\n".join(hall)); sys.exit(1)
print("clean-up: limpio")
