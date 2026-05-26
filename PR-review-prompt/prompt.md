# Git Diff Code Review Prompt (Complete)
## With Confidence Scoring & False Positive Prevention

---

## Overview
Analyze git diff changes with confidence scoring (0-100%). Score = certainty of issue existence. Re-verify all 60%+ findings to prevent false positives.

---

## Prerequisites
```bash
git fetch origin
php --version          # 8.1+
node -v && npm -v      # 16+
composer install && npm install
```

---

## Branches
- **BASE:** `feature/DPN-103-discover-landing-add-patterns-section`
- **COMPARE:** `feature/ditto-dev10.6.9`

---

## Quick Start

### 1. Scope Assessment
```bash
git diff --stat BASE..COMPARE
git diff --name-only BASE..COMPARE | grep -E '\.(php|vue|twig|js)$'
```

### 2. Run Tests First
```bash
php artisan test
npm run test -- pimcore-vue-unittest
npm run lint
vendor/bin/phpstan analyse app/ --level=7
```

---

## Confidence Scoring

| Score | Meaning | Action |
|-------|---------|--------|
| **95-100%** | Definite error (syntax, null ref) | 🚫 BLOCK |
| **85-94%** | Very likely (logic error clear) | ⚠️ MUST FIX |
| **70-84%** | Probable (missing validation) | 📋 SHOULD FIX |
| **50-69%** | Possible (depends on context) | 🔍 INVESTIGATE |
| **<50%** | Speculative | ℹ️ NOTE |

**Boost confidence:** Linter catches it (+5%), test fails (+10%), obvious in code (+15%)  
**Lower confidence:** Needs testing (-20%), edge case (-15%), context-dependent (-10%)

---

## Check for Issues

### PHP Backend
```bash
# Files: *.php
git diff BASE..COMPARE -- "*.php" | grep -E "^[\+\-]"
```

**Critical (95%+):**
- Syntax errors, missing semicolons
- Undefined vars: `$var->method()` without null check → **Fix:** `$var?->method()`
- Type mismatches in params
- Missing exception handling

**High (85-94%):**
- Array key access without isset: `$arr['key']` → **Fix:** `$arr['key'] ?? default`
- Changed validation rules vs DB constraints
- Deprecated API usage

**Medium (70-84%):**
- Logic changes: `if ($x == 'a')` → `if ($x == 'b')`
- Removed caching

---

### Twig Templates
```bash
# Files: *.twig
git diff BASE..COMPARE -- "*.twig" | grep -E "^[\+\-]"
```

**Critical (95%+):**
- Undefined variables: `{{ $var }}` not passed from controller
- Missing template includes/extends
- Syntax errors: `{% if x = 'a' %}` (should be `==`)

**High (85-94%):**
- Loop without null check: `{% for item in items %}` but items can be null → **Fix:** `{% for item in items ?? [] %}`
- Missing custom filter registration

**Medium (70-84%):**
- Condition changed meaning
- Missing cache invalidation

---

### Vue Components
```bash
# Files: *.vue
git diff BASE..COMPARE -- "*.vue" | grep -E "^[\+\-]"
```

**Critical (95%+):**
- Syntax errors (missing tags/brackets)
- Undefined props/emits in child
- Broken reactivity: assigning to array without `$set()` → **Fix:** `this.$set(arr, i, val)` or Vue 3 `ref()`

**High (85-94%):**
- Missing imports: `computed` used but not imported
- Prop type mismatch
- Unhandled promises → **Fix:** `.catch(err => this.error = err)`
- Watcher modifies same data (infinite loop)

**Medium (70-84%):**
- Missing computed deps (Vue 2 Options API)
- Lifecycle race conditions
- Deep watchers on large objects

---

### Unit Tests
```bash
# Files in: resources/js/pimcore-vue-unittest/
npm run test -- pimcore-vue-unittest --verbose
```

**Issues:**
- ❌ Tests failing → confidence 99%
- Mount props mismatch with component change → confidence 92%
- Mock API responses stale → confidence 88%
- Async test not awaiting → confidence 95%
- Selector doesn't match HTML → confidence 98%
- Snapshot updated but behavior wrong → confidence 80%
- New logic without test → confidence 75% (incomplete coverage)

