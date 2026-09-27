#!/bin/bash
# =============================================================================
# Dev Env Workspace - Bootstrap Script
# =============================================================================
# Sets up Claude Code configurations at ~/repos on a new machine.
#
# What this does:
#   1. Creates ~/repos/CLAUDE.md                    (single root-level workspace guide)
#   2. Creates ~/repos/.claude/settings.local.json  (root-level permissions)
#   3. Creates per-project .claude/settings.local.json (clean base permissions)
#   4. Deploys settings/ → ~/repos/.claude/ (agents, commands, output-styles, rules, settings.json)
#
# What this does NOT do:
#   - Create per-project CLAUDE.md files (all guidance lives in root CLAUDE.md)
#   - Clone repos (you should have ~/repos/* already populated)
#   - Install tools (that's what the devcontainer handles)
#   - Modify your shell configs (~/.gitconfig, ~/.bash_aliases, etc.)
#
# Note: ~/.gitignore_global already ignores CLAUDE.md and .claude/ so
#       nothing from this script will appear in git status of any repo.
#
# Usage:
#   cd ~/repos/dev-env && bash setup/bootstrap.sh
#
# Safe to re-run: only writes files that don't already exist (use --force to overwrite)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS_DIR="$(dirname "$SCRIPT_DIR")"
# Go up one more level since SCRIPT_DIR is dev-env/setup/
REPOS_DIR="$(dirname "$REPOS_DIR")"

FORCE=false
DRY_RUN=false

for arg in "$@"; do
    case $arg in
        --force) FORCE=true ;;
        --dry-run) DRY_RUN=true ;;
        --help|-h)
            echo "Usage: bash setup/bootstrap.sh [--force] [--dry-run]"
            echo ""
            echo "  --force    Overwrite existing files"
            echo "  --dry-run  Show what would be done without writing"
            exit 0
            ;;
    esac
done

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

write_file() {
    local target="$1"
    local content="$2"
    local description="$3"

    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${BLUE}[dry-run]${NC} Would write: $target"
        return
    fi

    if [ -f "$target" ] && [ "$FORCE" = false ]; then
        echo -e "  ${YELLOW}[skip]${NC} $target (exists, use --force to overwrite)"
        return
    fi

    mkdir -p "$(dirname "$target")"
    echo "$content" > "$target"
    echo -e "  ${GREEN}[wrote]${NC} $target — $description"
}

copy_file() {
    local src="$1"
    local target="$2"
    local description="$3"

    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${BLUE}[dry-run]${NC} Would copy: $(basename "$src") → $target"
        return
    fi

    if [ -f "$target" ] && [ "$FORCE" = false ]; then
        echo -e "  ${YELLOW}[skip]${NC} $target (exists, use --force to overwrite)"
        return
    fi

    mkdir -p "$(dirname "$target")"
    cp "$src" "$target"
    echo -e "  ${GREEN}[copied]${NC} $target — $description"
}

echo ""
echo "============================================"
echo "  Dev Env Workspace - Bootstrap"
echo "============================================"
echo ""
echo "Repos directory: $REPOS_DIR"
echo ""

# =============================================================================
# 1. Root-level CLAUDE.md (single source of truth for all project guidance)
# =============================================================================

echo "--- Root CLAUDE.md ---"

write_file "$REPOS_DIR/CLAUDE.md" '# CLAUDE.md — Workspace Root

This is a multi-repo workspace containing all infrastructure and tooling repositories.

## Common Patterns

### Coregen (IaC Templating)
Most infrastructure repos use coregen for Jinja2 templating:
```bash
coregen generate c/<context>       # Generate for a context
coregen generate cm/*              # Generate all matching contexts
coregen get c/* --output json      # List contexts
coregen detect-changes --base-branch main --output matrix --changed-only
```

### Terraform
Generated Terraform lives in `output/` directories:
```bash
make init        # terraform init
make plan        # terraform plan
make deploy      # terraform apply (prompted)
make auto-deploy # terraform apply -auto-approve
make destroy     # terraform destroy
make help        # list targets
```

CI-specific: `make init-ci / validate-ci / deploy-ci`

### Git Workflow
All repos use GitHub with PR-based workflow. Branches follow: `<user>/<ticket>/<description>`

## Key Conventions
- AWS primary region: us-east-2
- BCDR region: us-west-2
- Global-only services: us-east-1
- Ansible collections: amazon.aws, community.general, ansible.posix' "Root-level workspace guide for Claude"

echo ""

# =============================================================================
# 2. Root-level settings.local.json
# =============================================================================

echo "--- Root Claude Settings ---"

write_file "$REPOS_DIR/.claude/settings.local.json" '{
  "permissions": {
    "allow": [
      "Bash(find:*)",
      "Bash(cat:*)",
      "Bash(git checkout:*)",
      "Bash(git pull:*)",
      "Bash(git mv:*)",
      "Bash(git fetch:*)",
      "Bash(git log:*)",
      "Bash(git show:*)",
      "Bash(git branch:*)",
      "Bash(git reset:*)",
      "Bash(grep:*)",
      "Bash(ls:*)",
      "Bash(chmod:*)",
      "Bash(xargs:*)",
      "Bash(coregen --help:*)",
      "Bash(coregen generate:*)",
      "Bash(coregen get:*)",
      "WebFetch(domain:registry.terraform.io)",
      "WebFetch(domain:github.com)",
      "WebFetch(domain:aws.amazon.com)",
      "WebFetch(domain:techdocs.genetec.com)",
      "WebFetch(domain:www.rabbitmq.com)",
      "WebSearch"
    ],
    "deny": [],
    "ask": []
  }
}' "Common permissions for all repos"

