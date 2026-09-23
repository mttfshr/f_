"""
module_contract.py -- static analysis of shipped f_ bpatchers
(.specify/test_bench/tasks_extensions.md T101).

Reads package/patchers/f_*.maxpat and checks the control path a module's
parameters travel, without opening Max:

    inlet 0 -> routepass -> route <names...> -> (live.dial / numbox / ...)
            -> attrui @attr X -> target object (normally a jit.gl.pix)

For each module it reports:
  - route names that never reach an attrui (control message goes nowhere)
  - attrui attributes that the target pix doesn't have (neither a Param in
    its gen codebox nor a built-in jit.gl.pix attribute) -- the class of the
    2026-07 f_vf_advect bug (dial bound to `strength`, codebox read `mix_amt`)
  - which pix objects the bypass jsui actually reaches
It also returns the route-name -> attribute map the live contract test uses.
"""
import json
import re
from collections import defaultdict, deque
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PATCHERS = REPO / "package" / "patchers"

# Built-in jit.gl.pix attributes (Max 9 refpage) -- valid attrui targets even
# without a matching codebox Param.
PIX_BUILTINS = {"bypass", "activeinput", "adapt", "colormode", "dim", "dimscale",
                "filter", "gen", "rect", "rectangle", "thru", "title", "type",
                "exportfolder", "file", "inputs", "outputs", "out_name", "dirty", "t"}

_PARAM_RE = re.compile(r"\bParam\s+([A-Za-z_]\w*)\s*\(")
TRAVERSE_TOKENS = {"t", "trigger", "prepend", "scale", "zl", "pack", "pak", "int", "i",
                   "float", "f", "expr", "+", "*", "/", "-", "!-", "!/", "round", "clip",
                   "gate", "change", "speedlim", "deferlow", "defer"}
PASS_THROUGH = ("live.dial", "live.numbox", "live.menu", "live.toggle", "flonum",
                "number", "toggle", "umenu")


def _text(box):
    return (box.get("text") or "").strip()


def _is_pix(box):
    return box.get("maxclass") == "newobj" and _text(box).startswith("jit.gl.pix")


def pix_params(box):
    """Params declared in a jit.gl.pix box's embedded gen patcher."""
    params = set()
    sub = box.get("patcher") or {}
    for b in sub.get("boxes", []):
        bx = b["box"]
        if bx.get("maxclass") == "codebox":
            code = bx.get("code") or ""
            code = re.sub(r"//[^\n]*", "", code)
            params |= set(_PARAM_RE.findall(code))
        t = _text(bx)
        if t.startswith("param "):
            params.add(t.split()[1])
    return params


def pix_name(box):
    m = re.search(r"@name\s+(\S+)", _text(box))
    return m.group(1) if m else box.get("varname") or box["id"]


