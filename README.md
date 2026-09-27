# Dev Env

Unified devcontainer workspace for working with Claude Code across all repos in `~/repos/`.

## What's Included

- **`.devcontainer/`** — Docker-based dev environment (Ubuntu 24.04 LTS) with Claude Code, coregen, Terraform/OpenTofu, Kubernetes/Talos tooling, Ansible, Python, zsh. All tooling lives in the container so the host stays clean.
- **`setup/bootstrap.sh`** — Sets up Claude Code configs at `~/repos/.claude/` on a new machine:
  - `CLAUDE.md` — workspace guide (single source of truth)
  - `settings.local.json` — root-level permissions (local overrides, gitignored)
  - `settings.json`, `agents/`, `commands/`, `output-styles/`, `rules/` — deployed from `settings/`
- **`settings/`** — Claude Code agents, commands, rules, and output styles (versioned in this repo)

## Quick Start

1. Clone this repo to `~/repos/dev-env`
2. Run the bootstrap script to set up Claude configs:
   ```bash
   cd ~/repos/dev-env && bash setup/bootstrap.sh
   ```
3. Open `~/repos/dev-env` in VS Code → **Reopen in Container**
4. All repos are mounted at `/workspace/`

## Prerequisites

On the host machine you need:
- Docker Desktop
- VS Code with the Dev Containers extension
- `~/.gitignore_global` and `~/.bash_aliases` (bind-mounted read-only; create empty files if you have none)
- `~/repos/` populated with your project repos

Nothing else: no Terraform, Python, kubectl, etc. on the host.

## Security Model

The container is a build/lint/validate environment with **no credentials** and a **non-admin user**:

- No `~/.ssh`, `~/.aws`, `~/.kube`, `~/.talos`, `~/.gitconfig` or 1Password access is mounted.
- Generated cluster credentials inside repos (`lapcotek/**/on-prem/*/generated/`) are hidden by empty tmpfs mounts.
- The user `nabu` has no sudo, except to run the root-owned firewall script.
- `dev-env/` itself is mounted read-only, so nothing in the container can relax these settings.
- Outbound network is limited to an allowlist (see below); the LAN is not reachable.
- Credentialed commands (`tofu apply`, `op`, `ssh`, `git push`, `kubectl` against a cluster) run on the host.

VS Code forwards some host credentials into dev containers by default. Turn that off in your **VS Code user settings** on the host:

```jsonc
"dev.containers.copyGitConfig": false,
"dev.containers.gitCredentialHelperConfigLocation": "none",
"dev.containers.dockerCredentialHelper": false
```

The SSH agent VS Code forwards is blanked via `remoteEnv` and unset in `.zshrc`. `postCreate.sh` prints a warning if any credential leaks in.

## Container Tools

Versions are pinned as build args in `.devcontainer/devcontainer.json`.

| Tool | Version |
|------|---------|
| Base OS | Ubuntu 24.04 LTS |
| Claude Code | latest |
| Node.js | 24 |
| Python / pip / pipx / uv | 3.12 / system / system / 0.12.19 |
| coregen | 1.1.1 (from github.com/skoonin/coregen) |
| Terraform | 1.16.4 |
| OpenTofu | 1.12.6 |
| TFLint | 0.64.0 |
| kubectl | 1.36.5 |
| talosctl | 1.13.10 (matches cluster Talos version) |
| Helm | 4.3.0 |
| Cilium CLI | 0.20.1 |
| Argo CD CLI | 3.5.3 |
| k9s | 0.51.0 |
| yq / jq | 4.53.6 / system |
| Ansible core | 2.20.4 (+ ansible-lint) |
| AWS CLI | v2 (no credentials) |
| Python CLIs | pre-commit, ruff, black, flake8, pylint, mypy, pytest, tox, yamllint |
| gh, git-delta, shellcheck, make | latest / 0.19.2 / system / system |
| zsh + Powerlevel10k | with fzf, git-delta, autosuggestions |

To bump a tool, change its build arg and **Rebuild Container**.

## Persistent Volumes

| Volume | Mount | Purpose |
|--------|-------|---------|
| `dev-env-claude-config` | `/home/node/.claude` | Claude Code auth & config |
| `dev-env-bashhistory` | `/commandhistory` | zsh history across rebuilds |

## Network Firewall

The container runs a whitelist-based firewall allowing only:
- GitHub (incl. release assets), Anthropic API, npm registry
- Terraform and OpenTofu registries, HashiCorp releases, Talos image factory
- Helm chart repos (Cilium, Argo, MetalLB, Kubernetes), dl.k8s.io
- PyPI, Ansible Galaxy
- VS Code marketplace services

Add domains in `.devcontainer/init-firewall.sh`. IPs are resolved at container start.
