# Migrating from upstream `obra/superpowers`

> Step-by-step guide for users who already have the upstream
> `superpowers@claude-plugins-official` (or the equivalent on another
> runtime) installed and want to move to `superpowers-safe`.

## When to migrate

- You want the mandatory 5-gate safety preflight before any skill runs
- You run `subagent-driven-development` or `dispatching-parallel-agents` for hours at a time and want a hard "no" before destructive operations
- You operate Claude Code (or another supported runtime) on machines with real data and want defense in depth

If you only use brainstorming, planning, and TDD for short sessions, the upstream plugin is probably enough.

## What's different from upstream

`superpowers-safe` is byte-identical to upstream on every skill except:

| Where | What changed |
|---|---|
| `skills/using-superpowers/SKILL.md` | Added a `<MANDATORY-SAFETY-GATE>` block at the top. Forces the agent to invoke `safety-check` before any non-trivial skill. |
| `skills/safety-check/SKILL.md` (new) | The 5-gate preflight itself. Defines resource budget, command risk scan, loop/spend limits, secret/PII scan, scope confirmation. |
| `hooks/safety-guard.py` (new) | Optional defense-in-depth: a `PreToolUse` hook that blocks destructive bash at the tool layer even if the agent tries to skip the skill. |
| Plugin / extension manifests | Renamed to `superpowers-safe` in every runtime's manifest (`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `.kimi-plugin/`, `.hermes-plugin/`, `gemini-extension.json`, `package.json`). |
| Marketplace | The fork is its own Claude Code marketplace: `/plugin marketplace add JFWaskin/superpowers-safe`. |

The other 14 skills (`brainstorming`, `test-driven-development`, `systematic-debugging`, `subagent-driven-development`, `dispatching-parallel-agents`, `executing-plans`, `writing-plans`, `finishing-a-development-branch`, `requesting-code-review`, `receiving-code-review`, `verification-before-completion`, `using-git-worktrees`, `writing-skills`, and the skill you came for — `using-superpowers`) are unchanged in content; only `using-superpowers` has the safety gate prepended.

## Side-by-side install (recommended)

The fork and the upstream are distinct plugins and can coexist. The fork replaces the upstream's role, but having both loaded at once is wasteful and confusing. Two paths:

### Path A — Clean swap (recommended)

1. **Install the fork** in your runtime (per the table below).
2. **Verify it loads** (the `safety-check` skill is reachable).
3. **Disable the upstream** (do not uninstall — keeps the cache for rollback).
4. **Restart the runtime** so the new `using-superpowers` content (with the MANDATORY-SAFETY-GATE block) is loaded into context.

### Path B — Side-by-side for evaluation

1. Install the fork in a non-default project / workspace.
2. Use the fork in that workspace only.
3. After a week or two of usage, disable the upstream globally and move the fork to your default.

## Per-runtime install (with disable-upstream step)

| Runtime | Install | Disable upstream |
|---|---|---|
| **Claude Code** | `/plugin marketplace add JFWaskin/superpowers-safe && /plugin install superpowers-safe@JFWaskin-superpowers-safe` | `/plugin disable superpowers@claude-plugins-official` |
| **Codex (app)** | Plugins → Coding → search `superpowers-safe` → Install | Disable the upstream `superpowers` plugin in the same UI |
| **Codex CLI** | `/plugins` → search `superpowers-safe` → Install | `/plugins` → disable upstream `superpowers` |
| **Cursor** | `/add-plugin superpowers-safe` | Remove or disable upstream `superpowers` in Cursor settings |
| **Gemini CLI** | For each skill under `skills/`: `gemini skills link <path> --consent`. Full extension manifest: `gemini extensions install https://github.com/JFWaskin/superpowers-safe` | Disable any upstream `superpowers` extension with `gemini extensions disable superpowers` |
| **Kimi Code** | `/plugins` → Marketplace → search `superpowers-safe` → Install | `/plugins` → disable upstream `superpowers` |
| **OpenCode** | Add `"superpowers-safe@git+https://github.com/JFWaskin/superpowers-safe"` to the `plugin` array in `opencode.json` and restart | Remove the upstream `superpowers` entry from `opencode.json` |
| **Pi** | Marketplace install → search `superpowers-safe` | Disable upstream `superpowers` in the Pi marketplace UI |
| **Hermes** | `agy plugin install https://github.com/JFWaskin/superpowers-safe` | `agy plugin disable superpowers` |
| **GitHub Copilot CLI** | `copilot plugin marketplace add JFWaskin/superpowers-safe && copilot plugin install superpowers-safe@JFWaskin-superpowers-safe` | `copilot plugin disable superpowers` |
| **Factory Droid** | `droid plugin marketplace add https://github.com/JFWaskin/superpowers-safe && droid plugin install superpowers-safe@JFWaskin` | `droid plugin disable superpowers` |
| **Antigravity** | No first-party support yet (see `docs/compatibility.md`). | n/a |

