///|
pub(all) enum InvocationMode {
  Passthrough
  TextComments
  JsonComments(Array[String])
  Init
  Doctor
} derive(Eq, Debug)

///|
pub(all) struct PullRequestRef {
  hostname : String
  owner : String
  name : String
  number : Int
} derive(Eq, Debug)

///|
pub(all) struct Author {
  login : String
} derive(Eq, Debug, ToJson, @json.FromJson)

///|
pub(all) struct ReviewComment {
  id : String
  author : Author?
  authorAssociation : String
  body : String
  diffHunk : String
  createdAt : String
  updatedAt : String
  url : String
} derive(Eq, Debug)

///|
pub(all) struct ReviewThread {
  id : String
  path : String
  line : Int?
  originalLine : Int?
  startLine : Int?
  diffSide : String?
  startDiffSide : String?
  subjectType : String
  isResolved : Bool
  isOutdated : Bool
  resolvedBy : Author?
  comments : Array[ReviewComment]
} derive(Eq, Debug)

///|
pub impl ToJson for ReviewComment with fn to_json(self) {
  Json::object({
    "id": Json::string(self.id),
    "author": match self.author {
      Some(author) => @json.to_json(author)
      None => Json::null()
    },
    "authorAssociation": Json::string(self.authorAssociation),
    "body": Json::string(self.body),
    "diffHunk": Json::string(self.diffHunk),
    "createdAt": Json::string(self.createdAt),
    "updatedAt": Json::string(self.updatedAt),
    "url": Json::string(self.url),
  })
}

///|
pub impl ToJson for ReviewThread with fn to_json(self) {
  Json::object({
    "id": Json::string(self.id),
    "path": Json::string(self.path),
    "line": match self.line {
      Some(line) => @json.to_json(line)
      None => Json::null()
    },
    "originalLine": match self.originalLine {
      Some(line) => @json.to_json(line)
      None => Json::null()
    },
    "startLine": match self.startLine {
      Some(line) => @json.to_json(line)
      None => Json::null()
    },
    "diffSide": match self.diffSide {
      Some(side) => Json::string(side)
      None => Json::null()
    },
    "startDiffSide": match self.startDiffSide {
      Some(side) => Json::string(side)
      None => Json::null()
    },
    "subjectType": Json::string(self.subjectType),
    "isResolved": Json::boolean(self.isResolved),
    "isOutdated": Json::boolean(self.isOutdated),
    "resolvedBy": match self.resolvedBy {
      Some(author) => @json.to_json(author)
      None => Json::null()
    },
    "comments": @json.to_json(self.comments),
  })
}

///|
pub impl @json.FromJson for ReviewComment with fn from_json(
  json : Json,
  path : @json.JsonPath,
) -> ReviewComment raise {
  guard json is Object(fields) else {
    raise @json.JsonDecodeError((path, "expected an object for ReviewComment"))
  }
  let required = [
    "id", "authorAssociation", "body", "diffHunk", "createdAt", "updatedAt", "url",
  ]
  for key in required {
    if !fields.contains(key) {
      raise @json.JsonDecodeError((path.add_key(key), "missing required field"))
    }
  }
  let author = match fields.get("author") {
    None | Some(Null) => None
    Some(value) => Some(@json.from_json(value, path=path.add_key("author")))
  }
  {
    id: @json.from_json(fields["id"], path=path.add_key("id")),
    author,
    authorAssociation: @json.from_json(
      fields["authorAssociation"],
      path=path.add_key("authorAssociation"),
    ),
    body: @json.from_json(fields["body"], path=path.add_key("body")),
    diffHunk: @json.from_json(fields["diffHunk"], path=path.add_key("diffHunk")),
    createdAt: @json.from_json(
      fields["createdAt"],
      path=path.add_key("createdAt"),
    ),
    updatedAt: @json.from_json(
      fields["updatedAt"],
      path=path.add_key("updatedAt"),
    ),
    url: @json.from_json(fields["url"], path=path.add_key("url")),
  }
}

