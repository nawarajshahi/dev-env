---
description: Clean up merged/stale branches
---

Help me clean up local git branches:

1. List all local branches
2. Identify which have been merged to main/master
3. Identify which have been deleted on remote (show as [gone])
4. Show last commit date for each branch
5. Suggest which branches are safe to delete

**DO NOT delete any branches automatically** - just show the analysis and suggest commands I can run.

Format output as:
- Safe to delete (merged branches)
- Probably safe (gone from remote)
- Active (recent commits)
- Needs review (unmerged with old commits)
