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

The runtime / IO boundary layer is now concretely represented by:

- `runtime_io.mbt` for the sync filesystem facade;
- `runtime_async.mbt` for async-capable task descriptors and task constructors;
- `runtime_native.mbt` for native runtime adaptation and policy-aware execution hooks;
- `runtime_policy.mbt` for conflict handling and cancellation policy types.

This layer is the single place where MoonInk should wrap `moonbitlang/x/fs`, surface runtime task execution, and hold future native scheduler/cancellation hooks.

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
- `io_runtime`: runtime command dispatch entry that hands side-effecting work to native runtime adapters
- `runtime_io`: project-owned sync filesystem facade over `moonbitlang/x/fs`
- `runtime_async`: async-capable task descriptors and task constructors for IO-backed flows
- `runtime_native`: native runtime adapter and policy-aware task execution hooks
- `runtime_policy`: runtime conflict and cancellation policy types
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

MoonInk should avoid turning every layer into async by default. The current runtime model is:

- feature modules expose result-oriented APIs plus pure planning/parsing helpers where practical;
- `runtime_async.mbt` provides async-capable `RuntimeIOTask[T]` wrappers around IO-backed workflows;
- `runtime_native.mbt` is the default runtime execution adapter for CLI-side side effects;
- `runtime_policy.mbt` defines the current conflict and cancellation policy contract;
- parsing, semantic normalization, and modeling remain synchronous where practical;
- native-specific runtime behavior stays below the facade boundary instead of leaking into feature modules.

## 9. Why This Architecture

This architecture is suitable because it keeps the implementation understandable, supports future plugin hooks, and aligns well with proposal writing where the project must explain its module structure and technical route clearly.

It also creates a stable path for future extensions such as:

- a real Typst parser backend;
- non-dummy WikiLink resolution;
- richer template systems;
- alternative rendering backends without forcing a redesign of the content pipeline.
