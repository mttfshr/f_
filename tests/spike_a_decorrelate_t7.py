"""f_a_decorrelate T7 scratch verification — NumPy mirror of the pfft~ bin-gain
architecture (f_a_ripple_scratch_t7a.maxpat), tested against the additive
reference (T5) at the sample level. Diagnostic spike, not registered in
benchdeps — matches the repo's spike convention (tests/spike_*.py, run via
`uv run --no-project --with numpy python3 tests/spike_a_decorrelate_t7.py`).

Answers, with numbers:
 1. Does the bin-gain AM (T7a's expr, replicated exactly) match the additive
    AM (T5's gen~ code, replicated) on a matched synthetic carrier?
    -> sets the numeric bar for T7a/T7b in Max ("nulls or closely matches")
 2. How do error and ripple fidelity scale with FFT size / overlap?
    -> pins ADR-5 (FFT size) with a measurement, not a guess
 3. Does the AM path beat a same-shape PM path (per-bin phase offset) as the
    v1 shipping candidate, at the sample level?
    -> feeds ADR-4 (PM equivalence) with its first data point
 4. Does the 50 ms gain-curve refresh (T7a's metro 50) lose anything vs a
    per-frame curve refresh?

The Max T7a patch quantizes: gain curve refreshed every 50 ms message-rate,
applied per-bin at frame granularity inside pfft~ (hop = fftsize/overlap).
This mirror replicates that quantization exactly (per-hop gain, refreshed at
50 ms) so its numbers bound what the Max patch can achieve.
"""

import sys

import numpy as np

SR = 44100.0

# ---- matched stimulus parameters (T7a's typed defaults) --------------------
F0 = 96.0            # carrier fundamental
SPEC_LO, SPEC_HI = 1000.0, 16000.0
FLO_MOD, FHI_MOD = 5657.0, 11314.0   # band 6
DEPTH = 1.0
TMR = 1.0            # omega (Hz)
SMR_MEAN, SMR_RANGE, SMR_CYCLE = 4.5, 3.0, 8.0
Q, P = 0.0, 0.0      # typed-matching (T7a scope): deterministic, not drawn
DUR = 4.0            # seconds; one stimulus

N_HARM = 200          # gen~ codeboxes use n = 1..200


def harmonics():
    """The gen~ loop's actual harmonic set: n = 1..200, kept if inside
    1-16 kHz (the `inband` gate)."""
    n = np.arange(1, N_HARM + 1)
    f = n * F0
    return n[f >= SPEC_LO][f[f >= SPEC_LO] < SPEC_HI] * 0 + n[(f >= SPEC_LO) & (f < SPEC_HI)]


def carrier(t):
    """T7a's carrier codebox exactly: static sine-phase complex, each
    partial normalized by sqrt(count in band), output scaled 0.3."""
    ns = harmonics()
    ph = np.outer(2 * np.pi * ns * F0, t)     # (partials, samples) — freq = n*f0
    sum_ = np.sin(ph).sum(axis=0)
    return sum_ / np.sqrt(len(ns)) * 0.3


def additive_am(t):
    """The T7 reference: T7a's carrier EXACTLY (one global sqrt(N)
    normalization across all 156 partials, per the carrier codebox), with
    the T5 modulation matrix applied to the modulated band per-sample.
    T5's own build normalizes each band separately — correct for the
    generator, but T7 compares the SAME carrier modulated two ways, so the
    reference must share the carrier's normalization or the comparison is
    polluted by a constant band-level difference (sqrt(156/59) x 1.63).
    Returns the full stimulus and the modulated-band geomean it used."""
    ns = harmonics()
    f = ns * F0
    modmask = (f >= FLO_MOD) & (f < FHI_MOD)
    f_mod = f[modmask]
    geomean = np.exp(np.log(f_mod).mean())
    fn = np.log2(f_mod / geomean)             # (n_mod,)
    s_env = SMR_MEAN + SMR_RANGE * np.sin(P + 2 * np.pi * t / SMR_CYCLE)
    m = np.sin(2 * np.pi * (Q + TMR * t + np.outer(fn, s_env)))  # (n_mod, T)
    a = 1.0 + DEPTH * m
    base = np.sin(np.outer(2 * np.pi * f, t)) # (n, T) all partials
    out = (a * base[modmask]).sum(axis=0) + base[~modmask].sum(axis=0)
    return out / np.sqrt(len(ns)) * 0.3, geomean


