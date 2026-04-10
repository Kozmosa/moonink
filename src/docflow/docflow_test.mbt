///|
test "docflow parser domain types support construction" {
  let input : @docflow.SourceDocumentInput = {
    path: "docs/getting-started.md",
    format: @core.SourceFormat::Markdown,
    content: "# Hello MoonInk",
    uuid: "doc-001",
  }
  inspect(input.format, content="Markdown")
  inspect(input.path, content="docs/getting-started.md")
}

///|
test "docflow diagnostic formatting supports line and hint details" {
  let diagnostic : @docflow.DocumentDiagnostic = {
    severity: @docflow.DiagnosticSeverity::Warn,
    line: Some(1),
    message: "Undefined Typst symbol.",
    hint: Some("Check output of typst."),
    backend_name: "typst-stub",
  }
  inspect(
    @docflow.format_document_diagnostic(diagnostic),
    content="(WARN) Line 1, Undefined Typst symbol. Check output of typst.",
  )
}

///|
test "docflow parser adapter contract preserves identity and source metadata" {
  let capabilities : @docflow.ParserCapabilities = {
    supports_incremental_parsing: true,
    supports_html_passthrough: false,
  }
  let adapter = @docflow.fake_parser_adapter(
    "fake-markdown-parser",
    capabilities~,
    note="Fake parser adapter for contract coverage.",
  )
  let input : @docflow.SourceDocumentInput = {
    path: "articles/hello.md",
    format: @core.SourceFormat::Markdown,
    content: "# Hello",
    uuid: "article-001",
  }
  let parsed = @docflow.parse_with_adapter(adapter, input)
  inspect(adapter.name, content="fake-markdown-parser")
  inspect(parsed.backend_name, content="fake-markdown-parser")
  inspect(parsed.source_format, content="Markdown")
  inspect(parsed.source_path, content="articles/hello.md")
  inspect(parsed.source_uuid, content="article-001")
}

///|
test "docflow wikilinker contract remains explicit no-op" {
  let parsed : @docflow.ParsedDocument = {
    backend_name: "fake-markdown-parser",
    source_format: @core.SourceFormat::Markdown,
    source_path: "articles/hello.md",
    source_uuid: "article-001",
    diagnostics: @docflow.empty_document_diagnostics(),
    backend_payload: Some("fake-parse:articles/hello.md"),
  }
  let linker = @docflow.noop_wikilinker(
    name="semantic-noop",
    note="No-op semantic stage for contract coverage.",
  )
  inspect(linker.exact_targets.is_empty(), content="true")
  inspect(linker.ambiguous_targets.is_empty(), content="true")
  let linked = @docflow.apply_wikilinker(linker, parsed)
  inspect(linked.source_path, content="articles/hello.md")
  inspect(
    linked.backend_payload,
    content="Some(\"fake-parse:articles/hello.md\")",
  )
}

///|
test "docflow indexed wikilinker stores exact and ambiguous targets" {
  let linker = @docflow.indexed_wikilinker(
    { "hello": "/hello/" },
    { "intro": ["/guides/intro/", "/reference/intro/"] },
    name="test-indexed-linker",
  )
  inspect(linker.name, content="test-indexed-linker")
  inspect(linker.exact_targets.get("hello"), content="Some(\"/hello/\")")
  inspect(
    linker.ambiguous_targets.get("intro"),
    content="Some([\"/guides/intro/\", \"/reference/intro/\"])",
  )
}

///|
test "docflow render adapter contract produces html from parsed document" {
  let parsed : @docflow.ParsedDocument = {
    backend_name: "fake-markdown-parser",
    source_format: @core.SourceFormat::Markdown,
    source_path: "articles/hello.md",
    source_uuid: "article-001",
    diagnostics: @docflow.empty_document_diagnostics(),
    backend_payload: Some("<h1>Hello</h1>"),
  }
  let renderer = @docflow.fake_render_adapter(
    "fake-html-renderer",
    note="Fake render adapter for contract coverage.",
  )
  let rendered = @docflow.render_with_adapter(renderer, parsed)
  inspect(rendered.backend_name, content="fake-html-renderer")
  inspect(
    rendered.html,
    content="<article data-renderer=\"fake-html-renderer\" data-source-format=\"Markdown\"><h1>Hello</h1></article>",
  )
}

///|
test "docflow parser registry resolves adapters by source format" {
  let parser = @docflow.fake_parser_adapter("fake-markdown-parser", capabilities={
    supports_incremental_parsing: true,
    supports_html_passthrough: false,
  })
  let registry = @docflow.register_parser_adapter(
    @docflow.empty_parser_registry(),
    @core.SourceFormat::Markdown,
    parser,
  )
  inspect(
    @docflow.lookup_parser_adapter(registry, @core.SourceFormat::Markdown)
    is Ok(_),
    content="true",
  )
}

