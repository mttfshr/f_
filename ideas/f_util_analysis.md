# f_util_analysis — texture analysis utility family

**Status:** Ideation — not yet specced individually. `f_util_profile` is furthest along; `f_util_envelope` is a companion utility. Others are named but not yet developed.

---

## Design principle: proprioception

These utilities give a Vsynth patch awareness of its own visual content. The output is not a display or a texture — it's a control signal derived from what the system is currently rendering.

This is categorically different from external control (MIDI, audio, OSC) or WFG modulation textures. Those impose behavior from outside. Analysis utilities enable behavior that *emerges from the content itself* — the patch responding to what it's doing rather than what it's told.

**The concrete case:** A weave patch that knows its own luminance distribution per band isn't just parameter-driven with extra steps. It can develop internal coherence — bright regions behaving differently from dark regions according to rules that emerge from the content itself rather than being imposed externally. The rule is simple and fixed; the behavior is complex and changing because the signal driving it is itself dynamic. That's the loop.

**Why this matters for the library:** Analysis utilities change what *other* patches can do. They enable a class of patch behavior — texture-responsive, self-referential, content-driven — that nothing in Vsynth currently supports. `vs_b2b` fires one bit of information when mean luma crosses a threshold. That's the ceiling of native Vsynth self-awareness. This family raises it substantially.

---

## Shared architecture

All analysis utilities follow the same pattern:

```
GPU texture → jit.gl.asyncread → CPU matrix → aggregation function → control signal out
```

The GPU→CPU readback via `jit.gl.asyncread` is the shared bottleneck and shared infrastructure. `f_util_profile` establishes this pattern; subsequent utilities inherit it.

**What these share:**
- Texture in, no texture out — not image operators
- Small output: a float, a coordinate, a short vector
- Raw signal out — conditioning is the caller's responsibility (or `f_util_envelope`'s)
- `f_util_` prefix signals infrastructure, not image operator

---

## Known design gaps to hold

**Temporal structure.** These utilities answer "what is this texture doing right now?" The interesting behavior often lives in how the signal *changes over time* — rate of change, periodicity, acceleration. A slowly oscillating centroid is different from a jumping one. This dimension is easy to miss when thinking in pictures.

**Signal relationships.** The ratio or difference between two analysis outputs is often more stable and meaningful than either alone. Centroid position relative to variance, motion energy in one region vs another.

**Signal conditioning.** Raw output from any of these will be noisy and jumpy. The gap between "GPU produces a number" and "that number usefully drives a parameter" is mostly conditioning. This is `f_util_envelope`'s job.

---

## f_util_profile

**What it measures:** Luminance distribution across spatial bands. Divides the incoming texture into N horizontal slices, computes mean luminance per slice, outputs a 1×N `jit_matrix`.

**Why it's the first:** Shaders can't aggregate information across pixels — every pixel only knows its own position. `f_util_profile` does that aggregation upstream. The output gives band-level coherence driven by texture content, which a shader alone can't achieve.

**Interface:**
- inlet: texture in
- param: `freq` — number of slices; match to upstream generator's spatial frequency
- outlet: 1×N `jit_matrix` of mean luminance values per band

**First integration target: f_weave**

Each pixel in the weave codebox already knows which band it belongs to (Y coordinate → band index). With the profile vector available, that pixel can look up its band's current luminance and modify its own behavior:

- **Speed** — bright bands animate faster than dark bands
- **Phase offset** — bright bands lead or lag dark bands in animation cycle; produces traveling wave effect across bands
- **Thread width** — density tracks luminance; coarser where there's more energy
- **Over/under dominance** — crossing occlusion rule varies with band luminance

The rule is simple and fixed; the behavior is complex because the luminance distribution driving it is itself dynamic.

**Open questions:**
- Consumption pattern downstream: `jit.iter`, `peek~` into buffer, something else? Shapes output format.
- Orientation: horizontal slicing assumed. Vertical or angular configurable?
- Output statistic: mean first; variance or peak useful later?
- Bpatcher vs abstraction: produces no visual output — UI panel may not be warranted. Decision deferred until implementation suggests what it needs to be.

---

## f_util_envelope

**What it does:** ADSR-style conditioning for control signals. Sits downstream of any analysis utility. Not tied to `f_util_profile` specifically — any float or short vector can pass through it.

**Why ADSR rather than simple smoothing:** Attack/release treats rise and fall with one asymmetry. ADSR separately shapes the initial transient response and the sustained response. This maps well to visual behavior:
- Fast attack, slow release: signal lunges at changes and hangs — responsive but persistent
- Slow attack, fast release: sluggish to respond but drops quickly — a different character entirely
- The sustain level lets the signal hold at a meaningful plateau rather than immediately beginning release

**Why this matters for proprioception:** Without shaping, per-band speed or phase driven by a raw luminance vector would jitter every frame. The smoothed signal gives the patch's response to its own content a feeling of *intention* rather than noise. The system appears to be making decisions rather than twitching.

**Interface:** (sketch only)
- inlet: float or jit_matrix
- params: `attack`, `decay`, `sustain`, `release` — times in ms
- outlet: shaped signal, same format as input

**Open questions:**
- Does it handle both scalar floats and 1×N matrices, or is it scalar-only with per-element behavior?
- Should it live as a bpatcher or a Max abstraction (no UI)?

---

## Other analysis utilities — named, not yet developed

These follow the same GPU→CPU pattern. Listed here to establish the category; to be developed when a specific integration target motivates them.

**Centroid** — weighted average of pixel position by luminance. Outputs (x, y) coordinate tracking center of visual mass. Evokes: motion of boundaries toward/away from center of mass; coloration gradients toward center of mass.

**Variance** — spread of luminance distribution. High = strong contrast, low = homogeneous. One float tracking visual complexity. Evokes: comparative contrast measurement vs earlier frame or vs another region.

**Dominant frequency** — which spatial scale is most prominent. Coarse vs fine structure. Evokes: band-pass comparison; controlling spatial frequency of a response.

**Motion energy** — frame-to-frame difference, summed. How much changed between this frame and last. Requires holding a previous frame (architecture implication). Evokes: color/hue adjustment driver — knowing where moving edges are to color them.

**Regional contrast** — divide frame into zones, compare luminance between adjacent zones. Spatially structured, not global like variance. Evokes: vector field setting — driving regional displacements from contrast map.

**Common thread across all:** The most interesting outputs preserve *some* spatial structure rather than collapsing all the way to a scalar. Even `f_util_profile`'s 1×N vector preserves one spatial dimension. Fully collapsed scalars (one float for the whole frame) lose the spatial indexing that makes content-driven behavior interesting.

---

## Priority

1. `f_util_profile` — furthest developed, clear first integration target (f_weave), establishes GPU→CPU readback pattern
2. `f_util_envelope` — needed immediately once profile is producing raw signal; unblocks any integration work
3. Others — motivated by specific integration targets as they arise
