# MoonInk Check Diagnostics Design

_Date_: 2026-04-15

## Context

MoonInk already provides a non-emitting `check` command and recently gained stronger theme/template preflight validation. The command can already surface parse-time and wikilink diagnostics, but it still lacks a coherent report model for expanding pre-build validation across content and runtime-facing concerns.

The next useful slice is not a full diagnostics framework. It is a focused strengthening of `moonink check` so that it can reliably block builds on the small set of problems that would make output invalid or untrustworthy, while keeping lower-severity quality issues as warnings.

## Goal

Enhance `moonink check` so it acts as a stronger preflight command with a lightweight internal report aggregator and category-grouped CLI output.

The first version should:

- classify diagnostics into explicit categories;
- distinguish blocking errors from warnings;
- fail only on problems that would make build output unreliable or incorrect;
- continue surfacing unresolved wikilinks as warnings;
- keep `check` non-emitting.

## Non-goals

This design intentionally does **not** include:

- a new `doctor` command;
- anchor-level link validation;
- validation of unknown frontmatter keys;
- deep semantic frontmatter validation such as date-format correctness;
- content quality review beyond build-affecting concerns;
- configurable rule severities;
- a generic rebuild of the entire build/check architecture.

## Recommended approach

Introduce a lightweight explicit `check` report model that gathers diagnostics by category and severity, then render that report through the CLI.

This is the chosen approach because the feature needs grouped output and predictable pass/fail rules, but should not turn into a full architectural refactor. The report layer should exist only to make the first-version checks coherent and extensible enough to support the approved feature set.

A larger “make check fully share build internals as a mode” refactor was considered but deferred. For this slice, the priority is to get the checks working and user-facing behavior stable before attempting deeper cleanup.

## Design

### 1. Add a lightweight report aggregator inside `check`

`moonink check` should collect its results into an explicit report structure before formatting output.

The report should group diagnostics under the categories:

- `theme_template`
- `frontmatter`
- `routes`
- `wikilinks`

Each category should store:

- `errors`
- `warnings`

The report should also provide top-level summary fields:

- `error_count`
- `warning_count`
- `passed`

This layer should remain lightweight. Its job is to gather and summarize check results, not to become a general diagnostics runtime.

### 2. Block only on the approved first-version error set

The first version should treat the following as blocking errors:

- active `theme/template` resolution or loading failures;
- final output route conflicts;
- obvious frontmatter type mismatches.

These are blocking because they can either stop the build or produce incorrect output.

The first version should keep the following as warnings only:

- unresolved wikilink targets;
- existing wikilink ambiguity diagnostics, if they continue to be surfaced through the same diagnostics path.

Warnings must not affect the exit code.

### 3. Keep frontmatter validation intentionally narrow

Frontmatter validation in this slice should only catch obvious type mismatches, for example:

- a field expected to be an array is not an array;
- a field expected to be a string is not a string.

The design intentionally does not include:

- unknown-key rejection;
- enum-style validation for fields like `type`;
- date-format validation;
- broader metadata policy enforcement.

This keeps the first version aligned with the rule that `check` should fail only on clearly output-affecting errors.

### 4. Define route failure in terms of final emitted paths

Route checking should fail only when two inputs resolve to the same final output path or URL.

This design does not attempt to fail earlier on “potential” collisions such as similar titles, repeated slugs, or other hints of future overlap. The first version should only block on the concrete condition that would make emitted output conflict.

### 5. Reuse existing wikilink warning behavior

The current wikilinker already emits unresolved-target diagnostics as warnings. That behavior should be preserved.

This means:

- missing wikilink targets remain warning-only;
- anchor-level validation is out of scope for this slice;
- the report aggregator should ingest the existing diagnostics instead of redefining them.

That keeps `check` behavior aligned with the current docflow boundary and avoids turning link quality issues into blocking build failures prematurely.

### 6. Render grouped CLI output from the report

The CLI should print grouped results in a fixed order:

1. `theme/template`
2. `frontmatter`
3. `routes`
4. `wikilinks`

Each category should only be printed when it has content.

Each displayed issue should include, when available:

- severity;
- message;
- source file;
- hint.

The command should end with a summary such as:

```text
[check] summary: 2 errors, 3 warnings
[check] failed
```

or:

```text
[check] summary: 0 errors, 2 warnings
[check] passed
```

The exact wording can vary, but the grouped structure and final status should remain clear and stable.

### 7. Keep `check` non-emitting

Even with stronger validation, `check` must remain non-emitting.

This means the enhanced path must still avoid:

- output directory cleanup;
- HTML emission;
- theme asset copying;
- public asset copying.

The new report layer changes result collection and formatting only. It does not change `check` into a partial build.

## Files to modify

Primary files:
- `src/cli/cmd_build.mbt`
- `src/cli/cli_test.mbt`

Likely supporting reads or targeted edits:
- frontmatter parsing/model code in `src/core/`
- existing route computation/build helpers already used by `build`
- `src/docflow/wikilinker.mbt`
- relevant fixtures under `fixtures/v2/`

## Testing strategy

### Theme/template blocking failures

Retain and extend coverage ensuring theme/template loading failures:
- appear in the `theme/template` group;
- count as errors;
- cause `check` to return non-zero.

### Frontmatter type mismatch failures

Add a fixture or targeted test showing that obvious frontmatter type mismatches:
- appear in the `frontmatter` group;
- count as errors;
- cause `check` to return non-zero.

### Route conflict failures

Add coverage where two source documents resolve to the same final output path.
The test should confirm that the conflict:
- appears in the `routes` group;
- counts as an error;
- causes `check` to fail.

### Wikilink warnings remain non-blocking

Add or retain coverage showing that unresolved wikilinks:
- appear in the `wikilinks` group;
- count as warnings;
- do not fail the command when no blocking errors are present.

### Mixed-result summary coverage

Add a scenario combining at least one blocking error and at least one warning. The test should confirm:
- grouped output contains both categories;
- summary counts are correct;
- final exit status is failure.

## Trade-offs

### Why not make unresolved wikilinks blocking now?

Because the approved scope is to fail only on issues that make output invalid or unreliable. Missing wikilink targets are important, but the current product behavior already treats them as warnings, and changing that policy would be a larger product decision.

### Why not validate more frontmatter rules?

Because the goal is to keep `check` focused on clearly blocking problems. Broader schema and content-policy validation can come later without changing the core report model.

### Why add a report layer before broader refactoring?

Because grouped output and consistent summary rules are hard to keep coherent once checks come from multiple sources. A small report layer solves that user-facing problem without forcing a larger internal rewrite yet.

## Success criteria

This feature is complete when:

1. `moonink check` groups diagnostics under `theme/template`, `frontmatter`, `routes`, and `wikilinks`.
2. Theme/template failures, final route conflicts, and obvious frontmatter type mismatches fail the command.
3. Unresolved wikilinks remain warnings and do not fail the command on their own.
4. The summary clearly reports error and warning counts plus overall pass/fail status.
5. `check` remains non-emitting on both success and failure.

## Verification

Planned verification commands:

- `moon test src/cli`
- `moon check`
- `moon info && moon fmt`

Targeted behavior to verify:
- grouped CLI output remains stable;
- blocking categories produce non-zero exit status;
- warning-only wikilink cases still pass;
- mixed error/warning cases produce correct summary counts;
- no output files are emitted during `check` runs.
