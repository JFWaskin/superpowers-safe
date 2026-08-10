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
