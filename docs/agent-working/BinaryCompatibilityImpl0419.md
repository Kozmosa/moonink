# Binary Compatibility Implementation 0419

## Goal And Scope

Implement the single-binary runtime-compatibility slice on `feat/binary-compatibility` so a native Linux `moonink` binary can run `onboard`, `build`, `check`, and `serve` without depending on repository paths at runtime.

This slice owns:

- host-path config resolution from cwd-relative or absolute `--config`;
- absolute project-root derivation from the resolved config path;
- embedded built-in theme/runtime resource fallback;
- main-binary in-process native preview startup;
- removal of runtime dependency on `native-serve/` and shell delegation glue.

This slice does not add file watching or hot reload as a supported contract.

## Files Changed

- `src/core/config.mbt`
- `src/runtime/host_paths.mbt`
- `src/runtime/config_loader.mbt`
- `src/runtime/theme_loader.mbt`
- `src/runtime/builtin_theme_embedded.mbt`
- `src/runtime/preview_startup.mbt`
- `src/runtime/preview_startup_native.mbt`
- `src/runtime/preview_startup_stub.mbt`
- `src/runtime/preview_startup.c`
- `src/runtime/serve.mbt`
- `src/runtime/io.mbt`
- `src/runtime/content_discovery.mbt`
- `src/runtime/moon.pkg`
- `src/runtime/runtime_test.mbt`
- `src/cli/cmd_build.mbt`
- `src/cli/cmd_serve.mbt`
- `src/cli/serve_watch.mbt`
- `src/cli/cli_test.mbt`
- `src/cmd/main/main.mbt`
- `src/cmd/main/native_serve.mbt`
- `src/cmd/main/native_serve_wbtest.mbt`
- `src/cmd/main/moon.pkg`
- `README.mbt.md`
- `docs/technical/08-Theme-System.md`
- `docs/technical/10-CLI-and-Dev-Server.md`
- `docs/agent-working/MoonInkCliArch.md`

Removed runtime-only delegation glue:

- `src/runtime/serve_delegate.c`
- `src/runtime/serve_delegate_bytes.mbt`
- `src/runtime/serve_delegate_native.mbt`
- `src/runtime/serve_delegate_stub.mbt`
- `src/runtime/serve_process.mbt`
- `src/runtime/serve_process_native.mbt`
- `src/runtime/serve_process_stub.mbt`

## Design Decisions

### Host paths vs policy paths

`--config` is now resolved in a dedicated runtime host-path layer. The runtime normalizes cwd-relative or absolute host input to `config_abs_path`, then derives `project_root_abs = dirname(config_abs_path)`.

Project config fields remain policy paths:

- `content_dir`
- `output_dir`
- `theme`
- `template_file`
- CLI `--output`

That keeps the existing project-relative safety boundary while allowing detached execution from anywhere on the machine.

### Embedded built-in resources

The built-in theme fallback is now served from typed embedded sources in `src/runtime/builtin_theme_embedded.mbt` instead of repository probing.

Build/check/theme resolution now prefers:

1. project Theme V2 bundle;
2. project legacy `theme/layout.html`;
3. configured `template_file`;
4. embedded built-in fallback.

Theme assets and the built-in search client are written from embedded maps when the selected theme has no project asset directory.

### Main-binary native serve

The real native preview server moved into `src/cmd/main/native_serve.mbt`.

The main entry now owns:

- public `serve`;
- hidden internal `serve-prebuilt --root ... --host ... --port ...`;
- real `oboard/mocket` static-file startup.

Runtime preview launch now performs a native startup preflight through `src/runtime/preview_startup*.mbt` + `src/runtime/preview_startup.c` so invalid/native-unavailable startup conditions surface as serve-stage failures before the blocking server starts.

`src/cmd/main/main.mbt` now also propagates `CliOutcome.exit_code` to the host
process so detached smoke validation can reliably distinguish fatal
build/config/serve-stage failures from successful or warning-only runs.

### Repository independence

The runtime no longer:

- searches upward for `src/runtime/builtin_theme`;
- shells out through `/bin/sh`;
- constructs `moon run --manifest-path native-serve/moon.mod.json ...`;
- requires `native-serve/` to exist for normal command execution.

`native-serve/` stays in the repository as a migration shim only.

## Current Limitations

- File watching / hot reload is intentionally out of scope for this slice.
- The protected preview pipeline still emits `dist/__moonink/live-reload.js` and `preview-status.json` even though runtime no longer advertises watch mode.
- Native startup preflight currently accepts `localhost`, `0.0.0.0`, and IPv4 literal hosts; broader host binding semantics can be expanded later if needed.
- `moon` still emits non-blocking warnings for the legacy `supported-targets` package syntax and for direct multiline-string return expressions inside `src/runtime/builtin_theme_embedded.mbt`.

## Next Steps

- Decide whether watch-mode preview should return as a separately scoped follow-up.
- Consider generating the embedded built-in theme module automatically instead of maintaining a checked-in source file by hand.
- Decide whether the hidden `serve-prebuilt` main-binary path should remain internal-only or later be promoted into a supported smoke-validation tool.

## Validation

Commands run after implementation:

- `moon test src/runtime`
- `moon test src/cli`
- `moon test src/cmd/main --target native`
- `moon build src/cmd/main --target native`
- `./_build/native/debug/build/cmd/main/main.exe build --config fixtures/v2/missing_config/moonink.json`
- `./_build/native/debug/build/cmd/main/main.exe serve --config fixtures/v2/missing_config/moonink.json`
- `./_build/native/debug/build/cmd/main/main.exe build --config <temp-fixture>/moonink.json`
- `moon test`
- `moon check`
- `moon info`
- `moon fmt`

Observed results:

- all MoonBit tests passed;
- native binary exit-code smoke checks returned `1` for fatal `build` / `serve` startup failures and `0` for a successful build against a detached copied fixture;
- `src/core/pkg.generated.mbti` now intentionally exports `parse_config_json_with_project_root(...)`;
- `src/runtime/pkg.generated.mbti` now removes delegated-serve/shell-process APIs and exports host-path helpers, embedded built-in theme accessors, embedded asset fields, and native preview-startup validation.
