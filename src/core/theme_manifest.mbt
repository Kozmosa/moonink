///|
pub(all) struct ThemeTokenDeclaration {
  name : String
  default_value : String?
} derive(Debug, Eq)

///|
pub(all) struct ThemeManifest {
  name : String
  layouts : Map[String, String]
  tokens : Array[ThemeTokenDeclaration]
  page_overrides : Array[String]
  slots : Array[String]
} derive(Debug, Eq)

///|
pub impl Show for ThemeTokenDeclaration with output(self, logger) {
  logger.write_string("ThemeTokenDeclaration(name=")
  logger.write_object(self.name)
  logger.write_string(", default_value=")
  logger.write_object(self.default_value)
  logger.write_string(")")
}

///|
pub impl Show for ThemeManifest with output(self, logger) {
  logger.write_string("ThemeManifest(name=")
  logger.write_object(self.name)
  logger.write_string(", layouts=")
  logger.write_object(self.layouts)
  logger.write_string(", tokens=")
  logger.write_object(self.tokens)
  logger.write_string(", page_overrides=")
  logger.write_object(self.page_overrides)
  logger.write_string(", slots=")
  logger.write_object(self.slots)
  logger.write_string(")")
}

///|
pub(all) suberror ThemeManifestError {
  InvalidJson(detail~ : String)
  MissingField(key~ : String)
  InvalidField(key~ : String, detail~ : String)
} derive(Debug, Eq)

///|
pub impl Show for ThemeManifestError with output(self, logger) {
  match self {
    ThemeManifestError::InvalidJson(detail~) => {
      logger.write_string("InvalidJson(detail=\"")
      logger.write_string(detail)
      logger.write_string("\")")
    }
    ThemeManifestError::MissingField(key~) => {
      logger.write_string("MissingField(key=\"")
      logger.write_string(key)
      logger.write_string("\")")
    }
    ThemeManifestError::InvalidField(key~, detail~) => {
      logger.write_string("InvalidField(key=\"")
      logger.write_string(key)
      logger.write_string("\", detail=\"")
      logger.write_string(detail)
      logger.write_string("\")")
    }
  }
}

///|
fn is_valid_theme_token_segment_char(char : String) -> Bool {
  (char >= "a" && char <= "z") || (char >= "0" && char <= "9")
}

///|
fn is_valid_theme_token_name(name : String) -> Bool {
  if name.length() == 0 {
    return false
  }
  for part_view in name.split(".") {
    let part = part_view.to_string()
    if part.length() == 0 {
      return false
    }
    for i in 0..<part.length() {
      if !is_valid_theme_token_segment_char(part[i:i + 1].to_string()) {
        return false
      }
    }
  }
  true
}

///|
fn require_json_object_string_map(
  obj : Map[String, Json],
  key : String,
) -> Map[String, String] raise ThemeManifestError {
  match obj.get(key) {
    None => {}
    Some(Object(value)) => {
      let result : Map[String, String] = {}
      for entry in value {
        let (entry_key, entry_value) = entry
        match entry_value {
          String(text) => result[entry_key] = text
          _ =>
            raise ThemeManifestError::InvalidField(
              key~,
              detail="must contain only string values",
            )
        }
      }
      result
    }
    Some(_) =>
      raise ThemeManifestError::InvalidField(
        key~,
        detail="must be a JSON object",
      )
  }
}

///|
fn parse_theme_token_declarations(
  obj : Map[String, Json],
) -> Array[ThemeTokenDeclaration] raise ThemeManifestError {
  match obj.get("tokens") {
    None => []
    Some(Array(items)) => {
      let result : Array[ThemeTokenDeclaration] = []
      let token_names : Map[String, Bool] = {}
      for item in items {
        guard item is Object(token_obj) else {
          raise ThemeManifestError::InvalidField(
            key="tokens",
            detail="must contain only objects",
          )
        }
        let name = match token_obj.get("name") {
          Some(String(name)) => name
          _ =>
            raise ThemeManifestError::InvalidField(
              key="tokens",
              detail="each token must include a string `name`",
            )
        }
        if !is_valid_theme_token_name(name) {
          raise ThemeManifestError::InvalidField(
            key="tokens",
            detail="token `name` values must be dot-separated lowercase ASCII letters and digits",
          )
        }
        if token_names.get(name) is Some(_) {
          raise ThemeManifestError::InvalidField(
            key="tokens",
            detail="token `name` values must be unique",
          )
        }
        token_names[name] = true
        let default_value = match token_obj.get("default") {
          None => None
          Some(String(value)) => Some(value)
          Some(_) =>
            raise ThemeManifestError::InvalidField(
              key="tokens",
              detail="token `default` values must be strings",
            )
        }
        result.push({ name, default_value })
      }
      result
    }
    Some(_) =>
      raise ThemeManifestError::InvalidField(
        key="tokens",
        detail="must be an array",
      )
  }
}

///|
fn require_json_string_array(
  obj : Map[String, Json],
  key : String,
) -> Array[String] raise ThemeManifestError {
  match obj.get(key) {
    None => []
    Some(Array(items)) => {
      let result : Array[String] = []
      for item in items {
        match item {
          String(value) => result.push(value)
          _ =>
            raise ThemeManifestError::InvalidField(
              key~,
              detail="must contain only strings",
            )
        }
      }
      result
    }
    Some(_) =>
      raise ThemeManifestError::InvalidField(key~, detail="must be an array")
  }
}

///|
pub fn parse_theme_manifest_result(
  source : String,
) -> Result[ThemeManifest, ThemeManifestError] {
  let json = @json.parse(source.view()) catch {
    err => return Err(ThemeManifestError::InvalidJson(detail=err.to_string()))
  }
  guard json is Object(obj) else {
    return Err(
      ThemeManifestError::InvalidJson(
        detail="expected JSON object at top level",
      ),
    )
  }
  let name = match obj.get("name") {
    Some(String(name)) => name
    _ => return Err(ThemeManifestError::MissingField(key="name"))
  }
  let layouts = require_json_object_string_map(obj, "layouts") catch {
    err => return Err(err)
  }
  let tokens = parse_theme_token_declarations(obj) catch {
    err => return Err(err)
  }
  let page_overrides = require_json_string_array(obj, "page_overrides") catch {
    err => return Err(err)
  }
  let slots = require_json_string_array(obj, "slots") catch {
    err => return Err(err)
  }
  Ok({ name, layouts, tokens, page_overrides, slots })
}
