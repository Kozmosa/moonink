# Serve Parity Implementation 0419

## Goal

Complete the `serve-parity` slice so the main MoonInk CLI becomes the canonical
preview entry point: build once, distinguish build-stage vs serve-stage failure,
and delegate real HTTP serving to the native-only preview backend.

## Scope

Implemented in this slice:

- main-binary `moonink serve` now performs the real build step before preview;
- warning-only builds still continue into preview startup;
- fatal build failures still stop before preview startup;
- the main binary now delegates successful preview startup to `native-serve/`
  through an internal `serve-prebuilt` handoff instead of stopping at dry-run
  validation;
- `native-serve` now supports both direct `serve` and internal
  `serve-prebuilt --root ... --host ... --port ...` entry modes;
- CLI coverage now asserts the main-workspace delegated launch plan for build
  success, warning-tolerant startup, and parameter passthrough;
- `check` report rendering now includes the existing `site` warning group, which
  fixes the pre-existing missing-homepage diagnostic output.

Not implemented in this slice:

- watch mode or live reload;
- preview-time incremental rebuilds;
- replacing the native preview backend with an in-process main-workspace server;
- packaging the delegated preview backend for use outside the MoonInk workspace.

## Files Changed

- `src/runtime/moon.pkg`
- `src/runtime/serve.mbt`
- `src/runtime/serve_delegate.c`
- `src/runtime/serve_delegate_bytes.mbt`
- `src/runtime/serve_delegate_native.mbt`
- `src/runtime/serve_delegate_stub.mbt`
- `src/cli/cmd_serve.mbt`
- `src/cli/cmd_build.mbt`
- `src/cli/cli_test.mbt`
- `src/cmd/main/main.mbt`
- `native-serve/src/cmd/main/main.mbt`
- `native-serve/src/cmd/main/moon.pkg.json`
- `README.mbt.md`
- `docs/technical/10-CLI-and-Dev-Server.md`
- `docs/agent-working/MoonInkCliArch.md`
- `docs/agent-working/ServeParityImpl0419.md`
- `docs/agent-working/worklog/20260419.md`

## Design Decisions

### Keep real preview serving in `native-serve/`

The main workspace still avoids a direct `oboard/mocket` dependency. The user-facing
binary now delegates to the native-only subproject after a successful build rather
than duplicating the server implementation or turning `serve` back into a dry-run.

### Delegate with a prebuilt-preview entry instead of rebuilding twice

`native-serve` gained an internal `serve-prebuilt` path that accepts the resolved
preview root plus host/port. This keeps the main CLI responsible for build-stage
semantics while letting the native backend own actual preview startup and the
long-running HTTP lifecycle.

### Special-case `serve` in `src/cmd/main/main.mbt`

`cli_exec()` remains a useful runtime helper for tests and non-serve commands, but
the main binary now intercepts `serve` so it can perform build-once-then-delegate
behavior without forcing the generic CLI helper path to become a long-running server
entry.

### Keep dry-run preview helpers for tests

The existing preview-runner boundary remains in place for wasm-gc and unit-style
coverage. Tests assert the delegated launch plan instead of starting a real server.

## Current Limitations

- The delegated preview backend still assumes it is being launched from inside a
  MoonInk workspace where `native-serve/moon.mod.json` is available.
- The delegated handoff uses a small native shell-exec bridge, so platform-specific
  process-launch behavior is still minimal and native-target oriented.
- Preview remains one-shot: there is still no file watching, live reload, or
  restart-on-change workflow.

## Validation

Validation completed for this slice:

- `moon check`
- `moon test src/cli`
- `moon check --target native`
- `moon check --manifest-path native-serve/moon.mod.json --target native`
- `timeout 5s moon run src/cmd/main --target native -- serve --config fixtures/v2/minimal/moonink.json`
- `moon test`
- `moon info`
- `moon fmt`