///|
test "docflow registry reports missing parser registrations" {
  inspect(
    @docflow.lookup_parser_adapter(
      @docflow.empty_parser_registry(),
      @core.SourceFormat::Html,
    ),
    content="Err(MissingParserAdapter(Html))",
  )
}

///|
test "docflow html passthrough adapter preserves html input" {
  let adapter = @docflow.html_passthrough_parser_adapter()
  let input : @docflow.SourceDocumentInput = {
    path: "pages/index.html",
    format: @core.SourceFormat::Html,
    content: "<main><h1>Home</h1></main>",
    uuid: "page-001",
  }
  let parsed = @docflow.parse_with_adapter(adapter, input)
  inspect(adapter.capabilities.supports_html_passthrough, content="true")
  inspect(
    parsed.backend_payload,
    content="Some(\"<main><h1>Home</h1></main>\")",
  )
}

///|
test "docflow fatal boundary reports backend failure for broken adapter" {
  let adapter = @docflow.broken_parser_adapter()
  let input : @docflow.SourceDocumentInput = {
    path: "articles/hello.md",
    format: @core.SourceFormat::Markdown,
    content: "# Hello",
    uuid: "article-002",
  }
  inspect(
    @docflow.parse_with_adapter_result(adapter, input),
    content="Err(BackendFailure(adapter_name=\"broken-parser-adapter\", detail=\"intentional fatal parse failure\"))",
  )
}

///|
test "docflow markdown parser adapter parses heading" {
  let adapter = @docflow.markdown_parser_adapter()
  let input : @docflow.SourceDocumentInput = {
    path: "articles/heading.md",
    format: @core.SourceFormat::Markdown,
    content: "# Hello MoonInk",
    uuid: "markdown-001",
  }
  let parsed = match @docflow.parse_with_adapter_result(adapter, input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  inspect(parsed.backend_name, content="markdown-parser-adapter")
  inspect(parsed.backend_payload, content="Some(\"# Hello MoonInk\\n\")")
}

///|
test "docflow markdown render adapter renders heading html" {
  let parser = @docflow.markdown_parser_adapter()
  let renderer = @docflow.markdown_render_adapter()
  let input : @docflow.SourceDocumentInput = {
    path: "articles/render-heading.md",
    format: @core.SourceFormat::Markdown,
    content: "# Hello MoonInk",
    uuid: "render-001",
  }
  let parsed = match @docflow.parse_with_adapter_result(parser, input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
  let rendered = @docflow.render_with_adapter(renderer, parsed)
  inspect(rendered.html, content="<h1>Hello MoonInk</h1>\n")
}

///|
test "docflow article pipeline keeps parser wikilinker and render order explicit" {
  let parser = @docflow.markdown_parser_adapter()
  let linker = @docflow.noop_wikilinker()
  let renderer = @docflow.markdown_render_adapter()
  let input : @docflow.SourceDocumentInput = {
    path: "articles/pipeline-heading.md",
    format: @core.SourceFormat::Markdown,
    content: "# Pipeline Heading",
    uuid: "pipeline-001",
  }
  let pipeline = match
    @docflow.run_article_pipeline(parser, linker, renderer, input) {
    Ok(result) => result
    Err(_) => panic()
  }
  inspect(pipeline.parsed.backend_name, content="markdown-parser-adapter")
  inspect(pipeline.linked.backend_name, content="markdown-parser-adapter")
  inspect(pipeline.rendered.html, content="<h1>Pipeline Heading</h1>\n")
}

///|
test "docflow downstream assembly accepts article output after templating" {
  let parser = @docflow.markdown_parser_adapter()
  let linker = @docflow.noop_wikilinker()
  let renderer = @docflow.markdown_render_adapter()
  let input : @docflow.SourceDocumentInput = {
    path: "articles/downstream-article.md",
    format: @core.SourceFormat::Markdown,
    content: "# Downstream Article",
    uuid: "downstream-001",
  }
  let pipeline = match
    @docflow.run_article_pipeline(parser, linker, renderer, input) {
    Ok(result) => result
    Err(_) => panic()
  }
  let templated = @docflow.apply_dummy_template(pipeline.rendered)
  let assembly = @docflow.construct_site([
    @docflow.article_site_entry(templated),
  ])
  inspect(assembly.entries.length(), content="1")
  inspect(assembly.entries[0].kind, content="article")
}

///|
test "docflow build pipeline processes files into site assembly" {
  let parser = @docflow.markdown_parser_adapter()
  let linker = @docflow.noop_wikilinker()
  let renderer = @docflow.markdown_render_adapter()
  let assembly = @docflow.run_docflow_build_pipeline(
    ["articles/first.md", "articles/second.md"],
    parser,
    linker,
    renderer,
  )
  inspect(assembly.entries.length(), content="2")
  inspect(assembly.entries[0].kind, content="article")
  inspect(assembly.entries[0].source_path, content="articles/first.md")
}
