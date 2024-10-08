#!/bin/sh

set -e
set -x

if [ -z "$INPUT_REPOSITORY" ]
then
  INPUT_REPOSITORY="${GITHUB_REPOSITORY}"
fi

if [ -z "$INPUT_USER_NAME" ]
then
  INPUT_USER_NAME="${GITHUB_ACTOR}"
fi

echo "Printing environment variables"
printenv

CLONE_DIR=$(mktemp -d)

echo "Cloning destination git repository"
git config --global user.email "$INPUT_USER_EMAIL"
git config --global user.name "$INPUT_USER_NAME"
git clone --single-branch --branch "$GITHUB_HEAD_REF" "https://x-access-token:$API_TOKEN_GITHUB@github.com/$INPUT_REPOSITORY.git" "$CLONE_DIR"

DEST_COPY="$CLONE_DIR/$INPUT_DST"

echo "Copying contents to git repo"
cp -R "$INPUT_SRC" "$DEST_COPY"

cd "$CLONE_DIR"

echo "Creating new branch: ${INPUT_DST_BRANCH}"
git checkout -b "$INPUT_DST_BRANCH"
OUTPUT_BRANCH="$INPUT_DST_BRANCH"

if [ -z "$INPUT_COMMIT_MESSAGE" ]
then
  INPUT_COMMIT_MESSAGE="Update from https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"
fi

echo "Adding git commit"
git add .
if git status | grep -q "Changes to be committed"
then
  git commit --message "$INPUT_COMMIT_MESSAGE"
  echo "Pushing git commit"
  git push -u origin HEAD:"$OUTPUT_BRANCH"
else
  echo "No changes detected"
fi