# Implement All Proposed Changes with TDD and Verification

Use this skill when you have a list of proposed changes (from analysis, planning, or user request) and want to implement them systematically with full testing and verification.

## Phase 0: Capture Proposed Changes

Before beginning, ensure all proposed changes are documented:

1. **If changes aren't already listed, extract them:**
   - From previous analysis output
   - From user's request
   - From planning document in `.claude/plans/`

2. **Create tracking document:** `.claude/plans/implementation-${timestamp}.md`
   - List ALL proposed changes
   - Mark each as: Pending | In Progress | Completed | Failed
   - This becomes the working document for tracking

3. **Validate scope:**
   - Group related changes that should be implemented together
   - Identify dependencies between changes
   - Flag any changes that need user clarification

**Ask user: "I've identified [N] changes to implement. Should I proceed with all, or would you like to review/modify the list first?"**

---

## Phase 1: Context Establishment (REQUIRED)

@agent-agent-orchestration:context-manager

**Context Manager Task:**
1. Identify all files that will be affected by proposed changes
2. Map existing test coverage for affected areas
3. Document existing patterns and conventions
4. Identify documentation that may need updates
5. Create `CONTEXT_SUMMARY.md` with baseline state

Output must include:
- Files in scope (with paths)
- Current test coverage status
- Documentation files that may need updates
- Any architectural constraints

---

## Phase 2: TDD Setup (When Applicable)

For each change, determine if TDD is appropriate:
- **Yes for:** New features, bug fixes, business logic changes
- **No for:** Config changes, documentation-only, simple refactors

@agent-tdd-workflows:tdd-orchestrator

**TDD Orchestrator Task (per change):**
1. Write failing test FIRST that captures expected behavior
2. Verify test fails for the right reason
3. Document the test in tracking document
4. Output: Test file path, test name, expected failure reason

**Red Phase Output:**
```markdown
### Change: [description]
- Test file: [path]
- Test name: [name]
- Expected failure: [reason]
- Actual failure: [output]
```

---

## Phase 3: Implementation Loop

For EACH change in the tracking document:

### Step 3.1: Implement Change

@agent-feature-dev:code-architect (for architectural decisions)
@agent-code-architect:code-architect (for implementation design)

1. Design the implementation approach
2. Make the code changes
3. Keep changes minimal and focused

### Step 3.2: Make Tests Pass (TDD Green Phase)

@agent-test-writer-fixer:test-writer-fixer

1. Run the failing test from Phase 2
2. Verify it now passes
3. If test still fails, iterate on implementation
4. Run ALL related tests to check for regressions

### Step 3.3: Reality Check (MANDATORY after each change)

@agent-reality-check-manager

**Reality Check Task:**
1. Verify the change actually works (not just compiles)
2. Test the specific behavior that was supposed to change
3. Check for obvious regressions in related functionality
4. Confirm test assertions match actual behavior

**Output:**
```markdown
### Reality Check: [change description]
- Verification method: [how tested]
- Result: PASS | FAIL | PARTIAL
- Evidence: [command output / test result]
- Regressions found: [list or "none"]
```

**If Reality Check FAILS:**
- Do NOT mark change as complete
- Diagnose and fix the issue
- Re-run reality check
- Only proceed when PASS

### Step 3.4: Update Tracking Document

Mark change status:
- Completed (with timestamp)
- Link to commit (if committed)
- Note any follow-up items discovered

---

## Phase 4: Regression Testing

After ALL changes are implemented:

@agent-test-writer-fixer:test-writer-fixer

1. **Run full test suite:**
   ```bash
   # Detect test runner and run all tests
   npm test / pytest / go test ./... / make test
   ```

2. **Analyze failures:**
   - Are they related to our changes?
   - Are they pre-existing failures?
   - Document each failure with file:line

3. **Fix regressions** introduced by our changes

@agent-pr-review-toolkit:pr-test-analyzer

4. **Validate test coverage:**
   - Are new code paths tested?
   - Any critical paths without coverage?
   - Recommend additional tests if needed

---

## Phase 5: Documentation Updates

@agent-code-documentation:docs-architect

**Documentation Task:**
1. Identify documentation that needs updates based on changes made
2. Update inline documentation (docstrings, comments) where needed
3. Update README if user-facing behavior changed
4. Update CHANGELOG.md with change summaries
5. Update any API docs if applicable

**Skip if:**
- Changes are purely internal refactors
- No user-facing behavior changed
- User explicitly opts out

