# PR: VoltAgent/awesome-claude-code-subagents — FIRED

> **Target repo:** https://github.com/VoltAgent/awesome-claude-code-subagents
> **PR:** https://github.com/VoltAgent/awesome-claude-code-subagents/pull/309
> **Fork:** https://github.com/JFWaskin/awesome-claude-code-subagents
> **Branch on this fork:** `feat/safety-check-subagent`
> **Stars:** ~24k
> **Status:** **FIRED — PR open (#309).**
>
> Reframed safety-check as a subagent `.md` definition (per the
> upstream template), filed the PR with category `04-quality-security`,
> and bumped the category + marketplace versions. Track the PR and
> follow-up notes below.

## What changed since the original "STAGED" decision

The original draft marked this list as STAGED with a category
mismatch: the list collects subagent `.md` definitions, and we were
shipping a safety **skill** (a different unit). The chosen path was
to refactor first, then PR.

The refactor is done. `fork/safety-check.md` now ships
as a sibling to the original `skills/safety-check/SKILL.md`, written
to the standard subagent template (frontmatter + When invoked + Gate
checklists + Communication Protocol + Development Workflow + Hard
Limits + Defense in Depth + Integration). Both artifacts share the
same 5 gates and hard limits; the subagent variant is for callers
who prefer Agent invocations (with isolated context and tool scoping)
over Skill invocations.

Branch on this fork: `feat/safety-check-subagent`
Commit: see `git log feat/safety-check-subagent -1`

## Original rationale (kept for history)

The list collects subagent definitions. The original work was a
safety skill — a different unit. The pragmatic path was to refactor
first, then submit.

Their CONTRIBUTING.md is explicit:

> "Choose the right category - Place your subagent in the most
> appropriate category folder"
>
> "Your agent .md file: Create the actual agent definition
> following the template"

## Why category `04-quality-security`

`04-quality-security` is the natural home:

- The subagent runs a safety preflight — destructive-bash detection,
  secret/PII scan, spend + loop limits, scope confirmation.
- The existing agents in this category are mostly **post-hoc** (code
  review, security audit, penetration test). `safety-check` is the
  only subagent that runs **before** the work, and pairs the
  reasoning-layer check with a capability-layer sandbox for defense
  in depth.
- We explicitly did **not** name any commercial substrate in the
  subagent body. The "Defense in Depth" section describes substrate
  classes generically, matching the upstream maintainers' vendor-
  neutrality rule.

## PR title (as filed)

`Add safety-check subagent (5-gate preflight wrapper for superpowers)`

## PR body (as filed)

```markdown
### Adding `safety-check` subagent

A subagent definition that runs a mandatory 5-gate safety preflight
before any non-trivial work. It checks resource budget, scans planned
commands for destructive patterns, enforces loop and spend limits,
scans files for secrets and PII, and confirms scope with the human.
The subagent refuses to proceed if any gate fails and emits a
structured `[SAFETY CLEARED]` or `[SAFETY HALTED]` block the parent
can parse.

This is the upstream-friendly subagent form of a safety preflight
pattern. The same 5 gates also exist as a Skill definition in a
separate fork; the version here is rewritten to the standard
subagent template (frontmatter + When invoked + Gate checklists +
Communication Protocol + Development Workflow + Hard Limits +
Defense in Depth + Integration), so anyone can adopt it without
that fork.

**Category:** `04-quality-security`
**What it defends against:** destructive bash, runaway subagent loops,
resource exhaustion, secret leaks, scope creep, untracked spend,
pipe-to-shell, force-pushes to protected branches.
**Tools used:** `Bash, Read, Grep, Glob` (no Write/Edit — the
subagent is a preflight, not a worker).
**Model:** `inherit`.
**Honesty note:** the subagent body is self-contained and
vendor-neutral. It does not name any specific commercial substrate;
the "Defense in Depth" section describes substrate classes
generically.

#### Updates in this PR

- New: `categories/04-quality-security/safety-check.md`
- `categories/04-quality-security/README.md`: added to Available
  Subagents (alphabetical), Quick Selection Guide, and the Security
  Assessment pattern (where it appears as the first gate, before
  the auditors)
- `categories/04-quality-security/.claude-plugin/plugin.json`:
  registered the agent and bumped version `1.1.1` → `1.1.2`
- `.claude-plugin/marketplace.json`: bumped the `voltagent-qa-sec`
  plugin entry to `1.1.2` to match
- `README.md`: added the entry to the main Quality & Security
  listing in alphabetical order

#### Why a preflight subagent belongs in this collection

Existing agents in this category are post-hoc: they review code, find
vulnerabilities, audit access, run penetration tests. `safety-check`
is the only subagent that runs *before* the work — it halts
destructive or runaway operations before they start, and pairs the
reasoning-layer check with a capability-layer sandbox for defense
in depth. The two layers catch different failure modes; together
they form a sturdier default than either alone.

— JFWaskin
```

## What to expect

- Maintainers care about: vendor neutrality, plugin-version bumps,
  alphabetical ordering, no obvious "promote my project" framing.
  The PR body addresses all four up front.
- Risk: a maintainer closes it for being out of scope. Defense: the
  subagent is self-contained and useful without the rest of the
  fork; the body does not link to or pitch the fork.
- If they ask for changes: probably the description length, or
  trimming the "Honesty note" section.

## After

- Update the per-list index in `awesome-list-pr.md` (if one exists)
  to flip the status from STAGED to FIRED + link the PR.
- If accepted: real win, 24k-star repo with direct subagent fit.
- If rejected: a "rationale rejected" issue note for future
  reference; do not re-submit without a structural change.

## Iteration log

- **Iteration 1 (initial PR):** opened #309 with the subagent body
  byte-identical to the fork copy. Bumped `voltagent-qa-sec` 1.1.1 →
  1.1.2 in both the category plugin manifest and the top-level
  marketplace manifest. Updated main README, category README
  (Available Subagents, Quick Selection Guide, Security Assessment
  pattern).
- **Iteration 2 (PR #309, follow-up commit):** trimmed the
  frontmatter description from ~480 chars to ~415 chars (peer
  average is ~280; the 5-gate list is the unique value prop and
  worth keeping). Removed the "Ralph-style" mention in two places
  and replaced with the generic "self-iteration loop" — the upstream
  maintainers' "stay vendor-neutral" rule applied more strictly than
  the first pass. No version bump needed (this is a content
  refinement, not a new agent).
- **Iteration 2 (superpowers-safe, this branch):** added a
  `See also` cross-link between the canonical skill form
  (`skills/safety-check/SKILL.md`) and the subagent form
  (`fork/safety-check.md`) so future maintainers and reviewers can
  find the sibling without grep'ing for the path. The two forms
  share gates, hard limits, and the substrate table; they differ
  only in invocation surface and tool scoping.

The fork copy of the subagent intentionally diverges from the
upstream PR copy on two points: (1) the upstream copy has the
shorter description, and (2) the upstream copy drops the
"Ralph-style" product mention. These are deliberate concessions to
the upstream maintainers' rules and do not affect the fork's
local-fidelity.
