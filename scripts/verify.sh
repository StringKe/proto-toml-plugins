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

  if [[ ! -x "$bin" ]]; then
    echo "binary not executable: $bin"
    return 1
  fi

  # Try common version flags
  local out
  if out=$("$bin" --version 2>&1 | head -1); then
    echo "$out"
    return 0
  fi
  if out=$("$bin" version 2>&1 | head -1); then
    echo "$out"
    return 0
  fi
  if out=$("$bin" --help 2>&1 | head -3); then
    echo "$out"
    return 0
  fi

  echo "no standard version/help output"
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

  if ! "$PROTO_BIN" install -c local -y "$plugin" 2>&1 | tail -5; then
    fail "$plugin@$ver : install failed"
    return 1
  fi

  # Find the installed binary (tools or shims)
  local bin
  bin=$(find "$phome" -type f -path "*/tools/$plugin/*/$plugin" 2>/dev/null | head -1 || true)
  if [[ -z "$bin" ]]; then
    bin=$(find "$phome" -type f -path "*/shims/$plugin" 2>/dev/null | head -1 || true)
  fi
  if [[ -z "$bin" ]]; then
    bin=$(find "$phome" -type f \( -name "$plugin" -o -name "${plugin}.exe" \) 2>/dev/null | head -1 || true)
  fi

  if [[ -z "$bin" ]]; then
    fail "$plugin@$ver : binary not found after install"
    return 1
  fi

  local smoke_out
  if smoke_out=$(smoke_test "$bin" "$plugin" 2>&1); then
    pass "$plugin@$ver : $smoke_out  ($bin)"
    return 0
  else
    fail "$plugin@$ver : smoke test failed - $smoke_out"
    return 1
  fi
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
