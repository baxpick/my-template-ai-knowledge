---
last_updated: 2026-07-07
scope: The full map of every agentic tool's entrypoint and how each is redirected to AGENTS.md.
read_when: Adding/removing a per-tool adapter, onboarding a new agentic tool, or debugging why a tool ignores AGENTS.md.
---
# Per-tool adapters — one entrypoint, every agent lands on AGENTS.md

`AGENTS.md` (repo root) is THE single source of agent instructions. This file
records, for every agentic tool we know of, **what file that tool reads first**
and **how we guarantee it ends up at `AGENTS.md`**. The rule:

- **If a tool reads `AGENTS.md` natively** (as its primary or merged context),
  ship NOTHING for it — a redundant file would just drift. It is listed as
  "native" below.
- **If a tool does NOT read `AGENTS.md` first** (its own file wins, or it never
  reads `AGENTS.md`), ship a **shallow pointer**: the smallest possible file at
  that tool's entrypoint whose only job is to redirect to `AGENTS.md`. Never a
  copy of the rules.

`scripts/kb/check_docs_drift.sh` enforces this: any adapter that exists but does
NOT reference `AGENTS.md` fails the build.

## Adapters we SHIP (tool does not read AGENTS.md first → shallow pointer)

| Tool | Entrypoint (current) | How it points to AGENTS.md |
|---|---|---|
| Claude Code | `CLAUDE.md` (root) | first line `@AGENTS.md` — documented import that inlines it |
| Gemini CLI | `.gemini/settings.json` | `{ "context": { "fileName": "AGENTS.md" } }` |
| Aider | `.aider.conf.yml` | `read: AGENTS.md` |
| Amazon Q (IDE) | `.amazonq/rules/*.md` | prose pointer rule (Q CLI reads AGENTS.md; the IDE does not) |
| JetBrains Junie | `.junie/guidelines.md` | prose pointer |
| Continue.dev | `.continue/rules/*.md` | prose pointer (`alwaysApply: true`) |
| Tabnine | `.tabnine/guidelines/*.md` | prose pointer |
| Firebase Studio | `.idx/airules.md` | prose pointer (its own file has higher precedence than AGENTS.md) |

Each shipped pointer is tiny and self-describing — delete the ones for tools your
team never uses. If you delete a pointer, nothing breaks: the tool simply falls
back to whatever it does natively.

## Native — NO file needed (tool reads AGENTS.md first / merges it)

Leave these file-less. Adding a per-tool file would only create drift.

| Tool | Reads | Notes |
|---|---|---|
| OpenAI Codex CLI | `AGENTS.md` | originated the format; nested + root merge |
| GitHub Copilot | `AGENTS.md` | merges it with any `.github/copilot-instructions` file; nearest wins |
| Cursor | `AGENTS.md` | plus optional scoped `.cursor/rules/*.mdc`; legacy `.cursorrules` deprecated |
| Windsurf / Devin Desktop | `AGENTS.md` | rules dir `.windsurf/rules/` (or `.devin/rules/`); legacy `.windsurfrules` deprecated |
| Cline | `AGENTS.md` | plus optional `.clinerules/` dir |
| Roo Code | `AGENTS.md` | on by default; fallback `.roo/rules/`, legacy `.roorules` |
| Zed | `AGENTS.md` | first-match list; also reads `.rules` / `AGENT.md` if present |
| Kilo Code | `AGENTS.md` | primary file; legacy `.kilocoderules` auto-migrated |
| Warp | `AGENTS.md` | must be ALL-CAPS; legacy `WARP.md` still wins if present |
| Amp | `AGENTS.md` | supports `@`-mention imports of other docs |
| goose | `AGENTS.md` | default context file; also reads `.goosehints` |
| OpenHands | `AGENTS.md` | recommended permanent context |
| Jules (Google) | `AGENTS.md` | auto-read at repo root |
| Devin (Cognition) | `AGENTS.md` | root + directory-scoped |

If your org standard forces one of these tools to have its own file anyway (e.g.
a mandated `.github/copilot-instructions` file), make it a one-line pointer —
"Follow the instructions in AGENTS.md." — so the drift check passes and nothing
diverges.

## Deprecated / legacy formats (do NOT create new ones)

Single-file legacy rule files have been superseded by directory formats or by
native `AGENTS.md`. If a brownfield repo has one, fold its content into
`AGENTS.md` / `docs/` and delete it (see `docs/ai-doc-solution-maker.md` §2):

- `.cursorrules` → `.cursor/rules/*.mdc` (or just `AGENTS.md`)
- `.windsurfrules` → `.windsurf/rules/*.md` / `.devin/rules/*.md` (or `AGENTS.md`)
- `.roorules` / `.kilocoderules` → their `*/rules/` dirs (or `AGENTS.md`)

## How the drift check enforces this

`scripts/kb/check_docs_drift.sh` checks two sets:

- **Single-file adapters** — if present, must reference `AGENTS.md`; `CLAUDE.md`
  additionally must start with the `@AGENTS.md` import.
- **Directory rule adapters** — every `*.md` / `*.mdc` under a known rules dir
  (`.amazonq/rules/`, `.continue/rules/`, `.cursor/rules/`, `.windsurf/rules/`,
  `.devin/rules/`, `.roo/rules/`, `.clinerules/`, `.tabnine/guidelines/`,
  `.github/instructions/`) must reference `AGENTS.md`.

## Adding a new tool

1. Find the tool's current entrypoint (its docs, or https://agents.md/).
2. If it reads `AGENTS.md` first → add a "native" row here, ship nothing.
3. Otherwise → ship the smallest pointer at its entrypoint and add its path to
   the adapter list in `scripts/kb/check_docs_drift.sh` (single-file or glob) so
   the pointer is enforced. Add the cleanup path to `init.sh` too.
