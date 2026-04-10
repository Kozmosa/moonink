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
fn lookup_template_variable(context : TemplateContext, name : String) -> String {
  match name {
    "site_name" => context.site_name
    "site_url" => context.site_url
    "page_title" => context.page_title
    "page_description" => context.page_description
    "url_path" => context.url_path
    "source_path" => context.source_path
    "content_kind" => context.content_kind
    "body_html" => context.body_html
    _ => ""
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
pub fn render_template_string(
  template : String,
  context : TemplateContext,
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
          output = output + lookup_template_variable(context, variable)
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
pub fn default_template_context(rendered : RenderedDocument) -> TemplateContext {
  {
    site_name: "MoonInk",
    site_url: "",
    page_title: rendered.source_path,
    page_description: "",
    url_path: route_from_source_path(rendered.source_path),
    source_path: rendered.source_path,
    content_kind: "article",
    body_html: rendered.html,
  }
}

///|
pub fn default_page_template() -> String {
  "<!doctype html>\n<html><head><meta charset=\"utf-8\"><title>{{ page_title }}</title></head><body data-kind=\"{{ content_kind }}\" data-url=\"{{ url_path }}\"><header><a href=\"{{ site_url }}\">{{ site_name }}</a></header><main data-source=\"{{ source_path }}\">{{ body_html }}</main></body></html>"
}

///|
pub fn apply_template(
  rendered : RenderedDocument,
  context : TemplateContext,
) -> TemplatedPage {
  {
    route: context.url_path,
    source_path: rendered.source_path,
    source_uuid: rendered.source_uuid,
    html: render_template_string(default_page_template(), context),
    note: "native templater renders the built-in page template with a minimal context",
  }
}

///|
/// Dummy templater that wraps rendered HTML in a simple site shell.
pub fn apply_dummy_template(rendered : RenderedDocument) -> TemplatedPage {
  let context = default_template_context(rendered)
  apply_template(rendered, context)
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
        let templated = apply_dummy_template(result.rendered)
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
        let templated = apply_dummy_template(failed_rendered)
        entries.push(article_site_entry(templated))
      }
    }
  }
  construct_site(entries)
}
