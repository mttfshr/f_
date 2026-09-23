#!/bin/bash
# Run f_ math tests in an ephemeral NumPy environment via uv -- nothing is
# installed system-wide. No args: run every tests/test_*.py.
#   tests/run.sh
#   tests/run.sh tests/test_fft_separable.py
cd "$(dirname "$0")/.." || exit 1
if [ $# -eq 0 ]; then set -- tests/test_*.py; fi
status=0
for f in "$@"; do
  echo "=== $f"
  uv run --no-project --with numpy python3 "$f" || status=1
done
exit $status
