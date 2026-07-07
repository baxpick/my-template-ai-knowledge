#!/usr/bin/env bash
#
# check_docs_drift.sh — verify the knowledge base is internally consistent.
#
# Hard failures (exit 1): broken relative .md links; any per-tool adapter — a
#   single-file one (CLAUDE.md, GEMINI.md, AGENT.md, .cursorrules, .windsurfrules,
#   .clinerules, .roorules, .goosehints, WARP.md, .aider.conf.yml,
#   .gemini/settings.json, .junie/guidelines.md, .idx/airules.md,
#   .github/copilot-instructions.md) OR a directory rule file (anything under
#   .amazonq/rules/, .continue/rules/, .cursor/rules/, .windsurf/rules/,
#   .devin/rules/, .roo/rules/, .clinerules/, .tabnine/guidelines/,
#   .github/instructions/) — that does NOT point back to AGENTS.md; a file larger
#   than its hard size cap; a STALENESS_MAP entry whose doc or source path no
#   longer exists. The full tool→entrypoint map is docs/reference/agent-adapters.md.
# Soft warnings (exit 0): recommended size caps, missing frontmatter, unreplaced
#   ⟨…⟩ placeholders, missing CLAUDE.md shim, staleness heuristic, orphan docs.
#
# This is general tooling — it makes no assumptions about the project's domain.
# Repos with an enumerable, auto-discoverable set of units can additionally add a
# generator script + an inventory-drift diff here (see the STALENESS MAP note).
#
# Portability: works on both macOS (BSD userland — bash 3.2, BSD date/sed/grep)
# and Ubuntu/Linux (GNU coreutils). Where the two diverge (date parsing) we probe
# GNU first, then fall back to BSD. No associative arrays (bash 3.2 lacks them).
#
# Testability: the unit tests source this file with DRIFT_LIB_ONLY=1 to load the
# functions WITHOUT running the checks (see the testability hook below). Nothing
# else should ever set that variable.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

FAIL=0
warn() { printf 'WARN:  %s\n' "$*"; }
fail() { printf 'FAIL:  %s\n' "$*"; FAIL=1; }
ok()   { printf 'OK:    %s\n' "$*"; }

# Parse YYYY-MM-DD portably: GNU date (Ubuntu/Linux) first, then BSD/macOS date.
epoch_of() {
  date -d "$1" +%s 2>/dev/null \
    || date -j -f "%Y-%m-%d" "$1" +%s 2>/dev/null \
    || echo 0
}

# Strip HTML comments so illustrative prose paths inside <!-- --> are ignored.
# Uses perl when present (both macOS and Ubuntu ship it); falls back to sed.
strip_comments() {
  if command -v perl >/dev/null 2>&1; then
    perl -0777 -pe 's/<!--.*?-->//gs' "$1"
  else
    sed '/<!--/,/-->/d' "$1"
  fi
}

# Broken relative .md links in one file. A "reference" is either a markdown-link
# target (]...(target)) or a slash-containing token ending in .md. A reference is
# valid if it resolves relative to the file OR to the repo root, so root-relative
# prose mentions don't false-positive. Skip URLs and template placeholders.
check_links_in() {
  local file="$1" dir; dir="$(dirname "$file")"
  local body; body="$(strip_comments "$file")"
  local candidates
  candidates="$(
    {
      printf '%s\n' "$body" | grep -oE '\]\([^)]+\.md[^)]*\)' | sed -E 's/^\]\(//; s/\)$//'
      printf '%s\n' "$body" | grep -oE '(\.\./)*[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+\.md'
    } 2>/dev/null | sort -u
  )"
  local ref target
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    case "$ref" in
      http*|*"<"*|*"*"*|*"⟨"*) continue ;;
    esac
    target="${ref%%#*}"                 # strip anchor
    if [ -e "$dir/$target" ] || [ -e "$REPO_ROOT/$target" ]; then
      :
    else
      fail "broken link in $file → $ref"
    fi
  done <<< "$candidates"
}

# Soft size guard: warn past the recommended cap, FAIL past the hard cap. The
# recommended caps are the documented KB standard (AGENTS.md is a map, not an
# encyclopedia); the hard cap catches egregious growth a warning would let slide.
guard_size() {
  local file="$1" soft="$2" hard="$3" n
  [ -f "$file" ] || return 0
  n="$(wc -l < "$file")"
  if [ "$n" -gt "$hard" ]; then
    fail "$file is $n lines (hard cap $hard — split it; keep it a map, not an encyclopedia)"
  elif [ "$n" -gt "$soft" ]; then
    warn "$file is $n lines (soft cap $soft)"
  fi
}

