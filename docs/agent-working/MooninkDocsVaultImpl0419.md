# MoonInk Docs Vault Implementation 0419

## Goal And Scope

This task implemented the first standalone `docs/moonink/` user-documentation vault described in `MooninkDocsVaultSpec0419.md`.

Delivered scope:

- a self-contained `docs/moonink/` content root with its own `moonink.json`;
- the full first-pass page inventory across landing, getting-started, guide, examples, migration, reference, compare, and FAQ;
- demo content that exercises shipped linking, asset-copy, backlinks, page/article mix, and Obsidian-compatible authoring paths;
- validation that the vault passes source-run `check` and `build`.

Out of scope for this pass:

- hosting / deployment docs;
- direct documentation of search / RSS / canonical / OG as first-user features;
- custom project theme authoring inside the docs vault itself;
- release-artifact-specific install commands, because the repository still does not expose a published release artifact set.

## Files Changed

Primary source addition:

- `docs/moonink/`

Project-basis documentation updates:

- `docs/agent-working/worklog/20260419.md`
- `docs/agent-working/MooninkDocsVaultImpl0419.md`

## Design Decisions And Trade-Offs

- The docs vault stays on the built-in default theme instead of shipping a custom project theme. This keeps the vault aligned with the beginner-default path while still showcasing the current Theme V2-backed default experience.
- The content follows the shipped-only truth boundary from code/tests/fixtures rather than inheriting older README wording. In particular, `check` is positioned as a first-class validator, `serve` is marked native-only everywhere relevant, and `template_file` is kept in compatibility notes instead of the main path.
- The page inventory matches the spec, but some pages intentionally use concise prose to keep the first-pass vault buildable and navigable before adding more polish.
- The vault demonstrates WikiLink/backlink behavior using real internal links, but avoids ambiguous duplicate-basename WikiLinks such as the two `obsidian-vault.md` pages by using ordinary Markdown links where needed.
- The install page treats GitHub Releases as the formal binary distribution channel but keeps the instructions generic because concrete artifact names and shell snippets are not yet discoverable from a live release.
- The docs mention only the frontmatter/config/theme surface that the spec explicitly allowed for first-user documentation. Implemented-but-downscoped features such as `featured`, `pinned`, `search`, `toc`, and richer site-author config are not presented as the stable beginner contract.

## Validation

Executed from the repository root in the docs worktree:

- `moon run src/cmd/main -- check --config docs/moonink/moonink.json`
- `moon run src/cmd/main -- build --config docs/moonink/moonink.json`
- `moon info`
- `moon fmt`
- `moon test`

Observed result:

- `check` passed with zero diagnostics after removing literal unresolved WikiLink examples from prose;
- `build` completed successfully for the standalone vault;
- `moon info`, `moon fmt`, and `moon test` all completed successfully.

The generated `docs/moonink/dist/` output was used only for validation and was not kept in the branch.

## Current Limitations / Follow-Up

- The copy is functional and spec-aligned, but there is still room for wording polish and denser screenshot-like examples if the project later wants a more marketing-shaped docs experience.
- The binary install page will likely need a follow-up update once GitHub Releases expose real artifact names and platform-specific commands.
- The docs vault currently showcases built-in functionality through links, assets, and structure rather than through a broader curated homepage configuration; that can be revisited if the product direction wants the docs home to lean harder into the generated-surface capabilities.
