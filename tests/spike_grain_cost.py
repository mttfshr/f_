"""
spike_grain_cost.py -- diagnostic, not a regression test (.specify/f_grain/tasks.md T001).

No bench_grain.py exists yet -- f_grain predates the Tier 2 bench convention and has had no
cost testing at all. This gets a frame-cost baseline for the real codebox at HD and 4K, and
checks the open question HANDOFF already raised for f_caustic and the other Param-bypass
modules (jit-gen-codebox skill, "Native @bypass skips the shader..."): f_grain's bypass is
Param-driven (bypass_gate, not native @bypass), so the shader always runs the full per-grain
Voronoi search even when bypassed -- native bypass used to skip the shader outright for free.
This measures whether a shader-side early-out guard under bypass_gate would recover any of
that cost, using an in-memory guarded variant of the codebox built right here. That variant is
NOT written back to src/f_grain/codebox_grain.gen -- this script is measurement only; whether
to actually add the guard is a separate call for Matt once the numbers are in.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/spike_grain_cost.py
"""
import statistics
import sys
from pathlib import Path

import numpy as np

import benchclient as bc

REPO = Path(__file__).resolve().parent.parent
CODEBOX = REPO / "src" / "f_grain" / "codebox_grain.gen"
REPEATS = 3  # single measure() sample is noisy -- median of several (jit-gen-codebox skill)
CHAIN = 128

SIZES = [("HD (1920x1080)", 1080, 1920), ("4K (3840x2160)", 2160, 3840)]

GUARD_START = '// cell identities pinned to fixed_res'
GUARD_END = '// bypass (bypass_mode "param"): passthrough on every outlet (Matt, 2026-10-05).'


def code():
    return CODEBOX.open(newline="").read()


def guarded_code():
    """In-memory variant: wraps the per-grain Voronoi search (the expensive part) in an
    `if (bypass_gate > 0.5) { cheap } else { the real work }` guard, to measure what a
    shader-side early-out WOULD cost/save when bypassed. See module docstring -- not shipped."""
    text = code()
    i = text.index(GUARD_START)
    j = text.index(GUARD_END)
    body = text[i:j]
    guarded_body = (
        # composited/raw/src_displaced are pre-declared before the if, not first-assigned
        # inside either branch -- jit-gen-codebox's "variables first assigned inside a loop
        # are out of scope after it" is documented for `for` only, but play it safe.
        "composited = src; raw = src; src_displaced = src;\n"
        "if (bypass_gate > 0.5) {\n"
        "    composited = src;\n"
        "    raw = vec(1.0, 1.0, 1.0, 1.0);\n"
        "    src_displaced = src;\n"
        "} else {\n"
        + body +
        "}\n\n"
    )
    return text[:i] + guarded_body + text[j:]


def rand(h, w, seed=0):
    return np.random.default_rng(seed).uniform(0.0, 1.0, (h, w, 4)).astype(np.float32)


def measure_one(c, h, w, bypass_gate):
    samples = []
    bound = None
    for _ in range(REPEATS):
        r = bc.measure(c, [rand(h, w)], chain=CHAIN,
                        params={"bypass_gate": float(bypass_gate), "src_mode": 1.0})
        if r["status"] != "ok":
            raise RuntimeError(f"bench job failed: {r}")
        bound = r["gpu_bound"]
        samples.append(r["ms_per_pass"] if bound else r["ms_per_pass_upper_bound"])
    return statistics.median(samples), bound


def main():
    bc.require_bench()
    original = code()
    guarded = guarded_code()

    print("=== Baseline: shipped codebox, as-is ===")
    base = {}
    for label, h, w in SIZES:
        for bg in (0.0, 1.0):
            ms, bound = measure_one(original, h, w, bg)
            base[(label, bg)] = ms
            flag = "" if bound else "  (upper bound -- cheaper than CPU-overhead floor)"
            print(f"  {label:<16} bypass_gate={bg:.0f}: {ms:7.3f} ms/pass{flag}")

    print()
    print("=== Guarded variant: early-out under bypass_gate (measurement only, not shipped) ===")
    guard = {}
    for label, h, w in SIZES:
        for bg in (0.0, 1.0):
            ms, bound = measure_one(guarded, h, w, bg)
            guard[(label, bg)] = ms
            flag = "" if bound else "  (upper bound -- cheaper than CPU-overhead floor)"
            print(f"  {label:<16} bypass_gate={bg:.0f}: {ms:7.3f} ms/pass{flag}")

    print()
    print(f"{'size':<16} {'baseline bypassed':>18} {'guarded bypassed':>18} {'recovered':>10}")
    for label, _, _ in SIZES:
        b = base[(label, 1.0)]
        g = guard[(label, 1.0)]
        print(f"{label:<16} {b:>18.3f} {g:>18.3f} {b - g:>10.3f}")

    print()
    print(f"{'size':<16} {'active (bypass=0)':>18}")
    for label, _, _ in SIZES:
        print(f"{label:<16} {base[(label, 0.0)]:>18.3f}")


if __name__ == "__main__":
    sys.exit(main())
