///|
/// Async-capable operation descriptor for runtime IO work introduced by IO-P6.
pub(all) enum RuntimeIOTask[T] {
  Ready(T)
} derive(Show, Eq)

///|
/// Execute an async-capable runtime IO task generically.
///
/// Higher-level runtime entrypoints should prefer the native adapter helpers in
/// `runtime_native.mbt`, while this function remains the backend-agnostic task
/// executor used by adapter implementations.
pub fn[T] run_runtime_io_task(task : RuntimeIOTask[T]) -> T {
  match task {
    Ready(value) => value
  }
}

///|
pub fn runtime_task_policy() -> RuntimeTaskPolicy {
  default_runtime_task_policy()
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
  Ready(load_config_result(config_path))
}

///|
pub fn plan_content_discovery_task(
  config : LoadedConfig,
) -> RuntimeIOTask[Result[ContentDiscoveryPlan, ContentDiscoveryError]] {
  Ready(try? plan_content_discovery(config))
}

///|
pub fn discover_content_task(
  config : LoadedConfig,
) -> RuntimeIOTask[Result[ContentInventory, ContentDiscoveryError]] {
  let plan_result = run_runtime_io_task(plan_content_discovery_task(config))
  let inventory = match plan_result {
    Ok(plan) => try discover_planned_content(plan) catch {
      err => Err(err)
    } noraise {
      value => Ok(value)
    }
    Err(err) => Err(err)
  }
  Ready(inventory)
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
  Ready(emit_starter_project_result(plan))
}
