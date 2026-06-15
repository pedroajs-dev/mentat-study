memory-protocol-version: 1

# Student Profile

name: {value}
<!-- Student's first name or preferred name. Free text, e.g. Pedro -->

preferred_language: {value}
<!-- Language for agent responses. e.g. English, Português -->

goal: {value}
<!-- What the student wants to achieve. One sentence, e.g. Pass Java backend interview at FAANG company -->

topic: {value}
<!-- Current study topic. Be specific, e.g. Java Backend Interview Prep (Kafka, Spring Boot, System Design) -->

current_level: {value}
<!-- Self-assessed knowledge level. One of: beginner, intermediate, advanced -->

time_per_day: {value}
<!-- Available study time per day. e.g. 1 hour, 30 minutes -->

deadline: {value}
<!-- Target completion date. Format: YYYY-MM-DD or None -->

preferred_style: {value}
<!-- Learning style preference. Free text, e.g. Analogies and real examples, then practice questions -->

study_plan: |
  {value}
<!-- Week-by-week plan written by Planner Agent. Multiline, starts with Week 1: entries -->
<!-- Only the Planner Agent writes this field. No other agent may modify it. (ARCH-13) -->
