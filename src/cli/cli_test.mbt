///|
fn find_substring_or_panic(haystack : String, needle : String) -> Int {
  let h_len = haystack.length()
  let n_len = needle.length()
  if n_len > h_len {
    panic()
  }
  for i in 0..<=(h_len - n_len) {
    let slice = haystack[i:i + n_len].to_string()
    if slice == needle {
      return i
    }
  }
  panic()
}

///|
test "build site assembly model combines pages and navigation" {
  let config : @core.MooninkConfig = {
    config_path: "moonink.json",
    project_root: ".",
    site_name: "Fixture Site",
    site_url: Some("https://example.com/docs"),
    content_dir: ".",
    output_dir: "dist",
    template_file: None,
    exclude: ["dist"],
    route_style: @core.RouteStyle::Pretty,
    text_encoding: "utf-8",
    theme: None,
    theme_config: {},
    author_profile: @core.AuthorProfile::default(),
  }
  let inventory : @core.ContentInventory = {
    root: "fixtures/v2/minimal",
    files: [],
    asset_files: [],
    total_articles: 1,
    total_pages: 2,
    total_assets: 0,
    note: "inventory for assembly test",
  }
  let inputs : Array[@runtime.BuildInput] = [
    {
      absolute_source_path: "fixtures/v2/minimal/index.md",
      relative_source_path: "index.md",
      source_content: "# Home",
      docflow_content: "# Home",
      meta: {
        source_path: "index.md",
        url_path: "/",
        output_path: "index.html",
        content_kind: @core.ContentKind::Page,
        format: @core.SourceFormat::Markdown,
        frontmatter: {
          ..@core.Frontmatter::default(),
          title: Some("Home"),
          content_type: Some("page"),
        },
        layout_override: None,
        resolved_title: "",
        sort_key: "index.md",
        is_index: true,
      },
    },
    {
      absolute_source_path: "fixtures/v2/minimal/about.html",
      relative_source_path: "about.html",
      source_content: "<h1>About</h1>",
      docflow_content: "<h1>About</h1>",
      meta: {
        source_path: "about.html",
        url_path: "/about/",
        output_path: "about/index.html",
        content_kind: @core.ContentKind::Page,
        format: @core.SourceFormat::Html,
        frontmatter: @core.Frontmatter::default(),
        layout_override: None,
        resolved_title: "",
        sort_key: "about.html",
        is_index: false,
      },
    },
    {
      absolute_source_path: "fixtures/v2/minimal/hello.md",
      relative_source_path: "hello.md",
      source_content: "# Hello",
      docflow_content: "# Hello",
      meta: {
        source_path: "hello.md",
        url_path: "/hello/",
        output_path: "hello/index.html",
        content_kind: @core.ContentKind::Article,
        format: @core.SourceFormat::Markdown,
        frontmatter: @core.Frontmatter::default(),
        layout_override: None,
        resolved_title: "",
        sort_key: "hello.md",
        is_index: false,
      },
    },
  ]
  let assembly = @cli.build_site_assembly_model(config, inputs, inventory)
  inspect(assembly.page_count, content="2")
  inspect(assembly.article_count, content="1")
  inspect(assembly.navigation_items, content="3")
  inspect(assembly.pages.length(), content="3")
  inspect(assembly.navigation.items.length(), content="3")
}

///|
test "build backlink index records markdown source urls once per page" {
  let inputs : Array[@runtime.BuildInput] = [
    {
      absolute_source_path: "fixtures/v2/minimal/index.md",
      relative_source_path: "index.md",
      source_content: "[[hello]] [[hello]]",
      docflow_content: "[[hello]] [[hello]]",
      meta: {
        source_path: "index.md",
        url_path: "/",
        output_path: "index.html",
        content_kind: @core.ContentKind::Page,
        format: @core.SourceFormat::Markdown,
        frontmatter: {
          ..@core.Frontmatter::default(),
          content_type: Some("page"),
        },
        layout_override: None,
        resolved_title: "",
        sort_key: "index.md",
        is_index: true,
      },
    },
    {
      absolute_source_path: "fixtures/v2/minimal/hello.md",
      relative_source_path: "hello.md",
      source_content: "# Hello",
      docflow_content: "# Hello",
      meta: {
        source_path: "hello.md",
        url_path: "/hello/",
        output_path: "hello/index.html",
        content_kind: @core.ContentKind::Article,
        format: @core.SourceFormat::Markdown,
        frontmatter: @core.Frontmatter::default(),
        layout_override: None,
        resolved_title: "",
        sort_key: "hello.md",
        is_index: false,
      },
    },
  ]
  let backlinks = @cli.build_backlink_index(
    inputs,
    @cli.build_wikilinker(inputs),
  )
  inspect(backlinks.get("/hello/"), content="Some([\"/\"])")
}

///|
test "build backlink index ignores unresolved and ambiguous wikilinks" {
  let inputs : Array[@runtime.BuildInput] = [
    {
      absolute_source_path: "fixtures/v2/minimal/index.md",
      relative_source_path: "index.md",
      source_content: "[[missing]] [[intro]]",
      docflow_content: "[[missing]] [[intro]]",
      meta: {
        source_path: "index.md",
        url_path: "/",
        output_path: "index.html",
        content_kind: @core.ContentKind::Page,
        format: @core.SourceFormat::Markdown,
        frontmatter: {
          ..@core.Frontmatter::default(),
          content_type: Some("page"),
        },
        layout_override: None,
        resolved_title: "",
        sort_key: "index.md",
        is_index: true,
      },
    },
    {
      absolute_source_path: "fixtures/v2/minimal/guide/intro.md",
      relative_source_path: "guide/intro.md",
      source_content: "# Guide Intro",
      docflow_content: "# Guide Intro",
      meta: {
        source_path: "guide/intro.md",
        url_path: "/guide/intro/",
        output_path: "guide/intro/index.html",
        content_kind: @core.ContentKind::Article,
        format: @core.SourceFormat::Markdown,
        frontmatter: @core.Frontmatter::default(),
        layout_override: None,
        resolved_title: "",
        sort_key: "guide/intro.md",
        is_index: false,
      },
    },
    {
      absolute_source_path: "fixtures/v2/minimal/reference/intro.md",
      relative_source_path: "reference/intro.md",
      source_content: "# Reference Intro",
      docflow_content: "# Reference Intro",
      meta: {
        source_path: "reference/intro.md",
        url_path: "/reference/intro/",
        output_path: "reference/intro/index.html",
        content_kind: @core.ContentKind::Article,
        format: @core.SourceFormat::Markdown,
        frontmatter: @core.Frontmatter::default(),
        layout_override: None,
        resolved_title: "",
        sort_key: "reference/intro.md",
        is_index: false,
      },
    },
  ]
  let backlinks = @cli.build_backlink_index(
    inputs,
    @cli.build_wikilinker(inputs),
  )
  inspect(backlinks.get("/missing/"), content="None")
  inspect(backlinks.get("/guide/intro/"), content="None")
  inspect(backlinks.get("/reference/intro/"), content="None")
}

///|
test "render navigation html marks active and ancestor items" {
  let navigation : @core.NavigationModel = {
    items: [
      {
        title: "Home",
        url_path: "/",
        source_path: "index.md",
        content_kind: @core.ContentKind::Page,
        children: [],
        is_index: true,
      },
      {
        title: "Guide",
        url_path: "/guide/",
        source_path: "guide/index.md",
        content_kind: @core.ContentKind::Page,
        children: [
          {
            title: "Install",
            url_path: "/guide/install/",
            source_path: "guide/install.md",
            content_kind: @core.ContentKind::Page,
            children: [],
            is_index: false,
          },
        ],
        is_index: true,
      },
    ],
    total_items: 3,
    note: "navigation for render test",
  }
  let html = @cli.render_navigation_html(navigation, "/guide/install/")
  inspect(html.contains("<nav data-moonink-nav=\"auto\">"), content="true")
  inspect(html.contains("href=\"/guide/install/\">Install</a>"), content="true")
  inspect(
    html.contains(
      "<li data-active=\"false\" data-ancestor=\"true\" data-index=\"true\" data-expanded=\"true\" data-current=\"ancestor\"><a href=\"/guide/\">Guide</a>",
    ),
    content="true",
  )
  inspect(
    html.contains(
      "<li data-active=\"true\" data-ancestor=\"false\" data-index=\"false\" data-expanded=\"true\" data-current=\"page\"><a href=\"/guide/install/\">Install</a>",
    ),
    content="true",
  )
}

///|
test "render navigation html escapes titles and urls" {
  let navigation : @core.NavigationModel = {
    items: [
      {
        title: "A < B",
        url_path: "/guide/?q=1&x=2",
        source_path: "guide/index.md",
        content_kind: @core.ContentKind::Page,
        children: [],
        is_index: true,
      },
    ],
    total_items: 1,
    note: "navigation escaping test",
  }
  let html = @cli.render_navigation_html(navigation, "/")
  inspect(html.contains("A &lt; B"), content="true")
  inspect(html.contains("/guide/?q=1&amp;x=2"), content="true")
}

///|
test "build navigation model uses nav_title and hides nav_hidden pages" {
  let pages : Array[@core.SitePage] = [
    {
      title: "Home",
      nav_title: "Home",
      nav_hidden: false,
      description: "",
      summary: "",
      date: None,
      updated: None,
      tags: [],
      series: None,
      cover: None,
      author: None,
      column: None,
      featured: false,
      pinned: false,
      search: true,
      toc: None,
      published_at: None,
      freshness_at: None,
      reading_time_minutes: 1,
      source_format: @core.SourceFormat::Markdown,
      source_path: "index.md",
      url_path: "/",
      content_kind: @core.ContentKind::Page,
      is_index: true,
    },
    {
      title: "Guide",
      nav_title: "Documentation",
      nav_hidden: false,
      description: "",
      summary: "",
      date: None,
      updated: None,
      tags: [],
      series: None,
      cover: None,
      author: None,
      column: None,
      featured: false,
      pinned: false,
      search: true,
      toc: None,
      published_at: None,
      freshness_at: None,
      reading_time_minutes: 1,
      source_format: @core.SourceFormat::Markdown,
      source_path: "guide/index.md",
      url_path: "/guide/",
      content_kind: @core.ContentKind::Page,
      is_index: true,
    },
    {
      title: "Install",
      nav_title: "Quick Start",
      nav_hidden: false,
      description: "",
      summary: "",
      date: None,
      updated: None,
      tags: [],
      series: None,
      cover: None,
      author: None,
      column: None,
      featured: false,
      pinned: false,
      search: true,
      toc: None,
      published_at: None,
      freshness_at: None,
      reading_time_minutes: 1,
      source_format: @core.SourceFormat::Markdown,
      source_path: "guide/install.md",
      url_path: "/guide/install/",
      content_kind: @core.ContentKind::Page,
      is_index: false,
    },
    {
      title: "Config",
      nav_title: "Config",
      nav_hidden: true,
      description: "",
      summary: "",
      date: None,
      updated: None,
      tags: [],
      series: None,
      cover: None,
      author: None,
      column: None,
      featured: false,
      pinned: false,
      search: true,
      toc: None,
      published_at: None,
      freshness_at: None,
      reading_time_minutes: 1,
      source_format: @core.SourceFormat::Markdown,
      source_path: "guide/config.md",
      url_path: "/guide/config/",
      content_kind: @core.ContentKind::Page,
      is_index: false,
    },
    {
      title: "Hello",
      nav_title: "Hello",
      nav_hidden: false,
      description: "",
      summary: "",
      date: None,
      updated: None,
      tags: [],
      series: None,
      cover: None,
      author: None,
      column: None,
      featured: false,
      pinned: false,
      search: true,
      toc: None,
      published_at: None,
      freshness_at: None,
      reading_time_minutes: 1,
      source_format: @core.SourceFormat::Markdown,
      source_path: "hello.md",
      url_path: "/hello/",
      content_kind: @core.ContentKind::Article,
      is_index: false,
    },
  ]
  let navigation = @cli.build_navigation_model(pages)
  inspect(navigation.total_items, content="4")
  inspect(navigation.items.length(), content="3")
  inspect(navigation.items[0].title, content="Home")
  inspect(navigation.items[1].title, content="Hello")
  inspect(navigation.items[2].title, content="Documentation")
  inspect(navigation.items[2].children.length(), content="1")
  inspect(navigation.items[2].children[0].title, content="Quick Start")
}

