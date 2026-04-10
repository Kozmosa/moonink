///|
fn find_wikilink_close(payload : String, start : Int) -> Int? {
  let mut cursor = start
  while cursor + 1 < payload.length() {
    if payload[cursor:cursor + 2].to_string() == "]]" {
      return Some(cursor)
    }
    cursor = cursor + 1
  }
  None
}

///|
fn normalize_wikilink_target(target : String) -> String {
  let trimmed = target.trim().to_string()
  if trimmed.has_prefix("./") {
    trimmed[2:].to_string()
  } else {
    trimmed
  }
}

///|
fn parse_wikilink_inner(inner : String) -> (String, String) {
  match inner.split_once("|") {
    Some((target_view, label_view)) => {
      let target = normalize_wikilink_target(target_view.to_string())
      let raw_label = label_view.trim().to_string()
      let label = if raw_label == "" { target } else { raw_label }
      (target, label)
    }
    None => {
      let target = normalize_wikilink_target(inner)
      (target, target)
    }
  }
}

///|
fn append_wikilink_diagnostic(
  parsed : ParsedDocument,
  message : String,
  hint : String?,
) -> ParsedDocument {
  let diagnostics = {
    entries: parsed.diagnostics.entries + [{
      severity: DiagnosticSeverity::Warn,
      line: None,
      message,
      hint,
      backend_name: parsed.backend_name,
    }],
  }
  { ..parsed, diagnostics }
}

///|
fn resolve_wikilink(linker : WikiLinker, target : String) -> Result[String, String?] {
  match linker.exact_targets.get(target) {
    Some(url) => Ok(url)
    None =>
      match linker.ambiguous_targets.get(target) {
        Some(candidates) => {
          let joined = candidates.iter().join(", ")
          Err(Some("Ambiguous wikilink target with candidates: \{joined}"))
        }
        None => Err(None)
      }
  }
}

///|
fn rewrite_markdown_wikilinks(
  linker : WikiLinker,
  parsed : ParsedDocument,
  payload : String,
) -> ParsedDocument {
  let result = StringBuilder::new()
  let mut cursor = 0
  let mut linked = parsed
  while cursor < payload.length() {
    if cursor + 1 < payload.length() && payload[cursor:cursor + 2].to_string() == "[[" {
      let close = find_wikilink_close(payload, cursor + 2)
      match close {
        Some(close_cursor) => {
          let inner = payload[cursor + 2:close_cursor].to_string()
          let raw = "[[\{inner}]]"
          let (target, label) = parse_wikilink_inner(inner)
          if target == "" {
            result.write_string(raw)
          } else {
            match resolve_wikilink(linker, target) {
              Ok(url) => result.write_string("[\{label}](\{url})")
              Err(Some(hint)) => {
                result.write_string(raw)
                linked = append_wikilink_diagnostic(
                  linked,
                  "Ambiguous wikilink target: \{target}",
                  Some(hint),
                )
              }
              Err(None) => {
                result.write_string(raw)
                linked = append_wikilink_diagnostic(
                  linked,
                  "Unresolved wikilink target: \{target}",
                  None,
                )
              }
            }
          }
          cursor = close_cursor + 2
        }
        None => {
          result.write_string(payload[cursor:].to_string())
          cursor = payload.length()
        }
      }
    } else {
      result.write_char(payload.unsafe_get(cursor).unsafe_to_char())
      cursor = cursor + 1
    }
  }
  { ..linked, backend_payload: Some(result.to_string()) }
}

///|
/// Apply the semantic linker boundary. The default stage is an explicit no-op.
/// Future implementation will handle Obsidian-compatible [[wikilink]] resolution.
pub fn apply_wikilinker(
  linker : WikiLinker,
  parsed : ParsedDocument,
) -> ParsedDocument {
  match parsed.source_format {
    @core.SourceFormat::Markdown =>
      match parsed.backend_payload {
        Some(payload) => rewrite_markdown_wikilinks(linker, parsed, payload)
        None => parsed
      }
    _ => parsed
  }
}
