#!/bin/bash
# Run f_ math tests in an ephemeral NumPy environment via uv -- nothing is
# installed system-wide. No args: run every tests/test_*.py.
#   tests/run.sh
#   tests/run.sh tests/test_fft_separable.py
#   tests/run.sh -q [files]     quiet: one line per file, full detail only for failures
cd "$(dirname "$0")/.." || exit 1
QUIET=0; ARGS=()
for a in "$@"; do
  case "$a" in
    -q|--quiet) QUIET=1; export TEST_QUIET=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
set -- "${ARGS[@]}"
if [ $# -eq 0 ]; then set -- tests/test_*.py; fi
status=0
for f in "$@"; do
  [ "$QUIET" -eq 1 ] || echo "=== $f"
  uv run --no-project --with numpy python3 "$f" || status=1
done
if [ "$QUIET" -eq 1 ]; then
  if [ "$status" -eq 0 ]; then echo "all test files passed"; else echo "FAILED (details above)"; fi
fi
exit $status
