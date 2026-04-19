///|
fn host_path(relative : String) -> String {
  match @runtime.resolve_host_path_from_cwd_result(relative) {
    Ok(path) => path
    Err(_) => panic()
  }
}

///|
fn prepare_native_preview_fixture_copy(name : String) -> String {
  let scratch_parent = host_path("fixtures/v2/_test_runs")
  let target_root = @runtime.join_host_path(scratch_parent, name) catch {
    _ => panic()
  }
  let _ = try? @runtime.io_remove_dir_all(target_root)
  @runtime.io_ensure_dir(scratch_parent) catch {
    _ => panic()
  }
  @runtime.io_copy_dir_recursive(host_path("fixtures/v2/minimal"), target_root) catch {
    _ => panic()
  }
  target_root
}

///|
fn build_native_preview_fixture(name : String) -> String {
  let fixture_root = prepare_native_preview_fixture_copy(name)
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  if outcome.exit_code != 0 {
    panic()
  }
  fixture_root
}

///|
test "parse internal serve prebuilt request keeps root host and port" {
  let request = parse_internal_serve_prebuilt_request([
    "serve-prebuilt", "--root", "/tmp/moonink-preview", "--host", "0.0.0.0", "--port",
    "4173",
  ])
  match request {
    MainServeInternalRequest::ServePrebuilt(options) => {
      inspect(options.root, content="/tmp/moonink-preview")
      inspect(options.host, content="0.0.0.0")
      inspect(options.port.to_string(), content="4173")
    }
    _ => panic()
  }
}

///|
test "main native prebuilt preview session validates built output" {
  let fixture_root = build_native_preview_fixture(
    "cmd-main-native-prebuilt-preview",
  )
  let startup = @cli.start_prepared_serve_session_result(
    @cli.prepare_serve_session(
      fixture_root + "/dist",
      host="127.0.0.1",
      port=43123,
    ),
    @runtime.native_mocket_preview_runner(),
  )
  match startup {
    Ok(session) => {
      inspect(session.preview_root, content=fixture_root + "/dist")
      inspect(
        session.note.contains("in-process main-binary serving"),
        content="true",
      )
    }
    Err(message) => {
      inspect(message, content="")
      panic()
    }
  }
}

///|
test "main native prebuilt preview session rejects invalid port" {
  let fixture_root = build_native_preview_fixture(
    "cmd-main-native-prebuilt-invalid-port",
  )
  let startup = @cli.start_prepared_serve_session_result(
    @cli.prepare_serve_session(fixture_root + "/dist", host="127.0.0.1", port=0),
    @runtime.native_mocket_preview_runner(),
  )
  match startup {
    Err(message) => {
      inspect(
        message.contains("[serve] failed during preview startup"),
        content="true",
      )
      inspect(
        message.contains("preview port must be between 1 and 65535"),
        content="true",
      )
    }
    Ok(_) => panic()
  }
}

///|
test "main native entry preserves failing build exit codes" {
  let outcome = run_main_native_entry([
    "build", "--config", "fixtures/v2/missing_config/moonink.json",
  ])
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[build] failed during config loading"),
    content="true",
  )
}

///|
test "main native entry preserves failing serve exit codes" {
  let outcome = run_main_native_entry([
    "serve", "--config", "fixtures/v2/missing_config/moonink.json",
  ])
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[serve] build failed before preview startup"),
    content="true",
  )
}
