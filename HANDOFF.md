# HANDOFF

_Session: 2026-07-17_

## Start Here — Next Session

Read `README.md` → this file → `.specify/plan.md` (as always). Then:
**Phase 0 of `f_vf_optical_flow`** — Stage A scratch test (gradients +
temporal diff). See `.specify/f_vf_optical_flow/tasks.md` T001–T007.
First real decision gate is T003 (Ix/Iy gradient source — current-only
vs. averaged) — resolve empirically once Stage A is running, not before.

---

## This session, in order

### 1. `f_focus` — built Phase 0, then shelved (not a failure — a real "does this warrant existing" call)

Phase 0 feasibility confirmed working in Max: `jit.fx.cf.tiltshift`
renders fine as the sole object in a bpatcher, all five ported params
respond correctly, and — better than expected — the object exposes its
own native `bypass` boolean attribute, so no external gate mechanism was
needed at all (superseded the original task-list expectation).

Mid-session, traced `f_lens.maxpat`'s actual bypass wiring directly
(not assumed) while checking T005, and found a real, separate bug:
`f_lens`'s bypass toggle only sets `@bypass` on `lens_pix` (the primary
pix) — `lens_halation` and `lens_tiltshift` downstream get no bypass
wiring at all, so today's "bypass" only makes the radial
aberration/distortion stage transparent, not the whole module. Logged as
a known bug in `plan.md`'s Parked section, tied to the eventual `f_lens`
v2 cleanup or the tiltshift extraction — not fixed this session, not
urgent, but real.

Then Matt raised the actual scoping question: as designed, `f_focus`
adds zero processing/logic of its own — it's pure UI/state/bypass
wrapper around one stock native object. That's a legitimately different
question from "does it work," and the answer was: shelve it. Not
resumed until either Phase 2 (content-driven focus-map gather-blur,
already scoped in `spec.md`) gets picked up for real, or some other
concrete capability gap surfaces. Full spec/plan/tasks preserved,
Phase 0 checkmarks in `tasks.md` are real and reusable if resumed.

**Files:** `.specify/f_focus/{spec,plan,tasks}.md` (all exist, Phase 0
tasks marked done). `plan.md` Parked section has the full shelving
rationale and the `f_lens` bypass bug.

### 2. `f_vf_optical_flow` — cheap approximation tested and ruled out, real Lucas-Kanade specced

Scratch-tested the proposed cheap chain live in Max: frame-diff (2-pix
feedback, `diff_pix`/`pass_pix`) → decay/injection accumulation (2-pix
feedback, `accum_pix`/`accum_pass_pix`) → `f_vf_fieldmap` →
`f_vf_advect` → `CORNERPINS`. All four pix objects built and wired
correctly (confirmed against `f_vf_advect`'s known-good feedback
pattern; also corrected a real misunderstanding mid-session about
`jit.gl.pix` outlet numbering — rightmost outlet is always `dumpout`,
not a data outlet).

Result: not visually interesting, no coherent motion-following. Traced
the actual reason, not just the symptom: `f_vf_fieldmap`'s gradient
points perpendicular-to-contour (dim→bright) — correct for a
height-field-like scalar, but an accumulated motion trail's meaningful
direction is tangent-to-trail (its long axis), a structurally different
shape. Gradient-of-a-blob gives "attraction toward recent change," not
flow direction. Not a tuning problem — a real dead end, now documented
with the reason why in `ideas/f_vf_optical_flow.md`.

This motivated designing real Lucas-Kanade instead — genuinely solves a
2×2 linear system per pixel from spatial+temporal gradients over a
local window, rather than inferring direction from a diff blob's shape.
Real architecture decided this session:
- **Window size: 5×5**, chosen as a real working size, not a minimal
  starting point — back off to 3×3 only if the GL2→GL3 capture-group
  ceiling actually bites.
- **Confidence output: separate scalar outlet** (the solve's matrix
  determinant), not bundled into the vecfield texture — no existing
  `f_vf_` consumer reads a 3rd channel, and a separate outlet mirrors
  `f_vf_split`'s existing precedent.
- **Single-scale only**, no coarse-to-fine pyramid — deliberately
  deferred, documented as the known next step if fast motion breaks
  down, not silently assumed away.
