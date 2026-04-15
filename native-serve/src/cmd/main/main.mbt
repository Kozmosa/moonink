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
