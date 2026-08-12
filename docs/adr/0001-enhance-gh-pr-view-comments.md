# ADR 0001：完整呈现 PR 评论与 Review Threads

- 状态：已采纳
- 日期：2026-08-12

## 背景

开发者和 Coding Agent 在处理 PR review 意见时，通常首先调用：

```bash
gh pr view <pr> --comments
```

GitHub CLI 会展示 PR Conversation 中的普通评论和 review summary，但不会完整展示代码 diff 上的 inline review comments。用户必须知道 GitHub 的底层数据模型，再额外调用 `gh api` 才能发现这些意见。

真实 Agent 会话表明，这不是单纯的可发现性问题：Agent 在先后调用 `--comments` 和 `--json comments,reviews` 后，仍会断言 PR 没有实质 review 意见；只有用户继续提醒，它才会尝试 `pulls/{number}/comments` API。仅增加一个需要显式请求的新字段，无法改善现有调用路径。

GitHub 中相关信息属于不同的数据结构：

```text
IssueComment
  └─ PR Conversation 中的普通评论

PullRequestReview
  └─ 一次 review 的 summary 和状态

PullRequestReviewThread
  └─ 某个代码位置上的 review discussion
      └─ PullRequestReviewComment[]
```

Review thread 的 `path`、位置、`isResolved`、`isOutdated` 和回复关系，决定了一条意见是否仍需处理。将 inline comments 扁平化会丢失这些关键语义。

`gh-shim` 的目标是让现有 `gh` 调用获得用户合理预期的完整信息，而不是要求每个 Agent 学会一组额外的 GitHub API 命令。

## 决策

`gh-shim` 将：

```bash
gh pr view <pr> --comments
```

解释为：

> 返回 PR 上所有用户可感知的 Conversation 评论、review summaries 和 inline review threads。

增强仅作用于请求评论信息的 `gh pr view` 调用。未请求评论的 `gh pr view` 以及其他 `gh` 命令保持原有行为。

### 文本输出

文本输出采用“摘要 + 原生输出 + 分组 Threads”结构：

1. 首行给出 review thread 总数和状态摘要。
2. 保留原生 `gh pr view --comments` 的内容、顺序和格式。
3. 在 `INLINE REVIEW THREADS` 区域按 thread 展示所有 inline comments 及其回复。

下面用 unified diff 展示相对于原生 `gh` 输出新增的内容。没有 `+` 的行是原生输出，带 `+` 的行由 `gh-shim` 增加：

```diff
--- gh pr view 2 --comments
+++ gh-shim pr view 2 --comments
@@
+review threads: 3 total, 2 unresolved, 1 resolved; 1 outdated
+
 author: kkkiio
 association: owner
 edited: false
 status: none
 --
 @codex review
 --
+
+INLINE REVIEW THREADS
+
+[UNRESOLVED] agconf.mbt:571
+thread: PRRT_kwDOTnSuG...
+url: https://github.com/...#discussion_r3680150505
+
+chatgpt-codex-connector • none • 2026-07-30T05:08:26Z
+Normalize the URL used for operation output...
+
+  reply: kkkiio • owner • 2026-07-30T06:12:03Z
+  Fixed in abf46ef.
+
+[UNRESOLVED, OUTDATED] docs/fetch.md:191 (original)
+thread: PRRT_kwDOTnSuG...
+url: https://github.com/...#discussion_r3680150508
+
+chatgpt-codex-connector • none • 2026-07-30T05:08:26Z
+Replace mutable GitHub fixtures in the CI cram suite...
+
+[RESOLVED] docs/fetch.md:166
+thread: PRRT_kwDOTnSuG...
+resolved-by: kkkiio
+url: https://github.com/...#discussion_r3680233694
+
+chatgpt-codex-connector • none • 2026-07-30T05:29:37Z
+Correct the expected nested-skill prompt name...
```

所有 thread 都会显示，包括 resolved 和 outdated thread。`isResolved` 与 `isOutdated` 是相互独立的状态；摘要中的 outdated 数量可能与 resolved 或 unresolved 重叠。

Thread 按以下顺序分组：

1. unresolved、非 outdated
2. unresolved、outdated
3. resolved、非 outdated
4. resolved、outdated

同一组内按照 thread 第一条评论的创建时间升序排列，thread 内的回复按照创建时间升序排列。

位置优先使用当前 diff 位置。当前位置不存在时使用原始位置，并在文本中标记为 `original`。文件级评论显示文件路径，不虚构行号。

即使没有 inline review thread，摘要也明确显示：

```text
review threads: 0 total
```

这表示 review threads 已经被查询且结果为空，而不是未被查询。

### JSON 输出

`comments` 与 `reviewThreads` 保持为两个独立字段：

```text
comments
  = IssueComment[]

reviewThreads
  = PullRequestReviewThread[]
      └─ comments: PullRequestReviewComment[]
```

请求 `comments` 字段时，`gh-shim` 隐式补充同级的 `reviewThreads` 字段：

```bash
gh pr view <pr> --json comments
```

返回：

```json
{
  "comments": [],
  "reviewThreads": []
}
```

同样地：

```bash
gh pr view <pr> --json reviews,comments
```

返回 `reviews`、`comments` 和 `reviewThreads`。调用方也可以显式请求：

```bash
gh pr view <pr> --json reviewThreads
```

不包含 `comments` 或 `reviewThreads` 的字段投影不受影响。例如：

```bash
gh pr view <pr> --json title,state
```

仍然只返回 `title` 和 `state`。

