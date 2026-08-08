# Changelog

All notable changes to `superpowers-safe` are recorded here. Versions follow
[Semantic Versioning](https://semver.org/). The upstream Superpowers library
is tracked separately; see [obra/superpowers Releases](https://github.com/obra/superpowers/releases).

---

## [Unreleased] — Tier 1 rigor pass (2026-08-08)

See [`docs/rigor-checklist.md`](docs/rigor-checklist.md) for the full tracking document.

### Added

- **`docs/THREAT-MODEL.md`** — explicit in-scope, out-of-scope, assumptions, failure modes, residual risk. The honest "what this gate does NOT defend against" answer that reviewers look for.
- **`SECURITY.md`** — responsible disclosure policy (response timeline, scope, coordinated disclosure). Required cross-reference from THREAT-MODEL.
- **Per-runtime CI lanes** — `.github/workflows/codex-smoke.yml`, `opencode-smoke.yml`, `kimi-smoke.yml`. Each validates the runtime-specific manifest + runs the fork-agnostic `test-mandatory-gate.sh`. Codex lane has an optional install job (placeholder for when the CLI ships a non-interactive install).
- **`tests/evals/`** — 3 fully-formed pressure scenarios (rm-rf-outside-cwd, sudo-without-ok, publish-without-ok) + `tests/evals/README.md` (RED-GREEN operational guide) + `tests/evals/quorum-setup.sh` (Quorum install helper) + `tests/evals/.gitignore`.
- **`docs/rigor-checklist.md`** — tracks what was done, what is planned (Tier 2/3), what is intentionally out of scope.

### Changed

- **`docs/INDEX.md`** — updated to reference the new docs and the `tests/evals/` scenarios directory; added "Where to go next" routing for evaluators (THREAT-MODEL §7 is the "is this for you?" answer).

---

## [6.3.0] — 2026-08-07

### Added

- **Mandatory safety preflight.** New `safety-check` skill runs five hard gates
  (resource budget, command risk scan, loop / spend limits, secret / PII scan,
  scope confirmation) before any other Superpowers skill. The gate is enforced
  by a `<MANDATORY-SAFETY-GATE>` block at the top of
  `skills/using-superpowers/SKILL.md`.
- **Never-override hard limits.** `safety-check` skill documents 10 operations
  the user cannot raise mid-session: rm-rf on system paths, dd to a device,
  mkfs, fork bombs, curl|sh, force-push to main/master, sudo, npm/pip/cargo
  publish, macOS system file writes, shutdown / kill of system processes.
- **Fork identity.** Renamed plugin from `superpowers` to `superpowers-safe`
  across all runtime manifests: `.claude-plugin/`, `.codex-plugin/`,
  `.cursor-plugin/`, `.kimi-plugin/`, `.hermes-plugin/`, `gemini-extension.json`,
  `package.json`.
- **Self-hosted marketplace.** New `.claude-plugin/marketplace.json` registers
  this fork as the `superpowers-safe` marketplace, installable via
  `/plugin marketplace add JFWaskin/superpowers-safe`.
- **Defense-in-depth hook pattern.** `docs/safety-gate.md#defense-in-depth`
  shows a `PreToolUse` hook that blocks destructive bash at the tool layer.
- **Sync automation.** `scripts/sync-upstream.sh` rebases from
  `obra/superpowers` `dev` branch with conflict-resolution policy.
- **GitHub Actions CI.** `.github/workflows/test.yml` runs the
  `tests/claude-code/run-skill-tests.sh` fast suite on every push and PR.
- **Two new tests.** `tests/claude-code/test-safety-check.sh` verifies the
  skill content; `tests/claude-code/test-mandatory-gate.sh` verifies the gate
  is referenced in `using-superpowers/SKILL.md`.

### Changed

- All `plugin.json` / `package.json` / `gemini-extension.json` files: author,
  homepage, repository, version (6.2.0 → 6.3.0), and description updated to
  reflect the fork.
- `CLAUDE.md` now opens with a fork-identity block (FORK NOTICE + relationship
  to upstream + fork-specific PR rules) before the inherited upstream
  contributor guidelines.
- `GEMINI.md` now includes the `safety-check` skill alongside
  `using-superpowers`.
- `.codex-plugin/plugin.json` `interface.brandColor` changed from `#F59E0B`
  (amber) to `#16A34A` (green) to visually distinguish the safety-hardened
  variant.

### Inherited from upstream (synced at fork time)

- All 12 non-safety skills (brainstorming, subagent-driven-development,
  executing-plans, dispatching-parallel-agents, writing-plans,
  test-driven-development, systematic-debugging, finishing-a-development-branch,
  using-git-worktrees, requesting-code-review, receiving-code-review,
  verification-before-completion, writing-skills) are byte-identical to
  upstream `dev` at the time of fork (commit `c367f80`).

---

## Versioning policy

- **MAJOR**: A breaking change to the safety gate, the `<MANDATORY-SAFETY-GATE>`
  block, or the never-override hard limits.
- **MINOR**: A new safety gate, a new hard limit, a new test, a new doc, or
  any non-breaking skill content change.
- **PATCH**: Doc typo, CI tweak, version sync from upstream, no behavior change.

When upstream Superpowers ships a release, this fork's next version is a
`MINOR` bump with the upstream changes merged in and a sync note in this file.
