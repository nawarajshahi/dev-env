# SRE Practices & Operational Patterns - HPC Infrastructure

> **Purpose**: Actual SRE practices from datadog-monitors-hpc and operational patterns across HPC infrastructure.

## Monitoring & Observability

### Observability Stack
- **Metrics & Monitoring**: Datadog (primary)
- **Alerting**: Datadog Monitors → PagerDuty
- **Service Checks**: HTTP checks for Ignition Gateways, Genetec
- **Query Alerts**: Metrics-based thresholds (AWS Outposts, backups)

### Monitor Naming Convention
**Pattern**: `[SERVICE] Description`

**Examples**:
- `[AWS Outpost] Disconnected`
- `[Ignition] Host ${instance_name} is down`
- `[Ignition] EAM controller disconnected from agent`
- `[Ignition] Backup freshness`
- `[${env}] Ignition Gateway Availability`

### Monitor Resource Naming
**Pattern**: `{service_prefix}_{description_snake_case}`

**Examples**:
- `aws_outposts_connection`
- `ig_gw_host_is_down`
- `ig_hub_eam_connections`
- `ignition_backup_coverage`

### Tagging Standards
**Mandatory tags for all monitors**:
```hcl
tags = [
  "team:sre",                    # or team:security-ops
  "service:{service_name}",      # service:ignition, service:ebs
  "env:${env}",                  # env:prod, env:dev
  "dc:${datacenter}",           # dc:aus1, dc:mbl1 (optional)
  "locale:${locale}",           # locale:aws, locale:outpost
]
```

### Threshold Patterns

**Service Checks** (HTTP/host monitoring):
```hcl
monitor_thresholds {
  critical = 3    # Strict: requires 3 consecutive failures
  warning  = 2
  ok       = 1
}
# OR
monitor_thresholds {
  critical = 2    # Medium: requires 2 consecutive failures
  warning  = 1
  ok       = 1
}
```

**Query Alerts** (metric-based):
```hcl
# Binary state (connected/disconnected)
monitor_thresholds {
  critical = 1
}

# Percentage-based (coverage)
monitor_thresholds {
  critical = 95   # Alert if < 95%
}

# Time-based (freshness)
monitor_thresholds {
  critical = 172800  # 2 days in seconds
}
```

### Timing Configuration

**New Group Delay** (suppress alerts for new instances):
- `0` seconds: Immediate escalation (Ignition Gateways - critical)
- `30` seconds: Quick escalation (Genetec)
- `300` seconds: Standard delay (AWS Outposts, Ignition Hub, EBS) - **DEFAULT**

**No Data Handling**:
- `no_data_timeframe = 2`: 2 minutes (Ignition Gateways - quick detection)
- `no_data_timeframe = 10`: 10 minutes (Ignition availability)
- `no_data_timeframe = 15`: 15 minutes (Genetec)
- `notify_no_data = true`: Escalate on missing data (host down scenarios)
- `notify_no_data = false`: Don't escalate (metrics gaps acceptable)

**Renotification**:
- `renotify_interval = 30`: Every 30 minutes during ongoing incident
- `renotify_interval = 60`: Every hour for less critical issues

### Query Window Patterns
- `last_5m`: Recent event monitoring (EAM connections, backup freshness)
- `last_15m`: AWS metrics aggregation
- `last_1h`: Capacity/throughput checks (Outposts)
- `last_1d`: Aggregate failure checking (EBS snapshots)

### Service Level Objectives

**Standard SLO Pattern**:
```hcl
resource "datadog_service_level_objective" "service_name" {
  name        = "{Service Name} - {Datacenter}"
  type        = "monitor"
  monitor_ids = data.datadog_monitors.filtered.monitors[*].id

  thresholds {
    timeframe = "30d"
    target    = 99.9    # 99.9% uptime target (STANDARD)
    warning   = 0       # 0% error budget warning
  }

  tags = ["team:sre", "service:{name}"]
}
```

**Monitor Aggregation for SLOs**:
```hcl
data "datadog_monitors" "ig_gw_aus1" {
  monitor_tags_filter = ["dc:aus1", "service:ignition"]
  depends_on          = [datadog_monitor.ig_gw_host_is_down]
}
```

### Notification Routing

**PagerDuty Integration**:
```hcl
message = <<EOT
{{#is_alert}}
Issue detected on {{host.name}}
{{/is_alert}}

{{#is_recovery}}
{{host.name}} has recovered
{{/is_recovery}}

@pagerduty-sre-hpc-static
@pagerduty-hpc-datacenter-ops-${datacenter}
EOT
```

**Dynamic Routing** (datacenter-based):
```hcl
# Extract datacenter from instance name
locals {
  datacenter = split("_", each.key)[0]  # "aus1_ig_prod_01" → "aus1"
}

# Route to datacenter-specific PagerDuty service
@pagerduty-hpc-datacenter-ops-${local.datacenter}
```

### Monitor Organization

**File Organization** (by service):
- `monitors-aws-outposts.tf`: AWS Outposts connectivity & capacity (3 monitors)
- `monitors-ignition-gateways.tf`: Ignition Gateway health checks (5 monitors + SLO)
- `monitors-ignition-hubs.tf`: Ignition Hub EAM & backups (5 monitors + SLO)
- `monitors-genetec.tf`: Genetec Security Center (monitors)
- `monitors-ebs-snapshots.tf`: AWS EBS backup operations (monitors)

