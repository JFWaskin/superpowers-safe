---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<MANDATORY-SAFETY-GATE>
**Before invoking ANY other superpowers skill — including brainstorming, subagent-driven-development, executing-plans, dispatching-parallel-agents, writing-plans, test-driven-development, systematic-debugging, finishing-a-development-branch, using-git-worktrees, requesting-code-review, receiving-code-review, verification-before-completion, or any task that runs Bash / writes files / dispatches subagents / runs builds / makes network calls / runs autonomously for more than 5 minutes — you MUST first invoke the `safety-check` skill.**

The `safety-check` skill enforces five hard gates (resource budget, command risk scan, loop / spend limits, secret / PII scan, scope confirmation) and a never-override list of destructive operations: no `rm -rf` on system paths, no `dd` to a device, no `mkfs` / `diskutil eraseDisk`, no fork bombs, no `curl | sh` / `wget | bash`, no `git push --force` to `main` / `master`, no `chmod -R 777 /` / `chown -R root /`, no `sudo` without per-command user OK, no `npm publish` / `pip upload` / `cargo publish` without explicit user OK, no writes to macOS system paths (`/System`, `/Library`, `/private`, `~/Library`), no shutdown / kill of system processes.

Skipping `safety-check` on a non-trivial task is a hard failure of this skill. Skipping it because "this is simple", "I already know what to do", or "we're on a tight schedule" is a red flag — see the red-flag table below. The user is the final safety authority; if in doubt, ask.

**Subagent exception:** If you were dispatched as a subagent with an isolated, well-scoped task and the parent agent already passed the gate, the gate may be minimal (Gates 1 + 2 + 4 only) — but it must still run before any destructive operation.

**Defense in depth:** The skill-level gate is the first line. A `PreToolUse` hook that blocks destructive bash at the tool layer is the second line. See `docs/safety-gate.md` for the recommended hook pattern.
</MANDATORY-SAFETY-GATE>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming skill first.

Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

## Skill Priority

When multiple skills apply, process skills come first — they set the approach, then implementation skills (frontend-design, etc.) carry it out. Brainstorming and systematic-debugging are Superpowers' most common process skills, but the rule holds for any of them.

- "Let's build X" → superpowers:brainstorming first, then implementation skills.
- "Fix this bug" → superpowers:systematic-debugging first, then domain skills.

## Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`
- Hermes Agent: `references/hermes-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.
