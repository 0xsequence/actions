#!/bin/sh

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

set -x

INPUT_REPOSITORY="${GITHUB_REPOSITORY}"

if [ -z "$INPUT_BRANCH" ]
then
  INPUT_BRANCH=${GITHUB_HEAD_REF}
fi

if [ -z "$INPUT_COMMIT_MESSAGE" ]
then
  INPUT_COMMIT_MESSAGE="[AUTOMATED] Update: ${INPUT_SRC}"
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

CLONE_DIR=$(mktemp -d)

echo "Cloning destination git repository"
git config --global user.name "$INPUT_USER_NAME"
git config --global user.email "$INPUT_USER_EMAIL"
git clone "https://x-access-token:$API_TOKEN_GITHUB@github.com/$INPUT_REPOSITORY.git" "$CLONE_DIR"

BASE_DIR=$(pwd)
cd "$CLONE_DIR"

echo "Creating new branch: ${INPUT_BRANCH}"
git checkout -b "$INPUT_BRANCH"
git reset --hard "origin/$INPUT_BRANCH"  || true

echo "Replacing contents"
cd "$BASE_DIR"

# Set IFS to whitespace (this is the default, but it's good to make it explicit)
IFS=' '
# Loop over the strings
for FILE in $INPUT_FILES; do
  echo "Processing $FILE"
  rm -rf $CLONE_DIR/$FILE
  cp -f --parents $FILE "$CLONE_DIR"
done
cd $CLONE_DIR

echo "Adding git commit"
git add .

# Check if there are changes to be committed
if ! git status | grep -q "Changes to be committed"; then
  echo "No changes detected"

  # list pull requests opened for specific branch
  # expect 1 branch
  curl \
    --connect-timeout 10 \
    -u "${INPUT_USER_NAME}:${API_TOKEN_GITHUB}" \
    -H 'Content-Type: application/json' \
    "https://api.github.com/repos/{$INPUT_REPOSITORY}/pulls?state=open&head=${GITHUB_REPOSITORY_OWNER}:${INPUT_BRANCH}" | tee pull_request.json

  count=$(jq '. | length' pull_request.json)
  if [ "$count" -eq 1 ]
  then
    PR_URL=$(jq -r '.[0].html_url' pull_request.json)
    update_labels $(jq -r '.[0].number' pull_request.json)
    echo "$PR_URL" >> $GITHUB_STEP_SUMMARY
  fi

  exit 0
fi

git commit --message "${INPUT_COMMIT_MESSAGE}"
echo "Pushing git commit"
git push -u origin --force HEAD:"$INPUT_BRANCH"

# Exit early if pull request creation is not needed
[ "$INPUT_PR_CREATE" != true ] && exit 0

PR_DESCRIPTION_ESCAPED="${INPUT_PR_DESCRIPTION//$'\n'/\\n}"

curl \
  --connect-timeout 10 \
  -u "${INPUT_USER_NAME}:${API_TOKEN_GITHUB}" \
  -X POST -H 'Content-Type: application/json' \
  --data "{\"head\":\"$INPUT_BRANCH\",\"base\":\"${INPUT_PR_BASE}\", \"title\": \"${INPUT_PR_TITLE}\", \"body\": \"${PR_DESCRIPTION_ESCAPED}\"}" \
  "https://api.github.com/repos/{$INPUT_REPOSITORY}/pulls" | tee pull_request.json

PR_EXISTS=$(jq '.errors' pull_request.json)
# PR does not exist
if [ "$PR_EXISTS" = 'null' ]
then
  PR_URL=$(jq -r '.html_url' pull_request.json)
  update_labels $(jq -r '.number' pull_request.json)
  echo "$PR_URL" >> $GITHUB_STEP_SUMMARY
  exit 0
fi

# list pull requests opened for specific branch
# expect branch
curl \
  --connect-timeout 10 \
  -u "${INPUT_USER_NAME}:${API_TOKEN_GITHUB}" \
  -H 'Content-Type: application/json' \
  "https://api.github.com/repos/{$INPUT_REPOSITORY}/pulls?state=open&head=${GITHUB_REPOSITORY_OWNER}:${INPUT_BRANCH}" | tee pull_request.json

PR_URL=$(jq -r '.[0].html_url' pull_request.json)
update_labels $(jq -r '.[0].number' pull_request.json)
echo "$PR_URL" >> $GITHUB_STEP_SUMMARY

