# Check Diagnostics Implementation 0415

## Goal

Record the `moonink check` diagnostics hardening slice that introduced grouped reporting, blocking-vs-warning semantics, and concrete non-emitting validation for build-affecting issues.

## Scope

Implemented in this slice:

- grouped `check` diagnostics reporting with explicit categories;
- structured check report model in the CLI runtime path;
- fixed-order grouped check rendering under `theme/template`, `frontmatter`, `routes`, and `wikilinks`;
- blocking theme/template validation during `check`;
- blocking frontmatter type mismatch validation for obvious scalar/list mistakes;
- blocking validation for invalid scalar `draft` values that are not `true`/`false`;
- blocking final emitted output path conflict detection;
- preservation of unresolved/ambiguous wikilinks as warning-only diagnostics;
- regression fixtures and CLI coverage for warning-only, blocking-only, and mixed-result `check` runs.

Not implemented in this slice:

- anchor-level link validation;
- unknown frontmatter key validation;
- deep semantic frontmatter validation beyond obvious type mismatches;
- configurable check severities;
- a separate `doctor` command.

## Files Changed In This Slice

- `src/core/frontmatter.mbt`
- `src/core/core_test.mbt`
- `src/cli/cmd_build.mbt`
- `src/cli/cli_test.mbt`
- `src/core/pkg.generated.mbti`
- `src/cli/pkg.generated.mbti`
- `fixtures/v2/check_frontmatter_type_mismatch/*`
- `fixtures/v2/check_route_conflict/*`
- `fixtures/v2/check_mixed_diagnostics/*`
- `fixtures/v2/check_frontmatter_invalid_draft/*`
- `fixtures/v2/check_group_order/*`
- `docs/agent-working/MoonInkCliArch.md`
- `docs/superpowers/plans/2026-04-18-check-diagnostics-completion.md`
- `docs/agent-working/CheckDiagnosticsImpl0415.md`
- `docs/agent-working/worklog/20260418.md`
- `docs/agent-working/worklog/20260415.md`

## Design Decisions

### Keep `check` Non-Emitting

The implementation continues to stop before output cleanup, rendering, asset copying,
or HTML emission. Validation is performed on loaded build inputs plus parsed document
diagnostics only.

### Use A Lightweight Report Model In CLI

`src/cli/cmd_build.mbt` now owns a small report structure that classifies entries by
category and severity. This keeps policy decisions close to command behavior without
forcing a broader architectural rewrite.

### Block Only Build-Affecting Problems

`check` now fails only when it finds issues that make output invalid or unreliable:

- active theme/template resolution failures;
- obvious frontmatter type mismatches;
- invalid scalar `draft` values;
- final emitted output path conflicts.

Unresolved or ambiguous wikilinks remain warnings so content-quality issues do not
block the command by themselves.

### Validate Route Conflicts At Final Output Path Level

Conflict detection uses `@core.output_html_path(...)`, so the command blocks only on
real emitted-path collisions instead of speculative route similarities.

### Preserve Parse-Time Shape Information For Narrow Frontmatter Checks

`Frontmatter` now carries `field_shapes` plus `invalid_scalar_fields` metadata so the
CLI can distinguish obvious schema mismatches without reparsing raw frontmatter or
expanding into a full schema system.

### Finish The User-Facing Grouping Contract

The original slice landed the right blocking policy and report counts, but still exposed
WikiLink warnings through a generic `document` label and rendered entries in append order.
The completion update closes that drift by:

- renaming the user-facing document diagnostics group to `wikilinks`;
- rendering non-empty groups in the fixed order `theme/template`, `frontmatter`, `routes`,
  `wikilinks`;
- using explicit pass/fail wording in both the header and final summary status line.

## Current Limitations

- `draft` validation is still intentionally narrow: list values and invalid scalar
  booleans are blocked, but broader metadata policy is still out of scope.
- The report model still lives entirely in the CLI layer rather than a shared runtime
  diagnostics package.

## Recommended Next Steps

1. consider whether broader frontmatter schema validation belongs in `check` or a
   future dedicated diagnostics command;
2. extend diagnostics coverage only when new checks remain clearly build-affecting.
