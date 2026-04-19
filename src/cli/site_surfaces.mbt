///|
fn strip_surface_source_extension(path : String) -> String {
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

///|
fn top_level_source_segment(source_path : String) -> String {
  match source_path.split_once("/") {
    Some((segment, _)) => strip_surface_source_extension(segment.to_string())
    None => strip_surface_source_extension(source_path)
  }
}

///|
fn generated_virtual_source(root : String) -> String {
  root + "/index.md"
}

///|
fn generated_surface_route(
  config : @core.MooninkConfig,
  root : String,
) -> String {
  @core.generate_route(generated_virtual_source(root), config.route_style)
}

///|
fn generated_page_for_root(
  root : String,
  kind : String,
  title : String,
  summary : String,
  description : String,
  layout_key : String,
  body_html : String,
  style : @core.RouteStyle,
) -> @core.GeneratedPage {
  generated_page_for_root_with_extras(
    root, kind, title, summary, description, layout_key, body_html, style, "", "",
  )
}

///|
fn generated_page_for_root_with_extras(
  root : String,
  kind : String,
  title : String,
  summary : String,
  description : String,
  layout_key : String,
  body_html : String,
  style : @core.RouteStyle,
  head_html : String,
  scripts_html : String,
) -> @core.GeneratedPage {
  let virtual_source = generated_virtual_source(root)
  {
    kind,
    title,
    summary,
    description,
    source_path: "@generated/" + virtual_source,
    url_path: @core.generate_route(virtual_source, style),
    output_path: @core.output_html_path(virtual_source, style),
    layout_key,
    body_html,
    head_html,
    scripts_html,
  }
}

///|
struct OutputTarget {
  output_path : String
  source_path : String
} derive(Debug, Eq)

///|
fn homepage_config_error(path : String, message : String) -> BuildCommandError {
  BuildCommandError::ProjectIO(@core.project_io_error("build", path, message))
}

///|
fn normalize_homepage_featured_path(
  path : String,
) -> String raise BuildCommandError {
  @core.normalize_relative_path(path) catch {
    err =>
      raise homepage_config_error(
        path,
        "homepage.featured_paths entry is invalid: " +
        @core.format_path_policy_error(err),
      )
  }
}

///|
fn validate_reserved_generated_roots(
  inputs : Array[@runtime.BuildInput],
) -> Unit raise BuildCommandError {
  let reserved = ["search", "tags", "series", "archive"]
  for input in inputs {
    let segment = top_level_source_segment(input.meta.source_path)
    if reserved.search_by(fn(value) { value == segment }) is Some(_) {
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "build",
          input.meta.source_path,
          "reserved generated root: " + segment,
        ),
      )
    }
  }
}

///|
fn theme_object_field(
  entries : Map[String, @core.ThemeConfigValue],
  key : String,
) -> Map[String, @core.ThemeConfigValue]? {
  match entries.get(key) {
    Some(@core.ThemeConfigValue::ObjectValue(value)) => Some(value)
    _ => None
  }
}

///|
fn theme_string_field(
  entries : Map[String, @core.ThemeConfigValue],
  key : String,
) -> String? {
  match entries.get(key) {
    Some(@core.ThemeConfigValue::StringValue(value)) => Some(value)
    _ => None
  }
}

///|
fn parse_decimal_int(source : String) -> Int? {
  let trimmed = source.trim().to_string()
  if trimmed.is_empty() {
    return None
  }
  let mut value = 0
  for i in 0..<trimmed.length() {
    let char = trimmed[i:i + 1].to_string()
    let digit = match char {
      "0" => 0
      "1" => 1
      "2" => 2
      "3" => 3
      "4" => 4
      "5" => 5
      "6" => 6
      "7" => 7
      "8" => 8
      "9" => 9
      _ => return None
    }
    value = value * 10 + digit
  }
  Some(value)
}

///|
fn theme_number_field(
  entries : Map[String, @core.ThemeConfigValue],
  key : String,
) -> Int? {
  match entries.get(key) {
    Some(@core.ThemeConfigValue::NumberValue(value)) => parse_decimal_int(value)
    Some(@core.ThemeConfigValue::StringValue(value)) => parse_decimal_int(value)
    _ => None
  }
}

