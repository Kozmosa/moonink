# CLI Scaffold Implementation 0324

## Goal

Record the evolution of the MoonInk CLI from a cold-start scaffold into a
partially real command-line tool, with `moonink new` now capable of creating a
starter documentation project on disk.

## Scope

Implemented in this milestone:

- command model and pure CLI execution entry;
- parsing and dispatch for `help`, `new`, `build`, and `serve`;
- separate pure (`cli_run`) and runtime (`cli_exec`) execution paths;
- real starter project file emission for `moonink new` on the JS runtime target;
- starter content generation for config, docs, articles, theme files, and `.gitignore`;
- runtime argv integration in `cmd/main` via `@env.args()`;
- argv normalization for both moonrun-style and JS-target layouts;
- black-box tests for parse behavior and starter planning content.

Not implemented in this milestone:

- TOML parsing;
- real content discovery;
- Markdown/frontmatter parsing;
- actual site rendering or local dev server startup;
- non-JS runtime starter emission.

## Files Changed In This Milestone

- `moonink.mbt`
- `starter.mbt`
- `moonink_test.mbt`
- `moon.pkg`
- `cmd/main/main.mbt`
- `cmd/main/moon.pkg`
- `README.mbt.md`
- `docs/agent-working/CliImpl0324.md`
- `docs/agent-working/MoonInkCliArch.md`

## Design Decisions

### Preserve A Pure Test Path

`cli_run(argv)` still returns a `CliOutcome` without side effects. This keeps
core command parsing and starter planning testable without depending on runtime
filesystem behavior.

### Add A Runtime Execution Layer

`cli_exec(argv)` was introduced for the actual executable. This allows the
runtime CLI to perform side effects for `moonink new` while keeping the public
command model unchanged.

### Keep Starter Planning And Emission Together

The `starter.mbt` module now owns both:

- the pure starter-project plan; and
- the runtime emission of that plan.

This keeps the feature cohesive and avoids leaking filesystem concerns into the
CLI parser.

### Use A JS Runtime Bridge First

The first working scaffold emission path targets the JS runtime because it can
use Node's filesystem API directly through MoonBit JS externs. Non-JS runtimes
currently return a guidance message instead of attempting unstable filesystem
calls.

## Current Limitations

- `new` refuses to overwrite an existing directory, but it does not yet offer `--force` or conflict resolution options.
- Runtime filesystem handling is still embedded in `starter.mbt` rather than a dedicated IO package.
- `build` and `serve` remain placeholders.
- CLI options/flags are still not parsed beyond the simple positional project name.
- Real starter emission currently requires `moon run --target js cmd/main -- new <project-name>`.

## Recommended Next Steps

1. extract starter filesystem operations behind a dedicated runtime IO abstraction;
2. add structured CLI option parsing;
3. implement config loading and validation for `build`;
4. add native or wasm-compatible filesystem support and then promote `moon run cmd/main` to the default documented path.
