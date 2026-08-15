# Changelog

All notable changes to the `deepseek-harness-bridge` are recorded
here. Versions follow [Semantic Versioning](https://semver.org/).
The bridge's version starts at `0.1.0`; bump to `0.x.0` for new
features, `0.0.x` for bug fixes.

The bridge is **not** an upstream artifact yet — it lives in the
`JFWaskin/superpowers-safe` fork's `fork/` directory and is
proposed upstream as a separate work item once the fork's eval
passes are green.

---

## [0.1.0] — 2026-08-15

### Added

- **Cordis plugin (`src/index.ts`)** that registers a
  `ctx.skills` provider reusing the existing
  `superpowers/skills/<name>/SKILL.md` files. Discovers one
  level deep, parses YAML frontmatter, loads bodies on demand.
  Provider name `superpowers-safe-bridge`; default rank `350`
  (below `customSkillDirs` at 300 — wait, that's the other
  way; the lower number wins within a single scope layer, so
  rank 350 actually loses to rank 300. The README documents
  this as a deliberate trade-off: a custom-root skill set by
  the user via `customSkillDirs` should outrank the bridge's
  fixed superpowers skills. Re-check this on first eval
  pass and bump if it causes confusion.)
- **`cordis.yml`** lowest-friction overlay that uses the
  shipped `@deepseek-ai/dsh-skill-filesystem` provider with
  `customSkillDirs: ['./superpowers/skills']` and adds
  `@deepseek-ai/dsh-hooks-claude-code` with our existing
  `hooks.json`.
- **`hooks.json`** Claude-Code-compatible `SessionStart` hook
  that delegates to the existing `hooks/session-start` script
  (no fork-local duplicate).
- **`README.md`** install guide + what's-covered matrix +
  open questions deferred to upstream.
- **`package.json`** + **`tsconfig.json`** for the custom
  provider's build path (`bun run build`).
- **`test/provider.test.ts`** Bun-based unit tests for the
  custom provider against a temporary skill directory.
- **`examples/config.example.json`**, **`examples/dsh-headless.yml`**,
  **`examples/acceptance.md`** for end-to-end install +
  verification.

### Known issues / not-yet-shipped

- The provider name `superpowers-safe-bridge` and the default
  rank `350` are not yet validated against a real DeepSeek
  Harness install. Re-verify on first eval pass.
- No `init` script (`dsh-deepseek-init` or similar) that
  scaffolds the patch into `~/.dsh/profiles/<name>/`. That
  belongs in a follow-up; for now the user copies the
  `cordis.yml` by hand.
- The `whenToUse` and `metadata` frontmatter fields are read
  by the custom provider but not exposed to model matching;
  they are surfaced only as candidate metadata. The upstream
  provider does the same. Document this in the user-facing
  docs before the first eval pass.
- The `examples/dsh-headless.yml` includes model names
  (`deepseek-v4-flash`, `deepseek-v4-pro`) that may not match
  the current `dsh-llm-deepseek` catalog by the time the user
  installs. Re-verify on first install.
- The `src/index.ts` does NOT register file-watching. Bodies
  are re-read on every `get()` call. The same posture the
  upstream provider takes for non-watched roots. Add a
  Chokidar watcher only if a real eval pass shows the
  re-read is a hot path.
