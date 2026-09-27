# Multi-Agent Code Review with Orchestration

## Phase 1: Context Gathering (REQUIRED FIRST)

Before any review begins, establish ground truth:

@agent-agent-orchestration:context-manager

**Context Manager Task:**
1. Identify the specific files/changes to review (use git diff, recent edits, or user-specified scope)
2. Read and summarize the actual code structure
3. Document existing patterns, dependencies, and constraints
4. Create a factual baseline that all reviewers must reference

Output a `CONTEXT_SUMMARY` with:
- Files in scope (with paths)
- Key functions/classes being reviewed
- Detected patterns and conventions
- Any test coverage present

---

## Phase 2: Focused Reviews (Run in Parallel)

Each reviewer MUST:
- **Cite specific file:line references** for every finding
- **Quote actual code** when making claims
- **State confidence level** (high/medium/low) for each finding
- **Mark speculation explicitly** with "[UNVERIFIED]" prefix

### Code Quality & Simplification
@agent-pr-review-toolkit:code-simplifier
Focus: Unnecessary complexity, over-engineering, dead code. Cite specific examples.

### Python Best Practices (if applicable)
@agent-python-development:python-pro
Focus: Pythonic patterns, type hints, performance. Skip if not Python code.

### Developer Experience
@agent-dx-optimizer
Focus: Build/test friction, tooling gaps, workflow issues. Must reference actual commands/configs.

### CLI Design (if applicable)
@agent-cli-developer
Focus: CLI UX, argument handling, help text. Skip if no CLI components.

### Code Quality Pragmatism
@agent-code-quality-pragmatist
Focus: Over-engineering, unnecessary abstractions, YAGNI violations. Cite specific instances.

### Comprehensive Code Review
@agent-comprehensive-review:code-reviewer
Focus: Security, logic errors, edge cases. Every finding needs file:line citation.

---

## Phase 3: Synthesis & Validation

@agent-agent-orchestration:context-manager

**Orchestrator Task:**
1. Compile findings from all reviewers
2. De-duplicate overlapping feedback
3. Flag any claims that lack code citations (potential hallucinations)
4. Categorize by: Critical / Important / Suggestion
5. Produce structured summary

---

## Phase 4: Reality Check (REQUIRED)

@agent-reality-check-manager

**Reality Checker Task:**
1. Verify each "Critical" and "Important" finding against actual code
2. Confirm cited file:line references are accurate
3. Flag any hallucinated or incorrect claims
4. Produce final validated report with:
   - ✓ Verified findings (with evidence)
   - ✗ Rejected findings (with reason)
   - ? Uncertain findings (need manual review)

---

## Output Format

```markdown
## Review Summary

### Context
- Files reviewed: [list]
- Lines of code: [count]
- Test coverage: [if known]

### Critical Issues (Verified)
1. [Issue] - file:line - [evidence quote]

### Important Improvements (Verified)
1. [Issue] - file:line - [evidence quote]

### Suggestions
1. [Suggestion] - [rationale]

### Rejected Findings
1. [Claim] - [why it was incorrect]

### Consensus
[2-3 sentence summary of agreement across reviewers]
```

---

## Anti-Hallucination Rules

1. **No claims without citations** - Every issue must reference actual code
2. **No assumed patterns** - Only report what's in the files
3. **No invented files** - Only reference files that exist
4. **Explicit uncertainty** - Prefix speculation with "[UNVERIFIED]"
5. **Reality check is mandatory** - Never skip Phase 4
6. **Severity requires evidence** - "CRITICAL" claims must prove exploitability, not just theoretical risk
7. **Verify defaults** - Check if code has defensive defaults before claiming validation gaps
8. **Distinguish edge cases** - Note if an issue requires unusual/contrived input to trigger
