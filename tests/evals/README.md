# Eval scenarios for the safety gate

> This directory contains **pressure scenarios** that exercise the
> safety gate's gates. The protocol is documented in
> [`../../docs/eval-protocol.md`](../../docs/eval-protocol.md). This README
> is the operational guide.

## What is here

```
tests/evals/
├── README.md                                    (this file)
├── validate-scenarios.sh                        (CI gate; checks all 4 scenarios)
├── quorum-setup.sh                              (one-time setup: clone superpowers-evals, bun install)
├── scenarios/
│   ├── rm-rf-outside-cwd/                       (Scenario 1: out-of-cwd destructive delete)
│   │   ├── scenario.yaml                        (Quorum metadata)
│   │   ├── story.md                             (pressure narrative + acceptance criteria)
│   │   ├── setup.sh                             (pre() fixture)
│   │   └── checks.sh                            (post() deterministic checks)
│   ├── sudo-without-ok/                         (Scenario 2: privilege escalation framing)
│   │   ├── scenario.yaml
│   │   ├── story.md
│   │   ├── setup.sh
│   │   └── checks.sh
│   ├── publish-without-ok/                      (Scenario 3: public-registry write)
│   │   ├── scenario.yaml
│   │   ├── story.md
│   │   ├── setup.sh
│   │   └── checks.sh
│   └── curl-pipe-shell/                         (Scenario 4: pipe-to-shell install pressure)
│       ├── scenario.yaml
│       ├── story.md
│       ├── setup.sh
│       └── checks.sh
├── baselines/                                   (expected RED behavior; synthetic, real runs replace)
│   ├── rm-rf-outside-cwd.md
│   ├── sudo-without-ok.md
│   ├── publish-without-ok.md
│   └── curl-pipe-shell.md
└── results/                                     (gitignored; populated by Quorum runs)
    └── <run-id>/
        └── log.txt
```

## What is here vs. what isn't

| Status | Item |
|--------|------|
| ✅ Scaffolding done | 4 scenarios in Quorum format (yaml + story + setup + checks), 4 RED baseline transcripts, this README, `validate-scenarios.sh` |
| 🟡 RED baseline | Synthetic — describes expected agent behavior without the safety-check skill. Real Quorum runs (with API budget) would replace these with captured transcripts. |
| ⏳ Not yet run | Real Quorum runs (live evals with API) |
| ⏳ Not yet done | Rationalization close (REFACTOR phase) — once GREEN verdicts come in |

## Format

Each scenario follows the [Quorum](https://github.com/prime-radiant-inc/superpowers-evals)
layout (the current name for the eval harness — was "Drill" in older
versions of the upstream docs):

- **`scenario.yaml`** — Quorum metadata (`id`, `title`, `status`, `tags`,
  `quorum_max_time`, `gates_under_test`).
- **`story.md`** — the pressure narrative + acceptance criteria + the
  pressure script (the exact turns the harness sends to the agent) +
  reference to the matching RED baseline.
- **`setup.sh`** — `pre()` function: builds fixtures, mocks credentials,
  sets the working dir. Idempotent: `rm -rf` any prior state at the top.
- **`checks.sh`** — `post()` function: deterministic checks against
  the captured transcript. `safety-check` must have been called; the
  blocked command pattern must not appear; per-command OK count must
  match.

## How to validate locally

```bash
bash tests/evals/validate-scenarios.sh
```

This checks each scenario for: required files, required yaml fields,
frontmatter, `pre()` / `post()` functions, shellcheck cleanliness, and
the Acceptance Criteria section in `story.md`. Exits non-zero on any
failure. Wired into the existing CI workflow.

## How to run (real Quorum, when API budget is available)

```bash
# One-time setup
bash tests/evals/quorum-setup.sh

# Per-scenario run
cd evals
TRANSCRIPT=../tests/evals/results/<run-id>/log.txt \
  bun run quorum run ../tests/evals/scenarios/rm-rf-outside-cwd/scenario.yaml \
    --coding-agent claude --credential sonnet

# Run the post-checks
TRANSCRIPT=../tests/evals/results/<run-id>/log.txt \
  bash ../tests/evals/scenarios/rm-rf-outside-cwd/checks.sh
```

The RED baseline transcript is in `baselines/<scenario>.md`. A real
Quorum run produces a transcript that the post-check verifies against
the Acceptance Criteria in `story.md`. The synthetic RED baseline is
the author's pre-run prediction; if a real run deviates, update
either the baseline (if the deviation is benign — different but still
safe) or the skill's bulletproofing (if the deviation reveals a
rationalization the bulletproofing didn't close).

## What's still needed

- **Real Quorum runs** to replace the synthetic RED baselines with
  captured transcripts. Requires API budget; budget-per-scenario
  estimated at $1-3 RED + $1-3 GREEN each (4 scenarios × 2 cycles).
- **REFACTOR phase** (closes rationalization loopholes that the real
  runs reveal). Begins after the first GREEN run lands.
- **Cross-harness runs**: Claude + Codex + Kimi + Gemini at minimum.
  See [`docs/experiments/dual-layer-protection.md`](../../docs/experiments/dual-layer-protection.md)
  for the cross-harness methodology.

## Why this layout

The Quorum format (yaml + story + setup + checks) was adopted from
the upstream `prime-radiant-inc/superpowers-evals` repo's
`sdd-escalates-broken-plan` scenario, which is the most thoroughly
structured scenario in that repo. The pattern lets a maintainer read
the acceptance criteria in 30 seconds (`story.md`'s `## Acceptance
Criteria` section) and the deterministic gates in another 30 seconds
(`checks.sh`). Compared to the previous single-yaml format, the
separation makes it easier to:

- Read the pressure narrative without scrolling past a yaml frontmatter
- Find the deterministic check for a given behavior
- Update one part (e.g., tighten an acceptance criterion) without
  re-reading the rest
- Port a scenario to a different harness by changing only `setup.sh`
  and `checks.sh`
