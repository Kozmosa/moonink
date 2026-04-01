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

The runtime / IO boundary layer is now concretely represented by the `src/runtime/` package:

- `runtime/io.mbt` for the sync filesystem facade;
- `runtime/async.mbt` for async-capable task descriptors and task constructors;
- `runtime/native.mbt` for native runtime adaptation and policy-aware execution hooks;
- `runtime/policy.mbt` for conflict handling and cancellation policy types.

This package is the single place where MoonInk wraps `moonbitlang/x/fs`, surfaces runtime task execution, and holds future native scheduler/cancellation hooks.

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

## 5. Major Packages And Modules

The codebase is organized into four packages under `src/`:

**`src/core/`** — pure types and logic, no external dependencies
- `config.mbt`: `MooninkConfig` schema, JSON parsing, `RouteStyle`
- `content.mbt`: `ContentFile`, `ContentInventory`, `ContentKind`, `SourceFormat`, classification helpers
- `frontmatter.mbt`: `Frontmatter` schema, YAML-like extraction and parsing
- `route.mbt`: route generation (`pretty` and `direct` styles)
- `page_meta.mbt`: `PageMeta` type combining source path, URL path, frontmatter, and kind
- `model.mbt`: `BuildContext`, `SiteModel`
- `io_error.mbt`: `ProjectIOError`
- `io_policy.mbt`: path normalization and parent-traversal policy

**`src/docflow/`** — document pipeline
- `parser.mbt`: `SourceDocumentInput`, `ParsedDocument`, diagnostics types
- `adapters.mbt`: `ParserAdapter`/`RenderAdapter` registry keyed by `SourceFormat`
- `markdown.mbt`: Markdown backend integrating `mizchi/markdown`
- `wikilinker.mbt`: `WikiLinker` (currently no-op stub)
- `pipeline.mbt`: article pipeline, build pipeline, templater, site assembly

**`src/runtime/`** — IO boundary
- `io.mbt`: sync filesystem facade over `moonbitlang/x/fs`
- `async.mbt`: `RuntimeIOTask[T]` wrapper
- `native.mbt`: `NativeRuntimeAdapter`
- `policy.mbt`: conflict and cancellation policy types
- `config_loader.mbt`: `load_config_result`, `load_config_task`
- `content_discovery.mbt`: recursive content file discovery with exclude patterns

**`src/cli/`** — CLI entry and command dispatch
- `moonink.mbt`: `CliCommand` enum, `parse_cli_command`, `cli_run`, `cli_exec`
- `cli_output.mbt`: help text
- `cmd_build.mbt`: build command implementation
- `cmd_onboard.mbt`: onboard command implementation
- `cmd_serve.mbt`: serve placeholder

**`src/cmd/main/`** — binary entry point (`is-main: true`)

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

MoonInk uses a dual-track content model. Classification is by file extension and frontmatter, not by directory structure:

- `.html` files → `Page` (HTML passthrough adapter)
- `.md` files with frontmatter `type: page` → `Page`
- other `.md` files → `Article` (Markdown parser adapter)

Both tracks converge at the Templater and SiteConstructor stages before final assembly. This enables MoonInk to operate inside existing Markdown folders (including Obsidian vaults) without requiring a specific directory layout.

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
