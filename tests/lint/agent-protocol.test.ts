import { describe, it, expect, afterEach } from 'vitest'
import { spawnSync } from 'child_process'
import { mkdtempSync, writeFileSync, rmSync } from 'fs'
import { tmpdir } from 'os'
import { join } from 'path'

// Validates the agent version-gate check added to scripts/lint-agnostic.sh (Story 1.4 AC #3):
// any file with `type: agent` in frontmatter MUST contain the memory-protocol-version check;
// if it does not, lint fails with a message identifying the missing check.

const runLint = (filePath: string) =>
  spawnSync('bash', ['scripts/lint-agnostic.sh', filePath], { encoding: 'utf-8' })

const tmpDirs: string[] = []

const writeFixture = (filename: string, content: string): string => {
  const dir = mkdtempSync(join(tmpdir(), 'lint-agent-'))
  tmpDirs.push(dir)
  const filePath = join(dir, filename)
  writeFileSync(filePath, content)
  return filePath
}

afterEach(() => {
  while (tmpDirs.length) {
    const dir = tmpDirs.pop()!
    rmSync(dir, { recursive: true, force: true })
  }
})

describe('lint-agnostic.sh agent version-gate check', () => {
  it('fails when a type: agent file is missing the memory-protocol-version check', () => {
    const fixture = writeFixture(
      'broken-agent.md',
      `---
id: broken
version: 1.0.0
type: agent
---

# Broken Agent

## On Activation

1. Read {project-root}/memory/student-profile.md
5. Greet the student by name.
`
    )
    const result = runLint(fixture)
    expect(result.status, 'lint should exit non-zero for an agent missing the version check').not.toBe(0)
    expect(result.stdout + result.stderr).toMatch(/memory-protocol-version/)
  })

  it('passes when a type: agent file contains the memory-protocol-version check', () => {
    const fixture = writeFixture(
      'good-agent.md',
      `---
id: good
version: 1.0.0
type: agent
---

# Good Agent

## On Activation

4. Schema version check: if memory-protocol-version in any file ≠ 1, halt immediately.
5. Greet the student by name.
`
    )
    const result = runLint(fixture)
    expect(result.status, result.stdout + result.stderr).toBe(0)
  })

  it('does not apply the agent check to type: skill files', () => {
    const fixture = writeFixture(
      'a-skill.md',
      `---
id: a-skill
version: 1.0.0
type: skill
---

# A Skill

## Instructions

Ask the student to explain the concept in their own words.
`
    )
    const result = runLint(fixture)
    expect(result.status, result.stdout + result.stderr).toBe(0)
  })

  it('detects a quoted type: "agent" missing the check', () => {
    const fixture = writeFixture(
      'quoted-agent.md',
      `---
id: q
type: "agent"
---

# Quoted Agent

No gate here.
`
    )
    const result = runLint(fixture)
    expect(result.status, 'quoted type: "agent" should still be gated').not.toBe(0)
    expect(result.stdout + result.stderr).toMatch(/memory-protocol-version/)
  })

  it('detects an agent whose type line has a trailing inline comment', () => {
    const fixture = writeFixture(
      'commented-agent.md',
      `---
id: c
type: agent # primary
---

# Commented Agent

No gate here.
`
    )
    const result = runLint(fixture)
    expect(result.status, 'type: agent # comment should still be gated').not.toBe(0)
  })

  it('does not treat type: agentic as an agent', () => {
    const fixture = writeFixture(
      'agentic.md',
      `---
id: a
type: agentic
---

# Not An Agent

No gate, but not an agent either.
`
    )
    const result = runLint(fixture)
    expect(result.status, result.stdout + result.stderr).toBe(0)
  })

  it('does not abort under pipefail on a large agent file body', () => {
    const fixture = writeFixture(
      'big-agent.md',
      `---
id: big
type: agent
---

# Big Agent

${'x'.repeat(200_000)}
`
    )
    const result = runLint(fixture)
    // Missing gate → exit 1, but the run must complete (not abort with a shell error)
    expect(result.status, 'large file must be reported, not abort the run').toBe(1)
    expect(result.stdout + result.stderr).toMatch(/memory-protocol-version/)
  })
})
