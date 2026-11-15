#!/usr/bin/env bash
# Skill upload staleness check.
#
# `f_/skills/` is the single source of truth for all Max/Vsynth/audio-DSP
# skills. Two consumers: `claude-scaffold/skills/` (symlinked, always in
# sync) and the claude.ai upload (a real copy, which CAN go stale silently).
#
# MANIFEST.md records the state of each skill AS OF THE LAST UPLOAD.
#
#   ./check.sh          compare disk to manifest, report drift (exit 1 if any)
#   ./check.sh stamp    rewrite manifest to current state -- run AFTER uploading
#
# No dependencies beyond shasum/awk.

set -euo pipefail
cd "$(dirname "$0")"

MANIFEST="MANIFEST.md"

skills() { find . -mindepth 2 -maxdepth 2 -name SKILL.md | sed 's|^\./||;s|/SKILL.md$||' | sort; }
# Hash SKILL.md followed by every other file in the skill folder (e.g. local.md),
# so a changed sidecar also reads STALE. For a SKILL.md-only skill the bytes are
# identical to hashing SKILL.md alone, so existing manifest rows stay valid.
hash_of() { { cat "$1/SKILL.md"; find "$1" -type f ! -name SKILL.md | LC_ALL=C sort | xargs cat 2>/dev/null; } | shasum -a 256 | awk '{print substr($1,1,12)}'; }
lines_of() { awk 'END{print NR}' "$1/SKILL.md"; }

if [ "${1:-check}" = "stamp" ]; then
  {
    echo "# Skill upload manifest"
    echo
    echo "State of each skill as of the last claude.ai upload."
    echo "Regenerate with \`./skills/check.sh stamp\` immediately AFTER uploading."
    echo "Check with \`./skills/check.sh\`."
    echo
    echo "_Stamped: $(date +%Y-%m-%d)_"
    echo
    echo "| skill | sha256(12) | lines |"
    echo "|---|---|---|"
    for s in $(skills); do
      echo "| \`$s\` | $(hash_of "$s") | $(lines_of "$s") |"
    done
  } > "$MANIFEST"
  echo "stamped $MANIFEST -- $(skills | wc -l | tr -d ' ') skills"
  exit 0
fi

if [ ! -f "$MANIFEST" ]; then
  echo "no $MANIFEST -- run './skills/check.sh stamp' after your next upload"
  exit 1
fi

# claude.ai upload rules: description at most 1024 characters, no < or >.
bad=0
for s in $(skills); do
  d=$(awk '/^description: /{sub(/^description: /,""); print; exit}' "$s/SKILL.md")
  n=$(printf '%s' "$d" | wc -m | tr -d ' ')
  if [ "$n" -gt 1024 ]; then printf "INVALID %-33s description is %s chars (max 1024)\n" "$s" "$n"; bad=1; fi
  case "$d" in *"<"*|*">"*) printf "INVALID %-33s description contains < or > (read as an XML tag)\n" "$s"; bad=1;; esac
done

drift=$bad
for s in $(skills); do
  want=$(awk -v s="\`$s\`" -F'|' '$2 ~ s {gsub(/ /,"",$3); print $3}' "$MANIFEST")
  got=$(hash_of "$s")
  if [ -z "$want" ]; then
    printf "NEW    %-34s never uploaded (%s lines)\n" "$s" "$(lines_of "$s")"
    drift=1
  elif [ "$want" != "$got" ]; then
    printf "STALE  %-34s upload differs (now %s lines)\n" "$s" "$(lines_of "$s")"
    drift=1
  else
    printf "ok     %-34s\n" "$s"
  fi
done

# skills in the manifest that no longer exist on disk
awk -F'|' '/^\| `/ {gsub(/[` ]/,"",$2); print $2}' "$MANIFEST" | while read -r m; do
  [ -f "$m/SKILL.md" ] || printf "GONE   %-34s in manifest, not on disk\n" "$m"
done

[ "$drift" = 0 ] && echo && echo "all uploads current" || { echo; echo "re-upload the above, then: ./skills/check.sh stamp"; exit 1; }
