# MoonInk Single-Binary Runtime Compatibility Design

_Date_: 2026-04-19

## Context

MoonInk now has real `onboard`, `build`, `check`, and `serve` command surfaces, but the current runtime still assumes execution inside the source repository.

The main breakpoints are structural rather than incidental:

- the built-in default theme is discovered by walking upward from the current working directory until `src/runtime/builtin_theme/layout.html` is found;
- `serve` still delegates preview startup through a shell `exec` into `moon run --manifest-path native-serve/moon.mod.json ...`;
- runtime path joining continues to treat many paths as project-relative policy paths, which works for repository-local fixtures but is too narrow for a released CLI installed anywhere on the machine.

Those assumptions are acceptable for repository development, but they fail the intended product contract for a released tool. A user should be able to copy one `moonink` binary onto a native Linux machine, point it at a project directory, and run the full command set without keeping the MoonInk repository around.

## Goal

Define the runtime contract required for a native Linux release where a single `moonink` executable can run the full supported command set outside the source repository:

- `moonink onboard`
- `moonink build`
- `moonink check`
- `moonink serve`

The runtime contract must ensure that:

1. the executable does not depend on repository paths such as `src/runtime/builtin_theme` or `native-serve/` at execution time;
2. command behavior is driven by the user project and embedded runtime resources only;
3. detached installation is a first-class supported mode rather than a fallback.

## Confirmed Decisions

- The target for this work is `native Linux` only.
- The runtime compatibility scope includes `onboard`, `build`, `check`, and `serve`.
- The success condition is detached execution: only one `moonink` executable is present, not the source repository.
- The release/runtime path is the primary design target.
- Repository development should use the same self-contained runtime contract rather than a separate repository-dependent behavior path.
- It is acceptable for the main binary to grow in size in order to embed the built-in theme and preview-serving capability.
- User-visible CLI behavior may be adjusted where needed, as long as the new contract is explicit and tested.

## Non-goals

This design intentionally does not include:

- Windows or macOS release behavior;
- hot reload, file watching, or broader development-server features;
- plugin packaging, theme marketplace packaging, or general resource extension APIs;
- distribution-channel concerns such as package manager formulas, container images, or installer UX;
- minimizing binary size at the expense of runtime clarity.

## Recommended Approach

Adopt a `release-first, self-contained runtime` model.

In this model, the executable owns two distinct resource domains:

- host filesystem resources belonging to the user project;
- embedded runtime resources compiled into the binary.

The CLI should no longer probe for repository layout at runtime. Instead, it should:

1. resolve the user project from CLI input and current working directory;
2. interpret project config fields relative to that project root;
3. load built-in assets from embedded resources;
4. run preview serving in-process on native Linux.

Two alternatives were considered and rejected as the primary direction:

- `dual-path runtime`: keep a repository-aware runtime for development and add a second release-only runtime for detached installs. This would preserve current behavior short-term, but it would lock MoonInk into duplicated semantics and make bugs harder to reason about.
- `repository fallback runtime`: keep repository probing as the main path and only fall back to embedded behavior when repository assets are unavailable. This would keep the wrong dependency direction: release quality would still be judged against repository presence.

## Design

### 1. Runtime architecture boundaries

The released CLI should have four explicit responsibility areas.

#### CLI surface

`src/cli/` remains responsible for:

- parsing arguments;
- user-visible command semantics;
- stage-specific success and failure messages.

#### Project filesystem runtime

A dedicated project-filesystem layer should own:

- locating the config file from CLI input;
- resolving host filesystem paths;
- reading and writing project files;
- converting CLI overrides into project-scoped config values.

This layer is the only place that should reason about the machine's real filesystem paths.

#### Embedded runtime resources

A dedicated embedded-resource layer should own runtime resources compiled into the binary, including:

- the built-in theme bundle;
- starter resources required by `onboard`, if `onboard` grows beyond one generated config file;
- any internal assets needed by the preview server.

