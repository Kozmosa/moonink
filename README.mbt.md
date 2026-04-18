# kozmosa/moonink

## MoonInk CLI Scaffold

This repository implements the MoonInk static site generator.

Implemented pieces:

- `moonink help`
- `moonink onboard`
- `moonink build`
- `moonink serve`

Current status:

- command parsing is wired through the root package;
- `cmd/main` reads real runtime argv;
- `onboard` creates starter config in-place and injects default frontmatter into markdown files that lack it;
- `build` loads config, discovers content, parses frontmatter, classifies `.html` plus `type: page` markdown as pages, rewrites wikilinks, renders through templates, and emits pretty/direct route-aware HTML output;
- site assembly now derives automatic page-only navigation, `nav_title`, and `nav_hidden` metadata for templates and default layout rendering;
- template rendering now resolves layouts in this order: project `theme/layout.html`, then configured `template_file`, then the repository-owned built-in default theme; theme builds also copy the selected theme assets into `dist/assets/` when available;
- `serve` in the main workspace now builds once and then delegates real local preview startup to the native-only `native-serve/` backend, keeping build-stage and serve-stage failures distinct;
- real native preview serving still lives in the standalone `native-serve/` subproject, which depends on `oboard/mocket` without polluting the main workspace wasm-gc test/build graph;
- Theme MVP now prefers `theme/layout.html` over `template_file`, copies `theme/assets/` into `dist/assets/`, and exposes `theme_name`, `theme_asset_root`, and `page_body_class` to theme templates.

### Native preview entry

The standard preview entry is now the main workspace CLI:

```bash
moon run src/cmd/main --target native -- serve <config-path>
```

The native-only subproject remains the delegated backend and still supports direct launch when needed:

```bash
moon run --manifest-path native-serve/moon.mod.json native-serve/src/cmd/main --target native -- serve <config-path>
```

Example from the repo root:

```bash
moon run --manifest-path native-serve/moon.mod.json native-serve/src/cmd/main --target native -- serve fixtures/v2/minimal/moonink.json
```

Notes:

- the main workspace `moonink serve` is now the canonical build-once-then-preview entry;
- tests still exercise dry-run helpers in `src/cli/cmd_serve.mbt` rather than starting a long-running server;
- the native entry accepts an explicit config path so it can be launched from the repo root or another working directory;
- `native-serve/` is the only place that pulls in `oboard/mocket`.

### Theme MVP

Theme support currently uses a simple directory convention:

- `theme/layout.html` — preferred over `template_file`
- `theme/assets/**` — copied to `dist/assets/**`

Theme templates can use these additional variables:

- `{{ theme_name }}`
- `{{ theme_asset_root }}`
- `{{ page_body_class }}`

The repository-owned built-in default theme now renders page/article-aware content shells and keeps using the existing automatic navigation and breadcrumb context.
