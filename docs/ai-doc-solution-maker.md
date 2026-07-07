---
last_updated: 2026-07-05
scope: The one-time guide to tailor this generic knowledge-base skeleton to THIS repo.
read_when: Asked to set up / implement / bootstrap the knowledge base ("implement the ai-doc solution").
---
# Solution Maker — build this repo's AI knowledge base

You are turning a **portable, vendor-neutral skeleton** into a knowledge base
tailored to THIS repository. Everything you need is in this file — it depends on
no external document. Work from the repo root and verify every fact by reading
the repo (never invent). Aim to finish COMPLETE in this one setup (see §3a) —
not "good enough for now". **Do NOT commit or push**: leave every changed/created
file uncommitted so the human can review and commit manually.

## 0. How this template is applied (for humans)
Copy the template's files (everything except its `.git/`) into the target
repo's root — greenfield or brownfield. Then, in any agentic tool, prompt:
**"implement the ai-doc solution"**. The agent lands on `AGENTS.md`, whose
visible "NOT SET UP YET" block routes it here. After setup, the trigger
**"update the ai-doc solution"** runs the recurring sweep
(`docs/runbooks/kb-review.md`). If the target repo already has an `AGENTS.md`
or `CLAUDE.md`, do not overwrite it blindly — keep both versions temporarily
and let the agent merge them (step 2 below).

## 1. Why this exists (the philosophy — follow it)
This is **context engineering** via **progressive disclosure**: a tiny, always-
loaded entry file is a table of contents; everything else loads on demand, only
when a task needs it. Non-negotiable principles:

- **`AGENTS.md` is a MAP, not an encyclopedia** (≤150 lines): identity, the few
  commands that matter, hard rules, and a pointer to `docs/INDEX.md`. It is the
  cross-tool open standard — every major agent reads it, so it is the ONE source
  of instructions. Do not fragment it into per-tool rule files.
- **Pointers, not copies.** Reference a doc with a one-line "read this when…".
  Knowledge lives in `docs/` ("cold memory"), one topic per file, each with
  frontmatter (`last_updated`, `scope`, `read_when`).
- **No code snippets in docs** — they rot; use `file:line` references. **No
  code-style prose** — enforce style with linters/CI, not sentences.
- **Decisions become ADRs** (`docs/decisions/`), append-only. Agents trust docs
  absolutely, so recording *why* stops a future agent from undoing a choice.
- **Critical "must never" rules become CI/hook gates**, not prose an agent may miss.
- **Docs are updated in the SAME session as the code** — see
  `docs/runbooks/keeping-docs-current.md`.
- **Closest `AGENTS.md` wins** — put area-specific rules in a nested `AGENTS.md`
  so the root map stays lean.

## 2. Investigate the repo first — build a written inventory (do not skip)
Read, don't guess. The #1 cause of an incomplete first pass is a shallow survey,
so treat this as an explicit discovery step and WRITE DOWN an inventory (a scratch
list is fine) that the build in §3 must then cover in FULL. Enumerate, from real
sources:
- **Identity & runtime** — what the project is, how/where it runs, its single most
  important architectural fact. Sources: README, manifests, entrypoints, Dockerfiles, CI.
- **Every command that matters** — build/test/lint/run/release/migrate/format.
  Sources: `package.json`/`pyproject.toml`/`go.mod`/`Makefile`/`justfile`/`Taskfile`,
  CI workflows, `scripts/`.
- **Every distinct area/subsystem** — walk the top-level tree and list each one.
  Each may deserve a nested `AGENTS.md` and/or a knowledge doc.
- **Every repeatable procedure** — deploy, release, seed, run a migration, rotate a
  secret, onboard. Each deserves a runbook.
- **Secrets/env/config** — where they live, what is git-ignored, how the app
  receives them (rules only, never a value).
- **Integrations** — submodules, sibling repos, external services, queues, datastores.
- **Decisions already made** — anything non-obvious worth an ADR (framework/data-model/
  auth choice, and the alternatives rejected).

**Brownfield: absorb existing agent instructions.** If the repo already has any
instruction files — a previous `AGENTS.md` or `CLAUDE.md`, `.cursorrules`,
`.windsurfrules`, a copilot-instructions file under `.github/`, `GEMINI.md`,
`.clinerules`, Cline memory-bank files, etc. — read them ALL first: they hold tribal
knowledge. Merge every still-true rule/fact into the new structure (root or
nested `AGENTS.md` for rules, `docs/` for knowledge, ADRs for decisions), then
DELETE the old files so nothing diverges. Same for human docs (README, wikis):
mine them for facts, but leave human-facing files in place — pointers, not
copies.

