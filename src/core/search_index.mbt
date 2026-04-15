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
fn is_ascii_lowercase_letter(char : String) -> Bool {
  char >= "a" && char <= "z"
}

///|
fn is_ascii_letter(char : String) -> Bool {
  (char >= "A" && char <= "Z") || is_ascii_lowercase_letter(char)
}

///|
fn is_ascii_digit(char : String) -> Bool {
  char >= "0" && char <= "9"
}

///|
fn is_word_char(char : String) -> Bool {
  is_ascii_letter(char) || is_ascii_digit(char)
}

///|
fn char_at(source : String, index : Int) -> String {
  source[index:index + 1].to_string()
}

///|
fn is_line_start(source : String, index : Int) -> Bool {
  index == 0 || char_at(source, index - 1) == "\n"
}

///|
fn is_markdown_emphasis_marker(source : String, index : Int) -> Bool {
  let char = char_at(source, index)
  if char != "*" && char != "_" && char != "`" {
    return false
  }
  let previous_is_word =
    index > 0 && is_word_char(char_at(source, index - 1))
  let next_is_word =
    index + 1 < source.length() && is_word_char(char_at(source, index + 1))
  !(previous_is_word && next_is_word)
}

///|
fn html_tag_end(source : String, start : Int) -> Int? {
  if start + 1 >= source.length() {
    return None
  }
  let next = char_at(source, start + 1)
  let mut cursor = start + 1
  if next == "/" {
    cursor += 1
    if cursor >= source.length() || !is_ascii_letter(char_at(source, cursor)) {
      return None
    }
  } else if next == "!" {
    cursor += 1
    if cursor >= source.length() {
      return None
    }
    let bang_next = char_at(source, cursor)
    if bang_next == "-" {
      if cursor + 1 >= source.length() || char_at(source, cursor + 1) != "-" {
        return None
      }
      cursor += 2
    } else if !is_ascii_letter(bang_next) {
      return None
    }
  } else if !is_ascii_lowercase_letter(next) {
    return None
  }
  for i in cursor..<source.length() {
    if char_at(source, i) == ">" {
      return Some(i)
    }
  }
  None
}

///|
fn strip_markdown_link(source : String, start : Int) -> (String, Int)? {
  let mut label_start = start
  if char_at(source, start) == "!" {
    if start + 1 >= source.length() || char_at(source, start + 1) != "[" {
      return None
    }
    label_start = start + 1
  }
  if char_at(source, label_start) != "[" {
    return None
  }
  let mut label_end = label_start + 1
  while label_end < source.length() && char_at(source, label_end) != "]" {
    label_end += 1
  }
  if label_end >= source.length() || label_end + 1 >= source.length() ||
    char_at(source, label_end + 1) != "(" {
    return None
  }
  let mut url_end = label_end + 2
  while url_end < source.length() && char_at(source, url_end) != ")" {
    url_end += 1
  }
  if url_end >= source.length() {
    return None
  }
  Some((source[label_start + 1:label_end].to_string(), url_end + 1))
}

///|
fn trim_space_before_punctuation(source : String) -> String {
  let result = StringBuilder::new()
  for i in 0..<source.length() {
    let char = char_at(source, i)
    let next_is_punctuation =
      i + 1 < source.length() &&
      (char_at(source, i + 1) == "." || char_at(source, i + 1) == "," ||
      char_at(source, i + 1) == ":" || char_at(source, i + 1) == ";" ||
      char_at(source, i + 1) == "!" || char_at(source, i + 1) == "?" ||
      char_at(source, i + 1) == ")")
    if char == " " && next_is_punctuation {
      continue
    }
    result.write_string(char)
  }
  result.to_string()
}

///|
fn strip_html_tags(source : String) -> String {
  let result = StringBuilder::new()
  let mut index = 0
  while index < source.length() {
    let char = char_at(source, index)
    if char == "<" {
      match html_tag_end(source, index) {
        Some(tag_end) => {
          result.write_string(" ")
          index = tag_end + 1
        }
        None => {
          result.write_string(char)
          index += 1
        }
      }
    } else {
      result.write_string(char)
      index += 1
    }
  }
  trim_space_before_punctuation(collapse_whitespace(result.to_string()))
}

///|
fn strip_markdown_markers(source : String) -> String {
  let result = StringBuilder::new()
  let mut index = 0
  while index < source.length() {
    match strip_markdown_link(source, index) {
      Some((label, next_index)) => {
        result.write_string(label)
        result.write_string(" ")
        index = next_index
      }
      None => {
        let char = char_at(source, index)
        if char == "#" && is_line_start(source, index) {
          result.write_string(" ")
        } else if char == ">" && is_line_start(source, index) {
          result.write_string(" ")
        } else if is_markdown_emphasis_marker(source, index) {
          result.write_string(" ")
        } else {
          result.write_string(char)
        }
        index += 1
      }
    }
  }
  trim_space_before_punctuation(collapse_whitespace(result.to_string()))
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
