---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-06-14'
inputDocuments:
  - "_bmad-output/planning-artifacts/prds/prd-bmad-study-2026-06-12/prd.md"
workflowType: 'architecture'
project_name: 'bmad-study'
user_name: 'Pedro Augusto'
date: '2026-06-12'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

---

## Starter Template Evaluation

### Primary Technology Domain
CLI tool — Node.js TypeScript, file distribution, interactive onboarding prompts. Phases 1 and 2 are pure markdown content with no build tooling. The starter template question applies to Phase 3 only.

### Approach: Manual TypeScript CLI Setup
No off-the-shelf starter fits this project's shape. A curated manual setup mirrors the BMAD Method's structure and gives full control over every toolchain decision.

### Toolchain

| Layer | Decision | Version | Rationale |
|-------|----------|---------|-----------|
| Language | TypeScript | latest | Structured project, typed interfaces |
| CLI framework | Commander.js | v14 | Node 18+ compatible; v15 is ESM-only, requires Node 22+ — conflicts with PRD |
| Prompts | @inquirer/prompts | 8.5.2 | Modern package; legacy `inquirer` no longer actively developed |
| Bundler | tsup | 8.5.1 | Zero-config, esbuild-backed, explicit `--format cjs` for Node 18 compat |
| Test framework | Vitest | 4.1.8 | TypeScript-native, fast, strong `vi.mock` support for `fs` |
| Node requirement | >=18 | — | Kept per PRD — Commander v14 supports this floor |

**Note on Commander v15:** Released May 2026, ESM-only, requires Node 22+. Deferred — conflicts with PRD Node 18+ requirement. Migrate when the project's Node floor moves.

**Note on zod:** Flagged as a Phase 3 implementation consideration — the questionnaire answers that parameterize file distribution should be typed and validated. Introduce at implementation time, not now.

### Project Structure

```
bmad-study/
├── src/
│   ├── index.ts              # bin entrypoint, Commander setup
│   ├── commands/
│   │   └── init.ts           # command handler, wires prompts + file ops
│   ├── prompts/
│   │   └── onboarding.ts     # @inquirer prompt definitions, typed answers
│   ├── utils/
│   │   ├── files.ts          # fs operations (copy, mkdir, exists checks)
│   │   └── templates.ts      # manifest resolution, path construction
│   └── types/
│       └── index.ts          # TemplateManifest, OnboardingAnswers, InitOptions
├── tests/
│   ├── commands/init.test.ts
│   ├── prompts/onboarding.test.ts
│   └── utils/files.test.ts
├── dist/                     # tsup output (gitignored)
├── tsconfig.json
├── tsup.config.ts
├── vitest.config.ts
└── package.json
```

### Initialization Commands

```bash
npm init -y
npm install commander@14 @inquirer/prompts
npm install -D typescript tsup vitest @types/node
npx tsc --init
```

**`package.json` key fields:**
```json
{
  "name": "bmad-study",
  "bin": { "bmad-study": "./dist/index.js" },
  "scripts": {
    "build": "tsup src/index.ts --format cjs --dts",
    "dev": "tsup src/index.ts --watch",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "engines": { "node": ">=18" }
}
```

### CLI Testing Strategy

Mock at the boundary — `fs`, `process.exit`, `@inquirer` module. Test command handler as a pure function of mocked dependencies.

**Known failure modes to write tests for before feature code:**

1. **`fs` mock drift** — mock `copyFile` passes but prod throws `ENOENT` on missing parent. `files.ts` must call `fs.mkdir(dest, { recursive: true })` before every copy; test that `EEXIST` is swallowed.
2. **TTY detection** — `@inquirer/prompts` may hang in Vitest (non-TTY stdin). Mock the entire `onboarding.ts` module at the command layer; test prompts with injected answers.
3. **`npx` path resolution** — `__dirname` in npm cache ≠ project root. Mock `__dirname` to an arbitrary temp path; assert copy source resolves correctly.
4. **Idempotency** — user runs `init` twice. Write the test before writing the guard.
5. **Process exit codes** — Commander calls `process.exit(1)` on error; Vitest process may exit mid-suite. Spy: `vi.spyOn(process, 'exit').mockImplementation(() => { throw new Error('process.exit called') })`.

**Note:** Project initialization is the first Phase 3 implementation story.

---

## Implementation Patterns & Consistency Rules

### Critical Conflict Points
7 areas where contributors could make inconsistent choices that silently break the system. Each has a defined rule, example, and enforcement mechanism.

