# BMAD-Study — Project Briefing for BMAD

> Cole este documento no BMAD como contexto inicial do projeto.
> O BMAD usará isso para entender a visão, tomar decisões de arquitetura e começar a construir.

---

## Project Overview

**Project name:** BMAD-Study
**Type:** Open source CLI tool + AI agent system
**Inspired by:** BMAD Method (github.com/bmad-code-org/BMAD-METHOD)
**Built with:** BMAD Method (dogfooding — we use BMAD to build BMAD-Study)

### One-liner
> A structured AI study method — specialized agents that turn any AI into a personalized tutor, evaluator, and study partner.

### The Problem
People use AI to study in an unstructured way:
- Single generic queries with no adaptation to their level
- No progression, no feedback loop, no retention tracking
- No memory of what was studied, what was wrong, what needs review
- The result: shallow learning, poor retention, no real progress

### The Solution
Apply the same structured methodology BMAD brought to software development — to learning.
A set of specialized AI agents with defined roles, skill files, and a session workflow that any AI can follow.
Model-agnostic. Ships via `npx bmad-study init`. Open source. MIT license.

---

## Core Principles

1. **Model-agnostic** — works with Claude, ChatGPT, Cursor, or any LLM via API. No vendor lock-in.
2. **Structure over prompts** — agents and skills are markdown files, not magic. Anyone can read, fork, and improve them.
3. **Adaptive by default** — every session starts by understanding the student's level, goal, and available time.
4. **Dogfooding** — we use BMAD to build BMAD-Study. The repo documents this process transparently.
5. **Open source community** — MIT license, bilingual (EN + PT-BR), welcoming to contributors.

---

## The 5 Core Agents

### 1. Professor Agent (`professor-agent`)
**Role:** Teach concepts at the right level.
**Behavior:**
- Always starts by confirming the student's current level on the topic
- Uses analogies and real-world examples
- Breaks complex topics into digestible chunks
- Never gives the full answer before the student attempts
- Adapts language complexity to the student profile

**Modes:** Explain / Deep Dive / Analogy Mode / ELI5

---

### 2. Evaluator Agent (`evaluator-agent`)
**Role:** Review answers and give structured, honest feedback.
**Behavior:**
- Scores answers from 0–10 with detailed justification
- Identifies exactly what was right and what was wrong
- Points to specific knowledge gaps
- Suggests what to study next based on the gap
- Never just says "correct" or "incorrect" — always explains why

**Output format:**
```
Score: X/10
✅ What was right:
❌ What was missing or incorrect:
💡 What to review:
📚 Suggested next step:
```

---

### 3. Quiz Master Agent (`quiz-agent`)
**Role:** Generate questions adapted to level and goal.
**Question types:**
- Multiple choice (4 options, 1 correct)
- Open-ended (no hints)
- True/False with justification required
- Scenario-based (real-world situation to solve)
- Code/command questions (for technical topics)

**Modes:**
- Quick Quiz (5 questions, 10 min)
- Deep Quiz (15 questions, 30 min)
- Mock Exam (timed, full simulation)
- Spaced Repetition (Anki-style flashcard generation)

---

### 4. Planner Agent (`planner-agent`)
**Role:** Run onboarding and build a personalized study plan.
**Onboarding questions:**
1. What do you want to study?
2. Why? (goal: exam / interview / career change / personal growth)
3. Current level on this topic? (beginner / intermediate / advanced)
4. How much time per day? (15min / 30min / 1h / 2h+)
5. Deadline? (if any)
6. Preferred language? (EN / PT-BR)
7. Preferred style? (theory-first / practice-first / mixed)

**Output:** Structured study plan in markdown with week-by-week breakdown and agent recommendations per session.

---

### 5. Socratic Agent (`socratic-agent`)
**Role:** Force deep thinking through questions, never direct answers.
**Behavior:**
- Responds to every question with a guiding question
- Leads the student to discover the answer themselves
- Only confirms when the student reaches the correct conclusion
- Ideal for complex conceptual topics

---

## Skill Files (building blocks)

| Skill | Description |
|-------|-------------|
| `explain-concept.md` | How the Professor explains any topic |
| `generate-quiz.md` | How the Quiz Master creates questions |
| `evaluate-answer.md` | How the Evaluator scores and gives feedback |
| `build-study-plan.md` | How the Planner structures a learning journey |
| `generate-flashcards.md` | How to generate spaced repetition cards |
| `run-mock-exam.md` | How to run a timed full simulation |

---

## Session Workflow

