# Update Claude Code Plugins

## Phase 1: Discover Plugin Directories

1. **Find plugin locations:**
   ```bash
   # Check standard locations
   ls -la ~/.claude/plugins/marketplaces/ 2>/dev/null
   ls -la .claude/plugins/ 2>/dev/null
   ```

2. **List all plugin repos:**
   ```bash
   find ~/.claude/plugins -name ".git" -type d 2>/dev/null | xargs -I {} dirname {}
   ```

3. **Record current state** (before updates):
   ```bash
   # For each plugin dir, record current commit
   for dir in $(find ~/.claude/plugins -name ".git" -type d 2>/dev/null | xargs -I {} dirname {}); do
     echo "=== $dir ==="
     git -C "$dir" log --oneline -1
   done
   ```

---

## Phase 2: Update Each Plugin

For each discovered plugin directory:

1. **Check for uncommitted changes:**
   ```bash
   git -C "$dir" status --porcelain
   ```
   - If changes exist, **skip this plugin** and note it

2. **Fetch and pull:**
   ```bash
   git -C "$dir" fetch origin
   git -C "$dir" pull --ff-only
   ```

3. **Record result:**
   - Success: note new commit hash
   - Already up-to-date: note "no changes"
   - Failed: note error message

---

## Phase 3: Summarize Changes

**Output format:**

```
## Plugin Update Summary

### Updated
| Plugin | Previous | Current | Changes |
|--------|----------|---------|---------|
| plugin-name | abc123 | def456 | 3 commits |

### Already Up-to-Date
- plugin-name (at abc123)

### Skipped (local changes)
- plugin-name: uncommitted changes detected

### Failed
- plugin-name: error message
```

---

## Phase 4: Show What Changed (for updated plugins only)

For each plugin that was actually updated:

```bash
git -C "$dir" log --oneline $OLD_COMMIT..$NEW_COMMIT
```

**Only report changes you can verify from git log output.**

---

## Anti-Hallucination Rules

1. **Only report plugins that exist** - Use actual `find` output
2. **Only report changes from git log** - Don't summarize what you think changed
3. **Quote commit messages** - Don't paraphrase
4. **If git pull fails** - Report the actual error, don't guess the cause
5. **Distinguish "updated" from "already current"** - Check if commits actually changed
