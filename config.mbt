///|
/// Configuration loading failures for build phase 1a.
pub(all) suberror ConfigError {
  IOError(ProjectIOError)
  InvalidPath(path~ : String, reason~ : String)
  InvalidLine(line~ : Int, content~ : String)
  InvalidSection(line~ : Int, section~ : String)
  MissingSection(String)
  MissingField(section~ : String, key~ : String)
  DuplicateField(section~ : String, key~ : String)
} derive(Show, Eq)

///|
/// Loaded build configuration resolved from `moonink.toml`.
pub(all) struct LoadedConfig {
  config_path : String
  project_root : String
  site_name : String
  site_url : String?
  docs_dir : String
  articles_dir : String
  output_dir : String
  theme_name : String
  text_encoding : String
} derive(Show, Eq)

///|
fn config_path_policy_error(path : String, err : PathPolicyError) -> ConfigError {
  ConfigError::InvalidPath(path=path, reason=err.to_string())
}

///|
pub fn normalize_config_path_or_error(value : String) -> String raise ConfigError {
  normalize_relative_path(value) catch {
    err => raise config_path_policy_error(value, err)
  }
}

///|
pub fn parse_loaded_config(
  config_path : String,
  source : String,
) -> LoadedConfig raise ConfigError {
  let sections = parse_toml_sections(source)
  let project_root = dirname_relative_path(config_path) catch {
    err => raise config_path_policy_error(config_path, err)
  }
  {
    config_path,
    project_root,
    site_name: require_field(sections, "site", "name"),
    site_url: optional_field(sections, "site", "url"),
    docs_dir: normalized_content_path(sections, "content", "docs"),
    articles_dir: normalized_content_path(sections, "content", "articles"),
    output_dir: normalized_content_path(sections, "build", "output"),
    theme_name: optional_field(sections, "theme", "name").unwrap_or("default"),
    text_encoding: TEXT_ENCODING_NAME,
  }
}

///|
fn parse_string_value(line_number : Int, raw_value : String) -> String raise ConfigError {
  let value = raw_value.trim().to_string()
  if value.length() < 2 || !value.has_prefix("\"") || !value.has_suffix("\"") {
    raise ConfigError::InvalidLine(line=line_number, content=raw_value)
  }
  value[1:value.length() - 1].to_string()
}

///|
fn parse_section_name(line_number : Int, line : String) -> String raise ConfigError {
  if line.length() < 3 || !line.has_prefix("[") || !line.has_suffix("]") {
    raise ConfigError::InvalidSection(line=line_number, section=line)
  }
  let section = line[1:line.length() - 1].trim().to_string()
  if section.is_empty() {
    raise ConfigError::InvalidSection(line=line_number, section=line)
  }
  section
}

///|
fn parse_toml_sections(source : String) -> Map[String, Map[String, String]] raise ConfigError {
  let sections : Map[String, Map[String, String]] = {}
  let lines = source.split("\n").map(StringView::to_string).collect()
  let mut current_section : String? = None
  for i in 0..<lines.length() {
    let line_number = i + 1
    let raw_line = lines[i]
    let line = raw_line.trim().to_string()
    if line.is_empty() || line.has_prefix("#") {
      continue
    }
    if line.has_prefix("[") {
      current_section = Some(parse_section_name(line_number, line))
      continue
    }
    let section_name = match current_section {
      Some(section_name) => section_name
      None => raise ConfigError::InvalidLine(line=line_number, content=raw_line)
    }
    match line.split_once("=") {
      Some((raw_key, raw_value)) => {
        let key = raw_key.trim().to_string()
        if key.is_empty() {
          raise ConfigError::InvalidLine(line=line_number, content=raw_line)
        }
        let value = parse_string_value(line_number, raw_value.to_string())
        let fields = match sections.get(section_name) {
          Some(fields) => fields
          None => {
            let created : Map[String, String] = {}
            sections[section_name] = created
            sections[section_name]
          }
        }
        if fields.contains(key) {
          raise ConfigError::DuplicateField(section=section_name, key=key)
        }
        fields[key] = value
      }
      None => raise ConfigError::InvalidLine(line=line_number, content=raw_line)
    }
  }
  sections
}

///|
fn require_section(
  sections : Map[String, Map[String, String]],
  section : String,
) -> Map[String, String] raise ConfigError {
  match sections.get(section) {
    Some(fields) => fields
    None => raise ConfigError::MissingSection(section)
  }
}

///|
fn require_field(
  sections : Map[String, Map[String, String]],
  section : String,
  key : String,
) -> String raise ConfigError {
  let fields = require_section(sections, section)
  match fields.get(key) {
    Some(value) => value
    None => raise ConfigError::MissingField(section=section, key=key)
  }
}

///|
fn optional_field(
  sections : Map[String, Map[String, String]],
  section : String,
  key : String,
) -> String? {
  match sections.get(section) {
    Some(fields) => fields.get(key)
    None => None
  }
}

///|
fn normalized_content_path(
  sections : Map[String, Map[String, String]],
  section : String,
  key : String,
) -> String raise ConfigError {
  let value = require_field(sections, section, key)
  normalize_relative_path(value) catch {
    err => raise config_path_policy_error(value, err)
  }
}

///|
pub fn load_config(config_path? : String = "moonink.toml") -> LoadedConfig raise ConfigError {
  let config_path = normalize_config_path_or_error(config_path)
  let source = io_read_file_to_string(config_path) catch {
    err => raise ConfigError::IOError(err)
  }
  parse_loaded_config(config_path, source)
}