For more detail and a copy-pasteable "help me install" prompt, see [`help-me-install.md`](help-me-install.md).

## Verify after install

- [ ] `safety-check` skill is loadable in your runtime
- [ ] `using-superpowers` includes the `<MANDATORY-SAFETY-GATE>` block
- [ ] Upstream `superpowers` is **disabled**, not deleted
- [ ] The fork's commands (e.g. `/superpowers-safe:brainstorming` in Claude Code, or just `brainstorming` on runtimes without prefixes) trigger correctly
- [ ] A non-trivial task produces a `[SAFETY CLEARED]` or `[SAFETY HALTED]` block before any other skill runs

If any of those fail, see [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) (when it exists) or open an issue with the runtime name, version, and the exact error.

## What changes in your workflow

- **Brainstorming, planning, TDD, code review, systematic debugging, verification** — all unchanged. The skills read the same way and produce the same output.
- **Subagent dispatch** — `subagent-driven-development` and `dispatching-parallel-agents` now run the gate per-subagent. The first subagent spawn has the full 5-gate check; subsequent subagents in the same run have a slimmed-down check (gates 1, 2, 4) since the parent already cleared the rest. Subagents can no longer silently `rm -rf` outside the working directory.
- **Git operations** — `git push --force` to `main` / `master` is blocked. `--force` to any other branch still works.
- **Package publishing** — `npm publish`, `pip upload`, `cargo publish` now require explicit per-command user OK. The agent will not just run them.
- **Long autonomous sessions** — the gate's gate 3 includes a 30-minute check-in. If you run a multi-hour task, the agent will surface for confirmation at the 30-minute mark, then every 30 minutes after. This is intentional; cancel it if you don't want it.
- **`sudo`** — any sudo command requires explicit per-command OK. The agent will not use sudo without asking.

## What does NOT change

- All other skills (`brainstorming`, `executing-plans`, `writing-plans`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`, `receiving-code-review`, `verification-before-completion`, `using-git-worktrees`, `writing-skills`, `finishing-a-development-branch`, `dispatching-parallel-agents`) are byte-identical to upstream. If your workflow relied on those, nothing about it changes.
- The cross-runtime packaging is the same: same set of supported runtimes, same install mechanism per runtime.
- The skill format and trigger conditions are unchanged. If you have muscle memory for "ask Claude to brainstorm", that still works the same way.

## Rollback

If you want to go back to upstream:

1. Re-enable the upstream plugin: `/plugin enable superpowers@claude-plugins-official` (or equivalent).
2. Disable the fork: `/plugin disable superpowers-safe@JFWaskin-superpowers-safe`.
3. Restart the runtime.

The fork is uninstalled (cache cleared) only if you explicitly do so; disabling leaves it in the cache for quick re-enable. If you want to remove the cache entirely:

```bash
rm -rf ~/.claude/plugins/cache/JFWaskin-superpowers-safe
```

## Differences that may surprise you

- **The agent asks more questions.** The gate forces a scope confirmation (one-line plan + "go") before any non-trivial task. If you liked the upstream's "just do it" behavior, this will feel slower at first.
- **The agent refuses more commands.** `sudo`, `rm -rf` outside the working directory, force-push to main, `npm publish` — all require explicit OK. You can grant OK per-command; the gate does not ask every time.
- **Subagent dispatch has a concurrency cap.** Max 3 concurrent subagents, regardless of what `dispatching-parallel-agents` would otherwise try. This is a hard limit in gate 3. If you need more parallelism, split the work into batches.
- **Spend thresholds.** The gate has $1 / $5 / $10 spend thresholds. At $1 the agent surfaces for a quick "still want to continue?". At $5 it requires explicit "yes, keep going". At $10 it halts. These are estimates, not exact. Real spend tracking is your API provider's job.

## If you hit a problem

1. Check [`docs/compatibility.md`](compatibility.md) — your runtime may not be fully tested.
2. File an issue at <https://github.com/JFWaskin/superpowers-safe/issues>. Include runtime, version, model, and the exact error.
3. If the problem is with the gate itself (e.g. it's blocking something you think it shouldn't), open an issue with the tag `gate-discussion`. Don't open a PR — gate changes need RED-GREEN-REFACTOR evidence per [`docs/eval-protocol.md`](eval-protocol.md).
