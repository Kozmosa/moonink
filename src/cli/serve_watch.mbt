///|
let serve_watch_poll_millis : Int = 400

///|
let serve_watch_max_diagnostic_lines : Int = 6

///|
let serve_preview_artifact_paths : Array[String] = [
  "__moonink/live-reload.js", "__moonink/preview-status.json",
]

///|
struct ServePreviewStatus {
  revision : Int
  status : String
  diagnostics : Array[String]
} derive(Debug, Eq)

///|
struct ServeRenderCache {
  source_fingerprints : Map[String, String]
  parsed : Map[String, @docflow.ParsedDocument]
  linked : Map[String, @docflow.ParsedDocument]
  rendered : Map[String, @docflow.RenderedDocument]
  target_signature : String
} derive(Debug, Eq)

///|
struct PreparedServeWatch {
  runtime : PreparedServeRuntime
  watch_roots : Array[String]
  watch_snapshot : Array[String]
  cache : ServeRenderCache
} derive(Debug, Eq)

///|
fn empty_serve_render_cache() -> ServeRenderCache {
  {
    source_fingerprints: {},
    parsed: {},
    linked: {},
    rendered: {},
    target_signature: "",
  }
}

///|
fn append_json_string(builder : StringBuilder, source : String) -> Unit {
  builder.write_string("\"")
  for index in 0..<source.length() {
    let char = source[index:index + 1].to_string()
    if char == "\\" {
      builder.write_string("\\\\")
    } else if char == "\"" {
      builder.write_string("\\\"")
    } else if char == "\n" {
      builder.write_string("\\n")
    } else if char == "\r" {
      builder.write_string("\\r")
    } else if char == "\t" {
      builder.write_string("\\t")
    } else {
      builder.write_string(char)
    }
  }
  builder.write_string("\"")
}

///|
fn preview_status_to_json(status : ServePreviewStatus) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{\"revision\":")
  builder.write_string(status.revision.to_string())
  builder.write_string(",\"status\":")
  append_json_string(builder, status.status)
  builder.write_string(",\"updated_at\":")
  append_json_string(builder, @runtime.current_utc_iso8601_second())
  builder.write_string(",\"diagnostics\":[")
  for index in 0..<status.diagnostics.length() {
    if index > 0 {
      builder.write_string(",")
    }
    append_json_string(builder, status.diagnostics[index])
  }
  builder.write_string("]}")
  builder.to_string()
}

///|
fn preview_script_source() -> String {
  let source =
    #|(() => {
    #|  const STATUS_URL = "/__moonink/preview-status.json";
    #|  const BANNER_ID = "moonink-preview-status";
    #|  let lastRevision = null;
    #|  let activeMessage = "";
    #|
    #|  function ensureBanner() {
    #|    let banner = document.getElementById(BANNER_ID);
    #|    if (banner) {
    #|      return banner;
    #|    }
    #|    banner = document.createElement("div");
    #|    banner.id = BANNER_ID;
    #|    banner.style.position = "fixed";
    #|    banner.style.right = "1rem";
    #|    banner.style.bottom = "1rem";
    #|    banner.style.maxWidth = "28rem";
    #|    banner.style.padding = "0.8rem 1rem";
    #|    banner.style.borderRadius = "0.9rem";
    #|    banner.style.font = "13px/1.45 ui-monospace, SFMono-Regular, Menlo, monospace";
    #|    banner.style.background = "rgba(35, 27, 21, 0.92)";
    #|    banner.style.color = "#f7f1e8";
    #|    banner.style.boxShadow = "0 16px 40px rgba(0, 0, 0, 0.2)";
    #|    banner.style.zIndex = "9999";
    #|    banner.style.whiteSpace = "pre-wrap";
    #|    banner.style.display = "none";
    #|    document.body.appendChild(banner);
    #|    return banner;
    #|  }
    #|
    #|  function setBanner(status, diagnostics) {
    #|    const banner = ensureBanner();
    #|    if (status === "ready") {
    #|      banner.style.display = "none";
    #|      activeMessage = "";
    #|      return;
    #|    }
    #|    const lines = [];
    #|    lines.push(status === "warning" ? "Preview warning" : "Preview error");
    #|    if (Array.isArray(diagnostics)) {
    #|      for (const line of diagnostics.slice(0, 6)) {
    #|        lines.push(line);
    #|      }
    #|    }
    #|    const message = lines.join("\n");
    #|    if (message !== activeMessage) {
    #|      banner.textContent = message;
    #|      activeMessage = message;
    #|    }
    #|    banner.style.display = "block";
    #|  }
    #|
    #|  async function poll() {
    #|    try {
    #|      const response = await fetch(`${STATUS_URL}?ts=${Date.now()}`, {
    #|        cache: "no-store",
    #|      });
    #|      if (!response.ok) {
    #|        return;
    #|      }
    #|      const data = await response.json();
    #|      if (lastRevision !== null && data.revision !== lastRevision) {
    #|        window.location.reload();
    #|        return;
    #|      }
    #|      lastRevision = data.revision;
    #|      setBanner(data.status, data.diagnostics || []);
    #|    } catch (_) {
    #|    }
    #|  }
    #|
    #|  if (document.readyState === "loading") {
    #|    document.addEventListener("DOMContentLoaded", () => {
    #|      poll();
    #|      window.setInterval(poll, 900);
    #|    }, { once: true });
    #|  } else {
    #|    poll();
    #|    window.setInterval(poll, 900);
    #|  }
    #|})();
  source
}

