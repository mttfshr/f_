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
  - per jit.gl.pix (merged in from the retired build/audit_interface.py):
      undriven    a codebox Param nothing drives: no attrui fed by a widget or
                  inlet, no `prepend param X` / `param X` box, no param_connect
                  that reaches that pix
      unused      a codebox Param declared but never read (comments ignored)
      no_codebox  a pix whose gen has no codebox and is not a pure in->out
                  identity pass (the feedback pattern's state/pass pix)
      port_gaps   a gen `in N` with no cord into pix inlet N-1, or an `out N`
                  with no cord out of pix outlet N-1
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


# Params that never need a driver of their own.
INFRA_PARAMS = {"bypass"}


def pix_code(box):
    """Codebox text of a pix's gen patcher, comments stripped ('' if none)."""
    parts = []
    for b in (box.get("patcher") or {}).get("boxes", []):
        bx = b["box"]
        if bx.get("maxclass") == "codebox":
            code = bx.get("code") or ""
            code = re.sub(r"/\*.*?\*/", "", code, flags=re.S)
            parts.append(re.sub(r"//[^\n]*", "", code))
    return "\n".join(parts)


def codebox_params(box):
    """Params declared in the codebox itself (not gen `param` objects)."""
    return set(_PARAM_RE.findall(pix_code(box)))


def param_is_read(box, name):
    """True if `name` appears in the codebox outside its own declaration."""
    code = re.sub(r"\bParam\s+" + re.escape(name) + r"\s*\([^)]*\)", "", pix_code(box))
    return bool(re.search(r"\b" + re.escape(name) + r"\b", code))


def gen_ports(box):
    """({N of `in N`}, {N of `out N`}) objects in a pix's gen patcher."""
    ins, outs = set(), set()
    for b in (box.get("patcher") or {}).get("boxes", []):
        m = re.fullmatch(r"(in|out)\s+(\d+)", _text(b["box"]))
        if m:
            (ins if m.group(1) == "in" else outs).add(int(m.group(2)))
    return ins, outs


def is_identity_gen(box):
    """A gen patcher holding only `in N` / `out N` objects with every `out`
    fed from an `in` -- the pass-through stage of the feedback pattern."""
    sub = box.get("patcher") or {}
    boxes = {b["box"]["id"]: b["box"] for b in sub.get("boxes", [])}
    if not boxes or not all(re.fullmatch(r"(in|out)\s+\d+", _text(b)) for b in boxes.values()):
        return False
    ins = {i for i, b in boxes.items() if _text(b).startswith("in ")}
    outs = {i for i, b in boxes.items() if _text(b).startswith("out ")}
    fed = {l["patchline"]["destination"][0] for l in sub.get("lines", [])
           if l["patchline"]["source"][0] in ins}
    return bool(ins) and bool(outs) and outs <= fed


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

    def drivers(self, pid):
        """Names something drives into pix `pid`:
          - an attrui @attr X that targets it and is fed by something (a
            widget, an inlet, a route) or is itself on the presentation panel;
          - a `prepend param X` / `param X ...` object that forward-reaches it;
          - a widget with param_connect '...::X' that forward-reaches it;
          - `js f_util_mod_handler.js` wired to it: that handler sends the
            pix's `*_mod_amt_*` depth Params (opaque to this check, so it
            counts as the driver of exactly those names, and only while wired)."""
        target = self.boxes[pid]
        is_target = lambda b: b is target
        fed = {d for dests in self.out.values() for d, _ in dests}
        names = set()
        for aid, a in self.attruis().items():
            if pid in self.attrui_targets(aid) and (aid in fed or a.get("presentation")):
                names.add(a.get("attr"))
        for bid, b in self.boxes.items():
            if (b.get("maxclass") == "newobj" and "f_util_mod_handler" in _text(b)
                    and self.reach([bid], stop=is_target)):
                names |= {p for p in codebox_params(target) if "_mod_amt_" in p}
                continue
            m = re.match(r"(?:prepend\s+)?param\s+(\S+)", _text(b))
            pc = b.get("param_connect") or ""
            name = None
            if m and b.get("maxclass") in ("newobj", "message"):
                name = m.group(1)
            elif "::" in pc:
                name = pc.split("::")[-1]
            if name and self.reach([bid], stop=is_target):
                names.add(name)
        return names

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

        # per-pix checks (ported from build/audit_interface.py)
        report.update({"undriven": [], "unused": [], "no_codebox": [], "port_gaps": []})
        into = defaultdict(set)                       # pix id -> inlets with a cord in
        outof = defaultdict(set)                      # pix id -> outlets with a cord out
        for (s, so), dests in self.out.items():
            if dests:
                outof[s].add(so)
            for d, di in dests:
                into[d].add(di)
        for pid, b in pix.items():
            nm = pix_name(b)
            if not pix_code(b).strip() and not is_identity_gen(b):
                report["no_codebox"].append(nm)
            declared = codebox_params(b) - INFRA_PARAMS
            driven = self.drivers(pid)
            report["undriven"] += [{"pix": nm, "param": p} for p in sorted(declared - driven)]
            report["unused"] += [{"pix": nm, "param": p} for p in sorted(codebox_params(b))
                                 if not param_is_read(b, p)]
            ins, outs = gen_ports(b)
            report["port_gaps"] += [f"{nm}:in{n}" for n in sorted(ins) if n - 1 not in into[pid]]
            report["port_gaps"] += [f"{nm}:out{n}" for n in sorted(outs) if n - 1 not in outof[pid]]
        return report


def shipped_modules():
    return sorted(p for p in PATCHERS.glob("f_*.maxpat"))


if __name__ == "__main__":
    for p in shipped_modules():
        r = Module(p).analyze()
        print(r["module"], json.dumps({k: v for k, v in r.items() if k not in ("module", "pix")}))
