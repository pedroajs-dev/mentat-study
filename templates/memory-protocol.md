<!-- memory-protocol.md — CANONICAL memory protocol block (FR-1.4).
     This is the single source of truth for the On Activation + After Session
     steps. Paste the two sections below VERBATIM into every agent file in
     agents/. Do not rephrase, reorder, or omit the version gate — the wording
     here is the contract. The halt message in step 4 is the exact canonical
     mismatch message frozen in the Story 1.2 memory schema contract.
     This file is NOT an agent (no `type: agent`) and is NOT compiled or seeded
     into a user's memory/ directory — it is an authoring-time reference. -->

# Memory Protocol

## On Activation

1. Read {project-root}/memory/student-profile.md
   → Know who you are talking to (name, level, goal, available time, deadline)
2. Read {project-root}/memory/knowledge-map.md
   → Know what they know and what the gaps are
3. Read {project-root}/memory/session-log.md (last 3 session entries only)
   → Know what was recently covered
4. Schema version check: if memory-protocol-version in any file ≠ 1, halt immediately and say:
   "Your memory files are from an older version. Please re-run onboarding with /bmad-study-planner."
5. Greet the student by name. Confirm current topic and session mode.

## After Session

1. Append to {project-root}/memory/session-log.md using the canonical append format
   (see templates/session-log.md for the exact block structure).
2. [Evaluator + Spaced Review only] Update {project-root}/memory/knowledge-map.md
