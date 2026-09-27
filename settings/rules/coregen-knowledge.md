# Coregen v1.0.5 Knowledge Base

- [Overview](#overview)
- [Core Concepts](#core-concepts)
- [Pattern Prefixes (MANDATORY)](#pattern-prefixes-mandatory)
- [Essential Commands](#essential-commands)
- [Filter Operators](#filter-operators)
- [Priority Rules](#priority-rules)
- [GitHub Actions Matrix](#github-actions-matrix)
- [Values File Structure](#values-file-structure)
- [Output Types](#output-types)
- [Environment Variables](#environment-variables)
- [Gotchas](#gotchas)
- [Breaking Changes](#breaking-changes)
- [Service Architecture (For Development)](#service-architecture-for-development)
- [Quick Debug](#quick-debug)

## Overview

Coregen is a configuration management and code generation tool designed for managing multi-environment deployments at scale. It provides intelligent change detection, matrix-based deployment strategies, and hierarchical configuration management.

## Core Concepts

### Hierarchical Structure

```
Workspace (e.g., workspaces)
├── Context (e.g., core-hpc-is-use2-dev)
│   ├── Component (e.g., workspace)
│   ├── Component (e.g., catalogs)
│   └── Component (e.g., instance-profiles)
└── Context (e.g., core-hpc-is-use2-prod)
    ├── Component (e.g., workspace)
    └── Component (e.g., catalogs)
```

### Key Terminology

- **Workspace**: Top-level organizational unit (e.g., "workspaces" directory)
- **Context**: Specific deployment target/environment (e.g., "core-hpc-is-use2-dev")
- **Component**: Deployable unit within a context (e.g., "workspace", "catalogs")
- **Priority**: Component execution order (0=highest, sequential; null=parallel)
- **Environment**: Context property indicating deployment stage (dev/prod)
- **Required Component**: When changed, triggers cascade to all components in context

## Pattern Prefixes (MANDATORY)

```bash
w/  # Workspaces
c/  # Contexts
cm/ # Components

# Examples
cm/*                    # All components
c/core-hpc-*           # Contexts matching pattern
```

## Essential Commands

### detect-changes
Detects components changed between branches by comparing generated output.

```bash
# Basic usage - compare to main branch
coregen detect-changes --base-branch main --output matrix --changed-only

# Compare to previous commit (for push events)
coregen detect-changes --base-branch HEAD~1 --output matrix --changed-only

# Filter by environment
coregen detect-changes --filter "context.environment=dev" --output matrix --changed-only

# Include inactive components
coregen detect-changes --include-inactive --output matrix

# Show only deleted components
coregen detect-changes --deleted-only --output matrix

# Keep generated files for debugging
coregen detect-changes --keep-generated --verbose
```

**Output formats:**

- `text`: Human-readable (default)
- `json`: Structured data
- `yaml`: YAML format
- `table`: Terminal table
- `matrix`: GitHub Actions matrix format

**Complete Matrix Output Structure:**

```json
{
  "include": [
    {
      "component_name": "workspace",
      "command": "cm/workspace --filter \"workspace.name=workspaces\" --filter \"context.name=core-hpc-is-use2-dev\"",
      "component_active": true,
      "component_path": "/path/to/workspace",
      "component_priority": 0,
      "component_required": false,
      "context_name": "core-hpc-is-use2-dev",
      "context_config_file_path": "/path/to/context-values.yaml",
      "reason": "direct",
      "status": "changed",
      "workspace_name": "workspaces"
    }
  ]
}
```

### generate
```bash
coregen generate cm/workspace --filter "context.name=core-hpc-is-use2-dev"
coregen generate c/core-hpc-is-use2-dev
coregen generate "cm/*" --skip-commit-dir  # Test without committing
```

### get
Retrieve configuration elements with filtering.

**Important**: The `coregen get` command outputs components sorted by priority (0 first, then 1, 2, 3, then null/undefined), then alphabetically within each priority level. This ordering is preserved in all output formats including matrix output.

```bash
coregen get "cm/*" --output matrix
coregen get "cm/*" --filter "component.active=true"
coregen get "c/*" --filter "context.environment=dev"
```

## Filter Operators

| Operator | Usage | Example |
|----------|-------|---------|
| `=` | Exact match (case-sensitive) | `context.environment=dev` |
| `!=` | Not equal | `component.name!=infra` |
| `~=` or `=~` | Regex (substring by default) | `context.name~=dev` |
| `>`, `<`, `>=`, `<=` | Numeric comparisons | `component.priority<=3` |
| `=none` | Check for null/undefined | `component.priority=none` |

```bash
# Regular expression examples (v1.0.3+)
--filter "context.name~=dev"          # Contains 'dev' (substring match)
--filter "component.name~=^workspace" # Starts with 'workspace' (anchored)
--filter "component.name~=-prod$"     # Ends with '-prod' (anchored)
--filter "workspace.name!=aws"        # Not equal to 'aws'
--filter "component.priority=none"    # No priority set
```

**Important filter notes:**
- Boolean values must be lowercase: `=true` not `=True`
- Null values use `=none` not `=null`
- Multiple filters use AND logic
- Field names use dots: `context.environment` not `context_environment`

## Priority Rules

1. No duplicate priorities in context
2. Priority can't depend on null-priority
3. Dependencies must have equal/better priority
4. Null can't depend on null
5. No circular dependencies

**Deploy order**: 0 → 1 → 2 → ... → null (alphabetical within same priority)

### Priority Cascade

When a component marked as `required: true` changes:

- ALL components in that context are marked as changed
- Reason is set to `required_cascade`
- **Important**: Filter operators like `!=` won't exclude cascaded components
  - Example: If `infra` (required: true) changes, `--filter "component.name!=infra"` will still return all components because they're included via required_cascade
  - This is by design to ensure consistency when required components change

### Special Case: Infra Component

The `infra` component is an EXAMPLE of using a required component that triggers cascade. It is typically:

- Marked as `required: true` (changes trigger cascade to all components)
- Used as a module sourced by other components
- Not deployed directly (only generated for other components to reference)

**Best Practice**: Filter out `infra` directly using coregen filters:

```bash
# Filter out infra component directly in the command
coregen detect-changes --base-branch main --output matrix --changed-only --filter "component.name!=infra"
```

## GitHub Actions Matrix

```yaml
- name: Detect changes
  run: |
    MATRIX=$(coregen detect-changes --base-branch ${{ github.base_ref || 'HEAD~1' }} --output matrix --changed-only)
    echo "matrix=$MATRIX" >> $GITHUB_OUTPUT
    [ "$MATRIX" != '{"include":[]}' ] && echo "has_changes=true" >> $GITHUB_OUTPUT

jobs:
  deploy:
    strategy:
      matrix: ${{ fromJson(needs.detect.outputs.matrix) }}
      fail-fast: false
```

**Key fields**: `component_name`, `context_name`, `workspace_name`, `environment`, `component_priority`, `command`

## Values File Structure

```yaml
context:
  name: "core-hpc-is-use2-dev"
  environment: "dev"
  component:
    - name: workspace
      config:
        active: true
        priority: 0
        required: false
        for_commit: true
        path: common-templates/workspace
      vars:
        custom_var: value
```

## Output Types

- **output_dir**: Temporary files for deployment
- **commit_dir + for_commit:true**: Committed to repo (ArgoCD)

## Environment Variables

```bash
CG_LOG_LEVEL=debug     # Debug mode
CG_OUTPUT_FORMAT=json  # Default output
CG_CONFIG_FILE=path    # Config location
```

## Gotchas

- **Prefixes mandatory**: `cm/*` not `*`
- **Case-sensitive**: Patterns and values
- **Boolean lowercase**: `=true` not `=True`
- **Fetch depth**: `fetch-depth: 0` in checkout
- **Required cascade**: Can't filter out cascaded components

## Breaking Changes

### v1.0.5
- Strict dependency validation rules enforced
- Priority-only sorting (0→1→2→...→null)

### v1.0.3
- `~=` uses regex, not glob: `~=dev` (contains), `~=^dev` (starts with)

### v1.0.2
- `generated` → `for_commit`
- `generated_dir` → `commit_dir`
- `--skip-generated-dir` → `--skip-commit-dir`

## Service Architecture (For Development)

### Base Classes
- **ServiceBase**: Console, FileManager, Logger, GlobalOptions
- **ServicesBase**: + ConfigurationProvider, PathService, FilterService

### Critical Patterns
1. **Lazy loading**: Never access `config_access` in `__init__`
2. **Defensive copy**: Copy GlobalOptions/kwargs before modifying
3. **Composition**: Services compose other services, don't inherit

### detect_changes Uniqueness
Needs TWO ConfigProviders (current + base branch) - intentionally complex.

## Quick Debug

```bash
# Component not showing?
coregen get "cm/*" --include-inactive

# Path issues?
coregen config view enhanced -o json | jq

# See all config
CG_LOG_LEVEL=debug coregen get "cm/*"
```

---
*Full documentation: ~/git/coregen-hpc/docs/*
