#!/usr/bin/env bash
# Test: safety-check skill
# Verifies that the safety-check skill exists, has the required structure,
# and is discoverable by Claude.
#
# This test combines static file-content checks (fast, deterministic) with
# one Claude invocation to verify the skill is loaded into context.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

CLAUDE_PROMPT_TIMEOUT="${CLAUDE_PROMPT_TIMEOUT:-90}"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL_FILE="$REPO_ROOT/skills/safety-check/SKILL.md"

echo "=== Test: safety-check skill ==="
echo ""

# Test 1: File exists and is non-empty
echo "Test 1: File existence and content..."

if [ ! -f "$SKILL_FILE" ]; then
    echo "  [FAIL] safety-check skill file exists at $SKILL_FILE"
    exit 1
fi
echo "  [PASS] safety-check skill file exists"

if [ ! -s "$SKILL_FILE" ]; then
    echo "  [FAIL] safety-check skill file is not empty"
    exit 1
fi
echo "  [PASS] safety-check skill file is non-empty"

# Test 2: Frontmatter is present and well-formed
echo ""
echo "Test 2: Frontmatter..."

if ! head -1 "$SKILL_FILE" | grep -q "^---$"; then
    echo "  [FAIL] frontmatter starts with ---"
    exit 1
fi
echo "  [PASS] frontmatter starts with ---"

if ! grep -q "^name: safety-check$" "$SKILL_FILE"; then
    echo "  [FAIL] frontmatter has 'name: safety-check'"
    exit 1
fi
echo "  [PASS] frontmatter has 'name: safety-check'"

if ! grep -q "^description: " "$SKILL_FILE"; then
    echo "  [FAIL] frontmatter has 'description:'"
    exit 1
fi
echo "  [PASS] frontmatter has 'description:'"

# Test 3: All 5 gates are documented
echo ""
echo "Test 3: 5 safety gates documented..."

for gate in "Resource Budget" "Command Risk Scan" "Loop / Spend Limits" "Secret / PII Scan" "Scope Confirmation"; do
    if grep -q "### Gate .*: $gate\|### Gate [0-9].*$gate" "$SKILL_FILE"; then
        echo "  [PASS] gate documented: $gate"
    else
        echo "  [FAIL] gate missing: $gate"
        exit 1
    fi
done

# Test 4: Never-override hard limits are present (at least 10)
echo ""
echo "Test 4: Never-override hard limits..."

hard_limits_count=$(grep -cE "^[0-9]+\. NEVER " "$SKILL_FILE" || true)
if [ "$hard_limits_count" -lt 10 ]; then
    echo "  [FAIL] expected ≥ 10 NEVER lines, found $hard_limits_count"
    exit 1
fi
echo "  [PASS] found $hard_limits_count NEVER lines (≥ 10 required)"

# Verify the 10 documented limits are all present
for limit in "rm -rf" "dd" "mkfs" "fork bomb" "curl | sh" "git push --force" "sudo" "npm / pip / cargo" "macOS system files" "disable, bypass, or skip"; do
    if grep -q "$limit" "$SKILL_FILE"; then
        echo "  [PASS] limit referenced: $limit"
    else
        echo "  [FAIL] limit missing: $limit"
        exit 1
    fi
done

# Test 5: Output format block is documented
echo ""
echo "Test 5: Output format..."

if ! grep -q "\[SAFETY CLEARED\]" "$SKILL_FILE"; then
    echo "  [FAIL] [SAFETY CLEARED] output block documented"
    exit 1
fi
echo "  [PASS] [SAFETY CLEARED] output block documented"

if ! grep -q "\[SAFETY HALTED\]" "$SKILL_FILE"; then
    echo "  [FAIL] [SAFETY HALTED] output block documented"
    exit 1
fi
echo "  [PASS] [SAFETY HALTED] output block documented"

# Test 6: Claude recognizes the skill
echo ""
echo "Test 6: Claude discovers safety-check skill..."

output=$(run_claude "What is the safety-check skill? Describe its 5 gates briefly." "$CLAUDE_PROMPT_TIMEOUT")

if assert_contains "$output" "safety-check" "Skill is recognized by name"; then
    : # pass
else
    exit 1
fi

# Verify Claude mentions key gate concepts
for concept in "resource" "command" "secret" "scope"; do
    if assert_contains "$output" "$concept" "Mentions '$concept' gate concept"; then
        : # pass
    else
        exit 1
    fi
done

echo ""
echo "=== All safety-check tests passed ==="
