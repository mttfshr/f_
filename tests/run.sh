#!/bin/bash
# Run f_ math tests in an ephemeral NumPy environment via uv -- nothing is
# installed system-wide. No args: run every tests/test_*.py.
#   tests/run.sh
#   tests/run.sh tests/test_fft_separable.py
#   tests/run.sh -q [files]     quiet: one line per file, full detail only for failures
#
# Every run writes tests/logs/<timestamp>-offline.log (tests/_log.sh): full output,
# a header (Max version, git SHA, dirty flag, flags) and a per-file timing table.
# The screen gets the total and the three slowest files.
cd "$(dirname "$0")/.." || exit 1
. tests/_log.sh
FLAGS="$*"
QUIET=0; ARGS=()
for a in "$@"; do
  case "$a" in
    -q|--quiet) QUIET=1; export TEST_QUIET=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
set -- "${ARGS[@]}"
if [ $# -eq 0 ]; then set -- tests/test_*.py; fi
log_open offline "${FLAGS:-none}"
if [ "$QUIET" -eq 1 ]; then export TEST_FULL_LOG="$LOG"; fi   # quiet on screen, complete in the log

now() { perl -MTime::HiRes=time -e 'printf "%.3f\n", time'; }
status=0; TIMES=(); T0=$(now)
for f in "$@"; do
  if [ "$QUIET" -eq 1 ]; then echo "=== $f" >> "$LOG"; else echo "=== $f" | tee -a "$LOG"; fi
  t=$(now)
  uv run --no-project --with numpy python3 "$f" 2>&1 | tee -a "$LOG"
  [ "${PIPESTATUS[0]}" -eq 0 ] || status=1
  dt=$(awk -v a="$t" -v b="$(now)" 'BEGIN { printf "%.2f", b - a }')
  TIMES+=("$dt $f")
  [ "$QUIET" -eq 1 ] || echo "  (${dt}s)"
done
total=$(awk -v a="$T0" -v b="$(now)" 'BEGIN { printf "%.1f", b - a }')
{
  echo "# timing, seconds per file, slowest first:"
  printf '%s\n' "${TIMES[@]}" | sort -rn | sed 's/^/#   /'
  echo "# total: ${total}s over $# files"
} >> "$LOG"
slowest=$(printf '%s\n' "${TIMES[@]}" | sort -rn | head -3 | awk '{ printf "%s%s %ss", (NR > 1 ? ", " : ""), $2, $1 }')
echo "total ${total}s over $# files; slowest: $slowest"
if [ "$QUIET" -eq 1 ]; then
  if [ "$status" -eq 0 ]; then echo "all test files passed (log: $LOG)"; else echo "FAILED (details above; full log: $LOG)"; fi
else
  echo "log: $LOG"
fi
exit $status
