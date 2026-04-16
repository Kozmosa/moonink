///|
/// Route style for URL generation.
pub(all) enum RouteStyle {
  Pretty
  Direct
} derive(Debug, Eq)

///|
pub impl Show for RouteStyle with output(self, logger) {
  match self {
    Pretty => logger.write_string("Pretty")
    Direct => logger.write_string("Direct")
  }
}

///|
pub(all) enum ThemeConfigValue {
  NullValue
  BoolValue(Bool)
  NumberValue(String)
  StringValue(String)
  ArrayValue(Array[ThemeConfigValue])
  ObjectValue(Map[String, ThemeConfigValue])
} derive(Debug, Eq)

///|
pub impl Show for ThemeConfigValue with output(self, logger) {
  match self {
    NullValue => logger.write_string("NullValue")
    BoolValue(value) => {
      logger.write_string("BoolValue(")
      logger.write_object(value)
      logger.write_string(")")
    }
    NumberValue(value) => {
      logger.write_string("NumberValue(")
      logger.write_object(value)
      logger.write_string(")")
    }
    StringValue(value) => {
      logger.write_string("StringValue(")
      logger.write_object(value)
      logger.write_string(")")
    }
    ArrayValue(values) => {
      logger.write_string("ArrayValue(")
      logger.write_object(values)
      logger.write_string(")")
    }
    ObjectValue(values) => {
      logger.write_string("ObjectValue(")
      logger.write_object(values)
      logger.write_string(")")
    }
  }
}

///|
/// Configuration loading failures.
pub(all) suberror ConfigError {
  IOError(ProjectIOError)
  InvalidPath(path~ : String, reason~ : String)
  InvalidJson(detail~ : String)
  MissingField(key~ : String)
  InvalidField(key~ : String, detail~ : String)
} derive(Debug, Eq)

///|
pub impl Show for ConfigError with output(self, logger) {
  match self {
    ConfigError::IOError(err) => {
      logger.write_string("IOError(")
      logger.write_string(format_project_io_error(err))
      logger.write_string(")")
    }
    ConfigError::InvalidPath(path~, reason~) => {
      logger.write_string("InvalidPath(path=\"")
      logger.write_string(path)
      logger.write_string("\", reason=\"")
      logger.write_string(reason)
      logger.write_string("\")")
    }
    ConfigError::InvalidJson(detail~) => {
      logger.write_string("InvalidJson(detail=\"")
      logger.write_string(detail)
      logger.write_string("\")")
    }
    ConfigError::MissingField(key~) => {
      logger.write_string("MissingField(key=\"")
      logger.write_string(key)
      logger.write_string("\")")
    }
    ConfigError::InvalidField(key~, detail~) => {
      logger.write_string("InvalidField(key=\"")
      logger.write_string(key)
      logger.write_string("\", detail=\"")
      logger.write_string(detail)
      logger.write_string("\")")
    }
  }
}

///|
/// Loaded build configuration resolved from `moonink.json`.
pub(all) struct MooninkConfig {
  config_path : String
  project_root : String
  site_name : String
  site_url : String?
  content_dir : String
  output_dir : String
  template_file : String?
  exclude : Array[String]
  route_style : RouteStyle
  text_encoding : String
  theme : String?
  theme_config : Map[String, ThemeConfigValue]
} derive(Debug, Eq)

///|
pub fn normalize_output_dir_or_error(
  value : String,
) -> String raise ConfigError {
  normalize_relative_path(value) catch {
    err => raise config_path_policy_error(value, err)
  }
}

///|
pub fn config_with_output_dir(
  config : MooninkConfig,
  output_dir : String,
) -> MooninkConfig raise ConfigError {
  {
    ..config,
    output_dir: normalize_output_dir_or_error(output_dir) catch {
      err => raise err
    },
  }
}

///|
pub impl Show for MooninkConfig with output(self, logger) {
  logger.write_string("MooninkConfig(site_name=\"")
  logger.write_string(self.site_name)
  logger.write_string("\")")
}

///|
fn config_path_policy_error(
  path : String,
  err : PathPolicyError,
) -> ConfigError {
  ConfigError::InvalidPath(path~, reason=format_path_policy_error(err))
}

///|
pub fn normalize_config_path_or_error(
  value : String,
) -> String raise ConfigError {
  normalize_relative_path(value) catch {
    err => raise config_path_policy_error(value, err)
  }
}

///|
fn default_exclude() -> Array[String] {
  [".obsidian", "dist", ".git", "node_modules"]
}

