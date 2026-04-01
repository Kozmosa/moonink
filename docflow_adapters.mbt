///|
/// Registry errors for parser/render backend lookup.
pub(all) suberror AdapterRegistryError {
  MissingParserAdapter(SourceFormat)
  MissingRenderAdapter(SourceFormat)
} derive(Show, Eq)

///|
/// Fatal parser failures for states where no meaningful ParsedDocument can be returned.
pub(all) suberror FatalParseError {
  InvalidAdapterState(adapter_name~ : String, reason~ : String)
  UnsupportedFormat(adapter_name~ : String, expected~ : SourceFormat, actual~ : SourceFormat)
  BackendFailure(adapter_name~ : String, detail~ : String)
} derive(Show, Eq)

///|
/// Contract surface for parser backends in the document-flow pipeline.
pub(all) struct ParserAdapter {
  name : String
  capabilities : ParserCapabilities
  note : String
} derive(Show, Eq)

///|
/// Contract surface for semantic post-parse stages such as WikiLink processing.
pub(all) struct WikiLinker {
  name : String
  note : String
} derive(Show, Eq)

///|
/// Contract surface for render backends that transform parsed documents into HTML.
pub(all) struct RenderAdapter {
  name : String
  note : String
} derive(Show, Eq)

///|
/// Thin render result used to freeze the RenderAdapter contract before real backends land.
pub(all) struct RenderedDocument {
  backend_name : String
  source_path : String
  source_uuid : String
  html : String
  note : String
} derive(Show, Eq)

///|
/// Explicit article-flow summary that keeps parser, WikiLinker, and render stages visible.
pub(all) struct ArticlePipelineResult {
  parsed : ParsedDocument
  linked : ParsedDocument
  rendered : RenderedDocument
  pipeline_note : String
} derive(Show, Eq)

///|
/// Dummy templated page produced after rendering but before site construction.
pub(all) struct TemplatedPage {
  route : String
  source_path : String
  source_uuid : String
  html : String
  note : String
} derive(Show, Eq)

///|
/// Common downstream site entry used by the dummy site constructor.
pub(all) struct SiteEntry {
  kind : String
  route : String
  source_path : String
  source_uuid : String
  html : String
} derive(Show, Eq)

///|
/// Dummy site-constructor result that holds all assembled downstream entries.
pub(all) struct SiteAssembly {
  entries : Array[SiteEntry]
  note : String
} derive(Show, Eq)

///|
/// Parser backend registry keyed by source format.
pub(all) struct ParserRegistry {
  markdown : ParserAdapter?
  typst : ParserAdapter?
  html : ParserAdapter?
  unknown : ParserAdapter?
} derive(Show, Eq)

///|
/// Render backend registry keyed by source format.
pub(all) struct RenderRegistry {
  markdown : RenderAdapter?
  typst : RenderAdapter?
  html : RenderAdapter?
  unknown : RenderAdapter?
} derive(Show, Eq)

///|
/// Create an empty parser registry before individual backends are registered.
pub fn empty_parser_registry() -> ParserRegistry {
  { markdown: None, typst: None, html: None, unknown: None }
}

///|
/// Create an empty render registry before individual backends are registered.
pub fn empty_render_registry() -> RenderRegistry {
  { markdown: None, typst: None, html: None, unknown: None }
}

///|
/// Register a parser adapter for a specific source format.
pub fn register_parser_adapter(
  registry : ParserRegistry,
  format : SourceFormat,
  adapter : ParserAdapter,
) -> ParserRegistry {
  match format {
    SourceFormat::Markdown => { ..registry, markdown: Some(adapter) }
    SourceFormat::Typst => { ..registry, typst: Some(adapter) }
    SourceFormat::Html => { ..registry, html: Some(adapter) }
    SourceFormat::Unknown => { ..registry, unknown: Some(adapter) }
  }
}

