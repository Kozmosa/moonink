# 15 IO Surface Inventory

## 1. Purpose

This document records the code-facing completion of `IO-P1: Inventory Existing IO Surface`.
It catalogs the current raw filesystem touch points, the caller chains that reach them, and the migration priority that should drive the next refactor stages.

The inventory is intentionally limited to real filesystem behavior already present in the repository. It does not speculate about future dev-server sockets, search indexing writes, or renderer output emission that has not been implemented yet.

## 2. Current Inventory Summary

At the time of this inventory, MoonInk has raw `moonbitlang/x/fs` usage in three feature modules:

- `config.mbt` for configuration file reads;
- `content.mbt` for directory existence checks and recursive Markdown discovery;
- `starter.mbt` for starter-project directory creation and file writes.

These modules are reached through the current CLI runtime chain:

```text
cmd/main/main.mbt
  -> @moonink.cli_exec(...)
  -> moonink.mbt dispatch_runtime_cli_command(...)
  -> feature command runner
  -> raw @fs calls inside feature modules
```

There are currently 10 direct raw `@fs` call sites:

- 1 read call site in `config.mbt`;
- 6 traversal and filesystem inspection call sites in `content.mbt`;
- 3 write and directory creation call sites in `starter.mbt`.

## 3. Detailed IO Surface Table

| Area | File | Function | Raw IO call sites | Runtime caller chain | Priority | Why it matters now |
| --- | --- | --- | --- | --- | --- | --- |
| Config read | `config.mbt` | `read_config_source` -> `load_config` | `@fs.read_file_to_string(config_path)` | `cmd/main/main.mbt` -> `@moonink.cli_exec` -> `run_build_command` -> `load_config` -> `read_config_source` | P1-High | Read-path migration should happen before writes; this is the narrowest and safest first facade target. |
| Content discovery | `content.mbt` | `collect_markdown_files` -> `discover_content` | `@fs.path_exists(root)`, `@fs.is_dir(root)`, `@fs.read_dir(root)`, `@fs.is_dir(full_path)`, `@fs.is_file(full_path)` | `cmd/main/main.mbt` -> `@moonink.cli_exec` -> `run_build_command` -> `discover_content` -> `collect_markdown_files` | P1-High | Recursive traversal is already real build behavior and is the main place where IO spread would grow without a facade. |
| Starter write flow | `starter.mbt` | `try_emit_starter_project` -> `emit_starter_project` -> `run_new_command_runtime` | `@fs.path_exists(plan.root_dir)`, `@fs.create_dir(directory)`, `@fs.write_string_to_file(...)` | `cmd/main/main.mbt` -> `@moonink.cli_exec` -> `run_new_command_runtime` -> `emit_starter_project` -> `try_emit_starter_project` | P2-Medium | Important, but should follow read-path stabilization because write safety and overwrite policy need a clearer boundary first. |

## 4. Module-By-Module Notes

### 4.1 `config.mbt`

Current behavior:

- reads `moonink.toml` as text;
- maps raw filesystem failures into `ConfigError::IOError(String)`;
- keeps parsing logic itself synchronous and filesystem-free after the source text is loaded.

Migration implication:

- this module is already close to the desired architecture;
- `IO-P5` can first replace the raw read call with a project-owned sync facade;
- `IO-P7` can then move the same boundary to an async-capable read API with minimal parser churn.

### 4.2 `content.mbt`

Current behavior:

- checks directory existence;
- validates directory-ness;
- reads directory entries;
- recursively traverses nested directories;
- filters `.md` files;
- maps raw filesystem failures into `ContentDiscoveryError::IOError(String)`.

Migration implication:

- this is the broadest current IO surface;
- path policy, traversal rules, and error normalization should be frozen before this area grows further;
- `IO-P9` should move this whole traversal path behind the runtime facade instead of wrapping each helper ad hoc.

### 4.3 `starter.mbt`

Current behavior:

- checks whether the destination root already exists;
- creates required directories for the starter template;
- writes all starter files directly;
- converts raw filesystem failures into CLI-facing text in `emit_starter_project`.

Migration implication:

- this path needs explicit overwrite, atomicity, and partial-write recovery policy;
- it should not be the first async migration target;
- `IO-P8` should migrate it after read behavior and shared error vocabulary are stable.

## 5. Non-IO But Relevant Callers

The following files participate in the caller graph but do not currently perform raw filesystem IO themselves:

- `cmd/main/main.mbt`: normalizes argv and invokes `@moonink.cli_exec`;
- `moonink.mbt`: dispatches between pure and runtime command paths;
- `render.mbt`: orchestrates `load_config` and `discover_content`, but current render output is still simulated.

This means the project already has a partial execution split between:

- a runtime CLI path that is allowed to cause side effects; and
- higher-level orchestration code that can be kept mostly synchronous once IO moves behind a facade.

That split should be preserved and strengthened in `IO-P2`.

## 6. Priority Ordering For The Next Stages

Recommended migration order after this inventory:

1. `IO-P2`: define the project-owned runtime / IO boundary;
2. `IO-P3`: unify filesystem-related errors under shared project vocabulary;
3. `IO-P4`: freeze path normalization and text encoding expectations;
4. `IO-P5`: introduce a sync facade over current `x/fs` calls;
5. `IO-P7`: migrate config and source-file reads first;
6. `IO-P8`: migrate starter writes with explicit safety guarantees;
7. `IO-P9`: migrate recursive directory and workspace loading.

## 7. Completion Result For IO-P1

`IO-P1` is satisfied when the repository has a current, reviewable inventory of real IO touch points and their caller chains.

This document now provides that baseline and should be treated as the source inventory for the next boundary-definition commit.
