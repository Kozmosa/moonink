# username/moonink

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
- `serve` in the main workspace now reuses the runtime build pipeline, validates the generated preview root, and reports the local preview address plus output directory through a dry-run preview boundary;
- real native preview serving now lives in the standalone `native-serve/` subproject, which depends on `oboard/mocket` without polluting the main workspace wasm-gc test/build graph;
- Theme MVP now prefers `theme/layout.html` over `template_file`, copies `theme/assets/` into `dist/assets/`, and exposes `theme_name`, `theme_asset_root`, and `page_body_class` to theme templates.

### Native preview entry

Use the native-only subproject when you want an actual local HTTP preview server:

```bash
moon run --manifest-path native-serve/moon.mod.json native-serve/src/cmd/main --target native -- serve <config-path>
```

Example from the repo root:

```bash
moon run --manifest-path native-serve/moon.mod.json native-serve/src/cmd/main --target native -- serve fixtures/v2/minimal/moonink.json
```

Notes:

- the main workspace `moonink serve` remains the dry-run orchestration contract used by tests;
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
