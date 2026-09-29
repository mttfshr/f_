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
hash_of() { shasum -a 256 "$1/SKILL.md" | awk '{print substr($1,1,12)}'; }
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

drift=0
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
