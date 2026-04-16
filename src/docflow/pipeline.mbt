///|
fn expected_format_for_adapter(adapter : ParserAdapter) -> @core.SourceFormat? {
  if adapter.name == "markdown-parser-adapter" {
    Some(@core.SourceFormat::Markdown)
  } else if adapter.name == "html-passthrough-parser" {
    Some(@core.SourceFormat::Html)
  } else {
    None
  }
}

///|
fn parse_document_with_adapter_result(
  adapter : ParserAdapter,
  input : SourceDocumentInput,
) -> Result[ParsedDocument, FatalParseError] {
  if adapter.name == "" {
    return Err(
      FatalParseError::InvalidAdapterState(
        adapter_name="",
        reason="adapter name must not be empty",
      ),
    )
  }
  if adapter.name == "broken-parser-adapter" {
    return Err(
      FatalParseError::BackendFailure(
        adapter_name=adapter.name,
        detail="intentional fatal parse failure",
      ),
    )
  }
  match expected_format_for_adapter(adapter) {
    Some(expected) if expected != input.format =>
      return Err(
        FatalParseError::UnsupportedFormat(
          adapter_name=adapter.name,
          expected~,
          actual=input.format,
        ),
      )
    _ => ()
  }
  if adapter.name == "markdown-parser-adapter" {
    let contract = parse_markdown_backend_contract(input.content)
    Ok({
      backend_name: adapter.name,
      source_format: input.format,
      source_path: input.path,
      source_uuid: input.uuid,
      diagnostics: contract.diagnostics,
      backend_payload: Some(contract.serialized_markdown),
    })
  } else if adapter.name == "html-passthrough-parser" {
    Ok({
      backend_name: adapter.name,
      source_format: input.format,
      source_path: input.path,
      source_uuid: input.uuid,
      diagnostics: empty_document_diagnostics(),
      backend_payload: Some(input.content),
    })
  } else {
    Ok({
      backend_name: adapter.name,
      source_format: input.format,
      source_path: input.path,
      source_uuid: input.uuid,
      diagnostics: empty_document_diagnostics(),
      backend_payload: Some("fake-parse:\{input.path}"),
    })
  }
}

///|
/// Parse through the adapter boundary and preserve the split between recoverable diagnostics and fatal parser failures.
pub fn parse_with_adapter_result(
  adapter : ParserAdapter,
  input : SourceDocumentInput,
) -> Result[ParsedDocument, FatalParseError] {
  parse_document_with_adapter_result(adapter, input)
}

///|
/// Run a parser adapter so tests can freeze the adapter boundary before real backends land.
pub fn parse_with_adapter(
  adapter : ParserAdapter,
  input : SourceDocumentInput,
) -> ParsedDocument {
  match parse_with_adapter_result(adapter, input) {
    Ok(parsed) => parsed
    Err(_) => panic()
  }
}

///|
/// Run a render adapter so tests can freeze the HTML render contract before real backends land.
pub fn render_with_adapter(
  adapter : RenderAdapter,
  parsed : ParsedDocument,
) -> RenderedDocument {
  let html_body = if adapter.name == "markdown-render-adapter" &&
    parsed.source_format == @core.SourceFormat::Markdown {
    let markdown_payload = match parsed.backend_payload {
      Some(payload) => payload
      None => ""
    }
    render_markdown_backend_payload(markdown_payload)
  } else {
    let payload = match parsed.backend_payload {
      Some(payload) => payload
      None => parsed.source_path
    }
    "<article data-renderer=\"\{adapter.name}\" data-source-format=\"\{parsed.source_format.to_string()}\">\{payload}</article>"
  }
  {
    backend_name: adapter.name,
    source_path: parsed.source_path,
    source_uuid: parsed.source_uuid,
    html: html_body,
    note: adapter.note,
  }
}

///|
/// Build a stable route from a source path for dummy downstream assembly.
pub fn route_from_source_path(source_path : String) -> String {
  "/" + source_path
}

///|
fn theme_string_value(value : String) -> @core.ThemeConfigValue {
  @core.ThemeConfigValue::StringValue(value)
}

