#!/usr/bin/env bash

set -euo pipefail

REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-gh-pages}"
CONFIG_PATH="${CONFIG_PATH:-docs/moonink/moonink.json}"
TARGET="${TARGET:-native}"
MOONINK_BIN="${MOONINK_BIN:-}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
GENERATE_EMBEDDED_THEME="${GENERATE_EMBEDDED_THEME:-1}"
BASE_PATH="${BASE_PATH:-}"
SKIP_BUILD="${SKIP_BUILD:-0}"
DRY_RUN="${DRY_RUN:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_ABS="${REPO_ROOT}/${CONFIG_PATH}"
DOCS_ROOT="$(cd "$(dirname "${CONFIG_ABS}")" && pwd)"
DIST_DIR="${DOCS_ROOT}/dist"
SOURCE_COMMIT="$(git -C "${REPO_ROOT}" rev-parse --short HEAD)"

WORKTREE_DIR=""
WORKTREE_ADDED=0

log() {
  printf '[publish-moonink-docs] %s\n' "$*"
}

die() {
  log "error: $*"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

run_moonink() {
  if [[ -n "${MOONINK_BIN}" ]]; then
    "${MOONINK_BIN}" "$@"
  else
    moon run src/cmd/main --target "${TARGET}" -- "$@"
  fi
}

run_moonink_checked() {
  local step="$1"
  local success_pattern="$2"
  shift 2

  local output_file
  output_file="$(mktemp "${TMPDIR:-/tmp}/moonink-${step}.XXXXXX.log")"

  set +e
  run_moonink "$@" >"${output_file}" 2>&1
  local exit_code=$?
  set -e

  cat "${output_file}"

  if [[ ${exit_code} -ne 0 ]]; then
    rm -f "${output_file}"
    die "${step} failed with exit code ${exit_code}"
  fi

  if grep -Eq '(^failed:)|(^Error: )' "${output_file}"; then
    rm -f "${output_file}"
    die "${step} reported a Moon/MoonInk build failure"
  fi

  if ! grep -Eq "${success_pattern}" "${output_file}"; then
    rm -f "${output_file}"
    die "${step} did not emit the expected success marker"
  fi

  rm -f "${output_file}"
}

resolve_base_path() {
  "${PYTHON_BIN}" - "${CONFIG_ABS}" "${BASE_PATH}" <<'PY'
import json
import sys
from urllib.parse import urlparse

config_path = sys.argv[1]
override = sys.argv[2].strip()

def normalize(value: str) -> str:
    if not value:
        return ""
    path = urlparse(value).path if "://" in value else value
    if not path or path == "/":
        return ""
    normalized = path.strip()
    if not normalized.startswith("/"):
        normalized = "/" + normalized
    normalized = normalized.rstrip("/")
    return normalized

if override:
    print(normalize(override))
    raise SystemExit(0)

with open(config_path, "r", encoding="utf-8") as fh:
    config = json.load(fh)

site_url = config.get("site_url") or ""
print(normalize(site_url))
PY
}

rewrite_publish_base_path() {
  local target_root="$1"
  local base_path="$2"

  [[ -n "${base_path}" ]] || return 0

  "${PYTHON_BIN}" - "${target_root}" "${base_path}" <<'PY'
import json
import re
import sys
from pathlib import Path

target_root = Path(sys.argv[1])
base_path = sys.argv[2].rstrip("/")

def prefix_root_path(path: str) -> str:
    if not path.startswith("/") or path.startswith("//"):
        return path
    if path == base_path or path.startswith(base_path + "/"):
        return path
    if path == "/":
        return base_path + "/"
    return base_path + path

html_attr_pattern = re.compile(r'(?P<attr>\b(?:href|src)=["\'])(?P<path>/[^"\']*)')
icon_link = f'<link rel="icon" href="{base_path}/moonink-badge.svg">'

for html_path in target_root.rglob("*.html"):
    text = html_path.read_text(encoding="utf-8")
    text = html_attr_pattern.sub(
        lambda m: m.group("attr") + prefix_root_path(m.group("path")),
        text,
    )
    if 'rel="icon"' not in text and "</head>" in text:
        text = text.replace("</head>", f"    {icon_link}\n  </head>", 1)
    html_path.write_text(text, encoding="utf-8")

search_index_path = target_root / "search-index.json"
if search_index_path.exists():
    search_index = json.loads(search_index_path.read_text(encoding="utf-8"))
    for item in search_index.get("items", []):
        url = item.get("url")
        if isinstance(url, str):
            item["url"] = prefix_root_path(url)
    search_index_path.write_text(
        json.dumps(search_index, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
PY
}

cleanup() {
  if [[ -n "${WORKTREE_DIR}" && "${WORKTREE_ADDED}" == "1" ]]; then
    git -C "${REPO_ROOT}" worktree remove --force "${WORKTREE_DIR}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${WORKTREE_DIR}" && -d "${WORKTREE_DIR}" ]]; then
    rm -rf "${WORKTREE_DIR}" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

require_cmd git
require_cmd "${PYTHON_BIN}"
if [[ "${SKIP_BUILD}" != "1" && -z "${MOONINK_BIN}" ]]; then
  require_cmd moon
fi

git -C "${REPO_ROOT}" remote get-url "${REMOTE}" >/dev/null 2>&1 || die "git remote \`${REMOTE}\` does not exist"
[[ -f "${CONFIG_ABS}" ]] || die "config file not found: ${CONFIG_PATH}"

cd "${REPO_ROOT}"

PUBLISH_BASE_PATH="$(resolve_base_path)"

if [[ "${SKIP_BUILD}" != "1" ]]; then
  if [[ -z "${MOONINK_BIN}" && "${GENERATE_EMBEDDED_THEME}" == "1" ]]; then
    log "refreshing embedded built-in theme bundle"
    "${PYTHON_BIN}" scripts/generate_builtin_theme_bundle.py
  fi

  log "running MoonInk check for ${CONFIG_PATH}"
  run_moonink_checked check '^\[check\] passed' check --config "${CONFIG_PATH}"

  log "removing previous docs output at ${DIST_DIR}"
  rm -rf "${DIST_DIR}"

  log "building docs for ${CONFIG_PATH}"
  run_moonink_checked build '^\[build\] completed' build --config "${CONFIG_PATH}"
else
  log "SKIP_BUILD=1; using existing build output at ${DIST_DIR}"
fi

[[ -d "${DIST_DIR}" ]] || die "build output directory not found: ${DIST_DIR}"

WORKTREE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/moonink-gh-pages.XXXXXX")"
git -C "${REPO_ROOT}" worktree add --detach "${WORKTREE_DIR}" HEAD >/dev/null 2>&1
WORKTREE_ADDED=1

if git -C "${REPO_ROOT}" ls-remote --exit-code --heads "${REMOTE}" "${BRANCH}" >/dev/null 2>&1; then
  log "fetching ${REMOTE}/${BRANCH}"
  git -C "${WORKTREE_DIR}" fetch "${REMOTE}" "${BRANCH}" >/dev/null
  git -C "${WORKTREE_DIR}" checkout --detach FETCH_HEAD >/dev/null 2>&1
else
  TMP_BRANCH="moonink-docs-publish-$(date +%s)-$$"
  log "creating new orphan publish history for ${REMOTE}/${BRANCH}"
  git -C "${WORKTREE_DIR}" switch --orphan "${TMP_BRANCH}" >/dev/null 2>&1
fi

find "${WORKTREE_DIR}" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf -- {} +
cp -a "${DIST_DIR}/." "${WORKTREE_DIR}/"
touch "${WORKTREE_DIR}/.nojekyll"

if [[ -n "${PUBLISH_BASE_PATH}" ]]; then
  log "rewriting published URLs for base path ${PUBLISH_BASE_PATH}"
  rewrite_publish_base_path "${WORKTREE_DIR}" "${PUBLISH_BASE_PATH}"
fi

git -C "${WORKTREE_DIR}" add --all

if git -C "${WORKTREE_DIR}" diff --cached --quiet --ignore-submodules --; then
  log "no publishable changes detected for ${REMOTE}/${BRANCH}"
  exit 0
fi

if [[ "${DRY_RUN}" == "1" ]]; then
  log "dry run enabled; staged publish payload for ${REMOTE}/${BRANCH}"
  git -C "${WORKTREE_DIR}" status --short
  exit 0
fi

log "creating publish commit from source ${SOURCE_COMMIT}"
git -C "${WORKTREE_DIR}" commit -m "docs: publish MoonInk docs from ${SOURCE_COMMIT}" >/dev/null

log "pushing ${DIST_DIR} to ${REMOTE}/${BRANCH}"
git -C "${WORKTREE_DIR}" push "${REMOTE}" HEAD:"refs/heads/${BRANCH}" >/dev/null

log "publish complete"
