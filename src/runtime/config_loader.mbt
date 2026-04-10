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
