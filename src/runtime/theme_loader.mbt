///|
pub(all) struct ActiveThemeBundle {
  manifest : @core.ThemeManifest
  layouts : Map[String, String]
  partials : Map[String, String]
  assets_root : String?
  embedded_assets : Map[String, String]
  source_kind : ActiveThemeSource
} derive(Debug, Eq)

///|
pub(all) suberror ThemeLoadError {
  Config(@core.ConfigError)
  Manifest(@core.ThemeManifestError)
  MissingLayout(kind~ : String)
  MissingPartial(name~ : String)
} derive(Debug, Eq)

///|
pub impl Show for ThemeLoadError with output(self, logger) {
  match self {
    ThemeLoadError::Config(err) => {
      logger.write_string("Config(")
      logger.write_object(err)
      logger.write_string(")")
    }
    ThemeLoadError::Manifest(err) => {
      logger.write_string("Manifest(")
      logger.write_object(err)
      logger.write_string(")")
    }
    ThemeLoadError::MissingLayout(kind~) => {
      logger.write_string("MissingLayout(kind=\"")
      logger.write_string(kind)
      logger.write_string("\")")
    }
    ThemeLoadError::MissingPartial(name~) => {
      logger.write_string("MissingPartial(name=\"")
      logger.write_string(name)
      logger.write_string("\")")
    }
  }
}

///|
fn theme_path_error(
  path : String,
  err : @core.PathPolicyError,
) -> ThemeLoadError {
  ThemeLoadError::Config(
    @core.ConfigError::InvalidPath(
      path~,
      reason=@core.format_path_policy_error(err),
    ),
  )
}

///|
fn theme_child_path(
  base : String,
  child : String,
) -> String raise ThemeLoadError {
  let normalized_child = @core.normalize_relative_path(child) catch {
    err => raise theme_path_error(child, err)
  }
  if base == "/" {
    "/" + normalized_child
  } else if base.has_prefix("/") {
    if base.has_suffix("/") {
      base + normalized_child
    } else {
      base + "/" + normalized_child
    }
  } else {
    @core.join_relative_path(base, normalized_child) catch {
      err => raise theme_path_error(child, err)
    }
  }
}

///|
fn load_theme_manifest_result(
  theme_root : String,
) -> Result[@core.ThemeManifest, ThemeLoadError] {
  let manifest_path = theme_child_path(theme_root, "theme.json") catch {
    err => return Err(err)
  }
  let source = io_read_file_to_string(manifest_path) catch {
    err => return Err(ThemeLoadError::Config(@core.ConfigError::IOError(err)))
  }
  match @core.parse_theme_manifest_result(source) {
    Ok(manifest) => Ok(manifest)
    Err(err) => Err(ThemeLoadError::Manifest(err))
  }
}

///|
fn load_theme_layout_map(
  theme_root : String,
  manifest : @core.ThemeManifest,
) -> Result[Map[String, String], ThemeLoadError] {
  // Core parsing treats an omitted `layouts` field as `{}`; reject that here so
  // Theme V2 bundles fail at load time instead of during later layout lookup.
  for _ in manifest.layouts {
    let layouts : Map[String, String] = {}
    for entry in manifest.layouts {
      let (kind, relative_path) = entry
      let full_path = theme_child_path(theme_root, relative_path) catch {
        err => return Err(err)
      }
      let source = io_read_file_to_string(full_path) catch {
        _ => return Err(ThemeLoadError::MissingLayout(kind~))
      }
      layouts[kind] = source
    }
    return Ok(layouts)
  }

  Err(
    ThemeLoadError::Manifest(
      @core.ThemeManifestError::InvalidField(
        key="layouts",
        detail="must contain at least one layout",
      ),
    ),
  )
}

///|
fn load_embedded_theme_manifest_result() -> Result[
  @core.ThemeManifest,
  ThemeLoadError,
] {
  match @core.parse_theme_manifest_result(built_in_theme_manifest_source()) {
    Ok(manifest) => Ok(manifest)
    Err(err) => Err(ThemeLoadError::Manifest(err))
  }
}

///|
fn load_embedded_theme_layout_map(
  manifest : @core.ThemeManifest,
) -> Result[Map[String, String], ThemeLoadError] {
  let sources = built_in_theme_layout_file_sources()
  for _ in manifest.layouts {
    let layouts : Map[String, String] = {}
    for entry in manifest.layouts {
      let (kind, relative_path) = entry
      match sources.get(relative_path) {
        Some(source) => layouts[kind] = source
        None => return Err(ThemeLoadError::MissingLayout(kind~))
      }
    }
    return Ok(layouts)
  }
  Err(
    ThemeLoadError::Manifest(
      @core.ThemeManifestError::InvalidField(
        key="layouts",
        detail="must contain at least one layout",
      ),
    ),
  )
}