///|
fn theme_array_value(values : Array[String]) -> @core.ThemeConfigValue {
  @core.ThemeConfigValue::ArrayValue(
    values.map(fn(value) { theme_string_value(value) }),
  )
}

///|
fn theme_object_string(
  entries : Map[String, String],
) -> Map[String, @core.ThemeConfigValue] {
  let result : Map[String, @core.ThemeConfigValue] = {}
  for entry in entries {
    let (key, value) = entry
    result[key] = theme_string_value(value)
  }
  result
}

///|
fn theme_value_to_string(value : @core.ThemeConfigValue) -> String {
  match value {
    @core.ThemeConfigValue::NullValue => ""
    @core.ThemeConfigValue::BoolValue(flag) =>
      if flag {
        "true"
      } else {
        "false"
      }
    @core.ThemeConfigValue::NumberValue(number) => number
    @core.ThemeConfigValue::StringValue(text) => text
    @core.ThemeConfigValue::ArrayValue(values) =>
      values.map(fn(value) { theme_value_to_string(value) }).iter().join(",")
    @core.ThemeConfigValue::ObjectValue(_) => ""
  }
}

///|
fn theme_value_is_truthy(value : @core.ThemeConfigValue) -> Bool {
  match value {
    @core.ThemeConfigValue::NullValue => false
    @core.ThemeConfigValue::BoolValue(flag) => flag
    @core.ThemeConfigValue::NumberValue(number) => !number.is_empty()
    @core.ThemeConfigValue::StringValue(text) => !text.is_empty()
    @core.ThemeConfigValue::ArrayValue(values) => !values.is_empty()
    @core.ThemeConfigValue::ObjectValue(values) => !values.is_empty()
  }
}

///|
fn theme_root_value(
  context : ThemeRenderContext,
  root : String,
) -> @core.ThemeConfigValue? {
  match root {
    "site" => Some(@core.ThemeConfigValue::ObjectValue(context.site))
    "page" => Some(@core.ThemeConfigValue::ObjectValue(context.page))
    "collections" =>
      Some(@core.ThemeConfigValue::ObjectValue(context.collections))
    "slots" => Some(@core.ThemeConfigValue::ObjectValue(context.slots))
    _ => context.locals.get(root)
  }
}

///|
fn lookup_theme_value_in_object(
  value : @core.ThemeConfigValue,
  key : String,
) -> @core.ThemeConfigValue? {
  match value {
    @core.ThemeConfigValue::ObjectValue(entries) => entries.get(key)
    _ => None
  }
}

///|
fn lookup_theme_value(
  context : ThemeRenderContext,
  path : String,
) -> @core.ThemeConfigValue? {
  let parts = path
    .split(".")
    .map(fn(part) { part.to_string().trim().to_string() })
    .collect()
  if parts.is_empty() {
    return None
  }
  let mut resolved = theme_root_value(context, parts[0])
  for index in 1..<parts.length() {
    resolved = match resolved {
      Some(value) => lookup_theme_value_in_object(value, parts[index])
      None => None
    }
  }
  resolved
}

///|
fn lookup_theme_string(context : ThemeRenderContext, path : String) -> String {
  match lookup_theme_value(context, path) {
    Some(value) => theme_value_to_string(value)
    None => ""
  }
}

///|
fn trim_template_variable_name(name : String) -> String {
  name.trim().to_string()
}

///|
fn find_template_close(template : String, start : Int) -> Int? {
  if start < 0 || start + 1 >= template.length() {
    return None
  }
  for i in start..<(template.length() - 1) {
    let pair = template[i:i + 2].to_string()
    if pair == "}}" {
      return Some(i)
    }
  }
  None
}

