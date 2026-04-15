///|
/// Search index entry used by static search consumers.
pub(all) struct SearchIndexItem {
  title : String
  url : String
  excerpt : String
  tags : Array[String]
  date : String?
} derive(Debug, Eq)

///|
/// Search index document emitted as compact JSON.
pub(all) struct SearchIndexDocument {
  version : Int
  generated_at : String
  items : Array[SearchIndexItem]
} derive(Debug, Eq)

///|
fn is_whitespace(char : String) -> Bool {
  char == " " || char == "\n" || char == "\r" || char == "\t"
}

///|
fn collapse_whitespace(source : String) -> String {
  let result = StringBuilder::new()
  let mut previous_was_space = false
  for i in 0..<source.length() {
    let char = source[i:i + 1].to_string()
    if is_whitespace(char) {
      if !previous_was_space {
        result.write_string(" ")
        previous_was_space = true
      }
    } else {
      result.write_string(char)
      previous_was_space = false
    }
  }
  result.to_string().trim().to_string()
}

///|
fn strip_html_tags(source : String) -> String {
  let result = StringBuilder::new()
  let mut in_tag = false
  for i in 0..<source.length() {
    let char = source[i:i + 1].to_string()
    if char == "<" {
      in_tag = true
      result.write_string(" ")
    } else if char == ">" {
      in_tag = false
      result.write_string(" ")
    } else if !in_tag {
      result.write_string(char)
    }
  }
  collapse_whitespace(result.to_string())
}

///|
fn strip_markdown_markers(source : String) -> String {
  let result = StringBuilder::new()
  for i in 0..<source.length() {
    let char = source[i:i + 1].to_string()
    if char == "#" || char == "*" || char == "_" || char == "`" ||
      char == ">" || char == "[" || char == "]" || char == "(" ||
      char == ")" || char == "!" {
      result.write_string(" ")
    } else {
      result.write_string(char)
    }
  }
  collapse_whitespace(result.to_string())
}

///|
fn normalize_excerpt(source : String) -> String {
  collapse_whitespace(source)
}

///|
pub fn search_index_excerpt(
  frontmatter_excerpt : String?,
  source : String,
  format : SourceFormat,
) -> String {
  match frontmatter_excerpt {
    Some(excerpt) => {
      let normalized = normalize_excerpt(excerpt)
      if !normalized.is_empty() {
        return normalized
      }
    }
    None => ()
  }
  match format {
    SourceFormat::Markdown => strip_markdown_markers(source)
    SourceFormat::Html => strip_html_tags(source)
    SourceFormat::Unknown => normalize_excerpt(source)
  }
}

///|
fn escape_json_string(source : String) -> String {
  let result = StringBuilder::new()
  for i in 0..<source.length() {
    let char = source[i:i + 1].to_string()
    if char == "\\" {
      result.write_string("\\\\")
    } else if char == "\"" {
      result.write_string("\\\"")
    } else if char == "\n" {
      result.write_string("\\n")
    } else if char == "\r" {
      result.write_string("\\r")
    } else if char == "\t" {
      result.write_string("\\t")
    } else {
      result.write_string(char)
    }
  }
  result.to_string()
}

///|
fn append_json_string(builder : StringBuilder, source : String) -> Unit {
  builder.write_string("\"")
  builder.write_string(escape_json_string(source))
  builder.write_string("\"")
}

///|
fn append_json_string_array(builder : StringBuilder, items : Array[String]) -> Unit {
  builder.write_string("[")
  for index in 0..<items.length() {
    if index > 0 {
      builder.write_string(",")
    }
    append_json_string(builder, items[index])
  }
  builder.write_string("]")
}

///|
fn append_json_nullable_string(
  builder : StringBuilder,
  value : String?,
) -> Unit {
  match value {
    Some(text) => append_json_string(builder, text)
    None => builder.write_string("null")
  }
}

///|
fn append_search_index_item_json(
  builder : StringBuilder,
  item : SearchIndexItem,
) -> Unit {
  builder.write_string("{\"title\":")
  append_json_string(builder, item.title)
  builder.write_string(",\"url\":")
  append_json_string(builder, item.url)
  builder.write_string(",\"excerpt\":")
  append_json_string(builder, item.excerpt)
  builder.write_string(",\"tags\":")
  append_json_string_array(builder, item.tags)
  builder.write_string(",\"date\":")
  append_json_nullable_string(builder, item.date)
  builder.write_string("}")
}

///|
pub fn search_index_document_to_json(document : SearchIndexDocument) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{\"version\":")
  builder.write_string(document.version.to_string())
  builder.write_string(",\"generated_at\":")
  append_json_string(builder, document.generated_at)
  builder.write_string(",\"items\":[")
  for index in 0..<document.items.length() {
    if index > 0 {
      builder.write_string(",")
    }
    append_search_index_item_json(builder, document.items[index])
  }
  builder.write_string("]}")
  builder.to_string()
}
