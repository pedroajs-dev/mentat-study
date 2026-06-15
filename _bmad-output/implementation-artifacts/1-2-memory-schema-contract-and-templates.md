---
baseline_commit: NO_VCS
---

# Story 1.2: Memory Schema Contract & Templates

Status: done

## Story

As a student,
I want complete, structured memory file templates with all fields and formats defined,
so that every agent I use reads and writes my personal study data in a consistent, predictable format from day one.

## Acceptance Criteria

1. **Given** `templates/student-profile.md` exists **When** an agent or contributor reads it **Then** it contains `memory-protocol-version: 1` and all fields: `name`, `preferred_language`, `goal`, `topic`, `current_level`, `time_per_day`, `deadline`, `preferred_style`, `study_plan` — each with an inline comment explaining its purpose and expected format.

2. **Given** `templates/session-log.md` exists **When** an agent appends a completed session **Then** the canonical append block format is exactly:
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

3. **Given** `templates/knowledge-map.md` exists **When** an agent reads or writes it **Then** it contains these exact five sections in order: `## Mastered ✅`, `## In Progress 🔄`, `## Gaps ❌`, `## Never Studied ⬜`, `## Spaced Repetition Queue` — **And** the Spaced Repetition Queue canonical line format is: `- {concept} — review by {YYYY-MM-DD}`

4. **Given** an agent reads a memory file and finds `memory-protocol-version` missing or set to a value other than `1` **When** it attempts to start a session **Then** it halts immediately and outputs exactly: `"Your memory files are from an older version. Please re-run onboarding with /bmad-study-planner."`

5. **Given** a contributor authors any agent file in Epic 2 or beyond **When** they write the On Activation memory reads **Then** they reference the exact field names defined in these templates without deviation — no aliases, no renamed fields.

## Tasks / Subtasks

