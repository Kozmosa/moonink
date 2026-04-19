#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_binary="${1:-}"

if [[ -z "${source_binary}" ]]; then
  echo "usage: scripts/validate_detached_release.sh <path-to-moonink-binary>" >&2
  exit 1
fi

if [[ ! -f "${source_binary}" ]]; then
  echo "binary not found: ${source_binary}" >&2
  exit 1
fi

workdir="$(mktemp -d)"
serve_pid=""

cleanup() {
  if [[ -n "${serve_pid}" ]]; then
    kill "${serve_pid}" >/dev/null 2>&1 || true
    wait "${serve_pid}" >/dev/null 2>&1 || true
  fi
  rm -rf "${workdir}"
}

trap cleanup EXIT

binary="${workdir}/moonink"
cp "${source_binary}" "${binary}"
chmod +x "${binary}"

if command -v strings >/dev/null 2>&1; then
  if strings "${binary}" | grep -Eq 'native-serve/moon\.mod\.json|moon run --manifest-path native-serve'; then
    echo "detached validation failed: binary still references repository-local native-serve runtime" >&2
    exit 1
  fi
fi

fetch_url() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${url}"
  else
    python3 - "${url}" <<'PY'
import sys
import urllib.request

with urllib.request.urlopen(sys.argv[1]) as response:
    sys.stdout.write(response.read().decode("utf-8"))
PY
  fi
}

mkdir -p "${workdir}/onboard-project"
(
  cd "${workdir}/onboard-project"
  "${binary}" onboard >/dev/null
)
if [[ ! -f "${workdir}/onboard-project/moonink.json" ]]; then
  echo "detached validation failed: onboard did not create moonink.json" >&2
  exit 1
fi

cp -R "${repo_root}/fixtures/v2/minimal" "${workdir}/site"

(
  cd "${workdir}/site"
  "${binary}" build >/dev/null
)
if [[ ! -f "${workdir}/site/dist/index.html" ]]; then
  echo "detached validation failed: build did not emit dist/index.html" >&2
  exit 1
fi
if [[ ! -f "${workdir}/site/dist/assets/moonink-default.css" ]]; then
  echo "detached validation failed: build did not emit embedded theme assets" >&2
  exit 1
fi

(
  cd "${workdir}/site"
  "${binary}" check >/dev/null
)

serve_log="${workdir}/serve.log"
(
  cd "${workdir}/site"
  "${binary}" serve --port 4173 >"${serve_log}" 2>&1
) &
serve_pid=$!

hello_html=""
for _ in $(seq 1 80); do
  if hello_html="$(fetch_url "http://127.0.0.1:4173/hello/index.html" 2>/dev/null)"; then
    break
  fi
  if ! kill -0 "${serve_pid}" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

if [[ "${hello_html}" != *"Hello World"* ]]; then
  echo "detached validation failed: serve did not return expected content" >&2
  cat "${serve_log}" >&2 || true
  exit 1
fi

kill "${serve_pid}" >/dev/null 2>&1 || true
wait "${serve_pid}" >/dev/null 2>&1 || true
serve_pid=""

echo "Detached validation passed for ${source_binary}"
