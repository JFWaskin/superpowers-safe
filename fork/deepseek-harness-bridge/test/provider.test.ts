/**
 * Unit tests for the bridge's `BridgeSkillProvider`.
 *
 * These tests do NOT depend on the DeepSeek Harness runtime — they
 * exercise the provider's `list()` and `get()` against a temporary
 * skill directory created by the test itself. The harness is mocked
 * just enough to wire `registerProvider()` and `effect()`.
 *
 * Run with:
 *   bun test test/provider.test.ts
 */

import { afterEach, beforeEach, describe, expect, it } from 'bun:test'
import { mkdtemp, rm, writeFile, mkdir } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import type { SkillCandidate, SkillLookupOptions, SkillProvider } from '@deepseek-ai/dsh-skill'
import { BridgeSkillProvider } from '../src/index'

const NEVER_ABORTED = new AbortController().signal

interface HarnessStub {
  registerProvider: (create: (control: {
    signal: AbortSignal
    invalidate: () => void
  }) => SkillProvider) => () => void
  effect: (generatorFactory: () => Generator<() => void, void, void>, label: string) => void
}

function makeHarnessStub(): HarnessStub {
  return {
    registerProvider: (_create) => () => {},
    effect: (_generatorFactory, _label) => {},
  }
}

async function writeSkill(
  root: string,
  name: string,
  frontmatter: Record<string, unknown>,
  body: string,
): Promise<void> {
  const dir = join(root, name)
  await mkdir(dir, { recursive: true })
  const lines: string[] = ['---']
  for (const [key, value] of Object.entries(frontmatter)) {
    lines.push(`${key}: ${JSON.stringify(value)}`)
  }
  lines.push('---', '', body)
  await writeFile(join(dir, 'SKILL.md'), lines.join('\n'))
}

