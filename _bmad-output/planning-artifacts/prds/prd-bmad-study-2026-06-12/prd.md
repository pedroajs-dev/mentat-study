---
title: "BMAD-Study — Product Requirements Document"
status: final
created: 2026-06-12
updated: 2026-06-12
---

# BMAD-Study — Product Requirements Document

## Glossary

| Term | Definition |
|------|-----------|
| **Agent** | A markdown file defining a specialized AI role — its purpose, behavior rules, and memory protocol. Agents own session execution and write to memory files. |
| **Skill** | A reusable markdown building block that encodes a specific pedagogical behavior (e.g., generating a quiz, evaluating an answer). Skills are imported by agents; they do not act independently. |
| **Memory file** | One of three persistent markdown files (`student-profile.md`, `session-log.md`, `knowledge-map.md`) that agents read before and write after every session. |
| **Session** | A single interaction between a student and one agent, with a defined mode (Learn, Quiz, Review, Simulate, Think, Coach, Troubleshoot). |
| **Knowledge map** | The living record of what a student knows — updated by the Evaluator after every evaluated answer. |
| **Onboarding** | The first-ever session, run by the Planner Agent, that creates all three memory files from scratch. |
| **Context window** | A single AI conversation. When a new context window opens, the student pastes their memory files to resume without repeating onboarding. |

---

## 1. Overview

**BMAD-Study** is an open-source AI study system that applies the BMAD Method's structured-agent approach to learning. It ships as a set of markdown agent and skill files that any AI (Claude, ChatGPT, Cursor, or any LLM) can follow — giving any student a personalized tutor, evaluator, quiz master, planner, and thinking partner in a single install.

The product is model-agnostic, file-based, and zero-infrastructure. It runs exactly the way the BMAD Method runs: install once via `npx`, get structured markdown files, use with any AI.

---

## 2. Problem

People use AI to study in an unstructured way:

- Single generic queries with no adaptation to the student's level
- No progression, no feedback loop, no retention tracking
- No memory of what was studied, what was wrong, or what needs review
- Knowledge is consumed but not tested; gaps are never escalated; application under pressure is never practiced

The result: shallow learning, poor retention, and no real progress — regardless of how capable the underlying AI is.

---

## 3. Solution

Apply the same structured methodology the BMAD Method brought to software development — to learning.

A set of specialized AI agents with defined roles, skill files, and a session workflow that any AI can follow. The structure is the product: markdown files that encode pedagogy, not just prompts.

**Core differentiator:** BMAD-Study is not a tutoring app or a study platform. It is a structured method for using AI to study — the same way BMAD Method is a structured method for using AI to build software.

---

## 4. Principles

1. **Model-agnostic** — works with any LLM via any interface. No vendor lock-in.
2. **Structure over prompts** — agents and skills are readable markdown files. Anyone can fork and improve them.
3. **Adaptive by default** — every session starts by understanding the student's level, goal, and available time.
4. **Runs like BMAD** — install via `npx bmad-study init`, get files, use with any AI. Zero friction.
5. **Open source** — MIT license, bilingual (EN + PT-BR), community-welcoming.
6. **Dogfooded** — built using the BMAD Method. The repo documents this process transparently.

---

## 5. Target Users

### Primary: The Structured Self-Learner
A developer, professional, or student who already uses AI for learning but finds it shallow and unstructured. They are motivated and self-directed. They want a system, not a chat.

**Typical goals:** Interview prep, certification study, skill ramp on a new technology, deep understanding of a complex domain.

### Secondary: The OSS Contributor
A developer familiar with the BMAD Method or AI-native tooling who wants to contribute agent files, skill files, or domain-specific examples to the community.

---

## 6. Out of Scope

- Web interface or mobile app
- Database, user accounts, or backend
- Proprietary model integration or API keys
- Paid tier
- Real-time notifications or scheduling (the agent is the scheduler)

---

## 7. Memory System

The memory system is the foundation. Every agent reads memory files before acting and writes to them after acting. A new context window that loads the memory files knows exactly where the student is.

### 7.1 Memory Files

| File | Owner | Purpose |
|------|-------|---------|
| `memory/student-profile.md` | Planner Agent (writes once at onboarding) | Who the student is, their goal, level, time, deadline, preferred style |
| `memory/session-log.md` | All agents (append-only after every session) | Full chronological history of what was covered, scores, gaps, next steps |
| `memory/knowledge-map.md` | Evaluator Agent (updates after every evaluated answer) | Living map: Mastered / In Progress / Gaps / Never Studied / Spaced Repetition Queue |

`memory/` is gitignored. It is personal data.

