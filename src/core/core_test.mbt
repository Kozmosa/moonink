///|
test "site assembly model supports construction" {
  let page : @core.SitePage = {
    title: "Home",
    nav_title: "Home",
    nav_hidden: false,
    description: "Landing page",
    source_path: "index.md",
    url_path: "/",
    content_kind: @core.ContentKind::Page,
    is_index: true,
  }
  let child : @core.NavigationItem = {
    title: "Install",
    url_path: "/guide/install/",
    source_path: "guide/install.md",
    content_kind: @core.ContentKind::Page,
    children: [],
    is_index: false,
  }
  let item : @core.NavigationItem = {
    title: "Guide",
    url_path: "/guide/",
    source_path: "guide/index.md",
    content_kind: @core.ContentKind::Page,
    children: [child],
    is_index: true,
  }
  let navigation : @core.NavigationModel = {
    items: [item],
    total_items: 2,
    note: "auto navigation placeholder",
  }
  let site : @core.SiteAssemblyModel = {
    pages: [page],
    navigation,
    page_count: 1,
    article_count: 0,
    navigation_items: 2,
    note: "site assembly placeholder",
  }
  inspect(site.pages[0].title, content="Home")
  inspect(site.navigation.items[0].children.length(), content="1")
  inspect(site.navigation.total_items, content="2")
  inspect(site.navigation_items, content="2")
}

///|
test "build_site_model_dummy preserves inventory counts" {
  let inventory : @core.ContentInventory = {
    root: "fixtures/v2/minimal",
    files: [],
    total_articles: 2,
    total_pages: 3,
    note: "inventory for site model dummy test",
  }
  let config : @core.MooninkConfig = {
    config_path: "moonink.json",
    project_root: ".",
    site_name: "Fixture Site",
    site_url: Some("https://example.com"),
    content_dir: ".",
    output_dir: "dist",
    template_file: None,
    exclude: ["dist"],
    route_style: @core.RouteStyle::Pretty,
    text_encoding: "utf-8",
    theme: None,
    theme_config: {},
  }
  let model = @core.build_site_model_dummy(config, inventory)
  inspect(model.page_count, content="3")
  inspect(model.article_count, content="2")
  inspect(model.navigation.total_items, content="0")
  inspect(model.pages.length(), content="0")
}

///|
test "normalize_relative_path normalizes redundant segments" {
  inspect(
    @core.normalize_relative_path("./docs//guides"),
    content="docs/guides",
  )
  inspect(@core.normalize_relative_path("articles/."), content="articles")
}

///|
test "normalize_relative_path rejects parent traversal" {
  inspect(
    try? @core.normalize_relative_path("../moonink.json"),
    content="Err(ParentTraversal(\"../moonink.json\"))",
  )
}

///|
test "normalize_relative_path rejects absolute paths" {
  inspect(
    try? @core.normalize_relative_path("/etc/passwd"),
    content="Err(AbsolutePath(\"/etc/passwd\"))",
  )
}

///|
test "normalize_relative_path rejects empty paths" {
  inspect(
    try? @core.normalize_relative_path(""),
    content="Err(EmptyPath(\"\"))",
  )
}

///|
test "parse_config_json parses minimal config" {
  let json =
    #|{"site_name": "Test Site", "site_url": "https://example.com"}
  let config = @core.parse_config_json("fixtures/moonink.json", json) catch {
    _ => panic()
  }
  inspect(config.site_name, content="Test Site")
  inspect(config.site_url, content="Some(\"https://example.com\")")
  inspect(config.content_dir, content=".")
  inspect(config.output_dir, content="dist")
  inspect(config.route_style, content="Pretty")
  inspect(config.text_encoding, content="utf-8")
}

///|
test "parse_config_json uses defaults for optional fields" {
  let json =
    #|{"site_name": "Defaults"}
  let config = @core.parse_config_json("moonink.json", json) catch {
    _ => panic()
  }
  inspect(config.content_dir, content=".")
  inspect(config.output_dir, content="dist")
  inspect(config.route_style, content="Pretty")
  inspect(config.template_file, content="None")
  inspect(config.exclude.length() > 0, content="true")
}

