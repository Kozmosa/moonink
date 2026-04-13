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

Current implementation: phases 1–2 are real; phases 3–6 remain scaffold placeholders.

### `serve`

Run a local development preview flow for the generated site.

Current MVP behavior:

1. Load `moonink.json`.
2. Reuse the build pipeline to regenerate `output_dir`.
3. Validate the preview root and prepare a preview launch record with default `127.0.0.1:3000`.
4. Return a runtime status message that exposes the preview address and built output directory.

The preview runner is now isolated behind `src/runtime/serve.mbt`. Tests currently exercise the dry-run validation path so the standard wasm-gc test suite can verify serve orchestration without starting a native server. A native mocket runner slot is reserved for the native-only entrypoint.

## 3. CLI Output Style

CLI messages should be concise, calm, and diagnostic-friendly. Success, warning, and failure output must help authors locate content issues quickly.

## 4. Pure vs IO Separation

`cli_run()` in `src/cli/moonink.mbt` is the pure, side-effect-free path used by tests. `cli_exec()` drives real IO through the runtime stack (`src/runtime/`).

## 5. Evolution Path

Later commands may include `check`, `deploy`, `doctor`, or plugin-related tooling once the core surface is stable.
