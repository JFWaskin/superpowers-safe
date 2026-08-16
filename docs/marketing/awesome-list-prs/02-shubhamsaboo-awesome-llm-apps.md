---
target_repo: Shubhamsaboo/awesome-llm-apps
pr_url: https://github.com/Shubhamsaboo/awesome-llm-apps/pull/1081
status: closed
closed_on: 2026-08-16
closed_reason: link-only README additions are declined
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
PR." Below is a feasibility note. The user has the final call —
this is a judgment, not a refusal.

### What it would look like (concretely)

A new folder in
`Shubhamsaboo/awesome-llm-apps`:

```
awesome_llm_apps/agent_skills/superpowers_safe/
├── README.md
├── safety_preflight_demo.py     # ~50–100 lines
└── requirements.txt
```

- `safety_preflight_demo.py` — a minimal runnable script that
  imports the safety-check 5-gate preflight from
  `superpowers_safe/skills/safety_check/` and runs the gates
  against a sample destructive command (e.g. an out-of-cwd
  `rm -rf` and a sudo invocation). Demonstrates the gate output
  (which gate fired, what it blocked, what the user prompt would
  be) without requiring the full `obra/superpowers` skill runtime
  to be installed. Possibly stand on its own by inlining the
  gate logic into the script, with attribution.
- `README.md` — explains the pattern (5-gate preflight,
  defense-in-depth with `nono.sh`, cross-runtime packaging),
  with a "How to run" section and a pointer back to
  `JFWaskin/superpowers-safe` for the full plugin.
- `requirements.txt` — empty or near-empty (the safety-check
  gates are stdlib + subprocess, no third-party deps).

### Cost

- ~½ day of real work: 1–2 hours to write the demo script and
  README, 1–2 hours to iterate on review feedback from
  @Shubhamsaboo.
- Ongoing maintenance burden: Shubhamsaboo's repo is fast-moving
  (high traffic, frequent PRs). A PR in their tree can rot in
  weeks if their structure changes, their example categories
  reorganize, or their safety-themed section moves.
- Review attention spent that does not directly improve
  `superpowers-safe` itself.

### Benefit

- A curated placement in one of the most-trafficked LLM-app
  awesome lists (132k stars), with "actually runs" credibility
  rather than just a link.
- A demonstration artifact that could be reused in
  `JFWaskin/superpowers-safe/docs/examples/` and on the x-thread /
  show-hn drafts as a concrete runnable demo.

### Recommendation

**Lean against** pursuing this path. The "self-contained example
in someone else's awesome list" is a strange artifact:
`awesome-llm-apps` is a showcase of LLM apps, and a safety-check
preflight is not really an LLM app. It is a safety layer for an
LLM-app development workflow. A demo of the safety layer is more
naturally at home in `JFWaskin/superpowers-safe`'s own `docs/` or
`examples/` folder, where the maintenance cost is zero and the
audience (existing and prospective users of the fork) is the
right one.

Reallocating the ~½ day to other awesome-list targets is
strictly better use of attention:

- `e2b-dev/awesome-ai-agents` (unblock the FIRE NOW PR if it is
  still open) — pure-link index, no curated-host rule.
- `VoltAgent/awesome-claude-code-subagents` follow-up — only
  if a real subagent refactor of safety-check is done (separate
  work; see that draft's "If you want to fit anyway" section).
- `hesreallyhim/awesome-claude-code` — eligible from
  **2026-08-22** or 100 stars, whichever first.

This is a judgment call, not a refusal. If the user wants the
132k-star placement and is willing to absorb the maintenance
burden, the path is open; opening the new PR is on the user,
not this draft.

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
