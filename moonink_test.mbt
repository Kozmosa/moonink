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
test "load_config reads the minimal build phase 1a fixture" {
  let config = @moonink.load_config(
    config_path="fixtures/build_phase1a/minimal/moonink.toml",
  ) catch {
    _ => panic()
  }
  inspect(config.site_name, content="Fixture Site")
  inspect(config.site_url, content="Some(\"https://example.com/docs\")")
  inspect(config.project_root, content="fixtures/build_phase1a/minimal")
  inspect(config.docs_dir, content="docs")
  inspect(config.articles_dir, content="articles")
  inspect(config.output_dir, content="site")
  inspect(config.theme_name, content="default")
}

///|
test "load_config reports missing required fields" {
  inspect(
    try? @moonink.load_config(
      config_path="fixtures/build_phase1a/missing_site_name/moonink.toml",
    ),
    content="Err(MissingField(section=\"site\", key=\"name\"))",
  )
}

///|
test "discover_content scans docs and articles recursively" {
  let config = @moonink.load_config(
    config_path="fixtures/build_phase1a/minimal/moonink.toml",
  ) catch {
    _ => panic()
  }
  let inventory = @moonink.discover_content(config) catch {
    _ => panic()
  }
  inspect(inventory.docs_root, content="fixtures/build_phase1a/minimal/docs")
  inspect(inventory.articles_root, content="fixtures/build_phase1a/minimal/articles")
  inspect(inventory.discovered_docs, content="2")
  inspect(inventory.discovered_articles, content="1")
  inspect(
    inventory.docs_files,
    content="[\"fixtures/build_phase1a/minimal/docs/index.md\", \"fixtures/build_phase1a/minimal/docs/guides/install.md\"]",
  )
  inspect(
    inventory.article_files,
    content="[\"fixtures/build_phase1a/minimal/articles/hello.md\"]",
  )
}

///|
test "discover_content reports missing content roots clearly" {
  let config = @moonink.load_config(
    config_path="fixtures/build_phase1a/missing_articles_dir/moonink.toml",
  ) catch {
    _ => panic()
  }
  inspect(
    try? @moonink.discover_content(config),
    content="Err(MissingDirectory(\"fixtures/build_phase1a/missing_articles_dir/articles\"))",
  )
}

///|
test "cli run remains a pure planning entry for new" {
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

///|
test "cli run keeps build behind runtime boundary" {
  inspect(
    @moonink.cli_run(["moonink", "build"]).message,
    content=(
      #|[build] runtime execution required
      #|status: use cli_exec or the runtime IO boundary to load config and discover content
    ),
  )
}

///|
test "runtime cli build crosses IO boundary and performs real IO" {
  let outcome = @moonink.cli_exec(["moonink", "build"])
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[build] failed during config loading"), content="true")
}