///|
fn preview_script_tag() -> String {
  "<script defer src=\"/__moonink/live-reload.js\"></script>"
}

///|
fn preview_slot_overrides() -> Map[String, @core.ThemeConfigValue] {
  { "scripts": theme_string_value(preview_script_tag()) }
}

///|
fn preview_status_diagnostics_from_build(
  diagnostics : Array[BuildDiagnostic],
) -> Array[String] {
  let lines : Array[String] = []
  for diagnostic in diagnostics {
    if lines.length() >= serve_watch_max_diagnostic_lines {
      break
    }
    lines.push("[\{diagnostic.source_path}] \{diagnostic.entry.message}")
  }
  lines
}

///|
fn preview_failure_diagnostics(message : String) -> Array[String] {
  let lines : Array[String] = []
  for line_view in message.split("\n") {
    let line = line_view.to_string().trim().to_string()
    if line == "" {
      continue
    }
    lines.push(line)
    if lines.length() >= serve_watch_max_diagnostic_lines {
      break
    }
  }
  lines
}

///|
fn preview_status_from_build_result(
  result : BuildWithDiagnostics,
  revision : Int,
) -> ServePreviewStatus {
  if result.diagnostics.is_empty() {
    { revision, status: "ready", diagnostics: [] }
  } else {
    {
      revision,
      status: "warning",
      diagnostics: preview_status_diagnostics_from_build(result.diagnostics),
    }
  }
}

///|
fn join_watch_path(
  base : String,
  child : String,
) -> String raise @core.ProjectIOError {
  let normalized = @core.normalize_relative_path(child) catch {
    err =>
      raise @core.project_io_error(
        "join_path",
        child,
        @core.format_path_policy_error(err),
      )
  }
  if base == "/" {
    "/" + normalized
  } else if base.has_suffix("/") {
    base + normalized
  } else {
    base + "/" + normalized
  }
}

///|
fn hidden_preview_relative_dir(name : String) -> String {
  ".moonink-preview/" + name
}

///|
fn hidden_preview_root(
  project_root : String,
  name : String,
) -> String raise @core.ProjectIOError {
  @core.join_relative_path(project_root, hidden_preview_relative_dir(name)) catch {
    err =>
      raise @core.project_io_error(
        "preview_root",
        hidden_preview_relative_dir(name),
        @core.format_path_policy_error(err),
      )
  }
}

///|
fn preview_artifact_root(
  preview_root : String,
) -> String raise @core.ProjectIOError {
  join_watch_path(preview_root, "__moonink")
}

///|
fn preview_status_path(
  preview_root : String,
) -> String raise @core.ProjectIOError {
  join_watch_path(preview_artifact_root(preview_root), "preview-status.json")
}

///|
fn preview_script_path(
  preview_root : String,
) -> String raise @core.ProjectIOError {
  join_watch_path(preview_artifact_root(preview_root), "live-reload.js")
}

