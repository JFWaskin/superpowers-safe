# PR: hesreallyhim/awesome-claude-code — STAGED, do not fire yet

> **Target repo:** https://github.com/hesreallyhim/awesome-claude-code
> **Stars:** ~52k
> **Status:** **STAGED — DO NOT FIRE until 2026-08-22+**
>
> Their contributing rules are explicit:
>
> > "Any resource that is recommended must either:
> > (i) Be at least 14 days old (14 days since first commit on default
> >     branch) AND show signs of active development
> > OR
> > (ii) Have at least 100 stars."
>
> As of 2026-08-13, the fork is **5 days old with 1 star**. PR will
> be auto-closed. Wait until **2026-08-22** (14 days from first
> commit) OR until 100 stars, whichever comes first.

## When to fire

- **Earliest:** 2026-08-22 (14 days from initial commit)
- **Preferred:** once the fork has 100+ stars (likely a few weeks
  in, given current adoption)

To check: `gh api repos/JFWaskin/superpowers-safe --jq
'{age_days: ((now - fromisoformat(created_at)).days), stars:
.stargazers_count}'`

## Why this list (when ready)

52k stars, canonical Claude Code list, "scintillating" /
"ambidextrous" / "top tier" tone. Maintainer is selective on
originality and quality. This is the right list eventually — the
bar is just high.

## PR title

`Add JFWaskin/superpowers-safe (safety-hardened fork of obra/superpowers)`

## PR body

```markdown
### Adding `JFWaskin/superpowers-safe`

A safety-hardened fork of `obra/superpowers` — the popular Claude
Code skills library — that adds a mandatory 5-gate safety
preflight before any non-trivial task. The preflight defends
against destructive bash, runaway subagents, resource
exhaustion, secret leaks, and scope creep.

**Upstream's position (2026-08-12):** the maintainer of
`obra/superpowers` reviewed this work and redirected to the
standalone-plugin path — i.e. this fork. Adoption, not upstream
blessing, is the metric that matters now.

**Cross-runtime packaging:** Claude Code, Codex, Cursor, Gemini
CLI, Kimi Code, OpenCode, Pi, Hermes, GitHub Copilot CLI,
Factory Droid (10 runtimes).

**Pressure scenarios:** 4 scenarios in Quorum format
(`tests/evals/scenarios/`) with synthetic RED baselines
(`tests/evals/baselines/`) — out-of-cwd `rm -rf`, sudo invocations,
public-registry publish, pipe-to-shell install.

**Defense in depth:** a 13-action campaign record
(`docs/experiments/dual-layer-protection.md`) showing that the
skill-level gate (policy) and `nono.sh` (kernel sandbox) catch
disjoint threat surfaces.

**License:** MIT (inherited from upstream)

**Maintainer:** @JFWaskin

Repo: https://github.com/JFWaskin/superpowers-safe

— JFWaskin
```

## What to expect

- The maintainer enforces 14-day OR 100-star rules strictly.
  A pre-mature PR is auto-closed.
- After the rule is satisfied, expect a high bar: they value
  originality, code quality, and active development.
- Their tone is friendly but specific in the rejection criteria.
  Don't argue; just wait.
