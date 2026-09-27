# Common Development Patterns - HPC Infrastructure

> **Purpose**: Concrete patterns extracted from actual HPC infrastructure repositories. These are YOUR established practices, not generic templates.

## Naming Conventions

### Resource Naming Standard

**Pattern**: `core-hpc-{locale_short}-{env}-{region_short}-{resource_type}-{instance}`

**Examples**:

- `core-hpc-de-dev-use2-vpc-01` (DataEng Dev US-East-2 VPC)
- `core-hpc-sre-prod-use2-vpc-01` (SRE Prod US-East-2 VPC)
- `aws-sre-use2-svcs-01-prod` (SVCS Prod K8s cluster)

### Locale Abbreviations

- `sre` = sre
- `de` = dataeng
- `ig` = ignition
- `ne` = networking
- `mgmt` = management
- `pt` = product
- `is` = infosec
- `gt` = genetec
- `rn` = rnd

### Region Abbreviations

- `use2` = us-east-2 (PRIMARY)
- `usw2` = us-west-2 (SECONDARY)
- `use1` = us-east-1 (Global services only)

### AWS Profile Naming

**Pattern**: `core-hpc-{account_name}-{env}` (uses FULL account names, NOT abbreviations)

**Examples**:
- `core-hpc-dataeng-dev` (DataEng Dev)
- `core-hpc-dataeng-prod` (DataEng Prod)
- `core-hpc-networking-dev` (Networking Dev)
- `core-hpc-sre-dev` (SRE Dev)

**Exceptions**:
- Management: `core-hpc-management` (no env suffix)
- Outposts: `core-hpc-outpost-{site}` (e.g., `core-hpc-outpost-aus1`)

### Terraform Backend Bucket Naming

**Pattern**: `corehpc-aws-{account_short}-{env}-{region_short}-infra` (uses SHORT codes)

**Examples**:
- `corehpc-aws-de-dev-use2-infra` (DataEng Dev)
- `corehpc-aws-pt-prod-use2-infra` (Product Prod)
- `corehpc-aws-ne-dev-use2-infra` (Networking Dev)

**Note**: Backend profile is always `core-hpc-sre-{env}` - state stored in SRE account

### Cluster Naming (Kubernetes)

**Pattern**: `aws-{account_short}-{region_short}-{service_type}-{instance}-{env}`

- Example: `aws-sre-use2-svcs-01-prod`
- Example: `aws-pt-use2-platform-01-prod`

## Infrastructure Organization

### Directory Structure (Coregen-Based)

```
{workspace}/
└── {environment}/            # dev or prod (only two levels)
    └── {region}/             # use2, usw2, use1 - not always required
        └── {context}/   # a single context
            ├── {context}-values.yaml # defines which components and jinja values to generate for the context
            └── {component}/  # Individual deployable units for a context
                ├── backend.tf
                ├── any other files required  for the component
                └── Makefile.j2 # always required for a component
```

### Terraform Backend Configuration

**MANDATORY PATTERN**:

```hcl
terraform {
  backend "s3" {
    profile      = "core-hpc-sre-{env}"     # State always in SRE account
    region       = "{region}"
    bucket       = "corehpc-aws-{locale_abbr}-{env}-{region_short}-infra"
    encrypt      = true
    use_lockfile = true
    key          = "{service_path}/terraform.tfstate"
  }
}
```

**Rule**: State ALWAYS stored in `core-hpc-sre-{env}` account, regardless of deployment target.
**Rule**: Always ensure required providers are included and pinned to specific versions.

### Terraform Provider Pattern

```hcl
provider "aws" {
  profile = "core-hpc-{locale}-{env}"  # Deployment target account
  region  = var.region
}

provider "aws" {
  alias   = "secrets"
  profile = "core-hpc-sre-{env}"       # Secrets stored in SRE account
  region  = var.region
}
```

## Coregen Template System

### File Extension Pattern

