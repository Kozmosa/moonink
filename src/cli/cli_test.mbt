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
  }
  let inventory : @core.ContentInventory = {
    root: "fixtures/v2/minimal",
    files: [],
    total_articles: 1,
    total_pages: 2,
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
        content_kind: @core.ContentKind::Page,
        format: @core.SourceFormat::Markdown,
        frontmatter: {
          ..@core.Frontmatter::default(),
          title: Some("Home"),
          content_type: Some("page"),
        },
        sort_key: "index.md",
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
        content_kind: @core.ContentKind::Page,
        format: @core.SourceFormat::Html,
        frontmatter: @core.Frontmatter::default(),
        sort_key: "about.html",
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
        content_kind: @core.ContentKind::Article,
        format: @core.SourceFormat::Markdown,
        frontmatter: @core.Frontmatter::default(),
        sort_key: "hello.md",
      },
    },
  ]
  let assembly = @cli.build_site_assembly_model(config, inputs, inventory)
  inspect(assembly.page_count, content="2")
  inspect(assembly.article_count, content="1")
  inspect(assembly.navigation_items, content="2")
  inspect(assembly.pages.length(), content="3")
  inspect(assembly.navigation.items.length(), content="2")
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
      source_path: "hello.md",
      url_path: "/hello/",
      content_kind: @core.ContentKind::Article,
      is_index: false,
    },
  ]
  let navigation = @cli.build_navigation_model(pages)
  inspect(navigation.total_items, content="3")
  inspect(navigation.items.length(), content="2")
  inspect(navigation.items[0].title, content="Home")
  inspect(navigation.items[1].title, content="Documentation")
  inspect(navigation.items[1].children.length(), content="1")
  inspect(navigation.items[1].children[0].title, content="Quick Start")
}

///|
test "build navigation model treats section index as landing item" {
  let pages : Array[@core.SitePage] = [
    {
      title: "Guide",
      nav_title: "Guide",
      nav_hidden: false,
      description: "",
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
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: {
      ..@core.Frontmatter::default(),
      title: Some("Install Guide"),
    },
    sort_key: "guide/install.md",
  }
  let untitled_meta : @core.PageMeta = {
    source_path: "guide/config.md",
    url_path: "/guide/config/",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: @core.Frontmatter::default(),
    sort_key: "guide/config.md",
  }
  let index_meta : @core.PageMeta = {
    source_path: "index.md",
    url_path: "/",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: @core.Frontmatter::default(),
    sort_key: "index.md",
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
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: {
      ..@core.Frontmatter::default(),
      title: Some("Install Guide"),
      extra: { "nav_title": "Quick Start", "nav_hidden": "true" },
    },
    sort_key: "guide/install.md",
  }
  let default_meta : @core.PageMeta = {
    source_path: "guide/config.md",
    url_path: "/guide/config/",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: @core.Frontmatter::default(),
    sort_key: "guide/config.md",
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
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: {
      ..@core.Frontmatter::default(),
      title: Some("Advanced Guide"),
      extra: { "nav_title": "" },
    },
    sort_key: "guide/advanced.md",
  }
  let loose_hidden_meta : @core.PageMeta = {
    source_path: "guide/draft.md",
    url_path: "/guide/draft/",
    content_kind: @core.ContentKind::Page,
    format: @core.SourceFormat::Markdown,
    frontmatter: {
      ..@core.Frontmatter::default(),
      extra: { "nav_hidden": "TRUE" },
    },
    sort_key: "guide/draft.md",
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
      content_kind: @core.ContentKind::Page,
      format: @core.SourceFormat::Markdown,
      frontmatter: {
        ..@core.Frontmatter::default(),
        title: Some("Home"),
        description: Some("Landing page"),
        content_type: Some("page"),
      },
      sort_key: "index.md",
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
      content_kind: @core.ContentKind::Article,
      format: @core.SourceFormat::Markdown,
      frontmatter: {
        ..@core.Frontmatter::default(),
        extra: { "nav_title": "Read Me", "nav_hidden": "true" },
      },
      sort_key: "hello.md",
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
  "[serve] runtime execution required\naddress: http://\{host}:\{port}\npreview root: \{preview_root}\nconfig: \{config_path}" +
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
  inspect(hello_html.contains("<h1>Hello World</h1>"), content="true")
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
  inspect(outcome.message.contains("[check] completed"), content="true")
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
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[check] completed with diagnostics"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/check-preview/index.html"),
    content="false",
  )
}

///|
test "runtime cli check reports wikilink diagnostics without writing output" {
  let fixture_root = "fixtures/v2/check_wikilink_warning"
  let outcome = @cli.run_check_command_runtime_from_config(
    fixture_root + "/moonink.json",
  )
  inspect(outcome.exit_code, content="1")
  inspect(
    outcome.message.contains("[check] completed with diagnostics"),
    content="true",
  )
  inspect(
    outcome.message.contains("Unresolved wikilink target: missing-page"),
    content="true",
  )
  inspect(outcome.message.contains("[hello.md]"), content="true")
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
  inspect(
    outcome.message.contains("[check] failed during theme loading"),
    content="true",
  )
  inspect(outcome.message.contains("load_template"), content="true")
  inspect(outcome.message.contains("templates/missing.html"), content="true")
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/index.html"),
    content="false",
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
  inspect(index_html.contains("Hello Article"), content="false")
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
  inspect(index_html.contains("data-theme=\"default\""), content="true")
  inspect(
    index_html.contains("href=\"/assets/moonink-default.css\""),
    content="true",
  )
  inspect(index_html.contains("class=\"moonink-page\""), content="true")
  inspect(index_html.contains("data-content-layout=\"page\""), content="true")
  inspect(
    index_html.contains("class=\"content-title\">Home</h1>"),
    content="true",
  )
  inspect(
    @runtime.io_path_exists(fixture_root + "/dist/assets/moonink-default.css"),
    content="true",
  )
  inspect(index_html.contains("Fixture Site"), content="true")
  inspect(index_html.contains("data-kind=\"page\""), content="true")
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
    hello_html.contains("class=\"content-kind-label\">article</p>"),
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
  inspect(hello_html.contains("Hello World"), content="true")
  inspect(about_html.contains("This is a static HTML page."), content="true")
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
  inspect(
    index_html.contains("data-section-url=\"/index.html\""),
    content="true",
  )
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
  inspect(hello_html.contains("href=\"/index.html\">Home</a>"), content="true")
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
  inspect(about_html.contains("href=\"/index.html\">Home</a>"), content="true")
  inspect(about_html.contains("data-section-title=\"\""), content="true")
  inspect(about_html.contains("data-section-url=\"\""), content="true")
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
  inspect(hello_html.contains("href=\"/index.html\""), content="true")
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
