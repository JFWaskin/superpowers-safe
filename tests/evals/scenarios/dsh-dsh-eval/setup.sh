#!/bin/bash
# Pre-checks for dsh-dsh-eval

pre() {
    # Verify the safety-check skill is loadable through the bridge path
    # (the bridge itself isn't on the test host, but the SKILL.md file
    # that the bridge would expose must exist with valid frontmatter).
    SKILL=/Users/jonathanwaskin/code/superpowers-safe/skills/safety-check/SKILL.md
    [ -f "$SKILL" ] || { echo "FAIL: missing $SKILL"; return 1; }

    head -1 "$SKILL" | grep -q -- "---" || {
        echo "FAIL: $SKILL missing opening frontmatter fence"
        return 1
    }

    # Confirm the skill's name is a single token (the bridge passes
    # the bare name to DeepSeek's ctx.skills registry, which expects
    # a single token — no colons, no slashes, no spaces).
    NAME=$(awk '/^---$/{c++; next} c==1 && /^name:/{print $2; exit}' "$SKILL")
    case "$NAME" in
        *:*|*/*|*' '*) echo "FAIL: skill name '$NAME' has invalid chars for DeepSeek ctx.skills"; return 1 ;;
    esac
    [ -n "$NAME" ] || { echo "FAIL: no name in frontmatter"; return 1; }

    # Confirm the deepseek-harness-bridge is present in the fork
    BRIDGE=/Users/jonathanwaskin/code/superpowers-safe/fork/deepseek-harness-bridge/cordis.yml
    [ -f "$BRIDGE" ] || { echo "FAIL: missing $BRIDGE"; return 1; }

    # Confirm the prereq analysis doc exists
    ANALYSIS=/Users/jonathanwaskin/code/superpowers-safe/docs/upstream/deepseek-harness-analysis.md
    [ -f "$ANALYSIS" ] || { echo "FAIL: missing $ANALYSIS"; return 1; }

    echo "OK: dsh-dsh-eval pre-checks passed (skill=$NAME, bridge present, analysis present)"
    return 0
}

pre
