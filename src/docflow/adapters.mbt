///|
/// Registry errors for parser/render backend lookup.
pub(all) suberror AdapterRegistryError {
  MissingParserAdapter(@core.SourceFormat)
  MissingRenderAdapter(@core.SourceFormat)
} derive(Show, Eq)

///|
/// Fatal parser failures for states where no meaningful ParsedDocument can be returned.
pub(all) suberror FatalParseError {
  InvalidAdapterState(adapter_name~ : String, reason~ : String)
  UnsupportedFormat(
    adapter_name~ : String,
    expected~ : @core.SourceFormat,
    actual~ : @core.SourceFormat
  )
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
pub fn empty_parser_registry() -> ParserRegistry {
  { markdown: None, typst: None, html: None, unknown: None }
}

///|
pub fn empty_render_registry() -> RenderRegistry {
  { markdown: None, typst: None, html: None, unknown: None }
}

///|
pub fn register_parser_adapter(
  registry : ParserRegistry,
  format : @core.SourceFormat,
  adapter : ParserAdapter,
) -> ParserRegistry {
  match format {
    @core.SourceFormat::Markdown => { ..registry, markdown: Some(adapter) }
    @core.SourceFormat::Html => { ..registry, html: Some(adapter) }
    @core.SourceFormat::Unknown => { ..registry, unknown: Some(adapter) }
  }
}

///|
pub fn register_render_adapter(
  registry : RenderRegistry,
  format : @core.SourceFormat,
  adapter : RenderAdapter,
) -> RenderRegistry {
  match format {
    @core.SourceFormat::Markdown => { ..registry, markdown: Some(adapter) }
    @core.SourceFormat::Html => { ..registry, html: Some(adapter) }
    @core.SourceFormat::Unknown => { ..registry, unknown: Some(adapter) }
  }
}

///|
pub fn lookup_parser_adapter(
  registry : ParserRegistry,
  format : @core.SourceFormat,
) -> Result[ParserAdapter, AdapterRegistryError] {
  let resolved = match format {
    @core.SourceFormat::Markdown => registry.markdown
    @core.SourceFormat::Html => registry.html
    @core.SourceFormat::Unknown => registry.unknown
  }
  match resolved {
    Some(adapter) => Ok(adapter)
    None => Err(AdapterRegistryError::MissingParserAdapter(format))
  }
}

///|
pub fn lookup_render_adapter(
  registry : RenderRegistry,
  format : @core.SourceFormat,
) -> Result[RenderAdapter, AdapterRegistryError] {
  let resolved = match format {
    @core.SourceFormat::Markdown => registry.markdown
    @core.SourceFormat::Html => registry.html
    @core.SourceFormat::Unknown => registry.unknown
  }
  match resolved {
    Some(adapter) => Ok(adapter)
    None => Err(AdapterRegistryError::MissingRenderAdapter(format))
  }
}

///|
pub fn fake_parser_adapter(
  name : String,
  capabilities? : ParserCapabilities = default_parser_capabilities(),
  note? : String = "Fake parser adapter for contract tests.",
) -> ParserAdapter {
  { name, capabilities, note }
}

///|
pub fn markdown_parser_adapter() -> ParserAdapter {
  {
    name: "markdown-parser-adapter",
    capabilities: markdown_backend_capabilities(),
    note: "Real Markdown parser adapter backed by mizchi/markdown.",
  }
}

///|
pub fn html_passthrough_parser_adapter() -> ParserAdapter {
  {
    name: "html-passthrough-parser",
    capabilities: {
      supports_incremental_parsing: false,
      supports_html_passthrough: true,
    },
    note: "HTML page input bypasses markup parsing while staying inside the parser adapter boundary.",
  }
}

///|
pub fn broken_parser_adapter(
  name? : String = "broken-parser-adapter",
  note? : String = "Intentional broken parser adapter for fatal-boundary tests.",
) -> ParserAdapter {
  { name, capabilities: default_parser_capabilities(), note }
}

///|
pub fn fake_render_adapter(
  name : String,
  note? : String = "Fake render adapter for contract tests.",
) -> RenderAdapter {
  { name, note }
}

///|
pub fn markdown_render_adapter() -> RenderAdapter {
  {
    name: "markdown-render-adapter",
    note: "Real Markdown render adapter backed by mizchi/markdown.",
  }
}

///|
pub fn noop_wikilinker(
  name? : String = "noop-wikilinker",
  note? : String = "No-op semantic stage for early document-flow testing.",
) -> WikiLinker {
  { name, note }
}
