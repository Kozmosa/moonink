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
test "load_active_theme_layout_result falls back to built-in default theme" {
  let config = match
    @runtime.load_config_result("fixtures/v2/minimal/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let layout = match @runtime.load_active_theme_layout_result(config) {
    Ok(layout) => layout
    Err(_) => panic()
  }
  inspect(
    layout.source_kind is @runtime.ActiveThemeSource::BuiltInDefault,
    content="true",
  )
  inspect(layout.theme_name, content="default")
  inspect(layout.asset_source_dir is Some(_), content="true")
  inspect(layout.source.contains("data-theme=\"default\""), content="true")
}

///|
test "load_active_theme_layout_result reads legacy project theme layout before template file" {
  let config = match
    @runtime.load_config_result("fixtures/v2/theme_layout_basic/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let layout = match @runtime.load_active_theme_layout_result(config) {
    Ok(layout) => layout
    Err(_) => panic()
  }
  inspect(
    layout.source_kind is @runtime.ActiveThemeSource::ProjectTheme,
    content="true",
  )
  inspect(layout.theme_name, content="theme")
  inspect(layout.source.contains("data-theme-layout=\"true\""), content="true")
}

///|
test "load_active_theme_layout_result uses configured legacy theme directory" {
  let config_json =
    #|{
    #|  "site_name": "Theme Fixture",
    #|  "template_file": "templates/site.html",
    #|  "theme": "alt-theme"
    #|}
  let config = @core.parse_config_json(
    "fixtures/v2/theme_layout_basic/moonink.json", config_json,
  ) catch {
    _ => panic()
  }
  let scratch_root = "fixtures/v2/_test_runs/runtime-legacy-theme-selector"
  let _ = try? @runtime.io_remove_dir_all(scratch_root)
  @runtime.io_ensure_dir(scratch_root) catch {
    _ => panic()
  }
  @runtime.io_copy_dir_recursive(
    "fixtures/v2/theme_layout_basic/theme",
    scratch_root + "/alt-theme",
  ) catch {
    _ => panic()
  }
  @runtime.io_copy_dir_recursive(
    "fixtures/v2/theme_layout_basic/templates",
    scratch_root + "/templates",
  ) catch {
    _ => panic()
  }
  let selected_config : @core.MooninkConfig = {
    ..config,
    project_root: scratch_root,
  }
  let layout = match @runtime.load_active_theme_layout_result(selected_config) {
    Ok(layout) => layout
    Err(_) => panic()
  }
  inspect(
    layout.source_kind is @runtime.ActiveThemeSource::ProjectTheme,
    content="true",
  )
  inspect(layout.theme_name, content="alt-theme")
  inspect(layout.source.contains("data-theme-layout=\"true\""), content="true")
}

