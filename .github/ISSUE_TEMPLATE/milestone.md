---
name: Milestone Tracking
about: Track a fork release milestone (e.g. v6.3.1) — goals, tasks, risks, rollout.
labels: milestone, planning
---

<!--
Use this template to track a fork release. One issue per milestone. Update
the Tasks section as work lands. Close the issue when the Definition of Done
is met and the tag is pushed.
-->

# Milestone: <VERSION> — <one-line theme>

**Tag:** `vX.Y.Z`
**Target date:** YYYY-MM-DD (best effort, not a promise)
**Milestone lead:** @handle

## Summary

<!-- One paragraph. What is this milestone about and why does it exist?
What user-visible change does shipping it unlock? -->

## Goals

- [ ] **Goal 1** — concrete, shippable
- [ ] **Goal 2** — concrete, shippable
- [ ] **Goal 3** — concrete, shippable
- [ ] *(add more as needed)*

## Non-goals

- **Not this milestone:** explicit out-of-scope item
- **Not this milestone:** another explicit out-of-scope item

> Listing non-goals prevents scope creep. If a request is real but not for
> this milestone, file it as a separate issue and link it here.

## Tasks

<!-- One checkbox per task. Use the Owner column to make assignments visible.
Add or remove rows as the milestone evolves. -->

- [ ] **Task 1** — short verb phrase
      - Owner: @handle
      - Tracks: #<issue>, #<issue>
- [ ] **Task 2** — short verb phrase
      - Owner: @handle
      - Tracks: #<issue>
- [ ] **Task 3** — short verb phrase
      - Owner: @handle
      - Depends on: Task 1
- [ ] **Task 4** — short verb phrase (RED-GREEN-REFACTOR evidence required)
      - Owner: @handle
      - Evidence: `docs/eval-protocol.md` pressure scenarios

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| <what could go wrong> | low/med/high | low/med/high | <how we'll prevent or recover> |

Examples to consider:
- Upstream `obra/superpowers` ships a release during the milestone that
  conflicts with our changes — mitigation: pin the sync cadence, hold the
  release until rebase is clean.
- A safety-gate change fails the RED-GREEN-REFACTOR protocol — mitigation:
  expand the pressure-scenario set, don't ship without evidence.
- Cross-runtime packaging breaks one harness — mitigation: per-harness CI
  lane (Codex, OpenCode, Kimi), revert the affected lane before reverting
  the whole release.
- New version bumps `safety-guard.py` hook defaults in a way that breaks
  existing user setups — mitigation: back-compat flag, documented migration.

## Rollout

1. **Pre-release:**
   - [ ] All tasks checked
   - [ ] Definition of Done met
   - [ ] `dev` branch is a clean fast-forward of `upstream/dev` (or a documented rebase is committed)
   - [ ] CI green on all per-runtime lanes
2. **Tag:**
   - [ ] Bump version via `./scripts/bump-version.sh <version>`
   - [ ] `git tag -s vX.Y.Z -m "Release vX.Y.Z"`
   - [ ] `git push origin vX.Y.Z`
3. **Publish:**
   - [ ] `scripts/sync-to-codex-plugin.sh` runs clean against the tagged commit
   - [ ] Claude Code marketplace listing regenerated (if applicable)
   - [ ] GitHub Release drafted with notes from `CHANGELOG.md`
4. **Announce:**
   - [ ] Discord `#releases` post (link to Release notes)
   - [ ] Twitter / blog post (optional)
5. **Post-release:**
   - [ ] Open the next milestone issue (`vX.Y.Z+1`)
   - [ ] Triage any issues filed in the first 48h

## Definition of done

The milestone is done when **all** of the following are true:

- [ ] Every Task in this issue is checked off
- [ ] RED-GREEN-REFACTOR evidence exists for every safety-gate change
  (per `docs/eval-protocol.md`)
- [ ] `dev` is a clean fast-forward of `upstream/dev` at tag time
- [ ] `CHANGELOG.md` has an entry for this version with the date set
- [ ] All per-runtime CI lanes are green
- [ ] The tag is pushed and the GitHub Release is published
- [ ] No "P0" or "P1" bugs filed against this milestone are open
- [ ] The next milestone issue exists and has a draft Goals section

## Out of band (filed but not in this milestone)

- #<issue> — <reason deferred>
- #<issue> — <reason deferred>
