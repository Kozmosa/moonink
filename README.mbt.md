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
- starter-project filesystem IO is now handled through `moonbitlang/x/fs`, so the runtime path no longer depends on custom JS FFI bridges;
- the starter scaffold writes `moonink.toml`, sample docs/articles content, theme overrides, and `.gitignore`;
- `build` and `serve` still call dummy placeholder modules;
- no real config parsing, content discovery, rendering, or dev server exists yet.
