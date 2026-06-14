# PRD Quality Review — BMAD-Study

## Overall verdict

The PRD has a genuine thesis, a clean scope, and product-specific NFRs — it reads like a real product document, not a template filler. The two issues that matter before handoff: the Spaced Review Agent is missing from the FR section entirely (appears only in the Phase 2 build order), and most FRs describe behavior but not testable outcomes, which will make story creation harder than it needs to be. Everything else is medium or lower.

---

## Decision-readiness — adequate

Core decisions are stated explicitly and logged: English-only files, runs like BMAD, no infrastructure, OSS MIT. Trade-offs are honest — "agent is the scheduler" stands in for the acknowledged absence of notifications. The decision log is properly referenced.

One genuine open point: FR-6 defines the Coach Agent as "the only agent with a full-picture view" and DL-009 says "Coach Agent is aware of [Spaced Review Agent] and may route students to it" — but the mechanism of that awareness is not specified anywhere in the PRD. This is an implicit dependency that could surface as ambiguity at story time.

### Findings
- **medium** Missing routing mechanism between Coach and Spaced Review Agent (§6 FR-6.1, §12 Phase 2) — the PRD says Coach "may route students to" Spaced Review Agent but never specifies how (a trigger? a menu option? a recommendation in its output format?). *Fix:* add one sentence in FR-6.1 or a new FR-6.3 describing the interaction contract.

---

## Substance over theater — strong

No NFR theater: every NFR has a product-specific constraint (Node 18+, 60-second install, named model list, "no code changes for content contributions"). Personas are two, lean, and both drive real requirements — the OSS Contributor directly justifies NFR-7. The differentiator ("not a tutoring app, a structured method") is earned and not interchangeable with other products in the space. No innovation theater detected.

---

## Strategic coherence — strong

The thesis is clear: "the structure is the product — markdown files that encode pedagogy, not just prompts." Every feature group follows from it. The Phase build order follows the thesis correctly (memory is the foundation; agents can't exist without it; CLI is distribution, not product). The absence of success metrics is logged as a deliberate choice (DL-005), not an oversight. No counter-metrics needed given SM absence.

---

## Done-ness clarity — thin

This is the weakest dimension. Most FRs describe what an agent or skill *does* but not what *done* looks like for the file itself.

Phase exit criteria (§12) are good and testable. But at the individual FR level, a story author picking up FR-2.2 (Professor Agent) has no criteria beyond "adapts language complexity to the student profile" — which is a behavior description, not a testable outcome.

For agent/skill markdown files, "done" plausibly means "the file, when loaded into any compliant LLM, produces behavior X in test scenario Y" — but the PRD never says this. That's not a problem for Pedro building solo, but it will matter for OSS contributors trying to know whether their PR is complete.

The Evaluator Agent (FR-2.3) is the exception: the output format is fully specified and testable. That's the right model.

### Findings
- **high** Most agent FRs lack testable outcomes (§9 FR-2.1, FR-2.2, FR-2.4, FR-2.5, FR-6.1, FR-6.2) — behavior is described but no acceptance signal is given. *Fix:* either add one "a correct implementation produces output Z when given input Y" line per agent FR, or add a short §9.x "Acceptance signals" note explaining that agent files are verified by running a reference test prompt and checking output against the FR's behavior bullets. The latter is lighter and still gives contributors something to test against.
- **low** FR-3.x skills (FR-3.1 through FR-3.6) have zero testable content — they're one-line descriptions. For Phase 1 solo use this is fine. For OSS contribution, contributors won't know what a correct `explain-concept.md` looks like. *Fix:* acceptable to defer; flag with `[NOTE FOR PM: add contributor acceptance signals before first external PR]`.

---

## Scope honesty — adequate

Out of Scope (§6) is explicit and well-placed. The three-phase structure is honest about what's in each phase and what's not started yet. DL-010 properly records the English-only decision.

Two mechanical gaps:

### Findings
- **high** Spaced Review Agent is absent from the FR section (§9) — it appears only in the Phase 2 build order (§12) with a description there, but has no FR-6.x entry. This means it has no stable ID, no behavior spec, and no place for an acceptance signal. *Fix:* add FR-6.3 Spaced Review Agent with the same depth as FR-6.1 and FR-6.2.
- **medium** Section 13 table is malformed — the "all resolved" text is inside the table body where a row should be, breaking the table structure. *Fix:* replace the table entirely with a one-line note or a clean resolved-items list.
- **low** Phase 1 build order items 12–14 (`progress-report.md`, `examples/system-design/`, `examples/kubernetes/`) are separated from items 1–11 by a blank line with no explanation of whether they are sequential, parallel, or lower-priority within Phase 1. *Fix:* add a one-sentence note ("The following ship within Phase 1 but are not blocking the exit criterion — they can be built in parallel after item 11.").

---

## Downstream usability — adequate

FR IDs are contiguous and stable (FR-1.1 through FR-8.6). File paths are used consistently as identifiers throughout — this works as a lightweight glossary substitute. No UJs present, which is correct for this product type (single-operator dev tool).

No formal glossary. Terms used consistently across the document: "agent," "skill," "memory file," "session," "knowledge map." For a solo build this is fine. For OSS contributors, the distinction between "agent" and "skill" is load-bearing (agents have roles and own memory writes; skills are composable building blocks) and currently only implied by the repo structure.

### Findings
- **medium** No glossary — the agent/skill distinction is the single most important concept for contributors and is never formally defined. *Fix:* add a short §2.x or §0 Glossary (5–8 terms: agent, skill, memory file, session, knowledge map, onboarding, context window) before the PRD is used to onboard first contributors.

---

## Shape fit — strong

This is a developer tool / OSS CLI project with a single-operator usage pattern. No UJs needed and correctly omitted. Two lean personas. NFR rigor is appropriate for an OSS launch. The PRD is not over-formalized. The full-vision scope (three phases) is appropriate given the stated audience (Pedro + OSS contributors who need to understand the product arc).

---

## Mechanical notes

- **Section 13 table:** malformed (text inside table row where data belongs) — fix noted above under Scope honesty.
- **ID continuity:** FR-1.x through FR-8.x are clean. No gaps or duplicates detected.
- **Spaced Review Agent ID gap:** no FR ID assigned — flagged as high finding above.
- **[ASSUMPTION] index:** none present. Given Fast path mode, this should either have tags or a note confirming all inferences were confirmed with the user. In this case the briefing + brainstorm session + explicit Q&A confirm the key decisions, so this is acceptable — but worth a one-line note in the decision log.
- **Phase 2 build order FR-6.3 description:** the Spaced Review Agent description in §12 Phase 2 build order is more detailed than anything in §9 FR-6. Until FR-6.3 is added, the build order is the only spec for this agent.
