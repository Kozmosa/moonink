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
  inspect(about_html.contains("About Template"), content="true")
  inspect(about_html.contains("<aside></aside>"), content="true")
  inspect(about_html.contains("data-kind=\"page\""), content="true")
  inspect(about_html.contains("data-url=\"/about/\""), content="true")
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
  inspect(about_html.contains("About Direct Template"), content="true")
  inspect(about_html.contains("data-url=\"/about.html\""), content="true")
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
