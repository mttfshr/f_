#!/usr/bin/env bash
# tests/check.sh quick|full -- the two checks worth running before a commit / before a release.
#   quick   offline suite only (tests/run.sh -q): no Max, ~1 minute.
#   full    quick, then the bench files whose inputs changed since their last green run
#           (tests/bench.sh --changed -q). Needs Max with tests/bench/bench.maxpat open; a run
#           where nothing changed costs seconds. Use `tests/bench.sh -q` (no --changed) before a release.
#           Ends with one line from the check history (tests/lib/checkhist.py report lists the details).
# Neither mode edits anything but the history. Exit status is the first failing step's.
set -u
cd "$(dirname "$0")/.." || exit 2
case "${1:-}" in
  quick) exec tests/run.sh -q ;;
  full)  tests/run.sh -q || exit $?
         tests/bench.sh --changed -q; rc=$?
         python3 tests/lib/checkhist.py summary 2>/dev/null
         exit $rc ;;
  *)     echo "usage: tests/check.sh quick|full" >&2; exit 2 ;;
esac
