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
5. parsing and normalization layer
6. site model layer
7. rendering layer
8. output layer

The runtime / IO boundary layer is responsible for filesystem access and later external IO concerns. It should become the single place where the project wraps `moonbitlang/x/fs` and future native async runtime hooks.

## 4. High-Level Flow

```text
CLI Command
  -> Runtime / IO Boundary
  -> Config Load And Validation
  -> Content Discovery
  -> Frontmatter Parse
  -> Markdown Parse
  -> Route + Identity Normalize
  -> Link Resolve And Validate
  -> Navigation + Site Model Build
  -> Theme Render
  -> HTML/Assets/Search Index Emit
```

## 5. Major Modules

- `cli`: command parsing and user-facing execution entry
- `runtime_io`: project-owned filesystem facade and future native runtime adapters
- `config`: site configuration schema and validation
- `content`: file scanning, classification, and source loading
- `frontmatter`: metadata extraction
- `markdown`: Markdown-to-AST or intermediate representation parsing
- `links`: relative links and WikiLink resolution
- `routing`: route generation and canonical URL decisions
- `nav`: navigation model generation
- `model`: global site model and page model
- `theme`: official theme templates and rendering helpers
- `render`: conversion from model to output artifacts
- `search`: static search index generation
- `serve`: local development server

## 6. Data Model Progression

The build should move through increasingly refined representations:

- raw file or directory entry provided by the runtime IO layer
- parsed source document
- normalized page input
- site page model
- rendered page output

This progression allows each stage to be tested independently.

## 7. Runtime And Async Guardrail

MoonInk should avoid turning every layer into async by default. The intended direction is:

- IO boundaries may become async;
- parsing, normalization, and modeling should remain synchronous where practical;
- native-specific runtime behavior should stay below the facade boundary instead of leaking into feature modules.

## 8. Why This Architecture

This architecture is suitable because it keeps the implementation understandable, supports future plugin hooks, and aligns well with proposal writing where the project must explain its module structure and technical route clearly.
