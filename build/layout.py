"""
layout.py -- edit-view (patching_rect) layout pass for build_patcher.py.

Design + decisions: .specify/build_layout/spec.md.  Pure function over a patcher's
boxes/lines plus a {box_id: (role, idx)} dict supplied by build_patcher.assign_roles().
It rewrites ONLY `patching_rect` (x, y, and, for the route box and per-param attrui,
width).  It never touches presentation_rect, ids, box order or patchlines --
assert_unchanged() checks that.  Boxes whose id is not in `roles` (e.g. definition
raw_boxes) are moved as one block, internal arrangement preserved, into an overflow
area below everything else.

Geometry (all constants below):
  signal strip : main inlet / routepass / vs_inState / r draw down the left rail;
                 modulation inlets in a band to the right (inlet, vs_inState, state prepend)
  param lane   : one column per route outlet, pitch PITCH; per column top->bottom:
                 label (header row) / [route box row] / control / attrui
                 route width = n*PITCH + 7 so outlet k sits over column k
                 route_bypass (route's first token is `bypass`): column 0 is the bypass outlet's,
                 holding the bypass jsui (control row) and its prepend (attrui row); the params
                 start at column 1, so each route outlet still sits over its control and every
                 cord runs downward
  pix stack    : jit.gl.pix nodes layered by their cross-pix wires, then the outlets
  range tiers  : one block per range_tiers param, below the outlets
  service      : moduleSize chain, autopattr, bypass, panel toggle, title, panel --
                 to the right of everything else
  route_first  : when the route's reject outlet feeds routepass (build_patcher `route_first`), the
                 routepass / vs_inState strip sits BELOW the param lane and the pix stack moves down
                 to make room, so that cord and everything after it runs downward
"""
import copy
from collections import defaultdict

# ---- geometry constants (spec: T002) ---------------------------------------
PITCH      = 72.0    # lane column pitch
COL_W      = 68.0    # widest box allowed in a lane column (PITCH minus 4 px gap)
ATTRUI_W   = 68.0    # compact per-param attrui (decided 2026-09-24)
MARGIN     = 30.0
LANE_X0    = 60.0    # centre x of lane column 0
Y_INLET    = 20.0
Y_ROW2     = 70.0    # routepass / vs_inState
Y_ROW3     = 120.0   # instate / r draw / state prepend
Y_HEADER   = 180.0   # param labels (column headers above the route box)
Y_ROUTE    = 204.0
Y_CTL      = 250.0
Y_PRE      = 310.0
Y_PIX      = 380.0
RF_PIX_SHIFT = 100.0  # route_first: the pix stack moves down this far to fit routepass / vs_inState
PIX_STEP   = 50.0    # vertical step between pix layers
PIX_GAP    = 20.0    # horizontal gap between pix in one layer
OUT_GAP    = 50.0
OUT_PITCH  = 70.0
MOD_X0     = 260.0   # modulation band start
MOD_PITCH  = 170.0
RANGE_PITCH = 150.0
SERV_GAP   = 60.0
SERV_COL_B = 220.0
SERV_STEP  = 30.0
OVERFLOW_GAP = 60.0


def _snap(v):
    return round(v * 2.0) / 2.0


def _rect(box):
    return list(box["patching_rect"])


def _put(box, x=None, y=None, w=None):
    r = _rect(box)
    if x is not None:
        r[0] = _snap(x)
    if y is not None:
        r[1] = _snap(y)
    if w is not None:
        r[2] = _snap(w)
    box["patching_rect"] = r


def _put_centered(box, cx, y, max_w=None):
    r = _rect(box)
    w = r[2] if max_w is None else min(r[2], max_w)
    _put(box, x=cx - w / 2.0, y=y, w=w)


def _pix_layers(pix_ids, lines):
    """Layer index per pix id from cross-pix wires; DFS back edges (feedback) ignored."""
    adj = {p: [] for p in pix_ids}
    for l in lines:
        pl = l["patchline"]
        a, b = pl["source"][0], pl["destination"][0]
        if a in adj and b in adj and a != b and b not in adj[a]:
            adj[a].append(b)
    state, fwd = {}, {p: [] for p in pix_ids}

    def dfs(u):
        state[u] = 1
        for v in adj[u]:
            if state.get(v) == 1:
                continue                      # back edge (feedback)
            fwd[u].append(v)
            if v not in state:
                dfs(v)
        state[u] = 2

    for p in pix_ids:
        if p not in state:
            dfs(p)
    layer = {p: 0 for p in pix_ids}
    changed = True
    while changed:
        changed = False
        for u in pix_ids:
            for v in fwd[u]:
                if layer[v] < layer[u] + 1:
                    layer[v] = layer[u] + 1
                    changed = True
    return layer


