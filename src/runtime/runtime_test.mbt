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
  inspect(config.text_encoding, content="utf-8")
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
