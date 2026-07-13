# HANDOFF — f_ library

## Start Here — Next Session

**Read `.specify/plan.md` first** for current priorities, workstream state,
and the full parked/blocked list — that's the standing source of truth.
Don't re-derive priority ordering by scanning the log below.

**Rollout status: implementation done, Max verification partial.** All
six modules in the dry/wet/gain rollout (`f_chladni`, `f_vf_advect`,
`f_vf_prism`, `f_caustic`, `f_vf_glow`, `f_vf_streak`) now have
consistent `gain`/`mix` naming. **`f_caustic` and `f_vf_streak` have not
been opened in Max yet this session** — do that before treating the
rollout as fully closed. `f_vf_glow` and `f_vf_prism` were opened and
confirmed working by Matt.

**Canonical naming, locked 2026-07-12**: every module with a composite/
blended outlet uses exactly two names, never a synonym — `gain`
(unbounded, can overdrive, effect intensity) and `mix` (0–100%,
`live.numbox`, blend ratio, internal codebox `Param` `mix_pct` to dodge
the `mix()` operator collision). This is now written into
`vsynth-bpatcher/SKILL.md`'s "Canonical naming: `gain` vs `mix`" section
as an explicit rule, not per-module precedent — real drift across three
different names (`gain`/`strength`/`intensity`) for the same role is
what triggered this. Any future module with a composite outlet follows
this without re-litigating it.

**Skill file consolidation, also this session**: the `vsynth-bpatcher`
skill existed in three diverging copies (the mounted Claude Desktop
copy, `f_/skills/`, and `claude-scaffold/skills/`) — each had content
the others lacked (mix/wet convention only in claude-scaffold; current
8-category module menu only in f_/skills). Merged into one canonical
version, now the single physical file at `f_/skills/vsynth-bpatcher/
SKILL.md` — `claude-scaffold/skills/vsynth-bpatcher` is now a **symlink**
to it, not a copy, so the two repos can't diverge again. The mounted
Claude Desktop copy is a manual-upload snapshot on Matt's end (not tied
to either repo path) — re-upload `f_/skills/vsynth-bpatcher/SKILL.md`
whenever it changes.

**Immediate next action**: open `f_caustic` and `f_vf_streak` in Max,
verify all acceptance criteria (especially `mix=0`→clean source,
`mix=100`→matches old pre-rename behavior, bypass unaffected). Once both
confirmed, do Phase 5 (docs/registration) sweep — `README.md` doesn't
need changes (no new modules, no outlet count changes), but
`docs/f-reference/*.md` for these four modules should get a pass to
match the new param names if those reference files exist and are
getting stale (not checked this session).

---



