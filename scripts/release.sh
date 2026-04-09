#!/usr/bin/env bash
# Release workflow: bump version on dev, create PR to main, merge, tag, release.
# main is protected — direct push is not allowed, so we use a PR-based flow.
#
# Usage:
#   ./scripts/release.sh              # release current version (single phase)
#   ./scripts/release.sh 0.3.0        # bump version first, then release
#   ./scripts/release.sh --two-phase 0.3.0  # stop after PR (for CI)
#   ./scripts/release.sh --after-ci         # finish after CI passes
#
# Default: single phase (no CI). Use --two-phase to split if CI is added.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
STATE_FILE="$ROOT/.release-state"
PLUGIN_JSON="$ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$ROOT/.claude-plugin/marketplace.json"

# ── Finish function (shared by single-phase and --after-ci) ────────────────

finish_release() {
  local pr_number="$1"
  local tag="$2"

  echo "Merging PR #$pr_number..."
  gh pr merge "$pr_number" --merge

  echo "Tagging main..."
  git fetch origin main
  git tag "$tag" origin/main
  git push origin "$tag"

  echo "Creating GitHub release..."
  gh release create "$tag" --title "$tag" --generate-notes

  git checkout dev
  git pull

  rm -f "$STATE_FILE"

  echo ""
  echo "Released $tag"
}

# ── --after-ci: resume from saved state ────────────────────────────────────

if [[ "${1:-}" == "--after-ci" ]]; then
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "Error: no .release-state file found. Run with --two-phase first." >&2
    exit 1
  fi

  # shellcheck source=/dev/null
  source "$STATE_FILE"

  echo "Resuming release: $RELEASE_TAG (PR #$RELEASE_PR_NUMBER)"
  finish_release "$RELEASE_PR_NUMBER" "$RELEASE_TAG"
  exit 0
fi

# ── Parse flags ────────────────────────────────────────────────────────────

TWO_PHASE=false
if [[ "${1:-}" == "--two-phase" ]]; then
  TWO_PHASE=true
  shift
fi

# ── Prepare ────────────────────────────────────────────────────────────────

CURRENT_BRANCH="$(git branch --show-current)"
CURRENT_VERSION="$(jq -r '.version' "$PLUGIN_JSON")"

# Ensure we start on dev
if [[ "$CURRENT_BRANCH" != "dev" ]]; then
  echo "Error: must be on dev branch (currently on $CURRENT_BRANCH)" >&2
  exit 1
fi

# Ensure working tree is clean (except beads which we'll sync)
if [[ -n "$(git diff --name-only -- ':!.beads')" ]] || [[ -n "$(git diff --cached --name-only -- ':!.beads')" ]]; then
  echo "Error: uncommitted changes on dev (excluding .beads/). Commit or stash first." >&2
  git status -s
  exit 1
fi

# --- Bump version (optional) ---

if [[ $# -ge 1 ]]; then
  NEW_VERSION="$1"

  if [[ "$CURRENT_VERSION" == "$NEW_VERSION" ]]; then
    echo "Already at version $NEW_VERSION, skipping bump"
  else
    echo "Bumping $CURRENT_VERSION → $NEW_VERSION"

    jq --arg v "$NEW_VERSION" '.version = $v' "$PLUGIN_JSON" > "$PLUGIN_JSON.tmp" && mv "$PLUGIN_JSON.tmp" "$PLUGIN_JSON"
    jq --arg v "$NEW_VERSION" '.plugins[0].version = $v' "$MARKETPLACE_JSON" > "$MARKETPLACE_JSON.tmp" && mv "$MARKETPLACE_JSON.tmp" "$MARKETPLACE_JSON"

    git add "$PLUGIN_JSON" "$MARKETPLACE_JSON"
    git commit -m "chore: bump version to $NEW_VERSION"
    git push

    CURRENT_VERSION="$NEW_VERSION"
  fi
else
  echo "Releasing current version: $CURRENT_VERSION"
fi

TAG="v${CURRENT_VERSION}"

# Check tag doesn't already exist
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Error: tag $TAG already exists" >&2
  exit 1
fi

# --- Sync beads ---

if command -v bd >/dev/null 2>&1 && [[ -d "$ROOT/.beads" ]]; then
  echo "Syncing beads..."
  bd sync --flush-only
  if [[ -n "$(git diff --name-only .beads/)" ]]; then
    git add .beads/
    git commit -m "chore: sync beads before release"
    git push
  fi
fi

# --- Create release branch and PR ---

RELEASE_BRANCH="release/$TAG"
echo "Creating release branch: $RELEASE_BRANCH"

git checkout -b "$RELEASE_BRANCH" dev
git push -u origin "$RELEASE_BRANCH"

echo "Creating PR to main..."
PR_URL=$(gh pr create --base main --title "release: $TAG" --body "$(cat <<EOF
## Release $TAG

Merge dev into main for release.

Version: $CURRENT_VERSION
Tag: $TAG
EOF
)")

echo "PR created: $PR_URL"
PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')

# --- Two-phase: save state and exit ---

if [[ "$TWO_PHASE" == "true" ]]; then
  cat > "$STATE_FILE" <<EOF
RELEASE_PR_NUMBER=$PR_NUMBER
RELEASE_TAG=$TAG
RELEASE_VERSION=$CURRENT_VERSION
RELEASE_BRANCH=$RELEASE_BRANCH
EOF

  echo ""
  echo "Phase 1 complete. PR: $PR_URL"
  echo "After CI passes, finish with:"
  echo "  ./scripts/release.sh --after-ci"

  git checkout dev
  exit 0
fi

# --- Single phase: finish immediately ---

finish_release "$PR_NUMBER" "$TAG"
