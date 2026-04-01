# username/moonink

## MoonInk CLI Scaffold

This repository implements the MoonInk static site generator.

Implemented pieces:

- `moonink help`
- `moonink new [project-name]`
- `moonink build`
- `moonink serve`

Current status:

- command parsing is wired through the root package;
- `cmd/main` reads real runtime argv;
- `new` creates starter projects with normalized paths and UTF-8 files;
- `build` implements phase 1a input handling: configuration loading, content discovery, and DocFlow pipeline integration;
- DocFlow parser adapter chain is now complete:
  - `ParserAdapter` boundary with `mizchi/markdown` integration;
  - `RenderAdapter` boundary with Markdown-to-HTML rendering;
  - `WikiLinker` no-op semantic stage;
  - downstream `Templater` and `SiteConstructor` stages;
  - article/page branching and build pipeline closure;
- rendering is exercised through the DocFlow test surface;
- `serve` remains a placeholder module;
- frontmatter parsing, routing, and search are planned for Phase 2.