///|
fn write_preview_runtime_assets(
  preview_root : String,
  status : ServePreviewStatus,
) -> Unit raise @core.ProjectIOError {
  let artifact_root = preview_artifact_root(preview_root)
  @runtime.io_ensure_dir(artifact_root) catch {
    err => raise err
  }
  @runtime.io_write_string(
    preview_script_path(preview_root) catch {
      err => raise err
    },
    preview_script_source(),
  ) catch {
    err => raise err
  }
  @runtime.io_write_string(
    preview_status_path(preview_root) catch {
      err => raise err
    },
    preview_status_to_json(status),
  ) catch {
    err => raise err
  }
}

///|
fn copy_dir_if_exists(source_dir : String, target_dir : String) -> Unit {
  if !@runtime.io_path_exists(source_dir) {
    return
  }
  let _ = try? @runtime.io_copy_dir_recursive(source_dir, target_dir)
}

///|
fn publish_preview_output(
  preview_root : String,
  staging_root : String,
  publish_root : String,
  backup_root : String,
) -> Unit raise @core.ProjectIOError {
  @runtime.io_remove_dir_all(publish_root) catch {
    err => raise err
  }
  @runtime.io_copy_dir_recursive(staging_root, publish_root) catch {
    err => raise err
  }
  @runtime.io_remove_dir_all(backup_root) catch {
    err => raise err
  }
  if @runtime.io_path_exists(preview_root) {
    @runtime.io_copy_dir_recursive(preview_root, backup_root) catch {
      err => raise err
    }
  }
  @runtime.io_remove_dir_all(preview_root) catch {
    err => raise err
  }
  @runtime.io_copy_dir_recursive(publish_root, preview_root) catch {
    err => {
      let _ = try? @runtime.io_remove_dir_all(preview_root)
      copy_dir_if_exists(backup_root, preview_root)
      raise err
    }
  }
  @runtime.io_remove_dir_all(publish_root) catch {
    err => raise err
  }
  @runtime.io_remove_dir_all(backup_root) catch {
    err => raise err
  }
}

///|
fn append_unique_path(paths : Array[String], candidate : String) -> Unit {
  if paths.search_by(fn(path) { path == candidate }) is None {
    paths.push(candidate)
  }
}

///|
fn configured_content_root(
  config : @core.MooninkConfig,
) -> String raise @core.ProjectIOError {
  if config.content_dir == "." {
    config.project_root
  } else {
    @core.join_relative_path(config.project_root, config.content_dir) catch {
      err =>
        raise @core.project_io_error(
          "content_root",
          config.content_dir,
          @core.format_path_policy_error(err),
        )
    }
  }
}

///|
fn configured_public_root(
  config : @core.MooninkConfig,
) -> String raise @core.ProjectIOError {
  @core.join_relative_path(config.project_root, "public") catch {
    err =>
      raise @core.project_io_error(
        "public_root",
        "public",
        @core.format_path_policy_error(err),
      )
  }
}

///|
fn configured_project_theme_root(
  config : @core.MooninkConfig,
) -> String raise @core.ProjectIOError {
  let relative = match config.theme {
    Some(theme_dir) => theme_dir
    None => "theme"
  }
  @core.join_relative_path(config.project_root, relative) catch {
    err =>
      raise @core.project_io_error(
        "theme_root",
        relative,
        @core.format_path_policy_error(err),
      )
  }
}

///|
fn configured_template_path(
  config : @core.MooninkConfig,
) -> String? raise @core.ProjectIOError {
  match config.template_file {
    Some(template_file) =>
      Some(
        @core.join_relative_path(config.project_root, template_file) catch {
          err =>
            raise @core.project_io_error(
              "template_path",
              template_file,
              @core.format_path_policy_error(err),
            )
        },
      )
    None => None
  }
}

