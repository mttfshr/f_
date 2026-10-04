#!/bin/bash
# bg.sh -- run the tests in the background and check on them later, so a 40 s to
# 3 minute run never blocks you (or Claude).
#
#   tests/bg.sh start [offline|bench|all] [args]   start detached and return at once
#   tests/bg.sh status [id|offline|bench|all]      state, elapsed, summary per file
#                                                  (exit 0 passed, 1 failed/stopped/died, 2 running, 3 none)
#   tests/bg.sh log [id] [lines]                   tail of the log (default 40)
#   tests/bg.sh stop [id]                          stop a running run
#   tests/bg.sh list                               the last 10 runs
#
#   offline   tests/run.sh (no Max)                       args go to run.sh
#   bench     tests/bench.sh --changed (live Max)         args replace --changed
#   all       offline, then bench --changed               both always run
#
# One bench run at a time (a lock); an offline run may overlap anything. A run
# keeps its log and status in tests/jobs/bg/<id>/ (gitignored) and sends a macOS
# notification when it finishes (BG_NO_NOTIFY=1 silences it). Starting a bench
# run needs Max up with the bench open, the same as bench.sh; if not, the run
# fails fast with "bench not reachable" in its log.
cd "$(dirname "$0")/.." || exit 1

BG_DIR="${BG_DIR:-tests/jobs/bg}"
OFFLINE_CMD="${BG_OFFLINE_CMD:-tests/run.sh}"
BENCH_CMD="${BG_BENCH_CMD:-tests/bench.sh}"

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; }

kill_tree() {
  local p=$1 c
  for c in $(pgrep -P "$p" 2>/dev/null); do kill_tree "$c"; done
  kill "$p" 2>/dev/null
}

alive() { [ -n "$1" ] && kill -0 "$1" 2>/dev/null; }

resolve() {
  local a="${1:-}" last
  case "$a" in
    "")  [ -f "$BG_DIR/latest" ] && cat "$BG_DIR/latest" ;;
    offline|bench|all)
         last=$(ls -d "$BG_DIR"/bg-*-"$a".* 2>/dev/null | tail -1)
         [ -n "$last" ] && basename "$last" ;;
    *)   [ -d "$BG_DIR/$a" ] && echo "$a" ;;
  esac
}

# ---------------------------------------------------------------- the run itself
if [ "${1:-}" = "_run" ]; then
  dir=$2; kind=$3; shift 3
  {
    case "$kind" in
      offline) $OFFLINE_CMD "$@"; rc=$? ;;
      bench)   if [ $# -eq 0 ]; then set -- --changed; fi; $BENCH_CMD "$@"; rc=$? ;;
      all)     $OFFLINE_CMD; rc=$?
               echo "=== (offline suite finished: exit $rc; now the bench)"
               if [ $# -eq 0 ]; then set -- --changed; fi
               $BENCH_CMD "$@"; r2=$?
               [ "$rc" -eq 0 ] && rc=$r2 ;;
    esac
    echo "$rc" > "$dir/exit"
  } > "$dir/log" 2>&1
  rc=$(cat "$dir/exit" 2>/dev/null || echo 1)
  date +%s > "$dir/ended"
  if [ "$rc" -eq 0 ]; then st=passed; else st=failed; fi
  echo "$st" > "$dir/status"
  if [ -f "$BG_DIR/bench.lock" ] && [ "$(cut -d' ' -f1 "$BG_DIR/bench.lock")" = "$$" ]; then
    rm -f "$BG_DIR/bench.lock"
  fi
  if [ -z "${BG_NO_NOTIFY:-}" ]; then
    osascript -e "display notification \"$kind run $st\" with title \"f_ tests\"" >/dev/null 2>&1 || true
  fi
  exit 0
fi

summarize() {   # per-file results from a log
  awk '/^=== /{f=$2; next}
       /^[0-9]+\/[0-9]+ passed/ || /^  FAIL/ || /Traceback/ || /^skipped \(slow\)/ {print "  " f ": " $0}
       /^bench not reachable/ || /^nothing to run/ || /^(skip|run) +tests\// {print "  " $0}' "$1"
}