///|
pub impl @json.FromJson for ReviewThread with fn from_json(
  json : Json,
  path : @json.JsonPath,
) -> ReviewThread raise {
  guard json is Object(fields) else {
    raise @json.JsonDecodeError((path, "expected an object for ReviewThread"))
  }
  let required = [
    "id", "path", "subjectType", "isResolved", "isOutdated", "comments",
  ]
  for key in required {
    if !fields.contains(key) {
      raise @json.JsonDecodeError((path.add_key(key), "missing required field"))
    }
  }
  let line : Int? = match fields.get("line") {
    None | Some(Null) => None
    Some(value) => Some(@json.from_json(value, path=path.add_key("line")))
  }
  let original_line : Int? = match fields.get("originalLine") {
    None | Some(Null) => None
    Some(value) =>
      Some(@json.from_json(value, path=path.add_key("originalLine")))
  }
  let start_line : Int? = match fields.get("startLine") {
    None | Some(Null) => None
    Some(value) => Some(@json.from_json(value, path=path.add_key("startLine")))
  }
  let diff_side : String? = match fields.get("diffSide") {
    None | Some(Null) => None
    Some(value) => Some(@json.from_json(value, path=path.add_key("diffSide")))
  }
  let start_diff_side : String? = match fields.get("startDiffSide") {
    None | Some(Null) => None
    Some(value) =>
      Some(@json.from_json(value, path=path.add_key("startDiffSide")))
  }
  let resolved_by : Author? = match fields.get("resolvedBy") {
    None | Some(Null) => None
    Some(value) => Some(@json.from_json(value, path=path.add_key("resolvedBy")))
  }
  {
    id: @json.from_json(fields["id"], path=path.add_key("id")),
    path: @json.from_json(fields["path"], path=path.add_key("path")),
    line,
    originalLine: original_line,
    startLine: start_line,
    diffSide: diff_side,
    startDiffSide: start_diff_side,
    subjectType: @json.from_json(
      fields["subjectType"],
      path=path.add_key("subjectType"),
    ),
    isResolved: @json.from_json(
      fields["isResolved"],
      path=path.add_key("isResolved"),
    ),
    isOutdated: @json.from_json(
      fields["isOutdated"],
      path=path.add_key("isOutdated"),
    ),
    resolvedBy: resolved_by,
    comments: @json.from_json(fields["comments"], path=path.add_key("comments")),
  }
}

///|
priv struct PageInfo {
  hasNextPage : Bool
  endCursor : String?
} derive(@json.FromJson)

///|
priv struct ReviewCommentConnection {
  nodes : Array[ReviewComment]
  pageInfo : PageInfo
} derive(@json.FromJson)

///|
priv struct ReviewThreadNode {
  id : String
  path : String
  line : Int?
  originalLine : Int?
  startLine : Int?
  diffSide : String?
  startDiffSide : String?
  subjectType : String
  isResolved : Bool
  isOutdated : Bool
  resolvedBy : Author?
  comments : ReviewCommentConnection
} derive(@json.FromJson)

///|
priv struct ReviewThreadConnection {
  nodes : Array[ReviewThreadNode]
  pageInfo : PageInfo
} derive(@json.FromJson)

///|
priv struct PullRequestNode {
  reviewThreads : ReviewThreadConnection
} derive(@json.FromJson)

///|
priv struct RepositoryNode {
  pullRequest : PullRequestNode?
} derive(@json.FromJson)

///|
priv struct ReviewThreadsData {
  repository : RepositoryNode?
} derive(@json.FromJson)

///|
priv struct ReviewThreadsResponse {
  data : ReviewThreadsData?
} derive(@json.FromJson)

///|
priv struct CommentPageNode {
  comments : ReviewCommentConnection
} derive(@json.FromJson)

///|
priv struct CommentPageData {
  node : CommentPageNode?
} derive(@json.FromJson)