///|
fn watch_roots_for_config(
  config : @core.MooninkConfig,
) -> Array[String] raise @core.ProjectIOError {
  let roots : Array[String] = []
  append_unique_path(roots, config.config_path)
  let content_root = configured_content_root(config) catch { err => raise err }
  let public_root = configured_public_root(config) catch { err => raise err }
  let theme_root = configured_project_theme_root(config) catch {
    err => raise err
  }
  append_unique_path(roots, content_root)
  append_unique_path(roots, public_root)
  append_unique_path(roots, theme_root)
  let template_path = configured_template_path(config) catch {
    err => raise err
  }
  match template_path {
    Some(path) => append_unique_path(roots, path)
    None => ()
  }
  append_unique_path(roots, @runtime.built_in_default_theme_root())
  roots
}

///|
fn hash_bytes(bytes : Bytes) -> String {
  let prime : Int64 = 16777619L
  let modulus : Int64 = 2147483647L
  let mut hash : Int64 = prime
  for index in 0..<bytes.length() {
    hash = (hash * prime + bytes[index].to_int().to_int64()) % modulus
  }
  bytes.length().to_string() + ":" + hash.to_string()
}

///|
fn hash_string(source : String) -> String {
  hash_bytes(@utf8.encode(source))
}

///|
fn source_fingerprint(input : @runtime.BuildInput) -> String {
  hash_string(
    input.meta.source_path +
    "|" +
    input.meta.url_path +
    "|" +
    input.source_content,
  )
}

///|
fn collect_watch_snapshot_tokens(
  path : String,
) -> Array[String] raise @core.ProjectIOError {
  if !@runtime.io_path_exists(path) {
    return ["missing:" + path]
  }
  let is_dir = @runtime.io_is_dir(path) catch { err => raise err }
  if !is_dir {
    let bytes = @runtime.io_read_file_to_bytes(path) catch { err => raise err }
    return ["file:" + path + ":" + hash_bytes(bytes)]
  }
  let entries = @runtime.io_read_dir(path) catch { err => raise err }
  entries.sort_by(fn(left, right) { left.compare(right) })
  let tokens : Array[String] = [
    "dir:" + path + ":" + entries.length().to_string(),
  ]
  for entry in entries {
    let child = join_watch_path(path, entry) catch { err => raise err }
    let child_tokens = collect_watch_snapshot_tokens(child) catch {
      err => raise err
    }
    for token in child_tokens {
      tokens.push(token)
    }
  }
  tokens
}

///|
fn watch_snapshot_for_roots(
  roots : Array[String],
) -> Array[String] raise @core.ProjectIOError {
  let snapshot : Array[String] = []
  for root in roots {
    let tokens = collect_watch_snapshot_tokens(root) catch { err => raise err }
    for token in tokens {
      snapshot.push(token)
    }
  }
  snapshot
}

///|
fn watch_snapshot_equal(left : Array[String], right : Array[String]) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for index in 0..<left.length() {
    if left[index] != right[index] {
      return false
    }
  }
  true
}

///|
fn build_link_target_signature(
  inputs : Array[@runtime.BuildInput],
  inventory : @core.ContentInventory,
) -> String {
  let parts : Array[String] = []
  for input in inputs {
    parts.push(input.meta.source_path + "=>" + input.meta.url_path)
  }
  for asset in inventory.asset_files {
    parts.push("asset:" + asset.relative_path)
  }
  parts.sort_by(fn(left, right) { left.compare(right) })
  hash_string(parts.iter().join("|"))
}

///|
fn find_preview_body_close(html : String) -> Int? {
  let needle = "</body>"
  if html.length() < needle.length() {
    return None
  }
  for index in 0..<(html.length() - needle.length() + 1) {
    if html[index:index + needle.length()].to_string() == needle {
      return Some(index)
    }
  }
  None
}

///|
fn ensure_preview_script_in_html(html : String) -> String {
  if html.contains("/__moonink/live-reload.js") {
    return html
  }
  let tag = preview_script_tag()
  match find_preview_body_close(html) {
    Some(index) => html[:index].to_string() + tag + html[index:].to_string()
    None => html + tag
  }
}

///|
fn validate_preview_artifact_output_conflicts(
  inventory : @core.ContentInventory,
) -> Unit raise BuildCommandError {
  for asset in inventory.asset_files {
    if serve_preview_artifact_paths.search_by(fn(path) {
        path == asset.relative_path
      })
      is Some(_) {
      raise BuildCommandError::ProjectIO(
        @core.project_io_error(
          "serve",
          asset.relative_path,
          "vault asset output path conflict with preview artifact",
        ),
      )
    }
  }
}