def layout_edit_view(boxes, lines, roles):
    """Rewrite patching_rect of every box in `boxes` (list of {"box": {...}}) in place."""
    by_id = {b["box"]["id"]: b["box"] for b in boxes}
    grp = defaultdict(list)                      # role -> [(idx, id)] in box order
    unknown = []
    for b in boxes:
        bid = b["box"]["id"]
        if bid in roles:
            role, idx = roles[bid]
            grp[role].append((idx, bid))
        else:
            unknown.append(bid)

    def one(role):
        return [by_id[i] for _, i in grp.get(role, [])]

    # route_first: a cord from the route to routepass.  routepass (and what hangs off it) then has
    # to sit below the route row, or that cord would run upward.
    route_ids = {i for _, i in grp.get("route", [])}
    rp_ids = {i for _, i in grp.get("routepass", [])}
    route_first = any(ln["patchline"]["source"][0] in route_ids and ln["patchline"]["destination"][0] in rp_ids
                      for ln in lines)
    y_rp = Y_PRE + 50.0 if route_first else Y_ROW2            # routepass
    y_is = y_rp + 50.0 if route_first else Y_ROW3             # vs_inState
    y_pix0 = Y_PIX + (RF_PIX_SHIFT if route_first else 0.0)

    # ---- signal strip -------------------------------------------------------
    for bx in one("inlet"):
        _put(bx, MARGIN, Y_INLET)
    for bx in one("routepass"):
        _put(bx, MARGIN, y_rp)
    for bx in one("instate"):
        _put(bx, MARGIN, y_is)
    for bx in one("srcmode_pre"):
        _put(bx, MARGIN, y_is + SERV_STEP)
    for bx in one("rdraw"):
        _put(bx, MARGIN, Y_ROW3)

    n_mod = 0
    for role, y in (("mod_inlet", Y_INLET), ("mod_instate", Y_ROW2), ("mod_statepre", Y_ROW3)):
        for i, bid in grp.get(role, []):
            _put(by_id[bid], MOD_X0 + i * MOD_PITCH, y)
            n_mod = max(n_mod, i + 1)

    # ---- param lane ----------------------------------------------------------
    n_cols = 0
    for bx in one("route"):
        n_cols = max(1, len(bx.get("text", "route").split()) - 1)
    for role in ("ctl", "pre", "label"):
        for i, _ in grp.get(role, []):
            n_cols = max(n_cols, i + 1)
    n_cols = max(n_cols, 1)
    cx = lambda k: LANE_X0 + k * PITCH
    # route_bypass: `bypass` is the route's first token, so its outlet 0 owns lane column 0 and
    # the params' columns start one over (n_cols already counts the token).
    route_bypass = any(bx.get("text", "").split()[1:2] == ["bypass"] for bx in one("route"))
    off = 1 if route_bypass else 0
    n_cols = max(n_cols, len(grp.get("ctl", [])) + off, len(grp.get("label", [])) + off)

    route_right = 0.0                                  # the route's right edge: the service area clears it
    for bx in one("route"):
        w = n_cols * PITCH + 7.0
        w = max(w, len(bx.get("text", "")) * 6.5)     # never clip below the text
        _put(bx, x=cx(0) - 3.5, y=Y_ROUTE, w=w)
        route_right = cx(0) - 3.5 + w
    for k, bid in grp.get("label", []):
        _put_centered(by_id[bid], cx(k + off), Y_HEADER, COL_W)
    for k, bid in grp.get("ctl", []):
        _put_centered(by_id[bid], cx(k + off), Y_CTL, COL_W)
    for k, bid in grp.get("pre", []):
        _put(by_id[bid], w=ATTRUI_W)
        _put_centered(by_id[bid], cx(k + off), Y_PRE)
    if route_bypass:
        for bx in one("bypass_jsui"):
            _put_centered(bx, cx(0), Y_CTL, COL_W)
        for bx in one("bypass_pre"):
            _put(bx, w=ATTRUI_W)
            _put_centered(bx, cx(0), Y_PRE)

    # ---- pix stack + outlets --------------------------------------------------
    pix_ids = [i for _, i in grp.get("pix", [])]
    y_bottom = y_pix0
    if pix_ids:
        layer = _pix_layers(pix_ids, lines)
        x_next = defaultdict(lambda: MARGIN)
        for pid in pix_ids:
            L = layer[pid]
            bx = by_id[pid]
            _put(bx, x_next[L], y_pix0 + L * PIX_STEP)
            x_next[L] += _rect(bx)[2] + PIX_GAP
            y_bottom = max(y_bottom, y_pix0 + L * PIX_STEP + _rect(bx)[3])
    y_out = y_bottom + OUT_GAP
    for i, bid in grp.get("outlet", []):
        _put(by_id[bid], MARGIN + i * OUT_PITCH, y_out)
    y_range = y_out + 30.0 + OUT_GAP

    # ---- range tier blocks ----------------------------------------------------
    range_ns = sorted({(i[0] if isinstance(i, tuple) else i)
                       for role in ("range_menu", "range_sel", "range_msg")
                       for i, _ in grp.get(role, [])})
    for role in ("range_menu", "range_sel", "range_msg"):
        for i, bid in grp.get(role, []):
            n, t = (i if isinstance(i, tuple) else (i, 0))
            x = MARGIN + range_ns.index(n) * RANGE_PITCH
            y = {"range_menu": y_range, "range_sel": y_range + 35.0,
                 "range_msg": y_range + 70.0 + t * SERV_STEP}[role]
            _put(by_id[bid], x, y)

    # ---- service area ---------------------------------------------------------
    x_a = max(cx(n_cols - 1) + PITCH,
              (MOD_X0 + n_mod * MOD_PITCH) if n_mod else 0.0,
              route_right,
              700.0) + SERV_GAP
    x_b = x_a + SERV_COL_B
    for role, x, y in (("loadbang", x_a, 20.0), ("getattr", x_a, 50.0),
                       ("thispatcher", x_a, 110.0), ("zlslice", x_a, 140.0),
                       ("pretam", x_a, 170.0), ("modulesize", x_a, 200.0),
                       ("panel_toggle", x_b, 20.0), ("panel_toggle_js", x_b, 60.0),
                       ("autopattr", x_b, 100.0), ("bypass_jsui", x_b, 130.0),
                       ("bypass_pre", x_b, 160.0), ("title", x_b, 200.0),
                       ("signal_type", x_b + 90.0, 200.0), ("panel", x_a, 260.0)):
        if route_bypass and role in ("bypass_jsui", "bypass_pre"):
            continue                         # placed in lane column 0 above
        for bx in one(role):
            _put(bx, x, y)

    # ---- overflow: unknown boxes move as one block -----------------------------
    if unknown:
        bottom = max(_rect(bx["box"])[1] + _rect(bx["box"])[3]
                     for bx in boxes if bx["box"]["id"] not in unknown)
        rects = [_rect(by_id[i]) for i in unknown]
        min_x = min(r[0] for r in rects)
        min_y = min(r[1] for r in rects)
        dx, dy = MARGIN - min_x, (bottom + OVERFLOW_GAP) - min_y
        for i in unknown:
            r = _rect(by_id[i])
            _put(by_id[i], r[0] + dx, r[1] + dy)


