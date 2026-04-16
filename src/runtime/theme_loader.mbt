///|
pub(all) struct ActiveThemeBundle {
  manifest : @core.ThemeManifest
  layouts : Map[String, String]
  partials : Map[String, String]
  assets_root : String?
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
  @core.join_relative_path(base, child) catch {
    err => raise theme_path_error(child, err)
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
  Ok(layouts)
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
fn validate_theme_partial_references(
  layouts : Map[String, String],
  partials : Map[String, String],
) -> Result[Unit, ThemeLoadError] {
  let marker = "{% include \""
  for entry in layouts {
    let (_, source) = entry
    let mut cursor = 0
    while cursor + marker.length() <= source.length() {
      let maybe_marker = source[cursor:cursor + marker.length()].to_string()
      if maybe_marker != marker {
        cursor = cursor + 1
        continue
      }
      let name_start = cursor + marker.length()
      let mut name_end = name_start
      while name_end < source.length() &&
            source[name_end:name_end + 1].to_string() != "\"" {
        name_end = name_end + 1
      }
      if name_end >= source.length() {
        cursor = source.length()
      } else {
        let partial_name = source[name_start:name_end].to_string()
        if partials.get(partial_name) is None {
          return Err(ThemeLoadError::MissingPartial(name=partial_name))
        }
        cursor = name_end + 1
      }
    }
  }
  Ok(())
}

///|
pub fn load_active_theme_bundle_result(
  config : @core.MooninkConfig,
) -> Result[ActiveThemeBundle, ThemeLoadError] {
  let theme_root = project_theme_root(config) catch {
    err => return Err(ThemeLoadError::Config(err))
  }
  let manifest = match load_theme_manifest_result(theme_root) {
    Ok(manifest) => manifest
    Err(err) => return Err(err)
  }
  let layouts = match load_theme_layout_map(theme_root, manifest) {
    Ok(layouts) => layouts
    Err(err) => return Err(err)
  }
  let partials = match load_theme_partial_map(theme_root) {
    Ok(partials) => partials
    Err(err) => return Err(err)
  }
  match validate_theme_partial_references(layouts, partials) {
    Ok(_) =>
      Ok({
        manifest,
        layouts,
        partials,
        assets_root: Some(theme_root + "/assets"),
        source_kind: ActiveThemeSource::ProjectTheme,
      })
    Err(err) => Err(err)
  }
}