///|
fn generated_preview_output_path(
  config : @core.MooninkConfig,
  output_path : String,
) -> String raise @core.ProjectIOError {
  @core.join_relative_path(output_root(config), output_path) catch {
    err =>
      raise @core.project_io_error(
        "serve_preview_output",
        output_path,
        @core.format_path_policy_error(err),
      )
  }
}

///|
fn ensure_generated_preview_scripts(
  config : @core.MooninkConfig,
  pages : Array[@core.GeneratedPage],
) -> Unit raise BuildCommandError {
  for page in pages {
    let full_path = generated_preview_output_path(config, page.output_path) catch {
      err => raise BuildCommandError::ProjectIO(err)
    }
    let html = @runtime.io_read_file_to_string(full_path) catch {
      err => raise BuildCommandError::ProjectIO(err)
    }
    @runtime.io_write_string(full_path, ensure_preview_script_in_html(html)) catch {
      err => raise BuildCommandError::ProjectIO(err)
    }
  }
}

///|
fn build_serve_preview_result(
  config : @core.MooninkConfig,
  inventory : @core.ContentInventory,
  revision : Int,
  cache : ServeRenderCache,
) -> Result[(BuildWithDiagnostics, ServeRenderCache), BuildCommandError] {
  let inputs = match @runtime.load_build_inputs_result(config, inventory) {
    Ok(inputs) => inputs
    Err(err) => return Err(BuildCommandError::ContentDiscovery(err))
  }
  let published_inputs = published_build_inputs(inputs)
  let theme_bundle = match resolve_active_theme_bundle(config) {
    Ok(theme_bundle) => theme_bundle
    Err(err) => return Err(err)
  }
  let active_theme = match theme_bundle {
    Some(_) => None
    None =>
      match resolve_active_theme_layout(config) {
        Ok(active_theme) => Some(active_theme)
        Err(err) => return Err(err)
      }
  }
  match theme_bundle {
    Some(bundle) => {
      validate_build_theme_overrides(published_inputs, bundle) catch {
        err => return Err(err)
      }
      for input in published_inputs {
        let _ = select_theme_layout(bundle, input) catch {
          err => return Err(err)
        }
      }
    }
    None => ()
  }
  validate_reserved_generated_roots(inputs) catch {
    err => return Err(err)
  }
  let assembly = build_site_assembly_model(config, published_inputs, inventory)
  let generated_pages = build_generated_pages(config, assembly.pages)
  match theme_bundle {
    Some(bundle) =>
      for page in generated_pages {
        if generated_theme_layout_source(bundle, page) is None {
          return Err(
            BuildCommandError::ProjectIO(
              @core.project_io_error(
                "build",
                page.source_path,
                missing_theme_layout_message(page.layout_key),
              ),
            ),
          )
        }
      }
    None => ()
  }
  let output_targets = build_input_output_targets(published_inputs) +
    generated_page_output_targets(generated_pages)
  validate_static_asset_output_conflicts(inventory, output_targets) catch {
    err => return Err(err)
  }
  validate_preview_artifact_output_conflicts(inventory) catch {
    err => return Err(err)
  }
  let staging_config = @core.config_with_output_dir(
    config,
    hidden_preview_relative_dir("serve-staging"),
  ) catch {
    err =>
      return Err(
        BuildCommandError::ProjectIO(
          @core.project_io_error(
            "serve_staging",
            hidden_preview_relative_dir("serve-staging"),
            @core.format_config_error(err),
          ),
        ),
      )
  }
  prepare_output_dir(staging_config) catch {
    err => return Err(err)
  }
  copy_public_assets(staging_config) catch {
    err => return Err(err)
  }
  copy_content_tree_assets(staging_config, inventory) catch {
    err => return Err(err)
  }
  match theme_bundle {
    Some(bundle) => {
      copy_theme_bundle_assets(staging_config, bundle) catch {
        err => return Err(err)
      }
      write_theme_vars_output(staging_config, bundle) catch {
        err => return Err(err)
      }
    }
    None =>
      match active_theme {
        Some(active_theme) =>
          copy_selected_theme_assets(staging_config, active_theme) catch {
            err => return Err(err)
          }
        None => ()
      }
  }
  ensure_surface_search_asset(staging_config) catch {
    err => return Err(err)
  }
  let wikilinker = build_wikilinker_with_assets(
    published_inputs,
    inventory.asset_files,
  )
  let experience = build_article_experience_model(
    published_inputs,
    assembly.pages,
    wikilinker,
  )
  let target_signature = build_link_target_signature(
    published_inputs, inventory,
  )
  let mut emitted_html_files = 0
  let mut article_count = 0
  let mut page_count = 0
  let diagnostics : Array[BuildDiagnostic] = []
  let next_fingerprints : Map[String, String] = {}
  let next_parsed : Map[String, @docflow.ParsedDocument] = {}
  let next_linked : Map[String, @docflow.ParsedDocument] = {}
  let next_rendered : Map[String, @docflow.RenderedDocument] = {}
  for input in published_inputs {
    let parser = match parser_for_format(input.meta.format) {
      Ok(parser) => parser
      Err(err) => return Err(err)
    }
    let renderer = match renderer_for_format(input.meta.format) {
      Ok(renderer) => renderer
      Err(err) => return Err(err)
    }
    let fingerprint = source_fingerprint(input)
    let source_input : @docflow.SourceDocumentInput = {
      path: input.meta.source_path,
      format: input.meta.format,
      content: input.docflow_content,
      uuid: input.meta.source_path,
    }
    let can_reuse_parsed = match
      cache.source_fingerprints.get(input.meta.source_path) {
      Some(previous_fingerprint) =>
        previous_fingerprint == fingerprint &&
        cache.parsed.get(input.meta.source_path) is Some(_)
      None => false
    }
    let parsed = if can_reuse_parsed {
      match cache.parsed.get(input.meta.source_path) {
        Some(parsed) => parsed
        None => panic()
      }
    } else {
      match @docflow.parse_with_adapter_result(parser, source_input) {
        Ok(parsed) => parsed
        Err(err) => return Err(BuildCommandError::FatalParse(err))
      }
    }
    let has_same_fingerprint = match
      cache.source_fingerprints.get(input.meta.source_path) {
      Some(previous_fingerprint) => previous_fingerprint == fingerprint
      None => false
    }
    let can_reuse_linked = cache.target_signature == target_signature &&
      has_same_fingerprint &&
      cache.linked.get(input.meta.source_path) is Some(_) &&
      cache.rendered.get(input.meta.source_path) is Some(_)
    let linked = if can_reuse_linked {
      match cache.linked.get(input.meta.source_path) {
        Some(linked) => linked
        None => panic()
      }
    } else {
      @docflow.apply_wikilinker(wikilinker, parsed)
    }
    for entry in linked.diagnostics.entries {
      diagnostics.push(build_runtime_diagnostic(input, entry))
    }
    let rendered = if can_reuse_linked {
      match cache.rendered.get(input.meta.source_path) {
        Some(rendered) => rendered
        None => panic()
      }
    } else {
      @docflow.render_with_adapter(renderer, linked)
    }
    let templated = match theme_bundle {
      Some(bundle) =>
        apply_build_theme_template(
          staging_config,
          bundle,
          assembly,
          experience,
          input,
          rendered,
          extra_slots=preview_slot_overrides(),
        ) catch {
          err => return Err(err)
        }
      None => {
        let active_theme = match active_theme {
          Some(active_theme) => active_theme
          None => panic()
        }
        apply_build_template(
          staging_config,
          active_theme,
          assembly,
          experience,
          input,
          rendered,
          active_theme.source,
        )
      }
    }
    write_build_output(
      staging_config,
      input.meta.output_path,
      ensure_preview_script_in_html(templated.html),
    ) catch {
      err => return Err(err)
    }
    next_fingerprints[input.meta.source_path] = fingerprint
    next_parsed[input.meta.source_path] = parsed
    next_linked[input.meta.source_path] = linked
    next_rendered[input.meta.source_path] = rendered
    emitted_html_files += 1
    match input.meta.content_kind {
      @core.ContentKind::Article => article_count += 1
      @core.ContentKind::Page => page_count += 1
    }
  }
  let generated_emitted = write_generated_surface_pages(
    staging_config, active_theme, theme_bundle, assembly,
  ) catch {
    err => return Err(err)
  }
  ensure_generated_preview_scripts(staging_config, generated_pages) catch {
    err => return Err(err)
  }
  emitted_html_files += generated_emitted
  write_search_index_output(staging_config, published_inputs) catch {
    err => return Err(err)
  }
  write_rss_output(staging_config, assembly.pages) catch {
    err => return Err(err)
  }
  let result : BuildWithDiagnostics = {
    summary: {
      output_dir: config.output_dir,
      processed_sources: inputs.length(),
      emitted_html_files,
      article_count,
      page_count,
    },
    diagnostics,
  }
  write_preview_runtime_assets(
    output_root(staging_config),
    preview_status_from_build_result(result, revision),
  ) catch {
    err => return Err(BuildCommandError::ProjectIO(err))
  }
  let publish_root = hidden_preview_root(config.project_root, "serve-publish") catch {
    err => return Err(BuildCommandError::ProjectIO(err))
  }
  let backup_root = hidden_preview_root(config.project_root, "serve-backup") catch {
    err => return Err(BuildCommandError::ProjectIO(err))
  }
  publish_preview_output(
    output_root(config),
    output_root(staging_config),
    publish_root,
    backup_root,
  ) catch {
    err => return Err(BuildCommandError::ProjectIO(err))
  }
  Ok(
    (
      result,
      {
        source_fingerprints: next_fingerprints,
        parsed: next_parsed,
        linked: next_linked,
        rendered: next_rendered,
        target_signature,
      },
    ),
  )
}

