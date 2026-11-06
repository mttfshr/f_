"""
test_build_gate_button.py -- the `gate_button` param type (2026-11-05, f_vf_stamp T020; build/spec.md).

A held press: a panel face, a `ubutton`, `[sel bang 1 0]` and a draw counter, extracted from f_wave_field's raw boxes.

  - it generates the 13 boxes, plus its own `r draw` and `loadbang` unless draw_from / load_from share a module's
  - it takes its route outlet in definition order among the raw_ui params
  - `param <gate> 0/1` reach every stage of the gate param's pix_target
  - it is loud on misuse: a missing key, a gate_param that is not internal, a bad release_draws or shared node
  - the logic, run over the built cords (drift cannot see these: their boxes are not unique): a tap holds the gate
    until draw release_draws + 1, a press cancels a pending release, nothing fires on load without a press

    tests/run.sh tests/build/test_build_gate_button.py
"""
import paths as _paths
import copy
import sys

ROOT = _paths.REPO
import build_patcher as bp          # noqa: E402

from harness import check, run      # noqa: E402

G = lambda role: bp.gate_id("hit", role)


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


def raises(fn, needle):
    try:
        fn()
    except ValueError as e:
        return needle in str(e)
    return False


def _gate(**over):
    p = {"name": "hit", "type": "gate_button", "label": "Hit", "gate_param": "hit_gate", "hint": "hold",
         "rect": [10.0, 40.0, 28.0, 28.0], "label_rect": [0.0, 20.0, 50.0, 18.0]}
    p.update(over)
    return p


def _defn(gate=None, after=(), target=None, **over):
    hit_gate = {"name": "hit_gate", "type": "internal"}
    if target:
        hit_gate["pix_target"] = target
    d = {"name": "f_t", "prefix": "t", "title": "Test", "signal_type": "texture", "archetype": "processor",
         "presentation_width": 160, "presentation_height": 90, "outlets": [{"comment": "out"}],
         "params": [
             {"name": "g", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "G", "hint": "g"},
             gate or _gate(), *after, hit_gate, {"name": "bypass", "type": "bypass"},
         ],
         "pix_chain": [
             {"id": "a", "name": "#0_t_a", "gen": "pass", "n_inlets": 1, "n_outlets": 1, "primary": False},
             {"id": "b", "name": "#0_t_b", "gen": "pass", "n_inlets": 1, "n_outlets": 1, "primary": True},
         ],
         "pix_wires": [["a", 0, "b", 0]]}
    d.update(over)
    return d


def _built(d):
    p = bp.build(copy.deepcopy(d))["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    cords = [(l["patchline"]["source"][0], l["patchline"]["source"][1],
              l["patchline"]["destination"][0], l["patchline"]["destination"][1]) for l in p["lines"]]
    return top, cords


class Sim:
    """Runs the gate's boxes over the built cords: a fan-out fires right to left, as in Max."""

    def __init__(self, d):
        self.top, self.cords = _built(d)
        self.right = {}          # an [i]'s stored value
        self.gate = None
        self.sent = []

    def emit(self, src, outlet, v="bang"):
        dests = [(d, i) for s, o, d, i in self.cords if s == src and o == outlet and d in self.top]
        for d, i in sorted(dests, key=lambda t: -self.top[t[0]]["patching_rect"][0]):
            self.send(d, i, v)

    def send(self, dst, inlet, v):
        b = self.top[dst]
        text = b.get("text", "")
        if b["maxclass"] == "message":
            if text.startswith("param "):
                self.sent.append(text)
                self.gate = int(text.split()[-1])
            else:
                self.emit(dst, 0, int(text))
        elif text == "t b b":
            self.emit(dst, 1)
            self.emit(dst, 0)
        elif text == "i":
            if inlet == 1:
                self.right[dst] = v
            else:
                self.emit(dst, 0, self.right.get(dst, 0))
        elif text == "+ 1":
            self.emit(dst, 0, v + 1)
        elif text == "sel bang 1 0":
            self.emit(dst, {"bang": 0, 1: 1, 0: 2}[v])
        elif text.startswith("sel "):
            if v == int(text.split()[1]):
                self.emit(dst, 0)

    def load(self):
        self.emit(G("load"), 0)

    def draw(self, n=1):
        for _ in range(n):
            self.emit(G("draw"), 0)

    def message(self, v="bang"):
        self.send(G("sel"), 0, v)


def test_it_generates_the_press_and_its_own_shared_boxes():
    top, cords = _built(_defn())
    gate = [b for i, b in top.items() if i.startswith("obj-gate-hit-")]
    _eq("13 gate boxes, an r draw and a loadbang", len(gate), 15)
    _eq("the ubutton has the hint and the rect", (top[G("button")]["hint"], top[G("button")]["presentation_rect"]),
        ("hold", [10.0, 40.0, 28.0, 28.0]))
    _eq("the label", (top[G("label")]["text"], top[G("label")]["varname"]), ("Hit", "lbl_hit"))
    ids = list(top)
    _eq("the face sits behind the button", ids.index(G("face")) < ids.index(G("button")), True)
    _eq("the messages name the gate", (top[G("on")]["text"], top[G("off")]["text"]),
        ("param hit_gate 1", "param hit_gate 0"))
    _eq("release_draws sets the counter's match", _built(_defn(_gate(release_draws=5)))[0][G("match")]["text"], "sel 5")


