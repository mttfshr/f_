---
name: maxpat-json-authoring
description: Conventions and a validation checklist for writing or editing Max/MSP .maxpat files directly as JSON text (by hand, with Read/Edit/Write, or from a script) instead of in Max's own editor. Use this skill whenever creating, patching, generating or reviewing a .maxpat, .maxhelp or bpatcher file as text, even a one-line change, and whenever a script will write one; the mistakes it catches are silent until someone opens the file in Max. Load it especially when a hand-made patch opens with broken or missing boxes, a codebox shows its default template instead of the code written, patchcords are missing after load, a pfft~ says "no patcher", a dial bound with param_connect has the wrong type or range or will not move, or a Max-saved file needs a small surgical change without a noisy diff. Distinct from gen-tilde-codebox and jit-gen-codebox, which cover the GenExpr code inside codeboxes.
---

# Hand-Authoring `.maxpat` JSON

**Why this exists.** A `.maxpat` is plain JSON, so it can be written and edited
without Max running: by hand, by a script, or by an AI assistant. The cost is
that mistakes Max would catch instantly in its editor (a made-up object class,
a dangling patchcord) surface only when someone opens the file, often much
later and reported as "it's broken" with no hint of where. This skill is the
discipline for catching those before handing a file over.

Findings are dated and were observed on Max 9.

---

## Quick rules

Each rule names the section with the details and evidence.

1. **Use only `maxclass` names you have seen in a file Max saved.** There is
   no `numbox`; use `flonum` (a good default, even for integers) or
   `number`. (There is no `maxclass: "numbox"`)
2. **Put codebox source under `"code"`, not `"text"`;** `text` silently
   gives the default template. (Codebox source lives under the `code` key)
3. **Run the validation script before handing a file over:** valid JSON,
   unique ids per patcher scope (each nested patcher has its own), no
   patchline pointing at a missing id. (Validation checklist)
4. **Give `pfft~` a separate subpatch file on disk;** an inline `"patcher"`
   key fails on load. (Validation checklist)
5. **Treat a file Max has rewritten as the current state:** re-read it
   before editing; never revert Max's reformatting. (Expect Max to rewrite
   the file)
6. **For a small change to a Max-saved file, parse, change and dump with
   formatting that round-trips byte for byte, then prove the diff is only
   the intended change.** Don't hand-edit the text or regenerate the file.
   (Surgical edit)
