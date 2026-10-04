#!/bin/bash
# Run bench tests (tests/bench_*.py) against the live Max test bench.
# Needs Max open with tests/bench/bench.maxpat. Math-only tests: tests/run.sh.
# The module-bench files (bench_modules, bench_fluid_module) reopen
# tests/bench/bench_module.maxpat themselves; close Vsynth performance patches first.
#
#   tests/bench.sh                 regression set (DEFAULT below)
#   tests/bench.sh --all           every bench_*.py (adds timing- and probe-style files)
#   tests/bench.sh --list          print what would run, then exit (no Max needed)
#   tests/bench.sh tests/bench_control.py   just the named files
#
# Not in the regression set, on purpose: bench_perf.py (fps-based checks that
# can fail on a busy machine without a regression) and bench_fluid_probes.py
# (Phase 0 record of bench-verified facts, not a gate for shipped modules).
cd "$(dirname "$0")/.." || exit 1

DEFAULT=(control selftest fft temporal fluid modules fluid_module)

ALL=0; LIST=0; FILES=()
for a in "$@"; do
  case "$a" in
    --all)  ALL=1 ;;
    --list) LIST=1 ;;
    *)      FILES+=("$a") ;;
  esac
done
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
if [ "$LIST" -eq 1 ]; then printf '%s\n' "${FILES[@]}"; exit 0; fi

PY=(uv run --no-project --with numpy python3)
if ! "${PY[@]}" -c "import sys; sys.path.insert(0, 'tests'); import benchclient; sys.exit(0 if benchclient.ping() else 1)"; then
  echo "bench not reachable -- open Max and tests/bench/bench.maxpat (no /pong on UDP 7472)"
  exit 2
fi
set -- "${FILES[@]}"
# full output (incl. tracebacks) always kept, even if the caller filters it
mkdir -p tests/jobs
LOG=tests/jobs/bench_last.log
: > "$LOG"
status=0
for f in "$@"; do
  echo "=== $f" | tee -a "$LOG"
  "${PY[@]}" "$f" 2>&1 | tee -a "$LOG"
  [ "${PIPESTATUS[0]}" -eq 0 ] || status=1
done
exit $status
