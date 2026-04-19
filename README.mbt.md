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
- `onboard` creates starter config in-place and does not rewrite note files;
- `build` loads config, discovers content, parses frontmatter, classifies `.html` plus `type: page` markdown as pages, rewrites wikilinks, renders through templates, and emits pretty/direct route-aware HTML output;
- runtime config loading now treats `--config` as a host path, resolves it from cwd-relative or absolute input, and derives an absolute project root from that config file;
- site assembly now derives automatic page-only navigation, `nav_title`, and `nav_hidden` metadata for templates and default layout rendering;
- template rendering now resolves layouts in this order: project `theme/layout.html`, then configured `template_file`, then the embedded built-in default theme; theme builds also copy the selected theme assets into `dist/assets/` when available;
- Theme V2 bundle fallback is now embedded into the main binary rather than loaded from repository paths at runtime;
- `serve` in the main workspace now builds once and then starts the real native preview server in-process from the main binary, keeping build-stage and serve-stage failures distinct;
- `native-serve/` remains in the repository only as a migration shim and is no longer a runtime dependency of the main binary;
- Theme MVP now prefers `theme/layout.html` over `template_file`, copies `theme/assets/` into `dist/assets/`, and exposes `theme_name`, `theme_asset_root`, and `page_body_class` to theme templates.

### Native preview entry

The standard preview entry is now the main workspace CLI:

```bash
moon run src/cmd/main --target native -- serve <config-path>
```

Notes:

- the main workspace `moonink serve` is the canonical build-once-then-preview entry;
- the main binary now embeds the built-in default theme plus the native preview-serving capability;
- `serve` is intentionally scoped to native preview use; JS/Wasm tests continue to exercise dry-run helpers in `src/cli/cmd_serve.mbt`;
- `native-serve/` remains in the repository for migration/debugging, but detached runtime execution no longer depends on it.
- detached single-binary release build and smoke validation are automated under `scripts/`, including `scripts/build_single_binary_release.sh` and `scripts/validate_detached_release.sh`.

### Theme MVP

Theme support currently uses a simple directory convention:

- `theme/layout.html` — preferred over `template_file`
- `theme/assets/**` — copied to `dist/assets/**`

Theme templates can use these additional variables:

- `{{ theme_name }}`
- `{{ theme_asset_root }}`
- `{{ page_body_class }}`

The embedded built-in default theme now renders page/article-aware content shells and keeps using the existing automatic navigation and breadcrumb context.
