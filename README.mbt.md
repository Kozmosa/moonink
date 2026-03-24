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
- `cmd/main` is a thin executable wrapper;
- `new` now produces a concrete starter-project plan for a sample MoonInk site layout;
- `build` and `serve` still call dummy placeholder modules;
- no real config parsing, content discovery, rendering, or dev server exists yet.
