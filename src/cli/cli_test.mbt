///|
test "parse cli command supports raw command tokens" {
  inspect(@cli.parse_cli_command([]), content="Help")
  inspect(@cli.parse_cli_command(["help"]), content="Help")
  inspect(@cli.parse_cli_command(["build"]), content="Build")
  inspect(@cli.parse_cli_command(["serve"]), content="Serve")
  inspect(@cli.parse_cli_command(["onboard"]), content="Onboard")
}

///|
test "parse cli command supports full argv forms" {
  inspect(@cli.parse_cli_command(["moonink"]), content="Help")
  inspect(@cli.parse_cli_command(["moonink", "build"]), content="Build")
  inspect(@cli.parse_cli_command(["moonink", "serve"]), content="Serve")
  inspect(@cli.parse_cli_command(["moonink", "onboard"]), content="Onboard")
  inspect(
    @cli.parse_cli_command(["moonink", "doctor"]),
    content="Unknown(\"doctor\")",
  )
}

///|
test "cli run keeps build behind runtime boundary" {
  inspect(
    @cli.cli_run(["moonink", "build"]).message,
    content=(
      #|[build] runtime execution required
      #|status: use cli_exec or the runtime IO boundary to load config and discover content
    ),
  )
}

///|
test "cli run returns serve placeholder" {
  inspect(@cli.cli_run(["moonink", "serve"]).exit_code, content="0")
}

///|
test "cli run returns error for unknown command" {
  inspect(@cli.cli_run(["moonink", "doctor"]).exit_code, content="1")
}

///|
test "runtime cli build writes minimal fixture html files" {
  let fixture_root = "fixtures/v2/minimal"
  let stale_path = fixture_root + "/dist/stale.txt"
  let _ = try? @runtime.io_create_dir(fixture_root + "/dist")
  @runtime.io_write_string(stale_path, "stale") catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/hello/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/about/index.html"),
    content="true",
  )
  inspect(@runtime.io_path_exists(stale_path), content="false")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello/index.html",
  ) catch {
    _ => panic()
  }
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("<!doctype html>"), content="true")
  inspect(index_html.contains("<title>Home</title>"), content="true")
  inspect(index_html.contains("Fixture Site"), content="true")
  inspect(index_html.contains("data-kind=\"page\""), content="true")
  inspect(index_html.contains("data-url=\"/\""), content="true")
  inspect(hello_html.contains("Hello World"), content="true")
  inspect(hello_html.contains("<title>Hello</title>"), content="true")
  inspect(hello_html.contains("data-kind=\"article\""), content="true")
  inspect(about_html.contains("This is a static HTML page."), content="true")
  inspect(about_html.contains("<title>about.html</title>"), content="true")
}

///|
test "runtime cli build formats io errors when no config exists" {
  let outcome = @cli.cli_exec(["moonink", "build"])
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[build] failed during config loading"),
    content="true",
  )
}

///|
test "runtime cli build respects direct route layout" {
  let fixture_root = "fixtures/v2/direct_route"
  let stale_path = fixture_root + "/dist/stale.txt"
  let _ = try? @runtime.io_create_dir(fixture_root + "/dist")
  @runtime.io_write_string(stale_path, "stale") catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/hello.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/about.html"),
    content="true",
  )
  inspect(@runtime.io_path_exists(stale_path), content="false")
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello.html",
  ) catch {
    _ => panic()
  }
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about.html",
  ) catch {
    _ => panic()
  }
  inspect(hello_html.contains("Hello World"), content="true")
  inspect(about_html.contains("This is a static HTML page."), content="true")
}

///|
test "runtime cli build resolves wikilinks for pretty routes" {
  let fixture_root = "fixtures/v2/wikilinks_pretty"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello/index.html",
  ) catch {
    _ => panic()
  }
  inspect(hello_html.contains("href=\"/about/\""), content="true")
  inspect(hello_html.contains(">about<"), content="true")
  inspect(hello_html.contains("href=\"/\""), content="true")
  inspect(hello_html.contains(">Home<"), content="true")
}

///|
test "runtime cli build resolves wikilinks for direct routes" {
  let fixture_root = "fixtures/v2/wikilinks_direct"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello.html",
  ) catch {
    _ => panic()
  }
  inspect(hello_html.contains("href=\"/about.html\""), content="true")
  inspect(hello_html.contains(">about<"), content="true")
  inspect(hello_html.contains("href=\"/index.html\""), content="true")
  inspect(hello_html.contains(">Home<"), content="true")
}
