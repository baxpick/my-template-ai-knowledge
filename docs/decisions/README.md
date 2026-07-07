# Architecture Decision Records (ADRs)

Short, numbered, **append-only** records of decisions that shape the repo. Agents
trust documentation absolutely — recording *why* prevents future sessions from
undoing deliberate choices.

## Rules
- One file per decision: `NNNN-kebab-title.md` (zero-padded, e.g. `0001-...`).
- Append-only: never rewrite history. To change a decision, add a new ADR and set
  the old one's status to `Superseded by NNNN`.
- Statuses: `Proposed` → `Accepted` → `Superseded` (or `Rejected`).
- Copy `0000-template.md` to start a new one; pick the next free number. Or run
  `scripts/kb/new_adr.sh "<title>"` to create the next-numbered ADR and index it
  automatically.

## Template
See [0000-template.md](0000-template.md).

## Index
<!-- Add one line per ADR, newest last. -->
| # | Title | Status |
|---|---|---|
| 0000 | Template (not a real decision) | — |
