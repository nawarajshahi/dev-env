# Fix Issue #$ARGUMENTS

## Phase 1: Understand the Issue (REQUIRED FIRST)

1. **Fetch issue details:**
   ```bash
   gh issue view $ARGUMENTS
   ```

2. **Document issue facts** (quote directly, don't paraphrase):
   - Title
   - Description/reproduction steps
   - Expected vs actual behavior
   - Any linked PRs or related issues

3. **Identify scope:**
   - What component/module is affected?
   - Is this a bug fix, feature, or refactor?

---

## Phase 2: Locate Relevant Code

1. **Search for related code:**
   - Use Grep to find error messages, function names, or keywords from the issue
   - Use Glob to find files in the suspected area

2. **Read and understand:**
   - Read the files that appear relevant
   - Trace the code path that triggers the issue
   - Note any existing tests for this area

3. **Verify you found the right code:**
   - Can you explain how the current code causes the issue?
   - If not, keep searching before proceeding

---

## Phase 3: Plan Solution

1. **Create plan document:** `.claude/plan-issue-$ARGUMENTS.md`

2. **Document in the plan:**
   - Root cause (cite specific file:line)
   - Proposed fix (be specific about what changes)
   - Files to modify
   - Potential side effects
   - How you'll verify the fix

3. **STOP and discuss with user:**
   - Present the plan
   - Ask: "Does this approach make sense? Any concerns?"
   - **Do not proceed without user approval**

---

## Phase 4: Implement

1. **Create feature branch:**
   ```bash
   git checkout -b fix/issue-$ARGUMENTS
   ```

2. **Make the fix:**
   - Follow existing code patterns
   - Make minimal changes to solve the issue
   - Add inline comments only if logic is non-obvious

3. **Self-review:**
   - Re-read your changes
   - Does this actually fix the root cause from Phase 3?

---

## Phase 5: Verify Fix

**CRITICAL: Do not skip this phase**

1. **Manual verification:**
   - Reproduce the original issue (confirm it exists on main)
   - Apply fix and confirm issue is resolved
   - Test related functionality for regressions

2. **Run existing tests:**
   ```bash
   # Adjust command for project's test framework
   npm test / pytest / go test ./...
   ```

3. **If verification fails:**
   - Do NOT commit
   - Return to Phase 3 and revise plan

---

## Phase 6: Commit Fix

1. **Stage and commit:**
   ```bash
   git add <changed-files>
   git commit -m "fix: description of fix

   Closes #$ARGUMENTS"
   ```

2. **Constraints:**
   - No `--no-verify`
   - No AI attribution
   - Reference the issue number

---

## Phase 7: Add/Update Tests

1. **Write test that would have caught this bug:**
   - Test should fail without the fix
   - Test should pass with the fix

2. **Run full test suite** to ensure no regressions

3. **Commit tests separately:**
   ```bash
   git add <test-files>
   git commit -m "test: add test for issue #$ARGUMENTS"
   ```

---

## Phase 8: Prepare PR

1. **Generate PR description:**
   - Use `/sk-pr-description` or write manually
   - Include: problem, solution, testing done
   - Reference: `Fixes #$ARGUMENTS`

2. **Output PR description** in markdown code block for easy copying

---

## Anti-Hallucination Rules

1. **Quote the issue** - Don't paraphrase or assume details
2. **Cite code locations** - Every claim about code needs file:line
3. **Verify before committing** - Manual test is mandatory
4. **Get approval for plan** - Don't implement without user sign-off
5. **Test proves fix** - If you can't verify, you're not done
