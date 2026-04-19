#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
artifacts_dir="${repo_root}/artifacts/release"
staged_binary="${artifacts_dir}/moonink"

cd "${repo_root}"

python3 scripts/generate_builtin_theme_bundle.py
moon build src/cmd/main --target native --release --strip

mkdir -p "${artifacts_dir}"
cp "_build/native/release/build/cmd/main/main.exe" "${staged_binary}"
chmod +x "${staged_binary}"

scripts/validate_detached_release.sh "${staged_binary}"

echo "Release binary staged at ${staged_binary}"
