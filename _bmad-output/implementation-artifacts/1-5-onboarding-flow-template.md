---
baseline_commit: b41f0615e620800496fca944affabb1b9623e730
---

# Story 1.5: Onboarding Flow Template

Status: in-progress

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a student,
I want a structured onboarding flow that the Planner Agent follows,
so that setup is consistent, all required data is collected in the right order, and my memory files are populated correctly on the first session.

## Acceptance Criteria

1. **Given** `templates/onboarding.md` exists **When** the Planner Agent reads it **Then** it contains all 7 onboarding questions in order: (1) What is your name?, (2) What topic are you studying?, (3) What is your goal?, (4) What is your current level (beginner / intermediate / advanced)?, (5) How much time can you dedicate per day?, (6) Do you have a deadline?, (7) What is your preferred learning style? **And** each question includes an example response showing the expected format and level of detail

2. **Given** `templates/onboarding.md` exists **When** the Planner Agent completes the questionnaire **Then** the template provides explicit field-mapping instructions: which `student-profile.md` field each answer maps to and the exact write format

3. **Given** `templates/onboarding.md` exists **When** I read the memory initialization instructions **Then** they instruct the Planner Agent to: (a) populate all `student-profile.md` fields, (b) initialize `knowledge-map.md` with all topic concepts under `## Never Studied ⬜`, (c) write `session-log.md` with a Session 0 entry (onboarding session) as the first record

## Tasks / Subtasks

