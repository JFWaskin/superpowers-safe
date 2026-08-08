#!/usr/bin/env bash
# One-time setup for the eval harness.
#
# Clones prime-radiant-inc/superpowers-evals into ./evals/ (gitignored)
# and installs its Bun-based dependencies. Quorum is the harness that
# drives a real coding-agent CLI through pressure scenarios and grades
# the run against workflow criteria.
#
# Usage:
#   bash tests/evals/quorum-setup.sh
#
# Requirements: git, bun (https://bun.sh), and any tools the agent will
# use during the scenarios (claude, codex, etc., as needed).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

if [ ! -d "evals" ]; then
    echo "Cloning superpowers-evals into ./evals/"
    git clone https://github.com/prime-radiant-inc/superpowers-evals.git evals
else
    echo "./evals/ already exists; skipping clone. Run 'git -C evals pull' to update."
fi

if ! command -v bun >/dev/null 2>&1; then
    echo "ERROR: bun is not installed."
    echo "Install it: curl -fsSL https://bun.sh/install | bash"
    exit 1
fi

cd evals
echo "Installing Quorum dependencies..."
bun install

echo ""
echo "Setup complete. Try a single scenario:"
echo "  bun run quorum list"
echo "  bun run quorum run ../tests/evals/scenarios/rm-rf-outside-cwd/scenario.yaml"