///|
fn extract_json_string(obj : Map[String, Json], key : String) -> String? {
  match obj.get(key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}

///|
fn extract_json_string_array(
  obj : Map[String, Json],
  key : String,
) -> Array[String] {
  match obj.get(key) {
    Some(Array(arr)) => {
      let result : Array[String] = []
      for item in arr {
        match item {
          String(s) => result.push(s)
          _ => ()
        }
      }
      result
    }
    _ => []
  }
}

///|
pub fn extract_json_object(
  obj : Map[String, Json],
  key : String,
) -> Map[String, Json]? {
  match obj.get(key) {
    Some(Object(value)) => Some(value)
    _ => None
  }
}

///|
fn extract_theme_config(
  obj : Map[String, Json],
) -> Map[String, ThemeConfigValue] raise ConfigError {
  match obj.get("theme_config") {
    None => {}
    Some(Object(value)) =>
      parse_theme_config_object(value) catch {
        err => raise err
      }
    Some(_) =>
      raise ConfigError::InvalidField(
        key="theme_config",
        detail="must be a JSON object",
      )
  }
}

///|
fn parse_theme_config_object(
  obj : Map[String, Json],
) -> Map[String, ThemeConfigValue] raise ConfigError {
  let result : Map[String, ThemeConfigValue] = {}
  for entry in obj {
    let (key, value) = entry
    result[key] = parse_theme_config_value(value) catch { err => raise err }
  }
  result
}

///|
fn parse_theme_config_array(
  values : Array[Json],
) -> Array[ThemeConfigValue] raise ConfigError {
  let result : Array[ThemeConfigValue] = []
  for value in values {
    result.push(parse_theme_config_value(value) catch { err => raise err })
  }
  result
}

///|
fn parse_theme_config_value(value : Json) -> ThemeConfigValue raise ConfigError {
  match value {
    Null => ThemeConfigValue::NullValue
    True => ThemeConfigValue::BoolValue(true)
    False => ThemeConfigValue::BoolValue(false)
    Number(_, repr~) =>
      ThemeConfigValue::NumberValue(
        match repr {
          Some(repr) => repr
          None => value.stringify()
        },
      )
    String(text) => ThemeConfigValue::StringValue(text)
    Array(values) =>
      ThemeConfigValue::ArrayValue(
        parse_theme_config_array(values) catch {
          err => raise err
        },
      )
    Object(obj) =>
      ThemeConfigValue::ObjectValue(
        parse_theme_config_object(obj) catch {
          err => raise err
        },
      )
  }
}

///|
/// Parse configuration from JSON string content.
pub fn parse_config_json(
  config_path : String,
  source : String,
) -> MooninkConfig raise ConfigError {
  let json = @json.parse(source.view()) catch {
    err => raise ConfigError::InvalidJson(detail=err.to_string())
  }
  guard json is Object(obj) else {
    raise ConfigError::InvalidJson(detail="expected JSON object at top level")
  }
  let project_root = dirname_relative_path(config_path) catch {
    err => raise config_path_policy_error(config_path, err)
  }
  let site_name = match extract_json_string(obj, "site_name") {
    Some(name) => name
    None => raise ConfigError::MissingField(key="site_name")
  }
  let site_url = extract_json_string(obj, "site_url")
  let content_dir = match extract_json_string(obj, "content_dir") {
    Some(dir) => dir
    None => "."
  }
  let output_dir = match extract_json_string(obj, "output_dir") {
    Some(dir) => dir
    None => "dist"
  }
  let template_file = match extract_json_string(obj, "template_file") {
    Some(path) =>
      Some(normalize_config_path_or_error(path) catch { err => raise err })
    None => None
  }
  let exclude_raw = extract_json_string_array(obj, "exclude")
  let exclude = if exclude_raw.is_empty() {
    default_exclude()
  } else {
    exclude_raw
  }
  let route_style = match extract_json_string(obj, "route_style") {
    Some("direct") => RouteStyle::Direct
    _ => RouteStyle::Pretty
  }
  let theme = extract_json_string(obj, "theme")
  let theme_config = extract_theme_config(obj) catch { err => raise err }
  {
    config_path,
    project_root,
    site_name,
    site_url,
    content_dir,
    output_dir,
    template_file,
    exclude,
    route_style,
    text_encoding: TEXT_ENCODING_NAME,
    theme,
    theme_config,
  }
}

///|
pub fn format_config_error(err : ConfigError) -> String {
  match err {
    ConfigError::IOError(io_error) =>
      "[config] io error:\n\{format_project_io_error(io_error)}"
    ConfigError::InvalidPath(path~, reason~) =>
      "[config] invalid path: \{path}\nreason: \{reason}"
    ConfigError::InvalidJson(detail~) => "[config] invalid JSON: \{detail}"
    ConfigError::MissingField(key~) => "[config] missing required field: \{key}"
    ConfigError::InvalidField(key~, detail~) =>
      "[config] invalid field `\{key}`: \{detail}"
  }
}
