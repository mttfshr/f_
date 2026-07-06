# Tasks: f_masonry

**Spec**: `.specify/f_masonry/spec.md`
**Plan**: `.specify/f_masonry/plan.md`
_Renamed from f_weave 2026-05-30. Vocabulary updated to masonry metaphor._

---

## Current State (as of 2026-06-04)

Phases 1–3 complete. Patcher built and working with correct param names and
seed numboxes. Brick-space modulation sampling fixed and committed.

M001 (u-mod/v-mod inlets) partially implemented in patcher but superseded by
M002 before codebox was completed. Patcher inlets from M001 will be replaced
in M002.

Active work: M002 — three-space modulation inlets (slot, brick, pixel).

---

## Source Layout

```
~/Vsynth/patterns/
  weave-scratch.maxpat     — scratch patch (reuse for masonry iteration)

/Users/matt/Github/f_/
  patchers/
    f_masonry.maxpat       — production output (version controlled)
  docs/
    f_masonry.md           — as-built reference (R003)
  .specify/f_masonry/
    spec.md
    plan.md
    tasks.md               — this file
```

---

## Remaining Tasks

### R001b-fix — pix/autopattr varname cleanup (cosmetic)

- [ ] R001b-fix In patcher JSON: update `weave_pix` → `masonry_pix` and
  `weave_autopattr` → `masonry_autopattr` throughout (pix object text,
  varname, autopattr varname, bypass jsui param_connect)

### R003 — Integration + docs

- [ ] R003a Load `f_masonry` in full Vsynth context — verify frame rate acceptable
- [ ] R003b Test animation: wire `vs_lfo` to phase, verify continuous scrolling; try speed_var > 0
- [ ] R003c Test `f_masonry → f_droste`
- [ ] R003d Test `f_masonry → f_lens`
- [ ] R003e Write `docs/f_masonry.md` — as-built reference
- [ ] R003f Update `README.md` — add f_masonry as ✅ Working
- [ ] R003g Git commit

---

## M001 — Modulation inlets (u-mod/v-mod) — SUPERSEDED

Superseded by M002. Patcher work from M001g–M001l remains in the patcher
but will be replaced during M002. Codebox work was never completed.

---

## E001 — Candidate-search slot ownership (drift/regularity/quantize redesign)

**Goal:** Fix the "sliced barcode" bug — `drift` can't currently relocate a
brick across its slot boundary, no matter how high, because slot ownership
is a single fixed lookup. See spec.md acceptance criteria (updated
2026-07-05) and plan.md ADR 7 for full design.

### E001 — Codebox (scratch first, per standing practice)

- [x] E001a Scratch-test the 3-candidate search in isolation first: reorder
      geometry so base geometry → search → A-sampling, confirm at
      `drift=0, regularity=1, quantize=1, phase=0` output is pixel-identical
      to current shipped behavior — **PASSES, confirmed in Max 2026-07-05**
- [x] E001b Implement per-candidate `drift_amt_s`/`cand_center_s`/`raw_dist_s`
      per ADR 7 formulas; verify `drift` alone produces real migration
      across the old fixed boundary, not a sliced barcode — **PASSES,
      confirmed in Max 2026-07-05**
- [x] E001c Implement `bias_dist_s` priority term; verify `regularity=0`
      produces uneven brick spacing (contested territory) rather than
      edge-hugging within a fixed slot — **PASSES, confirmed via the same
      screenshot as E001b/E001i, 2026-07-05**
- [x] E001d Implement pairwise winner-select (3-way min via step/mix, no
      arrays) — verify no visible seams/flicker at candidate boundaries —
      **PASSES, no flicker, confirmed 2026-07-05**
- [x] E001e Rewire A-space sampling (`brick_uv`) to key off the winner's slot
      identity, confirmed after the search resolves, not before — done in
      `codebox_phase7.gen`/`codebox_phase8.gen`
- [ ] E001f Shift `phase` into `base_along` pre-search; verify scrolling
      reassigns ownership across cells (should also fix prior
      treadmill-only scrolling as a side effect) — **NOT YET TESTED**, code
      is in place in phase8 but no vs_lfo scroll check done yet
- [x] E001g Remove now-dead `slot_hash`/`mark_dist_rnd` edge-hugging code and
      the `mark_center`/`floor()` recovery dance — done in phase7/phase8
- [x] E001h fps check at default and worst-case — **60+fps, confirmed in
      Max 2026-07-05**
- [x] E001i Known limitation to observe: does winning contested territory
      at low `regularity` render as more mortar/gap rather than a visibly
      bigger brick? **Confirmed in Max 2026-07-05: reads as a genuinely
      wider brick.** `mag_weight`-equivalent is NOT needed.

### E001 — quantize removed (found during E001 testing, 2026-07-05)

Matt caught, math confirms: `drift_scale = drift * 0.5 * (1.0 - quantize)`
is a pure linear scalar on `drift` — any `(drift, quantize)` pair is
reproducible by `drift` alone at `quantize=0`. Not a new axis of control.
See plan.md ADR 7 addendum for full rationale, including the declined
stepped/discrete-snap alternative (not something Matt asked for).