///|
priv struct CommentPageResponse {
  data : CommentPageData?
} derive(@json.FromJson)

///|
pub fn invocation_mode(arguments : Array[String]) -> InvocationMode {
  if arguments.length() > 0 && arguments[0] == "init" {
    return Init
  }
  if arguments.length() > 0 && arguments[0] == "doctor" {
    return Doctor
  }
  if arguments.length() < 2 || arguments[0] != "pr" || arguments[1] != "view" {
    return Passthrough
  }
  let fields : Array[String] = []
  let mut has_comments_flag = false
  let mut index = 2
  while index < arguments.length() {
    let argument = arguments[index]
    if argument == "--comments" || argument == "-c" {
      has_comments_flag = true
      index = index + 1
    } else if argument == "--json" && index + 1 < arguments.length() {
      for field in arguments[index + 1].split(",") {
        if field != "" && !fields.contains(field.to_owned()) {
          fields.push(field.to_owned())
        }
      }
      index = index + 2
    } else if argument.has_prefix("--json=") {
      for field in argument[7:].split(",") {
        if field != "" && !fields.contains(field.to_owned()) {
          fields.push(field.to_owned())
        }
      }
      index = index + 1
    } else {
      index = index + 1
    }
  }
  if fields.contains("comments") || fields.contains("reviewThreads") {
    JsonComments(fields)
  } else if fields.length() == 0 && has_comments_flag {
    TextComments
  } else {
    Passthrough
  }
}

///|
pub fn rewrite_pr_view_arguments(
  arguments : Array[String],
  json_fields : Array[String],
) -> Array[String] {
  let rewritten = ["pr", "view"]
  let mut index = 2
  while index < arguments.length() {
    let argument = arguments[index]
    if argument == "--comments" ||
      argument == "-c" ||
      argument == "--web" ||
      argument == "-w" {
      index = index + 1
    } else if argument == "--json" ||
      argument == "--jq" ||
      argument == "-q" ||
      argument == "--template" ||
      argument == "-t" {
      index = if index + 1 < arguments.length() { index + 2 } else { index + 1 }
    } else if argument.has_prefix("--json=") ||
      argument.has_prefix("--jq=") ||
      argument.has_prefix("--template=") {
      index = index + 1
    } else {
      rewritten.push(argument)
      index = index + 1
    }
  }
  rewritten.push("--json")
  rewritten.push(json_fields.join(","))
  rewritten
}

///|
pub fn parse_pull_request_url(url : String) -> PullRequestRef raise {
  let pieces = url.split("/").map(piece => piece.to_owned()).collect()
  guard pieces.length() >= 7 && pieces[0] == "https:" && pieces[2] != "" else {
    raise Failure::Failure("unexpected pull request URL: \{url}")
  }
  guard pieces[5] == "pull" && pieces[3] != "" && pieces[4] != "" else {
    raise Failure::Failure("unexpected pull request URL: \{url}")
  }
  let number = @string.parse_int(pieces[6]) catch {
    _ => raise Failure::Failure("unexpected pull request URL: \{url}")
  }
  if number <= 0 {
    raise Failure::Failure("unexpected pull request URL: \{url}")
  }
  { hostname: pieces[2], owner: pieces[3], name: pieces[4], number }
}

///|
fn shim_directory() -> String raise {
  let data_home = match @env.get_env_var("XDG_DATA_HOME") {
    Some(path) if path != "" => path.trim_end(chars="/").to_owned()
    _ =>
      match @env.get_env_var("HOME") {
        Some(home) if home != "" =>
          home.trim_end(chars="/").to_owned() + "/.local/share"
        _ => raise Failure::Failure("HOME is required")
      }
  }
  if data_home.has_prefix("/") {
    data_home + "/gh-shim/shims"
  } else {
    raise Failure::Failure("XDG_DATA_HOME must be an absolute path")
  }
}