## 3. Build it — customize the skeleton
Each skeleton file carries inline instructions; this is the order:

1. **Root `AGENTS.md`** — replace every `⟨…⟩` (identity, golden rules, real
   commands, repo layout). Delete the HTML comments AND the visible "NOT SET
   UP YET" blockquote. Keep it ≤150 lines. **KEEP the "Trigger phrases"
   section verbatim** — it is what makes "update the ai-doc solution" work as a
   command after setup; dropping or rewording it breaks the trigger (agents
   will call the phrase "vague" and ask for clarification instead of acting).
2. **Knowledge docs** — for each real area, copy `docs/TEMPLATE.md` into the
   right category (`architecture/`, `conventions/`, `runbooks/`, `decisions/`, or
   a new folder), fill it FOR THE AGENT (concrete paths, exact commands, explicit
   do/don't), and add a routing row to `docs/INDEX.md`. Rewrite or delete the seed
   docs — never leave empty stubs (they erode trust). Keep `docs/INDEX.md` ≤60 lines.
3. **Nested `AGENTS.md`** — for each subdirectory with its own rules/contract,
   copy `TEMPLATE-nested-AGENTS.md` to `<that-dir>/AGENTS.md` (≤60 lines,
   imperative rules only). Delete `TEMPLATE-nested-AGENTS.md` when done.
4. **Runbooks for procedures** — every repeatable multi-step procedure (deploy,
   add a unit, release, rotate a secret…) becomes a runbook under
   `docs/runbooks/` (copy `docs/TEMPLATE.md`). Plain-markdown runbooks are the
   ONE portable format every agentic tool can read — use runbooks from ALL tools.
   Do NOT author Claude-specific "agent skills" (`SKILL.md` / `.claude/skills/`)
   as the source of truth: they are vendor-specific and fragment the KB. (At most,
   a tool that supports skills may keep a thin skill that POINTS to the runbook —
   never the reverse; the runbook always stays the single source of truth.)
5. **Optional inventory automation** — if the repo has an enumerable/auto-
   discovered set of units (packages, services, modules), add a generator under
   `scripts/kb/` that writes a deterministic index, and add an inventory-drift
   diff to `scripts/kb/check_docs_drift.sh`. Skip if there is no such set.
   **MANDATORY when any doc describes a specific source path:** populate the
   `STALENESS_MAP` in `scripts/kb/check_docs_drift.sh` with one `doc source` pair
   per such doc, and keep it (a) COMPLETE, (b) free of entries whose doc or source
   no longer exists, and (c) UPDATED whenever a mapped file is renamed, removed,
   or added. The drift check FAILS on any stale entry.
6. **ADRs** — record the real decisions you found (`docs/decisions/NNNN-*.md`
   from `0000-template.md`) and index them in `docs/decisions/README.md`.
7. **Drift check in CI** — wire `scripts/kb/check_docs_drift.sh` into whatever CI
   this repo uses (it is just one command). Examples:
   - GitHub Actions: a step `run: bash scripts/kb/check_docs_drift.sh`.
   - GitLab CI: a job `script: bash scripts/kb/check_docs_drift.sh`.
   - Pre-commit / local hook: call the same script.
   Do not assume a CI vendor — add only the one the repo already uses.
   Tip: scaffold docs and ADRs deterministically with `scripts/kb/new_doc.sh`
   (dated frontmatter) and `scripts/kb/new_adr.sh` (next number + index row).
8. **Per-tool adapters (a SHALLOW import layer, not duplicates)** — `AGENTS.md`
   stays THE single entry point. Where a tool does not read `AGENTS.md` natively,
   add only a thin file that IMPORTS/points to it, never a copy of the rules. Do
   NOT rely on symlinks (Windows checkouts and some tools mishandle them):
   - Claude Code / Claude Desktop: keep the template's `CLAUDE.md`, whose first
     line is `@AGENTS.md` — the officially documented import syntax that inlines
     `AGENTS.md` at session start (a prose "see AGENTS.md" pointer is NOT
     guaranteed to be followed). Truly Claude-specific lines may go below the
     import. If the repo had its own `CLAUDE.md`, merge it per §2 first.
   - Gemini CLI: `.gemini/settings.json` = `{ "context": { "fileName": "AGENTS.md" } }`.
   - Aider: `.aider.conf.yml` = `read: AGENTS.md`.
   - Codex, Cursor, Copilot, Windsurf, Zed, Cline, Amazon Q: nothing — native
     `AGENTS.md`.
   Never create per-tool rule DUPLICATES (`.cursorrules`, copilot-instructions,
   …) that copy the actual rules; they diverge from `AGENTS.md`. If such a file
   must exist, it may ONLY be a SHALLOW pointer that references `AGENTS.md` —
   treated exactly like `CLAUDE.md`. `scripts/kb/check_docs_drift.sh` FAILS on any
   adapter (`CLAUDE.md`, `.cursorrules`, `.windsurfrules`, `.clinerules`,
   `GEMINI.md`, a `.github/copilot-instructions` file, `.aider.conf.yml`,
   `.gemini/settings.json`) that does not point back to `AGENTS.md`. Note: some
   tools strip HTML comments from instruction files before the agent sees them —
   anything an agent must act on belongs in visible markdown.

## 3a. Reach completeness in ONE setup — audit until stable
A single linear pass almost always MISSES things; that is why a fresh KB used to
need several later "update the ai-doc solution" runs to fill out. Do that
gap-hunting NOW, as part of setup, and loop until it finds nothing new:
1. **Coverage check.** Take the §2 inventory and confirm every item maps to
   something concrete: each area → a knowledge doc and/or nested `AGENTS.md`;
   each command → a line in root `AGENTS.md`; each procedure → a runbook; each
   decision → an ADR; and each doc has a routing row in `docs/INDEX.md`. Anything
   unmapped is a gap — fill it.
2. **Re-investigate with fresh eyes.** Re-scan the repo as in §2, ignoring what
   you already wrote, and diff against `docs/INDEX.md`: any real area/command/
   procedure/decision with no route is a gap — fill it.
3. **Run the drift check** (`scripts/kb/check_docs_drift.sh`) and resolve every
   warning (orphan/unrouted docs, missing frontmatter, size caps, leftover ⟨…⟩).
4. **Repeat 1–3 until a full pass adds nothing.** Only then is setup done. Do NOT
   defer gaps to a later "update the ai-doc solution" — the first build must be complete.

## 4. Do NOT (rejected approaches)
- ❌ Per-tool rule duplicates — `AGENTS.md` is the one source.
- ❌ A vector DB / RAG / MCP "context registry" for a normal repo — plain files +
  progressive disclosure are simpler, diffable, and read by every tool. Revisit
  only if docs outgrow keyword/file lookup (100k+ lines of docs).
- ❌ Auto-written session "memory" as the primary KB — non-standard, uncurated.
- ❌ Making the KB depend on any single vendor's folder or file format.
- ❌ Empty stub docs, code snippets in docs, style prose, or secret values.

## 5. Maintenance model (set expectations)
Fully autonomous doc upkeep does not exist. What works: **same-session updates**
(`docs/runbooks/keeping-docs-current.md`) + **scripted drift checks**
(`scripts/kb/check_docs_drift.sh` in CI) + a **periodic sweep**
(`docs/runbooks/kb-review.md`, triggered by the human phrase **"update the
ai-doc solution"** — it verifies every doc AND hunts for coverage gaps). The
sweep is fronted by `scripts/kb/kb_review_worklist.sh`, which turns "re-read
every doc" into a targeted, git-driven worklist (which docs recent commits
implicate) and suggests missing `STALENESS_MAP` entries. For
very large new features, consider an optional spec-driven flow (spec → plan →
tasks → implement) later — do not build it now.

## 6. Validate before finishing
- [ ] `AGENTS.md` ≤150 lines; `docs/INDEX.md` ≤60 lines; the "NOT SET UP YET"
      block is gone.
- [ ] Every path referenced in `AGENTS.md` and `docs/INDEX.md` exists.
- [ ] `CLAUDE.md` exists and its first line is `@AGENTS.md`; no leftover
      per-tool rule duplicates (`.cursorrules`, copilot-instructions, …).
- [ ] `scripts/kb/check_docs_drift.sh` exits 0.
- [ ] `STALENESS_MAP` in `scripts/kb/check_docs_drift.sh` covers every doc that
      describes a specific source path, with no entries for renamed/removed files.
- [ ] No `⟨…⟩` placeholders remain in tracked files except this guide
      (`grep -rn '⟨' . | grep -v docs/ai-doc-solution-maker.md`).
- [ ] No secret values written to any tracked file.
- [ ] Every §2 inventory item is covered (area/command/procedure/decision →
      doc/row/ADR) and the §3a audit adds nothing on a fresh pass.
- [ ] Fresh-eyes test: in a new session, give a realistic task and confirm the
      agent reads `docs/INDEX.md`, finds the right docs/runbooks, follows the
      conventions, and runs the keeping-docs-current checklist. Fix whatever it
      failed to find — that is the KB's real acceptance test.
- [ ] Leave all changes UNCOMMITTED for the human to review and commit. Do not
      run `git commit`, `git push`, or open a PR.
