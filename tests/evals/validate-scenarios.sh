#!/bin/bash
# validate-scenarios.sh — verify all 4 eval scenarios are well-formed
# and shellcheck-clean. Part of the CI gate; can be run locally:
#
#   bash tests/evals/validate-scenarios.sh
#
# Exits 0 on success, 1 on any failure.

set -eu
cd "$(dirname "$0")/../.."

SCENARIOS=(
    rm-rf-outside-cwd
    sudo-without-ok
    publish-without-ok
    curl-pipe-shell
    dsh-dsh-eval
)

echo "=== Scenario validation ==="
echo ""

for s in "${SCENARIOS[@]}"; do
    DIR="tests/evals/scenarios/$s"
    echo "--- $s ---"

    # Required files
    for f in scenario.yaml story.md setup.sh checks.sh; do
        if [ ! -f "$DIR/$f" ]; then
            echo "FAIL: missing $DIR/$f"
            exit 1
        fi
    done

    # scenario.yaml required fields
    for k in id title status tags; do
        grep -q "^$k:" "$DIR/scenario.yaml" || {
            echo "FAIL: $DIR/scenario.yaml missing field '$k'"
            exit 1
        }
    done

    # story.md frontmatter
    head -1 "$DIR/story.md" | grep -q "^---$" || {
        echo "FAIL: $DIR/story.md missing frontmatter"
        exit 1
    }

    # setup.sh and checks.sh must define pre() and post() respectively
    grep -q "^pre()" "$DIR/setup.sh" || {
        echo "FAIL: $DIR/setup.sh missing pre()"
        exit 1
    }
    grep -q "^post()" "$DIR/checks.sh" || {
        echo "FAIL: $DIR/checks.sh missing post()"
        exit 1
    }

    # shellcheck
    if command -v shellcheck > /dev/null; then
        shellcheck "$DIR/setup.sh" "$DIR/checks.sh" || {
            echo "FAIL: shellcheck issues in $DIR"
            exit 1
        }
    else
        echo "WARN: shellcheck not installed, skipping"
    fi

    # Acceptance criteria section
    grep -q "^## Acceptance Criteria" "$DIR/story.md" || {
        echo "FAIL: $DIR/story.md missing Acceptance Criteria section"
        exit 1
    }

    echo "OK: $s"
done

echo ""
echo "=== All ${#SCENARIOS[@]} scenarios valid ==="
