/**
 * superpowers-safe DeepSeek Harness bridge.
 *
 * Registers a `ctx.skills` provider that reuses the existing
 * `superpowers/skills/<name>/SKILL.md` files without rewriting them.
 * Discovers one level deep (matching the DeepSeek Harness
 * `@deepseek-ai/dsh-skill-filesystem` shape), parses YAML frontmatter,
 * and loads bodies on demand.
 *
 * This is the "cleaner long-term path" from the upstream analysis
 * (`docs/upstream/deepseek-harness-analysis.md` §7). It does NOT
 * depend on `@deepseek-ai/dsh-skill-filesystem` — the bridge is its
 * own provider with its own name so the host's discovery and watcher
 * stack do not see the superpowers skills as part of the user /
 * project roots.
 *
 * @module @jfwaskin/superpowers-safe-deepseek-bridge
 */

import { readdir, readFile } from 'node:fs/promises'
import { dirname, isAbsolute, join, resolve } from 'node:path'
import type { Context } from '@deepseek-ai/cordis'
import { parse as parseYaml } from 'yaml'
import {
  isSkillName,
  type SkillCandidate,
  type SkillDefinition,
  type SkillInvocationPolicy,
  type SkillLookupOptions,
  type SkillProvider,
  type SkillProviderControl,
} from '@deepseek-ai/dsh-skill'

// --- public Cordis metadata ----------------------------------------

export const name = 'superpowers-safe-bridge'

/** Cordis-injected services this plugin needs. */
export const inject = ['skills'] as const

/** Provider name registered on `ctx.skills`. */
export const PROVIDER_NAME = 'superpowers-safe-bridge'

/** Discovery rank. Below `customSkillDirs` (300) so host custom roots still win. */
export const DEFAULT_RANK = 350

// --- configuration --------------------------------------------------

/** Bridge configuration. */
export interface Config {
  /**
   * Absolute or cwd-relative path to the directory that contains the
   * superpowers-safe `skills/` directory. Defaults to the parent of
   * this file's compiled location, which works for the standard
   * `fork/deepseek-harness-bridge/` layout.
   */
  repoRoot?: string
  /**
   * Subdirectory of `repoRoot` that contains the skills.
   * Defaults to `skills/`.
   */
  skillsSubdir?: string
  /**
   * Discovery rank. Lower ranks lose to higher ones within a single
   * scope layer. Defaults to {@link DEFAULT_RANK}.
   */
  rank?: number
  /**
   * Provider name registered on `ctx.skills`. Defaults to
   * {@link PROVIDER_NAME}.
   */
  providerName?: string
}

// --- internal types -------------------------------------------------

/** Opaque locator returned on the candidate and passed back to `get()`. */
interface BridgeLocator {
  /** Absolute path to the `SKILL.md` file. */
  readonly path: string
  /** Absolute path to the directory that contains `SKILL.md`. */
  readonly directory: string
}

interface ParsedFrontmatter {
  readonly name: string
  readonly description: string
  readonly whenToUse?: string
  readonly invocation: SkillInvocationPolicy
}

interface FrontmatterParseResult {
  readonly data: Readonly<Record<string, unknown>>
  readonly body: string
}

// --- Cordis apply() -------------------------------------------------

/**
 * Register the bridge provider on the host's `ctx.skills` registry.
 *
 * The provider is registered through `ctx.skills.registerProvider()`,
 * which gives back an `invalidate()` function via the
 * {@link SkillProviderControl} argument. The bridge does not
 * implement file-watching; the host's invalidation event is a no-op
 * here because skill bodies are re-read on every `get()` call (the
 * same posture the upstream `@deepseek-ai/dsh-skill-filesystem`
 * provider takes for non-watched roots).
 *
 * @param ctx - the Cordis context to register against.
 * @param config - optional bridge configuration; see {@link Config}.
 */
export function apply(ctx: Context, config: Config = {}): void {
  const repoRoot = resolveRepoRoot(config.repoRoot)
  const skillsRoot = join(repoRoot, config.skillsSubdir ?? 'skills')
  const rank = config.rank ?? DEFAULT_RANK
  const providerName = config.providerName ?? PROVIDER_NAME

  const unregister = ctx.skills.registerProvider((control: SkillProviderControl): SkillProvider => {
    return new BridgeSkillProvider(providerName, skillsRoot, rank, control.signal)
  })
  ctx.effect(function* (): Generator<() => void, void, void> {
    yield unregister
  }, 'superpowers-safe-bridge dispose')
}

// --- the SkillProvider implementation -------------------------------

