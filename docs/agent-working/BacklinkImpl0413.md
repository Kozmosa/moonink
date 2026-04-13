# Backlinks Implementation 0413

## Goal

Record the inward integration of backlinks onto the current `main` architecture so MoonInk can surface inbound markdown wikilink references in built HTML output without regressing the existing check command, theme loading, or current build pipeline behavior.

## Scope

Implemented in this milestone:

- build-time backlink indexing derived from markdown wikilink targets;
- backlinks rendering through the build templating path;
- a new `backlinks_html` template-context field available to templating;
- built-in default theme placement for backlink sections beneath page content;
- CLI/docflow coverage for backlink output and template-context compatibility;
- worklog + validation for the inward integration on current `main`.

Not implemented in this milestone:

- direct-route backlink-specific assertions;
- a dedicated public backlink model in `docflow` or `core`;
- project-theme-specific backlink styling or alternate backlink layout contracts;
- backlink generation from non-markdown source formats.

## Files Changed In This Milestone

- `src/cli/cmd_build.mbt`
- `src/cli/cli_test.mbt`
- `src/docflow/adapters.mbt`
- `src/docflow/pipeline.mbt`
- `src/docflow/docflow_test.mbt`
- `src/runtime/builtin_theme/layout.html`
- `src/docflow/pkg.generated.mbti`
- `docs/agent-working/worklog/20260414.md`
- `docs/agent-working/BacklinkImpl0413.md`

## Design Decisions

### Integrate Backlinks In The Build Layer, Not By Copying Older Branch Files

A previously validated backlinks implementation existed in an older worktree, but direct file-level reuse conflicted with the newer `main` architecture. Current `main` contains additional build and theme responsibilities, including the check command path and richer theme/template context fields.

Instead of copying the older branch wholesale, the backlinks behavior was re-integrated inward into the current build pipeline. This preserved compatibility with the modern `main` command structure and avoided reintroducing earlier architectural drift.

### Keep Wikilink Resolution As The Source Of Truth

Backlinks are derived by scanning markdown wikilink syntax from source markdown during build, then resolving those targets through the same `WikiLinker` exact-target map already used for outbound wikilink rewriting.

This keeps backlinks aligned with existing route resolution rules and avoids inventing a second route-mapping system.

### Render Backlinks Through Template Context

Instead of hardcoding backlinks directly into rendered HTML bodies, the implementation exposes `backlinks_html` through `TemplateContext` and lets the built-in theme place that content.

This keeps responsibilities separated:

- build logic computes backlink HTML;
- docflow templating exposes the field;
- the built-in theme decides placement.

### Limit Backlink Scope To Markdown Wikilinks

This milestone only indexes backlinks from markdown inputs containing `[[...]]` syntax. HTML inputs continue to participate as backlink destinations if they are linked to, but they are not scanned as backlink sources.

That keeps the feature narrowly scoped to the existing wikilink feature and avoids speculative parsing behavior for formats that do not support MoonInk wikilinks.

## Testing And Validation

The integration followed TDD on current `main`:

1. add a new CLI test asserting backlinks appear in the pretty-route fixture output;
2. run the targeted test and watch it fail;
3. implement the minimal backlinks integration;
4. re-run targeted and package-level tests until green.

Validation completed for this milestone:

- `moon check`
- `moon info && moon fmt`
- `moon test`

Final result at completion: `moon test` passed with 105 tests.

## Current Limitations

- Backlink rendering is currently validated explicitly for the pretty-route fixture, not with a dedicated direct-route backlinks assertion.
- Backlinks are rendered as prebuilt HTML rather than a richer structured model passed into the template layer.
- The built-in theme exposes backlink placement, but project themes must opt in themselves if they want to render backlinks.
- Ambiguous or unresolved wikilinks do not produce backlinks, which matches current wikilink resolution behavior but may deserve explicit documentation later.

## Recommended Next Steps

1. add a direct-route-specific backlink assertion in CLI tests;
2. decide whether project theme documentation should mention `backlinks_html` as part of the supported template contract;
3. if backlink presentation becomes richer, introduce a structured backlink model instead of passing only pre-rendered HTML.
