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
test "runtime cli build formats io errors when no config exists" {
  let outcome = @cli.cli_exec(["moonink", "build"])
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[build] failed during config loading"),
    content="true",
  )
}
