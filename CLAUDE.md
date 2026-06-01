# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A catalogue of [Proto](https://moonrepo.dev/proto) TOML plugins for infra/devex CLIs (Kubernetes, HashiCorp stack, security scanners, GitOps, etc.). Each `plugins/*.toml` is a standalone schema-driven plugin consumed by Proto via `file://` (local) or raw GitHub URL (downstream users). There is **no build step and no source code** — the entire deliverable is the TOML files plus a verification harness.

## Common commands

```sh
./scripts/verify.sh                 # verify all plugins against tests/known-good.json (Unix)
./scripts/verify.sh <plugin>        # verify a single plugin
./scripts/verify.sh --latest        # verify all using @latest (what daily CI runs)
./scripts/verify.ps1 [-Target X] [-Latest]    # Windows equivalent
./scripts/update-versions.sh [plugin...]      # bump tests/known-good.json + README from GitHub API
```

verify scripts:
1. Cache a private `proto` binary in `$TMPDIR/proto-verify-cache/` (PowerShell: `$env:TEMP\proto-verify-cache`).
2. For each plugin, create a fresh `$PROTO_HOME` under `$TMPDIR/proto-verify-run-$PID/<plugin>/` with a `.prototools` referencing the local TOML.
3. `proto install` the pinned version, then run a smoke test that walks `tools/<plugin>/<ver>/` first and falls back to `shims/<plugin>` last.
4. Print `PASS`/`FAIL` per plugin with the resolved binary path.

## Repository layout

- `plugins/<name>.toml` — the actual plugins. Filename (without `.toml`) is the plugin id used by `proto`.
- `scripts/verify.sh` / `verify.ps1` — per-OS verifiers (intentionally separate, no shared core).
- `scripts/update-versions.sh` — pulls the latest GitHub release tag for every plugin and rewrites `tests/known-good.json` plus the version block in `README.md`.
- `tests/known-good.json` — flat `{plugin: version}` map. Single source of truth for pinned versions.
- `.github/workflows/` — three independent workflows, one job per concern (see below).

## CI workflows (three separate files, each does one thing)

- `verify-plugins.yml` — runs on push / PR / `workflow_dispatch`. Matrix `ubuntu-latest`, `macos-14`, `windows-latest`. `windows-latest` is `continue-on-error: true` (intentional — upstream Windows assets are routinely missing or named weirdly; we still want the overall job green).
- `verify-latest.yml` — daily cron at `15 4 * * *` UTC plus `workflow_dispatch`. Runs `--latest` so upstream release-mechanism changes (renamed assets, switched archive format, dropped a checksum file) surface before downstream users hit them.
- `update-versions.yml` — cron `30 5 */3 * *` UTC plus `workflow_dispatch`. Runs `scripts/update-versions.sh`, opens a PR via `peter-evans/create-pull-request` if anything moved. The PR then triggers `verify-plugins.yml`, so the bump is auto-verified before merge.

## Plugin TOML conventions

Every plugin follows the same shape — copy a passing existing plugin rather than writing from scratch.

- `name`, `type = "cli"` at top.
- `[platform.linux/macos/windows]` blocks set `download-file`. Use `{version}` and `{arch}` templates; `{arch}` is rewritten by `[install.arch]`.
- `[install]` sets `download-url` (typically `https://github.com/<org>/<repo>/releases/download/v{version}/{download_file}`) and `unpack = true|false`.
- If the archive contains the binary inside a subdirectory, set `archive-prefix` on the platform block.
- If the binary inside the archive is named differently than the plugin id (`aliyun-cli` ships `aliyun`, `tektoncd-cli` ships `tkn`, `oxlint` ships `oxlint-<triple>`), use `[install.exes.<plugin-id>] exe-path = "<real-binary>" primary = true` so proto creates the shim under the plugin id name.
- `[resolve] git-url` is required. `git-tag-pattern` defaults to `^v?(.*)$`; supply a custom regex when tags don't follow that shape (e.g. `^jq-(\d+\.\d+\.\d+)$` for jq, `^apps_v(?<version>.*)$` for Oxc, `^(?:v|kubernetes-)(.*)$` for kubectl).
- `kubectl.toml` is the canonical non-GitHub example (downloads from `dl.k8s.io` with `unpack = false`).

### Canonical reference plugins (copy these shapes)

| Pattern | Reference | Notes |
|---------|-----------|-------|
| Single bare binary tarball | `air.toml` | Simplest case |
| Archive with subdirectory prefix | `golangci-lint.toml` | Needs `archive-prefix` |
| Binary renamed inside archive | `aliyun-cli.toml`, `tektoncd-cli.toml` | Needs `[install.exes.<id>]` |
| Different ext per OS (Windows `.zip` vs Unix `.tar.gz`) | `kubectx.toml`, `lazygit.toml` | Most upstreams do this |
| Tag pattern filters old non-semver tags | `jq.toml` | `^jq-(\d+\.\d+\.\d+)$` |
| Special tag prefix | `oxlint.toml`, `oxfmt.toml` | `apps_v{version}` |
| Non-GitHub download | `kubectl.toml` | `unpack = false`, direct CDN |
| No Windows asset upstream | `operator-sdk.toml` | Map Windows to Linux blob — Windows job is continue-on-error |
| External mirror (upstream has no macOS) | `eza.toml` | Uses cargo-prebuilt mirror, resolver still on upstream |

