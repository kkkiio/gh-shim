# ADR 0002：分离安装与 Shell 激活

- 状态：已采纳
- 日期：2026-08-12

## 背景

`gh-shim` 必须让自己的 `gh` 入口出现在真实 GitHub CLI 之前，同时保留真实 `gh` 供透传和增强调用使用。

`moon install` 默认把二进制安装到 `~/.moon/bin`，但不保证该目录存在于 PATH 中，也不保证它排在真实 `gh` 之前。Homebrew 会把 formula 的可执行文件链接到共享的 `$(brew --prefix)/bin`，而官方 `gh` 已经占用其中的 `gh` 名称。

因此，包管理器既不能可靠决定 PATH 优先级，Homebrew formula 也不能在共享目录中同时安装另一个同名 `gh`。

pyenv、rbenv 和 asdf 等社区工具采用专用 shim 目录，并通过一次 shell 初始化将它放到 PATH 前面。安装软件与激活 shell hook 是两个不同的步骤。

## 决策

Moon 和 Homebrew 只安装名为 `gh-shim` 的主程序：

```text
Moon       ~/.moon/bin/gh-shim
Homebrew   $(brew --prefix)/bin/gh-shim
```

它们不安装或覆盖共享 PATH 中的 `gh`。

Moon registry 中的可安装 main package 是 `cmd/gh-shim`，因此发布后的命令为：

```bash
moon install KKKIIO/gh-shim/cmd/gh-shim
```

从本地源码验证时，直接把 main package 目录作为 source，例如：

```bash
moon install /path/to/gh-shim/cmd/gh-shim
```

用户安装后显式执行：

```bash
gh-shim init
```

该命令：

1. 在 `${XDG_DATA_HOME:-$HOME/.local/share}/gh-shim/shims` 创建 `gh` launcher。
2. 检测当前 shell。
3. 向对应的 shell 启动文件加入一条受管理的初始化语句。
4. 重复执行时不写入重复配置。

Zsh 写入 `.zshrc`。Bash 同时写入 `.bashrc` 和当前生效的登录启动文件：依次选择已有的 `.bash_profile`、`.bash_login`、`.profile`，都不存在时创建 `.bash_profile`。Fish 写入 `${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish`，并在首次配置时创建父目录。

自动写入的 managed 配置使用当前 `gh-shim` 的稳定绝对入口调用初始化命令。因此，即使 Moon 的 `~/.moon/bin` 原本不在新 shell 的 PATH 中，用户第一次用绝对路径执行 `gh-shim init` 后也能持续激活。Homebrew 场景记录稳定的 `$(brew --prefix)/bin/gh-shim` 链接，不记录 Cellar 版本目录。

Zsh 和 Bash 使用：

```bash
eval "$(gh-shim init - zsh)"
```

Fish 使用等价的 `source` 形式。

`gh-shim init` 是用户对修改 shell 配置的显式授权。`moon install`、`brew install` 和升级操作始终不修改用户的 dotfiles。

### 只输出初始化脚本

使用 dotfiles manager 或希望手动管理配置的用户调用：

```bash
gh-shim init - zsh
gh-shim init - bash
gh-shim init - fish
```

该模式确保 launcher 存在并只向 stdout 输出对应 shell 的初始化脚本，不修改 shell 启动文件。

初始化脚本每次执行时移除 PATH 中已有的 shim 目录，再将它添加到最前面。这样嵌套 shell 和重复加载不会不断累积相同 PATH 项。

### 查找真实 GitHub CLI

当 launcher 收到：

```bash
gh pr view 123 --comments
```

它把调用交给 `gh-shim`。`gh-shim` 从 PATH 中移除自己的 shim 目录，再按剩余 PATH 的顺序查找下一个可执行的 `gh`。

真实 `gh` 的路径不能硬编码，因为它可能来自 Homebrew、apt、Nix 或独立安装。传给真实进程的 PATH 同样移除 shim 目录，避免子进程再次解析到 shim。

普通命令使用真实 `gh` 的 stdin、stdout、stderr 和退出状态。只有 ADR 0001 确定的 PR comments 调用进入增强逻辑。

### 安装提示

Homebrew formula 的 Caveats 和 Moon 包文档都提示用户执行：

```bash
gh-shim init
exec "$SHELL"
```

安装器不把当前机器恰好已有的 PATH 顺序视为可依赖行为。

### 诊断

`gh-shim doctor` 显示：

```text
shim directory
real gh path
shim 是否位于 PATH 最前面
真实 gh 版本
```

这为 PATH 顺序错误、真实 `gh` 缺失和递归风险提供一个确定的诊断入口。

## 结果

正面影响：

- Moon 和 Homebrew 使用相同的激活模型。
- Homebrew formula 不与官方 `gh` 的链接冲突。
- 用户明确控制 shell 配置变更。
- shim 目录稳定，不依赖包管理器的版本目录。
- 升级 `gh-shim` 不需要重复修改 PATH。
- 卸载或临时禁用只需移除初始化行，真实 `gh` 会自然恢复。

负面影响：

- 安装后需要一次显式激活，不能只运行包管理器命令。
- 不同 shell 需要生成不同初始化语法。
- 如果用户移动或卸载 `gh-shim` 却保留初始化行，shell 启动时会报告找不到命令。

## 未采用的方案

### 让 Moon 直接安装名为 `gh` 的二进制

拒绝。它依赖 `~/.moon/bin` 恰好排在真实 `gh` 前面，也无法为 Homebrew 提供无冲突的对应行为。

### 让 Homebrew formula 覆盖官方 `gh`

拒绝。shim 依赖真实 `gh`，不能与其冲突或要求用户卸载它。

### 使用 shell alias 或 function 覆盖 `gh`

拒绝。Alias 和 function 的行为依赖交互式 shell，Coding Agent、脚本和其他进程启动方式可能绕过它们。

### 由包管理器自动修改 dotfiles

拒绝。包管理器无法可靠判断用户的 shell、启动文件和 dotfiles 管理方式。只有用户显式调用的 `gh-shim init` 可以执行该变更。

## 参考资料

- [pyenv：Understanding Shims](https://github.com/pyenv/pyenv/blob/master/README.md#understanding-shims)——说明 shim 位于 PATH 前端并把命令交给版本管理器。
- [pyenv：Advanced Configuration](https://github.com/pyenv/pyenv/blob/master/README.md#advanced-configuration)——说明 `init` 会移除 PATH 中重复的 shim 目录并重新前置，允许嵌套 shell 重复执行。
- [pyenv：`pyenv-which` 实现](https://github.com/pyenv/pyenv/blob/master/libexec/pyenv-which)——展示查找选定版本和 system executable 的实际路径解析逻辑。
- [rbenv：How rbenv hooks into your shell](https://github.com/rbenv/rbenv#how-rbenv-hooks-into-your-shell)——区分面向用户、会更新启动文件的 `init` 与只输出 shell 脚本的 `init -`。
- [asdf：How It Works](https://asdf-vm.com/guide/introduction.html#how-it-works)——说明工具安装后生成 shim，并由 shim 解析和执行选定版本。
- [asdf：Configure asdf](https://asdf-vm.com/guide/getting-started.html#_2-configure-asdf)——要求把专用 shims 目录放入 PATH，并给出不同 shell 的配置方式。
