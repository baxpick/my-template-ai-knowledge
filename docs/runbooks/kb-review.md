---
last_updated: 2026-07-05
scope: The full knowledge-base sweep — verify every doc AND hunt for coverage gaps.
read_when: A human says "update the ai-doc solution", or a periodic KB health review is due.
---
# Runbook: KB Sweep ("update the ai-doc solution")

A recurring (e.g. monthly) or on-demand session that keeps the knowledge base
honest and complete. A human triggers it with the phrase **"update the ai-doc
solution"**; the agent executes. Do NOT fully automate this yet — it starts as
a human-triggered prompt and can later be wired to a scheduled-agent feature.

The sweep has two halves: **verify what exists** and **find what is missing**.

## Part A — verify existing docs
1. Run `scripts/kb/kb_review_worklist.sh [DAYS]` first for a targeted worklist —
   the docs recent commits implicate (via `STALENESS_MAP`) plus changed paths
   nothing maps yet. Pass a window reaching back to the last sweep (e.g. `30` for
   monthly; over-shoot when unsure). Then run `scripts/kb/check_docs_drift.sh` and
   note every warning/failure.
2. Walk `docs/INDEX.md` top to bottom; open each linked file; compare it to the
   code/config it describes (read the real files — never trust the doc).
3. Fix stale content; bump `last_updated` on every edited file; merge duplicate
   or overlapping docs.
4. Verify every nested `AGENTS.md` still matches its directory's reality.
5. Propose (don't silently delete) obsolete files to the human.

## Part B — find coverage gaps
6. Re-investigate the repo the way `../ai-doc-solution-maker.md` §2 describes (areas,
   commands, procedures, secrets handling, related repos) and compare against
   `docs/INDEX.md`: anything real with no routing row is a gap.
7. Commands drift: do the commands in the root `AGENTS.md` still match the
   repo's manifests/Makefiles/CI? Fix mismatches.
8. New/changed subsystems with their own contract → add or update a nested
   `AGENTS.md`. Repeatable procedures done by hand recently → add a runbook.
   Decisions made but never recorded → add ADRs. Any doc that maps to a source
   path that was renamed/removed/added → update the `STALENESS_MAP` in
   `scripts/kb/check_docs_drift.sh` so it stays complete and valid (the Part A
   worklist's "consider mapping" suggestions list changed paths not yet mapped).
9. Slight improvements are in scope: sharpen vague rules, make commands exact,
   split docs that grew past ~200 lines, tighten `read_when` lines.

## Loop until stable
Repeat Part A + Part B until a full pass finds no new drift and no new gaps.
One pass usually misses things — do not stop after the first.

## Finish
10. Re-run `scripts/kb/check_docs_drift.sh` until it exits 0.
11. **Do NOT commit or push.** Leave every changed/created file uncommitted so the
    human can review and commit manually.
12. Report to the human: what was fixed, what was added, what is proposed for
    deletion, and any open questions.
