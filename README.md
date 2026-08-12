# gh-shim

![原生 gh 与 gh-shim 的 PR comments 输出差异](docs/assets/gh-shim-comments-diff.jpg)

`gh-shim` 是 GitHub CLI 的透明增强层：补全 `gh pr view --comments` 遗漏的 inline review comments，其他命令原样转发给真实 `gh`。

## Why gh-shim

原生 `gh pr view --comments` 会显示 Conversation 评论和 review summary，却不会完整显示代码行上的 review comments/threads。命令仍会成功，因此 Coding Agent 容易误判为“没有待处理反馈”。

相关 GitHub CLI 问题：[cli/cli#359](https://github.com/cli/cli/issues/359)、[#3883](https://github.com/cli/cli/issues/3883)、[#5788](https://github.com/cli/cli/issues/5788)、[#11477](https://github.com/cli/cli/issues/11477)。

## Goals

- 保留现有 `gh` 命令入口、认证和普通命令行为。
- `gh pr view --comments` 输出 review comments。

## Installation

需要已安装并登录的 GitHub CLI；使用 `--jq` 时还需要安装 `jq`。

```bash
# homebrew
brew install kkkiio/tap/gh-shim
# or moon
moon install KKKIIO/gh-shim/cmd/gh-shim
```

安装后激活 shim：

```bash
gh-shim init
```

重新打开终端，使 shim 生效。

## Usage

```bash
gh pr view 42 --comments --repo owner/repository
```

JSON 请求 `comments` 时会增加同级字段 `reviewThreads`：

```bash
gh pr view 42 --repo owner/repository --json comments \
  --jq '{comments: (.comments | length), reviewThreads: (.reviewThreads | length)}'
```

增强 JSON 支持原始输出和 `--jq`，不支持 `--template`。检查安装状态：

```bash
gh-shim doctor
```

## Project lifecycle

如果官方 GitHub CLI 完整支持 review threads，`gh-shim` 将移除对应增强；若不再有其他信息缺口，项目会归档。

## Related work

[`agynio/gh-pr-review`](https://github.com/agynio/gh-pr-review) 提供查看、回复和解决 review threads 的专用工作流；`gh-shim` 则增强已有的 `gh pr view --comments` 调用。
