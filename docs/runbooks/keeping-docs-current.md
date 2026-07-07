---
last_updated: 2026-07-05
scope: The checklist to run after any change so docs ship with the code.
read_when: The END of every task that changed files.
---
# Keeping docs current

Run this before you consider any change done — doc updates belong to the SAME
change set as the code that made them necessary, never "later". Do NOT commit or
push: leave the doc edits uncommitted alongside your code changes so the human
reviews and commits everything together.

1. List what you changed (files + behavior).
2. Open `docs/INDEX.md`; for every row whose files describe what you changed,
   update that file: fix the content and bump its `last_updated`.
3. New design decision or deviation from a convention → add an ADR
   (`scripts/kb/new_adr.sh "<title>"` picks the next number and indexes it; or copy
   `../decisions/0000-template.md` and add a row to `../decisions/README.md`).
4. New knowledge needed → add a doc (`scripts/kb/new_doc.sh <path> "<scope>"
   "<read_when>"`, or copy `../TEMPLATE.md`) and add a routing row to
   `docs/INDEX.md`.
5. New repeatable procedure you performed by hand → add a runbook here under
   `docs/runbooks/` (copy `../TEMPLATE.md`).
6. If you renamed, removed, or added a doc that maps to a specific source path,
   update the `STALENESS_MAP` in `scripts/kb/check_docs_drift.sh` to match. Then
   run `scripts/kb/check_docs_drift.sh`; fix every failure. Leave all changes
   uncommitted for the human to commit.
