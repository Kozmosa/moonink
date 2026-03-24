# MoonInk RFC

## 1. Abstract

MoonInk is a static site generator built with MoonBit for documentation, blogs, and knowledge sites, with the first release focused on personal knowledge publishing. This RFC defines the product direction, scope boundary, architecture baseline, and engineering decisions for the first implementable version of MoonInk.

MoonInk takes MkDocs as a reference model for predictable configuration, content-to-site generation, and clear build stages, but it does not aim to fully reproduce the MkDocs feature surface. Instead, the first version emphasizes a smaller, more teachable, more controllable architecture that is suitable both as a real tool and as a demonstration of MoonBit's engineering capability in developer tooling.

## 2. Background And Motivation

Existing static site generators already cover documentation and publishing well, but MoonBit still lacks a representative, end-to-end, tool-grade project that demonstrates how the language can support configuration parsing, content processing, rendering pipelines, and command-line workflows in a non-trivial system.

The project therefore serves two goals at once:

- provide a practical knowledge-oriented static site generator;
- demonstrate that MoonBit can support a real developer tool with clear architecture and maintainable implementation.

From the application perspective, the target problem is not "how to generate any website," but "how to turn structured personal knowledge content into a predictable, navigable, searchable static site with minimal conceptual overhead."

## 3. Goals

- Build a MoonBit-based static site generator for personal knowledge authors.
- Support a dual-track site model: documentation tree plus article stream.
- Keep the first version content-first, predictable, and small enough to implement cleanly.
- Reuse successful ideas from MkDocs, especially clear configuration and staged build flow.
- Produce design and engineering documents that can directly support a project proposal.

## 4. Non-Goals

- Full compatibility with `mkdocs.yml` or the entire MkDocs plugin ecosystem.
- A complete third-party plugin system in the first release.
- A theme marketplace or multi-theme package distribution mechanism in the first release.
- Full multilingual support in the first release.
- Incremental build and deployment automation in the first release.
- Knowledge graph visualization or sophisticated backlink UI in the first release.

## 5. Target Users And Primary Scenario

### 5.1 Target Users

The primary target users are personal knowledge authors who want to publish structured notes, long-form documentation, and article-like entries from Markdown content.

### 5.2 Primary Scenario

The first release is optimized for a knowledge-base-style site that combines:

- a hierarchical documentation or note tree;
- a chronological or tag-based article flow;
- internal links between knowledge units;
- local static search over all published content.

## 6. Product Positioning

MoonInk is positioned as a calm, structured, content-first generator. The product should align with the brand direction already defined in `docs/Brand_Design.md`: restrained, precise, quiet, sustainable.

In engineering terms, this means:

- simple configuration over flexible but hard-to-reason abstraction;
- explicit staged build pipeline over opaque magic;
- a strong default theme over an unfinished extension surface;
- quality through predictable behavior rather than feature volume.

## 7. Reference Strategy Relative To MkDocs

MoonInk uses MkDocs as a reference for:

- project-level configuration;
- navigation and content organization concepts;
- build command workflow;
- separation between content, theme, and output.

MoonInk intentionally diverges in the following ways:

- configuration uses TOML rather than YAML;
- first-release scope is narrower;
- the information model is more explicitly knowledge-base-oriented;
- the architecture is written to be pedagogical and implementation-oriented for MoonBit.

## 8. Scope Of Version 1

### 8.1 Included In Version 1

- TOML configuration file.
- Markdown content input.
- Frontmatter support with core fields: `title`, `author`, `id`, `tags`, `date`.
- Dual-track site structure: documentation tree plus article stream.
- Mixed navigation strategy: auto-generated defaults with manual override.
- Internal relative-link validation.
- WikiLink syntax support.
- Single official built-in theme.
- Static search index generation.
- CLI commands: `moonink new`, `moonink build`, `moonink serve`.
- Single-language site generation.
- Unit tests for core modules.

### 8.2 Explicitly Deferred

- third-party plugins;
- multiple official themes;
- formal deployment command;
- multi-language site generation;
- incremental build cache;
- complete backlink or graph view;
- content components or MDX-like embedded UI syntax.

## 9. Product Model

MoonInk V1 treats a site as the composition of five layers:

1. configuration;
2. content source tree;
3. parsed content and metadata;
4. site model;
5. rendered output artifacts.

This separation is important because it keeps the implementation explainable and testable, and it maps naturally to MoonBit modules.

## 10. Core Design Decisions

### 10.1 Configuration Format

MoonInk will use TOML for first-release configuration. TOML gives better structure than ad hoc frontmatter-like configuration files while remaining readable, and it avoids over-coupling the project to MkDocs-compatible YAML.

