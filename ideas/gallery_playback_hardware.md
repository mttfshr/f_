# Gallery playback without the personal laptop

_Captured 2026-11-14 from Matt's question: can Max patches run on an Arduino or another
low-cost processor in a gallery, so the personal laptop stays home? Concept only: nothing
tried. Every claim about third-party hardware, licensing and export paths below is from
Claude's general knowledge, not checked against current vendor docs this session (not
verified). Prices are rough 2026 US figures (inferred)._
_Status: 🔵 research note, not a module proposal. Not a gate._

## Short answer

Not on an Arduino. An Arduino is a microcontroller (no OS, kilobytes of RAM, no GPU), and
Max itself runs only on macOS and Windows. The `f_` library is also the hardest kind of
Max to move: it is Jitter on the GPU (`jit.gl.pix` codeboxes, `jit.world`, GL3), so even
Max's own export routes, which are audio-only, skip it.

So the real choices are: **a cheap dedicated computer that runs Max**, **render to video
and play it back on a cheap player**, or **port the look out of Max** to something a
small Linux board or a browser can run. An Arduino still has a job, as the sensor and
button side of the piece, talking to whichever brain is chosen.

## Routes

### A. A dedicated, cheap Mac running a Max standalone (lean)

- A used Apple-silicon Mac mini (M1/M2, roughly $300-450 used) or a new base Mac mini.
  It runs the same patch, the same GPU path, the same `f_` package. Nothing is ported.
- Build the patch as a **standalone application** (File > Build Collective / Application).
  To my knowledge a standalone does not need a Max authorization on the gallery machine
  (not verified; check the current Cycling '74 licensing page before relying on it).
- Things a standalone must carry that a patch on Matt's laptop gets for free: the `f_`
  package's patchers, `javascript/` files (`f_addmod.js` and any `js`/`jsui`), shaders,
  `.jxf` and media files, and any third-party externals. Missing ones fail silently or show
  as empty boxes, so test the built app on a second machine, never on the laptop.
- Gallery hardening, all macOS settings rather than Max work: auto-login to a dedicated
  user, the app in Login Items, no sleep or screensaver, restart automatically after a
  power failure (`pmset autorestart 1`), a scheduled nightly restart, notifications and
  updates off, and a watchdog (a `launchd` job or a small script) that relaunches the app
  if it quits. Screen Sharing or a remote-desktop tool for checking in from home.
- Fullscreen on the projector: `jit.world @fullscreen 1` on the right display, cursor
  hidden, and a startup patch that loads a fixed preset rather than relying on state.
- Cost: highest of the routes in money, lowest in work. Keeps generative and
  interactive behavior.

A **Windows mini PC** is the same idea and can be cheaper, but the GL3 path then depends
on that GPU's drivers, and the standalone has to be built on Windows. Worth it only if a
Windows box is already on hand (inferred).

### B. Render to video, play back on a media player (cheapest, most robust)

- Record the output (`jit.record`, or Syphon into a recorder) at the projector's
  resolution, then loop it on a dedicated player: a BrightSign-type signage player, a
  Raspberry Pi with a looping player, or the projector's own USB playback.
- Galleries already know how to run these: power on, it plays. Nothing to crash.
- Loses what makes a generative piece generative: no live input, no non-repetition, and
  long renders get large. Mitigations: render a long piece (hours) so the loop is not
  noticeable, or several pieces shuffled by the player.
- Recording at full quality may need to run slower than real time; see
  `variable_framerate.md` for render rate versus display rate, and
  `walkthrough_and_capture.md` for the capture pipeline already being thought about.

### C. RNBO export to a Raspberry Pi (audio and control only)

- RNBO is Cycling '74's export path: patches built in an `rnbo~` object export to a
  Raspberry Pi target, C++, the web and plugins. It covers audio and `gen~`-style code,
  **not Jitter** (per general knowledge, not verified for the current version).
- So it fits the `f_a_` audio side (see `f_a_build_process.md`), or a piece whose sound
  runs on a Pi while the picture comes from route A or B. It does not move any video
  module.
- Requires an RNBO license and rebuilding the audio patch inside `rnbo~`; existing
  `gen~` codeboxes may carry over with edits (inferred).

### D. Port the look out of Max: shaders on a Pi, a mini PC, or a browser

- A `jit.gl.pix` codebox is GenExpr compiled to GLSL, so each module's math is already a
  fragment shader in spirit. A chain of modules is a chain of shader passes with
  feedback textures. That can be rebuilt in a small renderer: openFrameworks, a
  three.js/WebGL or WebGPU page in a kiosk browser, or a VJ app that takes ISF shaders.
- Targets: a Raspberry Pi 5 (about $80, OpenGL ES 3.1), an NVIDIA Jetson Orin Nano (about
  $250, much stronger GPU), or any cheap PC or Chromebox running a browser fullscreen.
- Cost is the porting work, per piece: every module in the chain, its parameter state,
  any feedback, and any input (camera, sensors). The GLSL dialect differs from the
  jit.gl.pix codebox dialect (`skills/jit-gen-codebox/SKILL.md` lists the quirks we know).
- Performance on a Pi is the main risk: multi-pass feedback chains at 1080p may not hold
  frame rate on its GPU (inferred, unmeasured). A Jetson or a mini PC with a real GPU
  removes most of that doubt.
- The browser version doubles as a public, shareable version of a piece; it overlaps the
  `## webgpgpu-derived ideas` section of `INDEX.md` and `walkthrough_and_capture.md`.
- Open question for a spike: can Max show or export the GLSL a `jit.gl.pix` generates
  (not verified)? If yes, porting starts from generated code rather than a rewrite.

### E. The Arduino's actual role: inputs

Whatever runs the picture, an Arduino (or an ESP32 for Wi-Fi) is the right part for the
interactive side: buttons, distance or motion sensors, pots, a presence switch that
wakes the piece. It talks to Max over USB serial (`serial` object) or to a port over
serial, OSC or MIDI. `wind_as_interface.md` already sketches ESP32-class IMU nodes sending
OSC; `CV_TRIGGER_INVENTORY.md` lists what the modules can be driven by.

## Comparison

| Route | Hardware cost | Work | Generative / interactive | Failure risk in a gallery |
|---|---|---|---|---|
| A. Mac mini + standalone | high | low | yes / yes | medium (app crash; watchdog fixes most) |
| B. Rendered video + player | lowest | lowest | no / no | lowest |
| C. RNBO on a Pi | low | medium | audio only | low |
| D. Ported shaders | low to medium | high, per piece | yes / yes | medium (new code) |
| E. Arduino | very low | low | inputs only | low |

## Lean

A first (with E for any interaction), B as the fallback for a show where nothing may go
wrong, and D only for a piece that will be shown many times or wants a web life. C only
when the piece is mainly sound.

## Spikes, none tried

1. Build one existing `f_` chain as a standalone and run it on a second Mac that has never
   had Max installed. Records which package files the collective missed.
2. Run that standalone unattended for a weekend with the hardening settings above; note
   crashes and memory growth.
3. Find out whether a `jit.gl.pix`'s generated GLSL can be viewed or exported.
4. If D is wanted: port one simple module (a single pass, no feedback) to a browser page
   and time it on a Pi 5.

## Questions for Matt

- Is the first gallery piece generative or interactive, or would a long render do?
- Is sound part of it?
- Is a spare Mac already on hand?
