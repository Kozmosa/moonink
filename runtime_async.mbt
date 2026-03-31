///|
/// Async-capable operation descriptor for runtime IO work introduced by IO-P6.
pub(all) enum RuntimeIOTask[T] {
  Ready(T)
} derive(Show, Eq)

///|
/// Execute an async-capable runtime IO task.
///
/// The current native-first implementation is eager, but the `RuntimeIOTask`
/// wrapper freezes the interface shape needed for a later true async runtime.
pub fn[T] run_runtime_io_task(task : RuntimeIOTask[T]) -> T {
  match task {
    Ready(value) => value
  }
}

///|
pub fn read_config_source_task(
  config_path : String,
) -> RuntimeIOTask[Result[(String, String), ConfigError]] {
  let normalized_path = try normalize_config_path_or_error(config_path) catch {
    err => return Ready(Err(err))
  }
  let source = io_read_file_to_string(normalized_path) catch {
    err => return Ready(Err(ConfigError::IOError(err)))
  }
  Ready(Ok((normalized_path, source)))
}

///|
pub fn load_config_task(config_path : String) -> RuntimeIOTask[Result[LoadedConfig, ConfigError]] {
  let source_result = run_runtime_io_task(read_config_source_task(config_path))
  let config = match source_result {
    Ok((normalized_path, source)) => try parse_loaded_config(normalized_path, source) catch {
      err => Err(err)
    } noraise {
      value => Ok(value)
    }
    Err(err) => Err(err)
  }
  Ready(config)
}

///|
pub fn discover_content_task(
  config : LoadedConfig,
) -> RuntimeIOTask[Result[ContentInventory, ContentDiscoveryError]] {
  Ready(try? discover_content(config))
}

///|
pub fn plan_starter_write_task(
  plan : StarterTemplatePlan,
) -> RuntimeIOTask[StarterWritePlan] {
  Ready(plan_starter_write(plan))
}

///|
pub fn emit_starter_project_task(
  plan : StarterTemplatePlan,
) -> RuntimeIOTask[CliOutcome] {
  ignore(run_runtime_io_task(plan_starter_write_task(plan)))
  Ready(emit_starter_project_runtime(plan))
}
