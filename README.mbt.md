Read this in Chinese: [README-zh.md](./README-zh.md)

<div align="center">
  <h1>MoonInk</h1>
  <p><strong>A static site generator for existing Markdown folders and Obsidian-style vaults.</strong></p>
  <p>
    <a href="https://github.com/Kozmosa/moonink/actions/workflows/publish-moonink-docs.yml"><img src="https://github.com/Kozmosa/moonink/actions/workflows/publish-moonink-docs.yml/badge.svg" alt="Docs publish status" /></a>
    <a href="./LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg" alt="License: Apache 2.0" /></a>
  </p>
  <p>
    <a href="https://kozmosa.github.io/moonink/"><strong>Documentation and Live Demo</strong></a>
    ·
    <a href="./README-zh.md"><strong>中文说明</strong></a>
  </p>
</div>

MoonInk turns an existing Markdown folder into a static site without forcing a CMS-style rewrite. It fits well with Obsidian-style vaults, wiki links, frontmatter, and a docs-first writing workflow.

## Quickstart

### Use MoonInk in an existing Markdown folder

Initialize a config in the current content directory:

```bash
moonink onboard
```

Create a minimal home page:

```md
---
title: Home
type: page
---

# Hello MoonInk

This site is built from an existing Markdown folder.
```

Check before building:

```bash
moonink check
```

Build the site:

```bash
moonink build
```

Start a local preview server:

```bash
moonink serve
```

`serve` is for native preview. If you are working from source, use the native-target command shown below.

### Run from source in this repository

```bash
moon run src/cmd/main -- onboard
moon run src/cmd/main -- check
moon run src/cmd/main -- build
moon run src/cmd/main --target native -- serve
```

Use `--config <path>` when you want to target a specific vault or fixture directory.

## Documentation and Demo

The full documentation lives at [kozmosa.github.io/moonink](https://kozmosa.github.io/moonink/). That site is also a live demo built with MoonInk itself, so it shows the product in the same form users will actually ship.

Start there for installation, first-site setup, configuration, linking, themes, and CLI reference details.

## Features

- Build a static site from an existing Markdown folder.
- Work well with Obsidian-style vault structure and wiki links.
- Classify content as pages or articles through frontmatter and file shape.
- Render through built-in templates or project themes.
- Copy public assets and content-local assets into the generated site.
- Generate static HTML output for direct hosting.
- Preview locally with the native `serve` workflow.

## Repository Guide

Project layout:

```text
src/core       Pure data types and shared logic
src/docflow    Parser and rendering pipeline
src/runtime    Filesystem, config loading, and site construction
src/cli        Command entry points
src/cmd/main   Binary entry point
docs/moonink   Public documentation source used for the live demo site
```

Common developer commands:

```bash
moon check
moon test
moon fmt
moon info
```

Use `moon test --update` when a snapshot-backed test is intentionally changed.

## Contributing

Issues and pull requests are welcome. If you are changing behavior, follow the existing package boundaries in `src/`, keep fixtures representative, and update the project worklog under `docs/agent-working/worklog/` for completed change sets.

## License

MoonInk is licensed under [Apache License 2.0](./LICENSE).
