---
baseline_commit: NO_VCS
---

# Story 1.1: Repo Foundation

Status: review

## Story

As a contributor,
I want the repository to have all foundational scaffolding in place,
so that I can immediately start authoring agent and skill files with clear format contracts and automated quality gates.

## Acceptance Criteria

1. **Given** a fresh clone of the repo **When** I open `.gitignore` **Then** `memory/`, `dist/`, `compiled/`, and `node_modules/` are listed as gitignored entries.

2. **Given** I read `agent-template.md` and `skill-template.md` **When** I follow their structure **Then** I can produce a valid agent or skill file that passes lint without reading any other documentation — every required section and frontmatter field is shown by example with inline comments.

3. **Given** I run `scripts/lint-agnostic.sh` against any file in `agents/` or `skills/` **When** the file contains a model name (e.g., "GPT-4", "Claude", "Gemini"), a platform-specific syntax, or a context-window-size reference **Then** the script exits non-zero and reports the offending line and filename.

4. **Given** a PR is opened against main **When** CI runs **Then** the workflow executes in order: `scripts/lint-agnostic.sh` → `tsc --noEmit` → `vitest run`; all three must pass for the PR check to succeed.

5. **Given** I read `CONTRIBUTING.md` **When** I want to add a new agent or skill **Then** I find: (a) where to place the file, (b) required YAML frontmatter fields (`id`, `version`, `type`), (c) how to run lint locally, (d) how to build `compiled/` and verify output.

6. **Given** CI runs on a PR and `lint-agnostic.sh` fails **When** the CI log is inspected **Then** the offending line is visible and the workflow exits with a non-zero code.

## Tasks / Subtasks