cmd_start() {
  local kind="${1:-offline}"; [ $# -gt 0 ] && shift
  case "$kind" in offline|bench|all) ;; *) usage; exit 64 ;; esac
  mkdir -p "$BG_DIR"
  if [ "$kind" != "offline" ] && [ -f "$BG_DIR/bench.lock" ]; then
    read -r lpid lid < "$BG_DIR/bench.lock"
    if alive "$lpid"; then
      echo "a bench run is already in progress: $lid (tests/bg.sh status | stop)"; exit 1
    fi
    rm -f "$BG_DIR/bench.lock"                     # stale: that run died
  fi
  local dir; dir=$(mktemp -d "$BG_DIR/bg-$(date +%Y%m%d-%H%M%S)-$kind.XXXX") || exit 1
  local id; id=$(basename "$dir")
  echo "$kind${*:+ $*}" > "$dir/cmd"; date +%s > "$dir/started"; echo running > "$dir/status"
  ( nohup bash "$0" _run "$dir" "$kind" "$@" >/dev/null 2>&1 & echo $! > "$dir/pid" )
  if [ "$kind" != "offline" ]; then echo "$(cat "$dir/pid") $id" > "$BG_DIR/bench.lock"; fi
  echo "$id" > "$BG_DIR/latest"
  echo "started $id  (tests/bg.sh status | log | stop)"
}

cmd_status() {
  local id; id=$(resolve "${1:-}")
  [ -z "$id" ] && { echo "no runs yet"; exit 3; }
  local dir="$BG_DIR/$id" st started ended now elapsed
  st=$(cat "$dir/status" 2>/dev/null || echo unknown)
  if [ "$st" = "running" ] && ! alive "$(cat "$dir/pid" 2>/dev/null)"; then st=died; fi
  started=$(cat "$dir/started" 2>/dev/null || echo 0); now=$(date +%s)
  ended=$(cat "$dir/ended" 2>/dev/null || echo "$now"); elapsed=$((ended - started))
  echo "$id  $st  ${elapsed}s  ($(cat "$dir/cmd" 2>/dev/null))"
  summarize "$dir/log" 2>/dev/null
  if [ "$st" = "running" ]; then
    echo "  now: $(grep '^=== ' "$dir/log" 2>/dev/null | tail -1)"
  elif [ "$st" = "died" ]; then
    echo "  the run's process is gone without a result (tests/bg.sh log)"
  fi
  case "$st" in passed) exit 0 ;; running) exit 2 ;; *) exit 1 ;; esac
}

cmd_log() {
  local id; id=$(resolve "${1:-}")
  [ -z "$id" ] && { echo "no runs yet"; exit 3; }
  echo "# $BG_DIR/$id/log"
  tail -n "${2:-40}" "$BG_DIR/$id/log"
}

cmd_stop() {
  local id; id=$(resolve "${1:-}")
  [ -z "$id" ] && { echo "no runs yet"; exit 3; }
  local dir="$BG_DIR/$id" pid
  pid=$(cat "$dir/pid" 2>/dev/null)
  if [ "$(cat "$dir/status" 2>/dev/null)" != "running" ] || ! alive "$pid"; then
    echo "$id is not running"; exit 1
  fi
  kill_tree "$pid"
  echo stopped > "$dir/status"; date +%s > "$dir/ended"
  if [ -f "$BG_DIR/bench.lock" ] && [ "$(cut -d' ' -f1 "$BG_DIR/bench.lock")" = "$pid" ]; then
    rm -f "$BG_DIR/bench.lock"
  fi
  echo "stopped $id"
}

cmd_list() {
  local d
  for d in $(ls -d "$BG_DIR"/bg-* 2>/dev/null | sort | tail -10); do
    local id; id=$(basename "$d"); local st; st=$(cat "$d/status" 2>/dev/null)
    if [ "$st" = "running" ] && ! alive "$(cat "$d/pid" 2>/dev/null)"; then st=died; fi
    echo "$id  $st"
  done
}

case "${1:-}" in
  start)  shift; cmd_start "$@" ;;
  status) shift; cmd_status "$@" ;;
  log)    shift; cmd_log "$@" ;;
  stop)   shift; cmd_stop "$@" ;;
  list)   cmd_list ;;
  *)      usage; exit 64 ;;
esac
