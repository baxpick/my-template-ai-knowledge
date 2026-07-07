#!/usr/bin/env bash
#
# new_doc.sh — scaffold a knowledge-base doc with correct, dated frontmatter.
#
# Usage:
#   scripts/kb/new_doc.sh <path-under-docs.md> "<scope>" "<read_when>" ["<Title>"]
# Example:
#   scripts/kb/new_doc.sh architecture/auth.md "How auth works" "Touching login/session code"
#
# Why this exists: agents routinely hardcode the wrong last_updated date and
# forget the frontmatter keys the drift check relies on. This makes the
# deterministic part deterministic. It does NOT touch git — the human commits.
#
# Portability: runs on both macOS (BSD userland — bash 3.2) and Ubuntu/Linux
# (GNU coreutils); uses only POSIX-common flags of date/sed/awk/basename.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

rel="${1:?usage: new_doc.sh <path-under-docs.md> \"<scope>\" \"<read_when>\" [\"<Title>\"]}"
scope="${2:?scope required (one line — what this file covers)}"
read_when="${3:?read_when required (one line — task patterns that trigger reading it)}"
path="docs/$rel"

case "$rel" in
  *.md) : ;;
  *) echo "refuse: path must end in .md (got '$rel')" >&2; exit 1 ;;
esac
if [ -e "$path" ]; then
  echo "refuse: $path already exists" >&2
  exit 1
fi

# Derive a Title from the filename if not given (foo-bar.md -> "Foo Bar").
title="${4:-}"
if [ -z "$title" ]; then
  base="$(basename "$rel" .md)"
  title="$(printf '%s' "$base" | sed 's/[-_]/ /g' \
    | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}; print}')"
fi

today="$(date +%Y-%m-%d)"
mkdir -p "$(dirname "$path")"
cat > "$path" <<EOF
---
last_updated: $today
scope: $scope
read_when: $read_when
---
# $title

## Overview
<!-- Write FOR THE AGENT: concrete file paths, exact commands, explicit
     do this / don't do this. No code snippets (use file:line references).
     No secret values, ever. Target 50-200 lines. Delete this comment. -->
EOF

echo "created $path"
echo "NEXT: add a routing row for it in docs/INDEX.md (task type -> $rel)"
