---
baseline_commit: b41f0615e620800496fca944affabb1b9623e730
---

# Story 1.6: Planner Agent & Build-Study-Plan Skill

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a student,
I want to invoke `/bmad-study-planner` and complete onboarding in a single session,
so that my three memory files are fully populated with my study goals, topic, level, deadline, and a personalized week-by-week study plan — and I never need to repeat onboarding.

## Acceptance Criteria

1. **Given** `skills/build-study-plan.md` exists **When** I read it and run `scripts/lint-agnostic.sh` against it **Then** it is stateless (no references to `session-log.md`, `knowledge-map.md`, or `student-profile.md` by filename), contains only `## Instructions` with model-agnostic language, and lint exits `0`

2. **Given** `agents/planner-agent.md` exists **When** I read it **Then** it follows the BMAD skill structure in order: (a) agent persona + title block, (b) `## On Activation` with all 5 memory protocol steps from Story 1.4, (c) `## Skills` section with `### build-study-plan` referencing the skill, (d) `## Session Workflow` with onboarding flow instructions pointing to `templates/onboarding.md`, (e) `## After Session` with instructions to write all three memory files per Story 1.2 ownership rules

3. **Given** `bash scripts/build-skills.sh` runs after both files exist **When** it completes **Then** `compiled/bmad-study-planner.md` exists with `build-study-plan.md` content inlined under `## Skills` and all 5 structural assertions from Story 1.3 pass against it

4. **Given** a student invokes `/bmad-study-planner` with no existing `memory/` files **When** the session completes all 7 onboarding questions **Then** `memory/student-profile.md`, `memory/session-log.md`, and `memory/knowledge-map.md` all exist and contain: (a) `student-profile.md` has all 7 answers in the correct fields with `memory-protocol-version: 1`, (b) `session-log.md` has a Session 0 entry with `Agent: planner`, `Mode: onboarding`, and the study plan summary, (c) `knowledge-map.md` has all topic concepts under `## Never Studied ⬜` and `memory-protocol-version: 1`

5. **Given** a student invokes `/bmad-study-planner` a second time with memory files already present **When** On Activation runs **Then** the agent reads the existing files, greets the student by name, and offers to update the study plan rather than re-running full onboarding

6. **Given** `compiled/bmad-study-planner.md` is loaded into any instruction-following LLM **When** the student answers all 7 onboarding questions **Then** the agent produces a structured week-by-week study plan matching the student's stated time budget and deadline — with no model-specific syntax or platform-specific features required

## Tasks / Subtasks

> ⚠️ **These three files ALREADY EXIST as Epic-1 spike stubs and currently VIOLATE the ACs.** This story is a REFACTOR-to-spec, not a green-field create. Read each existing file before editing (done in Dev Notes). Do not assume "create new."

