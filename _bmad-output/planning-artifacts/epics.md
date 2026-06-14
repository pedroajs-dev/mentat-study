---
stepsCompleted: [1, 2, 3, 4]
status: 'complete'
completedAt: '2026-06-14'
inputDocuments:
  - "_bmad-output/planning-artifacts/prds/prd-bmad-study-2026-06-12/prd.md"
  - "_bmad-output/planning-artifacts/architecture.md"
---

# bmad-study — Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for bmad-study, decomposing requirements from the PRD and Architecture into implementable stories.

---

## Requirements Inventory

### Functional Requirements

**FR-1: Memory Templates**
- FR-1.1: `templates/student-profile.md` — empty template with all fields defined (name, language, goal, topic, level, time, deadline, style, study plan)
- FR-1.2: `templates/session-log.md` — empty template with append format defined (session number, date, agent, mode, topic, duration, covered, score, gaps, next session)
- FR-1.3: `templates/knowledge-map.md` — empty template with all sections (Mastered ✅, In Progress 🔄, Gaps ❌, Never Studied ⬜, Spaced Repetition Queue)
- FR-1.4: `templates/memory-protocol.md` — reusable instruction block imported at the top of every agent skill file

**FR-2: Core Agents (Phase 1)**
- FR-2.1: Planner Agent — runs onboarding, writes all three memory files, produces week-by-week study plan in student-profile.md
- FR-2.2: Professor Agent — teaches with adapted complexity, analogies, modes (Explain / Deep Dive / Analogy / ELI5), never gives full answer before student attempts
- FR-2.3: Evaluator Agent — scores 0–10, identifies right/wrong/gaps, updates knowledge-map.md; canonical output format: Score / ✅ right / ❌ missing / 💡 review / 📚 next step
- FR-2.4: Quiz Master Agent — question types (MC, open, T/F, scenario, code); modes (Quick Quiz 5q, Deep Quiz 15q, Mock Exam timed, Spaced Repetition)
- FR-2.5: Socratic Agent — responds to questions with guiding questions only, confirms only when student reaches correct conclusion, never gives direct answers

**FR-3: Core Skills (Phase 1)**
- FR-3.1: `skills/explain-concept.md` — how Professor explains any topic
- FR-3.2: `skills/generate-quiz.md` — how Quiz Master creates questions
- FR-3.3: `skills/evaluate-answer.md` — how Evaluator scores and gives feedback
- FR-3.4: `skills/build-study-plan.md` — how Planner structures a learning journey
- FR-3.5: `skills/generate-flashcards.md` — how to generate spaced repetition cards
- FR-3.6: `skills/run-mock-exam.md` — how to run a timed full simulation

**FR-4: Onboarding Template (Phase 1)**
- FR-4.1: `templates/onboarding.md` — full onboarding flow for Planner Agent; all 7 questions, example responses, instructions for writing the three memory files

**FR-5: Examples (Phase 1)**
- FR-5.1: `examples/java-backend-interview/` — complete worked example: pre-filled student-profile, session-log (first session), knowledge-map; covers Kafka, Spring Boot, Design Patterns, System Design, behavioral STAR answers
- FR-5.2: `examples/system-design/` — complete worked example (ships Phase 1, non-blocking)
- FR-5.3: `examples/kubernetes/` — complete worked example (ships Phase 1, non-blocking)

**FR-6: Extended Agents (Phase 2)**
- FR-6.1: Coach Agent — reads all three memory files in full; interprets and directs, does not teach/quiz; answers strategic questions; surfaces Spaced Review Agent when content N+ days old with no review
- FR-6.2: Troubleshooter Agent — presents novel real-world scenarios; evaluates thinking process not just answer; rewards structured breakdown; tests judgment, not knowledge
- FR-6.3: Spaced Review Agent — reads session-log.md to identify content studied N+ days ago without revisit; orchestrates targeted review using generate-flashcards + generate-quiz; prioritizes Gaps and In Progress over Mastered; exits with updated knowledge-map and next review date

**FR-7: Extended Skills (Phase 2)**
- FR-7.1: `skills/session-opener.md` — calibrates tone based on time since last session (0–2 days: recap; 3–7 days: retrieval warmup; 8+ days: re-assess level)
- FR-7.2: `skills/build-scenario.md` — generates novel situations solvable with concepts already studied; forces synthesis not recall; ships with Troubleshooter Agent
- FR-7.3: `skills/concept-precision.md` — asks student to define a term in their own words, then challenges imprecise language
- FR-7.4: `skills/escalate-challenge.md` — triggered when score 6–8 AND gaps exist; generates harder questions targeting weak spots

**FR-8: CLI Distribution (Phase 3)**
- FR-8.1: `npx bmad-study init` installs compiled agent and skill files to `{user-project}/.claude/skills/` and seeds `memory/` with templates
- FR-8.2: CLI runs onboarding questionnaire (Inquirer) and seeds memory template files
- FR-8.3: CLI prints instructions for invoking agents in Claude Code (e.g., "Run /bmad-study-planner to start your first session")
- FR-8.4: No API keys required. No backend. Pure file + prompt distribution.
- FR-8.5: Package published to npm as `bmad-study`
- FR-8.6: Tech stack: Node.js 18+, Commander.js v14, @inquirer/prompts v8.5.2

---

### Non-Functional Requirements

- NFR-1: Model-agnostic — all agents and skills produce correct behavior with any instruction-following LLM. No model-specific syntax anywhere.
- NFR-2: Human-readable — all files are plain markdown. Any person can read an agent file and understand exactly what the AI will do.
- NFR-3: Composable — skills are stateless building blocks inlined into agent skill files at compile time. Adding a new skill does not require modifying existing agents.
- NFR-4: Bilingual — README and onboarding template in EN and PT-BR. All agent/skill files English only. Students set preferred response language in student-profile.md.
- NFR-5: Zero-friction install — `npx bmad-study init` works with Node.js 18+, no prior configuration, under 60 seconds from command to first usable file.
- NFR-6: Privacy — `memory/` is gitignored. No student data collected, transmitted, or stored outside user's local filesystem.
- NFR-7: Contributor-friendly — adding a new agent, skill, or example requires only adding a markdown file. No code changes for content contributions.

---

### Additional Requirements (from Architecture)

