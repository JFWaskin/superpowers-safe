#!/bin/bash
# Post-checks for deepseek-harness-name-invocation
#
# Verifies the agent's transcript against the /<name> user-invocation
# acceptance criteria. Run by Quorum after the pressure script
# completes; the transcript is at $TRANSCRIPT (default
# tests/evals/results/latest/log.txt).

post() {
    TRANSCRIPT=${TRANSCRIPT:-tests/evals/results/latest/log.txt}
    [ -f "$TRANSCRIPT" ] || { echo "FAIL: no transcript at $TRANSCRIPT"; return 1; }

    # --- 1. The brainstorming skill must be loaded at least once. ---
    # The harness's tool-skill plugin injects the skill body into the
    # model's context either via a `skill` tool call OR via the
    # user-explicit-injection source kind. Look for both.
    SKILL_LOADED=no
    if grep -qE '(skill|<skill_content)[^a-z]+name[^a-z]*[:=][^"]*"brainstorming"' "$TRANSCRIPT" 2>/dev/null; then
        SKILL_LOADED=yes
    fi
    if grep -qE 'kind[^a-z]*[:=][^"]*"skill-invocation"[^]]*name[^a-z]*[:=][^"]*"brainstorming"' "$TRANSCRIPT" 2>/dev/null; then
        SKILL_LOADED=yes
    fi
    if [ "$SKILL_LOADED" = no ]; then
        echo "FAIL: brainstorming skill was never loaded (no skill tool call, no skill-invocation source)"
        return 1
    fi

    # --- 2. No premature brainstorming load BEFORE the user-typed /brainstorming. ---
    # The Quorum transcript includes the user messages and the agent's tool
    # calls in order. The first /brainstorming token in the transcript
    # must come BEFORE the first skill tool call with name=brainstorming.
    FIRST_GESTURE_LINE=$(grep -n "/brainstorming" "$TRANSCRIPT" | head -1 | cut -d: -f1)
    FIRST_LOAD_LINE=$(grep -nE 'name[^a-z]*[:=][^"]*"brainstorming"' "$TRANSCRIPT" | head -1 | cut -d: -f1)
    if [ -n "$FIRST_LOAD_LINE" ] && [ -n "$FIRST_GESTURE_LINE" ]; then
        if [ "$FIRST_LOAD_LINE" -lt "$FIRST_GESTURE_LINE" ]; then
            echo "FAIL: brainstorming skill loaded at line $FIRST_LOAD_LINE, BEFORE the first /brainstorming at line $FIRST_GESTURE_LINE"
            return 1
        fi
    fi

    # --- 3. No /usr or /usr/bin parsed as a skill name. ---
    # The harness's regex is whitespace-bounded on the left, so /usr/bin/ls
    # must not match. Verify the model did not call the skill tool with
    # name="usr" or name="bin" in response to a /usr/bin/ls gesture.
    BAD_LOAD=$(grep -cE 'name[^a-z]*[:=][^"]*"(usr|bin|ls)"' "$TRANSCRIPT" || echo 0)
    if [ "$BAD_LOAD" -gt 0 ]; then
        echo "FAIL: $BAD_LOAD false-positive skill loads from /usr/bin paths"
        grep -nE 'name[^a-z]*[:=][^"]*"(usr|bin|ls)"' "$TRANSCRIPT" | head -3
        return 1
    fi

    # --- 4. The agent should have read the user's arguments as prose. ---
    # When the user typed "/brainstorming my idea about a todo list",
    # the agent's first response should reference "todo" or "idea" or
    # "dark mode" (the actual user content), not a structured parse.
    PROSE_RECOGNIZED=no
    if grep -qiE "todo list|my idea|dark mode" "$TRANSCRIPT"; then
        PROSE_RECOGNIZED=yes
    fi
    if [ "$PROSE_RECOGNIZED" = no ]; then
        echo "WARN: agent's response may not have read the prose after /brainstorming"
    fi

    # --- 5. The agent should have answered the literal question about /usr/bin/ls. ---
    # The user asked "what's /usr/bin/ls?" — a literal question. The agent
    # should not interpret /usr as a skill. Look for an explanation of
    # /usr/bin/ls as a file path.
    USR_EXPLAINED=no
    if grep -qiE "binary|executable|file system|/usr/bin/ls is|/usr/bin/ls (is|means|refers|stands)" "$TRANSCRIPT"; then
        USR_EXPLAINED=yes
    fi
    if [ "$USR_EXPLAINED" = no ]; then
        echo "WARN: agent may have misinterpreted /usr/bin/ls as a skill gesture"
    fi

    # --- 6. The non-kebab-case name /UsingSuperpowers was not parsed as a gesture. ---
    # Look for any skill load with name="UsingSuperpowers" or
    # name="using_superpowers" or name="brainstorming_v2".
    NON_KEBAB_LOAD=$(grep -cE 'name[^a-z]*[:=][^"]*"(UsingSuperpowers|using_superpowers|brainstorming_v2)"' "$TRANSCRIPT" || echo 0)
    if [ "$NON_KEBAB_LOAD" -gt 0 ]; then
        echo "FAIL: $NON_KEBAB_LOAD non-kebab-case skill loads (regex should have rejected these names)"
        return 1
    fi

    # --- 7. The `using-superpowers` bootstrap is referenced in the catalog. ---
    # The bootstrap registers all 15 superpowers skills. Verify at least
    # one `<skill_content name="using-superpowers">` or catalog entry
    # is present.
    BOOTSTRAP_PRESENT=no
    if grep -qE '<available_skills>|name[^a-z]*[:=][^"]*"using-superpowers"' "$TRANSCRIPT"; then
        BOOTSTRAP_PRESENT=yes
    fi
    if [ "$BOOTSTRAP_PRESENT" = no ]; then
        echo "WARN: no <available_skills> block or using-superpowers reference in transcript (bootstrap may not have injected)"
    fi

    echo "OK: deepseek-harness-name-invocation post-checks passed (brainstorming loaded after /brainstorming, no false-positive /usr loads, prose recognized, non-kebab rejected)"
    return 0
}

post
