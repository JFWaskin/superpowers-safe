# Benchmarks

> Measured overhead of the safety gate. Re-run on the same host for
> version-to-version comparison.
>
> Script: [`../scripts/bench-gate.sh`](../scripts/bench-gate.sh)
>
> Methodology: each gate is measured in isolation; multiple iterations
> are taken; median is reported. The hook is measured per Bash call.

## Latest run

Host: **Darwin 25.6.0 arm64** (Apple Silicon)
Iterations: **3** (use `--iterations=100` for production measurement)
Python startup: ~30-50ms (included in hook times; cached after first call)

| Component | Median | Min | Max | What it does |
|---|---|---|---|---|
| **Gate 1: resource budget** | 34.0ms | 30ms | 38ms | `df -h .` + `vm_stat` + `sysctl -n hw.ncpu` + `uptime` |
| **Gate 2: command risk (5 cmds)** | 160.0ms | 157ms | 160ms | 5 hook invocations (`rm -rf /`, `git push`, etc.) — ~32ms per cmd |
| **Gate 3: loop / spend** | 26.0ms | 25ms | 29ms | Grep the skill for limit definitions (skill-level, agent-driven) |
| **Gate 4: secret scan** | 21.0ms | 21ms | 25ms | Bash regex on 5 paths (skill-level, agent-driven) |
| **Gate 5: scope confirmation** | 24.0ms | 22ms | 26ms | Grep the skill for output format (skill-level, agent-driven) |
| **Hook per Bash call** | 26.0ms | 26ms | 28ms | PreToolUse hook — `safety-guard.py` startup + classification |
| **5-skill content load** | 33.0ms | 33ms | 36ms | Reading 5 SKILL.md files (cold read; cached after) |

**Sum**:
- **Gate-only adds ~265ms one-time per session** (Gates 1-5)
- **+ ~26ms per Bash invocation** (the hook)

## What this means

For a typical session that runs 50 Bash commands, the total gate overhead is:

```
265ms (one-time) + 50 × 26ms (per-Bash) = ~1.6 seconds
```

Compared to:
- A typical Claude Code session: 5-30 minutes
- A typical SDD plan execution: 30 minutes - 2 hours

**The gate adds <1% overhead to a typical session.** This is cheap
enough that the safety value far exceeds the cost.

## What this does NOT measure

- **Real Claude Code session latency.** This bench measures the gate
  in isolation. Real sessions have additional latency from API calls,
  context loading, and other plugins. The gate's contribution to real
  latency is what this bench measures; the absolute session latency
  is not measured here.
- **Token spend.** The gate's `[SAFETY CLEARED]` block is ~500 tokens
  once per session. This is <0.1% of a typical session's token usage.
- **Eval harness (Quorum) overhead.** Quorum runs are separate; see
  `tests/evals/README.md`.

## Comparison: gate cost vs. gate benefit

| Cost | Benefit |
|------|---------|
| ~265ms one-time + ~26ms/Bash | Hard-blocks `rm -rf /`, `dd` to device, fork bombs, `curl\|sh`, force-push to main, publish commands, sudo without OK |
| ~500 tokens per session | Refuses to run malicious patterns even when the agent is "in a hurry" |
| Adds 4-8s to a long autonomous session | Forces human check-in at 30 min, $1/$5/$10 spend |

The cost is paid once per session. The benefit is "you didn't lose a
machine, a git history, or a published package".

## Running the benchmark

```bash
# Quick (3 iterations, ~30s)
bash scripts/bench-gate.sh

# Standard (10 iterations, ~2min)
bash scripts/bench-gate.sh

# Production (100 iterations, ~20min)
bash scripts/bench-gate.sh --iterations=100

# JSON output for tracking over time
bash scripts/bench-gate.sh --json > benchmarks-$(date +%Y%m%d).json
```

The script writes its results to stdout; you can pipe to a file for
archival.

## When to re-benchmark

Re-run when any of these changes:
- The `scripts/safety-guard.py` hook (Python regex patterns)
- The `skills/safety-check/SKILL.md` content (gate definitions)
- The `<MANDATORY-SAFETY-GATE>` block in `skills/using-superpowers/SKILL.md`
- The Python version on the runner (different startup times)
- The host hardware (different baseline)

Store the output in a dated file under `docs/benchmarks-history/` (not
yet created; the first historical snapshot will be the v6.3.0 release).

## Known limitations of the benchmark

1. **Python startup dominates hook time.** On the bench host, ~25ms of
   the 26ms hook time is Python interpreter startup, not regex matching.
   A compiled language would be much faster. We accept the cost for
   the safety property.
2. **The "5 cmds" workload for Gate 2 is contrived.** Real sessions see
   a mix of allow / warn / block, with most calls being allow. The
   32ms-per-cmd number is upper-bound; allow-path is faster.
3. **Gate 3, 4, 5 are skill-level checks** the agent runs in its
   context. The bench simulates the disk-read cost; actual cost in a
   real session is the agent's reasoning time, which is dominated by
   the LLM call, not the file read.
4. **Single-host benchmark.** Numbers will differ on Linux, Windows,
   and other macOS versions. Re-run on the target host.
