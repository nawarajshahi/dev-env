---
description: Sync current branch with remote
---

Safely sync the current branch with its remote tracking branch:

1. Check if there are uncommitted changes - if so, warn and stop
2. Fetch from remote
3. Show comparison between local and remote (commits ahead/behind)
4. If branch is behind, offer to pull with rebase
5. If branch is ahead, remind me I can push
6. If branch has diverged, explain the situation and suggest next steps

Don't automatically push or pull - just prepare and inform.