///|
/// Register a render adapter for a specific source format.
pub fn register_render_adapter(
  registry : RenderRegistry,
  format : SourceFormat,
  adapter : RenderAdapter,
) -> RenderRegistry {
  match format {
    SourceFormat::Markdown => { ..registry, markdown: Some(adapter) }
    SourceFormat::Typst => { ..registry, typst: Some(adapter) }
    SourceFormat::Html => { ..registry, html: Some(adapter) }
    SourceFormat::Unknown => { ..registry, unknown: Some(adapter) }
  }
}

///|
/// Resolve a parser adapter for the requested source format.
pub fn lookup_parser_adapter(
  registry : ParserRegistry,
  format : SourceFormat,
) -> Result[ParserAdapter, AdapterRegistryError] {
  let resolved = match format {
    SourceFormat::Markdown => registry.markdown
    SourceFormat::Typst => registry.typst
    SourceFormat::Html => registry.html
    SourceFormat::Unknown => registry.unknown
  }
  match resolved {
    Some(adapter) => Ok(adapter)
    None => Err(AdapterRegistryError::MissingParserAdapter(format))
  }
}

///|
/// Resolve a render adapter for the requested source format.
pub fn lookup_render_adapter(
  registry : RenderRegistry,
  format : SourceFormat,
) -> Result[RenderAdapter, AdapterRegistryError] {
  let resolved = match format {
    SourceFormat::Markdown => registry.markdown
    SourceFormat::Typst => registry.typst
    SourceFormat::Html => registry.html
    SourceFormat::Unknown => registry.unknown
  }
  match resolved {
    Some(adapter) => Ok(adapter)
    None => Err(AdapterRegistryError::MissingRenderAdapter(format))
  }
}

///|
/// Create a fake parser adapter for contract tests and early pipeline wiring.
pub fn fake_parser_adapter(
  name : String,
  capabilities? : ParserCapabilities = default_parser_capabilities(),
  note? : String = "Fake parser adapter for contract tests.",
) -> ParserAdapter {
  { name, capabilities, note }
}

///|
/// Create the real Markdown parser adapter backed by mizchi/markdown.
pub fn markdown_parser_adapter() -> ParserAdapter {
  {
    name: "markdown-parser-adapter",
    capabilities: markdown_backend_capabilities(),
    note: "Real Markdown parser adapter backed by mizchi/markdown.",
  }
}

///|
/// Create the explicit Typst stub adapter used before a real Typst backend exists.
pub fn unsupported_typst_parser_adapter() -> ParserAdapter {
  {
    name: "unsupported-typst-parser",
    capabilities: { supports_incremental_parsing: false, supports_html_passthrough: false },
    note: "Typst parsing is not implemented yet; this adapter returns a structured warning diagnostic.",
  }
}

///|
/// Create the explicit HTML passthrough adapter for page-origin HTML sources.
pub fn html_passthrough_parser_adapter() -> ParserAdapter {
  {
    name: "html-passthrough-parser",
    capabilities: { supports_incremental_parsing: false, supports_html_passthrough: true },
    note: "HTML page input bypasses markup parsing while staying inside the parser adapter boundary.",
  }
}

///|
/// Create an intentionally broken parser adapter for fatal-boundary tests.
pub fn broken_parser_adapter(
  name? : String = "broken-parser-adapter",
  note? : String = "Intentional broken parser adapter for fatal-boundary tests.",
) -> ParserAdapter {
  {
    name,
    capabilities: default_parser_capabilities(),
    note,
  }
}

///|
/// Create a fake render adapter for contract tests and early pipeline wiring.
pub fn fake_render_adapter(
  name : String,
  note? : String = "Fake render adapter for contract tests.",
) -> RenderAdapter {
  { name, note }
}

///|
/// Create the real Markdown render adapter backed by mizchi/markdown.
pub fn markdown_render_adapter() -> RenderAdapter {
  {
    name: "markdown-render-adapter",
    note: "Real Markdown render adapter backed by mizchi/markdown.",
  }
}

///|
/// Create a no-op WikiLinker stage that leaves parsed documents unchanged.
pub fn noop_wikilinker(
  name? : String = "noop-wikilinker",
  note? : String = "No-op semantic stage for early document-flow testing.",
) -> WikiLinker {
  { name, note }
}

