# A GenExpr interpreter: is it worth it?

_Created 2026-10-18. Status: 🔵 analysis note, no decision. Question from Matt: what would the relative level of
effort and the benefits of writing a GenExpr interpreter be, and is it worth thinking about?_

**Short answer.** Worth thinking about, not worth building yet. The strongest honest case for it is narrower than it
first sounds, and the repo's own evidence does not yet show that hand-translating codeboxes is the thing costing us
time. The cheap, informative move is a one-session feasibility spike plus a small tally (both below), then decide.
Everything labeled "estimate" is my judgment, not a measurement.

## What it would replace

Today a *mirror* (`tests/modules/*/..._mirror.py`, `tests/lib/gpu_sim.py`) is a hand translation of a codebox into
NumPy. Tier 1 checks the mirror against independent ground truth; tier 2 (the bench) diffs the real codebox on the GPU
against the mirror. See "The idea, and what it does and doesn't prove" at the top of `tests/README.md`.

An interpreter (or a transpiler that turns a `.gen` file into NumPy source) would run the **shipped codebox itself**
on the CPU. The mirror, as a separate hand-written artifact, goes away. Nothing about ground truth changes: the
interpreted code would still be checked against `np.fft`, closed forms and so on.

## Benefits, in order of how real they are

1. **Removes one error class: translation and drift between a codebox and its mirror.** A mirror can be wrong about
   the shader, or go stale when the codebox changes, and only the bench notices. With an interpreter there is one
   artifact. This is real but bounded: it only matters to the extent that translation errors are what we actually hit
   (see "Evidence" below).
2. **Tier-1 coverage of everything, not just modules that got a mirror.** There are 88 `.gen` files under `src/`
   (about 9,000 lines, including historical versions and scratch variants). Mirrors exist for a subset: the fluid
   solver, caustic scatter, the seven `f_tf_` modules and a few others. An interpreter makes every codebox testable
   offline, including the ones nobody wrote a mirror for.
3. **One generic bench test instead of many bespoke ones.** "Interpreter output equals GPU output for this codebox on
   these inputs" is a single parameterized test. Run across all codeboxes, it also becomes the interpreter's own
   validation. This is the most attractive part of the idea, and it is also where most of the cost lives.
4. **Faster iteration on codebox math** without a mirror-writing step. Useful for new modules, speculative for old ones.
5. **Speculative side benefits** (CPU previews, docs figures, a web shim). Max's `exportcode` already covers the web
   shim (see `ideas/web_shim_candidates.md`), so I would not count this.

## What it would not do (the important limit)

The findings that have actually mattered were **GPU and Max behaviors**, not translation errors:

- runtime `atan2(0, 0)` is NaN though constants fold to 0
- `sample()` falls back to nearest when its coordinate is data-dependent and jumps
- the 8-bit-weight ceiling on interpolated reads (about 2e-4 stacked)
- `dim` reads 1 inside a live `jit.gl.pix`; the bench GPU wraps out-of-range reads
- `phi` is a predefined constant and assigning it fails the whole compile
- `atan2` returns +pi where IEEE gives -pi at the branch cut

An interpreter reproduces only what we have already learned and encoded. Each of those was found on the bench and
then written down; an interpreter would need the same quirks encoded by hand, after the fact, and could not have
found any of them. It does not replace the bench, and it adds a second implementation of GenExpr semantics (ours)
that itself has to be validated against Max. That validation is the bench, again.

## Level of effort (estimate)

The subset the library actually uses is small, which keeps the core cheap. From a rough, comment-stripped scan of
`src/**/*.gen`: 14 `for` loops (fixed count), 3 `if`, no `while`, no `History`, `Buffer` or `Data`. The most used
calls are `sample`, `vec`, `clamp`, `mix`, `sin`, `step`, `max`, `floor`, `smoothstep`, `fract`, `nearest`, `sqrt`,
`cos`, `abs`, `pow`, `min`, `exp`, plus `Param` declarations and a few codebox-defined helpers.

