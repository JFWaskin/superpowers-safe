# Show HN draft

> **Show HN is high-leverage but high-stakes.** A bad post gets ignored or
> dunked on. A good post can drive 500+ stars in 24 hours. Read the
> [Show HN guidelines](https://news.ycombinator.com/showhn.html) before
> posting.

## When to post

- **Tuesday–Thursday, 8–10am US Pacific.** Worst time: Friday after 5pm
  and weekends.
- Don't post on a holiday week.
- Post ONCE. If it doesn't take off, don't repost — engage in the
  comments instead.

## Title (≤80 chars)

**Show HN: superpowers-safe – mandatory 5-gate safety preflight for AI coding agents**

Alternatives:
- **Show HN: superpowers-safe – Superpowers skills with a hard safety preflight before any task**
- **Show HN: superpowers-safe – Drop-in safety layer for Claude Code / Codex / Gemini agents**

## Post body

```text
I maintain a fork of obra/superpowers (the popular Claude Code / Codex
skills library) that adds a mandatory safety preflight before any
non-trivial work runs.

The preflight is 5 hard gates:
  1. Resource budget   (disk ≥ 2GB, RAM ≥ 1GB, load < 2× cores)
  2. Command risk scan (refuses rm -rf on system paths, dd, fork bombs,
                         curl|sh, force-push to main, publish commands,
                         sudo without per-command OK)
  3. Loop / spend limits (max 3 concurrent subagents, 30-min check-in,
                          $1/$5/$10 spend thresholds, ralph-loop guard)
  4. Secret / PII scan (pre-write scan for .env, *.key, id_rsa*, *.pem,
                        sk-…, ghp_…)
  5. Scope confirmation (one-line plan + explicit "go" before non-trivial)

The skill-level gate is enforced by a <MANDATORY-SAFETY-GATE> block at
the top of skills/using-superpowers/SKILL.md. The agent literally
cannot start a non-trivial task without passing the gate — including
subagents dispatched in the middle of work. The recommended second line
is a PreToolUse hook that blocks destructive bash at the tool layer.

The skills library itself is byte-identical to upstream; only the
gating and one new "safety-check" skill are added. It works on
Claude Code, Codex, Cursor, Gemini CLI, Kimi Code, OpenCode, Pi,
Hermes, GitHub Copilot CLI, and Factory Droid.

The fork: https://github.com/JFWaskin/superpowers-safe

Safety-gate spec: https://github.com/JFWaskin/superpowers-safe/blob/dev/docs/safety-gate.md

I'm curious:
  - Is the "mandatory in-skill" model the right shape, or should this
    be a hook-only layer?
  - Are the 5 gates the right gates? Missing any?
  - What would make you actually adopt a hard preflight over a soft one?

— Jonathan
```

## What to expect in comments

- **The good:** "I wish I'd had this when Claude deleted my entire
  monorepo last week." — these are your future users.
- **The bad:** "Why not just use a hook?" — answer with the in-skill
  enforcement angle.
- **The harsh:** "This won't actually stop a determined prompt
  injection." — agree, link to `docs/safety-gate.md` which says
  exactly that.
- **The technical:** pressure-test questions about specific gates.
  Have `docs/safety-gate.md` open in a tab.

## After the post

- Reply to every comment within the first 2 hours. After that, once an
  hour is fine.
- Don't argue. Don't shill. Answer questions and let the work speak.
- If someone files an issue, link to it from the comment thread so
  the bug is visible.

## What NOT to do

- Don't cross-post to Reddit on the same day. Pick one.
- Don't have friends register HN accounts to upvote. HN can tell.
- Don't edit the post to add a "thanks for the gold!" — it looks bad.