**Parameterization Pattern**:
```hcl
variable "ig_gws" {
  type    = set(any)
  default = ["aus1_ig_prod_01", "aus1_ig_prod_02", "mbl1_ig_prod_01"]
}

resource "datadog_monitor" "ig_gw_host_is_down" {
  for_each = var.ig_gws
  name     = "[Ignition] Host ${each.key} is down"
  # ... monitor configuration
}
```

### Security & Audit

**Required Configuration**:
```hcl
restricted_roles = [data.datadog_role.admin_role.id]  # Admin-only edits
notify_audit     = true                                # Track all changes
include_tags     = true                                # Include tags in notifications
```

## Incident Response

### Service Impact Levels
Based on monitor configurations:
- **Critical (SEV1)**: Service down, immediate PagerDuty escalation
  - Ignition Gateway unavailable (new_group_delay = 0)
  - AWS Outpost disconnected
  - Genetec system failure

- **Warning (SEV2)**: Degraded service, page during business hours
  - EAM controller disconnected
  - Backup freshness > 2 days
  - Capacity approaching limits

- **Info**: Monitoring alerts, no immediate action
  - Metrics collection gaps (notify_no_data = false)

### Datacenter-Specific Escalation
- **aus1**: @pagerduty-hpc-datacenter-ops-aus1
- **mbl1**: @pagerduty-hpc-datacenter-ops-mbl1
- **dto1**: @pagerduty-hpc-datacenter-ops-dto1
- **Global**: @pagerduty-sre-hpc-static

## Deployment Safety

### Terraform State Management
```hcl
terraform {
  backend "s3" {
    profile      = "core-hpc-sre-prod"
    region       = "us-east-2"
    bucket       = "corehpc-aws-sre-prod-use2-infra"
    key          = "datadog-monitors/terraform.tfstate"
    use_lockfile = true
  }
}
```

### Secrets Management
**Datadog API Credentials**:
```hcl
module "common" {
  source = "../common"  # Retrieves credentials from AWS Secrets Manager
}

provider "datadog" {
  api_key = module.common.datadog_api_key
  app_key = module.common.datadog_app_key
}
```

**Pattern**: All credentials via AWS Secrets Manager, never hardcoded.

### Deployment Workflow
1. **PR Validation**: `terraform plan` + Checkov security scan
2. **Merge to main**: Auto-apply monitors (low-risk changes)
3. **Review**: All changes audited via `notify_audit = true`

## Backup & Monitoring

### Backup Monitoring Patterns

**Freshness Check**:
```hcl
query = "max(last_5m):max:ignition.backup.seconds_since_last{env:prod} > 172800"
# Alert if > 2 days (172800 seconds) since last backup
```

**Coverage Check**:
```hcl
query = "100 * (sum:ignition.backup.ok{env:prod}.as_count() / sum:ignition.backup.total{env:prod}.as_count()) < 95"
# Alert if < 95% of gateways have successful backups
```

**Snapshot Failures** (EBS):
```hcl
query = "sum(last_1d):sum:aws.ebs.snapshot.failure{*}.as_count() > 0"
# Alert on ANY snapshot failure in last 24 hours
```

## Capacity Planning

### AWS Outpost Monitoring
```hcl
# Connectivity
query = "max(last_1h):max:aws.outposts.connection{*} < 1"

# Capacity Utilization
query = "max(last_1h):max:aws.outposts.capacity.utilization{*} > 90"
```

**Pattern**: Alert at 90% capacity for proactive scaling.

## Multi-Environment Patterns

### Environment-Specific Monitors
```hcl
resource "datadog_monitor" "ignition_availability" {
  for_each = toset(["dev", "prod"])
  name     = "[${each.key}] Ignition Gateway Availability"

  query = "avg(last_10m):avg:ignition.gateway.status{env:${each.key}} < 1"

  tags = ["team:sre", "service:ignition", "env:${each.key}"]
}
```

### Datacenter-Specific Monitoring
```hcl
variable "hpc_sites" {
  type    = set(any)
  default = ["aus1", "mbl1", "dto1"]
}

# Create per-datacenter SLOs
resource "datadog_service_level_objective" "ig_gw" {
  for_each = var.hpc_sites
  name     = "Ignition Gateways - ${upper(each.key)}"
  # ...
}
```

## Change Management

### Monitor Lifecycle
```hcl
lifecycle {
  prevent_destroy = false  # Monitors can be destroyed (unlike infra)
}
```

**Pattern**: Monitors are code - can be destroyed/recreated safely.

### Makefile Automation
```makefile
.PHONY: init plan apply destroy

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply

deploy-ci:  # CI/CD auto-apply
	terraform apply -auto-approve

validate-ci:  # CI/CD validation
	terraform plan -detailed-exitcode || echo $$? > .validation_exitcode
```

## HPC Site Patterns

### Site Identifiers
- **aus1**: Austin site 1
- **aub1**: Auburn site 1
- **dto1**: Dayton site 1
- **dnn1**: Dunn site 1
- **mbl1**: Mobile site 1
- **msk1**: Muskegon site 1

### On-Premises vs Cloud
- **Locale tags**: `locale:outpost` (on-prem) vs `locale:aws` (cloud)
- **Networking**: VPC integration for outpost connectivity
- **Monitoring**: Separate monitor groups per locale

---

**Note**: These patterns are extracted from actual datadog-monitors-hpc repository and represent production monitoring practices for HPC infrastructure.