---

## Risk Matrix

```
CRITICAL: 95%+ conf + crash/data loss
HIGH: 85-94% conf + feature broken
MEDIUM: 70-84% conf + edge case
LOW: 50-69% conf + unlikely to trigger
INFO: <50% conf + awareness only
```

---

## Issue Template

```
[XX%] Issue Title

**Location:** file.php:line | component.vue:line | template.twig:line
**Confidence:** XX% (why?)
**Risk:** CRITICAL | HIGH | MEDIUM | LOW
**Issue:** [What's wrong]

Before:
```code
...
```

After:
```code
...
```

**Verify:** [Test command]
**Effort:** [5 min | 30 min | 2h]
```

---

## ⚠️ FALSE POSITIVE PREVENTION (MANDATORY FOR 60%+ CONFIDENCE)

**For ANY issue with confidence ≥60%, run re-verification before reporting.**

### Re-Verification Decision Tree

```
Found Issue (Confidence ≥60%)
    ↓
[1] Check Code Context
    Is variable/method defined somewhere?
    ├─ YES → Confidence -50% (FALSE POSITIVE)
    └─ NO → Continue
    ↓
[2] Run Targeted Test
    Does feature/component work correctly?
    ├─ YES (test passes) → Confidence -20% (LOWER CONFIDENCE)
    └─ NO (test fails) → Continue
    ↓
[3] Check Intent
    Is change intentional? (commit msg, PR desc)
    ├─ YES → Confidence -25% (DESIGN CHOICE)
    └─ NO → Continue
    ↓
[4] Verify Data Flow
    Does data actually reach problem point?
    ├─ NO (data never used) → Confidence -30%
    └─ YES → CONFIRMED ISSUE ✓
```

### Quick Re-Verify Commands

```bash
# 1. Check variable exists
git show COMPARE:[file] | grep -E "^\s*\\\$variable\s*=|function.*variable"
git diff BASE..COMPARE -- [file] | grep -B 5 "\$variable"

# 2. Check method exists
grep -r "public function methodName" app/ --include="*.php"
php -r "echo method_exists('ClassName', 'methodName') ? 'EXISTS' : 'NOT FOUND';"

# 3. Run affected tests
npm run test -- ComponentName.spec.js --verbose
php artisan test --filter=TestClassName::testMethod

# 4. Check context
git show COMPARE:[file] | grep -B 20 -A 20 "suspicious_pattern"
git diff BASE COMPARE -- [file] | grep -B 10 -A 10 "issue_line"

# 5. Check git history
git log -p --all -S "similar_pattern" | head -100
git blame COMPARE:[file] | grep "issue_line"
```

### Confidence Adjustment After Re-Verification

| Finding | Re-Test Result | New Confidence | Action |
|---------|---|---|---|
| Undefined var (78%) | Variable actually passed | 20% ↓ | REMOVE |
| Null dereference (92%) | Null check exists elsewhere | 40% ↓ | Downgrade to INFO |
| Logic error (85%) | Behavior intentional | 35% ↓ | Note as design choice |
| Missing test (75%) | New code untestable | 75% ✓ | KEEP as-is |
| Async error (88%) | Error handler exists | 25% ↓ | REMOVE |
| Missing method (90%) | Method in parent class | 30% ↓ | REMOVE |

### Common False Positives & How to Spot Them

**1. Variable Looks Undefined But Passed Via Props**
```javascript
// Component uses: {{ filterTerm }}
// Looks undefined! → Initial: 78%
// Re-verify: git show COMPARE:component.vue | grep "props:"
// Found: props: { filterTerm: String }
// Result: FALSE POSITIVE → 20%
```

**2. Method Doesn't Exist In Child But In Parent**
```php
// Calls: $this->formatDate()
// Looks missing! → Initial: 85%
// Re-verify: grep -r "function formatDate" app/
// Found in parent class
// Result: FALSE POSITIVE → 25%
```

