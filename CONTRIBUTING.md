# Contributing to BMAD Study

## Adding a new agent

Place the file at: `agents/{your-agent-id}.md`

Required YAML frontmatter (first lines of the file):

```yaml
---
id: your-agent-id   # kebab-case; compiled filename: compiled/bmad-study-{id}.md
version: 1.0.0
type: agent
---
```

Required sections (in this order):

1. **Title + persona block** — one paragraph, second person imperative
2. **`## On Activation`** — the 5-step memory read + schema check (copy from `agent-template.md`)
3. **`## Skills`** — one `### {skill-id}` block per skill the agent uses
4. **`## Session Workflow`** — agent behaviour during the session
5. **`## After Session`** — session-log append; knowledge-map update if evaluator/spaced-review

See `agent-template.md` for a fully annotated example.

## Adding a new skill

Place the file at: `skills/{your-skill-id}.md`

Required YAML frontmatter:

```yaml
---
id: your-skill-id   # kebab-case; must match filename: skills/{id}.md
version: 1.0.0
type: skill
---
```

Required sections:

1. **`## Purpose`** — one sentence
2. **`## Instructions`** — imperative voice, addressed to the LLM

**Stateless constraint:** Skills must NOT read or write any memory files (`student-profile.md`,
`session-log.md`, `knowledge-map.md`). All memory access belongs in the agent's
`On Activation` (reads) and `After Session` (writes).

See `skill-template.md` for a fully annotated example.

## Running lint locally

```bash
bash scripts/lint-agnostic.sh agents/ skills/
```

The script exits 0 on a clean pass and exits 1 (with an error line) if any agent or skill
file contains a model name, platform-specific syntax, or context-window-size reference.

To lint a single file:

```bash
bash scripts/lint-agnostic.sh agents/my-agent.md
```

## Building compiled output

```bash
bash scripts/build-skills.sh
```

This inlines each skill referenced in an agent's `## Skills` section into
`compiled/bmad-study-{agent-id}.md`. Inspect `compiled/` after running to verify output.

Do **not** edit files in `compiled/` directly — they are regenerated on every build.

## Opening a PR

All three CI checks must pass before a PR can be merged:

1. **Lint** — `bash scripts/lint-agnostic.sh agents/ skills/`
2. **Type check** — `npx tsc --noEmit`
3. **Tests** — `npx vitest run`

Run these locally before pushing to catch failures early.
