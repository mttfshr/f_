#!/usr/bin/env bash
# Build a release zip of the installable Max package.
#
# The zip holds a single top-level `f_/` folder containing the contents of
# `package/`, so unzipping it into Documents/Max 9/Packages/ installs it.
#
#   build/release.sh                  zip the COMMITTED state of package/ (HEAD)
#   build/release.sh --working-tree   zip package/ as it is on disk now
#                                     (includes uncommitted edits; for test builds)
#
# Output goes to dist/ (gitignored). Naming:
#   f_-<version>.zip       HEAD is tagged v<version>
#   f_-<version>-dev.zip   HEAD is not tagged
#   f_-<version>-wip.zip   --working-tree
#
# Refuses to build if HEAD carries a tag that doesn't match the version in
# package-info.json. Does not create tags or GitHub releases.
# Needs: git, python3, zip, unzip, rsync.

set -euo pipefail
cd "$(dirname "$0")/.."

PKG=package
MODE=head
case "${1:-}" in
  "") ;;
  --working-tree) MODE=wip ;;
  *) echo "usage: build/release.sh [--working-tree]" >&2; exit 2 ;;
esac

# name + version come from package-info.json (HEAD's copy unless --working-tree)
read_info() {
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d['name'], d['version'])"
}
if [ "$MODE" = wip ]; then
  read -r NAME VERSION < <(read_info < "$PKG/package-info.json")
else
  read -r NAME VERSION < <(git show "HEAD:$PKG/package-info.json" | read_info)
fi

# version / tag consistency
SUFFIX=""
if [ "$MODE" = wip ]; then
  SUFFIX="-wip"
else
  TAG=$(git describe --tags --exact-match HEAD 2>/dev/null || true)
  if [ -z "$TAG" ]; then
    echo "note: HEAD is not tagged; building a -dev zip" >&2
    SUFFIX="-dev"
  elif [ "$TAG" != "v$VERSION" ]; then
    echo "error: HEAD is tagged $TAG but package-info.json says version $VERSION" >&2
    exit 1
  fi
  DIRTY=$(git status --porcelain -- "$PKG" | wc -l | tr -d ' ')
  if [ "$DIRTY" != 0 ]; then
    echo "warning: $DIRTY uncommitted change(s) under $PKG/ are NOT in this zip (--working-tree includes them)" >&2
  fi
fi

# build
mkdir -p dist
OUT="$PWD/dist/${NAME}-${VERSION}${SUFFIX}.zip"
rm -f "$OUT"
if [ "$MODE" = head ]; then
  git archive --format=zip --prefix="$NAME/" -o "$OUT" "HEAD:$PKG"
else
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  rsync -a --exclude='.DS_Store' --exclude='*.bak' "$PKG/" "$TMP/$NAME/"
  (cd "$TMP" && zip -qrX "$OUT" "$NAME")
fi

# verify the zip's shape
LIST=$(unzip -Z1 "$OUT")
OUTSIDE=$(printf '%s\n' "$LIST" | grep -v "^$NAME/" || true)
JUNK=$(printf '%s\n' "$LIST" | grep -E '(^|/)\.DS_Store$|\.bak$' || true)
[ -z "$OUTSIDE" ] || { echo "error: entries outside $NAME/:"; echo "$OUTSIDE"; exit 1; }
[ -z "$JUNK" ]    || { echo "error: junk files in zip:"; echo "$JUNK"; exit 1; }
printf '%s\n' "$LIST" | grep -qx "$NAME/package-info.json" \
  || { echo "error: $NAME/package-info.json missing from zip" >&2; exit 1; }

COUNT=$(printf '%s\n' "$LIST" | grep -vc '/$' || true)
echo "built ${OUT#$PWD/}  ($COUNT files, $(du -h "$OUT" | cut -f1))"
