import json, re, sys

PATH = "/Users/matt/Github/f_/package/patchers/f_masonry.maxpat"
text = open(PATH, encoding="utf-8").read()


def scan_arrays(t):
    """Return {key: [open_idx, close_idx]} for patcher-level arrays 'boxes' and 'lines'."""
    out = {}
    i, n, depth = 0, len(t), 0
    while i < n:
        c = t[i]
        if c == '"':
            j = i + 1
            while t[j] != '"':
                j += 2 if t[j] == "\\" else 1
            s = t[i + 1:j]
            if depth == 2 and s in ("boxes", "lines") and s not in out:
                k = j + 1
                while t[k] in " \t\r\n":
                    k += 1
                if t[k] == ":":
                    k += 1
                    while t[k] in " \t\r\n":
                        k += 1
                    if t[k] == "[":
                        out[s] = [k, None]
            i = j + 1
            continue
        if c in "{[":
            depth += 1
        elif c in "}]":
            depth -= 1
            if c == "]" and depth == 2:
                for key, v in out.items():
                    if v[1] is None and t[v[0]] == "[" and i > v[0]:
                        v[1] = i
        i += 1
    return out


def elements(t, a, b):
    """Split array interior (a=open '[' idx, b=close ']' idx) into element spans."""
    spans, depth, i = [], 0, a + 1
    start = None
    while i < b:
        c = t[i]
        if c == '"':
            j = i + 1
            while t[j] != '"':
                j += 2 if t[j] == "\\" else 1
            i = j + 1
            continue
        if c in "{[":
            if depth == 0:
                start = i
            depth += 1
        elif c in "}]":
            depth -= 1
            if depth == 0:
                spans.append((start, i + 1))
        i += 1
    return spans


def rebuild(t, key, keep_fn, edit_fn):
    arrs = scan_arrays(t)
    a, b = arrs[key]
    spans = elements(t, a, b)
    texts = [t[s:e] for s, e in spans]
    objs = [json.loads(x) for x in texts]
    new = []
    for x, o in zip(texts, objs):
        if not keep_fn(o):
            continue
        new.append(edit_fn(o, x))
    sep = t[spans[0][1]:spans[1][0]]
    head = t[a + 1:spans[0][0]]
    tail = t[spans[-1][1]:b]
    body = head + sep.join(new) + tail
    return t[:a + 1] + body + t[b:], len(texts) - len(new)


DEL_BOXES = {"obj-25", "lbl-obj-25", "obj-75", "obj-113", "obj-165"}
SHIFT_X = {  # id -> new presentation x
    "obj-26": 48.0, "lbl-obj-26": 48.0,   # regularity
    "obj-27": 90.0, "lbl-obj-27": 90.0,   # drift
    "obj-24": 132.0, "lbl-obj-24": 132.0,  # skip
    "obj-28": 178.0, "lbl-obj-28": 178.0,  # phase
    "obj-29": 220.0, "lbl-obj-29": 220.0,  # speed_var
}
OLD_ROUTE = "route courses bond offset angle skip quantize regularity drift phase speed_var mortar softness width roundness bypass course_color brick_color course_seed brick_seed"
NEW_ROUTE = OLD_ROUTE.replace(" quantize", "")


def edit_box(o, x):
    b = o["box"]
    i = b["id"]
    if i == "obj-5b":
        assert b["text"] == OLD_ROUTE
        x = x.replace(OLD_ROUTE, NEW_ROUTE)
        x, n1 = re.subn(r'"numoutlets"\s*:\s*20', '"numoutlets": 19', x)
        assert n1 == 1
        m = re.search(r'"outlettype"\s*:\s*\[([^\]]*)\]', x)
        assert m and m.group(1).count('""') == 20, "outlettype len"
        inner = m.group(1)
        pos = inner.rfind('""')
        before = inner[:pos].rstrip()
        assert before.endswith(",")
        inner2 = before[:-1].rstrip() + inner[pos + 2:]
        x = x[:m.start(1)] + inner2 + x[m.end(1):]
    if i == "obj-103":
        assert "quantize" in b["text"]
        x = x.replace(" quantize ", " ")
    if i == "obj-6":  # autopattr
        assert b["text"] == "autopattr @varname masonry_autopattr"
        x = x.replace('"text": "autopattr @varname masonry_autopattr"', '"text": "autopattr"')
        x, n = re.subn(r'"varname"\s*:\s*"u945001373"', '"varname": "masonry_autopattr"', x)
        assert n == 1
        x, n = re.subn(r'\n\s*"quantize"\s*:\s*\[\s*0\.0\s*\],', "", x)
        assert n == 1, "restore quantize"
    if i in SHIFT_X:
        m = re.search(r'("presentation_rect"\s*:\s*\[\s*)([-\d.]+)', x)
        assert m, i
        x = x[:m.start(2)] + repr(SHIFT_X[i]) + x[m.end(2):]
    return x


def keep_box(o):
    return o["box"]["id"] not in DEL_BOXES


text, nb = rebuild(text, "boxes", keep_box, edit_box)
assert nb == len(DEL_BOXES), nb


def keep_line(o):
    p = o["patchline"]
    return p["source"][0] not in DEL_BOXES and p["destination"][0] not in DEL_BOXES


def edit_line(o, x):
    p = o["patchline"]
    if p["source"][0] == "obj-5b":
        old = p["source"][1]
        if old <= 5:
            new = old
        elif old <= 16:
            new = old - 1
        elif old in (18, 19):
            new = old - 2   # seed fix: 18->16 (course_seed), 19->17 (brick_seed)
        else:
            raise AssertionError(old)
        if new != old:
            x, n = re.subn(r'("source"\s*:\s*\[\s*"obj-5b"\s*,\s*)%d(\s*\])' % old, r"\g<1>%d\g<2>" % new, x)
            assert n == 1, (old, x)
    return x


text, nl = rebuild(text, "lines", keep_line, edit_line)
print("deleted boxes:", nb, "deleted lines:", nl)

text, n = re.subn(r'\n\s*"obj-25"\s*:\s*\[\s*"quantize"\s*,\s*"quantize"\s*,\s*0\s*\],', "", text)
assert n == 1, "parameters block"

json.loads(text)
open(PATH, "w", encoding="utf-8").write(text)
print("written; parses OK")
