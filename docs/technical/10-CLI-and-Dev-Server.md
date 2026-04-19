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

Runtime path handling for `build` now distinguishes:

- host-path CLI input: `--config` may be cwd-relative or absolute and is normalized to an absolute host path before loading;
- project-relative policy paths: `content_dir`, `output_dir`, `theme`, `template_file`, and CLI `--output` remain project-relative and are resolved from the derived absolute project root.

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
2. Resolve the config path to an absolute host path and derive the project root from that config file.
3. Build preview output through a hidden staging directory under `.moonink-preview/`.
4. Publish staging output into the real preview root only after a successful build.
5. Emit preview-only runtime assets under `dist/__moonink/`:
   - `live-reload.js`
   - `preview-status.json`
6. Validate the preview root plus native host/port startup requirements.
7. Start the in-process native preview backend from the main binary.

This slice intentionally does not include file watching or hot reload as a supported contract. The protected staging/publish flow and preview-status artifacts remain, but `serve` is now a one-shot build-then-preview command rather than a watch-mode dev server.

The preview runner remains isolated behind [src/runtime/serve.mbt](src/runtime/serve.mbt). The standard wasm-gc test suite exercises the build orchestration and dry-run validation helpers, while the native main package owns the real HTTP listener.

Real preview serving is intentionally native-only. The main-workspace `serve`
path should be treated as a `--target native` feature; JS/Wasm targets stop at
the dry-run/runtime-helper boundary rather than launching an HTTP server.

### Native preview server

Real HTTP preview serving is now owned by the main binary under
[src/cmd/main/native_serve.mbt](../../src/cmd/main/native_serve.mbt).

Responsibilities of the native entry:

1. Parse normal CLI argv using the same normalization pattern as the rest of the binary.
2. Support the public `serve` path by reusing CLI/runtime build-before-serve helpers.
3. Support a hidden internal `serve-prebuilt --root ... --host ... --port ...` path for native smoke validation and migration tooling.
4. Reuse `kozmosa/moonink/cli.start_prepared_serve_session_result(...)` to validate preview startup before handing off to the real server.
5. Print the runtime-ready message with a main-binary native-server note.
6. Start a real `oboard/mocket` static file server rooted at the generated preview directory.
7. Propagate `CliOutcome.exit_code` to the host process so shell and CI callers see fatal build/config/serve-stage failures.

Example launch from the repository root:

```bash
moon run src/cmd/main --target native -- serve fixtures/v2/minimal/moonink.json
```

Design constraints:

- detached execution must not require `/bin/sh`, `moon`, repository-local `native-serve/`, or repository-local built-in theme files;
- `oboard/mocket` now lives in the main module dependency set, but only the native-only `src/cmd/main` package imports it;
- the main workspace `moonink serve` is the canonical build-once-then-preview command;
- `native-serve/` remains in the repository as a migration shim rather than a required runtime component;
- non-native targets are not expected to offer a real preview server.

## 3. CLI Output Style

CLI messages should be concise, calm, and diagnostic-friendly. Success, warning, and failure output must help authors locate content issues quickly.

## 4. Pure vs IO Separation

`cli_run()` in `src/cli/moonink.mbt` is the pure, side-effect-free path used by tests. `cli_exec()` drives real IO through the runtime stack (`src/runtime/`).

## 5. Evolution Path

Later commands may include `check`, `deploy`, `doctor`, or plugin-related tooling once the core surface is stable.
