#!/bin/bash
# Run bench tests (tests/bench_*.py) against the live Max test bench.
# Needs Max running. tests/bench/bench.maxpat must be open (benchclient.reopen()
# opens it) for every file except the module-bench files, bench_modules and
# bench_fluid_module, which open tests/bench/bench_module.maxpat themselves
# (close Vsynth performance patches first). Math-only tests: tests/run.sh.
#
#   tests/bench.sh                 regression set (DEFAULT below), slow tests skipped
#   tests/bench.sh --changed       only the files whose inputs changed since their last green run
#   tests/bench.sh --slow          the same files, plus their @slow tests
#   tests/bench.sh --all           every bench_*.py, slow tests included
#   tests/bench.sh --list          print what would run, then exit (no Max needed)
#   tests/bench.sh tests/bench_control.py   just the named files
#   BENCH_LOG=path                 write the log there instead of tests/jobs/bench_last.log
#
# --changed (tests/benchdeps.py): a file whose Python imports, data files and
# environment (Max and Vsynth versions) equal those of its last green run is
# skipped, with the reason printed; bench_modules runs only the modules whose
# patcher changed. Without --changed everything selected runs, and every file that
# passes is recorded, so a plain run seeds the record. Not covered: GPU driver,
# macOS, what else is open in Max, so run without --changed before a release.
#
# Slow tests (harness.slow) are marked where they live and listed by name in each
# file's output when skipped; at the moment: bench_fluid T021 (cost, ~45 s) and
# T022 (soak, ~190 s).
#
# Not in the regression set, on purpose: bench_perf.py (fps-based checks that
# can fail on a busy machine without a regression) and bench_fluid_probes.py
# (Phase 0 record of bench-verified facts, not a gate for shipped modules).
cd "$(dirname "$0")/.." || exit 1

DEFAULT=(control selftest fft temporal fluid caustic_codebox modules fluid_module caustic_sheets)

ALL=0; LIST=0; SLOW=0; CHANGED=0; FILES=()
for a in "$@"; do
  case "$a" in
    --all)     ALL=1; SLOW=1 ;;
    --slow)    SLOW=1 ;;
    --changed) CHANGED=1 ;;
    --list)    LIST=1 ;;
    *)         FILES+=("$a") ;;
  esac
done
if [ "$SLOW" -eq 1 ]; then export BENCH_SLOW=1; fi
if [ ${#FILES[@]} -eq 0 ]; then
  if [ "$ALL" -eq 1 ]; then
    FILES=(tests/bench_*.py)
  else
    for n in "${DEFAULT[@]}"; do
      if [ ! -f "tests/bench_$n.py" ]; then
        echo "DEFAULT names a missing file: tests/bench_$n.py (update DEFAULT in tests/bench.sh)" >&2
        exit 1
      fi
      FILES+=("tests/bench_$n.py")
    done
  fi
fi

# --changed: keep only what needs to run; MODS[i] is a comma list of modules for
# FILES[i] (bench_modules only), or "-".
MODS=()
if [ "$CHANGED" -eq 1 ]; then
  PLAN_ARGS=(); if [ "$SLOW" -eq 1 ]; then PLAN_ARGS+=(--slow); fi
  PLAN=$(python3 tests/benchdeps.py plan "${PLAN_ARGS[@]}" "${FILES[@]}") || exit 3
  FILES=()
  while IFS=$'\t' read -r f m; do
    if [ -n "$f" ]; then FILES+=("$f"); MODS+=("$m"); fi
  done <<< "$PLAN"
  if [ ${#FILES[@]} -eq 0 ]; then
    echo "nothing to run: every selected bench file is unchanged since its last green run" \
         "(tests/bench.sh without --changed runs everything)"
    exit 0
  fi
fi
if [ "$LIST" -eq 1 ]; then printf '%s\n' "${FILES[@]}"; exit 0; fi

# The codebox bench (bench.maxpat) must be open for every file except the two
# module-bench files, which open their own bench; with only those selected there
# is nothing to require.
NEEDS_CODEBOX=0
for f in "${FILES[@]}"; do
  case "$f" in
    */bench_modules.py|*/bench_fluid_module.py|*/bench_caustic_sheets.py|bench_modules.py|bench_fluid_module.py|bench_caustic_sheets.py) ;;
    *) NEEDS_CODEBOX=1 ;;
  esac
done

PY=(uv run --no-project --with numpy python3)
if [ "$NEEDS_CODEBOX" -eq 1 ] && \
   ! "${PY[@]}" -c "import sys; sys.path.insert(0, 'tests'); import benchclient; sys.exit(0 if benchclient.ping() else 1)"; then
  echo "bench not reachable -- open Max and tests/bench/bench.maxpat (no /pong on UDP 7472)"
  exit 2
fi
# full output (incl. tracebacks) always kept, even if the caller filters it
mkdir -p tests/jobs
LOG="${BENCH_LOG:-tests/jobs/bench_last.log}"
mkdir -p "$(dirname "$LOG")"
# first line records what produced the log: results here depend on the Max build
# (2026-10-04: Max 9.2.0 rejected an assignment to `PI` that earlier runs accepted)
echo "# Max $(defaults read /Applications/Max.app/Contents/Info CFBundleShortVersionString 2>/dev/null || echo unknown), $(date '+%Y-%m-%d %H:%M')" > "$LOG"
status=0
i=0
for f in "${FILES[@]}"; do
  mods="${MODS[$i]:-}"; i=$((i + 1))
  [ "$mods" = "-" ] && mods=""
  # inputs as they are NOW, so an edit made during the run is never recorded as tested
  snap=$(mktemp "${TMPDIR:-/tmp}/benchsnap.XXXXXX")
  python3 tests/benchdeps.py snapshot "$f" > "$snap" 2>/dev/null
  echo "=== $f${mods:+ (modules: $mods)}" | tee -a "$LOG"
  if [ -n "$mods" ]; then export BENCH_MODULES="$mods"; else unset BENCH_MODULES; fi
  "${PY[@]}" "$f" 2>&1 | tee -a "$LOG"
  if [ "${PIPESTATUS[0]}" -eq 0 ]; then
    REC_ARGS=(--snapshot "$snap")
    if [ "$SLOW" -eq 1 ]; then REC_ARGS+=(--slow); fi
    if [ -n "$mods" ]; then REC_ARGS+=(--modules "$mods"); fi
    python3 tests/benchdeps.py record "$f" "${REC_ARGS[@]}"
  else
    status=1
    python3 tests/benchdeps.py forget "$f"
  fi
  rm -f "$snap"
done
unset BENCH_MODULES
exit $status
