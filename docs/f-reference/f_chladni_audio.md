# f_chladni_audio — Patch Reference (As-Built)

**Type:** Audio-to-control bridge (audio in → control messages out) — MSP, no texture path
**Status:** ⚠ Unverified, and **out of step with `f_chladni`** (see the contract mismatch below). Hand-built; in `package/patchers/`, not in the `f_modules` menu.

_Reference written 2026-10-22 from `package/patchers/f_chladni_audio.maxpat` (read object by object), `docs/f-reference/f_chladni.md`, `.specify/f_chladni/{spec,tasks}.md` and `ideas/scratchpad.md`. This doc describes what the shipped patch does, not what the README or the `f_chladni` docs say it does._

---

## The contract mismatch (read this first)

The README row, `f_chladni.md` ("Companion Patches") and `.specify/f_chladni/` all describe this patch as `sigmund~` pitch → `note`, `peakamp~` → `amp`. **The shipped patch contains neither `sigmund~` nor `peakamp~`.** It is the *superseded* eight-band filterbank version: it emits `m0amp` … `m7amp` messages, one amplitude per Chladni mode.

`f_chladni` no longer accepts those messages. The 2026-06-17 single-resonance reframe replaced the `m0amp`–`m7amp` / `z0`–`z7` / `ph1`–`ph7` parameters with `note` (0–127) and `amp` (0–1), and `src/f_chladni/definition.py` has no `m*amp` parameter. So the shipped companion cannot drive the current `f_chladni`.

Task T123 (create the `note` / `amp` companion) is still open, as are T140 (verify with a mic) and T141 (this doc). What is below is the as-built filterbank patch.

---

## What it does

Splits an audio signal into eight resonant bands tuned to the eight Chladni modes, follows the level in each band, and sends the eight levels out as control messages every 20 ms. A listener plays an instrument or a mic into it and gets eight slowly-moving numbers describing how much of the signal sits in each mode's band.

It is an *analysis* module: it makes no sound and no texture.

---

## Signal Flow

One signal inlet, one wired outlet (messages).

```
inlet~ -> 8 x biquad~ (band-pass resonators, one per mode)
          each -> abs~ -> slide~ 441 44100 -> *~ (Gain) -> snapshot~ 20 -> prepend mN amp -> outlet
                                                      \-> meter~ (presentation)
```

- **`biquad~` resonators.** Eight band-pass filters (coefficient lists of the form `1. 0. -1. a1 a2`), Q about 2 for most bands (1.9 to 2.7 by calculation). Coefficients are sent to the `biquad~` objects by messages when the tuning menu changes.
- **Envelope follower.** `abs~` then `slide~ 441 44100`: rise over 441 samples (10 ms at 44.1 kHz), fall over 44100 samples (1 s).
- **Gain.** A `number~` (presentation, default 1 on load) multiplies all eight envelopes by the same factor; its output is also what `meter~` shows.
- **Output.** `snapshot~ 20` samples each scaled envelope every 20 ms and `prepend m0amp` … `prepend m7amp` turns it into a message such as `m3amp 0.12`. All eight go to one outlet.

An outlet with the comment `m0amp-m7amp` also exists in the patch but nothing is wired to it; the wired outlet has no comment.

## Tuning modes

Two coefficient sets exist, **Log** and **Bessel**. The eight `biquad~` objects are typed with the **Log** coefficients, so Log is what runs unless a Bessel list reaches them. The switch is wired as: `live.text` (`tuning_mode`, two states, initial 0; only the label "Log" is saved) → `umenu` (items Log, Bessel) → `[select 0 1]` → one message box per band per set → `unpack` → the five coefficient inlets of that band's `biquad~`.

**Reading the wiring (not tested in Max), the switch looks inert.** `[select 0 1]` is fed from the `umenu`'s *middle* outlet, which sends the item's text ("Log" or "Bessel"), not its index. `select` with numeric arguments does not match a symbol, so neither coefficient message fires and the filters stay on the typed Log set. The index outlet (left) would work. The `loadbang` also sends `1.` to the `umenu`, so on load the menu displays **Bessel** while the filters still run Log. If this is right, the Bessel set is unreachable and the on-screen tuning can disagree with the sound.

