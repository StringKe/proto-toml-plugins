# proto-toml-plugins

[Proto](https://moonrepo.dev/proto) TOML plugins for common infra CLI tooling. Use a single `.prototools` to manage versions of 68+ tools including Kubernetes ecosystem, HashiCorp stack, security scanners, GitOps, cloud CLIs and DevEx utilities (tofu, terraform, terragrunt, flux, kind, k3d, kubectl, helm, kustomize, argocd, velero, k9s, kubectx, kubens, cosign, sops, age, trivy, gitleaks, vault, consul, packer, gh, yq, jq, crane, d2, mkcert, golangci-lint, air, sqlc, stern, tflint, terraform-docs, buf, atlas, direnv, lazygit, cloudflared, caddy, eksctl, aliyun, helmfile, operator-sdk, tkn, istioctl, oras, syft, grype, starship, zoxide, eza, fd, vp (Vite+), oxlint, oxfmt, just, dra, dive, process-compose, ubi, eget, regctl, lazydocker, kail, popeye, and more).

## Plugins

| Plugin | Upstream | Description |
|--------|----------|-------------|
| `air` | https://github.com/air-verse/air | Go hot reload development tool |
| `argocd` | https://github.com/argoproj/argo-cd | Argo CD CLI |
| `atlas` | https://github.com/ariga/atlas | Atlas database schema migration |
| `buf` | https://github.com/bufbuild/buf | Buf protobuf toolchain |
| `consul` | https://github.com/hashicorp/consul | HashiCorp Consul (service mesh / KV) |
| `cosign` | https://github.com/sigstore/cosign | Cosign container & artifact signing |
| `crane` | https://github.com/google/go-containerregistry | crane / gcrane container registry CLI |
| `d2` | https://github.com/terrastruct/d2 | Declarative diagram language (text to diagrams) |
| `dive` | https://github.com/wagoodman/dive | Docker image layer analyzer |
| `dra` | https://github.com/devmatteini/dra | GitHub release asset downloader (meta tool) |
| `flux` | https://github.com/fluxcd/flux2 | Flux GitOps continuous delivery |
| `gh` | https://github.com/cli/cli | GitHub CLI |
| `gitleaks` | https://github.com/gitleaks/gitleaks | Git secret leak detection |
| `golangci-lint` | https://github.com/golangci/golangci-lint | Go linters aggregator |
| `helm` | https://github.com/helm/helm | Helm Kubernetes package manager |
| `jq` | https://github.com/jqlang/jq | Command-line JSON processor |
| `just` | https://github.com/casey/just | Modern command runner / make alternative |
| `k3d` | https://github.com/k3d-io/k3d | Lightweight K3s in Docker |
| `k9s` | https://github.com/derailed/k9s | Modern Kubernetes TUI |
| `kind` | https://github.com/kubernetes-sigs/kind | Local Kubernetes clusters (Docker) |
| `kubeconform` | https://github.com/yannh/kubeconform | Kubernetes manifest validator |
| `kubectl` | https://github.com/kubernetes/kubectl | Kubernetes CLI |
| `kubectx` | https://github.com/ahmetb/kubectx | Kubernetes context switcher |
| `kubens` | https://github.com/ahmetb/kubectx | Kubernetes namespace switcher |
| `kustomize` | https://github.com/kubernetes-sigs/kustomize | Kustomize K8s manifest overlay |
| `mkcert` | https://github.com/FiloSottile/mkcert | Local HTTPS dev certificates (same author as age) |
| `packer` | https://github.com/hashicorp/packer | HashiCorp image builder |
| `process-compose` | https://github.com/F1bonacc1/process-compose | Process orchestrator (like docker-compose for local processes) |
| `regctl` | https://github.com/regclient/regclient | OCI registry client (part of regclient) |
| `ubi` | https://github.com/houseabsolute/ubi | Universal Binary Installer from GitHub releases (meta tool) |
| `eget` | https://github.com/zyedidia/eget | GitHub release binary downloader (meta tool) |
| `lazydocker` | https://github.com/jesseduffield/lazydocker | Terminal Docker manager TUI |
| `kail` | https://github.com/boz/kail | Kubernetes log tailer (multi-pod) |
| `popeye` | https://github.com/derailed/popeye | Kubernetes cluster sanitizer |
| `sops` | https://github.com/getsops/sops | SOPS encrypted secret editor |
| `sqlc` | https://github.com/sqlc-dev/sqlc | SQL to type-safe code generator |
| `stern` | https://github.com/stern/stern | Kubernetes multi-pod log tail |
| `terraform` | https://github.com/hashicorp/terraform | Terraform infrastructure as code |
| `terraform-docs` | https://github.com/terraform-docs/terraform-docs | Generate docs from Terraform modules |
| `terragrunt` | https://github.com/gruntwork-io/terragrunt | Terragrunt, DRY thin wrapper over Terraform / OpenTofu |
| `tflint` | https://github.com/terraform-linters/tflint | Terraform linter |
| `tofu` | https://github.com/opentofu/opentofu | OpenTofu, open-source Terraform fork |
| `trivy` | https://github.com/aquasecurity/trivy | Vulnerability scanner (containers / code / fs) |
| `vault` | https://github.com/hashicorp/vault | HashiCorp Vault CLI |
| `velero` | https://github.com/vmware-tanzu/velero | Kubernetes backup and disaster recovery |
| `vp` | https://github.com/voidzero-dev/vite-plus | Vite+ (vp) — unified zero-config web toolchain (Vite + Rolldown + Oxlint + Vitest etc.) |
| `oxlint` | https://github.com/oxc-project/oxc | Oxc oxlint (Rust linter, Vite+ recommended) |
| `oxfmt` | https://github.com/oxc-project/oxc | Oxc oxfmt (Rust formatter) |
| `yq` | https://github.com/mikefarah/yq | YAML/JSON/XML/CSV processor (jq for YAML) |

## Usage

In your `.prototools`:

```toml
tofu = "1.12.0"
terraform = "1.12.2"
terragrunt = "1.0.1"
flux = "2.8.8"
kind = "0.29.0"
k3d = "5.8.3"
kubectl = "1.34.0"
helm = "4.1.4"
kustomize = "5.8.1"
argocd = "3.4.3"
k9s = "0.50.9"
kubectx = "0.11.0"
kubens = "0.11.0"
cosign = "3.0.6"
sops = "3.12.2"
age = "1.2.1"
trivy = "0.70.0"
vault = "1.21.2"
vp = "0.1.23"
oxlint = "1.67.0"
oxfmt = "0.52.0"
consul = "1.21.0"
packer = "1.13.1"
process-compose = "1.110.0"
ubi = "0.9.0"
eget = "1.3.4"
regctl = "0.11.5"
lazydocker = "0.25.2"
kail = "0.17.4"
popeye = "0.22.1"
gh = "2.81.0"
yq = "4.47.2"
jq = "1.8.1"
crane = "0.21.6"
d2 = "0.7.1"
mkcert = "1.4.4"
golangci-lint = "2.1.6"
sqlc = "1.31.1"
stern = "1.34.0"
tflint = "0.59.0"
terraform-docs = "0.20.0"
buf = "1.61.0"
atlas = "1.2.0"

[plugins]
air            = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/air.toml"
argocd         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/argocd.toml"
atlas          = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/atlas.toml"
buf            = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/buf.toml"
consul         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/consul.toml"
cosign         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/cosign.toml"
crane          = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/crane.toml"
d2             = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/d2.toml"
flux           = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/flux.toml"
gh             = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/gh.toml"
gitleaks       = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/gitleaks.toml"
golangci-lint  = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/golangci-lint.toml"
helm           = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/helm.toml"
jq             = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/jq.toml"
just           = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/just.toml"
dra            = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/dra.toml"
dive           = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/dive.toml"
k3d            = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/k3d.toml"
k9s            = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/k9s.toml"
kind           = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/kind.toml"
kubeconform    = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/kubeconform.toml"
kubectl        = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/kubectl.toml"
kubectx        = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/kubectx.toml"
kubens         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/kubens.toml"
kustomize      = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/kustomize.toml"
mkcert         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/mkcert.toml"
packer         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/packer.toml"
process-compose = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/process-compose.toml"
regctl         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/regctl.toml"
ubi            = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/ubi.toml"
eget           = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/eget.toml"
lazydocker     = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/lazydocker.toml"
kail           = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/kail.toml"
popeye         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/popeye.toml"
sops           = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/sops.toml"
sqlc           = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/sqlc.toml"
stern          = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/stern.toml"
terraform      = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/terraform.toml"
terraform-docs = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/terraform-docs.toml"
terragrunt     = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/terragrunt.toml"
tflint         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/tflint.toml"
tofu           = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/tofu.toml"
trivy          = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/trivy.toml"
vault          = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/vault.toml"
velero         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/velero.toml"
vp             = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/vp.toml"
oxlint         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/oxlint.toml"
oxfmt          = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/oxfmt.toml"
yq             = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/yq.toml"
```

Then:

```sh
proto install
```

## Special notes

- **AWS CLI / Azure CLI / gcloud**: These use complex installers (python bundles, .pkg, post-install scripts). Recommended to use `brew install awscli` / `brew install --cask gcloud-cli` / official installers instead of proto plugins. A placeholder may be added later if a clean static binary path appears.
- **pre-commit**: Python package, no static binary release. Use `pipx install pre-commit` or `brew install pre-commit`.
- **vite-plus (vp)**: GitHub Releases 提供原生二进制（vp-aarch64-apple-darwin.tar.gz 等）。本仓库已提供 `plugins/vp.toml`。官方 curl 脚本会额外设置 ~/.vite-plus 完整环境（Node 管理等），如需完整特性仍可搭配使用。

### Vite 生态工具（用户列出的组件）

- **oxlint / oxfmt**（1.67.0 / 0.52.0）：Oxc 项目在 GitHub Releases (apps_vX.Y.Z tag) 提供大量高质量预构建 tar.gz + zip + checksum。本仓库已提供 `oxlint.toml` 和 `oxfmt.toml`，可直接用于 proto 管理。
- **vite** (8.x)、**rolldown**、**vitest**、**tsdown**：目前 GitHub Releases 不提供独立可执行二进制，主要通过 npm / pnpm / corepack / vp 管理。推荐在项目内使用，或通过 `vp` 统一。
- **oxlint-tsgolint**：通过 npm 包 `oxlint-tsgolint` 分发平台二进制（供 oxlint --type-aware 调用），无独立 GitHub release 二进制。建议随 oxlint 的 npm 依赖安装。

如未来这些工具开始提供稳定的原生 release binary，我们会及时补充 plugin。
- **moon** (moonrepo build system): Official plugin available from moonrepo/moon repo (`proto-plugin.toml`). This collection focuses on infra CLIs not covered well elsewhere.
- **Shell enhancements** (starship, atuin, zoxide, eza, fd, yazi, direnv, fzf, lazygit): Excellent candidates for proto if you want exact team pinning; add on request.

## Verification (sound & automated)

All 55+ plugins are continuously validated.

### Local (one command)

```sh
# Unix / macOS / Linux
./scripts/verify.sh

# Windows (PowerShell)
./scripts/verify.ps1

# Single plugin or latest
./scripts/verify.sh flux
./scripts/verify.ps1 --latest
```

The script:
- Spins isolated `PROTO_HOME` for each plugin
- Registers the local `.toml` via `file://`
- Installs the tool (pinned or latest)
- Runs `--version` / `version` / `--help` smoke test
- Reports clear PASS/FAIL with the actual binary path and output

### CI (GitHub Actions)

- **Daily (04:15 UTC)**: runs `--latest` on macOS arm64 + Ubuntu amd64. Catches asset name changes, broken checksums, and new release formats immediately.
- **On PR**: only tests changed plugins against `tests/known-good.json`.
- **Manual**: `workflow_dispatch` (use when you add a new plugin).
- Failures produce artifacts with full logs.

`tests/known-good.json` is the single source of truth for stable versions. Update it after a successful `--latest` run (or let a future bot PR do it).

This combination (local script + daily latest matrix + known-good pins) gives a complete, low-maintenance verification story.

## License

MIT