`--jq` 在增强后的 JSON 对象上执行，因此可以访问 `reviewThreads`。显式选择 `.comments` 仍然只得到 `IssueComment[]`；inline comments 不会伪装成普通 Conversation comments。

Comment-aware projection 不接受 `--template`。完整兼容 GitHub CLI 的 Go Template 语法及扩展函数需要另一套运行时；提供语义不完整的模板子集会让已有命令产生不可预测的结果。检测到该组合时，在请求 PR 或 review thread 数据前以非零状态失败。未请求 `comments` 或 `reviewThreads` 的原生字段投影继续由 real gh 处理，因此其 `--template` 行为不变。

请求 `comments` 时隐式增加字段是有意的兼容性取舍。严格字段投影的重要性低于 `gh-shim` 的核心承诺：请求 PR 评论时不能静默漏掉 review feedback。

### Review Thread 数据契约

每个 `reviewThreads` 元素至少提供：

```json
{
  "id": "PRRT_kwDOTnSuG...",
  "path": "agconf.mbt",
  "line": 571,
  "originalLine": 571,
  "startLine": 570,
  "diffSide": "RIGHT",
  "subjectType": "LINE",
  "isResolved": false,
  "isOutdated": false,
  "resolvedBy": null,
  "comments": [
    {
      "id": "PRRC_kwDOTnSuG...",
      "author": {
        "login": "chatgpt-codex-connector"
      },
      "authorAssociation": "NONE",
      "body": "Normalize the URL used for operation output...",
      "diffHunk": "@@ -543,23 +559,50 @@ ...",
      "createdAt": "2026-07-30T05:08:26Z",
      "updatedAt": "2026-07-30T05:08:27Z",
      "url": "https://github.com/...#discussion_r3680150505"
    }
  ]
}
```

字段命名遵循 GitHub GraphQL 的 camelCase 习惯。没有值的位置字段使用 `null`，不使用 `0`、空字符串或推测值代替。

### 完整性与失败语义

返回结果必须覆盖全部 review threads 和 thread 内全部 comments，而不是只返回 API 的第一页。

如果 review threads 无法完整取得，命令必须以非零状态退出并给出明确错误。它不能把缺少 inline feedback 的原生输出作为成功结果返回，因为看似成功的不完整结果正是本决策要消除的问题。

## 结果

正面影响：

- Agent 继续使用熟悉的 `gh pr view --comments` 即可看到完整 review feedback。
- 未解决意见在摘要和排序中优先出现，不会被较长的 Conversation 淹没。
- Thread 的位置、解决状态、过期状态和回复关系得到保留。
- 空数组和零计数明确表示已经查询，调用方可以区分“没有”与“遗漏”。
- JSON 仍然保留 GitHub 原有对象类型，调用方不需要从混合数组中猜测评论类别。

负面影响：

- `--comments` 文本输出不再与原生 `gh` 完全相同。
- 请求 JSON `comments` 会得到一个未显式列出的同级字段，严格字段投影有所放宽。
- Comment-aware JSON projection 不能使用 `--template`。
- 获取全部 review threads 会增加网络请求、延迟和分页成本。
- GitHub API 权限、限流或暂时故障可能使原本能够部分成功的调用显式失败。

这些代价是可接受的，因为该命令的首要目标是可靠呈现完整反馈，而不是尽可能返回部分数据。

## 未采用的方案

### 只增加显式 `reviewThreads` 字段

拒绝。真实 Agent 不会主动请求一个它不知道存在的字段，仍会依据 `--comments` 或 `--json comments,reviews` 的不完整结果作出错误判断。

### 将所有评论合并为扁平数组

拒绝。`IssueComment` 和 `PullRequestReviewComment` 的语义不同；扁平化还会丢失 thread 的 resolved、outdated、位置和回复关系。

### 只显示 unresolved threads

拒绝。Resolved 和 outdated thread 仍是理解修改历史、确认处理结果和避免重复工作的有效上下文。默认输出完整数据，通过摘要与排序突出当前任务。

### 将所有反馈合并为统一时间线

拒绝作为默认结构。统一时间线适合审计，但不利于快速识别待处理 thread，也会模糊 thread 第一条评论与后续回复之间的边界。

### 获取失败时退化为原生输出

拒绝。静默退化会重新引入“命令成功但关键信息缺失”的问题，使调用方无法判断结果是否完整。

## 参考资料

- [GitHub CLI：`gh pr view` 手册](https://cli.github.com/manual/gh_pr_view)——记录 `--comments`、`--json`、`--jq`、`--template` 以及当前可选 JSON 字段。
- [cli/cli#359：Fine Grained Code Review Support](https://github.com/cli/cli/issues/359)——GitHub CLI 对细粒度 code review 支持的长期跟踪问题。
- [cli/cli#5788：`gh pr view --comments` should show all comments](https://github.com/cli/cli/issues/5788)——记录 inline review comments 缺失，以及 thread、文件位置和 resolved 状态对终端展示的必要性。
- [cli/cli#11477：`gh pr view --json comments` does not include review comments](https://github.com/cli/cli/issues/11477)——记录 JSON `comments` 字段不包含 review comments 的现有行为。
- [GitHub GraphQL：Pull requests reference](https://docs.github.com/en/graphql/reference/pulls#pullrequestreviewthread)——定义 `PullRequestReviewThread` 的 comments、位置、resolved、outdated 和 resolvedBy 等字段。
- [GitHub CLI：JSON formatting](https://cli.github.com/manual/gh_help_formatting)——定义 `--jq` 和 `--template` 在命令 JSON 输出上的格式化语义。