///|
fn prepare_serve_watch_result(
  config_path : String,
  output_dir : String?,
  host : String,
  port : Int,
  revision : Int,
  cache : ServeRenderCache,
) -> Result[PreparedServeWatch, String] {
  let config = match @runtime.load_config_result(config_path) {
    Ok(config) => config
    Err(err) =>
      return Err(
        "[serve] build failed before preview startup\n" +
        format_runtime_config_error(err),
      )
  }
  let config = match apply_serve_output_override_result(config, output_dir) {
    Ok(config) => config
    Err(err) =>
      return Err(
        "[serve] build failed before preview startup\n" +
        format_runtime_config_error(err),
      )
  }
  let inventory = match
    @runtime.run_runtime_io_task(@runtime.discover_content_task(config)) {
    Ok(inventory) => inventory
    Err(err) =>
      return Err(
        "[serve] build failed before preview startup\n" +
        format_runtime_content_error(err),
      )
  }
  let (result, next_cache) = match
    build_serve_preview_result(config, inventory, revision, cache) {
    Ok(result) => result
    Err(err) =>
      return Err(
        "[serve] build failed before preview startup\n" +
        format_build_command_error(err),
      )
  }
  let build_stage = if result.diagnostics.is_empty() {
    ServeBuildStage::Clean(result.summary)
  } else {
    ServeBuildStage::WithWarnings(result.summary, result.diagnostics)
  }
  let watch_roots = watch_roots_for_config(config) catch {
    err =>
      return Err(
        "[serve] build failed before preview startup\n" +
        @core.format_project_io_error(err),
      )
  }
  let watch_snapshot = watch_snapshot_for_roots(watch_roots) catch {
    err =>
      return Err(
        "[serve] build failed before preview startup\n" +
        @core.format_project_io_error(err),
      )
  }
  Ok({
    runtime: {
      session: prepare_serve_session(output_root(config), host~, port~),
      build_stage,
    },
    watch_roots,
    watch_snapshot,
    cache: next_cache,
  })
}

