# Compatibility Matrix

> Which runtimes has `superpowers-safe` been tested on, and to what
> depth. Honest about what we know and what we don't.

## Status legend

- ✅ **Tested**: end-to-end install + load + safety gate verified on this host
- 🟡 **Manifest validated**: manifest JSON is correct for this runtime, but no actual install/load test on this host
- ⚠️ **Partial**: something works, something doesn't (see notes)
- ❌ **Not installed**: this runtime is not installed on the test host
- 🚫 **Not supported**: deliberately not supported (see notes)

## Runtimes

| Runtime | Install | Load | Safety gate | Plugin manifest | Notes |
|---|---|---|---|---|---|
| **Claude Code** | ✅ | ✅ | ✅ | ✅ | Primary runtime. Full test path. The `MANDATORY-SAFETY-GATE` is loaded by SessionStart hook. `safety-check` skill auto-loads. Hook blocks at the tool layer. |
| **Gemini CLI** | ✅ | ✅ | ✅ | ✅ | `gemini skills link` over 15 skills including safety-check. Gate's resource check (`vm_stat`) is macOS-specific — would need adjustment on Linux. |
| **DeepSeek Harness** | 🟡 | 🟡 | 🟡 | ✅ | New runtime, 2026-08-15 release. Not installed on test host. Bridge in `fork/deepseek-harness-bridge/` (Cordis plugin + `cordis.yml` overlay + Claude-Code-shaped `hooks.json`). Lowest-friction install: `dsh --profile web --patch ./fork/deepseek-harness-bridge/cordis.yml`. Prereq analysis at `docs/upstream/deepseek-harness-analysis.md`. Upstream-PR inquiry to `obra/superpowers` pending — not claiming compatibility here until the ask-PR model resolves. |
| **Codex CLI** | ❌ | 🟡 | 🟡 | ✅ | Codex CLI not installed on test host. Manifest validated; install path requires OpenAI's plugin publish flow. |
| **Cursor** | ❌ | 🟡 | 🟡 | ✅ | Cursor not installed on test host. Plugin auto-discovered via `.cursor-plugin/plugin.json`. |
| **Devin CLI** | ❌ | 🟡 | 🟡 | ✅ | Devin not installed on test host. `.devin-plugin/plugin.json` is auto-discovered; Devin's own system prompt already documents subagent / todo / question tools, so no tool-mapping scaffold is required. CI test in `tests/devin/test-devin-plugin.sh`. |
| **Grok Build CLI** | ❌ | 🟡 | 🟡 | 🚫 | Grok not installed on test host. Plugin would be installed via `grok plugin install ... --trust`; no dedicated manifest yet (the fork's `package.json` is the closest thing). |
| **Kimi Code** | ❌ | 🟡 | 🟡 | ✅ | Kimi not installed on test host. Plugin install is TUI-only. `skillInstructions` references the safety-check skill. |
| **OpenCode** | ❌ | 🟡 | 🟡 | ✅ | OpenCode not installed on test host. Plugin format lives in `package.json` (Pi-compatible). |
| **Pi** | ❌ | 🟡 | 🟡 | ✅ | Pi not installed on test host. Same package.json layout. |
| **GitHub Copilot CLI** | ❌ | 🟡 | 🟡 | ✅ | Not installed. Cross-harness packaging mirrors upstream. |
| **Factory Droid** | ❌ | 🟡 | 🟡 | ✅ | Not installed. Droid CLI install path documented but not exercised. |
| **Antigravity** | ❌ | 🟡 | 🟡 | ✅ | Not installed. `agy plugin install` documented but not exercised. |
| **Hermes** | ❌ | 🟡 | 🟡 | ✅ | Not installed. `.hermes-plugin/plugin.yaml` validated. |
| **Augment / Continue / Cline / Aider** | 🚫 | 🚫 | 🚫 | 🚫 | Not supported. These runtimes don't have a plugin discovery mechanism compatible with this manifest family. Use at your own risk. |

## How "tested" is determined

For each ✅ cell above, we ran the full path:
1. **Install**: the runtime's standard install command for the plugin
2. **Load**: started a new session in the runtime
3. **Safety gate**: confirmed `<MANDATORY-SAFETY-GATE>` was present in
   the session context AND the `safety-check` skill was auto-loaded
   AND the `safety-guard.py` hook (where applicable) was registered

For 🟡 cells, only step "manifest" was performed: the JSON manifest
file passes linting, has the right `name`, `version`, `keywords`, and
the safety-check skill is referenced. The runtime is not installed on
the test host, so steps 1-3 cannot be verified.

## What this matrix doesn't claim

- ✅ does **not** mean "the safety gate works correctly in all
  scenarios on this runtime." It means "the install path works, the
  plugin loads, and the gate is wired up." Behavior under pressure
  scenarios is validated only by the eval protocol (Tier 1.1), which
  has not been run yet.
- The matrix is **per-test-host**, not per-user. A user with a
  different OS or runtime version may see different results.
- New runtimes that are added upstream (e.g. via a new harness
  PR) need their own row here. The matrix is not auto-updated.

## Adding a new row

When you test a new runtime:
1. Install per the runtime's docs
2. Verify the manifest is loadable
3. Start a session, check that the gate is in the context
4. Run a destructive command, verify the hook blocks
5. Add a row above with the new runtime

If the runtime uses a different manifest format (not in the 7
upstream-supported families), the plugin will not work — see
`docs/porting-to-a-new-harness.md` for adding support.

## References

- [`safety-gate.md`](safety-gate.md) — what the gate does
- [`THREAT-MODEL.md`](THREAT-MODEL.md) — what the gate does NOT do
- [`benchmarks.md`](benchmarks.md) — performance overhead per runtime
- [`tests/evals/README.md`](../tests/evals/README.md) — eval protocol
