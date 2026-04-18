# Theme System V2 Implementation 0416

## Goal

Record the Theme System V2 milestone that moved MoonInk from a single active layout file toward manifest-driven theme bundles with structured template context, bundle validation, token emission, and a built-in Theme V2 fallback.

## Scope

Implemented in this milestone:

- `moonink.json` support for `theme` and structured `theme_config`
- frontmatter support for page-level `layout` and `theme_*` overrides
- Theme V2 manifest parsing for `name`, `layouts`, `tokens`, `page_overrides`, and `slots`
- runtime loading of project-local Theme V2 bundles from the configured theme directory (`moonink.json.theme`, defaulting to `theme/theme.json`)
- eager validation for missing layouts and missing partial references
- Theme V2 page-kind routing with `index`, `page`, and `article` layout keys
- structured Theme V2 render context with `site`, `page`, `collections`, `slots`, and loop locals
- template engine support for nested path lookup, `{% if %}`, `{% for %}`, and `{% include %}`
- CLI-side validation for missing Theme V2 layouts and unsupported page override keys
- theme token flattening and `dist/assets/theme-vars.css` emission from manifest declarations plus config overrides
- manifest-level rejection of invalid and duplicate token names
- built-in Theme V2 bundle files under `src/runtime/builtin_theme/`
- build/check fallback to the built-in Theme V2 bundle when no project bundle or legacy override path exists
- realistic Theme V2 fixtures covering layout selection, slots, page overrides, preflight validation, and built-in fallback

Not implemented in this milestone:

- layered or inheritable theme bundles
- theme registry / remote theme installation
- recursive partial directory traversal
- a frontend theme gallery or visual theme companion
- per-theme schema validation beyond the current manifest and page-override allowlist

## Files Changed In This Milestone

Core and frontmatter/modeling:

- `src/core/config.mbt`
- `src/core/frontmatter.mbt`
- `src/core/theme_manifest.mbt`
- `src/core/theme_view_model.mbt`
- `src/core/core_test.mbt`

Template engine and pipeline:

- `src/docflow/pipeline.mbt`
- `src/docflow/docflow_test.mbt`

Runtime theme loading:

- `src/runtime/config_loader.mbt`
- `src/runtime/theme_loader.mbt`
- `src/runtime/runtime_test.mbt`
- `src/runtime/builtin_theme/theme.json`
- `src/runtime/builtin_theme/layouts/index.html`
- `src/runtime/builtin_theme/layouts/page.html`
- `src/runtime/builtin_theme/layouts/article.html`
- `src/runtime/builtin_theme/partials/header.html`
- `src/runtime/builtin_theme/partials/sidebar.html`
- `src/runtime/builtin_theme/assets/moonink-default.css`

CLI integration and validation:

- `src/cli/cmd_build.mbt`
- `src/cli/cli_test.mbt`

Fixtures added or expanded:

- `fixtures/v2/theme_v2_basic/*`
- `fixtures/v2/theme_v2_invalid_missing_partial/*`
- `fixtures/v2/theme_v2_invalid_nested_missing_partial/*`
- `fixtures/v2/theme_v2_invalid_empty_layouts/*`
- `fixtures/v2/theme_v2_page_overrides/*`

Documentation/finalization:

- `docs/agent-working/MoonInkCliArch.md`
- `docs/agent-working/ThemeSystemV2Impl0416.md`
- `docs/agent-working/worklog/20260417.md`
- `docs/agent-working/worklog/20260418.md`

## Design Decisions And Trade-offs

### Keep Theme V2 Bundle Resolution In Runtime, But Contract Enforcement In CLI Preflight

Runtime owns loading bundle files and validating manifest/layout/partial integrity. CLI owns page-level enforcement such as layout-key selection and override allowlisting because those depend on discovered content metadata.

The trade-off is a split validation surface, but it keeps filesystem concerns in runtime and site assembly concerns in CLI.

### Preserve Legacy Layout Compatibility While Making Theme V2 The Default Fallback

Project `<theme>/layout.html` and configured `template_file` still work as the legacy path, where `<theme>` comes from `moonink.json.theme` or defaults to `theme`. The built-in default for `build` and `check` now becomes the built-in Theme V2 bundle when no project bundle or legacy override exists.

The trade-off is some extra selection logic, but it avoids breaking existing users while moving the default system toward the new contract.

### Use Derived Page Kinds As The Default Layout Contract

Theme V2 uses `index`, `page`, and `article` as the baseline layout keys, with frontmatter `layout` as an explicit override.

The trade-off is that theme authors must cover the default kinds explicitly, but layout selection becomes deterministic and testable without introducing directory-based heuristics.

### Keep Theme Config Structured Until The Last Responsible Moment

`theme_config` and page `theme_*` overrides are preserved as nested `ThemeConfigValue` trees. Flattening happens only for token CSS emission, while templates still receive the structured shape.

The trade-off is a small amount of conversion code, but themes can consume either rich structured values or emitted CSS variables without losing source shape prematurely.

### Validate Token Names At Manifest Parse Time

Token-name constraints and duplicate rejection live in manifest parsing rather than later CSS emission. This fixes collisions and malformed CSS-variable generation at the source boundary.

The trade-off is a stricter manifest contract, but failures become early and unambiguous.

### Keep HTML Helper Slots During The Transition

Theme V2 receives both structured collections and some pre-rendered HTML helpers such as navigation, page header, and backlinks. This made it possible to ship the new system without first redesigning every downstream presentation surface.

The trade-off is a slightly mixed contract. It is practical now, but the system may want to converge further toward structured-only data later.

## Current Limitations

- Theme bundles are project-local only; layering and inheritance are not implemented.
- Partial discovery is flat under `partials/` and does not recurse.
- Theme token CSS emission only serializes scalar string/number/bool values.
- Some presentation concerns, especially backlinks and navigation, still exist as pre-rendered HTML helpers alongside structured collection data.
- Theme V2 still relies on documented conventions rather than a separate theme-author CLI or schema tool.

## Next Implementation Steps

1. Decide whether layered Theme V2 bundles are worth adding or whether project-local bundles remain the intended model.
2. Write focused theme-author documentation for the stable `site` / `page` / `collections` / `slots` contract.
3. Decide whether recursive partial lookup is useful enough to standardize.
4. If richer theme ergonomics are needed, consider moving more helper HTML toward structured renderable data.
5. Continue extending `check` only for clearly build-affecting theme errors.

## Validation Completed

Focused verification completed during this milestone included:

- `moon test "src/runtime/runtime_test.mbt" -F "*falls back to built-in theme v2 bundle*"`
- `moon test "src/cli/cli_test.mbt" -F "*runtime cli build uses built-in theme v2 fallback*"`
- `moon test "src/runtime/runtime_test.mbt" -i 6-10`
- `moon test "src/cli/cli_test.mbt" -i 32-42`

Full-repo verification is still required as part of final branch completion:

- `moon test`
- `moon check`
- `moon info && moon fmt`
