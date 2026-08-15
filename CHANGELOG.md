# Changelog

All notable changes to `superpowers-safe` are recorded here. Versions follow
[Semantic Versioning](https://semver.org/). The upstream Superpowers library
is tracked separately; see [obra/superpowers Releases](https://github.com/obra/superpowers/releases).

---

## [Unreleased] — DeepSeek Harness bridge (2026-08-15)

### Added

- **`fork/deepseek-harness-bridge/`** — Cordis plugin + `cordis.yml`
  overlay that wires the existing `superpowers/skills/*/SKILL.md`
  files into the [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)
  via its `ctx.skills` provider registry, plus a
  Claude-Code-compatible `hooks.json` for `dsh-hooks-claude-code`.
  Two install paths ship in the same directory: (1) a
  lowest-friction `cordis.yml` that points the shipped
  `@deepseek-ai/dsh-skill-filesystem` provider at
  `./superpowers/skills` via `customSkillDirs`, and (2) a custom
  `BridgeSkillProvider` in `src/index.ts` that reuses the same
  `SKILL.md` files under a fork-owned provider name
  (`superpowers-safe-bridge`). The bridge is fork-only work;
  it is not proposed upstream yet — see its own
  `fork/deepseek-harness-bridge/README.md` for the ask-PR
  checklist. Companion analysis:
  [`docs/upstream/deepseek-harness-analysis.md`](docs/upstream/deepseek-harness-analysis.md).
- **`fork/README.md`** — convention doc for `fork/`-directory
  artifacts (work-in-progress, fork adaptations, integration glue
  that lives in this fork but not in upstream `obra/superpowers`).
- **`docs/compatibility.md`** — added a `DeepSeek Harness` row
  to the runtime matrix (status: implemented via
  `fork/deepseek-harness-bridge/`, not yet an upstream PR).
- **`tests/evals/scenarios/deepseek-harness/`** — Quorum eval
  scenario that exercises the DeepSeek-specific
  whitespace-bounded `/<name>` user-invocation regex
  (`/(^|\s)\/([a-z0-9]+(?:-[a-z0-9]+)*)(?=\s|$)/g` per
  `packages/skill/tool-skill/src/index.ts` in the upstream
  DeepSeek harness). Validates that (a) every superpowers
  skill name is kebab-case and matches the regex, (b) every
  description fits the 500-char `catalogDescriptionMaxLength`
  cap, (c) `/usr/bin/ls` is not parsed as a skill gesture
  (the left whitespace-boundary check), (d) `/UsingSuperpowers`
  is not parsed as a gesture (the kebab-case check), and
  (e) arguments after the name are passed through as prose.

## [Unreleased] — Upstream sync (2026-08-13)

### Changed

- **`CODE_OF_CONDUCT.md`** — replaced the Contributor Covenant v3.0 with the Prime Radiant Community Code of Conduct. Inherited verbatim from upstream `obra/superpowers#2122`. Same scope and enforcement ladder structure; new framing ("Encouraged Behaviors" / "Restricted Behaviors" / "Other Restrictions") and explicit reference to GitHub + the Prime Radiant Discord server as covered spaces. Reporting and enforcement contact channels are unchanged for this fork (the issue-tracker and the project owner's email).
- **`RELEASE-NOTES.md`** — added the upstream v6.3.0 (2026-08-12) section. Covers upstream's harness additions (Devin CLI, Hermes Agent, Grok Build CLI), the brainstorming ceremony scaling change, the SDD plan-scoped workspace + resume-the-implementer fix-loop, Codex event-driven subagent waits, and the Windows fixes (worktree removal safety, Copilot CLI backgrounding, `render-graphs.js`). Brought in verbatim; this fork's own `CHANGELOG.md` is the user-facing record of fork-specific changes, and `RELEASE-NOTES.md` is the inherited upstream-side record.

## [Unreleased] — Tier 3.5 migration guide + discovery pass (2026-08-10)

### Added

- **`docs/MIGRATION.md`** — step-by-step guide for users moving from upstream `superpowers@claude-plugins-official` to this fork. Side-by-side install, per-runtime disable-upstream command (12 runtimes), what's different, what changes in your workflow, what does NOT change, rollback, "what may surprise you" gotchas.
- **`docs/ENHANCEMENT-LOG.md`** — append-only log of what shipped and why. Cross-references the rigor-checklist tiers; the day-to-day record that the tiers are the strategic arc.
- **`docs/marketing/`** directory — 8 ready-to-use promotional drafts: README index, GitHub-settings checklist, awesome-list PR text, Show HN post, Reddit drafts (r/ClaudeAI, r/LocalLLaMA, r/MachineLearning), X/Twitter thread (10 tweets), newsletter cold-pitch, influencer DMs. Each is copy-paste-ready.
- **`assets/social-preview.png`** — 1200×669 banner for Open Graph and the GitHub social preview slot. Shows the 5-gate shield, the title, the tagline, and the bottom row "5 hard gates · 15 skills · 0 surprises".
- **`CITATION.cff`** — author (Waskin, Huaqiao University), references to upstream `obra/superpowers` and the eval harness, and the "what's added vs upstream" description. Ready for academic citation.

### Changed

- **`README.md`** — added Shields.io badge block (license, release, stars, forks, watchers, last-commit), a one-line TL;DR under the title, a "Compared to alternatives" table (5 rows: raw Claude Code, upstream, upstream + hand-rolled hook, sandbox-only, this fork), a "Who this is for" section with 4 personas, and a "Showcase" placeholder.
- **`.github/FUNDING.yml`** — was pointing to `obra` (upstream leftover); now points to `JFWaskin`. Inline comment documents how to hide the button if no sponsorship is set up.
- **`docs/INDEX.md`** — links to the new files; the marketing directory is added to the table.
- **`docs/rigor-checklist.md`** — Tier 3.5 status table added and marked shipped. Issue log + net-effect summary match the Tier 1 / Tier 2 sections.

## [Unreleased] — Upstream sync (2026-08-11)

### Added

- **Devin CLI support.** New `.devin-plugin/plugin.json` manifest registers the fork as installable via `devin plugins install JFWaskin/superpowers-safe`. Skills are auto-discovered from `./skills/`; Devin's own system prompt already documents its subagent / todo / question tools, so no tool-mapping scaffold is required. CI test in `tests/devin/test-devin-plugin.sh` validates the manifest. Cross-runtime support table in the README and the compatibility matrix updated.
- **Grok Build CLI in cross-runtime support table.** Documented the `grok plugin install superpowers-safe@JFWaskin-superpowers-safe --trust` install path (no dedicated manifest yet — the fork's `package.json` is the closest thing). Mirrors upstream `obra/superpowers#1919`.

### Changed

- **`.version-bump.json`** — `.devin-plugin/plugin.json` added to the version-bump file list so version-bumps update it alongside the other manifests.
- **`scripts/sync-to-codex-plugin.sh`** — `/.devin-plugin/` added to the rsync exclude list, so embedded Codex plugins don't ship the Devin-specific manifest.
- **`docs/compatibility.md`** — Devin CLI and Grok Build CLI rows added to the runtime matrix. Devin is "manifest validated" (🟡 for install / load / safety gate, ✅ for plugin manifest). Grok is "no dedicated manifest yet" (🚫 for plugin manifest, 🟡 for the rest).
- **`README.md`** — Devin CLI and Grok Build CLI added to the cross-runtime support table. `.devin-plugin/` added to the repository-layout section.

### Inherited from upstream

- **`skills/brainstorming/visual-companion.md`** — Copilot CLI backgrounding guidance corrected for Windows. The previous instructions referenced `read_bash` / `stop_bash` (Claude-Code-only tools); the new guidance uses Copilot CLI's own non-blocking/background shell mechanism and explicitly notes the Git-Bash invocation needed on Windows. Mirrors upstream `obra/superpowers#2006`.

---

## [Unreleased] — Tier 1 rigor pass (2026-08-08)

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