- **ALL templated files**: Use `.j2` extension (Jinja2)
- **Template location**: `common-templates/{component}/`
- **Values files**: `{context-name}-values.yaml`
- **Generated output**: `output/` directory (gitignored)
- **Committed output**: `for-commit/` (ArgoCD only)

### Values File Structure

```yaml
context:
  name: "{full-context-name}"
  environment: "dev|prod"
  team: "{team_name}"
  region: "{region}"
  region_short: "{region_abbr}"
  component:
    - name: "{component-name}"
      config:
        active: true|false
        priority: 0-10              # Lower deploys first
        required: true|false        # Cannot skip
        for_commit: true|false      # Commit generated code (ArgoCD)
        path: "common-templates/{component}|service/{component}"
      vars:
        # Component-specific variables
```

### Component Priority System

**Standard Priorities** (used in K8s, Databricks):

- 0: Foundation (EKS, Workspace creation)
- 1: Secrets/Auth (External Secrets, credentials)
- 2: Networking (Ingress, DNS)
- 3-4: Security (Cert Manager, PrivateCA)
- 5-6: GitOps (ArgoCD)
- 7: CI/CD (ARC runners)
- 8+: Applications
- `priority: none` = parallel deployment (alphabetical)

## Makefile Standards

### Required Targets

**Local Development**:

```makefile
help          # Display available commands
init          # Initialize Terraform
plan          # Show changes (alias: dry-run)
deploy        # Apply changes interactively (alias: apply)
auto-deploy   # Apply with -auto-approve (alias: auto-apply)
destroy       # Destroy resources
```

**CI/CD Targets**:

```makefile
init-ci       # Initialize without color/input
validate-ci   # Plan with exit code capture
deploy-ci     # Apply with -auto-approve (alias: apply-ci)
fmt-ci        # Check formatting
```

### Standard Makefile Pattern

```makefile
.ONESHELL:
.PHONY: help

##@ Local Targets

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ CI Targets

validate-ci:  ## Terraform plan for CI
	terraform plan -detailed-exitcode -out=tfplan.out || echo $$? > .validation_exitcode
```

## Python Development (Coregen Pattern)

### Project Standards

- **Python version**: 3.11+ ONLY (no backwards compatibility)
- **Package manager**: pip (pyproject.toml for dependencies)
- **Virtual environment**: `.venv/` (checked by `.ci-tools/setup-venv.sh`)
- **Testing**: pytest with pytest-cov, using tox for automation
- **Linting**: black, isort, flake8, pylint, mypy
- **Type Checking**: mypy
- **Pre-commit hooks**: Enforced via pre-commit, requires installation
- **Coverage minimum**: 79% (fail_under = 79)

### Code Quality Tools

```toml
[tool.black]
line-length = 88
target-version = ["py311"]

[tool.isort]
profile = "black"

[tool.mypy]
disallow_untyped_defs = true
disallow_incomplete_defs = true
python_version = "3.11"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--import-mode=importlib -p no:warnings"
markers = [
    "unit: unit tests",
    "integration: integration tests",
    "e2e: end-to-end tests",
    "platform_macos: macOS-only tests",
    "platform_linux: Linux-only tests",
]

[tool.coverage.run]
source = ["source"]
branch = true
fail_under = 79
```

### Test Organization

```
tests/
├── test_cli/           # Mirrors source/cli
├── test_services/      # Mirrors source/services
├── test_common/        # Mirrors source/common
├── fixtures/           # Test data separate from test code
└── conftest.py         # Global fixtures and config
```

## Git & GitHub Workflow

### Branch Strategy

- **Main branch**: `main` (standard), sometimes `development`, `master`, or `dev`, etc.
- **Feature branches**: Work in branches, PR to main
- **Protected branches**: Cannot force push, require reviews

### PR Requirements

- **SRE repos**: 1 code owner approval
- **CI must pass**: No merge without green build
- **Stale reviews**: Dismissed on new commits
- **Delete after merge**: Standard practice

### GitHub Actions Patterns

**Concurrency**:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # PRs only
  # OR
  cancel-in-progress: false # Main deployments (queue instead)
