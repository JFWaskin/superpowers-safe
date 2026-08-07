# The Safety Gate Specification

> Companion document to [`skills/safety-check/SKILL.md`](../skills/safety-check/SKILL.md).
> This file is the engineering spec. The SKILL.md is what the agent reads.

## Purpose

Superpowers' `subagent-driven-development`, `dispatching-parallel-agents`,
and `executing-plans` skills can run for hours, dispatch many subagents, and
execute thousands of bash commands. The safety gate is the front door that
ensures every work session starts with a hard check on the environment, the
planned operations, and the scope. The gate is the user — the agent must
get explicit "go" before doing anything irreversible.

The gate is **not** a replacement for human review. It is a structure that
forces the agent to surface risks before they become incidents.

## Architecture

```
                    ┌──────────────────────────────────────────────┐
                    │   using-superpowers/SKILL.md                 │
                    │   <MANDATORY-SAFETY-GATE> block (top)        │
                    └──────────────────┬───────────────────────────┘
                                       │ "must invoke safety-check first"
                                       ▼
                    ┌──────────────────────────────────────────────┐
                    │   skills/safety-check/SKILL.md               │
                    │   5 gates + never-override list              │
                    └──────────────────┬───────────────────────────┘
                                       │ "all 5 gates passed"
                                       ▼
                    ┌──────────────────────────────────────────────┐
                    │   other superpowers skills                   │
                    │   (brainstorming, SDD, TDD, debugging, ...)  │
                    └──────────────────────────────────────────────┘

       Defense in depth (optional, recommended):

                    ┌──────────────────────────────────────────────┐
                    │   ~/.claude/hooks/safety-guard.py            │
                    │   PreToolUse matcher=Bash                    │
                    │   Exits 2 on destructive patterns            │
                    └──────────────────────────────────────────────┘
```

The skill-level gate is the **first** line. The `PreToolUse` hook is the
**second** line — it catches destructive bash even if the agent skips the
skill. Both should be deployed in production.

## The 5 gates

