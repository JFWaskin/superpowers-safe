# superpowers-safe

> A safety-hardened fork of [obra/superpowers](https://github.com/obra/superpowers). Same skills library, plus a **mandatory safety preflight** before any skill runs.

`superpowers-safe` keeps every skill from upstream Superpowers byte-identical and adds one thing: a `safety-check` preflight that runs **five hard gates** before any work begins. The preflight defends against destructive bash commands, runaway subagents, resource exhaustion, secret leaks, and scope creep.

- Upstream: [`obra/superpowers`](https://github.com/obra/superpowers) — Jesse Vincent & the Prime Radiant team, MIT
- This fork: [`JFWaskin/superpowers-safe`](https://github.com/JFWaskin/superpowers-safe) — Jonathan F. Waskin, Huaqiao University (HQU)
- Sync: rebase from `upstream/dev` regularly (`scripts/sync-upstream.sh`)

---

## Why this fork exists

Superpowers' `subagent-driven-development`, `dispatching-parallel-agents`, and `executing-plans` skills can run for hours, dispatch many subagents, and execute thousands of bash commands. That's powerful — and it's exactly when one wrong `rm -rf` or runaway `find` can wreck a machine, a git history, or a public registry.

`superpowers-safe` doesn't change what Superpowers teaches. It adds a gate at the front door.

### What the gate enforces (5 hard gates)

| # | Gate | What it checks |
|---|------|---------------|
| 1 | **Resource budget** | Disk ≥ 2 GB free, RAM ≥ 1 GB free, load avg < 2× core count |
| 2 | **Command risk scan** | Refuses destructive bash (`rm -rf` on system paths, `dd` to device, fork bombs, `curl \| sh`, force-push to main, publish commands, `sudo` without per-command OK) |
| 3 | **Loop / spend limits** | Max 3 concurrent subagents, 30 min autonomous check-in, $1 / $5 / $10 spend thresholds, ralph-loop guard |
| 4 | **Secret / PII scan** | Pre-write scan for `.env`, `*.key`, `id_rsa*`, `*.pem`, `sk-…`, `ghp_…` |
| 5 | **Scope confirmation** | One-line plan + explicit "go" before non-trivial work |

The full specification is in [`docs/safety-gate.md`](docs/safety-gate.md). The skill itself is [`skills/safety-check/SKILL.md`](skills/safety-check/SKILL.md).

### Defense in depth

The skill-level gate is the first line. The recommended second line is a `PreToolUse` hook that blocks destructive bash at the tool layer — even if the agent skips the skill. See [`docs/safety-gate.md#defense-in-depth`](docs/safety-gate.md) for the hook pattern.

---

## Installation

### Claude Code (official marketplace)

```bash
# 1. Register this fork's marketplace
/plugin marketplace add JFWaskin/superpowers-safe

# 2. Install the plugin
/plugin install superpowers-safe@JFWaskin-superpowers-safe

# 3. (Optional) Disable the upstream version to avoid two skills libraries
# /plugin disable superpowers@claude-plugins-official
```

After install, restart Claude Code so the SessionStart hook injects the `using-superpowers` content (which now includes the `<MANDATORY-SAFETY-GATE>` block) into context.

### Claude Code (from URL, no marketplace)

```bash
/plugin install https://github.com/JFWaskin/superpowers-safe
```

### Other runtimes

The same plugin supports Codex, Cursor, Kimi Code, Gemini CLI, Hermes, OpenCode, and Pi. See [Cross-runtime support](#cross-runtime-support) below.

---

## Quickstart

Once installed, every Claude Code session starts with the `safety-check` gate loaded. To use it explicitly:

> "I want to refactor the auth module. Please run the safety-check first."

The agent will run the 5 gates, output a `[SAFETY CLEARED]` or `[SAFETY HALTED]` block, and only then proceed.

For the most common case — you want a coding task done with the full Superpowers workflow — just ask normally. The `using-superpowers` meta-skill will route through `safety-check` first, then `brainstorming` (if it's a new feature), then the appropriate implementation skills.

---

## Cross-runtime support

This fork mirrors upstream's cross-runtime packaging. The same safety gate is honored on every runtime:

| Runtime | Install |
|---------|---------|
| Claude Code | `/plugin install superpowers-safe@JFWaskin-superpowers-safe` |
| Codex App | Search "superpowers-safe" in Plugins → Coding |
| Codex CLI | `/plugins` → search `superpowers-safe` → Install |
| Cursor | `/add-plugin superpowers-safe` |
| Gemini CLI | `gemini extensions install https://github.com/JFWaskin/superpowers-safe` |
| Kimi Code | Plugin marketplace (search `superpowers-safe`) |
| OpenCode | Plugin marketplace (search `superpowers-safe`) |
| Pi | Marketplace install (search `superpowers-safe`) |
| Hermes | `agy plugin install https://github.com/JFWaskin/superpowers-safe` |
| GitHub Copilot CLI | `copilot plugin marketplace add JFWaskin/superpowers-safe && copilot plugin install superpowers-safe@JFWaskin-superpowers-safe` |
| Factory Droid | `droid plugin marketplace add https://github.com/JFWaskin/superpowers-safe && droid plugin install superpowers-safe@JFWaskin` |

The `safety-check` gate is enforced via the `<MANDATORY-SAFETY-GATE>` block in `skills/using-superpowers/SKILL.md`, which is loaded by every runtime that auto-discovers skills in `skills/`.

---

## Repository layout

```
superpowers-safe/
├── .claude-plugin/        Claude Code plugin + marketplace manifests
├── .codex-plugin/         Codex plugin manifest
├── .cursor-plugin/        Cursor plugin manifest
├── .kimi-plugin/          Kimi Code plugin manifest
├── .hermes-plugin/        Hermes plugin manifest
├── gemini-extension.json  Gemini CLI extension manifest
├── package.json           OpenCode / Pi package manifest
├── skills/                All Superpowers skills (byte-identical to upstream + 1 new: safety-check)
│   ├── using-superpowers/ (modified: +<MANDATORY-SAFETY-GATE> block)
│   ├── safety-check/      (NEW: the preflight skill)
│   └── ...                (12 other skills, synced from upstream)
├── hooks/                 SessionStart hook (auto-injects using-superpowers into context)
├── tests/                 Plugin-infrastructure tests (shell-based, run via `run-skill-tests.sh`)
├── scripts/               Sync + version-bump scripts
├── docs/                  Safety-gate spec, sync guide, eval protocol
├── CLAUDE.md              Fork identity + contributor rules
├── AGENTS.md              Symlink to CLAUDE.md
├── GEMINI.md              Gemini entry point
├── CHANGELOG.md           Versioned change log
├── CONTRIBUTING.md        PR rules
└── LICENSE                MIT (inherited from upstream)
```

---

## How to contribute to this fork

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and the in-repo contributor rules in [`CLAUDE.md`](CLAUDE.md). Short version:

1. Sync from `upstream/dev` first
2. Branch off `dev`, target `dev` in the PR
3. Safety-gate changes need RED-GREEN-REFACTOR evidence (3+ pressure scenarios)
4. Skill content changes need an upstream issue/PR reference
5. Identify model, harness, version, and plugins in the PR

---

## How to sync from upstream

```bash
# In your local work tree
./scripts/sync-upstream.sh
```

This rebases `dev` onto `upstream/dev`, fast-forwarding when possible and pausing for conflict resolution when not. The script refuses to push if there are uncommitted changes or if the local `dev` is not a clean superset of `upstream/dev`.

See [`docs/sync-upstream.md`](docs/sync-upstream.md) for the manual procedure and conflict-resolution policy.

---

## Documentation

All docs are indexed in [`docs/INDEX.md`](docs/INDEX.md). Highlights:

- [`docs/safety-gate.md`](docs/safety-gate.md) — the 5 hard gates and never-override limits
- [`docs/eval-protocol.md`](docs/eval-protocol.md) — RED-GREEN-REFACTOR protocol for gate changes
- [`docs/sync-upstream.md`](docs/sync-upstream.md) — rebase-from-upstream procedure
- [`docs/porting-to-a-new-harness.md`](docs/porting-to-a-new-harness.md) — how to add a new AI harness
- [`docs/testing.md`](docs/testing.md) — `tests/` (plugin code) vs `evals/` (LLM sessions)

---

## License

MIT. Same as upstream. See [`LICENSE`](LICENSE).

Upstream copyright: Jesse Vincent and the Superpowers contributors.
Fork changes copyright: Jonathan F. Waskin and the `superpowers-safe` contributors.

---

## Acknowledgments

- **Jesse Vincent** and the Prime Radiant team for [obra/superpowers](https://github.com/obra/superpowers), the underlying skills library
- The **superpowers-evals** team for the [Quorum behavioral eval lab](https://github.com/prime-radiant-inc/superpowers-evals) that makes RED-GREEN-REFACTOR possible
- Everyone who's contributed pressure scenarios, bug reports, and skill improvements upstream
