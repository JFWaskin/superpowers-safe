# Rigor Checklist

> Tracks what we've done to make `superpowers-safe` look like a serious
> engineering project to maintainers, evaluators, and ourselves. Updated
> each time a tier is completed.

## Status legend

- ✅ Shipped
- 🟡 Scaffolded (infrastructure done, content not run)
- ⏳ Planned (Tier 2 or later)
- 🚫 Out of scope (we explicitly decided not to)

---

## Tier 1 — Visible engineering rigor (2026-08-08)

| Item | Status | Evidence |
|------|--------|----------|
| 1.1 RED-GREEN eval scenarios | 🟡 | 3 scenarios scaffolded in `tests/evals/scenarios/`; RED/GREEN runs not yet performed (requires 2-4 weeks + ~$30-50 API cost) |
| 1.2 THREAT-MODEL.md | ✅ | `docs/THREAT-MODEL.md` (339 lines). Explicit in-scope, out-of-scope, assumptions, failure modes, residual risk |
| 1.3 Per-runtime CI lanes | ✅ | `.github/workflows/codex-smoke.yml`, `opencode-smoke.yml`, `kimi-smoke.yml` |

### Issues found and fixed during Tier 1

1. **THREAT-MODEL.md referenced `SECURITY.md` which didn't exist** →
   created `SECURITY.md` (responsible disclosure policy, MIT-style
   fork-appropriate). Moved from "Tier 2" to "shipped" because the
   cross-reference was a real broken link.
2. **YAML indentation error in initial CI workflows** → rewrote all 3
   workflows with simpler one-line `python3 -c` invocations inside
   `run: |` blocks.
3. **Scenario YAML format is approximated** — actual
   `prime-radiant-inc/superpowers-evals` may have a different schema.
   Marked as a known issue; needs verification when scenarios are run.

## Tier 2 — Quick wins (planned)

| Item | Effort | Signal |
|------|--------|--------|
| 2.1 `SECURITY.md` | Done early (see above) | — |
| 2.2 Branch protection on `dev` | 5 min via GitHub UI | High |
| 2.3 `CODEOWNERS` | 10 min | Medium |
| 2.4 Performance benchmark (gate overhead) | 4 hours | High |
| 2.5 Compatibility matrix | 2 hours | Medium |

## Tier 3 — Long-term investments (planned)

| Item | Effort | Signal |
|------|--------|--------|
| 3.1 GitHub Releases with auto-generated notes | 1 day | Low |
| 3.2 Signed commits (GPG/SSH) | 2 hours setup | Low |
| 3.3 SBOM (zero-deps, but useful) | 1 hour | Low |
| 3.4 Devcontainer | 1 day | Low |
| 3.5 Migration guide (upstream → fork) | 4 hours | Medium |
| 3.6 Governance / RFC process | 1 day | Low |
| 3.7 Per-runtime install validation (real CLIs) | 1-2 days per runtime | High (when CLIs are non-interactive) |
| 3.8 Cross-runtime integration tests | 1 week | High |

## Out of scope (intentionally)

| Item | Why |
|------|-----|
| Token accounting (precise) | The gate's $1/$5/$10 thresholds are approximate. External API-side tracking is the user's responsibility |
| Network egress firewall | OS-level concern; the gate is at the agent reasoning level. Documented in THREAT-MODEL §4.4 |
| Sandboxing (firejail / Docker) | OS-level concern; documented in THREAT-MODEL §6.3 |
| Malicious-agent defense | The gate assumes the agent is trying to do the right thing. Malicious agents need a different solution. Documented in THREAT-MODEL §4.1 |

## What to attach to the upstream PR / discussion

When posting in `obra/superpowers#2111` or `obra/superpowers-marketplace#69`,
the rigor checklist is the proof-of-work. Suggested one-liner:

> "Added a THREAT-MODEL.md and 3 per-runtime CI lanes. Eval scenarios
> are scaffolded (3 ready to run); RED-GREEN data is the next milestone."

## What still gaps us against upstream's bar

The upstream `CLAUDE.md` is explicit:

> "If you modify skill content: ... Run adversarial pressure testing
> across multiple sessions. Show before/after eval results in your PR."

We have **scenario scaffolding** but **no actual RED-GREEN data**. Until
someone runs the 3 scenarios (or more) through Quorum, this is a gap.
The eval is the biggest remaining piece.

## Owner + timeline

- Owner: Jonathan F. Waskin (with Claude as drafting partner)
- Tier 1 shipped: 2026-08-08
- Tier 2 ETA: same session, 1-2 hours total
- Tier 3 ETA: rolling, opportunistic
- Eval first run ETA: 2-4 weeks (depends on API cost budget)
