# Wind as Interface — Sensing a Wind-Deformed Dome

_Created 2026-10-10._ Captured from a conversation about a physical build:
a sewn, inflatable, translucent dome, rear-projected from inside and viewed
from outside, deliberately designed to move and deform gently in wind
rather than hold a fixed shape — with `f_` content meant to read as
sympathetic to that movement rather than fighting it. Speculative
throughout, a brainstorm to mull over, not a spec. Cross-reference
`ideas/vector_field_math_concepts.md` (the tensor-field material this
leans on directly) and `ideas/CV_TRIGGER_INVENTORY.md` (existing
control-message conventions this would extend).

---

## The core reframe: design for the deformation, don't correct it

A sewn, inflated, pressurized structure isn't a fixed shape — seams, fabric
stretch, and wind mean the real surface never holds still and was never
going to match a clean mathematical dome anyway. The geometric-correction
toolkit (Tissot's indicatrix, Jacobian-driven anti-aliasing, metric-based
warp authoring — see `vector_field_math_concepts.md` §10-13) answers "how do
I make a fixed, imperfect surface look correct." That's the wrong question
here: the surface won't stay still long enough for a correction to hold.
The better question is what content *character* survives, or even
benefits from, continuous unpredictable deformation.

## Content character matters more than correction math

A sharp grid, text, or anything with hard geometric edges will visibly
"break" with every gust — every wobble reads as an error, because the
content implicitly claims a fixed shape the screen won't hold. Organic,
flow-derived content — `f_vf_vortex`, `f_vf_fluid`, `f_caustic`, `f_grain`
— degrades gracefully instead: it has no rigid shape to violate, so a
billow or ripple in the fabric just reads as more billow. This isn't a new
module, it's a selection principle for what actually gets run on this
structure — the vecfield family is a good fit by nature, not by accident.

There's a conceptual rhyme worth naming even without acting on it: wind
pushing fabric and a vortex/advection field pushing a flow are the same
kind of phenomenon. Content that's itself fluid-sim-like isn't just
*tolerating* the structure's movement, it's expressing the same kind of
math the structure is — one in cloth, one in light.

## The escalation: sense the deformation, don't just survive it

A step further than picking resilient content: actually sense the live
deformation and let it drive the content, so the image's motion follows
the fabric's motion rather than merely coexisting with it. A wrinkle/fold
pattern in fabric under tension is a structure-tensor phenomenon — the
same math as the "unoriented line field" idea in
`vector_field_math_concepts.md` §9 (a fold has an axis, not a signed
direction, same as a fiber or a grain line). Read live from a camera
pointed at the dome, that tensor could modulate the generative content's
own orientation or flow — turning the deformation from a constraint
design around into the actual instrument driving the piece.

## Why this needs distributed processing, not one machine

Camera-based CV and GPU-heavy video synth both want the same scarce
resources — GPU context, VRAM, bus bandwidth for moving frames around —
so running both in one Max process means they fight over the same pool
instead of running in parallel. That's the bogged-down experience from
past attempts. The fix isn't a faster machine, it's making sure what
crosses between devices is the *extracted* field, not raw video: a coarse
grid of orientation/magnitude values is kilobytes, not a video stream, and
a secondary device doing the sensing never touches the Vsynth machine's
GPU at all.

## Sensing options, compared

**Camera + CV, sending a small field texture.** A secondary device
(Mac mini / NUC / Jetson / Raspberry Pi) runs OpenCV or TouchDesigner,
computes a structure-tensor field from the camera feed, reduces it to a
small texture (orientation + anisotropy packed into RG, same spirit as
`f_vecfield`'s existing contract), and streams *that* — not the camera
feed — over NDI to the Max machine as an ordinary texture input. Gives
real spatial resolution (content can track which side of the dome is
moving) at the cost of more setup complexity and camera-reliability risk
(night lighting, dust, needing a clean view of the structure).

**Distributed IMU nodes, sending OSC.** Several motion sensors sewn
directly into the fabric at different points, each reporting its own
patch's acceleration/rotation — no camera, no CV pipeline, no GPU
contention anywhere. Coarser (a handful of points, not a dense field) but
simpler and far more robust. Candidate part: the Adafruit LSM6DS3TR-C,
6-DoF (accelerometer + gyroscope, no magnetometer) on a STEMMA QT/Qwiic
breakout.

- **6-DoF over 9-DoF is the right call here**, not a lesser option — a
  magnetometer adds absolute compass heading, which isn't needed (the
  goal is relative motion of a fabric patch, not which way is north), and
  it's the part most prone to interference from nearby metal/electronics
  in a sewn structure full of wiring.
- **STEMMA QT/Qwiic** means solderless, keyed connectors — real value for
  a hand-sewn, field-repairable build. One limitation: the breakout
  typically supports only two selectable I2C addresses, so more than two
  sensors on one bus needs an I2C multiplexer (e.g. Adafruit's TCA9548A,
  also STEMMA QT).
- **Better architecture for 3-4 sensor points: one small ESP32 per sensor**
  (some Adafruit boards, like the QT Py ESP32-S2/S3, have STEMMA QT built
  in), each independently sending its own OSC over WiFi — rather than one
  hub plus a multiplexer juggling all of them. More units, but each is
  simpler, and one node failing doesn't take down the whole network.
  Software path: Adafruit's `Adafruit_LSM6DS` Arduino library +
  CNMAT's OSC-for-Arduino library, both well-trodden for exactly this kind
  of interactive-art sensing.

**A plain wind sensor (anemometer).** Measures the air, not the fabric —
and would need mounting *away* from the dome, since the structure itself
disturbs the airflow right around it. Gives the cause (wind speed/
direction) rather than the effect (how the dome actually moves), which
would then need inferring back onto the structure's real behavior — an
extra, fuzzier step compared to sensing the fabric's motion directly.

## Transport: WiFi/OSC over LoRa

LoRa trades bandwidth for range — built for small, occasional packets over
kilometers on very little power, often with duty-cycle limits on how often
you're even allowed to transmit. This project needs the opposite profile:
continuous, low-latency updates from sensors within a few feet of each
other on one structure. WiFi (free with an ESP32) has far more bandwidth
and lower latency, and range isn't a real constraint when everything's on
the same dome. LoRa would make sense if the sensors were scattered far
apart with no shared network — not the case here.

---

## Open questions, not yet answered

- Single overall "wind mood" signal (simpler, less setup) vs. genuine
  regional/spatial response (more sensors or a camera, more setup) —
  undecided; depends how much the content needs to visibly track *which*
  part of the dome is moving vs. just that *something* is moving.
- Whether IMU data needs any smoothing/feature-extraction on the ESP32
  itself (e.g. an "activity level" per node) before it's useful as OSC
  control data, or whether raw accel/gyro into Max and processed there is
  fine to start.
- Camera route's structure-tensor idea is real but un-prototyped — no
  check yet on whether a cheap camera + CV setup can actually resolve
  fabric wrinkle orientation at a useful frame rate on a secondary device.
- Power for fabric-mounted IMU nodes (battery vs. a thin wire run) not
  decided — depends on final sensor count and placement.
- No decision yet on which sensing approach (if any) this build actually
  uses — this file is explicitly for mulling over, not a plan.