///|
fn typst_stub_diagnostics() -> DocumentDiagnostics {
  {
    entries: [
      {
        severity: DiagnosticSeverity::Warn,
        line: Some(1),
        message: "Typst parsing is not implemented yet.",
        hint: Some("Use the stub diagnostic until the real Typst backend lands."),
        backend_name: "unsupported-typst-parser",
      },
    ],
  }
}

///|
fn expected_format_for_adapter(adapter : ParserAdapter) -> SourceFormat? {
  if adapter.name == "markdown-parser-adapter" {
    Some(SourceFormat::Markdown)
  } else if adapter.name == "unsupported-typst-parser" {
    Some(SourceFormat::Typst)
  } else if adapter.name == "html-passthrough-parser" {
    Some(SourceFormat::Html)
  } else {
    None
  }
}

///|
fn parse_document_with_adapter_result(
  adapter : ParserAdapter,
  input : SourceDocumentInput,
) -> Result[ParsedDocument, FatalParseError] {
  if adapter.name == "" {
    return Err(FatalParseError::InvalidAdapterState(adapter_name="", reason="adapter name must not be empty"))
  }
  if adapter.name == "broken-parser-adapter" {
    return Err(FatalParseError::BackendFailure(adapter_name=adapter.name, detail="intentional fatal parse failure"))
  }
  match expected_format_for_adapter(adapter) {
    Some(expected) if expected != input.format => {
      return Err(
        FatalParseError::UnsupportedFormat(
          adapter_name=adapter.name,
          expected=expected,
          actual=input.format,
        ),
      )
    }
    _ => ()
  }
  if adapter.name == "markdown-parser-adapter" {
    let contract = parse_markdown_backend_contract(input.content)
    Ok({
      backend_name: adapter.name,
      source_format: input.format,
      source_path: input.path,
      source_uuid: input.uuid,
      diagnostics: contract.diagnostics,
      backend_payload: Some(contract.serialized_markdown),
    })
  } else if adapter.name == "unsupported-typst-parser" {
    Ok({
      backend_name: adapter.name,
      source_format: input.format,
      source_path: input.path,
      source_uuid: input.uuid,
      diagnostics: typst_stub_diagnostics(),
      backend_payload: None,
    })
  } else if adapter.name == "html-passthrough-parser" {
    Ok({
      backend_name: adapter.name,
      source_format: input.format,
      source_path: input.path,
      source_uuid: input.uuid,
      diagnostics: empty_document_diagnostics(),
      backend_payload: Some(input.content),
    })
  } else {
    Ok({
      backend_name: adapter.name,
      source_format: input.format,
      source_path: input.path,
      source_uuid: input.uuid,
      diagnostics: empty_document_diagnostics(),
      backend_payload: Some("fake-parse:\{input.path}"),
    })
  }
}

///|
/// Parse through the adapter boundary and preserve the split between recoverable diagnostics and fatal parser failures.
pub fn parse_with_adapter_result(
  adapter : ParserAdapter,
  input : SourceDocumentInput,
) -> Result[ParsedDocument, FatalParseError] {
  parse_document_with_adapter_result(adapter, input)
}

