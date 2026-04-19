# MoonInk Single-Binary Build Pipeline Design

_Date_: 2026-04-19

## Context

The runtime compatibility design defines what the released CLI must do. This companion design defines how MoonInk should produce a native Linux release artifact that can satisfy that runtime contract.

The current repository still shows a split build shape:

- the main module builds the user-facing CLI;
- preview serving lives in a sibling `native-serve` package that depends on the main module and is launched through `moon run` at runtime;
- the built-in theme lives as repository files under `src/runtime/builtin_theme` rather than as a release-owned payload;
- runtime C glue currently exists only to shell out into another command rather than to support a self-contained runtime.

That structure was sufficient for repository-local development, but it does not produce a true one-binary release. A single-binary release must make the runtime contract mechanically true at build time, not merely by convention.

## Goal

Define the build and packaging changes required to produce one native Linux `moonink` executable that contains everything needed for:

- built-in theme fallback;
- native preview serving;
- detached execution of `onboard`, `build`, `check`, and `serve`.

The release artifact must not require sidecar asset directories, helper binaries, or a sibling MoonInk repository checkout.

## Confirmed Decisions

- The only target for this slice is `native Linux`.
- The released artifact is exactly one `moonink` executable.
- The executable may grow in size in order to embed runtime resources and native preview functionality.
- Built-in theme resources must be embedded into the main release artifact.
- Preview serving capability must be compiled into the main release artifact.
- Runtime access to repository paths is not an acceptable release dependency.

## Non-goals

This design intentionally does not include:

- macOS or Windows packaging;
- producing package-manager metadata or installers;
- reducing binary size through late optimization work;
- adding watch mode, live reload, or advanced dev-server features;
- creating a generalized plugin/resource pack format.

## Recommended Approach

Adopt a `main-binary owns all runtime dependencies` packaging model.

In that model:

1. the main MoonInk module compiles the preview-serving implementation directly;
2. built-in theme resources are transformed into an embedded source bundle consumed by the runtime;
3. release validation proves detached execution by running the emitted binary outside the repository.

Two alternatives were considered and rejected as the primary direction:

- `helper binary release`: ship `moonink` plus a second preview-helper executable. This still fails the one-binary product contract.
- `sidecar asset release`: ship `moonink` plus a theme asset directory. This reduces embedding work but keeps runtime behavior dependent on installation layout and weakens release verification.

## Design

### 1. Release artifact contract

The standard native Linux release output should be:

- one executable named `moonink`

No runtime sidecars are allowed for the built-in theme, preview server, or starter resources.

That means the release verification question becomes simple: if the single file is copied to another directory, all supported commands still work.

### 2. What must be embedded

The release pipeline must embed all runtime-owned resources that are not project files.

#### Built-in theme bundle

The embedded built-in theme payload should include:

- `theme.json` or equivalent manifest content;
- all default layout templates;
- all partial templates;
- default theme asset bytes.

The runtime should consume this through a typed bundle API rather than through path-based file loading.

#### Preview server capability

The preview server should be compiled into the main binary as normal native code, not invoked through `moon run` against a sibling package.

That means the release artifact already contains:

- the HTTP serving implementation;
- any native-target-only server wiring;
- startup and error reporting code required by `moonink serve`.

#### Optional starter assets

If `onboard` later emits starter markdown, theme files, or static assets, those materials must also be part of the embedded resource set. This is not required for today's minimal `moonink.json` writer, but the packaging rule should be established now so the command does not regress later.

### 3. Embedded resource generation strategy

The simplest stable contract for MoonInk is to generate checked-in source modules that expose embedded resources directly to MoonBit code.

Recommended mechanism:

1. treat the repository files under the built-in theme directory as source-of-truth authoring inputs;
2. run a generation step that converts those files into a generated MoonBit module under `src/runtime/`;
3. have the runtime read the generated module rather than the repository directory at execution time.

This generated module should provide typed accessors for:

- manifest source;
- named layouts;
- named partials;
- asset-file byte content.

This approach is preferred over ad hoc linker blobs because it keeps the asset contract visible in repository diffs and easier to test with the existing MoonBit codebase.

### 4. Preview server build integration

The current preview-server implementation should be absorbed into the main build graph rather than remaining a runtime-delegated sibling project.

Recommended direction:

- move or factor the reusable native preview-serving implementation into `src/runtime/` or another package compiled by the main module;
- add any required preview-server dependency directly to the main `moon.mod.json` dependency graph;
- make the native Linux main target compile preview-server code as part of the standard `moonink` binary.