# ---- invariants -------------------------------------------------------------

def _strip_rects(boxes):
    out = copy.deepcopy(boxes)
    for b in out:
        b["box"].pop("patching_rect", None)
    return out


def snapshot(boxes, lines):
    return _strip_rects(boxes), copy.deepcopy(lines)


def assert_unchanged(before, boxes, lines):
    """Layout may change patching_rect only: everything else (ids, order, presentation_rect,
    lines) must be byte-for-byte what it was."""
    b_boxes, b_lines = before
    if _strip_rects(boxes) != b_boxes:
        raise AssertionError("layout pass changed something other than patching_rect")
    if lines != b_lines:
        raise AssertionError("layout pass changed patchlines")


def audit(boxes, lines, roles=None):
    """Measured layout quality: overlapping pairs (background panels excluded), boxes sharing
    an origin, upward wires (cross-pix and range-tier->control wires excluded)."""
    roles = roles or {}
    rects = {}
    for b in boxes:
        bx = b["box"]
        if bx.get("maxclass") == "panel" or "patching_rect" not in bx:
            continue
        rects[bx["id"]] = bx["patching_rect"]
    ids = list(rects)
    overlaps = []
    for i in range(len(ids)):
        ax, ay, aw, ah = rects[ids[i]]
        for j in range(i + 1, len(ids)):
            bx_, by_, bw, bh = rects[ids[j]]
            if ax < bx_ + bw and bx_ < ax + aw and ay < by_ + bh and by_ < ay + ah:
                overlaps.append((ids[i], ids[j]))
    origins = defaultdict(list)
    for i in ids:
        origins[(rects[i][0], rects[i][1])].append(i)
    same_origin = [v for v in origins.values() if len(v) > 1]
    upward = []
    for l in lines:
        pl = l["patchline"]
        a, b = pl["source"][0], pl["destination"][0]
        if a not in rects or b not in rects:
            continue
        ra, rb = roles.get(a, ("?", None))[0], roles.get(b, ("?", None))[0]
        if ra == "pix" and rb == "pix":
            continue
        if ra in ("range_msg",) and rb == "ctl":
            continue
        if rects[b][1] < rects[a][1]:
            upward.append((a, b))
    return {"overlaps": overlaps, "same_origin": same_origin, "upward": upward}
