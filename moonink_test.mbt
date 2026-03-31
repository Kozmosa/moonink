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


///|
test "docflow parser registry resolves adapters by source format" {
  let parser = @moonink.fake_parser_adapter(
    "fake-markdown-parser",
    capabilities={ supports_incremental_parsing: true, supports_html_passthrough: false },
  )
  let registry = @moonink.register_parser_adapter(
    @moonink.empty_parser_registry(),
    @moonink.SourceFormat::Markdown,
    parser,
  )
  inspect(
    @moonink.lookup_parser_adapter(registry, @moonink.SourceFormat::Markdown),
    content="Ok({name: \"fake-markdown-parser\", capabilities: {supports_incremental_parsing: true, supports_html_passthrough: false}, note: \"Fake parser adapter for contract tests.\"})",
  )
}

///|
test "docflow render registry resolves adapters by source format" {
  let renderer = @moonink.fake_render_adapter(
    "fake-html-renderer",
    note="Fake render adapter for registry coverage.",
  )
  let registry = @moonink.register_render_adapter(
    @moonink.empty_render_registry(),
    @moonink.SourceFormat::Markdown,
    renderer,
  )
  inspect(
    @moonink.lookup_render_adapter(registry, @moonink.SourceFormat::Markdown),
    content="Ok({name: \"fake-html-renderer\", note: \"Fake render adapter for registry coverage.\"})",
  )
}

///|
test "docflow registry reports missing parser and render registrations" {
  inspect(
    @moonink.lookup_parser_adapter(@moonink.empty_parser_registry(), @moonink.SourceFormat::Typst),
    content="Err(MissingParserAdapter(Typst))",
  )
  inspect(
    @moonink.lookup_render_adapter(@moonink.empty_render_registry(), @moonink.SourceFormat::Html),
    content="Err(MissingRenderAdapter(Html))",
  )
}


///|
test "docflow typst stub adapter returns warning diagnostics" {
  let adapter = @moonink.unsupported_typst_parser_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/draft.typ",
    format: @moonink.SourceFormat::Typst,
    content: "= Draft",
    uuid: "typst-001",
  }
  let parsed = @moonink.parse_with_adapter(adapter, input)
  inspect(adapter.name, content="unsupported-typst-parser")
  inspect(adapter.capabilities.supports_html_passthrough, content="false")
  inspect(parsed.backend_payload, content="None")
  inspect(parsed.diagnostics.entries.length(), content="1")
  inspect(
    @moonink.format_document_diagnostics(parsed.diagnostics),
    content="(WARN) Line 1, Typst parsing is not implemented yet. Use the stub diagnostic until the real Typst backend lands.",
  )
}

///|
test "docflow html passthrough adapter preserves html input" {
  let adapter = @moonink.html_passthrough_parser_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "pages/index.html",
    format: @moonink.SourceFormat::Html,
    content: "<main><h1>Home</h1></main>",
    uuid: "page-001",
  }
  let parsed = @moonink.parse_with_adapter(adapter, input)
  inspect(adapter.name, content="html-passthrough-parser")
  inspect(adapter.capabilities.supports_html_passthrough, content="true")
  inspect(parsed.diagnostics.entries.length(), content="0")
  inspect(parsed.backend_payload, content="Some(\"<main><h1>Home</h1></main>\")")
}

///|
test "docflow parser registry supports typst stub and html passthrough paths" {
  let registry0 = @moonink.empty_parser_registry()
  let registry1 = @moonink.register_parser_adapter(
    registry0,
    @moonink.SourceFormat::Typst,
    @moonink.unsupported_typst_parser_adapter(),
  )
  let registry = @moonink.register_parser_adapter(
    registry1,
    @moonink.SourceFormat::Html,
    @moonink.html_passthrough_parser_adapter(),
  )
  inspect(
    @moonink.lookup_parser_adapter(registry, @moonink.SourceFormat::Typst),
    content="Ok({name: \"unsupported-typst-parser\", capabilities: {supports_incremental_parsing: false, supports_html_passthrough: false}, note: \"Typst parsing is not implemented yet; this adapter returns a structured warning diagnostic.\"})",
  )
  inspect(
    @moonink.lookup_parser_adapter(registry, @moonink.SourceFormat::Html),
    content="Ok({name: \"html-passthrough-parser\", capabilities: {supports_incremental_parsing: false, supports_html_passthrough: true}, note: \"HTML page input bypasses markup parsing while staying inside the parser adapter boundary.\"})",
  )
}