///|
fn render_template_paths(
  template : String,
  context : ThemeRenderContext,
) -> String {
  let mut cursor = 0
  let mut output = ""
  while cursor < template.length() {
    if cursor + 1 < template.length() &&
      template[cursor:cursor + 2].to_string() == "{{" {
      match find_template_close(template, cursor + 2) {
        Some(close) => {
          let variable = trim_template_variable_name(
            template[cursor + 2:close].to_string(),
          )
          output = output + lookup_theme_string(context, variable)
          cursor = close + 2
        }
        None => {
          output = output + template[cursor:].to_string()
          cursor = template.length()
        }
      }
    } else {
      output = output + template[cursor:cursor + 1].to_string()
      cursor = cursor + 1
    }
  }
  output
}

///|
fn find_template_tag_close(template : String, start : Int) -> Int? {
  if start < 0 || start + 1 >= template.length() {
    return None
  }
  for i in start..<(template.length() - 1) {
    let pair = template[i:i + 2].to_string()
    if pair == "%}" {
      return Some(i)
    }
  }
  None
}

///|
fn find_template_block_end(
  template : String,
  start : Int,
  open_tag : String,
  close_tag : String,
) -> (Int, Int)? {
  let mut cursor = start
  let mut depth = 1
  while cursor < template.length() {
    if cursor + 1 < template.length() &&
      template[cursor:cursor + 2].to_string() == "{%" {
      match find_template_tag_close(template, cursor + 2) {
        Some(close) => {
          let tag = trim_template_variable_name(
            template[cursor + 2:close].to_string(),
          )
          if tag.has_prefix(open_tag) {
            depth = depth + 1
          } else if tag == close_tag {
            depth = depth - 1
            if depth == 0 {
              return Some((cursor, close + 2))
            }
          }
          cursor = close + 2
        }
        None => return None
      }
    } else {
      cursor = cursor + 1
    }
  }
  None
}

///|
fn parse_include_name(tag : String) -> String? {
  if !tag.has_prefix("include ") {
    return None
  }
  let name = tag[8:].to_string().trim().to_string()
  if name.length() >= 2 &&
    name[0:1].to_string() == "\"" &&
    name[name.length() - 1:name.length()].to_string() == "\"" {
    Some(name[1:name.length() - 1].to_string())
  } else {
    None
  }
}

///|
fn copy_string_array(source : Array[String]) -> Array[String] {
  let copied : Array[String] = []
  for entry in source {
    copied.push(entry)
  }
  copied
}

///|
fn string_array_contains(source : Array[String], target : String) -> Bool {
  for entry in source {
    if entry == target {
      return true
    }
  }
  false
}

///|
fn include_cycle_comment(stack : Array[String], name : String) -> String {
  let cycle = copy_string_array(stack)
  cycle.push(name)
  let cycle_path = cycle.iter().join(" -> ")
  "<!-- moonink include cycle: \{cycle_path} -->"
}

///|
fn render_template_includes(
  template : String,
  context : ThemeRenderContext,
  partials : Map[String, String],
  include_stack : Array[String],
) -> String {
  let mut cursor = 0
  let mut output = ""
  while cursor < template.length() {
    if cursor + 1 < template.length() &&
      template[cursor:cursor + 2].to_string() == "{%" {
      match find_template_tag_close(template, cursor + 2) {
        Some(close) => {
          let tag = trim_template_variable_name(
            template[cursor + 2:close].to_string(),
          )
          match parse_include_name(tag) {
            Some(name) => {
              let partial = match partials.get(name) {
                Some(source) => source
                None => ""
              }
              let rendered = if string_array_contains(include_stack, name) {
                include_cycle_comment(include_stack, name)
              } else {
                let next_stack = copy_string_array(include_stack)
                next_stack.push(name)
                render_theme_template_with_stack(
                  partial,
                  context,
                  partials,
                  next_stack,
                )
              }
              output = output + rendered
              cursor = close + 2
            }
            None => {
              output = output + template[cursor:close + 2].to_string()
              cursor = close + 2
            }
          }
        }
        None => {
          output = output + template[cursor:].to_string()
          cursor = template.length()
        }
      }
    } else {
      output = output + template[cursor:cursor + 1].to_string()
      cursor = cursor + 1
    }
  }
  output
}

