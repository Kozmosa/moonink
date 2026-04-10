///|
/// Registry errors for parser/render backend lookup.
pub(all) suberror AdapterRegistryError {
  MissingParserAdapter(@core.SourceFormat)
  MissingRenderAdapter(@core.SourceFormat)
} derive(Debug, Eq)

///|
pub impl Show for AdapterRegistryError with output(self, logger) {
  match self {
    AdapterRegistryError::MissingParserAdapter(format) => {
      logger.write_string("MissingParserAdapter(")
      logger.write_string(format.to_string())
      logger.write_string(")")
    }
    AdapterRegistryError::MissingRenderAdapter(format) => {
      logger.write_string("MissingRenderAdapter(")
      logger.write_string(format.to_string())
      logger.write_string(")")
    }
  }
}

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
} derive(Debug, Eq)

///|
pub impl Show for FatalParseError with output(self, logger) {
  match self {
    FatalParseError::InvalidAdapterState(adapter_name~, reason~) => {
      logger.write_string("InvalidAdapterState(adapter_name=\"")
      logger.write_string(adapter_name)
      logger.write_string("\", reason=\"")
      logger.write_string(reason)
      logger.write_string("\")")
    }
    FatalParseError::UnsupportedFormat(adapter_name~, expected~, actual~) => {
      logger.write_string("UnsupportedFormat(adapter_name=\"")
      logger.write_string(adapter_name)
      logger.write_string("\", expected=")
      logger.write_string(expected.to_string())
      logger.write_string(", actual=")
      logger.write_string(actual.to_string())
      logger.write_string(")")
    }
    FatalParseError::BackendFailure(adapter_name~, detail~) => {
      logger.write_string("BackendFailure(adapter_name=\"")
      logger.write_string(adapter_name)
      logger.write_string("\", detail=\"")
      logger.write_string(detail)
      logger.write_string("\")")
    }
  }
}

///|
/// Contract surface for parser backends in the document-flow pipeline.
pub(all) struct ParserAdapter {
  name : String
  capabilities : ParserCapabilities
  note : String
} derive(Debug, Eq)

///|
pub impl Show for ParserAdapter with output(self, logger) {
  logger.write_string("ParserAdapter(name=\"")
  logger.write_string(self.name)
  logger.write_string("\")")
}

///|
/// Contract surface for semantic post-parse stages such as WikiLink processing.
pub(all) struct WikiLinker {
  name : String
  note : String
  exact_targets : Map[String, String]
  ambiguous_targets : Map[String, Array[String]]
} derive(Debug, Eq)

///|
/// Contract surface for render backends that transform parsed documents into HTML.
pub(all) struct RenderAdapter {
  name : String
  note : String
} derive(Debug, Eq)

///|
/// Thin render result used to freeze the RenderAdapter contract before real backends land.
pub(all) struct RenderedDocument {
  backend_name : String
  source_path : String
  source_uuid : String
  html : String
  note : String
} derive(Debug, Eq)

///|
/// Minimal native template context used by the built-in templater.
pub(all) struct TemplateContext {
  site_name : String
  site_url : String
  page_title : String
  page_description : String
  url_path : String
  source_path : String
  content_kind : String
  navigation_html : String
  body_html : String
} derive(Debug, Eq)

///|
/// Explicit article-flow summary that keeps parser, WikiLinker, and render stages visible.
pub(all) struct ArticlePipelineResult {
  parsed : ParsedDocument
  linked : ParsedDocument
  rendered : RenderedDocument
  pipeline_note : String
} derive(Debug, Eq)

///|
/// Dummy templated page produced after rendering but before site construction.
pub(all) struct TemplatedPage {
  route : String
  source_path : String
  source_uuid : String
  html : String
  note : String
} derive(Debug, Eq)

///|
/// Common downstream site entry used by the dummy site constructor.
pub(all) struct SiteEntry {
  kind : String
  route : String
  source_path : String
  source_uuid : String
  html : String
} derive(Debug, Eq)

///|
/// Dummy site-constructor result that holds all assembled downstream entries.
pub(all) struct SiteAssembly {
  entries : Array[SiteEntry]
  note : String
} derive(Debug, Eq)

///|
/// Parser backend registry keyed by source format.
pub(all) struct ParserRegistry {
  markdown : ParserAdapter?
  typst : ParserAdapter?
  html : ParserAdapter?
  unknown : ParserAdapter?
} derive(Debug, Eq)

///|
/// Render backend registry keyed by source format.
pub(all) struct RenderRegistry {
  markdown : RenderAdapter?
  typst : RenderAdapter?
  html : RenderAdapter?
  unknown : RenderAdapter?
} derive(Debug, Eq)

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
  { name, note, exact_targets: {}, ambiguous_targets: {} }
}

///|
pub fn indexed_wikilinker(
  exact_targets : Map[String, String],
  ambiguous_targets : Map[String, Array[String]],
  name? : String = "indexed-wikilinker",
  note? : String = "Semantic post-parse stage with precomputed route-aware wikilink targets.",
) -> WikiLinker {
  { name, note, exact_targets, ambiguous_targets }
}
