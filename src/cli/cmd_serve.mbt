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
fn run_serve_command() -> CliOutcome {
  let session = prepare_serve_session("dist")
  { exit_code: 0, message: format_serve_message(session) }
}

///|
pub fn run_serve_command_runtime_from_config(config_path : String) -> CliOutcome {
  ignore(config_path)
  let session = prepare_serve_session(
    "dist",
    note="Serve runtime command skeleton prepared.",
  )
  {
    exit_code: 0,
    message: "[serve] runtime ready\naddress: http://\{session.host}:\{session.port}\npreview root: \{session.preview_root}\nstatus: serve preview runner not connected yet",
  }
}

///|
fn run_serve_command_runtime() -> CliOutcome {
  run_serve_command_runtime_from_config("moonink.json")
}

///|
fn run_native_serve_command() -> CliOutcome {
  @runtime.run_native_runtime_io_task_with_policy(
    @runtime.RuntimeIOTask::Ready(run_serve_command_runtime()),
    @runtime.native_runtime_adapter().policy,
  )
}
