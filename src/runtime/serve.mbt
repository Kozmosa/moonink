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
      match validate_native_preview_startup_result(launch.host, launch.port) {
        Ok(_) =>
          Ok({
            ..launch,
            note: "Native mocket preview launch validated the built output for in-process main-binary serving.",
          })
        Err(err) => Err(err)
      }
  }
}
