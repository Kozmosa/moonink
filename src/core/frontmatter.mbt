///|
/// Parsed frontmatter from a markdown file's YAML front matter.
pub(all) struct Frontmatter {
  title : String?
  description : String?
  content_type : String?
  date : String?
  tags : Array[String]
  draft : Bool
  extra : Map[String, String]
} derive(Show, Eq)

///|
pub fn Frontmatter::default() -> Frontmatter {
  {
    title: None,
    description: None,
    content_type: None,
    date: None,
    tags: [],
    draft: false,
    extra: {},
  }
}

///|
/// Find the byte offset of a substring in a string. Returns None if not found.
fn find_substring(haystack : String, needle : String) -> Int? {
  let h_len = haystack.length()
  let n_len = needle.length()
  if n_len > h_len {
    return None
  }
  for i in 0..<=(h_len - n_len) {
    let slice = haystack[i:i + n_len].to_string()
    if slice == needle {
      return Some(i)
    }
  }
  None
}

///|
/// Extract the raw frontmatter YAML block and the remaining body from a
/// markdown source string. Returns `(frontmatter_yaml, body)`.
pub fn extract_frontmatter_raw(source : String) -> (String?, String) {
  let trimmed = source.trim().to_string()
  if !trimmed.has_prefix("---") {
    return (None, source)
  }
  // Find the closing ---
  let after_open = trimmed[3:].to_string()
  match find_substring(after_open, "---") {
    Some(end_pos) => {
      let yaml_block = after_open[:end_pos].to_string().trim().to_string()
      let body = after_open[end_pos + 3:].to_string().trim().to_string()
      (Some(yaml_block), body)
    }
    None => (None, source)
  }
}

///|
/// Parse a simple YAML-like key-value frontmatter block into a Frontmatter struct.
/// Supports: `key: value`, `key: "quoted value"`, `key: [a, b, c]`, `key: true/false`.
pub fn parse_frontmatter(yaml : String) -> Frontmatter {
  let fields : Map[String, String] = {}
  let list_fields : Map[String, Array[String]] = {}
  for line_view in yaml.split("\n") {
    let line = line_view.to_string().trim().to_string()
    if line.is_empty() || line.has_prefix("#") {
      continue
    }
    match line.split_once(":") {
      Some((key_view, value_view)) => {
        let key = key_view.trim().to_string()
        let value = value_view.trim().to_string()
        if key.is_empty() {
          continue
        }
        // Check for list values: [a, b, c]
        if value.has_prefix("[") && value.has_suffix("]") {
          let inner = value[1:value.length() - 1].to_string()
          let items : Array[String] = []
          for item_view in inner.split(",") {
            let item = item_view.trim().to_string()
            // Strip quotes
            let clean = if item.length() >= 2 &&
              item.has_prefix("\"") &&
              item.has_suffix("\"") {
              item[1:item.length() - 1].to_string()
            } else {
              item
            }
            if !clean.is_empty() {
              items.push(clean)
            }
          }
          list_fields[key] = items
        } else {
          // Strip optional surrounding quotes
          let clean = if value.length() >= 2 &&
            value.has_prefix("\"") &&
            value.has_suffix("\"") {
            value[1:value.length() - 1].to_string()
          } else {
            value
          }
          fields[key] = clean
        }
      }
      None => ()
    }
  }
  let title = fields.get("title")
  let description = fields.get("description")
  let content_type = fields.get("type")
  let date = fields.get("date")
  let tags = match list_fields.get("tags") {
    Some(t) => t
    None => []
  }
  let draft = match fields.get("draft") {
    Some("true") => true
    _ => false
  }
  // Collect remaining fields into extra
  let core_keys : Array[String] = [
    "title", "description", "type", "date", "draft",
  ]
  let extra : Map[String, String] = {}
  for entry in fields {
    let (key, value) = entry
    if core_keys.search_by(k => k == key) is None && key != "tags" {
      extra[key] = value
    }
  }
  { title, description, content_type, date, tags, draft, extra }
}

///|
/// Parse frontmatter from the full source of a markdown file.
pub fn parse_frontmatter_from_source(source : String) -> (Frontmatter, String) {
  let (yaml, body) = extract_frontmatter_raw(source)
  match yaml {
    Some(y) => (parse_frontmatter(y), body)
    None => (Frontmatter::default(), source)
  }
}