```
START SESSION
    ↓
User chooses mode:
[L] Learn      → Professor Agent
[Q] Quiz       → Quiz Master Agent
[R] Review     → Evaluator Agent reviews previous answers
[S] Simulate   → Mock Exam (Quiz Master + Evaluator combined)
[T] Think      → Socratic Agent
    ↓
Agent runs session
    ↓
Evaluator scores (if applicable)
    ↓
Session log generated (what was covered, score, gaps, next step)
    ↓
END SESSION
```

---

## Memory System

This is the core mechanism that gives BMAD-Study persistence across sessions and context windows.
Every agent reads memory files before acting. Every agent writes to memory files after acting.
A new context window that loads the memory files knows exactly where the student is.

### Memory Files (written by agents, read by all)

```
bmad-study/
└── memory/
    ├── student-profile.md     ← written by Planner at onboarding
    ├── session-log.md         ← appended by every agent at session end
    └── knowledge-map.md       ← updated by Evaluator after every answer
```

---

### `student-profile.md` — Written by Planner Agent

Created once during onboarding. Updated only if the student explicitly requests changes.

```markdown
# Student Profile

**Name:** [name or anonymous]
**Language:** EN / PT-BR
**Created:** YYYY-MM-DD
**Last updated:** YYYY-MM-DD

## Study Goal
[What they want to achieve and why]

## Current Topic
[The topic currently being studied]

## Level
[beginner / intermediate / advanced] — self-reported + adjusted by Evaluator over time

## Available Time
[X minutes per day]

## Deadline
[date or "none"]

## Preferred Style
[theory-first / practice-first / mixed]

## Study Plan
[Week-by-week breakdown generated by Planner]
```

---

### `session-log.md` — Appended by every agent at session end

Never overwritten — always appended. This is the full history.

```markdown
# Session Log

---

## Session [N] — YYYY-MM-DD
**Agent:** [Professor / Quiz Master / Evaluator / Socratic]
**Mode:** [Learn / Quiz / Review / Simulate / Think]
**Topic:** [specific topic covered]
**Duration:** [X minutes]

### What was covered
[bullet list of concepts or questions addressed]

### Score (if applicable)
[X/10 — or N/A]

### Gaps identified
[bullet list of weak areas]

### Next recommended session
[specific suggestion for next session]

---
```

---

### `knowledge-map.md` — Updated by Evaluator Agent

The living map of what the student knows. Updated after every evaluated answer.

```markdown
# Knowledge Map

**Topic:** [main topic]
**Last updated:** YYYY-MM-DD

## Mastered ✅
[concepts with consistent correct answers]

## In Progress 🔄
[concepts partially understood — needs more practice]

## Gaps ❌
[concepts with wrong or incomplete answers]

## Never studied ⬜
[concepts from the study plan not yet covered]

## Spaced Repetition Queue
[concepts to revisit — with suggested review date]
```

---

### How agents use memory

Every agent prompt must start with this instruction block:

```
MEMORY PROTOCOL — execute before every session:

1. READ student-profile.md → know who you are talking to
2. READ knowledge-map.md → know what they already know and what the gaps are
3. READ last 3 entries of session-log.md → know what was recently covered

After the session:
4. APPEND to session-log.md → log what happened
5. UPDATE knowledge-map.md → reflect new knowledge state (Evaluator only)
```

---

### Memory in new context windows

When a user opens a new chat/context window, they paste this at the start:

```
Load my BMAD-Study memory:

[paste student-profile.md]
[paste knowledge-map.md]
[paste last 3 entries of session-log.md]

I want to start a [Learn / Quiz / Review / Simulate] session on [topic].
```

The agent immediately knows the student's full context without repeating onboarding.

---

### Memory Lifecycle

```
ONBOARDING (once)
    Planner writes → student-profile.md
    Planner writes → knowledge-map.md (empty template)
    Planner writes → session-log.md (session 1 entry)
         ↓
EVERY SESSION
    All agents read → student-profile.md + knowledge-map.md + last 3 session-log entries
    All agents append → session-log.md
    Evaluator updates → knowledge-map.md
         ↓
NEW CONTEXT WINDOW
    User pastes → the 3 memory files
    Agent continues → as if no context was lost
```

---

## Repository Structure

```
bmad-study/
├── agents/
│   ├── professor-agent.md
│   ├── evaluator-agent.md
│   ├── quiz-agent.md
│   ├── planner-agent.md
│   └── socratic-agent.md
├── skills/
│   ├── explain-concept.md
│   ├── generate-quiz.md
│   ├── evaluate-answer.md
│   ├── build-study-plan.md
│   ├── generate-flashcards.md
│   └── run-mock-exam.md
├── templates/
│   ├── onboarding.md
│   ├── session-log.md         ← template (empty)
│   ├── student-profile.md     ← template (empty)
│   ├── knowledge-map.md       ← template (empty)
│   └── progress-report.md
├── memory/                    ← generated per user, gitignored
│   ├── student-profile.md
│   ├── session-log.md
│   └── knowledge-map.md
├── examples/
│   ├── java-backend-interview/
│   ├── system-design/
│   └── kubernetes/
├── .gitignore                 ← memory/ is gitignored (personal data)
├── README.md                  ← EN
├── README.pt.md               ← PT-BR
└── package.json               ← npx entry point
```

