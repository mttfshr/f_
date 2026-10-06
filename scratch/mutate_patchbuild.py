import hashlib, os, subprocess, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
T = REPO / "tests/bench/patchbuild.py"
orig = T.read_text(); sha = hashlib.sha256(orig.encode()).hexdigest()
M = [("rect not floated in obj", '"patching_rect": [float(v) for v in rect]}\n        if n_out', '"patching_rect": list(rect)}\n        if n_out'),
     ("outlettype always written", "        if n_out:\n            box[\"outlettype\"]", "        if True:\n            box[\"outlettype\"]"),
     ("varname always written", "        if varname:\n            box[\"varname\"] = varname", "        if True:\n            box[\"varname\"] = varname"),
     ("obj returns nothing", "        self.boxes.append({\"box\": box})\n        return oid", "        self.boxes.append({\"box\": box})\n        return None"),
     ("maxclass ignored", '"maxclass": maxclass, "text": text,', '"maxclass": "newobj", "text": text,'),
     ("shared lists", "        self.boxes, self.lines = [], []", "        self.boxes, self.lines = _S, _S2"),
     ("wire swapped", '"source": [src, so], "destination": [dst, di]', '"source": [dst, di], "destination": [src, so]'),
     ("appversion shared", '"appversion": dict(APPVERSION)', '"appversion": APPVERSION'),
     ("rect not floated in wrapper", '"rect": [float(v) for v in rect]', '"rect": list(rect)'),
     ("key order changed", '"classnamespace": "box", "rect"', '"rect"')]
def run():
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", PATH="/opt/homebrew/bin:" + os.environ["PATH"])
    for p in REPO.rglob("__pycache__"):
        if ".git" not in p.parts: subprocess.run(["rm", "-rf", str(p)])
    return subprocess.run(["uv","run","--no-project","--with","numpy","python3","tests/test_bench_patchbuild.py"],cwd=REPO,env=env,capture_output=True,text=True).returncode
try:
    if run(): sys.exit("ABORT baseline red")
    print("baseline green"); surv = []
    for label, old, new in M:
        if orig.count(old) != 1: print("SKIP", label, orig.count(old)); surv.append(label + " (anchor)"); continue
        pre = "_S, _S2 = [], []\n" if label == "shared lists" else ""
        T.write_text(orig.replace(old, new).replace("APPVERSION = ", pre + "APPVERSION = ", 1) if pre else orig.replace(old, new))
        rc = run(); print(("caught    " if rc else "SURVIVED  ") + label)
        if not rc: surv.append(label)
finally:
    T.write_text(orig); assert hashlib.sha256(T.read_text().encode()).hexdigest() == sha
    for p in REPO.rglob("__pycache__"):
        if ".git" not in p.parts: subprocess.run(["rm", "-rf", str(p)])
print("restored; survivors:", surv or "none")