///|
test "build navigation model treats section index as landing item" {
  let pages : Array[@core.SitePage] = [
    {
      title: "Guide",
      nav_title: "Guide",
      nav_hidden: false,
      description: "",
      summary: "",
      date: None,
      updated: None,
      tags: [],
      series: None,
      cover: None,
      author: None,
      column: None,
      featured: false,
      pinned: false,
      search: true,
      toc: None,
      published_at: None,
      freshness_at: None,
      reading_time_minutes: 1,
      source_format: @core.SourceFormat::Markdown,
      source_path: "guide/index.md",
      url_path: "/guide/",
      content_kind: @core.ContentKind::Page,
      is_index: true,
    },
    {
      title: "Advanced",
      nav_title: "Advanced",
      nav_hidden: false,
      description: "",
      summary: "",
      date: None,
      updated: None,
      tags: [],
      series: None,
      cover: None,
      author: None,
      column: None,
      featured: false,
      pinned: false,
      search: true,
      toc: None,
      published_at: None,
      freshness_at: None,
      reading_time_minutes: 1,
      source_format: @core.SourceFormat::Markdown,
      source_path: "guide/advanced/index.md",
      url_path: "/guide/advanced/",
      content_kind: @core.ContentKind::Page,
      is_index: true,
    },
    {
      title: "Reference",
      nav_title: "Reference",
      nav_hidden: false,
      description: "",
      summary: "",
      date: None,
      updated: None,
      tags: [],
      series: None,
      cover: None,
      author: None,
      column: None,
      featured: false,
      pinned: false,
      search: true,
      toc: None,
      published_at: None,
      freshness_at: None,
      reading_time_minutes: 1,
      source_format: @core.SourceFormat::Markdown,
      source_path: "guide/advanced/reference.md",
      url_path: "/guide/advanced/reference/",
      content_kind: @core.ContentKind::Page,
      is_index: false,
    },
  ]
  let navigation = @cli.build_navigation_model(pages)
  inspect(navigation.items.length(), content="1")
  inspect(navigation.items[0].title, content="Guide")
  inspect(navigation.items[0].children.length(), content="1")
  inspect(navigation.items[0].children[0].title, content="Advanced")
  inspect(
    navigation.items[0].children[0].children[0].title,
    content="Reference",
  )
}

///|
test "site page title derives from frontmatter basename and root index" {
  let titled_meta : @core.PageMeta = {
    source_path: "guide/install.md",
    url_path: "/guide/install/",
    output_path: "guide/install/index.html",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: {
      ..@core.Frontmatter::default(),
      title: Some("Install Guide"),
    },
    layout_override: None,
    resolved_title: "",
    sort_key: "guide/install.md",
    is_index: false,
  }
  let untitled_meta : @core.PageMeta = {
    source_path: "guide/config.md",
    url_path: "/guide/config/",
    output_path: "guide/config/index.html",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: @core.Frontmatter::default(),
    layout_override: None,
    resolved_title: "",
    sort_key: "guide/config.md",
    is_index: false,
  }
  let index_meta : @core.PageMeta = {
    source_path: "index.md",
    url_path: "/",
    output_path: "index.html",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: @core.Frontmatter::default(),
    layout_override: None,
    resolved_title: "",
    sort_key: "index.md",
    is_index: true,
  }
  inspect(@cli.site_page_title(titled_meta), content="Install Guide")
  inspect(@cli.site_page_title(untitled_meta), content="config")
  inspect(@cli.site_page_title(index_meta), content="Home")
}

///|
test "site page navigation metadata derives from frontmatter extra" {
  let nav_meta : @core.PageMeta = {
    source_path: "guide/install.md",
    url_path: "/guide/install/",
    output_path: "guide/install/index.html",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: {
      ..@core.Frontmatter::default(),
      title: Some("Install Guide"),
      extra: { "nav_title": "Quick Start", "nav_hidden": "true" },
    },
    layout_override: None,
    resolved_title: "",
    sort_key: "guide/install.md",
    is_index: false,
  }
  let default_meta : @core.PageMeta = {
    source_path: "guide/config.md",
    url_path: "/guide/config/",
    output_path: "guide/config/index.html",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: @core.Frontmatter::default(),
    layout_override: None,
    resolved_title: "",
    sort_key: "guide/config.md",
    is_index: false,
  }
  inspect(@cli.site_page_nav_title(nav_meta), content="Quick Start")
  inspect(@cli.site_page_nav_hidden(nav_meta), content="true")
  inspect(@cli.site_page_nav_title(default_meta), content="config")
  inspect(@cli.site_page_nav_hidden(default_meta), content="false")
}

///|
test "site page navigation metadata falls back on empty title and strict hidden flag" {
  let empty_title_meta : @core.PageMeta = {
    source_path: "guide/advanced.md",
    url_path: "/guide/advanced/",
    output_path: "guide/advanced/index.html",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: {
      ..@core.Frontmatter::default(),
      title: Some("Advanced Guide"),
      extra: { "nav_title": "" },
    },
    layout_override: None,
    resolved_title: "",
    sort_key: "guide/advanced.md",
    is_index: false,
  }
  let loose_hidden_meta : @core.PageMeta = {
    source_path: "guide/draft.md",
    url_path: "/guide/draft/",
    output_path: "guide/draft/index.html",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: {
      ..@core.Frontmatter::default(),
      extra: { "nav_hidden": "TRUE" },
    },
    layout_override: None,
    resolved_title: "",
    sort_key: "guide/draft.md",
    is_index: false,
  }
  inspect(@cli.site_page_nav_title(empty_title_meta), content="Advanced Guide")
  inspect(@cli.site_page_nav_hidden(loose_hidden_meta), content="false")
}

///|
test "build site pages derives description index flag and nav metadata" {
  let page_input : @runtime.BuildInput = {
    absolute_source_path: "fixtures/v2/minimal/index.md",
    relative_source_path: "index.md",
    source_content: "---\ntitle: Home\ndescription: Landing page\ntype: page\n---\n",
    docflow_content: "# Home",
    meta: {
      source_path: "index.md",
      url_path: "/",
      output_path: "index.html",
      content_kind: @core.ContentKind::Page,
      format: @core.SourceFormat::Markdown,
      frontmatter: {
        ..@core.Frontmatter::default(),
        title: Some("Home"),
        description: Some("Landing page"),
        content_type: Some("page"),
      },
      layout_override: None,
      resolved_title: "",
      sort_key: "index.md",
      is_index: true,
    },
  }
  let article_input : @runtime.BuildInput = {
    absolute_source_path: "fixtures/v2/minimal/hello.md",
    relative_source_path: "hello.md",
    source_content: "# Hello",
    docflow_content: "# Hello",
    meta: {
      source_path: "hello.md",
      url_path: "/hello/",
      output_path: "hello/index.html",
      content_kind: @core.ContentKind::Article,
      format: @core.SourceFormat::Markdown,
      frontmatter: {
        ..@core.Frontmatter::default(),
        extra: { "nav_title": "Read Me", "nav_hidden": "true" },
      },
      layout_override: None,
      resolved_title: "",
      sort_key: "hello.md",
      is_index: false,
    },
  }
  let pages = @cli.build_site_pages([page_input, article_input])
  inspect(pages.length(), content="2")
  inspect(pages[0].description, content="Landing page")
  inspect(pages[0].is_index, content="true")
  inspect(pages[0].nav_title, content="Home")
  inspect(pages[0].nav_hidden, content="false")
  inspect(pages[1].title, content="hello")
  inspect(pages[1].nav_title, content="Read Me")
  inspect(pages[1].nav_hidden, content="true")
  inspect(pages[1].description, content="")
  inspect(pages[1].is_index, content="false")
}

///|
test "parse cli command supports raw command tokens" {
  inspect(@cli.parse_cli_command([]), content="Help")
  inspect(@cli.parse_cli_command(["help"]), content="Help")
  inspect(@cli.parse_cli_command(["build"]), content="Build")
  inspect(@cli.parse_cli_command(["check"]), content="Check")
  inspect(@cli.parse_cli_command(["serve"]), content="Serve")
  inspect(@cli.parse_cli_command(["onboard"]), content="Onboard")
}

///|
test "default onboard config json includes obsidian-friendly excludes" {
  let config_json = @cli.default_onboard_config_json("Vault")
  inspect(config_json.contains("\".trash\""), content="true")
  inspect(config_json.contains("\"templates\""), content="true")
  inspect(config_json.contains("\"Templates\""), content="true")
}

///|
test "parse cli command supports full argv forms" {
  inspect(@cli.parse_cli_command(["moonink"]), content="Help")
  inspect(@cli.parse_cli_command(["moonink", "build"]), content="Build")
  inspect(@cli.parse_cli_command(["moonink", "check"]), content="Check")
  inspect(@cli.parse_cli_command(["moonink", "serve"]), content="Serve")
  inspect(@cli.parse_cli_command(["moonink", "onboard"]), content="Onboard")
  inspect(
    @cli.parse_cli_command(["moonink", "doctor"]),
    content="Unknown(\"doctor\")",
  )
}

///|
test "parse cli request keeps structured build and serve flags" {
  inspect(
    @cli.parse_cli_request([
      "moonink", "build", "--config", "fixtures/v2/minimal/moonink.json", "--output",
      "dist-alt",
    ]),
    content="Build({ config_path: \"fixtures/v2/minimal/moonink.json\", output_dir: Some(\"dist-alt\") })",
  )
  inspect(
    @cli.parse_cli_request([
      "moonink", "serve", "--config", "fixtures/v2/minimal/moonink.json", "--host",
      "0.0.0.0", "--port", "4173", "--output", "preview-dist",
    ]),
    content="Serve({ config_path: \"fixtures/v2/minimal/moonink.json\", output_dir: Some(\"preview-dist\"), host: \"0.0.0.0\", port: 4173 })",
  )
}

