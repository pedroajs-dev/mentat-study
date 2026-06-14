---
stepsCompleted: [1, 2, 3]
session_topic: 'New agents and skills for bmad-study to make the system more robust and ensure user study success'
session_goals: 'Explore what agents and skills are missing from the current learning journey — covering retention, motivation, accountability, practical application, and progress awareness'
selected_approach: 'ai-recommended'
techniques_used: ['reverse-brainstorming', 'cross-pollination', 'solution-matrix']
ideas_generated: 9
---

# Brainstorming Session — 2026-06-12

**Topic:** New agents and skills for bmad-study
**Goal:** Close the gaps in the current 5-agent system so users achieve real study success — not just consume content.

---

## Session Overview

### Context

bmad-study currently has:

**Agents:** Professor, Evaluator, Quiz Master, Planner, Socratic
**Skills:** explain-concept.md, generate-quiz.md, evaluate-answer.md, build-study-plan.md, generate-flashcards.md, run-mock-exam.md
**Memory System:** student-profile.md, session-log.md, knowledge-map.md

The system covers content delivery and feedback well. What's missing: the strategic layer, re-entry experience, and the bridge from knowledge to real-world application.

---

## Technique Selection

**Approach:** AI-Recommended
**Phase 1:** Reverse Brainstorming — find gaps via student failure archetypes
**Phase 2:** Cross-Pollination — mine Matt Pocock's grill-with-docs skill for patterns
**Phase 3:** Solution Matrix — prioritize by impact vs. fit

---

## Ideas Generated

### From Phase 1 — Reverse Brainstorming

**Archetype: The Passive Absorber**
Student reads everything, session-log fills up, but fails when faced with a real problem. Nothing triggered review of older content.

**#1 — Spaced Review Agent** (`spaced-review-agent.md`)
Reads session-log.md, knows what was studied and when, triggers review sessions for content studied N days ago. Orchestrates when to use generate-flashcards.md.

---

**Archetype: The Overconfident Intermediate**
Scores 7/10, skips review because "almost got it." Same gap persists across 3 sessions. System never escalated.

**#2 — Gap Escalation Skill** (`escalate-challenge.md`)
Triggered when score is 6-8 AND gaps exist. Generates harder questions specifically targeting weak spots. Forces the student past the comfortable plateau.

**#3 — Stagnation Detection Skill** (`detect-stagnation.md`)
Reads last N entries of knowledge-map.md. Flags when the same gap appears 2+ sessions in a row. Triggers a change of approach — e.g., switch from Quiz Master to Professor.

---

**Archetype: The Motivated Starter**
Studies every day for two weeks, then disappears. No backend, no notifications. System is silent until the student returns.

**#4 — Session Opener Skill** (`session-opener.md`)
Runs at the start of every session. Reads session-log.md + current date. Calibrates tone and suggests warm-up based on time away:
- 2 days away: "Welcome back! Here's where you left off..."
- 7 days away: "It's been a week. Quick retrieval warmup before we continue."
- 30 days away: "You've been away a while. Let's re-assess your level before jumping back in."
No backend required — the agent is the scheduler, activated when the student opens a session.

---

**Archetype: The Theory Expert**
Aces every quiz. Knowledge-map is green. Freezes in a real interview because they can explain concepts but can't apply them to unfamiliar problems under pressure.

**#5 — Troubleshooter Agent** (`troubleshooter-agent.md`)
Presents real-world scenarios the student has never seen explicitly. Doesn't ask "what is X" — asks "what would you DO if X happened." Evaluates the thinking process, not just the answer. Rewards structured breakdown: "I'd first check... then I'd look at... if that fails I'd..."
Key differentiator from Quiz Master: Quiz Master tests knowledge. Troubleshooter tests judgment.

**#6 — Scenario Builder Skill** (`build-scenario.md`)
Generates novel situations solvable using concepts the student already studied. Forces synthesis instead of recall. Ships alongside Troubleshooter Agent.

---

**Archetype: The Lost Student**
Two weeks in, study plan feels overwhelming. Can't tell if they're on track, if gaps are critical, or whether to push forward or go back. All the data exists in memory — but nobody is reading it for them.

**#7 — Coach Agent** (`coach-agent.md`)
The meta-agent. Reads everything: student-profile.md, knowledge-map.md, full session-log.md. Doesn't teach, doesn't quiz — interprets and directs. Answers:
- "Am I on track for my interview in 3 weeks?"
- "What should I focus on this week?"
- "Is my Kafka gap critical or minor?"
- "Should I go deeper here or move on?"
The only agent with a full-picture view of the student's arc. The Planner sets the plan once. The Coach reads reality and adjusts continuously.

---

### From Phase 2 — Cross-Pollination (Matt Pocock's grill-with-docs)

Patterns borrowed from a skill that does relentless design interrogation using sequential questioning and terminology stress-testing.

**#8 — Guided Socratic Mode** (variation on `socratic-agent.md`)
After 2 failed student attempts, reveals the reasoning scaffold without giving the full answer. Softer Socratic that doesn't leave beginners stranded.

**#9 — Concept Precision Skill** (`test-concept-precision.md`)
Asks the student to define a term in their own words, then challenges imprecise language. "You said Kafka is a 'messaging system' — what specifically distinguishes it from RabbitMQ?" Catches the "I know the word but not the concept" failure mode.

---

## Prioritization Matrix

| # | Idea | Type | Impact | Fit | Priority |
|---|------|------|--------|-----|----------|
| 7 | Coach Agent | Agent | 3/3 | 3/3 | Tier 1 |
| 5 | Troubleshooter Agent | Agent | 3/3 | 3/3 | Tier 1 |
| 4 | Session Opener Skill | Skill | 3/3 | 3/3 | Tier 1 |
| 6 | Scenario Builder Skill | Skill | 3/3 | 3/3 | Tier 1 |
| 9 | Concept Precision Skill | Skill | 2/3 | 3/3 | Tier 2 |
| 2 | Gap Escalation Skill | Skill | 2/3 | 3/3 | Tier 2 |
| 1 | Spaced Review Agent | Agent | 3/3 | 2/3 | Tier 2 — may be absorbed into Coach |
| 3 | Stagnation Detection Skill | Skill | 2/3 | 3/3 | Tier 3 — may be absorbed into Coach |
| 8 | Guided Socratic Mode | Skill | 2/3 | 3/3 | Tier 3 — polish, not core |

---

## Recommended Build Order

### Tier 1 — Phase 2 of bmad-study

1. `session-opener.md` — runs every session, immediate value, zero infrastructure
2. `coach-agent.md` — the strategic layer the system is missing
3. `troubleshooter-agent.md` + `build-scenario.md` — ship together, close the knowledge-to-application gap

### Tier 2 — After Tier 1 is solid

4. `concept-precision.md` — sharpens the Evaluator feedback loop
5. `escalate-challenge.md` — makes the Evaluator push harder at plateaus
6. Spaced Review Agent — revisit after Coach Agent exists; may become a Coach behavior

### Tier 3 — Consider later

7. Stagnation Detection — likely absorbed into Coach Agent logic
8. Guided Socratic Mode — nice polish, low priority

---

## Core Insight

The current bmad-study system is excellent at delivering learning. What it's missing is:

- The **strategic layer** (Coach Agent) — someone who reads the full picture and gives direction
- The **re-entry experience** (Session Opener) — intelligent warm-up after any absence
- The **knowledge-to-application bridge** (Troubleshooter + Scenario Builder) — judgment under pressure, not just recall

These four are the natural Phase 2 of the system.
