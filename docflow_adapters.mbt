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
/// Run a fake render adapter so tests can freeze the HTML render contract before real backends land.
pub fn render_with_adapter(adapter : RenderAdapter, parsed : ParsedDocument) -> RenderedDocument {
  let html_body = match parsed.backend_payload {
    Some(payload) => payload
    None => parsed.source_path
  }
  {
    backend_name: adapter.name,
    source_path: parsed.source_path,
    source_uuid: parsed.source_uuid,
    html: "<article data-renderer=\"\{adapter.name}\" data-source-format=\"\{parsed.source_format}\">\{html_body}</article>",
    note: adapter.note,
  }
}
