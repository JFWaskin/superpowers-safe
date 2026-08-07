# Syncing from upstream

This fork rebases from `obra/superpowers` `dev` branch. The procedure is
automated by [`scripts/sync-upstream.sh`](../scripts/sync-upstream.sh) but
documented here in case you need to do it manually.

## When to sync

- At minimum: once per week, or before opening a PR
- Always: after upstream ships a release
- Conditionally: if upstream `dev` has new commits that touch the same
  files as your in-progress PR

## The automated way

```bash
./scripts/sync-upstream.sh
```

The script will:

1. Refuse to run if there are uncommitted changes
2. Verify `upstream` remote points to `obra/superpowers`
3. Fetch `upstream/dev`
4. Check that local `dev` is a fast-forward of `upstream/dev` (else abort)
5. Rebase any feature branches onto the new `dev`
6. (Optionally) push to `origin` with `--force-with-lease`

If the script aborts at step 4, your `dev` has diverged. Use the manual
procedure below.

## The manual way

```bash
# 1. Make sure your local dev is clean
git status
git checkout dev
git fetch upstream
git rebase upstream/dev

# 2. Resolve any conflicts. Most conflicts will be in:
#    - skills/*/SKILL.md (skill content; take upstream unless you have a
#      documented reason to keep your change)
#    - .claude-plugin/plugin.json (metadata; keep your author/homepage)
#    - .claude-plugin/marketplace.json (metadata; keep your marketplace name)
#    - hooks/session-start (auto-generated; take upstream)
#    - scripts/bump-version.sh (auto-generated; take upstream)

# 3. Re-apply the safety gate if upstream overwrote it
git diff upstream/dev -- skills/using-superpowers/SKILL.md
# Look for the <MANDATORY-SAFETY-GATE> block. If it's missing, re-add
# from the template in docs/safety-gate.md#architecture

# 4. Run the full test suite
./tests/claude-code/run-skill-tests.sh

# 5. Push
git push origin dev
```

## Conflict resolution policy

When upstream changes conflict with this fork's changes, the policy is:

| File | Policy |
|------|--------|
| `skills/<name>/SKILL.md` (non-safety) | Take upstream. Open a separate PR to re-apply your change if you still want it. |
| `skills/using-superpowers/SKILL.md` | Take upstream, then re-add the `<MANDATORY-SAFETY-GATE>` block. The block is documented in `docs/safety-gate.md#architecture` so you can re-apply from the spec. |
| `skills/safety-check/SKILL.md` | Keep fork. If upstream adds a `safety-check` skill, treat it as a sync candidate. |
| `.claude-plugin/plugin.json` | Keep fork's author/homepage. Take upstream's version bump. |
| `.claude-plugin/marketplace.json` | Keep fork's marketplace name + plugins array. Take upstream's version field. |
| `hooks/session-start` | Take upstream. It's auto-generated. |
| `scripts/bump-version.sh` | Take upstream. It's auto-generated. |
| `tests/**` | Take upstream. Re-add fork-specific tests as new files. |
| `CHANGELOG.md` | Keep fork. Append a new section for the sync. |
| `CLAUDE.md` | Keep fork's prepended FORK NOTICE block. Take upstream's contributor section if it changed. |
| `package.json` | Keep fork's name. Take upstream's version bump. |

## Long-term divergence

If the divergence between this fork and upstream becomes hard to maintain,
the right move is to upstream a subset of the safety gate (after running
the eval protocol in `docs/eval-protocol.md`) and reduce the local delta.
The goal is for the safety gate to be small and well-encapsulated, so
that syncing from upstream remains a 5-minute job.

## When to give up the sync

If upstream makes a change that's incompatible with the safety gate
(e.g. a skill that explicitly tells agents to skip the gate), the right
move is to fork that skill out. Don't fight upstream on this — the safety
gate is a *layer*, not a *modification*. Keep the upstream skill intact
and document the divergence.
