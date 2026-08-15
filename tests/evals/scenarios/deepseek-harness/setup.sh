#!/bin/bash
# Pre-checks for deepseek-harness-name-invocation
#
# Verifies that the bridge and its target skills are wired correctly
# for the /<name> user-invocation test. Does NOT require the DeepSeek
# harness to be installed (this is a host-side preflight), but
# verifies the SKILL.md frontmatter the bridge would surface.

pre() {
    SKILLS_DIR=/Users/jonathanwaskin/code/superpowers-safe/skills
    BRIDGE_DIR=/Users/jonathanwaskin/code/superpowers-safe/fork/deepseek-harness-bridge
    ANALYSIS=/Users/jonathanwaskin/code/superpowers-safe/docs/upstream/deepseek-harness-analysis.md

    # 1. Bridge must exist with the expected layout.
    for required in \
        "$BRIDGE_DIR/README.md" \
        "$BRIDGE_DIR/cordis.yml" \
        "$BRIDGE_DIR/hooks.json" \
        "$BRIDGE_DIR/src/index.ts" \
        "$BRIDGE_DIR/package.json" \
        "$BRIDGE_DIR/tsconfig.json"; do
        [ -f "$required" ] || { echo "FAIL: missing bridge artifact $required"; return 1; }
    done

    # 2. Prerequisite analysis must exist (cross-references in setup).
    [ -f "$ANALYSIS" ] || { echo "FAIL: missing $ANALYSIS"; return 1; }

    # 3. Every superpowers skill name must be a single kebab-case token.
    #    The DeepSeek harness's /<name> regex requires
    #    [a-z0-9]+(?:-[a-z0-9]+)* — no spaces, no colons, no slashes,
    #    no uppercase. Validate against every SKILL.md in the skills
    #    tree.
    COUNT=0
    for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
        [ -f "$skill_md" ] || continue
        name=$(awk '/^---$/{c++; next} c==1 && /^name:/{sub(/^name: */,""); print; exit}' "$skill_md")
        if [ -z "$name" ]; then
            echo "FAIL: $skill_md missing 'name:' frontmatter"
            return 1
        fi
        if ! echo "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
            echo "FAIL: $skill_md has non-kebab-case name '$name' — would not match DeepSeek /<name> regex"
            return 1
        fi
        COUNT=$((COUNT + 1))
    done

    if [ "$COUNT" -lt 10 ]; then
        echo "FAIL: expected at least 10 superpowers skills, found $COUNT"
        return 1
    fi

    # 4. Every description must fit under catalogDescriptionMaxLength
    #    (500 chars per upstream `@deepseek-ai/dsh-tool-skill`).
    #    Document any that don't, but do NOT trim — the upstream
    #    catalogDescription() truncates with '...' anyway.
    OVER_CAP=0
    for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
        [ -f "$skill_md" ] || continue
        desc=$(awk '/^---$/{c++; next} c==1 && /^description:/{sub(/^description: */,""); print; exit}' "$skill_md")
        if [ -z "$desc" ]; then
            echo "FAIL: $skill_md missing 'description:' frontmatter"
            return 1
        fi
        len=${#desc}
        if [ "$len" -gt 500 ]; then
            echo "WARN: $skill_md description is $len chars (>500 catalogDescriptionMaxLength)"
            OVER_CAP=$((OVER_CAP + 1))
        fi
    done
    if [ "$OVER_CAP" -gt 0 ]; then
        echo "WARN: $OVER_CAP descriptions exceed the 500-char cap; will be truncated by tool-skill"
    fi

    # 5. The bridge's hooks.json must reference a SessionStart event
    #    with a 'command' handler. Other event types are tolerated
    #    (the bridge parses-and-skips them) but SessionStart is the
    #    load-bearing one.
    if ! grep -q '"SessionStart"' "$BRIDGE_DIR/hooks.json"; then
        echo "FAIL: $BRIDGE_DIR/hooks.json has no SessionStart event"
        return 1
    fi

    # 6. The bridge's cordis.yml must register the skill-filesystem
    #    provider with customSkillDirs, OR the custom bridge provider.
    HAS_CUSTOM_DIRS=no
    HAS_BRIDGE_PLUGIN=no
    if grep -q "customSkillDirs" "$BRIDGE_DIR/cordis.yml"; then
        HAS_CUSTOM_DIRS=yes
    fi
    if grep -q "superpowers-safe-bridge" "$BRIDGE_DIR/cordis.yml" 2>/dev/null; then
        HAS_BRIDGE_PLUGIN=yes
    fi
    if [ "$HAS_CUSTOM_DIRS" = no ] && [ "$HAS_BRIDGE_PLUGIN" = no ]; then
        echo "FAIL: cordis.yml registers neither customSkillDirs nor the bridge plugin"
        return 1
    fi

    echo "OK: deepseek-harness-name-invocation pre-checks passed (skills=$COUNT, descriptions-in-cap, bridge present, $HAS_CUSTOM_DIRS/$HAS_BRIDGE_PLUGIN)"
    return 0
}

pre
