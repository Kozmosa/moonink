///|
fn normalize_runtime_argv(raw_argv : Array[String]) -> Array[String] {
  if raw_argv.length() >= 3 && raw_argv[1].has_suffix(".js") {
    raw_argv[2:].to_array()
  } else if raw_argv.length() > 1 {
    raw_argv[1:].to_array()
  } else {
    []
  }
}

///|
pub(all) struct ServePrebuiltOptions {
  root : String
  host : String
  port : Int
} derive(Debug, Eq)

///|
enum ServePrebuiltRequest {
  NotRequested
  Invalid
  Run(ServePrebuiltOptions)
} derive(Debug, Eq)

///|
fn next_flag_value(
  flag_name : String,
  tokens : Array[String],
  index : Int,
) -> String? {
  if index + 1 < tokens.length() {
    Some(tokens[index + 1])
  } else {
    println(
      "[serve] failed during preview startup\nreason: missing value for \{flag_name}",
    )
    None
  }
}

///|
fn parse_serve_prebuilt_options(
  tokens : Array[String],
) -> ServePrebuiltRequest {
  if tokens.is_empty() || tokens[0] != "serve-prebuilt" {
    return ServePrebuiltRequest::NotRequested
  }
  let mut root = ""
  let mut host = @cli.DEFAULT_SERVE_HOST
  let mut port = @cli.DEFAULT_SERVE_PORT
  let mut index = 1
  while index < tokens.length() {
    let token = tokens[index]
    if token == "--root" {
      let value = match next_flag_value("--root", tokens, index) {
        Some(value) => value
        None => return ServePrebuiltRequest::Invalid
      }
      root = value
      index += 2
    } else if token == "--host" {
      let value = match next_flag_value("--host", tokens, index) {
        Some(value) => value
        None => return ServePrebuiltRequest::Invalid
      }
      host = value
      index += 2
    } else if token == "--port" {
      let value = match next_flag_value("--port", tokens, index) {
        Some(value) => value
        None => return ServePrebuiltRequest::Invalid
      }
      let parsed = try @string.parse_int(value) catch {
        _ => {
          println(
            "[serve] failed during preview startup\nreason: invalid port \{value}",
          )
          return ServePrebuiltRequest::Invalid
        }
      }
      if parsed <= 0 || parsed > 65535 {
        println(
          "[serve] failed during preview startup\nreason: invalid port \{value}",
        )
        return ServePrebuiltRequest::Invalid
      }
      port = parsed
      index += 2
    } else {
      println(
        "[serve] failed during preview startup\nreason: unknown internal flag \{token}",
      )
      return ServePrebuiltRequest::Invalid
    }
  }
  if root.is_empty() {
    println(
      "[serve] failed during preview startup\nreason: missing required --root",
    )
    ServePrebuiltRequest::Invalid
  } else {
    ServePrebuiltRequest::Run({ root, host, port })
  }
}

///|
fn launch_native_preview(session : @cli.ServeSession) -> Unit {
  println(
    @cli.format_runtime_ready_message(
      @cli.prepare_serve_session(
        session.preview_root,
        host=session.host,
        port=session.port,
        note="Native mocket preview server started.",
      ),
    ),
  )
  let app = @mocket.new()
  app.static_assets("/", @static_file.new(session.preview_root))
  app.serve(port=session.port)
}

///|
fn run_prebuilt_preview(options : ServePrebuiltOptions) -> Unit {
  let startup = @cli.start_prepared_serve_session_result(
    @cli.prepare_serve_session(
      options.root,
      host=options.host,
      port=options.port,
    ),
    @runtime.dry_run_preview_runner(),
  )
  match startup {
    Ok(session) => launch_native_preview(session)
    Err(message) => println(message)
  }
}

///|
fn main {
  let argv = normalize_runtime_argv(@env.args())
  match parse_serve_prebuilt_options(argv) {
    ServePrebuiltRequest::Run(options) => {
      run_prebuilt_preview(options)
      return
    }
    ServePrebuiltRequest::Invalid => return
    ServePrebuiltRequest::NotRequested => ()
  }
  let request = @cli.parse_cli_request(argv)
  match request {
    @cli.ParsedCliRequest::Serve(options) =>
      match @cli.prepare_serve_runtime_session(
        options.config_path,
        options.output_dir,
        options.host,
        options.port,
      ) {
        Ok(prepared) => {
          let startup = match @cli.start_prepared_serve_session_result(
            prepared.session,
            @runtime.native_mocket_preview_runner(),
          ) {
            Ok(session) => session
            Err(message) => {
              println(message)
              return
            }
          }
          match prepared.build_stage {
            @cli.ServeBuildStage::Clean(_) => println("[serve] build completed")
            @cli.ServeBuildStage::WithWarnings(_, diagnostics) =>
              println(@cli.format_serve_build_warnings(diagnostics))
          }
          launch_native_preview(startup)
        }
        Err(message) => println(message)
      }
    _ => {
      let outcome = @cli.cli_exec(argv)
      println(outcome.message)
    }
  }
}