///|
/// Run a parser adapter so tests can freeze the adapter boundary before real backends land.
pub fn parse_with_adapter(adapter : ParserAdapter, input : SourceDocumentInput) -> ParsedDocument {
  match parse_with_adapter_result(adapter, input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
}

///|
/// Apply the semantic linker boundary. The default stage is an explicit no-op.
pub fn apply_wikilinker(linker : WikiLinker, parsed : ParsedDocument) -> ParsedDocument {
  ignore(linker)
  parsed
}

///|
/// Build a stable route from a source path for dummy downstream assembly.
pub fn route_from_source_path(source_path : String) -> String {
  "/" + source_path
}

///|
/// Dummy templater that wraps rendered HTML in a simple site shell.
pub fn apply_dummy_template(rendered : RenderedDocument) -> TemplatedPage {
  {
    route: route_from_source_path(rendered.source_path),
    source_path: rendered.source_path,
    source_uuid: rendered.source_uuid,
    html:
      "<!doctype html>\n<html><body><main data-source=\"\{rendered.source_path}\">\{rendered.html}</main></body></html>",
    note: "dummy templater keeps rendered content inside a simple site shell",
  }
}

///|
/// Convert a templated article page into the common downstream site-entry shape.
pub fn article_site_entry(page : TemplatedPage) -> SiteEntry {
  {
    kind: "article",
    route: page.route,
    source_path: page.source_path,
    source_uuid: page.source_uuid,
    html: page.html,
  }
}

///|
/// Convert a templated page into the common downstream site-entry shape.
pub fn page_site_entry(page : TemplatedPage) -> SiteEntry {
  {
    kind: "page",
    route: page.route,
    source_path: page.source_path,
    source_uuid: page.source_uuid,
    html: page.html,
  }
}

///|
/// Dummy site constructor that collects common downstream entries into one assembly.
pub fn construct_site(entries : Array[SiteEntry]) -> SiteAssembly {
  {
    entries,
    note: "dummy site constructor now collects article and page outputs into one shared assembly",
  }
}

///|
/// DocFlow build closure that routes discovered Markdown files through the article pipeline.
pub fn run_docflow_build_pipeline(
  files : Array[String],
  parser : ParserAdapter,
  linker : WikiLinker,
  renderer : RenderAdapter,
) -> SiteAssembly {
  let entries = []
  for file in files {
    let input : SourceDocumentInput = {
      path: file,
      format: SourceFormat::Markdown,
      content: "[docflow placeholder content for \{file}]",
      uuid: file,
    }
    match run_article_pipeline(parser, linker, renderer, input) {
      Ok(result) => {
        let templated = apply_dummy_template(result.rendered)
        entries.push(article_site_entry(templated))
      }
      Err(_) => {
        let failed_rendered : RenderedDocument = {
          backend_name: "docflow-build-failed",
          source_path: file,
          source_uuid: file,
          html: "<!-- docflow build failed for \{file} -->",
          note: "docflow build placeholder for failed article pipeline",
        }
        let templated = apply_dummy_template(failed_rendered)
        entries.push(article_site_entry(templated))
      }
    }
  }
  construct_site(entries)
}

///|
/// Run the article pipeline explicitly through parser, WikiLinker, and render stages.
pub fn run_article_pipeline(
  parser : ParserAdapter,
  linker : WikiLinker,
  renderer : RenderAdapter,
  input : SourceDocumentInput,
) -> Result[ArticlePipelineResult, FatalParseError] {
  let parsed = match parse_with_adapter_result(parser, input) {
    Ok(parsed) => parsed
    Err(err) => return Err(err)
  }
  let linked = apply_wikilinker(linker, parsed)
  let rendered = render_with_adapter(renderer, linked)
  Ok({
    parsed,
    linked,
    rendered,
    pipeline_note: "article pipeline now keeps parser, wikilinker, and render order explicit",
  })
}

///|
/// Run a render adapter so tests can freeze the HTML render contract before real backends land.
pub fn render_with_adapter(adapter : RenderAdapter, parsed : ParsedDocument) -> RenderedDocument {
  let html_body = if adapter.name == "markdown-render-adapter" && parsed.source_format == SourceFormat::Markdown {
    let markdown_payload = match parsed.backend_payload {
      Some(payload) => payload
      None => ""
    }
    render_markdown_backend_payload(markdown_payload)
  } else {
    let payload = match parsed.backend_payload {
      Some(payload) => payload
      None => parsed.source_path
    }
    "<article data-renderer=\"\{adapter.name}\" data-source-format=\"\{parsed.source_format}\">\{payload}</article>"
  }
  {
    backend_name: adapter.name,
    source_path: parsed.source_path,
    source_uuid: parsed.source_uuid,
    html: html_body,
    note: adapter.note,
  }
}
