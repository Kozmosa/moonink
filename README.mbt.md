# username/moonink

## MoonInk CLI Scaffold

This repository is currently in the cold-start scaffold phase.

Implemented placeholders:

- `moonink help`
- `moonink new [project-name]`
- `moonink build`
- `moonink serve`

Current status:

- command parsing is wired through the root package;
- `cmd/main` is a thin executable wrapper;
- `new`, `build`, and `serve` call dummy placeholder modules;
- no real config parsing, content discovery, rendering, or dev server exists yet.