**3. Test Fails In Diff But Passes When Run**
```javascript
// Mock looks stale → Initial: 88%
// Re-verify: npm run test -- ComponentTest.spec.js
// Result: ✓ Test passes
// Result: FALSE POSITIVE → 30%
```

**4. Logic Changed But Change Is Intentional**
```php
// - if ($status === 'draft')
// + if ($status === 'published')
// Looks wrong! → Initial: 85%
// Re-verify: git log | grep "Change default filter"
// Found: PR "Change default to published"
// Result: INTENTIONAL → 35%
```

**5. Variable Used Later In Code**
```php
// $config = $this->getConfig();
// + $cache->set('config', $config);  // Looks unused → Initial: 70%
// Re-verify: git show COMPARE:[file] | grep "\$config"
// Found: Used 20 lines later
// Result: FALSE POSITIVE → 25%
```

### Re-Verification Checklist (Before Finalizing Report)

For **every issue ≥60% confidence**:

- [ ] **Code Context:** Viewed full 20-line context around issue?
- [ ] **Variable/Method Exists:** Confirmed variable/method is actually defined?
- [ ] **Data Flow:** Traced variable from source to usage point?
- [ ] **Test Result:** Ran targeted test - does it pass or fail?
- [ ] **Type Check:** Checked PHP types or TypeScript definitions?
- [ ] **Intent Check:** Read commit message - is change intentional?
- [ ] **History Check:** Did similar pattern work before in git history?
- [ ] **Parent Class:** Checked parent class, interface, traits for method?
- [ ] **Logic Verification:** Can you explain why code is actually broken?

**If ANY checkbox fails → confidence should be <60% or issue removed.**

### Decision Rules After Re-Verification

```
Confidence ≥85% after re-verify → REPORT (HIGH or CRITICAL)
Confidence 70-84% after re-verify → REPORT (MEDIUM) + note re-verified
Confidence 60-69% after re-verify → REPORT (LOW/INFO) + caveat "needs confirmation"
Confidence <60% after re-verify → REMOVE from report (FALSE POSITIVE)
```

---

## Output Format

# Code Review: BASE → COMPARE

## Summary
- Files changed: X
- Lines: +X/-X
- Risk: CRITICAL | HIGH | MEDIUM

## Issues

### 🚫 CRITICAL (Block Merge)
1. [XX%] Issue 1 (re-verified: ✓ CONFIRMED)
2. [XX%] Issue 2 (re-verified: ✓ CONFIRMED)

### ⚠️ HIGH (Must Fix)
1. [XX%] Issue 1 (re-verified: ✓ CONFIRMED)

### 📋 MEDIUM (Should Fix)
1. [XX%] Issue 1 (re-verified: ✓ CONFIRMED)

### ℹ️ INFO (Note)
1. [XX%] Issue 1 (re-verified: ✓ CONFIRMED)

## Tests
- [ ] Tests pass: `npm run test && php artisan test`
- [ ] Coverage adequate: `npm run test -- --coverage`
- [ ] No lint errors: `npm run lint`
- [ ] Type checks: `npm run type-check`

## Re-Verification Summary
- Total issues found: X
- Issues after re-verify: X (removed Y false positives)
- Confirmed issues by severity: CRITICAL: X, HIGH: X, MEDIUM: X, LOW: X

## Final: ✅ APPROVE | ⚠️ CONDITIONAL | 🚫 REJECT

---

## Validation Commands

```bash
# Quick check
git diff --stat BASE..COMPARE
npm run test && php artisan test && npm run lint

# Detailed
php -l app/
vendor/bin/phpstan analyse app/ --level=7
npm run type-check
npm run build

# Test coverage
npm run test -- pimcore-vue-unittest --coverage

# View specific diffs
git diff BASE..COMPARE -- "*.php"
git diff BASE..COMPARE -- "*.vue"
git diff BASE..COMPARE -- "*.twig"

# Re-verification commands (for 60%+ issues)
git show COMPARE:[file] | grep -E "variable|method"
npm run test -- ComponentName.spec.js --verbose
php artisan test --filter=TestClassName
```

