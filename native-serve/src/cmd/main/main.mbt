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
fn serve_config_path(argv : Array[String]) -> String {
  if argv.length() >= 2 && argv[0] == "serve" {
    argv[1]
  } else {
    "moonink.json"
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
fn main {
  let argv = normalize_runtime_argv(@env.args())
  let command = @cli.parse_cli_command(argv)
  match command {
    @cli.CliCommand::Serve =>
      match @cli.prepare_serve_runtime_session(serve_config_path(argv)) {
        Ok(session) => launch_native_preview(session)
        Err(message) => println(message)
      }
    _ => {
      let outcome = @cli.cli_exec(argv)
      println(outcome.message)
    }
  }
}
