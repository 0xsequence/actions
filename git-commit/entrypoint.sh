#!/bin/sh

set -e

update_labels () {
  PR_ID=$1

  IFS=','
  LABELS=""
  # Loop over the input labels
  for LABEL in $INPUT_PR_LABELS; do
    if [ -z "$LABELS" ]; then
      LABELS="\"$LABEL\""  # First label, no comma
    else
      LABELS="$LABELS, \"$LABEL\""  # Subsequent labels, add a comma
    fi
  done

  if [ -n "$LABELS" ]; then
    # Wrap the labels in square brackets and prepare the JSON payload
    LABELS_JSON="{\"labels\":[$LABELS]}"

    curl \
      -L \
      --connect-timeout 10 \
      -u "$INPUT_USER_NAME}:$API_TOKEN_GITHUB" \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -d "$LABELS_JSON" \
      "https://api.github.com/repos/$INPUT_REPOSITORY/issues/$PR_ID/labels"
  fi
}

INPUT_REPOSITORY="${GITHUB_REPOSITORY}"

if [ -z "$INPUT_BRANCH" ]
then
  INPUT_BRANCH=${GITHUB_HEAD_REF}
fi

if [ -z "$INPUT_COMMIT_MESSAGE" ]
then
  INPUT_COMMIT_MESSAGE="[AUTOMATED] Update: ${INPUT_FILES}"
fi

if [ -z "$INPUT_PR_TITLE" ]
then
  INPUT_PR_TITLE="[AUTOMATED] Update files from ${GITHUB_REPOSITORY}"
fi

if [ -z "$INPUT_PR_DESCRIPTION" ]
then
  INPUT_PR_DESCRIPTION="Triggered by https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"
fi

if [ -z "$INPUT_USER_NAME" ]
then
  INPUT_USER_NAME="${GITHUB_ACTOR}"
fi

if [ -z "$INPUT_USER_EMAIL" ]
then
  INPUT_USER_EMAIL="$GITHUB_ACTOR_ID+$GITHUB_ACTOR@users.noreply.github.com"
fi

if [ -z "$INPUT_PR_CREATE" ]
then
  INPUT_PR_CREATE=false
fi

DEST_DIR=$(mktemp -d)

echo "Cloning destination git repository"
git config --global user.name "$INPUT_USER_NAME"
git config --global user.email "$INPUT_USER_EMAIL"
git clone "https://x-access-token:$API_TOKEN_GITHUB@github.com/$INPUT_REPOSITORY.git" "$DEST_DIR"

BASE_DIR=$(pwd)
cd "$DEST_DIR"

echo "Creating new branch: ${INPUT_BRANCH}"
git checkout -b "$INPUT_BRANCH"
git reset --hard "origin/$INPUT_BRANCH" || true

cd "$BASE_DIR"
echo "Copying files"

for INPUT in $INPUT_FILES; do
    if [ -d "$INPUT" ]; then
        # If it's a directory, sync the entire directory
        rsync -avh --delete "$INPUT/" "$DEST_DIR/$INPUT"
    elif [ -e "$INPUT" ]; then
        # If it's a file or matches a glob, sync the file
        rsync -avh "$INPUT" "$DEST_DIR/$(dirname "$INPUT")/"
    else
        # delete file in destination
        # https://www.shellcheck.net/wiki/SC2115
        rm -rf "${DEST_DIR:?}/$(dirname "$INPUT")/"
    fi
done

cd $DEST_DIR
git status -s

# Exit early if there's nothing to commit.
if [ -z "$(git status -s)" ]; then
  echo "Nothing to commit."

  # Print pull requests URL for the current branch.
  curl \
    --connect-timeout 10 \
    -u "${INPUT_USER_NAME}:${API_TOKEN_GITHUB}" \
    -H 'Content-Type: application/json' \
    "https://api.github.com/repos/{$INPUT_REPOSITORY}/pulls?state=open&head=${GITHUB_REPOSITORY_OWNER}:${INPUT_BRANCH}" > pull_request.json

  count=$(jq '. | length' pull_request.json)
  if [ "$count" -eq 1 ]
  then
    PR_URL=$(jq -r '.[0].html_url' pull_request.json)
    update_labels $(jq -r '.[0].number' pull_request.json)
    echo "$PR_URL" >> $GITHUB_STEP_SUMMARY
  fi

  exit 0
fi

echo "Committing changes"
git add .
git commit --message "${INPUT_COMMIT_MESSAGE}"
git push -u origin --force HEAD:"$INPUT_BRANCH"

# Exit early if pull request is not enabled.
[ "$INPUT_PR_CREATE" != true ] && exit 0

PR_DESCRIPTION_ESCAPED="${INPUT_PR_DESCRIPTION//$'\n'/\\n}"

curl \
  --connect-timeout 10 \
  -u "${INPUT_USER_NAME}:${API_TOKEN_GITHUB}" \
  -X POST -H 'Content-Type: application/json' \
  --data "{\"head\":\"$INPUT_BRANCH\",\"base\":\"${INPUT_PR_BASE}\", \"title\": \"${INPUT_PR_TITLE}\", \"body\": \"${PR_DESCRIPTION_ESCAPED}\"}" \
  "https://api.github.com/repos/{$INPUT_REPOSITORY}/pulls" > pull_request.json

PR_EXISTS=$(jq '.errors' pull_request.json)
if [ "$PR_EXISTS" = 'null' ]; then
  # Create pull request.
  PR_URL=$(jq -r '.html_url' pull_request.json)
  update_labels $(jq -r '.number' pull_request.json)
  echo "$PR_URL" >> $GITHUB_STEP_SUMMARY
  exit 0
fi

# Print pull requests URL for the current branch.
curl \
  --connect-timeout 10 \
  -u "${INPUT_USER_NAME}:${API_TOKEN_GITHUB}" \
  -H 'Content-Type: application/json' \
  "https://api.github.com/repos/{$INPUT_REPOSITORY}/pulls?state=open&head=${GITHUB_REPOSITORY_OWNER}:${INPUT_BRANCH}" > pull_request.json

PR_URL=$(jq -r '.[0].html_url' pull_request.json)
update_labels $(jq -r '.[0].number' pull_request.json)
echo "$PR_URL" >> $GITHUB_STEP_SUMMARY

