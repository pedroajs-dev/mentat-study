---
baseline_commit: b41f0615e620800496fca944affabb1b9623e730
---

# Story 1.4: Memory Protocol Block

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a contributor,
I want a canonical, reusable On Activation instruction block,
so that every agent file uses identical memory-loading language and the version gate is never omitted or rephrased.

## Acceptance Criteria

1. **Given** `templates/memory-protocol.md` exists **When** I read it **Then** it contains the exact On Activation steps in order: (1) Read `{project-root}/memory/student-profile.md`, (2) Read `{project-root}/memory/knowledge-map.md`, (3) Read last 3 entries of `{project-root}/memory/session-log.md`, (4) Check `memory-protocol-version` — if ≠ 1, halt and output the canonical mismatch message from Story 1.2, (5) Greet student by name and confirm current topic

2. **Given** `templates/memory-protocol.md` exists **When** I read the After Session section **Then** it contains: (1) Append to `{project-root}/memory/session-log.md` using the canonical format from Story 1.2, (2) [Evaluator + Spaced Review only] Update `{project-root}/memory/knowledge-map.md`

3. **Given** `scripts/lint-agnostic.sh` runs on any file with `type: agent` in frontmatter **When** the file is missing the `memory-protocol-version` check instruction **Then** lint fails with a message identifying the missing check

## Tasks / Subtasks