The repository may temporarily keep `native-serve/` as a migration aid or code-diff bridge, but it must stop being part of the runtime execution path once the new release pipeline lands.

### 5. Release build entrypoint

The repository should define one documented release build entrypoint for the native Linux binary.

That entrypoint should do all required preparation steps in a fixed order:

1. regenerate embedded built-in resources;
2. compile the main native Linux binary;
3. stage the output as a single executable named `moonink`;
4. run detached release smoke tests.

The exact command wrapper can be a repository script, a documented `moon` invocation sequence, or another checked-in build entry, but the pipeline must be explicit and repeatable. Release success should not depend on manual recollection of hidden setup steps.

### 6. Detached release validation

Release validation is part of the build pipeline, not an optional manual check.

The release pipeline should create a validation step that:

1. copies the built `moonink` binary into a temporary directory outside the repository;
2. creates or copies small fixture projects into the same detached workspace;
3. runs:
   - `moonink onboard`
   - `moonink build`
   - `moonink check`
   - `moonink serve`
4. confirms these commands succeed without repository access.

The validation should also assert negative guarantees:

- no access to `src/runtime/builtin_theme`;
- no access to `native-serve/`;
- no invocation of external `moon run`.

### 7. Failure policy for incomplete embedding

If the release pipeline does not successfully embed a required runtime resource, the build should fail before producing a release artifact.

The system should not allow a partially self-contained binary that silently falls back to repository probing. That would create a fake single-binary release and make detached smoke validation meaningless.

### 8. Likely code and build surfaces affected

Primary packaging/build areas:

- `moon.mod.json`
- `src/runtime/moon.pkg`
- native-target runtime modules under `src/runtime/`
- built-in theme authoring directory under `src/runtime/builtin_theme/`
- generated embedded-resource module(s) under `src/runtime/`
- `src/cmd/main/main.mbt`

Likely migration surfaces:

- `native-serve/moon.mod.json`
- `native-serve/src/`
- current serve delegation glue under `src/runtime/serve_delegate_*`

Documentation likely affected after implementation:

- `README.mbt.md`
- `docs/technical/10-CLI-and-Dev-Server.md`
- `docs/agent-working/MoonInkCliArch.md`
- release/build notes under `docs/agent-working/`

## Testing Strategy

### 1. Embedded bundle generation tests

Add tests or validation checks ensuring that generated embedded-resource modules stay in sync with the source built-in theme inputs.

At minimum, generation should fail when required assets are missing or when the generated module is stale relative to the source bundle.

### 2. Native main-binary serve tests

Add native-target coverage showing that the main `moonink` binary can start preview serving without delegating to another package.

### 3. Detached release smoke tests

Make detached smoke execution part of the release pipeline. This is the key proof that the artifact is truly self-contained.

### 4. Negative dependency checks

Add a validation step ensuring the built artifact does not require:

- repository-local theme files;
- repository-local `native-serve` files;
- runtime shell delegation to `moon run`.

## Trade-offs

### Why prefer generated MoonBit source for embedded assets?

Because it keeps the bundle contract visible, reviewable, and testable inside the normal repository workflow. A generated module is easier to inspect than opaque linker blobs and aligns with MoonInk's existing typed runtime architecture.

### Why compile preview serving into the main binary instead of keeping `native-serve` as an internal helper?

Because the product contract is one released binary. Keeping a second helper may reduce short-term migration work, but it would preserve the exact deployment shape this work is meant to remove.

### Why make detached smoke testing mandatory for release?

Because single-binary claims are easy to believe and easy to accidentally violate. Detached smoke testing turns the release promise into something mechanically checked.

## Success Criteria

This design is satisfied when:

1. the repository has one documented native Linux release build entrypoint for `moonink`;
2. the release artifact is exactly one executable file;
3. built-in theme resources are embedded into the main binary;
4. preview serving is compiled into the main binary rather than delegated through `moon run`;
5. the release pipeline runs detached smoke tests and fails if the artifact still depends on repository files.

## Verification

Planned verification after implementation:

- regenerate the embedded resource module(s);
- build the native Linux `moonink` binary through the documented release entrypoint;
- run `moon check`;
- run `moon test`;
- copy the resulting binary to a temporary non-repository directory and execute detached smoke tests for `onboard`, `build`, `check`, and `serve`.