///|
fn partial_name_from_path(path : String) -> String {
  let normalized = @core.normalize_relative_path(path) catch { _ => return "" }
  let prefix = "partials/"
  let without_prefix = if normalized.has_prefix(prefix) {
    normalized[prefix.length():].to_string()
  } else {
    normalized
  }
  if without_prefix.has_suffix(".html") {
    without_prefix[:without_prefix.length() - 5].to_string()
  } else {
    without_prefix
  }
}

///|
fn trim_template_tag_name(name : String) -> String {
  name.trim().to_string()
}

///|
fn find_template_tag_close(template : String, start : Int) -> Int? {
  if start < 0 || start + 1 >= template.length() {
    return None
  }
  for i in start..<(template.length() - 1) {
    let pair = template[i:i + 2].to_string()
    if pair == "%}" {
      return Some(i)
    }
  }
  None
}

///|
fn parse_include_name(tag : String) -> String? {
  if !tag.has_prefix("include ") {
    return None
  }
  let name = tag[8:].to_string().trim().to_string()
  if name.length() >= 2 &&
    name[0:1].to_string() == "\"" &&
    name[name.length() - 1:name.length()].to_string() == "\"" {
    Some(name[1:name.length() - 1].to_string())
  } else {
    None
  }
}

///|
fn copy_string_array(source : Array[String]) -> Array[String] {
  let copied : Array[String] = []
  for entry in source {
    copied.push(entry)
  }
  copied
}

///|
fn string_array_contains(source : Array[String], target : String) -> Bool {
  for entry in source {
    if entry == target {
      return true
    }
  }
  false
}

///|
fn load_theme_partial_map(
  theme_root : String,
) -> Result[Map[String, String], ThemeLoadError] {
  let partials_root = theme_child_path(theme_root, "partials") catch {
    err => return Err(err)
  }
  if !io_path_exists(partials_root) {
    return Ok({})
  }
  let partial_entries = io_read_dir(partials_root) catch {
    err => return Err(ThemeLoadError::Config(@core.ConfigError::IOError(err)))
  }
  let partials : Map[String, String] = {}
  for entry in partial_entries {
    let relative_path = "partials/" + entry
    let full_path = theme_child_path(theme_root, relative_path) catch {
      err => return Err(err)
    }
    let source = io_read_file_to_string(full_path) catch {
      err => return Err(ThemeLoadError::Config(@core.ConfigError::IOError(err)))
    }
    partials[partial_name_from_path(relative_path)] = source
  }
  Ok(partials)
}

///|
fn load_embedded_theme_partial_map() -> Map[String, String] {
  let partials : Map[String, String] = {}
  for entry in built_in_theme_partial_file_sources() {
    let (relative_path, source) = entry
    partials[partial_name_from_path(relative_path)] = source
  }
  partials
}

///|
fn validate_theme_partial_references_in_source(
  source : String,
  partials : Map[String, String],
  stack : Array[String],
) -> Result[Unit, ThemeLoadError] {
  let mut cursor = 0
  while cursor < source.length() {
    if cursor + 1 < source.length() &&
      source[cursor:cursor + 2].to_string() == "{%" {
      match find_template_tag_close(source, cursor + 2) {
        Some(close) => {
          let tag = trim_template_tag_name(source[cursor + 2:close].to_string())
          match parse_include_name(tag) {
            Some(name) => {
              if partials.get(name) is None {
                return Err(ThemeLoadError::MissingPartial(name~))
              }
              if !string_array_contains(stack, name) {
                let next_stack = copy_string_array(stack)
                next_stack.push(name)
                match partials.get(name) {
                  Some(partial_source) =>
                    match
                      validate_theme_partial_references_in_source(
                        partial_source, partials, next_stack,
                      ) {
                      Ok(_) => ()
                      Err(err) => return Err(err)
                    }
                  None => ()
                }
              }
            }
            None => ()
          }
          cursor = close + 2
        }
        None => return Ok(())
      }
    } else {
      cursor = cursor + 1
    }
  }
  Ok(())
}

