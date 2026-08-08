# Threat Model

> Engineering specification of what the safety gate defends against, what it
> does NOT defend against, and the assumptions and failure modes of the
> gate itself. Companion to [`safety-gate.md`](safety-gate.md) (gate
> specification) and [`../skills/safety-check/SKILL.md`](../skills/safety-check/SKILL.md)
> (the implementation).
>
> This document is intentionally honest about limits. A threat model that
> over-claims is worse than no threat model — it gives users false
> confidence.

## 1. Purpose

The safety gate is a front door for Superpowers sessions. It runs five
hard gates before any other Superpowers skill. This document states,
explicitly:

- what kinds of damage the gate prevents
- what kinds of damage it does NOT prevent
- the assumptions we make about the agent and the host
- the ways the gate itself can fail
- the residual risk after the gate passes

The goal is for a reader to be able to make a clear yes/no decision
about whether the gate is appropriate for their environment.

## 2. Threat model scope

| Layer | Status | Documented in |
|-------|--------|---------------|
| Skill-level gate (`safety-check` SKILL.md) | ✅ shipped | `../skills/safety-check/SKILL.md` |
| Tool-level hook (`PreToolUse` Bash) | ✅ shipped | [`safety-gate.md#defense-in-depth`](safety-gate.md) |
| Outbound network restriction | ❌ NOT shipped | §4 below |
| Sandboxing (filesystem, syscalls) | ❌ NOT shipped | §4 below |
| Per-session token accounting | 🟡 partial (in skill, not enforced) | §5 below |

The gate operates **at the agent reasoning level** (does the agent
read and follow the safety check output?) and **at the tool-call level**
(does the hook block destructive bash?). It does **not** operate at the
operating-system level.

## 3. Threats we defend against

