---
name: safety-check
description: Use as the FIRST skill before any other superpowers skill and before any non-trivial task. Mandatory preflight that runs hard safety gates (resource budget, command risk scan, loop/spend limits, secret scan, scope confirmation) and refuses to proceed if any gate fails. Defends computer, hardware, budget, and data.
---

# Safety Check (Mandatory Preflight)

## When to Invoke

**ALWAYS** invoke this skill FIRST when ANY of the following is true:

- About to invoke any other superpowers skill (`brainstorming`, `subagent-driven-development`, `executing-plans`, `dispatching-parallel-agents`, `systematic-debugging`, `test-driven-development`, `writing-plans`, `writing-skills`, `finishing-a-development-branch`, `using-git-worktrees`, `requesting-code-review`, `receiving-code-review`, `verification-before-completion`)
- About to run Bash, write or modify files, make network calls, dispatch subagents, run tests, run builds, or do any autonomous work
- User asks for any non-trivial task (build, refactor, deploy, run tests, batch operations)
- Combined use with `ralph-loop` is detected or likely
- A command is about to run for more than 5 minutes

**Exception**: If dispatched as a subagent with an isolated, well-scoped task, the parent agent should have already passed the gate. If you are a subagent and the gate is not documented, **run a minimal version anyway** (Gates 1 + 2 + 4) before doing anything destructive.

If you skip this skill on a task that meets the criteria above, you have failed the task.

## The 5 Safety Gates

Run gates in order. **Halt on any failure**. Never run a gate partially — pass or fail, all of it.

### Gate 1: Resource Budget

Run these checks. If any fails, **stop and ask the user to free resources**.

```bash
# Disk: need ≥ 2 GB free in working dir
df -h . | tail -1 | awk '{ if ($4+0 < 2) print "HALT: <2GB free"; else print "OK disk: "$4 }'

# Memory (macOS): need ≥ 1 GB free
vm_stat | awk '/Pages free/ { free=$3*4/1024 } /Pages inactive/ { inact=$3*4/1024 } END { tot=free+inact; if (tot<1024) print "HALT: <1GB free"; else print "OK mem: "int(tot)"MB" }'

# CPU load: 1-min load avg should be < 2× core count
sysctl -n hw.ncpu | xargs -I{} sh -c 'uptime | awk -v c={} "{ if (\$(NF-2)+0 > c*2) print \"HALT: load high\"; else print \"OK load\" }"'
```

- Disk < 2 GB → halt
- RAM < 1 GB → halt
- Load avg > 2× cores → halt

### Gate 2: Command Risk Scan

Scan the planned operations. **Refuse to run** the following without explicit user confirmation (per item):

| Pattern | Reason |
|---|---|
| `rm -rf` outside project working dir | Recursive delete outside scope |
| `rm -rf /`, `rm -rf ~`, `rm -rf ..` | Catastrophic delete |
| `dd if=/dev/(zero\|random\|urandom) of=/dev/...` | Device overwrite |
| `mkfs`, `fdisk`, `diskutil eraseDisk` | Format / erase |
| `sudo ...` (any) | Privilege escalation |
| `git push --force` to `main` / `master` | History rewrite on protected branch |
| `git reset --hard` (without explicit OK) | Discards uncommitted work |
| `git clean -fd` (without explicit OK) | Deletes untracked files |
| `chmod -R 777 /`, `chown -R` on system paths | System permission change |
| Writing to `/System`, `/Library`, `~/Library`, `/usr`, `/etc`, `/private`, `/var` | macOS / Linux system paths |
| `curl ... \| sh` / `wget ... \| bash` | Pipe-to-shell |
| `npm publish`, `pip upload`, `cargo publish` | Publish to public registry |
| `:(){ :\|:& };:` or other fork bombs | Resource exhaustion |
| Network payload > 100 MB without OK | Bandwidth / cost |
| `brew install --cask` system tools | System-level package change |

If a needed command matches, **state the command and the risk, then explicitly ask the user** before running it. Do not paraphrase the risk away.