class Module:
    def __init__(self, path):
        self.path = Path(path)
        self.name = self.path.stem
        self.patcher = json.load(open(path))["patcher"]
        self.boxes = {b["box"]["id"]: b["box"] for b in self.patcher.get("boxes", [])}
        self.out = defaultdict(list)                   # (id, outlet) -> [(id, inlet)]
        for line in self.patcher.get("lines", []):
            (s, so), (d, di) = line["patchline"]["source"], line["patchline"]["destination"]
            self.out[(s, so)].append((d, di))

    # ---- graph helpers
    def successors(self, bid):
        box = self.boxes[bid]
        for o in range(box.get("numoutlets", 0)):
            for d, _ in self.out.get((bid, o), []):
                yield d

    def reach(self, starts, stop, max_depth=6):
        """BFS from start ids; collect ids where stop(box) is true (not
        traversed past). Passes only through lightweight UI / message objects."""
        found, seen = [], set(starts)
        q = deque((s, 0) for s in starts)
        while q:
            bid, depth = q.popleft()
            for nxt in self.successors(bid):
                if nxt in seen:
                    continue
                seen.add(nxt)
                box = self.boxes[nxt]
                if stop(box):
                    found.append(nxt)
                elif depth < max_depth and self._traversable(box):
                    q.append((nxt, depth + 1))
        return found

    def _traversable(self, box):
        mc, t = box.get("maxclass"), _text(box)
        if mc in PASS_THROUGH or mc in ("message", "jsui"):
            return True
        return mc == "newobj" and (t.split() or [""])[0] in TRAVERSE_TOKENS

    # ---- facts
    def pix(self):
        return {bid: b for bid, b in self.boxes.items() if _is_pix(b)}

    def attruis(self):
        return {bid: b for bid, b in self.boxes.items() if b.get("maxclass") == "attrui"}

    def attrui_targets(self, bid):
        """Objects an attrui drives: first non-traversable objects downstream."""
        return self.reach([bid], stop=lambda b: not self._traversable(b), max_depth=3)

    def routes(self):
        """[(route_box_id, [names])] -- `route`, not `routepass`."""
        out = []
        for bid, b in self.boxes.items():
            t = _text(b)
            if b.get("maxclass") == "newobj" and t.startswith("route "):
                out.append((bid, t.split()[1:]))
        return out

    def bypass_jsuis(self):
        return [bid for bid, b in self.boxes.items()
                if b.get("maxclass") == "jsui" and "bypass_toggle" in (b.get("filename") or "")]

    def analyze(self):
        pix = self.pix()
        params = {bid: pix_params(b) for bid, b in pix.items()}
        report = {"module": self.name, "pix": {pix_name(b): sorted(params[bid]) for bid, b in pix.items()},
                  "route_map": {}, "route_direct": [], "unrouted": [], "bad_attr": [], "non_pix_targets": [],
                  "unconnected_attrui": [], "bypass": None}

        # attrui -> target validity
        attr_of = {}
        for aid, a in self.attruis().items():
            attr = a.get("attr")
            attr_of[aid] = attr
            targets = self.attrui_targets(aid)
            if not targets:
                report["unconnected_attrui"].append(attr)
            for t in targets:
                tb = self.boxes[t]
                if _is_pix(tb):
                    if attr not in params[t] and attr not in PIX_BUILTINS:
                        report["bad_attr"].append({"attr": attr, "pix": pix_name(tb),
                                                   "pix_params": sorted(params[t])})
                else:
                    report["non_pix_targets"].append({"attr": attr, "target": _text(tb)[:60] or tb.get("maxclass")})

        # route names -> attrui attrs
        for rid, names in self.routes():
            for k, name in enumerate(names):
                starts = [d for d, _ in self.out.get((rid, k), [])]
                hits = [s for s in starts if self.boxes[s].get("maxclass") == "attrui"]
                hits += self.reach(starts, stop=lambda b: b.get("maxclass") == "attrui")
                attrs = sorted({attr_of[h] for h in hits})
                direct = [s for s in starts if _is_pix(self.boxes[s])]
                direct += self.reach(starts, stop=_is_pix)
                if attrs:
                    report["route_map"][name] = attrs
                elif direct:
                    report["route_direct"].append(name)        # message path into a pix
                else:
                    report["unrouted"].append(name)

        # bypass reach
        js = self.bypass_jsuis()
        if js:
            by_attruis = [h for h in self.reach(js, stop=lambda b: b.get("maxclass") == "attrui")
                          if attr_of.get(h) == "bypass"]
            reached = set()
            for a in by_attruis:
                reached |= {pix_name(self.boxes[t]) for t in self.attrui_targets(a) if _is_pix(self.boxes[t])}
            report["bypass"] = {"reaches": sorted(reached), "all_pix": sorted(report["pix"])}
        return report


def shipped_modules():
    return sorted(p for p in PATCHERS.glob("f_*.maxpat"))


if __name__ == "__main__":
    for p in shipped_modules():
        r = Module(p).analyze()
        print(r["module"], json.dumps({k: v for k, v in r.items() if k not in ("module", "pix")}))