- [x] Task 1: Create `templates/onboarding.md` with the 7-question flow (AC: #1)
  - [x] Place the file at repo-root `templates/onboarding.md` (sits alongside `student-profile.md`, `session-log.md`, `knowledge-map.md`, `memory-protocol.md`). This is a NEW file — it does not exist yet.
  - [x] Do NOT add `type: agent` frontmatter. This is a template (a contributor reference + instruction source the Planner Agent reads), not an invokable agent. `type: agent` would subject it to the Story 1.4 lint version-gate check and fail. Use a short HTML-comment header explaining its purpose, or `type: template` at most — mirror exactly how `templates/memory-protocol.md` was authored in Story 1.4.
  - [x] Add a `## Onboarding Questions` section listing all 7 questions **in the exact AC #1 order** (name → topic → goal → level → time → deadline → style). This order differs from the field order inside `student-profile.md` — follow the AC order, not the profile order.
  - [x] For EACH of the 7 questions, include an inline example response that shows expected format and detail level (see Dev Notes "Question → example mapping" table for ready-to-use examples drawn from the schema templates).
  - [x] Question 4 (level) must constrain the answer to exactly one of: `beginner`, `intermediate`, `advanced` (matches the `current_level` enum in `student-profile.md`).
  - [x] Question 6 (deadline) must show both the date format (`YYYY-MM-DD`) and the "no deadline" case (`None`) — matching the `deadline` field comment in `student-profile.md`.

- [x] Task 2: Add the field-mapping instructions (AC: #2)
  - [x] Add a `## Field Mapping` section mapping each of the 7 answers to its exact `student-profile.md` field name and write format. Use the EXACT field names from the schema (see Dev Notes table) — no aliases, no renamed fields (Story 1.2 contract / ARCH-13).
  - [x] Mapping is: Q1→`name`, Q2→`topic`, Q3→`goal`, Q4→`current_level`, Q5→`time_per_day`, Q6→`deadline`, Q7→`preferred_style`.
  - [x] Handle `preferred_language` explicitly (CRITICAL — see Dev Notes). It is a required `student-profile.md` field but is NOT one of the 7 questions. The template must instruct the Planner Agent to populate it (infer from the language the student is conversing in; default `English`). Leaving it as `{value}` would violate AC #3a ("populate all fields") and the Story 1.2 schema contract.
  - [x] Note that `study_plan` is NOT written from a direct onboarding answer — it is produced by the `build-study-plan` skill in Story 1.6 and is Planner-only (ARCH-13). The onboarding template should defer/cross-reference this field, not invent a write format for it here.

- [x] Task 3: Add the memory-initialization instructions (AC: #3)
  - [x] Add a `## Memory Initialization` section instructing the Planner Agent to write all three memory files in the correct order, respecting write ownership (ARCH-13: Planner writes `student-profile.md` once; all agents append `session-log.md`; Planner seeds `knowledge-map.md`).
  - [x] (a) Populate ALL `student-profile.md` fields — the 7 mapped answers + `preferred_language` (+ `study_plan` is filled by `build-study-plan` per Story 1.6; reference it, don't duplicate). Keep `memory-protocol-version: 1`.
  - [x] (b) Initialize `knowledge-map.md`: set `**Topic:**` and `**Last updated:**` headers, leave Mastered/In Progress/Gaps empty, and seed `## Never Studied ⬜` with ALL concepts from the study plan / topic. Keep the five canonical sections in order and `memory-protocol-version: 1`. (Matches architecture Day-0 seed state, lines 228–245.)
  - [x] (c) Write the `session-log.md` Session 0 entry as the first record, using the canonical append block from `templates/session-log.md`. Use `Agent: planner` and `Mode: onboarding` (see Dev Notes "Session 0 Mode" variance — use `onboarding`, consistent with Story 1.6 AC #4b, even though it is outside the canonical Mode enum). Include the study plan summary under `### What was covered`, `Score: N/A`, `Gaps identified: None`, and a `Next recommended session`.

- [x] Task 4: Validation
  - [x] `bash scripts/lint-agnostic.sh templates/onboarding.md` exits `0` — the template must be model-agnostic (NFR-1): no model names (GPT/Claude/Gemini/etc.), no platform-specific syntax, no context-window-size references. (The template MAY reference memory files by name — it is a template, not a stateless skill; the no-memory-refs rule applies only to `skills/` files per ARCH-2.)
  - [x] `bash scripts/lint-agnostic.sh` (default `agents/` + `skills/` targets) still exits `0` — confirm you did not break anything.
  - [x] Manually verify against AC #1/#2/#3: exact 7-question order, every question has an example, field mapping uses exact schema field names, all three memory files covered in init instructions.
  - [x] `vitest run` — confirm no existing test regressions (this story adds no test; a pure-markdown template has no unit test, consistent with Story 1.2/1.4 template deliverables).

### Review Findings

<!-- Appended by code-review (2026-06-15). decision-needed and patch items are unchecked; defer items are checked off and logged in deferred-work.md. -->

- [x] [Review][Defer] build-study-plan vs `student-profile.md` write sequencing is ambiguous [templates/onboarding.md:73-87] — deferred: to be resolved in Story 1.6. The Memory Initialization preamble implies the plan already exists when `student-profile.md` is written, while Field Mapping implies the profile is written first and `study_plan` is filled later by `build-study-plan`. The canonical sequence (and whether the Session 0 log may unconditionally claim "Generated week-by-week study plan") should be pinned down when the Planner's Session Workflow is wired in Story 1.6.
- [ ] [Review][Patch] Session 0 `**Duration:** {X} minutes` has no source or fill instruction — no onboarding question captures elapsed time and no default is specified, so the Planner will either invent a number or emit the literal `{X}` placeholder (the file is otherwise explicit about not leaving placeholders, e.g. `preferred_language`). Note: this block is copied verbatim from the spec's canonical Session 0 block. [templates/onboarding.md:134]
- [x] [Review][Defer] Runtime input validation for the 7 answers is unspecified [templates/onboarding.md:27-46] — deferred; out-of-enum `current_level`, past/malformed `deadline`, and blank answers have no re-ask/reject path. Not required by the ACs; runtime validation behavior belongs to the Planner Agent (Story 1.6).
- [x] [Review][Defer] Session 0 uses `## Session 0` vs the canonical `## Session [N]` numbering [templates/onboarding.md:130] — deferred; whether the bootstrap consumes index 0 (making the first study session "Session 1") is unstated. Session numbering/collision is already a tracked cross-story concern (see 1-2 deferred items).

## Dev Notes

### What this deliverable is (and is not)

- **FR-4.1 deliverable:** `templates/onboarding.md` — "full onboarding flow for Planner Agent; all 7 questions, example responses, instructions for writing the three memory files."
- It is a **template/instruction source**, consumed by the Planner Agent's `## Session Workflow` (Story 1.6 AC #2d explicitly: the Planner's Session Workflow points to `templates/onboarding.md`). Author it so a future Planner Agent can follow it verbatim.
- It is **NOT** a skill (skills are stateless and may not reference memory files — ARCH-2). This template MAY and MUST reference `student-profile.md` / `knowledge-map.md` / `session-log.md` by name, exactly like `templates/memory-protocol.md` does.
- It is **NOT** an agent (no `type: agent` frontmatter — would self-fail the Story 1.4 lint gate).
- It is **NOT** the CLI onboarding (`src/prompts/onboarding.ts`, Story 5.2) — different artifact, different epic. Do not conflate.
- The actual memory writes happen at runtime via the Planner Agent (Story 1.6). This story authors only the **instructions** the agent follows; no `memory/` files are created by this story.

### Exact schema field names (Story 1.2 contract — use VERBATIM)

From `templates/student-profile.md` (do not rename, alias, or reorder fields when writing the mapping):

| Onboarding Q (AC order) | Question | `student-profile.md` field | Format / constraint | Example answer |
|---|---|---|---|---|
| Q1 | What is your name? | `name` | free text | `Pedro` |
| Q2 | What topic are you studying? | `topic` | be specific | `Java Backend Interview Prep (Kafka, Spring Boot, System Design)` |
| Q3 | What is your goal? | `goal` | one sentence | `Pass Java backend interview at a FAANG company` |
| Q4 | Current level? | `current_level` | one of: `beginner`, `intermediate`, `advanced` | `intermediate` |
| Q5 | Time per day? | `time_per_day` | e.g. `1 hour`, `30 minutes` | `1 hour` |
| Q6 | Deadline? | `deadline` | `YYYY-MM-DD` or `None` | `2026-09-01` |
| Q7 | Preferred learning style? | `preferred_style` | free text | `Analogies and real examples, then practice questions` |
| — (not a question) | inferred | `preferred_language` | e.g. `English`, `Português` | `English` |
| — (Story 1.6) | built by `build-study-plan` | `study_plan` | multiline, `Week 1:` entries; Planner-only (ARCH-13) | — |

Keep `memory-protocol-version: 1` at the top of `student-profile.md` (it is already line 1 of the template).

### ⚠️ CRITICAL — `preferred_language` has no question (gap to close)

AC #1 specifies exactly 7 questions, and none of them is language. But `student-profile.md` has a required `preferred_language` field, and AC #3a says "populate ALL `student-profile.md` fields." If you stop at the 7 answers, `preferred_language` stays as the literal placeholder `{value}` and the schema contract is violated (and downstream NFR-4 "students set preferred response language in student-profile.md" breaks).

**Resolution:** The onboarding template MUST tell the Planner Agent how to fill `preferred_language` without adding an 8th explicit question — infer it from the language the student is using to converse, defaulting to `English`. State this explicitly in the `## Field Mapping` and `## Memory Initialization` sections. (Do not add a question; the AC freezes the count at 7.)

### ⚠️ Session 0 `Mode` value — known cross-story variance

The canonical `session-log.md` Mode enum is `{Learn|Quiz|Review|Simulate|Think|Coach|Troubleshoot}` (Story 1.2). `onboarding` is NOT in that enum. However, **Story 1.6 AC #4b explicitly requires the Session 0 entry to use `Mode: onboarding`**. For cross-story consistency, this template must specify `Mode: onboarding` for the Session 0 block. Flag this as an intentional, documented exception in your Completion Notes (the enum is for ongoing study sessions; onboarding is the one bootstrap record). Do not "fix" it to a Learn/Review enum value — that would diverge from Story 1.6.

### Canonical Session 0 block (copy structure from `templates/session-log.md`)

```
## Session 0 — YYYY-MM-DD
**Agent:** planner
**Mode:** onboarding
**Topic:** {student's topic}
**Duration:** {X} minutes

### What was covered
- Completed onboarding; captured goal, level, time budget, deadline, learning style
- Generated week-by-week study plan

### Score
N/A

### Gaps identified
- None

### Next recommended session
{one sentence, e.g. "Begin Week 1 with the Professor Agent on {first concept}."}

---
```

### Day-0 `knowledge-map.md` seed (architecture lines 228–245)

Set `**Topic:**` and `**Last updated:**`; leave Mastered/In Progress/Gaps/Spaced Repetition Queue empty; seed `## Never Studied ⬜` with every concept derived from the study plan/topic. Preserve the five canonical sections in order and `memory-protocol-version: 1`. Never-Studied concept line format is just `- {concept}` (no date suffix).

### Model-agnostic authoring (NFR-1) — what trips lint

`scripts/lint-agnostic.sh` flags: model names (GPT-4, Claude, Gemini, etc.), platform-specific syntax, and context-window-size references. Write the flow in plain, tool-neutral language. Phrase agent actions as "the Planner Agent reads/writes…" not "Claude reads…". Em dashes (—), arrows (→), and `≠` are fine (they appear in the already-passing `memory-protocol.md`).

### NFR-4 bilingual scope note (do NOT expand scope)

NFR-4 lists "README and onboarding template in EN and PT-BR." Story 1.5's deliverable and the architecture directory (line 580) list only a single `templates/onboarding.md`, and agent/skill files are English-only (NFR-4). Author this file in **English only** for Story 1.5. A PT-BR onboarding variant, if pursued, is a separate decision (likely surfaced via README.pt.md / Epic 5 CLI prompts) — flag it in Completion Notes but do not create a second file in this story unless the user explicitly asks.

### Project Structure Notes

- New file: `templates/onboarding.md` (repo root → `templates/`). Confirmed by architecture directory structure line 580: `onboarding.md ← FR-4.1 — full onboarding flow`.
- No conflicts with existing files. The four existing `templates/*.md` (student-profile, session-log, knowledge-map, memory-protocol) are the schema sources this template references — read them, do not modify them.
- Variance: epics list only `templates/onboarding.md` as the deliverable; AC #3 also requires this template to encode write-ownership behavior consistent with ARCH-13. That behavioral spec lives inside the template text, not in separate files — in-scope.
- This story does NOT touch `agents/planner-agent.md` or the build pipeline. The wiring of the Planner's Session Workflow to this template is Story 1.6's job (Story 1.6 AC #2d). Keep this story to the template only.

### Previous Story Context (Story 1.4 — in progress)

- Story 1.4 authored `templates/memory-protocol.md` as a non-`type:agent` template with a short HTML-comment header — **use it as the structural model** for `onboarding.md` (same directory, same "template not agent" pattern, same lint expectations).
- Story 1.4 extended `lint-agnostic.sh` with an agent-only `memory-protocol-version` check that fires only on `type: agent` files. Because `onboarding.md` is NOT `type: agent`, that check will not apply — but the negative scans (model names / platform tokens / context-window refs) still apply to any file passed explicitly. Keep the file clean.
- The canonical halt message and On Activation block are owned by `memory-protocol.md`; do not restate or rephrase them here — onboarding is a separate concern (the first-run bootstrap), not the per-session activation gate.

### References

- Story 1.5 requirements & ACs: [Source: epics.md#Story 1.5: Onboarding Flow Template]
- FR-4.1 (onboarding template, 7 questions, write instructions): [Source: epics.md#FR-4 Onboarding Template]
- `student-profile.md` field schema (exact names/formats): [Source: templates/student-profile.md], [Source: epics.md#Story 1.2 AC 1]
- Canonical `session-log.md` append block + Session 0 usage: [Source: templates/session-log.md], [Source: epics.md#Story 1.6 AC 4]
- `knowledge-map.md` five canonical sections + Day-0 seed: [Source: templates/knowledge-map.md], [Source: architecture.md#Pattern 4 — Day-0 seed state (lines 219–245)]
- Memory write ownership (Planner writes profile once; seeds knowledge-map; appends session-log): [Source: architecture.md#ARCH-13 (lines 656, 702)], [Source: epics.md#ARCH-13]
- Planner Session Workflow points to this template (downstream consumer): [Source: epics.md#Story 1.6 AC 2]
- Template-not-agent / lint pattern to mirror: [Source: 1-4-memory-protocol-block.md], [Source: templates/memory-protocol.md]
- Model-agnostic constraint: [Source: epics.md#NFR-1], [Source: scripts/lint-agnostic.sh]
- Bilingual scope: [Source: epics.md#NFR-4]

## Dev Agent Record

### Agent Model Used

claude-opus-4-8

### Debug Log References

- `bash scripts/lint-agnostic.sh templates/onboarding.md` → `lint-agnostic: all files OK` (exit 0)
- `bash scripts/lint-agnostic.sh` (default agents/ + skills/) → `lint-agnostic: all files OK` (exit 0)
- `npx vitest run` → 2 files, 15 tests passed, no regressions

### Completion Notes List

- Created `templates/onboarding.md` as the FR-4.1 onboarding flow. Authored as a template (HTML-comment header, no `type: agent` frontmatter), mirroring `templates/memory-protocol.md` so it is not subject to the Story 1.4 agent version-gate lint check.
- All 7 questions are listed in the exact AC #1 order (name → topic → goal → level → time → deadline → style), each with an example answer. Q4 constrains to the `beginner|intermediate|advanced` enum; Q6 shows both `YYYY-MM-DD` and the `None` case.
- Field Mapping uses the exact `student-profile.md` schema field names verbatim (no aliases/renames per Story 1.2 contract / ARCH-13).
- **`preferred_language` gap closed:** the template instructs the Planner Agent to infer language from the conversation (default `English`) rather than adding an 8th question, so AC #3a ("populate all fields") is satisfied without changing the frozen 7-question count.
- **`study_plan` deferred:** the template cross-references the `build-study-plan` skill (Story 1.6) as the writer and does not invent a write format (ARCH-13, Planner-only field).
- Memory Initialization covers all three files in order with write-ownership respected: profile (all fields), knowledge-map (Day-0 seed — `Never Studied ⬜` seeded, other sections empty), and the Session 0 `session-log.md` entry.
- **Documented intentional exception:** the Session 0 block uses `Mode: onboarding`, which is outside the canonical Mode enum (`Learn|Quiz|Review|Simulate|Think|Coach|Troubleshoot`). This is required for consistency with Story 1.6 AC #4b; the template notes it inline as the one-time bootstrap record.
- **Scope note (NFR-4 bilingual):** authored in English only for this story, matching the architecture directory's single `templates/onboarding.md` deliverable. A PT-BR onboarding variant remains a separate, future decision and was deliberately not created here.
- No code/tests added — pure-markdown template deliverable, consistent with the Story 1.2/1.4 template deliverables. No `memory/` files are written by this story; runtime writes happen via the Planner Agent (Story 1.6).

### File List

- `templates/onboarding.md` (new)
- `_bmad-output/implementation-artifacts/1-5-onboarding-flow-template.md` (modified — task checkboxes, Dev Agent Record, Status)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — status tracking)

## Change Log

- 2026-06-15: Implemented Story 1.5 — created `templates/onboarding.md` (7-question flow, field mapping, memory-initialization instructions). Lint + vitest pass. Status → review.