```

**Change Detection**:

- Use coregen `detect-changes` action
- Generates matrix for parallel jobs
- Filters by environment, priority, active status

**Deployment Flow**:

1. PR validation: `terraform plan`, Checkov security scan, TFLint
2. Merge to main: Auto-deploy changed components
3. Production: Manual approval via Slack notification

## Secrets Management

### AWS Secrets Manager Paths

**Pattern**: `{account-secret-is-consumed}/resource-type/{naming_prefix}-{env}/{secret_type}`

**Examples**:

- `sre/databricks/core-hpc-de-use2-prod/account-perms/cicd-prod`
- `dataeng/databricks/core-hpc-de-use2-dev/workspace_metadata`

### Retrieval Pattern

```hcl
data "aws_secretsmanager_secret_version" "credentials" {
  provider  = aws.secrets
  secret_id = "sre/{service}/{context}/{secret_name}"
}

locals {
  credentials = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)
}
```

**Rule**: NEVER hardcode credentials. Always use AWS Secrets Manager via `aws.secrets` provider.
**Rule**: All secrets should be in a secrets.tf file for terraform deployments.

## Tagging Standards

### Required Tags

```hcl
tags = merge(module.infra.tags, {
  Name        = "{resource_name}"
  Environment = "{env}"
  Team        = "{team}"
  ManagedBy   = "terraform"
  Repository  = "{repo_name}"
})
```

### Infra Module Pattern

Every deployment has an `infra/` module providing:

- `naming_prefix`: Standardized naming
- `env`: Environment (dev/prod)
- `tags`: Base tag set for all resources
- `account_id`: AWS account ID
- `region`: AWS region

## CI/CD Tools

### Standard Tools in CI

- **Terraform**: 1.5.0+ (pinned in provider blocks)
- **TFLint**: v0.58.1
- **Checkov**: Latest via GitHub Actions
- **Python detection**: `.ci-tools/detect-python.sh` (fallback: python3.11 → python3 → python)
- **Coregen**: Required for template generation

### Pre-commit Hooks

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    hooks:
      - id: terraform_fmt
  - repo: https://github.com/Yelp/detect-secrets
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
  - repo: https://github.com/psf/black
    hooks:
      - id: black
  - repo: https://github.com/pycqa/isort
    hooks:
      - id: isort
```

## Common Commands

### Terraform Operations

```bash
# Initialize with proper backend
make init

# Plan changes
make plan

# Apply interactively
make deploy

# CI/CD deployment
make init-ci validate-ci deploy-ci
```

### Coregen Operations

```bash
# Generate single cluster
make generate cluster=aws-sre-use2-svcs-01-dev

# Generate and deploy
make generate cluster=aws-sre-use2-svcs-01-dev deploy=true

# Deploy single component
make deploy cluster=aws-sre-use2-svcs-01-dev component=eks auto=true gen=true
```

### Python Development

```bash
# Setup
make setup        # Create .venv, install base deps
make setup-dev    # + pre-commit hooks

# Testing
make test                  # Standard tox run
make test-parallel         # Parallel with pytest-xdist
make test-ci              # CI-specific (skip platform tests)

# Code quality
make lint         # flake8, pylint
make type-check   # mypy
make format       # black + isort
```

## Documentation Standards

### Required Files

- `README.md`: Minimal - setup requirements, AWS SSO commands, state prerequisites
- `CHANGELOG.md`: Semantic versioning with PR numbers
- No extensive docs - code clarity over documentation

### CHANGELOG Format

```markdown
## v1.2.3 - 2025-12-09

### Added
- Feature description (#123)

### Changed
- **BREAKING**: Change description (#124)

### Fixed
- Fix description (#125)
```

---

**Note**: These patterns are extracted from aws-infra-hpc, k8s-infra-hpc, databricks-infra-hpc, coregen-hpc, github-actions-reusable-resources, datadog-monitors-hpc, and terraform-github-hpc repositories.
