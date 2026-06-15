---
id: build-study-plan
version: 1.0.0
type: skill
---

## Purpose

Collect onboarding answers from the student and populate all memory files with their profile, study plan, and initial knowledge map.

## Instructions

1. Ask the student the 7 onboarding questions in order, one at a time. Wait for each answer before asking the next:
   - What is your name?
   - What topic are you studying?
   - What is your goal?
   - What is your current level (beginner / intermediate / advanced)?
   - How much time can you dedicate per day?
   - Do you have a deadline?
   - What is your preferred learning style?
2. After all 7 answers are collected, confirm the summary with the student before writing anything.
3. Write all fields to student-profile.md using the exact field names from the memory schema contract.
4. Create a week-by-week study plan and write it to the `study_plan` field.
5. Seed knowledge-map.md by listing all concepts from the study plan under `## Never Studied ⬜`.
6. Write a Session 0 entry to session-log.md to record the onboarding session.