- **4 pix nodes total** (not 5) — `pass_pix` (previous-frame identity)
  + Stage A (gradients) + Stage B (windowed sum) + Stage C (solve).
  Realized Stage A's own `It` computation already needs the previous
  frame, so only one feedback loop is needed, not one per stage.
- **Confirmed the `pix_chain` build-system schema is sufficient** — read
  `build_pix_chain()` in `build_patcher.py` directly rather than
  assuming; `pix_wires` is a fully general list of cross-wires, no new
  schema capability needed (unlike `f_focus`, which needed a new
  `primary_object` mode).

Specced fully this session: `.specify/f_vf_optical_flow/{spec,plan,
tasks}.md` all written. 6-phase build (Stage A scratch test → Stage B →
Stage C → `definition.py`/build → real-consumer verification →
docs/registration), 33 tasks, 4 explicit decision-gate tasks embedded
(T003, T009, T017, T019) rather than left as spec prose. Not yet
started — Phase 0 is next session's first move.

### 3. `f_vf_channelmap` — new idea, absorbed `f_vf_normal`

Surfaced as a tangent from the optical-flow thread: direct
channel-to-vecfield reinterpretation (pick 2 of R/G/B/A/Luma, remap to
x/y, per-axis invert, no gain knob) — the structural inverse of
`f_vf_split`. Checked against existing ideas before writing anything
new: found `ideas/f_vf_normal.md` (2026-06-16) was nearly the same
mechanism, narrower (fixed R/G, normal-map-motivated). Folded that
file's context and open questions into the new one and deleted it, per
Matt's call, rather than keeping two overlapping idea files.

**File:** `ideas/f_vf_channelmap.md` (new). `ideas/f_vf_normal.md`
deleted.

---

## Loose threads / open items for next session

- **`f_vf_optical_flow` Phase 0 is the immediate next step** — see
  Start Here above.
- **`f_lens` bypass bug** (found this session, not fixed) — only gates
  `lens_pix`, not `lens_halation`/`lens_tiltshift`. Tied to the eventual
  `f_lens` v2 cleanup or tiltshift-extraction work. See `plan.md` Parked
  section for full detail. Not urgent.
- **`f_focus`** — shelved, not deleted. Resume only if Phase 2 (real
  focus-map processing) gets picked up, or some other concrete
  capability gap surfaces. Don't resume just because Phase 0 already
  passed.
- **`f_vf_channelmap`** — idea only, not specced. Whether it gets built
  may depend on how `f_vf_optical_flow`'s Stage A/B raw channel data
  looks once that's running — worth a glance if anything there seems
  like a natural second use case.

## Uncommitted state

Working tree has substantial uncommitted changes from before and during
this session (`f_lens` halation/ghost work in progress from a prior
session, plus this session's new `.specify/f_focus/`,
`.specify/f_vf_optical_flow/`, and `ideas/` changes). Per standing rule,
commits are Matt's to make — not run this session. Suggested commit
message for review/edit, covering just this session's additions (the
`f_lens` in-progress work is a separate, earlier logical unit and
probably wants its own commit if not already handled):

```
Spec f_vf_optical_flow (Lucas-Kanade); shelve f_focus; fold f_vf_normal into f_vf_channelmap

- f_focus: Phase 0 confirmed working (jit.fx.cf.tiltshift standalone,
  native bypass attribute found). Shelved on scope grounds (Matt's
  call) — pure UI wrapper, no added processing. Full spec/plan/tasks
  preserved for future resumption.
- Found and logged (not fixed): f_lens bypass only gates lens_pix, not
  the full halation/tiltshift chain.
- f_vf_optical_flow: scratch-tested and ruled out the cheap frame-diff
  + f_vf_fieldmap approximation, with root cause documented (gradient
  direction mismatch, not a tuning issue). Specced real Lucas-Kanade
  architecture: 5x5 window, separate confidence outlet, single-scale
  only, 4-node pix_chain. spec/plan/tasks all written, Phase 0 not yet
  started.
- New idea: f_vf_channelmap (direct channel-to-vecfield remap,
  inverse of f_vf_split). Absorbed and deleted the narrower
  f_vf_normal.md idea into it.
```