///|
async fn resolve_real_gh() -> (String, String) {
  let path = @env.get_env_var("PATH").unwrap_or("")
  let shim = shim_directory().trim_end(chars="/").to_owned()
  let shim_real = if @fs.exists(shim) {
    @fs.realpath(shim) catch {
      _ => shim
    }
  } else {
    shim
  }
  let remaining : Array[String] = []
  let mut real_gh : String? = None
  for entry_view in path.split(":") {
    let entry = entry_view.to_owned()
    let comparable = if entry == "" {
      @env.current_dir().unwrap_or("")
    } else {
      entry.trim_end(chars="/").to_owned()
    }
    let comparable_real = if comparable != "" && @fs.exists(comparable) {
      @fs.realpath(comparable) catch {
        _ => comparable
      }
    } else {
      comparable
    }
    if comparable_real != shim_real {
      remaining.push(entry)
      if real_gh is None {
        let candidate = if comparable == "" { "gh" } else { comparable + "/gh" }
        if @fs.exists(candidate) && @fs.can_execute(candidate) {
          real_gh = Some(@fs.realpath(candidate) catch { _ => candidate })
        }
      }
    }
  }
  match real_gh {
    Some(executable) => (executable, remaining.join(":"))
    None =>
      raise Failure::Failure(
        "real gh executable not found after removing \{shim} from PATH",
      )
  }
}

///|
async fn fetch_review_threads(
  real_gh : String,
  clean_path : String,
  reference : PullRequestRef,
) -> Array[ReviewThread] {
  let query =
    #|query($owner:String!,$name:String!,$number:Int!,$after:String){
    #|  repository(owner:$owner,name:$name){
    #|    pullRequest(number:$number){
    #|      reviewThreads(first:100,after:$after){
    #|        nodes{id path line originalLine startLine diffSide startDiffSide subjectType isResolved isOutdated resolvedBy{login} comments(first:100){nodes{id author{login} authorAssociation body diffHunk createdAt updatedAt url} pageInfo{hasNextPage endCursor}}}
    #|        pageInfo{hasNextPage endCursor}
    #|      }
    #|    }
    #|  }
    #|}
  let comment_query =
    #|query($id:ID!,$after:String){
    #|  node(id:$id){
    #|    ... on PullRequestReviewThread{
    #|      comments(first:100,after:$after){nodes{id author{login} authorAssociation body diffHunk createdAt updatedAt url} pageInfo{hasNextPage endCursor}}
    #|    }
    #|  }
    #|}
  let threads : Array[ReviewThread] = []
  let mut after : String? = None
  while true {
    let query_arguments = [
      "api",
      "graphql",
      "--hostname",
      reference.hostname,
      "-f",
      "query=" + query,
      "-f",
      "owner=" + reference.owner,
      "-f",
      "name=" + reference.name,
      "-F",
      "number=\{reference.number}",
    ]
    match after {
      Some(cursor) => {
        query_arguments.push("-f")
        query_arguments.push("after=" + cursor)
      }
      None => ()
    }
    let (status, stdout, stderr) = @process.collect_output(
      real_gh,
      query_arguments,
      extra_env={ "PATH": clean_path },
    )
    if status != 0 {
      raise Failure::Failure(
        "failed to fetch review threads: " + stderr.text().trim().to_owned(),
      )
    }
    let normalized = @json.parse(stdout.text()).transform(
      @json.Replacer((_, value) => {
        if value is Null {
          None
        } else {
          Some(value)
        }
      }),
    )
    let response : ReviewThreadsResponse = @json.from_json(normalized)
    guard response.data is Some(data) &&
      data.repository is Some(repository) &&
      repository.pullRequest is Some(pull_request) else {
      raise Failure::Failure(
        "GitHub returned no pull request review thread data",
      )
    }
    for node in pull_request.reviewThreads.nodes {
      let comments = node.comments.nodes.copy()
      let mut comment_page = node.comments.pageInfo
      while comment_page.hasNextPage {
        guard comment_page.endCursor is Some(cursor) else {
          raise Failure::Failure(
            "GitHub omitted the next review comment cursor",
          )
        }
        let comment_arguments = [
          "api",
          "graphql",
          "--hostname",
          reference.hostname,
          "-f",
          "query=" + comment_query,
          "-f",
          "id=" + node.id,
          "-f",
          "after=" + cursor,
        ]
        let (comment_status, comment_stdout, comment_stderr) = @process.collect_output(
          real_gh,
          comment_arguments,
          extra_env={ "PATH": clean_path },
        )
        if comment_status != 0 {
          raise Failure::Failure(
            "failed to fetch review thread replies: " +
            comment_stderr.text().trim().to_owned(),
          )
        }
        let normalized_comments = @json.parse(comment_stdout.text()).transform(
          @json.Replacer((_, value) => {
            if value is Null {
              None
            } else {
              Some(value)
            }
          }),
        )
        let comment_response : CommentPageResponse = @json.from_json(
          normalized_comments,
        )
        guard comment_response.data is Some(comment_data) &&
          comment_data.node is Some(comment_node) else {
          raise Failure::Failure("GitHub returned no review thread reply data")
        }
        for comment in comment_node.comments.nodes {
          comments.push(comment)
        }
        comment_page = comment_node.comments.pageInfo
      }
      comments.sort_by((left, right) => {
        left.createdAt.lexical_compare(right.createdAt)
      })
      threads.push({
        id: node.id,
        path: node.path,
        line: node.line,
        originalLine: node.originalLine,
        startLine: node.startLine,
        diffSide: node.diffSide,
        startDiffSide: node.startDiffSide,
        subjectType: node.subjectType,
        isResolved: node.isResolved,
        isOutdated: node.isOutdated,
        resolvedBy: node.resolvedBy,
        comments,
      })
    }
    let page_info = pull_request.reviewThreads.pageInfo
    if page_info.hasNextPage {
      guard page_info.endCursor is Some(cursor) else {
        raise Failure::Failure("GitHub omitted the next review thread cursor")
      }
      after = Some(cursor)
    } else {
      break
    }
  }
  threads
}