///|
test "parse cli request rejects invalid flag combinations" {
  inspect(
    @cli.parse_cli_request(["moonink", "build", "--port", "4173"]),
    content="Invalid(\"[build] invalid arguments\\nreason: --port is only supported for serve\")",
  )
  inspect(
    @cli.parse_cli_request(["moonink", "serve", "--port", "9999"]),
    content="Invalid(\"[serve] invalid arguments\\nreason: invalid port 9999\")",
  )
  inspect(
    @cli.parse_cli_request(["moonink", "check", "--config"]),
    content="Invalid(\"[check] invalid arguments\\nreason: missing value for --config\")",
  )
}

///|
fn expected_build_runtime_message(
  config_path : String,
  output_dir? : String? = None,
) -> String {
  let output_status = match output_dir {
    Some(path) => "\noutput override: \{path}"
    None => ""
  }
  "[build] runtime execution required\nconfig: \{config_path}\nstatus: use cli_exec or the runtime IO boundary to load config and discover content" +
  output_status
}

///|
fn expected_check_runtime_message(
  config_path : String,
  output_dir? : String? = None,
) -> String {
  let output_status = match output_dir {
    Some(path) => "\noutput override: \{path}"
    None => ""
  }
  "[check] runtime execution required\nconfig: \{config_path}\nstatus: use cli_exec or the runtime IO boundary to load config, discover content, and collect diagnostics" +
  output_status
}

///|
fn expected_serve_runtime_message(
  config_path : String,
  host : String,
  port : Int,
  preview_root : String,
  output_dir? : String? = None,
) -> String {
  let output_status = match output_dir {
    Some(path) => "\noutput override: \{path}"
    None => ""
  }
  "[serve] build step will run before preview startup\n[serve] runtime execution required\naddress: http://\{host}:\{port}\npreview root: \{preview_root}\nconfig: \{config_path}" +
  output_status
}

///|
fn prepare_isolated_fixture_copy(source_root : String, name : String) -> String {
  let scratch_parent = "fixtures/v2/_test_runs"
  let target_root = scratch_parent + "/" + name
  let _ = try? @runtime.io_remove_dir_all(target_root)
  @runtime.io_ensure_dir(scratch_parent) catch {
    _ => panic()
  }
  @runtime.io_copy_dir_recursive(source_root, target_root) catch {
    _ => panic()
  }
  target_root
}

///|
test "cli run keeps build behind runtime boundary" {
  inspect(
    @cli.cli_run(["moonink", "build"]).message,
    content=expected_build_runtime_message("moonink.json"),
  )
  inspect(
    @cli.cli_run([
      "moonink", "build", "--config", "fixtures/v2/minimal/moonink.json", "--output",
      "dist-alt",
    ]).message,
    content=expected_build_runtime_message(
      "fixtures/v2/minimal/moonink.json",
      output_dir=Some("dist-alt"),
    ),
  )
}

///|
test "cli run keeps check behind runtime boundary" {
  inspect(
    @cli.cli_run(["moonink", "check"]).message,
    content=expected_check_runtime_message("moonink.json"),
  )
}

///|
test "cli run keeps serve behind runtime boundary" {
  inspect(
    @cli.cli_run(["moonink", "serve"]).message,
    content=expected_serve_runtime_message(
      "moonink.json", "127.0.0.1", 3000, "dist",
    ),
  )
  inspect(
    @cli.cli_run([
      "moonink", "serve", "--config", "fixtures/v2/minimal/moonink.json", "--host",
      "0.0.0.0", "--port", "4173", "--output", "preview-dist",
    ]).message,
    content=expected_serve_runtime_message(
      "fixtures/v2/minimal/moonink.json",
      "0.0.0.0",
      4173,
      "preview-dist",
      output_dir=Some("preview-dist"),
    ),
  )
}

///|
test "cli exec routes serve through runtime skeleton" {
  let outcome = @cli.cli_exec(["moonink", "serve"])
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[build] failed during config loading"),
    content="true",
  )
}

///|
test "cli exec routes check through runtime skeleton" {
  let outcome = @cli.cli_exec(["moonink", "check"])
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[check] failed during config loading"),
    content="true",
  )
}

///|
test "cli exec rejects invalid flag combinations" {
  let outcome = @cli.cli_exec(["moonink", "build", "--port", "4173"])
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message,
    content=(
      #|[build] invalid arguments
      #|reason: --port is only supported for serve
    ),
  )
}

///|
test "runtime cli serve builds fixture before preview skeleton" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/minimal", "minimal-serve-default",
  )
  let outcome = @cli.run_serve_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    outcome.message,
    content=(
      #|[serve] build completed
      #|[serve] runtime ready
      #|address: http://127.0.0.1:3000
      #|preview root: fixtures/v2/_test_runs/minimal-serve-default/dist
      #|status: Dry-run preview launch validated the built output without starting a server.
    ),
  )
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello/index.html",
  ) catch {
    _ => panic()
  }
  inspect(
    hello_html.contains("<h1 id=\"hello-world\">Hello World</h1>"),
    content="true",
  )
  inspect(
    hello_html.contains(
      "<script defer src=\"/__moonink/live-reload.js\"></script>",
    ),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(
      fixture_root + "/dist/__moonink/preview-status.json",
    ),
    content="true",
  )
  let preview_status = @runtime.io_read_file_to_string(
    fixture_root + "/dist/__moonink/preview-status.json",
  ) catch {
    _ => panic()
  }
  inspect(preview_status.contains("\"status\":\"ready\""), content="true")
}

///|
test "runtime cli serve respects host port and output override" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/minimal", "minimal-serve-preview-dist",
  )
  let outcome = @cli.run_serve_command_runtime_from_config_with_runner(
    fixture_root + "/moonink.json",
    Some("preview-dist"),
    "0.0.0.0",
    4173,
    @runtime.dry_run_preview_runner(),
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    outcome.message,
    content=(
      #|[serve] build completed
      #|[serve] runtime ready
      #|address: http://0.0.0.0:4173
      #|preview root: fixtures/v2/_test_runs/minimal-serve-preview-dist/preview-dist
      #|status: Dry-run preview launch validated the built output without starting a server.
    ),
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/preview-dist/hello/index.html"),
    content="true",
  )
}

///|
test "main serve launch plan builds once before delegated preview startup" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/minimal", "minimal-main-serve-delegate",
  )
  let launch = match
    prepare_main_serve_launch_result(
      fixture_root + "/moonink.json",
      Some("preview-dist"),
      "0.0.0.0",
      4173,
    ) {
    Ok(launch) => launch
    Err(message) => {
      inspect(message, content="")
      panic()
    }
  }
  inspect(launch.build_message, content="[serve] build completed")
  inspect(launch.preview_root, content=fixture_root + "/preview-dist")
  inspect(launch.host, content="0.0.0.0")
  inspect(launch.port.to_string(), content="4173")
  inspect(
    @runtime.io_path_exists(fixture_root + "/preview-dist/hello/index.html"),
    content="true",
  )
}

///|
test "runtime cli serve continues after build warnings" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/check_wikilink_warning", "check-wikilink-warning-serve",
  )
  let outcome = @cli.run_serve_command_runtime_from_config_with_runner(
    fixture_root + "/moonink.json",
    None,
    "127.0.0.1",
    3000,
    @runtime.dry_run_preview_runner(),
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    outcome.message,
    content=(
      #|[serve] build completed with warnings
      #|[hello.md] Unresolved wikilink target: missing-page
      #|[serve] runtime ready
      #|address: http://127.0.0.1:3000
      #|preview root: fixtures/v2/_test_runs/check-wikilink-warning-serve/dist
      #|status: Dry-run preview launch validated the built output without starting a server.
    ),
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="true",
  )
  let preview_status = @runtime.io_read_file_to_string(
    fixture_root + "/dist/__moonink/preview-status.json",
  ) catch {
    _ => panic()
  }
  inspect(preview_status.contains("\"status\":\"warning\""), content="true")
  inspect(
    preview_status.contains("Unresolved wikilink target: missing-page"),
    content="true",
  )
}

///|
test "main serve launch plan keeps warning-tolerant build semantics" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/check_wikilink_warning", "main-serve-warning-delegate",
  )
  let launch = match
    prepare_main_serve_launch_result(
      fixture_root + "/moonink.json",
      None,
      "127.0.0.1",
      3000,
    ) {
    Ok(launch) => launch
    Err(message) => {
      inspect(message, content="")
      panic()
    }
  }
  inspect(
    launch.build_message,
    content=(
      #|[serve] build completed with warnings
      #|[hello.md] Unresolved wikilink target: missing-page
    ),
  )
  inspect(launch.preview_root, content=fixture_root + "/dist")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="true",
  )
}

///|
test "runtime cli serve blocks preview startup on fatal build failure" {
  let outcome = @cli.run_serve_command_runtime_from_config(
    "fixtures/v2/missing_config/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[serve] build failed before preview startup"),
    content="true",
  )
  inspect(
    outcome.message.contains("[build] failed during config loading"),
    content="true",
  )
  inspect(outcome.message.contains("[serve] runtime ready"), content="false")
}

///|
test "runtime cli serve reports preview startup failure separately from build" {
  let startup = @cli.start_prepared_serve_session_result(
    @cli.prepare_serve_session(
      "fixtures/v2/missing_config/moonink.json",
      host="127.0.0.1",
      port=3000,
      note="manually prepared for serve-startup failure",
    ),
    @runtime.dry_run_preview_runner(),
  )
  match startup {
    Err(message) => {
      inspect(
        message.contains("[serve] failed during preview startup"),
        content="true",
      )
      inspect(message.contains("preview root does not exist"), content="true")
    }
    Ok(_) => panic()
  }
}

///|
test "runtime cli serve reports missing config before preview skeleton" {
  let outcome = @cli.run_serve_command_runtime_from_config(
    "fixtures/v2/missing_config/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[build] failed during config loading"),
    content="true",
  )
}

///|
test "runtime cli check succeeds for minimal fixture without diagnostics" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/minimal", "minimal-check-default",
  )
  let stale_path = fixture_root + "/dist/check-stale.txt"
  let _ = try? @runtime.io_create_dir(fixture_root + "/dist")
  @runtime.io_write_string(stale_path, "stale") catch {
    _ => panic()
  }
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(outcome.message.contains("[check] passed"), content="true")
  inspect(outcome.message.contains("diagnostics: 0"), content="true")
  inspect(@runtime.io_path_exists(stale_path), content="true")
}

///|
test "runtime cli check respects output override without writing output" {
  let fixture_root = "fixtures/v2/check_wikilink_warning"
  let outcome = @cli.run_check_command_runtime_from_config_with_output(
    fixture_root + "/moonink.json",
    Some("check-preview"),
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    outcome.message.contains("[check] passed with diagnostics"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/check-preview/index.html"),
    content="false",
  )
}

///|
test "runtime cli check reports wikilink diagnostics without writing output" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/check_wikilink_warning", "check-wikilink-warning-check",
  )
  let _ = try? @runtime.io_remove_dir_all(fixture_root + "/dist")
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    outcome.message.contains("[check] passed with diagnostics"),
    content="true",
  )
  inspect(outcome.message.contains("[check] wikilinks"), content="true")
  inspect(outcome.message.contains("[check] document"), content="false")
  inspect(
    outcome.message.contains("Unresolved wikilink target: missing-page"),
    content="true",
  )
  inspect(
    outcome.message.contains("[check] summary: 0 errors, 1 warnings"),
    content="true",
  )
  inspect(outcome.message.contains("[check] passed"), content="true")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="false",
  )
}

