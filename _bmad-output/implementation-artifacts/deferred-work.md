# Deferred Work

## Deferred from: code review of 1-1-repo-foundation (2026-06-14)

- `--passWithNoTests` flag in CI and `package.json` — remove when first real test file lands; todo

- `tsconfig.json` `include` only covers root `*.ts` and `src/**/*` — no TS outside root yet; revisit when Story 1.3 (build pipeline) adds TypeScript utilities in subdirectories
- No `npm run lint` convenience script in `package.json` — minor ergonomics gap; CONTRIBUTING.md documents the full command; add when developer workflow consistency becomes a priority

## Deferred from: code review of 1-2-memory-schema-contract-and-templates (2026-06-14)

- `session-log.md` canonical append block is inside an HTML comment — AC #2 ambiguity; dev notes say this is intentional as a copy-paste reference; revisit in Story 1.4 when memory protocol is finalized and agent read instructions clarify whether they strip comment delimiters
- `study_plan: |` pipe syntax in a plain-text (non-YAML) file — design question for Story 1.6 when Planner Agent writes this field; revisit when Planner Agent implementation begins
- Session [N] numbering is manual with no collision detection — relevant for multi-agent concurrent appends; address in agent write protocol (likely Story 2.x)
- No protocol for moving concepts between knowledge-map sections — agent behavior spec; address when Evaluator Agent (Story 2.2) and Spaced Review Agent (Story 4.4) are implemented

## Deferred from: code review of 1-3-build-pipeline (2026-06-15)

- `@types/node@^25.9.3` — pin to `^18` to match minimum Node version; non-breaking with `skipLibCheck: true`; revisit when Node floor changes
- `moduleResolution: "node"` is legacy CommonJS resolver — prefer `"node16"` or `"bundler"` for modern TypeScript; currently working with `skipLibCheck`; no current type errors
- `types: ["vitest/globals"]` in tsconfig is redundant with explicit imports in test file — harmless; clean up when tsconfig is next touched
- `beforeAll` runs `build-skills.sh` making structure tests non-hermetic — intentional design trade-off (ensures compiled/ is always fresh); document trade-off in CONTRIBUTING.md or README
- `skill_placeholder` silently discards source agent content under `### skill-name` with no warning — by design per Pattern 1; add a `stderr` WARNING when lines are dropped to improve contributor DX; address in Story 1.6 when real agent content is authored

## Deferred from: code review of 1-4-memory-protocol-block (2026-06-15)

- `lint-agnostic.sh` agent version-gate is a bare substring check (`grep -q 'memory-protocol-version'`), not a semantic one — a file mentioning the token in prose/a comment without an actual gate would pass lint. Consistent with the existing enforcement heuristic (`tests/agents/structure.test.ts` uses the same substring contract); tighten to a stricter pattern (e.g. require the `≠ 1` / halt phrasing) if a real false-pass ever occurs.

## Deferred from: code review of 1-5-onboarding-flow-template (2026-06-15)

- `templates/onboarding.md` build-study-plan vs `student-profile.md` write sequencing is ambiguous (lines 73-87) — the Memory Initialization preamble implies the study plan exists when the profile is written, while Field Mapping implies the profile is written first and `study_plan` is filled afterward by `build-study-plan`. Deferred: resolve in Story 1.6 when the Planner's Session Workflow is wired (per user). Pin down the canonical sequence and whether the Session 0 log may unconditionally claim "Generated week-by-week study plan."
- `templates/onboarding.md` does not specify runtime input validation for the 7 answers — out-of-enum `current_level`, past or malformed `deadline` (`YYYY-MM-DD`), and blank/whitespace answers have no re-ask or reject path. Not required by Story 1.5's ACs; runtime validation behavior belongs to the Planner Agent (Story 1.6). Revisit when the Planner's Session Workflow is implemented.
- `templates/onboarding.md` Session 0 entry uses `## Session 0` while `templates/session-log.md` defines the canonical header as `## Session [N]`. Whether the onboarding bootstrap consumes index 0 (so the first study session is "Session 1") is unstated. Related to the existing Story 1.2 deferred item on manual Session [N] numbering / collision detection; resolve together in the agent write protocol.