///|
test "docflow fatal boundary preserves recoverable typst diagnostics" {
  let adapter = @moonink.unsupported_typst_parser_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/draft.typ",
    format: @moonink.SourceFormat::Typst,
    content: "= Draft",
    uuid: "typst-002",
  }
  let result = @moonink.parse_with_adapter_result(adapter, input)
  inspect(result is Ok(_), content="true")
  let parsed = match result {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  inspect(parsed.backend_name, content="unsupported-typst-parser")
  inspect(parsed.backend_payload, content="None")
  inspect(parsed.diagnostics.entries.length(), content="1")
}

///|
test "docflow fatal boundary reports backend failure for broken adapter" {
  let adapter = @moonink.broken_parser_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/hello.md",
    format: @moonink.SourceFormat::Markdown,
    content: "# Hello",
    uuid: "article-002",
  }
  inspect(
    @moonink.parse_with_adapter_result(adapter, input),
    content="Err(BackendFailure(adapter_name=\"broken-parser-adapter\", detail=\"intentional fatal parse failure\"))",
  )
}

///|
test "docflow fatal boundary reports format mismatch for html passthrough adapter" {
  let adapter = @moonink.html_passthrough_parser_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/hello.md",
    format: @moonink.SourceFormat::Markdown,
    content: "# Hello",
    uuid: "article-003",
  }
  inspect(
    @moonink.parse_with_adapter_result(adapter, input),
    content="Err(UnsupportedFormat(adapter_name=\"html-passthrough-parser\", expected=Html, actual=Markdown))",
  )
}

///|
test "docflow fatal boundary reports invalid adapter state when name is empty" {
  let adapter = @moonink.fake_parser_adapter("", note="Invalid parser adapter for fatal-boundary coverage.")
  let input : @moonink.SourceDocumentInput = {
    path: "articles/hello.md",
    format: @moonink.SourceFormat::Markdown,
    content: "# Hello",
    uuid: "article-004",
  }
  inspect(
    @moonink.parse_with_adapter_result(adapter, input),
    content="Err(InvalidAdapterState(adapter_name=\"\", reason=\"adapter name must not be empty\"))",
  )
}


///|
test "docflow markdown parser adapter parses empty input" {
  let adapter = @moonink.markdown_parser_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/empty.md",
    format: @moonink.SourceFormat::Markdown,
    content: "",
    uuid: "markdown-001",
  }
  let parsed = match @moonink.parse_with_adapter_result(adapter, input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let contract = @moonink.parse_markdown_backend_contract("")
  inspect(parsed.backend_name, content="markdown-parser-adapter")
  inspect(parsed.diagnostics.entries.length(), content="0")
  inspect(parsed.backend_payload, content="Some(\"\")")
  inspect(contract.block_count, content="0")
  inspect(contract.definition_count, content="0")
  inspect(contract.html_output, content="")
}