///|
fn render_template_conditionals(
  template : String,
  context : ThemeRenderContext,
  partials : Map[String, String],
  include_stack : Array[String],
) -> String {
  let mut cursor = 0
  let mut output = ""
  while cursor < template.length() {
    if cursor + 1 < template.length() &&
      template[cursor:cursor + 2].to_string() == "{%" {
      match find_template_tag_close(template, cursor + 2) {
        Some(close) => {
          let tag = trim_template_variable_name(
            template[cursor + 2:close].to_string(),
          )
          if tag.has_prefix("if ") {
            let condition = tag[3:].to_string().trim().to_string()
            match find_template_block_end(template, close + 2, "if ", "endif") {
              Some((block_start, block_end)) => {
                let body = template[close + 2:block_start].to_string()
                let rendered = match lookup_theme_value(context, condition) {
                  Some(value) if theme_value_is_truthy(value) =>
                    render_theme_template_with_stack(
                      body,
                      context,
                      partials,
                      include_stack,
                    )
                  _ => ""
                }
                output = output + rendered
                cursor = block_end
              }
              None => {
                output = output + template[cursor:].to_string()
                cursor = template.length()
              }
            }
          } else {
            output = output + template[cursor:close + 2].to_string()
            cursor = close + 2
          }
        }
        None => {
          output = output + template[cursor:].to_string()
          cursor = template.length()
        }
      }
    } else {
      output = output + template[cursor:cursor + 1].to_string()
      cursor = cursor + 1
    }
  }
  output
}

///|
fn parse_for_tag(tag : String) -> (String, String)? {
  if !tag.has_prefix("for ") {
    return None
  }
  let body = tag[4:].to_string().trim().to_string()
  match body.split_once(" in ") {
    Some((name, path)) => {
      let local_name = name.trim().to_string()
      let collection_path = path.trim().to_string()
      if local_name.is_empty() || collection_path.is_empty() {
        None
      } else {
        Some((local_name, collection_path))
      }
    }
    None => None
  }
}

///|
fn copy_theme_value_map(
  source : Map[String, @core.ThemeConfigValue],
) -> Map[String, @core.ThemeConfigValue] {
  let copied : Map[String, @core.ThemeConfigValue] = {}
  for entry in source {
    let (key, value) = entry
    copied[key] = value
  }
  copied
}

///|
fn context_with_local(
  context : ThemeRenderContext,
  name : String,
  value : @core.ThemeConfigValue,
) -> ThemeRenderContext {
  let locals = copy_theme_value_map(context.locals)
  locals[name] = value
  { ..context, locals, }
}

///|
fn render_template_loops(
  template : String,
  context : ThemeRenderContext,
  partials : Map[String, String],
  include_stack : Array[String],
) -> String {
  let mut cursor = 0
  let mut output = ""
  while cursor < template.length() {
    if cursor + 1 < template.length() &&
      template[cursor:cursor + 2].to_string() == "{%" {
      match find_template_tag_close(template, cursor + 2) {
        Some(close) => {
          let tag = trim_template_variable_name(
            template[cursor + 2:close].to_string(),
          )
          match parse_for_tag(tag) {
            Some((local_name, collection_path)) =>
              match
                find_template_block_end(template, close + 2, "for ", "endfor") {
                Some((block_start, block_end)) => {
                  let body = template[close + 2:block_start].to_string()
                  let rendered = match
                    lookup_theme_value(context, collection_path) {
                    Some(@core.ThemeConfigValue::ArrayValue(values)) => {
                      let parts : Array[String] = []
                      for value in values {
                        let local_context = context_with_local(
                          context, local_name, value,
                        )
                        parts.push(
                          render_theme_template_with_stack(
                            body,
                            local_context,
                            partials,
                            include_stack,
                          ),
                        )
                      }
                      parts.iter().join("")
                    }
                    _ => ""
                  }
                  output = output + rendered
                  cursor = block_end
                }
                None => {
                  output = output + template[cursor:].to_string()
                  cursor = template.length()
                }
              }
            None => {
              output = output + template[cursor:close + 2].to_string()
              cursor = close + 2
            }
          }
        }
        None => {
          output = output + template[cursor:].to_string()
          cursor = template.length()
        }
      }
    } else {
      output = output + template[cursor:cursor + 1].to_string()
      cursor = cursor + 1
    }
  }
  output
}

