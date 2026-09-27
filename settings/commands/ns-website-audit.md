# Website Quality & UX Audit

Perform a comprehensive audit of the website codebase, analyzing code quality, architecture, maintainability, and UX design. Save findings to a dated report.

## Output Configuration

**Report file**: `website-audit-{{DATE}}.md` (where {{DATE}} is today's date in YYYY-MM-DD format)
**Location**: Current working directory or `.claude/audits/` if it exists

---

## Phase 1: Codebase Discovery

First, understand the project structure:

1. **Identify the tech stack**:
   - Framework (React, Vue, Svelte, Next.js, Nuxt, Astro, etc.)
   - CSS approach (Tailwind, CSS Modules, Styled Components, SCSS, vanilla)
   - Build tools (Vite, Webpack, Turbopack, esbuild)
   - Package manager and dependencies

2. **Map the architecture**:
   - Directory structure and organization
   - Component hierarchy
   - Routing strategy
   - State management approach
   - API/data fetching patterns

3. **Locate key files**:
   - Entry points
   - Configuration files
   - Shared components/utilities
   - Style definitions
   - Type definitions (if TypeScript)

---

## Phase 2: Code Quality Audit

Analyze each area and assign a grade (A/B/C/D/F) with specific findings:

### 2.1 Code Organization
- [ ] Clear separation of concerns
- [ ] Consistent file/folder naming conventions
- [ ] Logical component grouping
- [ ] Appropriate use of index files
- [ ] No deeply nested structures (max 3-4 levels)

### 2.2 Component Quality
- [ ] Single responsibility principle
- [ ] Appropriate component size (< 200 lines preferred)
- [ ] Props interface clarity
- [ ] Minimal prop drilling
- [ ] Proper use of composition vs inheritance

### 2.3 Code Simplicity
- [ ] No over-engineering or premature abstraction
- [ ] Clear, readable logic flows
- [ ] Appropriate use of utilities/helpers
- [ ] No unnecessary complexity
- [ ] DRY without over-abstraction

### 2.4 Type Safety (if applicable)
- [ ] Consistent type definitions
- [ ] No excessive `any` usage
- [ ] Proper interface/type exports
- [ ] Generic types used appropriately

### 2.5 Error Handling
- [ ] Graceful error boundaries
- [ ] User-friendly error states
- [ ] Proper async error handling
- [ ] No silent failures

### 2.6 Performance Patterns
- [ ] Appropriate memoization
- [ ] Lazy loading for routes/components
- [ ] Image optimization
- [ ] Bundle size awareness
- [ ] No unnecessary re-renders

---

## Phase 3: Maintainability Assessment

### 3.1 Developer Experience
- [ ] Clear README with setup instructions
- [ ] Consistent code formatting (Prettier/ESLint)
- [ ] Meaningful commit history
- [ ] Environment configuration clarity

### 3.2 Testability
- [ ] Test file presence and coverage
- [ ] Testable component design
- [ ] Mock/stub patterns
- [ ] E2E test setup

### 3.3 Documentation
- [ ] Component documentation (Storybook, JSDoc)
- [ ] API documentation
- [ ] Architecture decision records
- [ ] Inline comments where necessary (not excessive)

### 3.4 Dependency Health
- [ ] No outdated critical dependencies
- [ ] No known vulnerabilities
- [ ] Reasonable dependency count
- [ ] Lock file present and committed

---

## Phase 4: Architecture Review

### 4.1 Scalability Patterns
- [ ] Feature-based or domain-driven structure
- [ ] Clear module boundaries
- [ ] Appropriate abstraction layers
- [ ] Extensibility considerations

### 4.2 Data Flow
- [ ] Predictable state management
- [ ] Clear data fetching strategy
- [ ] Caching approach
- [ ] Optimistic updates where appropriate

### 4.3 Security Considerations
- [ ] No secrets in client code
- [ ] XSS prevention patterns
- [ ] CSRF protection (if applicable)
- [ ] Input sanitization
- [ ] Secure authentication flow

### 4.4 SEO & Accessibility Foundations
- [ ] Semantic HTML structure
- [ ] Meta tags and Open Graph
- [ ] Sitemap/robots.txt
- [ ] Structured data (JSON-LD)

---

## Phase 5: UX/UI Design Audit

### 5.1 Visual Consistency
- [ ] Consistent spacing system
- [ ] Typography hierarchy
- [ ] Color palette adherence
- [ ] Icon consistency
- [ ] Component visual language

### 5.2 Responsive Design
- [ ] Mobile-first approach
- [ ] Breakpoint consistency
- [ ] Touch target sizes (min 44x44px)
- [ ] Viewport handling
- [ ] Orientation support

### 5.3 Accessibility (WCAG 2.1)
- [ ] Color contrast ratios (4.5:1 text, 3:1 UI)
- [ ] Keyboard navigation
- [ ] Screen reader compatibility
- [ ] Focus indicators
- [ ] ARIA labels where needed
- [ ] Alt text for images
- [ ] Form label associations

### 5.4 User Experience Patterns
- [ ] Clear navigation hierarchy
- [ ] Consistent interaction patterns
- [ ] Loading states and skeletons
- [ ] Empty states
- [ ] Error states with recovery actions
- [ ] Success feedback
- [ ] Form validation UX

### 5.5 Performance UX
- [ ] Perceived performance (skeleton screens, optimistic UI)
- [ ] Core Web Vitals consideration (LCP, FID, CLS)
- [ ] Progressive enhancement
- [ ] Offline handling (if PWA)

---

## Phase 6: Specific Recommendations

For each finding, provide:

1. **Issue**: What was found
2. **Location**: File path and line numbers
3. **Severity**: Critical / High / Medium / Low
4. **Recommendation**: Specific fix or improvement
5. **Example**: Code snippet showing the improvement (when applicable)

---

## Report Template

Generate the report in this format:

```markdown
# Website Audit Report
**Date**: [TODAY'S DATE]
**Project**: [PROJECT NAME]
**Tech Stack**: [IDENTIFIED STACK]

## Executive Summary
[2-3 paragraph overview of findings, overall health, and priority actions]

## Grades Overview
| Area | Grade | Key Finding |
|------|-------|-------------|
| Code Organization | | |
| Component Quality | | |
| Code Simplicity | | |
| Maintainability | | |
| Architecture | | |
| UX/UI Design | | |
| Accessibility | | |
| Performance | | |

## Critical Issues (Fix Immediately)
[List with file locations and specific recommendations]

## High Priority Improvements
[List with file locations and specific recommendations]

## Medium Priority Improvements
[List with file locations and specific recommendations]

## Low Priority / Nice-to-Have
[List with file locations and specific recommendations]

## Architecture Recommendations
[Structural improvements, refactoring suggestions]

## UX/UI Recommendations
[Design improvements, interaction enhancements]

## Accessibility Fixes Required
[WCAG compliance issues with specific remediation]

## Performance Opportunities
[Optimization suggestions with expected impact]

## Positive Findings
[What the codebase does well - important for morale and to preserve good patterns]

## Appendix: Files Reviewed
[List of key files examined during audit]
```

---

## Execution Instructions

1. **Start with discovery** - understand the full project before judging
2. **Be specific** - every finding needs a file path and actionable recommendation
3. **Prioritize ruthlessly** - not everything is critical
4. **Balance criticism with praise** - note what works well
5. **Consider context** - startup MVP vs enterprise has different standards
6. **Focus on impact** - what changes will most improve the codebase?

After completing the audit, save the report to the dated file and provide a brief verbal summary of the top 3-5 priority items.