---

## Escalation

- 3+ CRITICAL issues → Escalate to lead
- 50%+ files HIGH risk → Escalate to architect
- Unclear confidence on critical → Request pair review
- Tests failing unexplained → Ask author
- Can't re-verify issue → Flag as inconclusive

---

## Quick Confidence Checklist

For each issue, ask:
- [ ] Syntax error? → 99%
- [ ] Linter catches it? → 95%+
- [ ] Test would fail? → 92%+
- [ ] Logic error obvious? → 88%
- [ ] Needs verification? → 75%
- [ ] Edge case? → 60%
- [ ] Business logic dependent? → 50%
- [ ] Speculative? → <50%

---

## Quick Confidence Checklist (Re-Verify)

For issues **60-100% confidence**, before finalizing:

- [ ] Syntax error? (99% - NO re-verify needed) ✓
- [ ] Linter catches it? (95%+ - NO re-verify needed) ✓
- [ ] Test would fail? (92%+ - Run test to verify) 
- [ ] Logic error obvious? (88% - Check full context)
- [ ] Needs verification? (75% - MUST re-verify)
- [ ] Edge case? (60% - MUST re-verify)
- [ ] Business logic dependent? (50% - Likely false positive, investigate)
- [ ] Speculative? (<50% - Remove, too risky)

---

## Re-Verification Workflow Summary

1. **Find issue** → Score confidence (e.g., 78%)
2. **If ≥60%** → Run re-verification steps
3. **Test variable/method** existence
4. **Run affected tests** - do they pass?
5. **Check code context** - full 20-line context
6. **Verify intent** - intentional change?
7. **Adjust confidence** - based on findings
8. **Decision:** 
   - ≥85% after re-verify → REPORT
   - 70-84% after re-verify → REPORT (with caveat)
   - <70% after re-verify → REMOVE (FALSE POSITIVE)

---

## Example Complete Re-Verification

### Initial Finding
```
[78%] Undefined variable $filterTerm in Twig template
Location: resources/views/patterns/filter.twig:42
Issue: {{ filterTerm }} used without null check
```

### Step 1: Check Code Context
```bash
$ git show COMPARE:resources/views/patterns/filter.twig | grep -B 5 -A 5 "filterTerm"
```
**Result:** Variable used in template

### Step 2: Check Variable Source
```bash
$ git diff BASE..COMPARE -- app/Http/Controllers/PatternController.php | grep filterTerm
+ 'filterTerm' => $request->input('filter'),
```
**Result:** Variable IS passed from controller ✓

### Step 3: Run Affected Test
```bash
$ php artisan test --filter=PatternViewTest
✓ Test passes
```
**Result:** Feature works correctly ✓

### Step 4: Check Type/Intent
```bash
$ git log --oneline | grep "DPN-103"
DPN-103 Add patterns section with filter
```
**Result:** Change is intentional ✓

### Final Decision
```
Initial Confidence: 78%
Re-Verification: Variable IS passed (obvious from code)
Adjusted Confidence: 20% (FALSE POSITIVE)
Action: REMOVE from report
```

---

## Review Metadata Template

| Field | Value |
|-------|-------|
| **Reviewer** | [Your name] |
| **Date** | [Review date] |
| **Time Spent** | [X hours] |
| **Files Reviewed** | [X] |
| **Total Issues Found** | [X] |
| **Issues After Re-Verify** | [X] |
| **False Positives Caught** | [X] |
| **Confidence Overall** | [XX%] |
| **Recommendation** | APPROVE / CONDITIONAL / REJECT |

---

## Summary: Trust But Verify

**The Goal:** Find real issues while avoiding false alarms.

**The Method:** 
- Score confidence for every finding
- Re-verify all 60%+ issues before reporting
- Remove findings that don't hold up to scrutiny
- Report only confirmed issues

**The Payoff:** 
- More credible code reviews
- Fewer "you missed the context" complaints
- Better relationships with code authors
- Higher trust in your review process
