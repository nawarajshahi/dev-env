# Claude Code Security Reference

> Quick reference for sandbox configuration and security controls.

## Permission Evaluation Order

```
deny -> ask -> allow -> sandbox
```

1. **deny** - Blocked entirely (highest priority)
2. **ask** - Prompts for confirmation
3. **allow** - Auto-approved
4. **sandbox** - If `autoAllowBashIfSandboxed: true`, auto-approved within constraints

**Key insight**: `ask` takes priority over `allow`. Safe to use broad wildcards in allow (e.g., `Bash(aws:*)`) as long as destructive operations are in ask.

## Security Layers

| Layer | Purpose | Bypass |
|-------|---------|--------|
| deny list | Hard block dangerous commands | Cannot bypass |
| PreToolUse hooks | Scan scripts for dangerous patterns | `.claude/trusted/` or `CLAUDE_ALLOW_DANGEROUS=1` |
| ask list | Require confirmation for destructive ops | User approval |
| sandbox | OS-level filesystem/network isolation | `excludedCommands` or `dangerouslyDisableSandbox` |

## Excluded Commands (Run Outside Sandbox)

Commands in `sandbox.excludedCommands` bypass sandbox automatically:

| Command | Reason |
|---------|--------|
| `docker`, `docker-compose` | Requires `/var/run/docker.sock` |
| `git`, `gh` | Requires SSH keys, credentials, keychain |
| `aws` | Requires network to `*.amazonaws.com` |
| `kubectl`, `helm` | Requires kubeconfig, cluster network |
| `terraform` | Requires provider network, state backends |
| `bash`, `sh`, `python` | Script execution with full system access |

## Destructive Operations (Require Confirmation)

These patterns are in the `ask` list:

- **Git/GitHub**: `git push`, `gh pr create`, `gh repo delete/create`
- **Terraform**: `apply`, `destroy`, `import`, `taint`, `untaint`
- **AWS**: `s3 rm/rb/sync`, `ec2 terminate/stop/delete`, `rds delete/modify`, `iam delete/put/attach`
- **Kubernetes**: `kubectl apply/delete/scale/exec`, `helm install/upgrade/uninstall`
- **Docker**: `docker-compose up/down`
- **Ansible**: `ansible-playbook` (without `--check`)

## Blocked Commands (Deny List)

- `bash -c`, `sh -c` - Inline execution bypass
- `sudo`, `su` - Privilege escalation
- `rm -rf /`, `dd`, `mkfs`, `fdisk` - System destruction
- `shutdown`, `reboot`, `halt` - System availability
- `eval`, `exec` - Arbitrary code execution
- `curl|sh`, `wget|bash` - Remote code execution
- `chmod 777`, `chown -R` - Dangerous permissions

## Script Security

PreToolUse hooks scan scripts for dangerous patterns before execution.

**Bypass options**:
1. Move script to `.claude/trusted/` directory
2. Set `CLAUDE_ALLOW_DANGEROUS=1` environment variable

## Security Profiles

Templates available in `~/.claude/templates/`:

| Profile | Use Case |
|---------|----------|
| `security-strict.json` | Production infra, compliance requirements |
| `security-moderate.json` | Standard development (default) |
| `security-permissive.json` | Sandboxed VMs, containers only |

Copy to `PROJECT/.claude/settings.local.json` to override.

---

**Configuration**: `~/.claude/settings.json`
**Templates**: `~/.claude/templates/`
