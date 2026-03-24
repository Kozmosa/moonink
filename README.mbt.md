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
- the current real scaffold emission is supported on the JS runtime target (`moon run --target js cmd/main -- new <project-name>`);
- the starter scaffold writes `moonink.toml`, sample docs/articles content, theme overrides, and `.gitignore`;
- `build` and `serve` still call dummy placeholder modules;
- no real config parsing, content discovery, rendering, or dev server exists yet.
