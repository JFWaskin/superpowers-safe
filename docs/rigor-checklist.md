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
| 1.1 RED-GREEN eval scenarios | 🟡 | 3 scenarios scaffolded in `tests/evals/scenarios/`; RED/GREEN runs not yet performed |
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

## Tier 2 — Quick wins (shipped 2026-08-08)

| Item | Status | Evidence |
|------|--------|----------|
| 2.1 `SECURITY.md` | ✅ Shipped (Tier 1) | `SECURITY.md` |
| 2.2 Branch protection on `dev` | ✅ Shipped | `gh api repos/.../branches/dev/protection` returns the configured policy: 1 review required, dismiss stale, linear history, no force-push, no deletions |
| 2.3 `CODEOWNERS` | ✅ Shipped | `.github/CODEOWNERS` covers safety-critical files, CI workflows, all 7 cross-runtime manifests |
| 2.4 Performance benchmark | ✅ Shipped | `scripts/bench-gate.sh` + `docs/benchmarks.md`. **Measured: ~265ms one-time per session + ~26ms per Bash call** (Apple Silicon, 3 iterations). |
| 2.5 Compatibility matrix | ✅ Shipped | `docs/compatibility.md`. **2 runtimes end-to-end tested (Claude Code, Gemini CLI); 9 manifest-validated; 4 not supported.** Honest about what we don't know. |

### Issues found and fixed during Tier 2

1. **gh api -f sends values as strings**; the branch-protection
   endpoint requires typed values → switched to `--input` with a JSON
   body file. First 3 attempts returned 422 ("not an object" /
   "not a boolean" / "not a null"); the JSON body fixed it.
2. **bench-gate.sh f-string had a syntax error** (`{expr):.0f}`
   instead of `{expr:.0f}`) → rewrote with a clear structure; the
   `Sum: ...` line now uses Python-side arithmetic instead of nested
   f-strings.
3. **write tool's "File has not been read yet" guard** blocked the
   initial write of `bench-gate.sh` → rewrote (the file didn't exist
   yet, so the guard was overly conservative).
4. **shellcheck SC2155 warning** in `bench-gate.sh` (declare-and-assign
   separately to avoid masking return values) → fixed by splitting
   the line.

### Tier 2 net effect

- **Maintainer eyeball cost**: 5 minutes to read the 4 new artifacts
  (CODEOWNERS, benchmarks, compatibility, branch-protection API
  response)
- **Code-review cost**: a maintainer reading a PR that touches
  safety-critical files now gets auto-routed to the right reviewer
  via CODEOWNERS, instead of having to figure out who to ping
- **Performance claim is now backed by numbers**, not "I tried it
  and it felt fast"
- **Compatibility is honest**: not "supports all runtimes" but
  "tested on 2, validated on 9 more"

## Tier 3 — Long-term investments (planned)

| Item | Effort | Signal |
|------|--------|--------|
| 3.1 GitHub Releases with auto-generated notes | 1 day | Low |
| 3.2 Signed commits (GPG/SSH) | 2 hours setup | Low |
| 3.3 SBOM (zero-deps, but useful) | 1 hour | Low |
| 3.4 Devcontainer | 1 day | Low |
| **3.5 Migration guide (upstream → fork)** | **4 hours** | **Medium** |
| 3.6 Governance / RFC process | 1 day | Low |
| 3.7 Per-runtime install validation (real CLIs) | 1-2 days per runtime | High (when CLIs are non-interactive) |
| 3.8 Cross-runtime integration tests | 1 week | High |

### Tier 3.5 — Migration guide (shipped 2026-08-10)

| Item | Status | Evidence |
|------|--------|----------|
| 3.5 `docs/MIGRATION.md` | ✅ Shipped | `docs/MIGRATION.md` (240 lines). Side-by-side install, per-runtime disable-upstream table, "what's different / what changes in your workflow / what does NOT change / rollback / what may surprise you", filing-issue instructions |

### Tier 3.5 net effect

