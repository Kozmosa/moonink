///|
test "load_config_result reads the minimal v2 fixture" {
  let config = match
    @runtime.load_config_result("fixtures/v2/minimal/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  inspect(config.site_name, content="Fixture Site")
  inspect(config.site_url, content="Some(\"https://example.com/docs\")")
  inspect(config.project_root, content="fixtures/v2/minimal")
  inspect(config.content_dir, content=".")
  inspect(config.output_dir, content="dist")
  inspect(config.template_file, content="None")
  inspect(config.text_encoding, content="utf-8")
}

///|
test "load_template_source_result returns none without configured template" {
  let config = match
    @runtime.load_config_result("fixtures/v2/minimal/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  inspect(@runtime.load_template_source_result(config), content="Ok(None)")
}

///|
test "load_template_source_result reads configured template contents" {
  let config = match
    @runtime.load_config_result("fixtures/v2/with_template_file/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let source = match @runtime.load_template_source_result(config) {
    Ok(Some(source)) => source
    _ => panic()
  }
  inspect(source.contains("data-template=\"custom\""), content="true")
  inspect(source.contains("{{ body_html }}"), content="true")
}

///|
test "load_config_result reports missing config file" {
  let result = @runtime.load_config_result(
    "fixtures/v2/missing_config/moonink.json",
  )
  inspect(result is Err(_), content="true")
}

///|
test "load_config_result rejects parent traversal paths" {
  inspect(
    @runtime.load_config_result("../moonink.json") is Err(_),
    content="true",
  )
}

///|
test "load_config_task wraps config loading in runtime io task" {
  let outcome = @runtime.run_runtime_io_task(
    @runtime.load_config_task("fixtures/v2/minimal/moonink.json"),
  )
  inspect(outcome is Ok(_), content="true")
}

///|
test "load_template_source_result reports missing configured template file" {
  let config_json =
    #|{"site_name": "Fixture Site", "template_file": "templates/missing.html"}
  let config = @core.parse_config_json(
    "fixtures/v2/minimal/moonink.json", config_json,
  ) catch {
    _ => panic()
  }
  inspect(
    @runtime.load_template_source_result(config) is Err(_),
    content="true",
  )
}

///|
test "discover_content finds markdown and html files" {
  let config = match
    @runtime.load_config_result("fixtures/v2/minimal/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let inventory = match @runtime.discover_content_result(config) {
    Ok(inventory) => inventory
    Err(_) => panic()
  }
  // Should find: about.html, hello.md, index.md
  // Note: .md files are classified as Article during discovery (frontmatter not read yet)
  // .html files are classified as Page
  inspect(inventory.files.length(), content="3")
  inspect(inventory.total_articles, content="2")
  inspect(inventory.total_pages, content="1")
}

///|
test "discover_content_build inputs read frontmatter-aware metadata" {
  let config = match
    @runtime.load_config_result("fixtures/v2/minimal/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let inventory = match @runtime.discover_content_result(config) {
    Ok(inventory) => inventory
    Err(_) => panic()
  }
  let inputs = match @runtime.load_build_inputs_result(config, inventory) {
    Ok(inputs) => inputs
    Err(_) => panic()
  }
  inspect(inputs.length(), content="3")
  let by_path : Map[String, @runtime.BuildInput] = {}
  for input in inputs {
    by_path[input.meta.source_path] = input
  }
  inspect(by_path.get("about.html").unwrap().meta.content_kind, content="Page")
  inspect(by_path.get("hello.md").unwrap().meta.content_kind, content="Article")
  inspect(by_path.get("index.md").unwrap().meta.content_kind, content="Page")
  inspect(by_path.get("about.html").unwrap().meta.url_path, content="/about/")
  inspect(by_path.get("hello.md").unwrap().meta.url_path, content="/hello/")
  inspect(by_path.get("index.md").unwrap().meta.url_path, content="/")
}

///|
test "native runtime adapter exposes explicit runtime identity" {
  let adapter = @runtime.native_runtime_adapter()
  inspect(adapter.name, content="native-runtime-adapter")
  inspect(adapter.policy.conflict_policy, content="AbortOnConflict")
}

///|
test "native runtime adapter executes runtime io tasks" {
  let result = @runtime.run_native_runtime_io_task(
    @runtime.RuntimeIOTask::Ready(42),
  )
  inspect(result, content="42")
}