### Asset-naming traps (each cost one CI cycle)

These caught us during the asset-name audit. Always run `gh release view <tag> -R <owner>/<repo> --json assets --jq '.assets[].name'` for a real version before guessing.

- **OS labels differ**: most use `linux` / `darwin` / `windows`; some use `Linux` / `Darwin` / `Windows` (eksctl, tektoncd-cli, lazygit); kubeconform uses `darwin` not `macos`; aliyun-cli uses `macosx`; operator-sdk uses `darwin` not `macos`.
- **Arch label drift**: GitHub releases split between `amd64` / `arm64` and `x86_64` / `aarch64` essentially at random. kubectx, kubens, crane, lazygit, tektoncd-cli all use `x86_64`. trivy uses `64bit` / `ARM64`. gitleaks uses `x64`. Set `[install.arch]` accordingly.
- **Windows extension swap**: many tools ship `.tar.gz` on Linux/macOS and `.zip` on Windows.
- **Version-in-filename pattern flip**: aliyun-cli puts the version between OS and arch (`aliyun-cli-linux-3.3.18-amd64`), most others put it first or last.
- **Checksum file with no derivable algorithm**: yq's `checksums` file confuses proto (`Unknown checksum algorithm`). Easiest fix: omit `checksum-url` entirely so proto skips checksum verification.
- **Tag mismatches**: a `tests/known-good.json` pin that doesn't exist upstream returns "Failed to resolve" or 404 — verify the tag exists before pinning.

## verify.sh / verify.ps1 invariants (don't regress these)

- **Binary discovery walks `tools/<plugin>/<ver>/` first**, not `shims/`. proto-shim depends on environment that an isolated `PROTO_HOME` may not set up correctly, so the shim can silently fail with `program not found`. Real binary first, shim as last resort.
- **Smoke test iterates ALL candidates.** A bad shim must not mask a working real binary. `verify.sh` collects every executable candidate then tries each through `--version` / `version` / `--help` until one returns exit code 0.
- **PowerShell smoke test requires `$LASTEXITCODE -eq 0`**, not just non-empty output. Many CLIs print `Error: unknown flag: --version` to stderr but exit non-zero — that's NOT a pass.
- **Skip macOS metadata files (`._*`) when scanning Windows archives.** Some upstream tarballs (d2) carry AppleDouble files that PowerShell's `&` operator chokes on.
- **macOS bash 3.2 / BSD `find` only.** No `mapfile`, no `${var,,}`, no GNU-only flags. `-mindepth` / `-maxdepth` exist but count from the search root: `$PROTO_HOME/tools/<plugin>/<ver>` is depth 3, not 4 — get this wrong and your last-resort discovery silently misses the binary.
- **Windows `file://` URIs**: proto on Windows rejects `file:///D:/path/to/plugin.toml` with `plugin::loader::file::missing`. `verify.ps1` copies the plugin TOML beside `.prototools` and uses a relative `file://./<plugin>.toml` URL.
- **`proto.ps1` installer takes version as positional arg only.** Setting `--dir` makes the installer treat the dir path as a version string and produces a 404 URL. Use `$env:PROTO_HOME` instead.
- **Per-OS verifier split is deliberate** (commit `ca99eba`). Do not refactor into a single cross-platform script.

## update-versions.sh

- Reads each plugin's `[resolve] git-url` + optional `git-tag-pattern` from the TOML, calls `gh api repos/<owner>/<name>/releases/latest`, strips the prefix matched by the tag pattern.
- Rewrites `tests/known-good.json` with `jq`.
- Rewrites `README.md` with `awk` scoped to the **first** ```` ```toml ```` fenced block and stops at the `[plugins]` header, so the URL lines below stay untouched. A naive `sed` on the whole file replaces those URLs and silently breaks the example.
- Non-GitHub git-urls (e.g. kubectl's `https://github.com/kubernetes/kubectl` works fine, but real non-github resolvers are skipped) print `SKIP <name>`.

## Adding or changing a plugin

1. Run `gh release view <tag> -R <owner>/<repo> --json assets --jq '.assets[].name'` and READ THE ASSET NAMES. Do not guess.
2. Write/edit `plugins/<name>.toml` modelled on the closest reference plugin above.
3. Add an entry to `tests/known-good.json` with a real released version.
4. Run `./scripts/verify.sh <name>` locally until PASS.
5. Add the plugin row to the table in `README.md` and the example `.prototools` block.
6. Push. `verify-plugins.yml` only runs on changes to `plugins/`, `scripts/verify.*`, `tests/known-good.json`, or the workflow itself — merge after green.

## Excluded tools (don't try to add these)

- AWS CLI / Azure CLI / gcloud — complex installers (python bundles, .pkg, post-install scripts). Use `brew` or the official installers.
- `pre-commit` — Python package, no static binary. Use `pipx`/`brew`.
- `vite` / `rolldown` / `vitest` / `tsdown` — npm-distributed, no standalone GitHub release binary. Use `vp` (Vite+) which IS pluginned.
