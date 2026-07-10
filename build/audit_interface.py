#!/usr/bin/env python3
"""
audit_interface.py — f_ bpatcher interface contract checker

Builds a forward cord graph for each patcher, then traces UI controls to their
terminal destinations before making any judgments. This correctly handles
patchers where some UI controls target downstream objects (e.g. jit.fx.cf.tiltshift)
rather than the jit.gl.pix codebox.

Checks:
  1. Param coverage:  every codebox Param has a UI control whose forward path
                      reaches the pix object (via attrui or param_connect)
  2. UI orphans:      UI controls whose forward path reaches the pix but the
                      attr name is not a codebox Param
  3. Param usage:     every declared Param is used in codebox logic
  4. Inlet coverage:  every codebox `in N` has a patchcord into pix inlet N
  5. Outlet coverage: every codebox `out N` has a patchcord from pix outlet N

Skips patchers with no jit.gl.pix.

Usage:
    build/py.sh build/audit_interface.py [--patcher NAME]
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict

PATCHERS_DIR = Path(__file__).parent.parent / "package" / "patchers"

SKIP = {
    "f_modules", "f_texrouter", "f_util_matrix_2",
    "f_util_profile", "f_chladni_audio",
    "f_vf_vortex_multi_version",
}

# Params that need no UI — infrastructure / inlet-driven
INFRA_PARAMS = {"bypass"}

# Params whose names suggest they are inlet-modulated scalars, not UI params.
# These get a softer warning rather than a hard flag.
def is_mod_amt_param(name):
    return re.search(r'_mod_amt_', name) or name in {"src_vecfield", "src_mode", "era_clock"}

# ── box classification ────────────────────────────────────────────────────────

UI_CLASSES = {"live.dial", "live.numbox", "live.menu", "slider", "number", "umenu"}
PASSTHROUGH_CLASSES = {
    "newobj",   # route, routepass, prepend, zl, etc.
    "message",
    "js",
    "jsui",     # bypass_toggle — treat as passthrough for graph walk
}

def classify_box(box):
    cls = box.get("maxclass", "")
    text = box.get("text", "")
    if "jit.gl.pix" in text:
        return "pix"
    if cls == "attrui":
        return "attrui"
    if cls in UI_CLASSES:
        return "ui"
    if cls == "inlet":
        return "inlet"
    if cls == "outlet":
        return "outlet"
    return "other"

# ── graph construction ────────────────────────────────────────────────────────

def build_graph(boxes, lines):
    """
    Returns:
      id_to_box   — dict: box_id -> box dict
      fwd         — dict: (src_id, src_outlet) -> list of (dst_id, dst_inlet)
      rev         — dict: (dst_id, dst_inlet)  -> list of (src_id, src_outlet)
    """
    id_to_box = {b["box"]["id"]: b["box"] for b in boxes}
    fwd = defaultdict(list)
    rev = defaultdict(list)
    for line in lines:
        pl = line.get("patchline", {})
        src = pl.get("source", [])
        dst = pl.get("destination", [])
        if src and dst:
            fwd[(src[0], src[1])].append((dst[0], dst[1]))
            rev[(dst[0], dst[1])].append((src[0], src[1]))
    return id_to_box, fwd, rev

# ── forward walk ─────────────────────────────────────────────────────────────

def walk_forward(start_id, start_outlet, id_to_box, fwd, visited=None):
    """
    Walk forward from (start_id, start_outlet), following all cords.
    Returns list of Terminal dicts:
      {"type": "pix",      "box": box_dict}
      {"type": "attrui",   "box": box_dict, "attr": str, "pix_id": str|None}
      {"type": "external", "box": box_dict}   # tiltshift, js sink, etc.
      {"type": "outlet",   "box": box_dict}   # patcher outlet
    We stop recursing at pix, attrui, patcher outlet, or external terminals.
    Passthrough objects (route, js, message, etc.) are traversed.
    """
    if visited is None:
        visited = set()

    key = (start_id, start_outlet)
    if key in visited:
        return []
    visited = visited | {key}

    terminals = []
    nexts = fwd.get(key, [])

    if not nexts:
        # dead end — the cord goes nowhere (or this is a terminal with no further cords)
        box = id_to_box.get(start_id, {})
        cls = classify_box(box)
        if cls not in ("ui", "other", "inlet"):
            terminals.append({"type": "dead_end", "box": box})
        return terminals

    for (dst_id, dst_inlet) in nexts:
        box = id_to_box.get(dst_id, {})
        cls = classify_box(box)

        if cls == "pix":
            terminals.append({"type": "pix", "box": box})

        elif cls == "attrui":
            attr = box.get("attr", "")
            # Does this attrui itself connect to the pix?
            pix_id = None
            for (nxt_id, _) in fwd.get((dst_id, 0), []):
                nbox = id_to_box.get(nxt_id, {})
                if classify_box(nbox) == "pix":
                    pix_id = nxt_id
                    break
            terminals.append({"type": "attrui", "box": box, "attr": attr, "pix_id": pix_id})

        elif cls == "outlet":
            terminals.append({"type": "outlet", "box": box})

        elif cls == "ui":
            # UI control in the middle of a chain (e.g. route -> dial -> attrui)
            # The dial is a passthrough here — walk from its outlet
            sub = walk_forward(dst_id, 0, id_to_box, fwd, visited)
            terminals.extend(sub)

        else:
            # passthrough or unknown — keep walking from all outlets of this box
            numinlets = box.get("numinlets", 1)
            numoutlets = box.get("numoutlets", 1)
            has_onward = False
            for out_idx in range(numoutlets):
                onward = fwd.get((dst_id, out_idx), [])
                if onward:
                    has_onward = True
                    sub = walk_forward(dst_id, out_idx, id_to_box, fwd, visited)
                    terminals.extend(sub)
            if not has_onward:
                terminals.append({"type": "external", "box": box})

    return terminals

# ── codebox helpers ───────────────────────────────────────────────────────────

def find_pix(boxes):
    for b in boxes:
        box = b.get("box", {})
        if "jit.gl.pix" in box.get("text", ""):
            return box
    return None

def find_codebox(pix_box):
    sub = pix_box.get("patcher")
    if not sub:
        return None
    for b in sub.get("boxes", []):
        box = b.get("box", {})
        if box.get("maxclass") == "codebox":
            return box.get("code", "")
    return None

def parse_codebox_params(code):
    return set(re.findall(r'\bParam\s+(\w+)\s*\(', code))

def parse_gen_ins(pix_box):
    sub = pix_box.get("patcher", {})
    ins = set()
    for b in sub.get("boxes", []):
        m = re.match(r'^in\s+(\d+)$', b.get("box", {}).get("text", "").strip())
        if m:
            ins.add(int(m.group(1)))
    return ins

def parse_gen_outs(pix_box):
    sub = pix_box.get("patcher", {})
    outs = set()
    for b in sub.get("boxes", []):
        m = re.match(r'^out\s+(\d+)$', b.get("box", {}).get("text", "").strip())
        if m:
            outs.add(int(m.group(1)))
    return outs

def param_used_in_logic(param, code):
    lines = code.splitlines()
    non_decl = [l for l in lines if not re.match(r'\s*Param\s+' + re.escape(param) + r'\s*\(', l)]
    return bool(re.search(r'\b' + re.escape(param) + r'\b', "\n".join(non_decl)))

# ── per-patcher audit ─────────────────────────────────────────────────────────

def audit_patcher(path):
    issues = []
    info = []

    with open(path) as f:
        data = json.load(f)

    boxes_raw = data.get("patcher", {}).get("boxes", [])
    lines = data.get("patcher", {}).get("lines", [])

    pix = find_pix(boxes_raw)
    if pix is None:
        return None, []

    code = find_codebox(pix)
    if code is None:
        issues.append("⚠  jit.gl.pix found but no codebox in gen subpatcher")
        return issues, info

    pix_id = pix["id"]
    id_to_box, fwd, rev = build_graph(boxes_raw, lines)

    cb_params = parse_codebox_params(code)
    cb_ins    = parse_gen_ins(pix)
    cb_outs   = parse_gen_outs(pix)

    # ── build param->UI coverage map via graph walk ───────────────────────────
    # For every UI control box, walk forward and collect terminals.
    # Terminal "attrui reaching pix" gives us attr->pix coverage.
    # Terminal "pix directly" (via param_connect) also counts.

    # params covered by a UI->attrui->pix or UI->pix path
    covered_params = set()   # codebox param names with UI coverage
    # attrs that reach pix but are NOT codebox params (potential orphans)
    external_pix_attrs = set()

    for b_raw in boxes_raw:
        box = b_raw.get("box", {})
        cls = classify_box(box)
        if cls != "ui":
            continue

        bid = box["id"]
        # Walk forward from outlet 0 (the value outlet for live.*)
        terminals = walk_forward(bid, 0, id_to_box, fwd)

        for t in terminals:
            if t["type"] == "attrui" and t.get("pix_id") == pix_id:
                attr = t["attr"]
                if attr in cb_params:
                    covered_params.add(attr)
                elif attr and attr not in INFRA_PARAMS:
                    external_pix_attrs.add(attr)
            elif t["type"] == "pix" and t["box"]["id"] == pix_id:
                # Direct UI->pix connection — check param_connect
                pc = box.get("param_connect", "")
                if "::" in pc:
                    param_name = pc.split("::")[-1]
                    if param_name in cb_params:
                        covered_params.add(param_name)

    # ── 1. Param coverage ────────────────────────────────────────────────────
    checkable = cb_params - INFRA_PARAMS
    missing = checkable - covered_params
    for p in sorted(missing):
        if is_mod_amt_param(p):
            issues.append(f"ℹ  param '{p}' has no UI — likely inlet-modulated (expected)")
        else:
            issues.append(f"⚠  param '{p}' declared in codebox — no UI control reaches pix")

    # ── 2. UI orphans reaching pix ───────────────────────────────────────────
    # external_pix_attrs are attruis wired to pix but not in codebox
    # These are genuine mismatches (UI sets a pix attr that the codebox doesn't declare)
    for attr in sorted(external_pix_attrs):
        if attr not in INFRA_PARAMS:
            issues.append(f"⚠  UI control targets pix attr '{attr}' but no codebox Param found")

    # ── 3. Param usage ───────────────────────────────────────────────────────
    for p in sorted(cb_params):
        if p not in INFRA_PARAMS and not param_used_in_logic(p, code):
            issues.append(f"⚠  param '{p}' declared but never used in codebox logic")

    # ── 4. Inlet coverage ────────────────────────────────────────────────────
    connected_inlets = {
        dst[1]
        for line in lines
        for dst in [line.get("patchline", {}).get("destination", [])]
        if dst and dst[0] == pix_id
    }
    for n in sorted(cb_ins):
        if (n - 1) not in connected_inlets:
            issues.append(f"⚠  codebox 'in {n}' (pix inlet {n-1}) has no patchcord connection")

    # ── 5. Outlet coverage ───────────────────────────────────────────────────
    connected_outlets = {
        src[1]
        for line in lines
        for src in [line.get("patchline", {}).get("source", [])]
        if src and src[0] == pix_id
    }
    for n in sorted(cb_outs):
        if (n - 1) not in connected_outlets:
            issues.append(f"⚠  codebox 'out {n}' (pix outlet {n-1}) has no patchcord connection")

    info.append(f"params={sorted(cb_params - INFRA_PARAMS)}  ins={sorted(cb_ins)}  outs={sorted(cb_outs)}")
    return issues, info

# ── main ──────────────────────────────────────────────────────────────────────

def main():
    target = None
    if "--patcher" in sys.argv:
        idx = sys.argv.index("--patcher")
        target = sys.argv[idx + 1]

    paths = sorted(PATCHERS_DIR.glob("*.maxpat"))
    if target:
        paths = [p for p in paths if p.stem == target or p.stem == f"f_{target}"]

    total_issues = 0
    skipped = []
    results = []

    for path in paths:
        name = path.stem
        if name in SKIP:
            skipped.append(name)
            continue
        issues, info = audit_patcher(path)
        if issues is None:
            skipped.append(f"{name} (no jit.gl.pix)")
            continue
        results.append((name, issues, info))
        total_issues += len([i for i in issues if i.startswith("⚠")])

    print("=" * 64)
    print("f_ interface contract audit")
    print("=" * 64)

    for name, issues, info in results:
        warnings = [i for i in issues if i.startswith("⚠")]
        notes    = [i for i in issues if i.startswith("ℹ")]
        status = "✓" if not warnings else "✗"
        print(f"\n{status} {name}")
        if info:
            print(f"  {info[0]}")
        for issue in issues:
            print(f"  {issue}")

    print()
    print("─" * 64)
    print(f"Checked: {len(results)}  Warnings: {total_issues}  Skipped: {len(skipped)}")
    if skipped:
        print(f"Skipped: {', '.join(skipped)}")
    print("=" * 64)

if __name__ == "__main__":
    main()