### 10.2 Content Format

The first release accepts Markdown only. This keeps parsing, rendering, and validation scope controlled. Future structured-data-driven pages may be added later.

### 10.3 Site Structure

MoonInk supports both a hierarchical knowledge tree and a stream of article entries. This dual-track model reflects real personal knowledge publishing: some content belongs in stable conceptual hierarchies, while some belongs in time-oriented writing flows.

### 10.4 Metadata Model

The first-release metadata model is intentionally small.

- required: `title`
- recommended: `id`, `date`
- optional: `author`, `tags`

The implementation may reserve additional future fields such as `summary`, `draft`, `order`, and `aliases`, but those are not required for the first release scope.

### 10.5 Linking

MoonInk V1 must support both:

- standard internal links with path validation;
- `[[WikiLink]]` syntax resolved through page identity rules.

This decision makes MoonInk meaningfully more knowledge-base-friendly while keeping the feature set modest.

### 10.6 Theme Strategy

V1 ships with one official theme. The theme system should be architected as replaceable, but not yet stabilized as a public ecosystem API.

### 10.7 Plugin Strategy

V1 does not expose a third-party plugin mechanism. However, the build pipeline and internal module boundaries should be designed so that lifecycle hooks can be introduced later without major restructuring.

### 10.8 Search

V1 generates a local static search index at build time and performs search client-side in the generated site.

### 10.9 Internationalization

V1 is single-language. Internationalization support should be documented as an evolution path rather than implemented prematurely.

## 11. Architecture Overview

The baseline build pipeline is:

1. load and validate configuration;
2. discover content files and assets;
3. parse frontmatter and Markdown;
4. normalize page identity and routes;
5. resolve links and WikiLinks;
6. construct navigation and site model;
7. render pages with the official theme;
8. emit assets, HTML, and search index.

This architecture is selected because it is:

- easy to explain in proposal materials;
- easy to map to MoonBit modules;
- easy to test phase-by-phase;
- suitable for future extension points.

## 12. Command-Line Experience

Version 1 will expose:

- `moonink new`: create a starter project;
- `moonink build`: build a static site into an output directory;
- `moonink serve`: start a local development server.

The CLI should present a stable, calm, informative experience aligned with the MoonInk brand tone.

## 13. Quality Baseline

The quality baseline for V1 is centered on unit testing. Priority test areas include:

- configuration parsing and validation;
- frontmatter parsing;
- route generation;
- navigation generation;
- internal link validation;
- WikiLink resolution;
- search index generation.

## 14. Risks

### 14.1 Ecosystem Risk

MoonBit's ecosystem for content tooling, parsing libraries, and templating is not as mature as ecosystems around Python or JavaScript. This may increase implementation effort for foundational modules.

Mitigation: keep V1 scope tight; prefer internal abstractions with minimal dependencies; design modules for gradual replacement.

### 14.2 Rendering Complexity Risk

A powerful theme or template system can grow complexity quickly.

Mitigation: ship a single official theme and stabilize only internal interfaces in V1.

### 14.3 Knowledge-Base Scope Creep

Knowledge-base products often expand into backlinks, graphs, references, embeddings, and many note-taking features.

Mitigation: keep V1 focused on dual-track organization, WikiLink support, and search; defer graph-heavy features.

### 14.4 Development Server Risk

Live preview and file watching can become disproportionately complex.

Mitigation: define `serve` as a practical local preview command first, with hot reload quality evolving over time.

## 15. Alternatives Considered

### 15.1 Full MkDocs Compatibility

Rejected for V1 because compatibility pressure would distort the architecture and overload the project before MoonBit-native design is established.

### 15.2 Blog-First Product

Rejected because the project goal is better aligned with structured knowledge publishing than with pure chronological writing.

### 15.3 Plugin-First Architecture

Rejected because extension pressure before the core model stabilizes would produce premature abstractions.

## 16. Expected Deliverables

- MoonInk RFC
- MoonInk roadmap
- technical architecture and engineering documentation set
- later, a project proposal document derived from those materials

## 17. Acceptance Criteria For The RFC Direction

The RFC direction is considered successful if the project can proceed to implementation with clear answers to all of the following:

- what V1 includes and excludes;
- who V1 serves first;
- what the architecture stages are;
- what the CLI surface is;
- what the content model is;
- what features are intentionally deferred.

## 18. Conclusion

MoonInk V1 should be a focused, content-first, knowledge-oriented static site generator built in MoonBit, borrowing the right lessons from MkDocs without inheriting its full complexity. The project succeeds if it becomes both a usable publishing tool and a credible demonstration of MoonBit's potential for real engineering systems.
