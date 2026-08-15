# `deepseek-harness-bridge` — superpowers skills for the DeepSeek Harness

> **Status:** implemented in our fork, not yet in upstream `obra/superpowers`.
> **Companion doc:** [`docs/upstream/deepseek-harness-analysis.md`](../../docs/upstream/deepseek-harness-analysis.md) is the prerequisite graphify + deep-read analysis this bridge was designed against.

A small bridge that lets every existing `superpowers/skills/*/SKILL.md` file
load into the [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)
without rewriting the skill content. Two complementary paths ship in this
directory:

1. **Lowest-friction path** — a `cordis.yml` overlay that uses the
   harness's own `@deepseek-ai/dsh-skill-filesystem` provider with
   `customSkillDirs: ['./superpowers/skills']`, plus a
   `@deepseek-ai/dsh-hooks-claude-code` bridge that loads our existing
   `hooks.json`. No build, no extra plugin code; one `--patch` flag
   wires the skills up.
2. **Cleaner long-term path** — a custom `ctx.skills` provider in
   `src/index.ts` that reuses the existing `SKILL.md` files but
   registers them under a fork-owned provider name. Use this when you
   want the skills isolated from the harness's other discovery roots
   (e.g., a packaged install where you cannot rely on
   `customSkillDirs`).

The two paths use the same skill files; pick whichever fits your
install shape.

## What is in this directory

```
fork/deepseek-harness-bridge/
├── README.md                this file
├── cordis.yml               lowest-friction: reuses @deepseek-ai/dsh-skill-filesystem + dsh-hooks-claude-code
├── hooks.json               Claude-Code-compatible SessionStart hook (reuses hooks/session-start)
├── package.json             bridge package metadata (the cleaner long-term path)
├── tsconfig.json            type-check settings for src/index.ts
├── src/
│   └── index.ts             the custom ctx.skills provider (cleaner long-term path)
├── test/
│   └── provider.test.ts    unit tests for the custom provider (run with bun)
├── examples/
│   ├── config.example.json  bare-bones user config
│   ├── dsh-headless.yml     a headless profile patch that wires everything up
│   └── acceptance.md        the per-port acceptance test
└── CHANGELOG.md             per-bridge change log
```

## Install (lowest-friction path, the recommended start)

This path uses the harness's own providers and our existing
`hooks/session-start` script. No build, no extra package.

```sh
# 1. Make sure the harness can find the harness-bridge and the superpowers skills.
#    Both live in the same checkout: <checkout>/fork/deepseek-harness-bridge/
#    and <checkout>/skills/. Patch the harness with our cordis.yml:

dsh --profile web --patch ./fork/deepseek-harness-bridge/cordis.yml

# 2. (Optional) Persist the patch in your profile so every session
#    inherits it. Drop the same cordis.yml into the active profile's
#    directory (~/.dsh/profiles/<name>/cordis.patch.yml by default).
```

What the patch does:

- Sets `customSkillDirs` on the `@deepseek-ai/dsh-skill-filesystem` provider
  to point at `./superpowers/skills` (rank 300, after the project roots
  and before the user roots, so user-level skills still override).
- Adds the `@deepseek-ai/dsh-hooks-claude-code` bridge with
  `configPath: ./fork/deepseek-harness-bridge/hooks.json` so the
  `SessionStart` hook injects the `using-superpowers` bootstrap into
  every new session.
- Re-uses the existing `hooks/session-start` script (no fork-local
  duplicate). The script detects the harness from env vars; on
  DeepSeek, it falls through to the `additionalContext` (SDK standard)
  branch which the bridge maps to `agent.inject()`.

## Install (cleaner long-term path, future optimization)

This path uses the custom `ctx.skills` provider in `src/index.ts`. It
skips the harness's discovery + watcher stack and re-registers the
existing `SKILL.md` files directly. Use this when:

- You want the bridge to be a single self-contained package (no
  `customSkillDirs` indirection).
- You are packaging the fork for distribution outside the source tree.
- You want the bridge to control how skills are named in the
  discovery roots (so user-shadowed skills cannot silently override).

Build it first:

```sh
# 1. Install dev deps + build the provider.
cd fork/deepseek-harness-bridge
bun install                # uses bun >= 1.3.13
bun run build              # writes lib/index.js + lib/index.d.ts

# 2. Reference the built output from your patch:
cd ../..
dsh --profile web --patch ./fork/deepseek-harness-bridge/examples/dsh-headless.yml
```

See `examples/dsh-headless.yml` for the patch contents.

## What is and is not covered

