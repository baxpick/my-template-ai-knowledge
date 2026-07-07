#!/usr/bin/env bash
#
# new_adr.sh — create the next-numbered ADR and index it, deterministically.
#
# Usage:
#   scripts/kb/new_adr.sh "<Decision title>"
# Example:
#   scripts/kb/new_adr.sh "Use Postgres for the primary store"
#
# Picks the next free NNNN (0000 is the template, so real ADRs start at 0001),
# writes the file from the template shape, and appends a row to the index table
# in docs/decisions/README.md (newest last). It does NOT touch git.
#
# Portability: runs on both macOS (BSD userland — bash 3.2) and Ubuntu/Linux
# (GNU coreutils); uses only POSIX-common flags of date/sed/awk/tr/printf/ls.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

title="${1:?usage: new_adr.sh \"<Decision title>\"}"
dir="docs/decisions"
index="$dir/README.md"
[ -f "$index" ] || { echo "refuse: $index not found" >&2; exit 1; }

# Highest existing NNNN among decisions/NNNN-*.md; base-10 to ignore zero-padding.
# The `|| true` is required: with an empty decisions/ dir the glob matches nothing,
# `ls` exits non-zero, and under `set -o pipefail` that would abort the script —
# defeating the `${last:-0}` "start at 0001" fallback the next line relies on.
last="$( { ls "$dir"/[0-9][0-9][0-9][0-9]-*.md 2>/dev/null \
  | sed -E 's#.*/([0-9]{4})-.*#\1#' | sort -n | tail -n1; } || true )"
next=$(( 10#${last:-0} + 1 ))
num="$(printf '%04d' "$next")"

slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-//; s/-$//')"
file="$dir/$num-$slug.md"
today="$(date +%Y-%m-%d)"

if [ -e "$file" ]; then
  echo "refuse: $file already exists" >&2
  exit 1
fi

cat > "$file" <<EOF
# $num — $title

Date: $today | Status: Accepted

## Context
<!-- The forces at play: what problem, what constraints, what alternatives existed. -->

## Decision
<!-- The choice made, stated plainly. -->

## Consequences
<!-- What becomes easier, what becomes harder, what future agents must respect. -->
EOF

# Append a row to the index table, right after the last existing table row.
row="| $num | $title | Accepted |"
awk -v row="$row" '
  { lines[NR]=$0; if ($0 ~ /^\| /) last=NR }
  END { for (i=1;i<=NR;i++){ print lines[i]; if (i==last) print row } }
' "$index" > "$index.tmp" && mv "$index.tmp" "$index"

echo "created $file"
echo "indexed it in $index"