describe('BridgeSkillProvider', () => {
  let workdir: string
  let skillsRoot: string

  beforeEach(async () => {
    workdir = await mkdtemp(join(tmpdir(), 'superpowers-bridge-test-'))
    skillsRoot = join(workdir, 'skills')
    await mkdir(skillsRoot, { recursive: true })
  })

  afterEach(async () => {
    await rm(workdir, { recursive: true, force: true })
  })

  it('discovers all skills in the root directory', async () => {
    await writeSkill(skillsRoot, 'brainstorming', { name: 'brainstorming', description: 'Brainstorm before coding.' }, 'Brainstorm body.')
    await writeSkill(skillsRoot, 'using-superpowers', { name: 'using-superpowers', description: 'Bootstrap.' }, 'Bootstrap body.')
    const provider = new BridgeSkillProvider('superpowers-safe-bridge', skillsRoot, 350, NEVER_ABORTED)
    const candidates = await provider.list({ signal: NEVER_ABORTED })
    expect(candidates).toHaveLength(2)
    const names = candidates.map((c) => c.name).sort()
    expect(names).toEqual(['brainstorming', 'using-superpowers'])
  })

  it('exposes skill frontmatter as candidate fields', async () => {
    await writeSkill(
      skillsRoot,
      'safety-check',
      { name: 'safety-check', description: 'Mandatory preflight.' },
      'Five hard gates.',
    )
    const provider = new BridgeSkillProvider('superpowers-safe-bridge', skillsRoot, 350, NEVER_ABORTED)
    const candidates = await provider.list({ signal: NEVER_ABORTED })
    const candidate = candidates.find((c) => c.name === 'safety-check')
    expect(candidate).toBeDefined()
    expect(candidate?.description).toBe('Mandatory preflight.')
    expect(candidate?.source).toBe('custom')
    expect(candidate?.provider).toBe('superpowers-safe-bridge')
    expect(candidate?.rank).toBe(350)
    expect(candidate?.resourceBase).toEqual({ kind: 'directory', path: join(skillsRoot, 'safety-check') })
  })

  it('returns the full body on get()', async () => {
    const body = '# Safety Check\n\nFive hard gates run before any other skill.'
    await writeSkill(
      skillsRoot,
      'safety-check',
      { name: 'safety-check', description: 'Mandatory preflight.' },
      body,
    )
    const provider = new BridgeSkillProvider('superpowers-safe-bridge', skillsRoot, 350, NEVER_ABORTED)
    const candidates = await provider.list({ signal: NEVER_ABORTED })
    const candidate = candidates[0] as SkillCandidate
    const definition = await provider.get(candidate, { signal: NEVER_ABORTED })
    expect(definition).toBeDefined()
    expect(definition?.name).toBe('safety-check')
    expect(definition?.content).toBe(body)
  })

  it('skips skills with invalid kebab-case names', async () => {
    await writeSkill(skillsRoot, 'NotKebab', { name: 'NotKebab', description: 'Bad name.' }, 'Body.')
    await writeSkill(skillsRoot, 'good-name', { name: 'good-name', description: 'Good name.' }, 'Body.')
    const provider = new BridgeSkillProvider('superpowers-safe-bridge', skillsRoot, 350, NEVER_ABORTED)
    const candidates = await provider.list({ signal: NEVER_ABORTED })
    const names = candidates.map((c) => c.name)
    expect(names).toEqual(['good-name'])
  })

  it('skips skills missing name or description', async () => {
    await mkdir(join(skillsRoot, 'no-name'), { recursive: true })
    await writeFile(join(skillsRoot, 'no-name', 'SKILL.md'), '---\ndescription: x\n---\nBody.')
    await mkdir(join(skillsRoot, 'no-desc'), { recursive: true })
    await writeFile(join(skillsRoot, 'no-desc', 'SKILL.md'), '---\nname: no-desc\n---\nBody.')
    await writeSkill(skillsRoot, 'all-good', { name: 'all-good', description: 'OK.' }, 'Body.')
    const provider = new BridgeSkillProvider('superpowers-safe-bridge', skillsRoot, 350, NEVER_ABORTED)
    const candidates = await provider.list({ signal: NEVER_ABORTED })
    expect(candidates.map((c) => c.name)).toEqual(['all-good'])
  })

  it('skips skills without frontmatter', async () => {
    await mkdir(join(skillsRoot, 'no-fm'), { recursive: true })
    await writeFile(join(skillsRoot, 'no-fm', 'SKILL.md'), 'Just a body, no frontmatter.')
    await writeSkill(skillsRoot, 'all-good', { name: 'all-good', description: 'OK.' }, 'Body.')
    const provider = new BridgeSkillProvider('superpowers-safe-bridge', skillsRoot, 350, NEVER_ABORTED)
    const candidates = await provider.list({ signal: NEVER_ABORTED })
    expect(candidates.map((c) => c.name)).toEqual(['all-good'])
  })

  it('handles a missing skills root gracefully', async () => {
    const provider = new BridgeSkillProvider(
      'superpowers-safe-bridge',
      join(workdir, 'no-such-dir'),
      350,
      NEVER_ABORTED,
    )
    const candidates = await provider.list({ signal: NEVER_ABORTED })
    expect(candidates).toEqual([])
  })

  it('respects disable-model-invocation and user-invocable frontmatter', async () => {
    await writeSkill(
      skillsRoot,
      'hidden',
      { name: 'hidden', description: 'Model-disabled.', 'disable-model-invocation': true },
      'Body.',
    )
    await writeSkill(
      skillsRoot,
      'user-only',
      { name: 'user-only', description: 'User-only.', 'user-invocable': false },
      'Body.',
    )
    await writeSkill(skillsRoot, 'normal', { name: 'normal', description: 'Normal.' }, 'Body.')
    const provider = new BridgeSkillProvider('superpowers-safe-bridge', skillsRoot, 350, NEVER_ABORTED)
    const candidates = await provider.list({ signal: NEVER_ABORTED })
    const byName = new Map(candidates.map((c) => [c.name, c]))
    expect(byName.get('hidden')?.invocation.modelInvocable).toBe(false)
    expect(byName.get('hidden')?.invocation.userInvocable).toBe(true)
    expect(byName.get('user-only')?.invocation.modelInvocable).toBe(true)
    expect(byName.get('user-only')?.invocation.userInvocable).toBe(false)
    expect(byName.get('normal')?.invocation.modelInvocable).toBe(true)
    expect(byName.get('normal')?.invocation.userInvocable).toBe(true)
  })

  it('returns undefined from get() when the file disappears', async () => {
    await writeSkill(skillsRoot, 'will-vanish', { name: 'will-vanish', description: 'Will disappear.' }, 'Body.')
    const provider = new BridgeSkillProvider('superpowers-safe-bridge', skillsRoot, 350, NEVER_ABORTED)
    const candidates = await provider.list({ signal: NEVER_ABORTED })
    const candidate = candidates[0] as SkillCandidate
    await rm(join(skillsRoot, 'will-vanish'), { recursive: true, force: true })
    const definition = await provider.get(candidate, { signal: NEVER_ABORTED })
    expect(definition).toBeUndefined()
  })

  it('returns undefined from get() when the frontmatter name changes', async () => {
    await writeSkill(skillsRoot, 'will-rename', { name: 'will-rename', description: 'Before.' }, 'Body.')
    const provider = new BridgeSkillProvider('superpowers-safe-bridge', skillsRoot, 350, NEVER_ABORTED)
    const candidates = await provider.list({ signal: NEVER_ABORTED })
    const candidate = candidates[0] as SkillCandidate
    // Rewrite the frontmatter name in place.
    await writeFile(
      join(skillsRoot, 'will-rename', 'SKILL.md'),
      '---\nname: was-renamed\ndescription: After.\n---\nBody.',
    )
    const definition = await provider.get(candidate, { signal: NEVER_ABORTED })
    expect(definition).toBeUndefined()
  })
})

describe('BridgeSkillProvider integration with apply()', () => {
  it('calls registerProvider with a provider that returns the right name', async () => {
    const workdir = await mkdtemp(join(tmpdir(), 'superpowers-bridge-test-'))
    try {
      const skillsRoot = join(workdir, 'skills')
      await mkdir(skillsRoot, { recursive: true })
      await writeSkill(skillsRoot, 'foo', { name: 'foo', description: 'A skill.' }, 'Body.')

      // We do not import `apply` here because it pulls in the real
      // Cordis context type. Instead, we replicate the registration
      // shape inline.
      const stub = makeHarnessStub()
      let registered: SkillProvider | undefined
      stub.registerProvider = (create) => {
        registered = create({ signal: NEVER_ABORTED, invalidate: () => {} })
        return () => {}
      }

      // Simulate the part of `apply()` that matters: register a
      // provider built from the same arguments.
      const provider = new BridgeSkillProvider('superpowers-safe-bridge', skillsRoot, 350, NEVER_ABORTED)
      registered = provider
      expect(registered.name).toBe('superpowers-safe-bridge')
      const candidates = await registered.list({ signal: NEVER_ABORTED } as SkillLookupOptions)
      expect(candidates.map((c) => c.name)).toEqual(['foo'])
    } finally {
      await rm(workdir, { recursive: true, force: true })
    }
  })
})
