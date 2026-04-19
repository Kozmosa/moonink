# 10 CLI And Dev Server

## 1. CLI Surface

- `moonink help`
- `moonink onboard`
- `moonink build`
- `moonink check`
- `moonink serve`

## 2. Command Responsibilities

### `onboard`

First-time setup inside an existing Markdown folder or Obsidian vault:

1. Checks if `moonink.json` already exists.
2. If not: emits a default `moonink.json` with `content_dir: "."`, `output_dir: "dist"`, and vault-friendly excludes for `.obsidian`, `.trash`, `templates`, and related helper directories.
3. Does not rewrite note files or inject frontmatter.
4. Reports whether config generation succeeded or was aborted to avoid overwriting an existing config.

Replaces the earlier `new` command. The key difference: `onboard` works non-destructively inside an existing content folder rather than creating a fresh project skeleton.

### `build`

Runs the static generation pipeline:

1. Load `moonink.json` configuration.
2. Recursively discover content files (respecting `exclude` patterns).
3. Parse frontmatter; classify articles and pages.
4. Process through DocFlow: `ParserAdapter → WikiLinker → RenderAdapter`.
5. Apply templater and site constructor.
6. Emit HTML to `output_dir` (default `dist/`).

Current implementation includes the real parser/render/template/site-assembly flow, route-aware pretty/direct output layout, build-time wikilink rewriting based on discovered page routes, project-root `public/` asset copying, and a Theme MVP that resolves layouts in this order: `theme/layout.html`, then `template_file`, then the built-in default theme; selected theme assets are copied into `dist/assets/` when present.

Obsidian-direct output support extends the same build path:

- content discovery keeps non-content vault files as passthrough assets;
- build-input loading infers homepage metadata from root `index.*` or fallback `README.md`;
- page titles can be resolved from the first Markdown H1 when frontmatter is absent;
- build-time wikilinking resolves both note targets and vault resource targets;
- discovered content-tree assets are copied into `dist/` and preflight-checked against generated/reserved output paths.

### `check`

Validation-only pass over the same config/discovery/build-input pipeline used by `build`.

Current implementation:

1. Loads config and discovers content without writing output.
2. Reuses homepage inference, title resolution, and route collision checks.
3. Resolves note and resource wikilinks and reports unresolved or ambiguous targets as diagnostics.
4. Adds a non-blocking site warning when no homepage note can be inferred.
5. Returns exit code `0` for warnings-only runs and `1` for blocking errors.

### `serve`

Run a local preview flow for the generated site.

Main workspace behavior:

1. Load `moonink.json`.
2. Build preview output through a hidden staging directory under `.moonink-preview/`.
3. Publish staging output into the real preview root only after a successful rebuild.
4. Emit preview-only runtime assets under `dist/__moonink/`:
   - `live-reload.js`
   - `preview-status.json`
5. Start the native-only preview backend against the published preview root.
6. Poll watched config/content/theme/template paths and rebuild on change.
7. If a rebuild finishes with warnings, keep serving the new output and surface the warning both in terminal output and `preview-status.json`.
8. If a rebuild fails fatally, keep serving the last successful output and update `preview-status.json` with error state instead of tearing down preview.

The preview runner is still isolated behind [src/runtime/serve.mbt](src/runtime/serve.mbt). The standard wasm-gc test suite exercises the build-orchestration and dry-run validation helpers, while the standalone native server remains responsible for the actual HTTP listener.

Real preview serving is intentionally native-only. The main-workspace `serve`
path should be treated as a `--target native` feature; if a non-native target
hits the runtime stub and reports that native serve delegation is only available
on native targets, that is expected and matches the supported-platform scope.

Watch-mode preview uses polling rather than OS-specific file watching. The
browser refresh behavior is intentionally a full-page reload, not HMR.

### Native preview server

Real HTTP preview serving is implemented in the standalone [native-serve/](native-serve/) subproject.

Responsibilities of the native entry:

1. Parse CLI argv using the same normalization pattern as the main binary.
2. Support direct `serve` for standalone native use, including build + preview startup.
3. Support an internal `serve-prebuilt` handoff used by the main workspace CLI after a successful build.
4. Reuse `kozmosa/moonink/cli.start_prepared_serve_session_result(...)` to validate preview startup before handing off to the real server.
5. Print the runtime-ready message with a native-server note.
6. Start a real `oboard/mocket` static file server rooted at the generated preview directory.

Example launch from the repository root:

```bash
moon run --manifest-path native-serve/moon.mod.json native-serve/src/cmd/main --target native -- serve fixtures/v2/minimal/moonink.json
```

Design constraints:

- `oboard/mocket` must stay out of the main workspace `src/` dependency graph so `moon test` and wasm-gc build plans remain clean.
- The main workspace `moonink serve` is the canonical build-once-then-preview command.
- The native subproject is the only place that owns the real preview server dependency.
- The native entry accepts an explicit config path so it can be launched from the repo root or other working directories.
- Main-workspace `serve` delegates to `native-serve` through an internal prebuilt-preview handoff instead of rebuilding twice.
- Non-native targets are not expected to offer a real preview server; the native-only delegation boundary is part of the design.

## 3. CLI Output Style

CLI messages should be concise, calm, and diagnostic-friendly. Success, warning, and failure output must help authors locate content issues quickly.

## 4. Pure vs IO Separation

`cli_run()` in `src/cli/moonink.mbt` is the pure, side-effect-free path used by tests. `cli_exec()` drives real IO through the runtime stack (`src/runtime/`).

## 5. Evolution Path

Later commands may include `check`, `deploy`, `doctor`, or plugin-related tooling once the core surface is stable.