///|
test "parse_config_json parses optional template_file" {
  let json =
    #|{"site_name": "Templated", "template_file": "templates/site.html"}
  let config = @core.parse_config_json("moonink.json", json) catch {
    _ => panic()
  }
  inspect(config.template_file, content="Some(\"templates/site.html\")")
}

///|
test "parse_config_json rejects parent traversal template_file" {
  let json =
    #|{"site_name": "Templated", "template_file": "../site.html"}
  inspect(
    try? @core.parse_config_json("moonink.json", json),
    content="Err(InvalidPath(path=\"../site.html\", reason=\"parent traversal is not allowed: ../site.html\"))",
  )
}

///|
test "parse_config_json reports missing site_name" {
  let json =
    #|{"site_url": "https://example.com"}
  inspect(
    try? @core.parse_config_json("moonink.json", json),
    content="Err(MissingField(key=\"site_name\"))",
  )
}

///|
test "parse_config_json reports invalid JSON" {
  let result = try? @core.parse_config_json("moonink.json", "not json")
  inspect(result is Err(_), content="true")
}

///|
test "parse_config_json supports direct route style" {
  let json =
    #|{"site_name": "Test", "route_style": "direct"}
  let config = @core.parse_config_json("moonink.json", json) catch {
    _ => panic()
  }
  inspect(config.route_style, content="Direct")
}

///|
test "parse_config_json records theme and theme_config" {
  let json =
    #|{"site_name": "Themed", "theme": "paper", "theme_config": {"accent": "sunset", "font": "serif"}}
  let config = @core.parse_config_json("moonink.json", json) catch {
    _ => panic()
  }
  inspect(config.theme, content="Some(\"paper\")")
  inspect(
    config.theme_config.get("accent"),
    content="Some(StringValue(\"sunset\"))",
  )
  inspect(
    config.theme_config.get("font"),
    content="Some(StringValue(\"serif\"))",
  )
}

///|
test "parse_config_json preserves nested theme_config values" {
  let json =
    #|{"site_name": "Themed", "theme_config": {"colors": {"accent": "sunset"}, "spacing": ["sm", "md"], "enabled": true}}
  let config = @core.parse_config_json("moonink.json", json) catch {
    _ => panic()
  }
  inspect(
    config.theme_config.get("colors"),
    content="Some(ObjectValue({\"accent\": StringValue(\"sunset\")}))",
  )
  inspect(
    config.theme_config.get("spacing"),
    content="Some(ArrayValue([StringValue(\"sm\"), StringValue(\"md\")]))",
  )
  inspect(config.theme_config.get("enabled"), content="Some(BoolValue(true))")
}

///|
test "parse_config_json rejects non-object theme_config" {
  let json =
    #|{"site_name": "Themed", "theme_config": ["accent"]}
  inspect(
    try? @core.parse_config_json("moonink.json", json),
    content="Err(InvalidField(key=\"theme_config\", detail=\"must be a JSON object\"))",
  )
}

///|
test "parse_theme_manifest_result reads layout map and token declarations" {
  let json =
    #|{"name": "paper", "layouts": {"article": "layouts/article.html", "page": "layouts/page.html"}, "tokens": [{"name": "accent", "default": "sunset"}, {"name": "font", "default": "serif"}], "page_overrides": ["landing", "docs/index"], "slots": ["head", "footer"]}
  let manifest = match @core.parse_theme_manifest_result(json) {
    Ok(manifest) => manifest
    Err(_) => panic()
  }
  inspect(manifest.name, content="paper")
  inspect(
    manifest.layouts.get("article"),
    content="Some(\"layouts/article.html\")",
  )
  inspect(manifest.tokens.length(), content="2")
  inspect(manifest.tokens[0].name, content="accent")
  inspect(manifest.tokens[0].default_value, content="Some(\"sunset\")")
  inspect(manifest.page_overrides[1], content="docs/index")
  inspect(manifest.slots[0], content="head")
}

