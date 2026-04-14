# MoonInk Check Theme/Template Diagnostics Design

_Date_: 2026-04-15

## Context

MoonInk already has a non-emitting `check` command that validates config loading, content discovery, document parsing, and wikilink diagnostics. However, theme/template loading failures are still mostly discovered during `build`, even though they are deterministic preconditions for a successful build.

We recently completed structured CLI flags and made `check` more usable as a first-class pre-build command. The next high-value improvement is to make `check` catch theme/template loading failures early, without writing output files or copying assets.

## Goal

Enhance `moonink check` so it validates the active theme/template resolution path before document checking proceeds, and reports failures using `[check] ...` error formatting.

This slice should let users discover problems such as:

- configured `template_file` does not exist;
- configured `template_file` cannot be read;
- project `theme/layout.html` resolution or reading fails;
- the effective active layout cannot be loaded through the same precedence used by `build`.

## Non-goals

This design intentionally does **not** include:

- validating HTML/template syntax correctness;
- validating that theme templates reference all supported context fields;
- validating `theme/assets/` contents or copyability;
- broader frontmatter/config diagnostics;
- broader wikilink diagnostic redesign;
- refactoring `check` into a generic multi-stage diagnostics framework.

## Recommended approach

Reuse the existing active theme/template resolution logic from the runtime/config layer directly inside the `check` path.

This is the recommended approach because it keeps `check` behavior aligned with `build` behavior. If `build` would fail because the active layout cannot be loaded, `check` should fail for the same reason, using the same precedence rules:

1. `theme/layout.html`
2. configured `template_file`
3. built-in default theme

A separate lightweight checker was considered but rejected because it would duplicate logic and drift from the real build path.

## Design

### 1. Add theme/template preflight validation to `check`

The `check` flow in `src/cli/cmd_build.mbt` should validate active theme/layout resolution before collecting document diagnostics.

Current `check_site_result(...)` behavior:
- loads build inputs;
- builds wikilinker state;
- parses documents;
- applies wikilink diagnostics;
- returns summary + diagnostics.

Planned behavior:
- load build inputs;
- resolve the active theme/layout using the same runtime resolution as `build`;
- if active theme resolution succeeds, continue with existing parse/link diagnostics;
- if active theme resolution fails, return a `CheckCommandError` and stop without emitting output.

### 2. Reuse the existing active layout source of truth

`src/runtime/config_loader.mbt` already exposes `load_active_theme_layout_result(config)` with the correct precedence and error behavior. `check` should call that instead of introducing a second interpretation of theme/template state.

`src/cli/cmd_build.mbt` already has a `resolve_active_theme_layout(...)` helper used by `build`. The most direct implementation is to reuse that helper from `check`, or extract the shared part cleanly if needed.

### 3. Extend check-specific error reporting

`CheckCommandError` and `format_check_command_error(...)` should gain a theme/template-loading failure path.

Recommended user-facing format:

```text
[check] failed during theme loading
<underlying formatted error>
```

This keeps the existing `[check] failed during ...` convention while making the failing phase explicit.

### 4. Preserve the non-emitting contract

Even with theme/template preflight added, `check` must remain non-emitting.

This means the enhanced `check` path must still avoid:
- output directory cleanup;
- `public/` copying;
- theme asset copying;
- rendered HTML emission.

The added theme/template validation should stop at “can the active layout be resolved and loaded?”

## Files to modify

Primary files:
- `src/cli/cmd_build.mbt`
- `src/cli/cli_test.mbt`

Likely supporting reads only:
- `src/runtime/config_loader.mbt`
- existing fixture configs under `fixtures/v2/`

## Testing strategy

### Keep existing green-path behavior

Retain and rerun existing tests confirming:
- minimal fixture `check` succeeds with zero diagnostics;
- wikilink warning fixture returns diagnostics without writing output.

### Add theme/template failure coverage

Add a new `check` test using the existing missing-template fixture:
- `fixtures/v2/missing_template_file/moonink.json`
- assert `check` fails;
- assert the error is reported as a check-stage failure, not a build-stage failure;
- assert the message still points to the missing template path.

### Re-assert non-emitting behavior on failure

In the new missing-template test, assert that `check` does not create output HTML in the configured output directory.

## Trade-offs

### Why not build a dedicated lightweight theme checker?

Because it would duplicate the precedence and loading rules already implemented in runtime config loading. Reusing the actual active layout resolution keeps `check` trustworthy.

### Why not validate theme assets too?

Because this slice is specifically about catching layout/template blockers with minimal scope. Asset validation is a separate concern and can be added later if needed.

## Success criteria

This feature is complete when:

1. `moonink check` fails early if the active layout/template cannot be loaded.
2. The failure uses `[check] ...` framing rather than surfacing only through `build` semantics.
3. Existing successful and diagnostic `check` behavior remains unchanged otherwise.
4. `check` still writes no output files on both success and failure.

## Verification

Planned verification commands:

- `moon test src/cli`
- `moon check`
- `moon info && moon fmt`

Targeted behavior to verify:
- minimal fixture still passes `check`;
- wikilink-warning fixture still reports diagnostics only;
- missing-template fixture now fails through `check` with theme/template load reporting;
- no output HTML is emitted during any `check` run.