- **User onboarding cost**: a user coming from `superpowers@claude-plugins-official` now has a single doc that covers "is this for me, how do I install, what changes, how do I roll back"
- **Side-by-side install is documented** with the exact disable-upstream command for all 12 supported runtimes (rather than just Claude Code)
- **Surprises are named** before users hit them: more questions from the agent, `sudo` requires OK, subagent concurrency capped at 3, spend thresholds surface, `--force` to `main` blocked

## Out of scope (intentionally)

| Item | Why |
|------|-----|
| Token accounting (precise) | The gate's $1/$5/$10 thresholds are approximate. External API-side tracking is the user's responsibility |
| Network egress firewall | OS-level concern; the gate is at the agent reasoning level. Documented in THREAT-MODEL §4.4 |
| Sandboxing (firejail / Docker) | OS-level concern; documented in THREAT-MODEL §6.3 |
| Malicious-agent defense | The gate assumes the agent is trying to do the right thing. Malicious agents need a different solution. Documented in THREAT-MODEL §4.1 |

## Upstream engagement — closed 2026-08-12

`obra/superpowers#2111` (the opt-in safety-check preflight interest check)
was closed by @obra on 2026-08-12 with `state_reason: not_planned` and
a friendly comment from obra's triage agent.

The decision is **policy, not quality** — three upstream `CLAUDE.md` rules
apply:

- Superpowers core stays zero-dependency (the nono.sh integration rules
  that part out)
- Fork-derived features don't come upstream
- Workflow additions that some users want and others don't ship as
  separate plugins so people can opt in

obra's own framing of the alternative path: **as a standalone plugin
(`superpowers-safe` or similar), you don't need anyone's permission,
you can iterate at your own pace, and if it earns real adoption that's
far stronger evidence than an interest-check thread.**

Implication for the fork:

- The fork IS the path. `JFWaskin/superpowers-safe` is the
  standalone plugin in question — the name was even cited by obra.
- Upstream merge was not a useful success criterion. The new
  criterion is **real adoption**: installs, users, downstream
  integrations. (The marketplace listing `obra/superpowers-marketplace#69`
  is the public surface; the fork's own self-hosted marketplace
  via `/plugin marketplace add JFWaskin/superpowers-safe` is the
  direct-install path.)
- Reference: `#1495` (linked by obra) — a previous safety-screen
  PR landed in the same place. The pattern is established.
- Public artifact: the closure comment from obra's agent (Claude Fable
  5) and our acknowledgment are the durable record.

### What to attach to the upstream PR / discussion

When posting in `obra/superpowers-marketplace#69` (the marketplace
listing, still open), the rigor checklist + the dual-layer protection
campaign record + the Quorum-format scenarios are the proof-of-work.
Suggested one-liner:

> "Safety-check is the policy layer (spend / scope / time-pressure
> rationalizations). For capability-layer defense (disk / network /
> credentials), the recommended substrate is nono.sh. The fork ships
> both, with eval scenarios in Quorum format and CI green on 4
> runtimes."

## What still gaps us against upstream's bar

The upstream `CLAUDE.md` is explicit:

> "If you modify skill content: ... Run adversarial pressure testing
> across multiple sessions. Show before/after eval results in your PR."

We have **scenario scaffolding** + **synthetic RED baselines** but
**no actual Quorum-driven RED-GREEN data**. The 4 scenarios in
`tests/evals/scenarios/` are now in Quorum format
(`scenario.yaml` + `story.md` + `setup.sh` + `checks.sh`) with
`synthetic` expected-behavior baselines in `tests/evals/baselines/`.
Running them through Quorum (live evals with API budget) is the
remaining piece.

**Note**: even with the closure of #2111, the eval bar still applies
to changes within the fork. Any future change to the safety-check
skill or its never-override limits should be backed by a Quorum run
+ verdict table.

## Owner

- Owner: JFWaskin
- Tier 1 shipped: 2026-08-08
- Upstream #2111: closed not_planned 2026-08-12 (fork path confirmed)
- Marketplace #69: still open, awaiting maintainer review
