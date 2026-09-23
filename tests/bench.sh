#!/bin/bash
# Run bench tests (tests/bench_*.py) against the live Max test bench.
# Needs Max open with tests/bench/bench.maxpat. Math-only tests: tests/run.sh.
#   tests/bench.sh
#   tests/bench.sh tests/bench_control.py
cd "$(dirname "$0")/.." || exit 1
PY=(uv run --no-project --with numpy python3)
if ! "${PY[@]}" -c "import sys; sys.path.insert(0, 'tests'); import benchclient; sys.exit(0 if benchclient.ping() else 1)"; then
  echo "bench not reachable -- open Max and tests/bench/bench.maxpat (no /pong on UDP 7472)"
  exit 2
fi
if [ $# -eq 0 ]; then set -- tests/bench_*.py; fi
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
