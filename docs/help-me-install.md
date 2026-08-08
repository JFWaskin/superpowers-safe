# Help me install from GitHub

> Shareable one-liner. Copy the prompt below into any agent and let it do
> the install. Works across every runtime that ships the plugin manifests
> in this repo.

## The prompt

Copy and paste this into any agent (Claude Code, Codex, Cursor, Gemini CLI,
Kimi Code, OpenCode, Pi, Hermes, GitHub Copilot CLI, Factory Droid, …):

```text
Please install the superpowers-safe fork from GitHub for whichever agent
runtime you are currently running in.

Repo: https://github.com/JFWaskin/superpowers-safe

What I need you to do:
1. Detect which agent runtime you are in (Claude Code / Codex / Cursor /
   Gemini CLI / Kimi Code / OpenCode / Pi / Hermes / GitHub Copilot CLI /
   Factory Droid / Antigravity / other).
2. If an upstream `superpowers` install is already present in this runtime,
   disable it. The fork replaces the upstream — I do not want both loaded.
3. Run the appropriate install command for the fork. If no clean install
   path exists for this runtime, stop and tell me what is missing rather
   than guessing.
4. Verify the `safety-check` skill is loadable after install.
5. Tell me the install path you used and any manual steps I need to take
   to finish (e.g. enabling in settings, restarting the agent).

Reference install commands are in `docs/help-me-install.md` of the repo
under "Per-runtime install commands" below. The fork's `README.md` also
has them in the "Cross-runtime support" table.
```

## What the agent should do

| Step | Action |
|---|---|
| 1 | Detect runtime from environment, settings file, or by asking the user. |
| 2 | If upstream is present, set `enabledPlugins.superpowers@claude-plugins-official = false` (or equivalent) **before** installing the fork. |
| 3 | Run the install. Prefer marketplace commands over direct git-URL installs when both exist. |
| 4 | Confirm the `safety-check` skill is reachable. For Claude Code this means the file `skills/safety-check/SKILL.md` exists under the install path. |
| 5 | Report back. |

## Per-runtime install commands

For reference. The agent should pick the row matching its detected runtime.

| Runtime | Install command | Disable upstream |
|---|---|---|
| **Claude Code** | `/plugin marketplace add JFWaskin/superpowers-safe && /plugin install superpowers-safe@JFWaskin-superpowers-safe` | `/plugin disable superpowers@claude-plugins-official` |
| **Codex (app)** | Plugins → Coding → search `superpowers-safe` → Install | Disable the upstream `superpowers` plugin in the same UI |
| **Codex CLI** | `/plugins` → search `superpowers-safe` → Install | `/plugins` → disable the upstream `superpowers` plugin |
| **Cursor** | `/add-plugin superpowers-safe` | Remove or disable upstream `superpowers` in Cursor settings |
| **Gemini CLI** | `gemini skills link https://github.com/JFWaskin/superpowers-safe` (link each skill under `skills/`) **or** `gemini extensions install https://github.com/JFWaskin/superpowers-safe` | Disable any upstream `superpowers` extension with `gemini extensions disable superpowers` |
| **Kimi Code** | `/plugins` → Marketplace → search `superpowers-safe` → Install | `/plugins` → disable upstream `superpowers` |
| **OpenCode** | Add `"superpowers-safe@git+https://github.com/JFWaskin/superpowers-safe"` to the `plugin` array in `opencode.json`, then restart | Remove the upstream `superpowers` entry from `opencode.json` |
| **Pi** | Marketplace install → search `superpowers-safe` | Disable upstream `superpowers` in the Pi marketplace UI |
| **Hermes** | `agy plugin install https://github.com/JFWaskin/superpowers-safe` | `agy plugin disable superpowers` |
| **GitHub Copilot CLI** | `copilot plugin marketplace add JFWaskin/superpowers-safe && copilot plugin install superpowers-safe@JFWaskin-superpowers-safe` | `copilot plugin disable superpowers` |
| **Factory Droid** | `droid plugin marketplace add https://github.com/JFWaskin/superpowers-safe && droid plugin install superpowers-safe@JFWaskin` | `droid plugin disable superpowers` |
| **Antigravity** | No first-party support yet. Track [issue](#) for status. | n/a |

## Verify after install

- [ ] The `safety-check` skill is loadable
- [ ] The `using-superpowers` skill includes the `<MANDATORY-SAFETY-GATE>` block
- [ ] Upstream `superpowers` is **disabled**, not deleted (so rollback is easy)
- [ ] The fork shows up in the agent's plugin list

## If the install fails

The agent should **stop and report** rather than improvise. The most common
failure modes are:

- **Network/registry not reachable** — the agent can't reach the plugin
  registry. Try again, or install from a local checkout.
- **Plugin manifest not recognized** — the runtime doesn't know about
  this marketplace yet. Register it first (Claude Code:
  `/plugin marketplace add …`).
- **Permission denied** — some runtimes need elevated permissions to write
  to the plugin cache. Re-run with the right scope.
- **Conflict with existing install** — disable or uninstall the upstream
  first, then retry.

If the agent is stuck, point it at this file and ask it to follow the
"Per-runtime install commands" table directly.
