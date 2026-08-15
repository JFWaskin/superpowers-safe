# `fork/` — fork-only artifacts

This directory holds artifacts that live in **`JFWaskin/superpowers-safe`** but
**not** in upstream `obra/superpowers`. They are work-in-progress, fork
adaptations, and integration glue that:

- We want to develop and review inside our own tree before proposing upstream.
- May diverge from upstream (e.g., safety-gate wiring, optional feature flags).
- Are versioned and shippable without coordinating an upstream release.

The contents of this directory are **not** advertised in the main
`README.md` or in upstream-facing PRs. They appear in the fork's own
documentation under `docs/integrations/` and `docs/upstream/`.

## Current entries

| Path | Purpose |
| --- | --- |
| `deepseek-harness-bridge/` | Cordis plugin + `cordis.yml` overlay that wires the existing `superpowers/skills/*/SKILL.md` files into the [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) via its `ctx.skills` provider registry, plus a Claude-Code-compatible `hooks.json` for `dsh-hooks-claude-code`. See its own `README.md` for the install instructions. |

## Conventions

- One subdirectory per fork-only artifact. The subdirectory is the unit
  of work and the unit of review.
- Each subdirectory has its own `README.md` that names the upstream
  artifact, states what the bridge does and does **not** do, and points
  at the upstream issue / PR that motivated the work.
- We do not import anything from `fork/` in the main `package.json` or
  in any of the other plugin manifests (`.claude-plugin/`,
  `.cursor-plugin/`, etc.). The fork-only artifacts are opted into
  explicitly by the user.
- Anything in `fork/` is in scope for fork PRs (`dev` branch) but **not**
  for upstream PRs — when we ship upstream, we re-home the artifact
  to a sensible upstream path (`packages/skill/skill-superpowers` for
  the deepseek-harness-bridge, etc.) and drop the `fork/` shim.

## See also

- [`docs/upstream/deepseek-harness-analysis.md`](../docs/upstream/deepseek-harness-analysis.md) — the prerequisite research for `deepseek-harness-bridge/`.
- [`docs/porting-to-a-new-harness.md`](../docs/porting-to-a-new-harness.md) — the 9-runtime spec the bridge follows.
- [`docs/compatibility.md`](../docs/compatibility.md) — the per-runtime matrix.
