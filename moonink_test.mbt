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
test "load_config reads the minimal build phase 1a fixture" {
  let config = match @moonink.load_config_result("fixtures/build_phase1a/minimal/moonink.toml") {
    Ok(config) => config
    Err(_) => panic()
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
  let config = match @moonink.load_config_result("fixtures//build_phase1a/./minimal/moonink.toml") {
    Ok(config) => config
    Err(_) => panic()
  }
  inspect(config.config_path, content="fixtures/build_phase1a/minimal/moonink.toml")
  inspect(config.project_root, content="fixtures/build_phase1a/minimal")
}

///|
test "load_config rejects parent traversal paths" {
  inspect(
    @moonink.load_config_result("../moonink.toml"),
    content=(
      #|Err(InvalidPath(path="../moonink.toml", reason="ParentTraversal(\"../moonink.toml\")"))
    ),
  )
}

///|
test "load_config reports missing required fields" {
  inspect(
    @moonink.load_config_result("fixtures/build_phase1a/missing_site_name/moonink.toml"),
    content="Err(MissingField(section=\"site\", key=\"name\"))",
  )
}

///|
test "load_config reports normalized io errors" {
  inspect(
    @moonink.load_config_result("fixtures/build_phase1a/minimal/missing.toml"),
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
test "read config source task reports missing file contract" {
  inspect(
    @moonink.run_runtime_io_task(
      @moonink.read_config_source_task("fixtures/build_phase1a/minimal/missing.toml"),
    ),
    content=(
      #|Err(IOError(Failure(operation="read_file", path="fixtures/build_phase1a/minimal/missing.toml", detail="IOError(\"Failed to read file fixtures/build_phase1a/minimal/missing.toml: No such file or directory (os error 2)\")")))
    ),
  )
}

///|
test "load_config task wraps config loading in runtime io task" {
  let outcome = @moonink.run_runtime_io_task(
    @moonink.load_config_task("fixtures/build_phase1a/minimal/moonink.toml"),
  )
  inspect(outcome is Ok(_), content="true")
}

///|
test "load_config task propagates parse contract errors" {
  inspect(
    @moonink.run_runtime_io_task(
      @moonink.load_config_task("fixtures/build_phase1a/missing_site_name/moonink.toml"),
    ),
    content="Err(MissingField(section=\"site\", key=\"name\"))",
  )
}

///|
test "emit starter project task preserves overwrite contract" {
  ignore(
    @moonink.run_runtime_io_task(
      @moonink.emit_starter_project_task(@moonink.plan_starter_project(Some("demo"))),
    ),
  )
  let outcome = @moonink.run_runtime_io_task(
    @moonink.emit_starter_project_task(@moonink.plan_starter_project(Some("demo"))),
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("target directory already exists"), content="true")
}

///|
test "discover_content uses normalized relative content roots" {
  let config = match @moonink.load_config_result("fixtures/build_phase1a/minimal/moonink.toml") {
    Ok(config) => config
    Err(_) => panic()
  }
  let normalized_config = { ..config, docs_dir: "./docs//guides", articles_dir: "articles/." }
  let inventory = match @moonink.discover_content_result(normalized_config) {
    Ok(inventory) => inventory
    Err(_) => panic()
  }
  inspect(inventory.docs_root, content="fixtures/build_phase1a/minimal/docs/guides")
  inspect(inventory.articles_root, content="fixtures/build_phase1a/minimal/articles")
}

///|
test "discover_content reports missing content roots clearly" {
  let config = match @moonink.load_config_result("fixtures/build_phase1a/missing_articles_dir/moonink.toml") {
    Ok(config) => config
    Err(_) => panic()
  }
  inspect(
    @moonink.discover_content_result(config),
    content="Err(MissingDirectory(\"fixtures/build_phase1a/missing_articles_dir/articles\"))",
  )
}

///|
test "native runtime adapter executes runtime io tasks" {
  let write_plan = @moonink.run_native_runtime_io_task(
    @moonink.plan_starter_write_task(@moonink.plan_starter_project(Some("demo"))),
  )
  inspect(write_plan.overwrite_policy, content="abort_if_target_exists")
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
      #|overwrite policy: abort_if_target_exists
      #|status: ready for file emission
    ),
  )
  inspect(@moonink.cli_run(["moonink", "serve"]).exit_code, content="0")
  inspect(@moonink.cli_run(["moonink", "doctor"]).exit_code, content="1")
}

///|
test "starter write plan exposes overwrite protection" {
  let write_plan = @moonink.run_runtime_io_task(
    @moonink.plan_starter_write_task(@moonink.plan_starter_project(Some("demo"))),
  )
  inspect(write_plan.file_count, content="7")
  inspect(write_plan.overwrite_policy, content="abort_if_target_exists")
}

///|
test "emit starter project task keeps runtime interface shape" {
  let outcome = @moonink.run_runtime_io_task(
    @moonink.emit_starter_project_task(@moonink.plan_starter_project(Some("demo"))),
  )
  inspect(outcome.message.contains("[new]"), content="true")
}

///|
test "native runtime adapter exposes explicit runtime identity" {
  let adapter = @moonink.native_runtime_adapter()
  inspect(adapter.name, content="native-runtime-adapter")
  inspect(adapter.note.contains("Native runtime wiring"), content="true")
  inspect(adapter.policy.conflict_policy, content="AbortOnConflict")
}

///|
test "native runtime adapter preserves config read contract" {
  inspect(
    @moonink.run_native_runtime_io_task(
      @moonink.read_config_source_task("fixtures/build_phase1a/minimal/missing.toml"),
    ),
    content=(
      #|Err(IOError(Failure(operation="read_file", path="fixtures/build_phase1a/minimal/missing.toml", detail="IOError(\"Failed to read file fixtures/build_phase1a/minimal/missing.toml: No such file or directory (os error 2)\")")))
    ),
  )
}

///|
test "native runtime adapter policy hook preserves task result" {
  let write_plan = @moonink.run_native_runtime_io_task_with_policy(
    @moonink.plan_starter_write_task(@moonink.plan_starter_project(Some("demo"))),
    @moonink.default_runtime_task_policy(),
  )
  inspect(write_plan.overwrite_policy, content="abort_if_target_exists")
}

///|
test "native runtime adapter preserves discovery contract" {
  let config = match @moonink.load_config_result("fixtures/build_phase1a/missing_articles_dir/moonink.toml") {
    Ok(config) => config
    Err(_) => panic()
  }
  inspect(
    @moonink.run_native_runtime_io_task(@moonink.discover_content_task(config)),
    content="Err(MissingDirectory(\"fixtures/build_phase1a/missing_articles_dir/articles\"))",
  )
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


///|
test "docflow parser domain types support construction" {
  let input : @moonink.SourceDocumentInput = {
    path: "docs/getting-started.md",
    format: @moonink.SourceFormat::Markdown,
    content: "# Hello MoonInk",
    uuid: "doc-001",
  }
  let diagnostics : @moonink.DocumentDiagnostics = {
    entries: [
      {
        severity: @moonink.DiagnosticSeverity::Warn,
        line: Some(1),
        message: "Undefined Typst symbol.",
        hint: Some("Check output of typst."),
        backend_name: "typst-stub",
      },
    ],
  }
  let parsed : @moonink.ParsedDocument = {
    backend_name: "markdown-backend",
    source_format: input.format,
    source_path: input.path,
    source_uuid: input.uuid,
    diagnostics,
    backend_payload: Some("native-markdown-payload"),
  }
  inspect(input.format, content="Markdown")
  inspect(parsed.backend_name, content="markdown-backend")
  inspect(parsed.source_path, content="docs/getting-started.md")
  inspect(parsed.source_uuid, content="doc-001")
  inspect(parsed.backend_payload, content="Some(\"native-markdown-payload\")")
}

///|
test "docflow diagnostic formatting supports line and hint details" {
  let diagnostic : @moonink.DocumentDiagnostic = {
    severity: @moonink.DiagnosticSeverity::Warn,
    line: Some(1),
    message: "Undefined Typst symbol.",
    hint: Some("Check output of typst."),
    backend_name: "typst-stub",
  }
  inspect(
    @moonink.format_document_diagnostic(diagnostic),
    content="(WARN) Line 1, Undefined Typst symbol. Check output of typst.",
  )
}

///|
test "docflow diagnostic formatting handles missing location and capability defaults" {
  let info_diagnostic : @moonink.DocumentDiagnostic = {
    severity: @moonink.DiagnosticSeverity::Info,
    line: None,
    message: "HTML passthrough engaged.",
    hint: None,
    backend_name: "html-passthrough",
  }
  let error_diagnostic : @moonink.DocumentDiagnostic = {
    severity: @moonink.DiagnosticSeverity::Error,
    line: Some(3),
    message: "Parser backend missing.",
    hint: None,
    backend_name: "registry",
  }
  let diagnostics : @moonink.DocumentDiagnostics = {
    entries: [info_diagnostic, error_diagnostic],
  }
  let default_capabilities = @moonink.default_parser_capabilities()
  inspect(@moonink.format_document_diagnostic(info_diagnostic), content="(INFO) HTML passthrough engaged.")
  inspect(
    @moonink.format_document_diagnostics(diagnostics),
    content=(
      #|(INFO) HTML passthrough engaged.
      #|(ERROR) Line 3, Parser backend missing.
    ),
  )
  inspect(default_capabilities.supports_incremental_parsing, content="false")
  inspect(default_capabilities.supports_html_passthrough, content="false")
  inspect(@moonink.empty_document_diagnostics().entries.length(), content="0")
  inspect(@moonink.SourceDocumentInput::{ path: "page.html", format: @moonink.SourceFormat::Html, content: "<p>x</p>", uuid: "page-001" }.format, content="Html")
  inspect(@moonink.SourceDocumentInput::{ path: "draft.typ", format: @moonink.SourceFormat::Typst, content: "= Hello", uuid: "typ-001" }.format, content="Typst")
  inspect(@moonink.SourceDocumentInput::{ path: "misc.bin", format: @moonink.SourceFormat::Unknown, content: "", uuid: "unknown-001" }.format, content="Unknown")
}


///|
test "docflow parser adapter contract preserves identity and source metadata" {
  let capabilities : @moonink.ParserCapabilities = {
    supports_incremental_parsing: true,
    supports_html_passthrough: false,
  }
  let adapter = @moonink.fake_parser_adapter(
    "fake-markdown-parser",
    capabilities=capabilities,
    note="Fake parser adapter for contract coverage.",
  )
  let input : @moonink.SourceDocumentInput = {
    path: "articles/hello.md",
    format: @moonink.SourceFormat::Markdown,
    content: "# Hello",
    uuid: "article-001",
  }
  let parsed = @moonink.parse_with_adapter(adapter, input)
  inspect(adapter.name, content="fake-markdown-parser")
  inspect(adapter.capabilities.supports_incremental_parsing, content="true")
  inspect(parsed.backend_name, content="fake-markdown-parser")
  inspect(parsed.source_format, content="Markdown")
  inspect(parsed.source_path, content="articles/hello.md")
  inspect(parsed.source_uuid, content="article-001")
  inspect(parsed.diagnostics.entries.length(), content="0")
  inspect(parsed.backend_payload, content="Some(\"fake-parse:articles/hello.md\")")
}

///|
test "docflow wikilinker contract remains explicit no-op" {
  let parsed : @moonink.ParsedDocument = {
    backend_name: "fake-markdown-parser",
    source_format: @moonink.SourceFormat::Markdown,
    source_path: "articles/hello.md",
    source_uuid: "article-001",
    diagnostics: @moonink.empty_document_diagnostics(),
    backend_payload: Some("fake-parse:articles/hello.md"),
  }
  let linker = @moonink.noop_wikilinker(
    name="semantic-noop",
    note="No-op semantic stage for contract coverage.",
  )
  let linked = @moonink.apply_wikilinker(linker, parsed)
  inspect(linker.name, content="semantic-noop")
  inspect(linked, content="{backend_name: \"fake-markdown-parser\", source_format: Markdown, source_path: \"articles/hello.md\", source_uuid: \"article-001\", diagnostics: {entries: []}, backend_payload: Some(\"fake-parse:articles/hello.md\")}")
}

///|
test "docflow render adapter contract produces html from parsed document" {
  let parsed : @moonink.ParsedDocument = {
    backend_name: "fake-markdown-parser",
    source_format: @moonink.SourceFormat::Markdown,
    source_path: "articles/hello.md",
    source_uuid: "article-001",
    diagnostics: @moonink.empty_document_diagnostics(),
    backend_payload: Some("<h1>Hello</h1>"),
  }
  let renderer = @moonink.fake_render_adapter(
    "fake-html-renderer",
    note="Fake render adapter for contract coverage.",
  )
  let rendered = @moonink.render_with_adapter(renderer, parsed)
  inspect(renderer.name, content="fake-html-renderer")
  inspect(rendered.backend_name, content="fake-html-renderer")
  inspect(rendered.source_path, content="articles/hello.md")
  inspect(rendered.source_uuid, content="article-001")
  inspect(
    rendered.html,
    content="<article data-renderer=\"fake-html-renderer\" data-source-format=\"Markdown\"><h1>Hello</h1></article>",
  )
  inspect(rendered.note, content="Fake render adapter for contract coverage.")
}
