# 04 Build Pipeline

## 1. Pipeline Stages

MoonInk V1 build flow is intentionally explicit.

1. load configuration
2. validate configuration
3. discover files
4. classify content into article/page inputs
5. parse frontmatter for article-oriented sources
6. branch into document-flow adapters
   - article -> `ParserAdapter` -> `WikiLinker` -> `RenderAdapter`
   - page -> `HtmlPassthroughParserAdapter`
7. pass rendered or passthrough HTML into `Templater`
8. pass templated outputs into `SiteConstructor`
9. normalize routes and identifiers
10. build navigation and site model
11. emit HTML, static assets, and search index

## 2. Why Staged Processing Matters

This staging gives three benefits:

- easier debugging;
- narrower test responsibilities;
- future extensibility through hook points.

The article/page split is especially important because MoonInk should support both markup-origin documents and HTML-origin pages without collapsing them into hidden special cases.

## 3. Intermediate Outputs

Each stage should produce an explicit internal data structure rather than mutating shared global state.

A minimal progression is:

- discovered source entry
- classified source document input
- frontmatter-separated source input
- parsed document with diagnostics
- post-WikiLink document
- rendered HTML fragment
- templated page output
- site-construction input

## 4. Parser And Render Boundaries

The build pipeline should not assume that parsing and HTML rendering are the same concern, even if an initial dependency provides both.

This separation makes later evolution easier:

- `mizchi/markdown` can serve as the first Markdown backend;
- a future Typst parser can occupy the parser side without requiring the same native document model;
- HTML passthrough remains explicit for page-oriented input.

## 5. Failure Strategy

The build should stop on structural failures such as invalid config, missing required backends, or unrecoverable route conflicts.

Content diagnostics such as parser warnings, unsupported syntax notes, or future WikiLink issues should be preserved and reported clearly. The parser layer should prefer best-effort behavior where meaningful output can still be produced.
