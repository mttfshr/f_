"""
patchbuild.py -- the object / cord / patcher-wrapper helpers shared by the two bench-patch generators,
make_bench.py (bench.maxpat) and make_module_bench.py (bench_module.maxpat, bench_module_empty.maxpat).

Both used to carry their own copy of `obj` and `wire` and of the patcher wrapper (build_cleanup T026,
2026-10-06).  The generated patches did not change: regenerating both gives byte-identical files
(tests/test_bench_patchbuild.py checks the helpers' output shape; compare the generators' output with git).
Stdlib only.
"""

APPVERSION = {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1}


class Patch:
    """A growing list of boxes and cords, in the order the generator adds them."""

    def __init__(self):
        self.boxes, self.lines = [], []

    def obj(self, oid, text, n_in, n_out, rect, outlettype=None, varname=None, maxclass="newobj"):
        box = {"id": oid, "maxclass": maxclass, "text": text,
               "numinlets": n_in, "numoutlets": n_out,
               "patching_rect": [float(v) for v in rect]}
        if n_out:
            box["outlettype"] = outlettype or [""] * n_out
        if varname:
            box["varname"] = varname
        self.boxes.append({"box": box})
        return oid

    def comment(self, oid, text, rect):
        self.boxes.append({"box": {"id": oid, "maxclass": "comment", "text": text,
                                   "numinlets": 1, "numoutlets": 0,
                                   "patching_rect": [float(v) for v in rect]}})

    def wire(self, src, so, dst, di):
        self.lines.append({"patchline": {"source": [src, so], "destination": [dst, di]}})


def patcher_dict(boxes, lines, rect=(100.0, 100.0, 900.0, 640.0)):
    """The top-level {"patcher": ...} wrapper, keys in the order Max writes them."""
    return {"patcher": {"fileversion": 1, "appversion": dict(APPVERSION),
                        "classnamespace": "box", "rect": [float(v) for v in rect],
                        "boxes": boxes, "lines": lines}}
