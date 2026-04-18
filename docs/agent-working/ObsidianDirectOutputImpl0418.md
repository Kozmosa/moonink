# Obsidian Direct Output Implementation

## Goal

Make a typical Obsidian vault build directly with minimal config changes and no required frontmatter migration.

## Files changed

- `src/core/config.mbt`
- `src/core/content.mbt`
- `src/core/page_meta.mbt`
- `src/core/route.mbt`
- `src/core/theme_view_model.mbt`
- `src/runtime/content_discovery.mbt`
- `src/docflow/adapters.mbt`
- `src/docflow/wikilinker.mbt`
- `src/cli/cmd_build.mbt`
- `src/cli/cmd_onboard.mbt`

## Design decisions

- Reused the existing `config -> discovery -> docflow -> render` pipeline instead of adding an Obsidian-only mode.
- Added content-tree asset discovery and copying so vault attachments do not need relocation into `public/`.
- Added homepage inference only for root `index.*` and fallback root `README.md`.
- Kept backlink collection note-only while extending wikilink rewriting to discovered assets.
- Used resolved page metadata (`output_path`, `resolved_title`, `is_index`) to keep routing, navigation, and theme selection aligned.

## Current limitations

- Only image embeds render inline.
- Non-image embeds degrade to ordinary links.
- Plugin-specific formats such as Canvas and Dataview remain out of scope.

## Files changed in docs

- `docs/technical/03-Configuration-Design.md`
- `docs/technical/05-Routing-and-Navigation.md`
- `docs/technical/07-Linking-and-WikiLink.md`
- `docs/technical/10-CLI-and-Dev-Server.md`
- `docs/agent-working/MoonInkCliArch.md`

## Verification

- `moon test src/core`
- `moon test src/runtime`
- `moon test src/docflow`
- `moon test src/cli`
- full-suite verification recorded after the implementation finished
