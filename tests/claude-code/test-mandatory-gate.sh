#!/usr/bin/env bash
# Test: MANDATORY-SAFETY-GATE block in using-superpowers/SKILL.md
# Verifies that the mandatory gate block is present, in the right
# position, and references the safety-check skill.
#
# Pure file-content test (no Claude invocation). The test is deterministic
# and fast — gate wiring is a structural concern, not a behavior one.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL_FILE="$REPO_ROOT/skills/using-superpowers/SKILL.md"

echo "=== Test: MANDATORY-SAFETY-GATE block ==="
echo ""

# Test 1: File exists
echo "Test 1: using-superpowers/SKILL.md exists..."

if [ ! -f "$SKILL_FILE" ]; then
    echo "  [FAIL] using-superpowers skill file exists at $SKILL_FILE"
    exit 1
fi
echo "  [PASS] using-superpowers skill file exists"

# Test 2: MANDATORY-SAFETY-GATE block is present
echo ""
echo "Test 2: MANDATORY-SAFETY-GATE block present..."

if ! grep -q "<MANDATORY-SAFETY-GATE>" "$SKILL_FILE"; then
    echo "  [FAIL] <MANDATORY-SAFETY-GATE> block is present"
    exit 1
fi
echo "  [PASS] <MANDATORY-SAFETY-GATE> block is present"

if ! grep -q "</MANDATORY-SAFETY-GATE>" "$SKILL_FILE"; then
    echo "  [FAIL] </MANDATORY-SAFETY-GATE> closing tag is present"
    exit 1
fi
echo "  [PASS] </MANDATORY-SAFETY-GATE> closing tag is present"

# Test 3: Block is in the correct position (before EXTREMELY-IMPORTANT,
# which is the existing using-superpowers preamble)
echo ""
echo "Test 3: Block is in the correct position..."

gate_line=$(grep -n "<MANDATORY-SAFETY-GATE>" "$SKILL_FILE" | head -1 | cut -d: -f1)
important_line=$(grep -n "<EXTREMELY-IMPORTANT>" "$SKILL_FILE" | head -1 | cut -d: -f1)

if [ -z "$gate_line" ] || [ -z "$important_line" ]; then
    echo "  [FAIL] could not find both gate and important markers"
    exit 1
fi

if [ "$gate_line" -lt "$important_line" ]; then
    echo "  [PASS] gate block precedes EXTREMELY-IMPORTANT (gate at line $gate_line, important at line $important_line)"
else
    echo "  [FAIL] gate block must precede EXTREMELY-IMPORTANT (gate at line $gate_line, important at line $important_line)"
    exit 1
fi

# Test 4: Block references the safety-check skill
echo ""
echo "Test 4: Block references safety-check skill..."

# Extract the gate block
gate_block=$(awk '/<MANDATORY-SAFETY-GATE>/,/<\/MANDATORY-SAFETY-GATE>/' "$SKILL_FILE")

if echo "$gate_block" | grep -q "safety-check"; then
    echo "  [PASS] gate block references 'safety-check' skill"
else
    echo "  [FAIL] gate block must reference 'safety-check' skill"
    exit 1
fi

# Test 5: Block lists key skills that trigger the gate
echo ""
echo "Test 5: Block lists skills that trigger the gate..."

for skill in "brainstorming" "subagent-driven-development" "executing-plans" "dispatching-parallel-agents" "writing-plans" "test-driven-development" "systematic-debugging"; do
    if echo "$gate_block" | grep -q "$skill"; then
        echo "  [PASS] gate references triggering skill: $skill"
    else
        echo "  [FAIL] gate should reference triggering skill: $skill"
        exit 1
    fi
done

# Test 6: Block documents the never-override limits
echo ""
echo "Test 6: Block documents key never-override limits..."

for limit in "rm -rf" "dd" "mkfs" "fork bomb" "curl | sh" "git push --force" "sudo" "npm publish" "pip upload" "cargo publish"; do
    if echo "$gate_block" | grep -qF "$limit"; then
        echo "  [PASS] gate documents limit: $limit"
    else
        echo "  [FAIL] gate should document limit: $limit"
        exit 1
    fi
done

# Test 7: Subagent exception is documented
echo ""
echo "Test 7: Subagent exception documented..."

if echo "$gate_block" | grep -qi "subagent"; then
    echo "  [PASS] subagent exception is documented"
else
    echo "  [FAIL] subagent exception should be documented"
    exit 1
fi

# Test 8: Cross-reference to safety-check skill is correct
echo ""
echo "Test 8: Cross-reference to safety-check is correct..."

safety_skill_file="$REPO_ROOT/skills/safety-check/SKILL.md"
if [ -f "$safety_skill_file" ]; then
    echo "  [PASS] skills/safety-check/SKILL.md exists (gate references a real skill)"
else
    echo "  [FAIL] skills/safety-check/SKILL.md missing — gate references a non-existent skill"
    exit 1
fi

echo ""
echo "=== All MANDATORY-SAFETY-GATE tests passed ==="
