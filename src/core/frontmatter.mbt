///|
/// Parsed frontmatter from a markdown file's YAML front matter.
pub(all) enum FrontmatterFieldShape {
  Scalar
  List
} derive(Debug, Eq)

///|
pub impl Show for FrontmatterFieldShape with output(self, logger) {
  match self {
    Scalar => logger.write_string("Scalar")
    List => logger.write_string("List")
  }
}

///|
pub(all) struct Frontmatter {
  title : String?
  description : String?
  content_type : String?
  date : String?
  tags : Array[String]
  draft : Bool
  layout : String?
  theme_meta : Map[String, ThemeConfigValue]
  extra : Map[String, String]
  field_shapes : Map[String, FrontmatterFieldShape]
  invalid_scalar_fields : Map[String, Bool]
} derive(Debug, Eq)

///|
pub fn Frontmatter::default() -> Frontmatter {
  {
    title: None,
    description: None,
    content_type: None,
    date: None,
    tags: [],
    draft: false,
    layout: None,
    theme_meta: {},
    extra: {},
    field_shapes: {},
    invalid_scalar_fields: {},
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
fn theme_meta_key(key : String) -> String? {
  if !key.has_prefix("theme_") {
    return None
  }
  let normalized = key[6:key.length()].to_string()
  if normalized.is_empty() {
    None
  } else {
    Some(normalized)
  }
}

///|
fn theme_meta_from_json(value : Json) -> ThemeConfigValue {
  match value {
    Null => ThemeConfigValue::NullValue
    True => ThemeConfigValue::BoolValue(true)
    False => ThemeConfigValue::BoolValue(false)
    Number(_, repr~) =>
      ThemeConfigValue::NumberValue(
        match repr {
          Some(repr) => repr
          None => value.stringify()
        },
      )
    String(text) => ThemeConfigValue::StringValue(text)
    Array(values) => {
      let items : Array[ThemeConfigValue] = []
      for entry in values {
        items.push(theme_meta_from_json(entry))
      }
      ThemeConfigValue::ArrayValue(items)
    }
    Object(entries) => {
      let items : Map[String, ThemeConfigValue] = {}
      for entry in entries {
        let (key, item) = entry
        items[key] = theme_meta_from_json(item)
      }
      ThemeConfigValue::ObjectValue(items)
    }
  }
}

///|
fn theme_meta_value(
  raw_value : String,
  fallback_value : String,
) -> ThemeConfigValue {
  let normalized = raw_value.trim().to_string()
  if normalized.is_empty() {
    return ThemeConfigValue::StringValue(fallback_value)
  }
  let value = @json.parse(normalized.view()) catch {
    _ => return ThemeConfigValue::StringValue(fallback_value)
  }
  theme_meta_from_json(value)
}

///|
fn theme_meta_scalar_value(
  raw_value : String,
  value : String,
) -> ThemeConfigValue {
  theme_meta_value(raw_value, value)
}

///|
fn theme_meta_list_value(
  raw_values : Array[String],
  values : Array[String],
) -> ThemeConfigValue {
  let items : Array[ThemeConfigValue] = []
  for index in 0..<values.length() {
    items.push(theme_meta_value(raw_values[index], values[index]))
  }
  ThemeConfigValue::ArrayValue(items)
}

///|
/// Parse a simple YAML-like key-value frontmatter block into a Frontmatter struct.
/// Supports: `key: value`, `key: "quoted value"`, `key: [a, b, c]`, `key: true/false`.
pub fn parse_frontmatter(yaml : String) -> Frontmatter {
  let fields : Map[String, String] = {}
  let raw_fields : Map[String, String] = {}
  let list_fields : Map[String, Array[String]] = {}
  let raw_list_fields : Map[String, Array[String]] = {}
  let field_shapes : Map[String, FrontmatterFieldShape] = {}
  let invalid_scalar_fields : Map[String, Bool] = {}
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
          let raw_items : Array[String] = []
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
              raw_items.push(item)
            }
          }
          list_fields[key] = items
          raw_list_fields[key] = raw_items
          field_shapes[key] = FrontmatterFieldShape::List
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
          raw_fields[key] = value
          field_shapes[key] = FrontmatterFieldShape::Scalar
          if key == "draft" && clean != "true" && clean != "false" {
            invalid_scalar_fields[key] = true
          }
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
  let layout = fields.get("layout")
  let theme_meta : Map[String, ThemeConfigValue] = {}
  for entry in raw_fields {
    let (key, raw_value) = entry
    match theme_meta_key(key) {
      Some(theme_key) =>
        match fields.get(key) {
          Some(value) =>
            theme_meta[theme_key] = theme_meta_scalar_value(raw_value, value)
          None => ()
        }
      None => ()
    }
  }
  for entry in raw_list_fields {
    let (key, raw_values) = entry
    match theme_meta_key(key) {
      Some(theme_key) =>
        match list_fields.get(key) {
          Some(values) =>
            theme_meta[theme_key] = theme_meta_list_value(raw_values, values)
          None => ()
        }
      None => ()
    }
  }
  // Collect remaining fields into extra
  let core_keys : Array[String] = [
    "title", "description", "type", "date", "draft", "layout",
  ]
  let extra : Map[String, String] = {}
  for entry in fields {
    let (key, value) = entry
    if core_keys.search_by(k => k == key) is None &&
      key != "tags" &&
      theme_meta_key(key) is None {
      extra[key] = value
    }
  }
  {
    title,
    description,
    content_type,
    date,
    tags,
    draft,
    layout,
    theme_meta,
    extra,
    field_shapes,
    invalid_scalar_fields,
  }
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
