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
fn resolve_wikilink(
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
fn find_embed_open(payload : String, cursor : Int) -> Bool {
  cursor + 2 < payload.length() &&
  payload[cursor:cursor + 3].to_string() == "![["
}

///|
fn is_image_resource_target(target : String) -> Bool {
  target.has_suffix(".png") ||
  target.has_suffix(".jpg") ||
  target.has_suffix(".jpeg") ||
  target.has_suffix(".gif") ||
  target.has_suffix(".svg") ||
  target.has_suffix(".webp")
}

///|
fn resolve_resource_target(
  linker : WikiLinker,
  target : String,
) -> Result[String, String?] {
  match linker.resource_targets.get(target) {
    Some(url) => Ok(url)
    None =>
      match linker.ambiguous_resource_targets.get(target) {
        Some(candidates) => {
          let joined = candidates.iter().join(", ")
          Err(Some("Ambiguous resource target with candidates: \{joined}"))
        }
        None => Err(None)
      }
  }
}

///|
fn looks_like_resource_target(target : String) -> Bool {
  target.contains(".")
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
    if find_embed_open(payload, cursor) {
      let close = find_wikilink_close(payload, cursor + 3)
      match close {
        Some(close_cursor) => {
          let inner = payload[cursor + 3:close_cursor].to_string()
          let raw = "![[\{inner}]]"
          let (target, label) = parse_wikilink_inner(inner)
          if target == "" {
            result.write_string(raw)
          } else {
            match resolve_resource_target(linker, target) {
              Ok(url) =>
                if is_image_resource_target(target) {
                  result.write_string("![")
                  result.write_string(label)
                  result.write_string("](")
                  result.write_string(url)
                  result.write_string(")")
                } else {
                  result.write_string("[")
                  result.write_string(label)
                  result.write_string("](")
                  result.write_string(url)
                  result.write_string(")")
                }
              Err(Some(hint)) => {
                result.write_string(raw)
                linked = append_wikilink_diagnostic(
                  linked,
                  "Ambiguous resource target: \{target}",
                  Some(hint),
                )
              }
              Err(None) => {
                result.write_string(raw)
                linked = append_wikilink_diagnostic(
                  linked,
                  "Unresolved resource target: \{target}",
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
    } else if cursor + 1 < payload.length() &&
      payload[cursor:cursor + 2].to_string() == "[[" {
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
              Err(None) =>
                match resolve_resource_target(linker, target) {
                  Ok(url) => result.write_string("[\{label}](\{url})")
                  Err(Some(hint)) => {
                    result.write_string(raw)
                    linked = append_wikilink_diagnostic(
                      linked,
                      "Ambiguous resource target: \{target}",
                      Some(hint),
                    )
                  }
                  Err(None) => {
                    result.write_string(raw)
                    linked = append_wikilink_diagnostic(
                      linked,
                      if looks_like_resource_target(target) {
                        "Unresolved resource target: \{target}"
                      } else {
                        "Unresolved wikilink target: \{target}"
                      },
                      None,
                    )
                  }
                }
              Err(Some(hint)) => {
                result.write_string(raw)
                linked = append_wikilink_diagnostic(
                  linked,
                  "Ambiguous wikilink target: \{target}",
                  Some(hint),
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
fn find_line_start(payload : String, cursor : Int) -> Int {
  let mut index = cursor
  while index > 0 {
    if payload[index - 1:index].to_string() == "\n" {
      return index
    }
    index -= 1
  }
  0
}

///|
fn find_line_end(payload : String, cursor : Int) -> Int {
  let mut index = cursor
  while index < payload.length() {
    if payload[index:index + 1].to_string() == "\n" {
      return index
    }
    index += 1
  }
  payload.length()
}

///|
fn replace_wikilinks_with_labels(source : String) -> String {
  let output = StringBuilder::new()
  let mut cursor = 0
  while cursor < source.length() {
    if find_embed_open(source, cursor) {
      match find_wikilink_close(source, cursor + 3) {
        Some(close_cursor) => {
          let inner = source[cursor + 3:close_cursor].to_string()
          let (_, label) = parse_wikilink_inner(inner)
          output.write_string(label)
          cursor = close_cursor + 2
        }
        None => {
          output.write_string(source[cursor:].to_string())
          cursor = source.length()
        }
      }
    } else if cursor + 1 < source.length() &&
      source[cursor:cursor + 2].to_string() == "[[" {
      match find_wikilink_close(source, cursor + 2) {
        Some(close_cursor) => {
          let inner = source[cursor + 2:close_cursor].to_string()
          let (_, label) = parse_wikilink_inner(inner)
          output.write_string(label)
          cursor = close_cursor + 2
        }
        None => {
          output.write_string(source[cursor:].to_string())
          cursor = source.length()
        }
      }
    } else {
      output.write_char(source.unsafe_get(cursor).unsafe_to_char())
      cursor += 1
    }
  }
  output.to_string()
}

///|
fn clip_snippet(source : String, max_length : Int) -> String {
  if source.length() <= max_length {
    return source
  }
  let mut end = max_length
  while end > 0 && source[end - 1:end].to_string() != " " {
    end -= 1
  }
  let clipped = if end <= 0 {
    source[:max_length].to_string()
  } else {
    source[:end].to_string().trim().to_string()
  }
  if clipped.is_empty() {
    source[:max_length].to_string()
  } else {
    clipped + "..."
  }
}

///|
fn mention_snippet(payload : String, cursor : Int) -> String {
  let line_start = find_line_start(payload, cursor)
  let line_end = find_line_end(payload, cursor)
  let line = payload[line_start:line_end].to_string()
  let text = @core.source_plain_text(
    replace_wikilinks_with_labels(line),
    @core.SourceFormat::Markdown,
  )
  clip_snippet(text, 160)
}

///|
fn collect_resolved_wikilink_targets_from_payload(
  linker : WikiLinker,
  payload : String,
) -> Array[String] {
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
            match resolve_wikilink(linker, target) {
              Ok(url) => targets.push(url)
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
  targets
}

///|
fn collect_resolved_wikilink_mentions_from_payload(
  linker : WikiLinker,
  payload : String,
) -> Array[ResolvedWikilinkMention] {
  let mentions : Array[ResolvedWikilinkMention] = []
  let mut cursor = 0
  while cursor < payload.length() {
    if cursor + 1 < payload.length() &&
      payload[cursor:cursor + 2].to_string() == "[[" {
      match find_wikilink_close(payload, cursor + 2) {
        Some(close_cursor) => {
          let inner = payload[cursor + 2:close_cursor].to_string()
          let (target, label) = parse_wikilink_inner(inner)
          if target != "" {
            match resolve_wikilink(linker, target) {
              Ok(url) =>
                mentions.push({
                  target_url: url,
                  label,
                  snippet: mention_snippet(payload, cursor),
                  is_embed: false,
                })
              Err(_) => ()
            }
          }
          cursor = close_cursor + 2
        }
        None => cursor = payload.length()
      }
    } else {
      cursor += 1
    }
  }
  mentions
}

///|
/// Collect resolved WikiLink destinations without inspecting rendered markdown links.
pub fn collect_resolved_wikilink_targets(
  linker : WikiLinker,
  parsed : ParsedDocument,
) -> Array[String] {
  match parsed.source_format {
    @core.SourceFormat::Markdown =>
      match parsed.backend_payload {
        Some(payload) =>
          collect_resolved_wikilink_targets_from_payload(linker, payload)
        None => []
      }
    _ => []
  }
}

///|
pub fn collect_resolved_wikilink_mentions(
  linker : WikiLinker,
  parsed : ParsedDocument,
) -> Array[ResolvedWikilinkMention] {
  match parsed.source_format {
    @core.SourceFormat::Markdown =>
      match parsed.backend_payload {
        Some(payload) =>
          collect_resolved_wikilink_mentions_from_payload(linker, payload)
        None => []
      }
    _ => []
  }
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
