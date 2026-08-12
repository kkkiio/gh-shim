///|
test "routes comment-aware PR views and preserves native projections" (
  t : @test.Test,
) {
  let cases = [
    ["pr", "view", "2", "--comments"],
    ["pr", "view", "2", "--json", "reviews,comments"],
    ["pr", "view", "2", "--json=reviewThreads"],
    ["pr", "view", "2", "--json", "title"],
    ["issue", "list"],
  ]
  for arguments in cases {
    let mode = match @gh_shim.invocation_mode(arguments) {
      Passthrough => "passthrough"
      TextComments => "text comments"
      JsonComments(fields) => "json comments: " + fields.join(",")
      Init => "init"
      Doctor => "doctor"
    }
    t.writeln(arguments.join(" ") + " => " + mode)
  }
  let rewritten = @gh_shim.rewrite_pr_view_arguments(
    [
      "pr", "view", "2", "-R", "kkkiio/agconf", "--comments", "--json", "reviews,comments",
      "--jq", ".comments",
    ],
    ["reviews", "comments", "url"],
  )
  t.writeln("rewritten => " + rewritten.join(" "))
  let rewritten_attached_template = @gh_shim.rewrite_pr_view_arguments(
    ["pr", "view", "2", "--json=comments", "-t{{len .comments}}"],
    ["comments", "url"],
  )
  t.writeln(
    "rewritten attached template => " + rewritten_attached_template.join(" "),
  )
  let reference = @gh_shim.parse_pull_request_url(
    "https://github.example.com/acme/widgets/pull/42",
  )
  t.writeln(
    "reference => \{reference.hostname}/\{reference.owner}/\{reference.name}#\{reference.number}",
  )
  t.snapshot(filename="command_routing.txt")
}

///|
test "renders native comments before grouped review thread snapshots" (
  t : @test.Test,
) {
  let root : @gh_shim.ReviewComment = {
    id: "PRRC_root",
    author: Some({ login: "reviewer" }),
    authorAssociation: "MEMBER",
    body: "Please fix this.",
    diffHunk: "@@ -1 +1 @@",
    createdAt: "2026-08-01T00:00:00Z",
    updatedAt: "2026-08-01T00:00:00Z",
    url: "https://github.com/acme/widgets/pull/1#discussion_r1",
  }
  let reply : @gh_shim.ReviewComment = {
    id: "PRRC_reply",
    author: Some({ login: "author" }),
    authorAssociation: "OWNER",
    body: "Fixed now.\nAdded a regression test.",
    diffHunk: "@@ -1 +1 @@",
    createdAt: "2026-08-02T00:00:00Z",
    updatedAt: "2026-08-02T00:00:00Z",
    url: "https://github.com/acme/widgets/pull/1#discussion_r2",
  }
  let threads : Array[@gh_shim.ReviewThread] = [
    {
      id: "resolved",
      path: "src/old.mbt",
      line: None,
      originalLine: Some(8),
      startLine: None,
      diffSide: Some("RIGHT"),
      startDiffSide: None,
      subjectType: "LINE",
      isResolved: true,
      isOutdated: true,
      resolvedBy: Some({ login: "author" }),
      comments: [root],
    },
    {
      id: "unresolved",
      path: "src/current.mbt",
      line: Some(12),
      originalLine: Some(12),
      startLine: None,
      diffSide: Some("RIGHT"),
      startDiffSide: None,
      subjectType: "LINE",
      isResolved: false,
      isOutdated: false,
      resolvedBy: None,
      comments: [root, reply],
    },
  ]
  t.write(
    @gh_shim.render_review_threads(
      threads,
      native_output="author: reviewer\nassociation: member\n",
    ),
  )
  t.snapshot(filename="review_threads_text.txt")
}

///|
async test "renders a real Codex Connector review without live GitHub access" (
  t : @test.Test,
) {
  let fixture = @json.parse(
    @fs.read_file("gh/testdata/codex-connector-review.json").text(),
  )
  guard fixture is Object(fields) &&
    fields.get("nativeOutput") is Some(String(native_output)) &&
    fields.get("reviewThreads") is Some(review_threads) else {
    fail("expected the Codex Connector review fixture")
  }
  let threads : Array[@gh_shim.ReviewThread] = @json.from_json(review_threads)
  t.write(@gh_shim.render_review_threads(threads, native_output~))
  t.snapshot(filename="codex_connector_review.txt")
}

///|
test "serializes the public review thread JSON contract" (t : @test.Test) {
  let thread : @gh_shim.ReviewThread = {
    id: "thread",
    path: "README.md",
    line: None,
    originalLine: None,
    startLine: None,
    diffSide: None,
    startDiffSide: None,
    subjectType: "FILE",
    isResolved: false,
    isOutdated: false,
    resolvedBy: None,
    comments: [],
  }
  let encoded = @json.to_json(thread)
  let decoded : @gh_shim.ReviewThread = @json.from_json(encoded)
  t.writeln(@json.to_json(decoded).stringify(indent=2))
  t.snapshot(filename="review_thread_json.txt")
}
