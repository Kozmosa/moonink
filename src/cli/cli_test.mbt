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
      "<li data-active=\"false\" data-ancestor=\"true\" data-index=\"true\"><a href=\"/guide/\">Guide</a>",
    ),
    content="true",
  )
  inspect(
    html.contains(
      "<li data-active=\"true\" data-ancestor=\"false\" data-index=\"false\"><a href=\"/guide/install/\">Install</a>",
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
test "build navigation model keeps only pages and nests section children" {
  let pages : Array[@core.SitePage] = [
    {
      title: "Home",
      description: "",
      source_path: "index.md",
      url_path: "/",
      content_kind: @core.ContentKind::Page,
      is_index: true,
    },
    {
      title: "Guide",
      description: "",
      source_path: "guide/index.md",
      url_path: "/guide/",
      content_kind: @core.ContentKind::Page,
      is_index: true,
    },
    {
      title: "Install",
      description: "",
      source_path: "guide/install.md",
      url_path: "/guide/install/",
      content_kind: @core.ContentKind::Page,
      is_index: false,
    },
    {
      title: "Config",
      description: "",
      source_path: "guide/config.md",
      url_path: "/guide/config/",
      content_kind: @core.ContentKind::Page,
      is_index: false,
    },
    {
      title: "Hello",
      description: "",
      source_path: "hello.md",
      url_path: "/hello/",
      content_kind: @core.ContentKind::Article,
      is_index: false,
    },
  ]
  let navigation = @cli.build_navigation_model(pages)
  inspect(navigation.total_items, content="4")
  inspect(navigation.items.length(), content="2")
  inspect(navigation.items[0].title, content="Home")
  inspect(navigation.items[1].title, content="Guide")
  inspect(navigation.items[1].children.length(), content="2")
  inspect(navigation.items[1].children[0].title, content="Config")
  inspect(navigation.items[1].children[1].title, content="Install")
}

///|
test "build navigation model treats section index as landing item" {
  let pages : Array[@core.SitePage] = [
    {
      title: "Guide",
      description: "",
      source_path: "guide/index.md",
      url_path: "/guide/",
      content_kind: @core.ContentKind::Page,
      is_index: true,
    },
    {
      title: "Advanced",
      description: "",
      source_path: "guide/advanced/index.md",
      url_path: "/guide/advanced/",
      content_kind: @core.ContentKind::Page,
      is_index: true,
    },
    {
      title: "Reference",
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
test "build site pages derives description and index flag" {
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
      frontmatter: @core.Frontmatter::default(),
      sort_key: "hello.md",
    },
  }
  let pages = @cli.build_site_pages([page_input, article_input])
  inspect(pages.length(), content="2")
  inspect(pages[0].description, content="Landing page")
  inspect(pages[0].is_index, content="true")
  inspect(pages[1].title, content="hello")
  inspect(pages[1].description, content="")
  inspect(pages[1].is_index, content="false")
}

///|
test "parse cli command supports raw command tokens" {
  inspect(@cli.parse_cli_command([]), content="Help")
  inspect(@cli.parse_cli_command(["help"]), content="Help")
  inspect(@cli.parse_cli_command(["build"]), content="Build")
  inspect(@cli.parse_cli_command(["serve"]), content="Serve")
  inspect(@cli.parse_cli_command(["onboard"]), content="Onboard")
}

///|
test "parse cli command supports full argv forms" {
  inspect(@cli.parse_cli_command(["moonink"]), content="Help")
  inspect(@cli.parse_cli_command(["moonink", "build"]), content="Build")
  inspect(@cli.parse_cli_command(["moonink", "serve"]), content="Serve")
  inspect(@cli.parse_cli_command(["moonink", "onboard"]), content="Onboard")
  inspect(
    @cli.parse_cli_command(["moonink", "doctor"]),
    content="Unknown(\"doctor\")",
  )
}

///|
test "cli run keeps build behind runtime boundary" {
  inspect(
    @cli.cli_run(["moonink", "build"]).message,
    content=(
      #|[build] runtime execution required
      #|status: use cli_exec or the runtime IO boundary to load config and discover content
    ),
  )
}

///|
test "cli run returns serve placeholder" {
  inspect(@cli.cli_run(["moonink", "serve"]).exit_code, content="0")
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
  inspect(index_html.contains("data-template=\"nav-pretty\""), content="true")
  inspect(
    index_html.contains("<nav data-moonink-nav=\"auto\">"),
    content="true",
  )
  inspect(index_html.contains("href=\"/guide/\">Guide</a>"), content="true")
  inspect(
    index_html.contains("href=\"/guide/install/\">Install</a>"),
    content="true",
  )
  inspect(index_html.contains("Hello Article"), content="false")
  inspect(
    guide_html.contains(
      "<li data-active=\"true\" data-ancestor=\"false\" data-index=\"true\"><a href=\"/guide/\">Guide</a>",
    ),
    content="true",
  )
  inspect(
    install_html.contains(
      "<li data-active=\"false\" data-ancestor=\"true\" data-index=\"true\"><a href=\"/guide/\">Guide</a>",
    ),
    content="true",
  )
  inspect(
    install_html.contains(
      "<li data-active=\"true\" data-ancestor=\"false\" data-index=\"false\"><a href=\"/guide/install/\">Install</a>",
    ),
    content="true",
  )
}

///|
test "runtime cli build writes minimal fixture html files" {
  let fixture_root = "fixtures/v2/minimal"
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
  inspect(index_html.contains("<!doctype html>"), content="true")
  inspect(index_html.contains("<title>Home</title>"), content="true")
  inspect(index_html.contains("Fixture Site"), content="true")
  inspect(index_html.contains("data-kind=\"page\""), content="true")
  inspect(index_html.contains("data-url=\"/\""), content="true")
  inspect(hello_html.contains("Hello World"), content="true")
  inspect(hello_html.contains("<title>Hello</title>"), content="true")
  inspect(hello_html.contains("data-kind=\"article\""), content="true")
  inspect(
    hello_html.contains("href=\"https://example.com/docs\""),
    content="true",
  )
  inspect(about_html.contains("data-kind=\"page\""), content="true")
  inspect(about_html.contains("data-url=\"/about/\""), content="true")
  inspect(
    about_html.contains(
      "<header><a href=\"https://example.com/docs\">Fixture Site</a></header>",
    ),
    content="true",
  )
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
  inspect(index_html.contains("data-template=\"custom\""), content="true")
  inspect(
    index_html.contains("<title>Home :: Template Fixture</title>"),
    content="true",
  )
  inspect(index_html.contains("<aside>Landing page</aside>"), content="true")
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
  inspect(about_html.contains("About Template"), content="true")
  inspect(about_html.contains("<aside></aside>"), content="true")
  inspect(about_html.contains("data-kind=\"page\""), content="true")
  inspect(about_html.contains("data-url=\"/about/\""), content="true")
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
  inspect(index_html.contains("data-template=\"nav-direct\""), content="true")
  inspect(
    index_html.contains("<nav data-moonink-nav=\"auto\">"),
    content="true",
  )
  inspect(
    index_html.contains("href=\"/guide/index.html\">Guide</a>"),
    content="true",
  )
  inspect(
    index_html.contains("href=\"/guide/install.html\">Install</a>"),
    content="true",
  )
  inspect(index_html.contains("Direct Hello Article"), content="false")
  inspect(
    guide_html.contains(
      "<li data-active=\"true\" data-ancestor=\"false\" data-index=\"true\"><a href=\"/guide/index.html\">Guide</a>",
    ),
    content="true",
  )
  inspect(
    install_html.contains(
      "<li data-active=\"false\" data-ancestor=\"true\" data-index=\"true\"><a href=\"/guide/index.html\">Guide</a>",
    ),
    content="true",
  )
  inspect(
    install_html.contains(
      "<li data-active=\"true\" data-ancestor=\"false\" data-index=\"false\"><a href=\"/guide/install.html\">Install</a>",
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
  inspect(about_html.contains("About Direct Template"), content="true")
  inspect(about_html.contains("data-url=\"/about.html\""), content="true")
  inspect(about_html.contains("href=\"/index.html\">Home</a>"), content="true")
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
