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
pub(all) suberror ThemeManifestError {
  InvalidJson(detail~ : String)
  MissingField(key~ : String)
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
  }
}

///|
fn extract_json_object_string_map(
  obj : Map[String, Json],
  key : String,
) -> Map[String, String] {
  match extract_json_object(obj, key) {
    Some(value) => {
      let result : Map[String, String] = {}
      for entry in value {
        let (entry_key, entry_value) = entry
        match entry_value {
          String(text) => result[entry_key] = text
          _ => ()
        }
      }
      result
    }
    None => {}
  }
}

///|
fn parse_theme_token_declarations(
  obj : Map[String, Json],
) -> Array[ThemeTokenDeclaration] {
  match obj.get("tokens") {
    Some(Array(items)) => {
      let result : Array[ThemeTokenDeclaration] = []
      for item in items {
        guard item is Object(token_obj) else { continue }
        match token_obj.get("name") {
          Some(String(name)) => {
            let default_value = match token_obj.get("default") {
              Some(String(value)) => Some(value)
              _ => None
            }
            result.push({ name, default_value })
          }
          _ => ()
        }
      }
      result
    }
    _ => []
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
  Ok({
    name,
    layouts: extract_json_object_string_map(obj, "layouts"),
    tokens: parse_theme_token_declarations(obj),
    page_overrides: extract_json_string_array(obj, "page_overrides"),
    slots: extract_json_string_array(obj, "slots"),
  })
}