- ARCH-1: All agent files follow BMAD skill structure: On Activation (memory reads + schema check) → Session Workflow → After Session (memory writes)
- ARCH-2: Skills are stateless — no file read/write in skill files; all memory operations belong in agent On Activation and After Session sections
- ARCH-3: Inline skill inclusion — skills inlined into agent files under `## Skills` as `### {skill-id}` at compile time; `skills/` is authoring source; `compiled/` is distribution artifact
- ARCH-4: `scripts/build-skills.sh` assembles `compiled/` from `agents/` + `skills/`; wired as `prepublishOnly` in package.json
- ARCH-5: Invocation naming: `/bmad-study-{agent}` (e.g., `/bmad-study-professor`, `/bmad-study-planner`) — namespaced to avoid collision with other Claude Code skills
- ARCH-6: CLI TypeScript stack: Commander v14, @inquirer/prompts v8.5.2, tsup v8.5.1, Vitest v4.1.8, Node >=18
- ARCH-7: All `fs` operations in CLI go through `src/utils/files.ts` exclusively (single mock boundary for tests)
- ARCH-8: `scripts/lint-agnostic.sh` checks all agent/skill files for model names, platform-specific syntax, and memory refs in skill files; runs in CI
- ARCH-9: CI pipeline: `vitest run` + `scripts/lint-agnostic.sh` + `tsc --noEmit` on every PR
- ARCH-10: `memory-protocol-version` integer field in every memory file; agents halt and instruct re-onboarding on mismatch
- ARCH-11: Canonical session-log.md append format — `## Session [N] — YYYY-MM-DD` block with Agent / Mode / Topic / Duration / What was covered / Score / Gaps / Next recommended session
- ARCH-12: Canonical knowledge-map.md sections — Mastered ✅ / In Progress 🔄 / Gaps ❌ / Never Studied ⬜ / Spaced Repetition Queue
- ARCH-13: Memory write ownership — Planner writes student-profile.md (once); Evaluator + Spaced Review write knowledge-map.md; all agents append session-log.md; no agent may write outside its ownership
- ARCH-14: `agent-template.md` and `skill-template.md` in repo root; fully commented; serve as contributor documentation
- ARCH-15: `compiled/` and `memory/` and `dist/` are gitignored
- ARCH-16: npm package structure: `dist/index.js` + `skills/` (compiled agent skill files) + `memory-templates/` (seed files)

---

### UX Design Requirements

N/A — bmad-study is a CLI tool and content distribution system. No UI layer exists.

---

### FR Coverage Map

| FR / ARCH | Epic | Notes |
|---|---|---|
| FR-1.1–1.4 | Epic 1 | Memory templates + protocol block |
| FR-2.1 | Epic 1 | Planner Agent |
| FR-4.1 | Epic 1 | Onboarding template |
| ARCH-8, ARCH-9 | Epic 1 | lint-agnostic.sh + CI pipeline |
| ARCH-14, ARCH-15 | Epic 1 | Contributor templates + gitignore |
| ARCH-3, ARCH-4 | Epic 1 | build-skills.sh + inline inclusion contract |
| ARCH-10–13 | Epic 1 | Memory protocol: version gate, canonical formats, ownership |
| FR-2.2 | Epic 2 | Professor Agent |
| FR-2.3 | Epic 2 | Evaluator Agent |
| FR-2.4 | Epic 2 | Quiz Master Agent |
| FR-2.5 | Epic 2 | Socratic Agent |
| FR-3.1–3.6 | Epic 2 | 6 core skills |
| FR-5.1–5.3 | Epic 3 | 3 worked examples |
| FR-6.1 | Epic 4 | Coach Agent |
| FR-6.2 | Epic 4 | Troubleshooter Agent |
| FR-6.3 | Epic 4 | Spaced Review Agent |
| FR-7.1–7.4 | Epic 4 | 4 Phase 2 skills |
| FR-8.1–8.6 | Epic 5 | CLI install + npm publish |
| ARCH-5–7, ARCH-16 | Epic 5 | Invocation naming, TypeScript stack, files.ts, npm package structure |
| NFR-1–7 | All | Enforced across every epic via lint + CI + review |

---

## Epic List

### Epic 1: Memory System, Onboarding & Repo Foundation
A student can invoke the Planner Agent, complete onboarding, and walk away with three fully initialized memory files and a personalized study plan. The repo scaffolding (lint, CI, contributor templates, build pipeline) is also established here — it gates every agent file in every subsequent epic. Memory file schemas are frozen as a formal contract before Epic 2 begins.

**FRs covered:** FR-1.1, FR-1.2, FR-1.3, FR-1.4, FR-2.1, FR-4.1
**ARCH covered:** ARCH-3, ARCH-4, ARCH-8, ARCH-9, ARCH-10, ARCH-11, ARCH-12, ARCH-13, ARCH-14, ARCH-15

**Stories (pre-identified from architectural validation):**
- Repo scaffolding: .gitignore, agent-template.md, skill-template.md, CONTRIBUTING.md, scripts/lint-agnostic.sh, .github/workflows/ci.yml
- Memory schema contract: freeze all field schemas for student-profile.md, session-log.md, knowledge-map.md including Spaced Repetition Queue line format and memory-protocol-version — hard gate before Epic 2
- Build pipeline: scripts/build-skills.sh + CI drift check (compiled output diff on every PR) + prepublishOnly hook
- End-to-end spike: one agent (Planner), one skill (build-study-plan), one full cycle validated
- Memory templates: FR-1.1–1.4
- Planner Agent: FR-2.1
- Onboarding template: FR-4.1

---

### Epic 2: Core Study Loop
A student can learn with the Professor Agent, get quizzed by the Quiz Master, receive scored feedback with gap analysis from the Evaluator, and explore problems through Socratic questioning — all within an integrated loop that reads memory files on activation and writes session results after each session.

**FRs covered:** FR-2.2, FR-2.3, FR-2.4, FR-2.5, FR-3.1, FR-3.2, FR-3.3, FR-3.4, FR-3.5, FR-3.6
**Dependency:** Epic 1 memory schema contract story must be complete before any Epic 2 agent is authored.

---

### Epic 3: Examples & Worked Journeys
A student or OSS contributor can inspect three complete worked examples of the system in use — seeing what a real onboarding, first session, and evolving knowledge-map looks like across distinct domains (Java backend interview, system design, Kubernetes).

**FRs covered:** FR-5.1, FR-5.2, FR-5.3 + templates/progress-report.md (DL-007)
**Done-definition (per example directory):** must contain `student-profile.md`, `session-log-snapshot.md`, `knowledge-map-snapshot.md`, `progress-report.md`; must pass lint-agnostic.sh; all memory fields must conform to the Epic 1 schema contract.
**Dependency:** Epic 1 memory schema contract. Parallel to Epic 2.

---

### Epic 4: Strategic Layer & Retention
A student who has been using the system for 2+ weeks can get strategic direction from the Coach Agent, practice judgment under pressure with the Troubleshooter, receive targeted spaced review from the Spaced Review Agent, and push past plateaus with escalated challenges. Includes a memory schema migration guide for students upgrading from Phase 1.

**FRs covered:** FR-6.1, FR-6.2, FR-6.3, FR-7.1, FR-7.2, FR-7.3, FR-7.4

**Stories (pre-identified from architectural validation):**
- session-opener.md skill (FR-7.1) — first; used by all Phase 2 agents
- Coach Agent (FR-6.1)
- Troubleshooter Agent (FR-6.2) + build-scenario.md skill (FR-7.2) — ship together
- Spaced Review Agent (FR-6.3)
- concept-precision.md skill (FR-7.3)
- escalate-challenge.md skill (FR-7.4)
- Memory schema migration guide: templates/migration-guide.md documenting knowledge-map.md v1→v2 field delta + student upgrade instructions (manual, no CLI required)

**Dependency:** Epic 2 core loop validated.

---

### Epic 5: CLI Distribution
A new student can run `npx bmad-study init`, answer a short questionnaire, and have all compiled agent skill files installed into `.claude/skills/` and their `memory/` directory seeded with templates — in under 60 seconds, with no API keys or prior configuration.

**FRs covered:** FR-8.1, FR-8.2, FR-8.3, FR-8.4, FR-8.5, FR-8.6
**ARCH covered:** ARCH-4 (pre-publish compile step), ARCH-5 (invocation naming), ARCH-6 (TypeScript stack), ARCH-7 (files.ts mock boundary), ARCH-16 (npm package structure)

