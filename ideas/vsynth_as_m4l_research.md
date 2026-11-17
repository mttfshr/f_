# Vsynth as Max for Live devices: scope and LOE (first pass)

_Started 2026-11-17 (Matt's question). Desk research only: repo reading, the installed Vsynth 1.7.0 package, and one round of web search. **Nothing was built or run in Live; every effort figure is inferred, not measured.**_

## The question

What would it take to refactor Vsynth (Kevin Kripper's package; `f_` is the extension layer on top) as a set of Max for Live devices, and how big is it?

## What Vsynth is, from the installed package (observed 2026-11-17)

- `Packages/vsynth`: 102 `vs_*` module patchers, 16 abstractions, 97 gen files in `code/`, 108 helpfiles, 73 media files, a parallel vector subsystem (`patchers/vector/`). Min Max 8.5.0. No `.amxd` anywhere.
- Modules are **bpatchers chained by patch cords carrying `jit_gl_texture` names.** The chain is the instrument.
- Shared state is by **global `send`/`receive`**: `r draw` (frame clock), `r canvas` / `r canvas_lfo` (global enable), `r vs_ntime` and `r trig_res` (time and sync), plus `vs_render` owning the one GL context and `vs_black`. `vs_inState` detects a connected inlet by timing against `r draw`.
- Per `docs/vsynth-reference/patterns.md` and `vocabulary.md`, which are my notes from 2026-05-31 and which I did not re-verify against the package this session.
- `f_` adds ~58 modules (`src/`, 63 patchers) on the same conventions, plus a build system that generates patchers from `definition.py`.

## The structural problem

A Live device is its own patcher in its own device chain. Live carries **audio and MIDI** between devices, not textures. Vsynth's core mechanism (a texture on a cord from one module to the next) has no equivalent across devices. Anything else (UI, params, gen code) ports almost unchanged, since modules already use `live.*` objects and Ableton Sans Light.

From the search (community forum posts and Cycling '74 docs, mixed Max versions, **not tested by me**):
- Texture sharing across devices is reported possible by giving every device the same named GL context and managing `drawto`, ideally with one "main context" device owning `jit.world`; a forum report had a send/receive texture work briefly and then error out.
- `jit.world` in a device needs an implicitly named or `---` context; reports of the context name changing on set reload.
- `@shared 1` on the window object is the usual advice for textures across contexts.
- Multiple instances of the same GL objects are hard to keep in sync.

Sources: [M4L devices and Jitter Texture sharing](https://cycling74.com/forums/m4l-devices-and-jitter-texture-sharing), [Jitter Limitations in Max for Live](https://cycling74.com/forums/jitter-limitations-in-max-for-live), [Max for Live Limitations](https://docs.cycling74.com/userguide/m4l/live_limitations/), [Jitter and Max for Live](https://docs.cycling74.com/max8/vignettes/jitter_and_Max_for_Live), [Jitter GL contexts](https://docs.cycling74.com/max8/vignettes/jitter_gl_contexts).

## Licensing (decide before any build)

Vsynth is CC BY-NC 4.0 (`docs/vsynth-reference/*`). An adaptation needs attribution and may not be commercial without Kevin's permission. His site lists Max for Live device building as a service, and he already sold "Vsynth Patchbook", a Vsynth-derived M4L device ([listing](https://maxforlive.com/library/device.php?id=3990)). So: free and attributed is likely fine; paid, or anything that competes with his offering, needs his agreement. Worth asking him anyway, since he may have solved the chaining problem. This is a decision for Matt, and the answer changes the scope.

## Three architectures

| | A. One device per module, shared context | B. One rack device hosting the chain | C. Hybrid |
|---|---|---|---|
| Shape | A "Vsynth Hub" device owns `jit.world`; each module device renders into a named texture and reads its input texture by name | One device with a module-slot host (like `f_addmod.js` / `f_modules`) | Hub plus a small set of generator and mixer devices; processors stay inside a rack |
| Chain order | Not carried by Live; needs a routing UI (input/output slot names) or a convention | In-device, as today | Mixed |
| Live wins | Per-module automation, Macros, MIDI and audio mapped to any module, native-feeling | Automation of whatever is exposed; one device on the track | Best of both for the modules that matter |
| Risk | Highest: cross-device GL sharing, set-reload ordering, per-device GPU overhead, global `r draw`/`vs_ntime` needing a single owner | Lowest; closest to what Patchbook did | Medium |
| Inferred LOE | 4-8 months for the full ~100 + ~58 library | 2-4 weeks for a working rack with a starter set, then ~0.5 day per module | 6-10 weeks for hub + ~15 devices |

All LOE figures are **inferred** from module counts and my guess of per-module effort (re-skin, Live parameter visibility and naming, I/O adapter, freeze, test), with no timing data from this repo. Treat them as order of magnitude.

## Cost drivers (inferred)

1. **The hub and the routing model** (A and C): the one real unknown. A spike would settle it.
2. **Global receives**: `r draw`, `r canvas`, `vs_ntime` become per-device or hub-owned; a device cannot assume the rest of Vsynth is loaded. M4L devices must be frozen and self-contained, so the 16 abstractions and the gen files get embedded or the device depends on the package.
3. **Live parameters**: `live.*` objects already automate, but Live's parameter limit per device, long names and `pattrstorage` presets (e.g. `f_util_vary`) need checking.
4. **`f_` build system**: `build_patcher.py` emits `.maxpat`; an `.amxd` wrapper (device header, `live.thisdevice`, freeze) would be a new target. Moderate, and it keeps the drift and bench tests useful.
5. **Test coverage**: the Max bench (`tests/bench.sh`) drives patchers in Max, not Live; Live-hosted behavior would be live-only checks by Matt.
6. **Out of scope unless asked**: the vector subsystem, audio-reactive modules (those get easier in Live), Windows.

## Proposed next steps (each needs Matt's go; none run yet)

1. Ask Kevin Kripper about permission and prior art.
2. Spike S1 (about half a day, live in Live): two tiny devices, a hub with `jit.world` and one generator device writing a named texture, one processor device reading it; check reload, delete order, and two instances. This decides A versus B.
3. Spike S2: a frozen device containing one real Vsynth module and one `f_` module, to see what the freeze pulls in.
4. Then re-estimate with measured numbers.

## Asks for Matt

- Is the target free and attributed, or commercial? (Changes whether Kevin's permission is required.)
- Do you have Live with Max for Live on this machine, and which Live and Max versions? S1 needs it.
- Go on S1, or on emailing Kevin first?
- Should this stay under `ideas/` only, or get a gate row in `.specify/gates.md`? I have not added one.