See [`skills/safety-check/SKILL.md`](../skills/safety-check/SKILL.md#the-5-safety-gates)
for the full specification. Summary:

| Gate | Output on pass | Output on fail |
|------|----------------|----------------|
| 1. Resource budget | "OK disk: 12G, OK mem: 8GB, OK load" | `[SAFETY HALTED] Gate 1 failed: <2GB free` |
| 2. Command risk scan | "OK risk scan: clean" (or "N items need user OK" with list) | Asks user before risky cmd |
| 3. Loop / spend limits | Implicit — limits recorded in `[SAFETY CLEARED]` block | Forces check-in at 30 min / $1 / $5 / $10 |
| 4. Secret / PII scan | "OK secret scan: clean" | Refuses to write/commit the file |
| 5. Scope confirmation | User says "go" | Agent doesn't proceed |

## Never-override hard limits

These 10 limits cannot be raised by the user mid-session, regardless of
urgency, framing, or "just this once" reasoning. They are physical /
security boundaries. Full list in
[`skills/safety-check/SKILL.md#hard-limits-never-override`](../skills/safety-check/SKILL.md).

| # | Limit | Why it cannot be raised |
|---|-------|--------------------------|
| 1 | No `rm -rf` on system paths | Physical data loss |
| 2 | No `dd` to a device, no `mkfs` | Physical device overwrite |
| 3 | No fork bombs | Resource exhaustion DoS |
| 4 | No `curl \| sh` | Remote code execution |
| 5 | No force-push to main/master | History rewrite on protected branch |
| 6 | No `sudo` without per-command OK | Privilege escalation |
| 7 | No publish to npm/pip/cargo without per-command OK | Public registry write |
| 8 | No macOS system file writes | SIP / system integrity |
| 9 | No bypass via env vars / flags | Defense in depth |
| 10 | Stop and ask on any near-miss | Rationalization is a failure mode |

The list is closed. Adding a new hard limit is a MINOR version bump (the
fork can never break compat with this list, only extend it).

## Defense in depth: the `PreToolUse` hook

The recommended second line of defense is a `PreToolUse` hook that blocks
destructive bash at the tool layer. The hook is registered in
`~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "command": "python3 ~/.claude/hooks/safety-guard.py",
            "type": "command"
          }
        ]
      }
    ]
  }
}
```

The hook reads the tool call from stdin as JSON, classifies the `command`
field, and exits:

- **0 (allow)** — normal command
- **0 (allow + stderr warning)** — risky command (git push, sudo, brew install, kill -9, etc.); the agent sees the warning
- **2 (block)** — destructive command (`rm -rf` on system paths, `dd` to device, fork bomb, `curl | sh`, force-push to main/master, publish commands, shutdown, killall system processes); the agent must ask the user to run the command themselves

The hook fails open on a parse error (returns 0) so a hook bug does not
lose the user's work. The reference implementation is in this repo at
`scripts/safety-guard.py` and can be installed with:

```bash
cp scripts/safety-guard.py ~/.claude/hooks/
chmod +x ~/.claude/hooks/safety-guard.py
```

See [`scripts/safety-guard.py`](../scripts/safety-guard.py) for the full
source.

## Red flags the agent must NOT rationalize

These are thoughts the agent might have that mean STOP — you're about to
skip the gate:

| Thought | Why it's a red flag |
|---------|---------------------|
| "This is a simple read / grep" | Even reads can leak secrets. Run the gate. |
| "I already know what to do" | Knowing is not the same as having checked. |
| "We're on a tight schedule" | Urgency framing is exactly when mistakes happen. |
| "The user said go" | "Go" comes after the gate, not before. |
| "I'll just check one thing first" | One thing leads to ten. Run the gate. |
| "It's already in a worktree" | Worktree is not a sandbox for the safety gate. |
| "It's a test fixture" | Tests can still rm-rf, dd, publish. |
| "The previous session passed" | Each session re-runs the gate. State is not preserved. |
| "I'm a subagent" | Subagents run a minimal gate (Gates 1 + 2 + 4). |
| "I'll just disable it for this one" | NEVER. The gate cannot be disabled. |

If the agent has any of these thoughts, it must invoke `safety-check`
before any other action.

## Eval protocol

The safety gate is behavior-shaping content. Changes to the gate require
RED-GREEN-REFACTOR evidence following the upstream
[`superpowers-evals`](https://github.com/prime-radiant-inc/superpowers-evals)
protocol. The full eval protocol is in [`docs/eval-protocol.md`](eval-protocol.md).

Short version:

1. Write 3+ pressure scenarios that demonstrate the failure mode the gate
   is meant to catch. Each scenario goes in
   `tests/evals/scenarios/<gate-name>/<scenario-name>.yaml`.
2. Run the scenarios **without** the new gate. Record the QA agent verdict
   per scenario (RED).
3. Implement the gate.
4. Re-run the scenarios (GREEN).
5. Refactor: find new rationalizations the agent uses to skip the gate,
   plug them, re-run.
6. Attach a summary table to the PR: scenario | RED verdict | GREEN verdict
   | pass / fail / indeterminate.

The eval is expensive (each scenario = one full Claude Code agent run with
real API cost). Don't run it speculatively. Run it once, when the gate is
ready for review.

## Subagent exception

When dispatched as a subagent with an isolated, well-scoped task, the gate
may be reduced to **Gates 1, 2, and 4** only (resource budget, command
risk, secret scan). Gates 3 and 5 (loop / spend limits, scope confirmation)
are the responsibility of the parent agent.

The parent agent must document, in the subagent dispatch prompt, which
gates have been passed. The subagent must verify the documentation before
proceeding.

If the subagent is dispatched without documentation, it must run all 5
gates itself. There is no implicit "the parent already passed" trust.

## Recovery

If something has already gone wrong (process runaway, disk fill, etc.):

1. Stop dispatching new work
2. Identify the runaway (`ps aux | sort -nk 3 | tail`)
3. Kill it (`kill <pid>`, escalate to `kill -9` only with user OK)
4. Clean up artifacts (worktrees, temp files, logs)
5. Report to user with: what happened, what was killed, what is left to clean up

The recovery procedure is in
[`skills/safety-check/SKILL.md#recovery`](../skills/safety-check/SKILL.md).

## Versioning

The safety gate spec is versioned with the fork. Any change to:

- The list of 5 gates
- The list of never-override hard limits
- The `<MANDATORY-SAFETY-GATE>` block in `using-superpowers/SKILL.md`

is a MAJOR version bump if it removes a limit, MINOR if it adds, PATCH
otherwise. See [`CHANGELOG.md`](../CHANGELOG.md) for the version history.