| Piece | Notes | Rough size |
|---|---|---|
| Parser for the used subset | C-like statements, expressions, `Param`, `in`/`out`, swizzles, codebox-defined functions, `for`, `if` | small: a focused session |
| Vectorized evaluator or NumPy transpiler | vec arithmetic and broadcasting over `(H, W)`; `if` needs masked execution (`np.where`); fixed loops just unroll | small to moderate |
| Builtins | about 20-40 functions; `sample`/`nearest`/`grid` already exist in `gpu_sim.py` | small |
| Predefined names and semantics | `norm`, `dim`, `cell` (= `norm * (dim - 1)`), multi-outlet `outN`, float32 throughout | small, but it is where subtle errors hide |
| Validation against the GPU across all 88 codeboxes | needs bench time and per-file debugging; this is where surprises show up | **the largest and least predictable part** |
| Keeping it faithful as quirks are found | ongoing, never finished | ongoing |

My estimate: **a working subset interpreter is about 2-4 focused sessions; a trusted one, validated across the
library, is more like 6-10 or more, mostly validation.** The risk is not the parser; it is discovering, file by file,
where "what we think GenExpr does" and "what Max does" differ.

**Transpiler vs tree-walking interpreter.** For this subset I would lean toward generating NumPy source: readable
output you can print and step through, vectorization is natural, and a generated function can be diffed against the
existing hand mirror. Either way, unsupported syntax should fail loudly rather than guess.

## Alternatives that give part of the benefit for less

- **Exported GLSL through a software GL.** The 2026-10-12 web-shim trial showed `exportcode` works and the output
  runs in headless Chromium. But that tests exported GLSL, not what Max runs, so it is a third implementation, with
  the exporter's known gaps (outlet collapse, 8-bit RGBA, hardwired inputs). Cheap to try, weaker as evidence.
- **Keep hand mirrors and make them cheaper:** the tf mirror extraction (Phase C) and a shared tensor helper already
  reduce the cost of writing one. Low risk, partial benefit.
- **A static "mirror lint"** (does every function and constant in the codebox appear in its mirror). Cheap, catches
  little.

## Evidence we have today, and what is missing

What the repo's records show: mirror and wrapper bugs have cost time (key-mapping bugs in the aniso and sharpen
mirror wrappers and a fixture bug in sharpen's bench, 2026-10-17; three of four first drafts of the atan2 tests failed
on test-side bugs, 2026-10-12; "a red here is as likely to be the harness as the GPU"). But those are mostly
**harness and wrapper bugs**, not translation errors in the mirror's math, and I do not see a recorded case of a
translation error that survived tier 1 and was caught only by the bench. The costly discoveries were GPU quirks, which
an interpreter would not have found. So the benefit most specific to an interpreter (item 1) is **plausible but
unevidenced**. That, not effort, is the main reason not to start.

## Suggestion

1. **Tally, starting now.** When a bench or tier-1 failure is resolved, note which kind it was: *translation error in
   a mirror*, *GPU/Max quirk*, or *harness/wrapper bug*. A line in the module's `tasks.md` is enough. After 10-15
   entries the question mostly answers itself.
2. **One time-boxed spike (one session):** transpile one real codebox that already has a mirror (`f_tf_axisflow` is
   small) into NumPy, and diff it against its hand mirror. This measures how much grammar the subset really needs, how
   awkward masked control flow is, and whether the generated code is readable, at a cost far below the full build.
3. **Revisit** only if the tally shows translation errors are a real share, or the spike comes in much easier than
   estimated. Until then the open decision gates and module work are better uses of the time.

## Related

`tests/README.md` (what the mirrors and the bench do and do not prove) · `tests/lib/gpu_sim.py` ·
`.specify/test_bench/` · `ideas/web_shim_candidates.md` · `skills/jit-gen-codebox/SKILL.md` (the bench-verified quirks)