---

### Pattern 1 — Skill Composition (Inline Inclusion)

Skills are pasted verbatim into the agent file under `## Skills`. The skill's YAML frontmatter is **stripped** — only the content below the frontmatter is included. The skill's title becomes a `###` heading using the skill's `id`.

**Before (skill file — `skills/explain-concept.md`):**
```markdown
---
id: explain-concept
version: 1.0.0
type: skill
---
## Purpose
Teach any concept at the right level for the student.

## Instructions
Always begin by asking the student what they already know about the topic.
...
```

**After (inlined into agent file — `agents/professor-agent.md`):**
```markdown
## Skills

### explain-concept
Always begin by asking the student what they already know about the topic.
...

### active-recall
...
```

**Skill conflict rule:** When two inlined skills contain contradictory instructions, the later-defined skill (lower in the `## Skills` section) takes precedence. Conflicts must be noted in a `## Skill Conflicts` comment block immediately after the `## Skills` section.

---

### Pattern 2 — Heading Hierarchy (strict)

```
# Agent or Skill Title          ← file title only, matches id in frontmatter
## Required Section             ← Purpose / Memory Protocol / Skills / Instructions
### Inlined Skill Name          ← skill id, within ## Skills only
#### Sub-step within a skill    ← phases or steps inside a ### skill block
```

No other heading levels. No `#####` or deeper. No `##` inside a `###` skill block.

---

### Pattern 3 — Instruction Language

All agent and skill instructions are written in **second person imperative, addressed to the LLM executing the file** — not to the student, not to the reader.

| ✅ Write this | ❌ Not this |
|---|---|
| `Always confirm the student's current topic before starting.` | `The agent should always confirm the student's current topic.` |
| `If memory is missing, announce it and stop.` | `Agents must announce missing memory and stop.` |
| `Never give the full answer before the student attempts.` | `I will never give the full answer before the student attempts.` |

---

### Pattern 4 — Memory Write Format

**session-log.md — canonical append block (append only, never overwrite):**
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

**knowledge-map.md — canonical update format:**
```markdown
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

**Day-0 seed state** (what freshly initialized memory files look like — written by Planner Agent at onboarding):

`session-log.md` seed:
```markdown
# Session Log
memory-protocol-version: 1
<!-- Append sessions below. Never overwrite. -->
```

`knowledge-map.md` seed:
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

---

### Pattern 5 — Memory Protocol (On Activation steps)

Every agent skill file implements this as `## On Activation` steps — using file system tools, not copy-paste. The agent reads files from the project's `memory/` directory automatically when invoked, exactly as BMAD agents read PRDs and architecture docs.

```
## On Activation

1. Read {project-root}/memory/student-profile.md
   → Know who you are talking to (name, level, goal, available time, deadline)
2. Read {project-root}/memory/knowledge-map.md
   → Know what they know and what the gaps are
3. Read {project-root}/memory/session-log.md (last 3 session entries only)
   → Know what was recently covered

Schema version check: if memory-protocol-version in any file does not equal 1,
announce: "Your memory files are from an older version of BMAD-Study. Please
re-run onboarding with the Planner Agent before continuing." Then stop.

4. Greet the student by name. Confirm current topic and session mode.

## After Session

5. Append to {project-root}/memory/session-log.md using the canonical append format
6. [Evaluator Agent and Spaced Review Agent only] Update {project-root}/memory/knowledge-map.md
```

This is the same pattern BMAD agents use to read PRDs and architecture documents — no user action required beyond invoking the skill.

---

### Pattern 6 — Agent-to-Agent Handoff

**Sending pattern** (agent A recommending a switch to agent B):
```
To switch to {Agent Name}, start a new session and say:
"Load {agent-id} — {one sentence: current topic + why you're switching}"
```

**Example:**
```
To switch to the Coach Agent, start a new session and say:
"Load coach-agent — I've completed 3 weeks of Kafka study and want to
check if I'm on track for my interview in 2 weeks."
```

**Receiving pattern** (agent B opening a handoff session):
```
I've loaded your context: {one sentence summary of the handoff message}.
Before we begin, let me confirm: {restate the student's stated goal}.
Is that right?
```

The `[context]` field must always include: current topic + reason for the switch. Nothing more, nothing less.

---

### Pattern 7 — Missing Memory Handling

If any memory file is absent or cannot be parsed:

```
I notice your {student-profile.md / session-log.md / knowledge-map.md} is
missing or unreadable. I cannot start a session without it.

To fix this:
- If you are new: run the Planner Agent to complete onboarding.
- If you have existing files: paste the missing file into this conversation
  and I will resume.
```

**Never silently proceed.** Never guess at missing values. Never invent a student profile.

---

### Pattern 8 — Agent Error Vocabulary

Four canonical error forms for agents. Use these exact structures:

| Situation | Canonical form |
|-----------|---------------|
| Missing file | `"Your {filename} is missing. [fix instruction]"` |
| Out-of-scope request | `"That's outside what I handle as {agent name}. For that, try {other agent}."` |
| Unrecognized intent | `"I'm not sure what you're asking. Could you rephrase? I can help with {agent scope}."` |
| Schema mismatch | `"Your memory files are from an older version. Please re-run onboarding."` |

---

### Pattern 9 — Stateless Skills (structural enforcement)

Skills must not reference `session-log.md`, `knowledge-map.md`, or `student-profile.md` by name. Memory behavior belongs in agents only.

**Rationale:** Skills are stateless so they can be composed into any agent without memory schema conflicts. If you need memory behavior, put it in the agent file, not the skill.

**Lint enforcement:** `scripts/lint-agnostic.sh` checks all files with `type: skill` in frontmatter for any occurrence of `session-log`, `knowledge-map`, or `student-profile`. A match is a CI failure.

---

### Pattern 10 — Versioning Semantics

| Version bump | Meaning | Student impact |
|---|---|---|
| Major (1.x → 2.x) | Memory schema changed | Re-onboarding required |
| Minor (x.1 → x.2) | Additive only, backwards compatible | None |
| Patch (x.x.1 → x.x.2) | Bug fix in agent behavior | None |

---

### Pattern 11 — CLI: `utils/files.ts` Ownership

All `fs` calls go through `src/utils/files.ts`. This file is the single mock boundary in tests. When a new command needs a file operation not currently exposed by `files.ts`, **add it to `files.ts`** — do not import `fs` directly in command or prompt files.

Current interface surface (to be implemented):
- `copyFile(src: string, dest: string): Promise<void>`
- `ensureDir(path: string): Promise<void>`
- `fileExists(path: string): Promise<boolean>`
- `readFile(path: string): Promise<string>`
- `writeFile(path: string, content: string): Promise<void>`

---

### All Contributors MUST

- Follow YAML frontmatter format exactly: `id`, `version`, `type`
- Use canonical memory write format — no variations
- Write instructions in second person imperative (addressed to the LLM)
- Pass `scripts/lint-agnostic.sh` locally before opening a PR
- Include `## Memory Protocol` verbatim block in every agent file
- Never add memory read/write logic to skill files
- Never silently proceed when memory files are missing
- Use canonical error vocabulary for agent error announcements
- Bump major version when changing memory schema

---

### Enforcement Summary

| Pattern | Enforcement |
|---------|-------------|
| Required sections present | CI lint: grep for `## Memory Protocol`, `## Purpose`, `## Instructions` in agent files |
| Stateless skills | CI lint: grep for memory file names in `type: skill` files |
| Model-agnosticism | CI lint: `scripts/lint-agnostic.sh` |
| TypeScript types | CI: `tsc --noEmit` |
| Test coverage | CI: `vitest run` |
| Memory write format | Human review (template comparison) |
| Instruction language | Human review (two-column table reference) |

---

## Core Architectural Decisions

### Decision Priority Analysis

**Critical (block implementation):**
- **Agent files are BMAD skills** — not standalone markdown, not custom format. They follow the BMAD skill structure and run in a tool-enabled environment (Claude Code or equivalent). Agents read memory files via file system tools (Read, Glob), not copy-paste.
- Skill composition contract → inline inclusion
- File format contract → BMAD skill format with activation steps that load memory
- Memory file schema → template + schema version field
- CLI path resolution contract → `__dirname`-relative, tested with mock

**Important (shape architecture):**
- Distribution → `npx bmad-study init` installs BMAD skills into user's `.claude/skills/` (or equivalent), not standalone files into arbitrary directory
- npm package structure → compiled skills bundled inside package
- CI pipeline → Vitest + lint-agnostic + tsc on every PR
- Versioning → semver (package) + frontmatter version (files)

**Deferred:**
- Commander v15 / Node 22+ migration → when Node floor moves
- Automated npm release pipeline → post-Phase 3
- zod validation of onboarding answers → Phase 3 implementation

