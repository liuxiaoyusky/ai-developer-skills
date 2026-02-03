---
name: debug
description: 系统化调试技能 - 在提出解决方案前，必须完成根本原因分析。包含 5 Whys、生产环境验证、工具使用指南，避免症状修复和验证偏差。
---

# Debug Skill

> **CRITICAL**: Before proposing ANY solution, you MUST go through this debugging framework.

---

## 🎯 Core Questions (Ask Yourself FIRST)

Before responding to any problem, ALWAYS ask yourself:

1. **"Is this the root cause or just a symptom?"**
2. **"What does the user really want to accomplish?"**
3. **"Will my solution serve their actual goal?"**
4. **"Can I verify this really solves the problem?"**

---

## 🔍 Investigation Process

### Phase 1: Gather Information

**Ask clarifying questions:**
- What exact error message or behavior are you seeing?
- When does this occur? (timing, context, triggers)
- Can you share error logs, stack trace, or screenshots?

**Use tools to investigate:**
- **Read** - Examine actual code/config (NEVER guess)
- **Grep** - Search for patterns, related code
- **Glob** - Find all relevant files
- **Bash** - Check logs, processes, test behavior

### Phase 2: Root Cause Analysis (5 Whys)

Apply the **5 Whys technique** - ask "why" at least 5 times:

```
PROBLEM: API returns 500 error
Why 1? → Database query times out
Why 2? → Connection pool is exhausted
Why 3? → Connections aren't being closed
Why 4? → Error path doesn't call connection.close()
Why 5? → Missing finally block in error handling

ROOT CAUSE: Missing finally block to close connections
```

**Distinguish symptom vs root cause:**
- ❌ Symptom: "Page loads slowly"
- ✅ Root cause: "Unoptimized N+1 database queries"

### Phase 3: Solution Design

**Only AFTER identifying root cause:**
1. Propose solution that addresses the root cause
2. Ensure solution aligns with user's actual goal
3. Plan verification steps

### Phase 4: Verification Plan

**Standard Verification:**
1. Read the code you modified
2. Use Grep to check for similar issues
3. Run tests with Bash
4. Test the specific broken behavior

**🔴 Production Verification (for deployed apps):**

```bash
# Step 1: Extract exact filename from user's error
# User error: "index-FPRo3oei.js:18 API call failed"

# Step 2: Check what HTML references
curl -s https://domain.com/ | grep -o "assets/index-.*\.js"

# Step 3: Verify THAT specific file (NOT your local build!)
curl -s https://domain.com/assets/index-FPRo3oei.js | grep "PATTERN"

# Step 4: Cache-bust if needed
curl -H "Cache-Control: no-cache" https://domain.com/assets/index-FPRo3oei.js
```

**Critical Principles:**
- Error messages contain the ONLY truth about production
- Filenames/URLs/line numbers in errors are FACTS
- Tool success ≠ Production reality (CDN/cache create gaps)
- Verify what users ACTUALLY see, not what you THINK they see

---

## 📋 Example: Good vs Bad Debugging

### ❌ BAD: Symptom-Focused

```
User: "My page loads slowly"
Assistant: "Add caching to speed it up."

Problems:
- Didn't find root cause
- Didn't verify what's actually slow
- Can't verify if caching solves the real issue
```

### ✓ GOOD: Root Cause Analysis

```
User: "My page loads slowly"

Assistant:
1. Read page code (Read tool)
2. Check database queries (Grep for N+1 patterns)
3. Found: N+1 query problem (150 queries instead of 2)

5 Whys:
- Slow? → 150 database queries
- 150 queries? → Fetching user for each item
- Fetching per item? → No eager loading
- No eager loading? → Missing .include()

ROOT CAUSE: Missing eager loading

Solution: Add .include('user')
Verify: Run query, confirm only 2 queries
```

---

## ⚠️ Common Pitfalls

1. **Guessing instead of reading** - Always Read actual code first
2. **Treating symptoms** - Use 5 Whys to find root cause
3. **Ignoring user goals** - Ask what they're really trying to do
4. **No verification** - Always plan how to test the fix
5. **Premature solutions** - Don't propose solutions until you understand

### 🔴 Production Pitfalls

6. **Trusting "build artifacts" over "runtime errors"**
   - ❌ "Local build looks correct"
   - ✅ "User's error shows file ABC.js, let me check THAT file"

7. **Believing deployment tools**
   - ❌ "Wrangler says deployed successfully"
   - ✅ "Let me verify what's actually being served"

8. **Ignoring the cache layer**
   - ❌ "I deployed, users should see it"
   - ✅ "CDN might cache old files, let me verify"

---

## 🎯 Quick Reference

When you encounter a problem:

1. **STOP** - Don't propose a solution yet
2. **READ** - Use Read tool to examine code
3. **SEARCH** - Use Grep to find patterns
4. **ASK** - Use 5 Whys to find root cause
5. **VERIFY** - Use tools to confirm understanding
6. **ALIGN** - Ensure solution matches user's goal
7. **TEST** - Verify the fix actually works

**Remember: Use tools to investigate, use tools to verify. Never assume.**

---

## 🔄 Multiple Solution Strategy (Bounded Depth-First)

When debugging, consider multiple solutions upfront:

**Example Problem**: "API returns 500 error"

**Possible solutions**:
1. Database connection issue
2. API endpoint bug
3. Configuration error

**Strategy**:
```
Solution A, attempt 1 → Failed
Solution A, attempt 2 → Failed
Solution A, attempt 3 → Failed
→ Switch to Solution B (max 3 attempts per solution)

Solution B, attempt 1 → Failed
Solution B, attempt 2 → SUCCESS!
→ Problem solved
```

**Benefits**:
- Breadth-first exploration before going deep
- Avoid tunnel vision
- Skip obviously wrong approaches after 3 failures

---

**End of Debug Skill**
