#!/bin/bash
# Post-create runtime setup for Dev Env Workspace
# Verifies tool installations, checks credential isolation, prints workspace overview

set -euo pipefail

echo ""
echo "============================================"
echo "  Dev Env Workspace - Setup Verification"
echo "============================================"
echo ""

# ============================================================================
# Installation Verification
# ============================================================================

# First line of a command's output, or "not found"
v() {
    local out
    if out=$("$@" 2>/dev/null) && [ -n "$out" ]; then
        echo "${out%%$'\n'*}"
    else
        echo "not found"
    fi
}

echo "--- Installed Tools ---"
echo ""
echo "Node.js:    $(v node --version)"
echo "npm:        $(v npm --version)"
echo "Claude:     $(v claude --version)"
echo "Python:     $(v python3 --version)"
echo "uv:         $(v uv --version)"
echo "coregen:    $(v sh -c 'uv tool list | grep "^coregen"')"
echo "Terraform:  $(v terraform version)"
echo "OpenTofu:   $(v tofu version)"
echo "TFLint:     $(v tflint --version)"
echo "kubectl:    $(v kubectl version --client)"
echo "talosctl:   $(v sh -c 'talosctl version --client --short | grep Talos')"
echo "Helm:       $(v helm version --short)"
echo "Cilium CLI: $(v cilium version --client)"
echo "Argo CD:    $(v argocd version --client --short)"
echo "k9s:        $(v k9s version --short)"
echo "yq:         $(v yq --version)"
echo "Ansible:    $(v ansible --version)"
echo "AWS CLI:    $(v aws --version)"
echo "Git:        $(v git --version)"
echo "gh:         $(v gh --version)"
echo "Make:       $(v make --version)"
echo "ShellCheck: $(v sh -c 'shellcheck --version | grep "^version:"')"
echo ""

# ============================================================================
# Credential Isolation Check
# ============================================================================
# The container is meant to hold no credentials. Flag anything that leaked in.

echo "--- Credential Isolation ---"
echo ""
leaks=0
check_absent() {
    if [ -e "$1" ]; then
        echo "  WARNING: $1 present"
        leaks=$((leaks + 1))
    fi
}
for path in "$HOME/.ssh" "$HOME/.aws" "$HOME/.kube/config" "$HOME/.talos/config" \
            "$HOME/.config/op" "$HOME/.config/gh/hosts.yml" "$HOME/.docker/config.json"; do
    check_absent "$path"
done
if [ -n "${SSH_AUTH_SOCK:-}" ]; then
    echo "  WARNING: SSH_AUTH_SOCK is set ($SSH_AUTH_SOCK)"
    leaks=$((leaks + 1))
fi
if git config --global --get-all credential.helper >/dev/null 2>&1; then
    echo "  WARNING: git credential.helper configured (VS Code forwards host git credentials)"
    echo "           set \"dev.containers.gitCredentialHelperConfigLocation\": \"none\" in VS Code user settings"
    leaks=$((leaks + 1))
fi
if [ "$leaks" -eq 0 ]; then
    echo "  ok: no host credentials detected"
fi
echo ""

# ============================================================================
# Workspace Overview
# ============================================================================

echo "--- Workspace Layout ---"
echo ""
echo "All repositories mounted at /workspace:"
echo ""

for dir in /workspace/*/; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        if [ -d "$dir/.git" ]; then
            echo "  $dirname/ (git repo)"
        else
            subcount=$(find "$dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
            if [ "$subcount" -gt 0 ]; then
                echo "  $dirname/ ($subcount sub-directories)"
            else
                echo "  $dirname/"
            fi
        fi
    fi
done
echo ""

# ============================================================================
# Host Aliases Check
# ============================================================================

echo "--- Host Aliases ---"
echo ""
if [ -f "$HOME/.bash_aliases" ]; then
    aliascount=$(grep -c "^alias " "$HOME/.bash_aliases" 2>/dev/null || echo "0")
    echo "~/.bash_aliases mounted ($aliascount aliases available)"
    echo "  Sourced automatically in zsh sessions"
else
    echo "~/.bash_aliases not mounted (optional)"
fi
echo ""

# ============================================================================
# Ready
# ============================================================================

echo "============================================"
echo "  Workspace Ready"
echo "============================================"
echo ""
echo "Quick start:"
echo "  claude                 - Start Claude Code"
echo "  cd lapcotek/           - Navigate to Lapcotek repos"
echo "  cd yantramakers/       - Navigate to Yantra Makers repos"
echo "  cd dev-env/            - This devcontainer repo (read-only)"
echo ""
echo "Credentialed commands (tofu apply, op, ssh, git push) run on the host."
echo ""
