#!/usr/bin/env bash
# Robust local verification for all (or one) proto TOML plugins.
# Usage:
#   ./scripts/verify.sh                  # test all using tests/known-good.json
#   ./scripts/verify.sh mkcert           # test single plugin (latest if not in known-good)
#   ./scripts/verify.sh --latest         # test all with @latest (daily CI mode)
#   ./scripts/verify.sh mkcert --latest  # single with latest
#
# Requirements: curl, tar, jq (for known-good), internet.
# Proto is installed on-demand into a temp dir (cached across runs in /tmp/proto-verify-cache).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KNOWN_GOOD="$ROOT/tests/known-good.json"
PROTO_CACHE="/tmp/proto-verify-cache"
PROTO_BIN="$PROTO_CACHE/bin/proto"
if [[ ! -x "$PROTO_BIN" && -x "$PROTO_CACHE/bin/proto.exe" ]]; then
  PROTO_BIN="$PROTO_CACHE/bin/proto.exe"
fi
TEMP_BASE="${TMPDIR:-/tmp}/proto-verify-run-$$"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "$*" >&2; }
pass() { log "${GREEN}PASS${NC} $*"; }
fail() { log "${RED}FAIL${NC} $*"; }

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

install_proto() {
  if [[ -x "$PROTO_BIN" ]]; then
    return 0
  fi
  mkdir -p "$PROTO_CACHE"
  log "Installing proto into $PROTO_CACHE ..."
  curl -fsSL --max-time 60 https://moonrepo.dev/install/proto.sh | \
    PROTO_HOME="$PROTO_CACHE" bash -s -- --yes 2>&1 | tail -3
  if [[ ! -x "$PROTO_BIN" ]]; then
    log "Failed to install proto"
    exit 1
  fi
  "$PROTO_BIN" --version
}

get_version() {
  local plugin="$1"
  local use_latest="${2:-false}"

  if [[ "$use_latest" == "true" ]]; then
    echo "latest"
    return
  fi

  if [[ -f "$KNOWN_GOOD" ]] && command -v jq >/dev/null 2>&1; then
    local ver
    ver=$(jq -r --arg p "$plugin" '.[$p] // empty' "$KNOWN_GOOD" 2>/dev/null || true)
    if [[ -n "$ver" && "$ver" != "null" ]]; then
      echo "$ver"
      return
    fi
  fi

  echo "latest"
}

smoke_test() {
  local bin="$1"
  local name="$2"

  # On Windows, ensure we have a .exe if needed
  if [[ "${RUNNER_OS:-}" == "Windows" && ! -f "$bin" && -f "${bin}.exe" ]]; then
    bin="${bin}.exe"
  fi

  if [[ ! -f "$bin" ]]; then
    echo "binary not found: $bin"
    return 1
  fi

  # Try common version flags (some tools print to stderr)
  local out
  if out=$("$bin" --version 2>&1 | head -1); then
    [[ -n "$out" ]] && { echo "$out"; return 0; }
  fi
  if out=$("$bin" version 2>&1 | head -1); then
    [[ -n "$out" ]] && { echo "$out"; return 0; }
  fi
  if out=$("$bin" --help 2>&1 | head -3); then
    [[ -n "$out" ]] && { echo "$out"; return 0; }
  fi

  # Last resort: just check that the binary runs without crashing immediately
  if "$bin" --help > /dev/null 2>&1 || "$bin" -h > /dev/null 2>&1; then
    echo "runs (help succeeded)"
    return 0
  fi

  echo "no standard version/help output and basic execution test failed"
  return 1
}

