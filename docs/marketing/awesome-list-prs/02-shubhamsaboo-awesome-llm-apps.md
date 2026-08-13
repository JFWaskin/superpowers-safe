# PR: Shubhamsaboo/awesome-llm-apps

> **Target repo:** https://github.com/Shubhamsaboo/awesome-llm-apps
> **Stars:** ~132k, very high traffic
> **Acceptance criteria:** Repo description says "100+ open-source AI
> agents, agent skills, and RAG apps. Hand-built, tested end-to-end,
> Apache-2.0." Their scope explicitly includes "agent skills" — we
> fit.
> **Status:** FIRE NOW (high-leverage, but only 9 open PRs at last
> check — selective, so a focused pitch matters)

## Why this list

132k stars, "100+ open-source AI agents, agent skills, and RAG apps"
— the term "agent skills" is in their pitch. Our safety-check is
a skill. We're MIT (their stated license is Apache-2.0, but MIT is
similar and they list other licenses). High leverage IF accepted.

## How to submit

1. Go to https://github.com/Shubhamsaboo/awesome-llm-apps
2. Open a PR adding a row to the agent-skills / safety / subagents
   section (or wherever fits their current structure)
3. Their contributing rules (if any) are in the README footer

## PR title

`Add JFWaskin/superpowers-safe (safety-hardened fork of obra/superpowers with 5-gate preflight)`

## PR body

```markdown
### Adding `JFWaskin/superpowers-safe`

A safety-hardened fork of `obra/superpowers` (the popular Claude
Code / Codex skills library) that adds a mandatory 5-gate safety
preflight before any non-trivial task runs. The preflight defends
against destructive bash, runaway subagents, resource exhaustion,
secret leaks, and scope creep.

**Why it belongs here:** the repo's pitch explicitly calls out
"agent skills" as a category. Our safety-check is an agent skill
(plus a `<MANDATORY-SAFETY-GATE>` block in the bootstrap that
enforces it).

**Upstream's position (2026-08-12):** the maintainer of
`obra/superpowers` reviewed this work and redirected to the
standalone-plugin path — i.e. this fork. They explicitly said
"if it earns real adoption that's far stronger evidence than
an interest-check thread."

**Cross-runtime packaging:** Claude Code, Codex, Cursor, Gemini
CLI, Kimi Code, OpenCode, Pi, Hermes, GitHub Copilot CLI,
Factory Droid (10 runtimes).

**Pressure scenarios:** 4 scenarios in Quorum format with
synthetic RED baselines — out-of-cwd `rm -rf`, sudo invocations,
public-registry publish, pipe-to-shell install.

**Defense in depth:** a 13-action campaign record showing that
the skill-level gate (policy) and `nono.sh` (kernel sandbox)
catch disjoint threat surfaces. Together they form defense in
depth; neither alone is sufficient.

**License:** MIT (similar permissive; upstream and our fork
both MIT).

**Maintainer:** @JFWaskin

Repo: https://github.com/JFWaskin/superpowers-safe

— JFWaskin
```

## What to expect

- The list is selective (9 open PRs last check). Maintainer reviews
  most.
- If accepted, this is the highest-leverage of the 4 candidates
  (132k stars).
- If declined, the maintainer may say "doesn't fit" or suggest a
  different list. Don't push back; just move on.

## After acceptance

- Add the list to `docs/marketing/README.md` "Accepted on" log.
- Don't open more PRs in the same week to this repo.