### 7.2 Memory Protocol

Every agent prompt begins with:

```
MEMORY PROTOCOL — execute before every session:
1. READ student-profile.md → know who you are talking to
2. READ knowledge-map.md → know what they know and what the gaps are
3. READ last 3 entries of session-log.md → know what was recently covered

After the session:
4. APPEND to session-log.md
5. UPDATE knowledge-map.md (Evaluator only)
```

### 7.3 New Context Window Flow

When a user opens a new chat, they paste:

```
Load my BMAD-Study memory:
[paste student-profile.md]
[paste knowledge-map.md]
[paste last 3 entries of session-log.md]

I want to start a [Learn / Quiz / Review / Simulate / Think] session on [topic].
```

The agent resumes without repeating onboarding.

---

## 8. Session Workflow

```
START SESSION
    ↓
User chooses mode:
  [L] Learn     → Professor Agent
  [Q] Quiz      → Quiz Master Agent
  [R] Review    → Evaluator Agent reviews previous answers
  [S] Simulate  → Mock Exam (Quiz Master + Evaluator)
  [T] Think     → Socratic Agent
  [C] Coach     → Coach Agent (Phase 2)
  [X] Troubleshoot → Troubleshooter Agent (Phase 2)
    ↓
Session Opener Skill runs (Phase 2) — calibrates tone based on time since last session
    ↓
Agent runs session
    ↓
Evaluator scores (if applicable)
    ↓
Session log generated
    ↓
END SESSION
```

---

## 9. Features

### FR-1: Memory Templates

**FR-1.1** `templates/student-profile.md` — empty template with all fields defined (name, language, goal, topic, level, time, deadline, style, study plan).

**FR-1.2** `templates/session-log.md` — empty template with the append format defined (session number, date, agent, mode, topic, duration, what was covered, score, gaps, next recommended session).

**FR-1.3** `templates/knowledge-map.md` — empty template with all sections defined (Mastered ✅, In Progress 🔄, Gaps ❌, Never Studied ⬜, Spaced Repetition Queue).

**FR-1.4** `templates/memory-protocol.md` — reusable instruction block imported at the top of every agent prompt.

---

### FR-2: Core Agents (Phase 1)

**FR-2.1 Planner Agent** (`agents/planner-agent.md`)
- Runs onboarding and writes all three memory files
- Collects: topic, goal, level, time per day, deadline, language, preferred style
- Outputs: structured week-by-week study plan in `student-profile.md`
- Must be the first agent used in any new study journey

**FR-2.2 Professor Agent** (`agents/professor-agent.md`)
- Always confirms the student's current level before teaching
- Uses analogies and real-world examples
- Breaks complex topics into digestible chunks
- Never gives the full answer before the student attempts
- Adapts language complexity to the student profile
- Modes: Explain / Deep Dive / Analogy Mode / ELI5

**FR-2.3 Evaluator Agent** (`agents/evaluator-agent.md`)
- Scores answers 0–10 with detailed justification
- Identifies exactly what was right and what was wrong
- Points to specific knowledge gaps
- Suggests what to study next based on the gap
- Updates `knowledge-map.md` after every evaluated answer
- Output format:
  ```
  Score: X/10
  ✅ What was right:
  ❌ What was missing or incorrect:
  💡 What to review:
  📚 Suggested next step:
  ```

**FR-2.4 Quiz Master Agent** (`agents/quiz-agent.md`)
- Question types: multiple choice (4 options), open-ended, true/false with justification, scenario-based, code/command
- Modes: Quick Quiz (5q / 10min), Deep Quiz (15q / 30min), Mock Exam (timed simulation), Spaced Repetition (Anki-style)

**FR-2.5 Socratic Agent** (`agents/socratic-agent.md`)
- Responds to every question with a guiding question
- Only confirms when the student reaches the correct conclusion
- Never gives direct answers

---

**Acceptance signal for agent files:** A correct agent implementation, when loaded into any instruction-following LLM with a reference student memory context, produces output that satisfies all behavior bullets listed in its FR. The Evaluator Agent (FR-2.3) output format is the model: a fully specified output structure is the acceptance criterion. For agents where no output format is specified, the acceptance signal is that the agent follows every listed behavior rule across three distinct test prompts without requiring user correction.

---

### FR-3: Core Skills (Phase 1)

**FR-3.1** `skills/explain-concept.md` — how the Professor explains any topic
**FR-3.2** `skills/generate-quiz.md` — how the Quiz Master creates questions
**FR-3.3** `skills/evaluate-answer.md` — how the Evaluator scores and gives feedback
**FR-3.4** `skills/build-study-plan.md` — how the Planner structures a learning journey
**FR-3.5** `skills/generate-flashcards.md` — how to generate spaced repetition cards
**FR-3.6** `skills/run-mock-exam.md` — how to run a timed full simulation