def test_shared_draw_and_load_add_no_boxes():
    raw = [{"box": {"id": "obj-raw-1", "maxclass": "newobj", "text": "r draw", "numinlets": 0, "numoutlets": 1,
                    "outlettype": [""], "patching_rect": [400.0, 400.0, 50.0, 22.0]}},
           {"box": {"id": "obj-raw-2", "maxclass": "newobj", "text": "loadbang", "numinlets": 1, "numoutlets": 1,
                    "outlettype": ["bang"], "patching_rect": [400.0, 440.0, 50.0, 22.0]}}]
    top, cords = _built(_defn(_gate(draw_from="obj-raw-1", load_from="obj-raw-2"), raw_boxes=raw))
    _eq("no box of its own", (G("draw") in top, G("load") in top), (False, False))
    _eq("the shared boxes drive it", (("obj-raw-1", 0, G("count"), 0) in cords, ("obj-raw-2", 0, G("arm"), 0) in cords),
        (True, True))


def test_route_outlet_follows_definition_order():
    after = [{"name": "clear", "type": "raw_ui"}]
    top, cords = _built(_defn(after=after))
    _eq("route text keeps definition order", top[bp.OBJ_ROUTE]["text"].split()[1:], ["g", "hit", "clear"])
    _eq("the gate takes outlet 1", (bp.OBJ_ROUTE, 1, G("sel"), 0) in cords, True)
    top, cords = _built(_defn(_gate(), after=after, params=[
        {"name": "clear", "type": "raw_ui"}, _gate(), {"name": "hit_gate", "type": "internal"},
        {"name": "bypass", "type": "bypass"}]))
    _eq("after a raw_ui it takes the next outlet", (bp.OBJ_ROUTE, 1, G("sel"), 0) in cords, True)


def test_messages_reach_each_target_stage():
    top, cords = _built(_defn(target=["a", "b"]))
    pix = {b.get("text", "").split("@name ")[-1].split()[0]: i for i, b in top.items() if "jit.gl.pix" in b.get("text", "")}
    for stage in ("#0_t_a", "#0_t_b"):
        _eq(f"on and off reach {stage}", ((G("on"), 0, pix[stage], 0) in cords, (G("off"), 0, pix[stage], 0) in cords),
            (True, True))


def test_misuse_is_loud():
    no_label = _gate()
    del no_label["label"]
    _eq("a missing key", raises(lambda: bp.build(_defn(no_label)), "label is required"), True)
    _eq("an undeclared gate_param", raises(lambda: bp.build(_defn(_gate(gate_param="nope"))), "must be a declared internal"),
        True)
    _eq("a gate_param that is not internal", raises(lambda: bp.build(_defn(_gate(gate_param="g"))),
                                                    "must be a declared internal"), True)
    for bad in (0, 1.5, True):
        _eq(f"release_draws {bad!r}", raises(lambda: bp.build(_defn(_gate(release_draws=bad))), "release_draws"), True)
    _eq("an unknown shared node", raises(lambda: bp.build(_defn(_gate(draw_from="obj-raw-9"))), "unknown node"), True)


def test_nothing_fires_on_load():
    s = Sim(_defn())
    s.load()
    s.draw(10)
    _eq("no gate message without a press", s.sent, [])


def test_tap_holds_until_the_third_draw():
    s = Sim(_defn())
    s.load()
    s.message()
    _eq("a tap opens the gate", s.gate, 1)
    s.draw(2)
    _eq("still open after two draws", s.gate, 1)
    s.draw()
    _eq("closed on the third", s.gate, 0)
    s.draw(10)
    _eq("closed once", s.sent, ["param hit_gate 1", "param hit_gate 0"])


def test_hold_and_release_by_message_and_release_draws():
    s = Sim(_defn(_gate(release_draws=4)))
    s.load()
    s.message(1)
    s.draw(20)
    _eq("a press holds", s.sent, ["param hit_gate 1"])
    s.message(0)
    s.draw(4)
    _eq("release_draws 4: open after four draws", s.gate, 1)
    s.draw()
    _eq("closed on the fifth", s.gate, 0)


def test_press_cancels_a_pending_release():
    s = Sim(_defn())
    s.load()
    s.message(1)
    s.message(0)
    s.draw()
    s.message(1)
    s.draw(20)
    _eq("the release never lands", s.gate, 1)
    _eq("no close was sent", "param hit_gate 0" in s.sent, False)


def test_ubutton_outlets():
    top, cords = _built(_defn())
    _eq("mouse-down is outlet 1, PRESS", (G("button"), 1, G("press"), 0) in cords, True)
    _eq("mouse-up is outlet 0, RELEASE", (G("button"), 0, G("release"), 0) in cords, True)


if __name__ == "__main__":
    sys.exit(run(globals()))
