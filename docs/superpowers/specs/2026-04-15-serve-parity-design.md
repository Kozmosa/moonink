# MoonInk Serve Parity Design

_Date_: 2026-04-15

## Context

MoonInk already exposes a `serve` command from the main CLI, and the repository also contains native serving functionality for local preview. However, the current experience is still split: the main CLI and the native server do not yet present one fully unified preview flow with a single obvious user-facing entry point.

The next useful slice is not hot reload, incremental rebuilds, or a full development server overhaul. It is to make `moonink serve` the clear primary preview command by unifying argument handling, build-before-serve behavior, and startup/error semantics while delegating actual HTTP serving to the existing native implementation.

## Goal

Make `moonink serve` the user-facing primary preview entry point with a minimal complete flow:

1. parse the supported serve arguments from the main CLI;
2. run a standard build once;
3. proceed to preview serving if the build has no fatal errors;
4. delegate actual HTTP serving to the native serve implementation.

The first version should:

- make the main CLI the clear formal entry point for previewing a site;
- keep build and serve as distinct stages in user-facing behavior;
- allow warnings from build without blocking preview startup;
- block preview startup only on fatal build failure;
- align the supported argument surface across the main CLI and delegated native serve path for the approved minimal parameter set.

## Non-goals

This design intentionally does **not** include:

- file watching or automatic rebuilds;
- live reload or browser refresh support;
- incremental build logic;
- broader preview-root customization beyond the approved parameter set;
- replacing the native serve implementation with a fully in-process server;
- a large refactor that merges all native serve internals back into the main CLI/runtime.

## Recommended approach

Make the main CLI `serve` command the canonical preview entry point, and have it delegate to native serve only after a successful one-time build.

This is the chosen approach because it gives users one clear command while keeping the implementation scope small. It avoids a large server refactor, but still produces a coherent experience: `serve` means “build once, then preview.”

A thinner wrapper that leaves the dual-entry mental model mostly intact was considered, but rejected as the primary direction. The goal of this slice is not merely to expose native serve through another command; it is to make the main CLI the obvious user-facing home for local preview.

## Design

### 1. Make `moonink serve` the canonical preview command

The user-facing contract should be that `moonink serve` is the standard way to preview a site locally.

The native serve implementation remains an internal execution capability, but users should no longer need to think of it as a separate conceptual entry point. The main CLI is responsible for argument parsing, command semantics, and phase-specific messaging.

### 2. Define serve as “build once, then preview”

The first-version `serve` flow should be:

1. parse `--config`, `--output`, `--host`, and `--port`;
2. run a standard build using the same config/output semantics as `moonink build`;
3. inspect build results;
4. if build has fatal errors, stop;
5. otherwise delegate the final preview root and network parameters to native serve.

This keeps `serve` easy to reason about. It is not a pure static-file server over whatever already happens to exist in `dist/`; it is a preview command that ensures the site has been built first.

### 3. Distinguish build warnings from build-fatal errors

The first version should allow preview startup when build completes with warnings.

That means:

- warning-only build results do **not** block preview serving;
- fatal build errors do block preview serving;
- warnings should still be shown to the user before the server starts.

This preserves a practical preview workflow while keeping the command honest about truly broken builds.

### 4. Delegate serving to native serve after build success

Once build completes without fatal errors, the main CLI should hand off the actual preview-serving responsibility to the native serve implementation.

The delegated handoff should include, at minimum:

- resolved preview/output root;
- `host`;
- `port`.

The main CLI should remain responsible for the user-facing command semantics, but the native serve implementation should continue to own the actual HTTP server lifecycle.

### 5. Support only the approved minimal argument set in the first version

The first version should align the main CLI and delegated native serve path around:

- `--config`
- `--output`
- `--host`
- `--port`

These are the only parameters that should be normalized in this slice. Broader preview-specific tuning can come later once the primary flow is stable.

### 6. Make the two phases visible in CLI output

User-facing output should clearly distinguish:

- the build stage; and
- the serve-startup stage.

The exact wording can vary, but the command should make these states obvious:

- building the site;
- build completed, possibly with warnings;
- starting the preview server;
- preview server failed to start.

This avoids ambiguous failures where users cannot tell whether the problem came from content/build processing or network/server startup.

### 7. Keep build and serve failure semantics distinct

The command should expose these stage-specific outcomes:

#### Build-fatal failure
- preview server is not started;
- output should make clear that the failure occurred during build/preflight.

#### Build with warnings
- preview server still starts;
- warnings are shown before startup continues.

#### Serve-startup failure
- build has already succeeded;
- output should make clear that the failure occurred while starting the preview server, for example because `host`/`port` binding failed.

This phase distinction is part of the product contract for the command, not only an implementation detail.

## Files to modify

Primary files:
- `src/cli/cmd_serve.mbt`
- `src/cli/moonink.mbt`
- `src/cli/cli_test.mbt`

Likely supporting reads or targeted edits:
- `src/runtime/serve.mbt`
- native serve entry files under `native-serve/`
- `docs/technical/10-CLI-and-Dev-Server.md`

## Testing strategy

### Parameter passthrough coverage

Add tests ensuring the approved minimal parameters:
- `--config`
- `--output`
- `--host`
- `--port`

are parsed by the main CLI and correctly flow into the build + delegated serve path.

### Build-success path coverage

Add coverage showing that when build succeeds, `serve` proceeds into the preview-serving branch.

### Warning-tolerant startup coverage

Add a scenario where the build completes with warnings only. The test should confirm that:
- warnings are surfaced;
- preview startup still proceeds.

### Fatal-build blocking coverage

Add a scenario where build fails fatally. The test should confirm that:
- preview startup is not attempted;
- the reported failure is identified as a build-stage problem.

### Serve-startup failure coverage

Add a scenario where build succeeds but preview startup fails. The test should confirm that:
- the failure is reported as a serve/startup issue;
- it is not misreported as a build failure.

## Trade-offs

### Why not make `serve` only serve existing output?

Because the approved user-facing model is that `serve` is a preview command, not merely a static-file server. Running one build first makes the command more reliable and more intuitive for normal use.

### Why not add watch mode now?

Because watch and reload would immediately expand the complexity of lifecycle management, error recovery, and user expectations. The first goal is to make the one-shot preview path reliable and coherent.

### Why keep native serve instead of folding everything into the main CLI now?

Because the chosen slice is about product-level parity, not server reimplementation. Delegating to the existing native serve keeps scope controlled while still giving users a single formal entry point.

## Success criteria

This feature is complete when:

1. `moonink serve` acts as the clear main entry point for local preview.
2. The command runs a standard one-time build before serving.
3. Warning-only builds still allow preview startup.
4. Fatal build failures prevent preview startup.
5. Build-stage and serve-stage failures are distinguishable in command output.
6. The minimal parameter set `--config`, `--output`, `--host`, and `--port` works consistently through the main CLI and delegated serve path.

## Verification

Planned verification commands:

- `moon test src/cli`
- `moon check`
- `moon info && moon fmt`

Targeted behavior to verify:
- `serve` performs build-once-then-preview semantics;
- warnings do not block preview startup;
- fatal build failures do block preview startup;
- serve-startup failures are distinguished from build failures;
- the approved parameter set behaves consistently across the delegated path.