///|
fn render_theme_template_with_stack(
  template : String,
  context : ThemeRenderContext,
  partials : Map[String, String],
  include_stack : Array[String],
) -> String {
  let with_loops = render_template_loops(template, context, partials, include_stack)
  let with_conditionals = render_template_conditionals(
    with_loops,
    context,
    partials,
    include_stack,
  )
  let with_includes = render_template_includes(
    with_conditionals,
    context,
    partials,
    include_stack,
  )
  render_template_paths(with_includes, context)
}

///|
pub fn render_theme_template(
  template : String,
  context : ThemeRenderContext,
  partials : Map[String, String],
) -> String {
  render_theme_template_with_stack(template, context, partials, [])
}

///|
fn legacy_template_locals(
  context : TemplateContext,
) -> Map[String, @core.ThemeConfigValue] {
  let locals = theme_object_string({
    "site_name": context.site_name,
    "site_url": context.site_url,
    "page_title": context.page_title,
    "page_description": context.page_description,
    "url_path": context.url_path,
    "source_path": context.source_path,
    "content_kind": context.content_kind,
    "theme_name": context.theme_name,
    "theme_asset_root": context.theme_asset_root,
    "page_body_class": context.page_body_class,
    "navigation_html": context.navigation_html,
    "current_section_title": context.current_section_title,
    "current_section_url": context.current_section_url,
    "page_header_title": context.page_header_title,
    "page_header_html": context.page_header_html,
    "backlinks_html": context.backlinks_html,
    "body_html": context.body_html,
  })
  locals["backlink_urls"] = theme_array_value(context.backlink_urls)
  locals
}

///|
fn template_context_to_theme_render_context(
  context : TemplateContext,
) -> ThemeRenderContext {
  {
    site: theme_object_string({
      "name": context.site_name,
      "url": context.site_url,
    }),
    page: theme_object_string({
      "title": context.page_title,
      "description": context.page_description,
      "url_path": context.url_path,
      "source_path": context.source_path,
      "content_kind": context.content_kind,
      "theme_name": context.theme_name,
      "theme_asset_root": context.theme_asset_root,
      "body_class": context.page_body_class,
      "navigation_html": context.navigation_html,
      "current_section_title": context.current_section_title,
      "current_section_url": context.current_section_url,
      "page_header_title": context.page_header_title,
      "page_header_html": context.page_header_html,
      "backlinks_html": context.backlinks_html,
      "body_html": context.body_html,
    }),
    collections: {},
    slots: {
      "navigation_html": theme_string_value(context.navigation_html),
      "page_header_html": theme_string_value(context.page_header_html),
      "backlinks_html": theme_string_value(context.backlinks_html),
      "body_html": theme_string_value(context.body_html),
      "backlink_urls": theme_array_value(context.backlink_urls),
    },
    locals: legacy_template_locals(context),
  }
}

///|
pub fn default_theme_render_context(
  rendered : RenderedDocument,
) -> ThemeRenderContext {
  template_context_to_theme_render_context(default_template_context(rendered))
}

///|
pub fn render_template_string(
  template : String,
  context : TemplateContext,
) -> String {
  render_theme_template(
    template,
    template_context_to_theme_render_context(context),
    {},
  )
}

///|
pub fn default_template_context(rendered : RenderedDocument) -> TemplateContext {
  {
    site_name: "MoonInk",
    site_url: "",
    page_title: rendered.source_path,
    page_description: "",
    url_path: route_from_source_path(rendered.source_path),
    source_path: rendered.source_path,
    content_kind: "article",
    theme_name: "",
    theme_asset_root: "",
    page_body_class: "moonink-article",
    navigation_html: "",
    backlink_urls: [],
    current_section_title: "",
    current_section_url: "",
    page_header_title: "",
    page_header_html: "",
    backlinks_html: "",
    body_html: rendered.html,
  }
}