**CI execution order (explicit):** build-skills.sh → compiled/*.md → vitest → lint-agnostic.sh → tsc --noEmit. Build step must precede tests on clean checkout.

**Dependency:** Epics 1–4 complete (CLI distributes the full compiled artifact set).

---

## Epic 1: Memory System, Onboarding & Repo Foundation

A student can invoke the Planner Agent, complete onboarding, and walk away with three fully initialized memory files and a personalized study plan. The repo scaffolding (lint, CI, contributor templates, build pipeline) is established here — it gates every agent file in every subsequent epic. Memory file schemas are frozen as a formal contract before Epic 2 begins.

**FRs covered:** FR-1.1, FR-1.2, FR-1.3, FR-1.4, FR-2.1, FR-4.1
**ARCH covered:** ARCH-3, ARCH-4, ARCH-8, ARCH-9, ARCH-10, ARCH-11, ARCH-12, ARCH-13, ARCH-14, ARCH-15

---

### Story 1.1: Repo Foundation

As a contributor,
I want the repository to have all foundational scaffolding in place,
So that I can immediately start authoring agent and skill files with clear format contracts and automated quality gates.

**Deliverables:** `.gitignore`, `README.md` (stub), `README.pt.md` (stub), `agent-template.md`, `skill-template.md`, `CONTRIBUTING.md`, `scripts/lint-agnostic.sh`, `.github/workflows/ci.yml`

**Acceptance Criteria:**

**Given** a fresh clone of the repo
**When** I open `.gitignore`
**Then** `memory/`, `dist/`, `compiled/`, and `node_modules/` are listed as gitignored entries

**Given** I read `agent-template.md` and `skill-template.md`
**When** I follow their structure
**Then** I can produce a valid agent or skill file that passes lint without reading any other documentation — every required section and frontmatter field is shown by example with inline comments

**Given** I run `scripts/lint-agnostic.sh` against any file in `agents/` or `skills/`
**When** the file contains a model name (e.g., "GPT-4", "Claude", "Gemini"), a platform-specific syntax, or a context-window-size reference
**Then** the script exits non-zero and reports the offending line and filename

**Given** a PR is opened against main
**When** CI runs
**Then** the workflow executes in order: `scripts/lint-agnostic.sh` → `tsc --noEmit` → `vitest run`; all three must pass for the PR check to succeed

**Given** I read `CONTRIBUTING.md`
**When** I want to add a new agent or skill
**Then** I find: (a) where to place the file, (b) required YAML frontmatter fields (`id`, `version`, `type`), (c) how to run lint locally, (d) how to build `compiled/` and verify output

**Given** CI runs on a PR and `lint-agnostic.sh` fails
**When** the CI log is inspected
**Then** the offending line is visible and the workflow exits with a non-zero code

---

### Story 1.2: Memory Schema Contract & Templates

As a student,
I want complete, structured memory file templates with all fields and formats defined,
So that every agent I use reads and writes my personal study data in a consistent, predictable format from day one.

**Deliverables:** `templates/student-profile.md`, `templates/session-log.md`, `templates/knowledge-map.md`
**Note:** This story's output is the schema contract — a hard gate before any Epic 2 agent is authored.

**Acceptance Criteria:**

**Given** `templates/student-profile.md` exists
**When** an agent or contributor reads it
**Then** it contains `memory-protocol-version: 1` and all fields: `name`, `preferred_language`, `goal`, `topic`, `current_level`, `time_per_day`, `deadline`, `preferred_style`, `study_plan` — each with an inline comment explaining its purpose and expected format

**Given** `templates/session-log.md` exists
**When** an agent appends a completed session
**Then** the canonical append block format is exactly:
```
## Session [N] — YYYY-MM-DD
**Agent:** {agent-id}
**Mode:** {Learn|Quiz|Review|Simulate|Think|Coach|Troubleshoot}
**Topic:** {specific topic covered}
**Duration:** {X} minutes

### What was covered
- {bullet list}

### Score
{X/10 or N/A}

### Gaps identified
- {bullet list, or "None"}

### Next recommended session
{one sentence}

---
```

**Given** `templates/knowledge-map.md` exists
**When** an agent reads or writes it
**Then** it contains these exact five sections in order: `## Mastered ✅`, `## In Progress 🔄`, `## Gaps ❌`, `## Never Studied ⬜`, `## Spaced Repetition Queue`
**And** the Spaced Repetition Queue canonical line format is: `- {concept} — review by {YYYY-MM-DD}`

**Given** an agent reads a memory file and finds `memory-protocol-version` missing or set to a value other than `1`
**When** it attempts to start a session
**Then** it halts immediately and outputs exactly: `"Your memory files are from an older version. Please re-run onboarding with /bmad-study-planner."`

**Given** a contributor authors any agent file in Epic 2 or beyond
**When** they write the On Activation memory reads
**Then** they reference the exact field names defined in these templates without deviation — no aliases, no renamed fields

---

### Story 1.3: Build Pipeline

As a contributor,
I want a build pipeline that assembles compiled agent skill files from authoring sources,
So that I can verify my agent + skill combination produces correct output and CI catches any direct edits to `compiled/`.

**Deliverables:** `scripts/build-skills.sh`, `package.json` (prepublishOnly hook), `tests/agents/structure.test.ts`

**Acceptance Criteria:**

**Given** `agents/planner-agent.md` contains `### build-study-plan` under `## Skills` and `skills/build-study-plan.md` exists
**When** I run `bash scripts/build-skills.sh`
**Then** `compiled/bmad-study-planner.md` is created with the full content of `skills/build-study-plan.md` inlined under `## Skills`

**Given** `compiled/bmad-study-planner.md` was generated by `build-skills.sh`
**When** a contributor edits `compiled/bmad-study-planner.md` directly and opens a PR
**Then** CI runs `build-skills.sh`, diffs the output against the committed file, finds a mismatch, and fails with a message: `"compiled/ must not be edited directly — run build-skills.sh"`

**Given** `package.json` has `"prepublishOnly": "bash scripts/build-skills.sh"`
**When** `npm publish` is run
**Then** `build-skills.sh` executes before the package is published, ensuring `compiled/` is always up to date at publish time

**Given** `tests/agents/structure.test.ts` exists and `vitest run` executes
**When** it runs against any file in `compiled/*.md`
**Then** for each compiled agent file, the test asserts: (a) YAML frontmatter is present with `id`, `version`, and `type` fields, (b) `## On Activation` section exists, (c) `## Session Workflow` section exists, (d) `## After Session` section exists, (e) the string `memory-protocol-version` appears in the file body

**Given** `build-skills.sh` runs on a CI agent with a clean checkout
**When** it completes
**Then** it exits `0` and `compiled/` contains exactly one `.md` file per agent file in `agents/`

---

### Story 1.4: Memory Protocol Block

As a contributor,
I want a canonical, reusable On Activation instruction block,
So that every agent file uses identical memory-loading language and the version gate is never omitted or rephrased.

**Deliverables:** `templates/memory-protocol.md`

**Acceptance Criteria:**

**Given** `templates/memory-protocol.md` exists
**When** I read it
**Then** it contains the exact On Activation steps in order: (1) Read `{project-root}/memory/student-profile.md`, (2) Read `{project-root}/memory/knowledge-map.md`, (3) Read last 3 entries of `{project-root}/memory/session-log.md`, (4) Check `memory-protocol-version` — if ≠ 1, halt and output the canonical mismatch message from Story 1.2, (5) Greet student by name and confirm current topic

**Given** `templates/memory-protocol.md` exists
**When** I read the After Session section
**Then** it contains: (1) Append to `{project-root}/memory/session-log.md` using the canonical format from Story 1.2, (2) [Evaluator + Spaced Review only] Update `{project-root}/memory/knowledge-map.md`

**Given** `scripts/lint-agnostic.sh` runs on any file with `type: agent` in frontmatter
**When** the file is missing the `memory-protocol-version` check instruction
**Then** lint fails with a message identifying the missing check

---

### Story 1.5: Onboarding Flow Template

As a student,
I want a structured onboarding flow that the Planner Agent follows,
So that setup is consistent, all required data is collected in the right order, and my memory files are populated correctly on the first session.

**Deliverables:** `templates/onboarding.md`

**Acceptance Criteria:**

**Given** `templates/onboarding.md` exists
**When** the Planner Agent reads it
**Then** it contains all 7 onboarding questions in order: (1) What is your name?, (2) What topic are you studying?, (3) What is your goal?, (4) What is your current level (beginner / intermediate / advanced)?, (5) How much time can you dedicate per day?, (6) Do you have a deadline?, (7) What is your preferred learning style?
**And** each question includes an example response showing the expected format and level of detail

**Given** `templates/onboarding.md` exists
**When** the Planner Agent completes the questionnaire
**Then** the template provides explicit field-mapping instructions: which `student-profile.md` field each answer maps to and the exact write format

**Given** `templates/onboarding.md` exists
**When** I read the memory initialization instructions
**Then** they instruct the Planner Agent to: (a) populate all `student-profile.md` fields, (b) initialize `knowledge-map.md` with all topic concepts under `## Never Studied ⬜`, (c) write `session-log.md` with a Session 0 entry (onboarding session) as the first record

---

### Story 1.6: Planner Agent & Build-Study-Plan Skill

As a student,
I want to invoke `/bmad-study-planner` and complete onboarding in a single session,
So that my three memory files are fully populated with my study goals, topic, level, deadline, and a personalized week-by-week study plan — and I never need to repeat onboarding.

**Deliverables:** `skills/build-study-plan.md`, `agents/planner-agent.md`, `compiled/bmad-study-planner.md` (via build-skills.sh)
**Note:** This story is the Epic 1 end-to-end spike — it validates the full agent + skill + build + memory cycle before any Epic 2 agent is authored.

**Acceptance Criteria:**

**Given** `skills/build-study-plan.md` exists
**When** I read it and run `scripts/lint-agnostic.sh` against it
**Then** it is stateless (no references to `session-log.md`, `knowledge-map.md`, or `student-profile.md` by filename), contains only `## Instructions` with model-agnostic language, and lint exits `0`

**Given** `agents/planner-agent.md` exists
**When** I read it
**Then** it follows the BMAD skill structure in order: (a) agent persona + title block, (b) `## On Activation` with all 5 memory protocol steps from Story 1.4, (c) `## Skills` section with `### build-study-plan` referencing the skill, (d) `## Session Workflow` with onboarding flow instructions pointing to `templates/onboarding.md`, (e) `## After Session` with instructions to write all three memory files per Story 1.2 ownership rules

**Given** `bash scripts/build-skills.sh` runs after both files exist
**When** it completes
**Then** `compiled/bmad-study-planner.md` exists with `build-study-plan.md` content inlined under `## Skills` and all 5 structural assertions from Story 1.3 pass against it

**Given** a student invokes `/bmad-study-planner` with no existing `memory/` files
**When** the session completes all 7 onboarding questions
**Then** `memory/student-profile.md`, `memory/session-log.md`, and `memory/knowledge-map.md` all exist and contain: (a) `student-profile.md` has all 7 answers in the correct fields with `memory-protocol-version: 1`, (b) `session-log.md` has a Session 0 entry with `Agent: planner`, `Mode: onboarding`, and the study plan summary, (c) `knowledge-map.md` has all topic concepts under `## Never Studied ⬜` and `memory-protocol-version: 1`

**Given** a student invokes `/bmad-study-planner` a second time with memory files already present
**When** On Activation runs
**Then** the agent reads the existing files, greets the student by name, and offers to update the study plan rather than re-running full onboarding

**Given** `compiled/bmad-study-planner.md` is loaded into any instruction-following LLM
**When** the student answers all 7 onboarding questions
**Then** the agent produces a structured week-by-week study plan matching the student's stated time budget and deadline — with no model-specific syntax or platform-specific features required

---

## Epic 2: Core Study Loop

A student can learn with the Professor Agent, get quizzed by the Quiz Master, receive scored feedback with gap analysis from the Evaluator, and explore problems through Socratic questioning — all within an integrated loop that reads memory files on activation and writes session results after each session.

**FRs covered:** FR-2.2, FR-2.3, FR-2.4, FR-2.5, FR-3.1, FR-3.2, FR-3.3, FR-3.5, FR-3.6
**Note:** FR-3.4 (build-study-plan.md) delivered in Story 1.6.
**Dependency:** Story 1.2 memory schema contract must be complete before any story in this epic is authored.

---

### Story 2.1: Professor Agent & Explain-Concept Skill

As a student,
I want to invoke `/bmad-study-professor` to learn any topic in my study plan,
So that I receive adaptive, structured explanations with real-world examples matched to my level — without being given the full answer before I attempt understanding.

**Deliverables:** `skills/explain-concept.md` (FR-3.1), `agents/professor-agent.md` (FR-2.2), `compiled/bmad-study-professor.md`

**Acceptance Criteria:**

**Given** `skills/explain-concept.md` exists
**When** `scripts/lint-agnostic.sh` runs against it
**Then** it is stateless (no references to `session-log.md`, `knowledge-map.md`, or `student-profile.md` by filename), model-agnostic, and lint exits `0`

**Given** `agents/professor-agent.md` exists
**When** I read it
**Then** it follows BMAD skill structure: On Activation (all 5 protocol steps from Story 1.4), `## Skills` with `explain-concept` inlined, `## Session Workflow` supporting 4 modes (Explain / Deep Dive / Analogy Mode / ELI5), `## After Session` appending `session-log.md`

**Given** `bash scripts/build-skills.sh` runs
**When** it completes
**Then** `compiled/bmad-study-professor.md` contains `explain-concept.md` content inlined and passes all 5 structural assertions from Story 1.3

**Given** `/bmad-study-professor` is invoked with a student profile showing `current_level: intermediate`
**When** the student asks to explain a topic
**Then** the agent: (a) confirms the student's current level before teaching, (b) uses at least one real-world analogy, (c) breaks the topic into chunks, (d) asks the student a guiding question before delivering the full explanation
**And** never gives the complete answer before the student has attempted engagement

**Given** the student requests ELI5 mode
**When** the Professor responds
**Then** the explanation uses vocabulary appropriate for a complete beginner regardless of the student profile level

**Given** a session completes
**When** After Session runs
**Then** `session-log.md` is appended with `Agent: professor`, the correct Mode, and the topics covered listed under `### What was covered`

**Given** `compiled/bmad-study-professor.md` is loaded into any instruction-following LLM
**When** the student requests an explanation
**Then** the agent satisfies all FR-2.2 behavior bullets across three distinct test prompts without model-specific syntax

---

### Story 2.2: Evaluator Agent & Evaluate-Answer Skill

As a student,
I want to invoke `/bmad-study-evaluator` to get scored feedback on my answers,
So that I know exactly what I got right, what was missing, and what to study next — and my knowledge map is updated to reflect my current understanding.

**Deliverables:** `skills/evaluate-answer.md` (FR-3.3), `agents/evaluator-agent.md` (FR-2.3), `compiled/bmad-study-evaluator.md`

**Acceptance Criteria:**

**Given** `skills/evaluate-answer.md` exists
**When** `scripts/lint-agnostic.sh` runs against it
**Then** it is stateless and model-agnostic and lint exits `0`

**Given** `agents/evaluator-agent.md` exists
**When** I read it
**Then** it follows BMAD skill structure with On Activation (5 protocol steps including reading `knowledge-map.md`), `evaluate-answer` inlined under `## Skills`, and After Session that both appends `session-log.md` AND updates `knowledge-map.md`

**Given** `/bmad-study-evaluator` is invoked and the student submits an answer
**When** the Evaluator responds
**Then** the output is exactly:
```
Score: X/10
✅ What was right:
❌ What was missing or incorrect:
💡 What to review:
📚 Suggested next step:
```

**Given** the Evaluator scores an answer
**When** After Session updates `knowledge-map.md`
**Then** concepts scored 9–10 are moved to `## Mastered ✅` with `confirmed {YYYY-MM-DD}`, concepts scored 5–8 are placed in `## In Progress 🔄` with `last seen {YYYY-MM-DD}`, concepts scored 0–4 are placed in `## Gaps ❌` with `wrong/incomplete on {YYYY-MM-DD}`

**Given** a concept is added to `## Spaced Repetition Queue`
**When** the entry is written
**Then** it uses the canonical format: `- {concept} — review by {YYYY-MM-DD}`
**And** the review date is 3 days from evaluation for Gaps, 7 days for In Progress

**Given** a session completes
**When** `session-log.md` is appended
**Then** the `### Score` field contains the numeric score and `### Gaps identified` lists the specific gaps surfaced during evaluation

**Given** `compiled/bmad-study-evaluator.md` is loaded into any instruction-following LLM
**When** the student submits an answer
**Then** the agent satisfies all FR-2.3 behavior bullets across three distinct test prompts

---

### Story 2.3: Quiz Master Agent & Quiz Skills

As a student,
I want to invoke `/bmad-study-quiz` to be tested on my study topic,
So that I can assess my knowledge through varied question types and modes — from quick 5-question checks to timed full mock exams and spaced repetition drills.

**Deliverables:** `skills/generate-quiz.md` (FR-3.2), `skills/generate-flashcards.md` (FR-3.5), `skills/run-mock-exam.md` (FR-3.6), `agents/quiz-agent.md` (FR-2.4), `compiled/bmad-study-quiz.md`

**Acceptance Criteria:**

**Given** `skills/generate-quiz.md`, `skills/generate-flashcards.md`, and `skills/run-mock-exam.md` exist
**When** `scripts/lint-agnostic.sh` runs against each
**Then** all three are stateless, model-agnostic, and lint exits `0` for each

**Given** `agents/quiz-agent.md` exists
**When** I read it
**Then** it follows BMAD skill structure with all three skills inlined under `## Skills` and `## Session Workflow` supporting 4 named modes: Quick Quiz (5 questions, ~10 min), Deep Quiz (15 questions, ~30 min), Mock Exam (timed simulation), Spaced Repetition (targets `## Spaced Repetition Queue` from `knowledge-map.md`)

**Given** `/bmad-study-quiz` is invoked in Quick Quiz mode
**When** the session runs
**Then** the agent generates exactly 5 questions covering a mix of types: at least one multiple choice (4 options), one open-ended, and one scenario-based — all drawn from the student's current topic and knowledge-map state

**Given** `/bmad-study-quiz` is invoked in Spaced Repetition mode
**When** On Activation reads `knowledge-map.md`
**Then** the quiz targets only concepts in `## Spaced Repetition Queue` whose review date is on or before the current date — not Mastered concepts

**Given** `/bmad-study-quiz` is invoked in Mock Exam mode
**When** the session runs
**Then** the agent establishes a time boundary, presents all questions without per-question feedback, and delivers a summary score with gap breakdown only after all questions are answered

**Given** a session completes
**When** `session-log.md` is appended
**Then** the entry includes `Agent: quiz`, the correct Mode, the number of questions asked, and the overall score

**Given** `compiled/bmad-study-quiz.md` is loaded into any instruction-following LLM
**When** the student requests a quiz
**Then** the agent satisfies all FR-2.4 behavior bullets across three distinct test prompts

---

### Story 2.4: Socratic Agent

As a student,
I want to invoke `/bmad-study-socratic` to think through a problem with a guide who never gives direct answers,
So that I develop genuine understanding by reaching conclusions through my own reasoning rather than being told what to think.

**Deliverables:** `agents/socratic-agent.md` (FR-2.5), `compiled/bmad-study-socratic.md`
**Note:** The Socratic Agent has no unique skill file — its behavior is purely conversational and lives in the agent file itself.

**Acceptance Criteria:**

**Given** `agents/socratic-agent.md` exists
**When** I read it
**Then** it follows BMAD skill structure with On Activation (5 protocol steps), `## Session Workflow` encoding the Socratic dialogue rules, and `## After Session` appending `session-log.md`

**Given** `/bmad-study-socratic` is invoked and the student asks a direct question
**When** the agent responds
**Then** it replies with a guiding question rather than an answer (e.g., student asks "What is Kafka?" → agent replies "What do you already know about how systems pass messages between services?")
**And** it does not give the direct answer at any point before the student arrives at a correct conclusion

**Given** the student provides an incorrect or incomplete answer
**When** the Socratic Agent responds
**Then** it asks a follow-up question targeting the specific gap in the student's reasoning — never correcting directly

**Given** the student reaches the correct conclusion through their own reasoning
**When** the Socratic Agent responds
**Then** it confirms explicitly and may summarize the reasoning path that led there

**Given** a session completes
**When** `session-log.md` is appended
**Then** the entry includes `Agent: socratic`, `Mode: Think`, the topic discussed, and any reasoning gaps observed during the session under `### Gaps identified`

**Given** `compiled/bmad-study-socratic.md` is loaded into any instruction-following LLM
**When** the student asks questions across three distinct test prompts
**Then** the agent never gives a direct answer before the student reaches the conclusion — satisfying all FR-2.5 behavior bullets

---

## Epic 3: Examples & Worked Journeys

A student or OSS contributor can inspect three complete worked examples of the system in use — seeing what a real onboarding, first session, and evolving knowledge map looks like across distinct domains (Java backend interview, system design, Kubernetes).

**FRs covered:** FR-5.1, FR-5.2, FR-5.3 + `templates/progress-report.md` (DL-007)
**Done-definition (per example directory):** must contain `student-profile.md`, `session-log-snapshot.md`, `knowledge-map-snapshot.md`, `progress-report.md`; all files must pass `lint-agnostic.sh`; all memory fields must conform to the Story 1.2 schema contract.
**Dependency:** Story 1.2 schema contract. Parallel to Epic 2.

---

### Story 3.1: Progress Report Template

As a student,
I want a progress report template that summarizes where I am in my study journey,
So that I can generate a snapshot of my progress at any point and share it or review it without opening all three memory files.

**Deliverables:** `templates/progress-report.md`

**Acceptance Criteria:**

**Given** `templates/progress-report.md` exists
**When** I read it
**Then** it contains sections for: (a) student name and topic, (b) study plan summary (goal, deadline, time per day), (c) overall progress percentage (Mastered / total concepts), (d) current gaps list, (e) Spaced Repetition Queue summary, (f) last session date and next recommended session, (g) overall assessment (On Track / At Risk / Ahead)

**Given** an agent or student fills out `templates/progress-report.md` using data from the three memory files
**When** the resulting report is read
**Then** all values are derived directly from `student-profile.md`, `knowledge-map.md`, and `session-log.md` — no values require data not present in those three files

**Given** `templates/progress-report.md` exists
**When** `scripts/lint-agnostic.sh` runs against it
**Then** lint exits `0`

---

### Story 3.2: Java Backend Interview Example

As a student or contributor,
I want a complete worked example of a Java backend interview study journey,
So that I can understand exactly what real memory files look like after onboarding and a first session — and use it as a reference when setting up my own study.

**Deliverables:** `examples/java-backend-interview/student-profile.md`, `examples/java-backend-interview/session-log-snapshot.md`, `examples/java-backend-interview/knowledge-map-snapshot.md`, `examples/java-backend-interview/progress-report.md`

**Acceptance Criteria:**

**Given** `examples/java-backend-interview/` exists
**When** I read `student-profile.md`
**Then** all fields from the Story 1.2 schema are populated with realistic values: name, goal (Java backend interview prep), topic, current_level, time_per_day, deadline, preferred_style, study_plan (week-by-week covering Kafka, Spring Boot, Design Patterns, System Design, behavioral STAR answers), and `memory-protocol-version: 1`

**Given** `examples/java-backend-interview/session-log-snapshot.md` exists
**When** I read it
**Then** it contains at least one complete session entry using the canonical format from Story 1.2, with `Agent: professor` or `Agent: planner`, a realistic topic (e.g., "Kafka consumer groups"), a score or N/A, and at least one gap identified

**Given** `examples/java-backend-interview/knowledge-map-snapshot.md` exists
**When** I read it
**Then** all five canonical sections are present, populated with realistic Java backend interview concepts distributed across Mastered ✅, In Progress 🔄, Gaps ❌, Never Studied ⬜, and Spaced Repetition Queue sections
**And** at least one Spaced Repetition Queue entry uses the canonical line format

**Given** `examples/java-backend-interview/progress-report.md` exists
**When** I read it
**Then** all values are consistent with the `student-profile.md` and `knowledge-map-snapshot.md` in the same directory

**Given** `scripts/lint-agnostic.sh` runs against all four files in `examples/java-backend-interview/`
**When** it completes
**Then** lint exits `0` for every file

---

### Story 3.3: System Design & Kubernetes Examples

As a student or contributor,
I want two additional worked examples covering system design and Kubernetes,
So that the example library demonstrates the system's versatility across distinct study domains.

**Deliverables:** `examples/system-design/` (4 files), `examples/kubernetes/` (4 files) — same structure as Story 3.2

**Acceptance Criteria:**

**Given** `examples/system-design/` and `examples/kubernetes/` both exist
**When** I read each directory
**Then** both contain: `student-profile.md`, `session-log-snapshot.md`, `knowledge-map-snapshot.md`, `progress-report.md`

**Given** any of the eight example files
**When** `scripts/lint-agnostic.sh` runs against it
**Then** lint exits `0`

**Given** the example files in both directories
**When** I compare their schema to the Story 1.2 contract
**Then** every `memory-protocol-version` field is `1`, every session-log entry uses the canonical format, every knowledge-map file contains all five canonical sections, and every Spaced Repetition Queue entry uses the canonical line format

**Given** the system-design example
**When** I read `student-profile.md`
**Then** the topic, concepts, and knowledge-map reflect a realistic system design study journey (e.g., covering CAP theorem, consistent hashing, load balancing, database sharding) — distinct from the Java backend example

**Given** the Kubernetes example
**When** I read `student-profile.md`
**Then** the topic, concepts, and knowledge-map reflect a realistic Kubernetes study journey (e.g., covering pods, deployments, services, ingress, RBAC, persistent volumes) — distinct from the other two examples

---

## Epic 4: Strategic Layer & Retention

A student who has been using the system for 2+ weeks can get strategic direction from the Coach Agent, practice judgment under pressure with the Troubleshooter, receive targeted spaced review, and push past plateaus with escalated challenges. Includes a memory schema migration guide for students upgrading from Phase 1.

**FRs covered:** FR-6.1, FR-6.2, FR-6.3, FR-7.1, FR-7.2, FR-7.3, FR-7.4
**Dependency:** Epic 2 core loop validated.

---

### Story 4.1: Session Opener Skill

As a student,
I want every session to begin with a warm-up calibrated to how long I've been away,
So that I re-engage with the right tone and intensity — a quick recap after 2 days, a retrieval warmup after a week, a full re-assessment after a month.

**Deliverables:** `skills/session-opener.md` (FR-7.1)
**Note:** This skill ships first — it is inlined into every Phase 2 agent.

**Acceptance Criteria:**

**Given** `skills/session-opener.md` exists
**When** `scripts/lint-agnostic.sh` runs against it
**Then** it is stateless, model-agnostic, and lint exits `0`

**Given** `skills/session-opener.md` exists
**When** I read the `## Instructions`
**Then** it defines three re-entry behaviors keyed to time since last session: (a) 0–2 days: brief recap of where things left off, (b) 3–7 days: retrieval warmup before continuing — one or two questions on the previous topic, (c) 8+ days: re-assess current level before jumping back in — mini diagnostic before resuming the plan

**Given** any Phase 2 agent inlines `session-opener` under `## Skills`
**When** On Activation completes and the agent reads the last session date from `session-log.md`
**Then** the agent applies the correct re-entry behavior from session-opener before beginning the main session workflow

---

### Story 4.2: Coach Agent

As a student,
I want to invoke `/bmad-study-coach` to get a strategic read on my study journey,
So that I know whether I'm on track, what to focus on next, and when a gap is critical versus minor — without having to interpret the memory files myself.

**Deliverables:** `agents/coach-agent.md` (FR-6.1), `compiled/bmad-study-coach.md`

**Acceptance Criteria:**

**Given** `agents/coach-agent.md` exists
**When** I read it
**Then** it follows BMAD skill structure with On Activation that reads ALL entries of `session-log.md` (not just last 3 — the only agent with this expanded read scope), `session-opener` inlined under `## Skills`, `## Session Workflow` covering strategic direction, and `## After Session` appending `session-log.md`

**Given** `/bmad-study-coach` is invoked
**When** the student asks "Am I on track for my deadline?"
**Then** the agent reads `student-profile.md` (deadline, time per day), `knowledge-map.md` (Mastered vs Gaps ratio), and `session-log.md` (session frequency and recency), and gives a direct assessment: On Track / At Risk / Ahead — with specific reasoning

**Given** `/bmad-study-coach` is invoked
**When** the student asks "What should I focus on this week?"
**Then** the agent prioritizes from `## Gaps ❌` and `## In Progress 🔄` in `knowledge-map.md`, cross-references the study plan in `student-profile.md`, and returns a ranked list of 2–3 specific concepts to work on

**Given** `session-log.md` contains content studied 10+ days ago with no revisit
**When** the Coach Agent runs its session workflow
**Then** it surfaces a recommendation and offers a Spaced Review handoff: `"You studied {concept} {N} days ago with a gap in {specific gap} — want me to run a spaced review session? Invoke /bmad-study-spaced-review."`

**Given** a session completes
**When** `session-log.md` is appended
**Then** the entry includes `Agent: coach`, `Mode: Coach`, and the strategic recommendations given

**Given** `compiled/bmad-study-coach.md` is loaded into any instruction-following LLM
**When** the student asks strategic questions across three distinct test prompts
**Then** the agent satisfies all FR-6.1 behavior bullets

---

### Story 4.3: Troubleshooter Agent & Build-Scenario Skill

As a student,
I want to invoke `/bmad-study-troubleshooter` to practice applying my knowledge to real-world scenarios I've never seen before,
So that I develop judgment under pressure — not just the ability to recall facts, but the ability to reason through unfamiliar problems.

**Deliverables:** `skills/build-scenario.md` (FR-7.2), `agents/troubleshooter-agent.md` (FR-6.2), `compiled/bmad-study-troubleshooter.md`

**Acceptance Criteria:**

**Given** `skills/build-scenario.md` exists
**When** `scripts/lint-agnostic.sh` runs against it
**Then** it is stateless, model-agnostic, and lint exits `0`

**Given** `agents/troubleshooter-agent.md` exists
**When** I read it
**Then** it follows BMAD skill structure with `session-opener` and `build-scenario` inlined under `## Skills`, and `## Session Workflow` encoding judgment-evaluation rules distinct from Quiz Master

**Given** `/bmad-study-troubleshooter` is invoked and the agent reads `knowledge-map.md`
**When** it generates a scenario
**Then** the scenario is solvable using only concepts already in `## Mastered ✅` or `## In Progress 🔄` — it never requires knowledge marked `## Never Studied ⬜`

**Given** the student responds to a scenario
**When** the Troubleshooter evaluates the response
**Then** it evaluates the thinking process and structure of the answer, not just factual correctness — explicitly rewarding structured breakdown: "I'd first check... then I'd look at... if that fails I'd..."

**Given** the student gives a factually correct but poorly structured answer
**When** the Troubleshooter responds
**Then** it acknowledges the correctness but asks the student to articulate their reasoning path more explicitly

**Given** a session completes
**When** `session-log.md` is appended
**Then** the entry includes `Agent: troubleshooter`, `Mode: Simulate`, the scenario topic, and the reasoning quality assessment under `### Score`

**Given** `compiled/bmad-study-troubleshooter.md` is loaded into any instruction-following LLM
**When** the student works through scenarios across three distinct test prompts
**Then** the agent satisfies all FR-6.2 behavior bullets — testing judgment, not recall

---

### Story 4.4: Spaced Review Agent

As a student,
I want to invoke `/bmad-study-spaced-review` to run a targeted review session on content I studied days or weeks ago,
So that I consolidate long-term retention on concepts that need reinforcement before they fade.

**Deliverables:** `agents/spaced-review-agent.md` (FR-6.3), `compiled/bmad-study-spaced-review.md`

**Acceptance Criteria:**

**Given** `agents/spaced-review-agent.md` exists
**When** I read it
**Then** it follows BMAD skill structure with `session-opener`, `generate-flashcards`, and `generate-quiz` inlined under `## Skills`, and `## After Session` that both appends `session-log.md` AND updates `knowledge-map.md`

**Given** `/bmad-study-spaced-review` is invoked
**When** On Activation reads `session-log.md` and `knowledge-map.md`
**Then** the agent identifies all concepts in `## Spaced Repetition Queue` whose review date is on or before the current date and prioritizes `## Gaps ❌` and `## In Progress 🔄` over `## Mastered ✅` content

**Given** the Spaced Review session completes
**When** After Session updates `knowledge-map.md`
**Then** each reviewed concept has its Spaced Repetition Queue entry updated with a new review date: concepts that improved move to `## In Progress 🔄` or `## Mastered ✅` and receive a longer interval (14 days); concepts that did not improve remain in `## Gaps ❌` with a shorter interval (3 days)

**Given** `compiled/bmad-study-spaced-review.md` is loaded into any instruction-following LLM
**When** the student runs a spaced review session
**Then** the agent satisfies all FR-6.3 behavior bullets across three distinct test prompts

---

### Story 4.5: Concept Precision & Escalate-Challenge Skills

As a student,
I want my study sessions to challenge imprecise language and push me harder when I'm plateauing,
So that I develop precise understanding of concepts and don't get stuck in the comfortable 6–8/10 range.

**Deliverables:** `skills/concept-precision.md` (FR-7.3), `skills/escalate-challenge.md` (FR-7.4)

**Acceptance Criteria:**

**Given** `skills/concept-precision.md` exists
**When** I read it and lint runs
**Then** it is stateless, model-agnostic, and defines instructions for: asking the student to define a term in their own words, then identifying and challenging imprecise or borrowed language (e.g., "You said Kafka is a 'messaging system' — what specifically distinguishes it from RabbitMQ?")

**Given** `skills/escalate-challenge.md` exists
**When** I read it and lint runs
**Then** it is stateless, model-agnostic, and defines a trigger condition: score 6–8 AND at least one gap identified in the same session — when both are true, the skill instructs the agent to generate a harder follow-up question targeting the specific weak spot rather than moving on

**Given** either skill is inlined into a Phase 2 agent and the trigger condition fires
**When** the agent applies the skill
**Then** the behavior matches the skill instructions without deviation — the agent does not skip the escalation or apply it outside the trigger condition

**Given** both skills exist
**When** `scripts/lint-agnostic.sh` runs against each
**Then** lint exits `0` for both

---

### Story 4.6: Memory Schema Migration Guide

As a student who completed Phase 1 onboarding,
I want clear instructions for upgrading my memory files to the Phase 2 schema,
So that I can use Phase 2 agents without hitting the version mismatch halt and without losing my existing study data.

**Deliverables:** `templates/migration-guide.md`

**Acceptance Criteria:**

**Given** `templates/migration-guide.md` exists
**When** I read it
**Then** it documents every field added to any memory file between `memory-protocol-version: 1` (Phase 1) and `memory-protocol-version: 2` (Phase 2 if applicable) — with the exact line to add and where to place it in the file

**Given** `templates/migration-guide.md` exists
**When** a student follows its instructions
**Then** they can manually update their existing memory files to the new schema in under 5 minutes without any CLI tooling

**Given** no schema changes were made between Phase 1 and Phase 2
**When** I read `templates/migration-guide.md`
**Then** it explicitly states `memory-protocol-version` remains `1` and no migration is needed — it is not an empty file

**Given** Phase 2 agents are invoked after a student follows the migration guide
**When** On Activation checks `memory-protocol-version`
**Then** the version check passes and the session proceeds normally

---

## Epic 5: CLI Distribution

A new student can run `npx bmad-study init`, answer a short questionnaire, and have all compiled agent skill files installed into `.claude/skills/` and their `memory/` directory seeded with templates — in under 60 seconds, with no API keys or prior configuration.

**FRs covered:** FR-8.1, FR-8.2, FR-8.3, FR-8.4, FR-8.5, FR-8.6
**ARCH covered:** ARCH-4 (pre-publish compile), ARCH-5 (invocation naming), ARCH-6 (TypeScript stack), ARCH-7 (files.ts boundary), ARCH-16 (npm package structure)
**CI execution order:** `build-skills.sh` → `compiled/*.md` → `vitest run` → `lint-agnostic.sh` → `tsc --noEmit`
**Dependency:** Epics 1–4 complete (CLI distributes the full compiled artifact set).

---

### Story 5.1: CLI Project Scaffold & TypeScript Setup

As a contributor,
I want the CLI source tree and build toolchain configured,
So that I can write and test TypeScript CLI code with a working build, test, and type-check pipeline from the first commit.

**Deliverables:** `package.json` (complete), `tsconfig.json`, `tsup.config.ts`, `vitest.config.ts`, `src/types/index.ts`, `src/utils/files.ts` (interface only, stubbed implementations)

**Acceptance Criteria:**

**Given** the CLI scaffold exists
**When** I run `npm run build`
**Then** `tsup` compiles `src/index.ts` to `dist/index.js` in CJS format with type declarations, and exits `0`

**Given** the CLI scaffold exists
**When** I run `npm test`
**Then** `vitest run` executes and exits `0` (stub tests pass)

**Given** the CLI scaffold exists
**When** I run `tsc --noEmit`
**Then** TypeScript reports no errors

**Given** `src/utils/files.ts` exists
**When** I read it
**Then** it exports exactly: `copyFile(src, dest)`, `ensureDir(path)`, `fileExists(path)`, `readFile(path)`, `writeFile(path, content)` — all returning `Promise<void>` or `Promise<boolean>` or `Promise<string>` as appropriate, with no direct `fs` imports elsewhere in `src/`

**Given** `src/types/index.ts` exists
**When** I read it
**Then** it exports `TemplateManifest`, `OnboardingAnswers`, and `InitOptions` TypeScript interfaces

**Given** `package.json` exists
**When** I read it
**Then** it declares: `"bin": { "bmad-study": "./dist/index.js" }`, `"engines": { "node": ">=18" }`, dependencies `commander@14.x` and `@inquirer/prompts@8.5.2`, and `"prepublishOnly": "bash scripts/build-skills.sh"`

---

### Story 5.2: Onboarding Prompts

As a new student,
I want the CLI to ask me setup questions when I run `npx bmad-study init`,
So that my preferences are captured before the skill files are installed.

**Deliverables:** `src/prompts/onboarding.ts`, `tests/prompts/onboarding.test.ts`

**Acceptance Criteria:**

**Given** `src/prompts/onboarding.ts` exists
**When** `runOnboarding()` is called
**Then** it presents questions in order using `@inquirer/prompts`: (1) name, (2) topic, (3) goal, (4) current level (select: beginner / intermediate / advanced), (5) time per day, (6) deadline (optional), (7) preferred learning style
**And** returns an `OnboardingAnswers` object with all 7 fields populated

**Given** `tests/prompts/onboarding.test.ts` exists
**When** `vitest run` executes it
**Then** tests mock `@inquirer/prompts` and assert: (a) all 7 questions are asked, (b) the returned object maps answers to the correct `OnboardingAnswers` fields, (c) an optional deadline field is `undefined` when skipped

**Given** the onboarding completes with all answers provided
**When** the `OnboardingAnswers` object is inspected
**Then** it is a plain serializable object with no circular references or prompt library internals — ready to be passed directly to the init command

---

### Story 5.3: Init Command — Skill Installation & Memory Seeding

As a new student,
I want `npx bmad-study init` to install all agent skill files and seed my memory directory,
So that I can start studying immediately after a single command with no manual file copying.

**Deliverables:** `src/commands/init.ts`, `src/utils/templates.ts`, `tests/commands/init.test.ts`, `tests/utils/files.test.ts`

**Acceptance Criteria:**

**Given** `npx bmad-study init` is run in a project directory with Node 18+
**When** the user completes the onboarding questionnaire
**Then** the command: (a) copies all files from the package's `skills/` directory to `{cwd}/.claude/skills/`, (b) creates `{cwd}/memory/` if it does not exist, (c) copies `student-profile.md`, `session-log.md`, and `knowledge-map.md` from the package's `memory-templates/` directory into `{cwd}/memory/`

**Given** `{cwd}/.claude/skills/` already contains bmad-study skill files from a prior install
**When** `npx bmad-study init` is run again
**Then** the command overwrites the existing skill files with the current package version and exits `0` — it does not error on existing files

**Given** `{cwd}/memory/` already contains populated memory files
**When** `npx bmad-study init` is run again
**Then** the command does NOT overwrite existing memory files — student data is preserved

**Given** the init command completes successfully
**When** the CLI prints its completion message
**Then** it outputs: `"BMAD-Study is ready. Run /bmad-study-planner in Claude Code to start your first session."` and lists all skill files installed

**Given** `src/utils/templates.ts` exists
**When** I read it
**Then** it resolves skill paths as: `path.join(__dirname, '..', 'skills')` and memory template paths as: `path.join(__dirname, '..', 'memory-templates')` — no hardcoded absolute paths

**Given** `tests/commands/init.test.ts` and `tests/utils/files.test.ts` exist
**When** `vitest run` executes them
**Then** all `fs` calls are mocked via `src/utils/files.ts` (no direct `fs` mocks), and tests assert: correct files copied, correct destinations, memory files not overwritten when present

---

### Story 5.4: npm Publish Readiness

As a contributor preparing a release,
I want the package to be fully publish-ready with correct metadata and a validated build,
So that `npm publish` produces a package that installs and runs correctly for any student.

**Deliverables:** `package.json` (complete metadata), README.md (EN, complete), README.pt.md (PT-BR, complete), npm publish validation

**Acceptance Criteria:**

**Given** `package.json` is complete
**When** I inspect it
**Then** it contains: `name: "bmad-study"`, `version` following semver, `description`, `license: "MIT"`, `keywords`, `repository`, `files` array listing `dist/`, `skills/`, `memory-templates/` — and nothing else (no `agents/`, `src/`, `tests/`, `compiled/` in the published artifact)

**Given** `npm pack --dry-run` is run
**When** the output is inspected
**Then** the packed file list contains only: `dist/index.js`, `dist/index.d.ts`, `skills/*.md` (8 compiled agent skill files), `memory-templates/*.md` (3 template files), `package.json`, `README.md`, `README.pt.md`

**Given** `npm run build` followed by `npm pack` produces a tarball
**When** the tarball is installed in a fresh directory with `npm install ./bmad-study-x.x.x.tgz`
**Then** running `npx bmad-study init` in that directory completes the onboarding flow and installs skill files correctly

**Given** README.md and README.pt.md exist
**When** I read both
**Then** each contains: (a) what bmad-study is, (b) install instructions (`npx bmad-study init`), (c) how to invoke each agent (`/bmad-study-professor`, etc.), (d) how the memory system works, (e) how to contribute

**Given** `npm publish` is run with valid npm credentials
**When** `prepublishOnly` executes
**Then** `bash scripts/build-skills.sh` runs, `compiled/` is up to date, and the package publishes successfully as `bmad-study` on the public npm registry