**Ask user: "Documentation updates identified for [list]. Update all, some, or skip?"**

---

## Phase 6: Final Validation

@agent-task-completion-validator

**Validation Task:**
1. Review each change against original requirements
2. Verify all tests pass
3. Confirm no critical issues remain
4. Check that documentation is consistent with code

@agent-reality-check-manager

**Final Reality Check:**
1. End-to-end verification of all changes together
2. Confirm the system works as a whole, not just individual pieces
3. Test edge cases and error scenarios

---

## Phase 7: Code Review (Before Commit)

@agent-pr-review-toolkit:code-reviewer

**Review Focus:**
- Security vulnerabilities introduced
- Performance regressions
- Code quality issues
- Pattern violations

@agent-pr-review-toolkit:silent-failure-hunter

**Silent Failure Check:**
- Inadequate error handling
- Swallowed exceptions
- Missing validation

**If critical issues found:**
- Fix issues before proceeding
- Re-run reality check on fixes
- Do NOT commit with known critical issues

---

## Phase 8: Commit Changes

Only after all phases pass:

1. **Stage related changes together:**
   ```bash
   git add <related-files>
   ```

2. **Commit with meaningful message:**
   - Reference the tracking document
   - Summarize what was implemented
   - Note any breaking changes

3. **Update tracking document** with commit SHA

---

## Phase 9: ELI5 Summary

**Generate a simple summary for the user:**

```markdown
## What We Did (Simple Version)

**Problem:** [1-2 sentences describing what needed to change]

**Solution:** [1-2 sentences describing what we built/fixed]

**Changes Made:**
- [Simple bullet point for each major change]

**Tests Added:**
- [Count] new tests to make sure it keeps working

**What's Different Now:**
- [User-visible behavior change, if any]

**Confidence Level:** HIGH | MEDIUM | LOW
[Brief explanation of confidence]
```

---

## Phase 10: Working Document Offer

**Ask user:**

> "Would you like me to create a working document that tracks everything we did? This includes:
> - All changes made (with file:line references)
> - Tests added
> - Decisions made and why
> - Any known limitations or follow-up items
>
> This is useful for:
> - Onboarding others to these changes
> - Future debugging
> - Compliance/audit trails
>
> Create working document? (Yes/No)"

**If Yes, create:** `.claude/docs/implementation-${date}-summary.md`

Include:
- Full change list with status
- Test coverage summary
- Decisions log
- Known limitations
- Recommendations for future work

---

## Loop Control

**Continue implementing until:**
- All proposed changes are marked Complete
- OR all remaining changes are blocked (document blockers)
- OR user requests stop

**For each iteration:**
1. Pick next Pending change
2. Run phases 3.1-3.4
3. Update tracking document
4. Check if more changes remain
5. If yes, loop back

---

## Anti-Hallucination Rules

1. **Track everything** - Every change must be in the tracking document
2. **Reality check is mandatory** - Never skip Phase 3.3
3. **Tests must actually run** - Show command output, not assumptions
4. **Cite file:line** - Every code reference needs location
5. **Verify, don't assume** - If test "should pass", run it and prove it
6. **Document failures** - If something doesn't work, record it honestly
7. **Ask when uncertain** - If requirements are unclear, stop and ask

---

## Failure Handling

**If implementation fails:**
1. Document the failure reason
2. Mark change as Failed in tracking
3. Ask user: "Change X failed due to [reason]. Options: Retry | Skip | Abort all"

**If tests fail:**
1. Diagnose if it's our change or pre-existing
2. If our change, fix it before proceeding
3. If pre-existing, document and ask user

**If reality check fails:**
1. NEVER proceed to next change
2. Debug and fix
3. Re-run reality check
4. Only continue when PASS

---

## Quick Reference: Agent Responsibilities

| Phase | Agent | Responsibility |
|-------|-------|----------------|
| 1 | context-manager | Establish baseline |
| 2 | tdd-orchestrator | Write failing tests |
| 3.1 | code-architect | Design implementation |
| 3.2 | test-writer-fixer | Make tests pass |
| 3.3 | reality-check-manager | Verify changes work |
| 4 | test-writer-fixer, pr-test-analyzer | Regression testing |
| 5 | docs-architect | Documentation |
| 6 | task-completion-validator, reality-check-manager | Final validation |
| 7 | code-reviewer, silent-failure-hunter | Code review |
