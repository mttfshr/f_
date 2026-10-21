#!/usr/bin/env python3
"""
sweep_unguarded_samples.py -- which shipped codeboxes call sample() with a coordinate that can leave [0, 1]
and has no explicit guard?  Written 2026-10-20 after the boundmode probes found that a bare sample() WRAPS its
x coordinate on a pix-to-pix chain (HANDOFF 2026-10-20): a mirror that clamps is then wrong exactly where a
codebox reads out of range without clamping or fract()ing its own coordinate.

A heuristic, not a proof. For every `sample(inN, <coord>)` it substitutes stored variables (up to 3 levels, from
the latest earlier assignment) and classifies the coordinate:
  safe      no arithmetic on uv / norm in the vec(...) components
  guarded   contains clamp( fract( wrap( mod( min( max( smoothstep( (an explicit guard of some kind)
  UNGUARDED arithmetic and no guard anywhere in the (substituted) expression  <- the candidates
Run:  python3 tests/records/sweep_unguarded_samples.py            (stdlib only; read-only)
      python3 tests/records/sweep_unguarded_samples.py --all       (also list safe and guarded calls)
"""
import ast
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
GUARDS = ("clamp(", "fract(", "wrap(", "mod(", "min(", "max(", "smoothstep(", "saturate(")


def codeboxes(mod_dir):
    """(label, text) for every shipped codebox of a module: inline strings in definition.py and the .gen files it names."""
    out, seen = [], set()
    d = mod_dir / "definition.py"
    if not d.exists():
        return out
    tree = ast.parse(d.read_text())
    consts = {}
    for n in ast.walk(tree):
        if isinstance(n, ast.Assign) and isinstance(n.value, ast.Constant) and isinstance(n.value.value, str):
            for t in n.targets:
                if isinstance(t, ast.Name):
                    consts[t.id] = n.value.value
    for n in ast.walk(tree):
        if isinstance(n, ast.Dict):
            for k, v in zip(n.keys, n.values):
                if isinstance(k, ast.Constant) and k.value == "codebox":
                    text = v.value if isinstance(v, ast.Constant) and isinstance(v.value, str) else consts.get(getattr(v, "id", ""))
                    if text and text not in seen:
                        seen.add(text)
                        out.append(("inline", text))
    for n in ast.walk(tree):
        if isinstance(n, ast.Constant) and isinstance(n.value, str) and n.value.endswith(".gen"):
            g = mod_dir / Path(n.value).name
            if g.exists() and g.name not in seen:
                seen.add(g.name)
                out.append((g.name, g.read_text()))
    return out


def calls(text):
    """Yield (line_no, coord_expr) for each sample( call, with balanced parentheses."""
    for m in re.finditer(r"\bsample\s*\(", text):
        i, depth, args, cur = m.end(), 1, [], []
        while i < len(text) and depth:
            c = text[i]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    break
            if c == "," and depth == 1:
                args.append("".join(cur)); cur = []
            else:
                cur.append(c)
            i += 1
        args.append("".join(cur))
        if len(args) >= 2:
            yield text.count("\n", 0, m.start()) + 1, ",".join(args[1:]).strip()


def substitute(expr, text, upto_line, depth=3):
    """Replace identifiers by their latest earlier assignment (one scalar or vec expression) a few levels deep."""
    lines = text.split("\n")[:upto_line - 1]
    prior = "\n".join(lines)
    for _ in range(depth):
        changed = False
        for name in set(re.findall(r"\b[A-Za-z_]\w*\b", expr)):
            if name in ("vec", "uv", "norm", "x", "y", "z", "in1", "in2", "in3", "in4", "in5", "sample", "float"):
                continue
            ms = list(re.finditer(rf"(?m)^\s*{re.escape(name)}\s*=\s*([^;]+);", prior))
            if ms:
                expr = re.sub(rf"\b{re.escape(name)}\b", "(" + ms[-1].group(1).strip() + ")", expr)
                changed = True
        if not changed:
            break
    return expr


def classify(expr):
    flat = re.sub(r"\s+", "", expr)
    if any(g in flat for g in GUARDS):
        return "guarded"
    inner = re.sub(r"\b(vec|uv|norm)\b|[.xyz\s,()0]|\b[xyz]\b", "", flat)
    if not re.search(r"[+\-*/]", re.sub(r"-?\d+\.?\d*", "", flat.replace("vec(", "").replace("norm.x", "").replace("norm.y", "").replace("uv.x", "").replace("uv.y", "").replace("uv", "").replace("norm", ""))):
        return "safe"
    return "UNGUARDED"


def main():
    show_all = "--all" in sys.argv
    total = {"safe": 0, "guarded": 0, "UNGUARDED": 0}
    for mod_dir in sorted((ROOT / "src").glob("f_*")):
        rows, seen_rows = [], set()
        for label, text in codeboxes(mod_dir):
            for ln, expr in calls(text):
                kind = classify(substitute(expr, text, ln))
                total[kind] += 1
                key = (kind, label, ln, " ".join(expr.split())[:110])
                if (kind == "UNGUARDED" or show_all) and key not in seen_rows:
                    seen_rows.add(key)
                    rows.append(key)
        if rows:
            print(f"== {mod_dir.name}")
            for kind, label, ln, expr in rows:
                print(f"   {kind:9s} [{label}:{ln}] sample(..., {expr})")
    print(f"\ncalls: {sum(total.values())}  safe {total['safe']}  guarded {total['guarded']}  UNGUARDED {total['UNGUARDED']}")


if __name__ == "__main__":
    main()