///|
test "parse_theme_manifest_result rejects malformed layouts values" {
  let json =
    #|{"name": "paper", "layouts": {"article": 1}}
  inspect(
    @core.parse_theme_manifest_result(json),
    content="Err(InvalidField(key=\"layouts\", detail=\"must contain only string values\"))",
  )
}

///|
test "parse_theme_manifest_result rejects malformed token entries" {
  let json =
    #|{"name": "paper", "tokens": [{"default": "sunset"}]}
  inspect(
    @core.parse_theme_manifest_result(json),
    content="Err(InvalidField(key=\"tokens\", detail=\"each token must include a string `name`\"))",
  )
}

///|
test "parse_theme_manifest_result rejects malformed page_overrides entries" {
  let json =
    #|{"name": "paper", "page_overrides": ["landing", false]}
  inspect(
    @core.parse_theme_manifest_result(json),
    content="Err(InvalidField(key=\"page_overrides\", detail=\"must contain only strings\"))",
  )
}

///|
test "parse_theme_manifest_result rejects malformed slots entries" {
  let json =
    #|{"name": "paper", "slots": ["head", {"name": "footer"}]}
  inspect(
    @core.parse_theme_manifest_result(json),
    content="Err(InvalidField(key=\"slots\", detail=\"must contain only strings\"))",
  )
}

///|
test "extract_frontmatter_raw extracts yaml block" {
  let source = "---\ntitle: Hello\n---\n\n# Body"
  let (yaml, body) = @core.extract_frontmatter_raw(source)
  inspect(yaml, content="Some(\"title: Hello\")")
  inspect(body, content="# Body")
}

///|
test "extract_frontmatter_raw handles no frontmatter" {
  let source = "# Just a heading"
  let (yaml, body) = @core.extract_frontmatter_raw(source)
  inspect(yaml, content="None")
  inspect(body, content="# Just a heading")
}

///|
test "parse_frontmatter records scalar tags shape mismatch" {
  let fm = @core.parse_frontmatter("title: Demo\ntags: moonbit")
  inspect(fm.tags.length(), content="0")
  inspect(fm.field_shapes.get("tags"), content="Some(Scalar)")
}

///|
test "parse_frontmatter records invalid scalar draft value" {
  let fm = @core.parse_frontmatter("title: Demo\ndraft: maybe")
  inspect(fm.draft, content="false")
  inspect(fm.field_shapes.get("draft"), content="Some(Scalar)")
  inspect(fm.invalid_scalar_fields.get("draft"), content="Some(true)")
}

///|
test "parse_frontmatter records list title shape mismatch" {
  let fm = @core.parse_frontmatter("title: [Demo]\n")
  inspect(fm.title, content="None")
  inspect(fm.field_shapes.get("title"), content="Some(List)")
}

///|
test "parse_frontmatter parses core fields" {
  let yaml = "title: My Article\ndescription: A test\ntype: article\ndate: 2026-04-01\ndraft: true"
  let fm = @core.parse_frontmatter(yaml)
  inspect(fm.title, content="Some(\"My Article\")")
  inspect(fm.description, content="Some(\"A test\")")
  inspect(fm.content_type, content="Some(\"article\")")
  inspect(fm.date, content="Some(\"2026-04-01\")")
  inspect(fm.draft, content="true")
}

///|
test "parse_frontmatter parses tags list" {
  let yaml = "title: Tagged\ntags: [moonbit, ssg, test]"
  let fm = @core.parse_frontmatter(yaml)
  inspect(fm.tags.length(), content="3")
  inspect(fm.tags[0], content="moonbit")
  inspect(fm.tags[2], content="test")
}

///|
test "parse_frontmatter collects extra fields" {
  let yaml = "title: Custom\ncustom_field: custom_value\nanother: 42"
  let fm = @core.parse_frontmatter(yaml)
  inspect(fm.extra.get("custom_field"), content="Some(\"custom_value\")")
  inspect(fm.extra.get("another"), content="Some(\"42\")")
  inspect(fm.extra.get("title"), content="None")
}

