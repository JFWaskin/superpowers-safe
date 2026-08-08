# Documentation Index

> One page, every doc. If you're new to `superpowers-safe`, start with the
> [README](../README.md), then come back here when you need depth.

## Fork-specific docs (this repo's own)

| Doc | What it's for |
|---|---|
| [`safety-gate.md`](safety-gate.md) | Engineering spec for the 5 hard gates and the never-override limits. Companion to `skills/safety-check/SKILL.md`. |
| [`sync-upstream.md`](sync-upstream.md) | How to rebase `dev` from `obra/superpowers`, what conflicts to expect, and the conflict-resolution policy. |
| [`eval-protocol.md`](eval-protocol.md) | RED-GREEN-REFACTOR protocol for safety-gate changes — when it applies, what evidence is required, and the pressure-scenario format. |
| [`testing.md`](testing.md) | How the two test layers work: `tests/` (plugin code) and `evals/` (real LLM sessions). |
| [`README.kimi.md`](README.kimi.md) | Kimi-Code-specific install and tool-mapping notes. |
| [`README.opencode.md`](README.opencode.md) | OpenCode-specific install notes (symlink migration, plugin cache). |
| `windows/` | Windows installer notes (inherited from upstream). |

## Inherited from upstream

| Path | What lives there |
|---|---|
| [`porting-to-a-new-harness.md`](porting-to-a-new-harness.md) | How to add a new AI harness / IDE to the cross-runtime packaging. Start here if you're porting superpowers to a new tool. |
| [`superpowers/`](superpowers/) | Design notes and specs for the Superpowers skills library itself. |
| [`superpowers/plans/`](superpowers/plans/) | Long-form design plans for individual skills (TDD, brainstorming, etc.). |
| [`superpowers/specs/`](superpowers/specs/) | Behavior specs the skills conform to. |
| [`plans/`](plans/) | Design plans from the dev branch: OpenCode support, skills improvements, visual brainstorming. |

## Top-level files

| File | What it is |
|---|---|
| [`../README.md`](../README.md) | Project overview, the 5-gate summary, install instructions. |
| [`../CHANGELOG.md`](../CHANGELOG.md) | Fork-specific release notes. Upstream has its own. |
| [`../CONTRIBUTING.md`](../CONTRIBUTING.md) | How to file PRs, branch policy, the "identify model/harness/version" rule. |
| [`../RELEASE-NOTES.md`](../RELEASE-NOTES.md) | Long-form notes for each tagged release. |
| [`../CLAUDE.md`](../CLAUDE.md) | Contributor rules for AI agents working in this repo (symlink: `AGENTS.md`). |
| [`../CODE_OF_CONDUCT.md`](../CODE_OF_CONDUCT.md) | Contributor Covenant. |
| [`../LICENSE`](../LICENSE) | MIT, same as upstream. |

## Where to go next

- **New to the fork?** Read the top-level `README.md`, then `docs/safety-gate.md`.
- **Changing the gate or never-override limits?** Read `docs/eval-protocol.md` first; you'll need pressure scenarios.
- **Syncing from upstream?** Run `./scripts/sync-upstream.sh`; if it errors, read `docs/sync-upstream.md`.
- **Porting to a new harness?** `docs/porting-to-a-new-harness.md` is the playbook.
- **Filing an issue?** Use `.github/ISSUE_TEMPLATE/bug_report.md`, `feature_request.md`, or `platform_support.md`.
