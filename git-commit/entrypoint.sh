#!/bin/sh

set -e
set -x

if [ -z "$INPUT_REPOSITORY" ]
then
  INPUT_REPOSITORY="${GITHUB_REPOSITORY}"
fi

if [ -z "$INPUT_COMMIT_MESSAGE" ]
then
  INPUT_COMMIT_MESSAGE="Generated from https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"
fi

if [ -z "$INPUT_PR_TITLE" ]
then
  INPUT_PR_TITLE="Automatic update from: ${GITHUB_REPOSITORY}"
fi

if [ -z "$INPUT_PR_DESCRIPTION" ]
then
  INPUT_PR_DESCRIPTION=${INPUT_COMMIT_MESSAGE}
fi

if [ -z "$INPUT_DST_BRANCH" ]
then
  INPUT_DST_BRANCH=${GITHUB_HEAD_REF}
fi

if [ -z "$INPUT_USER_NAME" ]
then
  INPUT_USER_NAME = "0xSEQUENCE BOT"
fi

if [ -z "$INPUT_USER_EMAIL" ]
then
  INPUT_USER_EMAIL = "$GITHUB_ACTOR_ID+$GITHUB_ACTOR@users.noreply.github.com"
fi

CLONE_DIR=$(mktemp -d)

echo "Cloning destination git repository"
git config --global user.name "$INPUT_USER_NAME"
git config --global user.email "$INPUT_USER_EMAIL"
git clone "https://x-access-token:$API_TOKEN_GITHUB@github.com/$INPUT_REPOSITORY.git" "$CLONE_DIR"

BASE_DIR=$(pwd)
cd "$CLONE_DIR"

echo "Creating new branch: ${INPUT_DST_BRANCH}"
git checkout -b "$INPUT_DST_BRANCH"
git reset --hard "origin/$INPUT_DST_BRANCH"  || true

DEST_COPY="$CLONE_DIR/$INPUT_DST"
if [ "$INPUT_DST" != "" ]
then
  mkdir -p $DEST_COPY
fi

echo "Copying contents to git repo"
cp -R $BASE_DIR/$INPUT_SRC "$DEST_COPY"

echo "Adding git commit"
git add .
if git status | grep -q "Changes to be committed"
then
  git commit --message "$INPUT_COMMIT_MESSAGE"
  echo "Pushing git commit"
  git push -u origin HEAD:"$INPUT_DST_BRANCH"

  if [ "$INPUT_PR_CREATE" == "true" ]
  then
    PR_DESCRIPTION_ESCAPED="${INPUT_PR_DESCRIPTION//$'\n'/\\n}"

    curl --connect-timeout 10 \
      -u "${INPUT_USER_NAME}:${API_TOKEN_GITHUB}" \
      -X POST -H 'Content-Type: application/json' \
      --data "{\"head\":\"$INPUT_DST_BRANCH\",\"base\":\"${INPUT_PR_BASE}\", \"title\": \"${INPUT_PR_TITLE}\", \"body\": \"${PR_DESCRIPTION_ESCAPED}\"}" \
      "https://api.github.com/repos/{$INPUT_REPOSITORY}/pulls"
  fi
else
  echo "No changes detected"
fi