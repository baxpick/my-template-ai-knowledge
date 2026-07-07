#!/usr/bin/env bash
#
# kb_review_worklist.sh — a "since-last-review" reporter that says WHICH knowledge
# docs recent code changes likely made stale, from git history alone — WITHOUT
# reading every doc into an agent's context. It is the targeted front-end to the
# KB sweep (docs/runbooks/kb-review.md, the "update the ai-doc solution" trigger):
# run it first to turn "re-read all docs" into a short, evidence-based worklist.
#
# It complements scripts/kb/check_docs_drift.sh. The drift check validates
# STRUCTURE (links, frontmatter, size caps, and that the STALENESS_MAP is valid).
# This adds the TIME dimension: given a window of recent commits it cross-refs the
# changed paths against that same STALENESS_MAP and reports:
#   1. Docs whose mapped source changed in the window — flagging the ones whose
#      last_updated PREDATES the change ([review]) vs. those already touched
#      after it ([check]).
#   2. Changed paths NO map entry covers — with a suggested STALENESS_MAP line for
#      each, so the map (whose #1 failure mode is going stale/incomplete) stays
#      honest semi-automatically. A human/LLM still confirms the real doc name.
#
# Usage:
#   scripts/kb/kb_review_worklist.sh [DAYS]
#
#   DAYS  How many days of recent git history to inspect. Default: 3 — tuned for
#         the same-session / weekly cadence. The single positional argument is the
#         window size; pass a LARGER number to cover a longer gap since the last
#         KB review:
#           30  after a monthly sweep
#           90  catching up after a quiet quarter
#           <whole-history>  first review of an old repo (over-shoot freely)
#         The window MUST reach back to the last time someone ran "update the
#         ai-doc solution" — changes committed before that cutoff are invisible
#         here. When unsure, over-shoot: extra noise is cheaper than a missed
#         stale doc. Deeper/older reviews therefore need a BIGGER DAYS value.
#
# Read-only: edits no files, never touches git, and (being advisory, not a gate)
# exits 0 on any successful report. Portable across macOS (BSD userland, bash 3.2)
# and Ubuntu/Linux (GNU coreutils). No associative arrays (bash 3.2 lacks them).
#
# Testability note: the reporter derives everything from real git history, so its
# tests build throwaway repos with back-dated commits — it needs no seams of its
# own and nothing here should be special-cased for tests.
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

DRIFT_SCRIPT="scripts/kb/check_docs_drift.sh"

usage() {
  cat <<'USAGE'
usage: scripts/kb/kb_review_worklist.sh [DAYS]

  DAYS  Days of recent git history to inspect (positive integer). Default: 3.
        Use a bigger window to cover a longer gap since the last KB review:
          30  after a monthly sweep    90  a quiet quarter    (over-shoot freely)
        The window must reach back to the last "update the ai-doc solution" run,
        or earlier changes stay invisible.

Reports which knowledge docs recent code changes implicate (via the STALENESS_MAP
in scripts/kb/check_docs_drift.sh) and suggests map entries for changed paths
nothing maps yet. Read-only: edits no files, never touches git.
USAGE
}

# ── args ─────────────────────────────────────────────────────────────────────
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac
DAYS="${1:-3}"
case "$DAYS" in
  ''|*[!0-9]*) echo "error: DAYS must be a positive integer (got '${1:-}')" >&2; usage >&2; exit 2 ;;
esac
[ "$DAYS" -gt 0 ] || { echo "error: DAYS must be > 0" >&2; exit 2; }

# ── preconditions ────────────────────────────────────────────────────────────
command -v git >/dev/null 2>&1 || { echo "error: git not found on PATH" >&2; exit 1; }
git rev-parse >/dev/null 2>&1  || { echo "error: not inside a git repository" >&2; exit 1; }

# Human-readable cutoff date (GNU date first, then BSD/macOS date).
CUTOFF="$(date -d "${DAYS} days ago" +%Y-%m-%d 2>/dev/null \
  || date -v-"${DAYS}"d +%Y-%m-%d 2>/dev/null \
  || echo "${DAYS} days ago")"

# Parse YYYY-MM-DD to epoch portably (GNU date first, then BSD/macOS date).
epoch_of() {
  date -d "$1" +%s 2>/dev/null \
    || date -j -f "%Y-%m-%d" "$1" +%s 2>/dev/null \
    || echo 0
}

