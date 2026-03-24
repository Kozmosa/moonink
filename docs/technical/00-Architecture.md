# 00 Architecture

## 1. Purpose

This document defines the overall architecture of MoonInk V1, including major modules, data flow, and the relationship between content processing and site generation.

## 2. Architectural Principles

- content-first rather than theme-first;
- explicit stages rather than hidden coupling;
- strong defaults rather than early extensibility;
- MoonBit-friendly modularity rather than framework-style abstraction.

## 3. System Layers

MoonInk V1 is divided into the following layers:

1. CLI layer
2. configuration layer
3. content ingestion layer
4. parsing and normalization layer
5. site model layer
6. rendering layer
7. output layer

## 4. High-Level Flow

```text
CLI Command
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

- raw file
- parsed source document
- normalized page input
- site page model
- rendered page output

This progression allows each stage to be tested independently.

## 7. Why This Architecture

This architecture is suitable because it keeps the implementation understandable, supports future plugin hooks, and aligns well with proposal writing where the project must explain its module structure and technical route clearly.