///|
test "runtime cli check reports missing configured template file" {
  let fixture_root = "fixtures/v2/missing_template_file"
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[check] theme/template"), content="true")
  inspect(
    outcome.message.contains("error: Failed to load active theme layout"),
    content="true",
  )
  inspect(outcome.message.contains("templates/missing.html"), content="true")
  inspect(
    outcome.message.contains("[check] summary: 1 errors, 0 warnings"),
    content="true",
  )
  inspect(outcome.message.contains("[check] failed"), content="true")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="false",
  )
}

///|
test "runtime cli check reports frontmatter type mismatch as blocking" {
  let fixture_root = "fixtures/v2/check_frontmatter_type_mismatch"
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[check] frontmatter"), content="true")
  inspect(
    outcome.message.contains("error: Frontmatter field `tags` must be an array"),
    content="true",
  )
  inspect(outcome.message.contains("[index.md]"), content="true")
  inspect(
    outcome.message.contains("[check] summary: 1 errors, 0 warnings"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="false",
  )
}

///|
test "runtime cli check reports frontmatter layout mismatch as blocking" {
  let fixture_root = "fixtures/v2/check_frontmatter_layout_mismatch"
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[check] frontmatter"), content="true")
  inspect(
    outcome.message.contains(
      "error: Frontmatter field `layout` must be a string",
    ),
    content="true",
  )
  inspect(outcome.message.contains("[index.md]"), content="true")
  inspect(
    outcome.message.contains("[check] summary: 1 errors, 0 warnings"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="false",
  )
}

///|
test "runtime cli check reports final route conflicts as blocking" {
  let fixture_root = "fixtures/v2/check_route_conflict"
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[check] routes"), content="true")
  inspect(
    outcome.message.contains("error: Final output path conflict"),
    content="true",
  )
  inspect(outcome.message.contains("index.md"), content="true")
  inspect(outcome.message.contains("index.html"), content="true")
  inspect(
    outcome.message.contains("[check] summary: 1 errors, 0 warnings"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="false",
  )
}

///|
test "runtime cli check reports mixed blocking and warning diagnostics" {
  let fixture_root = "fixtures/v2/check_mixed_diagnostics"
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[check] routes"), content="true")
  inspect(outcome.message.contains("[check] wikilinks"), content="true")
  inspect(outcome.message.contains("[check] document"), content="false")
  inspect(
    outcome.message.contains("Unresolved wikilink target: missing-page"),
    content="true",
  )
  inspect(
    outcome.message.contains("Final output path conflict"),
    content="true",
  )
  inspect(
    outcome.message.contains("[check] summary: 1 errors, 1 warnings"),
    content="true",
  )
  inspect(outcome.message.contains("[check] failed"), content="true")
}

///|
test "runtime cli check renders grouped diagnostics in fixed category order" {
  let fixture_root = "fixtures/v2/check_group_order"
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[check] frontmatter"), content="true")
  inspect(outcome.message.contains("[check] routes"), content="true")
  inspect(outcome.message.contains("[check] wikilinks"), content="true")
  inspect(outcome.message.contains("[check] document"), content="false")
  inspect(
    outcome.message.contains("Frontmatter field `tags` must be an array"),
    content="true",
  )
  inspect(
    outcome.message.contains("Final output path conflict"),
    content="true",
  )
  inspect(
    outcome.message.contains("Unresolved wikilink target: missing-page"),
    content="true",
  )
  inspect(
    outcome.message.contains("[check] summary: 2 errors, 1 warnings"),
    content="true",
  )
  let frontmatter_offset = find_substring_or_panic(
    outcome.message,
    "[check] frontmatter",
  )
  let routes_offset = find_substring_or_panic(outcome.message, "[check] routes")
  let wikilinks_offset = find_substring_or_panic(
    outcome.message,
    "[check] wikilinks",
  )
  inspect((frontmatter_offset < routes_offset).to_string(), content="true")
  inspect((routes_offset < wikilinks_offset).to_string(), content="true")
}

///|
test "runtime cli check reports invalid draft scalar as blocking" {
  let fixture_root = "fixtures/v2/check_frontmatter_invalid_draft"
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[check] frontmatter"), content="true")
  inspect(
    outcome.message.contains(
      "error: Frontmatter field `draft` must be a boolean",
    ),
    content="true",
  )
  inspect(outcome.message.contains("[index.md]"), content="true")
  inspect(
    outcome.message.contains("[check] summary: 1 errors, 0 warnings"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="false",
  )
}

///|
test "runtime cli check warns when a vault has no homepage note" {
  let outcome = @cli.run_check_command_runtime_from_config(
    "fixtures/v2/obsidian_direct_no_home/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(outcome.message.contains("No homepage note detected"), content="true")
  inspect(
    outcome.message.contains("[check] summary: 0 errors, 1 warnings"),
    content="true",
  )
}

///|
test "runtime cli check reports missing config" {
  let outcome = @cli.run_check_command_runtime_from_config(
    "fixtures/v2/missing_config/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[check] failed during config loading"),
    content="true",
  )
}

///|
test "cli run returns error for unknown command" {
  inspect(@cli.cli_run(["moonink", "doctor"]).exit_code, content="1")
}

///|
test "runtime cli build renders automatic navigation for pretty routes" {
  let fixture_root = "fixtures/v2/nav_pretty_basic"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  let guide_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/guide/index.html",
  ) catch {
    _ => panic()
  }
  let install_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/guide/install/index.html",
  ) catch {
    _ => panic()
  }
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello/index.html",
  ) catch {
    _ => panic()
  }
  let guide_tips_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/guide/tips/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("data-template=\"nav-pretty\""), content="true")
  inspect(
    index_html.contains("<nav data-moonink-nav=\"auto\">"),
    content="true",
  )
  inspect(
    index_html.contains("href=\"/guide/\">Documentation</a>"),
    content="true",
  )
  inspect(
    index_html.contains("href=\"/guide/install/\">Quick Start</a>"),
    content="true",
  )
  inspect(
    index_html.contains("href=\"/guide/config/\">Config</a>"),
    content="false",
  )
  inspect(index_html.contains("Hello Article"), content="true")
  inspect(index_html.contains("data-section-title=\"Home\""), content="true")
  inspect(index_html.contains("data-section-url=\"/\""), content="true")
  inspect(
    index_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Home</span></nav>",
    ),
    content="true",
  )
  inspect(
    guide_html.contains(
      "<li data-active=\"true\" data-ancestor=\"false\" data-index=\"true\" data-expanded=\"true\" data-current=\"page\"><a href=\"/guide/\">Documentation</a>",
    ),
    content="true",
  )
  inspect(
    guide_html.contains("data-section-title=\"Documentation\""),
    content="true",
  )
  inspect(guide_html.contains("data-section-url=\"/guide/\""), content="true")
  inspect(
    guide_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Guide</span></nav>",
    ),
    content="true",
  )
  inspect(
    install_html.contains(
      "<li data-active=\"false\" data-ancestor=\"true\" data-index=\"true\" data-expanded=\"true\" data-current=\"ancestor\"><a href=\"/guide/\">Documentation</a>",
    ),
    content="true",
  )
  inspect(
    install_html.contains(
      "<li data-active=\"true\" data-ancestor=\"false\" data-index=\"false\" data-expanded=\"true\" data-current=\"page\"><a href=\"/guide/install/\">Quick Start</a>",
    ),
    content="true",
  )
  inspect(
    install_html.contains("href=\"/guide/config/\">Config</a>"),
    content="false",
  )
  inspect(
    install_html.contains("data-section-title=\"Documentation\""),
    content="true",
  )
  inspect(install_html.contains("data-section-url=\"/guide/\""), content="true")
  inspect(
    install_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Install</span></nav>",
    ),
    content="true",
  )
  inspect(hello_html.contains("data-section-title=\"\""), content="true")
  inspect(hello_html.contains("data-section-url=\"\""), content="true")
  inspect(
    hello_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Hello Article</span></nav>",
    ),
    content="true",
  )
  inspect(
    guide_tips_html.contains("data-section-title=\"Documentation\""),
    content="true",
  )
  inspect(
    guide_tips_html.contains("data-section-url=\"/guide/\""),
    content="true",
  )
  inspect(
    guide_tips_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Guide Tips</span></nav>",
    ),
    content="true",
  )
}

///|
test "runtime cli build renders backlinks for minimal fixture" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/minimal", "minimal-build-backlinks",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello/index.html",
  ) catch {
    _ => panic()
  }
  inspect(hello_html.contains("Explore this thread"), content="true")
  inspect(hello_html.contains("Referenced by"), content="true")
  inspect(hello_html.contains(">Home<"), content="true")
  inspect(hello_html.contains("See hello."), content="true")
}

///|
test "runtime cli build respects output override" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/minimal", "minimal-build-dist-alt",
  )
  let outcome = @cli.run_build_command_runtime_from_config_with_output(
    fixture_root + "/moonink.json",
    Some("dist-alt"),
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist-alt/hello/index.html"),
    content="true",
  )
}

///|
test "runtime cli build surfaces wikilink diagnostics after successful output" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/check_wikilink_warning", "check-wikilink-warning-build",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    outcome.message.contains("[build] completed with diagnostics"),
    content="true",
  )
  inspect(
    outcome.message.contains("Unresolved wikilink target: missing-page"),
    content="true",
  )
  inspect(outcome.message.contains("[hello.md]"), content="true")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="true",
  )
}

///|
test "runtime cli build ignores ordinary markdown links in backlink index" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/minimal", "minimal-build-backlinks-ignore-markdown",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about/index.html",
  ) catch {
    _ => panic()
  }
  inspect(about_html.contains("<h2>Backlinks</h2>"), content="false")
}

///|
test "runtime cli build uses built-in theme v2 fallback" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/minimal", "minimal-built-in-theme-v2",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("data-theme-v2=\"default\""), content="true")
  inspect(index_html.contains("data-layout-kind=\"index\""), content="true")
  inspect(
    index_html.contains("href=\"/assets/theme-vars.css\""),
    content="true",
  )
  inspect(
    index_html.contains("href=\"/assets/moonink-default.css\""),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/theme-vars.css"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/moonink-default.css"),
    content="true",
  )
}

