///|
struct MainServePrebuiltOptions {
  root : String
  host : String
  port : Int
} derive(Debug, Eq)

///|
enum MainServeInternalRequest {
  NotRequested
  Invalid(String)
  ServePrebuilt(MainServePrebuiltOptions)
} derive(Debug, Eq)

///|
fn internal_flag_value(tokens : Array[String], index : Int) -> String? {
  if index + 1 < tokens.length() {
    Some(tokens[index + 1])
  } else {
    None
  }
}

///|
fn parse_internal_serve_prebuilt_request(
  tokens : Array[String],
) -> MainServeInternalRequest {
  if tokens.is_empty() || tokens[0] != "serve-prebuilt" {
    return MainServeInternalRequest::NotRequested
  }
  let mut root = ""
  let mut host = @cli.DEFAULT_SERVE_HOST
  let mut port = @cli.DEFAULT_SERVE_PORT
  let mut index = 1
  while index < tokens.length() {
    let token = tokens[index]
    if token == "--root" {
      let value = match internal_flag_value(tokens, index) {
        Some(value) => value
        None =>
          return MainServeInternalRequest::Invalid(
            "[serve] failed during preview startup\nreason: missing value for --root",
          )
      }
      root = value
      index += 2
    } else if token == "--host" {
      let value = match internal_flag_value(tokens, index) {
        Some(value) => value
        None =>
          return MainServeInternalRequest::Invalid(
            "[serve] failed during preview startup\nreason: missing value for --host",
          )
      }
      host = value
      index += 2
    } else if token == "--port" {
      let value = match internal_flag_value(tokens, index) {
        Some(value) => value
        None =>
          return MainServeInternalRequest::Invalid(
            "[serve] failed during preview startup\nreason: missing value for --port",
          )
      }
      let parsed = @string.parse_int(value) catch {
        _ =>
          return MainServeInternalRequest::Invalid(
            "[serve] failed during preview startup\nreason: invalid port \{value}",
          )
      }
      if parsed <= 0 || parsed > 65535 {
        return MainServeInternalRequest::Invalid(
          "[serve] failed during preview startup\nreason: invalid port \{value}",
        )
      }
      port = parsed
      index += 2
    } else {
      return MainServeInternalRequest::Invalid(
        "[serve] failed during preview startup\nreason: unknown internal flag \{token}",
      )
    }
  }
  if root.is_empty() {
    MainServeInternalRequest::Invalid(
      "[serve] failed during preview startup\nreason: missing required --root",
    )
  } else {
    MainServeInternalRequest::ServePrebuilt({ root, host, port })
  }
}

///|
fn launch_native_preview_server(session : @cli.ServeSession) -> Unit {
  println(
    @cli.format_runtime_ready_message(
      @cli.prepare_serve_session(
        session.preview_root,
        host=session.host,
        port=session.port,
        note="Native mocket preview server started in the main moonink binary.",
      ),
    ),
  )
  let app = @mocket.new()
  app.static_assets("/", @static_file.new(session.preview_root))
  app.serve(port=session.port)
}

///|
fn run_main_native_serve_prebuilt_command(
  options : MainServePrebuiltOptions,
) -> @cli.CliOutcome {
  let startup = match
    @cli.start_prepared_serve_session_result(
      @cli.prepare_serve_session(
        options.root,
        host=options.host,
        port=options.port,
      ),
      @runtime.native_mocket_preview_runner(),
    ) {
    Ok(session) => session
    Err(message) => return { exit_code: 1, message }
  }
  launch_native_preview_server(startup)
  { exit_code: 0, message: "" }
}

///|
fn run_main_native_serve_command(
  options : @cli.ServeCliOptions,
) -> @cli.CliOutcome {
  let prepared = match
    @cli.prepare_serve_runtime_session(
      options.config_path,
      options.output_dir,
      options.host,
      options.port,
    ) {
    Ok(prepared) => prepared
    Err(message) => return { exit_code: 1, message }
  }
  let startup = match
    @cli.start_prepared_serve_session_result(
      prepared.session,
      @runtime.native_mocket_preview_runner(),
    ) {
    Ok(session) => session
    Err(message) => return { exit_code: 1, message }
  }
  match prepared.build_stage {
    @cli.ServeBuildStage::Clean(_) => println("[serve] build completed")
    @cli.ServeBuildStage::WithWarnings(_, diagnostics) =>
      println(@cli.format_serve_build_warnings(diagnostics))
  }
  launch_native_preview_server(startup)
  { exit_code: 0, message: "" }
}

///|
fn run_main_native_entry(argv : Array[String]) -> @cli.CliOutcome {
  match parse_internal_serve_prebuilt_request(argv) {
    MainServeInternalRequest::ServePrebuilt(options) =>
      run_main_native_serve_prebuilt_command(options)
    MainServeInternalRequest::Invalid(message) => { exit_code: 1, message }
    MainServeInternalRequest::NotRequested =>
      match @cli.parse_cli_request(argv) {
        @cli.ParsedCliRequest::Serve(options) =>
          run_main_native_serve_command(options)
        _ => @cli.cli_exec(argv)
      }
  }
}
