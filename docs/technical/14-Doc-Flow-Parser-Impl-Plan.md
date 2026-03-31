# 14 Doc Flow Parser Implementation Plan

## 1. Purpose

This document defines the implementation plan for MoonInk's next document-flow milestone: introducing a generic `ParserAdapter` layer, integrating `mizchi/markdown` as the first backend, and establishing the downstream adapter boundaries needed for future `Typst`, WikiLink processing, rendering, templating, and site construction.

The document is intentionally execution-oriented. It serves as both:

- an implementation plan for the next coding cycle;
- a roadmap addendum for the parsing and document-flow part of Phase 1.

## 2. Position In The V1 Architecture

This plan advances Phase 1 Milestone M2 from a simple "Markdown + frontmatter parsing" statement into a staged engineering track.

The immediate target is to move MoonInk from:

```text
Config -> File Discovery -> Placeholder Build
```

into:

```text
FrontMatterParser
  -> ParserAdapter
  -> WikiLinker
  -> RenderAdapter
  -> Templater
  -> SiteConstructor
```

For the first implementation cycle:

- `FrontMatterParser` is assumed to be a separate responsibility;
- `ParserAdapter` is introduced as the format-facing parsing boundary;
- `WikiLinker`, `Templater`, and `SiteConstructor` start with dummy implementations;
- `RenderAdapter` is introduced separately from parsing, even when the first backend comes from the same dependency.

## 3. Scope And Non-Goals

### 3.1 In Scope

- define a generic parser-facing input object;
- define `SourceFormat` and `ParsedDocument`;
- define structured diagnostics and diagnostic formatting;
- define parser capabilities and backend registry patterns;
- add a Markdown backend using `mizchi/markdown`;
- add a `Typst` stub backend to validate the abstraction boundary;
- add an HTML passthrough parser path for page-style HTML input;
- add a dummy WikiLink stage;
- add a separate render adapter boundary;
- connect article/page branching into the build pipeline;
- drive the work with atomic TDD-oriented commits.

### 3.2 Out Of Scope

- implementing a real Typst parser;
- implementing real WikiLink resolution or backlinks;
- implementing the final template engine;
- implementing the final site model builder;
- exposing multi-target backend guarantees beyond `native`;
- merging frontmatter parsing into the parser adapter.

## 4. Design Decisions Already Fixed

The implementation plan is based on these decisions:

- frontmatter parsing stays independent from parser backends;
- only `article` documents go through parser backends;
- `page` documents are HTML-origin content and should take an HTML passthrough path;
- only Markdown and Typst are future text-format targets for now, while inline HTML inside Markdown remains acceptable content;
- the architecture should not force a unified AST for Markdown and Typst;
- the system should preserve backend-native payloads in a controlled way;
- diagnostics should be stored as structured data, then formatted into user-facing messages;
- parsing should be best-effort by default, while still allowing fatal errors for truly unrecoverable cases;
- capability negotiation should use explicit flags rather than trait explosion;
- the first end-to-end closure should be:
  - `FrontMatterParser -> ParserAdapter -> WikiLinker(dummy) -> RenderAdapter -> HTML`.

## 5. Core Abstractions

## 5.1 SourceDocumentInput

The parser-facing input object should contain:

- `path`
- `format`
- `content`
- `uuid`

This object is expected to be produced after frontmatter extraction, not before it.

## 5.2 SourceFormat

The first stable format set should be:

- `Markdown`
- `Typst`
- `Html`
- `Unknown`

## 5.3 ParsedDocument

`ParsedDocument` is intentionally thin. It should not pretend to be a universal syntax tree.

Its first stable responsibilities are:

- identify the backend that produced it;
- record the source format;
- carry diagnostics;
- preserve a backend-native payload;
- remain consumable by downstream stages without leaking third-party APIs into most call sites.

## 5.4 DocumentDiagnostics

Diagnostics should be represented as structured data, not as prebuilt strings.

Recommended fields:

- severity
- line
- message
- hint
- backend_name

A formatter should turn that structure into output such as:

```text
(WARN) Line 1, Undefined Typst symbol. Check output of typst.
```