///|
fn write_preview_failure_status(
  preview_root : String,
  revision : Int,
  message : String,
) -> Result[Unit, String] {
  write_preview_runtime_assets(preview_root, {
    revision,
    status: "error",
    diagnostics: preview_failure_diagnostics(message),
  }) catch {
    err =>
      return Err(
        "[serve] failed while writing preview status\n" +
        @core.format_project_io_error(err),
      )
  }
  Ok(())
}

///|
fn build_preview_startup_command(
  session : ServeSession,
) -> Result[String, String] {
  match
    @runtime.native_serve_delegate_command_result(
      session.preview_root,
      session.host,
      session.port,
    ) {
    Ok(command) => Ok(command)
    Err(err) =>
      Err(
        "[serve] failed during preview startup\n" +
        @core.format_project_io_error(err),
      )
  }
}

///|
fn start_preview_child_result(
  session : ServeSession,
) -> Result[@runtime.SpawnedProcess, String] {
  let command = match build_preview_startup_command(session) {
    Ok(command) => command
    Err(message) => return Err(message)
  }
  let process = match @runtime.spawn_shell_command_result(command) {
    Ok(process) => process
    Err(err) =>
      return Err(
        "[serve] failed during preview startup\n" +
        @core.format_project_io_error(err),
      )
  }
  @runtime.sleep_millis(150)
  let status = match @runtime.poll_spawned_process_result(process) {
    Ok(status) => status
    Err(err) =>
      return Err(
        "[serve] failed during preview startup\n" +
        @core.format_project_io_error(err),
      )
  }
  if status != 0 {
    return Err(
      "[serve] failed during preview startup\nreason: preview server exited with status \{status - 1}",
    )
  }
  Ok(process)
}

