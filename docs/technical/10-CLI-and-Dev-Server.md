# 10 CLI And Dev Server

## 1. CLI Surface

- `moonink help`
- `moonink onboard`
- `moonink build`
- `moonink serve`

## 2. Command Responsibilities

### `onboard`

First-time setup inside an existing Markdown folder or Obsidian vault:

1. Checks if `moonink.json` already exists.
2. If not: infers `site_name` from the current directory name, emits a default `moonink.json`.
3. Scans all `.md` files; injects minimal frontmatter (`title`, `type: article`) into files that have none.
4. Reports a summary of what was created and modified.

Replaces the earlier `new` command. The key difference: `onboard` works non-destructively inside an existing content folder rather than creating a fresh project skeleton.

### `build`

Runs the static generation pipeline:

1. Load `moonink.json` configuration.
2. Recursively discover content files (respecting `exclude` patterns).
3. Parse frontmatter; classify articles and pages.
4. Process through DocFlow: `ParserAdapter → WikiLinker → RenderAdapter`.
5. Apply templater and site constructor.
6. Emit HTML to `output_dir` (default `dist/`).

Current implementation includes the real parser/render/template/site-assembly flow, route-aware pretty/direct output layout, and build-time wikilink rewriting based on discovered page routes.

### `serve`

Run a local development preview flow for the generated site.

Main workspace behavior:

1. Load `moonink.json`.
2. Reuse the build pipeline to regenerate `output_dir`.
3. Validate the preview root and prepare a preview launch record with default `127.0.0.1:3000`.
4. Return a runtime status message that exposes the preview address and built output directory.

The preview runner is isolated behind [src/runtime/serve.mbt](src/runtime/serve.mbt). The standard wasm-gc test suite only exercises the dry-run validation path, so serve orchestration stays testable without starting a native server.

### Native preview server

Real HTTP preview serving is implemented in the standalone [native-serve/](native-serve/) subproject.

Responsibilities of the native entry:

1. Parse CLI argv using the same normalization pattern as the main binary.
2. Reuse `username/moonink/cli.prepare_serve_runtime_session(...)` to load config, discover content, rebuild the site, and validate the preview root.
3. Start a real `oboard/mocket` static file server rooted at the generated preview directory.
4. Print the shared runtime-ready message with a native-server note.

Example launch from the repository root:

```bash
moon run --manifest-path native-serve/moon.mod.json native-serve/src/cmd/main --target native -- serve fixtures/v2/minimal/moonink.json
```

Design constraints:

- `oboard/mocket` must stay out of the main workspace `src/` dependency graph so `moon test` and wasm-gc build plans remain clean.
- The main workspace `moonink serve` is the dry-run/orchestration contract.
- The native subproject is the only place that owns the real preview server dependency.
- The native entry accepts an explicit config path so it can be launched from the repo root or other working directories.

## 3. CLI Output Style

CLI messages should be concise, calm, and diagnostic-friendly. Success, warning, and failure output must help authors locate content issues quickly.

## 4. Pure vs IO Separation

`cli_run()` in `src/cli/moonink.mbt` is the pure, side-effect-free path used by tests. `cli_exec()` drives real IO through the runtime stack (`src/runtime/`).

## 5. Evolution Path

Later commands may include `check`, `deploy`, `doctor`, or plugin-related tooling once the core surface is stable.
