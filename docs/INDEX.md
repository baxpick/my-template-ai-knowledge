---
last_updated: 2026-07-05
scope: Router mapping task types to knowledge files.
read_when: Start of any non-trivial task.
---
# Knowledge Base Index

Read the row that matches your task, then open only the listed file(s). Paths are
relative to this `docs/` directory. Add/rename rows as the KB grows — keep each to
one line and keep this file small (it is read often).

| If your task involves… | Read |
|---|---|
| Understanding the whole system | architecture/overview.md |
| Project conventions & workflow | conventions/conventions.md |
| A recurring operational procedure | runbooks/ (pick the matching runbook) |
| Something is broken | runbooks/troubleshooting.md |
| Updating docs after a change | runbooks/keeping-docs-current.md |
| "update the ai-doc solution" / periodic KB sweep | runbooks/kb-review.md |
| Why is X designed this way? / changing a past design | decisions/README.md (ADR index) |
| Setting up / tailoring this knowledge base itself | ai-doc-solution-maker.md |
| ⟨add repo-specific task → doc rows here⟩ | ⟨path.md⟩ |

Rule: if you changed anything a file above describes, update that file before
finishing (see runbooks/keeping-docs-current.md). To add a new knowledge doc,
copy TEMPLATE.md.