## 5.5 ParserCapabilities

The adapter layer should expose a compact capability object. The initial flags can remain small, for example:

- incremental parsing support;
- HTML passthrough support.

This is enough to prevent over-design while still supporting future expansion.

## 6. Layered Flow

The document-processing path should be split as follows.

### 6.1 FrontMatterParser

Responsibilities:

- extract metadata block;
- extract body content;
- assign or preserve content UUID;
- return a cleaned `SourceDocumentInput`.

### 6.2 ParserAdapter

Responsibilities:

- accept format-specific article content;
- return `ParsedDocument` with diagnostics and backend payload;
- advertise backend capabilities;
- remain backend-replaceable.

### 6.3 WikiLinker

Responsibilities:

- operate after parse and before final render;
- perform semantic link rewriting later;
- remain a no-op dummy in the first cycle.

### 6.4 RenderAdapter

Responsibilities:

- transform `ParsedDocument` into render-ready HTML;
- remain separate from parsing even if the first backend library supports both parsing and rendering.

### 6.5 Templater

Responsibilities:

- wrap page HTML with the site theme shell;
- remain a dummy boundary in the first cycle.

### 6.6 SiteConstructor

Responsibilities:

- collect processed page outputs into the final site assembly stage;
- remain a dummy boundary in the first cycle.

## 7. Format And Content Branching

MoonInk should branch content at least into:

- `article`: markup-origin content such as Markdown and future Typst;
- `page`: HTML-origin content that should bypass normal markup parsing.

The intended near-term behavior is:

```text
article
  -> FrontMatterParser
  -> ParserAdapter
  -> WikiLinker
  -> RenderAdapter
  -> Templater
  -> SiteConstructor

page
  -> HtmlPassthroughParserAdapter
  -> Templater
  -> SiteConstructor
```

This keeps the build flow explicit while still allowing both paths to converge before output assembly.

## 8. Backend Strategy

## 8.1 First Markdown Backend

`mizchi/markdown` should be the first integrated backend because it provides the shortest path to a working closure:

- parse Markdown;
- preserve a backend document model;
- render HTML;
- keep the build moving toward a usable MVP.

## 8.2 Why Not Force A Universal AST

Markdown and Typst are likely to diverge structurally. A premature universal AST would increase interface complexity and make later replacement harder.

The recommended approach is therefore:

- preserve backend-native payloads;
- expose only normalized metadata, diagnostics, and pipeline behavior at the adapter layer;
- add richer cross-format queries only after real use cases require them.

## 8.3 Typst Strategy

A real Typst backend is deferred, but the abstraction should already validate its future place.

The first Typst backend should therefore be an explicit stub backend that:

- can be registered;
- reports its backend name and capabilities;
- returns diagnostics explaining that full Typst parsing is not implemented yet.

## 8.4 HTML Passthrough Strategy

HTML page input should not bypass the adapter architecture completely. Instead, a lightweight HTML passthrough parser should wrap page input into the same broad document-flow contract.

This keeps the branching explicit without introducing two unrelated processing systems.

## 9. Error And Diagnostic Policy

The plan adopts a two-level failure model.

### 9.1 Best-Effort Diagnostics

Normal parse problems should remain recoverable and visible through diagnostics.

Examples:

- malformed but partially readable content;
- unsupported syntax fragments that do not prevent output generation;
- future backend warnings.

### 9.2 Fatal Errors

Fatal parser errors should be reserved for states where the system cannot safely continue with a meaningful `ParsedDocument`.

Examples may include:

- unregistered parser backend for a required path;
- invalid adapter state;
- unrecoverable backend integration failure.

This should be represented as `Result[ParsedDocument, FatalParseError]` at the adapter boundary.

## 10. TDD Strategy

The implementation should follow a stable red-green-refactor loop.

For each atomic stage:

1. write a focused failing test;
2. implement the smallest change that makes it pass;
3. rerun the affected tests;
4. rerun the project checks;
5. optionally perform a small cleanup;
6. commit.

The preferred testing style is:

- black-box tests first;
- contract tests for adapters;
- snapshot-style checks where output shape matters;
- precise assertions where behavior flags and diagnostics matter.

