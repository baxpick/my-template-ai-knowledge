#!/usr/bin/env bash
#
# init.sh — reset & (re)initialize the AI knowledge base in a target repo.
#
# Usage (from the ROOT of the target repo):
#   curl -fsSL https://raw.githubusercontent.com/baxpick/my-template-ai-knowledge/main/init.sh -o /tmp/kb-init.sh
#   bash /tmp/kb-init.sh
#
# What it does:
#   1. Removes every file the template ships AND every file a previous
#      "implement the ai-doc solution" run generated (root/nested AGENTS.md,
#      CLAUDE.md, docs/ KB tree, scripts/kb/, per-tool adapters).
#   2. Copies a fresh checkout of the template into the repo root.
#   3. You then prompt your agent: "implement the ai-doc solution".
#
# Options:
#   --clean-only   only remove files, do not copy the fresh template
#   --yes | -y     do not ask for confirmation
#
# Env:
#   TEMPLATE_REPO  clone URL or local path of the template repo
#                  (default: https://github.com/baxpick/my-template-ai-knowledge.git)
#   TEMPLATE_REF   branch/tag to fetch (default: main)
#
# Portability: runs on both macOS (BSD userland — bash 3.2, BSD find/tar) and
# Ubuntu/Linux (GNU coreutils). find -mindepth, tar --exclude and mktemp -d all
# behave the same on both; no GNU-only flags are used.

set -euo pipefail

TEMPLATE_REPO="${TEMPLATE_REPO:-https://github.com/baxpick/my-template-ai-knowledge.git}"
TEMPLATE_REF="${TEMPLATE_REF:-main}"

CLEAN_ONLY=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --clean-only) CLEAN_ONLY=1 ;;
    --yes|-y)     ASSUME_YES=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

err()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

# ---------------------------------------------------------------------------
# Safety checks
# ---------------------------------------------------------------------------
[[ -e .git ]] || err "run this from the ROOT of a git repository (deleted files stay recoverable via git)."

# ---------------------------------------------------------------------------
# 1. Collect everything to delete
# ---------------------------------------------------------------------------
# Well-known KB directories under docs/ (template seeds + generated content).
DOC_DIRS=(docs/architecture docs/conventions docs/decisions docs/runbooks docs/reference)
# Well-known single files (template + per-tool adapters the KB setup creates).
KB_FILES=(
  AGENTS.md
  CLAUDE.md
  TEMPLATE-nested-AGENTS.md
  GEMINI.md
  .cursorrules
  .windsurfrules
  .clinerules
  .aider.conf.yml
  docs/INDEX.md
  docs/TEMPLATE.md
  docs/ai-doc-solution-maker.md
)

targets=()

for f in "${KB_FILES[@]}"; do
  [[ -e "$f" ]] && targets+=("$f")
done

for d in "${DOC_DIRS[@]}"; do
  [[ -d "$d" ]] && targets+=("$d/")
done

[[ -d scripts/kb ]] && targets+=("scripts/kb/")

# Gemini adapter: only if it is the KB-generated pointer to AGENTS.md.
if [[ -f .gemini/settings.json ]] && grep -q 'AGENTS.md' .gemini/settings.json; then
  targets+=(".gemini/settings.json")
fi

# Directory-based per-tool adapters (see docs/reference/agent-adapters.md). Each
# is removed ONLY when it is the KB-generated SHALLOW POINTER (references
# AGENTS.md) — never a user's real tool config that happens to share the path.
GUARDED_ADAPTERS=(
  .amazonq/rules/use-agents-md.md
  .junie/guidelines.md
  .continue/rules/use-agents-md.md
  .tabnine/guidelines/use-agents-md.md
  .idx/airules.md
  .github/copilot-instructions.md
)
for a in "${GUARDED_ADAPTERS[@]}"; do
  if [[ -f "$a" ]] && grep -q 'AGENTS.md' "$a"; then
    targets+=("$a")
  fi
done

# Nested AGENTS.md files anywhere in the tree, skipping .git, node_modules and
# nested git repos/submodules (they own their files).
while IFS= read -r f; do
  targets+=("${f#./}")
done < <(find . -mindepth 2 \
           \( -name .git -o -name node_modules \) -prune -o \
           \( -type d -exec test -e '{}/.git' \; \) -prune -o \
           -type f -name AGENTS.md -print)

if [[ ${#targets[@]} -eq 0 ]]; then
  info "nothing to clean (no template/KB files found)."
else
  echo
  echo "The following template/KB files will be DELETED:"
  printf '  %s\n' "${targets[@]}"
  echo
  if [[ $ASSUME_YES -ne 1 ]]; then
    read -r -p "Proceed? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
  fi
  for t in "${targets[@]}"; do
    rm -rf -- "$t"
  done
  # Drop now-empty parents (adapter dirs + KB dirs). rmdir is a no-op if the dir
  # still holds a user's own files, so this never clobbers non-KB content.
  rmdir .amazonq/rules .amazonq .continue/rules .continue \
        .tabnine/guidelines .tabnine .junie .idx .gemini 2>/dev/null || true
  rmdir docs scripts 2>/dev/null || true
  info "clean done."
fi

# ---------------------------------------------------------------------------
# 2. Copy a fresh template checkout
# ---------------------------------------------------------------------------
if [[ $CLEAN_ONLY -eq 1 ]]; then
  info "--clean-only: skipping template copy. Done."
  exit 0
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

info "fetching template ($TEMPLATE_REPO @ $TEMPLATE_REF) ..."
git clone --quiet --depth 1 --branch "$TEMPLATE_REF" "$TEMPLATE_REPO" "$tmpdir/tpl"

info "copying template files into $(pwd) ..."
(cd "$tmpdir/tpl" && tar cf - --exclude .git --exclude init.sh .) | tar xf -

info "done. Now prompt your agent: \"implement the ai-doc solution\""