Centre frequencies, computed from the shipped coefficients at **44.1 kHz** and rounded:

| Band | Log (Hz) | Bessel (Hz) |
|---|---|---|
| m0 | 77 | 213 |
| m1 | 150 | 339 |
| m2 | 289 | 455 |
| m3 | 558 | 565 |
| m4 | 1077 | 672 |
| m5 | 2082 | 777 |
| m6 | 4040 | 880 |
| m7 | 7913 | 982 |

**Log** spaces the bands roughly one octave apart, from the low register to the top of the audible band. **Bessel** spaces them roughly evenly (about 100–125 Hz apart) in a narrow range (213–982 Hz). The coefficients are fixed numbers, so the centre frequencies scale with the audio sample rate: at 48 kHz every band sits about 9% higher.

---

## Parameters

| Name | Control | Default | Description |
|---|---|---|---|
| `tuning_mode` | `live.text` (Log / Bessel) | Log (initial 0; the `biquad~` objects are typed with Log coefficients) | Intended to pick the coefficient set; see the wiring finding above, which suggests it currently changes nothing |
| Gain | `number~` | 1.0 | Scales all eight band envelopes before they are metered and sent |

There are no dials per band and no `bypass`.

## Outlets

| Outlet | Content |
|---|---|
| 1 (wired) | `m0amp <float>` … `m7amp <float>`, one message each every 20 ms |

The levels are unnormalized envelope values, so they scale with the input level and the Gain control.

---

## Notes

- **Spectral starvation (known, unfixed).** Amplitude-based band-pass analysis means `m0` and `m1` saturate before `m6` and `m7` see any signal on normal audio, because real material has far more low-frequency energy. The proposed fix is to normalize each frame so the bands reflect spectral shape, not level: divide each band's envelope by the total power (or the loudest band) before output. Alternatives are peak-normalizing or driving from per-band rate of change (spectral flux, so transients become the signal). The normalization would go after the `slide~` envelopes and before the `*~` gain stage (`ideas/scratchpad.md`).
- **Not a sound source.** Nothing is sent to an audio outlet.

## Known issues / open

- **Mismatch with `f_chladni`** (above): the module emits a contract the target no longer implements. Options are to build the planned `note` / `amp` companion (`sigmund~` or a pitch follower → `note`; `peakamp~` → `slide~` → `amp`; master gain) as a replacement, or to keep this patch as an eight-band analyzer and give it a different name and purpose.
- **Tuning switch probably inert** (wiring finding above): fix by taking `select` from the `umenu`'s left (index) outlet, then check in Max that Bessel loads and that the menu and the sound agree after load.
- **Unverified (T140):** whether the bands track a mic or instrument has not been checked, and T140's wording (note and amp tracking) refers to the planned patch, not this one.
- **Wording elsewhere was corrected 2026-10-22:** the README row, `f_chladni.md` (Companion Patches, Loose Threads, References), `.specify/f_chladni/tasks.md` and `.specify/plan.md` described the planned `sigmund~` / `peakamp~` patch as if it shipped, and now describe this one. Only the planned `note` / `amp` patch (T123) is still a different, unbuilt thing.
- **Integration (tabled 2026-10-18):** one of the audio modules (with `f_a_ripple` and `f_a_decorrelate`) that is hand-built, `NOT_IN_MENU` and drift `out_of_scope`. Its build script lives outside the repo (`~/Vsynth/patterns/`). The plan's option 3 (bridge-only audio-to-control modules) starts from this patch.

## Verification

None. There is no test, no bench and no recorded listening check. The coefficient table above was calculated from the shipped biquad coefficients, and the tuning-switch finding was read from the patch's connections; neither was checked in Max.

## References

- Related: `f_chladni.md` (the target module, `note` / `amp` contract, Bessel-mode math), `f_a_decorrelate.md`, `f_a_ripple.md` (other hand-built audio modules).
- Design notes: `.specify/f_chladni/spec.md` (companion section), `ideas/scratchpad.md` (spectral normalization).

## Source Files

`package/patchers/f_chladni_audio.maxpat` (hand-built), `.specify/f_chladni/{spec,plan,tasks}.md` (T123, T140, T141), `ideas/scratchpad.md`.
