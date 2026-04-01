///|
/// Parser-facing document input produced after frontmatter extraction.
pub(all) struct SourceDocumentInput {
  path : String
  format : @core.SourceFormat
  content : String
  uuid : String
} derive(Show, Eq)

///|
/// Structured severity levels for parser diagnostics.
pub(all) enum DiagnosticSeverity {
  Info
  Warn
  Error
} derive(Show, Eq)

///|
/// Single structured parser diagnostic entry.
pub(all) struct DocumentDiagnostic {
  severity : DiagnosticSeverity
  line : Int?
  message : String
  hint : String?
  backend_name : String
} derive(Show, Eq)

///|
/// Diagnostic collection carried by a parsed document.
pub(all) struct DocumentDiagnostics {
  entries : Array[DocumentDiagnostic]
} derive(Show, Eq)

///|
/// Compact capability flags exposed by parser backends.
pub(all) struct ParserCapabilities {
  supports_incremental_parsing : Bool
  supports_html_passthrough : Bool
} derive(Show, Eq)

///|
/// Thin parsed document wrapper that preserves backend identity and payload.
pub(all) struct ParsedDocument {
  backend_name : String
  source_format : @core.SourceFormat
  source_path : String
  source_uuid : String
  diagnostics : DocumentDiagnostics
  backend_payload : String?
} derive(Show, Eq)

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
