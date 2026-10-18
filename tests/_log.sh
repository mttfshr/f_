#!/bin/bash
# tests/_log.sh -- sourced by run.sh, bench.sh and bg.sh (not run directly).
#
# Every run writes tests/logs/<YYYYmmdd-HHMMSS>-<kind>.log, so one run's results are
# never overwritten by the next. tests/logs/latest points at the newest log of any
# kind, tests/logs/latest-<kind> at the newest of that kind; the newest LOGS_KEEP of
# each kind are kept. The first line says what produced the log -- kind, Max version,
# git SHA, whether the tree had uncommitted changes, the flags -- because results
# depend on all of them (2026-10-04: Max 9.2.0 rejected an assignment to `PI` that
# earlier runs accepted).
#
#   MAX_APP=/path/Max.app   the Max install to read the version from
#                           (default /Applications/Max.app)
#   TEST_LOGS_DIR=dir       where logs go (the tests use it); relative to the repo root
#   BENCH_LOG=path          bench.sh only: write the bench log there instead
LOGS_DIR="${TEST_LOGS_DIR:-tests/logs}"
LOGS_KEEP=20

# Import path for every test file: tests/lib (shared libraries, incl. paths.py), each test directory and
# build/. Replaces the per-file sys.path.insert hacks. Run a single file with tests/py.sh.
TESTS_PYPATH="$PWD/tests/lib:$PWD/tests/toolchain:$PWD/tests/contracts:$PWD/tests/build:$PWD/tests/math:$PWD/tests/records:$PWD/build"
for _d in "$PWD"/tests/modules/*/; do TESTS_PYPATH="$TESTS_PYPATH:${_d%/}"; done
export PYTHONPATH="$TESTS_PYPATH${PYTHONPATH:+:$PYTHONPATH}"

max_version() {
  defaults read "${MAX_APP:-/Applications/Max.app}/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo unknown
}

# log_header KIND [FLAGS] -> the one header line
log_header() {
  local kind="$1" flags="${2:-none}" sha dirty
  sha=$(git rev-parse --short HEAD 2>/dev/null || echo nogit)
  if [ -n "$(git status --porcelain 2>/dev/null | head -1)" ]; then dirty=dirty; else dirty=clean; fi
  echo "# $kind | Max $(max_version) | git $sha ($dirty) | flags: $flags | $(date '+%Y-%m-%d %H:%M')"
}

# log_open KIND [FLAGS] -> sets LOG, writes the header, updates the links, prunes old logs
log_open() {
  local kind="$1" flags="${2:-none}" old
  mkdir -p "$LOGS_DIR"
  if [ "$kind" = bench ] && [ -n "${BENCH_LOG:-}" ]; then
    LOG="$BENCH_LOG"
    mkdir -p "$(dirname "$LOG")"
  else
    LOG="$LOGS_DIR/$(date +%Y%m%d-%H%M%S)-$kind.log"
  fi
  log_header "$kind" "$flags" > "$LOG"
  case "$LOG" in
    "$LOGS_DIR"/*)
      ln -sf "$(basename "$LOG")" "$LOGS_DIR/latest-$kind"
      ln -sf "$(basename "$LOG")" "$LOGS_DIR/latest"
      ls -1 "$LOGS_DIR"/[0-9]*-"$kind".log 2>/dev/null | sort \
        | awk -v k="$LOGS_KEEP" '{ a[NR] = $0 } END { for (i = 1; i <= NR - k; i++) print a[i] }' \
        | while read -r old; do rm -f "$old"; done ;;
  esac
}
