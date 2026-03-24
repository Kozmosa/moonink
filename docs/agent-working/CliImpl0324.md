# CLI Scaffold Implementation 0324

## Goal

Record the evolution of the MoonInk CLI from a cold-start scaffold into a
partially real command-line tool, with `moonink new` capable of creating a
starter documentation project on disk and `moonink build` now able to perform
the first real input stage of the build pipeline.

## Scope

Implemented in this milestone:

- command model and pure CLI execution entry;
- parsing and dispatch for `help`, `new`, `build`, and `serve`;
- separate pure (`cli_run`) and runtime (`cli_exec`) execution paths;
- real starter project file emission for `moonink new` through `moonbitlang/x/fs`;
- starter content generation for config, docs, articles, theme files, and `.gitignore`;
- runtime argv integration in `cmd/main` via `@env.args()`;
- argv normalization for both moonrun-style and JS-target layouts;
- build phase 1a config loading from `moonink.toml` with minimal TOML parsing and validation;
- recursive Markdown discovery under `docs/` and `articles/` for build phase 1a;
- committed fixture projects and black-box tests for config loading and content discovery.

Not implemented in this milestone:

- frontmatter parsing;
- Markdown/frontmatter semantic parsing;
- actual site-model construction beyond the placeholder bridge;
- actual rendering or local dev server startup.

## Files Changed In This Milestone

- `moonink.mbt`
- `starter.mbt`
- `config.mbt`
- `content.mbt`
- `render.mbt`
- `moonink_test.mbt`
- `moon.pkg`
- `cmd/main/main.mbt`
- `cmd/main/moon.pkg`
- `README.mbt.md`
- `fixtures/build_phase1a/minimal/...`
- `fixtures/build_phase1a/missing_site_name/...`
- `fixtures/build_phase1a/missing_articles_dir/...`
- `docs/agent-working/CliImpl0324.md`
- `docs/agent-working/MoonInkCliArch.md`

## Design Decisions

### Preserve A Pure Test Path

`cli_run(argv)` still returns a `CliOutcome` without side effects. This keeps
command parsing and starter planning testable without depending on runtime
filesystem behavior.

### Add A Runtime Execution Layer

`cli_exec(argv)` was introduced for the actual executable. This allows the
runtime CLI to perform side effects for `moonink new` while keeping the public
command model unchanged.

### Keep Starter Planning And Emission Together

The `starter.mbt` module owns both:

- the pure starter-project plan; and
- the runtime emission of that plan.

This keeps the feature cohesive and avoids leaking filesystem concerns into the
CLI parser.

### Use `moonbitlang/x/fs` For Runtime File IO

The starter emission path and build phase 1a content access both rely on
`moonbitlang/x/fs` for path existence checks, directory creation, directory
listing, and string reads/writes. Runtime IO failures surface as typed error
values that are converted into user-facing CLI messages.

### Parse Only The Minimal TOML Subset Needed For Phase 1a

Instead of adding a full TOML dependency immediately, phase 1a uses a focused
line-oriented parser that supports:

- section headers like `[site]`;
- simple `key = "value"` entries;
- blank lines and `#` comment lines.

This is enough for the current starter format and fixture coverage, while
keeping the implementation small and explicit.

## Current Limitations

- `new` refuses to overwrite an existing directory, but it does not yet offer `--force` or conflict resolution options.
- Runtime filesystem handling is still embedded in feature modules rather than a dedicated IO package.
- `build` validates config and discovers Markdown files, but later phases still rely on dummy site-model and render layers.
- The TOML parser is intentionally minimal and does not yet support broader TOML syntax.
- CLI options/flags are still not parsed beyond the simple positional project name.

## Recommended Next Steps

1. decide whether filesystem helpers should move into a shared runtime IO abstraction as more commands gain real behavior;
2. add structured CLI option parsing;
3. implement frontmatter parsing and richer content typing on top of the discovery layer;
4. replace the remaining dummy model/render stages once the build input layer is stable.
