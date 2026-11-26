///|
async fn main {
  try {
    let arguments = @env.args()
    let forwarded = if arguments.length() > 1 {
      arguments[1:].to_owned()
    } else {
      []
    }
    let executable = if arguments.length() > 0 {
      arguments[0]
    } else {
      "gh-shim"
    }
    let code = @lib.run(forwarded, executable~)
    if code != 0 {
      @env.exit(code)
    }
  } catch {
    Failure::Failure(message) => {
      @stdio.stderr.write("gh-shim: " + message + "\n")
      @env.exit(1)
    }
    error => {
      @stdio.stderr.write("gh-shim: \{error}\n")
      @env.exit(1)
    }
  }
}
