#!/usr/bin/env bash
set -euo pipefail

# This script requires:
#   - gh CLI installed and authenticated (`gh auth login`)
#   - To be run from inside the target repository checkout
#
# It:
#   - Detects owner, repo, and default branch
#   - Configures branch protection to require status checks
#   - Enables auto-merge on the repository

echo "=== Enforcing branch protection and enabling auto-merge ==="

# Get repo URL and parse owner/repo
REPO_URL=$(git remote get-url origin)
REPO_NAME=$(basename -s .git "$REPO_URL")

# Supports both git@github.com:owner/repo.git and https://github.com/owner/repo.git
if [[ "$REPO_URL" =~ github.com[:/]+([^/]+)/([^/]+)(\.git)?$ ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
else
  echo "Error: Could not parse owner/repo from origin URL: $REPO_URL"
  exit 1
fi

# Determine default branch
MAIN_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD)

echo "Repository: $OWNER/$REPO"
echo "Default branch (detected): $MAIN_BRANCH"

read -rp "Proceed to configure branch protection and enable auto-merge on '$MAIN_BRANCH'? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborting."
  exit 0
fi

echo "Configuring branch protection via GitHub API..."

# Configure branch protection:
# - require status checks (example: a generic 'test' check)
# - require up-to-date branch (strict: true)
# - require conversation resolution
# - no specific user restrictions
PROTECTION_PAYLOAD=$(
  cat <<JSON
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "test" }
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "required_conversation_resolution": true,
  "restrictions": null
}
JSON
)

echo "$PROTECTION_PAYLOAD" | gh api \
  repos/"$OWNER"/"$REPO"/branches/"$MAIN_BRANCH"/protection \
  --method PUT \
  --silent \
  --header "Accept: application/vnd.github.v3+json" \
  --input -

echo "Enabling repository-level auto-merge..."

AUTO_MERGE_PAYLOAD=$(
  cat <<JSON
{
  "allow_auto_merge": true,
  "delete_branch_on_merge": true
}
JSON
)

echo "$AUTO_MERGE_PAYLOAD" | gh api \
  repos/"$OWNER"/"$REPO" \
  --method PATCH \
  --silent \
  --header "Accept: application/vnd.github.v3+json" \
  --input -

echo "Done. Branch protection and auto-merge should now be configured for $OWNER/$REPO on branch $MAIN_BRANCH."