### Gate 3: Loop / Spend Limits (autonomous work only)

When running autonomously or dispatching subagents, **enforce**:

- **Max concurrent subagents**: 3 (default)
- **Max wall-clock autonomous time before human check-in**: 30 minutes (default; user may lower or raise once explicitly)
- **Max consecutive failures of same command**: 3 — then halt and ask
- **Token spend tracking**: when cumulative cost in a session exceeds user-set threshold (default $1, $5, $10), pause and report
- **Ralph-loop interaction**: if `ralph-loop` is enabled, do NOT nest it inside `subagent-driven-development`. Run ralph-loop only on its own, with explicit user OK each time, and never let it iterate for more than 10 cycles before a hard user check-in.

If user asks to override a limit, document the override ("raising subagent cap to 6 at user request") and proceed. Never silently ignore a limit.

### Gate 4: Secret / PII Scan

Before any commit, file write, or `curl` / `wget`, scan for:

- Filenames matching: `.env`, `*.env`, `*.key`, `*id_rsa*`, `*id_ed25519*`, `credentials.json`, `secrets.*`, `*token*`, `*.pem`, `*.p12`
- Content matching: `sk-...`, `sk-ant-...`, `ghp_...`, `AKIA[0-9A-Z]{16}`, `-----BEGIN .* PRIVATE KEY-----`

If a match is found in a file about to be written or committed, **refuse and ask the user**. Never echo tokens or keys to the conversation — redact as `[REDACTED:API_KEY]` in any output.

### Gate 5: Scope Confirmation

Before doing real work, output a 3-line confirmation:

1. **What** will happen (1 sentence)
2. **Which superpowers skills** will be used (or "none, plain execution")
3. **Which operations are irreversible** (or "none")

Wait for explicit user "go" before proceeding on non-trivial tasks. For trivial tasks (single read, single grep) the gate may be implicit.

## Output Format

After all 5 gates pass, output exactly:

```
[SAFETY CLEARED]
- Resource budget: <disk> disk, <ram> RAM, <load> load
- Risk scan: <clean | N items need user OK>
- Loop limits: 3 subagents, 30 min check-in, $1/$5/$10 spend
- Secret scan: clean
- Scope: <one-line plan>
[/SAFETY CLEARED]
```

If any gate fails, output exactly:

```
[SAFETY HALTED]
- Gate <N> failed: <reason>
- Remediation: <what user needs to do>
[/SAFETY HALTED]
```

Do not proceed past a halt. Do not silently retry.

## Hard Limits (Never Override)

These limits cannot be raised by the user mid-session. They are physical / security boundaries:

1. NEVER `rm -rf` any system path (`/`, `/System`, `/Library`, `/usr`, `/etc`, `/private`, `/var`, `~/Library`)
2. NEVER `dd` to a device, `mkfs`, `diskutil eraseDisk`
3. NEVER run a fork bomb or infinite loop
4. NEVER pipe a network payload directly to a shell (`curl | sh`)
5. NEVER `git push --force` to `main` or `master`
6. NEVER `sudo` without explicit, per-command user permission
7. NEVER publish to npm / pip / cargo without explicit, per-command user permission
8. NEVER modify macOS system files (`/System`, `/Library`, `/private`, SIP-protected paths)
9. NEVER disable, bypass, or skip these checks via env vars, flags, or "just this once" reasoning
10. NEVER proceed past a `SAFETY HALTED` output — no silent retry, no "let me try once more"
11. If a check would otherwise fail, **stop and ask** — do not rationalize

## Recovery

If something has already gone wrong (process runaway, disk fill, etc.):

1. Stop dispatching new work
2. Identify the runaway (e.g. `ps aux | sort -nk 3 | tail`)
3. Kill it (`kill <pid>`, escalate to `kill -9` only with user OK)
4. Clean up artifacts (worktrees, temp files, logs)
5. Report to user with: what happened, what was killed, what is left to clean up

The user is the final safety authority. If in doubt, ask.