- [x] Task 1: Create `.gitignore` (AC: #1)
  - [x] Add entries: `memory/`, `dist/`, `compiled/`, `node_modules/`

- [x] Task 2: Create stub `README.md` and `README.pt.md` (no AC — prerequisite for NFR-4)
  - [x] `README.md`: project name, one-line description, "coming soon" install instructions, link to `README.pt.md`
  - [x] `README.pt.md`: Portuguese mirror of same stub content

- [x] Task 3: Create `agent-template.md` (AC: #2)
  - [x] Include YAML frontmatter with all required fields shown: `id`, `version`, `type: agent` — each with inline comment
  - [x] Include all required sections with inline comments: title/persona block, `## On Activation`, `## Skills`, `## Session Workflow`, `## After Session`
  - [x] Show `## On Activation` with the 5-step memory read + schema check pattern (see Dev Notes)
  - [x] Show `## Skills` with one stub `### example-skill` block (placeholder content)
  - [x] Show `## After Session` with session-log append and knowledge-map update stubs
  - [x] Template must pass `lint-agnostic.sh` — no model names, no platform syntax

- [x] Task 4: Create `skill-template.md` (AC: #2)
  - [x] Include YAML frontmatter: `id`, `version`, `type: skill` with inline comments
  - [x] Include required sections: `## Purpose`, `## Instructions` with inline comments
  - [x] Add inline comment: "Skills are stateless — NO memory file reads or writes here. Memory belongs in the agent's On Activation / After Session."
  - [x] Template must pass `lint-agnostic.sh`

- [x] Task 5: Create `CONTRIBUTING.md` (AC: #5)
  - [x] Section: "Adding a new agent" — file location (`agents/`), required frontmatter (`id`, `version`, `type: agent`), required sections (On Activation, Skills, Session Workflow, After Session)
  - [x] Section: "Adding a new skill" — file location (`skills/`), required frontmatter (`id`, `version`, `type: skill`), stateless constraint
  - [x] Section: "Running lint locally" — `bash scripts/lint-agnostic.sh agents/ skills/`
  - [x] Section: "Building compiled output" — `bash scripts/build-skills.sh`, then inspect `compiled/`
  - [x] Section: "Opening a PR" — must pass CI (lint → tsc → vitest)

- [x] Task 6: Create `scripts/lint-agnostic.sh` (AC: #3, #6)
  - [x] Accept one or more file/directory arguments; default to `agents/ skills/` if none given
  - [x] Detect model names: GPT-4, GPT-3, Claude, Gemini, Llama, Mistral, Grok (case-insensitive)
  - [x] Detect platform-specific syntax patterns: `<claude:`, `{anthropic:`, `[INST]`, `<|im_start|>`, `<s>` (common instruct/chat tokens)
  - [x] Detect context-window-size references: numeric patterns like "128k", "200k", "32k context", "context window"
  - [x] On any match: print `ERROR: {filename}:{line}: {offending text}` and exit 1
  - [x] On clean pass: print `lint-agnostic: all files OK` and exit 0
  - [x] Must be executable (`chmod +x scripts/lint-agnostic.sh`)

- [x] Task 7: Create `.github/workflows/ci.yml` (AC: #4, #6)
  - [x] Trigger on: `push` to `main`, `pull_request` targeting `main`
  - [x] Single job `ci` with steps in this exact order:
    1. `actions/checkout@v4`
    2. `actions/setup-node@v4` with `node-version: '18'`
    3. `npm ci`
    4. `bash scripts/lint-agnostic.sh agents/ skills/` — step named "Lint: model-agnostic check"
    5. `npx tsc --noEmit` — step named "Type check"
    6. `npx vitest run` — step named "Tests"
  - [x] No `continue-on-error` on any step — failure must halt the job

- [x] Task 8: Create minimal `package.json` to make CI steps 5–6 work (prerequisite)
  - [x] `name: "bmad-study"`, `version: "0.0.1"`, `private: true` (not yet for publish)
  - [x] `devDependencies`: `typescript`, `vitest`
  - [x] `scripts.test: "vitest run"`, `scripts.typecheck: "npx tsc --noEmit"`
  - [x] `engines: { "node": ">=18" }`
  - [x] Add `tsconfig.json` stub: `strict: true`, `noEmit: true`, `target: ES2020`

## Dev Notes

### Agent Template Structure (exact sections required)

Every agent file must follow this structure (Pattern 1 + Pattern 2 from architecture):

```markdown
---
id: {agent-id}          # kebab-case, matches compiled filename: compiled/bmad-study-{agent-id}.md
version: 1.0.0
type: agent
---

# {Agent Title}

{One-paragraph persona: who this agent is, tone, teaching approach}

## On Activation

1. Read {project-root}/memory/student-profile.md
   → Know who you are talking to (name, level, goal, available time, deadline)
2. Read {project-root}/memory/knowledge-map.md
   → Know what they know and what the gaps are
3. Read {project-root}/memory/session-log.md (last 3 session entries only)
   → Know what was recently covered
4. Schema version check: if memory-protocol-version in any file ≠ 1, halt immediately and say:
   "Your memory files are from an older version of BMAD-Study. Please re-run onboarding with /bmad-study-planner."
5. Greet the student by name. Confirm current topic and session mode.

## Skills

### {skill-id}
{full skill content inlined here by build-skills.sh — do not edit compiled/ directly}

## Session Workflow

{agent behavior during the session}

## After Session

- Append to {project-root}/memory/session-log.md using the canonical append format
- [Evaluator and Spaced Review only] Update {project-root}/memory/knowledge-map.md
```

### Skill Template Structure (exact sections required)

```markdown
---
id: {skill-id}          # kebab-case, matches filename: skills/{skill-id}.md
version: 1.0.0
type: skill
---

## Purpose

{One sentence: what this skill does}

## Instructions

{All instructions written in second person imperative, addressed to the LLM executing the file}
{NEVER reference student-profile.md, session-log.md, or knowledge-map.md here — skills are stateless}
```

### Lint Script — Exact Detection Requirements

The lint script must detect ALL of the following (case-insensitive for model names):

**Model names to block:** `GPT-4`, `GPT-3`, `GPT4`, `GPT3`, `Claude`, `Gemini`, `Llama`, `Mistral`, `Grok`, `Falcon`, `PaLM`

**Platform tokens to block:** `<claude:`, `{anthropic:`, `[INST]`, `<<SYS>>`, `<|im_start|>`, `<|im_end|>`, `<s>`, `</s>`, `<|endoftext|>`

**Context-window references to block:** any occurrence of `context window`, `128k`, `200k`, `32k`, `100k`, `token limit`, `context length`

**Files to scan:** all `.md` files under the given directories; skip `compiled/` (it's generated output)

**Output format on failure:**
```
lint-agnostic ERROR: agents/professor-agent.md:42: model name detected: "Claude"
```

### CI Order — Architecture Requirement (ARCH-9)

The CI pipeline step order is MANDATORY per architecture. Build step (`build-skills.sh`) does NOT run in Story 1.1 (that's Story 1.3). The CI here handles TypeScript content only. Story 1.3 adds the build step as step 1 in CI.

Current order for this story's CI:
1. `lint-agnostic.sh` (catches model names in any new content)
2. `tsc --noEmit` (TypeScript type check — even if no TS yet, zero files = pass)
3. `vitest run` (tests — even if no tests yet, zero tests = pass)

### File Structure Being Created

```
bmad-study/                        ← repo root
├── .gitignore                     ← NEW: memory/, dist/, compiled/, node_modules/
├── .github/
│   └── workflows/
│       └── ci.yml                 ← NEW: lint → tsc → vitest
├── scripts/
│   └── lint-agnostic.sh           ← NEW: executable bash script
├── agent-template.md              ← NEW: contributor reference, repo root
├── skill-template.md              ← NEW: contributor reference, repo root
├── CONTRIBUTING.md                ← NEW: contributor guide, repo root
├── README.md                      ← NEW: stub
├── README.pt.md                   ← NEW: stub (Portuguese)
├── package.json                   ← NEW: minimal, not yet publishable
└── tsconfig.json                  ← NEW: stub for tsc --noEmit to work
```

**Note:** `agents/`, `skills/`, `compiled/`, `memory/`, `templates/`, `examples/` directories are NOT created in this story — each epic/story creates exactly what it needs. Do not create placeholder directories.

### YAML Frontmatter Contract (ARCH-14)

Every agent and skill file requires exactly these three frontmatter fields. No more, no less:

```yaml
---
id: {kebab-case-identifier}
version: {semver}
type: {agent|skill}
---
```

The `id` field in an agent file maps to its compiled filename: `compiled/bmad-study-{id}.md`.
The `id` field in a skill file maps to its source filename: `skills/{id}.md`.

### Instruction Language Convention (Pattern 3)

All content in agent-template.md and skill-template.md must demonstrate the correct instruction voice:
- **Correct:** `"Always confirm the student's current topic before starting."`
- **Wrong:** `"The agent should confirm the student's current topic."` or `"I will confirm..."`

This is the most common contributor mistake. The template comments must make this explicit.

### NFR-2 — Human Readability

The templates must read as living documentation. Every section heading and stub comment should be self-explanatory so a new contributor who has never seen BMAD can open `agent-template.md` and produce a valid agent file without reading anything else first.

### Testing Approach

No unit tests are introduced in this story — the deliverables are shell scripts and markdown. The CI job itself is the integration test: a real workflow file that runs real tools. Confirm locally by:
1. Running `bash scripts/lint-agnostic.sh agent-template.md skill-template.md` — should pass clean
2. Checking `npx tsc --noEmit` returns 0 with the tsconfig stub
3. Checking `npx vitest run` returns 0 with no test files (Vitest exits 0 on empty suite)

### Project Structure Notes

- `scripts/` is at repo root (not inside `src/`). CLI TypeScript code lives in `src/` — that's Epic 5. Shell scripts live at `scripts/`.
- `agent-template.md` and `skill-template.md` go at repo root per ARCH-14.
- `CONTRIBUTING.md` goes at repo root (GitHub convention).
- `.github/workflows/ci.yml` is the standard GitHub Actions path.
- Do NOT create `src/` directory in this story — that's Epic 5.

### References

- Agent file format contract: [Source: architecture.md#Content Architecture]
- Required sections in agent files: [Source: architecture.md#Pattern 1 — Skill Composition]
- Heading hierarchy: [Source: architecture.md#Pattern 2 — Heading Hierarchy]
- Instruction language: [Source: architecture.md#Pattern 3 — Instruction Language]
- Memory On Activation pattern: [Source: architecture.md#Pattern 5 — Memory Protocol]
- Lint script requirements (model-agnostic): [Source: architecture.md#Pattern 9 — Stateless Skills], [Source: architecture.md#ARCH-8]
- CI pipeline order: [Source: architecture.md#ARCH-9], [Source: epics.md#Epic 5 CI execution order]
- YAML frontmatter: [Source: architecture.md#All Contributors MUST]
- Gitignore entries: [Source: architecture.md#ARCH-15]
- Story ACs: [Source: epics.md#Story 1.1]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Vitest v1.6.1 exits code 1 with no test files; fixed by adding `--passWithNoTests` flag to both `package.json` scripts and `ci.yml`.
- `tsc --noEmit` emits TS18003 with no input files; fixed by adding `types.ts` stub at repo root and `"include": ["*.ts", "src/**/*"]` in tsconfig.

### Completion Notes List

- All 8 tasks implemented and validated locally.
- `lint-agnostic.sh` catches model names (case-insensitive), platform tokens, and context-window references; exits 1 with `lint-agnostic ERROR: file:line: ...` format.
- Templates (`agent-template.md`, `skill-template.md`) pass lint clean.
- `tsc --noEmit` exits 0 via `types.ts` placeholder stub.
- `vitest run --passWithNoTests` exits 0 with zero test files.
- CI workflow enforces exact order: lint → tsc → vitest; no `continue-on-error`.

### File List

- `.gitignore`
- `README.md`
- `README.pt.md`
- `agent-template.md`
- `skill-template.md`
- `CONTRIBUTING.md`
- `scripts/lint-agnostic.sh`
- `.github/workflows/ci.yml`
- `package.json`
- `package-lock.json`
- `tsconfig.json`
- `types.ts`

## Change Log

- 2026-06-14: Story 1.1 implemented — repo foundation scaffolding created (all 8 tasks, ACs #1–#6 satisfied)