///|
test "runtime cli build renders branded article experience" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/article_experience_basic", "article-experience-basic",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let article_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/essays/stone-garden/index.html",
  ) catch {
    _ => panic()
  }
  inspect(article_html.contains("class=\"article-hero\""), content="true")
  inspect(
    article_html.contains(
      "Designing a site that feels like a room you can return to instead of a pile of exported notes.",
    ),
    content="true",
  )
  inspect(article_html.contains("Updated 2026-04-18"), content="true")
  inspect(article_html.contains("1 min read"), content="true")
  inspect(
    article_html.contains("src=\"/images/stone-garden.png\""),
    content="true",
  )
  inspect(article_html.contains("href=\"#threshold\""), content="true")
  inspect(article_html.contains("href=\"#texture\""), content="true")
  inspect(article_html.contains("id=\"threshold\""), content="true")
  inspect(article_html.contains("id=\"texture\""), content="true")
  inspect(article_html.contains(">Companion Note<"), content="true")
  inspect(
    article_html.contains("While revising Stone Garden, I kept trimming"),
    content="true",
  )
  inspect(article_html.contains(">Studio Rituals<"), content="true")
  inspect(article_html.contains("Shared tags: garden, systems"), content="true")
  inspect(article_html.contains(">Open Loops<"), content="true")
  inspect(article_html.contains("Explore this thread"), content="true")
  inspect(article_html.contains("Mentioned here"), content="true")
  inspect(article_html.contains("Referenced by"), content="true")
  inspect(article_html.contains("Keep reading"), content="true")
  inspect(article_html.contains(">Koz<"), content="true")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/images/stone-garden.png"),
    content="true",
  )
}

///|
test "runtime cli build writes minimal fixture html files" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/minimal", "minimal-build-default",
  )
  let stale_path = fixture_root + "/dist/stale.txt"
  let _ = try? @runtime.io_create_dir(fixture_root + "/dist")
  @runtime.io_write_string(stale_path, "stale") catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/hello/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/about/index.html"),
    content="true",
  )
  inspect(@runtime.io_path_exists(stale_path), content="false")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello/index.html",
  ) catch {
    _ => panic()
  }
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about/index.html",
  ) catch {
    _ => panic()
  }
  let search_index_path = fixture_root + "/dist/search-index.json"
  inspect(@runtime.io_path_exists(search_index_path), content="true")
  let search_index = @runtime.io_read_file_to_string(search_index_path) catch {
    _ => panic()
  }
  inspect(index_html.contains("data-theme=\"default\""), content="true")
  inspect(
    index_html.contains("href=\"/assets/moonink-default.css\""),
    content="true",
  )
  inspect(index_html.contains("class=\"moonink-page\""), content="true")
  inspect(index_html.contains("data-content-layout=\"index\""), content="true")
  inspect(
    index_html.contains("class=\"content-title\">Home</h1>"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/moonink-default.css"),
    content="true",
  )
  inspect(index_html.contains("Fixture Site"), content="true")
  inspect(index_html.contains("data-kind=\"index\""), content="true")
  inspect(index_html.contains("data-url=\"/\""), content="true")
  inspect(index_html.contains("data-section-title=\"Home\""), content="true")
  inspect(index_html.contains("data-section-url=\"/\""), content="true")
  inspect(
    index_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Home</span></nav>",
    ),
    content="true",
  )
  inspect(index_html.contains("<aside class=\"site-nav\">"), content="true")
  inspect(index_html.contains("href=\"/about/\">about</a>"), content="true")
  inspect(index_html.contains("href=\"/\">Home</a>"), content="true")
  inspect(hello_html.contains("Hello World"), content="true")
  inspect(hello_html.contains("<title>Hello</title>"), content="true")
  inspect(hello_html.contains("data-kind=\"article\""), content="true")
  inspect(
    hello_html.contains("data-content-layout=\"article\""),
    content="true",
  )
  inspect(
    hello_html.contains("class=\"section-kicker\">Article</p>"),
    content="true",
  )
  inspect(
    hello_html.contains("href=\"https://example.com/docs\""),
    content="true",
  )
  inspect(about_html.contains("data-kind=\"page\""), content="true")
  inspect(about_html.contains("data-url=\"/about/\""), content="true")
  inspect(
    about_html.contains("<header class=\"site-header\">") &&
    about_html.contains("href=\"https://example.com/docs\">Fixture Site</a>"),
    content="true",
  )
  inspect(search_index.contains("\"version\":"), content="true")
  inspect(search_index.contains("\"generated_at\":"), content="true")
  inspect(search_index.contains("\"title\":\"Home\""), content="true")
  inspect(search_index.contains("\"title\":\"Hello\""), content="true")
  inspect(search_index.contains("\"title\":\"about\""), content="true")
  inspect(search_index.contains("\"url\":\"/\""), content="true")
  inspect(search_index.contains("\"url\":\"/hello/\""), content="true")
  inspect(search_index.contains("\"url\":\"/about/\""), content="true")
  inspect(search_index.contains("\"tags\":[]"), content="true")
  inspect(search_index.contains("\"date\":null"), content="true")
}

///|
test "runtime cli build copies public assets into output" {
  let fixture_root = "fixtures/v2/public_assets_basic"
  let stale_path = fixture_root + "/dist/stale.txt"
  let _ = try? @runtime.io_create_dir(fixture_root + "/dist")
  @runtime.io_write_string(stale_path, "stale") catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(@runtime.io_path_exists(stale_path), content="false")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/robots.txt"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/css/site.css"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/images/logo.bin"),
    content="true",
  )
  let robots = @runtime.io_read_file_to_string(
    fixture_root + "/dist/robots.txt",
  ) catch {
    _ => panic()
  }
  let css = @runtime.io_read_file_to_string(fixture_root + "/dist/css/site.css") catch {
    _ => panic()
  }
  inspect(robots.contains("User-agent: *"), content="true")
  inspect(css.contains("background: #fafafa"), content="true")
}

///|
test "runtime cli build formats io errors when no config exists" {
  let outcome = @cli.cli_exec(["moonink", "build"])
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[build] failed during config loading"),
    content="true",
  )
}

///|
test "runtime cli build includes frontmatter-free article links in navigation" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/obsidian_direct_basic", "obsidian-nav-articles",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("data-layout-kind=\"index\""), content="true")
  inspect(index_html.contains("data-kind=\"index\""), content="true")
  inspect(
    index_html.contains("data-section-title=\"Vault Home\""),
    content="true",
  )
  inspect(index_html.contains("data-section-url=\"/\""), content="true")
  inspect(index_html.contains("href=\"/notes/project/\""), content="true")
  inspect(index_html.contains(">Project Overview<"), content="true")
}

///|
test "runtime cli build copies vault assets from the content tree" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/obsidian_direct_basic", "obsidian-vault-assets-build",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/Attachments/diagram.png"),
    content="true",
  )
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  inspect(
    index_html.contains("src=\"/Attachments/diagram.png\""),
    content="true",
  )
}

///|
test "runtime cli build fails when a vault asset collides with a reserved output artifact" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/obsidian_direct_basic", "obsidian-output-collision",
  )
  @runtime.io_write_string(fixture_root + "/search-index.json", "shadow") catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("search-index.json"), content="true")
  inspect(
    outcome.message.contains("vault asset output path conflict"),
    content="true",
  )
}

///|
test "runtime cli build respects direct route layout" {
  let fixture_root = "fixtures/v2/direct_route"
  let stale_path = fixture_root + "/dist/stale.txt"
  let _ = try? @runtime.io_create_dir(fixture_root + "/dist")
  @runtime.io_write_string(stale_path, "stale") catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/hello.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/about.html"),
    content="true",
  )
  inspect(@runtime.io_path_exists(stale_path), content="false")
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello.html",
  ) catch {
    _ => panic()
  }
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about.html",
  ) catch {
    _ => panic()
  }
  let search_index_path = fixture_root + "/dist/search-index.json"
  inspect(@runtime.io_path_exists(search_index_path), content="true")
  let search_index = @runtime.io_read_file_to_string(search_index_path) catch {
    _ => panic()
  }
  inspect(hello_html.contains("Hello World"), content="true")
  inspect(about_html.contains("This is a static HTML page."), content="true")
  inspect(search_index.contains("\"url\":\"/\""), content="true")
  inspect(search_index.contains("\"url\":\"/index.html\""), content="false")
  inspect(search_index.contains("\"url\":\"/hello.html\""), content="true")
  inspect(search_index.contains("\"url\":\"/about.html\""), content="true")
}

///|
test "runtime cli build applies configured template file" {
  let fixture_root = "fixtures/v2/with_template_file"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello/index.html",
  ) catch {
    _ => panic()
  }
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about/index.html",
  ) catch {
    _ => panic()
  }
  let guide_tips_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/guide/tips/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("data-template=\"custom\""), content="true")
  inspect(
    index_html.contains("<title>Home :: Template Fixture</title>"),
    content="true",
  )
  inspect(index_html.contains("<aside>Landing page</aside>"), content="true")
  inspect(
    index_html.contains("data-page-header-title=\"Home\""),
    content="true",
  )
  inspect(index_html.contains("data-section-title=\"Home\""), content="true")
  inspect(index_html.contains("data-section-url=\"/\""), content="true")
  inspect(
    index_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Home</span></nav>",
    ),
    content="true",
  )
  inspect(hello_html.contains("Hello Template"), content="true")
  inspect(
    hello_html.contains("<title>Hello :: Template Fixture</title>"),
    content="true",
  )
  inspect(
    hello_html.contains("data-site=\"https://example.com/template\""),
    content="true",
  )
  inspect(hello_html.contains("href=\"/about/\""), content="true")
  inspect(hello_html.contains(">about<"), content="true")
  inspect(hello_html.contains("href=\"/\""), content="true")
  inspect(hello_html.contains(">Home<"), content="true")
  inspect(hello_html.contains("<nav class=\"template-nav\">"), content="true")
  inspect(hello_html.contains("href=\"/about/\">about</a>"), content="true")
  inspect(hello_html.contains("href=\"/\">Home</a>"), content="true")
  inspect(
    hello_html.contains("data-page-header-title=\"Hello\""),
    content="true",
  )
  inspect(hello_html.contains("data-section-title=\"\""), content="true")
  inspect(hello_html.contains("data-section-url=\"\""), content="true")
  inspect(
    hello_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Hello</span></nav>",
    ),
    content="true",
  )
  inspect(
    guide_tips_html.contains("data-page-header-title=\"Guide Tips\""),
    content="true",
  )
  inspect(
    guide_tips_html.contains("data-section-title=\"Documentation\""),
    content="true",
  )
  inspect(
    guide_tips_html.contains("data-section-url=\"/guide/\""),
    content="true",
  )
  inspect(
    guide_tips_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Guide Tips</span></nav>",
    ),
    content="true",
  )
  inspect(about_html.contains("About Template"), content="true")
  inspect(about_html.contains("<aside></aside>"), content="true")
  inspect(about_html.contains("data-kind=\"page\""), content="true")
  inspect(about_html.contains("data-url=\"/about/\""), content="true")
  inspect(about_html.contains("data-section-title=\"\""), content="true")
  inspect(about_html.contains("data-section-url=\"\""), content="true")
}

