# IO Refactor Plan 0331

## Goal And Scope

This note records the documentation-side completion of the initial IO refactor planning task. The work establishes MoonInk's current engineering direction for filesystem handling and async evolution under the constraint that `native` support is mandatory and `moonbitlang/x/fs` is the current filesystem API source.

## Files Changed

- `docs/technical/13-IO-Runtime-and-Async-Plan.md`
- `docs/zh/technical/13-IO-Runtime-and-Async-Plan.md`
- `docs/Roadmap.md`
- `docs/zh/Roadmap.md`
- `docs/technical/00-Architecture.md`
- `docs/agent-working/MoonInkCliArch.md`
- `docs/technical/15-IO-Surface-Inventory.md`

## Design Decisions And Trade-Offs

### 1. Native Is The First-Class Runtime Target

The plan explicitly treats `native` as a required target now instead of trying to remain equally optimized for all backends.

Trade-off: this accelerates practical runtime design, but postpones broader target-specific abstraction work.

### 2. `x/fs` Remains The Baseline Capability Source

The plan does not replace `moonbitlang/x/fs`. Instead, it defines a MoonInk-owned facade as the next architectural step.

Trade-off: this adds one more layer, but it prevents raw filesystem calls from spreading and gives the project a place to normalize errors, path policy, and async evolution.

### 3. Sync Core, Async Boundary

The documents now state that parsing, normalization, routing, and modeling should remain synchronous where practical, while reads, writes, and traversal move toward async runtime boundaries.

Trade-off: this avoids whole-codebase async contamination, but requires discipline in how feature modules call runtime helpers.

### 4. Atomic Commit Roadmap

The roadmap is split into `IO-P0` through `IO-P14` so the future implementation can proceed with reversible, reviewable commits.

Trade-off: the migration may take longer, but each stage becomes easier to validate and safer to roll back.

## Current Limitations / Placeholders

- no code-level runtime IO facade exists yet;
- no async interface has been implemented yet;
- direct `x/fs` usage still exists in `starter.mbt`, `config.mbt`, and `content.mbt`;
- `IO-P1` is now documented in `docs/technical/15-IO-Surface-Inventory.md`, but `IO-P2` and later refactor stages are still pending.

## IO-P1 Inventory Result

The current raw filesystem inventory established by `IO-P1` is:

- `config.mbt`: `@fs.read_file_to_string(config_path)` for `moonink.toml` loading;
- `content.mbt`: `@fs.path_exists`, `@fs.is_dir`, `@fs.read_dir`, and `@fs.is_file` across recursive Markdown discovery;
- `starter.mbt`: `@fs.path_exists`, `@fs.create_dir`, and `@fs.write_string_to_file` for starter project emission.

Caller chains are currently routed through `cmd/main/main.mbt` -> `@moonink.cli_exec` -> `moonink.mbt` runtime dispatch -> feature modules.

## Next Implementation Steps

1. define the intended runtime/IO package boundary (`IO-P2`);
2. introduce the project-owned error model and path policy before adding async interfaces;
3. add a sync facade over the existing `x/fs` usage without changing behavior;
4. start migration with read paths before write paths.