**Do not auto-resume, without rereading their entries in plan.md first:**
- `f_apollonian` — shelved, real unresolved use_mapped=2 vs. =4 contradiction
- `f_poincare` — shelved (Matt's explicit call, 2026-07-12)
- `f_vf_vorticity` — built but genuinely unverified, don't build on top of it

For anything else, plan.md's Workstreams section has current state per
thread. The log below is compressed session history — a way to locate a
specific thread's origin story, not a priority queue and not meant to be
read start-to-end.

---

## Session log (compressed)

### 2026-07-12d — Canonical gain/mix naming locked; skill files unified; f_caustic bug found; rollout finished
Several threads, starting from resuming the dry/wet/gain rollout on
`f_caustic`.

**`f_caustic` Phase 1 (rebuild + verify)**: found a second, deeper bug
beyond the already-documented `codebox_v3.gen` file-swap. The file on
disk named `codebox_v2.gen` was actually stale `v1`-era content
(mislabeled internally), lacking the `strength` crossfade the built
`.maxpat` already had — the real, correct v2 codebox only existed baked
into the already-built patcher, never separately saved back to a `.gen`
file. Extracted the true v2 code from the `.maxpat` JSON, wrote it to
disk, confirmed `build_patcher.py` passes codebox content through
verbatim (no parsing), then rebuilt — diff showed the rebuild also fixed
a previously hand-patched, half-wired `strength` dial (bound via direct
`param_connect` but never wired through `route`, so control messages
couldn't reach it) and a presentation panel width mismatch. Full
account: `.specify/f_caustic/plan.md`/`spec.md`.

**Canonical `gain`/`mix` naming — real drift found and fixed.** Before
touching `f_vf_glow`, checking precedent surfaced three different names
for the same "effect intensity" role across already-shipped modules
(`f_chladni`/`f_vf_advect`: `gain`; `f_vf_prism`: `strength`, after its
own plan called for renaming to `gain` and then abandoned the rename
mid-fix; `f_caustic`: `intensity`). Matt's call: one canonical name per
role, everywhere — `gain` (intensity, unbounded) and `mix` (blend,
0–100%, `live.numbox`), never a synonym. Written into
`vsynth-bpatcher/SKILL.md` as an explicit rule (not per-module
precedent). Retrofitted onto the two already-shipped modules that had
drifted (`f_vf_prism`: `strength`→`gain`; `f_caustic`: `intensity`→
`gain`, `strength`→`mix`, dropping the old 0–1.5 extrapolation range in
favor of true 0–100%, mix default kept at 0 per Matt's explicit call to
preserve original off-by-default load behavior). Then built
`f_vf_glow` and `f_vf_streak` fresh with `gain`+`mix` from the start.
Every rebuild diffed clean against its pre-change `.maxpat` — only the
intended renames, no unintended structural changes.

**Two more pre-existing bugs found as rebuild side effects, unrelated to
the renames**: `f_vf_glow`'s `radius`/`falloff`/`strength` dial UI
labels were shifted by one position in the previously-built patcher
(stale build artifact); both `f_vf_glow` and `f_vf_streak` had their
vecfield inlet labeled "vecfield in" (a directional label reserved for
mixed-outlet non-`f_vf_`-prefixed modules) instead of the plain
`"vecfield"` correct for fully-`f_vf_`-typed modules. Both fixed by the
rebuild.

**Skill file consolidation.** Discovered the `vsynth-bpatcher` skill
existed in three diverging copies — mounted Claude Desktop snapshot,
`f_/skills/`, `claude-scaffold/skills/` — each missing content the
others had. Merged into one canonical file, made `claude-scaffold`'s
copy a symlink to `f_/skills/vsynth-bpatcher` so they can't diverge
again. Mounted Claude Desktop copy is a manual-upload step on Matt's
end, not tied to either repo path — needs re-uploading after skill
changes, no automatic sync.

**Rollout status**: all six modules (`f_chladni`, `f_vf_advect`,
`f_vf_prism`, `f_caustic`, `f_vf_glow`, `f_vf_streak`) now have
consistent `gain`/`mix` naming. `f_vf_glow` and `f_vf_prism` confirmed
working in Max by Matt this session. `f_caustic` and `f_vf_streak` not
yet opened in Max — do that before closing the rollout out.

Full detail: `.specify/f_caustic/{spec,plan}.md`, `.specify/f_vf_prism/
{spec,plan}.md`, `.specify/f_vf_glow/spec.md`, `.specify/f_vf_streak/
spec.md`, `vsynth-bpatcher/SKILL.md`'s "Canonical naming" section.



Entries are pointers to where full detail now lives: spec/plan/tasks per
module, `ideas/*.md` for standalone findings, `docs/f-reference/*.md` for
as-built module docs, `docs/max-reference/*.md` for architecture research,
and the `jit-gen-codebox`/`vsynth-bpatcher` skills for reusable GenExpr/Max
findings. When an entry says a finding "is now in" one of these, that's
the place to read for detail — this log won't repeat it.

### 2026-07-12c — f_vf_prism: mix crossfade + 3rd vecfield outlet, five-round formula struggle, vocabulary for composite blend models
Third module through the dry/wet rollout (plan.md work queue #2), fully
complete after five attempts — read `.specify/f_vf_prism/plan.md` ADR 2
for the complete round-by-round history before touching `mix`/`gain` on
`f_vf_glow`/`f_vf_streak`/`f_caustic`.

**Shipped**: `strength` (live.dial, 0-2.0, unchanged from v15) + `mix`
(live.numbox, 0-100%, internal `Param mix_pct` per the naming-collision
fix) + `out3` (gate-weighted dispersion vecfield, ADR 1, combines each
RGB channel's displacement vector weighted by its own already-computed
gate strength — no new sampling passes). `out3_scale` internal constant
(guess 8.0) still needs empirical tuning once confirmed in Max. Also
added `build_patcher.py` support for an opt-in `"widget": "numbox"`
override on float params — the general mechanism for getting a `mix`
numbox instead of a dial on any future module in this rollout.

**The formula took five rounds to land** (round 1: source baked into
"driven" — mix=100% still showed src+effect; round 2: plain crossfade
toward a bare effect layer — double-image at intermediate mix, since
the effect layer is sparse/mostly-black; round 3: coverage-based "over"
compositing using the soft feather-blurred gate as opacity — still
double-imaged, because that gate rarely reaches a clean 1.0; round 4:
pure additive `src+layer*gain*mix` — rejected, same superimposition
problem the whole exercise was trying to fix; round 5, confirmed
correct: full revert to `v15` baseline, then `mix` crossfades toward the
**complete already-composited 100%-state** (`src+layer*gain`), not
toward a bare layer — works because that target is never sparse/black
anywhere, so there's no region for a double-image artifact to appear).

**Two more things resolved along the way, both now general-purpose**:
- **Vocabulary for composite blend models** — Additive/Screen (light
  adds, superimposition is correct), Occlusion/Over (effect replaces,
  needs private per-pixel coverage), Global blend (frame-uniform
  crossfade, wrong for sparse effects). The "novel information" test
  (already used for vecfield outlets) generalizes to composites too:
  occlusion is the only model needing information a module has that
  nothing downstream can reconstruct. Now in
  `ideas/dry_wet_gain_and_novel_field_outlet.md` finding 1.
- **Alpha channel investigated and set aside** — checked whether
  exposing real per-pixel coverage via `out2`'s alpha would unlock
  external "over" compositing. It wouldn't: `vs_alpha_blend`,
  `vs_alpha_blend_2`, `vs_crssfade` all use a manual blend-amount knob,
  none read texture alpha at all. Matt's call: don't refactor around a
  dimension nothing downstream consumes.

**Open, unresolved (flagged, not fixed)**: `strength`'s own composite is
additive/screen — Matt's diagnosis is a prism's actual character (light
becomes separated color, doesn't add on top) is closer to occlusion.
Redefining this needs a real separate "effect color" vs. "gate strength"
distinction and its own scratch verification — real follow-up work, not
resolved today. See plan.md's "Open follow-up" section.

Full detail: `.specify/f_vf_prism/plan.md` ADR 1 and ADR 2,
`ideas/dry_wet_gain_and_novel_field_outlet.md` finding 1.

### 2026-07-12b — f_vf_advect: gain/mix split, mode→live.menu, 3rd vecfield outlet, real Param-name collision found
Second module through the dry/wet rollout (plan.md work queue #2), now
fully complete for this module. `mix_amt` (0-1.5 dial) split into `gain`
(live.dial, 0-4.0) + `mix` (live.numbox, 0-100%, the now-renamed
convention — see previous entry, "wet" renamed to "mix" per Matt's
call). Real bug hit and fixed: a `Param` literally named `mix` collided
with the codebox's own `mix()` operator on the same line — compiled
clean, produced solid black output. Fixed by renaming the internal
`Param` to `mix_pct` while keeping the UI-facing label/attrui attr/
varname as plain `mix`. General finding now in `jit-gen-codebox` skill
(same class as the documented `active`/`inN` collisions). Also
converted `mode` (Ride/Hold/Snap selector on the `separate` feature)
from an unlabeled live.dial to a labeled live.menu — closes plan.md's
standing work-queue item for this.

Also built and shipped the 3rd outlet (ADR 6/Phase 5, specced
2026-07-11, actually built this session): luma-reduced central-
difference gradient of the feedback texture, same idiom as
`f_vf_fieldmap`. Real correction found in Max verification: the
original design (bypass → neutral vecfield, matching `f_vf_flow`'s
convention) was wrong for this module — out3 needs to stay **live**
through bypass, since the feedback loop keeps running regardless of
`bypass` and a derived signal off that loop shouldn't flatten just
because out1 shows dry source. Fixed (`out3 = field;` unconditionally)
and both `spec.md`/`plan.md` corrected to match — `spec.md` briefly had
an inaccurate description of this fix (said "passthrough of source
texture" when the actual behavior is "always the live gradient") that
got caught and corrected in the same pass.

Full detail: `.specify/f_vf_advect/plan.md` ADR 7, ADR 8, and the Phase
5 status note.

Note: `f_vf_advect`'s `separate`/Ride-Hold-Snap feature itself remains
flagged CANDIDATE/UNVERIFIED in its own codebox header comment (dated
2026-07-07) — this session's work did not touch or verify that claim,
only the mix/gain/mode/vecfield-outlet work around it.

### 2026-07-12a — Dry/wet UI convention resolved; f_chladni out3 shipped
Crossfader convention resolved: `mix` control is `live.numbox`, unipolar
0-100% (bipolar considered, dropped — no meaning for negative values;
originally named "wet" during discussion, renamed to "mix" per Matt's
call — see the 2026-07-12b entry above for why that rename mattered).
Now documented in `vsynth-bpatcher/SKILL.md` and
`ideas/dry_wet_gain_and_novel_field_outlet.md` finding 2. This unblocks
the six-module rollout (plan.md work queue #2).
First module through: `f_chladni`'s Decision 7 (out3 magnitude scalar +
`gain` param, unrelated to the wet/dry convention above — chladni is a
pure generator with no source texture to crossfade against). Built,
confirmed in Max: `gain` affects only out3, default `1.0` looks correct,
no tuning needed. `docs/f-reference/f_chladni.md` was badly stale
(pre-2026-06-17 reframe) — fully rewritten to match as-built state.
`f_apollonian` and `f_poincare` both explicitly shelved by Matt this
session — do not resume either without being asked.

### 2026-07-11 — Dry/wet/gain/novel-field-outlet convention
Convention captured, six modules spec'd/planned (`f_chladni`,
`f_vf_advect`, `f_vf_prism`, `f_vf_glow`, `f_vf_streak`, `f_caustic`), one
real bug found/fixed in `f_caustic` (stale codebox file wired in;
`definition.py` now points at the correct one). Full rationale:
`ideas/dry_wet_gain_and_novel_field_outlet.md`. Per-module specifics: each
module's own `.specify/<module>/{spec,plan}.md`. `f_vf_warp` flagged for a
real behavior change (out2 currently ignores bypass) needing Matt's
explicit confirmation before building. No production files touched.

### 2026-07-10 — f_modules menu rebuilt to 8 categories
Complete, confirmed in Max at every step; current state is in plan.md's
Workstreams. One reusable Max quirk found: a single-item `parameter_enum`
in `live.menu` renders raw numbers instead of the label — fix is padding
to a duplicate 2-item enum (remember this if a future single-module
category gets added).

### 2026-07-09 — f_poincare {4,5} tiling confirmed; f_apollonian shelved
`f_poincare`: closed-form {p,q} edge-geodesic formula derived and
confirmed in Max — first real hyperbolic tiling this project has produced.
Full derivation: `.specify/f_poincare/plan.md` Phase 3. `f_apollonian`:
shelved on a genuine unresolved contradiction between two debug views that
should agree and don't — see plan.md's Paused/Blocked and
`.specify/f_apollonian/plan.md` ADR-8. Verified complex/Möbius-transform
machinery (composition rule, adjugate-without-determinant inverse) is now
in the `jit-gen-codebox` skill as known-good. `f_ngon` (regular N-gon
generator, byproduct of this thread) captured as an idea, not specced:
`ideas/f_ngon.md`.

### 2026-07-08 — f_apollonian: three sessions, real bugs, confidence wrongly asserted twice
Full history: `.specify/f_apollonian/{plan,tasks}.md` (ADR-1 through
ADR-8). Headline lesson, worth remembering generally: this module was
marked "confirmed working and correct" twice this day and was wrong both
times — "compiled clean, looked plausible" is not sufficient verification
here. Three real GenExpr bugs found this era are now in the
`jit-gen-codebox` skill (variable names shaped like `in0`-`in7` silently
collide with inlet syntax; loop-scoped variables unreadable after the
loop; `active` collides with a reserved attribute name). A full
`tools/build_patcher.py` regeneration also silently destroyed `f_masonry`'s
hand-built UI in this same era — see the "never regenerate" module list
in plan.md's Build system generalisation section.

### 2026-07-06/07 — f_vf_vorticity built (unverified); f_vf_advect confinement reverted
Current status is in plan.md's Paused/Blocked — don't build on either
without rereading it first. Full diagnostic trail (every hypothesis tried
and ruled out for the confinement fold-in): `ideas/vorticity_confinement.md`
addendum.

### 2026-07-05 — f_masonry ADR 7 shipped
Fixed the "sliced barcode" bug at high `drift` — replaced a single-slot
lookup with a 3-candidate winner-take-all search. Full detail:
`.specify/f_masonry/plan.md` ADR 7. Two instructive bugs from getting this
into production are now in the `jit-gen-codebox` skill (user-defined
functions with multi-value `return` fail silently) and the
`build_patcher.py`/hand-built-UI lesson noted above. Committed as
`e27db16`.

### 2026-07-04 — f_vf_seeds Evolution 2 shipped (texture bombing + multi-owner overlap)
Six-stage `jit.gl.pix` chain, confirmed working incl. fps (59-60fps). Full
architecture and mechanism: `docs/f-reference/f_vf_seeds.md`. Hit and
resolved Max's GL2→GL3 shader-transformer capture-group ceiling twice —
documented in the `jit-gen-codebox` skill. `build_patcher.py`'s
`driving_inlet` mechanism (distinguishing "primary required content"
modules from "optional secondary modulation" generators) reached full
correctness this era after several partial attempts — it's now correct
and self-documenting in `build_patcher.py` itself; no need to revisit the
debugging trail.

### 2026-07-03 — GPU Gems research sweep, complete (all 3 volumes)
Full findings in `ideas/gpu_gems_research.md` and its spawned files,
tracked in plan.md's Parked. Real findings that produced their own
`ideas/` files: godray composition via `f_vf_vortex` → `f_vf_streak`/
`f_vf_glow` (untested); line/mark edge antialiasing for `f_weave`/
`f_masonry` (blocked on whether GenExpr exposes `ddx`/`ddy`-equivalent
derivatives); incremental Gaussian taps optimization (unprofiled);
`f_tone_curve` real LUT-based curve (Matt wants this); `f_lens`
tilt-shift split (undecided); vorticity confinement placement (see
2026-07-06/07 above); Voronoi vs. texture-bombing identity question for
`f_grain`/`f_vf_seeds`; spectral rainbow colormap for `f_vf_prism`; glow
profile shaping + afterimage for `f_vf_glow`; sketchy/uncertainty
perturbation for `f_weave`. Confirmed no-fits (architectural mismatch, not
pursued): analytic water caustics, correlated Perlin noise, anything
needing real 3D voxel data, tangent-space cone-stepping, CUDA RNG,
GPU-optical-flow-style multi-pass CPU-readback techniques, SDF-from-
3D-mesh generation. Small inline confirmations (existing code already
matches a chapter's technique correctly): `f_vf_warp` (Sousa's
refraction), `f_vf_advect` (Stam's Advection step), `f_vf_streak`
(motion-blur-style directional accumulation). No production code touched
across the whole sweep.

### 2026-07-03 — f_sirds built, registered, shipped
First working release, renamed from `f_stereogram`. Full findings/
architecture/citations: `docs/f-reference/f_sirds.md`. Real bugs found by
working the math against the GPU Gems Ch. 41 source directly (seam bug,
depth-map sampling offset bug) rather than by observation alone — worth
remembering as the general approach for anything with a literature
source. `num_strips` fixed at 12 (not live) — a repeat-density
requirement, not a content division.

### 2026-07-03 — Ceyron simulation_scripts notes
Full writeup: `ideas/ceyron_simulation_scripts_notes.md`. Key finding:
`jit.fft` is CPU-matrix-only, not GL-space, so an FFT-based diffusion/
pressure-projection path would need a GPU→CPU→GPU round trip (a genuine
architectural first for `f_`). Agreed next step, not yet done: scratch-
test a plain Jacobi diffusion loop directly in `jit.gl.pix` to test the
"too expensive" assumption empirically before pursuing either FFT path.

### 2026-07-01 — f_stereogram forward-chain architecture proven; jit.gl.pass research
A 4-stage scratch test confirmed a plain `jit.gl.pix` forward chain is
sufficient (no `jit.gl.node`/`jit.gl.pass` needed) for this algorithm's
intra-frame dependency structure — superseded by the shipped `f_sirds`
above. Separately, `jit.gl.pass` subpass chaining against a `jit.world`
with zero 3D geometry was confirmed working — full writeup:
`docs/max-reference/jit_gl_pass_architecture.md` and
`docs/max-reference/intraframe_multipass_architecture.md`. One general
lesson worth keeping: a render-clock/`@enable` default-off setting
produced identical "everything is black" symptoms across unrelated
debugging threads twice in this era — check the render window's fps
counter before trusting any "still broken" visual result as evidence
about the actual logic being debugged.

### Earlier — f_weave orientation response (open)
Not yet resolved; needs a live scratch-patch A/B before deciding between
two candidate fixes. Full writeup, extracted from session discussion:
`ideas/f_weave_orientation_blend.md`.

### Earlier — f_vf_seeds shape-tex architecture (foundational)
The major revision that introduced the external-shape-tex/pure-placement-
engine architecture, the `size`+`stretch` param convention, and bipolar
modulation depths — all now standard conventions across the discrete-item
module family, fully documented in
`docs/f-reference/discrete_item_conventions.md`. Long since superseded by
the Evolution 1.5/2 work above; no need to reread the original session
narrative.

### Earlier — f_grain size_mod inlet (designed, not built)
Small, self-contained, ready-to-build addition. Full design, extracted
from session notes: `ideas/f_grain_size_mod.md`.

---

## Superseded / stale — do not treat as current
The "Module inventory" and "Known issues" lists that used to live at the
end of this file are stale. Current equivalents: README.md's patch table,
and `.specify/plan.md`'s Parked section (which already includes the
still-real items from the old known-issues list: `f_masonry` square
output at non-square render dimensions, `f_hue_processor` band drag).