[NOTE FOR PM: before the first external OSS contribution PR is accepted, add a reference test prompt per skill — a canonical input + expected output shape that contributors can run to verify their file behaves correctly.]

---

### FR-4: Onboarding Template (Phase 1)

**FR-4.1** `templates/onboarding.md` — the full onboarding flow for the Planner Agent to follow. Includes all 7 questions, example responses, and instructions for writing the three memory files.

---

### FR-5: First Example (Phase 1)

**FR-5.1** `examples/java-backend-interview/` — a complete worked example using pre-existing content:
- Behavioral questions + STAR answers
- Technical topics: Kafka, Spring Boot, Design Patterns, System Design
- A pre-filled `student-profile.md`, `session-log.md` (first session), and `knowledge-map.md` showing what a real study journey looks like

---

### FR-6: Extended Agents (Phase 2)

**FR-6.1 Coach Agent** (`agents/coach-agent.md`)
- The meta-agent. Reads all three memory files in full.
- Does not teach or quiz — interprets and directs.
- Answers: "Am I on track?", "What should I focus on this week?", "Is this gap critical or minor?", "Should I go deeper here or move on?"
- The only agent with a full-picture view of the student's arc. Planner sets the plan once; Coach reads reality and adjusts continuously.
- When the student's session-log shows content studied N+ days ago with no review, Coach surfaces a recommendation and offers to hand off to the Spaced Review Agent: "You studied Kafka consumers 12 days ago with a gap in offset management — want me to run a spaced review session?"

**FR-6.3 Spaced Review Agent** (`agents/spaced-review-agent.md`)
- Reads `session-log.md` to identify content studied N+ days ago that has not been revisited
- Orchestrates a targeted review session using `generate-flashcards.md` and `generate-quiz.md` skills
- Prioritizes content from the knowledge-map's "In Progress" and "Gaps" sections over Mastered content
- Exits with an updated knowledge-map entry and a suggested next review date per reviewed concept
- Triggered directly by the student or via Coach Agent recommendation

---

**FR-6.2 Troubleshooter Agent** (`agents/troubleshooter-agent.md`)
- Presents real-world scenarios the student has never seen explicitly
- Evaluates thinking process, not just the answer: "what would you DO if X happened?"
- Rewards structured breakdown: "I'd first check... then I'd look at... if that fails I'd..."
- Key differentiator from Quiz Master: Quiz Master tests knowledge. Troubleshooter tests judgment.

---

### FR-7: Extended Skills (Phase 2)

**FR-7.1** `skills/session-opener.md` — runs at the start of every session. Reads session-log.md + current date. Calibrates tone and warm-up based on time away:
- 0–2 days: brief recap of where things left off
- 3–7 days: retrieval warm-up before continuing
- 8+ days: re-assess level before jumping back in

**FR-7.2** `skills/build-scenario.md` — generates novel real-world situations solvable with concepts the student already studied. Forces synthesis, not recall. Ships alongside Troubleshooter Agent.

**FR-7.3** `skills/concept-precision.md` — asks the student to define a term in their own words, then challenges imprecise language. Catches "I know the word but not the concept."

**FR-7.4** `skills/escalate-challenge.md` — triggered when score is 6–8 AND gaps exist. Generates harder questions targeting weak spots. Forces the student past the comfortable plateau.

---

### FR-8: CLI Distribution (Phase 3)

**FR-8.1** `npx bmad-study init` installs agent and skill files to `~/.bmad-study/` (or current directory).

**FR-8.2** CLI runs an onboarding questionnaire and generates `study-plan.md` in the current directory.

**FR-8.3** CLI prints instructions for loading files into the user's preferred AI.

**FR-8.4** No API keys required. No backend. Pure file + prompt distribution.

**FR-8.5** Package published to npm as `bmad-study`.

**FR-8.6** Tech stack: Node.js, Commander.js or Inquirer.js.

---

## 10. Non-Functional Requirements

**NFR-1 Model-agnostic** — all agents and skills must produce correct behavior with any instruction-following LLM (Claude, GPT-4+, Gemini, Llama 3+, etc.). No model-specific syntax.

**NFR-2 Human-readable** — all files are plain markdown. No YAML frontmatter required for agent operation. A human must be able to read any agent file and understand exactly what the AI will do.

