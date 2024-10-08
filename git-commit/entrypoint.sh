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

if [ -z "$INPUT_COMMIT_MESSAGE" ]
then
  INPUT_COMMIT_MESSAGE="Generated from https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"
fi

if [ -z "$INPUT_PR_TITLE" ]
then
  PR_TITLE="Automatic update from: ${GITHUB_REPOSITORY}"
fi

if [ -z "$INPUT_PR_DESCRIPTION" ]
then
  PR_DESCRIPTION=${INPUT_COMMIT_MESSAGE}
fi

echo "Printing environment variables"
printenv

CLONE_DIR=$(mktemp -d)

echo "Cloning destination git repository"
git config --global user.email "$INPUT_USER_EMAIL"
git config --global user.name "$INPUT_USER_NAME"
git clone --branch "$GITHUB_HEAD_REF" "https://x-access-token:$API_TOKEN_GITHUB@github.com/$INPUT_REPOSITORY.git" "$CLONE_DIR"

DEST_COPY="$CLONE_DIR/$INPUT_DST"
if [ "$INPUT_DST" != "" ]
then
  mkdir -p $DEST_COPY
fi

echo "Copying contents to git repo"
cp -R $INPUT_SRC "$DEST_COPY"

cd "$CLONE_DIR"

echo "Creating new branch: ${INPUT_DST_BRANCH}"
git checkout -b "$INPUT_DST_BRANCH"
git reset --hard "origin/$INPUT_DST_BRANCH"  || true
OUTPUT_BRANCH="$INPUT_DST_BRANCH"

echo "Adding git commit"
git add .
if git status | grep -q "Changes to be committed"
then
  git commit --message "$INPUT_COMMIT_MESSAGE"
  echo "Pushing git commit"
  git push -u origin HEAD:"$OUTPUT_BRANCH"

  if [ "$INPUT_PR_CREATE" == "true" ]
  then
    PR_DESCRIPTION_ESCAPED="${PR_DESCRIPTION//$'\n'/\\n}"

    curl --connect-timeout 10 \
      -u "${INPUT_USER_NAME}:${API_TOKEN_GITHUB}" \
      -X POST -H 'Content-Type: application/json' \
      --data "{\"head\":\"$OUTPUT_BRANCH\",\"base\":\"${INPUT_PR_BASE}\", \"title\": \"${PR_TITLE}\", \"body\": \"${PR_DESCRIPTION_ESCAPED}\"}" \
      "https://api.github.com/repos/{$INPUT_REPOSITORY}/pulls"
  fi
else
  echo "No changes detected"
fi