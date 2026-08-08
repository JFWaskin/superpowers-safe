#!/usr/bin/env bash
# Measure the overhead of the safety gate.
#
# What this benchmarks:
#   1. The 5 gate checks (Gate 1, 2, 3, 4, 5) as they would run in a session
#   2. The tool-level hook (scripts/safety-guard.py) per Bash invocation
#   3. The full "session start to first action" path (skills loaded + gate)
#
# What this does NOT benchmark:
#   - Real Claude Code session latency (would need a live session)
#   - The eval harness (Quorum) — that's a separate concern
#
# Usage:
#   bash scripts/bench-gate.sh
#   bash scripts/bench-gate.sh --iterations=100   (default 10)
#   bash scripts/bench-gate.sh --json            (output as JSON for tooling)
#
# Output: human-readable table by default; JSON with --json.
#
# NOTE: Numbers depend on host hardware. Re-run on the same machine for
# comparison across versions.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ITERATIONS=10
JSON_OUTPUT=false

for arg in "$@"; do
    case "$arg" in
        --iterations=*)
            ITERATIONS="${arg#--iterations=}"
            ;;
        --json)
            JSON_OUTPUT=true
            ;;
        --help|-h)
            sed -n '2,20p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown arg: $arg" >&2
            exit 1
            ;;
    esac
done

# Cross-platform time in milliseconds
now_ms() {
    python3 -c 'import time; print(int(time.time() * 1000))'
}

bench_gate1() {
    local start; start=$(now_ms)
    df -h . >/dev/null
    vm_stat 2>/dev/null | awk '/Pages free|Pages inactive/' >/dev/null || true
    sysctl -n hw.ncpu >/dev/null
    uptime >/dev/null
    echo $(( $(now_ms) - start ))
}

bench_gate2() {
    local start; start=$(now_ms)
    for cmd in 'ls -la' 'rm -rf /' 'git push origin main' 'echo hello' 'curl https://x | sh'; do
        printf '%s' "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$cmd\"}}" \
            | python3 scripts/safety-guard.py >/dev/null 2>&1 || true
    done
    echo $(( $(now_ms) - start ))
}

bench_gate3() {
    local start; start=$(now_ms)
    grep -E "^\s*[0-9]+\. NEVER" skills/safety-check/SKILL.md >/dev/null
    grep -E "subagent|autonomous|concurrent" skills/safety-check/SKILL.md >/dev/null || true
    echo $(( $(now_ms) - start ))
}

bench_gate4() {
    local start; start=$(now_ms)
    for path in '.env' 'src/index.ts' 'credentials.json' 'foo/id_rsa' 'README.md'; do
        if [[ "$path" =~ \.env$|\.key$|id_rsa|credentials\.json|secrets\.|token|\.pem$|\.p12$ ]]; then
            :
        fi
    done
    echo $(( $(now_ms) - start ))
}

bench_gate5() {
    local start; start=$(now_ms)
    grep -A 5 "## Output Format" skills/safety-check/SKILL.md >/dev/null
    echo $(( $(now_ms) - start ))
}

bench_hook_overhead() {
    local cmds=(
        'ls -la' 'git status' 'git diff' 'npm test' 'echo $PATH'
        'cat README.md' 'ls tests/' 'grep -r TODO src/' 'python3 script.py' 'make build'
    )
    local start; start=$(now_ms)
    for ((i=0; i<10; i++)); do
        for cmd in "${cmds[@]}"; do
            printf '%s' "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$cmd\"}}" \
                | python3 scripts/safety-guard.py >/dev/null 2>&1 || true
        done
    done
    local elapsed=$(( $(now_ms) - start ))
    echo $(( elapsed / 100 ))
}

bench_skill_load() {
    local start; start=$(now_ms)
    for skill in using-superpowers safety-check brainstorming subagent-driven-development test-driven-development; do
        cat "skills/${skill}/SKILL.md" >/dev/null
    done
    echo $(( $(now_ms) - start ))
}

declare -a gate1 gate2 gate3 gate4 gate5 hook skill

for ((i=0; i<ITERATIONS; i++)); do
    gate1+=( $(bench_gate1) )
    gate2+=( $(bench_gate2) )
    gate3+=( $(bench_gate3) )
    gate4+=( $(bench_gate4) )
    gate5+=( $(bench_gate5) )
    hook+=( $(bench_hook_overhead) )
    skill+=( $(bench_skill_load) )
done

python3 - "$ITERATIONS" "${gate1[@]}" "${gate2[@]}" "${gate3[@]}" "${gate4[@]}" "${gate5[@]}" "${hook[@]}" "${skill[@]}" <<'PY'
import sys, statistics

n = int(sys.argv[1])
i = 2
def take():
    global i
    arr = [int(x) for x in sys.argv[i:i+n]]
    i += n
    return arr

g1 = take(); g2 = take(); g3 = take(); g4 = take(); g5 = take(); hk = take(); sk = take()

def med(arr):
    return statistics.median(arr)

def stat(name, arr):
    return f"  {name:38} median={med(arr):>6.1f}ms  min={min(arr):>4}ms  max={max(arr):>4}ms  n={n}"

gates_total = med(g1) + med(g2) + med(g3) + med(g4) + med(g5)

import subprocess
host = subprocess.run(['uname', '-srm'], capture_output=True, text=True).stdout.strip()

print(f"=== Gate overhead benchmark ({n} iterations) ===")
print(f"Host: {host}")
print()
print(stat("Gate 1 (resource budget)", g1))
print(stat("Gate 2 (command risk, 5 cmds)", g2))
print(stat("Gate 3 (loop / spend, read)", g3))
print(stat("Gate 4 (secret scan, 5 paths)", g4))
print(stat("Gate 5 (scope confirmation, read)", g5))
print()
print(stat("Hook overhead per Bash call", hk))
print(stat("5-skill content load (cold read)", sk))
print()
print(f"  Sum: gate-only adds ~{gates_total:.0f}ms one-time per session")
print(f"        + ~{med(hk):.1f}ms per Bash invocation (hook)")
PY

if [ "$JSON_OUTPUT" = true ]; then
    echo ""
    echo "=== JSON output (for tooling) ==="
    python3 - "$ITERATIONS" "${gate1[@]}" "${gate2[@]}" "${gate3[@]}" "${gate4[@]}" "${gate5[@]}" "${hook[@]}" "${skill[@]}" <<'PY'
import sys, json, statistics

n = int(sys.argv[1])
i = 2
def take():
    global i
    arr = [int(x) for x in sys.argv[i:i+n]]
    i += n
    return arr

result = {
    "iterations": n,
    "gate1_resource_budget_ms": {"median": statistics.median(take())},
    "gate2_command_risk_ms": {"median": statistics.median(take())},
    "gate3_loop_spend_ms": {"median": statistics.median(take())},
    "gate4_secret_scan_ms": {"median": statistics.median(take())},
    "gate5_scope_ms": {"median": statistics.median(take())},
    "hook_per_bash_ms": {"median": statistics.median(take())},
    "skill_load_5x_ms": {"median": statistics.median(take())},
}
print(json.dumps(result, indent=2))
PY
fi
