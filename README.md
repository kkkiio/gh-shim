# gh-shim

![Difference between native gh and gh-shim PR comments output](docs/assets/gh-shim-comments-diff.jpg)

`gh-shim` is a transparent enhancement layer for GitHub CLI. It adds the inline review comments missing from `gh pr view --comments` while forwarding all other commands unchanged to the real `gh` executable.

## Why gh-shim

Native `gh pr view --comments` displays conversation comments and review summaries, but does not include all review comments and threads attached to lines of code. The command still succeeds, which can lead coding agents to incorrectly conclude that there is no feedback left to address.

Related GitHub CLI issues: [cli/cli#359](https://github.com/cli/cli/issues/359), [#3883](https://github.com/cli/cli/issues/3883), [#5788](https://github.com/cli/cli/issues/5788), and [#11477](https://github.com/cli/cli/issues/11477).

## Goals

- Preserve the existing `gh` command entry point, authentication, and behavior for regular commands.
- Include review comments in `gh pr view --comments` output.

## Installation

GitHub CLI must be installed and authenticated. Using `--jq` also requires `jq`.

```bash
# homebrew
brew install kkkiio/tap/gh-shim
gh-shim init

# or moon
moon install KKKIIO/gh-shim/cmd/gh-shim
~/.moon/bin/gh-shim init
```

Restart your terminal to activate the shim.

## Usage

```bash
gh pr view 42 --comments --repo owner/repository
```

When a JSON query requests `comments`, a sibling `reviewThreads` field is added:

```bash
gh pr view 42 --repo owner/repository --json comments \
  --jq '{comments: (.comments | length), reviewThreads: (.reviewThreads | length)}'
```

Enhanced JSON output supports both raw output and `--jq`, but not `--template`. To check the installation status:

```bash
gh-shim doctor
```

## Project lifecycle

If the official GitHub CLI gains complete review thread support, `gh-shim` will remove the corresponding enhancement. If no other information gaps remain, the project will be archived.

## Related work

[`agynio/gh-pr-review`](https://github.com/agynio/gh-pr-review) provides a dedicated workflow for viewing, replying to, and resolving review threads. In contrast, `gh-shim` enhances existing `gh pr view --comments` calls.
