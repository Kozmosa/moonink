# username/moonink

## MoonInk CLI Scaffold

This repository is currently in the early implementation phase.

Implemented pieces:

- `moonink help`
- `moonink new [project-name]`
- `moonink build`
- `moonink serve`

Current status:

- command parsing is wired through the root package;
- `cmd/main` now reads real runtime argv;
- `new` has both a pure planning path for tests and a real runtime path that creates a starter project on disk;
- starter-project filesystem IO is handled through `moonbitlang/x/fs`;
- the starter scaffold writes `moonink.toml`, sample docs/articles content, theme overrides, and `.gitignore`;
- `build` now implements phase 1a input handling: real `moonink.toml` loading, minimal validation, and recursive Markdown discovery under `docs/` and `articles/`;
- rendering and `serve` still remain placeholder modules after the input stage;
- frontmatter parsing, Markdown rendering, routing, and search are not implemented yet.
