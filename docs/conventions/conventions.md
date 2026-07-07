---
last_updated: 2026-07-05
scope: Project conventions and workflow rules an agent must follow.
read_when: Making changes; committing; anything touching shared conventions.
---
# Conventions

<!-- Seed doc for the "conventions" category. Split into multiple files under
     conventions/ (e.g. secrets, git-workflow, <domain>-contract) as it grows,
     and add routing rows in ../INDEX.md. Rules only — enforce style via linters,
     not prose. Never write secret VALUES here, only the rules for handling them. -->

## Secrets & environment
⟨Where secrets live, what is git-ignored, how the app receives them. Rules only.⟩

## Git & workflow
⟨Commit/branch conventions, submodule handling, what may/may not be committed.⟩

## Domain conventions
⟨Repo-specific contracts a change must honor. Cross-link the relevant nested
AGENTS.md and any skills that automate the procedure.⟩
