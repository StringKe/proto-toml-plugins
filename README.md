# proto-toml-plugins

[Proto](https://moonrepo.dev/proto) TOML plugins for common infra CLI tooling. Use a single `.prototools` to manage versions of tofu, terragrunt, kustomize, cosign, helm, sops, atlas, buf, kubectl, gh, argocd, vault, and age.

## Plugins

| Plugin | Upstream | Description |
|--------|----------|-------------|
| `tofu` | https://github.com/opentofu/opentofu | OpenTofu, open-source Terraform fork |
| `terragrunt` | https://github.com/gruntwork-io/terragrunt | Terragrunt, DRY thin wrapper over Terraform / OpenTofu |
| `kustomize` | https://github.com/kubernetes-sigs/kustomize | Kustomize K8s manifest overlay |
| `cosign` | https://github.com/sigstore/cosign | Cosign container & artifact signing |
| `helm` | https://github.com/helm/helm | Helm Kubernetes package manager |
| `sops` | https://github.com/getsops/sops | SOPS encrypted secret editor |
| `atlas` | https://github.com/ariga/atlas | Atlas database schema migration |
| `buf` | https://github.com/bufbuild/buf | Buf protobuf toolchain |
| `kubectl` | https://github.com/kubernetes/kubectl | Kubernetes CLI |
| `gh` | https://github.com/cli/cli | GitHub CLI |
| `argocd` | https://github.com/argoproj/argo-cd | Argo CD CLI |
| `vault` | https://github.com/hashicorp/vault | HashiCorp Vault CLI |
| `age` | https://github.com/FiloSottile/age | age encryption tool (sops backend) |

## Usage

In your `.prototools`:

```toml
tofu = "1.12.0"
terragrunt = "1.0.1"
kustomize = "5.8.1"
cosign = "3.0.6"
helm = "4.1.4"
sops = "3.12.2"
atlas = "1.2.0"
buf = "1.61.0"
kubectl = "1.34.0"
gh = "2.81.0"
argocd = "3.4.3"
vault = "1.21.2"
age = "1.2.1"

[plugins]
tofu       = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/tofu.toml"
terragrunt = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/terragrunt.toml"
kustomize  = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/kustomize.toml"
cosign     = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/cosign.toml"
helm       = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/helm.toml"
sops       = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/sops.toml"
atlas      = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/atlas.toml"
buf        = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/buf.toml"
kubectl    = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/kubectl.toml"
gh         = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/gh.toml"
argocd     = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/argocd.toml"
vault      = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/vault.toml"
age        = "https://raw.githubusercontent.com/StringKe/proto-toml-plugins/main/plugins/age.toml"
```

Then:

```sh
proto install
```

## License

MIT