///|
test "parse_frontmatter keeps navigation fields in extra" {
  let yaml = "title: Guide\nnav_title: Documentation\nnav_hidden: true\ntype: page"
  let fm = @core.parse_frontmatter(yaml)
  inspect(fm.title, content="Some(\"Guide\")")
  inspect(fm.content_type, content="Some(\"page\")")
  inspect(fm.extra.get("nav_title"), content="Some(\"Documentation\")")
  inspect(fm.extra.get("nav_hidden"), content="Some(\"true\")")
}

///|
test "parse_frontmatter records theme page override fields" {
  let yaml = "title: Landing\nlayout: landing\ntheme_tone: sunset\ntheme_sections: [hero, cta]\ntype: page"
  let fm = @core.parse_frontmatter(yaml)
  inspect(fm.layout, content="Some(\"landing\")")
  inspect(fm.theme_meta.get("tone"), content="Some(StringValue(\"sunset\"))")
  inspect(
    fm.theme_meta.get("sections"),
    content="Some(ArrayValue([StringValue(\"hero\"), StringValue(\"cta\")]))",
  )
}

///|
test "page_view_model_from_meta exposes layout override and theme meta" {
  let frontmatter = @core.parse_frontmatter(
    "title: Landing\nlayout: hero\ntheme_variant: feature\ntheme_sections: [hero, faq]\ntype: page",
  )
  let meta = @core.PageMeta::new(
    "index.md",
    @core.ContentKind::Page,
    @core.SourceFormat::Markdown,
    frontmatter,
    @core.RouteStyle::Pretty,
  )
  let page = @core.page_view_model_from_meta(meta)
  inspect(meta.layout_override, content="Some(\"hero\")")
  inspect(page.layout, content="Some(\"hero\")")
  inspect(
    page.theme_meta.get("variant"),
    content="Some(StringValue(\"feature\"))",
  )
  inspect(
    page.theme_meta.get("sections"),
    content="Some(ArrayValue([StringValue(\"hero\"), StringValue(\"faq\")]))",
  )
}

///|
test "parse_frontmatter_from_source handles full document" {
  let source = "---\ntitle: Hello\ntype: page\n---\n\n# Body content"
  let (fm, body) = @core.parse_frontmatter_from_source(source)
  inspect(fm.title, content="Some(\"Hello\")")
  inspect(fm.content_type, content="Some(\"page\")")
  inspect(body, content="# Body content")
}

///|
test "search index excerpt prefers explicit excerpt" {
  inspect(
    @core.search_index_excerpt(
      Some("Frontmatter summary"),
      "# Heading\n\nBody text should be ignored.",
      @core.SourceFormat::Markdown,
    ),
    content="Frontmatter summary",
  )
}

///|
test "search index excerpt derives plain text from markdown body" {
  inspect(
    @core.search_index_excerpt(
      None,
      "# Hello World\n\nThis is body text for search.",
      @core.SourceFormat::Markdown,
    ),
    content="Hello World This is body text for search.",
  )
}

///|
test "search index excerpt preserves literal punctuation inside markdown text" {
  inspect(
    @core.search_index_excerpt(
      None,
      "Use `search_index` with C# and config.yaml in [docs](guide.md).",
      @core.SourceFormat::Markdown,
    ),
    content="Use search_index with C# and config.yaml in docs.",
  )
}

///|
test "search index excerpt strips html tags for html pages" {
  inspect(
    @core.search_index_excerpt(
      None,
      "<h1>About</h1><p>This is a static HTML page.</p>",
      @core.SourceFormat::Html,
    ),
    content="About This is a static HTML page.",
  )
}

///|
test "search index excerpt preserves non-tag angle bracket text" {
  inspect(
    @core.search_index_excerpt(
      None,
      "Compare a < b and Vector<T> while keeping <literal text.",
      @core.SourceFormat::Html,
    ),
    content="Compare a < b and Vector<T> while keeping <literal text.",
  )
}

///|
test "search index excerpt strips actual html tags with attributes" {
  inspect(
    @core.search_index_excerpt(
      None,
      "<code class=\"lang\">search_index</code> <br/> ready",
      @core.SourceFormat::Html,
    ),
    content="search_index ready",
  )
}