| Concern | Status | Notes |
| --- | --- | --- |
| Skill discovery (`ctx.skills`) | ✅ | Either via `customSkillDirs` (path 1) or the custom provider (path 2). |
| Model-facing catalog (`<available_skills>`) | ✅ | Same template as Claude Code; the harness renders it. |
| `skill` tool (load-on-demand) | ✅ | The harness's `@deepseek-ai/dsh-tool-skill` tool works against the registered provider. |
| `/<name>` user invocation | ✅ | The harness's regex is `/(^|\s)\/([a-z0-9]+(?:-[a-z0-9]+)*)(?=\s|$)/g`. All 15 superpowers skill names are kebab-case and match. No adapter needed. |
| `SessionStart` bootstrap | ✅ | via `dsh-hooks-claude-code` + the existing `hooks/session-start` script. |
| `UserPromptSubmit` / `PreToolUse` / `PostToolUse` / `Stop` hooks | ✅ | same bridge; `commands` of `type: 'command'` run. |
| `SessionEnd` hook | ❌ | `dsh-hooks-claude-code` has no mapping for `SessionEnd`. **No superpowers skill depends on it** (verified — see `examples/acceptance.md`). If a future skill does, write a native Cordis plugin on `agent/turn-end` / `session/dispose`. |
| `Bash(...)` permission rules | ❌ | The harness uses a generic JSON policy via `dsh-sandbox-policy` / `dsh-approval` rows. **No superpowers skill ships `Bash(...)`-style rules** (they live in the user's `settings.json`, not in the skill). Translating those is the user's job; this bridge does not auto-translate. |
| `subagent` vs `subagent_fork` distinction | ⚠️ | Superpowers skills name the action ("dispatch a subagent") without naming the tool. The `using-superpowers/SKILL.md` Platform Adaptation list now points at `references/deepseek-harness-tools.md` so the model knows which tool to call. See the tool mapping reference. |
| `catalogDescriptionMaxLength` cap (500) | ✅ | All 15 superpowers `description:` values are under 500 chars (max is `safety-check` at 315). No trimming needed. |
| `disable-model-invocation` / `user-invocable` frontmatter | ✅ | No superpowers skill sets these today; if a future skill does, the harness's strict parser is compatible. |
| MCP, settings, credentials | n/a | The harness handles these natively; the bridge does not re-implement them. |
| Windows / WSL | ⚠️ | The bridge reuses `hooks/session-start` which is shell + bash. Windows is supported by the existing polyglot `run-hook.cmd` mechanism — the DeepSeek harness's `@deepseek-ai/dsh-bash-sandbox` is platform-aware. No additional Windows work is needed in this bridge. |

## Open questions deferred to upstream

1. **`/name` regex as the only user-invocation surface.** The harness
   does not list `/<name>` in `/help` and does not parse arguments
   after the token. If we ever need `/superpowers-brainstorm my idea`
   semantics, a thin native Cordis plugin can wrap the regex match in
   `dsh-hooks-claude-code` and inject the body — until then, the
   bare-name gesture is the contract.
2. **Catalog description trimming at deploy time.** The
   `catalogDescriptionMaxLength` is configurable per `tool-skill`
   instance. We have not raised it (no superpowers description is
   over 500). If a future skill grows past 500, the deploy-time
   decision is to either trim the `description:` or raise
   `catalogDescriptionMaxLength` in the patch.
3. **No first-class `Bash(...)` syntax.** The harness's `dsh-approval`
   row uses a JSON policy. If users want to translate their existing
   Claude Code `Bash(...)` rules, they can do so by hand in the
   `dsh-approval` row config; the bridge does not auto-translate.
   This is the right boundary: rule semantics differ between the two
   harnesses (sandbox modes, scope, per-command approval), and silent
   auto-translation is more dangerous than explicit re-authoring.

## Acceptance test

Per the porting spec (`docs/porting-to-a-new-harness.md` Part 3), the
acceptance test for this bridge is documented in
`examples/acceptance.md`. TL;DR — in a clean session, the message
"let's make a react todo list" must auto-trigger the `brainstorming`
skill before any code is written.

## Per-port-shape pointers

- **Shape A (shell hook)** — the existing `hooks/session-start` script
  emits the harness-agnostic JSON shape; the bridge's
  `dsh-hooks-claude-code` row consumes it. The script is unchanged
  from how Claude Code, Cursor, Copilot CLI, and OpenCode consume it
  today.
- **Shape B (in-process plugin)** — `src/index.ts` is the in-process
  equivalent, a Cordis plugin that mutates the layered `ctx.skills`
  registry. The harness loads it via the
  `- id: deepseek-harness-bridge` row in the patch YAML.
- **Shape C (instructions file)** — the DeepSeek harness's
  `AGENTS.md` is the analog of `GEMINI.md` / `CLAUDE.md`. We do not
  ship an in-tree `AGENTS.md` because the harness's own
  `AGENTS.md` is for the harness maintainers, not for skill consumers
  (see [the analysis doc](../../docs/upstream/deepseek-harness-analysis.md#8-open-questions--unknowns)
  question 9). The bootstrap rides the `dsh-hooks-claude-code` row
  instead.

## See also

- [`docs/upstream/deepseek-harness-analysis.md`](../../docs/upstream/deepseek-harness-analysis.md) — prerequisite research
- [`docs/porting-to-a-new-harness.md`](../../docs/porting-to-a-new-harness.md) — the porting spec
- [`docs/compatibility.md`](../../docs/compatibility.md) — runtime matrix
- [DeepSeek Harness repo](https://github.com/deepseek-ai/deepseek-harness) — the upstream harness
- [Cordis](https://github.com/cordiverse/cordis) — the plugin framework the harness is built on
