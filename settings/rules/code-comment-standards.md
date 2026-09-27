# Code Comment Standards

> **Purpose**: Define professional, maintainable comment practices for enterprise code. Comments must serve future developers, not document the obvious or describe "what" without "why".

## Core Principles

**Comments must be:**
- **Future-developer focused**: Explain WHY, not WHAT the code does
- **Professional**: No casual language, obvious statements, or commit-style descriptions
- **Succinct**: Convey maximum information in minimum words
- **Necessary**: If code is self-explanatory, no comment is needed

## Anti-Patterns (NEVER DO THIS)

### ❌ Commit-Style Comments
```python
# This fixes the issue we were seeing
# Updated to handle edge case
# Changed implementation as requested
```
**Why bad**: These describe process, not code purpose. Belongs in commit messages/PRs.

### ❌ Obvious Statements
```python
# Set the variable to 5
x = 5

# Loop through items
for item in items:
    process(item)

# Call the API
response = api.call()
```
**Why bad**: Code already says this. Comments add no value.

### ❌ Casual/Narrative Explanations
```python
# So basically what we're doing here is checking if the user is logged in
# We want to make sure that only authenticated users can access this
# Otherwise we return an error message to let them know
```
**Why bad**: Verbose, conversational. Professional docs should be concise.

### ❌ Redundant Documentation
```python
def calculate_tax(amount: float) -> float:
    """Calculate tax on amount"""  # Function signature already says this
    return amount * 0.08
```
**Why bad**: Type hints + function name already convey this information.

### ❌ Apologetic/Uncertain Comments
```python
# Not sure if this is the best way, but it works
# TODO: fix this later when we have time
# Quick fix for now
```
**Why bad**: If it's wrong, fix it. If it's temporary, document constraints and create tickets.

## Acceptable Comment Patterns

### ✅ Business Logic Rationale
```python
# Tax exempt for non-profit organizations per IRS Publication 557
if org.non_profit:
    return 0

# Retry with exponential backoff: API rate limit is 10req/min
@retry(wait_exponential_multiplier=1000, stop_max_attempt_number=3)
def call_api():
    ...
```
**Why good**: Explains business rules/external constraints that aren't obvious from code.

### ✅ Non-Obvious Algorithm Choices
```python
# Using binary search: dataset sorted, O(log n) required for <100ms SLA
index = bisect.bisect_left(sorted_data, target)

# SHA-256 required for FIPS 140-2 compliance
hash = hashlib.sha256(data).hexdigest()
```
**Why good**: Explains why specific approach chosen when alternatives exist.

### ✅ Critical Warnings
```python
# CRITICAL: Must acquire lock before modifying shared state (race condition in prod)
with self.lock:
    self.counter += 1

# SECURITY: Input sanitized to prevent SQL injection (OWASP A1)
query = sql.SQL("SELECT * FROM users WHERE id = {}").format(sql.Literal(user_id))
```
**Why good**: Warns about non-obvious but critical consequences.

### ✅ Workarounds with Context
```python
# Workaround: boto3 1.26.x doesn't support AssumeRoleWithWebIdentity retry
# Ticket: JIRA-1234, Remove after boto3 1.28+ upgrade
retry_config = Config(retries={'max_attempts': 3, 'mode': 'standard'})
```
**Why good**: Explains why code exists + provides removal criteria + references ticket.

### ✅ Complex Regex/Math Explanation
```python
# RFC 5322 compliant email: local@domain with optional subdomain
EMAIL_PATTERN = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

# Haversine formula: great-circle distance between lat/long points
distance = 2 * R * asin(sqrt(sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2))
```
**Why good**: Provides context for non-obvious patterns/formulas.

### ✅ API Contract Documentation
```python
def process_webhook(payload: dict) -> None:
    """
    Process Stripe webhook events. Expects payload with:
    - type: str (event.type from Stripe API)
    - data.object: dict (event.data.object)

    Raises:
        ValidationError: Invalid payload structure
        ProcessingError: Payment processing failed (retryable)

    See: https://stripe.com/docs/webhooks
    """
```
**Why good**: Documents external contract, expected structure, failure modes.

## Language-Specific Standards

### Python
- **Docstrings**: Required for public functions/classes (use Google/NumPy style)
- **Type hints**: Prefer type hints over comments explaining types
- **Inline**: Only for non-obvious business logic or algorithmic choices

### HCL/Terraform
```hcl
# MANDATORY: State stored in SRE account for cross-account access
backend "s3" {
  profile = "core-hpc-sre-prod"
}

# EKS 1.28+: Pod security admission enforces restricted policy
pod_security_policy_enabled = true
```

### Makefiles
```makefile
##@ Local Targets  # Section header for `make help`

deploy:  ## Apply with approval (use auto-deploy for CI)
	terraform apply
```

### YAML (K8s/GitHub Actions)
```yaml
# Concurrency: cancel in-progress PR builds, queue main deployments
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

## When to Skip Comments

Skip comments when:
1. **Function/variable names are self-documenting**
   ```python
   # Good: No comment needed
   def calculate_employee_annual_bonus(employee: Employee, year: int) -> Decimal:
       return employee.salary * BONUS_MULTIPLIER
   ```

2. **Type hints convey intent**
   ```python
   # Good: No comment needed
   def parse_config(file_path: Path) -> dict[str, Any]:
       ...
   ```

3. **Code structure is obvious**
   ```python
   # Good: No comment needed
   if user.is_authenticated:
       return redirect('/dashboard')
   return redirect('/login')
   ```

## Comment Removal Checklist

Before committing, scan for and REMOVE:
- [ ] "This fixes...", "Updated to...", "Changed..." (commit-style)
- [ ] "Loop through", "Set variable", "Call function" (obvious)
- [ ] "So basically...", "We want to...", "Let's..." (casual)
- [ ] "Not sure...", "Quick fix...", "TODO" without ticket (uncertain)
- [ ] Commented-out code without explanation
- [ ] Duplicate information already in function signature/types

## Documentation vs. Comments

**Use comments for:**
- In-line explanations of WHY (business logic, algorithms)
- Critical warnings about non-obvious behavior
- Workarounds with context + removal criteria

**Use external docs for:**
- Architecture decisions (ADRs)
- API usage examples (README, docs/)
- Onboarding guides (CONTRIBUTING.md)
- Process explanations (CHANGELOG.md, PR descriptions)

---

**Remember**: The best comment is the one you don't need to write because the code is clear.