Embedded resources must not masquerade as project files. They come from the binary, not from the user's vault.

#### Preview server runtime

A dedicated preview-server layer should own:

- validating the built preview root;
- binding host and port;
- serving the generated output tree on native Linux;
- reporting serve-stage startup failures without delegating to another repository-local command.

### 2. Host path model

The detached binary needs a stricter distinction between `host filesystem paths` and `project-relative policy paths`.

#### CLI path inputs

`--config` is a host filesystem path. It may be:

- omitted, meaning `moonink.json` in the current working directory;
- relative to the current working directory;
- absolute.

The runtime should normalize this to an absolute host path before config loading begins.

#### Project root derivation

After the config path is normalized to an absolute host path, the runtime should derive:

- `config_abs_path`
- `project_root_abs = dirname(config_abs_path)`

The project root must come from the config path, not from repository probing and not from a search for MoonInk source files.

#### Config field path policy

Within `moonink.json`, the following fields remain project-relative policy paths:

- `content_dir`
- `output_dir`
- `theme`
- `template_file`

These fields should continue to:

- forbid absolute paths;
- forbid `..` traversal;
- normalize repeated separators and `.` segments.

This preserves the existing safety boundary from `src/core/io_policy.mbt`.

#### Required runtime split

The runtime must add a separate host-path helper layer instead of reusing `join_relative_path` for everything.

The current relative-path policy is correct for project config fields but incorrect for:

- absolute config paths;
- absolute project roots;
- detached installation execution.

The new contract therefore requires two path spaces:

- host paths: absolute or cwd-relative machine paths;
- policy paths: relative, sandboxed paths inside the project contract.

#### CLI `--output` contract

For this slice, `--output` should remain a project-relative override, not a free-form host absolute path.

That keeps the override consistent with `output_dir` in config and avoids widening the write boundary during the same refactor. The runtime should resolve the final preview/output root as:

`project_root_abs + normalized output policy path`

### 3. Embedded built-in resource model

Detached execution should never require repository lookups for default resources.

#### Built-in theme

The built-in default theme should be loaded from an embedded bundle compiled into the main binary. That bundle should cover:

- manifest data;
- layouts;
- partials;
- theme assets.

Theme resolution order should be:

1. project theme directory, if configured and present;
2. project template file, if configured and present;
3. embedded built-in default theme.

The embedded default theme is not a fallback to repository files. It is the canonical default runtime theme source.

#### `onboard` resources

`onboard` currently only writes `moonink.json`. If future `onboard` behavior grows to emit starter theme files, starter pages, or starter assets, those materials must also come from embedded resources rather than repository-local templates.

### 4. Command semantics in detached runtime

#### `onboard`

`onboard` should operate entirely within the current working directory as the target project directory.

Its runtime behavior should:

- check for an existing `moonink.json` in the target directory;
- write a new config if none exists;
- avoid repository lookups or external template dependencies.

#### `build`

`build` should:

1. resolve the config path through the host-path layer;
2. derive the absolute project root from that config file;
3. interpret content/theme/template/output policy paths relative to the derived project root;
4. read project files from the host filesystem;
5. use embedded built-in resources where the project does not supply its own theme/template override.

#### `check`

`check` should share the same runtime entry and path resolution model as `build`.

It must operate over the same resolved project root, theme resolution order, and content discovery boundaries, but stop before output emission.

#### `serve`

`serve` should be redefined as:

1. perform a normal detached-runtime build using the resolved project root;
2. if the build has fatal errors, stop;
3. if the build is warning-only or clean, start the preview server in-process from the produced output root.

`serve` must not:

- shell out to `/bin/sh`;
- `exec` another program;
- require `moon` to be installed;
- read `native-serve/moon.mod.json` from the repository.

### 5. Runtime refactor targets

This design requires removing repository-dependent runtime behavior from the main command path.

#### Remove repository probing from built-in theme discovery

The runtime should stop using current-working-directory upward search for `src/runtime/builtin_theme/...` as the default theme mechanism.