Each threat is mapped to the gate(s) that address it. Gate names refer
to [`safety-check/SKILL.md`](../skills/safety-check/SKILL.md#the-5-safety-gates).

### 3.1 Destructive filesystem operations

| Threat | Gate | Notes |
|--------|------|-------|
| `rm -rf` outside project working dir | Gate 2 (Command risk) | Hard-blocked by the tool-level hook; refused at skill level |
| `rm -rf /`, `rm -rf ~`, `rm -rf ..` | Gate 2 | Hard-blocked |
| `rm -rf` on macOS system paths (`/System`, `/Library`, etc.) | Gate 2 | Hard-blocked |
| `dd if=/dev/zero` to a device | Gate 2 | Hard-blocked |
| `mkfs` / `diskutil eraseDisk` | Gate 2 | Hard-blocked |
| Fork bombs (`:(){ :\|:& };:`) | Gate 2 | Hard-blocked |

### 3.2 Remote code execution

| Threat | Gate | Notes |
|--------|------|-------|
| `curl ... \| sh` / `wget ... \| bash` | Gate 2 | Hard-blocked by the hook; the install-script pathway is the highest-volume remote-code-execution vector in agent workflows |
| `npm install` of untrusted packages | 🟡 gate 2 warns (no auto-block) | Out of scope for full block; users with stricter needs should add an `npm install` block to Gate 2 |

### 3.3 Resource exhaustion

| Threat | Gate | Notes |
|--------|------|-------|
| Disk fill via runaway logging | Gate 1 (Resource budget) | Refuses to start if <2GB free; loop in Gate 3 catches growth |
| Memory exhaustion from large processing | Gate 1 | Refuses to start if <1GB free (macOS `vm_stat`) |
| CPU thrash from fork bombs | Gate 2 | Hard-blocked at command level |
| Runaway subagent dispatch (token spend) | Gate 3 | 3 concurrent default; 30-min check-in; $1/$5/$10 spend thresholds |

### 3.4 Secret leakage

| Threat | Gate | Notes |
|--------|------|-------|
| Committing `.env`, `*.key`, `id_rsa`, `*.pem` | Gate 4 (Secret scan) | Pre-write filename + content match |
| Echoing API keys / tokens to conversation output | Gate 4 | Pre-write content scan |
| Writing credentials to a public file path | Gate 2 | Path-based check catches obvious cases |

### 3.5 Scope creep

| Threat | Gate | Notes |
|--------|------|-------|
| Agent starts work on a "simple" task that turns out to be a 4-hour autonomous refactor | Gate 5 (Scope confirmation) | Forces 1-line plan + explicit "go" before non-trivial work |
| Agent expands scope beyond user's stated intent | Gate 3 | 30-min autonomous check-in forces re-confirmation |
| Agent continues after user said "stop" | Gate 3 | Re-anchors to user on each check-in |

## 4. Threats we do NOT defend against

This section is the most important. If your environment requires defense
against any of these, the safety gate is **not sufficient** and you need
additional layers.

### 4.1 Malicious or compromised agent

The gate assumes the agent is **trying to do the right thing** but may
make mistakes or be subject to prompt injection. The gate does **not**
defend against:

- An agent that is actively malicious and reads the gate output but
  intentionally ignores it
- An agent that has been compromised (e.g. via a poisoned skill file)
  and tries to evade the gate
- An agent that has been fine-tuned to bypass the gate

If your threat model includes a malicious agent, you need sandboxing
(see §6.3) and not just the safety gate.

### 4.2 Prompt injection from external content

The gate does not sanitize content that the agent reads from external
sources (web pages, GitHub issues, files in the repo). An attacker can
plant text that, when read by the agent, manipulates the agent into
ignoring or modifying the gate. Mitigations:

- Use the upstream Superpowers' "Be paranoid about prompt injection"
  guidance
- Don't paste untrusted content into the agent's context without review
- Run the agent with restricted network access (out of scope for the
  gate, but the gate documents this need)

### 4.3 Compromised dependencies

The gate does not audit `pip install`, `npm install`, `brew install`,
or other dependency-resolution operations. A compromised package can
execute arbitrary code on install. Mitigations:

- Pin versions, use lockfiles
- Review package sources before install
- Use sandboxing for untrusted package installs

### 4.4 Outbound network exfiltration

The gate does not restrict outbound network calls. An agent can
`curl` arbitrary URLs to upload data, exfiltrate secrets, or call
attacker-controlled endpoints. Mitigations:

- Network egress firewall (out of scope for the gate)
- DNS-level restrictions
- Outbound proxy that logs all calls

### 4.5 Side-channel leakage

The gate does not protect against:

- Shoulder-surfing the terminal
- Disk-level encryption being absent (an attacker with physical access
  can read everything)
- Swap/pagefile containing secret material
- Process memory dumps

These are operating-system / hardware concerns outside the gate's
scope.

### 4.6 Other agents / processes on the same host

The gate does not protect against:

- A second agent on the same machine interfering with the first
- A non-agent process (e.g. a background `cron` job) modifying files
  the agent is working on
- A malicious user logged in via another shell

Use OS-level isolation (containers, separate users, namespaces) if
these are in your threat model.

## 5. Assumptions

The gate works correctly **only if** these assumptions hold:

| # | Assumption | What breaks it |
|---|------------|---------------|
| A1 | The agent reads the `<MANDATORY-SAFETY-GATE>` block in `using-superpowers/SKILL.md` | Plugin not properly installed; SKILL.md content ignored |
| A2 | The agent invokes the `safety-check` skill before any other superpowers skill | Agent bypasses the gate (this is the most likely failure) |
| A3 | The agent respects the `[SAFETY HALTED]` output and does not silently retry | Agent ignores halt; tries again with the same command |
| A4 | The PreToolUse hook is registered in `~/.claude/settings.json` | Hook not installed; gate degrades to skill-level only |
| A5 | The host has a working shell, `df`, `vm_stat` (macOS) or `free` (Linux), and `sysctl` or `/proc/loadavg` | Resource check fails; gate cannot verify budget |
| A6 | The agent's session log is preserved across the safety-check invocation | Session state lost; gate result is unreliable |
| A7 | The user reviews the `[SAFETY CLEARED]` block before giving "go" | User rubber-stamps without reading; gate is theater |

If any of these assumptions break, the gate's effectiveness is
**unquantifiably degraded**. The agent may still behave correctly by
accident, but the gate provides no guarantee.

## 6. Failure modes of the gate itself

Even when all assumptions hold, the gate can fail in the following ways:

### 6.1 Pattern-based bypasses

Gate 2 (Command risk) uses **regex patterns** to detect destructive
bash. Regexes can be bypassed by:

- **Encoding tricks**: `r\u006d -rf /` (Unicode escapes that the shell
  may interpret)
- **Whitespace tricks**: `rm\u0020-rf /` or `rm - rf /` (the hook
  requires `-rf` as a contiguous token)
- **Quoting tricks**: `r""m -rf /`
- **Eval chains**: `$(echo "rm -rf /")` or `bash -c "rm -rf /"`
- **Alternate commands**: `find / -delete`, `python -c "import shutil; shutil.rmtree('/')"`
- **Shell built-ins**: `cd /; rm -rf *`

The current hook covers the most common patterns. The companion
`safety-check` skill instructs the agent to refuse the *intent* of a
command even if it doesn't match a pattern, but this depends on the
agent reading and following the instruction (see A2, A3).

**Mitigation**: the hook is updated as new bypass patterns are
discovered. Users who find bypasses should report them via
[`SECURITY.md`](../SECURITY.md) (responsible disclosure).

### 6.2 Tool-level hook can be disabled

The PreToolUse hook is registered in `~/.claude/settings.json`. A user
or process that can write to this file can disable the hook. The
gate degrades to skill-level only.

**Mitigation**: gate the file with OS-level permissions; monitor for
changes; consider OS-level audit logging.

### 6.3 No OS-level isolation

The gate runs in the same process tree as the agent. It cannot prevent
the agent from:

- Modifying its own SKILL.md to remove the gate
- Modifying the hook's Python source to bypass pattern matching
- Writing to memory locations that survive session restarts and
  re-inject malicious instructions

**Mitigation**: for high-stakes work, use a sandbox (Docker, firejail,
macOS sandbox-exec) so the agent cannot escape its working
environment.

### 6.4 Time-of-check vs time-of-use

Gate 1 (Resource budget) checks disk/RAM/CPU at one moment. By the
time the agent runs a command 30 minutes later, the resource state
may have changed. There is no continuous monitoring.

**Mitigation**: the skill instructs the agent to re-check resources
if it intends a long-running operation. Users with strict budgets
should add external monitoring (OS-level resource alerts).

### 6.5 Token spend measurement is approximate

Gate 3's "spend threshold" assumes the agent can track its own token
usage. The agent's self-report is approximate; actual spend may differ
by 10-30%. The thresholds ($1, $5, $10) are conservative to absorb
this variance.

**Mitigation**: external API-side tracking (e.g. via the API
provider's dashboard) is more accurate.

## 7. Residual risk

After the gate passes, the following risks remain:

| Category | Residual risk | Acceptable for |
|----------|---------------|----------------|
| Unintended file modification | Low | Personal projects, internal tools |
| Destructive bash | Very low (with hook); Low (without) | All non-malicious use cases |
| Runaway subagent dispatch | Low (with check-ins) | Long-running autonomous work |
| Secret leakage | Low | Most code repos; not for high-compliance environments |
| Network exfiltration | **High** (gate does nothing here) | Never acceptable without external controls |
| Compromised package install | **High** | Never acceptable without external controls |
| Malicious agent | **Unmitigated** | Acceptable for trusted agents only |

The safety gate is appropriate for:

- Personal development workflows
- Team-internal coding agents
- Long-running autonomous work where you want sanity-check anchors

The safety gate is **not** appropriate for:

- Compliance-regulated environments (HIPAA, SOC2, etc.) without
  additional layers
- Running untrusted agents
- Work involving sensitive data without OS-level isolation
- Work where the agent has direct production access

## 8. Defense in depth

The gate is one layer in a stack. The recommended full stack is:

| Layer | What it adds | Out of scope for this gate? |
|-------|--------------|-----------------------------|
| **1. Safety gate (this)** | Reasoning-time check + tool-level block | ✅ |
| **2. OS-level sandbox** | `sandbox-exec` (macOS) / `firejail` (Linux) / Docker | ❌ not provided |
| **3. Network egress firewall** | Restrict outbound to known hosts | ❌ not provided |
| **4. Filesystem mount restrictions** | Read-only mounts for system paths | ❌ not provided |
| **5. Audit log** | Record every action with timestamp + actor | ❌ not provided |
| **6. User review checkpoint** | Periodic human-in-the-loop on long sessions | 🟡 partially (Gate 3) |
| **7. External token accounting** | API-side usage dashboard | ❌ not provided |

If your environment needs layer 2-7, **build them separately**. The
safety gate assumes layers 1 and (for non-trivial work) 6 are present
but does not enforce the others.

## 9. Reporting bypasses

If you find a way to bypass the gate (a command pattern the hook
misses, an assumption the skill makes that the agent violates, a
false-negative that lets a destructive operation through), please
report it responsibly per [`SECURITY.md`](../SECURITY.md). We will:

1. Acknowledge within 72 hours
2. Triage and write a fix within 1 week for high-severity bypasses
3. Credit you in the CHANGELOG (if you want)
4. Coordinate a public disclosure timing

## 10. Versioning

This threat model is versioned with the fork. Changes to:

- **§3 (Threats we defend against)** — MINOR version bump (adding
  threats covered)
- **§4 (Threats we do NOT defend against)** — MAJOR version bump if
  shrinking; MINOR if expanding
- **§5 (Assumptions)** — MAJOR version bump (changing assumptions is
  a fundamental change in how the gate works)
- **§6 (Failure modes)** — MINOR version bump

See [`CHANGELOG.md`](../CHANGELOG.md) for the version history.

## 11. Cross-references

- [`safety-gate.md`](safety-gate.md) — the gate specification
- [`eval-protocol.md`](eval-protocol.md) — RED-GREEN-REFACTOR protocol
  for validating that the gate actually catches what it claims
- [`../skills/safety-check/SKILL.md`](../skills/safety-check/SKILL.md) — the
  implementation
- [`../SECURITY.md`](../SECURITY.md) — responsible disclosure policy
- [`sync-upstream.md`](sync-upstream.md) — how this fork stays
  current with upstream Superpowers
