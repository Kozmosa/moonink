# Theme Nemophila Implementation 2026-04-19

## Goal

Add a first-version Theme V2 fixture that ports Nemophila’s visual shell into MoonInk without extending the current theme contract.

## Files Changed

- `fixtures/v2/theme_v2_nemophila/...`
- `src/cli/cli_test.mbt`
- `docs/agent-working/worklog/20260419.md`

## Decisions

- Kept implementation fixture-local instead of modifying `src/runtime/builtin_theme`
- Limited scope to `index`, `page`, and `article`
- Reused existing Theme V2 context and generated-surface page fallback
- Kept the port focused on palette, typography, navigation shell, hero, cards, and article chrome

## Current Limitations

- No music/search/comment integrations beyond linking to generated surfaces
- No extra Theme V2 context fields
- No packaging or distribution path yet
- Navigation currently mirrors the existing page collection rather than a Nemophila-specific nav model

## Next Steps

- Evaluate extracting the fixture into a distributable theme package
- Decide whether the mobile nav JS should stay or move to a CSS-only behavior
- Tighten the homepage identity card and featured-card art direction if higher-fidelity parity is needed
