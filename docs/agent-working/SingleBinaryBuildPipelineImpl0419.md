# Single-Binary Build Pipeline Implementation 0419

## Goal

Land the first end-to-end single-binary release path for MoonInk on native
Linux so one `moonink` executable can run `onboard`, `build`, `check`, and
`serve` outside the source repository.

## Scope

Implemented in this slice:

- the main native binary now owns real preview serving through an internal
  `serve-prebuilt` entry instead of delegating to `moon run` against
  `native-serve/`;
- runtime serve delegation now self-spawns the current executable, preserving
  watch-mode preview while removing repository/runtime coupling;
- the built-in Theme V2 bundle is now embedded through a generated MoonBit
  source module, and built-in asset emission no longer reads
  `src/runtime/builtin_theme/` at runtime;
- checked-in release automation now regenerates embedded theme sources, builds a
  native release binary, stages it at `artifacts/release/moonink`, and runs
  detached smoke validation;
- detached validation now proves `onboard`, `build`, `check`, and `serve`
  against a temporary non-repository workspace.

Not implemented in this slice:

- Windows or macOS release packaging;
- installer/package-manager metadata;
- binary-size reduction work;
- removal of the historical `native-serve/` subproject from the repository.

## Files Changed

Primary implementation surfaces:

- `moon.mod.json`
- `src/cmd/main/moon.pkg`
- `src/cmd/main/main.mbt`
- `src/runtime/config_loader.mbt`
- `src/runtime/theme_loader.mbt`
- `src/runtime/serve.mbt`
- `src/runtime/runtime_test.mbt`
- `src/cli/cmd_build.mbt`
- `src/cli/serve_watch.mbt`
- `src/runtime/builtin_theme_embedded.mbt`
- `scripts/generate_builtin_theme_bundle.py`
- `scripts/validate_detached_release.sh`
- `scripts/build_single_binary_release.sh`

Documentation surfaces:

- `README.mbt.md`
- `docs/technical/08-Theme-System.md`
- `docs/technical/10-CLI-and-Dev-Server.md`
- `docs/agent-working/MoonInkCliArch.md`

## Design Decisions

### Keep watch-mode preview by self-spawning the same binary

The main `serve` path still needs a long-running parent watch loop plus a real
HTTP server child. Replacing the old `moon run --manifest-path native-serve/...`
handoff with `current moonink binary -- serve-prebuilt ...` preserves that
behavior while making the runtime contract detached and single-binary.

### Embed the built-in theme through generated MoonBit source

The repository files under `src/runtime/builtin_theme/` remain the authoring
inputs, but runtime fallback now consumes the generated
`src/runtime/builtin_theme_embedded.mbt` module. This keeps diffs reviewable and
lets build/check/serve read the default theme without probing repository paths.

### Keep built-in asset emission inside the normal build pipeline

Theme bundle asset copy now handles both project filesystem assets and embedded
built-in assets. The generated search client fallback also reads from the
embedded asset map, so build output remains consistent in detached execution.

### Make release validation part of the checked-in workflow

`scripts/build_single_binary_release.sh` does not stop at compilation. It stages
the release artifact and immediately calls
`scripts/validate_detached_release.sh`, which copies the binary into a
temporary workspace and smoke-tests the supported command set.

## Current Limitations

- `src/cmd/main/moon.pkg` still emits a package-level warning about legacy
  `supported_targets` syntax; functionality is correct, but the package metadata
  should be modernized when the exact non-legacy syntax is confirmed.
- `oboard/mocket/static_file` emits an upstream `supported_targets` warning that
  is outside this repository.
- `native-serve/` is no longer part of the runtime path, but it remains in the
  repository as a migration/reference artifact.

## Next Steps

1. Modernize the native-only package metadata to eliminate the local
   `supported_targets` warning.
2. Decide whether `native-serve/` should be deleted after the migration settles
   or retained as a narrow integration fixture.
3. Extend release automation if later product work adds embedded onboarding
   starter assets beyond `moonink.json`.

## Validation

Validation completed for this slice:

- `python3 scripts/generate_builtin_theme_bundle.py`
- `moon check`
- `moon test src/cli`
- `scripts/build_single_binary_release.sh`

Additional note:

- `moon test src/runtime` is currently affected by pre-existing untracked
  fixture output under `fixtures/v2/minimal/`, which changes content-discovery
  counts in unrelated runtime tests. Targeted runtime coverage for the new
  bundle/delegate behavior still compiles and the detached release smoke path
  passes.
