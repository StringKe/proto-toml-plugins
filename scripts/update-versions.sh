#!/usr/bin/env bash
# Fetch latest upstream version for every plugin and update:
#   - tests/known-good.json
#   - README.md (the .prototools example block)
#
# Usage: ./scripts/update-versions.sh [plugin ...]
# No args -> all plugins. Args -> only listed plugins.
#
# Requires: gh (authenticated), jq, sed.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KNOWN_GOOD="$ROOT/tests/known-good.json"
README="$ROOT/README.md"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}
need_cmd gh
need_cmd jq

# Parse `resolve.git-url` and optional `resolve.git-tag-pattern` from a plugin TOML.
extract_git_url() {
  awk -v key="git-url" '
    /^\[resolve\]/ { in_section = 1; next }
    /^\[/ && !/^\[resolve\]/ { in_section = 0 }
    in_section && $1 == key {
      sub(/^[^=]*=[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$1"
}

extract_tag_pattern() {
  awk -v key="git-tag-pattern" '
    /^\[resolve\]/ { in_section = 1; next }
    /^\[/ && !/^\[resolve\]/ { in_section = 0 }
    in_section && $1 == key {
      sub(/^[^=]*=[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$1"
}

# Convert a git tag (e.g. "v1.2.3", "jq-1.7.1", "apps_v1.67.0") into the bare version
# string that proto would resolve to, using the plugin's git-tag-pattern.
# Falls back to stripping a leading "v" if no pattern is set.
extract_version() {
  local tag="$1" pattern="$2"
  if [[ -z "$pattern" ]]; then
    echo "${tag#v}"
    return
  fi
  # Strip the prefix matched by the pattern before any capture group / .*
  # Common forms: ^v(.*)$, ^jq-(.*)$, ^apps_v(?<version>.*)$, ^(?:v|kubernetes-)(.*)$
  # We can rely on `sed -E` for ERE; convert pattern to ERE-friendly form.
  local ere="$pattern"
  ere="${ere//\(\?<version>/(}"   # named group -> plain group
  ere="${ere//\(\?:/(}"           # non-capturing -> capturing (harmless)
  printf '%s' "$tag" | sed -En "s/${ere}/\\1/p"
}

# repo "owner/name" from a github URL.
owner_repo() {
  local url="${1#https://github.com/}"
  url="${url%.git}"
  url="${url%/}"
  printf '%s' "$url"
}

# Resolve latest version for one plugin. Echoes the version or nothing on failure.
latest_version_for() {
  local plugin="$1"
  local toml="$ROOT/plugins/${plugin}.toml"
  [[ -f "$toml" ]] || return 1

  local git_url
  git_url="$(extract_git_url "$toml")"
  [[ -n "$git_url" ]] || return 1

  case "$git_url" in
    https://github.com/*) ;;
    *) return 1 ;;  # non-github resolvers (rare) skipped here
  esac

  local repo
  repo="$(owner_repo "$git_url")"

  local tag pattern
  tag=$(gh api "repos/${repo}/releases/latest" --jq '.tag_name' 2>/dev/null || true)
  if [[ -z "$tag" || "$tag" == "null" ]]; then
    # Fallback: pick the newest non-prerelease release.
    tag=$(gh api "repos/${repo}/releases?per_page=20" \
      --jq '[.[] | select(.prerelease==false and .draft==false)][0].tag_name' 2>/dev/null || true)
  fi
  [[ -n "$tag" && "$tag" != "null" ]] || return 1

  pattern="$(extract_tag_pattern "$toml")"
  local ver
  ver="$(extract_version "$tag" "$pattern")"
  [[ -n "$ver" ]] || return 1
  printf '%s' "$ver"
}

update_known_good_in_place() {
  local plugin="$1" version="$2"
  local tmp
  tmp="$(mktemp)"
  jq --arg p "$plugin" --arg v "$version" '.[$p] = $v' "$KNOWN_GOOD" > "$tmp"
  mv "$tmp" "$KNOWN_GOOD"
}

update_readme_in_place() {
  local plugin="$1" version="$2"
  # Only update lines INSIDE the first ```toml … ``` fenced block, and only
  # the bare-version lines (before the [plugins] header inside that block).
  # The [plugins] table's URL lines must stay untouched.
  local tmp
  tmp="$(mktemp)"
  awk -v p="$plugin" -v v="$version" '
    BEGIN { in_block = 0; done_block = 0; past_plugins = 0 }
    !done_block && /^```toml[[:space:]]*$/ { in_block = 1; print; next }
    in_block && /^```[[:space:]]*$/ { in_block = 0; done_block = 1; print; next }
    in_block && /^\[plugins\][[:space:]]*$/ { past_plugins = 1; print; next }
    in_block && !past_plugins {
      pat = "^[[:space:]]*" p "[[:space:]]*=[[:space:]]*\""
      if (match($0, pat)) {
        prefix = substr($0, 1, RSTART + RLENGTH - 1)
        rest = substr($0, RSTART + RLENGTH)
        # rest looks like:  <oldversion>"<maybe trailing>
        i = index(rest, "\"")
        if (i > 0) {
          tail = substr(rest, i)
          print prefix v tail
          next
        }
      }
    }
    { print }
  ' "$README" > "$tmp"
  mv "$tmp" "$README"
}

main() {
  local plugins=("$@")
  if [[ ${#plugins[@]} -eq 0 ]]; then
    while IFS= read -r f; do
      plugins+=("$(basename "$f" .toml)")
    done < <(find "$ROOT/plugins" -name '*.toml' | sort)
  fi

  local changed=0 checked=0 skipped=0
  for plugin in "${plugins[@]}"; do
    checked=$((checked + 1))
    local cur new
    cur=$(jq -r --arg p "$plugin" '.[$p] // empty' "$KNOWN_GOOD")
    if ! new=$(latest_version_for "$plugin"); then
      printf 'SKIP %-20s (could not resolve)\n' "$plugin"
      skipped=$((skipped + 1))
      continue
    fi
    if [[ "$cur" == "$new" ]]; then
      printf 'OK   %-20s %s\n' "$plugin" "$cur"
      continue
    fi
    printf 'BUMP %-20s %s -> %s\n' "$plugin" "${cur:-<unset>}" "$new"
    update_known_good_in_place "$plugin" "$new"
    update_readme_in_place "$plugin" "$new"
    changed=$((changed + 1))
  done

  printf '\nChecked %d, bumped %d, skipped %d.\n' "$checked" "$changed" "$skipped"
}

main "$@"