## 11. Atomic Commit Plan

The following stages are the recommended implementation sequence.

### P1. Core Parser Domain Types

Create the parser-facing domain model:

- `SourceFormat`
- `SourceDocumentInput`
- `ParsedDocument`
- `DocumentDiagnostics`
- `ParserCapabilities`

TDD target:

- type construction;
- diagnostic formatting;
- basic capability defaults.

### P2. Adapter Contract Tests

Freeze expected behavior for:

- `ParserAdapter`
- `RenderAdapter`
- `WikiLinker`

TDD target:

- fake backends and no-op semantic stages.

### P3. Registry Layer

Introduce:

- `ParserRegistry`
- `RenderRegistry`

TDD target:

- backend lookup by `SourceFormat`;
- correct error behavior for missing registrations.

### P4. Typst Stub And HTML Passthrough

Add:

- `UnsupportedTypstParserAdapter`
- `HtmlPassthroughParserAdapter`

TDD target:

- multiple format paths exist even before the real Typst parser.

### P5. Fatal Error Boundary

Add a controlled split between:

- recoverable diagnostics;
- fatal parser errors.

TDD target:

- best-effort vs fatal behavior.

### P6. Markdown Backend Contract Tests

Write backend-facing tests for `mizchi/markdown` integration.

Coverage should include:

- empty input;
- paragraph;
- heading;
- list;
- link;
- inline HTML;
- diagnostics propagation;
- capability reporting.

### P7. Markdown Parser Backend Integration

Implement the first real parser adapter using `mizchi/markdown`.

TDD target:

- previously written Markdown backend tests turn green.

### P8. Markdown Render Backend Integration

Introduce the first render adapter using the same dependency, while keeping the interface separate.

TDD target:

- parsed Markdown content becomes HTML through the render boundary.

### P9. Dummy WikiLinker Pipeline Stage

Insert a no-op semantic stage into the article flow.

TDD target:

- stable processing order;
- no-op transform remains explicit.

### P10. Dummy Templater And SiteConstructor

Add the next two dummy stages so the broader document-flow architecture exists before the full feature logic lands.

TDD target:

- article/page outputs enter a common downstream structure.

### P11. Build Pipeline Integration

Wire the new article/page branching and adapter flow into the current build path.

TDD target:

- fixtures can pass through the new content-processing closure.

### P12. Stabilization Refactor

Perform a dedicated cleanup pass once the whole chain exists.

Goals:

- reduce naming drift;
- tighten payload boundaries;
- improve package layout;
- keep the public adapter surface stable.

## 12. Commit Message Policy

Each implementation stage should use:

- a concise conventional-commit-style English subject line;
- short Chinese bullet notes describing the change details.

Example:

```text
feat(parser): add core parser adapter domain types

- 新增 SourceFormat、SourceDocumentInput、ParsedDocument 等基础类型
- 建立结构化 diagnostics 与统一格式化函数
- 为后续多后端 parser/render 分层奠定命名基础
```

## 13. Build Closure Goal

The first concrete success condition is not just "a parser exists" but:

- article content can travel from frontmatter output into parser, dummy WikiLink processing, and HTML rendering;
- page HTML content can travel through the passthrough path;
- both paths can enter the same downstream assembly boundary.

That is the minimum useful closure for the current cycle.

## 14. Correspondence To Phase 1 Roadmap

This plan refines Phase 1 Milestone M2 and prepares the handoff into M3 and M4.

- M2 gains an explicit parser implementation track;
- M3 benefits from a stable post-parse semantic boundary;
- M4 benefits from a stable render and templating boundary.

## 15. Completion Signals

This plan should be considered implemented successfully when:

- a stable `ParserAdapter` boundary exists;
- `mizchi/markdown` is integrated as the first parser and render backend;
- `Typst` has a registered stub backend;
- HTML page input has a passthrough adapter path;
- article/page branching is explicit in the build pipeline;
- the adapter chain is covered by tests;
- future Typst, WikiLink, and templating work can proceed without redesigning the document-flow boundaries.