///|
pub fn render_review_threads(
  input : Array[ReviewThread],
  native_output? : String = "",
) -> String {
  let threads = input.copy()
  threads.sort_by((left, right) => {
    let left_group = if !left.isResolved && !left.isOutdated {
      0
    } else if !left.isResolved {
      1
    } else if !left.isOutdated {
      2
    } else {
      3
    }
    let right_group = if !right.isResolved && !right.isOutdated {
      0
    } else if !right.isResolved {
      1
    } else if !right.isOutdated {
      2
    } else {
      3
    }
    if left_group != right_group {
      left_group - right_group
    } else {
      let left_time = if left.comments.length() > 0 {
        left.comments[0].createdAt
      } else {
        ""
      }
      let right_time = if right.comments.length() > 0 {
        right.comments[0].createdAt
      } else {
        ""
      }
      left_time.lexical_compare(right_time)
    }
  })
  let mut unresolved = 0
  let mut outdated = 0
  for thread in threads {
    if !thread.isResolved {
      unresolved = unresolved + 1
    }
    if thread.isOutdated {
      outdated = outdated + 1
    }
  }
  let resolved = threads.length() - unresolved
  let output = StringBuilder::new()
  output.write_string("review threads: \{threads.length()} total")
  if threads.length() > 0 {
    output.write_string(
      ", \{unresolved} unresolved, \{resolved} resolved; \{outdated} outdated",
    )
  }
  output.write_string("\n")
  if native_output != "" {
    output.write_string("\n")
    output.write_string(native_output)
    if !native_output.has_suffix("\n") {
      output.write_string("\n")
    }
  }
  if threads.length() == 0 {
    return output.to_string()
  }
  output.write_string("\nINLINE REVIEW THREADS\n")
  for thread in threads {
    let state = if thread.isResolved { "RESOLVED" } else { "UNRESOLVED" }
    let labels = if thread.isOutdated { state + ", OUTDATED" } else { state }
    let location = if thread.subjectType == "FILE" {
      thread.path
    } else {
      match thread.line {
        Some(line) => "\{thread.path}:\{line}"
        None =>
          match thread.originalLine {
            Some(line) => "\{thread.path}:\{line} (original)"
            None => thread.path
          }
      }
    }
    output.write_string("\n[\{labels}] \{location}\nthread: \{thread.id}\n")
    match thread.resolvedBy {
      Some(author) => output.write_string("resolved-by: \{author.login}\n")
      None => ()
    }
    if thread.comments.length() > 0 {
      output.write_string("url: \{thread.comments[0].url}\n")
    }
    for index = 0; index < thread.comments.length(); index = index + 1 {
      let comment = thread.comments[index]
      let login = match comment.author {
        Some(author) => author.login
        None => "ghost"
      }
      if index == 0 {
        output.write_string(
          "\n\{login} • \{comment.authorAssociation.to_lower()} • \{comment.createdAt}\n",
        )
        output.write_string(comment.body)
        output.write_string("\n")
      } else {
        output.write_string(
          "\n  reply: \{login} • \{comment.authorAssociation.to_lower()} • \{comment.createdAt}\n",
        )
        for line in comment.body.split("\n") {
          output.write_string("  " + line.to_owned() + "\n")
        }
      }
    }
  }
  output.to_string()
}

