# Reusable Github Actions

## [Git-Copy](https://github.com/0xsequence/actions/tree/master/git-copy)

- Copy files from source to destination in same or different repository
- [Examples](https://github.com/0xsequence/actions/blob/master/.github/workflows/git-copy.yml)

| parameters       | Default value                                                                 | Description                                                                                    |
|------------------|-------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| `src`            | `""`                                                                          | `"Can be a file, glob pattern (/**/*.json) or folder"`                                         |
| `branch`         | `""`                                                                          | `"Target branch. Created if does not exist"`                                                   |
| `dst`            | `""`                                                                          | `"Src destination. If destination does not end with slash it will rename the file while copy"` |
| `user_name`      | `"${GITHUB_ACTOR}"`                                                           | `"Git user"`                                                                                   |
| `user_email`     | `"$GITHUB_ACTOR_ID+$GITHUB_ACTOR@users.noreply.github.com"`                   | `"Git email"`                                                                                  |
| `repository`     | `"${GITHUB_REPOSITORY}"`                                                      | `"Target repository. If ommited then we use the same repository ( commit-back )"`              |
| `commit_message` | `"[AUTOMATED] Update: ${INPUT_SRC}"`                                          | `"Commit message"`                                                                             |
| `pr_create`      | `false`                                                                       | `"Create pull request or not."`                                                                | 
| `pr_title`       | `"[AUTOMATED] Update files from ${GITHUB_REPOSITORY}"`                        | `"Pull request title"`                                                                         |
| `pr_description` | `"Triggered by https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"` | `"Pull request description"`                                                                   |
| `pr_base`        | `"master"`                                                                    | `"Pull request base"`                                                                          |
| `pr_labels`      | `""`                                                                          | `"Pull request labels separated by comma"`                                                     | 

## [Git-Commit](https://github.com/0xsequence/actions/tree/master/git-commit)

- Commit back files to same destination. Overwrite existing files with changes and commit back.
- [Examples](https://github.com/0xsequence/actions/blob/master/.github/workflows/git-copy.yml)

| parameters       | Default value                                                                 | Description                                  |
|------------------|-------------------------------------------------------------------------------|----------------------------------------------|
| `files`          | `""`                                                                          | `"Can be a file, glob pattern (/**/*.json)"` |
| `branch`         | `""`                                                                          | `"Target branch. Created if does not exist"` |
| `user_name`      | `"${GITHUB_ACTOR}"`                                                           | `"Git user"`                                 |
| `user_email`     | `"$GITHUB_ACTOR_ID+$GITHUB_ACTOR@users.noreply.github.com"`                   | `"Git email"`                                |
| `commit_message` | `"[AUTOMATED] Update: ${INPUT_SRC}"`                                          | `"Commit message"`                           |
| `pr_create`      | `false`                                                                       | `"Create pull request or not."`              | 
| `pr_title`       | `"[AUTOMATED] Update files from ${GITHUB_REPOSITORY}"`                        | `"Pull request title"`                       |
| `pr_description` | `"Triggered by https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"` | `"Pull request description"`                 |
| `pr_base`        | `"master"`                                                                    | `"Pull request base"`                        |
| `pr_labels`      | `""`                                                                          | `"Pull request labels separated by comma"`   | 
