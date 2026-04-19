#!/bin/bash
set -e

echo "=== Mobile Commander: Push to GitHub ==="
echo ""

# Step 1: Check/fix gh auth
echo "[1/4] Checking GitHub CLI authentication..."
if ! gh auth status 2>/dev/null; then
    echo ""
    echo "GitHub CLI needs authentication. Starting login flow..."
    echo "Log in as the account that owns the palmr-jing SSH key."
    echo ""
    gh auth login --hostname github.com --git-protocol ssh --web --scopes repo
    echo ""
fi

echo "✓ Authenticated as: $(gh api user --jq .login 2>/dev/null || echo 'unknown')"
echo ""

# Step 2: Create the repo if it doesn't exist
REPO_NAME="mobile-exprimental"
OWNER=$(gh api user --jq .login)
echo "[2/4] Checking if repo ${OWNER}/${REPO_NAME} exists..."

if gh repo view "${OWNER}/${REPO_NAME}" > /dev/null 2>&1; then
    echo "✓ Repo already exists"
else
    echo "Creating repo..."
    gh repo create "${REPO_NAME}" --public --source=. --description "Mobile Commander iOS app"
    echo "✓ Repo created"
fi

# Step 3: Update remote if needed and push
echo "[3/4] Pushing to GitHub..."
REMOTE_URL=$(gh repo view "${OWNER}/${REPO_NAME}" --json sshUrl --jq .sshUrl 2>/dev/null)
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "none")

if [ "$CURRENT_REMOTE" != "$REMOTE_URL" ] && [ -n "$REMOTE_URL" ]; then
    echo "Updating remote origin to: ${REMOTE_URL}"
    git remote set-url origin "${REMOTE_URL}"
fi

git push -u origin main
echo "✓ Pushed to GitHub"
echo ""

# Step 4: Show clone instructions
echo "[4/4] Clone instructions for macbook-air-3:"
echo ""
echo "  git clone ${REMOTE_URL:-git@github.com:${OWNER}/${REPO_NAME}.git}"
echo ""
echo "Or if macbook-air-3 uses HTTPS:"
echo "  git clone https://github.com/${OWNER}/${REPO_NAME}.git"
echo ""
echo "=== Done ==="