///|
async fn run_text_comments(
  real_gh : String,
  clean_path : String,
  arguments : Array[String],
) -> Int {
  let metadata_arguments = rewrite_pr_view_arguments(arguments, ["url"])
  let (metadata_status, metadata_stdout, metadata_stderr) = @process.collect_output(
    real_gh,
    metadata_arguments,
    extra_env={ "PATH": clean_path },
  )
  if metadata_status != 0 {
    @stdio.stderr.write(metadata_stderr)
    return metadata_status
  }
  guard @json.parse(metadata_stdout.text()) is Object(metadata) &&
    metadata.get("url") is Some(String(url)) else {
    raise Failure::Failure("real gh returned no pull request URL")
  }
  let reference = parse_pull_request_url(url)
  let (native_status, native_stdout, native_stderr) = @process.collect_output(
    real_gh,
    arguments,
    extra_env={ "PATH": clean_path },
  )
  if native_status != 0 {
    @stdio.stderr.write(native_stderr)
    return native_status
  }
  let threads = fetch_review_threads(real_gh, clean_path, reference)
  @stdio.stdout.write(
    render_review_threads(threads, native_output=native_stdout.text()),
  )
  if native_stderr.text() != "" {
    @stdio.stderr.write(native_stderr)
  }
  0
}

