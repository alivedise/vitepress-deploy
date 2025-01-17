#!/bin/bash

set -e

echo ''

# env
echo "node version: $(node -v)"
echo "npm version: $(npm -v)"

# Build vuepress project
echo "==> Start building \n $BUILD_SCRIPT"
eval "$BUILD_SCRIPT"
echo "Build success"

# Change directory to the dest
echo "==> Changing directory to '$BUILD_DIR' ..."
cd $BUILD_DIR

# workaround for 'fatal: unsafe repository' error
git config --global --add safe.directory "*"

# Get repository
if [[ -z "$TARGET_REPO" ]]; then
  REPOSITORY_NAME="${GITHUB_REPOSITORY}"
else
  REPOSITORY_NAME="$TARGET_REPO"
fi

# Get branch
if [[ -z "$TARGET_BRANCH" ]]; then
  DEPLOY_BRAN="gh-pages"
else
  DEPLOY_BRAN="$TARGET_BRANCH"
fi

# Final repository
DEPLOY_REPO="https://username:${ACCESS_TOKEN}@github.com/${REPOSITORY_NAME}.git"
if [ "$TARGET_LINK" ]; then
  DEPLOY_REPO="$TARGET_LINK"
fi

echo "==> Prepare to deploy"

git init
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"

if [ -z "$(git status --porcelain)" ]; then
    echo "The BUILD_DIR is setting error or nothing produced" && \
    echo "Exiting..."
    exit 0
fi

# Generate a CNAME file
if [ "$CNAME" ]; then
  echo "Generating a CNAME file..."
  echo $CNAME > CNAME
fi

# Fetch the target branch history
echo "==> Fetching existing branch history"
git remote add origin $DEPLOY_REPO
git fetch origin $DEPLOY_BRAN || echo "Branch does not exist, creating a new one"
git checkout -B $DEPLOY_BRAN || git checkout -B $DEPLOY_BRAN

# Merge existing history without overwriting build results
echo "==> Merging existing branch history"
git fetch origin $DEPLOY_BRAN
if git rev-parse origin/$DEPLOY_BRAN >/dev/null 2>&1; then
  git merge --no-commit --strategy=ours origin/$DEPLOY_BRAN || echo "No conflicts with existing history"
fi

# Commit and push changes
if [[ -z "$COMMIT_MESSAGE" ]]; then
  COMMIT_MESSAGE="Auto deploy from Github Actions"
fi

echo "==> Adding and committing changes"
git add .
git commit -m "$COMMIT_MESSAGE"

# Resolve non-fast-forward push issues
echo "==> Pulling latest changes to avoid non-fast-forward push"
git pull --rebase origin $DEPLOY_BRAN || echo "Rebase completed or no changes"

echo "==> Pushing to repository"
git push origin $DEPLOY_BRAN

cd $GITHUB_WORKSPACE

echo "Successfully deployed!" && \
echo "See: https://github.com/$REPOSITORY_NAME/tree/$DEPLOY_BRAN"
