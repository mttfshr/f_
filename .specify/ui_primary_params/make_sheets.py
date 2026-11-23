"""Write blind J2 sheets (sheets/sheet_<module>.md) from inventory.json. Reads roles.json only for WHICH modules and
params are in scope; it never copies a role, confidence or reason. Widget (dial/numbox) is left off on purpose."""
import json, pathlib
here = pathlib.Path(__file__).parent
inv = json.load(open(here / "inventory.json"))
roles = {m: v for m, v in json.load(open(here / "roles.json")).items() if m != "_meta"}
scope = {m: {k for k, x in v.items() if "typed" not in x} for m, v in roles.items()}   # typed params (H3) are not judged
HEAD = """# Blind sheet: {m}

Mark each param **P** (primary), **S** (secondary) or **?** (unsure). Primary = it sets the character of the effect (changes
what it *is*, you reach for it live, or other params depend on it). Secondary = it scales, tunes or is set once.
Few primaries per module is typical (0 to 5), not a quota. Current widgets are left off on purpose. Notes are welcome where you hesitate.

| Param | Label | Range | Default | P / S / ? | Note |
|---|---|---|---|---|---|
"""
PILOT = ["f_vf_advect", "f_vf_glow", "f_stipple", "f_quasi", "f_vf_seeds", "f_vf_vortex", "f_tf_hatch", "f_vf_ch"]   # set-aside modules are not written (spec pool rule)
for m, names in scope.items():
    if m not in PILOT:
        continue
    rows = [p for p in inv[m] if p["name"] in names]
    typed = [p["name"] for p in inv[m] if p["name"] in roles[m] and p["name"] not in names]
    ctx = [p for p in inv[m] if p["name"] not in roles[m]]
    out = HEAD.format(m=m)
    for p in rows:
        rng = f'{p["min"]} to {p["max"]}'
        out += f'| `{p["name"]}` | {p["label"] or ""} | {rng} | {p["default"]} |  |  |\n'
    out += "\nContext, not to mark (menus and buttons that change what the params above do): " + \
           (", ".join(f'`{p["name"]}` ({p["label"] or p["type"]})' for p in ctx) or "none") + "\n"
    if typed:
        out += "\nNot on this sheet (a type rule decides the widget, spec H3): " + ", ".join(f"`{t}`" for t in typed) + "\n"
    (here / "sheets" / f"sheet_{m}.md").write_text(out)
    print(m, len(rows), "params,", len(ctx), "context")
