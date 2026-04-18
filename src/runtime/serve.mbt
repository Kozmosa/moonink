///|
pub enum PreviewRunner {
  DryRun
  NativeMocket
} derive(Debug, Eq)

///|
pub fn dry_run_preview_runner() -> PreviewRunner {
  PreviewRunner::DryRun
}

///|
pub fn native_mocket_preview_runner() -> PreviewRunner {
  PreviewRunner::NativeMocket
}

///|
pub(all) struct PreviewLaunch {
  root_dir : String
  host : String
  port : Int
  note : String
} derive(Debug, Eq)

///|
pub fn prepare_preview_launch(
  root_dir : String,
  host : String,
  port : Int,
  note? : String = "Preview launch prepared.",
) -> PreviewLaunch {
  { root_dir, host, port, note }
}

///|
fn validate_preview_root(root_dir : String) -> Unit raise @core.ProjectIOError {
  if !io_path_exists(root_dir) {
    raise @core.project_io_error(
      "serve_preview", root_dir, "preview root does not exist",
    )
  }
  let is_dir = io_is_dir(root_dir)
  if !is_dir {
    raise @core.project_io_error(
      "serve_preview", root_dir, "preview root is not a directory",
    )
  }
}

///|
pub fn launch_preview_result(
  runner : PreviewRunner,
  launch : PreviewLaunch,
) -> Result[PreviewLaunch, @core.ProjectIOError] {
  validate_preview_root(launch.root_dir) catch {
    err => return Err(err)
  }
  match runner {
    PreviewRunner::DryRun =>
      Ok({
        ..launch,
        note: "Dry-run preview launch validated the built output without starting a server.",
      })
    PreviewRunner::NativeMocket =>
      Ok({
        ..launch,
        note: "Native mocket preview runner is reserved for a native-only entrypoint.",
      })
  }
}

///|
fn shell_quote(value : String) -> String {
  let mut quoted = "'"
  for i in 0..<value.length() {
    let char = value[i:i + 1].to_string()
    if char == "'" {
      quoted = quoted + "'\"'\"'"
    } else {
      quoted = quoted + char
    }
  }
  quoted + "'"
}

///|
fn serve_delegate_workspace_root() -> String raise @core.ProjectIOError {
  let cwd = match @env.current_dir() {
    Some(path) => path
    None =>
      raise @core.project_io_error(
        "serve_delegate", ".", "current working directory is unavailable",
      )
  }
  match find_workspace_root_from(cwd) {
    Some(root) => root
    None =>
      raise @core.project_io_error(
        "serve_delegate", cwd, "could not locate MoonInk workspace root for native serve delegation",
      )
  }
}

///|
fn moon_cli_command() -> String {
  match @env.get_env_var("HOME") {
    Some(home) => shell_quote(home + "/.moon/bin/moon")
    None => "moon"
  }
}

///|
pub fn native_serve_delegate_command_result(
  root_dir : String,
  host : String,
  port : Int,
) -> Result[String, @core.ProjectIOError] {
  let workspace_root = serve_delegate_workspace_root() catch {
    err => return Err(err)
  }
  Ok(
    "cd " +
    shell_quote(workspace_root) +
    " && " +
    moon_cli_command() +
    " run --manifest-path native-serve/moon.mod.json native-serve/src/cmd/main --target native -- serve-prebuilt --root " +
    shell_quote(root_dir) +
    " --host " +
    shell_quote(host) +
    " --port " +
    shell_quote(port.to_string()),
  )
}
