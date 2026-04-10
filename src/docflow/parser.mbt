///|
/// Parser-facing document input produced after frontmatter extraction.
pub(all) struct SourceDocumentInput {
  path : String
  format : @core.SourceFormat
  content : String
  uuid : String
} derive(Debug, Eq)

///|
/// Structured severity levels for parser diagnostics.
pub(all) enum DiagnosticSeverity {
  Info
  Warn
  Error
} derive(Debug, Eq)

///|
/// Single structured parser diagnostic entry.
pub(all) struct DocumentDiagnostic {
  severity : DiagnosticSeverity
  line : Int?
  message : String
  hint : String?
  backend_name : String
} derive(Debug, Eq)

///|
/// Diagnostic collection carried by a parsed document.
pub(all) struct DocumentDiagnostics {
  entries : Array[DocumentDiagnostic]
} derive(Debug, Eq)

///|
/// Compact capability flags exposed by parser backends.
pub(all) struct ParserCapabilities {
  supports_incremental_parsing : Bool
  supports_html_passthrough : Bool
} derive(Debug, Eq)

///|
/// Thin parsed document wrapper that preserves backend identity and payload.
pub(all) struct ParsedDocument {
  backend_name : String
  source_format : @core.SourceFormat
  source_path : String
  source_uuid : String
  diagnostics : DocumentDiagnostics
  backend_payload : String?
} derive(Debug, Eq)

///|
pub impl Show for ParsedDocument with output(self, logger) {
  logger.write_string("ParsedDocument(backend_name=\"")
  logger.write_string(self.backend_name)
  logger.write_string("\", source_path=\"")
  logger.write_string(self.source_path)
  logger.write_string("\")")
}

///|
/// Empty diagnostics helper for parser backends that have nothing to report.
pub fn empty_document_diagnostics() -> DocumentDiagnostics {
  { entries: [] }
}

///|
/// Default capability set for backends that only support basic full parsing.
pub fn default_parser_capabilities() -> ParserCapabilities {
  { supports_incremental_parsing: false, supports_html_passthrough: false }
}

///|
fn format_diagnostic_severity(severity : DiagnosticSeverity) -> String {
  match severity {
    DiagnosticSeverity::Info => "INFO"
    DiagnosticSeverity::Warn => "WARN"
    DiagnosticSeverity::Error => "ERROR"
  }
}

///|
/// Format a single structured parser diagnostic into user-facing text.
pub fn format_document_diagnostic(diagnostic : DocumentDiagnostic) -> String {
  let location = match diagnostic.line {
    Some(line) => " Line \{line},"
    None => ""
  }
  let hint = match diagnostic.hint {
    Some(hint) => " \{hint}"
    None => ""
  }
  "(\{format_diagnostic_severity(diagnostic.severity)})\{location} \{diagnostic.message}\{hint}"
}

///|
/// Format all parser diagnostics into newline-separated user-facing text.
pub fn format_document_diagnostics(diagnostics : DocumentDiagnostics) -> String {
  let lines = []
  for entry in diagnostics.entries {
    lines.push(format_document_diagnostic(entry))
  }
  lines.iter().join("\n")
}