That search path is appropriate only for development inspection, not for the released runtime contract.

#### Remove repository delegation from `serve`

The runtime should stop constructing a delegated shell command that runs `moon run --manifest-path native-serve/moon.mod.json ...`.

The detached binary must own preview startup directly.

#### Normalize config loading around host-path resolution

Config loading should accept a host path first and only later derive project-relative policy behavior. This is the only robust way to support:

- execution from outside the project directory;
- absolute config inputs;
- detached binary installs.

### 6. Error handling contract

The detached runtime should make path and stage failures explicit.

Required user-facing failure classes:

- config path not found;
- config path is invalid or unreadable;
- config contains invalid project-relative paths;
- project theme/template paths are invalid or missing;
- build-stage content or emission failures;
- serve-stage startup failures such as port binding errors.

Embedded-resource failure must be treated as a damaged MoonInk build artifact, not as a cue to fall back to repository lookups.

### 7. Files likely affected by implementation

Primary runtime and CLI areas:

- `src/core/io_policy.mbt`
- `src/core/config.mbt`
- `src/runtime/config_loader.mbt`
- `src/runtime/io.mbt`
- `src/runtime/serve.mbt`
- `src/runtime/theme_loader.mbt`
- `src/cli/cmd_onboard.mbt`
- `src/cli/cmd_build.mbt`
- `src/cli/cmd_serve.mbt`
- `src/cmd/main/main.mbt`

Likely new support modules:

- host-path helpers under `src/runtime/`
- embedded resource accessors under `src/runtime/`
- preview-server runtime modules under `src/runtime/`

## Testing Strategy

### 1. Detached-install smoke coverage

Add integration coverage that copies a built `moonink` binary into a temporary directory with no repository checkout present, then exercises:

- `moonink onboard`
- `moonink build`
- `moonink check`
- `moonink serve`

### 2. Config path resolution coverage

Add tests covering:

- default `moonink.json` in the current project directory;
- relative `--config`;
- absolute `--config`;
- invoking the binary from outside the project while targeting the project config.

### 3. Repository-independence coverage

Add verification that detached runtime execution does not:

- search for `src/runtime/builtin_theme`;
- read `native-serve/`;
- invoke external `moon run`;
- require `/bin/sh` for normal command execution.

### 4. Output-root coverage

Add tests showing that:

- config `output_dir` remains project-relative;
- CLI `--output` remains project-relative and normalized;
- the final build/serve preview root resolves correctly from an absolute project root.

### 5. Embedded-theme fallback coverage

Add tests proving that when no project theme or template file is configured, build/check load the embedded default theme and still succeed outside the repository.

## Trade-offs

### Why not keep repository fallback for development convenience?

Because it would preserve two runtime truths. The design goal is to make detached release behavior the primary contract and have repository development benefit from the same contract.

### Why keep `--output` project-relative for now?

Because the immediate bug is that host path resolution and project-relative policy are currently conflated. Expanding `--output` into a second host-path write surface during the same slice would increase risk without being necessary for the detached-binary goal.

### Why treat embedded-resource failure as fatal?

Because a missing embedded bundle means the release artifact itself is broken. Falling back to repository probing would hide packaging defects and make release validation unreliable.

## Success Criteria

This design is satisfied when:

1. a native Linux `moonink` binary runs `onboard`, `build`, `check`, and `serve` without the source repository present;
2. built-in theme loading no longer depends on repository path discovery;
3. `serve` no longer shells out or delegates through `native-serve/moon.mod.json`;
4. config resolution works from relative and absolute `--config` inputs;
5. detached runtime tests prove that only project files and embedded binary resources are required at execution time.

## Verification

Planned verification commands after implementation:

- `moon test`
- `moon check`
- `moon info && moon fmt`

Additional release validation required:

- build the native Linux `moonink` binary;
- copy it into a temporary directory with no repository checkout;
- run detached smoke tests for `onboard`, `build`, `check`, and `serve` against fixture projects.
