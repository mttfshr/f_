import hashlib, os, subprocess, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
T = REPO / "src/f_vf_seeds/definition.py"
orig = T.read_text(); sha = hashlib.sha256(orig.encode()).hexdigest()
M = [("bypass_target drops the merge stage", '"bypass_target": ["1c", "4"],', '"bypass_target": ["4"],'),
     ("seed coord outlet from the wrong stage", '"outlet_source": {2: ["1c", 2]},', '"outlet_source": {2: ["1c", 1]},'),
     ("vecfield state prepend gets a target", '"fanout": [["1a", 0], ["1b", 0], ["render_1", 2], ["render_2", 2]], "state_nodes": []},',
      '"fanout": [["1a", 0], ["1b", 0], ["render_1", 2], ["render_2", 2]], "state_nodes": ["4"]},'),
     ("range menu from outlet 0", "range_menu_outlet=2),", "range_menu_outlet=0),"),
     ("salt A changed", "_SALTS_A = (127.1,", "_SALTS_A = (127.2,"),
     ("merge input swapped", '["1b", 0, "1c", 3]', '["1b", 0, "1c", 4]'),
     ("bomb loses active_blend", ', pix_attr="active_blend"),', '),'),
     ("density not shared", '_ui("density", 0.0, 1.0, 0.5, "Density", "Seed spacing \\u2014 log-mapped, higher = more seeds", _AB),',
      '_ui("density", 0.0, 1.0, 0.5, "Density", "Seed spacing \\u2014 log-mapped, higher = more seeds", _AB, pix_shared_attrui=False),'),
     ("legacy label varnames dropped", '"element_box": {f"{p[\'name\']}.label": {"varname": None} for p in _PARAMS},', ''),
     ("a hint changed", '"Seed position randomness (0=regular grid', '"Seed position randomnes (0=regular grid')]
def run():
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", PATH="/opt/homebrew/bin:" + os.environ["PATH"])
    for p in REPO.rglob("__pycache__"):
        if ".git" not in p.parts: subprocess.run(["rm", "-rf", str(p)])
    for t in ("tests/test_build_seeds_keys.py", "tests/test_drift.py"):
        r = subprocess.run(["uv","run","--no-project","--with","numpy","python3",t],cwd=REPO,env=env,capture_output=True,text=True)
        if r.returncode: return r.returncode
    return 0
try:
    if run(): sys.exit("ABORT baseline red")
    print("baseline green"); surv=[]
    for label, old, new in M:
        if orig.count(old) != 1: print("SKIP", label, orig.count(old)); surv.append(label+" (anchor)"); continue
        T.write_text(orig.replace(old, new)); rc = run()
        print(("caught    " if rc else "SURVIVED  ") + label)
        if not rc: surv.append(label)
finally:
    T.write_text(orig); assert hashlib.sha256(T.read_text().encode()).hexdigest() == sha
    for p in REPO.rglob("__pycache__"):
        if ".git" not in p.parts: subprocess.run(["rm", "-rf", str(p)])
print("restored; survivors:", surv or "none")
