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
- template rendering now resolves layouts in this order: project `theme/layout.html`, then configured `template_file`, then the embedded built-in default theme generated from `src/runtime/builtin_theme/`; theme builds copy selected project theme assets into `dist/assets/`, and built-in assets are emitted from the embedded bundle;
- `serve` in the main workspace now builds once, keeps build-stage vs preview-stage failures distinct, and self-spawns the same native `moonink` binary through an internal `serve-prebuilt` mode for real preview serving;
- the main module now owns the native preview server dependency and the detached single-binary release path, with release automation checked in under `scripts/`;
- Theme MVP now prefers `theme/layout.html` over `template_file`, copies `theme/assets/` into `dist/assets/`, and exposes `theme_name`, `theme_asset_root`, and `page_body_class` to theme templates.

### Native preview entry

The standard preview entry is now the main workspace CLI:

```bash
moon run src/cmd/main --target native -- serve <config-path>
```

Detached single-binary release build and validation:

```bash
scripts/build_single_binary_release.sh
```

This stages one self-contained native binary at:

`artifacts/release/moonink`

Notes:

- the main workspace `moonink serve` is now the canonical build-once-then-preview entry;
- `serve` is intentionally scoped to native preview use, so a non-native `only available on native targets` message is expected rather than a sign that the serve path is half-implemented;
- tests still exercise dry-run helpers in `src/cli/cmd_serve.mbt` rather than starting a long-running server;
- the native entry accepts an explicit config path so it can be launched from the repo root or another working directory;
- `scripts/validate_detached_release.sh` copies the staged binary into a temporary non-repository workspace and smoke-tests `onboard`, `build`, `check`, and `serve`.

### Theme MVP

Theme support currently uses a simple directory convention:

- `theme/layout.html` — preferred over `template_file`
- `theme/assets/**` — copied to `dist/assets/**`

Theme templates can use these additional variables:

- `{{ theme_name }}`
- `{{ theme_asset_root }}`
- `{{ page_body_class }}`

The embedded built-in default theme now renders page/article-aware content shells and keeps using the existing automatic navigation and breadcrumb context.
