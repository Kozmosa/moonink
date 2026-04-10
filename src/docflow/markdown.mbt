///|
/// Backend-facing contract snapshot for the current mizchi/markdown parser integration tests.
pub(all) struct MarkdownBackendContract {
  html_output : String
  serialized_markdown : String
  block_count : Int
  definition_count : Int
  diagnostics : DocumentDiagnostics
  capabilities : ParserCapabilities
} derive(Debug, Eq)

///|
/// Capability contract expected from the first Markdown backend.
pub fn markdown_backend_capabilities() -> ParserCapabilities {
  { supports_incremental_parsing: true, supports_html_passthrough: false }
}

///|
/// Render Markdown through mizchi/markdown using the serialized parser payload contract.
pub fn render_markdown_backend_payload(serialized_markdown : String) -> String {
  let result = @markdown.parse(serialized_markdown)
  @markdown.render_html(result.document)
}

///|
/// Parse Markdown through mizchi/markdown and normalize the observable contract surface for tests.
pub fn parse_markdown_backend_contract(
  source : String,
) -> MarkdownBackendContract {
  let result = @markdown.parse(source)
  {
    html_output: @markdown.render_html(result.document),
    serialized_markdown: @markdown.serialize(result.document),
    block_count: result.document.children.length(),
    definition_count: result.definitions.length(),
    diagnostics: empty_document_diagnostics(),
    capabilities: markdown_backend_capabilities(),
  }
}