7. **Name `param_connect` controls with a token that can't be a
   `jit.gl.pix` attribute** (`pulse_depth`, not `depth`); keep the plain
   word in the label only. (A control's name can collide)

---

## There is no `maxclass: "numbox"`

Observed 2026-09-16: a hand-authored `.maxpat` used `"maxclass": "numbox"` for
integer-style parameter controls. It is not a real Max UI object; the boxes
rendered broken, and nothing said why until a person opened the file and
replaced them.

Valid `maxclass` values for the common numeric-control cases:

- **`flonum`**: floating-point number box. A good default for any numeric
  parameter, including integer-valued ones; a gen codebox does not care
  whether the incoming float is a whole number.
- **`number`**: the integer-only number box.
- **`live.numbox`** / **`live.dial`** / **`live.menu`** / **`live.text`**:
  parameter-enabled UI objects. Each needs a larger attribute set
  (`parameter_enable`, `saved_attribute_attributes` and the parameter's
  `valueof` block). For a quick prototype a plain `flonum` is far less
  scaffolding; when you do need one, copy a working box from a patch Max saved
  rather than writing it from memory.

**When unsure whether a `maxclass` name is real**, check a working `.maxpat`
that contains the same kind of control rather than guessing from general Max
familiarity:

```bash
grep -o '"maxclass" *: *"[a-z.~_]*"' known_good.maxpat | sort -u
```

---

## Codebox source lives under the `code` key, not `text`

The GenExpr source of a `codebox` (inside a `gen~`, `jit.gen` or `jit.gl.pix`
subpatcher) is stored under `"code"`. Writing it to `"text"` gives a codebox
that silently falls back to its default contents: no error, it just isn't
running the code you wrote. If a script writes codeboxes, check the key name
against a file Max saved.

---

## Validation checklist, every time, before handing a file over

None of these need Max. They are pure text/JSON checks, cheap to run, and they
catch a real class of silent failure (a broken box or a dangling cord produces
no error anywhere until someone opens the file and notices something missing).

1. **The file still parses as JSON.** A missed comma or brace from a hand-edit
   breaks the whole file.
2. **No duplicate object ids within one patcher scope.** The top-level patcher
   and every nested subpatcher (a `gen~`'s or `bpatcher`'s inline `"patcher"`
   key, at any depth) each have their **own** `id` namespace: `obj-1` inside a
   `gen~` does not collide with `obj-1` at the top level. Check each scope
   separately, not the file's ids as one flat set.
3. **No dangling patchline references.** Every `patchline`'s `source` /
   `destination` first element must name an `id` that exists *in the same
   scope*. A typo'd id, or a cord left behind by a deleted box, does not error
   the way you'd hope; Max can silently drop the connection.

A short script covering all three, recursing into nested patchers:

```python
import json, sys

def check_scope(scope, label):
    ids = [b['box']['id'] for b in scope.get('boxes', [])]
    dupes = {x for x in ids if ids.count(x) > 1}
    if dupes:
        print(f"{label}: duplicate ids {sorted(dupes)}")
    idset = set(ids)
    for l in scope.get('lines', []):
        pl = l['patchline']
        for end in (pl['source'][0], pl['destination'][0]):
            if end not in idset:
                print(f"{label}: dangling patchline ref {end}")
    for b in scope.get('boxes', []):
        if 'patcher' in b['box']:
            check_scope(b['box']['patcher'], f"{label} > {b['box']['id']}")

for path in sys.argv[1:]:
    check_scope(json.load(open(path))['patcher'], path)   # json.load fails loudly on bad JSON
```

Run it before considering a hand-edit done. It usually finds nothing, which is
the point: cheap insurance before someone spends time opening a broken file.

**Not covered by the script:** `pfft~` cannot embed its subpatcher inline; it
loads a separate `.maxpat` by name (see gen-tilde-codebox). An inline
`"patcher"` key on a `pfft~` box fails on load.

---

## Expect Max to rewrite the file once someone opens and touches it

Reformatted whitespace, reordered keys, added default attributes, changed
`patching_rect` values: all normal once a person has the file open in Max.
Treat a file that changed on disk since you last read it as the current,
authoritative state, not something to revert or treat as corruption. Re-read
it before editing again.

---

## Surgical edit of a Max-saved file: parse, change, dump, verify (2026-10-05)

To change a few things in a `.maxpat` Max has saved (rename a varname, remove a
cord, correct a `param_connect`), do not hand-edit the text and do not
regenerate the file. Parse the JSON, change it, dump it, and prove the result:

1. **Find the formatting that round-trips byte for byte before trusting a
   dump.** `json.loads` the file and try `json.dumps(d, indent=N,
   ensure_ascii=A)` for N in 2, 4, `"\t"` and A in False, True until the output
   equals the file's text (seen: tab and `ensure_ascii=False`; 4 and
   `ensure_ascii=True`; 2 and `ensure_ascii=False`). If none match, the diff
   will be noisy; say so rather than hide it.
2. **Prove the change is exactly the intended change:** apply the inverse to a
   deep copy of the new data and assert it equals the old data. Assert counts
   too (one box fewer, two cords fewer, and so on).
3. Max writes keys sorted. When you add a key to a box, re-sort that box's keys
   so the diff shows only the addition.
4. Check the diff with `git diff -w --stat`: a surgical edit is a handful of
   lines, not hundreds.
5. Anything that references box ids (`parameters` blocks, cords) must still
   resolve; removing a box means removing every cord that touches it and
   checking nothing else names it.

---

## A control's `varname` / `param_connect` name can collide with a `jit.gl.pix` attribute (2026-10-24)

A control wired to a `jit.gl.pix` through `param_connect` is addressed as
`<pix object>::<control name>`. If the pix has a native attribute with that
name, the control binds to the **attribute**, not to the codebox `Param`, and
takes the attribute's type and range. Seen twice: a dial named `depth` became
Type Int, Range 0 1 (jit.gl.pix has an int 0/1 `depth` attribute), and a dial
named `texture` snapped back to its minimum (native `@texture` takes a
texture-name list). Give each control a token that cannot be a pix attribute (a
prefix: `pulse_depth`, `out_mode`, `grain`) and keep the plain word in the
visible label only. The error is silent on load and shows only as a dial that
will not move or has the wrong range. Codebox-side companions (a `Param` named
`t` that is never applied, and others) are in jit-gen-codebox.

---

If a `local.md` sits next to this file, read it too: it holds project-specific
tooling and conventions that extend this skill.
