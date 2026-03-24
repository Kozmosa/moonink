///|
test "parse cli command supports raw command tokens" {
  inspect(@moonink.parse_cli_command([]), content="Help")
  inspect(@moonink.parse_cli_command(["help"]), content="Help")
  inspect(@moonink.parse_cli_command(["build"]), content="Build")
  inspect(@moonink.parse_cli_command(["serve"]), content="Serve")
  inspect(@moonink.parse_cli_command(["new"]), content="New(None)")
  inspect(@moonink.parse_cli_command(["new", "demo"]), content="New(Some(\"demo\"))")
}

///|
test "parse cli command supports full argv forms" {
  inspect(@moonink.parse_cli_command(["moonink"]), content="Help")
  inspect(@moonink.parse_cli_command(["moonink", "build"]), content="Build")
  inspect(@moonink.parse_cli_command(["moonink", "serve"]), content="Serve")
  inspect(
    @moonink.parse_cli_command(["moonink", "new", "demo"]),
    content="New(Some(\"demo\"))",
  )
  inspect(
    @moonink.parse_cli_command(["moonink", "doctor"]),
    content="Unknown(\"doctor\")",
  )
}

///|
test "starter project plan models the phase 1 sample site layout" {
  let plan = @moonink.plan_starter_project(Some("demo"))
  inspect(plan.project_name, content="demo")
  inspect(plan.root_dir, content="demo")
  inspect(plan.created_files.length(), content="7")
  inspect(plan.content_roots, content="[\"docs\", \"articles\"]")
  inspect(plan.created_files[0].path, content="moonink.toml")
  inspect(plan.created_files[0].content.contains("name = \"demo\""), content="true")
  inspect(plan.created_files[1].content.contains("# demo"), content="true")
  inspect(plan.created_files[3].path, content="articles/hello-moonink.md")
  inspect(plan.theme_dir, content="theme")
}

///|
test "cli run remains a pure planning entry for new" {
  inspect(@moonink.cli_run(["moonink", "build"]).exit_code, content="0")
  inspect(
    @moonink.cli_run(["moonink", "new", "demo"]).message,
    content=(
      #|[new] starter template planned
      #|project: demo
      #|root: demo
      #|files: 7
      #|content roots: docs, articles
      #|theme dir: theme
      #|status: ready for file emission
    ),
  )
  inspect(@moonink.cli_run(["moonink", "serve"]).exit_code, content="0")
  inspect(@moonink.cli_run(["moonink", "doctor"]).exit_code, content="1")
}