/**
 * Provider that exposes the superpowers-safe `skills/` directory to
 * the host's `ctx.skills` registry. Discovery is one-level deep
 * (matches the harness's standard provider shape: each skill is a
 * directory containing a `SKILL.md`). Bodies are re-read on every
 * `get()` call so an edit shows up in the next call without
 * invalidation plumbing.
 */
export class BridgeSkillProvider implements SkillProvider {
  readonly name: string
  private readonly skillsRoot: string
  private readonly rank: number
  private readonly lifecycle: AbortSignal

  constructor(providerName: string, skillsRoot: string, rank: number, lifecycle: AbortSignal) {
    this.name = providerName
    this.skillsRoot = skillsRoot
    this.rank = rank
    this.lifecycle = lifecycle
  }

  /**
   * Discover candidates for the current lookup. `cwd` is unused here
   * because the superpowers-safe layout is a single root, not a
   * workspace-rooted discovery surface.
   *
   * @param _options - lookup options; `cwd` is intentionally ignored.
   * @returns a complete-array shorthand of provider candidates.
   */
  async list(_options: SkillLookupOptions): Promise<readonly SkillCandidate[]> {
    const entries = await listSkillEntries(this.skillsRoot, this.lifecycle)
    const candidates: SkillCandidate[] = []
    for (const entry of entries) {
      const skillPath = join(entry.path, 'SKILL.md')
      const frontmatter = await parseSkillFrontmatter(skillPath, this.lifecycle)
      if (frontmatter === undefined) continue
      candidates.push({
        name: frontmatter.name,
        description: frontmatter.description,
        ...frontmatter.whenToUse !== undefined ? { whenToUse: frontmatter.whenToUse } : {},
        invocation: frontmatter.invocation,
        provider: this.name,
        source: 'custom',
        rank: this.rank,
        locator: { path: skillPath, directory: entry.path } satisfies BridgeLocator,
        resourceBase: { kind: 'directory', path: entry.path },
        path: skillPath,
      })
    }
    return candidates
  }

  /**
   * Load a complete skill definition. Re-reads the file on every call
   * (no body version protocol) so an edit shows up immediately.
   *
   * @param candidate - the winning candidate returned by this provider's `list()`.
   * @param options - lookup options whose signal cancels the read.
   * @returns the full skill definition, or `undefined` if the file
   *   disappeared or its `name` frontmatter no longer matches the
   *   candidate.
   */
  async get(candidate: SkillCandidate, options: SkillLookupOptions): Promise<SkillDefinition | undefined> {
    const locator = candidate.locator as BridgeLocator
    const filePath = locator.path
    const directory = locator.directory
    const signal = options.signal ?? this.lifecycle
    const text = await readFileSafe(filePath, signal)
    if (text === undefined) return undefined
    const parsed = parseFrontmatter(text)
    if (parsed === undefined) return undefined
    const frontmatter = readParsedFrontmatter(parsed.data)
    if (frontmatter === undefined) return undefined
    if (frontmatter.name !== candidate.name) return undefined
    return {
      name: frontmatter.name,
      description: frontmatter.description,
      ...frontmatter.whenToUse !== undefined ? { whenToUse: frontmatter.whenToUse } : {},
      invocation: frontmatter.invocation,
      source: 'custom',
      provider: this.name,
      resourceBase: { kind: 'directory', path: directory },
      path: filePath,
      content: parsed.body.trim(),
    }
  }
}

// --- helpers --------------------------------------------------------

/** Resolve the repo root used to anchor the skills directory. */
function resolveRepoRoot(override: string | undefined): string {
  if (override !== undefined && override.length > 0) {
    return isAbsolute(override) ? override : resolve(process.cwd(), override)
  }
  // Default to the parent of this compiled file's location. The compiled
  // file lives at <repo>/fork/deepseek-harness-bridge/lib/index.js, so
  // going up three levels lands at <repo>.
  const here = dirname(new URL(import.meta.url).pathname)
  return resolve(here, '..', '..', '..')
}

/** Read the `skills/` directory and return one entry per child. */
async function listSkillEntries(skillsRoot: string, signal: AbortSignal): Promise<readonly { path: string }[]> {
  signal.throwIfAborted()
  let names: string[]
  try {
    const entries = await readdir(skillsRoot, { withFileTypes: true, encoding: 'utf8' })
    names = entries
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .sort()
  } catch (error) {
    if (isAbsentPathError(error)) return []
    throw error
  }
  return names.map((name) => ({ path: join(skillsRoot, name) }))
}

