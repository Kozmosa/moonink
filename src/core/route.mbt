///|
/// Generate a URL route from a source file path based on the configured style.
///
/// Pretty: "guides/intro.md" → "/guides/intro/"
/// Direct: "guides/intro.md" → "/guides/intro.html"
/// index.md → "/" or "/dir/"
pub fn generate_route(source_path : String, style : RouteStyle) -> String {
  let stripped = strip_extension(source_path)
  match style {
    RouteStyle::Pretty =>
      if stripped == "index" {
        "/"
      } else if stripped.has_suffix("/index") {
        let dir = stripped[:stripped.length() - 6].to_string()
        "/\{dir}/"
      } else {
        "/\{stripped}/"
      }
    RouteStyle::Direct => "/\{stripped}.html"
  }
}

///|
fn strip_extension(path : String) -> String {
  if path.has_suffix(".md") {
    path[:path.length() - 3].to_string()
  } else if path.has_suffix(".html") {
    path[:path.length() - 5].to_string()
  } else if path.has_suffix(".htm") {
    path[:path.length() - 4].to_string()
  } else {
    path
  }
}