///|
pub fn default_page_template() -> String {
  "<!doctype html>\n<html><head><meta charset=\"utf-8\"><title>{{ page_title }}</title></head><body data-kind=\"{{ content_kind }}\" data-url=\"{{ url_path }}\"><header><a href=\"{{ site_url }}\">{{ site_name }}</a></header><aside class=\"site-nav\">{{ navigation_html }}</aside><div class=\"section-context\" data-section-title=\"{{ current_section_title }}\" data-section-url=\"{{ current_section_url }}\">{{ page_header_html }}</div><main data-source=\"{{ source_path }}\">{{ body_html }}</main>{{ backlinks_html }}</body></html>"
}

///|
pub fn apply_template(
  rendered : RenderedDocument,
  context : TemplateContext,
  template_source : String,
) -> TemplatedPage {
  {
    route: context.url_path,
    source_path: rendered.source_path,
    source_uuid: rendered.source_uuid,
    html: render_template_string(template_source, context),
    note: "native templater renders the provided template source with a minimal context",
  }
}

///|
pub fn apply_built_in_template(
  rendered : RenderedDocument,
  context : TemplateContext,
) -> TemplatedPage {
  apply_template(rendered, context, default_page_template())
}

///|
/// Native templater that derives a default context from the rendered document.
pub fn apply_default_template(rendered : RenderedDocument) -> TemplatedPage {
  let context = default_template_context(rendered)
  apply_built_in_template(rendered, context)
}

///|
pub fn article_site_entry(page : TemplatedPage) -> SiteEntry {
  {
    kind: "article",
    route: page.route,
    source_path: page.source_path,
    source_uuid: page.source_uuid,
    html: page.html,
  }
}

///|
pub fn page_site_entry(page : TemplatedPage) -> SiteEntry {
  {
    kind: "page",
    route: page.route,
    source_path: page.source_path,
    source_uuid: page.source_uuid,
    html: page.html,
  }
}

///|
pub fn construct_site(entries : Array[SiteEntry]) -> SiteAssembly {
  {
    entries,
    note: "dummy site constructor now collects article and page outputs into one shared assembly",
  }
}

///|
/// Run the article pipeline explicitly through parser, WikiLinker, and render stages.
pub fn run_article_pipeline(
  parser : ParserAdapter,
  linker : WikiLinker,
  renderer : RenderAdapter,
  input : SourceDocumentInput,
) -> Result[ArticlePipelineResult, FatalParseError] {
  let parsed = match parse_with_adapter_result(parser, input) {
    Ok(parsed) => parsed
    Err(err) => return Err(err)
  }
  let linked = apply_wikilinker(linker, parsed)
  let rendered = render_with_adapter(renderer, linked)
  Ok({
    parsed,
    linked,
    rendered,
    pipeline_note: "article pipeline now keeps parser, wikilinker, and render order explicit",
  })
}

///|
/// DocFlow build closure that routes discovered files through the article pipeline.
pub fn run_docflow_build_pipeline(
  files : Array[String],
  parser : ParserAdapter,
  linker : WikiLinker,
  renderer : RenderAdapter,
) -> SiteAssembly {
  let entries = []
  for file in files {
    let input : SourceDocumentInput = {
      path: file,
      format: @core.SourceFormat::Markdown,
      content: "[docflow placeholder content for \{file}]",
      uuid: file,
    }
    match run_article_pipeline(parser, linker, renderer, input) {
      Ok(result) => {
        let templated = apply_default_template(result.rendered)
        entries.push(article_site_entry(templated))
      }
      Err(_) => {
        let failed_rendered : RenderedDocument = {
          backend_name: "docflow-build-failed",
          source_path: file,
          source_uuid: file,
          html: "<!-- docflow build failed for \{file} -->",
          note: "docflow build placeholder for failed article pipeline",
        }
        let templated = apply_default_template(failed_rendered)
        entries.push(article_site_entry(templated))
      }
    }
  }
  construct_site(entries)
}
