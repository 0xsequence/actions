# Reusable Github Actions

## [Git-Commit](https://github.com/0xsequence/actions/tree/master/git-commit)

- Create a new git commit in the same repository
    - Commit back to the same branch (e.g. in `master` branch or in a Pull Request)
    - Create a new branch + Submit Pull Request with the changes

### Example: Generate webrpc client & commit back

```yaml
name: make proto

on:
  workflow_call:

jobs:
  run:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.head_ref }} # Commit back to the original git branch (no merge commit).
          fetch-depth: 20

      - uses: actions/setup-go@v5
        with:
          go-version-file: "go.mod"

      - run: go generate ./...

      - name: Commit back
        uses: 0xsequence/actions/git-commit@master
        env:
          API_TOKEN_GITHUB: ${{ secrets.GH_TOKEN_GIT_COMMIT }}
        with:
          files: "proto/indexer.gen.* proto/clients/"
          branch: ${{ github.head_ref }}
          commit_message: "[AUTOMATED] make proto"

```


## [Git-Copy](https://github.com/0xsequence/actions/tree/master/git-copy)

- Copy selected files to another git repository
- Great for spreading auto-generated files, e.g. via Pull Requests

### Example: Copy auto-generated webrpc TypeScript client to another repo via Pull Request
```yaml
name: copy-ts-client

on:
  workflow_call:

jobs:
  copy-ts-client:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Biome formatter
        uses: biomejs/setup-biome@v2

      - name: Run Biome formatter
        run: |
          biome format \
          --indent-style=space --indent-width=2 --line-width=130 \
          --semicolons=as-needed --trailing-commas=none \
          --arrow-parentheses=as-needed \
          --javascript-formatter-quote-style=single --jsx-quote-style=single \
          --write proto/clients/indexer*.gen.ts

      - name: Copy TS client to sequence.js repository
        uses: 0xsequence/actions/git-copy@master
        env:
          API_TOKEN_GITHUB: ${{ secrets.GH_TOKEN_GIT_COMMIT }}
        with:
          src: "proto/clients/indexer*.gen.ts"
          dst: "packages/indexer/src/"
          branch: "update_indexer_client"
          repository: "0xsequence/sequence.js"
          pr_create: true
          pr_base: "master"
```