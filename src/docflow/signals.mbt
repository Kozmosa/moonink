///|
fn is_ascii_letter(char : String) -> Bool {
  (char >= "A" && char <= "Z") || (char >= "a" && char <= "z")
}

///|
fn is_ascii_digit(char : String) -> Bool {
  char >= "0" && char <= "9"
}

///|
fn is_whitespace(char : String) -> Bool {
  char == " " || char == "\n" || char == "\r" || char == "\t"
}

///|
fn is_slug_separator(char : String) -> Bool {
  is_whitespace(char) ||
  char == "-" ||
  char == "_" ||
  char == "/" ||
  char == "." ||
  char == ":" ||
  char == "&"
}

///|
fn trim_hyphen_edges(source : String) -> String {
  let mut start = 0
  let mut end = source.length()
  while start < end && source[start:start + 1].to_string() == "-" {
    start += 1
  }
  while end > start && source[end - 1:end].to_string() == "-" {
    end -= 1
  }
  source[start:end].to_string()
}

///|
fn slugify_heading_title(title : String) -> String {
  let builder = StringBuilder::new()
  let mut previous_was_separator = false
  for index in 0..<title.length() {
    let char = title[index:index + 1].to_string()
    if is_ascii_letter(char) || is_ascii_digit(char) {
      builder.write_string(char.to_lower())
      previous_was_separator = false
    } else if is_slug_separator(char) {
      if !previous_was_separator {
        builder.write_string("-")
        previous_was_separator = true
      }
    }
  }
  let normalized = trim_hyphen_edges(builder.to_string())
  if normalized.is_empty() {
    "section"
  } else {
    normalized
  }
}

///|
fn next_heading_id(title : String, seen : Map[String, Int]) -> String {
  let base = slugify_heading_title(title)
  let next_index = match seen.get(base) {
    Some(count) => count + 1
    None => 1
  }
  seen[base] = next_index
  if next_index == 1 {
    base
  } else {
    base + "-" + next_index.to_string()
  }
}

///|
fn markdown_heading_from_line(line : String) -> @core.HeadingEntry? {
  let trimmed = line.trim().to_string()
  if !trimmed.has_prefix("#") {
    return None
  }
  let mut level = 0
  while level < trimmed.length() &&
        trimmed[level:level + 1].to_string() == "#" &&
        level < 6 {
    level += 1
  }
  if level == 0 || level >= trimmed.length() {
    return None
  }
  let separator = trimmed[level:level + 1].to_string()
  if separator != " " && separator != "\t" {
    return None
  }
  let title = trimmed[level + 1:trimmed.length()].trim().to_string()
  if title.is_empty() {
    None
  } else {
    Some({ level, id: "", title })
  }
}

///|
pub fn collect_markdown_headings(source : String) -> Array[@core.HeadingEntry] {
  let headings : Array[@core.HeadingEntry] = []
  let seen : Map[String, Int] = {}
  for line_view in source.split("\n") {
    let line = line_view.to_string()
    match markdown_heading_from_line(line) {
      Some(heading) =>
        headings.push({ ..heading, id: next_heading_id(heading.title, seen) })
      None => ()
    }
  }
  headings
}

///|
fn find_next(source : String, start : Int, needle : String) -> Int? {
  if needle.is_empty() || start < 0 || start >= source.length() {
    return None
  }
  let max = source.length() - needle.length()
  if max < start {
    return None
  }
  for index in start..<=max {
    if source[index:index + needle.length()].to_string() == needle {
      return Some(index)
    }
  }
  None
}

///|
pub fn inject_html_heading_ids(source : String) -> String {
  let output = StringBuilder::new()
  let seen : Map[String, Int] = {}
  let mut cursor = 0
  while cursor < source.length() {
    if cursor + 3 < source.length() &&
      source[cursor:cursor + 2].to_string() == "<h" {
      let level_char = source[cursor + 2:cursor + 3].to_string()
      let is_heading_level = level_char >= "1" && level_char <= "6"
      if is_heading_level {
        match find_next(source, cursor, ">") {
          Some(open_end) => {
            let closing_tag = "</h" + level_char + ">"
            match find_next(source, open_end + 1, closing_tag) {
              Some(close_start) => {
                let attributes = source[cursor + 3:open_end].to_string()
                if attributes.contains(" id=") {
                  output.write_string(
                    source[cursor:close_start + closing_tag.length()].to_string(),
                  )
                  cursor = close_start + closing_tag.length()
                } else {
                  let inner = source[open_end + 1:close_start].to_string()
                  let title = @core.source_plain_text(
                    inner,
                    @core.SourceFormat::Html,
                  )
                  let id = next_heading_id(title, seen)
                  output.write_string("<h")
                  output.write_string(level_char)
                  output.write_string(attributes)
                  output.write_string(" id=\"")
                  output.write_string(id)
                  output.write_string("\">")
                  output.write_string(inner)
                  output.write_string(closing_tag)
                  cursor = close_start + closing_tag.length()
                }
              }
              None => {
                output.write_string(source[cursor:].to_string())
                cursor = source.length()
              }
            }
          }
          None => {
            output.write_string(source[cursor:].to_string())
            cursor = source.length()
          }
        }
      } else {
        output.write_string(source[cursor:cursor + 1].to_string())
        cursor += 1
      }
    } else {
      output.write_string(source[cursor:cursor + 1].to_string())
      cursor += 1
    }
  }
  output.to_string()
}
