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
pub(all) struct AuthorProfileLink {
  label : String
  url : String
} derive(Debug, Eq)

///|
pub(all) struct AuthorProfile {
  name : String?
  bio : String?
  avatar : String?
  links : Array[AuthorProfileLink]
  homepage_text : String?
} derive(Debug, Eq)

///|
pub fn AuthorProfile::default() -> AuthorProfile {
  { name: None, bio: None, avatar: None, links: [], homepage_text: None }
}

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
  author_profile : AuthorProfile
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
fn normalize_content_dir_or_error(value : String) -> String raise ConfigError {
  let trimmed = value.trim().to_string()
  if trimmed == "." {
    "."
  } else {
    normalize_relative_path(trimmed) catch {
      err => raise config_path_policy_error(value, err)
    }
  }
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
pub fn default_exclude() -> Array[String] {
  [
    ".obsidian", "dist", ".git", "node_modules", ".trash", "templates", "Templates",
  ]
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
fn extract_optional_json_string_array(
  obj : Map[String, Json],
  key : String,
) -> Array[String]? {
  match obj.get(key) {
    Some(Array(_)) => Some(extract_json_string_array(obj, key))
    _ => None
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
  match extract_json_object(obj, "theme_config") {
    Some(value) => parse_theme_config_object(value)
    None =>
      match obj.get("theme_config") {
        None => {}
        Some(_) =>
          raise ConfigError::InvalidField(
            key="theme_config",
            detail="must be a JSON object",
          )
      }
  }
}

///|
fn parse_author_profile_link(
  value : Json,
) -> AuthorProfileLink raise ConfigError {
  guard value is Object(obj) else {
    raise ConfigError::InvalidField(
      key="author.links",
      detail="each link entry must be an object",
    )
  }
  let label = match extract_json_string(obj, "label") {
    Some(value) => value
    None =>
      raise ConfigError::InvalidField(
        key="author.links",
        detail="each link entry must have a string `label` field",
      )
  }
  let url = match extract_json_string(obj, "url") {
    Some(value) => value
    None =>
      raise ConfigError::InvalidField(
        key="author.links",
        detail="each link entry must have a string `url` field",
      )
  }
  { label, url }
}

///|
fn parse_author_profile(
  obj : Map[String, Json],
) -> AuthorProfile raise ConfigError {
  let links = match obj.get("links") {
    None => []
    Some(Array(values)) => {
      let result : Array[AuthorProfileLink] = []
      for value in values {
        result.push(parse_author_profile_link(value))
      }
      result
    }
    Some(_) =>
      raise ConfigError::InvalidField(
        key="author.links",
        detail="must be an array of objects",
      )
  }
  {
    name: extract_json_string(obj, "name"),
    bio: extract_json_string(obj, "bio"),
    avatar: extract_json_string(obj, "avatar"),
    links,
    homepage_text: extract_json_string(obj, "homepage_text"),
  }
}

///|
fn extract_author_profile(
  obj : Map[String, Json],
) -> AuthorProfile raise ConfigError {
  match obj.get("author") {
    None => AuthorProfile::default()
    Some(Object(value)) => parse_author_profile(value)
    Some(_) =>
      raise ConfigError::InvalidField(
        key="author",
        detail="must be a JSON object",
      )
  }
}

///|
fn parse_theme_config_object(
  obj : Map[String, Json],
) -> Map[String, ThemeConfigValue] {
  let result : Map[String, ThemeConfigValue] = {}
  for entry in obj {
    let (key, value) = entry
    result[key] = theme_config_value_from_json(value)
  }
  result
}

///|
fn parse_theme_config_array(values : Array[Json]) -> Array[ThemeConfigValue] {
  let result : Array[ThemeConfigValue] = []
  for value in values {
    result.push(theme_config_value_from_json(value))
  }
  result
}

///|
pub fn parse_config_json_with_project_root(
  config_path : String,
  project_root : String,
  source : String,
) -> MooninkConfig raise ConfigError {
  let json = @json.parse(source.view()) catch {
    err => raise ConfigError::InvalidJson(detail=err.to_string())
  }
  guard json is Object(obj) else {
    raise ConfigError::InvalidJson(detail="expected JSON object at top level")
  }
  let site_name = match extract_json_string(obj, "site_name") {
    Some(name) => name
    None => raise ConfigError::MissingField(key="site_name")
  }
  let site_url = extract_json_string(obj, "site_url")
  let content_dir = match extract_json_string(obj, "content_dir") {
    Some(dir) => normalize_content_dir_or_error(dir)
    None => "."
  }
  let output_dir = match extract_json_string(obj, "output_dir") {
    Some(dir) => normalize_output_dir_or_error(dir)
    None => "dist"
  }
  let template_file = match extract_json_string(obj, "template_file") {
    Some(path) => Some(normalize_config_path_or_error(path))
    None => None
  }
  let exclude = match extract_optional_json_string_array(obj, "exclude") {
    Some(values) => values
    None => default_exclude()
  }
  let route_style = match extract_json_string(obj, "route_style") {
    Some("direct") => RouteStyle::Direct
    _ => RouteStyle::Pretty
  }
  let theme = match extract_json_string(obj, "theme") {
    Some(path) => Some(normalize_config_path_or_error(path))
    None => None
  }
  let theme_config = extract_theme_config(obj)
  let author_profile = extract_author_profile(obj)
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
    author_profile,
  }
}

///|
pub fn theme_config_value_from_json(value : Json) -> ThemeConfigValue {
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
      ThemeConfigValue::ArrayValue(parse_theme_config_array(values))
    Object(obj) => ThemeConfigValue::ObjectValue(parse_theme_config_object(obj))
  }
}

///|
/// Parse configuration from JSON string content.
pub fn parse_config_json(
  config_path : String,
  source : String,
) -> MooninkConfig raise ConfigError {
  let project_root = dirname_relative_path(config_path) catch {
    err => raise config_path_policy_error(config_path, err)
  }
  parse_config_json_with_project_root(config_path, project_root, source)
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