///|
test "runtime cli build prefers theme layout over template file" {
  let fixture_root = "fixtures/v2/theme_layout_basic"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("data-theme-layout=\"true\""), content="true")
  inspect(index_html.contains("<title>Home :: theme</title>"), content="true")
  inspect(index_html.contains("class=\"moonink-page\""), content="true")
  inspect(index_html.contains("data-theme=\"theme\""), content="true")
  inspect(index_html.contains("href=\"/assets/style.css\""), content="true")
  inspect(index_html.contains("data-template=\"custom\""), content="false")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/style.css"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/moonink-default.css"),
    content="false",
  )
  let theme_css = @runtime.io_read_file_to_string(
    fixture_root + "/dist/assets/style.css",
  ) catch {
    _ => panic()
  }
  inspect(theme_css.contains("rebeccapurple"), content="true")
}

///|
test "runtime cli build uses theme v2 page kind layouts" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_basic", "theme-v2-layouts",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello/index.html",
  ) catch {
    _ => panic()
  }
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("data-layout-kind=\"index\""), content="true")
  inspect(index_html.contains("data-page-kind=\"index\""), content="true")
  inspect(
    index_html.contains(
      "<header class=\"theme-header\" data-nav-count=\"3\">Theme V2 Basic</header>",
    ),
    content="true",
  )
  inspect(hello_html.contains("data-layout-kind=\"article\""), content="true")
  inspect(about_html.contains("data-layout-kind=\"page\""), content="true")
}

///|
test "runtime cli build emits theme vars css and declared slot injections" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_basic", "theme-v2-vars",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let vars_css = @runtime.io_read_file_to_string(
    fixture_root + "/dist/assets/theme-vars.css",
  ) catch {
    _ => panic()
  }
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello/index.html",
  ) catch {
    _ => panic()
  }
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about/index.html",
  ) catch {
    _ => panic()
  }
  inspect(vars_css.contains("--moonink-color-bg: #fff8e1;"), content="true")
  inspect(vars_css.contains("--moonink-spacing-gap: 1.5rem;"), content="true")
  inspect(
    index_html.contains("href=\"/assets/theme-vars.css\""),
    content="true",
  )
  inspect(
    hello_html.contains("href=\"/assets/theme-vars.css\""),
    content="true",
  )
  inspect(
    about_html.contains("href=\"/assets/theme-vars.css\""),
    content="true",
  )
  inspect(index_html.contains("data-analytics=\"plausible\""), content="true")
  inspect(index_html.contains("src=\"/assets/site-init.js\""), content="true")
  inspect(index_html.contains("moonink-default.css"), content="false")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/site-init.js"),
    content="true",
  )
}

///|
test "runtime cli build renders moonink nemophila fixture shells" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_nemophila", "theme-v2-nemophila-shells",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about/index.html",
  ) catch {
    _ => panic()
  }
  let article_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/essays/stone-garden/index.html",
  ) catch {
    _ => panic()
  }
  inspect(
    index_html.contains("data-theme-v2=\"moonink-nemophila\""),
    content="true",
  )
  inspect(index_html.contains("data-layout-kind=\"index\""), content="true")
  inspect(about_html.contains("data-layout-kind=\"page\""), content="true")
  inspect(article_html.contains("data-layout-kind=\"article\""), content="true")
}

///|
test "runtime cli build emits moonink nemophila assets and structure" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_nemophila", "theme-v2-nemophila-assets",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  let article_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/essays/stone-garden/index.html",
  ) catch {
    _ => panic()
  }
  let vars_css = @runtime.io_read_file_to_string(
    fixture_root + "/dist/assets/theme-vars.css",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("moonink-nemophila.css"), content="true")
  inspect(index_html.contains("class=\"nemophila-home\""), content="true")
  inspect(index_html.contains("Koz"), content="true")
  inspect(article_html.contains("class=\"nemophila-article\""), content="true")
  inspect(article_html.contains("class=\"nemophila-cover\""), content="true")
  inspect(article_html.contains("class=\"nemophila-author-card\""), content="true")
  inspect(vars_css.contains("--moonink-color-base: #6c9ae4;"), content="true")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/moonink-nemophila.css"),
    content="true",
  )
}

///|
test "runtime cli build uses moonink nemophila page fallback for generated surfaces" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_nemophila", "theme-v2-nemophila-generated",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let archive_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/archive/index.html",
  ) catch {
    _ => panic()
  }
  let article_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/essays/stone-garden/index.html",
  ) catch {
    _ => panic()
  }
  inspect(archive_html.contains("class=\"nemophila-page\""), content="true")
  inspect(article_html.contains("class=\"nemophila-toc\""), content="true")
  inspect(
    article_html.contains("class=\"nemophila-author-card\""),
    content="true",
  )
}

///|
test "runtime cli build uses configured theme directory" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_basic", "theme-v2-config-selector",
  )
  @runtime.io_copy_dir_recursive(
    fixture_root + "/theme",
    fixture_root + "/alt-theme",
  ) catch {
    _ => panic()
  }
  @runtime.io_remove_dir_all(fixture_root + "/theme") catch {
    _ => panic()
  }
  let config_json =
    #|{
    #|  "site_name": "Theme V2 Basic",
    #|  "theme": "alt-theme",
    #|  "theme_config": {
    #|    "color": {
    #|      "bg": "#fff8e1"
    #|    },
    #|    "slots": {
    #|      "head": "<meta data-analytics=\"plausible\">",
    #|      "scripts": "<script src=\"/assets/site-init.js\"></script>"
    #|    }
    #|  }
    #|}
  @runtime.io_write_string(fixture_root + "/moonink.json", config_json) catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("data-theme-v2=\"basic\""), content="true")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/site-init.js"),
    content="true",
  )
}

///|
test "runtime cli check reports theme v2 missing partial" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_invalid_missing_partial", "theme-v2-check-fail",
  )
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("theme/template"), content="true")
  inspect(
    outcome.message.contains("Failed to load active theme bundle"),
    content="true",
  )
  inspect(
    outcome.message.contains("MissingPartial(name=\"header\")"),
    content="true",
  )
}

///|
test "runtime cli check reports illegal page override field" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_page_overrides", "theme-v2-override-check",
  )
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("theme/template"), content="true")
  inspect(
    outcome.message.contains("unsupported page override `banner`"),
    content="true",
  )
  inspect(
    outcome.message.contains("Allowed page overrides: layout, summary"),
    content="true",
  )
}

///|
test "runtime cli check reports invalid configured theme path" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/minimal", "check-invalid-theme-path",
  )
  let config_json =
    #|{"site_name": "Fixture Site", "theme": "../bad-theme"}
  @runtime.io_write_string(fixture_root + "/moonink.json", config_json) catch {
    _ => panic()
  }
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[check] theme/template"), content="true")
  inspect(
    outcome.message.contains("Failed to resolve active theme path"),
    content="true",
  )
  inspect(
    outcome.message.contains("parent traversal is not allowed"),
    content="true",
  )
}

///|
test "runtime cli check ignores theme files under configured content dir" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_basic", "check-content-dir-theme-ignore",
  )
  @runtime.io_ensure_dir(fixture_root + "/docs") catch {
    _ => panic()
  }
  @runtime.io_copy_file(
    fixture_root + "/index.md",
    fixture_root + "/docs/index.md",
  ) catch {
    _ => panic()
  }
  @runtime.io_copy_file(
    fixture_root + "/hello.md",
    fixture_root + "/docs/hello.md",
  ) catch {
    _ => panic()
  }
  @runtime.io_copy_file(
    fixture_root + "/about.html",
    fixture_root + "/docs/about.html",
  ) catch {
    _ => panic()
  }
  @runtime.io_copy_dir_recursive(
    fixture_root + "/theme",
    fixture_root + "/docs/theme",
  ) catch {
    _ => panic()
  }
  @runtime.io_write_string(
    fixture_root + "/docs/layout.html",
    "<html data-template=\"content-dir\"></html>",
  ) catch {
    _ => panic()
  }
  let config_json =
    #|{
    #|  "site_name": "Theme V2 Basic",
    #|  "content_dir": "docs",
    #|  "theme": "docs/theme",
    #|  "template_file": "docs/layout.html"
    #|}
  @runtime.io_write_string(fixture_root + "/moonink.json", config_json) catch {
    _ => panic()
  }
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(outcome.message.contains("processed: 3"), content="true")
  inspect(outcome.message.contains("diagnostics: 0"), content="true")
}

///|
test "runtime cli check reports missing theme v2 layout for page kind" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_basic", "theme-v2-missing-kind-layout-check",
  )
  let manifest =
    #|{
    #|  "name": "fixture-v2",
    #|  "layouts": {
    #|    "index": "layouts/index.html",
    #|    "page": "layouts/page.html"
    #|  }
    #|}
  @runtime.io_write_string(fixture_root + "/theme/theme.json", manifest) catch {
    _ => panic()
  }
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("theme/template"), content="true")
  inspect(
    outcome.message.contains("missing theme layout `article`"),
    content="true",
  )
  inspect(outcome.message.contains("[hello.md]"), content="true")
}

///|
test "runtime cli check reports missing theme v2 layout for layout override" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_page_overrides", "theme-v2-missing-override-layout-check",
  )
  let index_source =
    #|---
    #|title: Home
    #|type: page
    #|layout: landing
    #|theme_summary: Quick intro
    #|---
    #|
    #|# Home
  @runtime.io_write_string(fixture_root + "/index.md", index_source) catch {
    _ => panic()
  }
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("frontmatter"), content="true")
  inspect(
    outcome.message.contains(
      "Frontmatter field `layout` must be one of `article`, `page`, or `home`",
    ),
    content="true",
  )
  inspect(outcome.message.contains("[index.md]"), content="true")
}

///|
test "runtime cli build exposes theme v2 section collection" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_basic", "theme-v2-section-collection",
  )
  let index_layout =
    #|<html data-theme-v2="basic" data-layout-kind="index" data-section-count="{{ collections.sections.count }}"><body>{% for item in collections.sections.items %}<span class="section-item">{{ item.title }}</span>{% endfor %}<main data-page-kind="{{ page.kind }}">{{ page.body_html }}</main></body></html>
  @runtime.io_write_string(
    fixture_root + "/theme/layouts/index.html",
    index_layout,
  ) catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("data-section-count=\"1\""), content="true")
  inspect(
    index_html.contains("<span class=\"section-item\">Home</span>"),
    content="true",
  )
}

///|
test "runtime cli build keeps output when theme v2 preflight fails" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_basic", "theme-v2-preflight-build-failure",
  )
  let stale_path = fixture_root + "/dist/stale.txt"
  @runtime.io_ensure_dir(fixture_root + "/dist") catch {
    _ => panic()
  }
  @runtime.io_write_string(stale_path, "stale") catch {
    _ => panic()
  }
  let manifest =
    #|{
    #|  "name": "fixture-v2",
    #|  "layouts": {
    #|    "index": "layouts/index.html",
    #|    "page": "layouts/page.html"
    #|  }
    #|}
  @runtime.io_write_string(fixture_root + "/theme/theme.json", manifest) catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("missing theme layout `article`"),
    content="true",
  )
  inspect(@runtime.io_path_exists(stale_path), content="true")
}

