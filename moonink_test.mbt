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
test "starter project plan normalizes relative project names" {
  let plan = @moonink.plan_starter_project(Some("./demo//site"))
  inspect(plan.project_name, content="demo/site")
  inspect(plan.root_dir, content="demo/site")
  inspect(plan.note.contains("UTF-8"), content="true")
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
  inspect(config.text_encoding, content="utf-8")
}

///|
test "load_config normalizes relative config paths" {
  let config = @moonink.load_config(
    config_path="fixtures//build_phase1a/./minimal/moonink.toml",
  ) catch {
    _ => panic()
  }
  inspect(config.config_path, content="fixtures/build_phase1a/minimal/moonink.toml")
  inspect(config.project_root, content="fixtures/build_phase1a/minimal")
}

///|
test "load_config rejects parent traversal paths" {
  inspect(
    try? @moonink.load_config(config_path="../moonink.toml"),
    content=(
      #|Err(InvalidPath(path="../moonink.toml", reason="ParentTraversal(\"../moonink.toml\")"))
    ),
  )
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
test "load_config reports normalized io errors" {
  inspect(
    try? @moonink.load_config(config_path="fixtures/build_phase1a/minimal/missing.toml"),
    content=(
      #|Err(IOError(Failure(operation="read_file", path="fixtures/build_phase1a/minimal/missing.toml", detail="IOError(\"Failed to read file fixtures/build_phase1a/minimal/missing.toml: No such file or directory (os error 2)\")")))
    ),
  )
}

///|
test "read config source task moves file reads to runtime boundary" {
  let outcome = @moonink.run_runtime_io_task(
    @moonink.read_config_source_task("fixtures/build_phase1a/minimal/moonink.toml"),
  )
  inspect(outcome is Ok(_), content="true")
}

///|
test "load_config task wraps config loading in runtime io task" {
  let outcome = @moonink.run_runtime_io_task(
    @moonink.load_config_task("fixtures/build_phase1a/minimal/moonink.toml"),
  )
  inspect(outcome is Ok(_), content="true")
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
test "discover_content uses normalized relative content roots" {
  let config = @moonink.load_config(
    config_path="fixtures/build_phase1a/minimal/moonink.toml",
  ) catch {
    _ => panic()
  }
  let normalized_config = { ..config, docs_dir: "./docs//guides", articles_dir: "articles/." }
  let inventory = @moonink.discover_content(normalized_config) catch {
    _ => panic()
  }
  inspect(inventory.docs_root, content="fixtures/build_phase1a/minimal/docs/guides")
  inspect(inventory.articles_root, content="fixtures/build_phase1a/minimal/articles")
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
test "discover_content task wraps discovery in runtime io task" {
  let config = @moonink.load_config(
    config_path="fixtures/build_phase1a/minimal/moonink.toml",
  ) catch {
    _ => panic()
  }
  let outcome = @moonink.run_runtime_io_task(@moonink.discover_content_task(config))
  inspect(outcome is Ok(_), content="true")
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
      #|encoding: utf-8
      #|status: ready for file emission
    ),
  )
  inspect(@moonink.cli_run(["moonink", "serve"]).exit_code, content="0")
  inspect(@moonink.cli_run(["moonink", "doctor"]).exit_code, content="1")
}

///|
test "emit starter project task keeps runtime interface shape" {
  let outcome = @moonink.run_runtime_io_task(
    @moonink.emit_starter_project_task(@moonink.plan_starter_project(Some("demo"))),
  )
  inspect(outcome.message.contains("[new]"), content="true")
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
test "runtime cli build formats normalized io errors" {
  let outcome = @moonink.cli_exec(["moonink", "build"])
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[build] failed during config loading"), content="true")
  inspect(outcome.message.contains("io error:"), content="true")
  inspect(outcome.message.contains("operation: read_file"), content="true")
  inspect(outcome.message.contains("path: moonink.toml"), content="true")
}
