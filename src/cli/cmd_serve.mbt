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
) -> Result[ServeSession, String] {
  let config = match @runtime.load_config_result(config_path) {
    Ok(config) => config
    Err(err) => return Err(format_runtime_config_error(err))
  }
  let config = match apply_serve_output_override_result(config, output_dir) {
    Ok(config) => config
    Err(err) => return Err(format_runtime_config_error(err))
  }
  let inventory = match
    @runtime.run_runtime_io_task(@runtime.discover_content_task(config)) {
    Ok(inventory) => inventory
    Err(err) => return Err(format_runtime_content_error(err))
  }
  match build_site_result(config, inventory) {
    Ok(_) => {
      let preview_root = output_root(config)
      let launch = @runtime.prepare_preview_launch(preview_root, host, port)
      match
        @runtime.launch_preview_result(
          @runtime.dry_run_preview_runner(),
          launch,
        ) {
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
            "[serve] failed during preview launch\n\{@core.format_project_io_error(err)}",
          )
      }
    }
    Err(err) => Err(format_build_command_error(err))
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
    message: format_serve_message(session) +
    "\nconfig: \{options.config_path}" +
    output_status,
  }
}

///|
pub fn run_serve_command_runtime_from_config_with_runner(
  config_path : String,
  output_dir : String?,
  host : String,
  port : Int,
  runner : @runtime.PreviewRunner,
) -> CliOutcome {
  let session = match
    prepare_serve_runtime_session(config_path, output_dir, host, port) {
    Ok(session) => session
    Err(message) => return { exit_code: 1, message }
  }
  let final_session = match runner {
    @runtime.PreviewRunner::DryRun => session
    @runtime.PreviewRunner::NativeMocket =>
      prepare_serve_session(
        session.preview_root,
        host=session.host,
        port=session.port,
        note="Native mocket preview runner is delegated to the native main entrypoint.",
      )
  }
  { exit_code: 0, message: format_runtime_ready_message(final_session) }
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
