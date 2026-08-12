# AGENTS.md

本文件说明修改 `gh-shim` 时需要保持的结构、术语、约束和验证流程。

## Project Structure Guide

### Overview

项目是一个 native MoonBit CLI。`gh` package 实现命令判定、真实 `gh` 查找、GraphQL review thread 获取、格式化与 shell 激活；`cmd/gh-shim` 只负责进程入口和退出状态。

### Repo Structure & Important Files

```text
.
├── AGENTS.md                         # 开发 Agent 的项目规则
├── README.md                         # 用户安装与最小使用路径
├── moon.mod                          # MoonBit module 与发布元数据
├── .github/workflows/
│   ├── ci.yml                        # main 与 PR 的格式、检查、测试和构建
│   └── release.yml                   # v*.*.* tag 的 macOS arm64 GitHub Release
├── gh/
│   ├── moon.pkg                      # 核心 package 及黑盒测试依赖
│   ├── gh_shim.mbt                   # shim runtime 与公开行为
│   ├── gh_shim_test.mbt              # 公开 API 黑盒快照测试
│   ├── testdata/                     # 离线真实场景 fixture
│   └── __snapshot__/                 # moon test 管理的行为快照
├── cmd/gh-shim/
│   ├── main.mbt                      # async CLI 入口和退出码传播
│   └── moon.pkg                      # 可安装 native main package
├── tests/
│   ├── fake-gh                       # 进程集成测试使用的确定性 real gh 替身
│   └── ubuntu-integration.sh         # native binary、PATH、分页与 shell 黑盒测试
└── docs/
    ├── assets/gh-shim-comments-diff.jpg # README 输出对比图
    └── adr/
        ├── 0001-enhance-gh-pr-view-comments.md
        └── 0002-install-and-activate-the-shim.md
```

### Architecture Guidelines

- 把 `cmd/gh-shim/main.mbt` 保持为薄入口，把命令语义留在 `gh` package。
- 让普通命令复用真实 `gh` 的 stdin、stdout、stderr 和退出码；仅增强 ADR 0001 指定的 PR comments 调用。
- 从移除 shim 目录后的 PATH 查找真实 `gh`，不要硬编码 Homebrew、Moon、apt 或 Nix 路径。
- 完整分页 review threads 及 thread comments；任何不完整结果都以非零状态失败。

## Domain Language

- **shim directory** — 位于 PATH 最前、只承载 `gh` launcher 的稳定用户数据目录。
- **launcher** — 名为 `gh`、把参数交给已安装 `gh-shim` 主程序的轻量入口。
- **real gh** — 从排除 shim directory 后的 PATH 中解析到的 GitHub CLI 可执行文件。
- **native output** — 相同参数交给 real gh 后产生的原始命令输出。
- **review thread** — 带代码位置、resolved/outdated 状态和有序回复的 inline review discussion。
- **comment-aware projection** — 请求 `--comments`、JSON `comments` 或 `reviewThreads` 的 `gh pr view` 调用。

## Policies & Mandatory Rules

### Compatibility Policy

当修改公开 API、CLI 参数、JSON 契约、文本结构或 shell 激活流程时，直接迁移到 ADR 描述的当前设计；项目处于 0.x，不添加 deprecated alias、legacy fallback 或兼容层。仅修改内部实现且外部契约不变时不需要声明 breaking change。

### Documentation Intent Principle

当用户体验或架构意图变化时，先更新 `docs/adr/` 中对应决策，再同步代码、快照和 `README.md` 的用户路径。不要在 README 或行为测试中描述内部实现自证、废弃行为或“不支持旧功能”的检查。

### MoonBit Code Policy

当修改 MoonBit 代码时，设计有深度、接口薄的函数；避免为了拆分而增加 helper，函数通常保持 20 行以上，并优先使用标准库或成熟依赖提供的能力。运行 `moon fmt` 后保留格式化结果。

### Test Policy

当修改 `gh/gh_shim.mbt`、`cmd/gh-shim/` 或公开输出契约时，只写黑盒测试；公开 package API 行为使用 `*_test.mbt` 和 `@test.Test::snapshot`，native 进程、环境变量、PATH 与 shell 行为使用 `tests/ubuntu-integration.sh`。不要创建 `_wbtest.mbt`。修改快照行为时，先用 `moon test --update` 更新并审查，再用普通 `moon test` 确认快照稳定。仅修改 ADR 或文字且行为不变时可跳过快照更新。

### Git Policy

检查改动时不要运行 `git diff --check`。不要回滚 Moon 工具自动产生的格式化或接口文件变更。

## Operation Guide

### Development Workflow

1. 同步依赖并格式化：

   ```bash
   moon update
   moon fmt
   ```

2. 修改公开 API 后生成并审查接口：

   ```bash
   moon info
   ```

3. 修改行为后更新并审查快照：

   ```bash
   moon test --update
   ```

### Testing & Automated Checks

修改 MoonBit 代码或 package manifest 时运行：

```bash
moon fmt
moon info
moon check
moon test
moon build
tests/ubuntu-integration.sh
```

修改 GitHub 查询、格式化或 shim 激活行为时，再使用已登录的 GitHub CLI 对一个含 unresolved threads、一个含 resolved/outdated threads 和一个零 threads 的 PR 做真实验证：

```bash
moon run cmd/gh-shim -- pr view <number> --repo <owner>/<repository> --comments
moon run cmd/gh-shim -- pr view <number> --repo <owner>/<repository> --json comments --jq '.reviewThreads | length'
```

### Local Install Verification

需要验证发布形态时，把 main package 目录作为 local source；不要把 module 根目录当作 main package：

```bash
moon install --bin <temporary-bin-directory> ./cmd/gh-shim
```

### Release

准备发布时，先把 `moon.mod` 的 `version` 更新为目标版本并完成 Testing & Automated Checks。随后创建匹配的 `v<version>` tag；`.github/workflows/release.yml` 会校验 tag 与 module 版本一致，构建并测试 macOS arm64 release binary，再发布带 SHA-256 校验和的 GitHub Release。