///|
fn theme_string_list_field(
  entries : Map[String, @core.ThemeConfigValue],
  key : String,
) -> Array[String] {
  match entries.get(key) {
    Some(@core.ThemeConfigValue::ArrayValue(values)) => {
      let items : Array[String] = []
      for value in values {
        match value {
          @core.ThemeConfigValue::StringValue(text) => items.push(text)
          _ => ()
        }
      }
      items
    }
    _ => []
  }
}

///|
fn homepage_config(
  config : @core.MooninkConfig,
) -> (String?, String?, Array[String], Int) {
  let homepage = match theme_object_field(config.theme_config, "homepage") {
    Some(value) => value
    None => return (None, None, [], 4)
  }
  (
    theme_string_field(homepage, "hero_title"),
    theme_string_field(homepage, "hero_summary"),
    theme_string_list_field(homepage, "featured_paths"),
    match theme_number_field(homepage, "recent_count") {
      Some(value) if value > 0 => value
      _ => 4
    },
  )
}

///|
fn find_page_by_source_path(
  pages : Array[@core.SitePage],
  source_path : String,
) -> @core.SitePage? {
  for page in pages {
    if page.source_path == source_path {
      return Some(page)
    }
  }
  None
}

///|
fn source_path_in_list(paths : Array[String], target : String) -> Bool {
  paths.search_by(fn(path) { path == target }) is Some(_)
}

///|
fn render_surface_card(page : @core.SitePage) -> String {
  let meta_parts : Array[String] = []
  match page.date {
    Some(date) => meta_parts.push(escape_html_text(date))
    None => ()
  }
  match page.series {
    Some(series_name) => meta_parts.push(escape_html_text(series_name))
    None => ()
  }
  let meta_html = if meta_parts.is_empty() {
    ""
  } else {
    "<p class=\"surface-card-meta\">" + meta_parts.iter().join(" · ") + "</p>"
  }
  let summary_html = if page.summary == "" {
    ""
  } else {
    "<p>" + escape_html_text(page.summary) + "</p>"
  }
  let author_html = match page.author {
    Some(author) =>
      "<p class=\"surface-card-author\">" + escape_html_text(author) + "</p>"
    None => ""
  }
  "<li class=\"surface-card\" data-source=\"" +
  escape_html_text(page.source_path) +
  "\"><a href=\"" +
  escape_html_text(page.url_path) +
  "\"><h3>" +
  escape_html_text(page.title) +
  "</h3>" +
  meta_html +
  author_html +
  summary_html +
  "</a></li>"
}

///|
fn render_homepage_module(
  kicker : String,
  title : String,
  list_class : String,
  items_html : String,
) -> String {
  if items_html == "" {
    return ""
  }
  "<section class=\"home-module\"><div class=\"section-heading\"><p class=\"section-kicker\">" +
  escape_html_text(kicker) +
  "</p><h2>" +
  escape_html_text(title) +
  "</h2></div><ul class=\"" +
  list_class +
  "\">" +
  items_html +
  "</ul></section>"
}

///|
fn render_homepage_recent_card(page : @core.SitePage) -> String {
  let date_html = match page.date {
    Some(date) =>
      "<span class=\"home-card-date\">" + escape_html_text(date) + "</span>"
    None => ""
  }
  "<li class=\"home-card home-card-compact\"><a href=\"" +
  escape_html_text(page.url_path) +
  "\"><span>" +
  escape_html_text(page.title) +
  "</span>" +
  date_html +
  "</a></li>"
}

///|
fn surface_card_density_class(density : @core.CardDensity) -> String {
  match density {
    @core.CardDensity::Hero => "hero"
    @core.CardDensity::Standard => "standard"
    @core.CardDensity::Compact => "compact"
  }
}

///|
fn homepage_hero_title(
  config : @core.MooninkConfig,
  page : @core.SitePage,
) -> String {
  let (hero_title, _, _, _) = homepage_config(config)
  match hero_title {
    Some(title) => title
    None => page.title
  }
}

///|
fn homepage_hero_summary(
  config : @core.MooninkConfig,
  page : @core.SitePage,
) -> String {
  let (_, hero_summary, _, _) = homepage_config(config)
  match hero_summary {
    Some(summary) => summary
    None =>
      match config.author_profile.homepage_text {
        Some(summary) => summary
        None =>
          match config.author_profile.bio {
            Some(summary) => summary
            None => page.summary
          }
      }
  }
}