///|
test "runtime cli check skips layout lookup for unsupported layout override" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_page_overrides", "theme-v2-override-parity-check",
  )
  let manifest =
    #|{
    #|  "name": "fixture-v2-overrides",
    #|  "layouts": {
    #|    "index": "layouts/index.html",
    #|    "page": "layouts/index.html",
    #|    "article": "layouts/index.html"
    #|  },
    #|  "page_overrides": ["summary"]
    #|}
  @runtime.io_write_string(fixture_root + "/theme/theme.json", manifest) catch {
    _ => panic()
  }
  let index_source =
    #|---
    #|title: Home
    #|type: page
    #|layout: landing
    #|theme_summary: Quick intro
    #|---
    #|
    #|# Home
  @runtime.io_write_string(fixture_root + "/index.md", index_source) catch {
    _ => panic()
  }
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("unsupported page override `layout`"),
    content="true",
  )
  inspect(
    outcome.message.contains("missing theme layout `landing`"),
    content="false",
  )
}

///|
test "runtime cli build renders automatic navigation for direct routes" {
  let fixture_root = "fixtures/v2/nav_direct_basic"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  let guide_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/guide/index.html",
  ) catch {
    _ => panic()
  }
  let install_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/guide/install.html",
  ) catch {
    _ => panic()
  }
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello.html",
  ) catch {
    _ => panic()
  }
  let guide_tips_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/guide/tips.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("data-template=\"nav-direct\""), content="true")
  inspect(
    index_html.contains("<nav data-moonink-nav=\"auto\">"),
    content="true",
  )
  inspect(
    index_html.contains("href=\"/guide/index.html\">Documentation</a>"),
    content="true",
  )
  inspect(
    index_html.contains("href=\"/guide/install.html\">Quick Start</a>"),
    content="true",
  )
  inspect(
    index_html.contains("href=\"/guide/config.html\">Config</a>"),
    content="false",
  )
  inspect(index_html.contains("Direct Hello Article"), content="false")
  inspect(index_html.contains("data-section-title=\"Home\""), content="true")
  inspect(index_html.contains("data-section-url=\"/\""), content="true")
  inspect(
    index_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Home</span></nav>",
    ),
    content="true",
  )
  inspect(
    guide_html.contains(
      "<li data-active=\"true\" data-ancestor=\"false\" data-index=\"true\" data-expanded=\"true\" data-current=\"page\"><a href=\"/guide/index.html\">Documentation</a>",
    ),
    content="true",
  )
  inspect(
    guide_html.contains("data-section-title=\"Documentation\""),
    content="true",
  )
  inspect(
    guide_html.contains("data-section-url=\"/guide/index.html\""),
    content="true",
  )
  inspect(
    guide_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Guide</span></nav>",
    ),
    content="true",
  )
  inspect(
    install_html.contains(
      "<li data-active=\"false\" data-ancestor=\"true\" data-index=\"true\" data-expanded=\"true\" data-current=\"ancestor\"><a href=\"/guide/index.html\">Documentation</a>",
    ),
    content="true",
  )
  inspect(
    install_html.contains(
      "<li data-active=\"true\" data-ancestor=\"false\" data-index=\"false\" data-expanded=\"true\" data-current=\"page\"><a href=\"/guide/install.html\">Quick Start</a>",
    ),
    content="true",
  )
  inspect(
    install_html.contains("href=\"/guide/config.html\">Config</a>"),
    content="false",
  )
  inspect(
    install_html.contains("data-section-title=\"Documentation\""),
    content="true",
  )
  inspect(
    install_html.contains("data-section-url=\"/guide/index.html\""),
    content="true",
  )
  inspect(
    install_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Install</span></nav>",
    ),
    content="true",
  )
  inspect(hello_html.contains("data-section-title=\"\""), content="true")
  inspect(hello_html.contains("data-section-url=\"\""), content="true")
  inspect(
    hello_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Hello Article</span></nav>",
    ),
    content="true",
  )
  inspect(
    guide_tips_html.contains("data-section-title=\"Documentation\""),
    content="true",
  )
  inspect(
    guide_tips_html.contains("data-section-url=\"/guide/index.html\""),
    content="true",
  )
  inspect(
    guide_tips_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Guide Tips</span></nav>",
    ),
    content="true",
  )
}

///|
test "runtime cli build applies configured template file with direct routes" {
  let fixture_root = "fixtures/v2/template_direct_route"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/hello.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/about.html"),
    content="true",
  )
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello.html",
  ) catch {
    _ => panic()
  }
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about.html",
  ) catch {
    _ => panic()
  }
  let guide_tips_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/guide/tips.html",
  ) catch {
    _ => panic()
  }
  inspect(
    hello_html.contains("data-template=\"direct-custom\""),
    content="true",
  )
  inspect(
    hello_html.contains("<title>Hello :: Direct Template Fixture</title>"),
    content="true",
  )
  inspect(hello_html.contains("data-url=\"/hello.html\""), content="true")
  inspect(hello_html.contains("Hello Direct Template"), content="true")
  inspect(hello_html.contains("<nav class=\"template-nav\">"), content="true")
  inspect(hello_html.contains("href=\"/\">Home</a>"), content="true")
  inspect(
    hello_html.contains("data-page-header-title=\"Hello\""),
    content="true",
  )
  inspect(hello_html.contains("data-section-title=\"\""), content="true")
  inspect(hello_html.contains("data-section-url=\"\""), content="true")
  inspect(
    hello_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Hello</span></nav>",
    ),
    content="true",
  )
  inspect(
    guide_tips_html.contains("data-page-header-title=\"Guide Tips\""),
    content="true",
  )
  inspect(
    guide_tips_html.contains("data-section-title=\"Documentation\""),
    content="true",
  )
  inspect(
    guide_tips_html.contains("data-section-url=\"/guide/index.html\""),
    content="true",
  )
  inspect(
    guide_tips_html.contains(
      "<nav data-moonink-breadcrumb=\"auto\" aria-label=\"Breadcrumb\"><span aria-current=\"page\">Guide Tips</span></nav>",
    ),
    content="true",
  )
  inspect(about_html.contains("About Direct Template"), content="true")
  inspect(about_html.contains("data-url=\"/about.html\""), content="true")
  inspect(about_html.contains("href=\"/\">Home</a>"), content="true")
  inspect(about_html.contains("data-section-title=\"\""), content="true")
  inspect(about_html.contains("data-section-url=\"\""), content="true")
}

///|
test "runtime cli build emits search index contract fixture" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/search_index_contract", "search-index-contract-build",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let search_index_path = fixture_root + "/dist/search-index.json"
  inspect(@runtime.io_path_exists(search_index_path), content="true")
  let search_index = @runtime.io_read_file_to_string(search_index_path) catch {
    _ => panic()
  }
  inspect(search_index.contains("\"title\":\"Home\""), content="true")
  inspect(search_index.contains("\"title\":\"Guide\""), content="true")
  inspect(search_index.contains("\"title\":\"about\""), content="true")
  inspect(
    search_index.contains("\"excerpt\":\"Explicit home excerpt wins.\""),
    content="true",
  )
  inspect(
    search_index.contains("\"excerpt\":\"Explicit guide excerpt wins.\""),
    content="true",
  )
  inspect(
    search_index.contains(
      "\"excerpt\":\"About Search HTML fallback excerpt from body copy.\"",
    ),
    content="true",
  )
  inspect(
    search_index.contains("\"tags\":[\"search\",\"contract\"]"),
    content="true",
  )
  inspect(search_index.contains("\"date\":\"2026-04-15\""), content="true")
  inspect(search_index.contains("\"url\":\"/guide/\""), content="true")
  inspect(search_index.contains("\"url\":\"/about/\""), content="true")
}

///|
test "runtime cli build omits search false content from search index" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/m2_public_shell_basic", "m2-search-index-contract",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let search_index = @runtime.io_read_file_to_string(
    fixture_root + "/dist/search-index.json",
  ) catch {
    _ => panic()
  }
  inspect(search_index.contains("\"title\":\"Stone Garden\""), content="true")
  inspect(search_index.contains("\"title\":\"Companion Note\""), content="true")
  inspect(
    search_index.contains("\"title\":\"Private Scratchpad\""),
    content="false",
  )
  inspect(search_index.contains("\"kind\":\"article\""), content="true")
  inspect(
    search_index.contains(
      "\"summary\":\"Designing a site that feels like a room you can return to.\"",
    ),
    content="true",
  )
}

///|
test "runtime cli check reports non boolean search field" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/m2_public_shell_basic", "m2-invalid-search-frontmatter",
  )
  let invalid_search_note =
    #|---
    #|title: Private Scratchpad
    #|search: maybe
    #|---
    #|
    #|# Private Scratchpad
  @runtime.io_write_string(
    fixture_root + "/notes/private-scratchpad.md",
    invalid_search_note,
  ) catch {
    _ => panic()
  }
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("Frontmatter field `search` must be a boolean"),
    content="true",
  )
}

///|
test "runtime cli build emits generated search page" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/m2_public_shell_basic", "m2-generated-search-page",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/search/index.html"),
    content="true",
  )
}

///|
test "runtime cli build rejects reserved generated roots from source content" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/m2_public_shell_basic", "m2-reserved-root-conflict",
  )
  @runtime.io_ensure_dir(fixture_root + "/search") catch {
    _ => panic()
  }
  @runtime.io_write_string(
    fixture_root + "/search/index.md",
    "# This should conflict\n",
  ) catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("reserved generated root"), content="true")
  inspect(outcome.message.contains("search"), content="true")
}

///|
test "runtime cli build falls back to page layout for custom theme search page" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/theme_v2_basic", "m2-search-page-theme-fallback",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let search_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/search/index.html",
  ) catch {
    _ => panic()
  }
  inspect(search_html.contains("data-layout-kind=\"page\""), content="true")
  inspect(search_html.contains("moonink-search.js"), content="true")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/moonink-search.js"),
    content="true",
  )
}

///|
test "runtime cli build renders the built in search ui" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/m2_public_shell_basic", "m2-search-ui",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let search_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/search/index.html",
  ) catch {
    _ => panic()
  }
  inspect(search_html.contains("id=\"moonink-search-query\""), content="true")
  inspect(search_html.contains("data-moonink-search-results"), content="true")
  inspect(search_html.contains("moonink-search.js"), content="true")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/moonink-search.js"),
    content="true",
  )
}

///|
test "runtime cli build renders configured homepage hero and featured items" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/m2_public_shell_basic", "m2-homepage-curation",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("Notes From The Workbench"), content="true")
  inspect(index_html.contains("Stone Garden"), content="true")
  inspect(index_html.contains("Quiet Joins"), content="true")
  inspect(index_html.contains("href=\"/search/\""), content="true")
  inspect(index_html.contains("href=\"/tags/\""), content="true")
}

///|
test "runtime cli build fails when homepage featured path is missing" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/m2_public_shell_basic", "m2-homepage-missing-featured",
  )
  let invalid_homepage_config =
    #|{
    #|  "site_name": "MoonInk Lab",
    #|  "site_url": "https://moonink.example",
    #|  "theme_config": {
    #|    "homepage": {
    #|      "featured_paths": ["notes/missing.md"],
    #|      "recent_count": 2
    #|    }
    #|  }
    #|}
  @runtime.io_write_string(
    fixture_root + "/moonink.json",
    invalid_homepage_config,
  ) catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("homepage.featured_paths"), content="true")
}

