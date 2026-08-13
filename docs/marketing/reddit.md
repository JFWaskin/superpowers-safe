# Reddit drafts

> Each subreddit has its own culture. Read the top posts of the last
> month before posting anywhere. The drafts below are starting points;
> tune them to the vibe of the specific sub.

## Where to post

In rough order:

1. **r/ClaudeAI** — primary audience, very engaged
2. **r/LocalLLaMA** — high traffic, but more about local models; mention only the cross-runtime angle
3. **r/ClaudeCode** (if it exists) — niche, but exact audience
4. **r/programming** — high bar, only if you can frame it as a generic safety pattern, not "look at my repo"
5. **r/MachineLearning** — research angle: "we built a mandatory preflight for AI coding agents, here's the eval protocol"
6. **r/sysadmin** / **r/devops** — "defends against destructive bash" angle
7. **r/opensource** — project announcement, brief

Do **not** post to all of these in one day. Pick 1–2 per week.

---

## r/ClaudeAI draft

**Title:** I built a mandatory 5-gate safety preflight for Claude Code (fork of obra/superpowers) — upstream confirmed the standalone-plugin path

**Body:**

```text
Update: the maintainer of obra/superpowers reviewed this proposal
(#2111) and redirected to the standalone-plugin path — i.e. this
fork. They explicitly said the three CLAUDE.md rules (zero-dep,
fork-derived features don't go upstream, opt-in plugins) apply, and
that "if it earns real adoption that's far stronger evidence than
an interest-check thread." So the fork is the answer now, not a
stopgap.

Original post: I've been using obra/superpowers heavily and got
nervous when I saw `subagent-driven-development` running for an
hour with full Bash access. So I forked it and added a mandatory
preflight.

The preflight runs before any non-trivial skill (including
subagents dispatched mid-work) and refuses to start work if any of
these 5 gates fail:

1. Resource budget (disk, RAM, load)
2. Command risk scan (rm -rf on /, dd, fork bombs, curl|sh, etc.)
3. Loop / spend limits (max concurrent subagents, time check-ins,
   $ thresholds, ralph-loop guard)
4. Secret / PII scan (.env, *.key, id_rsa*, tokens)
5. Scope confirmation (one-line plan + explicit "go")

The gate is enforced by a `<MANDATORY-SAFETY-GATE>` block in
`using-superpowers/SKILL.md`, not by a hook the agent can ignore.

Since the original draft, the fork has also grown:

- 4 pressure-test scenarios in Quorum format
  (`tests/evals/scenarios/`), each with a synthetic RED baseline
  in `tests/evals/baselines/`. The Quorum format is yaml + story
  + setup + checks — same structure upstream uses for their own
  eval scenarios.
- A dual-layer campaign record
  (`docs/experiments/dual-layer-protection.md`): 13-action test
  showing that `safety-check` (policy) and `nono.sh` (kernel
  capability sandbox) catch disjoint threat surfaces. Together
  they form defense in depth; neither alone is sufficient.

Repo: https://github.com/JFWaskin/superpowers-safe
Spec: https://github.com/JFWaskin/superpowers-safe/blob/dev/docs/safety-gate.md

What I'd love from you:
  - Pressure-test scenarios I haven't covered
  - Gates that should never be overridable (already have 10; want more)
  - Use cases where this would get in the way (I want to know the
    failure modes before they happen to me)
```

---

## r/LocalLLaMA draft

**Title:** A cross-runtime safety preflight for AI coding agents (Claude Code, Codex, Cursor, Gemini CLI, Kimi, OpenCode, …)

**Body:** (focus on the cross-runtime packaging — the local-LLM crowd
cares about portable infrastructure)

```text
Sharing a fork of obra/superpowers that adds a mandatory 5-gate
safety preflight before any non-trivial task. The interesting thing
for this sub is that it's not tied to Claude Code — the same
plugin runs on Codex, Cursor, Gemini CLI, Kimi Code, OpenCode, Pi,
Hermes, and Factory Droid.

The preflight is enforced in-skill (not via a host hook), so the
sandbox is the agent's own reasoning, not the runtime's. This
matters when you're running agents on a beefy local box with full
network access and want a "no, don't do that" before the agent
tries to `rm -rf` the wrong directory.

Repo: https://github.com/JFWaskin/superpowers-safe
Spec: https://github.com/JFWaskin/superpowers-safe/blob/dev/docs/safety-gate.md

The eval protocol doc spells out what evidence a gate change has
to come with (RED-GREEN-REFACTOR with 3+ pressure scenarios). If
you run your own evals, I'd love feedback.
```

---

## r/MachineLearning draft (research angle)

**Title:** [P] A mandatory 5-gate preflight for AI coding agents, with a RED-GREEN-REFACTOR eval protocol for safety changes

**Body:** (frame as a methodology, not a product)

```text
We forked obra/superpowers to add a mandatory safety preflight
before any non-trivial coding task. The interesting part is the
methodology: any change to a safety gate has to come with
RED-GREEN-REFACTOR evidence — at least 3 pressure-test scenarios
run against a behavioral eval harness — before it can ship.

The 5 gates are: resource budget, command risk scan, loop / spend
limits, secret scan, scope confirmation. The never-override list
includes 10 destructive operations (rm -rf on system paths, dd,
mkfs, fork bombs, curl|sh, force-push to main, sudo without
per-command OK, package publish without explicit OK, macOS system
file writes, system process kill).

Repo + eval protocol:
https://github.com/JFWaskin/superpowers-safe
https://github.com/JFWaskin/superpowers-safe/blob/dev/docs/eval-protocol.md

Curious how this compares to the "guardrails" literature — Anthropic's
Constitutional AI, RLHF, output classifiers. My read is that this
is a complementary layer: it shapes the agent's plan, not its
output. But I'd love to be told I'm wrong.
```

---

## What to do after posting

- Reply to every top-level comment within 1 hour for the first 4
  hours, then every few hours for 24 hours.
- If a comment turns into a long discussion, write a follow-up
  comment that summarizes the discussion and links to a doc /
  issue you opened as a result.
- Don't argue with low-effort critics. Reply once politely, then
  stop.

## What NOT to do

- Don't post "Update: thanks for the support!" — Reddit hates that.
- Don't mass-DM people who commented.
- Don't use a brand-new account. Use your main.