///|
fn preview_process_still_running_result(
  process : @runtime.SpawnedProcess,
) -> Result[Unit, String] {
  match @runtime.poll_spawned_process_result(process) {
    Ok(0) => Ok(())
    Ok(status) =>
      Err(
        "[serve] watch loop interrupted\nreason: preview server exited with status \{status - 1}",
      )
    Err(err) =>
      Err(
        "[serve] watch loop interrupted\n" + @core.format_project_io_error(err),
      )
  }
}

///|
fn prepare_main_serve_launch_with_watch_result(
  config_path : String,
  output_dir : String?,
  host : String,
  port : Int,
) -> Result[(MainServeLaunch, PreparedServeWatch), String] {
  let prepared = match
    prepare_serve_watch_result(
      config_path,
      output_dir,
      host,
      port,
      1,
      empty_serve_render_cache(),
    ) {
    Ok(prepared) => prepared
    Err(message) => return Err(message)
  }
  Ok(
    (
      {
        build_message: format_serve_build_stage(prepared.runtime.build_stage),
        preview_root: prepared.runtime.session.preview_root,
        host: prepared.runtime.session.host,
        port: prepared.runtime.session.port,
      },
      prepared,
    ),
  )
}

///|
fn run_main_serve_watch_loop(
  config_path : String,
  output_dir : String?,
  initial : PreparedServeWatch,
) -> CliOutcome {
  let preview_process = match
    start_preview_child_result(initial.runtime.session) {
    Ok(process) => process
    Err(message) => return { exit_code: 1, message }
  }
  println(format_runtime_ready_message(initial.runtime.session))
  println("[serve] watch mode active")
  let mut revision = 1
  let mut watch_roots = initial.watch_roots
  let mut watch_snapshot = initial.watch_snapshot
  let mut cache = initial.cache
  let preview_root = initial.runtime.session.preview_root
  while true {
    @runtime.sleep_millis(serve_watch_poll_millis)
    match preview_process_still_running_result(preview_process) {
      Ok(_) => ()
      Err(message) => return { exit_code: 1, message }
    }
    let next_snapshot = watch_snapshot_for_roots(watch_roots) catch {
      err =>
        return {
          exit_code: 1,
          message: "[serve] watch loop failed\n" +
          @core.format_project_io_error(err),
        }
    }
    if watch_snapshot_equal(watch_snapshot, next_snapshot) {
      continue
    }
    println("[serve] change detected")
    match
      prepare_serve_watch_result(
        config_path,
        output_dir,
        initial.runtime.session.host,
        initial.runtime.session.port,
        revision + 1,
        cache,
      ) {
      Ok(prepared) => {
        revision += 1
        println(format_serve_build_stage(prepared.runtime.build_stage))
        watch_roots = prepared.watch_roots
        watch_snapshot = prepared.watch_snapshot
        cache = prepared.cache
      }
      Err(message) => {
        println(message)
        ignore(write_preview_failure_status(preview_root, revision, message))
        watch_snapshot = next_snapshot
      }
    }
  }
  { exit_code: 0, message: "" }
}