---

### Content Architecture

**Agent files are BMAD skills**

⚠️ Critical correction from original design: agent files are **not** standalone markdown files for copy-pasting into any AI chat. They are **BMAD skills** — structured exactly like `bmad-agent-analyst`, `bmad-create-architecture`, and every other BMAD skill in this repo. They run in a tool-enabled environment (Claude Code or equivalent) and use file system tools to read and write memory files automatically. The user never copies and pastes files.

Every agent skill file follows the BMAD skill structure:
1. Skill title and persona description
2. `## On Activation` — steps that use Read/Glob tools to load memory files from `{project-root}/memory/`
3. Schema version check — if `memory-protocol-version` in memory files doesn't match, halt and instruct re-onboarding
4. `## Workflow` — the agent's session behavior (teach / quiz / evaluate / etc.)
5. `## After Session` — steps that use Write/Edit tools to append session-log.md and update knowledge-map.md

**Skill Composition: Inline Inclusion**

Skill building blocks are inlined into agent skill files under a `## Skills` section, each as `### {skill-id}` with full content pasted. The `skills/` directory is the authoring source; agent files are the compiled artifact. Skills must be stateless — no memory read/write logic (that belongs in the agent's On Activation and After Session steps). When a skill is updated, all agent files that include it must be updated.

**File Format Contract — Agent Skills**

Every agent skill file must have, in order:
1. Skill title + persona (who this agent is, tone, approach)
2. `## On Activation` — ordered steps:
   - Read `{project-root}/memory/student-profile.md`
   - Read `{project-root}/memory/knowledge-map.md`
   - Read last 3 entries of `{project-root}/memory/session-log.md`
   - Check `memory-protocol-version` — halt if mismatch
   - Greet student by name, confirm current topic
3. `## Skills` — inlined skill blocks as `### {skill-id}`
4. `## Session Workflow` — agent behavior during the session
5. `## After Session` — ordered steps:
   - Append to `{project-root}/memory/session-log.md` using canonical format
   - [Evaluator + Spaced Review only] Update `{project-root}/memory/knowledge-map.md`

**File Format Contract — Skill Building Blocks**

Every skill file must have, in order:
1. Skill title + purpose description
2. `## Instructions` — stateless behavior, model-agnostic language only
3. **No file read/write steps** — skills are stateless; file operations belong in agent activation/after-session steps only

**Memory File Schema**

Memory files are real files on the user's local file system, read and written by agents via tools. Each file carries a `memory-protocol-version: 1` header. Future schema changes increment this field; agents detect mismatches in the On Activation step before proceeding.

---

### CLI Architecture

**Assembly Strategy:** The CLI installs BMAD skill files into the user's tool-enabled environment — specifically into `.claude/skills/` (for Claude Code users) or the equivalent skills directory. Agent files are pre-assembled with skills inlined. CLI = skill installer + onboarding runner.

**What `npx bmad-study init` does:**
1. Runs the onboarding questionnaire (Inquirer prompts)
2. Copies agent skill files → `{user-project}/.claude/skills/bmad-study-*/`
3. Creates `{user-project}/memory/` with seed templates
4. Prints: "BMAD-Study is ready. Invoke `/professor` to start your first session."

**npm Package Structure:**
```
package/
├── dist/index.js            ← compiled CLI entry
├── skills/                  ← compiled BMAD skill files (agents with skills inlined)
│   ├── bmad-study-professor.md
│   ├── bmad-study-evaluator.md
│   ├── bmad-study-quiz.md
│   ├── bmad-study-planner.md
│   ├── bmad-study-socratic.md
│   ├── bmad-study-coach.md        ← Phase 2
│   ├── bmad-study-troubleshooter.md ← Phase 2
│   └── bmad-study-spaced-review.md  ← Phase 2
├── memory-templates/        ← seed files for memory/ directory
│   ├── student-profile.md
│   ├── session-log.md
│   └── knowledge-map.md
└── package.json
```

**Path Resolution:** All source paths resolve as:
```typescript
const SKILLS_DIR = path.join(__dirname, '..', 'skills');
const MEMORY_TEMPLATES_DIR = path.join(__dirname, '..', 'memory-templates');
```
Tested with `__dirname` mocked to an arbitrary temp path.

---

### Infrastructure & Distribution

**CI/CD (GitHub Actions — every PR):**
1. `vitest run` — all tests must pass
2. `scripts/lint-agnostic.sh` — model-agnosticism grep check on all agent/skill files
3. `tsc --noEmit` — type check

**Versioning:**
- npm package: semver (`major.minor.patch`)
- Agent/skill files: `version` field in YAML frontmatter, independent of package version
- Memory protocol: `memory-protocol-version` integer in protocol block
- Filename rename = breaking change = major bump in file frontmatter + package version

**npm Publishing:** Manual `npm publish` on tag. No automated release pipeline in Phase 3.

---

### Contributor Interface

**Template-first:** `agent-template.md` and `skill-template.md` live in the repo root. They are fully commented and teach the entire format contract by example. `CONTRIBUTING.md` points to them as the primary contributor documentation.

**Lint:** `scripts/lint-agnostic.sh` checks for model names, platform-specific syntax, and context-window-size assumptions. Runs in CI on every PR. Contributors must pass it locally before submitting.

**Acceptance signal:** Human review — a correct agent skill file, when invoked in a tool-enabled environment with a reference `memory/` directory present, must satisfy all FR behavior bullets across three distinct test sessions.

---

## Project Structure & Boundaries

### Complete Project Directory Structure

```
bmad-study/
│
│  ← CONTENT LAYER (Phases 1-2) — BMAD skill files
│
├── agents/                         ← AUTHORING SOURCE for agent skills
│   ├── planner-agent.md            ← FR-2.1 — Phase 1, first agent built
│   ├── professor-agent.md          ← FR-2.2 — Phase 1
│   ├── evaluator-agent.md          ← FR-2.3 — Phase 1
│   ├── quiz-agent.md               ← FR-2.4 — Phase 1
│   ├── socratic-agent.md           ← FR-2.5 — Phase 1
│   ├── coach-agent.md              ← FR-6.1 — Phase 2
│   ├── troubleshooter-agent.md     ← FR-6.2 — Phase 2
│   └── spaced-review-agent.md      ← FR-6.3 — Phase 2
│
├── skills/                         ← AUTHORING SOURCE for skill building blocks
│   ├── explain-concept.md          ← FR-3.1 — Phase 1
│   ├── generate-quiz.md            ← FR-3.2 — Phase 1
│   ├── evaluate-answer.md          ← FR-3.3 — Phase 1
│   ├── build-study-plan.md         ← FR-3.4 — Phase 1
│   ├── generate-flashcards.md      ← FR-3.5 — Phase 1
│   ├── run-mock-exam.md            ← FR-3.6 — Phase 1
│   ├── session-opener.md           ← FR-7.1 — Phase 2
│   ├── build-scenario.md           ← FR-7.2 — Phase 2
│   ├── concept-precision.md        ← FR-7.3 — Phase 2
│   └── escalate-challenge.md       ← FR-7.4 — Phase 2
│
├── compiled/                       ← COMPILED AGENT SKILLS (skills inlined)
│   │                                 This is what ships in the npm package
│   ├── bmad-study-planner.md
│   ├── bmad-study-professor.md
│   ├── bmad-study-evaluator.md
│   ├── bmad-study-quiz.md
│   ├── bmad-study-socratic.md
│   ├── bmad-study-coach.md         ← Phase 2
│   ├── bmad-study-troubleshooter.md ← Phase 2
│   └── bmad-study-spaced-review.md  ← Phase 2
│
├── templates/
│   ├── memory-protocol.md          ← FR-1.4 — canonical On Activation block
│   ├── student-profile.md          ← FR-1.1 — Day-0 seed template
│   ├── session-log.md              ← FR-1.2 — Day-0 seed template
│   ├── knowledge-map.md            ← FR-1.3 — Day-0 seed template
│   ├── onboarding.md               ← FR-4.1 — full onboarding flow
│   └── progress-report.md          ← DL-007 — Phase 1
│
├── examples/
│   ├── java-backend-interview/     ← FR-5.1 — Phase 1 (primary example)
│   │   ├── student-profile.md
│   │   ├── session-log.md
│   │   └── knowledge-map.md
│   ├── system-design/              ← DL-008 — Phase 1
│   │   ├── student-profile.md
│   │   ├── session-log.md
│   │   └── knowledge-map.md
│   └── kubernetes/                 ← DL-008 — Phase 1
│       ├── student-profile.md
│       ├── session-log.md
│       └── knowledge-map.md
│
├── memory/                         ← GITIGNORED — user's personal memory files
│   ├── student-profile.md          ← read/written by agent skills via tools
│   ├── session-log.md              ← read/written by agent skills via tools
│   └── knowledge-map.md            ← read/written by agent skills via tools
│
│  ← CONTRIBUTOR INTERFACE
│
├── agent-template.md               ← fully commented BMAD skill template for agents
├── skill-template.md               ← fully commented template for skill building blocks
├── CONTRIBUTING.md                 ← points to templates, lint instructions
│
├── scripts/
│   └── lint-agnostic.sh            ← CI: model names, syntax, memory refs in skills
│
│  ← CLI LAYER (Phase 3) — TypeScript Node.js
│
├── src/
│   ├── index.ts                    ← bin entrypoint, Commander setup
│   ├── commands/
│   │   └── init.ts                 ← installs compiled/ skills + seeds memory/
│   ├── prompts/
│   │   └── onboarding.ts           ← @inquirer questionnaire
│   ├── utils/
│   │   ├── files.ts                ← ALL fs operations (single mock boundary)
│   │   └── templates.ts            ← skill path resolution, manifest
│   └── types/
│       └── index.ts                ← TemplateManifest, OnboardingAnswers, InitOptions
│
├── tests/
│   ├── commands/init.test.ts
│   ├── prompts/onboarding.test.ts
│   └── utils/files.test.ts
│
├── dist/                           ← GITIGNORED — tsup build output
│
│  ← CONFIGURATION
│
├── .github/
│   └── workflows/
│       └── ci.yml                  ← vitest + lint-agnostic + tsc on every PR
├── .gitignore                      ← memory/, dist/, node_modules/, compiled/
├── package.json                    ← bin: bmad-study → dist/index.js
├── tsconfig.json
├── tsup.config.ts
├── vitest.config.ts
├── README.md                       ← EN
└── README.pt.md                    ← PT-BR
```

> **Note on `compiled/`:** The `compiled/` directory is gitignored and generated — agent files with skills inlined. It is what ships inside the npm package. Authors work in `agents/` and `skills/`; a build script assembles `compiled/` before publish.

---

### Architectural Boundaries

**Content ↔ CLI boundary:**
The CLI copies files from `compiled/` (inside the npm package) into the user's `.claude/skills/` directory and seeds `memory/` with templates. The CLI has zero knowledge of agent skill content semantics — it does not parse, validate, or interpret the markdown files. If this boundary is ever crossed, it must be flagged as a violation.

**Memory boundary:**
- WRITE `student-profile.md`: Planner Agent only (once at onboarding, via Write tool)
- WRITE `knowledge-map.md`: Evaluator Agent + Spaced Review Agent only (via Edit tool)
- APPEND `session-log.md`: all agents after every session (via Edit tool)
- READ all files: all agents at On Activation (via Read tool)
- `memory/` is gitignored — never committed, never distributed

**Skill ↔ Agent boundary:**
Skills in `skills/` are stateless building blocks. Agents in `agents/` are BMAD skills with file system tool access. At build time, skills are inlined into compiled agent files. Skills must never contain file read/write steps — those belong in agent On Activation and After Session sections only.

**Authoring ↔ Distribution boundary:**
Authors work in `agents/` and `skills/`. A build step produces `compiled/`. The npm package ships `compiled/` and `memory-templates/` only — not the authoring source directories.

---

### Data Flow

```
INSTALL (once)
npx bmad-study init
    ↓
CLI runs onboarding questionnaire (Inquirer)
    ↓
CLI copies compiled/*.md → {user-project}/.claude/skills/
CLI seeds {user-project}/memory/ with student-profile, session-log, knowledge-map templates
Planner Agent fills in student-profile.md + knowledge-map.md during first session
    ↓
EVERY SESSION
User invokes skill: /bmad-study-professor (or equivalent)
    ↓
Agent On Activation: reads memory/ files via Read tool (automatic — no user action)
    ↓
Agent runs session (teach / quiz / evaluate / think / coach / troubleshoot)
    ↓
Agent After Session: appends session-log.md, updates knowledge-map.md via Edit tool
    ↓
Next session: same flow — memory files always current
```

---

### Internal Integration Points

- All agent skills share the same `memory/` directory — reads and writes are coordinated by the memory protocol, not by a lock or sync mechanism
- Coach Agent reads full session-log.md (not just last 3 entries) — the only agent with this expanded read scope
- Coach Agent surfaces Spaced Review Agent via canonical handoff pattern when stale content is detected
- Evaluator Agent is the only agent that updates `knowledge-map.md` during a normal session; Spaced Review Agent also updates it after a spaced review session
- Planner Agent writes all three memory files at onboarding — the only agent that writes `student-profile.md`

---

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
30+ FRs across 8 groups spanning three phases. Phase 1 establishes the foundation (memory templates + 5 core agents + 6 skills + 3 examples). Phase 2 adds the strategic layer (3 agents + 4 skills). Phase 3 wraps everything in a zero-friction CLI installer. The core product artifact in all phases is structured markdown files — there is no runtime application to architect, only a content system with strong format contracts.

**Non-Functional Requirements:**
- Model-agnostic: no LLM-specific syntax in any agent or skill file; agents run in any tool-enabled environment (Claude Code, Cursor, etc.)
- Human-readable: plain markdown; agent files follow BMAD skill structure
- Composable: skill building blocks are inlined into agent skills
- Zero-friction install: Node 18+, under 60 seconds end-to-end; skills auto-installed into user's environment
- Privacy: memory/ gitignored, no data leaves local filesystem, read/written only by agent tools
- Contributor-friendly: content contributions require only a markdown skill file

**Scale & Complexity:**
- Primary domain: content distribution system + CLI tool
- Complexity level: low-medium
- Estimated architectural components: 3 (file format layer, agent/skill content layer, CLI delivery layer)

### Technical Constraints & Dependencies

- All content files must work with any instruction-following LLM
- Memory files are plain text, user-managed (no sync, no automation)
- CLI is Node.js 18+, no API keys, no backend
- Bilingual README only; all agent/skill files are English
- `memory/` directory is gitignored — never versioned
- Skills are stateless building blocks; memory read/write logic belongs to agents only

### Cross-Cutting Concerns Identified

1. **Memory protocol consistency** — every agent must implement the same READ-before/WRITE-after protocol. One canonical source (`memory-protocol.md`), pasted verbatim into every agent file. CI grep enforces identical text across all agents.
2. **Model-agnosticism enforcement** — applies to every content file. Requires a concrete, lintable checklist (not an abstract principle): no model names, no platform-specific syntax, no context-window-size assumptions, no API-specific formats.
3. **Skill composition contract** — the single most important open architectural decision. Three options identified: inline inclusion (self-contained, drift risk), reference-based (single source of truth, loading contract required), or CLI-assembled build step (best of both — authors reference, runtime receives compiled file). Paige's `<!-- include: filename.md -->` pattern is the leading candidate: human-readable, CLI-resolvable, LLM receives a fully assembled file.
4. **File naming and linking conventions** — filenames are the public API. kebab-case, stable, no version numbers in filenames. Versioning lives in file frontmatter. Renames treated as breaking changes.
5. **Memory file schema** — the structure of each memory file must be defined before any real session data is written. Uncontrolled write-back formats cause silent data loss across agents.
6. **Contributor validation interface** — a template-first approach: `agent-template.md` and `skill-template.md` are so complete that reading them teaches the entire format contract. CONTRIBUTING.md reinforces; CI enforces.

---

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:** All technology decisions are compatible. BMAD skill
format + Commander v14 + TypeScript + @inquirer/prompts + tsup + Vitest work
together without conflicts. The memory protocol using Read/Edit tools is the
exact pattern BMAD agents already use — no new mechanism required.

**Pattern Consistency:** All 11 implementation patterns align with the BMAD
skill format and the inline skill inclusion decision. Naming conventions,
memory write formats, instruction language, and error vocabulary are consistent
across all agent types.

**Structure Alignment:** Project structure supports all architectural decisions.
Content layer (agents/, skills/, compiled/), memory layer (memory/), CLI layer
(src/), and contributor interface (templates/, scripts/) are cleanly separated.

### Requirements Coverage Validation ✅

**Functional Requirements:** All 8 FR groups (FR-1 through FR-8) map to
specific files and directories. Phase 1 (memory + core agents + skills +
examples), Phase 2 (extended agents + skills), and Phase 3 (CLI) are all
architecturally supported.

**Non-Functional Requirements:**
- Model-agnostic ✅ — scripts/lint-agnostic.sh enforces; no LLM-specific syntax
- Human-readable ✅ — BMAD skill format is plain markdown
- Composable ✅ — inline inclusion pattern; skills/ is authoring source
- Zero-friction install ✅ — npx → .claude/skills/ + memory/ seed
- Privacy ✅ — memory/ gitignored; read/written only by agent tools locally
- Contributor-friendly ✅ — agent-template.md + skill-template.md + CI lint

### Gap Analysis

**Critical Gaps — resolved during validation:**

1. **compiled/ build script** — the architecture defines `compiled/` as the
   npm distribution artifact (agents with skills inlined) but no build process
   was defined for assembling it from `agents/` + `skills/`.
   **Resolution:** `scripts/build-skills.sh` — a shell script (consistent with
   the existing `scripts/lint-agnostic.sh`) that reads each agent file, resolves
   `### {skill-id}` references under `## Skills` against `skills/`, inlines
   the content, and writes the assembled file to `compiled/`. Wired as a
   pre-publish step in `package.json` (`"prepublishOnly": "npm run build:skills"`).

2. **Skill invocation naming** — the name the user types to invoke an agent
   was not specified.
   **Resolution:** Namespaced pattern: `/bmad-study-professor`,
   `/bmad-study-evaluator`, `/bmad-study-quiz`, `/bmad-study-planner`,
   `/bmad-study-socratic`, `/bmad-study-coach`, `/bmad-study-troubleshooter`,
   `/bmad-study-spaced-review`. This matches the BMAD method naming convention
   (`/bmad-create-architecture`, `/bmad-prd`, etc.) and eliminates collision
   risk with other skills in the user's environment.

**Important Gaps — deferred:**

3. **Multi-environment install path** — `.claude/skills/` is Claude Code
   specific. Cursor, Windsurf, and other tool-enabled environments have
   different skill directory structures. `init` currently hardcodes one path.
   Deferred to Phase 3 scope; noted as a known limitation in README.

4. **Dev workflow documentation** — the author → build → lint → test → publish
   cycle is not yet written. Add to CONTRIBUTING.md before first external PR.

### Architecture Completeness Checklist

**Requirements Analysis**
- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**Architectural Decisions**
- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed (N/A for content system — noted)

**Implementation Patterns**
- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified (agent-to-agent handoff)
- [x] Process patterns documented (error vocabulary, memory handling)

**Project Structure**
- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status: READY FOR IMPLEMENTATION**

Both critical gaps (build script + invocation naming) are resolved above.
No open unknowns remain that would block Phase 1 content authoring.

**Confidence Level: High**

**Key Strengths:**
- BMAD skills pattern is proven — this architecture uses the same mechanism
  already running in production in this repo
- Memory system is simple, durable, and requires no infrastructure
- Inline inclusion eliminates runtime dependency resolution
- CI enforcement (lint + tsc + vitest) closes the main contributor risk vectors
- Content layer (Phases 1-2) is fully independent of CLI layer (Phase 3)

**Areas for Future Enhancement:**
- Multi-environment install support (Cursor, Windsurf, etc.)
- Automated npm release pipeline
- Commander v15 / Node 22+ migration when Node floor moves

### Implementation Handoff

**Two additions to the repo before first agent file is authored:**
1. Add `scripts/build-skills.sh` — the compiled/ assembly script
2. Add `"prepublishOnly": "bash scripts/build-skills.sh"` to `package.json`

**Phase 1 build order (from PRD, architecturally validated):**
1. `templates/student-profile.md` — Day-0 seed
2. `templates/session-log.md` — Day-0 seed
3. `templates/knowledge-map.md` — Day-0 seed
4. `templates/memory-protocol.md` — canonical On Activation block
5. `agents/planner-agent.md` — first BMAD skill; writes all memory files
6. `agents/professor-agent.md`
7. `agents/evaluator-agent.md`
8. `skills/explain-concept.md`
9. `skills/evaluate-answer.md`
10. `templates/onboarding.md`
11. `examples/java-backend-interview/`

Parallel (non-blocking after item 11):
- `templates/progress-report.md`
- `examples/system-design/`
- `examples/kubernetes/`

**AI agent guidelines for implementation:**
- All agent files follow BMAD skill structure (On Activation + Session Workflow + After Session)
- Memory files live at `{project-root}/memory/` — Read tool on activation, Edit/Write tool after session
- Skills are stateless — no file operations in skill files
- Invocation names: `/bmad-study-{agent}` (e.g., `/bmad-study-professor`)
- All 11 patterns in this document are binding — refer to them for every consistency decision
- Run `scripts/lint-agnostic.sh` before every PR
