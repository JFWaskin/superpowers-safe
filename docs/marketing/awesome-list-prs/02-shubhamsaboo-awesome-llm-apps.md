---
target_repo: Shubhamsaboo/awesome-llm-apps
pr_url: https://github.com/Shubhamsaboo/awesome-llm-apps/pull/1081
status: closed
closed_on: 2026-08-16
closed_reason: link-only README additions are declined
researched: 2026-08-16
research_file: 02-self-contained-research.md
---

# PR: Shubhamsaboo/awesome-llm-apps — CLOSED

> **Target repo:** https://github.com/Shubhamsaboo/awesome-llm-apps
> **Stars:** ~132k, very high traffic
> **Acceptance criteria:** Repo description says "100+ open-source AI
> agents, agent skills, and RAG apps. Hand-built, tested end-to-end,
> Apache-2.0." Their scope explicitly includes "agent skills" — we
> fit on topic, but the maintainer enforces a "no link-only README
> additions" rule (see closure analysis below).
> **Status:** **CLOSED 2026-08-16** by maintainer @Shubhamsaboo. Link-only
> README additions are declined. Acknowledgement comment drafted at
> `02-acknowledgement-draft.md` (NOT posted — user reviews and posts).

## Closure analysis

- **Closed:** 2026-08-16, ~6 hours after PR opened.
- **Reason (maintainer's words):** "This PR only adds a README
  bullet linking to an external fork, with no runnable code added
  in its own folder here. Link-only README additions are declined
  as a rule."
- **What was learned:** awesome-list repos with a curated-examples
  policy (i.e. a list that curates and hosts the examples itself)
  will not accept link-only PRs, even when the topic is squarely
  in-scope. This is a meaningful constraint on the
  "fire-and-forget awesome-list placement" strategy: for any
  curated-host list, the contribution unit is a self-contained
  folder in the awesome-list repo, not a pointer to an external
  repo.

### Cross-link: other awesome-list targets and their rules

- `01-e2b-dev-awesome-ai-agents.md` (e2b-dev/awesome-ai-agents,
  29k stars) — categorizes entries under headings like "Coding
  Agents" and "Agent Tooling"; the README has no explicit
  link-only rule visible, so a link-only PR may be acceptable
  there. Untested; treat as an open question until/unless
  e2b-dev declines the same way.
- `04-voltagent-awesome-claude-code-subagents.md`
  (VoltAgent/awesome-claude-code-subagents, 24k stars) — collects
  **subagent `.md` definition files** in folders; the unit of
  contribution is a self-contained file in the awesome-list repo
  (their `agents/<name>.md` template), not a link. That is a
  stricter version of the same curated-host policy
  Shubhamsaboo enforces. Staged, do-not-fire per its draft.
- `03-hesreallyhim-awesome-claude-code.md`
  (hesreallyhim/awesome-claude-code, 52k stars) — gated by the
  14-day-or-100-stars rule, not by a curated-host rule. Different
  shape of barrier.

The "curated host" pattern (Shubhamsaboo, VoltAgent) is a
meaningful signal: awesome-lists that host the artifacts they
showcase will not accept link-only PRs, regardless of topical
fit. Awesome-lists that are pure-link indexes (e.g. the classic
`awesome-*` lists with bulleted links to external repos) remain
link-friendly.

## Self-contained example path (assessment)

Shubhamsaboo offered: "If you would like to add a self-contained,
runnable example in its own folder in this repo, please open a new
PR." A comprehensive research assessment of what that actually
requires is in
[`02-self-contained-research.md`](02-self-contained-research.md).
The summary below is the headline; the research file is the
detailed input.

**The prior assessment (a 50-line demo, lean against) was wrong
in two ways.** With the actual repo requirements, the build is
bigger (a full agentskills.io-compliant skill, not a demo) and
the fit is better (the Agent Skills section is the exact right
category, with `npx skills add` as the natural install path).

### Key facts the research established

- The `agent_skills/` section has an **explicit contribution
  bar**: real scripts, researched references, evidence over
  vibes, local/private by default, tested before shipped. A
  link-only PR satisfies none of those.
- Required folder shape: `agent_skills/<name>/` with `SKILL.md`
  (agentskills.io frontmatter), `README.md`, `scripts/`,
  `references/`, plus `agent_skills/evals/<name>/test_*.py`.
- The exemplar `SKILL.md` declares `license: Apache-2.0`. Our
  fork is MIT — would need to dual-license the new code under
  MIT + Apache-2.0 before landing here.
- The "↗ external" link-only pattern that appears elsewhere in
  the README is **not** used in the `agent_skills/` section. PR
  #1070 (Pentest AI Agents) attempted exactly that and was
  closed on 2026-08-09, same pattern as our PR #1081.
- Self-contained additions do get merged: PR #1088 and PR #1095
  were merged within 1–2 days of submission. The maintainer's
  review cadence for substantive work is fast.

### Revised cost/benefit (full numbers in the research file)

- **Cost:** 2–3 days of careful work, not ½ day. SKILL.md +
  references are the heaviest items. Plus 1 round of review
  iteration (~1–3 days). Plus an ongoing sync burden — every
  safety-check update in `superpowers-safe` would need a
  corresponding sync to the awesome-llm-apps copy, or the eval
  will rot.
- **Benefit:** A real placement in the **exact** right section
  (Agent Skills), with `npx skills add` as the natural install
  path, 132k stars, the right audience (Claude Code / Codex /
  Cursor users), and "actually runs + has an eval" credibility.

### Revised recommendation

**Feasible but expensive.** Three options for the user:

1. **Skip.** The placement isn't worth a multi-day build +
   ongoing sync. Reallocate to other targets (e2b-dev,
   hesreallyhim, VoltAgent). The conservative move.
2. **Pursue.** Commit to the 2–3 day build + the maintenance
   burden. Build the skill locally first; the user reviews and
   then opens the new PR.
3. **Partial.** Ship the `scripts/preflight.py` standalone
   implementation inside
   `JFWaskin/superpowers-safe/docs/examples/` (or
   `examples/`), where maintenance is zero. Skip the
   awesome-llm-apps PR. This gets 80% of the credibility benefit
   at 20% of the cost.

The user's call. The research is the input; the decision is not
mine. Opening any new PR is on the user, not on this draft.

## Pre-closure draft (archived)

The original title and PR body from before the closure are
preserved below for reference. They are not the right shape for a
re-fire under the curated-host rule (they would need a
self-contained folder, not a link); kept for historical context.

### PR title (archived)

`Add JFWaskin/superpowers-safe (safety-hardened fork of obra/superpowers with 5-gate preflight)`

### PR body (archived)

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

## After-action notes

- The acknowledgement comment draft at
  `02-acknowledgement-draft.md` is ready for user review. Posting
  is on the user; do not auto-post.
- No new PR is opened under this draft. The
  "self-contained example" path requires a user decision.
- The pure-link variant of this PR is dead; do not re-open it.