///|
test "runtime cli build renders curated homepage shell" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/m2_public_shell_basic", "m2-homepage-shell",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("class=\"home-hero\""), content="true")
  inspect(index_html.contains("Notes From The Workbench"), content="true")
  inspect(index_html.contains("class=\"home-module-grid\""), content="true")
  inspect(index_html.contains("href=\"/search/\""), content="true")
  inspect(index_html.contains("href=\"/archive/\""), content="true")
}

///|
test "runtime cli build emits tags series and archive pages" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/m2_public_shell_basic", "m2-collection-pages",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")

  let tags_index = @runtime.io_read_file_to_string(
    fixture_root + "/dist/tags/index.html",
  ) catch {
    _ => panic()
  }
  let garden_tag = @runtime.io_read_file_to_string(
    fixture_root + "/dist/tags/garden/index.html",
  ) catch {
    _ => panic()
  }
  let series_page = @runtime.io_read_file_to_string(
    fixture_root + "/dist/series/notebook-atlas/index.html",
  ) catch {
    _ => panic()
  }
  let archive_page = @runtime.io_read_file_to_string(
    fixture_root + "/dist/archive/index.html",
  ) catch {
    _ => panic()
  }

  inspect(tags_index.contains("garden"), content="true")
  inspect(garden_tag.contains("Stone Garden"), content="true")
  inspect(garden_tag.contains("Companion Note"), content="true")
  inspect(series_page.contains("Notebook Atlas"), content="true")
  inspect(series_page.contains("Quiet Joins"), content="true")
  inspect(archive_page.contains("2026"), content="true")
}

///|
test "runtime cli build renders m3 surfaces and exclusions" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/search_index_contract", "m3-surface-build",
  )
  let config_source =
    #|{
    #|  "site_name": "M3 Fixture",
    #|  "site_url": "https://example.com/m3",
    #|  "content_dir": ".",
    #|  "output_dir": "dist",
    #|  "exclude": ["dist"],
    #|  "route_style": "pretty",
    #|  "author": {
    #|    "name": "Site Author",
    #|    "bio": "Writes careful notes.",
    #|    "homepage_text": "Building intentional surfaces.",
    #|    "links": [
    #|      { "label": "GitHub", "url": "https://example.com/github" }
    #|    ]
    #|  }
    #|}
  @runtime.io_write_string(fixture_root + "/moonink.json", config_source) catch {
    _ => panic()
  }
  let guide_source =
    #|---
    #|title: Guide
    #|summary: Explicit guide excerpt wins.
    #|description: Guide description should not win.
    #|date: 2026-04-15
    #|tags: [search, contract]
    #|author: Guest Writer
    #|---
    #|
    #|# Guide
    #|
    #|Guide search body content.
  @runtime.io_write_string(fixture_root + "/guide.md", guide_source) catch {
    _ => panic()
  }
  let quiet_source =
    #|---
    #|title: Quiet Note
    #|summary: Hidden from search, visible elsewhere.
    #|date: 2026-04-16
    #|tags: [quiet]
    #|featured: true
    #|search: false
    #|---
    #|
    #|# Quiet Note
    #|
    #|Still published.
  @runtime.io_write_string(fixture_root + "/quiet.md", quiet_source) catch {
    _ => panic()
  }
  let draft_source =
    #|---
    #|title: Draft Note
    #|date: 2026-04-17
    #|tags: [quiet]
    #|draft: true
    #|---
    #|
    #|# Draft Note
    #|
    #|Should never ship.
  @runtime.io_write_string(fixture_root + "/draft-note.md", draft_source) catch {
    _ => panic()
  }
  let series_old_source =
    #|---
    #|title: Series Old
    #|date: 2026-04-01
    #|series: River Notes
    #|---
    #|
    #|# Series Old
    #|
    #|The first entry.
  @runtime.io_write_string(fixture_root + "/series-old.md", series_old_source) catch {
    _ => panic()
  }
  let series_new_source =
    #|---
    #|title: Series New
    #|date: 2026-04-20
    #|series: River Notes
    #|pinned: true
    #|---
    #|
    #|# Series New
    #|
    #|The newer entry.
  @runtime.io_write_string(fixture_root + "/series-new.md", series_new_source) catch {
    _ => panic()
  }
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/search/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/archive/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/tags/quiet/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(
      fixture_root + "/dist/series/river-notes/index.html",
    ),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/quiet/index.html"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/draft-note/index.html"),
    content="false",
  )
  let index_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/index.html",
  ) catch {
    _ => panic()
  }
  let search_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/search/index.html",
  ) catch {
    _ => panic()
  }
  let quiet_tag_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/tags/quiet/index.html",
  ) catch {
    _ => panic()
  }
  let guide_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/guide/index.html",
  ) catch {
    _ => panic()
  }
  let series_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/series/river-notes/index.html",
  ) catch {
    _ => panic()
  }
  let archive_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/archive/index.html",
  ) catch {
    _ => panic()
  }
  let search_index = @runtime.io_read_file_to_string(
    fixture_root + "/dist/search-index.json",
  ) catch {
    _ => panic()
  }
  inspect(index_html.contains("Building intentional surfaces."), content="true")
  inspect(index_html.contains("Quiet Note"), content="true")
  inspect(search_html.contains("data-source=\"quiet.md\""), content="false")
  inspect(
    search_html.contains("data-source=\"draft-note.md\""),
    content="false",
  )
  inspect(quiet_tag_html.contains("Quiet Note"), content="true")
  inspect(quiet_tag_html.contains("Draft Note"), content="false")
  inspect(guide_html.contains("Guest Writer"), content="true")
  inspect(guide_html.contains("Writes careful notes."), content="true")
  inspect(search_index.contains("\"author\":\"Guest Writer\""), content="true")
  inspect(search_index.contains("\"title\":\"Quiet Note\""), content="false")
  inspect(search_index.contains("\"title\":\"Draft Note\""), content="false")
  let old_offset = find_substring_or_panic(
    series_html, "data-source=\"series-old.md\"",
  )
  let new_offset = find_substring_or_panic(
    series_html, "data-source=\"series-new.md\"",
  )
  inspect((old_offset < new_offset).to_string(), content="true")
  let archive_new = find_substring_or_panic(
    archive_html, "data-source=\"series-new.md\"",
  )
  let archive_quiet = find_substring_or_panic(
    archive_html, "data-source=\"quiet.md\"",
  )
  let archive_guide = find_substring_or_panic(
    archive_html, "data-source=\"guide.md\"",
  )
  let archive_old = find_substring_or_panic(
    archive_html, "data-source=\"series-old.md\"",
  )
  inspect((archive_new < archive_quiet).to_string(), content="true")
  inspect((archive_quiet < archive_guide).to_string(), content="true")
  inspect((archive_guide < archive_old).to_string(), content="true")
}

///|
test "runtime cli check reports m3 frontmatter contract failures" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/search_index_contract", "m3-frontmatter-check",
  )
  let invalid_source =
    #|---
    #|title: Home
    #|type: page
    #|featured: [true]
    #|search: maybe
    #|toc: [true]
    #|layout: landing
    #|---
    #|
    #|# Home
  @runtime.io_write_string(fixture_root + "/index.md", invalid_source) catch {
    _ => panic()
  }
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(outcome.message.contains("[check] frontmatter"), content="true")
  inspect(
    outcome.message.contains("Frontmatter field `featured` must be a boolean"),
    content="true",
  )
  inspect(
    outcome.message.contains("Frontmatter field `search` must be a boolean"),
    content="true",
  )
  inspect(
    outcome.message.contains("Frontmatter field `toc` must be a boolean"),
    content="true",
  )
  inspect(
    outcome.message.contains(
      "Frontmatter field `layout` must be one of `article`, `page`, or `home`",
    ),
    content="true",
  )
  inspect(
    outcome.message.contains("missing theme layout `landing`"),
    content="false",
  )
}

///|
test "runtime cli build emits canonical og and rss outputs for m2 pages" {
  let fixture_root = prepare_isolated_fixture_copy(
    "fixtures/v2/m2_public_shell_basic", "m2-public-metadata",
  )
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")

  let article_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/essays/stone-garden/index.html",
  ) catch {
    _ => panic()
  }
  let rss_xml = @runtime.io_read_file_to_string(fixture_root + "/dist/rss.xml") catch {
    _ => panic()
  }

  inspect(
    article_html.contains(
      "<link rel=\"canonical\" href=\"https://moonink.example/essays/stone-garden/\"",
    ),
    content="true",
  )
  inspect(
    article_html.contains(
      "<meta property=\"og:title\" content=\"Stone Garden\"",
    ),
    content="true",
  )
  inspect(article_html.contains("application/rss+xml"), content="true")
  inspect(rss_xml.contains("<title>MoonInk Lab</title>"), content="true")
  inspect(
    rss_xml.contains(
      "<link>https://moonink.example/essays/stone-garden/</link>",
    ),
    content="true",
  )
}

///|
test "runtime cli build reports missing configured template file" {
  let config_path = "fixtures/v2/missing_template_file/moonink.json"
  let outcome = @cli.run_build_command_runtime_from_config(config_path)
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[build] failed during file emission"),
    content="true",
  )
  inspect(outcome.message.contains("load_template"), content="true")
  inspect(outcome.message.contains("templates/missing.html"), content="true")
}

///|
test "runtime cli build resolves wikilinks for pretty routes" {
  let fixture_root = "fixtures/v2/wikilinks_pretty"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello/index.html",
  ) catch {
    _ => panic()
  }
  inspect(hello_html.contains("href=\"/about/\""), content="true")
  inspect(hello_html.contains(">about<"), content="true")
  inspect(hello_html.contains("href=\"/\""), content="true")
  inspect(hello_html.contains(">Home<"), content="true")
}

///|
test "runtime cli build renders backlinks for pretty routes" {
  let fixture_root = "fixtures/v2/wikilinks_pretty"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about/index.html",
  ) catch {
    _ => panic()
  }
  inspect(about_html.contains("aria-label=\"Backlinks\""), content="true")
  inspect(about_html.contains("href=\"/hello/\""), content="true")
  inspect(about_html.contains(">Hello<"), content="true")
}

///|
test "runtime cli build resolves wikilinks for direct routes" {
  let fixture_root = "fixtures/v2/wikilinks_direct"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let hello_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/hello.html",
  ) catch {
    _ => panic()
  }
  inspect(hello_html.contains("href=\"/about.html\""), content="true")
  inspect(hello_html.contains(">about<"), content="true")
  inspect(hello_html.contains("href=\"/\""), content="true")
  inspect(hello_html.contains(">Home<"), content="true")
}

///|
test "runtime cli build renders backlinks for direct routes" {
  let fixture_root = "fixtures/v2/wikilinks_direct"
  let outcome = @cli.run_build_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="0")
  let about_html = @runtime.io_read_file_to_string(
    fixture_root + "/dist/about.html",
  ) catch {
    _ => panic()
  }
  inspect(about_html.contains("aria-label=\"Backlinks\""), content="true")
  inspect(about_html.contains("href=\"/hello.html\""), content="true")
  inspect(about_html.contains(">Hello<"), content="true")
}
