# DRAFT PR Proposal Template — `upstream-rename-watcher`

This template is the output format of `fork/upstream-rename-watcher.py`
when it detects a genuine rename in `obra/superpowers:dev` and the
detection passes the 4 hard constraints (C1–C4) encoded in the script.

The watcher **emits drafts only**. It never calls `gh pr create` and
never opens a PR. A human (JFWaskin) reviews the draft, fills the
required blanks, verifies the "Verification" section by hand, and
posts manually. This is deliberate: auto-posting rename PRs against an
upstream that just closed two of them for the exact class of mistake
this template is designed to prevent is hostile, not helpful.

## When the watcher writes a draft

The watcher writes a draft into `fork/.drafts/draft-<slug>-<sha10>.md`
when:

- Upstream `obra/superpowers:dev` advanced past the last seen SHA.
- A rename was detected (file, directory, or term in a commit message).
- C1 passed: the rename is not in the token-swap red-flag list (e.g.,
  Drill→Quorum would be C1-blocked because Quorum is only part of the
  eval system, not the whole thing).
- C4 passed: no touched path is in `PROTECTED_GLOBS` (fork/,
  safety-check/, dsh-hooks-claude-code/, nono.sh integration,
  deepseek-harness-bridge/).

## When the watcher writes a *findings-only* file (no proposal)

The watcher writes `fork/.drafts/findings-<sha10>.md` instead of a
proposal when:

- A detected rename was C1-blocked (would misdescribe architecture).
- No other renames passed the gates.

The findings file is a follow-up TODO for the human, not a PR
proposal. The doc fix obra wants (a correct description of the
architecture, not a token swap) requires a human to write it.

## Authoring rules (hard)

- **Author**: `JFWaskin <waskin@users.noreply.github.com>` only.
- **No** `Co-Authored-By:` trailer (or any AI attribution) on any
  commit, PR body, GitHub comment, branch description, or other public
  artifact produced from this template. This is a hard rule, not a
  preference.
- **No** "with Claude as drafting partner" prose.
- PR body ends with `— JFWaskin` so attribution is visible at a glance.

## Submitter table (C3) — exact format from obra's PR template

The watcher embeds the **exact** table from
`obra/superpowers/.github/PULL_REQUEST_TEMPLATE.md` → "Who is
submitting this PR?" section. The fields are placeholders; the human
must fill them before posting. The watcher does NOT invent values
(this would be a C2 violation — claiming verification that didn't
happen).

| Field | Value |
|-------|-------|
| Your model + version | `<fill before posting>` |
| Harness + version | `<fill before posting>` |
| All plugins installed | `<fill before posting>` |
| Human partner who reviewed this diff | JFWaskin |

**Note on the table values**: the watcher itself is not a "model" and
not a "harness". If the human who is posting the PR did not use a
model or harness to author the proposal, the honest answer is "none —
drafted by JFWaskin from upstream diff + this script". Fabricating
"Claude 4.5 / Claude Code 2.0" etc. would (a) be a C2 lie and (b)
violate the no-AI-coauthor rule on the underlying commit.

## Verification section (C2)

The watcher's draft body includes a `## Verification (required before
posting)` section that is a **checklist**, not a claim. Every item
is unchecked. The human must check each box, delete the unchecked
lines, and only then post. The items the watcher always lists:

- The branch diff matches upstream `obra/superpowers@<sha10>` (compare
  URL is included).
- Each old→new replacement preserves meaning in context. If a
  replacement would be wrong in a particular context (e.g., a term
  that means something narrower in a different subsystem), the
  replacement was reverted in that location.
- No command in any "Quick Start" or "How to run" section was
  changed. (obra closed #2121 partly because the "fixed" quick start
  still showed stale `uv sync` / `uv run` while the evals repo had
  migrated to Bun/TypeScript. Do not repeat that mistake.)
- No `Co-Authored-By:` trailer, no "with Claude as drafting partner"
  prose, no AI attribution anywhere.

The watcher does NOT claim any of these are done. It only lists them
as the boxes the human must tick.

## C1: token-swap red flags

Currently watched:

- **Drill → Quorum**: Quorum is only PART of the eval system, not the
  whole thing. A blanket Drill→Quorum swap misdescribes the
  architecture. The docs need a correct description, not a token
  swap. (Per obra's #2121 closure.)

If a draft is generated that contains a C1-blocked term, the draft
also includes a `## C1: token-swap findings NOT proposed here`
section listing the blocked renames and their reasons, so the human
can write a proper doc fix instead.

## C4: protected paths

The watcher never proposes renames that touch:

- `fork/` (all of it)
- `fork/deepseek-harness-bridge/`
- `safety-check/`
- `dsh-hooks-claude-code/`
- `nono.sh` (integration rules that part out, per #2111 closure)
- `.git/`, `node_modules/`
- `docs/upstream/`, `docs/marketing/`, `*.md.bak`
- `tests/evals/scenarios/*/story.md`, `setup.sh`, `checks.sh`
- `tests/evals/baselines/`

If upstream renames a file under one of these paths in its own
dev branch, the watcher treats it as out-of-scope: fork-only surface
is the fork's problem, not upstream's, and the watcher must not
propose it.

## Worked example (synthetic — for shape only)

Title: `docs(term): rename Drill to Quorum`  ← **this would be C1-blocked**

If upstream did rename Drill → Quorum and the watcher's C1 gate
didn't catch it, the draft would look like:

```markdown
# DRAFT PR — DO NOT POST AUTOMATICALLY
# Title: docs(term): rename Drill to Quorum
# Generated: 2026-08-15T08:42:27Z
# Upstream range: abcdef1234..1234567890
# Reviewer checklist: see 'Verification' section below.
# Author rule: JFWaskin only. NO Co-Authored-By trailer. NO AI attribution.

---

Mirror of upstream renames in `obra/superpowers` between `abcdef1234`
and `1234567890`.

## Who is submitting this PR? (required)

| Field | Value |
|-------|-------|
| Your model + version | <fill before posting> |
| Harness + version | <fill before posting> |
| All plugins installed | <fill before posting> |
| Human partner who reviewed this diff | JFWaskin |

## Why
… (semantic justification, not just "old name was wrong")

## What changed
| Old | New | Kind | Upstream commit |
|-----|-----|------|-----------------|
| `Drill` | `Quorum` | `term` | `1234567890` |

## What was NOT changed
… (historical files, fork-only paths, code that runs the tool)

## Verification (required before posting)
- [ ] The diff on the branch matches upstream `obra/superpowers@1234567890`
- [ ] Each old→new replacement preserves meaning in context.
- [ ] No command in any 'Quick Start' or 'How to run' section was changed.
- [ ] No `Co-Authored-By:` trailer, no AI attribution anywhere.

## Existing PRs
- [ ] I have reviewed all open AND closed PRs on the fork for duplicates
- Related PRs: #2121 (closed by obra for the exact reasons this template is designed to prevent)

Upstream range: https://github.com/obra/superpowers/compare/abcdef1234...1234567890

— JFWaskin
```

## How the cron uses this

The hourly cron at `upstream-rename-watcher` runs:

```bash
cd /Users/jonathanwaskin/code/superpowers-safe
python3 fork/upstream-rename-watcher.py --dry-run
```

…to inspect what the script would detect, then on a real run emits
drafts to `fork/.drafts/`. The cron reports back what was found and
which drafts were written. It never posts to `obra/superpowers`.

— JFWaskin
