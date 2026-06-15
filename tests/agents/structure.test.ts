import { describe, it, expect, beforeAll } from 'vitest'
import { execSync } from 'child_process'
import { readFileSync, readdirSync, existsSync } from 'fs'
import { join } from 'path'

const COMPILED_DIR = 'compiled'
const AGENTS_DIR = 'agents'
const SKILLS_DIR = 'skills'

beforeAll(() => {
  execSync('bash scripts/build-skills.sh', { stdio: 'inherit' })
})

describe('compiled agent files', () => {
  const compiledFiles = (): string[] => {
    if (!existsSync(COMPILED_DIR)) return []
    return readdirSync(COMPILED_DIR).filter((f: string) => f.endsWith('.md'))
  }

  it('compiled/ contains at least one .md file', () => {
    expect(compiledFiles().length).toBeGreaterThan(0)
  })

  it('compiled/ has exactly one .md file per agent file in agents/', () => {
    const agentCount = readdirSync(AGENTS_DIR).filter((f: string) => f.endsWith('.md')).length
    expect(compiledFiles().length).toBe(agentCount)
  })

  it('each compiled file has YAML frontmatter with id, version, and type fields', () => {
    for (const filename of compiledFiles()) {
      const content = readFileSync(join(COMPILED_DIR, filename), 'utf-8')
      expect(content, `${filename}: missing YAML frontmatter opening`).toMatch(/^---\n/)
      expect(content, `${filename}: missing 'id' field in frontmatter`).toMatch(/^id:/m)
      expect(content, `${filename}: missing 'version' field in frontmatter`).toMatch(/^version:/m)
      expect(content, `${filename}: missing 'type' field in frontmatter`).toMatch(/^type:/m)
    }
  })

  it('each compiled file has a ## On Activation section', () => {
    for (const filename of compiledFiles()) {
      const content = readFileSync(join(COMPILED_DIR, filename), 'utf-8')
      expect(content, filename).toContain('## On Activation')
    }
  })

  it('each compiled file has a ## Session Workflow section', () => {
    for (const filename of compiledFiles()) {
      const content = readFileSync(join(COMPILED_DIR, filename), 'utf-8')
      expect(content, filename).toContain('## Session Workflow')
    }
  })

  it('each compiled file has a ## After Session section', () => {
    for (const filename of compiledFiles()) {
      const content = readFileSync(join(COMPILED_DIR, filename), 'utf-8')
      expect(content, filename).toContain('## After Session')
    }
  })

  it('each compiled file contains the string memory-protocol-version', () => {
    for (const filename of compiledFiles()) {
      const content = readFileSync(join(COMPILED_DIR, filename), 'utf-8')
      expect(content, filename).toContain('memory-protocol-version')
    }
  })

  it('inlines each referenced skill body into the compiled agent file', () => {
    for (const agentFile of readdirSync(AGENTS_DIR).filter((f: string) => f.endsWith('.md'))) {
      const agentText = readFileSync(join(AGENTS_DIR, agentFile), 'utf-8')
      const idMatch = agentText.match(/^id:\s*(.+)$/m)
      expect(idMatch, `${agentFile}: missing id`).not.toBeNull()
      const compiledPath = join(COMPILED_DIR, `bmad-study-${idMatch![1].trim()}.md`)
      const compiledText = readFileSync(compiledPath, 'utf-8')

      const skillNames = [...agentText.matchAll(/^###\s+(.+)$/gm)].map((m: RegExpMatchArray) => m[1].trim())
      for (const name of skillNames) {
        const skillPath = join(SKILLS_DIR, `${name}.md`)
        if (!existsSync(skillPath)) continue
        // First non-empty, non-heading line of the skill body (frontmatter stripped)
        const body = readFileSync(skillPath, 'utf-8')
          .replace(/^---[\s\S]*?\n---\n/, '')
          .split('\n')
          .map((l: string) => l.trim())
          .find((l: string) => l.length > 0 && !l.startsWith('#'))
        expect(body, `${name}: skill body is empty`).toBeTruthy()
        expect(compiledText, `${compiledPath}: body of skill '${name}' was not inlined`).toContain(body!)
      }
    }
  })
})