///|
fn render_homepage_modules_html(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> String raise BuildCommandError {
  let (_, _, featured_paths, recent_count) = homepage_config(config)
  let normalized_featured_paths : Array[String] = []
  for source_path in featured_paths {
    normalized_featured_paths.push(
      normalize_homepage_featured_path(source_path) catch {
        err => raise err
      },
    )
  }

  let featured : Array[@core.SitePage] = []
  if normalized_featured_paths.is_empty() {
    for page in pages {
      if page.featured && !page.is_index && !page.nav_hidden {
        featured.push(page)
      }
    }
    featured.sort_by(compare_pages_by_freshness_priority)
  } else {
    for source_path in normalized_featured_paths {
      match find_page_by_source_path(pages, source_path) {
        Some(page) => featured.push(page)
        None =>
          raise homepage_config_error(
            source_path, "homepage.featured_paths entry does not resolve to a discovered page",
          )
      }
    }
  }

  let recency_pool : Array[@core.SitePage] = []
  for page in pages {
    if page.content_kind == @core.ContentKind::Article &&
      !page.is_index &&
      !page.nav_hidden &&
      page.published_at is Some(_) &&
      !page.featured &&
      !source_path_in_list(normalized_featured_paths, page.source_path) {
      recency_pool.push(page)
    }
  }
  recency_pool.sort_by(compare_pages_by_freshness_priority)
  let recent = if recency_pool.length() > recent_count {
    recency_pool[:recent_count].to_array()
  } else {
    recency_pool
  }

  let featured_items = featured
    .map(fn(page) { render_surface_card(page) })
    .iter()
    .join("")
  let recent_items = recent
    .map(fn(page) { render_homepage_recent_card(page) })
    .iter()
    .join("")
  let modules : Array[String] = []
  let featured_html = render_homepage_module(
    "Featured", "Selected writing", "home-card-grid", featured_items,
  )
  if featured_html != "" {
    modules.push(featured_html)
  }
  let recent_html = render_homepage_module(
    "Recent", "Recent writing", "home-card-list", recent_items,
  )
  if recent_html != "" {
    modules.push(recent_html)
  }
  if modules.is_empty() {
    ""
  } else {
    "<section class=\"home-module-grid\">" +
    modules.iter().join("") +
    "</section>"
  }
}

///|
fn build_search_generated_page(
  config : @core.MooninkConfig,
) -> @core.GeneratedPage {
  let body_html = "<section class=\"search-shell\" data-moonink-search-page=\"true\">" +
    "<label class=\"search-label\" for=\"moonink-search-query\">Search the site</label>" +
    "<input id=\"moonink-search-query\" class=\"search-input\" type=\"search\" placeholder=\"Search titles, summaries, tags, and excerpts\" autocomplete=\"off\">" +
    "<p class=\"search-status\" data-search-status>Type to search the generated index.</p>" +
    "<ol class=\"search-results\" data-moonink-search-results></ol>" +
    "</section>"
  generated_page_for_root_with_extras(
    "search",
    "search",
    "Search",
    "Find pages by title, summary, tags, and excerpts.",
    "Find pages by title, summary, tags, and excerpts.",
    "search",
    body_html,
    config.route_style,
    "",
    "<script src=\"../assets/moonink-search.js\" defer></script>",
  )
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
fn slugify_surface_segment(source : String) -> String {
  let builder = StringBuilder::new()
  let mut previous_dash = false
  for i in 0..<source.length() {
    let char = source[i:i + 1].to_string()
    let lowered = char.to_lower()
    let is_alnum = (lowered >= "a" && lowered <= "z") ||
      (lowered >= "0" && lowered <= "9")
    if is_alnum {
      builder.write_string(lowered)
      previous_dash = false
    } else if !previous_dash {
      builder.write_string("-")
      previous_dash = true
    }
  }
  let slug = trim_hyphen_edges(builder.to_string())
  if slug == "" {
    "item"
  } else {
    slug
  }
}

///|
fn collection_index_item(
  config : @core.MooninkConfig,
  root : String,
  slug : String,
  label : String,
  count : Int,
) -> String {
  "<li><a href=\"" +
  escape_html_text(generated_surface_route(config, root + "/" + slug)) +
  "\">" +
  escape_html_text(label) +
  "</a><span class=\"surface-summary-count\">" +
  count.to_string() +
  "</span></li>"
}

///|
fn build_tag_generated_pages(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> Array[@core.GeneratedPage] {
  let grouped : Map[String, Array[@core.SitePage]] = {}
  for page in pages {
    if page.is_index {
      continue
    }
    for tag in page.tags {
      if tag == "" {
        continue
      }
      let existing = match grouped.get(tag) {
        Some(items) => items
        None => []
      }
      grouped[tag] = existing + [page]
    }
  }

  let tags : Array[String] = []
  for entry in grouped {
    let (tag, _) = entry
    tags.push(tag)
  }
  tags.sort_by(fn(left, right) { left.compare(right) })

  let summary_items : Array[String] = []
  let pages_out : Array[@core.GeneratedPage] = []
  for tag in tags {
    let items = match grouped.get(tag) {
      Some(items) => items
      None => []
    }
    let slug = slugify_surface_segment(tag)
    summary_items.push(
      collection_index_item(config, "tags", slug, tag, items.length()),
    )
    items.sort_by(compare_pages_by_freshness_priority)
    let body_html = "<ul class=\"surface-card-grid\">" +
      items.map(fn(page) { render_surface_card(page) }).iter().join("") +
      "</ul>"
    pages_out.push(
      generated_page_for_root(
        "tags/" + slug,
        "collection",
        "Tag: " + tag,
        "Writing tagged with " + tag + ".",
        "Writing tagged with " + tag + ".",
        "collection",
        body_html,
        config.route_style,
      ),
    )
  }

  [
    generated_page_for_root(
      "tags",
      "collection",
      "Tags",
      "Browse content by tag.",
      "Browse content by tag.",
      "collection",
      "<ul class=\"surface-summary-list\">" +
      summary_items.iter().join("") +
      "</ul>",
      config.route_style,
    ),
  ] +
  pages_out
}

///|
fn build_series_generated_pages(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> Array[@core.GeneratedPage] {
  let grouped : Map[String, Array[@core.SitePage]] = {}
  for page in pages {
    if page.is_index {
      continue
    }
    match page.series {
      Some(series_name) if series_name != "" => {
        let existing = match grouped.get(series_name) {
          Some(items) => items
          None => []
        }
        grouped[series_name] = existing + [page]
      }
      _ => ()
    }
  }

  let series_names : Array[String] = []
  for entry in grouped {
    let (series_name, _) = entry
    series_names.push(series_name)
  }
  series_names.sort_by(fn(left, right) { left.compare(right) })

  let summary_items : Array[String] = []
  let pages_out : Array[@core.GeneratedPage] = []
  for series_name in series_names {
    let items = match grouped.get(series_name) {
      Some(items) => items
      None => []
    }
    let slug = slugify_surface_segment(series_name)
    summary_items.push(
      collection_index_item(config, "series", slug, series_name, items.length()),
    )
    items.sort_by(compare_pages_by_series_contract)
    let body_html = "<ol class=\"surface-card-grid\">" +
      items.map(fn(page) { render_surface_card(page) }).iter().join("") +
      "</ol>"
    pages_out.push(
      generated_page_for_root(
        "series/" + slug,
        "collection",
        "Series: " + series_name,
        "Read the " + series_name + " sequence.",
        "Read the " + series_name + " sequence.",
        "collection",
        body_html,
        config.route_style,
      ),
    )
  }

  [
    generated_page_for_root(
      "series",
      "collection",
      "Series",
      "Browse content by series.",
      "Browse content by series.",
      "collection",
      "<ul class=\"surface-summary-list\">" +
      summary_items.iter().join("") +
      "</ul>",
      config.route_style,
    ),
  ] +
  pages_out
}

///|
fn archive_entry_label(page : @core.SitePage) -> String {
  match page.published_at {
    Some(date) => date
    None => ""
  }
}

///|
fn build_archive_generated_page(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> @core.GeneratedPage {
  let grouped : Map[String, Array[@core.SitePage]] = {}
  let month_keys : Array[String] = []
  for page in pages {
    if page.is_index {
      continue
    }
    match page.published_at {
      Some(date) =>
        match archive_group_key(date) {
          Some(key) =>
            match grouped.get(key) {
              Some(items) => items.push(page)
              None => {
                grouped[key] = [page]
                month_keys.push(key)
              }
            }
          None => ()
        }
      None => ()
    }
  }
  month_keys.sort_by(fn(left, right) { right.compare(left) })
  let sections : Array[String] = []
  for key in month_keys {
    let items = match grouped.get(key) {
      Some(items) => items
      None => []
    }
    items.sort_by(compare_pages_by_archive_contract)
    sections.push(
      "<section class=\"archive-month\"><div class=\"section-heading\"><p class=\"section-kicker\">" +
      escape_html_text(key[:4].to_string()) +
      "</p><h2>" +
      escape_html_text(key) +
      "</h2></div><ul class=\"archive-list\">" +
      items
      .map(fn(page) {
        "<li class=\"archive-item\" data-source=\"" +
        escape_html_text(page.source_path) +
        "\"><span class=\"archive-date\">" +
        escape_html_text(archive_entry_label(page)) +
        "</span><a href=\"" +
        escape_html_text(page.url_path) +
        "\">" +
        escape_html_text(page.title) +
        "</a></li>"
      })
      .iter()
      .join("") +
      "</ul></section>",
    )
  }
  let body_html = sections.iter().join("")
  generated_page_for_root(
    "archive",
    "archive",
    "Archive",
    "Browse recent writing chronologically.",
    "Browse recent writing chronologically.",
    "archive",
    body_html,
    config.route_style,
  )
}

///|
fn build_generated_pages(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> Array[@core.GeneratedPage] {
  [build_search_generated_page(config)] +
  build_tag_generated_pages(config, pages) +
  build_series_generated_pages(config, pages) +
  [build_archive_generated_page(config, pages)]
}

///|
fn absolute_site_url(
  config : @core.MooninkConfig,
  url_path : String,
) -> String? {
  match config.site_url {
    Some(site_url) => {
      let base = if site_url.has_suffix("/") {
        site_url[:site_url.length() - 1].to_string()
      } else {
        site_url
      }
      Some(base + url_path)
    }
    None => None
  }
}

///|
fn render_head_meta_html(
  config : @core.MooninkConfig,
  title : String,
  description : String,
  url_path : String,
  og_type : String,
) -> String {
  let description_html = if description == "" {
    ""
  } else {
    "<meta name=\"description\" content=\"" +
    escape_html_text(description) +
    "\"><meta property=\"og:description\" content=\"" +
    escape_html_text(description) +
    "\">"
  }
  let canonical_html = match absolute_site_url(config, url_path) {
    Some(url) =>
      "<link rel=\"canonical\" href=\"" +
      escape_html_text(url) +
      "\"><meta property=\"og:url\" content=\"" +
      escape_html_text(url) +
      "\">"
    None => ""
  }
  let rss_html = match absolute_site_url(config, "/rss.xml") {
    Some(url) =>
      "<link rel=\"alternate\" type=\"application/rss+xml\" href=\"" +
      escape_html_text(url) +
      "\" title=\"" +
      escape_html_text(config.site_name) +
      "\">"
    None => ""
  }
  description_html +
  canonical_html +
  "<meta property=\"og:title\" content=\"" +
  escape_html_text(title) +
  "\"><meta property=\"og:type\" content=\"" +
  escape_html_text(og_type) +
  "\"><meta property=\"og:site_name\" content=\"" +
  escape_html_text(config.site_name) +
  "\">" +
  rss_html
}

///|
fn render_rss_item(
  config : @core.MooninkConfig,
  page : @core.SitePage,
) -> String {
  let link = match absolute_site_url(config, page.url_path) {
    Some(url) => url
    None => page.url_path
  }
  let description = if page.summary == "" { page.title } else { page.summary }
  "<item><title>" +
  escape_html_text(page.title) +
  "</title><link>" +
  escape_html_text(link) +
  "</link><guid>" +
  escape_html_text(link) +
  "</guid><description>" +
  escape_html_text(description) +
  "</description></item>"
}

///|
fn render_rss_xml(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> String {
  let articles : Array[@core.SitePage] = []
  for page in pages {
    if page.content_kind == @core.ContentKind::Article && !page.is_index {
      articles.push(page)
    }
  }
  articles.sort_by(compare_site_pages_by_recency)
  let channel_link = match config.site_url {
    Some(url) => url
    None => ""
  }
  let items = articles
    .map(fn(page) { render_rss_item(config, page) })
    .iter()
    .join("")
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?><rss version=\"2.0\"><channel><title>" +
  escape_html_text(config.site_name) +
  "</title><link>" +
  escape_html_text(channel_link) +
  "</link><description>" +
  escape_html_text(config.site_name + " feed") +
  "</description>" +
  items +
  "</channel></rss>"
}

///|
fn compare_bool_desc(left : Bool, right : Bool) -> Int {
  match (left, right) {
    (true, false) => -1
    (false, true) => 1
    _ => 0
  }
}

///|
fn compare_pages_by_freshness_priority(
  left : @core.SitePage,
  right : @core.SitePage,
) -> Int {
  let pinned_compare = compare_bool_desc(left.pinned, right.pinned)
  if pinned_compare != 0 {
    return pinned_compare
  }
  let freshness_compare = compare_optional_dates_desc(
    left.freshness_at,
    right.freshness_at,
  )
  if freshness_compare != 0 {
    return freshness_compare
  }
  left.source_path.compare(right.source_path)
}

///|
fn compare_pages_by_series_contract(
  left : @core.SitePage,
  right : @core.SitePage,
) -> Int {
  let published_compare = compare_optional_dates_asc(
    left.published_at,
    right.published_at,
  )
  if published_compare != 0 {
    return published_compare
  }
  left.source_path.compare(right.source_path)
}

///|
fn compare_pages_by_archive_contract(
  left : @core.SitePage,
  right : @core.SitePage,
) -> Int {
  let published_compare = compare_optional_dates_desc(
    left.published_at,
    right.published_at,
  )
  if published_compare != 0 {
    return published_compare
  }
  left.source_path.compare(right.source_path)
}

///|
fn sort_named_collections(
  collections : Array[@core.NamedCardCollection],
) -> Array[@core.NamedCardCollection] {
  let sorted : Array[@core.NamedCardCollection] = []
  for collection in collections {
    sorted.push(collection)
  }
  sorted.sort_by(fn(left, right) { left.name.compare(right.name) })
  sorted
}

///|
fn sort_archive_months(
  months : Array[@core.ArchiveMonth],
) -> Array[@core.ArchiveMonth] {
  let sorted : Array[@core.ArchiveMonth] = []
  for month in months {
    sorted.push(month)
  }
  sorted.sort_by(fn(left, right) { right.label.compare(left.label) })
  sorted
}

///|
fn unique_collection_slugs(names : Array[String]) -> Map[String, String] {
  let sorted : Array[String] = []
  for name in names {
    sorted.push(name)
  }
  sorted.sort_by(fn(left, right) { left.compare(right) })
  let slug_counts : Map[String, Int] = {}
  let slugs : Map[String, String] = {}
  for name in sorted {
    let base_slug = slugify_surface_segment(name)
    let count = match slug_counts.get(base_slug) {
      Some(value) => value + 1
      None => 0
    }
    slug_counts[base_slug] = count
    slugs[name] = if count == 0 {
      base_slug
    } else {
      base_slug + "-" + count.to_string()
    }
  }
  slugs
}

///|
fn author_label_for_page(
  config : @core.MooninkConfig,
  page : @core.SitePage,
) -> String {
  match page.author {
    Some(author) => author
    None =>
      match config.author_profile.name {
        Some(author) => author
        None => config.site_name
      }
  }
}

///|
fn build_surface_card(
  config : @core.MooninkConfig,
  page : @core.SitePage,
  density : @core.CardDensity,
  display_date : String?,
) -> @core.SiteCard {
  {
    title: page.title,
    url_path: page.url_path,
    source_path: page.source_path,
    summary: page.summary,
    display_date,
    published_at: page.published_at,
    freshness_at: page.freshness_at,
    tags: page.tags,
    series: page.series,
    cover: page.cover,
    author: Some(author_label_for_page(config, page)),
    featured: page.featured,
    pinned: page.pinned,
    density,
  }
}

///|
fn archive_group_key(date : String) -> String? {
  let normalized = date.trim().to_string()
  if normalized.length() < 7 {
    return None
  }
  if normalized[4:5].to_string() != "-" {
    return None
  }
  let year = normalized[:4].to_string()
  let month = normalized[5:7].to_string()
  if parse_decimal_int(year) is None {
    return None
  }
  let month_value = match parse_decimal_int(month) {
    Some(value) => value
    None => return None
  }
  if month_value < 1 || month_value > 12 {
    return None
  }
  Some(year + "-" + month)
}

///|
fn build_tag_collections(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> Array[@core.NamedCardCollection] {
  let grouped : Map[String, Array[@core.SitePage]] = {}
  let tag_names : Array[String] = []
  for page in pages {
    for tag in page.tags {
      match grouped.get(tag) {
        Some(existing) => existing.push(page)
        None => {
          grouped[tag] = [page]
          tag_names.push(tag)
        }
      }
    }
  }
  let slugs = unique_collection_slugs(tag_names)
  let collections : Array[@core.NamedCardCollection] = []
  for tag in tag_names {
    let items = match grouped.get(tag) {
      Some(items) => items
      None => []
    }
    items.sort_by(compare_pages_by_freshness_priority)
    let cards : Array[@core.SiteCard] = []
    for page in items {
      cards.push(
        build_surface_card(
          config,
          page,
          @core.CardDensity::Standard,
          page.freshness_at,
        ),
      )
    }
    let slug = match slugs.get(tag) {
      Some(value) => value
      None => slugify_surface_segment(tag)
    }
    collections.push({
      name: tag,
      slug,
      url_path: generated_surface_route(config, "tags/" + slug),
      cards,
    })
  }
  sort_named_collections(collections)
}

///|
fn build_series_collections(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> Array[@core.NamedCardCollection] {
  let grouped : Map[String, Array[@core.SitePage]] = {}
  let series_names : Array[String] = []
  for page in pages {
    match page.series {
      Some(series_name) =>
        match grouped.get(series_name) {
          Some(existing) => existing.push(page)
          None => {
            grouped[series_name] = [page]
            series_names.push(series_name)
          }
        }
      None => ()
    }
  }
  let slugs = unique_collection_slugs(series_names)
  let collections : Array[@core.NamedCardCollection] = []
  for series_name in series_names {
    let items = match grouped.get(series_name) {
      Some(items) => items
      None => []
    }
    items.sort_by(compare_pages_by_series_contract)
    let cards : Array[@core.SiteCard] = []
    for page in items {
      cards.push(
        build_surface_card(
          config,
          page,
          @core.CardDensity::Standard,
          page.published_at,
        ),
      )
    }
    let slug = match slugs.get(series_name) {
      Some(value) => value
      None => slugify_surface_segment(series_name)
    }
    collections.push({
      name: series_name,
      slug,
      url_path: generated_surface_route(config, "series/" + slug),
      cards,
    })
  }
  sort_named_collections(collections)
}

///|
fn build_archive_months(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> Array[@core.ArchiveMonth] {
  let grouped : Map[String, Array[@core.SitePage]] = {}
  let keys : Array[String] = []
  for page in pages {
    match page.published_at {
      Some(date) =>
        match archive_group_key(date) {
          Some(key) =>
            match grouped.get(key) {
              Some(existing) => existing.push(page)
              None => {
                grouped[key] = [page]
                keys.push(key)
              }
            }
          None => ()
        }
      None => ()
    }
  }
  let months : Array[@core.ArchiveMonth] = []
  for key in keys {
    let items = match grouped.get(key) {
      Some(items) => items
      None => []
    }
    items.sort_by(compare_pages_by_archive_contract)
    let cards : Array[@core.SiteCard] = []
    for page in items {
      cards.push(
        build_surface_card(
          config,
          page,
          @core.CardDensity::Compact,
          page.published_at,
        ),
      )
    }
    months.push({
      year: key[:4].to_string(),
      month: key[5:7].to_string(),
      label: key,
      cards,
    })
  }
  sort_archive_months(months)
}

///|
fn build_homepage_featured_cards(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> Array[@core.SiteCard] {
  let (_, _, featured_paths, _) = homepage_config(config)
  let normalized_paths : Array[String] = []
  for source_path in featured_paths {
    normalized_paths.push(
      normalize_homepage_featured_path(source_path) catch {
        _ => continue
      },
    )
  }
  let featured_pages : Array[@core.SitePage] = []
  if normalized_paths.is_empty() {
    for page in pages {
      if page.featured && !page.is_index && !page.nav_hidden {
        featured_pages.push(page)
      }
    }
    featured_pages.sort_by(compare_pages_by_freshness_priority)
  } else {
    for path in normalized_paths {
      match find_page_by_source_path(pages, path) {
        Some(page) => featured_pages.push(page)
        None => ()
      }
    }
  }
  let cards : Array[@core.SiteCard] = []
  for index in 0..<featured_pages.length() {
    cards.push(
      build_surface_card(
        config,
        featured_pages[index],
        if index == 0 {
          @core.CardDensity::Hero
        } else {
          @core.CardDensity::Standard
        },
        featured_pages[index].freshness_at,
      ),
    )
  }
  cards
}

///|
fn build_homepage_recent_cards(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> Array[@core.SiteCard] {
  let (_, _, featured_paths, recent_count) = homepage_config(config)
  let normalized_paths : Array[String] = []
  for source_path in featured_paths {
    normalized_paths.push(
      normalize_homepage_featured_path(source_path) catch {
        _ => continue
      },
    )
  }
  let recency_pool : Array[@core.SitePage] = []
  for page in pages {
    if page.content_kind == @core.ContentKind::Article &&
      !page.is_index &&
      !page.nav_hidden &&
      page.published_at is Some(_) &&
      !page.featured &&
      !source_path_in_list(normalized_paths, page.source_path) {
      recency_pool.push(page)
    }
  }
  recency_pool.sort_by(compare_pages_by_freshness_priority)
  let limited = if recency_pool.length() > recent_count {
    recency_pool[:recent_count].to_array()
  } else {
    recency_pool
  }
  let cards : Array[@core.SiteCard] = []
  for page in limited {
    cards.push(
      build_surface_card(
        config,
        page,
        @core.CardDensity::Standard,
        page.freshness_at,
      ),
    )
  }
  cards
}

///|
fn build_search_cards(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> Array[@core.SiteCard] {
  let cards : Array[@core.SiteCard] = []
  let eligible : Array[@core.SitePage] = []
  for page in pages {
    if page.search {
      eligible.push(page)
    }
  }
  eligible.sort_by(compare_pages_by_freshness_priority)
  for page in eligible {
    cards.push(
      build_surface_card(
        config,
        page,
        @core.CardDensity::Compact,
        page.freshness_at,
      ),
    )
  }
  cards
}

///|
fn published_build_inputs(
  inputs : Array[@runtime.BuildInput],
) -> Array[@runtime.BuildInput] {
  let published : Array[@runtime.BuildInput] = []
  for input in inputs {
    if input.meta.frontmatter.draft {
      continue
    }
    published.push(input)
  }
  published
}

///|
fn build_input_output_targets(
  inputs : Array[@runtime.BuildInput],
) -> Array[OutputTarget] {
  let targets : Array[OutputTarget] = []
  for input in inputs {
    targets.push({
      output_path: input.meta.output_path,
      source_path: input.meta.source_path,
    })
  }
  targets
}

///|
fn generated_page_output_targets(
  pages : Array[@core.GeneratedPage],
) -> Array[OutputTarget] {
  let targets : Array[OutputTarget] = []
  for page in pages {
    targets.push({ output_path: page.output_path, source_path: page.source_path })
  }
  targets
}

///|
fn build_site_collections(
  config : @core.MooninkConfig,
  pages : Array[@core.SitePage],
) -> @core.SiteCollections {
  {
    homepage_featured: build_homepage_featured_cards(config, pages),
    homepage_recent: build_homepage_recent_cards(config, pages),
    search: build_search_cards(config, pages),
    tags: build_tag_collections(config, pages),
    series: build_series_collections(config, pages),
    archive: build_archive_months(config, pages),
  }
}
