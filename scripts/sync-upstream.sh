#!/usr/bin/env bash
# Sync the local dev branch from upstream obra/superpowers.
#
# Refuses to run if:
#   - There are uncommitted changes
#   - The local dev branch is not a fast-forward of upstream/dev
#   - The upstream remote is misconfigured
#
# Rebases any feature branches passed as arguments onto the new dev.
# By default, only syncs dev.
#
# Usage:
#   ./scripts/sync-upstream.sh                    # sync dev only
#   ./scripts/sync-upstream.sh feat/my-branch     # sync dev and rebase feat/my-branch onto it
#   ./scripts/sync-upstream.sh --push origin      # also push the synced dev to origin
#
# See docs/sync-upstream.md for the full procedure and conflict-resolution policy.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-dev}"
LOCAL_BRANCH="${LOCAL_BRANCH:-dev}"
PUSH_REMOTE=""
PUSH_AFTER=false

# Parse args
FEATURE_BRANCHES=()
for arg in "$@"; do
    case "$arg" in
        --push)
            PUSH_AFTER=true
            ;;
        --push=*)
            PUSH_AFTER=true
            PUSH_REMOTE="${arg#--push=}"
            ;;
        --upstream-remote=*)
            UPSTREAM_REMOTE="${arg#--upstream-remote=}"
            ;;
        --upstream-branch=*)
            UPSTREAM_BRANCH="${arg#--upstream-branch=}"
            ;;
        -h|--help)
            sed -n '2,20p' "$0"
            exit 0
            ;;
        -*)
            echo "Unknown flag: $arg" >&2
            exit 1
            ;;
        *)
            FEATURE_BRANCHES+=("$arg")
            ;;
    esac
done

# Helpers
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

# 1. Verify we're in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    red "Error: not a git repository (or any of the parent directories)"
    exit 1
fi

# 2. Verify the working tree is clean
if ! git diff --quiet HEAD 2>/dev/null; then
    red "Error: there are uncommitted changes. Commit or stash them first."
    git status --short
    exit 1
fi
if ! git diff --cached --quiet HEAD 2>/dev/null; then
    red "Error: there are staged but uncommitted changes. Commit or unstage them first."
    git status --short
    exit 1
fi

# 3. Verify the upstream remote points to obra/superpowers
remote_url=$(git config "remote.${UPSTREAM_REMOTE}.url" 2>/dev/null || echo "")
case "$remote_url" in
    *obra/superpowers*)
        green "Upstream remote: $remote_url"
        ;;
    "")
        red "Error: upstream remote '${UPSTREAM_REMOTE}' is not configured."
        red "Add it with: git remote add ${UPSTREAM_REMOTE} https://github.com/obra/superpowers.git"
        exit 1
        ;;
    *)
        yellow "Warning: upstream remote '${UPSTREAM_REMOTE}' points to: $remote_url"
        yellow "Expected something containing 'obra/superpowers'."
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
            exit 1
        fi
        ;;
esac

# 4. Fetch upstream
bold "Fetching $UPSTREAM_REMOTE/$UPSTREAM_BRANCH..."
git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"

# 5. Switch to local branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "$LOCAL_BRANCH" ]; then
    yellow "Currently on $current_branch, switching to $LOCAL_BRANCH"
    git checkout "$LOCAL_BRANCH"
fi

# 6. Check that local is a fast-forward of upstream
local_sha=$(git rev-parse "$LOCAL_BRANCH")
upstream_sha=$(git rev-parse "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH")

if [ "$local_sha" = "$upstream_sha" ]; then
    green "Already up to date with $UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
else
    if git merge-base --is-ancestor "$local_sha" "$upstream_sha"; then
        bold "Fast-forwarding $LOCAL_BRANCH to $UPSTREAM_REMOTE/$UPSTREAM_BRANCH..."
        git merge --ff-only "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
        green "Fast-forwarded"
    else
        red "Error: local $LOCAL_BRANCH has diverged from $UPSTREAM_REMOTE/$UPSTREAM_BRANCH."
        red "Local:   $local_sha"
        red "Upstream: $upstream_sha"
        red ""
        red "To resolve, you can:"
        red "  1. Manually rebase: git rebase $UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
        red "  2. Or, if your local commits should be discarded, hard-reset:"
        red "     git reset --hard $UPSTREAM_REMOTE/$UPSTREAM_BRANCH  # ⚠️  destructive"
        red ""
        red "See docs/sync-upstream.md for the conflict-resolution policy."
        exit 1
    fi
fi

# 7. Re-base any feature branches
if [ ${#FEATURE_BRANCHES[@]} -gt 0 ]; then
    for branch in "${FEATURE_BRANCHES[@]}"; do
        if ! git rev-parse --verify --quiet "$branch" >/dev/null; then
            yellow "Branch '$branch' does not exist locally, skipping"
            continue
        fi
        bold "Rebasing $branch onto $LOCAL_BRANCH..."
        git checkout "$branch"
        if git rebase "$LOCAL_BRANCH"; then
            green "Rebased $branch"
        else
            red "Rebase of $branch failed. Resolve manually, then re-run."
            git rebase --abort || true
            git checkout "$LOCAL_BRANCH"
            exit 1
        fi
    done
    git checkout "$LOCAL_BRANCH"
fi

# 8. Optionally push
if [ "$PUSH_AFTER" = true ]; then
    push_target="${PUSH_REMOTE:-$LOCAL_BRANCH}"
    bold "Pushing to $push_target..."
    if [ "$push_target" = "$LOCAL_BRANCH" ]; then
        git push origin "$LOCAL_BRANCH"
    else
        git push "$push_target" "$LOCAL_BRANCH"
    fi
    green "Pushed"
fi

green ""
green "Sync complete. $LOCAL_BRANCH is at $upstream_sha"
green "Next: review CHANGELOG.md, run tests, then push."