///|
async fn run_json_comments(
  real_gh : String,
  clean_path : String,
  arguments : Array[String],
  requested_fields : Array[String],
) -> Int {
  let native_fields = requested_fields.filter(field => field != "reviewThreads")
  if !native_fields.contains("url") {
    native_fields.push("url")
  }
  let native_arguments = rewrite_pr_view_arguments(arguments, native_fields)
  let (native_status, native_stdout, native_stderr) = @process.collect_output(
    real_gh,
    native_arguments,
    extra_env={ "PATH": clean_path },
  )
  if native_status != 0 {
    @stdio.stderr.write(native_stderr)
    return native_status
  }
  guard @json.parse(native_stdout.text()) is Object(native_object) &&
    native_object.get("url") is Some(String(url)) else {
    raise Failure::Failure("real gh returned no pull request URL")
  }
  let reference = parse_pull_request_url(url)
  let threads = fetch_review_threads(real_gh, clean_path, reference)
  if !requested_fields.contains("url") {
    native_object.remove("url")
  }
  native_object["reviewThreads"] = @json.to_json(threads)
  let enhanced = Json::object(native_object).stringify()
  let mut jq_expression : String? = None
  let mut template : String? = None
  let mut index = 0
  while index < arguments.length() {
    let argument = arguments[index]
    if (argument == "--jq" || argument == "-q") &&
      index + 1 < arguments.length() {
      jq_expression = Some(arguments[index + 1])
      index = index + 2
    } else if argument.has_prefix("--jq=") {
      jq_expression = Some(argument[5:].to_owned())
      index = index + 1
    } else if (argument == "--template" || argument == "-t") &&
      index + 1 < arguments.length() {
      template = Some(arguments[index + 1])
      index = index + 2
    } else if argument.has_prefix("--template=") {
      template = Some(argument[11:].to_owned())
      index = index + 1
    } else {
      index = index + 1
    }
  }
  if template is Some(_) {
    raise Failure::Failure(
      "--template is not supported for enhanced reviewThreads output",
    )
  }
  match jq_expression {
    None => @stdio.stdout.write(enhanced + "\n")
    Some(expression) =>
      @async.with_task_group() <| group => {
        let temporary = @fs.tmpdir(prefix="gh-shim-json")
        group.add_defer(() => {
          @async.protect_from_cancel(() => @fs.rmdir(temporary, recursive=true))
        })
        let input = temporary + "/input.json"
        @fs.write_file(input, enhanced, create_mode=CreateOrTruncate)
        let (jq_status, jq_stdout, jq_stderr) = @process.collect_output(
          "jq",
          ["-r", expression, input],
          extra_env={ "PATH": clean_path },
        )
        if jq_status != 0 {
          raise Failure::Failure(
            "jq failed: " + jq_stderr.text().trim().to_owned(),
          )
        }
        @stdio.stdout.write(jq_stdout)
      }
  }
  if native_stderr.text() != "" {
    @stdio.stderr.write(native_stderr)
  }
  0
}

///|
async fn run_init(arguments : Array[String], executable : String) -> Int {
  let shim = shim_directory()
  if !@fs.exists(shim) {
    @fs.mkdir(shim, recursive=true)
  }
  let launcher = shim + "/gh"
  let engine = if executable.has_prefix("/") {
    executable
  } else if executable.find("/") is Some(_) {
    @env.current_dir().unwrap_or("").trim_end(chars="/").to_owned() +
    "/" +
    executable
  } else {
    let mut located : String? = None
    for entry in @env.get_env_var("PATH").unwrap_or("").split(":") {
      if located is None {
        let candidate = if entry == "" {
          executable
        } else {
          entry.trim_end(chars="/").to_owned() + "/" + executable
        }
        if @fs.exists(candidate) && @fs.can_execute(candidate) {
          located = Some(candidate)
        }
      }
    }
    match located {
      Some(path) => path
      None => raise Failure::Failure("cannot locate the gh-shim executable")
    }
  }
  let quoted_engine = engine.replace_all(old="'", new="'\\''")
  @fs.write_file(
    launcher,
    "#!/bin/sh\nGH_SHIM_INVOKED_AS_GH=1 exec '\{quoted_engine}' \"$@\"\n",
    create_mode=CreateOrTruncate,
    permission=0o755,
  )
  @fs.chmod(launcher, 0o755)
  let print_only = arguments.contains("-")
  let requested_shell = arguments.search_by(argument => {
    argument != "init" && argument != "-"
  })
  let shell = match requested_shell {
    Some(index) => arguments[index]
    None =>
      match @env.get_env_var("SHELL") {
        Some(path) =>
          match path.rev_find("/") {
            Some(index) => path[index + 1:].to_owned()
            None => path
          }
        None =>
          raise Failure::Failure("SHELL is required; pass zsh, bash, or fish")
      }
  }
  if shell != "zsh" && shell != "bash" && shell != "fish" {
    raise Failure::Failure(
      "unsupported shell: \{shell}; expected zsh, bash, or fish",
    )
  }
  let path = @env.get_env_var("PATH").unwrap_or("")
  let clean_entries = path
    .split(":")
    .filter(entry => entry.trim_end(chars="/") != shim)
    .map(entry => entry.to_owned())
  if print_only {
    if shell == "fish" {
      let quoted = [shim, ..clean_entries].map(entry => {
        "'" +
        entry.replace_all(old="\\", new="\\\\").replace_all(old="'", new="\\'") +
        "'"
      })
      println("set -gx PATH " + quoted.join(" "))
    } else {
      let value = (shim + ":" + clean_entries.join(":")).replace_all(
        old="'",
        new="'\\''",
      )
      println("export PATH='\{value}'")
    }
    return 0
  }
  let home = @env.get_env_var("HOME").unwrap_or("")
  if home == "" {
    raise Failure::Failure("HOME is required")
  }
  let config = match shell {
    "zsh" => home + "/.zshrc"
    "bash" => home + "/.bashrc"
    _ =>
      @env.get_env_var("XDG_CONFIG_HOME").unwrap_or(home + "/.config") +
      "/fish/config.fish"
  }
  let line = if shell == "fish" {
    let fish_engine = engine
      .replace_all(old="\\", new="\\\\")
      .replace_all(old="'", new="\\'")
    "'\{fish_engine}' init - fish | source"
  } else {
    "eval \"$('\{quoted_engine}' init - \{shell})\""
  }
  let existing = if @fs.exists(config) {
    @fs.read_file(config).text()
  } else {
    ""
  }
  if !existing.split("\n").any(item => item == line) {
    let separator = if existing == "" || existing.has_suffix("\n") {
      ""
    } else {
      "\n"
    }
    @fs.write_file(
      config,
      separator + line + "\n",
      create_mode=OpenOrCreate,
      append=true,
    )
  }
  println("installed gh shim: \{launcher}")
  println("updated \{config}")
  println("restart the shell or run: exec \"$SHELL\"")
  0
}

