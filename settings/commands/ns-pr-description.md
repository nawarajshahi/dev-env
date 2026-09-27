# Generate PR Description

## Phase 1: Gather Facts (REQUIRED FIRST)

1. **Identify base branch:**
   ```bash
   git branch --show-current
   git log --oneline main..HEAD 2>/dev/null || git log --oneline master..HEAD 2>/dev/null || git log --oneline develop..HEAD
   ```

2. **Get complete change set:**
   ```bash
   # All commits in this branch
   git log --oneline $(git merge-base main HEAD)..HEAD

   # Full diff summary
   git diff --stat $(git merge-base main HEAD)..HEAD

   # Detailed diff (read this!)
   git diff $(git merge-base main HEAD)..HEAD
   ```

3. **Check for linked issues:**
   - Look for issue references in commit messages
   - Check branch name for issue numbers (e.g., `fix/issue-123`)

---

## Phase 2: Analyze Changes

Review ALL commits, not just the latest:

1. **Categorize changes:**
   - New features added
   - Bugs fixed
   - Refactoring done
   - Dependencies changed
   - Config/infra changes

2. **Identify the "why":**
   - What problem does this solve?
   - What business value does it provide?
   - Why was this approach chosen?

3. **Note concerns:**
   - Breaking changes?
   - Migration required?
   - Deployment considerations?
   - New dependencies?

---

## Phase 3: Write Description

**Output format:** Use the repo's pull_request_template.md.

If there is no pull_request_template.md, use the following format:

```markdown
## Summary and Changes

[1-3 bullet points explaining WHAT changed and WHY]

- [Specific change 1]
- [Specific change 2]
- [...]

## Impact

[Breaking changes, deployment steps, or other considerations - omit section if none]

```

---

## Guidelines

Be as succint, clear and concise  as possible while covering all important aspects.

1. **Focus on "why" over "what"** - The diff shows what; explain why
2. **Be concise** - High-level summary, not line-by-line changelog
3. **ALL commits matter** - Don't just describe the latest commit
4. **Cite specifics** - If mentioning a file/function, be precise
5. **No fluff** - Skip phrases like "This PR..." or "In this change..."

---

## Anti-Hallucination Rules

1. **Only describe changes you see in the diff** - Don't invent features
2. **Quote commit messages** if summarizing intent
3. **Verify issue references exist** before including them
4. **If unsure about "why"** - Ask user rather than guessing
