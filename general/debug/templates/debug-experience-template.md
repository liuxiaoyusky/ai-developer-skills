# [SUCCESS/FAILURE] YYYY-MM-DD: Short Description

> **Status**: SUCCESS / FAILURE
> **Component**: API / Database / Frontend / Worker / Cache / Other
> **Type**: Error / Performance / Design / Behavior

---

## Problem

**What happened?**
- Describe the issue clearly
- Error messages or stack traces
- When did it occur?
- Who was affected?

**Impact**
- High / Medium / Low
- User-facing or internal?
- Business impact?

---

## Tags

```yaml
type: error | performance | design | behavior
component: api | database | frontend | worker | cache | other
method: 5-whys | first-principles
impact: high | medium | low
```

**Keywords**:
- tag1, tag2, tag3 (for searching)

---

## Investigation Method

**Track**: A (5 Whys) / B (First Principles)

**Why this method?**
- Explain why you chose 5 Whys or First Principles
- What indicators led to this choice?

**Investigation Process**:
- Step 1: ...
- Step 2: ...
- Step 3: ...

---

## Root Cause

**The actual underlying issue**:
- What was really causing the problem?
- Not just symptoms, but the root cause

**Why did this happen?**
- Code change?
- Configuration issue?
- Design flaw?
- External factor?

---

## Solution Path

**Choice**: Fix System / Modify Expectations / Reconstruct System / Accept Difference

**Why this path?**
- Explain why you chose this solution path
- What alternatives did you consider?
- Why were they rejected?

---

## Solution Details

**What did you change?**

### Code Changes
```javascript
// Before
...

// After
...
```

### Configuration Changes
```yaml
# config.yml
key: new_value
```

### Architecture Changes
- Describe architectural changes
- Diagrams if helpful

### Files Modified
- `path/to/file1.js` - Description of change
- `path/to/file2.py` - Description of change

---

## Verification

**How did you verify it worked?**

### Test Results
- Test 1: ... ✓
- Test 2: ... ✓
- Test 3: ... ✓

### Metrics Before/After
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Response Time | 30s | 0.2s | 99% ↓ |
| Error Rate | 15% | 0% | 100% ↓ |
| Memory Usage | 2GB | 150MB | 92% ↓ |

### Production Verification
- Date deployed: YYYY-MM-DD
- Monitoring period: X days
- Any issues? No / Yes (describe)

---

## Lessons Learned

**What did you learn from this?**

### Success Factors (if SUCCESS)
- What made this solution work?
- What would you do differently next time?
- Best practices to follow

### Failure Analysis (if FAILURE)
**Why did this approach fail?**
- Reason 1: ...
- Reason 2: ...
- Reason 3: ...

**What should be avoided?**
- Don't: ...
- Don't: ...
- Don't: ...

**What would you do differently?**
- Alternative approach: ...
- Better solution: ...

**Key Takeaway**:
- One sentence summary of the lesson

---

## Occurrences

```yaml
first_occurrence: YYYY-MM-DD
last_occurrence: YYYY-MM-DD
frequency: X times
related_issues:
  - issue-1
  - issue-2
```

**Pattern**:
- Does this issue follow a pattern?
- When does it typically occur?
- What triggers it?

---

## Related Files

### Modified
- [file1.js](path/to/file1.js) - Description
- [file2.py](path/to/file2.py) - Description

### Documentation Updated
- [README.md](README.md) - Added troubleshooting section
- [docs/api.md](docs/api.md) - Updated API docs

### Related Debug Experiences
- [YYYY-MM-DD-related-issue](../related-issue.md) - Similar problem
- [YYYY-MMDD-another-issue](../another-issue.md) - Related root cause

---

## References

### Error Messages / Stack Traces
```
Paste relevant error messages here
```

### Useful Links
- [Documentation](https://...)
- [GitHub Issue](#...)
- [Stack Overflow](https://...)

---

**Last Updated**: YYYY-MM-DD
**Updated By**: Debug Skill / Manual

---

## Template Usage Guide

**When to create a new experience file**:
- After completing debug (Phase 5)
- After verification passes
- Whether success or failure (both are valuable!)

**File naming convention**:
- `YYYY-MM-DD-short-description.md`
- Use lowercase, hyphens for spaces
- Keep description concise but descriptive
- Examples:
  - `2025-01-15-api-timeout-n-plus-1.md`
  - `2025-01-10-redis-cache-failure.md`
  - `2025-01-08-memory-leak-worker.md`

**Template fields to fill**:
- ✅ **Required**: Problem, Root Cause, Solution Details, Verification
- 🟡 **Recommended**: Tags, Lessons Learned, Related Files
- ⚪ **Optional**: References (if external resources were helpful)

**SUCCESS vs FAILURE**:
- **SUCCESS**: Solution worked, problem resolved
- **FAILURE**: Attempted solution failed, lesson learned

**Remember**: Both successes and failures are valuable!
- Successes: What worked, what to repeat
- Failures: What didn't work, what to avoid