///|
async fn run_doctor(real_gh : String, clean_path : String) -> Int {
  let shim = shim_directory() catch { error => "unavailable: \{error}" }
  let path = @env.get_env_var("PATH").unwrap_or("")
  let entries = path.split(":").map(entry => entry.to_owned()).collect()
  let first = if entries.length() > 0 { entries[0] } else { "" }
  let active = first.trim_end(chars="/") == shim.trim_end(chars="/")
  println("shim directory: \{shim}")
  println("real gh:        \{real_gh}")
  println("shim active:    \{active}")
  let (status, stdout, stderr) = @process.collect_output(
    real_gh,
    ["--version"],
    extra_env={ "PATH": clean_path },
  )
  if stdout.text() != "" {
    @stdio.stdout.write(stdout)
  }
  if stderr.text() != "" {
    @stdio.stderr.write(stderr)
  }
  status
}

///|
pub async fn run(
  arguments : Array[String],
  executable? : String = "gh-shim",
) -> Int {
  let invoked_as_gh = @env.get_env_var("GH_SHIM_INVOKED_AS_GH") == Some("1")
  let mode = if invoked_as_gh {
    match invocation_mode(arguments) {
      Init | Doctor => Passthrough
      other => other
    }
  } else {
    invocation_mode(arguments)
  }
  match mode {
    Init => run_init(arguments, executable)
    _ => {
      let (real_gh, clean_path) = resolve_real_gh()
      match mode {
        Passthrough =>
          @process.run(
            real_gh,
            arguments,
            extra_env={ "PATH": clean_path },
            stdin=@stdio.stdin,
            stdout=@stdio.stdout,
            stderr=@stdio.stderr,
          )
        TextComments => run_text_comments(real_gh, clean_path, arguments)
        JsonComments(fields) =>
          run_json_comments(real_gh, clean_path, arguments, fields)
        Doctor => run_doctor(real_gh, clean_path)
        Init => abort("handled before resolving gh")
      }
    }
  }
}
