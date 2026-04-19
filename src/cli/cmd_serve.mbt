///|
pub const DEFAULT_SERVE_HOST : String = "127.0.0.1"

///|
pub const DEFAULT_SERVE_PORT : Int = 3000

///|
pub struct ServeSession {
  host : String
  port : Int
  preview_root : String
  note : String
} derive(Debug, Eq)

///|
pub enum ServeBuildStage {
  Clean(BuildSummary)
  WithWarnings(BuildSummary, Array[BuildDiagnostic])
} derive(Debug, Eq)

///|
pub(all) struct PreparedServeRuntime {
  session : ServeSession
  build_stage : ServeBuildStage
} derive(Debug, Eq)

///|
pub struct MainServeLaunch {
  build_message : String
  preview_root : String
  host : String
  port : Int
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
pub fn format_runtime_ready_message(session : ServeSession) -> String {
  "[serve] runtime ready\naddress: http://\{session.host}:\{session.port}\npreview root: \{session.preview_root}\nstatus: \{session.note}"
}

///|
pub fn format_serve_build_warnings(
  diagnostics : Array[BuildDiagnostic],
) -> String {
  let lines = ["[serve] build completed with warnings"]
  let mut output = lines.iter().join("\n")
  for diagnostic in diagnostics {
    output = output +
      "\n[" +
      diagnostic.source_path +
      "] " +
      diagnostic.entry.message
  }
  output
}

///|
fn format_serve_build_stage(stage : ServeBuildStage) -> String {
  match stage {
    ServeBuildStage::Clean(_) => "[serve] build completed"
    ServeBuildStage::WithWarnings(_, diagnostics) =>
      format_serve_build_warnings(diagnostics)
  }
}

///|
pub fn start_prepared_serve_session_result(
  session : ServeSession,
  runner : @runtime.PreviewRunner,
) -> Result[ServeSession, String] {
  let launch = @runtime.prepare_preview_launch(
    session.preview_root,
    session.host,
    session.port,
  )
  match @runtime.launch_preview_result(runner, launch) {
    Ok(preview) =>
      Ok(
        prepare_serve_session(
          preview.root_dir,
          host=preview.host,
          port=preview.port,
          note=preview.note,
        ),
      )
    Err(err) =>
      Err(
        "[serve] failed during preview startup\n" +
        @core.format_project_io_error(err),
      )
  }
}

///|
fn apply_serve_output_override_result(
  config : @core.MooninkConfig,
  output_dir : String?,
) -> Result[@core.MooninkConfig, @core.ConfigError] {
  match output_dir {
    Some(path) =>
      try @core.config_with_output_dir(config, path) catch {
        err => Err(err)
      } noraise {
        config => Ok(config)
      }
    None => Ok(config)
  }
}

///|
pub fn prepare_serve_runtime_session(
  config_path : String,
  output_dir : String?,
  host : String,
  port : Int,
) -> Result[PreparedServeRuntime, String] {
  match
    prepare_serve_watch_result(
      config_path,
      output_dir,
      host,
      port,
      1,
      empty_serve_render_cache(),
    ) {
    Ok(prepared) => Ok(prepared.runtime)
    Err(message) => Err(message)
  }
}

///|
fn run_serve_command(options : ServeCliOptions) -> CliOutcome {
  let output_status = match options.output_dir {
    Some(path) => "\noutput override: \{path}"
    None => ""
  }
  let session = prepare_serve_session(
    match options.output_dir {
      Some(path) => path
      None => "dist"
    },
    host=options.host,
    port=options.port,
  )
  {
    exit_code: 0,
    message: "[serve] build step will run before preview startup\n" +
    format_serve_message(session) +
    "\nconfig: " +
    options.config_path +
    output_status,
  }
}

///|
pub fn prepare_main_serve_launch_result(
  config_path : String,
  output_dir : String?,
  host : String,
  port : Int,
) -> Result[MainServeLaunch, String] {
  match
    prepare_main_serve_launch_with_watch_result(
      config_path, output_dir, host, port,
    ) {
    Ok((launch, _)) => Ok(launch)
    Err(message) => Err(message)
  }
}

///|
pub fn run_main_serve_command(options : ServeCliOptions) -> CliOutcome {
  run_serve_command_runtime_from_config_with_runner(
    options.config_path,
    options.output_dir,
    options.host,
    options.port,
    @runtime.native_mocket_preview_runner(),
  )
}

///|
pub fn run_serve_command_runtime_from_config_with_runner(
  config_path : String,
  output_dir : String?,
  host : String,
  port : Int,
  runner : @runtime.PreviewRunner,
) -> CliOutcome {
  let prepared = match
    prepare_serve_runtime_session(config_path, output_dir, host, port) {
    Ok(prepared) => prepared
    Err(message) => return { exit_code: 1, message }
  }
  let startup = match
    start_prepared_serve_session_result(prepared.session, runner) {
    Ok(session) => session
    Err(message) => return { exit_code: 1, message }
  }
  let build_message = format_serve_build_stage(prepared.build_stage)
  let final_session = match runner {
    @runtime.PreviewRunner::DryRun => startup
    @runtime.PreviewRunner::NativeMocket =>
      prepare_serve_session(
        startup.preview_root,
        host=startup.host,
        port=startup.port,
        note="Native mocket preview runner is validated for in-process main-binary serving.",
      )
  }
  {
    exit_code: 0,
    message: build_message + "\n" + format_runtime_ready_message(final_session),
  }
}

///|
pub fn run_serve_command_runtime_from_config(
  config_path : String,
) -> CliOutcome {
  run_serve_command_runtime_from_config_with_runner(
    config_path,
    None,
    DEFAULT_SERVE_HOST,
    DEFAULT_SERVE_PORT,
    @runtime.dry_run_preview_runner(),
  )
}

///|
pub fn run_serve_command_runtime() -> CliOutcome {
  run_serve_command_runtime_from_config_with_runner(
    "moonink.json",
    None,
    DEFAULT_SERVE_HOST,
    DEFAULT_SERVE_PORT,
    @runtime.native_mocket_preview_runner(),
  )
}

///|
fn run_native_serve_command(options : ServeCliOptions) -> CliOutcome {
  @runtime.run_native_runtime_io_task_with_policy(
    @runtime.RuntimeIOTask::Ready(
      run_serve_command_runtime_from_config_with_runner(
        options.config_path,
        options.output_dir,
        options.host,
        options.port,
        @runtime.native_mocket_preview_runner(),
      ),
    ),
    @runtime.native_runtime_adapter().policy,
  )
}
