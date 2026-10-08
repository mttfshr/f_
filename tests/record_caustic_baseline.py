"""
record_caustic_baseline.py -- task T001 of .specify/f_caustic_scatter/tasks.md.

Records the soft path of the UNMODIFIED f_caustic (package/patchers/f_caustic.maxpat) through the module bench
with fixed inputs, so the sheets-mode work can prove "soft mode unchanged" (spec, Acceptance criteria 1; task T027).

Inputs: the gradient source and the deterministic test glass (tests/scatter_truth.py), 512 x 512 (the soft
module hardcodes h = 1/512). Five parameter sets (every route token is sent every job: the bench keeps a Param's
last value between jobs). Per set and outlet we store the sha256 of the float32 bytes (the exact identity check),
a 128 x 128 block-mean copy (a diagnostic when the hashes differ) and the plain statistics. Set B is run twice:
if the two runs hash differently the GPU is not bit-deterministic and identity must be checked by tolerance, not
by hash; that is recorded too.

Needs the module bench (Max) and no Vsynth patch open.
Run:  tests/bench.sh tests/record_caustic_baseline.py      (or: uv run --no-project --with numpy python3 ...)
Writes tests/baselines/f_caustic_soft.npz
"""
import hashlib
import json
import sys
import time
from pathlib import Path

import numpy as np

import caustic_runner as cr
import scatter_mirror as sm
import scatter_truth as st

HERE = Path(__file__).resolve().parent
OUT = HERE / "baselines" / "f_caustic_soft.npz"
MODULE = "f_caustic.maxpat"
PATCHER = HERE.parent / "package" / "patchers" / "f_caustic.maxpat"

# (mix_pct, gain, scale, softness, color_shift): the shipped defaults first (mix 0 = a passthrough composite,
# the layer outlet still shows the caustic), then four non-default sets that exercise every parameter.
SETS = {
    "A_defaults":  (0.0, 0.5, 0.3, 0.3, 0.0),
    "B_wet":       (100.0, 0.5, 0.3, 0.3, 0.0),
    "C_sharp":     (100.0, 1.0, 0.6, 0.0, 0.0),
    "D_diffuse":   (60.0, 0.8, 0.2, 1.0, 0.5),
    "E_strong":    (100.0, 2.0, 1.0, 0.3, 0.3),
}
TOKENS = ("mix_pct", "gain", "scale", "softness", "color_shift")


def settings_of(values):
    """One message-box string: each control message is sent into the module's inlet 0 by the wrapper's loadbang."""
    return ", ".join(f"{t} {float(v):g}" for t, v in zip(TOKENS, values))


def sha(a):
    return hashlib.sha256(np.ascontiguousarray(a, dtype=np.float32).tobytes()).hexdigest()


def block_down(a, n=128):
    h = a.shape[0]
    f = h // n
    return a.reshape(n, f, n, f, a.shape[2]).mean(axis=(1, 3)).astype(np.float32)


def capture(src, fld, values):
    result, out = cr.run([src, fld], [], MODULE, n_out=2, settings=settings_of(values), warmup=60)
    errs = cr.report(result, "baseline job")
    arrs = out.get("base")                      # captured after the wrapper applied the settings (not 'bypassed')
    if not arrs or 1 not in arrs or 2 not in arrs:
        raise RuntimeError(f"captures missing: {sorted(arrs) if arrs else None} (errors {errs[:2]})")
    return arrs[1], arrs[2], errs


def main():
    cr.ensure_bench()
    src, fld = sm.gradient_src(512), st.field_texture()
    first_b = None
    data, meta = {}, {"module": str(PATCHER.relative_to(HERE.parent)),
                      "module_md5": hashlib.md5(PATCHER.read_bytes()).hexdigest(),
                      "recorded": time.strftime("%Y-%m-%d %H:%M:%S"), "sets": {}, "inputs": "gradient_src(512), field_texture()"}
    for name, values in SETS.items():
        print(f"\n== {name}: {dict(zip(TOKENS, values))}")
        comp, layer, errs = capture(src, fld, values)
        if name == "B_wet":
            first_b = (comp, layer)
        meta["sets"][name] = {"values": dict(zip(TOKENS, values)), "errors": len(errs)}
        for k, a in ((1, comp), (2, layer)):
            data[f"{name}_out{k}_sha"] = np.array(sha(a))
            data[f"{name}_out{k}_128"] = block_down(a)
            print(f"   outlet {k}: shape {a.shape}, mean RGB {a[..., :3].reshape(-1, 3).mean(0).round(4)}, "
                  f"max {a[..., :3].max():.4f}, sha {sha(a)[:12]}")
    layer_hashes = {str(data[f"{n}_out2_sha"]) for n in SETS}
    if len(layer_hashes) < 2:
        raise RuntimeError("every parameter set produced the same layer outlet: the settings never reached the "
                           "module (or the wrong capture was read); refusing to record this as a baseline")
    print(f"\nsanity: {len(layer_hashes)} distinct layer outputs across {len(SETS)} parameter sets")
    print("\n== determinism: set B again")
    comp2, layer2, _ = capture(src, fld, SETS["B_wet"])
    same = (sha(comp2) == str(data["B_wet_out1_sha"]), sha(layer2) == str(data["B_wet_out2_sha"]))
    meta["deterministic_B"] = bool(all(same))
    print(f"   identical hashes on a repeat run: composite {same[0]}, layer {same[1]}")
    if not all(same):
        d1 = max(np.abs(comp2.astype(np.float64) - first_b[0]).max(), np.abs(layer2.astype(np.float64) - first_b[1]).max())
        meta["repeat_max_abs_diff_B"] = float(d1)
        print(f"   (not bit-deterministic here: max |diff| between the two runs {d1:.3e}; check identity by tolerance)")
    data["meta"] = np.array(json.dumps(meta))
    OUT.parent.mkdir(exist_ok=True)
    np.savez_compressed(OUT, **data)
    print(f"\nwrote {OUT} ({OUT.stat().st_size / 1e6:.2f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