- [x] Task 1: Create `templates/` directory and `templates/student-profile.md` (AC: #1, #5)
  - [x] Place file at `templates/student-profile.md` (repo root → templates/)
  - [x] Add `memory-protocol-version: 1` as first line (plain text, NOT YAML frontmatter)
  - [x] Add all 9 fields with inline comments: `name`, `preferred_language`, `goal`, `topic`, `current_level`, `time_per_day`, `deadline`, `preferred_style`, `study_plan`
  - [x] Each field shown as `field: {value}` with comment on same or next line explaining purpose + expected format

- [x] Task 2: Create `templates/session-log.md` (AC: #2, #4)
  - [x] Place file at `templates/session-log.md`
  - [x] Add seed header: `# Session Log`, `memory-protocol-version: 1`, and comment `<!-- Append sessions below. Never overwrite. -->`
  - [x] Show exact canonical append block format as a commented example
  - [x] Canonical format must match exactly (header level, bold labels, subheadings, separator `---`)

- [x] Task 3: Create `templates/knowledge-map.md` (AC: #3, #4)
  - [x] Place file at `templates/knowledge-map.md`
  - [x] Add seed header: `# Knowledge Map`, `memory-protocol-version: 1`, `**Topic:** {topic}`, `**Last updated:** {YYYY-MM-DD}`
  - [x] Add all five sections in exact order: `## Mastered ✅`, `## In Progress 🔄`, `## Gaps ❌`, `## Never Studied ⬜`, `## Spaced Repetition Queue`
  - [x] Add per-section inline format comments showing the canonical line format for each section
  - [x] Show Spaced Repetition Queue canonical line: `- {concept} — review by {YYYY-MM-DD}` (em dash, not hyphen)

- [x] Task 4: Verify templates pass lint (AC: #5 — no model names in templates)
  - [x] Run `bash scripts/lint-agnostic.sh templates/student-profile.md templates/session-log.md templates/knowledge-map.md`
  - [x] All three must exit 0

## Dev Notes

### Critical: This Is a Schema Contract, Not Just Templates

These three files freeze the memory field names and formats for the entire project. **Every Epic 2+ agent will read and write these files.** Field names, heading text (including emoji), and the session-log append format are the public API. Any deviation — even a renamed field or missing emoji — will break agent On Activation reads silently.

**The mismatch halt message is exact text (AC #4). Do not paraphrase:**
```
Your memory files are from an older version. Please re-run onboarding with /bmad-study-planner.
```
This message is referenced in `agent-template.md` (On Activation step 4). The exact string must match what is defined in Story 1.4's `templates/memory-protocol.md`.

### File Location

`templates/` directory at repo root — does NOT exist yet, create it. These are authoring-time reference files. At install time, the CLI copies them to `{user-project}/memory/`. Do NOT place them in `memory/` (that directory is gitignored and never committed).

Architecture directory structure reference:
```
templates/
├── student-profile.md    ← this story (FR-1.1)
├── session-log.md        ← this story (FR-1.2)
└── knowledge-map.md      ← this story (FR-1.3)
```

`templates/memory-protocol.md` (FR-1.4) and `templates/onboarding.md` (FR-4.1) are created in Stories 1.4 and 1.5 respectively — do NOT create them now.

### student-profile.md — Exact Field Contract

`memory-protocol-version` is plain text (not YAML frontmatter — no `---` fences). It is the first line of the file so agents can check it before parsing fields.

The nine fields are the complete, closed set. No agent may add, remove, or rename them:

| Field | Purpose | Expected format |
|---|---|---|
| `name` | Student's first name or preferred name | Free text, e.g. `Pedro` |
| `preferred_language` | Language for agent responses | e.g. `English`, `Português` |
| `goal` | What the student wants to achieve | One sentence, e.g. `Pass Java backend interview at FAANG company` |
| `topic` | Current study topic | Specific, e.g. `Java Backend Interview Prep (Kafka, Spring Boot, System Design)` |
| `current_level` | Self-assessed knowledge level | One of: `beginner`, `intermediate`, `advanced` |
| `time_per_day` | Available study time | e.g. `1 hour`, `30 minutes` |
| `deadline` | Target completion date | `YYYY-MM-DD` or `None` |
| `preferred_style` | Learning style preference | Free text, e.g. `Analogies and real examples, then practice questions` |
| `study_plan` | Week-by-week plan written by Planner Agent | Multiline, starts with `Week 1:` entries |

**Memory write ownership (ARCH-13):** Only the Planner Agent writes `student-profile.md` — once at onboarding. No other agent may write it.

### session-log.md — Seed State and Append Format

**Day-0 seed state (what the file looks like when seeded by CLI):**
```markdown
# Session Log
memory-protocol-version: 1
<!-- Append sessions below. Never overwrite. -->
```

**Canonical append block (every agent appends this after each session):**
```markdown
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

**Critical details:**
- `## Session [N]` — square brackets around N, not just a number
- `---` separator at end of each block (horizontal rule)
- `**Agent:**` uses exact `agent-id` from file frontmatter (e.g., `planner`, `professor`, `evaluator`)
- `### Score` — uses `###` not `**Score:**` inline
- On Activation reads only the **last 3 session entries** (except Coach Agent which reads all)

**Memory write ownership (ARCH-13):** All agents append session-log.md after every session.

### knowledge-map.md — Seed State and Section Formats

**Day-0 seed state:**
```markdown
# Knowledge Map
memory-protocol-version: 1
**Topic:** {topic}
**Last updated:** {YYYY-MM-DD}

## Mastered ✅

## In Progress 🔄

## Gaps ❌

## Never Studied ⬜
{list all concepts from the study plan}

## Spaced Repetition Queue
```

**Per-section canonical line formats (from architecture Pattern 4):**
```
## Mastered ✅
- {concept} — confirmed {YYYY-MM-DD}

## In Progress 🔄
- {concept} — last seen {YYYY-MM-DD}, needs: {what's missing}

## Gaps ❌
- {concept} — wrong/incomplete on {YYYY-MM-DD}

## Never Studied ⬜
- {concept}

## Spaced Repetition Queue
- {concept} — review by {YYYY-MM-DD}
```

**Critical:** The `—` in the line formats is an **em dash** (U+2014), not a hyphen-minus. The Spaced Repetition Queue format is exactly `- {concept} — review by {YYYY-MM-DD}`.

**Section heading text must be exact** (emoji included). Agents locate sections by heading text. `## Mastered ✅` and `## Mastered` are not interchangeable.

**Memory write ownership (ARCH-13):** Only Evaluator Agent and Spaced Review Agent write/update `knowledge-map.md`. Planner Agent seeds it at onboarding (places all concepts under `## Never Studied ⬜`).

### Linting These Files

`scripts/lint-agnostic.sh` defaults to `agents/` and `skills/`. You must explicitly pass `templates/` to lint these files:
```bash
bash scripts/lint-agnostic.sh templates/student-profile.md templates/session-log.md templates/knowledge-map.md
```

Template files must not trigger lint errors (no model names, no platform tokens). The `{agent-id}`, `{concept}`, etc. placeholders in comments are fine — they are not pattern matches.

**Known safe:** The template will reference `{agent-id}` values like `planner`, `professor`, `evaluator` — none of these are model names blocked by lint.

### Testing Approach

No unit tests for this story — deliverables are markdown template files. Validation is:
1. Run lint against all three files — must exit 0
2. Human review: read each file and verify every field/section is present with correct format
3. Cross-check against AC checklist above before marking done

### Previous Story Context (Story 1.1)

- `scripts/lint-agnostic.sh` is live and working — use it for Task 4 verification
- `package.json` devDependencies: `typescript ^5.4.0`, `vitest ^1.6.0`  
- lint-agnostic.sh was patched in review: `<s>` and `</s>` now detect inline tokens (not just full-line)
- `templates/` directory does NOT exist — create it

### References

- Memory field schema: [Source: epics.md#Story 1.2]
- Day-0 seed state: [Source: architecture.md#Pattern 4 — Memory Write Format]
- Canonical append/update formats: [Source: architecture.md#Pattern 4 — Memory Write Format]
- Memory version gate: [Source: architecture.md#ARCH-10]
- Memory write ownership: [Source: architecture.md#ARCH-13]
- Canonical section headings: [Source: architecture.md#ARCH-12]
- Canonical append format: [Source: architecture.md#ARCH-11]
- On Activation protocol: [Source: architecture.md#Pattern 5 — Memory Protocol]
- File location (templates/): [Source: architecture.md#Complete Project Directory Structure]
- Epic 2 dependency: [Source: epics.md#Epic 2 dependency note]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Created `templates/` directory at repo root with three schema-contract files.
- `student-profile.md`: `memory-protocol-version: 1` as first plain-text line, all 9 fields with inline comments defining purpose and expected format per architecture contract.
- `session-log.md`: seed header with version marker and no-overwrite comment, canonical append block embedded as an HTML comment to serve as exact copy-paste reference for agents.
- `knowledge-map.md`: all five sections in exact order with correct heading text (emoji included), per-section format comments, em dash (U+2014) in Spaced Repetition Queue line format.
- All three files passed `lint-agnostic.sh` with exit 0 (no model names, no platform tokens).
- AC #4 halt message will be defined in Story 1.4 (`templates/memory-protocol.md`) as documented in Dev Notes.

### File List

- templates/student-profile.md (created)
- templates/session-log.md (created)
- templates/knowledge-map.md (created)
- scripts/lint-agnostic.sh (modified — restored ^<s>$ and ^</s>$ anchors in PLATFORM_TOKENS_PATTERN)
- _bmad-output/implementation-artifacts/1-2-memory-schema-contract-and-templates.md (modified — story file)

### Review Findings

- [x] [Review][Defer] Canonical append block in `session-log.md` is inside an HTML comment — deferred, revisit in Story 1.4 when agent read instructions clarify delimiter handling — AC #2 specifies the block "format is exactly" the raw block; embedding it in `<!-- ... -->` means agents see comment delimiters, not a literal copyable template. The Dev notes say this was intentional ("copy-paste reference for agents"). Clarification needed: should the block be uncommented literal content, or is the HTML-comment approach acceptable? [`templates/session-log.md`]
- [x] [Review][Patch] `<s>`/`</s>` unanchored in PLATFORM_TOKENS_PATTERN — change from `^<s>$|^</s>$` to `<s>|</s>` causes false-positive lint failures on any markdown file using HTML strikethrough (e.g., `<s>deprecated</s>`). [`scripts/lint-agnostic.sh:33`]
- [x] [Review][Patch] `study_plan` comment is inside the YAML block literal body, not at field level — all other fields use `field: {value}\n<!-- comment -->` immediately after the key; `study_plan` places its `<!-- -->` lines as indented content inside the `|` scalar, so they become part of the field value when parsed. AC #1 requires each field to have an inline comment explaining purpose/format at the field level. [`templates/student-profile.md:30-32`]

### Review Findings (Round 2 — 2026-06-14)

- [x] [Review][Patch] Em dash reminder (`<!-- Em dash (—) U+2014, not a hyphen -->`) only appears in Spaced Repetition Queue section, but Mastered, In Progress, and Gaps sections also use em dashes in their format comments — authors of those sections have no inline reminder and may use hyphens instead. [`templates/knowledge-map.md`]
- [x] [Review][Defer] `study_plan: |` pipe syntax in a plain-text (non-YAML) file may confuse agents or contributors expecting YAML block scalar semantics — design question for Story 1.6 when Planner Agent writes this field [`templates/student-profile.md:29`]
- [x] [Review][Defer] Session [N] numbering is manual with no auto-increment or collision detection — relevant when multi-agent concurrent appends land; out of scope here [`templates/session-log.md`]
- [x] [Review][Defer] No protocol for moving concepts between knowledge-map sections (e.g., Never Studied → In Progress → Mastered) — agent behavior specification, out of scope for this story [`templates/knowledge-map.md`]

## Change Log

- 2026-06-14: Created templates/ directory with student-profile.md, session-log.md, and knowledge-map.md. All files define the memory schema contract for Epic 2+ agents and pass lint-agnostic.sh with exit 0.
