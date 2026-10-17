# Prompt for oh-my-pi subagent work: tensor-family module development

_Paste this to omp as the task prompt. Repo: `/Users/matt/Github/f_/`. Read
`ideas/f_tf_build_brief.md` first — it's the single entry point for everything
below and compiles three longer source docs so you don't have to read all of
them cold._

---

## Context

You're working on the `f_` library: Max/MSP/Jitter bpatcher modules for live
visual performance (Vsynth framework). There's a tensor-field module family
(`f_tf_` prefix) with two modules already built and live-checked
(`f_tf_tensormap`, `f_tf_axisflow`) and a research pass that produced eleven
candidate new modules plus one open architecture question, none of them
specced yet.

Read, in order:
1. `ideas/f_tf_build_brief.md` — the combined brief. Start here.
2. `.specify/f_tf_tensormap/{spec,plan,tasks}.md` — the real template your
   output should mirror in structure and level of detail.
3. Anything the brief points you to for a specific module (the three longer
   source docs it compiles, the peripheral cross-ref docs in its §7).

Do NOT read the three longer source docs cover-to-cover before reading the
brief — that's exactly the redundant work it exists to save you.

## Hard constraints (non-negotiable, inherited from this project)

- **Never call the Anthropic API from any script or tool in this codebase.**
  Not a preference — a hard rule, stated and re-stated by the project owner.
- **Ask before running anything that incurs API billing**, and ask before any
  Max test-bench run (`tests/bench.sh`) — bench runs are expensive in this
  project's own token/time budget; run the one affected test only, `-q`, never
  re-run just to re-verify your own change.
- **Discuss architecture before writing code or specs.** If you reach a design
  fork with more than one reasonable answer, write it up as an explicit
  open-question or decision-gate task — don't just pick one and move on.
- **Verification tiers**: tier 1 NumPy mirror (`tests/test_*.py`) before any
  codebox; tier 2 Max test bench (`tests/bench_*.py`) on the real codebox; tier
  3 scratch patch (`/Users/matt/Vsynth/patterns/`, not version-controlled) for
  expressive tuning. Which tiers apply to a given module is itself a Phase-0
  decision-gate task in that module's `tasks.md` — don't skip stating it.
- **Capture decisions to docs, not just chat/logs** — valuable architectural
  discussion belongs in `spec.md`/`plan.md`/`tasks.md`, written as you go.
- **Never regenerate the shipped module list** or touch anything in
  `.specify/stable/` or `.specify/paused/` without being asked.
- Commit logically split; a commit that only sweeps in files you didn't work
  on is a plain-message save checkpoint, nothing elaborate.

## Phase 0 (yours to do first): the jit.fx / built-in Max audit

Only `jit.fx.cf.kuwahara` has been checked against the candidate catalog so
far (brief §3) — it's the template for how to do this, not the whole job.

1. Enumerate what else exists. Check the local Max bundle if you have
   filesystem access to it (`/Applications/Max.app/Contents/Resources/C74/`
   — refpages under `docs/refpages/`, help patches under `help/`, and the
   Jitter Tools package's own `code/fx/` source if present) — reading actual
   shader/gen source beats refpage prose, as the kuwahara assessment showed.
   If that path isn't reachable from where you're running, use
   `docs.cycling74.com` and general web search instead.
2. For each of the twelve items in the brief's §4 catalog, ask: does anything
   shipped already give this look, even approximately? Where "yes," is there
   still a legitimate **tensor-in** reason to build our own (per the kuwahara
   precedent: the only reason to duplicate a look is letting strokes/kernels
   follow an authored, mixed, or stabilized field instead of only the image's
   own edges) — or is it genuinely redundant?
3. Write findings as a new doc, `ideas/f_tf_jitfx_audit.md`, same evidence
   bar as the kuwahara assessment (read source where you can, mark anything
   inferred-from-prose-only as such).

**Stop after Phase 0.** Do not proceed to Phase 1 without this doc existing.

## Phase 1: triage (decision gate, not full specs yet)

For each of the twelve items in the brief's §4 catalog, write one paragraph:
**build as proposed** / **kill — redundant per Phase 0** / **merge with
<other item>** / **defer — <reason>**. Ground each verdict in the Phase 0
findings and the ranked-chains reasoning in the brief's §5. Write this as
`ideas/f_tf_triage.md`.

**Stop after Phase 1 and wait for review before touching `.specify/`.** This
mirrors the project's own standing rule: architecture gets discussed and
locked conversationally before files get built on top of it. Someone will
read the triage doc and confirm, adjust, or override individual verdicts
before Phase 2 starts.

## Phase 2 (only after Phase 1 is reviewed and confirmed): spec/plan/tasks

For each module that survived triage as "build," create
`.specify/<module>/{spec.md,plan.md,tasks.md}`, mirroring
`.specify/f_tf_tensormap`'s structure:

- **spec.md**: what it does and why, in architecture terms. State its
  tensor-native test explicitly (what's lost if you collapse to a vecfield or
  scalar — the brief's §2 test, applied to this specific module). Cross-link
  back to `ideas/f_tf_build_brief.md` and the relevant source doc the way
  `f_tf_tensormap/spec.md` cross-links to `ideas/f_tensorfield.md`.
- **plan.md**: stage-by-stage signal flow, technical context (Max 9, Vsynth,
  `jit.gl.pix` gen codeboxes, `@type float32`), what's actually risky about
  the build (not the math if a NumPy spike already answers it — the GPU cost,
  the GenExpr bounded-loop shape, anything a spike couldn't settle).
- **tasks.md**: phased build order, explicit Phase-0 blocking gates (the
  verification-tier decision, any remaining open question from the brief
  that bears on this specific module), declared output file layout.

**GenExpr/jit.gl.pix constraints to hold to**: loops must be bounded (no
dynamic iteration count); floats can go unclamped between pipeline stages,
but clamp before any sample the GPU would otherwise wrap out-of-range reads
on; `f_tf_` modules read from `f_tf_tensormap`'s two outlets per
`docs/f-reference/f_tensor_type.md`'s exact encoding — don't re-derive the
encoding, cite the contract.

## A note on module naming

Everything proposed uses the `f_tf_` prefix already. `f_tf_decode` (brief §4,
the open centralized-vs-per-consumer question) is not yet a committed name —
if Phase 1 triage concludes a centralized decode module is the right call,
propose the name as part of that module's own spec rather than assuming it.