---

## MVP Scope (Phase 1 — Days 1–3)

The BMAD should focus first on:

1. `templates/student-profile.md` — memory file template. Nothing works without this.
2. `templates/session-log.md` — memory file template. Required for persistence.
3. `templates/knowledge-map.md` — memory file template. Required for adaptation.
4. `planner-agent.md` — runs onboarding and writes the memory files. Must come before other agents.
5. `professor-agent.md` — the most important teaching agent.
6. `evaluator-agent.md` — updates knowledge-map.md after every answer.
7. `explain-concept.md` skill — core building block for the Professor.
8. `evaluate-answer.md` skill — core building block for the Evaluator.
9. `onboarding.md` template — the full onboarding flow.
10. One complete example: `examples/java-backend-interview/` — uses content we already have.

Do NOT start with the CLI (npx). That is Phase 3. Focus on memory templates + agent files first.

**The order matters:** memory templates → planner → professor → evaluator → skills → example.

---

## Example Content We Already Have

The following content exists and can be used directly as example material:

### Kubernetes Study
- 5 troubleshooting scenarios (OOMKilled, CrashLoopBackOff, Liveness/Readiness, ConfigMap/Secret, Rollback)
- Essential kubectl commands
- 6-week study roadmap + 5-day crash plan

### Java Backend Interview Prep
- Behavioral questions + STAR answers (real examples from Pedro's career)
- Technical topics: Kafka, Spring Boot, Design Patterns, System Design
- Real achievement stories: 75% processing time reduction, 10x latency improvement, sub-200ms fraud APIs

### System Design
- DDIA study plan (Kleppmann)
- Alex Xu roadmap
- 6-month progressive plan

---

## Tech Stack for CLI (Phase 3 only)

- **Runtime:** Node.js
- **CLI framework:** Commander.js or Inquirer.js
- **Package:** Published to npm as `bmad-study`
- **Entry point:** `npx bmad-study init`
- **What it does:**
  1. Downloads agent and skill files to `~/.bmad-study/`
  2. Runs onboarding questionnaire
  3. Generates `study-plan.md` in current directory
  4. Prints instructions for use with preferred AI

No API keys required. No backend. Pure file + prompt distribution.

---

## Constraints & Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Language | Bilingual (EN + PT-BR) | Maximize reach — Brazil + global |
| Model | Agnostic | No vendor lock-in, wider adoption |
| License | MIT | Open contribution |
| Distribution | npx | Zero friction, BMAD-style |
| Phase 1 focus | Agents + skills only | Validate the method before building CLI |
| First example | Java Backend Interview | Authentic — built from real prep material |

---

## What We're NOT Building (yet)

- Web interface
- Database or user accounts
- API backend
- Proprietary model integration
- Paid tier

Keep it simple. Markdown files + CLI. The power is in the structure, not the infrastructure.

---

## The Story (for README and launch)

> Most people use AI to study the same way they Googled in 2005 — one question at a time, no structure, no progression.
>
> BMAD-Study applies the same principle that made the BMAD Method powerful for software development: specialized agents with defined roles, structured workflows, and skill files that any AI can follow.
>
> The result: a Professor that adapts to your level, an Evaluator that gives honest feedback, a Quiz Master that generates real challenges, a Planner that builds your roadmap, and a Socratic agent that forces you to think.
>
> Model-agnostic. Open source. Ships in one command.
>
> `npx bmad-study init`

---

## First Message to Send BMAD

After loading this briefing, send BMAD this message to kick off:

```
You are now the architect of the BMAD-Study project.
You have full context from the briefing above.

Let's start with Phase 1. Your first task is the Memory System — it must exist before any agent can be built.

1. Create `templates/student-profile.md` — empty template with all fields defined
2. Create `templates/session-log.md` — empty template with the append format defined
3. Create `templates/knowledge-map.md` — empty template with all sections defined
4. Create `templates/memory-protocol.md` — the reusable instruction block that every agent will include at the top of their prompt (READ before session, WRITE after session)

The memory system is the foundation. Every agent will import and follow the memory-protocol.
Think carefully about the format — it must be easy for any AI to read, parse, and write without errors.

Follow the BMAD methodology. Think before building. Ask clarifying questions if needed.
Let's build something great.
```