///|
fn validate_theme_partial_references(
  layouts : Map[String, String],
  partials : Map[String, String],
) -> Result[Unit, ThemeLoadError] {
  for entry in layouts {
    let (_, source) = entry
    match validate_theme_partial_references_in_source(source, partials, []) {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
  }
  Ok(())
}

///|
fn theme_config_scalar_string(value : @core.ThemeConfigValue) -> String? {
  match value {
    @core.ThemeConfigValue::StringValue(text) => Some(text)
    @core.ThemeConfigValue::NumberValue(number) => Some(number)
    @core.ThemeConfigValue::BoolValue(flag) =>
      Some(if flag { "true" } else { "false" })
    _ => None
  }
}

///|
fn theme_config_path(prefix : String, key : String) -> String {
  if prefix.is_empty() {
    key
  } else {
    prefix + "." + key
  }
}

///|
fn flatten_theme_config_entries(
  prefix : String,
  source : Map[String, @core.ThemeConfigValue],
  flattened : Map[String, String],
) -> Unit {
  for entry in source {
    let (key, value) = entry
    let path = theme_config_path(prefix, key)
    match value {
      @core.ThemeConfigValue::ObjectValue(entries) =>
        flatten_theme_config_entries(path, entries, flattened)
      _ =>
        match theme_config_scalar_string(value) {
          Some(text) => flattened[path] = text
          None => ()
        }
    }
  }
}

///|
pub fn flatten_theme_config_values(
  config : Map[String, @core.ThemeConfigValue],
) -> Map[String, String] {
  let flattened : Map[String, String] = {}
  flatten_theme_config_entries("", config, flattened)
  flattened
}

///|
pub fn merge_theme_tokens(
  tokens : Array[@core.ThemeTokenDeclaration],
  config : Map[String, @core.ThemeConfigValue],
) -> Map[String, String] {
  let overrides = flatten_theme_config_values(config)
  let merged : Map[String, String] = {}
  for token in tokens {
    match overrides.get(token.name) {
      Some(value) => merged[token.name] = value
      None =>
        match token.default_value {
          Some(value) => merged[token.name] = value
          None => ()
        }
    }
  }
  merged
}

///|
pub fn declared_slot_values(
  slot_names : Array[String],
  config : Map[String, @core.ThemeConfigValue],
) -> Map[String, String] {
  let values : Map[String, String] = {}
  let configured_slots = match config.get("slots") {
    Some(@core.ThemeConfigValue::ObjectValue(entries)) => entries
    _ => return values
  }
  for slot_name in slot_names {
    match configured_slots.get(slot_name) {
      Some(@core.ThemeConfigValue::StringValue(value)) =>
        values[slot_name] = value
      _ => ()
    }
  }
  values
}

///|
pub fn load_active_theme_bundle_result(
  config : @core.MooninkConfig,
) -> Result[ActiveThemeBundle, ThemeLoadError] {
  let project_root = project_theme_root(config) catch {
    err => return Err(ThemeLoadError::Config(err))
  }
  let project_manifest_path = theme_child_path(project_root, "theme.json") catch {
    err => return Err(err)
  }
  if io_path_exists(project_manifest_path) {
    let manifest = match load_theme_manifest_result(project_root) {
      Ok(manifest) => manifest
      Err(err) => return Err(err)
    }
    let layouts = match load_theme_layout_map(project_root, manifest) {
      Ok(layouts) => layouts
      Err(err) => return Err(err)
    }
    let partials = match load_theme_partial_map(project_root) {
      Ok(partials) => partials
      Err(err) => return Err(err)
    }
    return match validate_theme_partial_references(layouts, partials) {
      Ok(_) =>
        Ok({
          manifest,
          layouts,
          partials,
          assets_root: Some(project_root + "/assets"),
          embedded_assets: {},
          source_kind: ActiveThemeSource::ProjectTheme,
        })
      Err(err) => Err(err)
    }
  }
  let manifest = match load_embedded_theme_manifest_result() {
    Ok(manifest) => manifest
    Err(err) => return Err(err)
  }
  let layouts = match load_embedded_theme_layout_map(manifest) {
    Ok(layouts) => layouts
    Err(err) => return Err(err)
  }
  let partials = load_embedded_theme_partial_map()
  let embedded_assets = built_in_theme_asset_file_sources()
  match validate_theme_partial_references(layouts, partials) {
    Ok(_) =>
      Ok({
        manifest,
        layouts,
        partials,
        assets_root: None,
        embedded_assets,
        source_kind: ActiveThemeSource::BuiltInDefault,
      })
    Err(err) => Err(err)
  }
}