**NFR-3 Composable** — skills are reusable building blocks. Agents import skills via explicit reference. Adding a new skill should not require modifying existing agents.

**NFR-4 Bilingual** — README and onboarding template available in EN and PT-BR. All agent and skill files are English only. Students may set their preferred response language in `student-profile.md`; the AI responds accordingly, but the agent files themselves are always EN.

**NFR-5 Zero friction install** — `npx bmad-study init` must work with Node.js 18+ and no prior configuration. Time from command to first usable file: under 60 seconds.

**NFR-6 Privacy** — `memory/` is gitignored. No student data is collected, transmitted, or stored outside the user's local file system.

**NFR-7 Contributor-friendly** — adding a new agent, skill, or example requires only adding a markdown file. No code changes required for content contributions.

---

## 11. Repository Structure

```
bmad-study/
├── agents/
│   ├── professor-agent.md
│   ├── evaluator-agent.md
│   ├── quiz-agent.md
│   ├── planner-agent.md
│   ├── socratic-agent.md
│   ├── coach-agent.md          ← Phase 2
│   ├── troubleshooter-agent.md ← Phase 2
│   └── spaced-review-agent.md  ← Phase 2
├── skills/
│   ├── explain-concept.md
│   ├── generate-quiz.md
│   ├── evaluate-answer.md
│   ├── build-study-plan.md
│   ├── generate-flashcards.md
│   ├── run-mock-exam.md
│   ├── session-opener.md       ← Phase 2
│   ├── build-scenario.md       ← Phase 2
│   ├── concept-precision.md    ← Phase 2
│   └── escalate-challenge.md   ← Phase 2
├── templates/
│   ├── onboarding.md
│   ├── memory-protocol.md
│   ├── session-log.md
│   ├── student-profile.md
│   ├── knowledge-map.md
│   └── progress-report.md
├── memory/                     ← gitignored, generated per user
│   ├── student-profile.md
│   ├── session-log.md
│   └── knowledge-map.md
├── examples/
│   ├── java-backend-interview/
│   ├── system-design/
│   └── kubernetes/
├── .gitignore
├── README.md                   ← EN
├── README.pt.md                ← PT-BR
└── package.json                ← npx entry point (Phase 3)
```

---

## 12. Phased Delivery

### Phase 1 — Foundation (Memory + Core Agents)

**Goal:** A working study system usable immediately with any AI, no CLI required.

**Build order (strict):**
1. `templates/student-profile.md`
2. `templates/session-log.md`
3. `templates/knowledge-map.md`
4. `templates/memory-protocol.md`
5. `agents/planner-agent.md`
6. `agents/professor-agent.md`
7. `agents/evaluator-agent.md`
8. `skills/explain-concept.md`
9. `skills/evaluate-answer.md`
10. `templates/onboarding.md`
11. `examples/java-backend-interview/`

The following ship within Phase 1 but are not blocking the exit criterion — they can be built in parallel after item 11:

12. `templates/progress-report.md`
13. `examples/system-design/`
14. `examples/kubernetes/`

Remaining core agents (Quiz Master, Socratic) and skills (generate-quiz, build-study-plan, generate-flashcards, run-mock-exam) follow after the above are validated.

**Exit criterion:** A student can complete a full onboarding → learn → quiz → evaluate loop using only the generated files and any AI, with no external tooling. Three worked examples cover distinct domains (Java backend interview, system design, Kubernetes).

---

### Phase 2 — Strategic Layer (Coach + Application)

**Goal:** Close the gap between knowing content and applying it under pressure. Add the meta-agent that reads the full picture.

**Build order:**
1. `skills/session-opener.md`
2. `agents/coach-agent.md`
3. `agents/troubleshooter-agent.md` + `skills/build-scenario.md` (ship together)
4. `agents/spaced-review-agent.md` — reads session-log.md, knows what was studied and when, orchestrates review sessions for content studied N days ago. Coach Agent is aware of it and may route students to it.
5. `skills/concept-precision.md`
6. `skills/escalate-challenge.md`

**Exit criterion:** A student who has been using the system for 2+ weeks can get strategic direction (Coach), practice under simulated pressure (Troubleshooter), and receive more demanding feedback when they plateau.

---

### Phase 3 — CLI Distribution

**Goal:** Zero-friction install. `npx bmad-study init` delivers the full Phase 1+2 file set with onboarding.

**Exit criterion:** A new user runs `npx bmad-study init`, completes the CLI onboarding, and has a working `study-plan.md` and all agent/skill files in under 60 seconds.

---

## 13. Open Questions

All open questions resolved. See `.decision-log.md` for decisions DL-001 through DL-010.
