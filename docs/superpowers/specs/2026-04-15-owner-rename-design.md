# 2026-04-15 MoonBit module owner rename design

## Goal

Replace the placeholder MoonBit owner prefix `username/` with the real owner prefix `kozmosa/` everywhere that defines the actual module identity or user-visible primary package title.

## Scope

This change is intentionally limited to the authoritative module/package metadata and import paths used by the build.

### In scope

- Root module name in `moon.mod.json`
- Native preview subproject module name and dependency reference in `native-serve/moon.mod.json`
- MoonBit import paths in `src/**/moon.pkg`
- Primary README title in `README.mbt.md`

### Out of scope

- Historical design docs and plans under `docs/`
- Worklog entries
- Example text that is not part of the active module identity
- Any behavioral changes to the CLI, build, or runtime

## Approaches considered

### A. Minimal authoritative rename (chosen)

Update only the files that currently define or surface the real package/module identity.

**Why chosen:** This fixes the visible naming problem with the smallest safe diff and avoids rewriting historical records.

### B. Global text replacement

Replace all `username/moonink` strings across the repository.

**Why not chosen:** This would create noisy edits in historical specs and plans that are not part of the running package identity.

## File plan

- Modify `moon.mod.json`
  - Change module name from `username/moonink` to `kozmosa/moonink`
- Modify `native-serve/moon.mod.json`
  - Change native subproject name from `username/moonink-native-serve` to `kozmosa/moonink-native-serve`
  - Change dependency key from `username/moonink` to `kozmosa/moonink`
- Modify `src/runtime/moon.pkg`
  - Update import path to `kozmosa/moonink/core`
- Modify `src/docflow/moon.pkg`
  - Update import path to `kozmosa/moonink/core`
- Modify `src/cmd/main/moon.pkg`
  - Update import path to `kozmosa/moonink/cli`
- Modify `src/cli/moon.pkg`
  - Update import paths to `kozmosa/moonink/core`, `kozmosa/moonink/runtime`, and `kozmosa/moonink/docflow`
- Modify `README.mbt.md`
  - Change title from `# username/moonink` to `# kozmosa/moonink`

## Expected outcome

After the rename:

- MoonBit module metadata will use the real owner-qualified name
- Internal package imports will resolve through `kozmosa/moonink/...`
- The README will no longer advertise the placeholder owner name
- Historical docs will remain untouched

## Verification

Because this is a metadata/import-path rename, verification should confirm both textual correctness and toolchain acceptance.

- Search for remaining `username/moonink` references in the authoritative files above
- Run `moon check`
- If `moon check` passes, the rename is considered valid

## Risks

The main risk is missing one import or dependency reference and leaving the workspace in a broken state. Limiting the change to the authoritative files and verifying with `moon check` keeps this risk low.