- [x] E001n Remove `quantize` from the scratch codebox — `codebox_phase8.gen`
      supersedes phase7, `drift_scale = drift * 0.5` flat, no `Param
      quantize` or `quantize_mod_amt_a` declarations
- [x] E001o Remove `quantize` row from spec.md param table; remove
      "scaled by quantize" note from `drift`'s row
- [ ] E001p Production promotion still needs: remove `quantize`'s
      `live.dial` + label from the patcher UI, remove its `route` entry,
      remove its field from `definition.py`/build script — **NOT DONE**,
      scratch-codebox-only so far

### E001 — production merge bug found + fixed (2026-07-05)

Direct merge into `definition.py` (preserving the AA block/`out2`/
`hash1d` conventions the stale `codebox_phase6.gen` reference had fallen
out of sync with) was never independently scratch-tested before landing
in production — a real process gap against standing practice. Result:
all `attrui` controls grayed out/inactive in Max, no console error
observed — a silent compile failure, same category as `f_vf_seeds`'
capture-ceiling issue (looks exactly like a render bug, isn't).

**Root cause:** `eval_candidate()`'s `return raw_dist, bias_dist;` — a
multi-value return from a **user-defined** function. The
jit-gen-codebox skill confirms multi-return via comma-assignment for
built-in operators (`cartopol`) and confirms user-defined functions
work, but has no confirmed example of a user-defined function itself
returning multiple values. Untested combination, not a documented
pattern.

**Fix:** inlined the per-candidate math three times (duplicated, not
called) using only the confirmed-working `hash1d` single-return
pattern. `codebox_phase9.gen` is the corresponding scratch reference,
matching `definition.py` exactly.

- [x] E001q Rebuilt `patchers/f_masonry.maxpat`, JSON-validated
- [ ] E001r Matt to reload in Max, confirm attrui's are active again —
      **awaiting confirmation**
- [ ] E001s Once confirmed, re-run E001a-i's regression checks against
      this exact inlined code — the earlier passes were against the
      function-based version, which never actually reached production
      correctly, so those results don't cover what's shipping now
- [ ] E001t Consider adding this finding to the jit-gen-codebox skill
      (user-defined multi-return functions unconfirmed/risky) — not
      done yet, Matt's call whether it's worth a skill update

### E001 — Verify / promote

- [ ] E001j Full regression pass against updated spec.md acceptance criteria
- [ ] E001k Update `docs/f-reference/f_masonry.md` if it exists, or note the
      behavior change wherever f_masonry is documented
- [ ] E001l Separately, flag/investigate: the `drift` live.dial in the
      current production patcher reads up to 4.00 in Max, but spec/codebox
      document a 0.0–1.0 range (codebox clamps internally, so this was
      invisible until now) — check patcher JSON for the actual dial range
      vs. `definition.py`/spec before this ships, don't assume which is
      wrong
- [ ] E001m Git commit as one logical unit once confirmed in Max (not JSON
      inspection alone, per standing practice)

---

## M002 — Three-space modulation inlets (slot, brick, pixel)

**Goal:** Replace u-mod/v-mod with three inlets each sampling in a distinct
coordinate space. See spec.md Phase 5 and plan.md ADR 6 for full design.

### M002 — Codebox

- [ ] M002a Write new codebox from scratch incorporating three-space mod model
      (supersedes phase5c). Verify geometry block ordering: slot mod after
      early geometry (`band_idx`, `slot`); brick mod after full geometry
      (`along_frac`, `across_phase`); pixel mod anywhere (needs only `norm`)
- [ ] M002b Add `in 2` (slot mod), `in 3` (brick mod), `in 4` (pixel mod)
- [ ] M002c Add params: `slot_mod_target`, `slot_mod_depth`, `brick_mod_target`,
      `brick_mod_depth`, `pixel_mod_target`, `pixel_mod_depth`
- [ ] M002d Implement sampling for each inlet at correct coordinates
- [ ] M002e Implement delta/depth/centering for all three
- [ ] M002f Implement target chooser — same target list for all three inlets;
      start with mortar, drift, offset; expand as needed
- [ ] M002g Implement `_eff` variables accumulating deltas from all three inlets
- [ ] M002h Verify in scratch patch: flat 0.5 texture → zero delta at any depth
- [ ] M002i Verify slot mod: profile strip → discrete per-brick variation
- [ ] M002j Verify brick mod: texture tiles visibly per brick face
- [ ] M002k Verify pixel mod: continuous field variation articulated by brick structure

### M002 — Patcher

- [ ] M002l Replace u-mod/v-mod inlets with slot/brick/pixel mod inlets
      (inlet count stays at 3 mod inlets, but all are new)
- [ ] M002m Update `numinlets` on pix to 5 (in0 + 3 mod inlets)
- [ ] M002n Replace u/v mod params in UI with slot/brick/pixel mod params
- [ ] M002o Update route object with new param names
- [ ] M002p Wire mod inlets directly to pix in2/in3/in4

### M002 — Verify

- [ ] M002q All three inlets independent and non-interfering
- [ ] M002r Bipolar depth correct for all three
- [ ] M002s Unconnected inlet produces no modulation (depth=0 default)
- [ ] M002t Two inlets targeting same param accumulate correctly
