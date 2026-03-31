# 00 Architecture

## 1. Purpose

This document defines the overall architecture of MoonInk V1, including major modules, data flow, and the relationship between content processing and site generation.

## 2. Architectural Principles

- content-first rather than theme-first;
- explicit stages rather than hidden coupling;
- strong defaults rather than early extensibility;
- MoonBit-friendly modularity rather than framework-style abstraction;
- keep the core model mostly synchronous while pushing external waiting to runtime boundaries.

## 3. System Layers

MoonInk V1 is divided into the following layers:

1. CLI layer
2. runtime / IO boundary layer
3. configuration layer
4. content ingestion layer
5. document flow layer
6. site model layer
7. rendering and output layer

The runtime / IO boundary layer is responsible for filesystem access and later external IO concerns. It should become the single place where the project wraps `moonbitlang/x/fs` and future native async runtime hooks.

The document flow layer is the most important near-term refinement. It turns the earlier generic parsing stage into an explicit sequence of processing boundaries.

## 4. High-Level Flow

```text
CLI Command
  -> Runtime / IO Boundary
  -> Config Load And Validation
  -> Content Discovery
  -> FrontMatter Parse
  -> ParserAdapter
  -> WikiLinker
  -> RenderAdapter
  -> Templater
  -> SiteConstructor
  -> HTML/Assets/Search Index Emit
```

For V1, `Templater` and `SiteConstructor` may begin as narrow internal boundaries rather than fully featured systems, but the flow should still be expressed explicitly.

## 5. Major Modules

- `cli`: command parsing and user-facing execution entry
- `runtime_io`: project-owned filesystem facade and future native runtime adapters
- `config`: site configuration schema and validation
- `content`: file scanning, classification, and source loading
- `frontmatter`: metadata extraction and body separation
- `parser_adapter`: format-facing parsing boundary for Markdown, future Typst, and HTML passthrough
- `wikilink`: semantic document linking stage, including future WikiLink and backlink logic
- `render_adapter`: conversion from parsed document form into render-ready HTML
- `templater`: theme shell and page framing
- `site_constructor`: assembly of processed pages into final site-oriented structures
- `routing`: route generation and canonical URL decisions
- `nav`: navigation model generation
- `model`: global site model and page model
- `search`: static search index generation
- `serve`: local development server

## 6. Data Model Progression

The build should move through increasingly refined representations:

- raw file or directory entry provided by the runtime IO layer
- classified source input
- frontmatter-separated source document input
- parsed document with diagnostics and backend-native payload
- semantically processed document
- rendered page fragment
- site page model or output artifact

This progression allows each stage to be tested independently.

## 7. Article And Page Branching

MoonInk should distinguish at least two content paths:

- `article`: markup-origin content such as Markdown and future Typst;
- `page`: HTML-origin content that can use an HTML passthrough adapter.

The intent is not to create two unrelated systems, but two explicit branches that still converge before final site assembly.

## 8. Runtime And Async Guardrail

MoonInk should avoid turning every layer into async by default. The intended direction is:

- IO boundaries may become async;
- parsing, semantic normalization, and modeling should remain synchronous where practical;
- native-specific runtime behavior should stay below the facade boundary instead of leaking into feature modules.

## 9. Why This Architecture

This architecture is suitable because it keeps the implementation understandable, supports future plugin hooks, and aligns well with proposal writing where the project must explain its module structure and technical route clearly.

It also creates a stable path for future extensions such as:

- a real Typst parser backend;
- non-dummy WikiLink resolution;
- richer template systems;
- alternative rendering backends without forcing a redesign of the content pipeline.