verify_one() {
  local plugin="$1"
  local use_latest="$2"
  local toml="$ROOT/plugins/${plugin}.toml"

  if [[ ! -f "$toml" ]]; then
    fail "$plugin: no such plugin file"
    return 1
  fi

  local ver
  ver=$(get_version "$plugin" "$use_latest")

  local run_dir="$TEMP_BASE/$plugin"
  rm -rf "$run_dir"
  mkdir -p "$run_dir"
  cd "$run_dir"

  local cfg=".prototools"
  cat > "$cfg" <<EOF
$plugin = "$ver"

[plugins]
$plugin = "file://$toml"
EOF

  local phome="$run_dir/proto-home"
  mkdir -p "$phome"

  # Use a clean proto home for this test
  export PROTO_HOME="$phome"

  if ! "$PROTO_BIN" plugin add "$plugin" "file://$toml" -c local --yes >/dev/null 2>&1; then
    fail "$plugin@$ver : plugin add failed"
    return 1
  fi

  echo "  [debug] Attempting proto install for $plugin@$ver on $(uname -s) $(uname -m)" >&2
  INSTALL_OUTPUT=$("$PROTO_BIN" install -c local -y "$plugin" 2>&1)
  INSTALL_EXIT=$?
  echo "$INSTALL_OUTPUT" >&2
  if [[ $INSTALL_EXIT -ne 0 ]]; then
    echo "::error::Plugin $plugin@$ver failed to install on $(uname -s). Full output above. This is the smoking gun for the Windows failure." >&2
    # Also print to stdout so it appears directly in the GitHub step summary
    echo "CRITICAL FAILURE on $(uname -s): $plugin@$ver install failed."
    echo "Last 30 lines of proto output:"
    echo "$INSTALL_OUTPUT" | tail -30
    fail "$plugin@$ver : install failed"
    return 1
  fi

  # Collect candidate binaries in priority order. We try each candidate's
  # smoke_test in turn so that a broken shim doesn't mask a working real
  # binary that lives under a different name (e.g. aliyun-cli ships `aliyun`,
  # tektoncd-cli ships `tkn`, oxlint ships `oxlint-<triple>`).
  local candidates=()
  candidates+=("$(find "$phome" -type f -path "*/tools/$plugin/*/$plugin" 2>/dev/null | head -1 || true)")
  candidates+=("$(find "$phome" -type f -path "*/tools/$plugin/*/$plugin.exe" 2>/dev/null | head -1 || true)")

  # Every executable file under tools/$plugin/* that isn't a known non-binary
  # artifact. Catches plugins whose binary name differs from the plugin id.
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$(basename "$f")" in
      checksums*|CHECKSUM*|LICENSE*|README*|*.md|*.txt|*.json|*.toml|*.sha256|*.sig|*.asc|.last-used) continue ;;
    esac
    [[ -x "$f" ]] && candidates+=("$f")
  done < <(find "$phome" -type f -path "*/tools/$plugin/*" 2>/dev/null)

  # Shims as a last resort — proto-shim depends on env that may not be set up.
  candidates+=("$(find "$phome" -type f -path "*/shims/$plugin" 2>/dev/null | head -1 || true)")
  candidates+=("$(find "$phome" -type f -path "*/shims/$plugin.exe" 2>/dev/null | head -1 || true)")
  candidates+=("$(find "$phome" -type f \( -name "$plugin" -o -name "${plugin}.exe" \) 2>/dev/null | head -1 || true)")

  local first_bin="" smoke_out="" last_smoke_out=""
  for c in "${candidates[@]}"; do
    [[ -z "$c" || ! -f "$c" ]] && continue
    [[ -z "$first_bin" ]] && first_bin="$c"
    if smoke_out=$(smoke_test "$c" "$plugin" 2>&1); then
      pass "$plugin@$ver : $smoke_out  ($c)"
      return 0
    fi
    last_smoke_out="$smoke_out"
  done

  if [[ -z "$first_bin" ]]; then
    fail "$plugin@$ver : binary not found after install"
  else
    fail "$plugin@$ver : smoke test failed - $last_smoke_out"
  fi
  return 1
}

main() {
  need_cmd curl
  need_cmd tar

  local target=""
  local use_latest=false

  for arg in "$@"; do
    case "$arg" in
      --latest) use_latest=true ;;
      *) target="$arg" ;;
    esac
  done

  install_proto

  local failures=0
  local total=0

  if [[ -n "$target" ]]; then
    total=1
    if ! verify_one "$target" "$use_latest"; then
      failures=1
    fi
  else
    # Test all plugins that have a .toml
    while IFS= read -r toml; do
      local p
      p=$(basename "$toml" .toml)
      total=$((total + 1))
      if ! verify_one "$p" "$use_latest"; then
        failures=$((failures + 1))
      fi
    done < <(find "$ROOT/plugins" -name '*.toml' | sort)
  fi

  log ""
  if [[ $failures -eq 0 ]]; then
    log "${GREEN}All $total plugins verified successfully.${NC}"
    exit 0
  else
    log "${RED}$failures / $total plugins failed.${NC}"
    exit 1
  fi
}

main "$@"
