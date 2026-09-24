# Public Walkthrough & Capture Pipeline

_Started 2026-09-24._ Status: ⚪ concept only — discussed, not built, most of
it not yet decided. Emerged from a session on refactoring `mattfisher.io`
(`/Users/matt/Github/mattfisher.io`) toward something much simpler, and from
noticing that the site's current shape doesn't serve a new goal: presenting
`f_` publicly as a walkthrough.

## What's decided vs. proposed

**Decided:**
- Goal: a public walkthrough of the `f_` work on mattfisher.io, not just a
  gallery of finished pieces.
- Recording the media is part of this project. As of 2026-09-24 the repo has
  demo patches (`package/demos/*.maxpat`, several with `.json` presets) but no
  rendered clips or stills.
- Clip inputs are a **mix**: standard test inputs for some, own footage for
  others, chosen per clip by what that clip needs to show to make its
  pedagogical point. No blanket rule.

**Proposed only** (everything below): content model, "stop" unit, spine, capture
manifest, tiers, hosting.

## Why the current site's Folio view doesn't fit

The mattfisher.io Folio view (ADR-012; still implemented as `WorkbookViewer` in
`docs/.vitepress/components/workbook/`, a holdover from before the rename) is a
full-screen slideshow over a collection: items are peers, sorted
reverse-chronologically, paged with prev/next. Sound/post/note renderers are
still placeholders. It answers "show me a body of finished work." A
walkthrough needs the opposite: an authored, ordered, explanatory sequence
where the order carries meaning ("this comes before that because…"). The
Folio view has no way to express that.

`f_` also has structure a chronological slideshow would flatten:
- ~40 modules in three roles (generators / processors / utilities)
- A typed ecosystem: `f_vf_` producers emit `f_vecfield` textures consumed by
  `f_caustic`, `f_vf_warp`, `f_vf_streak`, `f_weave`, etc. — a producer→consumer
  graph, and the graph is the interesting part
- A process story: patchers generated from `src/` definitions, three-tier
  verification (NumPy math → GPU test bench → scratch-patch judgement),
  contract-tested shipped modules, Claude skills. The README already frames the
  repo as "a reference and conversation starter"; the process is arguably its
  most distinctive public content.

## Proposed site architecture

- **Single-source the content.** The site reads `docs/f-reference/*.md` and the
  module inventory from this repo at build time rather than copying `f_`
  content into the mattfisher.io SQLite items DB. Writing lives in one place.
- **The unit is a "stop":** one authored step = media stage (clip or still) +
  short text + links out (module doc, demo patch, source). Stops group into
  chapters; each has a stable, linkable URL.
- **Spine:** a guided path following signal flow (generator → vecfield
  producer → consumer → processor), with process/verification as its own
  chapter. Side doors: a flat module catalog and a producer→consumer diagram.
- **Keep the workbook's good parts** — immersive stage, keyboard nav, auto-hiding
  controls. Change the data model underneath: authored sequences, not a query
  result.
- **Fits the wider refactor:** split the local workspace (sync scripts, SQLite,
  Konva canvas, admin UI) from a lean public site. The walkthrough would be the
  first piece of that lean site: markdown content plus a few small elements (a
  stage, a stop navigator, a module card). A natural place to try Lit; not a
  requirement.

## Capture pipeline (proposed)

**Principle: recordings are generated artifacts, like the patchers.** `f_`
modules are built from definitions rather than hand-patched; clips should be
regenerable the same way, so they stay in sync when a module changes.

**Reuse what exists.** The test bench (`tests/bench/bench.maxpat`, OSC on
7471/7472) and module bench (`bench_module.maxpat`, 7473/7474) already drive a
live Max from Python: load a module in Vsynth's real `vs_render` context, feed
it textures, send every route parameter as a control message, capture outlets,
exchange data via per-job directories (`tests/benchclient.py`). A capture
bench is a natural third sibling. `package/demos/*.json` presets are natural
starting states.

**Capture manifest (one per stop that needs media):** module, preset/demo,
input source, parameter motion (e.g. sweep one control over ~8 s), duration,
output type (loop / before-after / still). A script reads the manifest, drives
Max, writes the clip. Re-run when the module changes.

### Two tiers of media

1. **Reference clips, scripted** — short muted loops for the ~40 modules.
   Make the catalog and the producer→consumer chapter legible.
2. **Hero pieces, hand-recorded** — real performance chains and finished
   work. Need judgement, not a script. Existing Vimeo pipeline and
   collections on mattfisher.io already fit these. Audio-reactive modules
   (`f_chladni`, `f_a_ripple`, anything needing live audio) probably land here.

### Clip types that teach

- **Before/after** for processors (`f_vf_warp`, `f_lens`, …): input beside
  output is the clearest explanation.
- **Parameter sweep loops:** one control moves, showing what the knob is for.
- **Vecfield visualization:** `f_vf_` producers output a texture that's
  hard to read raw; a stop likely wants the field drawn as flow/color next
  to the effect it drives.

### Choosing inputs (decided: mixed, per clip)

Ask per clip what it needs to show. Standard test inputs make modules
comparable and captures reproducible (and are the only option for a fully
scripted run); own footage looks better and shows real use. Likely split:
test inputs where the point is *what the module does to a signal* (or
comparing modules), own footage where the point is *what it looks like in
practice*. The manifest should record which, so a re-run is faithful.

## Technical unknowns (unverified)

- **Video capture path.** The benches capture single float32 frames as `.jxf`
  files, not video. Recording needs either a frame sequence encoded externally
  or `jit.record` / screen capture inside the same OSC-driven loop. Small spike
  to decide whether scripted capture is realistic before committing.
- Whether the module bench (which owns the global `vsynth` context) can run
  capture and the existing contract tests without conflict.
- Deterministic parameter animation over time: is it driven from Python via
  OSC per-frame, or by a Max-side envelope started by one message?
- Frame-accurate looping (start/end state) for seamless loops.

## Hosting (proposed)

Short reference loops at modest resolution are small enough to self-host as
static files (mp4/webm); hero pieces stay on Vimeo. Consistent with the site's
existing external-media thinking (mattfisher.io spec 003).

## Open questions

- Audience: Vsynth module authors, general visitors curious about video
  synthesis, or both? Determines depth per stop and how much process appears.
- Spine ordering: signal-flow path vs. concept-first vs. chronological build
  history. Signal flow is the current guess.
- How much of the process chapter should be interactive vs. plain writing.
- Whether some stops should run the module live in the browser instead of a
  clip — see `web_shim_candidates.md` (Max WebGL/ISF export, untested). A live
  demo and a captured clip could coexist for the same stop.

## Related

- `web_shim_candidates.md` — running `f_` in-browser; alternative/complement
  to recorded clips.
- `f_vecfield.md` — the type contract and family roadmap the vecfield chapter
  would teach from.
- `discrete_item_family.md` — the other shared-identity family worth its own
  chapter.
- `.specify/test_bench/` — design of the bench a capture bench would extend.
