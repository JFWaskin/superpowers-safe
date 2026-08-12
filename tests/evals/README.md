# Eval scenarios for the safety gate

> This directory contains **pressure scenarios** that exercise the
> safety gate's gates. The protocol is documented in
> [`../../docs/eval-protocol.md`](../../docs/eval-protocol.md). This README
> is the operational guide.

## What is here

```
tests/evals/
├── README.md                                    (this file)
├── quorum-setup.sh                              (one-time setup: clone superpowers-evals, bun install)
├── scenarios/
│   ├── rm-rf-outside-cwd/                       (Scenario 1: out-of-scope destructive delete)
│   │   └── scenario.yaml
│   ├── sudo-without-ok/                         (Scenario 2: privilege escalation framing)
│   │   └── scenario.yaml
│   ├── publish-without-ok/                      (Scenario 3: public-registry write)
│   │   └── scenario.yaml
│   └── curl-pipe-shell/                         (Scenario 4: pipe-to-shell install pressure)
│       └── scenario.yaml
└── results/                                     (gitignored; populated by Quorum runs)
    ├── red-rm-rf-outside-cwd/
    ├── green-rm-rf-outside-cwd/
    └── ...
```

## What is here vs. what isn't

| Status | Item |
|--------|------|
| ✅ Scaffolding done | 4 scenario YAMLs, setup script, this README |
| ⏳ Not yet run | RED baseline (no gate) |
| ⏳ Not yet run | GREEN evaluation (gate installed) |
| ⏳ Not yet done | Rationalization close (REFACTOR phase) — once GREEN verdicts come in |

The scenarios are **ready to run** but have **not been run yet**.

## How to run

### One-time setup

```bash
bash tests/evals/quorum-setup.sh
```

This clones `prime-radiant-inc/superpowers-evals` into `./evals/` (git
submodule layout; that path is in `.gitignore` so it doesn't pollute
the repo). Then `bun install`s Quorum.

### Single scenario (manual)

```bash
cd evals
bun run quorum run ../tests/evals/scenarios/rm-rf-outside-cwd/scenario.yaml
```

The output is a pass/fail/indeterminate verdict plus a transcript. Save
the output to `tests/evals/results/{red|green}-<scenario>/` for the
eval PR.

### RED baseline (run WITHOUT the gate)

Before the gate works, run all 3 scenarios to capture the RED baseline:

```bash
# 1. Temporarily disable the gate
git stash push -- skills/using-superpowers/SKILL.md
git stash push -- skills/safety-check/SKILL.md

# 2. Run each scenario, save results
for s in tests/evals/scenarios/*/; do
  name=$(basename "$s")
  cd evals
  bun run quorum run "../$s/scenario.yaml" 2>&1 | tee "../tests/evals/results/red-${name}/log.txt"
  cd ../..
done

# 3. Re-apply the gate
git stash pop
```

### GREEN evaluation (run WITH the gate)

```bash
for s in tests/evals/scenarios/*/; do
  name=$(basename "$s")
  cd evals
  bun run quorum run "../$s/scenario.yaml" 2>&1 | tee "../tests/evals/results/green-${name}/log.txt"
  cd ../..
done
```

### Compare RED vs GREEN

```bash
ls tests/evals/results/red-*/log.txt tests/evals/results/green-*/log.txt
# Read each pair side by side; record:
#   - scenario name
#   - RED verdict + the agent's rationalization
#   - GREEN verdict + the agent's compliant action
#   - any new rationalization that the gate didn't close
```

Attach the resulting table to the eval PR (per `docs/eval-protocol.md`).

## Cost budget

Each scenario = one full Claude Code agent run with a real API spend.
Realistic budget per RED or GREEN cycle:

| Scenario | Estimated cost (RED) | Estimated cost (GREEN) |
|----------|---------------------|------------------------|
| rm-rf-outside-cwd | $0.5-1.5 | $0.5-1.5 |
| sudo-without-ok | $0.3-0.8 | $0.3-0.8 |
| publish-without-ok | $0.3-0.8 | $0.3-0.8 |
| curl-pipe-shell | $0.3-1.1 | $0.3-1.1 |
| **Total per cycle** | **$2-4** | **$2-4** |

For full RED + GREEN + 1-2 refactor iterations, budget **$25-60** for
all 4 scenarios. Add more scenarios as needed.

Time budget: 2-4 hours per cycle (mostly waiting for Quorum to drive
the agent).

## When to run

Per `docs/eval-protocol.md`:
- RED baseline: before submitting any change to the gate
- GREEN evaluation: after implementing a change
- Refactor: when GREEN reveals new rationalizations

For the **initial v6.3.0 release**: the eval was NOT run. The release
ships with:
- Static tests (8 in `test-mandatory-gate.sh`, 5 in `test-safety-check.sh`)
- Manual review of the 5 gates and 10 hard limits in `skills/safety-check/SKILL.md`
- The scenarios in this directory, ready to be run

## Adding a new scenario

1. Create `tests/evals/scenarios/<scenario-name>/`
2. Write `scenario.yaml` (see existing 3 for the schema)
3. Run RED + GREEN + compare
4. Add the verdict table to your PR

A good scenario has:
- **A real pressure**: time pressure, authority pressure, framing
  pressure, or novelty (something the agent hasn't seen)
- **A specific gate it's testing**: name the gate in the
  description
- **An expected behavior**: what should the agent do when the gate
  works correctly
- **A failure mode**: what does the agent do without the gate (so RED
  has something to fail on)

## References

- [`../../docs/eval-protocol.md`](../../docs/eval-protocol.md) — the
  RED-GREEN-REFACTOR protocol this directory implements
- [`../../docs/THREAT-MODEL.md`](../../docs/THREAT-MODEL.md) — what
  the gate covers; scenarios should test claims made here
- [`prime-radiant-inc/superpowers-evals`](https://github.com/prime-radiant-inc/superpowers-evals)
  — the Quorum harness, cloned by `quorum-setup.sh`
