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
} derive(Debug, Eq)

///|
fn built_in_default_theme_root() -> String {
  "src/runtime/builtin_theme"
}

///|
fn built_in_default_theme_layout_path() -> String {
  built_in_default_theme_root() + "/layout.html"
}

///|
fn built_in_default_theme_layout() -> String raise @core.ConfigError {
  io_read_file_to_string(built_in_default_theme_layout_path()) catch {
    err => raise @core.ConfigError::IOError(err)
  }
}

///|
fn project_theme_root(
  config : @core.MooninkConfig,
) -> String raise @core.ConfigError {
  @core.join_relative_path(config.project_root, "theme") catch {
    err =>
      raise @core.ConfigError::InvalidPath(
        path="theme",
        reason=@core.format_path_policy_error(err),
      )
  }
}

///|
fn project_theme_layout_path(
  config : @core.MooninkConfig,
) -> String raise @core.ConfigError {
  let root = project_theme_root(config)
  @core.join_relative_path(root, "layout.html") catch {
    err =>
      raise @core.ConfigError::InvalidPath(
        path="theme/layout.html",
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
      theme_name: "theme",
      asset_source_dir: Some(theme_root + "/assets"),
    })
  }
  match config.template_file {
    Some(template_file) => {
      let full_path = @core.join_relative_path(
        config.project_root,
        template_file,
      ) catch {
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
      })
    }
    None => {
      let source = built_in_default_theme_layout() catch {
        err => return Err(err)
      }
      Ok({
        source,
        source_kind: ActiveThemeSource::BuiltInDefault,
        theme_name: "default",
        asset_source_dir: Some(built_in_default_theme_root() + "/assets"),
      })
    }
  }
}

///|
/// Load and parse config from a JSON file.
pub fn load_config_result(
  config_path : String,
) -> Result[@core.MooninkConfig, @core.ConfigError] {
  let config_path = @core.normalize_config_path_or_error(config_path) catch {
    err => return Err(err)
  }
  let source = io_read_file_to_string(config_path) catch {
    err => return Err(@core.ConfigError::IOError(err))
  }
  try @core.parse_config_json(config_path, source) catch {
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
      let full_path = @core.join_relative_path(
        config.project_root,
        template_file,
      ) catch {
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
  let normalized_path = @core.normalize_config_path_or_error(config_path) catch {
    err => return Ready(Err(err))
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