///|
test "search index document serializes stable schema" {
  let json = @core.search_index_document_to_json({
    version: 1,
    generated_at: "2026-04-15T00:00:00Z",
    items: [
      {
        title: "Hello",
        url: "/hello/",
        excerpt: "A short intro",
        tags: ["intro", "demo"],
        date: Some("2026-04-01"),
      },
      {
        title: "About",
        url: "/about/",
        excerpt: "About page",
        tags: [],
        date: None,
      },
    ],
  })
  inspect(
    json,
    content=(
      #|{"version":1,"generated_at":"2026-04-15T00:00:00Z","items":[{"title":"Hello","url":"/hello/","excerpt":"A short intro","tags":["intro","demo"],"date":"2026-04-01"},{"title":"About","url":"/about/","excerpt":"About page","tags":[],"date":null}]}
    ),
  )
}

///|
test "classify_source_format identifies markdown and html" {
  inspect(@core.classify_source_format("docs/intro.md"), content="Markdown")
  inspect(@core.classify_source_format("pages/about.html"), content="Html")
  inspect(@core.classify_source_format("image.png"), content="Unknown")
}

///|
test "classify_content_kind uses format and frontmatter type" {
  inspect(
    @core.classify_content_kind(@core.SourceFormat::Html, None),
    content="Page",
  )
  inspect(
    @core.classify_content_kind(@core.SourceFormat::Markdown, Some("page")),
    content="Page",
  )
  inspect(
    @core.classify_content_kind(@core.SourceFormat::Markdown, None),
    content="Article",
  )
  inspect(
    @core.classify_content_kind(@core.SourceFormat::Markdown, Some("article")),
    content="Article",
  )
}

///|
test "generate_route pretty style" {
  inspect(
    @core.generate_route("guides/intro.md", @core.RouteStyle::Pretty),
    content="/guides/intro/",
  )
  inspect(
    @core.generate_route("index.md", @core.RouteStyle::Pretty),
    content="/",
  )
  inspect(
    @core.generate_route("docs/index.md", @core.RouteStyle::Pretty),
    content="/docs/",
  )
}

///|
test "generate_route direct style" {
  inspect(
    @core.generate_route("guides/intro.md", @core.RouteStyle::Direct),
    content="/guides/intro.html",
  )
  inspect(
    @core.generate_route("index.md", @core.RouteStyle::Direct),
    content="/index.html",
  )
}

///|
test "generate_output_html_path maps source paths to pretty html outputs" {
  inspect(
    @core.output_html_path("guides/intro.md", @core.RouteStyle::Pretty),
    content="guides/intro/index.html",
  )
  inspect(
    @core.output_html_path("index.md", @core.RouteStyle::Pretty),
    content="index.html",
  )
  inspect(
    @core.output_html_path("docs/index.md", @core.RouteStyle::Pretty),
    content="docs/index.html",
  )
  inspect(
    @core.output_html_path("about.html", @core.RouteStyle::Pretty),
    content="about/index.html",
  )
}

///|
test "generate_output_html_path maps source paths to direct html outputs" {
  inspect(
    @core.output_html_path("guides/intro.md", @core.RouteStyle::Direct),
    content="guides/intro.html",
  )
  inspect(
    @core.output_html_path("index.md", @core.RouteStyle::Direct),
    content="index.html",
  )
  inspect(
    @core.output_html_path("docs/index.md", @core.RouteStyle::Direct),
    content="docs/index.html",
  )
  inspect(
    @core.output_html_path("about.html", @core.RouteStyle::Direct),
    content="about.html",
  )
}

///|
test "should_exclude matches patterns and hidden dirs" {
  inspect(@core.should_exclude(".git", []), content="true")
  inspect(@core.should_exclude(".obsidian", []), content="true")
  inspect(
    @core.should_exclude("node_modules", ["node_modules"]),
    content="true",
  )
  inspect(@core.should_exclude("docs", ["dist"]), content="false")
}