///|
test "docflow markdown parser adapter parses paragraph and heading" {
  let adapter = @moonink.markdown_parser_adapter()
  let heading_input : @moonink.SourceDocumentInput = {
    path: "articles/heading.md",
    format: @moonink.SourceFormat::Markdown,
    content: "# Hello MoonInk",
    uuid: "markdown-002",
  }
  let heading = match @moonink.parse_with_adapter_result(adapter, heading_input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let heading_contract = @moonink.parse_markdown_backend_contract("# Hello MoonInk")
  inspect(heading.backend_payload, content="Some(\"# Hello MoonInk\\n\")")
  inspect(heading_contract.block_count, content="1")
  inspect(heading_contract.html_output, content="<h1>Hello MoonInk</h1>\n")
  let paragraph_input : @moonink.SourceDocumentInput = {
    path: "articles/paragraph.md",
    format: @moonink.SourceFormat::Markdown,
    content: "Hello paragraph",
    uuid: "markdown-003",
  }
  let paragraph = match @moonink.parse_with_adapter_result(adapter, paragraph_input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let paragraph_contract = @moonink.parse_markdown_backend_contract("Hello paragraph")
  inspect(paragraph.backend_payload, content="Some(\"Hello paragraph\\n\")")
  inspect(paragraph_contract.block_count, content="1")
  inspect(paragraph_contract.html_output, content="<p>Hello paragraph</p>\n")
}

///|
test "docflow markdown parser adapter parses list and link" {
  let adapter = @moonink.markdown_parser_adapter()
  let list_input : @moonink.SourceDocumentInput = {
    path: "articles/list.md",
    format: @moonink.SourceFormat::Markdown,
    content: "- one\n- two",
    uuid: "markdown-004",
  }
  let list_parsed = match @moonink.parse_with_adapter_result(adapter, list_input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let list_contract = @moonink.parse_markdown_backend_contract("- one\n- two")
  inspect(list_parsed.backend_payload, content="Some(\"* one\\n* two\\n\")")
  inspect(list_contract.block_count, content="1")
  inspect(
    list_contract.html_output,
    content=(
      #|<ul>
      #|<li>one</li>
      #|<li>two</li>
      #|</ul>
      #|
    ),
  )
  let link_input : @moonink.SourceDocumentInput = {
    path: "articles/link.md",
    format: @moonink.SourceFormat::Markdown,
    content: "[MoonBit](https://www.moonbitlang.com)",
    uuid: "markdown-005",
  }
  let link_parsed = match @moonink.parse_with_adapter_result(adapter, link_input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let link_contract = @moonink.parse_markdown_backend_contract("[MoonBit](https://www.moonbitlang.com)")
  inspect(link_parsed.backend_payload, content="Some(\"[MoonBit](https://www.moonbitlang.com)\\n\")")
  inspect(link_contract.block_count, content="1")
  inspect(link_contract.html_output, content="<p><a href=\"https://www.moonbitlang.com\">MoonBit</a></p>\n")
}

///|
test "docflow markdown parser adapter parses inline html and reports capabilities" {
  let adapter = @moonink.markdown_parser_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/html.md",
    format: @moonink.SourceFormat::Markdown,
    content: "Hello <span>inline</span> html",
    uuid: "markdown-006",
  }
  let parsed = match @moonink.parse_with_adapter_result(adapter, input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let contract = @moonink.parse_markdown_backend_contract("Hello <span>inline</span> html")
  inspect(adapter.capabilities.supports_incremental_parsing, content="true")
  inspect(adapter.capabilities.supports_html_passthrough, content="false")
  inspect(parsed.diagnostics.entries.length(), content="0")
  inspect(parsed.backend_payload, content="Some(\"Hello <span>inline</span> html\\n\")")
  inspect(
    contract.html_output,
    content="<p>Hello <a href=\"span\">span</a>inline<a href=\"/span\">/span</a> html</p>\n",
  )
  inspect(contract.definition_count, content="0")
}


///|
test "docflow markdown render adapter renders heading html through render boundary" {
  let parser = @moonink.markdown_parser_adapter()
  let renderer = @moonink.markdown_render_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/render-heading.md",
    format: @moonink.SourceFormat::Markdown,
    content: "# Hello MoonInk",
    uuid: "render-001",
  }
  let parsed = match @moonink.parse_with_adapter_result(parser, input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let rendered = @moonink.render_with_adapter(renderer, parsed)
  inspect(rendered.backend_name, content="markdown-render-adapter")
  inspect(rendered.source_path, content="articles/render-heading.md")
  inspect(rendered.source_uuid, content="render-001")
  inspect(rendered.html, content="<h1>Hello MoonInk</h1>\n")
  inspect(rendered.note, content="Real Markdown render adapter backed by mizchi/markdown.")
}

///|
test "docflow markdown render adapter renders list and link html through render boundary" {
  let parser = @moonink.markdown_parser_adapter()
  let renderer = @moonink.markdown_render_adapter()
  let list_input : @moonink.SourceDocumentInput = {
    path: "articles/render-list.md",
    format: @moonink.SourceFormat::Markdown,
    content: "- one\n- two",
    uuid: "render-002",
  }
  let list_parsed = match @moonink.parse_with_adapter_result(parser, list_input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let list_rendered = @moonink.render_with_adapter(renderer, list_parsed)
  inspect(
    list_rendered.html,
    content=(
      #|<ul>
      #|<li>one</li>
      #|<li>two</li>
      #|</ul>
      #|
    ),
  )
  let link_input : @moonink.SourceDocumentInput = {
    path: "articles/render-link.md",
    format: @moonink.SourceFormat::Markdown,
    content: "[MoonBit](https://www.moonbitlang.com)",
    uuid: "render-003",
  }
  let link_parsed = match @moonink.parse_with_adapter_result(parser, link_input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let link_rendered = @moonink.render_with_adapter(renderer, link_parsed)
  inspect(link_rendered.html, content="<p><a href=\"https://www.moonbitlang.com\">MoonBit</a></p>\n")
}

///|
test "docflow markdown render adapter renders inline html according to backend behavior" {
  let parser = @moonink.markdown_parser_adapter()
  let renderer = @moonink.markdown_render_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/render-inline-html.md",
    format: @moonink.SourceFormat::Markdown,
    content: "Hello <span>inline</span> html",
    uuid: "render-004",
  }
  let parsed = match @moonink.parse_with_adapter_result(parser, input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let rendered = @moonink.render_with_adapter(renderer, parsed)
  inspect(
    rendered.html,
    content="<p>Hello <a href=\"span\">span</a>inline<a href=\"/span\">/span</a> html</p>\n",
  )
}


///|
test "docflow article pipeline keeps parser wikilinker and render order explicit" {
  let parser = @moonink.markdown_parser_adapter()
  let linker = @moonink.noop_wikilinker(
    name="article-semantic-noop",
    note="Explicit no-op wikilinker for article pipeline coverage.",
  )
  let renderer = @moonink.markdown_render_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/pipeline-heading.md",
    format: @moonink.SourceFormat::Markdown,
    content: "# Pipeline Heading",
    uuid: "pipeline-001",
  }
  let pipeline = match @moonink.run_article_pipeline(parser, linker, renderer, input) {
    Ok(result) => result
    Err(_) => panic()
  }
  inspect(pipeline.parsed.backend_name, content="markdown-parser-adapter")
  inspect(pipeline.linked.backend_name, content="markdown-parser-adapter")
  inspect(pipeline.rendered.backend_name, content="markdown-render-adapter")
  inspect(pipeline.parsed.backend_payload, content="Some(\"# Pipeline Heading\\n\")")
  inspect(pipeline.linked.backend_payload, content="Some(\"# Pipeline Heading\\n\")")
  inspect(pipeline.rendered.html, content="<h1>Pipeline Heading</h1>\n")
  inspect(
    pipeline.pipeline_note,
    content="article pipeline now keeps parser, wikilinker, and render order explicit",
  )
}

///|
test "docflow article pipeline keeps noop wikilinker transform explicit for list content" {
  let parser = @moonink.markdown_parser_adapter()
  let linker = @moonink.noop_wikilinker()
  let renderer = @moonink.markdown_render_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/pipeline-list.md",
    format: @moonink.SourceFormat::Markdown,
    content: "- one\n- two",
    uuid: "pipeline-002",
  }
  let pipeline = match @moonink.run_article_pipeline(parser, linker, renderer, input) {
    Ok(result) => result
    Err(_) => panic()
  }
  inspect(pipeline.parsed == pipeline.linked, content="true")
  inspect(pipeline.linked.source_path, content="articles/pipeline-list.md")
  inspect(
    pipeline.rendered.html,
    content=(
      #|<ul>
      #|<li>one</li>
      #|<li>two</li>
      #|</ul>
      #|
    ),
  )
}


///|
test "docflow downstream assembly accepts article output after templating" {
  let parser = @moonink.markdown_parser_adapter()
  let linker = @moonink.noop_wikilinker()
  let renderer = @moonink.markdown_render_adapter()
  let input : @moonink.SourceDocumentInput = {
    path: "articles/downstream-article.md",
    format: @moonink.SourceFormat::Markdown,
    content: "# Downstream Article",
    uuid: "downstream-001",
  }
  let pipeline = match @moonink.run_article_pipeline(parser, linker, renderer, input) {
    Ok(result) => result
    Err(_) => panic()
  }
  let templated = @moonink.apply_dummy_template(pipeline.rendered)
  let assembly = @moonink.construct_site([@moonink.article_site_entry(templated)])
  inspect(templated.route, content="/articles/downstream-article.md")
  inspect(assembly.entries.length(), content="1")
  inspect(assembly.entries[0].kind, content="article")
  inspect(assembly.entries[0].route, content="/articles/downstream-article.md")
  inspect(assembly.entries[0].html.contains("<h1>Downstream Article</h1>"), content="true")
}

///|
test "docflow downstream assembly accepts page output in common structure" {
  let page_rendered : @moonink.RenderedDocument = {
    backend_name: "html-passthrough-render",
    source_path: "pages/index.html",
    source_uuid: "downstream-002",
    html: "<main><h1>Page Home</h1></main>",
    note: "Page passthrough render result for downstream assembly coverage.",
  }
  let page_templated = @moonink.apply_dummy_template(page_rendered)
  let article_rendered : @moonink.RenderedDocument = {
    backend_name: "markdown-render-adapter",
    source_path: "articles/second.md",
    source_uuid: "downstream-003",
    html: "<h1>Article Second</h1>\n",
    note: "Article render result for common assembly coverage.",
  }
  let article_templated = @moonink.apply_dummy_template(article_rendered)
  let assembly = @moonink.construct_site([
    @moonink.page_site_entry(page_templated),
    @moonink.article_site_entry(article_templated),
  ])
  inspect(page_templated.route, content="/pages/index.html")
  inspect(assembly.entries.length(), content="2")
  inspect(assembly.entries[0].kind, content="page")
  inspect(assembly.entries[1].kind, content="article")
  inspect(assembly.entries[0].route, content="/pages/index.html")
  inspect(assembly.entries[1].route, content="/articles/second.md")
  inspect(
    assembly.note,
    content="dummy site constructor now collects article and page outputs into one shared assembly",
  )
}