echo ""

# =============================================================================
# 3. Per-project .claude/settings.local.json (clean base permissions only)
# =============================================================================

echo "--- Per-Project Claude Settings ---"

if [ -d "$REPOS_DIR/core-mining/terraform-github" ]; then
    write_file "$REPOS_DIR/.claude/settings.local.json" '{
  "permissions": {
    "allow": [
      "Bash(git checkout:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(terraform init:*)",
      "Bash(terraform plan:*)",
      "Bash(terraform validate:*)",
      "Bash(terraform fmt:*)"
    ],
    "deny": [],
    "ask": []
  }
}' "terraform-github base permissions"
fi

echo ""

# =============================================================================
# 4. Deploy settings/ (agents, commands, output-styles, rules, settings)
# =============================================================================

echo "--- Claude Settings (settings/) ---"

CLAUDE_SETTINGS_SRC="$SCRIPT_DIR/../settings"

if [ ! -d "$CLAUDE_SETTINGS_SRC" ]; then
    echo -e "  ${YELLOW}[skip]${NC} $CLAUDE_SETTINGS_SRC not found"
else
    # settings.json → ~/repos/.claude/settings.json
    # Note: settings.local.json (written above) takes precedence for permissions overrides.
    if [ -f "$CLAUDE_SETTINGS_SRC/settings.json" ]; then
        copy_file "$CLAUDE_SETTINGS_SRC/settings.json" \
            "$REPOS_DIR/.claude/settings.json" \
            "Claude Code workspace settings (hooks, plugins, sandbox, output-style)"
    fi

    # Subdirectories: agents, output-styles, rules (flat: only *.md at root of each)
    for subdir in agents output-styles rules; do
        if [ -d "$CLAUDE_SETTINGS_SRC/$subdir" ]; then
            for src_file in "$CLAUDE_SETTINGS_SRC/$subdir"/*.md; do
                [ -f "$src_file" ] || continue
                copy_file "$src_file" \
                    "$REPOS_DIR/.claude/$subdir/$(basename "$src_file")" \
                    "$subdir/$(basename "$src_file")"
            done
        fi
    done

    # commands/ has both root-level *.md and subdirectories (aws/, git/, quick/)
    if [ -d "$CLAUDE_SETTINGS_SRC/commands" ]; then
        for src_file in "$CLAUDE_SETTINGS_SRC/commands"/*.md; do
            [ -f "$src_file" ] || continue
            copy_file "$src_file" \
                "$REPOS_DIR/.claude/commands/$(basename "$src_file")" \
                "commands/$(basename "$src_file")"
        done
        for src_subdir in "$CLAUDE_SETTINGS_SRC/commands"/*/; do
            [ -d "$src_subdir" ] || continue
            subdir_name="$(basename "$src_subdir")"
            for src_file in "$src_subdir"*.md; do
                [ -f "$src_file" ] || continue
                copy_file "$src_file" \
                    "$REPOS_DIR/.claude/commands/$subdir_name/$(basename "$src_file")" \
                    "commands/$subdir_name/$(basename "$src_file")"
            done
        done
    fi
fi

echo ""

# =============================================================================
# 5. Ensure ~/.gitignore_global covers Claude files
# =============================================================================

echo "--- Global Gitignore Check ---"

GITIGNORE_GLOBAL="$HOME/.gitignore_global"
if [ -f "$GITIGNORE_GLOBAL" ]; then
    missing=()
    grep -qF "CLAUDE.md" "$GITIGNORE_GLOBAL" || missing+=("CLAUDE.md")
    grep -qF ".claude/" "$GITIGNORE_GLOBAL" || missing+=(".claude/")

    if [ ${#missing[@]} -eq 0 ]; then
        echo -e "  ${GREEN}[ok]${NC} ~/.gitignore_global already ignores CLAUDE.md and .claude/"
    else
        echo -e "  ${YELLOW}[warn]${NC} Missing from ~/.gitignore_global: ${missing[*]}"
        echo "  Add these lines to ~/.gitignore_global:"
        for m in "${missing[@]}"; do
            echo "    $m"
        done
    fi
else
    echo -e "  ${YELLOW}[warn]${NC} ~/.gitignore_global not found"
    echo "  Create it with at least:"
    echo "    CLAUDE.md"
    echo "    .claude/"
fi

echo ""

# =============================================================================
# 6. Verification
# =============================================================================

echo "--- Summary ---"
echo ""

root_claude=$([ -f "$REPOS_DIR/CLAUDE.md" ] && echo "yes" || echo "no")
root_settings=$([ -f "$REPOS_DIR/.claude/settings.local.json" ] && echo "yes" || echo "no")
root_settings_json=$([ -f "$REPOS_DIR/.claude/settings.json" ] && echo "yes" || echo "no")
project_settings=$(find "$REPOS_DIR" -maxdepth 4 -path "*/.claude/settings.local.json" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
agents_count=$(find "$REPOS_DIR/.claude/agents" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
commands_count=$(find "$REPOS_DIR/.claude/commands" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

echo "Root CLAUDE.md:              $root_claude"
echo "Root settings.local.json:    $root_settings"
echo "Root settings.json:          $root_settings_json"
echo "Project settings.local.json: $project_settings"
echo "Agents deployed:             $agents_count"
echo "Commands deployed:           $commands_count"

echo ""
echo "============================================"
echo "  Bootstrap Complete"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Open ~/repos/dev-env in VS Code"
echo "  2. Reopen in Container"
echo "  3. All repos available at /workspace/"
echo "  4. Run 'claude' to start working"
echo ""