# Per-tool adapter guard. AGENTS.md is the ONE entry point; every other tool's
# file must be a SHALLOW pointer to it, never a copy of the rules — so every
# adapter is treated identically. If an adapter exists but does not reference
# AGENTS.md it will silently diverge → FAIL. CLAUDE.md is stricter: its first
# lines must be the '@AGENTS.md' import Claude Code inlines (a prose mention is
# not guaranteed to be followed). Only regular files are checked (a rules DIR is
# handled by the glob loop over its contents). Works the same on macOS and Ubuntu.
check_adapter() {
  local file="$1"
  [ -f "$file" ] || return 0
  if [ "$file" = "CLAUDE.md" ]; then
    head -n 3 "$file" | grep -q '^@AGENTS\.md' \
      || fail "CLAUDE.md must start with the '@AGENTS.md' import — otherwise it diverges from AGENTS.md"
    return 0
  fi
  grep -q 'AGENTS\.md' "$file" \
    || fail "$file exists but does not point to AGENTS.md — make it a shallow pointer to the single entry point (see docs/reference/agent-adapters.md), or delete it"
}

# ── Testability hook ────────────────────────────────────────────────────────
# When sourced by the unit tests with DRIFT_LIB_ONLY=1, expose the functions
# above but skip the checks below. Harmless when executed normally: the variable
# is unset, so this is a no-op. Works on macOS (bash 3.2) and Ubuntu/Linux.
if [ -n "${DRIFT_LIB_ONLY:-}" ]; then return 0 2>/dev/null || exit 0; fi

set -uo pipefail
cd "$REPO_ROOT"

# ── 1. Broken relative .md links ────────────────────────────────────────────
# Scan the root AGENTS.md, every nested AGENTS.md, and all docs/**/*.md.
scan_files=""
while IFS= read -r f; do scan_files="$scan_files"$'\n'"$f"; done < <(
  {
    find . -name 'AGENTS.md' -not -path './.git/*' 2>/dev/null
    find docs -name '*.md' 2>/dev/null
  } | sed 's|^\./||' | sort -u
)
while IFS= read -r f; do
  [ -f "$f" ] && check_links_in "$f"
done <<< "$scan_files"
[ "$FAIL" -eq 0 ] && ok "all relative .md links resolve"

# ── 2. Size guards (warn past recommended cap, FAIL past hard cap) ───────────
# Recommended caps are the documented KB standard; the hard cap (soft × 1.5) is
# a safety net so an overlooked warning can't let the map bloat without bound.
guard_size AGENTS.md 150 225
guard_size docs/INDEX.md 60 90

# ── 3. Frontmatter presence (warn only) ─────────────────────────────────────
# Every knowledge doc needs last_updated/scope/read_when so agents can judge
# relevance and staleness without reading the body. ADRs are exempt (they carry
# Date/Status inline).
while IFS= read -r f; do
  case "$f" in docs/decisions/*) continue ;; esac
  if ! head -n 8 "$f" | grep -q '^last_updated:'; then
    warn "$f is missing frontmatter (last_updated/scope/read_when)"
  else
    lu="$(sed -nE 's/^last_updated:[[:space:]]*([0-9-]+).*/\1/p' "$f" | head -n1)"
    if [ -n "$lu" ] && [ "$(epoch_of "$lu")" -gt "$(date +%s)" ]; then
      warn "$f last_updated ($lu) is in the future — use today's date"
    fi
  fi
done < <(find docs -name '*.md' 2>/dev/null)

# ── 4. Setup leftovers (warn only) ──────────────────────────────────────────
# ⟨…⟩ marks "must be replaced during setup". Warns (not fails) so the pristine
# template itself still passes CI; after tailoring, none should remain.
# docs/ai-doc-solution-maker.md is exempt: it documents the marker itself.
leftovers="$(grep -rln '⟨' --include='*.md' . 2>/dev/null \
  | grep -v '^\./\.git/' | grep -v '^\./docs/ai-doc-solution-maker\.md$' || true)"
if [ -n "$leftovers" ]; then
  while IFS= read -r f; do
    warn "unreplaced ⟨…⟩ placeholders in $f (KB not fully tailored yet?)"
  done <<< "$leftovers"
fi

# ── 5. Trigger phrases must survive tailoring ───────────────────────────────
# "implement/update the ai-doc solution" only work if the mapping is visible in
# the always-loaded AGENTS.md. Tailoring agents have dropped it before.
if [ -f AGENTS.md ]; then
  grep -q '"update the ai-doc solution"' AGENTS.md \
    || fail 'AGENTS.md lost the "Trigger phrases" section — restore it from the template (agents will treat "update the ai-doc solution" as vague)'
fi

# ── 6. Per-tool adapter guards ──────────────────────────────────────────────
# AGENTS.md is the single source of instructions. Per-tool files are allowed
# ONLY as a shallow pointer to it — and are ALL treated identically (CLAUDE.md
# included). Any adapter that does not reference AGENTS.md diverges → FAIL. The
# authoritative tool→entrypoint map is docs/reference/agent-adapters.md; add new
# tools to BOTH lists below as they appear.
#
# Single-file adapters (checked directly). Includes current entrypoints and
# deprecated single-file rule formats so a brownfield leftover is caught too.
for adapter in CLAUDE.md GEMINI.md AGENT.md \
               .cursorrules .windsurfrules .clinerules .roorules .goosehints \
               WARP.md .aider.conf.yml .gemini/settings.json \
               .junie/guidelines.md .idx/airules.md \
               .github/copilot-instructions.md; do
  check_adapter "$adapter"