- [ ] Task 1: Refactor `skills/build-study-plan.md` to a stateless, instructions-only skill (AC: #1)
  - [ ] **Remove the `## Purpose` section.** AC #1 says the skill "contains only `## Instructions`". The current stub has both `## Purpose` and `## Instructions` — drop Purpose (or fold a one-line intent into the first instruction). Per Pattern 2, allowed skill sections are `## Purpose` / `## Instructions`, but AC #1 is stricter for THIS skill: only `## Instructions`.
  - [ ] **Remove ALL memory-file references by filename.** The current stub instructs writing to `student-profile.md`, `knowledge-map.md`, and `session-log.md` (lines 22–25). That is a hard ARCH-2 violation — skills are stateless; no file read/write belongs in a skill. Move ALL memory writes OUT of the skill and INTO `agents/planner-agent.md` `## After Session` (Task 2e). The skill must not name any memory file.
  - [ ] **Scope the skill to plan-building only.** After refactor, `build-study-plan.md` describes HOW to turn the student's answers (level, time budget, deadline, goal) into a structured week-by-week study plan: how to size weekly chunks against `time_per_day`, how to sequence topics from fundamentals → advanced, how to fit the plan inside the deadline, how to decompose the topic into named concepts. It does NOT ask the questions (that flow lives in `templates/onboarding.md`, Story 1.5) and does NOT write files.
  - [ ] Keep frontmatter `id: build-study-plan`, `version`, `type: skill`. Write in second-person imperative addressed to the executing LLM (Pattern 3).
  - [ ] `bash scripts/lint-agnostic.sh skills/build-study-plan.md` exits `0` (no model names / platform tokens / context-window refs).

- [ ] Task 2: Bring `agents/planner-agent.md` to full BMAD structure (AC: #2, #4, #5)
  - [ ] (a) Keep the persona + title block. Keep frontmatter `id: planner`, `version`, `type: agent`.
  - [ ] (b) Keep `## On Activation` with the 5 protocol steps from Story 1.4 / `templates/memory-protocol.md`. **Verify the halt message is the canonical Story 1.2 string verbatim** — `"Your memory files are from an older version. Please re-run onboarding with /bmad-study-planner."` (the current stub already uses this — do NOT regress it back to "…of BMAD-Study…"). Add explicit FIRST-RUN handling: if `memory/` files are absent (not present-but-wrong-version), do NOT halt — treat as a new student and proceed to onboarding (see Dev Notes "First-run vs version-mismatch").
  - [ ] (c) Keep `## Skills` with `### build-study-plan` (the build pipeline inlines the skill body here — do not paste skill content manually).
  - [ ] (d) Rewrite `## Session Workflow`: on first session (no/empty `student-profile.md`), run the onboarding flow defined in `templates/onboarding.md` (the 7 questions, field mapping, memory-init order — Story 1.5), invoking the `build-study-plan` skill to produce the week-by-week plan. **Point to `templates/onboarding.md` by name** (AC #2d requires this explicit reference). On a return session with a populated profile, offer to review/update the plan instead of re-onboarding (AC #5).
  - [ ] (e) Rewrite `## After Session` to write ALL THREE memory files per Story 1.2 ownership (the current stub only appends `session-log.md` — insufficient). Planner is the SPECIAL agent that also writes `student-profile.md` (once) and seeds `knowledge-map.md` (ARCH-13). Specify: (1) write `student-profile.md` with all 7 mapped fields + `preferred_language` + the generated `study_plan`, `memory-protocol-version: 1`; (2) seed `knowledge-map.md` Day-0 state — `**Topic:**` / `**Last updated:**` headers, all study-plan concepts under `## Never Studied ⬜`, five canonical sections in order, `memory-protocol-version: 1`; (3) append the Session 0 block to `session-log.md` with `Agent: planner`, `Mode: onboarding` (see Dev Notes for the exact block + the Mode variance). On return sessions that only update the plan, update `student-profile.md`'s `study_plan` and append a normal session entry — do not re-seed knowledge-map from scratch.

- [ ] Task 3: Rebuild and commit the compiled artifact (AC: #3)
  - [ ] Run `bash scripts/build-skills.sh` — regenerates `compiled/bmad-study-planner.md` with the refactored skill body inlined under `## Skills` (headings demoted `## → ####` by the script). `compiled/` is a TRACKED artifact (Story 1.3) — commit the regenerated file.
  - [ ] Run `bash scripts/build-skills.sh --check` — must exit `0` (compiled/ in sync).
  - [ ] Confirm the 5 structural assertions from `tests/agents/structure.test.ts` still hold: frontmatter `id`/`version`/`type`, `## On Activation`, `## Session Workflow`, `## After Session`, and `memory-protocol-version` present in the body. (These already pass for the stub; the refactor must not remove any of these sections.)

- [ ] Task 4: Validation (AC: #1, #2, #3, #6)
  - [ ] `bash scripts/lint-agnostic.sh` (default `agents/` + `skills/`) exits `0` — covers both refactored files; the agent version-gate check (Story 1.4) confirms `planner-agent.md` still contains `memory-protocol-version`.
  - [ ] `vitest run` — all tests pass (Story 1.3 structure tests + Story 1.4 lint test). The structure test runs `build-skills.sh` in `beforeAll`, so it validates the freshly compiled output.
  - [ ] AC #4/#5/#6 are behavioral (LLM runtime) — they cannot be unit-tested here. Manually dry-run the compiled agent against the AC #4 first-run scenario and the AC #5 return scenario, and confirm the AC #6 plan output respects `time_per_day` + `deadline` with no model-specific syntax. Record results in Completion Notes.

## Dev Notes

### This is the Epic 1 end-to-end spike — it must leave the whole loop working

Per epics: "This story is the Epic 1 end-to-end spike — it validates the full agent + skill + build + memory cycle before any Epic 2 agent is authored." The bar is not just "ACs pass" — it is "a student can actually run `/bmad-study-planner` from empty and end up with three valid memory files + a real study plan." Every Epic 2 agent will be cloned from this agent's structure, so get the structure exactly right.

### ⚠️ The existing stubs violate the ACs — what must change

| File | Current stub state | AC requires | Action |
|---|---|---|---|
| `skills/build-study-plan.md` | Has `## Purpose` + `## Instructions`; instructions write to `student-profile.md`/`knowledge-map.md`/`session-log.md` by name | Only `## Instructions`; **stateless, zero memory-file references** (AC #1, ARCH-2) | Strip Purpose; remove all file writes; scope to plan-building |
| `agents/planner-agent.md` | On Activation ✅ canonical; Session Workflow does NOT reference `templates/onboarding.md`; After Session only appends `session-log.md` | Session Workflow → `templates/onboarding.md`; After Session writes ALL THREE files (AC #2d, #2e) | Add onboarding.md reference; expand After Session |
| `compiled/bmad-study-planner.md` | Inlines current (wrong) skill body | Inlines refactored skill; 5 assertions pass | Rebuild via `build-skills.sh` |

### Clean separation of concerns (do not conflate these three files)

The spike stub crammed everything into the skill. The correct division:

- **`templates/onboarding.md`** (Story 1.5 — the questionnaire): the 7 questions in order, each with an example answer, the answer→field mapping, and the memory-initialization instructions. The agent's Session Workflow *points to this*.
- **`skills/build-study-plan.md`** (this story — the planner brain): stateless instructions for structuring a week-by-week plan from the collected answers. No questions, no file writes.
- **`agents/planner-agent.md`** (this story — the orchestrator): On Activation memory reads + version gate; Session Workflow that runs onboarding (per `templates/onboarding.md`) and invokes `build-study-plan`; After Session that performs the actual writes to all three memory files.

### ⚠️ Dependency on Story 1.5 (`templates/onboarding.md`)

AC #2d requires the Session Workflow to point to `templates/onboarding.md`. That file is the **Story 1.5 deliverable, currently `ready-for-dev` (NOT yet implemented).** Before/while implementing this story:
- If `templates/onboarding.md` does not yet exist, the reference would be dangling. Confirm Story 1.5 is done first (recommended — it is the natural order), OR coordinate so both land together.
- The agent should reference it as the authoritative onboarding script (e.g. "Run the onboarding flow defined in `templates/onboarding.md`"). Do not duplicate the 7 questions inside the agent file — single source of truth lives in `templates/onboarding.md`.
- The `preferred_language` field, the `Mode: onboarding` value, and the field-mapping table are all specified by Story 1.5 — reuse them, do not redefine differently.

### First-run vs version-mismatch (On Activation nuance)

The generic memory-protocol (Story 1.4) On Activation halts if `memory-protocol-version ≠ 1`. But the Planner is the agent that *creates* the memory files — on a brand-new student there are NO files yet. Distinguish:
- **Files absent** → new student → proceed to onboarding (do NOT halt). This is the AC #4 path.
- **Files present but `memory-protocol-version ≠ 1`** → older schema → halt with the canonical message (the version gate still applies).
- **Files present and version = 1** → returning student → greet by name, offer plan update (AC #5).

Make this explicit in `## On Activation` step 4/5 so the dev agent does not blindly halt on a fresh install.

### Exact memory-write specs (Story 1.2 contract — verbatim field names)

`student-profile.md` fields (from `templates/student-profile.md`): `name`, `preferred_language`, `goal`, `topic`, `current_level` (one of beginner/intermediate/advanced), `time_per_day`, `deadline` (`YYYY-MM-DD` or `None`), `preferred_style`, `study_plan` (multiline `Week N:` — Planner-only, ARCH-13). Keep `memory-protocol-version: 1` at line 1. The 7 onboarding answers map to all fields except `preferred_language` (inferred — see Story 1.5) and `study_plan` (generated by `build-study-plan`).

**Session 0 block** (append to `session-log.md`, canonical format from `templates/session-log.md`):
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
{one sentence — e.g. "Begin Week 1 with the Professor Agent on {first concept}."}

---
```
**`Mode: onboarding` variance:** `onboarding` is NOT in the canonical Mode enum (`Learn|Quiz|Review|Simulate|Think|Coach|Troubleshoot`). AC #4b explicitly requires `Mode: onboarding` for Session 0. Use it; note the intentional exception in Completion Notes (consistent with Story 1.5).

**`knowledge-map.md` Day-0 seed** (architecture lines 219–245): set `**Topic:**` and `**Last updated:**`; leave Mastered/In Progress/Gaps/Spaced Repetition Queue empty; list every study-plan concept under `## Never Studied ⬜` as `- {concept}`; keep the five canonical sections in order; `memory-protocol-version: 1`.

### Build pipeline mechanics (how inlining works — Story 1.3)

`scripts/build-skills.sh` state machine: copies the agent file; at `## Skills` it reads each `### {skill-name}`, loads `skills/{skill-name}.md`, strips its frontmatter, **demotes its headings two levels** (`## Instructions` → `#### Instructions`) so they nest under the `###` skill heading (Pattern 2: no `##` inside a `###` block), and discards the agent's placeholder lines under that `###`. So: author the skill with `## Instructions`; the compiled file will show `#### Instructions`. The script validates skill names against path traversal and is CRLF-safe. `--check` mode builds to a temp dir and diffs against `compiled/` — this is the CI guard that fails if `compiled/` was hand-edited.

### Lint scope note (ARCH-8 partial — not this story's job to fix)

`scripts/lint-agnostic.sh` today checks model names, platform tokens, context-window refs, and the agent `memory-protocol-version` gate. ARCH-8 also envisions a "memory refs in skill files" check, but that rule is NOT implemented and is NOT in this story's ACs. Therefore AC #1's statelessness is satisfied by **authoring** (manual/review), not by lint. Do not add the memory-ref lint rule here unless asked — just ensure `build-study-plan.md` genuinely contains no memory-file names. (Flagged for a future story / deferred-work.)

### Previous Story Context

- **Story 1.5 (onboarding flow, `ready-for-dev`):** owns `templates/onboarding.md` — the 7 questions, field mapping, `preferred_language` inference, `Mode: onboarding`, memory-init order. This story's agent points to it. Align, do not diverge.
- **Story 1.4 (memory protocol, `review`):** owns `templates/memory-protocol.md` — the canonical 5-step On Activation block and the verbatim halt message; extended `lint-agnostic.sh` with the agent version-gate. The Planner's On Activation must match this block (it already does).
- **Story 1.3 (build pipeline, `done`):** `build-skills.sh` (+`--check`), `compiled/` tracked, `tests/agents/structure.test.ts` asserts compiled structure. CI order: build → check → lint → tsc → vitest.
- **Story 1.2 (schema contract, `done`):** frozen field names and canonical formats — the source of truth for every write spec above.
- **Deferred-work note (1.2 review):** "`study_plan: |` pipe syntax — design question for Story 1.6 when Planner Agent writes this field." → THIS story resolves it. Decide and document how the Planner writes the multiline `study_plan` value into a plain-text (non-YAML) profile file: keep the `study_plan: |` + indented `Week N:` lines convention already present in `templates/student-profile.md`, and have the Planner write indented continuation lines under it. Note the decision in Completion Notes.

### Project Structure Notes

- Files touched: `skills/build-study-plan.md` (UPDATE/refactor), `agents/planner-agent.md` (UPDATE), `compiled/bmad-study-planner.md` (REGENERATE). No new files created by this story.
- `compiled/bmad-study-planner.md` is generated — never edit it by hand; always via `build-skills.sh` (the `--check` CI guard enforces this).
- Architecture directory structure confirms `agents/planner-agent.md`, `skills/build-study-plan.md`, and the compiled output as Epic 1 deliverables.
- Variance: epics list the three deliverables; the refactor of the (already-committed) spike stubs is implied, not a new variance — the stubs were intentionally minimal end-to-end placeholders from earlier Epic 1 work.

### References

- Story 1.6 requirements & ACs: [Source: epics.md#Story 1.6: Planner Agent & Build-Study-Plan Skill]
- FR-2.1 (Planner Agent), FR-3.4 (build-study-plan skill): [Source: epics.md#FR-2 Core Agents], [Source: epics.md#FR-3 Core Skills]
- Skill statelessness / inlining: [Source: architecture.md#Pattern 1 — Skill Inlining (lines 120–147)], [Source: epics.md#ARCH-2], [Source: epics.md#ARCH-3]
- Heading hierarchy + instruction language: [Source: architecture.md#Pattern 2 (lines 151–160)], [Source: architecture.md#Pattern 3 (lines 164–172)]
- Memory protocol On Activation block + halt message: [Source: templates/memory-protocol.md], [Source: 1-4-memory-protocol-block.md], [Source: architecture.md#Pattern 5]
- Memory write ownership (Planner writes profile once + seeds knowledge-map): [Source: epics.md#ARCH-13], [Source: architecture.md (lines 656, 702)]
- student-profile field schema: [Source: templates/student-profile.md], [Source: epics.md#Story 1.2 AC 1]
- Session-log canonical block + Day-0 seed: [Source: templates/session-log.md], [Source: templates/knowledge-map.md], [Source: architecture.md#Pattern 4 (lines 176–245)]
- Onboarding flow (questions, mapping, Mode: onboarding, preferred_language): [Source: 1-5-onboarding-flow-template.md], [Source: epics.md#Story 1.5]
- Build pipeline + compiled tracked artifact + structure assertions: [Source: scripts/build-skills.sh], [Source: tests/agents/structure.test.ts], [Source: 1-3-build-pipeline.md]
- Lint behavior + agent version-gate: [Source: scripts/lint-agnostic.sh], [Source: epics.md#ARCH-8]
- study_plan write convention (deferred from 1.2 review): [Source: deferred-work.md]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
