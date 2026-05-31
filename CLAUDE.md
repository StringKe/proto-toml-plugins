# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A catalogue of [Proto](https://moonrepo.dev/proto) TOML plugins for infra/devex CLIs (Kubernetes, HashiCorp stack, security scanners, GitOps, etc.). Each `plugins/*.toml` is a standalone schema-driven plugin consumed by Proto via `file://` (local) or raw GitHub URL (downstream users). There is **no build step and no source code** — the entire deliverable is the TOML files plus a verification harness.

## Common commands

```sh
./scripts/verify.sh                 # verify all plugins against tests/known-good.json (Unix)
./scripts/verify.sh <plugin>        # verify a single plugin
./scripts/verify.sh --latest        # verify all using @latest (what daily CI runs)
./scripts/verify.sh <plugin> --latest
./scripts/verify.ps1 [-Target X] [-Latest]   # Windows equivalent
```

Both scripts:
1. Cache a private `proto` binary in `$TMPDIR/proto-verify-cache/`.
2. For each plugin, create a fresh `$PROTO_HOME` under `$TMPDIR/proto-verify-run-$PID/<plugin>/` with a `.prototools` referencing the local TOML via `file://`.
3. `proto install` the pinned version, then run `--version` / `version` / `--help` smoke tests.
4. Print `PASS`/`FAIL` per plugin with the resolved binary path.

`tests/known-good.json` is the single source of truth for stable pins; CI on PRs runs against it, daily cron at 04:15 UTC runs `--latest` to surface upstream breakage.

## Repository layout

- `plugins/<name>.toml` — the actual plugins. Filename (without `.toml`) is the plugin id used by `proto`.
- `scripts/verify.sh` / `verify.ps1` — per-OS verifiers (intentionally kept simple, no shared core).
- `tests/known-good.json` — flat `{plugin: version}` map. Update after a green `--latest` run.
- `.github/workflows/verify-plugins.yml` — matrix of `ubuntu-latest`, `macos-14`, `windows-latest`. `windows-latest` is `continue-on-error: true` (intentional, see commit `0ed96e2`).

## Plugin TOML conventions

Every plugin follows the same shape — copy a similar existing plugin rather than writing from scratch.

- `name`, `type = "cli"` at top.
- `[platform.linux/macos/windows]` blocks set `download-file`. Use `{version}` and `{arch}` templates; `{arch}` is rewritten by `[install.arch]` (`aarch64 = "arm64"` etc.).
- `[install]` sets `download-url` (typically `https://github.com/<org>/<repo>/releases/download/v{version}/{download_file}`) and `unpack = true|false`.
- If the archive contains the binary under a subdirectory, set `archive-prefix` on the platform block (e.g. `oxlint-{arch}-apple-darwin`).
- If the unpacked binary name differs from the plugin id (e.g. lazydocker ships as `lazydocker.exe` on Windows but `lazydocker` elsewhere), use `[install.exes.<name>] exe-path = "..."` with `primary = true`.
- `[resolve] git-url + git-tag-pattern` lets proto discover versions. Match the actual release tag format: most use `^v?(.*)$`, but some need custom captures (e.g. `^apps_v(?<version>.*)$` for Oxc, `^(?:v|kubernetes-)(.*)$` for kubectl).
- `kubectl.toml` is the canonical non-GitHub example (downloads from `dl.k8s.io` with `unpack = false`).

## Adding or changing a plugin

1. Write/edit `plugins/<name>.toml` modelled on a similar tool (single binary tarball -> `air.toml`; subdirectory archive -> `oxlint.toml`; renamed Windows exe -> `lazydocker.toml`; non-GitHub -> `kubectl.toml`).
2. Add an entry to `tests/known-good.json` with a real released version (check the upstream Releases page).
3. Run `./scripts/verify.sh <name>` locally until PASS.
4. Add the plugin row to the table in `README.md` and the example `.prototools` block.
5. CI on PR will run only the changed plugins' OS matrix; merge after green.

## Gotchas

- Windows release artifacts are inconsistent: some ship `name.exe` bare, some ship inside a zip with an extra prefix, some omit `.exe`. The smoke test in `verify.sh` (lines 75-109) already falls back through `--version` -> `version` -> `--help` -> bare `-h` and tries both `bin` and `bin.exe`; mirror that pattern if you extend it.
- `verify.sh` uses macOS-compatible `find` syntax (no `-printf`) and `bash` 3.2 features only — do not introduce `mapfile`, `${var,,}`, or GNU-only flags.
- Per-OS verifier split is deliberate (commit `ca99eba`): do not refactor `verify.sh` and `verify.ps1` into a single cross-platform script.
- AWS CLI / gcloud / Azure CLI / pre-commit are intentionally NOT plugins — see "Special notes" in README.
