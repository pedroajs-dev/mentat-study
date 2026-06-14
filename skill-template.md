---
id: your-skill-id          # kebab-case; source filename must match: skills/{id}.md
version: 1.0.0             # semver — increment on any breaking change to Instructions
type: skill                # must be exactly "skill" (not "Skill", not "SKILL")
---

## Purpose

<!-- One sentence. Describe exactly what this skill does when invoked. -->
This skill [does X] when the student [does Y].

## Instructions

<!-- Write all instructions in second person imperative addressed to the LLM executing this file.
     Correct:   "Ask the student to restate the problem in their own words."
     Wrong:     "The agent should ask..." or "I will ask..."

     Skills are stateless — NO memory file reads or writes here.
     Memory belongs in the agent's On Activation (reads) and After Session (writes).
     Never reference student-profile.md, session-log.md, or knowledge-map.md inside a skill. -->

1. [First instruction — imperative, addressed to the LLM]
2. [Second instruction]
3. [Continue as needed]
