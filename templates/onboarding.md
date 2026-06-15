<!-- onboarding.md — CANONICAL onboarding flow (FR-4.1).
     Single source of truth for the first-run onboarding the Planner Agent
     runs once per student. It defines the 7 onboarding questions (with example
     answers), the answer → student-profile.md field mapping, and the
     instructions for initializing all three memory files. The Planner Agent's
     Session Workflow points here (Story 1.6) and should follow it verbatim.
     This file is NOT an agent (no `type: agent`) and is NOT compiled or seeded
     into a user's memory/ directory — it is an authoring-time reference/template.
     Unlike skills/, a template MAY reference memory files by name (ARCH-2). -->

# Onboarding Flow

This is the first-run flow the Planner Agent follows once, at the start of a
student's very first session, before any studying happens. Its job is to
collect the student's setup data in a fixed order and then populate the three
memory files so every later session has consistent context.

The Planner Agent asks the questions below in order, captures each answer, then
follows the Field Mapping and Memory Initialization sections to write the
files.

## Onboarding Questions

Ask these 7 questions in this exact order. For each, show the student an example
answer so they know the expected format and level of detail.

1. **What is your name?**
   _Example:_ `Pedro`

2. **What topic are you studying?** (be specific)
   _Example:_ `Java Backend Interview Prep (Kafka, Spring Boot, System Design)`

3. **What is your goal?** (one sentence)
   _Example:_ `Pass Java backend interview at a FAANG company`

4. **What is your current level?** (answer with exactly one of: `beginner`, `intermediate`, `advanced`)
   _Example:_ `intermediate`

5. **How much time can you dedicate per day?**
   _Example:_ `1 hour` (or `30 minutes`)

6. **Do you have a deadline?** (a date in `YYYY-MM-DD` format, or `None` if you have no deadline)
   _Example:_ `2026-09-01` — _or_ `None`

7. **What is your preferred learning style?**
   _Example:_ `Analogies and real examples, then practice questions`

## Field Mapping

After collecting all 7 answers, write each one into `student-profile.md` using
the exact field names below. Use these field names verbatim — do not rename,
alias, or reorder fields (Story 1.2 schema contract / ARCH-13).

| Question | Answer maps to field | Write format / constraint |
|---|---|---|
| Q1 — name | `name` | free text |
| Q2 — topic | `topic` | be specific |
| Q3 — goal | `goal` | one sentence |
| Q4 — current level | `current_level` | exactly one of: `beginner`, `intermediate`, `advanced` |
| Q5 — time per day | `time_per_day` | e.g. `1 hour`, `30 minutes` |
| Q6 — deadline | `deadline` | `YYYY-MM-DD`, or `None` |
| Q7 — learning style | `preferred_style` | free text |

### Two fields that are NOT direct answers — handle them explicitly

- **`preferred_language`** — There is intentionally no onboarding question for
  language (the flow is frozen at 7 questions), but `preferred_language` is a
  required `student-profile.md` field and must be populated. Do NOT leave it as
  the `{value}` placeholder. Infer it from the language the student is using to
  converse, and default to `English` if it is unclear. Write it as plain text,
  e.g. `English` or `Português`.

- **`study_plan`** — Do NOT write this from an onboarding answer. It is produced
  by the `build-study-plan` skill (Story 1.6) and is Planner-only (ARCH-13). The
  build-study-plan step fills this field after onboarding; here, leave it for
  that step rather than inventing a write format.

Keep `memory-protocol-version: 1` as the first line of `student-profile.md` (it
is already there in the template).

## Memory Initialization

After the questionnaire (and after `build-study-plan` has produced the plan),
the Planner Agent initializes all three memory files. Respect write ownership
(ARCH-13): the Planner writes `student-profile.md` once, seeds
`knowledge-map.md`, and appends the first `session-log.md` entry. Write the
files in this order.

### (a) student-profile.md

Populate ALL fields:

- The 7 mapped answers: `name`, `topic`, `goal`, `current_level`,
  `time_per_day`, `deadline`, `preferred_style`.
- `preferred_language` — inferred from the conversation language (default
  `English`), as described in Field Mapping. Do not leave it as `{value}`.
- `study_plan` — filled by the `build-study-plan` skill (Story 1.6); reference
  it here, do not duplicate or hand-author its format.

Keep `memory-protocol-version: 1`.

### (b) knowledge-map.md

Seed the Day-0 state:

- Set the `**Topic:**` header to the student's topic and `**Last updated:**` to
  today's date (`YYYY-MM-DD`).
- Leave `## Mastered ✅`, `## In Progress 🔄`, `## Gaps ❌`, and
  `## Spaced Repetition Queue` empty.
- Seed `## Never Studied ⬜` with ALL concepts derived from the study plan /
  topic, one per line in the format `- {concept}` (no date suffix).
- Preserve all five canonical sections in their original order and keep
  `memory-protocol-version: 1`.

### (c) session-log.md — Session 0 entry

Write the very first record as a `Session 0` entry using the canonical append
block from `templates/session-log.md`. Use `Agent: planner` and
`Mode: onboarding`.

> Note: `onboarding` is intentionally outside the canonical Mode enum
> (`Learn | Quiz | Review | Simulate | Think | Coach | Troubleshoot`). That enum
> is for ongoing study sessions; Session 0 is the one-time bootstrap record.
> Use `onboarding` here for consistency with Story 1.6.

Include a brief study-plan summary under `### What was covered`, `Score: N/A`,
`Gaps identified: None`, and a one-sentence `Next recommended session`.

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