# Is changed file $1 under source path $2 (exact file, or anywhere below a dir)?
covered_by() {
  case "$1" in
    "$2"|"$2"/*) return 0 ;;
  esac
  return 1
}

# ── 1. changed paths in the window ───────────────────────────────────────────
# git log --since filters by commit date; on a normal (date-ordered) history it
# returns every path touched by commits newer than the cutoff.
changed="$(git log --since="${DAYS} days ago" --name-only --pretty=format: -- . 2>/dev/null \
  | sed '/^$/d' | sort -u || true)"

echo "KB review worklist — commits in the last $DAYS day(s) (since $CUTOFF)"
echo

if [ -z "$changed" ]; then
  echo "No commits in the window. Nothing to review."
  echo "If the KB has not been swept in longer, widen the window, e.g.: $0 30"
  exit 0
fi

echo "Changed paths ($(printf '%s\n' "$changed" | grep -c .)):"
printf '%s\n' "$changed" | sed 's/^/  /'
echo

# ── 2. extract STALENESS_MAP from the drift script (textually — no sourcing) ──
# The map lives between  STALENESS_MAP="  and the next lone  "  in the drift
# script. Reading it textually keeps that script's single source of truth and
# avoids executing it. Empty map (pristine template) is fine — every check below
# just degrades to "nothing mapped yet".
map=""
if [ -f "$DRIFT_SCRIPT" ]; then
  map="$(awk '
    /^STALENESS_MAP="/ { inmap=1; next }
    inmap && /^"/       { inmap=0 }
    inmap               { print }
  ' "$DRIFT_SCRIPT")"
fi

# Set of mapped source paths (trailing slash stripped) for the coverage test.
map_sources=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  # shellcheck disable=SC2086
  set -- $line
  src="${2:-}"
  [ -z "$src" ] && continue
  map_sources="$map_sources ${src%/}"
done <<< "$map"

# ── 3. docs implicated via the map ───────────────────────────────────────────
echo "Docs implicated via STALENESS_MAP:"
implicated=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  # shellcheck disable=SC2086
  set -- $line
  doc="${1:-}"; src="${2:-}"
  if [ -z "$doc" ] || [ -z "$src" ]; then continue; fi
  s="${src%/}"
  hit=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if covered_by "$f" "$s"; then hit=1; break; fi
  done <<< "$changed"
  [ "$hit" -eq 1 ] || continue
  implicated=$((implicated + 1))
  lu="$(sed -nE 's/^last_updated:[[:space:]]*([0-9-]+).*/\1/p' "$doc" 2>/dev/null | head -n1)"
  src_epoch="$(git log -1 --format=%ct -- "$s" 2>/dev/null || echo 0)"
  lu_epoch="$(epoch_of "${lu:-1970-01-01}")"
  if [ "${src_epoch:-0}" -gt "${lu_epoch:-0}" ]; then
    echo "  [review] $doc ← $src  (last_updated ${lu:-none} predates the change)"
  else
    echo "  [check ] $doc ← $src  (last_updated ${lu:-none}; touched around the change — verify)"
  fi
done <<< "$map"
[ "$implicated" -eq 0 ] && echo "  (none — no mapped source changed in this window)"
echo

# ── 4. changed paths not covered by any map entry → suggested map lines ──────
# docs/ (the KB itself) and .git/ are not "source that a doc describes", so they
# never warrant a STALENESS_MAP entry — skip them to keep suggestions signal-rich.
echo "Changed paths NOT covered by STALENESS_MAP (consider mapping):"
uncovered_dirs=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    docs/*|.git/*) continue ;;
  esac
  cov=0
  for s in $map_sources; do
    if covered_by "$f" "$s"; then cov=1; break; fi
  done
  [ "$cov" -eq 1 ] && continue
  d="$(dirname "$f")"
  [ "$d" = "." ] && d="$f"
  case " $uncovered_dirs " in
    *" $d "*) : ;;
    *) uncovered_dirs="$uncovered_dirs $d" ;;
  esac
done <<< "$changed"

if [ -z "$uncovered_dirs" ]; then
  echo "  (none — every changed path is already mapped or is KB-internal)"
else
  for d in $uncovered_dirs; do
    echo "  $d  → if a doc describes this, add to STALENESS_MAP in $DRIFT_SCRIPT:"
    echo "        docs/<the-doc-that-describes-it>.md $d"
  done
fi
echo

echo "Next: open [review] docs, verify against the code, and bump last_updated;"
echo "add STALENESS_MAP lines for suggested paths a doc really describes; then run"
echo "$DRIFT_SCRIPT to validate. This report changes nothing on its own."
exit 0
