///|
pub const DEFAULT_SERVE_HOST : String = "127.0.0.1"

///|
pub const DEFAULT_SERVE_PORT : Int = 3000

///|
pub(all) struct ServeSession {
  host : String
  port : Int
  preview_root : String
  note : String
} derive(Debug, Eq)

///|
pub fn prepare_serve_session(
  preview_root : String,
  host? : String = DEFAULT_SERVE_HOST,
  port? : Int = DEFAULT_SERVE_PORT,
  note? : String = "Serve runtime session prepared.",
) -> ServeSession {
  { host, port, preview_root, note }
}

///|
fn format_serve_message(session : ServeSession) -> String {
  "[serve] runtime execution required\naddress: http://\{session.host}:\{session.port}\npreview root: \{session.preview_root}"
}

///|
fn format_runtime_ready_message(session : ServeSession) -> String {
  "[serve] runtime ready\naddress: http://\{session.host}:\{session.port}\npreview root: \{session.preview_root}\nstatus: \{session.note}"
}

///|
fn run_serve_command() -> CliOutcome {
  let session = prepare_serve_session("dist")
  { exit_code: 0, message: format_serve_message(session) }
}

///|
pub fn run_serve_command_runtime_from_config_with_runner(
  config_path : String,
  runner : @runtime.PreviewRunner,
) -> CliOutcome {
  let config = match @runtime.load_config_result(config_path) {
    Ok(config) => config
    Err(err) =>
      return { exit_code: 1, message: format_runtime_config_error(err) }
  }
  let inventory = match
    @runtime.run_runtime_io_task(@runtime.discover_content_task(config)) {
    Ok(inventory) => inventory
    Err(err) =>
      return { exit_code: 1, message: format_runtime_content_error(err) }
  }
  match build_site_result(config, inventory) {
    Ok(_) => {
      let preview_root = output_root(config)
      let launch = @runtime.prepare_preview_launch(
        preview_root,
        DEFAULT_SERVE_HOST,
        DEFAULT_SERVE_PORT,
      )
      match @runtime.launch_preview_result(runner, launch) {
        Ok(preview) => {
          let session = prepare_serve_session(
            preview.root_dir,
            host=preview.host,
            port=preview.port,
            note=preview.note,
          )
          { exit_code: 0, message: format_runtime_ready_message(session) }
        }
        Err(err) =>
          {
            exit_code: 1,
            message: "[serve] failed during preview launch\n\{@core.format_project_io_error(err)}",
          }
      }
    }
    Err(err) => { exit_code: 1, message: format_build_command_error(err) }
  }
}

///|
pub fn run_serve_command_runtime_from_config(
  config_path : String,
) -> CliOutcome {
  run_serve_command_runtime_from_config_with_runner(
    config_path,
    @runtime.dry_run_preview_runner(),
  )
}

///|
fn run_serve_command_runtime() -> CliOutcome {
  run_serve_command_runtime_from_config_with_runner(
    "moonink.json",
    @runtime.native_mocket_preview_runner(),
  )
}

///|
fn run_native_serve_command() -> CliOutcome {
  @runtime.run_native_runtime_io_task_with_policy(
    @runtime.RuntimeIOTask::Ready(run_serve_command_runtime()),
    @runtime.native_runtime_adapter().policy,
  )
}