done
# Directory rule adapters: every rule file present under a known rules dir must
# point to AGENTS.md. Refs containing '*' are literal patterns that matched
# nothing (no such dir) — the [ -f ] guard in check_adapter skips them.
for pattern in .amazonq/rules/*.md .continue/rules/*.md .cursor/rules/*.mdc \
               .windsurf/rules/*.md .devin/rules/*.md .roo/rules/*.md \
               .clinerules/*.md .tabnine/guidelines/*.md \
               .github/instructions/*.md; do
  for f in $pattern; do
    check_adapter "$f"
  done
done
[ -f CLAUDE.md ] || warn "no CLAUDE.md import shim (Claude Code will not see AGENTS.md)"

# ── 7. Staleness heuristic + STALENESS_MAP validity ─────────────────────────
# Map a doc to a path (file or dir) of the source it describes. RULES (agents
# MUST keep this current — see docs/ai-doc-solution-maker.md and
# docs/runbooks/kb-review.md):
#   (a) COMPLETE  — every doc that describes a specific source path is listed.
#   (b) VALID     — no entry points at a doc/source that does not exist.
#   (c) CURRENT   — when a mapped file is renamed/removed/added, update the map.
# A stale entry (missing doc OR missing source) is a FAIL, so renames/removals
# are caught here rather than silently rotting. When a mapped source changed in
# git >30 days after the doc's last_updated, warn. One "doc source" pair per line
# (plain list, not an associative array — macOS ships bash 3.2). Example line:
#   docs/architecture/overview.md src/
# Tip: `scripts/kb/kb_review_worklist.sh` reads this map and, from recent git
# history, suggests entries to ADD here for changed paths nothing maps yet.
STALENESS_MAP="
"
HAVE_GIT=0
if command -v git >/dev/null 2>&1 && git rev-parse >/dev/null 2>&1; then HAVE_GIT=1; fi
while read -r doc src; do
  [ -z "$doc" ] && continue
  if [ -z "$src" ]; then
    fail "STALENESS_MAP entry '$doc' has no source path — each line must be 'doc source'"
    continue
  fi
  if [ ! -f "$doc" ]; then
    fail "STALENESS_MAP lists doc '$doc' which no longer exists — update the map (renamed or removed?)"
    continue
  fi
  if [ ! -e "$src" ]; then
    fail "STALENESS_MAP maps '$doc' → '$src' but that source path no longer exists — update the map (renamed or removed?)"
    continue
  fi
  [ "$HAVE_GIT" -eq 1 ] || continue
  lu="$(sed -nE 's/^last_updated:[[:space:]]*([0-9-]+).*/\1/p' "$doc" | head -n1)"
  [ -z "$lu" ] && continue
  src_epoch="$(git log -1 --format=%ct -- "$src" 2>/dev/null || echo 0)"
  lu_epoch="$(epoch_of "$lu")"
  if [ "$src_epoch" -gt 0 ] && [ "$lu_epoch" -gt 0 ]; then
    delta=$(( (src_epoch - lu_epoch) / 86400 ))
    [ "$delta" -gt 30 ] && warn "$doc may be stale: $src changed ~$delta days after last_updated ($lu)"
  fi
done <<< "$STALENESS_MAP"

# ── 8. Orphan / unrouted docs (warn only) ───────────────────────────────────
# A knowledge doc nobody routes to from docs/INDEX.md is undiscoverable, which is
# how first-pass coverage gaps hide. A doc counts as "routed" if its path OR its
# parent dir (e.g. runbooks/) appears in INDEX.md. Exempt: INDEX itself, TEMPLATE,
# ai-doc-solution-maker, and ADRs (indexed separately in decisions/README.md).
if [ -f docs/INDEX.md ]; then
  idx="$(cat docs/INDEX.md)"
  while IFS= read -r f; do
    rel="${f#docs/}"
    case "$rel" in
      INDEX.md|TEMPLATE.md|ai-doc-solution-maker.md|decisions/*) continue ;;
    esac
    dir="$(dirname "$rel")/"
    if ! printf '%s' "$idx" | grep -qF "$rel" && ! printf '%s' "$idx" | grep -qF "$dir"; then
      warn "$f is not routed from docs/INDEX.md (add a row so agents can find it)"
    fi
  done < <(find docs -name '*.md' 2>/dev/null | sed 's|^\./||')
fi

echo
if [ "$FAIL" -ne 0 ]; then
  echo "Drift check FAILED."
  exit 1
fi
echo "Drift check passed."
