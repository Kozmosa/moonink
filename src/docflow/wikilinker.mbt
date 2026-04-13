///|
pub(all) struct WikiLinkScanEntry {
  raw : String
  target : String
  label : String
} derive(Debug, Eq)

///|
fn find_wikilink_close(payload : String, start : Int) -> Int? {
  let mut cursor = start
  while cursor + 1 < payload.length() {
    let segment = payload[cursor:cursor + 2].to_string()
    if segment == "[[" {
      return None
    }
    if segment == "]]" {
      return Some(cursor)
    }
    cursor = cursor + 1
  }
  None
}

///|
fn find_wikilink_rewrite_close(payload : String, start : Int) -> Int? {
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
fn scan_wikilink_entry(payload : String, start : Int) -> WikiLinkScanEntry? {
  let close = find_wikilink_close(payload, start + 2)
  match close {
    Some(close_cursor) => {
      let inner = payload[start + 2:close_cursor].to_string()
      let raw = payload[start:close_cursor + 2].to_string()
      let (target, label) = parse_wikilink_inner(inner)
      Some({ raw, target, label })
    }
    None => None
  }
}

///|
pub fn scan_markdown_wikilinks(payload : String) -> Array[WikiLinkScanEntry] {
  let entries = []
  let mut cursor = 0
  while cursor < payload.length() {
    if cursor + 1 < payload.length() &&
      payload[cursor:cursor + 2].to_string() == "[[" {
      match scan_wikilink_entry(payload, cursor) {
        Some(entry) => {
          entries.push(entry)
          cursor = cursor + entry.raw.length()
        }
        None => cursor = cursor + 2
      }
    } else {
      cursor = cursor + 1
    }
  }
  entries
}

///|
fn append_wikilink_diagnostic(
  parsed : ParsedDocument,
  message : String,
  hint : String?,
) -> ParsedDocument {
  let diagnostics = {
    entries: parsed.diagnostics.entries +
    [
      {
        severity: DiagnosticSeverity::Warn,
        line: None,
        message,
        hint,
        backend_name: parsed.backend_name,
      },
    ],
  }
  { ..parsed, diagnostics, }
}

///|
pub fn parse_wikilink_targets(payload : String) -> Array[String] {
  let targets : Array[String] = []
  let mut cursor = 0
  while cursor < payload.length() {
    if cursor + 1 < payload.length() &&
      payload[cursor:cursor + 2].to_string() == "[[" {
      let close = find_wikilink_close(payload, cursor + 2)
      match close {
        Some(close_cursor) => {
          let inner = payload[cursor + 2:close_cursor].to_string()
          let (target, _) = parse_wikilink_inner(inner)
          if target != "" {
            targets.push(target)
          }
          cursor = close_cursor + 2
        }
        None => cursor = payload.length()
      }
    } else {
      cursor = cursor + 1
    }
  }
  targets
}

///|
pub fn resolve_wikilink(
  linker : WikiLinker,
  target : String,
) -> Result[String, String?] {
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
    if cursor + 1 < payload.length() &&
      payload[cursor:cursor + 2].to_string() == "[[" {
      match find_wikilink_rewrite_close(payload, cursor + 2) {
        Some(close_cursor) => {
          let inner = payload[cursor + 2:close_cursor].to_string()
          let raw = payload[cursor:close_cursor + 2].to_string()
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
/// Collect resolved markdown wikilink targets using the same parser and resolver semantics as apply_wikilinker.
pub fn collect_resolved_wikilink_urls(
  linker : WikiLinker,
  parsed : ParsedDocument,
) -> Array[String] {
  if parsed.source_format != @core.SourceFormat::Markdown {
    return []
  }
  let payload = match parsed.backend_payload {
    Some(payload) => payload
    None => return []
  }
  let urls : Array[String] = []
  let mut cursor = 0
  while cursor < payload.length() {
    if cursor + 1 < payload.length() &&
      payload[cursor:cursor + 2].to_string() == "[[" {
      let close = find_wikilink_close(payload, cursor + 2)
      match close {
        Some(close_cursor) => {
          let inner = payload[cursor + 2:close_cursor].to_string()
          let (target, _) = parse_wikilink_inner(inner)
          if target != "" {
            match resolve_wikilink(linker, target) {
              Ok(url) => urls.push(url)
              Err(_) => ()
            }
          }
          cursor = close_cursor + 2
        }
        None => cursor = payload.length()
      }
    } else {
      cursor = cursor + 1
    }
  }
  urls
}

///|
/// Apply the semantic linker boundary for route-aware markdown wikilinks.
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
