---
name: maxpat-json-authoring
description: Conventions and a validation checklist for hand-authoring or hand-editing .maxpat files directly as JSON text (via Read/Edit/Write), rather than through Max's live UI or a live MCP bridge. Use whenever a .maxpat is being created or modified without a running Max instance to catch errors immediately at edit time — the errors this catches are otherwise silent until someone opens the file in Max. Distinct from gen-tilde-codebox/jit-gen-codebox (which cover codebox *contents*) and max-patch-notation (which covers describing patches conversationally, not authoring raw JSON).
---

# Hand-Authoring `.maxpat` JSON

**Why this exists.** Most of this project's `f_a_` scratch-and-production
work happens without a live Max connection — patches get built and edited
as raw JSON text, then handed to a person to open in Max and report back.
That means mistakes that Max would normally catch instantly (a typo'd
object class, a dangling patchcord) instead surface only when someone
manually opens the file — often much later, and reported as "it's broken"
with no indication of where. This skill is the discipline for catching
those before handing a file over.

---

## There is no `maxclass: "numbox"`

Confirmed 2026-09-16 (`f_a_ripple` v1 production build): a hand-authored
`.maxpat` used `"maxclass": "numbox"` for integer-style parameter controls
(`band`, `hearing_profile`). It is not a real Max UI object — the boxes
rendered broken. Caught only because a person opened the file in Max and
manually swapped them.

Valid `maxclass` values for the common numeric-control cases actually used
in this project:

- **`flonum`** — floating-point number box. Used throughout this project
  for essentially every numeric parameter control, including ones that
  are conceptually integers (`band`, `hearing_profile`) — the codebox side
  doesn't care whether the incoming float is a whole number.
- **`number`** — the legacy integer-only number box. Rarely used here;
  `flonum` is the project default even for integer-valued parameters.
- **`live.numbox`** / **`live.dial`** / **`live.menu`** / **`live.text`** —
  parameter-enabled UI objects (the ones `build_patcher.py` generates for
  shipped `f_` modules), each with their own required attribute set
  (`parameter_enable`, `saved_attribute_attributes`, etc. — see
  `build/build_patcher.py`'s `dial_box`/`numbox_box`/`menu_box` for the
  exact shape). Don't reach for these in a quick scratch/prototype patch
  unless actually building toward the production UI — they need
  significantly more attribute scaffolding than a plain `flonum`.

**When unsure whether a `maxclass` name is real**, check an existing
working `.maxpat` in this project for the same kind of control rather than
guessing from general Max familiarity — `grep -o '"maxclass": "[a-z.~_]*"'
some_file.maxpat | sort -u` on a known-working patch gives a fast, grounded
list.

---

## Validation checklist, every time, before handing a file over

None of these require Max — they're pure text/JSON checks, cheap to run,
and they catch a real class of silent failure (a broken box or a dangling
wire produces no error message anywhere until a human opens the file and
notices something's missing or unresponsive).

1. **The file still parses as JSON.** `python3 -c "import json;
   json.load(open('path/to/file.maxpat'))"` — trivial, but a missed comma
   or brace from a hand-edit breaks the whole file silently otherwise.
2. **No duplicate object IDs** *within the same patcher scope.* A
   top-level patcher and any nested subpatcher (a `gen~`'s inline
   `"patcher"` key, a `pfft~`'s — though see `gen-tilde-codebox/SKILL.md`,
   `pfft~` needs an external file, not inline) each have their **own**
   independent `id` namespace — `obj-1` inside a `gen~`'s subpatcher does
   not collide with `obj-1` at the top level. Check each scope separately,
   not the whole file's ids as one flat set.
3. **No dangling patchline references.** Every `patchline`'s `source`/
   `destination` first element must name an `id` that actually exists *in
   that same scope*. A typo'd id or a box that got deleted but left its
   patchline behind will not error in Max the way you'd hope — it can
   silently drop the connection instead.

A short script covering all three, run before considering a hand-edit
done:

```python
import json
d = json.load(open(path))
p = d['patcher']

def check_scope(scope, label):
    ids = [b['box']['id'] for b in scope['boxes']]
    dupes = {x for x in ids if ids.count(x) > 1}
    if dupes:
        print(f"{label}: duplicate ids {dupes}")
    idset = set(ids)
    for l in scope.get('lines', []):
        pl = l['patchline']
        for end in (pl['source'][0], pl['destination'][0]):
            if end not in idset:
                print(f"{label}: dangling patchline ref {end}")

check_scope(p, "top-level")
for b in p['boxes']:
    if 'patcher' in b['box']:
        check_scope(b['box']['patcher'], f"subpatcher in {b['box']['id']}")
```

Confirmed useful in practice: caught nothing wrong on the `f_a_ripple`
patches it was run against, but that's the point — cheap insurance run
*before* a person spends time opening a broken file, not a reactive
debugging step after they report something's wrong.

---

## Expect Max to rewrite the file once a person opens and touches it

Reformatted whitespace, reordered keys, added default attributes, changed
`patching_rect` values from UI interaction — all normal and expected once
a human has the file open in Max and is actively working in it. Treat a
file that "changed on disk since you last read it" as the current,
authoritative state (per the harness's own file-changed notice), not
something to revert or treat as corruption — Max round-tripping its own
save format is not the same thing as an error.

---

## Surgical edit of a Max-saved file: parse, change, dump, verify (2026-10-05)

To change a few things in a `.maxpat` Max has saved (rename a varname, remove a cord, correct a
`param_connect`), do not hand-edit text and do not regenerate. Parse the JSON, change it, dump it, and
prove the result:

1. **Find the formatting that round-trips byte for byte before trusting a dump.** `json.loads` the file and
   try `json.dumps(d, indent=N, ensure_ascii=A)` for N in 2, 4, `"\t"` and A in False, True until the
   output equals the file's text (seen: tab and `ensure_ascii=False`; 4 and `ensure_ascii=True`; 2 and
   `ensure_ascii=False`). If none match, the diff will be noisy; say so rather than hide it.
2. **Prove the change is exactly the intended change:** apply the inverse to a deep copy of the new data and
   assert it equals the old data. Assert counts too (one box fewer, two cords fewer, and so on).
3. Max writes keys sorted. When you add a key to a box, re-sort that box's keys so the diff shows only the
   addition (a box Max did not write may have unsorted keys; re-sorting it changes the diff but not the data).
4. Check the diff with `git diff -w --stat`: a surgical edit is a handful of lines, not hundreds.
5. Anything that references box ids (`parameters` blocks, cords) must still resolve; removing a box means
   removing every cord that touches it, and checking nothing else names it.