///|
test "load_build_inputs_result ignores root helper directories" {
  let config = match
    @runtime.load_config_result("fixtures/v2/theme_layout_basic/moonink.json") {
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
  inspect(inputs.length(), content="1")
  inspect(inputs[0].meta.source_path, content="index.md")
}

///|
test "discover_content_result ignores root helper directories" {
  let config = match
    @runtime.load_config_result("fixtures/v2/theme_layout_basic/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let inventory = match @runtime.discover_content_result(config) {
    Ok(inventory) => inventory
    Err(_) => panic()
  }
  inspect(inventory.files.length(), content="1")
  inspect(
    inventory.files[0].path,
    content="fixtures/v2/theme_layout_basic/index.md",
  )
}

///|
test "discover_content_result ignores configured theme directory" {
  let config_json =
    #|{
    #|  "site_name": "Theme V2 Basic",
    #|  "theme": "alt-theme"
    #|}
  let config = @core.parse_config_json(
    "fixtures/v2/theme_v2_basic/moonink.json", config_json,
  ) catch {
    _ => panic()
  }
  let scratch_root = "fixtures/v2/_test_runs/runtime-discovery-theme-selector"
  let _ = try? @runtime.io_remove_dir_all(scratch_root)
  @runtime.io_copy_dir_recursive("fixtures/v2/theme_v2_basic", scratch_root) catch {
    _ => panic()
  }
  @runtime.io_copy_dir_recursive(
    scratch_root + "/theme",
    scratch_root + "/alt-theme",
  ) catch {
    _ => panic()
  }
  @runtime.io_remove_dir_all(scratch_root + "/theme") catch {
    _ => panic()
  }
  @runtime.io_write_string(scratch_root + "/moonink.json", config_json) catch {
    _ => panic()
  }
  let selected_config : @core.MooninkConfig = {
    ..config,
    project_root: scratch_root,
    config_path: scratch_root + "/moonink.json",
  }
  let inventory = match @runtime.discover_content_result(selected_config) {
    Ok(inventory) => inventory
    Err(_) => panic()
  }
  inspect(inventory.files.length(), content="3")
}

///|
test "discover_content_result ignores theme directory under configured content dir" {
  let scratch_root = "fixtures/v2/_test_runs/runtime-discovery-content-dir-theme"
  let _ = try? @runtime.io_remove_dir_all(scratch_root)
  @runtime.io_copy_dir_recursive("fixtures/v2/theme_v2_basic", scratch_root) catch {
    _ => panic()
  }
  @runtime.io_ensure_dir(scratch_root + "/docs") catch {
    _ => panic()
  }
  @runtime.io_copy_file(
    scratch_root + "/index.md",
    scratch_root + "/docs/index.md",
  ) catch {
    _ => panic()
  }
  @runtime.io_copy_file(
    scratch_root + "/hello.md",
    scratch_root + "/docs/hello.md",
  ) catch {
    _ => panic()
  }
  @runtime.io_copy_file(
    scratch_root + "/about.html",
    scratch_root + "/docs/about.html",
  ) catch {
    _ => panic()
  }
  @runtime.io_copy_dir_recursive(
    scratch_root + "/theme",
    scratch_root + "/docs/theme",
  ) catch {
    _ => panic()
  }
  @runtime.io_write_string(
    scratch_root + "/docs/layout.html",
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
  @runtime.io_write_string(scratch_root + "/moonink.json", config_json) catch {
    _ => panic()
  }
  let config = match
    @runtime.load_config_result(scratch_root + "/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let inventory = match @runtime.discover_content_result(config) {
    Ok(inventory) => inventory
    Err(_) => panic()
  }
  inspect(inventory.files.length(), content="3")
}

///|
test "discover_content_result keeps non-theme content under nested theme root" {
  let config_json =
    #|{
    #|  "site_name": "Theme V2 Basic",
    #|  "theme": "brand/theme"
    #|}
  let config = @core.parse_config_json(
    "fixtures/v2/theme_v2_basic/moonink.json", config_json,
  ) catch {
    _ => panic()
  }
  let scratch_root = "fixtures/v2/_test_runs/runtime-discovery-nested-theme-selector"
  let _ = try? @runtime.io_remove_dir_all(scratch_root)
  @runtime.io_copy_dir_recursive("fixtures/v2/theme_v2_basic", scratch_root) catch {
    _ => panic()
  }
  @runtime.io_ensure_dir(scratch_root + "/brand") catch {
    _ => panic()
  }
  @runtime.io_copy_dir_recursive(
    scratch_root + "/theme",
    scratch_root + "/brand/theme",
  ) catch {
    _ => panic()
  }
  @runtime.io_remove_dir_all(scratch_root + "/theme") catch {
    _ => panic()
  }
  @runtime.io_write_string(scratch_root + "/brand/guide.md", "# Brand Guide") catch {
    _ => panic()
  }
  @runtime.io_write_string(scratch_root + "/moonink.json", config_json) catch {
    _ => panic()
  }
  let selected_config : @core.MooninkConfig = {
    ..config,
    project_root: scratch_root,
    config_path: scratch_root + "/moonink.json",
  }
  let inventory = match @runtime.discover_content_result(selected_config) {
    Ok(inventory) => inventory
    Err(_) => panic()
  }
  inspect(inventory.files.length(), content="4")
  inspect(
    inventory.files.search_by(fn(file) { file.path.contains("brand/guide.md") })
    is Some(_),
    content="true",
  )
}

///|
test "load_active_theme_layout_result reads configured template contents" {
  let config = match
    @runtime.load_config_result("fixtures/v2/with_template_file/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let layout = match @runtime.load_active_theme_layout_result(config) {
    Ok(layout) => layout
    Err(_) => panic()
  }
  inspect(
    layout.source_kind is @runtime.ActiveThemeSource::TemplateFile,
    content="true",
  )
  inspect(layout.theme_name, content="")
  inspect(layout.asset_source_dir, content="None")
  inspect(layout.source.contains("data-template=\"custom\""), content="true")
  inspect(layout.source.contains("{{ body_html }}"), content="true")
}

///|
test "load_active_theme_layout_result keeps theme v2 bundles out of legacy layout flow" {
  let config = match
    @runtime.load_config_result("fixtures/v2/theme_v2_basic/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let layout = match @runtime.load_active_theme_layout_result(config) {
    Ok(layout) => layout
    Err(_) => panic()
  }
  inspect(
    layout.source_kind is @runtime.ActiveThemeSource::BuiltInDefault,
    content="true",
  )
  inspect(layout.theme_name, content="default")
  inspect(layout.source.contains("data-theme=\"default\""), content="true")
}

///|
test "load_active_theme_bundle_result reads theme v2 manifest layouts and partials" {
  let config = match
    @runtime.load_config_result("fixtures/v2/theme_v2_basic/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let bundle = match @runtime.load_active_theme_bundle_result(config) {
    Ok(bundle) => bundle
    Err(_) => panic()
  }
  inspect(bundle.manifest.name, content="fixture-v2")
  inspect(bundle.layouts.get("page") is Some(_), content="true")
  inspect(bundle.partials.get("header") is Some(_), content="true")
}

///|
test "load_active_theme_bundle_result uses configured theme directory" {
  let config_json =
    #|{
    #|  "site_name": "Theme Fixture",
    #|  "theme": "alt-theme"
    #|}
  let config = @core.parse_config_json(
    "fixtures/v2/theme_v2_basic/moonink.json", config_json,
  ) catch {
    _ => panic()
  }
  let scratch_root = "fixtures/v2/_test_runs/runtime-theme-selector"
  let _ = try? @runtime.io_remove_dir_all(scratch_root)
  @runtime.io_ensure_dir(scratch_root) catch {
    _ => panic()
  }
  @runtime.io_copy_dir_recursive(
    "fixtures/v2/theme_v2_basic/theme",
    scratch_root + "/alt-theme",
  ) catch {
    _ => panic()
  }
  let selected_config : @core.MooninkConfig = {
    ..config,
    project_root: scratch_root,
  }
  let bundle = match @runtime.load_active_theme_bundle_result(selected_config) {
    Ok(bundle) => bundle
    Err(_) => panic()
  }
  inspect(
    bundle.source_kind is @runtime.ActiveThemeSource::ProjectTheme,
    content="true",
  )
  inspect(bundle.manifest.name, content="fixture-v2")
}

///|
test "load_active_theme_bundle_result falls back to built-in theme v2 bundle" {
  let config = match
    @runtime.load_config_result("fixtures/v2/minimal/moonink.json") {
    Ok(config) => config
    Err(_) => panic()
  }
  let bundle = match @runtime.load_active_theme_bundle_result(config) {
    Ok(bundle) => bundle
    Err(_) => panic()
  }
  inspect(
    bundle.source_kind is @runtime.ActiveThemeSource::BuiltInDefault,
    content="true",
  )
  inspect(bundle.manifest.name, content="default")
  inspect(bundle.layouts.get("index") is Some(_), content="true")
  inspect(bundle.layouts.get("page") is Some(_), content="true")
  inspect(bundle.layouts.get("article") is Some(_), content="true")
  inspect(bundle.partials.get("header") is Some(_), content="true")
  inspect(bundle.assets_root is Some(_), content="true")
}

///|
test "load_active_theme_bundle_result reports missing partial referenced by layout" {
  let config = match
    @runtime.load_config_result(
      "fixtures/v2/theme_v2_invalid_missing_partial/moonink.json",
    ) {
    Ok(config) => config
    Err(_) => panic()
  }
  let result = @runtime.load_active_theme_bundle_result(config)
  inspect(
    result is Err(@runtime.ThemeLoadError::MissingPartial(name="header")),
    content="true",
  )
}

///|
test "load_active_theme_bundle_result reports missing partial referenced by partial" {
  let config = match
    @runtime.load_config_result(
      "fixtures/v2/theme_v2_invalid_nested_missing_partial/moonink.json",
    ) {
    Ok(config) => config
    Err(_) => panic()
  }
  let result = @runtime.load_active_theme_bundle_result(config)
  inspect(
    result is Err(@runtime.ThemeLoadError::MissingPartial(name="missing")),
    content="true",
  )
}

///|
test "load_active_theme_bundle_result rejects empty theme layout maps" {
  let config = match
    @runtime.load_config_result(
      "fixtures/v2/theme_v2_invalid_empty_layouts/moonink.json",
    ) {
    Ok(config) => config
    Err(_) => panic()
  }
  let result = @runtime.load_active_theme_bundle_result(config)
  inspect(
    result
    is Err(
      @runtime.ThemeLoadError::Manifest(
        @core.ThemeManifestError::InvalidField(
          key="layouts",
          detail="must contain at least one layout"
        )
      )
    ),
    content="true",
  )
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

///|
test "search index generated_at helper returns utc timestamp" {
  let generated_at = @runtime.current_utc_iso8601_second()
  inspect(generated_at.contains("T"), content="true")
  inspect(generated_at.has_suffix("Z"), content="true")
  inspect(generated_at.length() >= 20, content="true")
}

///|
test "preview launch dry run validates built root" {
  let launch = @runtime.prepare_preview_launch(
    "fixtures/v2/minimal", "127.0.0.1", 3000,
  )
  let result = @runtime.launch_preview_result(
    @runtime.dry_run_preview_runner(),
    launch,
  )
  inspect(result is Ok(_), content="true")
  let validated = match result {
    Ok(validated) => validated
    Err(_) => panic()
  }
  inspect(
    validated.note.contains("Dry-run preview launch validated"),
    content="true",
  )
}

///|
test "preview launch rejects missing root directory" {
  let launch = @runtime.prepare_preview_launch(
    "fixtures/v2/missing-root", "127.0.0.1", 3000,
  )
  let result = @runtime.launch_preview_result(
    @runtime.dry_run_preview_runner(),
    launch,
  )
  inspect(result is Err(_), content="true")
}
