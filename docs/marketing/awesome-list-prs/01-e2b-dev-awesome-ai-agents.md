# PR: e2b-dev/awesome-ai-agents

> **Target repo:** https://github.com/e2b-dev/awesome-ai-agents
> **Stars:** ~29k, active
> **Acceptance criteria:** None stated; the repo accepts general AI agent projects
> **Status:** FIRE NOW (this is one of the 2 that will likely land)

## Why this list

29k stars, "Awesome AI Agents" — broadest of the 4 candidates. AI agent
safety is squarely on-topic. They list actual software projects under
categories; the closest fit for us is "Coding Agents" or "Agent
Tooling".

## How to submit

1. Go to https://github.com/e2b-dev/awesome-ai-agents
2. Open a PR adding a bullet under the most appropriate section
3. The PR can be from any fork/branch; the canonical README gets
   updated by maintainers

## PR title

`Add JFWaskin/superpowers-safe (safety-hardened fork of obra/superpowers with mandatory 5-gate preflight)`

## PR body

```markdown
### Adding `JFWaskin/superpowers-safe`

- **Repo:** https://github.com/JFWaskin/superpowers-safe
- **What it is:** A safety-hardened fork of `obra/superpowers` (the
  popular Claude Code / Codex / Gemini skills library). Adds a
  mandatory 5-gate safety preflight that runs before any non-trivial
  skill: resource budget, command risk scan, loop / spend limits,
  secret / PII scan, scope confirmation. Defends against destructive
  bash, runaway subagents, resource exhaustion, secret leaks, and
  scope creep.
- **Why it belongs here:** the upstream `obra/superpowers` is one of
  the most-used Claude Code skill libraries; this fork addresses the
  most common failure mode (long-running autonomous work with full
  Bash access) with a preflight the agent literally cannot skip. The
  fork is byte-identical to upstream on skills, plus one new
  `safety-check` skill.
- **Upstream's position (2026-08-12):** the maintainer of
  `obra/superpowers` reviewed the proposal
  ([#2111](https://github.com/obra/superpowers/issues/2111)) and
  redirected to the standalone-plugin path — i.e. this fork. They
  explicitly said the three CLAUDE.md rules apply (zero-dep,
  fork-derived features don't go upstream, opt-in plugins) and
  that "if it earns real adoption that's far stronger evidence
  than an interest-check thread."
- **Cross-runtime packaging:** Claude Code, Codex, Cursor, Gemini
  CLI, Kimi Code, OpenCode, Pi, Hermes, GitHub Copilot CLI,
  Factory Droid (10 runtimes).
- **Pressure scenarios:** 4 scenarios in Quorum format
  (`tests/evals/scenarios/`) with synthetic RED baselines
  (`tests/evals/baselines/`) — out-of-cwd `rm -rf`, sudo invocations,
  public-registry publish, pipe-to-shell install.
- **Defense in depth:** a 13-action campaign record
  (`docs/experiments/dual-layer-protection.md`) showing that the
  skill-level gate (policy) and `nono.sh` (kernel-level sandbox)
  catch **disjoint** threat surfaces — together they form
  defense in depth; neither alone is sufficient.
- **Stars / activity:** <fill in> stars, latest release v6.3.0,
  actively maintained, CI green on 4 runtimes.
- **License:** MIT
- **Maintainer:** @JFWaskin

— JFWaskin
```

## What to expect

- Their PR review cadence varies. Could be 1 day, could be 1 month.
- The list is a curated one; expect a quick accept or a request for
  a category move.
- If accepted, this is high-leverage: 29k stars, AI-agent audience.

## After acceptance

- Add the list to `docs/marketing/README.md` "Accepted on" log.
- Don't open more PRs in the same week to this repo (spam rules).
