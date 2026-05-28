# PR Investigation & Code Review Prompt

Analyze the Git diff between the source branch and target branch.
Identify confirmed issues with confidence scoring (0–100%).

Only report issues that survive re-verification.

---

# Branch Setup

```bash
SOURCE_BRANCH="feature/DPN-103-discover-landing-add-patterns-section"
TARGET_BRANCH="feature/ditto-dev10.6.9"

git fetch origin
git checkout "$TARGET_BRANCH"
git pull

# Review changes introduced by SOURCE into TARGET
git diff --stat "$TARGET_BRANCH..$SOURCE_BRANCH"
git diff --name-only "$TARGET_BRANCH..$SOURCE_BRANCH"
```

---

# Environment Checks

```bash
php --version       # 8.1+
node -v && npm -v   # 16+

composer install
npm install
```

---

# Initial Validation

Run automated checks before reviewing code.

```bash
php artisan test
npm run test -- pimcore-vue-unittest
npm run lint
vendor/bin/phpstan analyse app/ --level=7
```

---

# Review Scope

Focus on:

* Functional correctness
* Runtime errors
* Regressions
* API contract changes
* Security
* Maintainability
* Performance
* Missing test coverage
* Frontend/backend integration consistency

---

# Confidence Scoring

| Confidence | Meaning           | Action         |
| ---------- | ----------------- | -------------- |
| 95–100%    | Definite issue    | 🚫 BLOCK       |
| 85–94%     | Very likely issue | ⚠️ MUST FIX    |
| 70–84%     | Probable issue    | 📋 SHOULD FIX  |
| 50–69%     | Possible issue    | 🔍 INVESTIGATE |
| <50%       | Speculative       | ℹ️ NOTE ONLY   |

Guidelines:

* Failing tests/linter errors increase confidence
* Context-dependent findings reduce confidence
* Intentional design changes reduce confidence
* Issues requiring assumptions should rarely exceed 70%

---

# Review Areas

## PHP / Laravel

Check for:

* Syntax/runtime errors
* Null dereferences
* Incorrect types
* Missing validation
* Exception handling gaps
* Array access without guards
* Broken service/container usage
* DB query regressions
* N+1 query risks
* Queue/job failures
* Migration compatibility
* Authorization/authentication issues

Examples:

```php
$arr['key'] ?? null
```

Avoid blindly replacing with nullsafe operators:

```php
$object?->method()
```

Only use if null is an expected valid state.

---

## Vue Components

Check for:

* Syntax issues
* Missing imports
* Incorrect props/emits
* Reactivity problems
* Infinite watchers
* Async race conditions
* Unhandled promises
* State mutation issues
* Incorrect lifecycle usage
* Rendering regressions

Vue version awareness:

* Vue 2 → `this.$set()`
* Vue 3 → direct reactive assignment

---

## Twig Templates

Check for:

* Undefined variables
* Broken includes/extents
* Invalid conditions
* Missing null guards
* Unsafe HTML rendering
* Cache invalidation issues

Example:

```twig
{% for item in items ?? [] %}
```

---

## Security Checks

Check for:

* XSS risks
* Unsafe `v-html`
* Missing auth checks
* Sensitive data exposure
* CSRF/token issues
* Unsafe uploads
* SQL injection risks
* Debug code left in production

---

## Architecture / Maintainability

Check for:

* Duplicate logic
* Tight coupling
* Violated service boundaries
* Dead code
* Inconsistent patterns
* Large untestable components
* API contract drift
* Missing abstractions

---

## Performance

Check for:

* N+1 queries
* Excessive renders
* Deep watchers
* Large payloads
* Missing caching
* Expensive loops
* Bundle size regressions

---

# Re-Verification Rules (MANDATORY)

For every finding with confidence ≥60%:

## 1. Verify Context

Check surrounding code.

```bash
git diff "$TARGET_BRANCH..$SOURCE_BRANCH" -- path/to/file
```

Inspect at least 20 lines around the issue.

---

## 2. Verify Variable / Method Exists

```bash
grep -r "function methodName" app/
grep -r "\$variable" app/
```

Check:

* parent classes
* traits
* interfaces
* props
* dependency injection

---

## 3. Run Targeted Tests

```bash
php artisan test --filter=TestName
npm run test -- Component.spec.js
```

If tests pass, reduce confidence unless issue remains obvious.

---

## 4. Verify Intent

Check whether change is intentional.

```bash
git log --oneline
git blame path/to/file
```

If behavior matches stated requirements, lower confidence.

---

## 5. Verify Data Flow

Trace source → transformation → usage.

Only report issue if problematic data path is reachable.

---

# Confidence Adjustment Rules

| Scenario                             | Adjustment |
| ------------------------------------ | ---------- |
| Test fails                           | +10%       |
| Linter/static analysis catches issue | +10%       |
| Full context confirms issue          | +10%       |
| Variable exists elsewhere            | -40%       |
| Intentional design choice            | -30%       |
| Test passes successfully             | -20%       |
| Data path unreachable                | -40%       |

If confidence drops below 60% after verification:

* REMOVE issue from report

---

# Output Format

# Code Review Summary

## Overview

* Files changed: X
* Insertions: +X
* Deletions: -X
* Overall risk: LOW | MEDIUM | HIGH | CRITICAL

---

# Confirmed Issues

## 🚫 CRITICAL

### [98%] Example Critical Issue

**Location:** `app/Service/Example.php:42`
**Risk:** CRITICAL
**Why:** Null dereference causes runtime failure.

### Before

```php
$user->profile->name
```

### After

```php
$user->profile?->name
```

### Re-Verification

* Context reviewed ✓
* Tests failed ✓
* Data path confirmed ✓

### Validation

```bash
php artisan test --filter=ProfileTest
```

---

## ⚠️ HIGH

...

---

## 📋 MEDIUM

...

---

## ℹ️ LOW / INFO

...

---

# Tests & Validation

* [ ] PHP tests pass
* [ ] Vue tests pass
* [ ] Lint passes
* [ ] Static analysis passes
* [ ] Build succeeds

---

# Re-Verification Summary

* Initial findings: X
* Removed false positives: X
* Confirmed issues: X

---

# Final Recommendation

✅ APPROVE
⚠️ CONDITIONAL APPROVAL
🚫 REJECT

---

# Helpful Commands

```bash
# Diff summary
git diff --stat "$TARGET_BRANCH..$SOURCE_BRANCH"

# PHP
php artisan test
vendor/bin/phpstan analyse app/ --level=7

# Frontend
npm run test -- pimcore-vue-unittest
npm run lint
npm run build

# File-specific diff
git diff "$TARGET_BRANCH..$SOURCE_BRANCH" -- "*.php"
git diff "$TARGET_BRANCH..$SOURCE_BRANCH" -- "*.vue"
git diff "$TARGET_BRANCH..$SOURCE_BRANCH" -- "*.twig"
```
