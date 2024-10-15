# Reusable Github Actions

## [Git-Commit](https://github.com/0xsequence/actions/tree/master/git-commit)

- [Examples](https://github.com/0xsequence/actions/blob/master/.github/workflows/git-commit.yml)

| parameters       | Default value                                                                 | Description                                                                                         |
|------------------|-------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| `src`            | `""`                                                                          | `"Can be a file, glob pattern (/**/*.json) or folder"`                                              |
| `branch`         | `""`                                                                          | `"Target branch. Created if does not exist"`                                                        |
| `dst`            | `""`                                                                          | `"Src destination. Can be ommited if you want to overwrite existing files with a change"`           |
| `user_name`      | `"${GITHUB_ACTOR}"`                                                           | `"Git user"`                                                                                        |
| `user_email`     | `"$GITHUB_ACTOR_ID+$GITHUB_ACTOR@users.noreply.github.com"`                   | `"Git email"`                                                                                       |
| `repository`     | `"${GITHUB_REPOSITORY}"`                                                      | `"Target repository. If ommited then we use the same repository ( commit-back )"`                   |
| `commit_message` | `"[AUTOMATED] Update: ${INPUT_SRC}"`                                          | `"Commit message"`                                                                                  |
| `pr_create`      | `false`                                                                       | `"Create pull request or not."`                                                                     | 
| `pr_title`       | `"[AUTOMATED] Update files from ${GITHUB_REPOSITORY}"`                        | `"Pull request title"`                                                                              |
| `pr_description` | `"Triggered by https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"` | `"Pull request description"`                                                                        |
| `pr_base`        | `"master"`                                                                    | `"Pull request base"`                                                                               |
| `overwrite`      | `false`                                                                       | `"Used when you are using glob pattern in `src` and want to overwrite the same files with changes"` | 