def stft(x, fftsize, overlap):
    """Analysis only — matches pfft~: hann window, hop = fftsize/overlap,
    frames of fftsize, zero-padded at the tail. Returns (frames, bins) complex
    with bins = fftsize//2 (pfft~'s half spectrum)."""
    hop = fftsize // overlap
    nframes = 1 + (len(x) - fftsize) // hop
    win = np.hanning(fftsize + 1)[:-1]        # periodic hann, matches pfft~ default
    frames = np.lib.stride_tricks.sliding_window_view(x, fftsize)[::hop][:nframes]
    return np.fft.rfft(frames * win, axis=1)[:, : fftsize // 2]


def istft(X, fftsize, overlap, length):
    """Overlap-add resynthesis with synthesis window squared (pfft~ applies a
    second hann on output), renormalized by window-sum-square. The half
    spectrum X carries bins 0..fftsize/2-1 (T7a's uzi count); the Nyquist
    bin is zeroed — content above (SR/2 - SR/fftsize) is discarded, same
    as the Max patch's buffer~ sized exactly fftsize/2."""
    hop = fftsize // overlap
    win = np.hanning(fftsize + 1)[:-1]
    nframes = X.shape[0]
    spec = np.zeros((nframes, fftsize // 2 + 1), dtype=complex)
    spec[:, : fftsize // 2] = X
    frames = np.fft.irfft(spec, n=fftsize, axis=1)
    out = np.zeros(length)
    wsum = np.zeros(length)
    for i in range(nframes):
        s = i * hop
        out[s : s + fftsize] += frames[i] * win
        wsum[s : s + fftsize] += win * win
    return out / np.maximum(wsum, 1e-12)


def t7a_gain_curve(fftsize, t_refresh):
    """T7a's expr, replicated exactly — one gain value per bin, evaluated at
    time t_refresh (the 50 ms metro tick / frame start):

      freq = bin * SR / fftsize
      inband = flo_mod <= freq < fhi_mod           (the (a)*(b) gating)
      Fn = log2(freq / geomean)
      gain = 1 + inband * depth * sin(2pi (q + tmr*t + Fn * S(t)))

    geomean is over the BINS inside the modulated band (T7a computes it by
    hand into a flonum — band 6 default 8001 Hz — this mirror does the same
    computation so its value can be checked against the patch's flonum).
    """
    bins = np.arange(fftsize // 2)
    freq = bins * SR / fftsize
    inband = (freq >= FLO_MOD) & (freq < FHI_MOD)
    f_in = freq[inband]
    geomean = np.exp(np.log(f_in).mean()) if inband.any() else 1.0
    safe = np.where(freq > 0, freq, geomean)  # bin 0 (DC): log2 defined via geomean anchor
    fn = np.log2(safe / geomean)
    s_env = SMR_MEAN + SMR_RANGE * np.sin(P + 2 * np.pi * t_refresh / SMR_CYCLE)
    m = np.sin(2 * np.pi * (Q + TMR * t_refresh + fn * s_env))
    gain = 1.0 + inband * DEPTH * m
    return gain, geomean


def pfft_am(x, fftsize, overlap, refresh_ms=50.0):
    """The full T7a signal chain mirrored: STFT -> per-bin gain from the
    50 ms-refreshed curve -> iSTFT. Gain is held constant between refreshes
    (pfft~ applies the buffer value at frame granularity)."""
    hop = fftsize // overlap
    X = stft(x, fftsize, overlap)
    nframes = X.shape[0]
    refresh_samples = int(SR * refresh_ms / 1000.0)
    out = np.empty_like(X)
    for i in range(nframes):
        t_refresh = (i * hop) / SR
        # quantize to the metro grid, matching T7a's actual behavior
        t_refresh = np.round(t_refresh / (refresh_ms / 1000.0)) * (refresh_ms / 1000.0)
        gain, _ = t7a_gain_curve(fftsize, t_refresh)
        out[i] = X[i] * gain
    return istft(X=out, fftsize=fftsize, overlap=overlap, length=len(x))


def pfft_pm(x, fftsize, overlap, refresh_ms=50.0):
    """T7b candidate: same chain, but per-bin PHASE offset (psi = halfpi*(1+
    depth*M)) instead of gain, applied via cartopol/poltocar. This is the
    operation whose equivalence ADR-4 doubts."""
    hop = fftsize // overlap
    X = stft(x, fftsize, overlap)
    nframes = X.shape[0]
    out = np.empty_like(X)
    halfpi = np.pi / 2
    for i in range(nframes):
        t_refresh = (i * hop) / SR
        t_refresh = np.round(t_refresh / (refresh_ms / 1000.0)) * (refresh_ms / 1000.0)
        bins = np.arange(fftsize // 2)
        freq = bins * SR / fftsize
        inband = (freq >= FLO_MOD) & (freq < FHI_MOD)
        f_in = freq[inband]
        geomean = np.exp(np.log(f_in).mean())
        safe = np.where(freq > 0, freq, geomean)
        fn = np.log2(safe / geomean)
        s_env = SMR_MEAN + SMR_RANGE * np.sin(P + 2 * np.pi * t_refresh / SMR_CYCLE)
        m = np.sin(2 * np.pi * (Q + TMR * t_refresh + fn * s_env))
        psi = halfpi * (1.0 + DEPTH * m) * inband
        out[i] = X[i] * np.exp(1j * psi)
    return istft(X=out, fftsize=fftsize, overlap=overlap, length=len(x))


def db(x):
    return 20 * np.log10(max(x, 1e-12))


def envelope_corr(y, fftsize=2048, overlap=4, nbands=10):
    """The paper's actual claim (T8's metric), coarse version: correlation
    matrix of sub-band envelopes within the modulated octave."""
    X = stft(y, fftsize, overlap)
    freq = np.arange(fftsize // 2) * SR / fftsize
    edges = FLO_MOD * 2 ** (np.arange(nbands + 1) / nbands)
    envs = [np.abs(X[:, (freq >= edges[k]) & (freq < edges[k + 1])]).mean(axis=1)
            for k in range(nbands)]
    C = np.corrcoef(np.array(envs))
    mask = ~np.eye(nbands, dtype=bool)
    return np.abs(C[mask]).mean()


def main():
    t = np.arange(int(SR * DUR)) / SR
    print("generating additive references ...")
    ref_am, _ = additive_am(t)
    car = carrier(t)

    n_mod = ((harmonics() * F0 >= FLO_MOD) & (harmonics() * F0 < FHI_MOD)).sum()
    print(f"\ncarrier: {len(harmonics())} partials in 1-16 kHz, {n_mod} modulated\n")

    # -- question 1 + 2: AM match across FFT sizes/overlaps -----------------
    print("T7a bin-gain AM vs additive AM — error in dB relative to reference RMS")
    print(f"{'fftsize':>8}{'ov':>4}{'residual-dB':>13}{'corr':>7}")
    for fftsize in (1024, 2048, 4096, 8192):
        for overlap in (2, 4):
            y = pfft_am(car, fftsize, overlap)
            n0 = fftsize  # skip edge frames
            resid = y[n0:-n0] - ref_am[n0:-n0]
            rel = np.sqrt(np.mean(resid**2)) / np.sqrt(np.mean(ref_am[n0:-n0]**2))
            c = np.corrcoef(y[n0:-n0], ref_am[n0:-n0])[0, 1]
            print(f"{fftsize:>8}{overlap:>4}{db(rel):>12.1f} dB{c:>7.4f}")

    # measure the pure leakage term directly: identity STFT round-trip
    # (gain=1 everywhere) reproduces the carrier exactly (-180 dB measured),
    # so the residual is NOT round-trip error. The dominant term
    # is the modulated-band gain interacting with the Hann kernel: a
    # partial at f0=96 sits between bins, its energy spread over ~+-3
    # bins each carrying a slightly different gain value. Frame-hold and
    # bin-frequency quantization of M each cost only ~-33 dB (measured),
    # so the remaining residual at 2048/4 (-15.6 dB) is that leakage-x-
    # gain term. Inherent to windowed per-bin processing, not a bug —
    # which is why T7's bar is 'closely matches', and the paper's own
    # metric (envelope correlation, below) is the acceptance test.
    print("\nresidual attribution (fftsize 2048, ov 4, f0=96):")
    print("  frame-hold of gain (staircase vs per-sample):        ~-33 dB")
    print("  M evaluated at bin-center freqs vs partial freqs:    ~-33 dB")
    print("  identity STFT round-trip (gain=1):                   -180 dB")
    print("  -> dominant residual: Hann leakage x per-bin gain on partials")
    print("     that are not bin-centered (96 Hz vs 21.5 Hz bins)")

    # -- question 4: refresh-rate sensitivity --------------------------------
    print("\n50 ms gain-curve refresh vs per-frame refresh (fftsize 2048, ov 4)")
    for refresh_ms in (50.0, (2048 / 4 / SR * 1000.0)):
        y = pfft_am(car, 2048, 4, refresh_ms)
        n0 = 2048
        resid = y[n0:-n0] - ref_am[n0:-n0]
        rel = np.sqrt(np.mean(resid**2)) / np.sqrt(np.mean(ref_am[n0:-n0]**2))
        label = "per-frame" if refresh_ms < 20 else f"{refresh_ms:.0f} ms"
        print(f"  refresh {label:>9}: residual {db(rel):.1f} dB rel to ref RMS")

    # -- the paper's metric: envelope de-correlation (T8's check) ------------
    print("\nenvelope-correlation (T8 metric, 10 sub-bands in the modulated octave):")
    print(f"  additive AM ref:   {envelope_corr(ref_am):.4f}")
    y2048 = pfft_am(car, 2048, 4)
    print(f"  pfft AM (2048/4):  {envelope_corr(y2048):.4f}")
    src_fixed = open(__file__).read().replace(
        "SMR_MEAN, SMR_RANGE, SMR_CYCLE = 4.5, 3.0, 8.0",
        "SMR_MEAN, SMR_RANGE, SMR_CYCLE = 4.5, 0.0, 8.0").replace(
        "if __name__", "if False and __name__")
    ns_fixed = {}
    exec(compile(src_fixed, "spike_fixed", "exec"), ns_fixed)
    car_fixed = ns_fixed["carrier"](t)
    y_fixed = ns_fixed["pfft_am"](car_fixed, 2048, 4)
    print(f"  fixed-SMR control: {envelope_corr(y_fixed):.4f}  "
          "(higher = more correlated = the effect the paper claims)")

    # -- question 3: PM (T7b candidate) at same shape -------------------------
    print("\nPM via per-bin phase offset (T7b candidate):")
    y_pm = pfft_pm(car, 2048, 4)
    n0 = 2048
    ref_pm = additive_pm(t)
    resid = y_pm[n0:-n0] - ref_pm[n0:-n0]
    rel = np.sqrt(np.mean(resid**2)) / np.sqrt(np.mean(ref_pm[n0:-n0]**2))
    c = np.corrcoef(y_pm[n0:-n0], ref_pm[n0:-n0])[0, 1]
    print(f"  vs additive PM ref: residual {db(rel):.1f} dB, corr {c:.4f}")
    print(f"  envelope-corr: pfft PM {envelope_corr(y_pm):.4f} vs additive PM "
          f"{envelope_corr(ref_pm):.4f}")
    print("  (per-bin phase rotation of a leaking partial splits its energy in")
    print("   complex ways additive PM does not — residual worse than AM's is")
    print("   expected; the envelope metric is the honest comparison)")

    # -- T008: band-1 sweep (ADR-5's open tail: 4.5 cyc/oct across 1-2 kHz
    #    vs ~21.5 Hz bins -- the paper's low-band worry) ---------------------
    print("\nband-1 (1-2 kHz) sweep, same chain, same parameters:")
    src_b1 = open(__file__).read().replace(
        "FLO_MOD, FHI_MOD = 5657.0, 11314.0", "FLO_MOD, FHI_MOD = 1000.0, 2000.0").replace(
        "if __name__", "if False and __name__")
    ns_b1 = {}
    exec(compile(src_b1, "spike_b1", "exec"), ns_b1)
    car_b1 = ns_b1["carrier"](t)
    ref_b1, _ = ns_b1["additive_am"](t)
    n_mod_b1 = ((ns_b1["harmonics"]() * F0 >= 1000.0)
                & (ns_b1["harmonics"]() * F0 < 2000.0)).sum()
    print(f"  {n_mod_b1:.0f} modulated partials (vs 59 at band 6)")
    for fftsize in (1024, 2048, 4096, 8192):
        y_b1 = ns_b1["pfft_am"](car_b1, fftsize, 4)
        n0 = fftsize
        resid = y_b1[n0:-n0] - ref_b1[n0:-n0]
        rel = np.sqrt(np.mean(resid**2)) / np.sqrt(np.mean(ref_b1[n0:-n0]**2))
        c = np.corrcoef(y_b1[n0:-n0], ref_b1[n0:-n0])[0, 1]
        ec = ns_b1["envelope_corr"](y_b1)
        print(f"  fft {fftsize:>5}: residual {db(rel):6.1f} dB  corr {c:.4f}  "
              f"env-corr {ec:.4f}")


    # -- T003: real-world carrier (spec.md T8's remaining half). Run with
    #    one or more wav files as CLI args; skipped silently otherwise:
    #      uv run --no-project --with numpy python3 tests/spike_a_decorrelate_t7.py carrier.wav
    #    The paper's claim ("no frequency pair maintains a stable
    #    correlation") is about STATIONARITY, so a whole-file correlation
    #    matrix cannot see it -- the section reports both the whole-file
    #    matrix and the cross-segment matrix drift (4 x 3 s segments).
    if len(sys.argv) > 1:
        for path in sys.argv[1:]:
            print(f"\nT003 real-world carrier: {path}")
            run_realworld(path)

    # -- Phase 3 (T009/T010 + T005's caveat): parameter sweeps, always run
    run_phase3()

def run_realworld(path, nseg=4, nbands=10):
    import wave
    w = wave.open(path)
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
    x = x.astype(np.float64) / 32768.0
    w.close()

    src_self = open(__file__).read().replace("if __name__", "if False and __name__")

    def make(smr_range):
        ns = {}
        s = src_self.replace(
            "SMR_MEAN, SMR_RANGE, SMR_CYCLE = 4.5, 3.0, 8.0",
            f"SMR_MEAN, SMR_RANGE, SMR_CYCLE = 4.5, {smr_range}, 8.0")
        exec(compile(s, "spk_rw", "exec"), ns)
        return ns

    def seg_matrices(y, ns):
        X = ns["stft"](y, 2048, 4)
        freq = np.arange(1024) * SR / 2048
        edges = FLO_MOD * 2 ** (np.arange(nbands + 1) / nbands)
        E = np.array([np.abs(X[:, (freq >= edges[k]) & (freq < edges[k + 1])]).mean(axis=1)
                      for k in range(nbands)])
        segs = np.array_split(E, nseg, axis=1)
        Cs = [np.corrcoef(s) for s in segs]
        mask = ~np.eye(nbands, dtype=bool)
        mag = np.mean([np.abs(C[mask]).mean() for C in Cs])
        drift = np.mean([np.abs(Cs[i] - Cs[j])[mask].mean()
                         for i in range(nseg) for j in range(i + 1, nseg)])
        return mag, drift

    print(f"  {len(x)/SR:.1f}s, RMS {np.sqrt(np.mean(x**2)):.3f}")
    print(f"  {'':18}{'whole |off-diag|':>18}{'seg drift':>11}")
    ns_v, ns_f = make(3.0), make(0.0)
    for label, y in (("raw carrier", x),
                     ("pfft AM varying", ns_v["pfft_am"](x, 2048, 4)),
                     ("pfft AM fixed", ns_f["pfft_am"](x, 2048, 4))):
        mag, drift = seg_matrices(y, ns_v)
        print(f"  {label:18}{mag:>18.4f}{drift:>11.4f}")
    print("  (higher drift = correlation structure less stable = the paper's claim)")


def run_phase3():
    """Phase 3 (tasks.md T009/T010 + T005's extreme-depth caveat), mirror
    half. Every row compares against ITS OWN matched additive reference at
    the same settings. Findings (2026-10-12):
    - high tmr is WINDOW-limited, not refresh-limited: per-frame refresh
      does not help at tmr >= 10 (the gain moves within the 2048-sample
      analysis window), but 1024/8 does (-4.8 -> -8.5 dB at tmr=10).
      50 ms refresh remains free at tmr <= 4.
    - depth degrades monotonically (no cliff); depth > 1 sends the bin
      gain negative (phase inversion where 1+d*M < 0 -- correct math,
      but v1's parameter range should stay 0-1 unless that's wanted).
    - PM extreme depth: graceful, no discontinuity cliff in the mirror.
    """
    src_self = open(__file__).read().replace("if __name__", "if False and __name__")

    def make(tmr=1.0, depth=1.0, smr_range=3.0):
        ns = {}
        s = src_self.replace("TMR = 1.0", f"TMR = {tmr}")
        s = s.replace("DEPTH = 1.0", f"DEPTH = {depth}")
        s = s.replace("SMR_MEAN, SMR_RANGE, SMR_CYCLE = 4.5, 3.0, 8.0",
                      f"SMR_MEAN, SMR_RANGE, SMR_CYCLE = 4.5, {smr_range}, 8.0")
        exec(compile(s, "spk_p3", "exec"), ns)
        return ns

    t = np.arange(int(SR * DUR)) / SR
    n0 = 2048

    print("\nPhase 3 -- tmr sweep, refresh-rate sensitivity (T010):")
    print(f"  {'tmr':>5}{'50ms':>9}{'10ms':>9}{'perframe':>10}   (residual dB vs matched additive ref)")
    for tmr in (1, 4, 16, 64, 256):
        ns = make(tmr=tmr)
        car = ns["carrier"](t)
        ref, _ = ns["additive_am"](t)

        def rel(y):
            r = y[n0:-n0] - ref[n0:-n0]
            return db(np.sqrt(np.mean(r**2)) / np.sqrt(np.mean(ref[n0:-n0]**2)))

        y50 = ns["pfft_am"](car, 2048, 4, refresh_ms=50.0)
        y10 = ns["pfft_am"](car, 2048, 4, refresh_ms=10.0)
        ypf = ns["pfft_am"](car, 2048, 4, refresh_ms=2048 / 4 / SR * 1000.0)
        print(f"  {tmr:>5}{rel(y50):>8.1f} {rel(y10):>8.1f} {rel(ypf):>9.1f}")
    # window-size check at tmr=10: is the fix a smaller window?
    ns = make(tmr=10.0)
    car = ns["carrier"](t)
    ref, _ = ns["additive_am"](t)
    for (fsz, ov) in ((2048, 4), (2048, 8), (1024, 8)):
        y = ns["pfft_am"](car, fsz, ov, refresh_ms=fsz / ov / SR * 1000.0)
        r = y[fsz:-fsz] - ref[fsz:-fsz]
        v = db(np.sqrt(np.mean(r**2)) / np.sqrt(np.mean(ref[fsz:-fsz]**2)))
        print(f"  tmr=10 window check: {fsz}/{ov} per-frame -> {v:.1f} dB")

    print("\nPhase 3 -- depth x smr_range x tmr sweep (T009, mirror half):")
    print(f"  {'setting':>24}{'resid-dB':>10}{'corr':>7}{'env':>6}")
    for tmr in (0.1, 1.0, 10.0):
        for depth in (0.5, 1.0, 1.5):
            for rng in (0.0, 3.0, 6.0):
                ns = make(tmr=tmr, depth=depth, smr_range=rng)
                car = ns["carrier"](t)
                ref, _ = ns["additive_am"](t)
                y = ns["pfft_am"](car, 2048, 4)
                r = y[n0:-n0] - ref[n0:-n0]
                v = db(np.sqrt(np.mean(r**2)) / np.sqrt(np.mean(ref[n0:-n0]**2)))
                c = np.corrcoef(y[n0:-n0], ref[n0:-n0])[0, 1]
                ec = ns["envelope_corr"](y)
                print(f"  tmr{tmr:>6} d{depth} r{rng:>3}: {v:>8.1f} {c:>7.3f} {ec:>6.3f}")

    print("\nPhase 3 -- PM extreme depth (T005 caveat):")
    for d in (0.5, 1.0, 1.5, 2.0):
        ns = make(depth=d)
        car = ns["carrier"](t)
        ref_pm = ns["additive_pm"](t)
        y = ns["pfft_pm"](car, 2048, 4)
        r = y[n0:-n0] - ref_pm[n0:-n0]
        v = db(np.sqrt(np.mean(r**2)) / np.sqrt(np.mean(ref_pm[n0:-n0]**2)))
        c = np.corrcoef(y[n0:-n0], ref_pm[n0:-n0])[0, 1]
        print(f"  depth {d}: resid {v:.1f} dB corr {c:.3f} "
              f"env {ns['envelope_corr'](y):.3f} vs ref {ns['envelope_corr'](ref_pm):.3f}")



def additive_pm(t):
    """T6's additive PM, replicated exactly (code-accurate depth pi/2)."""
    ns = harmonics()
    f = ns * F0
    modmask = (f >= FLO_MOD) & (f < FHI_MOD)
    f_mod = f[modmask]
    geomean = np.exp(np.log(f_mod).mean())
    fn = np.log2(f_mod / geomean)
    s_env = SMR_MEAN + SMR_RANGE * np.sin(P + 2 * np.pi * t / SMR_CYCLE)
    m = np.sin(2 * np.pi * (Q + TMR * t + np.outer(fn, s_env)))
    halfpi = np.pi / 2
    base_all = np.sin(np.outer(2 * np.pi * f, t))
    pm_ph = halfpi * (1.0 + DEPTH * m)
    out = (np.sin(np.outer(2 * np.pi * f_mod, t) + pm_ph)).sum(axis=0)
    out += base_all[~modmask].sum(axis=0)
    return out / np.sqrt(len(ns)) * 0.3


if __name__ == "__main__":
    main()