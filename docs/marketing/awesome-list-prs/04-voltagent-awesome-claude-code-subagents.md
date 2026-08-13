# PR: VoltAgent/awesome-claude-code-subagents — STAGED, category mismatch

> **Target repo:** https://github.com/VoltAgent/awesome-claude-code-subagents
> **Stars:** ~24k
> **Status:** **STAGED — DO NOT FIRE. Category mismatch.**
>
> This list is specifically for **subagent `.md` definition files**
> (per their CONTRIBUTING.md). Our fork ships a **safety skill**
> (which is a different category in the Claude Code ecosystem).
> A PR would likely be closed as off-topic.

## Why this list is a mismatch

Their CONTRIBUTING.md is explicit:

> "Choose the right category - Place your subagent in the most
> appropriate category folder"
>
> "Your agent .md file: Create the actual agent definition
> following the template"

The list collects subagent definitions (`agents/*.md`). Our work
is a safety skill, not a subagent. Even though safety-check is
triggered by the subagent-driven-development workflow, the unit
of contribution is different.

## If you want to fit anyway

Two paths:

1. **Reframe:** a `safety-check` subagent (an actual subagent that
   performs the safety check as an Agent invocation, not as a
   skill). This is plausible but is a new design — separate work.
2. **Skip:** the e2b-dev and Shubhamsaboo PRs are stronger fits
   for what we have. Don't waste review attention on a misfit.

## PR title (if you do fire it, after reframing)

`Add safety-check subagent (5-gate preflight wrapper for superpowers) — refactor of safety-check skill as a subagent definition`

## PR body

**Only fire this if you've actually refactored safety-check to be
a subagent definition (per their template).** Otherwise the PR
will be closed as off-topic.

```markdown
### Adding `safety-check` subagent

A subagent definition that runs the 5-gate safety preflight
before any non-trivial coding task. Wraps the safety-check
skill as an Agent invocation (rather than a Skill invocation),
so the subagent is the unit of safety enforcement.

The preflight defends against: destructive bash, runaway
subagents, resource exhaustion, secret leaks, scope creep.

Categories: safety / preflight

— JFWaskin
```

## After

- If the subagent refactor is done and the PR lands: real win
- If not: skip
