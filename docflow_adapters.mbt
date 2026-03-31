///|
/// Registry errors for parser/render backend lookup.
pub(all) suberror AdapterRegistryError {
  MissingParserAdapter(SourceFormat)
  MissingRenderAdapter(SourceFormat)
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
/// Run a fake parser adapter so tests can freeze the adapter boundary before real backends land.
pub fn parse_with_adapter(adapter : ParserAdapter, input : SourceDocumentInput) -> ParsedDocument {
  {
    backend_name: adapter.name,
    source_format: input.format,
    source_path: input.path,
    source_uuid: input.uuid,
    diagnostics: empty_document_diagnostics(),
    backend_payload: Some("fake-parse:\{input.path}"),
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
