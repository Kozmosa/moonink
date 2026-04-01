///|
/// Apply the semantic linker boundary. The default stage is an explicit no-op.
/// Future implementation will handle Obsidian-compatible [[wikilink]] resolution.
pub fn apply_wikilinker(
  linker : WikiLinker,
  parsed : ParsedDocument,
) -> ParsedDocument {
  ignore(linker)
  parsed
}
