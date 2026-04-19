///|
pub(all) enum ActiveThemeSource {
  ProjectTheme
  TemplateFile
  BuiltInDefault
} derive(Debug, Eq)

///|
pub(all) struct ActiveThemeLayout {
  source : String
  source_kind : ActiveThemeSource
  theme_name : String
  asset_source_dir : String?
  embedded_assets : Map[String, String]
} derive(Debug, Eq)

///|
fn selected_project_theme_dir(config : @core.MooninkConfig) -> String {
  match config.theme {
    Some(path) => path
    None => "theme"
  }
}

///|
fn project_theme_root(
  config : @core.MooninkConfig,
) -> String raise @core.ConfigError {
  let theme_dir = selected_project_theme_dir(config)
  join_host_path(config.project_root, theme_dir) catch {
    err =>
      raise @core.ConfigError::InvalidPath(
        path=theme_dir,
        reason=@core.format_path_policy_error(err),
      )
  }
}

///|
fn project_theme_layout_path(
  config : @core.MooninkConfig,
) -> String raise @core.ConfigError {
  let theme_dir = selected_project_theme_dir(config)
  let layout_path = join_host_path(theme_dir, "layout.html") catch {
    err =>
      raise @core.ConfigError::InvalidPath(
        path=theme_dir,
        reason=@core.format_path_policy_error(err),
      )
  }
  join_host_path(config.project_root, layout_path) catch {
    err =>
      raise @core.ConfigError::InvalidPath(
        path=layout_path,
        reason=@core.format_path_policy_error(err),
      )
  }
}

///|
pub fn load_active_theme_layout_result(
  config : @core.MooninkConfig,
) -> Result[ActiveThemeLayout, @core.ConfigError] {
  let theme_root = project_theme_root(config) catch { err => return Err(err) }
  let theme_layout_path = project_theme_layout_path(config) catch {
    err => return Err(err)
  }
  if io_path_exists(theme_layout_path) {
    let source = io_read_file_to_string(theme_layout_path) catch {
      err => return Err(@core.ConfigError::IOError(err))
    }
    return Ok({
      source,
      source_kind: ActiveThemeSource::ProjectTheme,
      theme_name: selected_project_theme_dir(config),
      asset_source_dir: Some(theme_root + "/assets"),
      embedded_assets: {},
    })
  }
  match config.template_file {
    Some(template_file) => {
      let full_path = join_host_path(config.project_root, template_file) catch {
        err =>
          return Err(
            @core.ConfigError::InvalidPath(
              path=template_file,
              reason=@core.format_path_policy_error(err),
            ),
          )
      }
      let source = io_read_file_to_string(full_path) catch {
        err => return Err(@core.ConfigError::IOError(err))
      }
      Ok({
        source,
        source_kind: ActiveThemeSource::TemplateFile,
        theme_name: "",
        asset_source_dir: None,
        embedded_assets: {},
      })
    }
    None =>
      Ok({
        source: embedded_builtin_theme_layout_source(),
        source_kind: ActiveThemeSource::BuiltInDefault,
        theme_name: "default",
        asset_source_dir: None,
        embedded_assets: embedded_builtin_theme_asset_sources(),
      })
  }
}

///|
/// Load and parse config from a JSON file.
pub fn load_config_result(
  config_path : String,
) -> Result[@core.MooninkConfig, @core.ConfigError] {
  let config_path = match resolve_host_path_from_cwd_result(config_path) {
    Ok(config_path) => config_path
    Err(err) => return Err(err)
  }
  let source = io_read_file_to_string(config_path) catch {
    err => return Err(@core.ConfigError::IOError(err))
  }
  let project_root = dirname_host_path(config_path)
  try
    @core.parse_config_json_with_project_root(config_path, project_root, source)
  catch {
    err => Err(err)
  } noraise {
    config => Ok(config)
  }
}

///|
pub fn load_template_source_result(
  config : @core.MooninkConfig,
) -> Result[String?, @core.ConfigError] {
  match config.template_file {
    None => Ok(None)
    Some(template_file) => {
      let full_path = join_host_path(config.project_root, template_file) catch {
        err =>
          return Err(
            @core.ConfigError::InvalidPath(
              path=template_file,
              reason=@core.format_path_policy_error(err),
            ),
          )
      }
      let source = io_read_file_to_string(full_path) catch {
        err => return Err(@core.ConfigError::IOError(err))
      }
      Ok(Some(source))
    }
  }
}

///|
pub fn read_config_source_task(
  config_path : String,
) -> RuntimeIOTask[Result[(String, String), @core.ConfigError]] {
  let normalized_path = match resolve_host_path_from_cwd_result(config_path) {
    Ok(normalized_path) => normalized_path
    Err(err) => return Ready(Err(err))
  }
  let source = io_read_file_to_string(normalized_path) catch {
    err => return Ready(Err(@core.ConfigError::IOError(err)))
  }
  Ready(Ok((normalized_path, source)))
}

///|
pub fn load_config_task(
  config_path : String,
) -> RuntimeIOTask[Result[@core.MooninkConfig, @core.ConfigError]] {
  Ready(load_config_result(config_path))
}
