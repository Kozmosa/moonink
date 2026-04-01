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
fn typst_stub_diagnostics() -> DocumentDiagnostics {
  {
    entries: [
      {
        severity: DiagnosticSeverity::Warn,
        line: Some(1),
        message: "Typst parsing is not implemented yet.",
        hint: Some(
          "Use the stub diagnostic until the real Typst backend lands.",
        ),
        backend_name: "unsupported-typst-parser",
      },
    ],
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
    "<article data-renderer=\"\{adapter.name}\" data-source-format=\"\{parsed.source_format}\">\{payload}</article>"
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
/// Dummy templater that wraps rendered HTML in a simple site shell.
pub fn apply_dummy_template(rendered : RenderedDocument) -> TemplatedPage {
  {
    route: route_from_source_path(rendered.source_path),
    source_path: rendered.source_path,
    source_uuid: rendered.source_uuid,
    html: "<!doctype html>\n<html><body><main data-source=\"\{rendered.source_path}\">\{rendered.html}</main></body></html>",
    note: "dummy templater keeps rendered content inside a simple site shell",
  }
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
