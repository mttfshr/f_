"""
spike_caustic_res_cost.py -- diagnostic, not a regression test (.specify/f_caustic_scatter/tasks.md T046).

bench_caustic_sheets.py's period_ms numbers for the `detail` ladder (test_T021) are flat across all five steps
(~16-17 ms) because the module bench's frame period is vsync-locked at 60 fps (cr.CAP_MS = 16.7 ms): a pass
cheaper than that is invisible to it, and at the bench's usual 512^2 source size every detail step is. Matt's
live-performance read (2026-10-08) was the opposite: `detail` barely moves frame rate, the Vsynth *output*
resolution clearly does.

The composite (`codebox_sheets.gen`) and both select stages run `@adapt 1` -- sized to the SOURCE texture, not a
fixed capture -- so pushing the source size up past the vsync floor should surface real numbers with no new Max
patches: cr.period_ms already takes arbitrary-size source arrays. This sweeps detail {1, 5} across source sizes
{512^2 (today's bench baseline), 1920x1080, 3840x2160} through the REAL module (f_caustic.maxpat, sheets mode),
same inputs/params shape as test_T035.

Needs Max with tests/bench/bench_module.maxpat open and every Vsynth performance patch CLOSED.
Run:  tests/bench.sh tests/spike_caustic_res_cost.py
"""
import statistics
import sys
from pathlib import Path

import caustic_runner as cr
import scatter_mirror as sm
import scatter_truth as st
from bench_caustic_sheets import MODULE, gradient_wide

SIZES = [("512^2 (bench baseline)", sm.gradient_src(512)),
          ("1920x1080 (HD)", gradient_wide(1920, 1080)),
          ("3840x2160 (4K)", gradient_wide(3840, 2160))]
DETAILS = [1, 5]
REPEATS = 3           # single-sample period_ms is known to vary up to ~2x run to run (optics_map.md, spike S6)


def main():
    cr.ensure_bench()
    tex, dstar = st.field_texture(), st.first_fold_distance()
    rows = []
    for label, src in SIZES:
        for detail in DETAILS:
            params = [["scale", dstar], ["gain", 0.5], ["mix_pct", 100.0], ["mode", 1], ["detail", detail]]
            samples = [cr.period_ms([src, tex], params, MODULE, n_out=2) for _ in range(REPEATS)]
            med = statistics.median(samples)
            rows.append((label, detail, med))
            s = "  ".join(f"{v:6.2f}" for v in samples)
            print(f"  {label:<24} detail {detail}: median {med:7.2f} ms  (cap {cr.CAP_MS:.1f})  samples [{s}]")
    print()
    print(f"{'size':<24} {'detail 1':>10} {'detail 5':>10} {'delta (detail)':>16}")
    for label, _ in SIZES:
        a = next(ms for l, d, ms in rows if l == label and d == 1)
        b = next(ms for l, d, ms in rows if l == label and d == 5)
        print(f"{label:<24} {a:>10.2f} {b:>10.2f} {b - a:>16.2f}")
    base = next(ms for l, d, ms in rows if l.startswith("512") and d == 5)
    hd = next(ms for l, d, ms in rows if l.startswith("1920") and d == 5)
    uhd = next(ms for l, d, ms in rows if l.startswith("3840") and d == 5)
    print()
    print(f"size delta at detail 5 (median of {REPEATS}): 512->HD {hd - base:+.2f} ms, HD->4K {uhd - hd:+.2f} ms")


if __name__ == "__main__":
    sys.exit(main())
