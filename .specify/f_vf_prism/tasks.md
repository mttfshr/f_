# f_vf_prism — tasks

_Created by the 2026-10-12 maintenance pass: the folder had
spec.md/plan.md/continuity.md but no tasks.md. The original build's
task tracking lived in plan.md phases. Ids start at T001._

- [ ] T001: Profile the 11-tap blur's cost including the bypassed
  full-cost question: the 33 gate calls (11 taps × 3 channels, each a
  displaced sample) are fully unrolled with no early-exit guard under
  param bypass; no measurement exists. Fold into the glow/streak
  profiling session (all three are the same class). Note: the out3
  BYPASS_EXPECT entry {3: ("vec", 2, 0.0042)} is one of the entries
  bench_modules.py's header still marks "not yet seen green live" —
  that header comment is stale vs the 2026-10-06 33/33 live run (plan.md);
  fix the comment in the same pass. Also while auditing cost:
  ideas/incremental_gaussian_taps.md names prism's "per-tap exp()" —
  stale, shipped v17 uses precomputed constant weights w0–w5; correct
  the idea file when touching it.

- [x] T001a (2026-10-13): Profiled on the live bench
  (`tests/records/spike_four_module_cost.py`, 512², chain=128, median of 3):
  ~0.0169 ms/pass active, ~0.0151 ms/pass bypassed — **not GPU-bound
  even at chain=128** (upper-bound figures only, below the bench's
  ~2–3.5 ms CPU-overhead floor at this resolution/chain). The 33 gate
  samples are confirmed negligible at practical resolution regardless
  of bypass state; no shader-side guard is warranted. The bench header
  staleness note above is unrelated and still open.

- **2026-10-20, clamp edge fix:** v17's three `displaced_r/g/b` helpers clamped the displaced coordinate to exact [0, 1], so on the GPU (probe P9: x = 1.0 reads the first column, y = 0.0 the last row) gate taps near the right and low-y edges read the opposite edge's luma. Bounds are now 0.001 / 0.999 (six lines plus a comment). Patcher regenerated, one-line diff, `drift.py -v f_vf_prism` ok. No tier-1 mirror exists. Tier 3 pending (Matt): a bright left or top edge should no longer produce prism fringes along the right or bottom edge.

- [x] T002 Stable preflight (2026-11-06, offline by Claude), record below.
- [ ] T003 Matt's helpfile look: the new demo chain at defaults, the digest, the two notes.
- [ ] T004 Matt's call: tier-1 mirror. None exists and prism is in the `P-mirrors` queue; skip, or build before the move.

## Stable preflight (2026-11-06)

Part 1 offline by Claude: drift ok after the comment edits, no baseline entry; menu and launcher `--check` up to date; README row 109 chars, no ⚠; menu entry under ∇ Effects, recipe Motion Prism; bypass is `bypass_gate` (`bypass_mode: "param"`, `BYPASS_EXPECT` has outlets 2 and 3; `bench_modules.py` 2/2 in `tests/logs/20261106-081412-bench.log`, from before these edits, which touch no patcher or codebox); helpfile box 208x170 against a footprint of 190x160 (the Reach label starts at x -7.5). The route has no `bypass` selector and the helpfile has no `bypass [0 / 1]` line, which is right. Gates: only `P-mirrors` names prism. Tests: no mirror (T004), no `bench_*` file of its own; the contract bench, plus offline out3 cases in `tests/contracts/test_bench_expect.py`.

T001 stays open until the main session applies its two shared edits: the `bench_modules.py` header and `ideas/incremental_gaussian_taps.md`. The cost part is T001a. The "33/33 (plan.md)" source could not be found in any plan.md; the 2026-11-06 log above is the evidence instead.

The 2026-10-20 note's Tier 3 pending is closed per `HANDOFF_ARCHIVE.md:950` ("all tier-3 looks passed", naming prism; the triage's `:941` is off by nine lines). That line does not say who looked or what was seen; not verified here. The dated note is left as written.

Patcher against docs: four inlets (source + control, vecfield, reach mod, spread mod), three outlets, by rect order. `vs_inState` on inlets 1-3 with the `vs_black` fallback; no `r draw`, so only the texture on inlet 0 triggers the pix (wiring read, not run). `@type char`.

Fixed in the doc: "Two outlets" and `strength` (three outlets, `gain`); the diagram now has all three and zero-based inlets. The gate is not luma: each channel gates on its own value, so a pure color casts only itself (code read, not run). `gain` and `mix` do not reach the isolated layer. Added what the doc lacked: trigger, the zero-field case (bright pixels still brighten, as `spec.md` implies), `field_suppress`, mod inlets (red, no depth control), out3, bypass per outlet. The Chroma comparison said Chroma is ungated; its own doc says it gates on luma, so that sentence is rewritten (Chroma is paused and was not analyzed further). `definition.py` comments: inlet numbers, and out3 is not float32.

Out3 is 8-bit because the pix is `@type char`, against `f_vecfield_type.md`'s float32 rule. The bench tolerance already allows for it. Recorded as fact, not changed. It clips at a `reach` of about 0.04 with three open gates on a full-strength field, below the default (worked from the code, not run).

Chains in `library-characteristics.md`: by type all hold (texture into inlet 0, vecfield into inlet 1; `out2` there is the third outlet, zero-based). Line 46 says luma-gated, and line 313 leaves out the source on inlet 0; edits returned to the main session, with README, inventory and the idea files. `f_vf_ch` was read from the inventory only.

Helpfile: confirmed nothing was wired upstream, so the demo drew nothing. Added `vs_sources_main` to inlet 0 and `f_vf_flow` (the pairing `f_demo_ngon` uses) to inlet 1; box counts corrected to 4 in, 3 out. Expected at defaults (from the codebox, not seen): source plus a bright echo about 5% of the frame along Flow's field, with color only as a thin fringe at bright edges (about 0.005 UV), white inside large bright areas. No pixel over 0.7 means output equals source. `vs_sources_main` opens on the Movie tab, so this depends on a movie being loaded. Neither note overlaps the preview (rects: preview 338-574 x 456-705; notes 560-785 x 271-358 and 590-780 x 456-569). Preview bottom is 705, past the skill's 681 usable height; nobody has looked. JSON parses. Live by Matt: T003.

Left alone: `continuity.md` (a 2026-06-20 session doc that stops at v14, not the tasks record); `spec.md` (`bypass` lines say black and neutral; line 228 says out3 is near-neutral where gates agree, the code does the opposite); the `Luma gate` hints in `definition.py` (executable, they reach the patcher); `codebox_v17.gen`'s "strength-scaled" comment (a bench input).
