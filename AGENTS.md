# ⟨PROJECT NAME⟩ — Agent Guide

<!--
  AGENTS.md is the cross-tool open standard read natively by Codex, Cursor,
  Copilot, Gemini, Windsurf, Aider, Zed, Amazon Q and others — it is THE single
  entry point, vendor-neutral by design. Keep it a MAP, not an encyclopedia:
  ≤150 lines, no code snippets, no style prose, pointers instead of copies.
  NOTE: some tools (e.g. Claude Code) STRIP HTML comments before loading this
  file — never put instructions the agent must act on inside a comment.
-->

> **NOT SET UP YET.** This repo still has ⟨…⟩ placeholders: the knowledge base
> has not been tailored to this repo. When a human says **"implement the ai-doc
> solution"** (or asks to set up / bootstrap the knowledge base), follow the
> complete, self-contained guide in `docs/ai-doc-solution-maker.md`, replace every
> ⟨…⟩ below, and DELETE this block. (This must stay visible markdown, not an
> HTML comment — some tools strip comments before the agent sees them.)

⟨One-paragraph project identity: what this repo is, what it does, and the single
most important fact an agent must know before touching it.⟩

## Trigger phrases — KEEP THIS SECTION VERBATIM, even after tailoring
These exact human phrases are commands, not vague requests. On hearing one, do
NOT ask for clarification — act immediately:
- **"implement the ai-doc solution"** — tailor this knowledge base to this repo:
  follow docs/ai-doc-solution-maker.md end to end.
- **"update the ai-doc solution"** — run the full knowledge-base sweep: follow
  docs/runbooks/kb-review.md end to end.

## Golden rules
1. NEVER commit secrets, keys or certs. Keep secret-bearing files git-ignored.
2. Update the knowledge base in the SAME session as any change. A change is not
   done until docs match reality — see docs/runbooks/keeping-docs-current.md.
3. Prefer editing existing patterns over inventing new ones; if you must deviate,
   record why in a new ADR under docs/decisions/.
4. The closest AGENTS.md to the file you are editing wins — check for a nested
   one before acting in a subdirectory.
5. Destructive or irreversible operations require explicit human confirmation.

## Commands
<!-- The handful of commands that matter most. Exact invocations, no prose.
     Keep only the ones that exist; add/rename freely. -->
- Build: ⟨exact command⟩
- Test: ⟨exact command⟩
- Lint: ⟨exact command⟩
- Run: ⟨exact command⟩
- Check docs drift: `scripts/kb/check_docs_drift.sh`
- KB review worklist: `scripts/kb/kb_review_worklist.sh [DAYS]` (which docs recent commits made stale)

## Knowledge base — read before acting
docs/INDEX.md is the routing table: it maps task types to the files you must
read. Read it first for any non-trivial task. Never guess architecture or
conventions — they are written down. If a doc contradicts the code, fix the doc
in the same session and flag it.

## Keeping docs current (your responsibility)
After any change, run the checklist in docs/runbooks/keeping-docs-current.md.
At minimum: changed behavior a docs/** file describes → update that file and
bump its `last_updated`; made a design decision → add an ADR.

## Repo layout
<!-- One line per top-level area an agent will touch. Note nested AGENTS.md files. -->
- docs/ — knowledge base (start at docs/INDEX.md)
- scripts/kb/ — knowledge-base tooling (drift checker + doc/ADR scaffolders)
- ⟨`path/to/area/` — one-line description; note if it has its own AGENTS.md⟩
