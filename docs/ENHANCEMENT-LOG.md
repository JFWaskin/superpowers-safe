# Enhancement log

> What was added to the fork and why. Each entry corresponds to one
> shipping commit (or a small, focused group of commits). The
> rigor-checklist tiers track the strategic arc; this file is the
> day-to-day record of what landed.

## How to use this file

- When starting work, check the latest entry to see where the cadence
  left off.
- When shipping, add a new dated entry at the top.
- When a rigor-checklist item is shipped, link the entry from
  `rigor-checklist.md` and vice versa.
- The file is append-only. Don't edit old entries; correct mistakes
  in a new entry.

## Format

Each entry:

- **Date** (ISO 8601)
- **Tier or category** (link to rigor-checklist section if applicable)
- **What shipped** (1–3 bullets, file paths)
- **Why** (1 sentence)
- **Issues found and fixed** (optional, matches rigor-checklist style)

---

## 2026-08-10 — Tier 3.5: Migration guide

- **Tier:** Tier 3.5 (new, ad-hoc)
- **What shipped:**
  - `docs/MIGRATION.md` — step-by-step guide for users coming from upstream
    `superpowers@claude-plugins-official`. Covers side-by-side install,
    per-runtime install with the disable-upstream step, what's different,
    what's unchanged, rollback, and "what may surprise you" gotchas.
  - `docs/ENHANCEMENT-LOG.md` (this file) — the cadence log
  - `docs/INDEX.md` — links the new files
  - `docs/rigor-checklist.md` — Tier 3.5 status updated to shipped
- **Why:** The rigor-checklist listed "Migration guide (upstream → fork)"
  as Tier 3.5 with medium signal. With the fork on its first wave of
  users, having a migration path is the difference between "I tried it
  and it broke" and "I tried it and it worked." Ships as Tier 3.5.

## 2026-08-11 — Upstream sync: Devin CLI support, Grok Build CLI, Copilot CLI Windows fix

- **Tier:** Tier 1.3 (per-runtime CI lanes) — extending the cross-runtime matrix
- **What shipped:**
  - **`.devin-plugin/plugin.json`** — new Devin CLI manifest, fork-adapted
    (name `superpowers-safe`, author Jonathan F. Waskin, repo
    `JFWaskin/superpowers-safe`)
  - **`tests/devin/test-devin-plugin.sh`** — CI-safe manifest validator
    (mirrors the kimi and upstream-devin tests, but checks for the fork's
    `superpowers-safe` naming and the JFWaskin homepage/repo)
  - **`.version-bump.json`** — `.devin-plugin/plugin.json` added to the file
    list, so future version bumps update it
  - **`scripts/sync-to-codex-plugin.sh`** — `/.devin-plugin/` added to the
    rsync exclude list
  - **`README.md`** — Devin CLI and Grok Build CLI added to the cross-runtime
    support table; `.devin-plugin/` added to the repository layout
  - **`docs/compatibility.md`** — Devin CLI and Grok Build CLI rows added to
    the runtime matrix
  - **`skills/brainstorming/visual-companion.md`** — upstream sync: Copilot
    CLI backgrounding guidance corrected for Windows (mirrors
    `obra/superpowers#2006`)
  - **`CHANGELOG.md`** — new "Upstream sync" section
- **Why:** Upstream `obra/superpowers` `dev` is now 9 commits ahead of this
  fork's base (`c367f80`). The substantive new upstream work — Devin CLI
  support (#1995), Grok Build CLI in the README (#1919), and the Copilot
  CLI Windows brainstorming fix (#2006) — is brought in here. The two
  README navigation refactors (#1995 prep, #2006 prep) are upstream's own
  TOC cleanup and don't apply to this fork (which has a different README
  structure). The 3 merge commits (#1995, #2006, #1919) are noise; the
  substantive changes were applied directly.

### Issues found and fixed during this sync

1. **README 3-way merge produced huge conflict blocks.** The fork's README
   has been heavily restructured (badges, TL;DR, "Compared to
   alternatives", showcase, "Who this is for", "Quickstart" relocation,
   etc.) since the initial commit, so a 3-way merge against upstream's
   README churn was unworkable. Resolution: cherry-pick only the
   skill-doc change (which is byte-identical between upstream and fork),
   and bring the README-only changes into the fork by hand in the fork's
   own style (cross-runtime support table + repo layout). One commit,
   one focus.
2. **`scripts/sync-to-codex-plugin.sh` was already fork-local but missing
   the `/.devin-plugin/` exclude** that the upstream Devin commit added
   in lockstep. The exclude was the only diff between upstream's version
   of the file and the fork's, so this is a 1-line addition.
3. **Upstream's `tests/devin/test-devin-plugin.sh` checks
   `name == "superpowers"`** but the fork convention is
   `name == "superpowers-safe"`. The fork-adapted test checks for the
   fork convention AND for the JFWaskin homepage/repo (so a future
   accidental revert to upstream's name is caught). The pre-existing
   fork's `tests/kimi/test-plugin-manifest.sh` has the same upstream-vs-fork
   name mismatch and is currently failing on the fork — that's a known
   issue, not addressed here (out of scope for a sync pass).
4. **Pre-existing `tests/claude-code/test-safety-check.sh` Test 6 fails
   on macOS without `timeout(1)` installed** (Homebrew doesn't ship GNU
   coreutils by default). Not introduced by this change. Not addressed
   here.

---

## Earlier work (rolled up)

- **2026-08-09 — feat(marketing):** discovery surface (badges, comparison
  table, showcase placeholder, CITATION.cff, FUNDING.yml fix, social
  preview, `docs/marketing/` drafts). See commit `e837188`.
- **2026-08-08 — feat(rigor) Tier 2:** branch protection, CODEOWNERS,
  `scripts/bench-gate.sh`, `docs/benchmarks.md`, `docs/compatibility.md`.
  See commit `9784b71`.
- **2026-08-08 — docs(scrub):** removed forward-looking language from
  `CHANGELOG.md` and `tests/evals/README.md`. See commit `a3e7aba`.
- **2026-08-08 — feat(rigor) Tier 1 (THREAT-MODEL, CI lanes, eval
  scenarios scaffolded):** `docs/THREAT-MODEL.md`, per-runtime CI
  workflows, 3 eval scenarios scaffolded. See commit `fcb4608`.
- **2026-08-08 — docs(install):** `docs/help-me-install.md` (copy-paste
  install prompt for any agent). See commit `799b2a9`.
- **2026-08-08 — docs(readme):** HQU attribution fix. See commit
  `e196d74`.
- **2026-08-08 — docs(meta):** `docs/INDEX.md`, milestone issue
  template, install-swap refinements. See commit `c599511`.
- **2026-08-07 — v6.3.0 release:** the first fork release, with the
  mandatory safety preflight. `CHANGELOG.md` has the full entry.