- [x] Task 1: Create `templates/memory-protocol.md` — the canonical reusable block (AC: #1, #2)
  - [x] Place file at `templates/memory-protocol.md` (repo root → `templates/`)
  - [x] Do NOT give it `type: agent` frontmatter (it is a reusable include, not an agent — `type: agent` would make it subject to its own lint check in Task 2). Use a short HTML-comment header explaining its purpose and that it is pasted verbatim into every agent file. No YAML `type` field, or `type: template` at most.
  - [x] Add a `## On Activation` section with the 5 ordered steps exactly per AC #1:
    1. Read `{project-root}/memory/student-profile.md` (+ purpose note)
    2. Read `{project-root}/memory/knowledge-map.md` (+ purpose note)
    3. Read last 3 entries of `{project-root}/memory/session-log.md` (+ purpose note)
    4. Check `memory-protocol-version` — if ≠ 1, halt immediately and output the EXACT canonical Story 1.2 message (see Dev Notes — verbatim, no paraphrase)
    5. Greet the student by name and confirm current topic
  - [x] Add a `## After Session` section with the 2 steps exactly per AC #2:
    1. Append to `{project-root}/memory/session-log.md` using the canonical append format from Story 1.2 (reference `templates/session-log.md`)
    2. `[Evaluator + Spaced Review only]` Update `{project-root}/memory/knowledge-map.md`
  - [x] Verify the file passes lint: `bash scripts/lint-agnostic.sh templates/memory-protocol.md` exits 0

- [x] Task 2: Extend `scripts/lint-agnostic.sh` with the agent version-gate check (AC: #3)
  - [x] After the existing per-line scans, add a per-file check: for each collected file, parse the YAML frontmatter (lines between the first two `---` fences) and detect `type: agent`
  - [x] For files where `type: agent`, assert the file body contains the string `memory-protocol-version`; if absent, print a clear error to stdout identifying the missing check (e.g. `lint-agnostic ERROR: {file}: agent file is missing the required memory-protocol-version check`) and set `found_error=1`
  - [x] Ensure the check tolerates spacing variants (`type: agent`, `type:agent`) and CRLF line endings (consistent with Story 1.3 hardening)
  - [x] Confirm existing `agents/planner-agent.md` still passes (it contains `memory-protocol-version`) — no false positive
  - [x] Confirm `compiled/` is still skipped by the new check (reuse the existing `collect_files` output, which already excludes `compiled/`)

- [x] Task 3: Add an automated test for the new lint behavior (AC: #3)
  - [x] Add a vitest test (e.g. `tests/lint/agent-protocol.test.ts`) consistent with the Story 1.3 vitest convention
  - [x] RED: write a temp fixture agent file (`type: agent` frontmatter, no `memory-protocol-version` anywhere), run `bash scripts/lint-agnostic.sh <fixture>` via `child_process`, assert non-zero exit and that the output names the missing check
  - [x] GREEN: write a temp fixture agent file that DOES contain the check, assert exit 0
  - [x] Also assert a `type: skill` fixture without `memory-protocol-version` does NOT trigger the agent check (the gate is agent-only)
  - [x] Clean up temp fixtures after the test

- [x] Task 4: Reconcile the halt-message wording divergence (AC: #1 — "never rephrased") — SEE DEV NOTES CONFLICT
  - [x] Confirm `templates/memory-protocol.md` uses the canonical Story 1.2 message verbatim
  - [x] Align `agent-template.md` On Activation step 4 and `agents/planner-agent.md` On Activation step 4 to the SAME canonical message (they currently add "of BMAD-Study" and diverge — this directly violates the story's "never rephrased" goal). If you choose NOT to touch these files, record the rationale in Completion Notes and leave them flagged.
  - [x] If `agents/planner-agent.md` is edited, re-run `bash scripts/build-skills.sh` so `compiled/bmad-study-planner.md` stays in sync, and run `vitest run` to confirm the structure tests still pass

- [x] Task 5: Full validation (AC: #1, #2, #3)
  - [x] `bash scripts/lint-agnostic.sh` (default targets) exits 0
  - [x] `bash scripts/lint-agnostic.sh templates/memory-protocol.md` exits 0
  - [x] `vitest run` — all tests pass (existing Story 1.3 structure tests + new lint test)
  - [x] `bash scripts/build-skills.sh --check` exits 0 (compiled/ in sync if any agent was edited)
  - [x] Manually verify `templates/memory-protocol.md` against the AC #1/#2 checklist (exact step order, exact message)

### Review Findings (2026-06-15)

<!-- Layers: Blind Hunter ✓, Acceptance Auditor ✓, Edge Case Hunter ✗ (agent unavailable — partial coverage from Blind Hunter). -->

- [x] [Review][Patch] `tr | awk` with early `exit` can abort the whole lint under `set -euo pipefail` on files larger than the pipe buffer (~64KB): `awk` exits at the 2nd `---` fence while `tr` is still streaming the body → `tr` gets SIGPIPE (141) → `pipefail` propagates → `frontmatter=$(...)` returns 141 → `set -e` aborts. **Resolved (2026-06-15):** removed the `awk exit`; awk now drains all input (`fences==1{print}`), so `tr` never gets SIGPIPE. Regression test added (200KB body must report, not abort). [scripts/lint-agnostic.sh:71]
- [x] [Review][Patch] `type: agent` detection regex `^[[:space:]]*type:[[:space:]]*agent[[:space:]]*$` silently skips the version-gate check for YAML-valid variants like `type: "agent"` or `type: agent # comment` — a false negative that lets an agent omit the gate undetected (defeats AC #3). **Resolved (2026-06-15):** regex now tolerates optional quotes and a trailing inline comment with a word boundary (`type:[[:space:]]*["']?agent["']?[[:space:]]*(#.*)?$`); `type: agentic` correctly does NOT match. 3 regression tests added. [scripts/lint-agnostic.sh:72]
- [x] [Review][Defer] The version-gate is a bare substring check (`grep -q 'memory-protocol-version'`), not a semantic check — a file mentioning the token in prose/a comment without an actual gate would pass. Consistent with the project's existing enforcement heuristic (`tests/agents/structure.test.ts` uses the same substring contract), so not actionable now. [scripts/lint-agnostic.sh:73] — deferred, heuristic limitation matching existing pattern

## Dev Notes

### ⚠️ CRITICAL CONFLICT — The halt message exists in FOUR different wordings

This story's entire purpose is that the version gate is "never omitted or rephrased." Today the codebase already has the gate **rephrased four ways**:

| Source | Exact text |
|---|---|
| **Story 1.2 AC #4 (CANONICAL — use this)** | `Your memory files are from an older version. Please re-run onboarding with /bmad-study-planner.` |
| `agents/planner-agent.md:20` | `Your memory files are from an older version of BMAD-Study. Please re-run onboarding with /bmad-study-planner.` |
| `agent-template.md:27` | `Your memory files are from an older version of BMAD-Study. Please re-run onboarding with /bmad-study-planner.` |
| `architecture.md` Pattern 5 (line 264) | `Your memory files are from an older version of BMAD-Study. Please re-run onboarding with the Planner Agent before continuing.` |
| `architecture.md` Pattern 8 (line 332) | `Your memory files are from an older version. Please re-run onboarding.` |

**AC #1 is explicit: use "the canonical mismatch message from Story 1.2".** That is the source of truth. `templates/memory-protocol.md` MUST contain this exact string, character-for-character:

```
Your memory files are from an older version. Please re-run onboarding with /bmad-study-planner.
```

`memory-protocol.md` is now the single canonical source of this block. Task 4 addresses the existing divergence in `agent-template.md` and `planner-agent.md` so the repo doesn't ship two competing "canonical" messages. This is in-scope because the story's stated goal is preventing rephrasing — leaving the rephrased copies in place would defeat the deliverable. (The architecture.md file is a planning artifact, not a shipped agent — do not edit it; just note the variance.)

### What `memory-protocol.md` is (and is not)

Per FR-1.4: "reusable instruction block imported at the top of every agent skill file." It is the authoring-time source for the `## On Activation` + `## After Session` blocks that every agent file copies verbatim. It is:
- **NOT** an agent (no `type: agent` frontmatter — that would make it self-fail the Task 2 lint check, and it is never invoked as `/bmad-study-*`).
- **NOT** processed by `scripts/build-skills.sh` (that script only assembles `agents/` + `skills/` → `compiled/`). `memory-protocol.md` lives in `templates/` and is a human/contributor reference + copy source.
- **NOT** seeded into the user's `memory/` directory by the CLI (only `student-profile.md`, `session-log.md`, `knowledge-map.md` are — see Story 1.2 / Story 5.3).

### Exact canonical content to author (AC #1 + AC #2)

Use the implemented section naming convention `## On Activation` / `## After Session` (this is what `agents/planner-agent.md` uses and what `tests/agents/structure.test.ts` asserts). Note: `architecture.md` lines 375/387 refer to a `## Memory Protocol` section name — that naming was never implemented; the live convention is `## On Activation`. Stay consistent with the live convention.

Author the block to match this structure (purpose notes mirror Pattern 5 / agent-template.md):

```markdown
## On Activation

1. Read {project-root}/memory/student-profile.md
   → Know who you are talking to (name, level, goal, available time, deadline)
2. Read {project-root}/memory/knowledge-map.md
   → Know what they know and what the gaps are
3. Read {project-root}/memory/session-log.md (last 3 session entries only)
   → Know what was recently covered
4. Schema version check: if memory-protocol-version in any file ≠ 1, halt immediately and say:
   "Your memory files are from an older version. Please re-run onboarding with /bmad-study-planner."
5. Greet the student by name. Confirm current topic and session mode.

## After Session

1. Append to {project-root}/memory/session-log.md using the canonical append format
   (see templates/session-log.md for the exact block structure).
2. [Evaluator + Spaced Review only] Update {project-root}/memory/knowledge-map.md
```

- Step order is fixed and asserted by AC #1 — do not reorder.
- The `≠` / `→` characters and the em-dash conventions are fine for lint (no model names / platform tokens).
- The halt message is the exact Story 1.2 string — do NOT add "of BMAD-Study", do NOT change "/bmad-study-planner" to "the Planner Agent".

### Task 2 — how the lint check works

`scripts/lint-agnostic.sh` today (read it fully before editing — it was hardened in Story 1.1 review and again indirectly in 1.3):
- `collect_files()` resolves targets (default `agents/` `skills/`), emits `.md` paths, and **already excludes `compiled/`** — reuse this; do not re-scan `compiled/`.
- The main loop scans each file line-by-line for three forbidden pattern groups (model names, platform tokens, context-window refs) and sets `found_error=1` on any hit.

Add a **positive/required** check (the inverse of the existing negative checks). Suggested approach, integrated into the existing `while IFS= read -r file` loop or a second pass over the same `collect_files` output:

1. Extract frontmatter: read lines until the first `---`, then capture lines up to the second `---`.
2. If a frontmatter line matches `type:` with value `agent` (tolerate optional space, trailing CR), the file is an agent.
3. For agent files, grep the file for `memory-protocol-version`. If not found, emit:
   `lint-agnostic ERROR: {file}: agent file is missing the required memory-protocol-version check` and `found_error=1`.

Match the existing error message style (`lint-agnostic ERROR: {file}:...`). Preserve `set -euo pipefail` safety — guard `grep` calls that may legitimately return non-zero (no match) with `|| true` so the script doesn't abort under `pipefail`.

CRLF note (from Story 1.3): the repo has `.gitattributes` with `eol=lf`, but be defensive — strip a trailing `\r` when comparing the `type` value, consistent with how 1.3 handled CRLF.

### Task 3 — testing approach (red-green-refactor)

The project's test harness is **Vitest** (Story 1.3 established `tests/` + `tsc --noEmit` coverage of `tests/`). A pure-markdown deliverable normally has no unit test, but AC #3 is a behavioral guarantee about the lint script, so it should be tested. Add a Vitest test that shells out to the bash script via `child_process.execSync` / `spawnSync`:

- RED first: create a temp agent fixture (`type: agent`, body without `memory-protocol-version`), run the script against it, assert it exits non-zero and the output contains the missing-check message. Confirm this FAILS before you implement Task 2.
- GREEN: implement Task 2, then add the positive fixture (agent file WITH the check) asserting exit 0, and a `type: skill` fixture without the string asserting exit 0 (gate is agent-only).
- Use `os.tmpdir()` for fixtures and clean them in `afterAll`/`finally`. `spawnSync('bash', ['scripts/lint-agnostic.sh', fixturePath])` — capture `status` and `stdout`.
- `execSync` throws on non-zero exit; prefer `spawnSync` so you can read `status` without try/catch, mirroring how a CI-friendly assertion reads the exit code.

Note `tsconfig.json` already includes `tests/**/*` with `@types/node` (Story 1.3), so `child_process`/`os`/`fs` imports type-check cleanly.

### Task 4 — keeping compiled/ in sync

If you edit `agents/planner-agent.md` (Task 4), you MUST re-run `bash scripts/build-skills.sh` to regenerate `compiled/bmad-study-planner.md` (it is now a TRACKED artifact — Story 1.3 removed it from `.gitignore`), then run `bash scripts/build-skills.sh --check` (must exit 0) and `vitest run` (structure tests must pass). If you do NOT edit any agent file, `compiled/` is unchanged and `--check` passes trivially.

### Previous Story Context (Story 1.3 — done)

- `scripts/lint-agnostic.sh` is live; `collect_files` excludes `compiled/`. Note: it is currently shown as modified in `git status` (a 2-line change restoring `<s>`/`</s>` anchors from Story 1.2 review) — incorporate your change on top of the working-tree version.
- `scripts/build-skills.sh` exists and is hardened (CRLF-safe, path-traversal guarded, demotes skill headings). `compiled/` is tracked (NOT gitignored). `--check` mode is a real CI guard.
- Vitest is wired; `tests/agents/structure.test.ts` runs `build-skills.sh` in `beforeAll` then asserts compiled-agent structure including that `memory-protocol-version` appears in the body. CI order: build → check → lint → tsc → vitest.
- `tsconfig.json` includes `tests/**/*`, `moduleResolution: node`, `esModuleInterop`, `skipLibCheck`, `types: [node, vitest/globals]`, with `@types/node` installed.

### Project Structure Notes

- `templates/memory-protocol.md` is the FR-1.4 deliverable; it sits alongside the Story 1.2 schema files in `templates/`. Architecture directory structure (line 576) confirms: `templates/memory-protocol.md ← FR-1.4 — canonical On Activation block`.
- Variance: epics list only `templates/memory-protocol.md` as the deliverable, but AC #3 forces a `scripts/lint-agnostic.sh` change too. This is expected — the lint enforcement is how the canonical block is kept un-omitted. Documented here so the dev does not treat the lint change as out-of-scope.
- Variance: architecture uses `## Memory Protocol` as the section name in two enforcement notes, but the implemented agents use `## On Activation`. Follow the implemented convention (`## On Activation` / `## After Session`).

### References

- Story 1.4 requirements & ACs: [Source: epics.md#Story 1.4: Memory Protocol Block]
- FR-1.4 (reusable instruction block): [Source: epics.md#FR-1 Memory Templates]
- Canonical On Activation block: [Source: architecture.md#Pattern 5 — Memory Protocol (On Activation steps)]
- Canonical halt message (source of truth): [Source: 1-2-memory-schema-contract-and-templates.md#AC 4], [Source: epics.md#Story 1.2 AC 4]
- Canonical session-log append format: [Source: templates/session-log.md], [Source: architecture.md#Pattern 4 — Memory Write Format]
- Memory write ownership (Evaluator + Spaced Review only update knowledge-map): [Source: architecture.md#ARCH-13]
- Version gate (ARCH-10): [Source: architecture.md#ARCH-10]
- Lint script current behavior: [Source: scripts/lint-agnostic.sh], [Source: architecture.md#Pattern 9 / Enforcement Summary]
- Build pipeline + compiled/ tracked artifact: [Source: 1-3-build-pipeline.md]
- agent-template.md On Activation block (to reconcile): [Source: agent-template.md], [Source: agents/planner-agent.md]

## Dev Agent Record

### Agent Model Used

claude-opus-4-8

### Debug Log References

- Red phase: `npx vitest run tests/lint/agent-protocol.test.ts` — confirmed the "broken-agent" case failed (lint exited 0 when it should fail) before the lint check existed. Green after Task 2: all 3 cases pass.
- Frontmatter extraction made CRLF-robust (`tr -d '\r'` before awk) consistent with the Story 1.3 `.gitattributes` hardening.

### Completion Notes List

- **Task 1** — Created `templates/memory-protocol.md`: the canonical reusable block. `## On Activation` (5 ordered steps) + `## After Session` (2 steps), matching AC #1/#2 exactly. Step 4 uses the verbatim Story 1.2 canonical halt message (`"Your memory files are from an older version. Please re-run onboarding with /bmad-study-planner."`). No `type: agent` frontmatter (so it does not self-trigger the Task 2 lint check) — an HTML-comment header documents its purpose. Passes `lint-agnostic.sh` exit 0.
- **Task 2** — Extended `scripts/lint-agnostic.sh` with a positive agent version-gate check: after the per-line scans, it extracts the YAML frontmatter (lines between the first two `---` fences, CR-stripped), and if `type: agent` (tolerant of `type:agent`/`type: agent` spacing), asserts the file body contains `memory-protocol-version`; if absent it prints `lint-agnostic ERROR: {file}: agent file is missing the required memory-protocol-version check` and fails. Reuses the existing `collect_files` output, which already excludes `compiled/`. Existing `agents/planner-agent.md` still passes (no false positive).
- **Task 3** — Added `tests/lint/agent-protocol.test.ts` (Vitest, `spawnSync` over the bash script): (a) `type: agent` missing the check → non-zero exit + message names the missing check, (b) `type: agent` with the check → exit 0, (c) `type: skill` without the string → exit 0 (gate is agent-only). Temp fixtures via `mkdtempSync`, cleaned in `afterEach`.
- **Task 4** — Reconciled the four-way halt-message divergence flagged in Dev Notes. Aligned `agents/planner-agent.md` (On Activation step 4) and `agent-template.md` (On Activation step 4) to the canonical Story 1.2 message — both previously added "of BMAD-Study", directly violating the story's "never rephrased" goal. `architecture.md` (planning artifact, not shipped) left as-is per Dev Notes. Re-ran `build-skills.sh`; `compiled/bmad-study-planner.md` now carries the canonical message.
- **Task 5** — Full validation: `bash scripts/build-skills.sh --check` exit 0 (compiled/ in sync), `bash scripts/lint-agnostic.sh` exit 0, `bash scripts/lint-agnostic.sh templates/memory-protocol.md` exit 0, `npx tsc --noEmit` exit 0, `npx vitest run` → 11/11 tests pass (8 structure + 3 new lint).

### File List

- templates/memory-protocol.md (created — FR-1.4 canonical On Activation + After Session block)
- scripts/lint-agnostic.sh (modified — added agent version-gate check; AC #3)
- tests/lint/agent-protocol.test.ts (created — Vitest coverage for the new lint check)
- agents/planner-agent.md (modified — halt message aligned to canonical Story 1.2 wording)
- agent-template.md (modified — halt message aligned to canonical Story 1.2 wording)
- compiled/bmad-study-planner.md (regenerated by build-skills.sh — reflects canonical message)
- _bmad-output/implementation-artifacts/1-4-memory-protocol-block.md (modified — story file: tasks, records, status)
- _bmad-output/implementation-artifacts/sprint-status.yaml (modified — 1-4 status transitions)

## Change Log

- 2026-06-15: Story 1.4 implemented — created `templates/memory-protocol.md` (canonical On Activation + After Session block with the verbatim Story 1.2 version-gate halt message). Extended `scripts/lint-agnostic.sh` with an agent version-gate check (AC #3) and added `tests/lint/agent-protocol.test.ts`. Reconciled the halt-message wording across `agents/planner-agent.md` and `agent-template.md` to the single canonical message and rebuilt `compiled/`. All ACs satisfied; lint, `tsc --noEmit`, `--check`, and 11/11 vitest tests pass. Status → review.
- 2026-06-15: Code review completed — Blind Hunter + Acceptance Auditor (Edge Case Hunter layer unavailable). 0 decision-needed, 2 patch, 1 defer, 6 dismissed. ACs and halt-message reconciliation passed audit.
- 2026-06-15: Review findings addressed — both patches resolved in `scripts/lint-agnostic.sh`: (1) removed `awk exit` to eliminate a `pipefail` SIGPIPE abort on large files; (2) relaxed the `type: agent` regex to tolerate quotes/inline comments while excluding `agentic`. Added 4 regression tests (now 7 lint tests; 15 tests total). lint, `--check`, `tsc --noEmit`, and full vitest suite all pass. Status → done.
