# Contributing to superpowers-safe

Thanks for considering a contribution. This fork follows a stricter bar than
upstream Superpowers in some areas and a more relaxed bar in others, because
we carry the upstream library and add one non-trivial addition (the
mandatory safety preflight). Read this whole document before opening a PR.

## TL;DR

1. Sync from `upstream/dev` first (run `./scripts/sync-upstream.sh`)
2. Branch off `dev`, target `dev` in the PR
3. Safety-gate changes need RED-GREEN-REFACTOR evidence (3+ pressure scenarios
   run with the Quorum eval harness)
4. Skill content changes need an upstream issue/PR reference
5. Identify model, harness, version, and installed plugins in the PR
6. All commits must show human review
7. Fill in the PR template completely — no blanks, no placeholders

## What belongs in this fork

| Kind of change | Bar |
|---|---|
| Bug fix in sync-from-upstream | Sync script + a one-line PR. No eval needed. |
| New safety gate | RED-GREEN-REFACTOR with 3+ pressure scenarios. New test. CHANGELOG entry. |
| New hard limit (never-override) | Same as a new safety gate, plus rationale for why it can never be raised. |
| Skill content change (not safety-related) | Mirror upstream's contribution rules. Reference the upstream issue or PR. If upstream won't accept it, we may still want it here, but it must be justified. |
| Docs / CI / scripts | One-line PR. No eval needed. |
| Refactor | One-line PR. No eval needed unless the refactor is in the safety gate. |

## What does NOT belong here

- Domain-specific skills (e.g. "iOS-only", "AWS-only"). Put them in a
  standalone plugin.
- Tools that depend on third-party services the upstream library doesn't
  already use. Fork policies follow upstream: zero new third-party deps.
- Reformatting of skills to "comply" with Anthropic's skills documentation
  without eval evidence. Same as upstream.
- Bulk refactors that touch many files for cosmetic reasons.

## Pull request rules

### Sync first

Before you open a PR, your local `dev` branch must be a clean superset of
`upstream/dev`. Run:

```bash
./scripts/sync-upstream.sh
```

If the script refuses (because of uncommitted changes, divergent history,
etc.), resolve the issue first. The script will not push a dirty tree.

### Branch and target

- Branch from `dev`. The branch name should be `feat/...`, `fix/...`,
  `chore/...`, or `docs/...` (no other prefixes).
- PR targets the `dev` branch. **Never** open a PR against `main`. The
  maintainer policy carries over from upstream.

### Safety-gate PRs

If your PR adds a new safety gate, a new hard limit, or modifies the
`<MANDATORY-SAFETY-GATE>` block:

1. Write at least 3 pressure scenarios that demonstrate the failure mode
   the gate is meant to catch. Put them in `tests/evals/scenarios/<gate-name>/`
   following the upstream `superpowers-evals` format. If you need a refresher,
   see `docs/eval-protocol.md`.
2. Run the scenarios **without** the new gate, record the QA agent verdict
   (RED).
3. Implement the gate.
4. Re-run the scenarios (GREEN).
5. Refactor: find new rationalizations, plug them, re-run.
6. Attach a summary table to the PR: scenario | RED verdict | GREEN verdict
   | pass / fail / indeterminate.
7. Add a new test in `tests/claude-code/test-*.sh` that asserts the gate is
   referenced in the expected location.
8. Update `CHANGELOG.md` under the next version with a "Added" entry.
9. Update `docs/safety-gate.md` with the new gate's specification.

### Skill content PRs (not safety-related)

1. Reference the upstream issue or PR that motivated the change.
2. If upstream has already accepted the change, mirror it. Open a one-line PR.
3. If upstream has rejected the change, justify why we want it here anyway.
   The justification must be more than "I prefer this wording".
4. The change must not break the `<MANDATORY-SAFETY-GATE>` block. The skill
   must still respect the safety preflight.

### Identifying yourself

Every PR description must include:

```
Model: <name>
Harness: <name + version>
Installed plugins: <list>
Human reviewer: <your name + brief note on what you verified>
```

This is the same rule as upstream and it is not optional.

### Human review

A human must review the complete proposed diff before submission. Bot-only
PRs will be closed. The "Human reviewer" field above is how you attest to
this. Lying about it is grounds for a permanent ban.

## Coding conventions

- Match the surrounding file's style. If the skill you're editing uses
  2-space indents, you use 2-space indents.
- New skills must follow the upstream `skills/<name>/SKILL.md` format. See
  any existing skill for the template.
- New tests in `tests/claude-code/` must `source test-helpers.sh` and use
  `run_claude` + `assert_*` helpers.
- Shell scripts: run through `shellcheck -x` before opening the PR. The CI
  workflow runs `scripts/lint-shell.sh` on every push.

## After the PR is merged

A maintainer will:

1. Run the full fast test suite locally
2. Verify the CHANGELOG entry
3. Bump the version using `./scripts/bump-version.sh patch|minor|major`
4. Tag the release and push the tag
5. Update the marketplace.json version pointer

You do not need to do any of this yourself.

## Questions?

Open an issue. Tag it with `question` and the maintainer will respond.