/**
 * Parse the YAML frontmatter of a `SKILL.md` file. Returns the
 * parsed frontmatter (with `name`, `description`, and invocation
 * policy) or `undefined` if the file is unreadable, has no
 * frontmatter, or the frontmatter is invalid.
 */
async function parseSkillFrontmatter(path: string, signal: AbortSignal): Promise<ParsedFrontmatter | undefined> {
  const text = await readFileSafe(path, signal)
  if (text === undefined) return undefined
  const parsed = parseFrontmatter(text)
  if (parsed === undefined) return undefined
  return readParsedFrontmatter(parsed.data)
}

/** Read a file as text. Returns `undefined` if the file is absent. */
async function readFileSafe(path: string, signal: AbortSignal): Promise<string | undefined> {
  signal.throwIfAborted()
  try {
    return await readFile(path, { encoding: 'utf8', signal })
  } catch (error) {
    if (isAbsentPathError(error)) return undefined
    throw error
  }
}

/** Parse the YAML frontmatter block at the top of a `SKILL.md` file. */
function parseFrontmatter(raw: string): FrontmatterParseResult | undefined {
  const firstLineEnd = raw.indexOf('\n')
  if (firstLineEnd < 0) return undefined
  const firstLine = raw.slice(0, firstLineEnd).replace(/\r$/, '')
  if (firstLine !== '---') return undefined
  const start = firstLineEnd + 1
  const closing = findClosingFrontmatter(raw, start)
  if (closing === undefined) return undefined
  const yaml = raw.slice(start, closing.start)
  let parsed: unknown
  try {
    parsed = parseYaml(yaml)
  } catch {
    return undefined
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) return undefined
  return { data: parsed as Record<string, unknown>, body: raw.slice(closing.bodyStart) }
}

function findClosingFrontmatter(raw: string, start: number): { start: number; bodyStart: number } | undefined {
  let lineStart = start
  while (lineStart <= raw.length) {
    const nextNewline = raw.indexOf('\n', lineStart)
    const lineEnd = nextNewline < 0 ? raw.length : nextNewline
    const line = raw.slice(lineStart, lineEnd).replace(/\r$/, '')
    if (line === '---') {
      return { start: lineStart, bodyStart: nextNewline < 0 ? raw.length : nextNewline + 1 }
    }
    if (nextNewline < 0) return undefined
    lineStart = nextNewline + 1
  }
  return undefined
}

/** Read the parsed frontmatter into a typed record. */
function readParsedFrontmatter(data: Readonly<Record<string, unknown>>): ParsedFrontmatter | undefined {
  const name = stringField(data, 'name')
  const description = stringField(data, 'description')
  if (name === undefined || description === undefined) return undefined
  if (!isSkillName(name)) return undefined
  const disableModelInvocation = parseBooleanField(data, 'disable-model-invocation', false)
  const userInvocable = parseBooleanField(data, 'user-invocable', true)
  const whenToUse = stringField(data, 'whenToUse')
  return {
    name,
    description,
    ...whenToUse !== undefined ? { whenToUse } : {},
    invocation: {
      modelInvocable: !disableModelInvocation,
      userInvocable,
    },
  }
}

function stringField(data: Readonly<Record<string, unknown>>, key: string): string | undefined {
  const value = data[key]
  return typeof value === 'string' && value.length > 0 ? value : undefined
}

/**
 * Parse a boolean frontmatter field. Accepts YAML booleans and the
 * case-insensitive `true`/`false`/`yes`/`no`/`on`/`off`/`1`/`0` set
 * (the same set the upstream provider accepts). Falls back to the
 * provided default when the field is absent. An invalid invocation
 * value falls back to the safe default rather than throwing — the
 * bridge README documents this trade-off and recommends validating
 * skill frontmatter at write time instead.
 */
function parseBooleanField(
  data: Readonly<Record<string, unknown>>,
  key: string,
  fallback: boolean,
): boolean {
  if (!Object.hasOwn(data, key)) return fallback
  const value = data[key]
  if (typeof value === 'boolean') return value
  if (value === 1 || value === '1') return true
  if (value === 0 || value === '0') return false
  if (typeof value === 'string') {
    switch (value.toLowerCase()) {
      case 'true':
      case 'yes':
      case 'on':
        return true
      case 'false':
      case 'no':
        return false
      case 'off':
        return false
    }
  }
  return fallback
}

function isAbsentPathError(error: unknown): boolean {
  if (typeof error !== 'object' || error === null) return false
  const code = (error as { code?: unknown }).code
  return code === 'ENOENT' || code === 'ENOTDIR'
}
