---
name: debug
description: 系统化的调试技能 - 在提出任何解决方案之前，必须经过此调试框架。包含根本原因分析（5 Whys）、生产环境验证、工具使用指南等。帮助避免症状修复、选择性验证偏差等常见调试陷阱。
---

# Debug Skill

> **CRITICAL**: Before proposing ANY solution, you MUST go through this debugging framework.

---

## 🎯 Core Questions (Ask Yourself FIRST)

Before responding to any problem, ALWAYS ask yourself:

1. **"Is this the root cause or just a symptom?"**
   - Am I treating the phenomenon or the underlying issue?
   - Have I dug deep enough?

2. **"What does the user really want to accomplish?"**
   - What's their actual goal?
   - Is the stated problem masking a different need?

3. **"Will my solution serve their actual goal?"**
   - Does this solve what they truly need?
   - Am I solving the right problem?

4. **"Can I verify this really solves the problem?"**
   - How will I test/confirm the fix?
   - What tools will I use to verify?

---

## 🧠 Theoretical Framework: Why Debugging Fails

### 🔴 The Anti-Pattern: False Trust in Verification

**The Verification Gap:**
```
Your Local Code → Build Artifacts → Deployed Files → What Users Actually See
     ✅              ✅                ✅                  ❌ (Reality Gap)
```

**Critical Principle:**
> **Verify what users ACTUALLY see, not what you THINK they should see**

### Theory 1: Error Messages Are Ground Truth

User error messages contain the ONLY absolute truth about production:

```
❌ WRONG: Check local build, see correct API, assume problem solved
✅ RIGHT:  User error shows index-ABC123.js → Check THAT file → Find wrong API
```

**Rule:**
- Filenames, URLs, line numbers in errors are FACTS
- Never use "build artifacts" to contradict "runtime errors"
- Always verify what the error message POINTS TO

### Theory 2: Tool Success ≠ User Success

Tools report success at multiple levels:
```
Level 1: Tool executed         ✅ (Bash says "Success")
Level 2: Files uploaded        ✅ (Wrangler says "Deployed")
Level 3: New files deployed    ❓ (Maybe, maybe not)
Level 4: CDN serving new files ❌ (Cache may serve old)
Level 5: Users getting new files ❌ ← ONLY THIS MATTERS
```

**Rule:**
> **Tool success ≠ Production reality**
> **CDN, cache, DNS, load balancers create gaps between "deployed" and "served"**

### Theory 3: The Cache-First Assumption

Modern web has caching at EVERY layer:
```
Browser → CDN → Server → Build → DNS
  ↓       ↓      ↓       ↓      ↓
 Cache  Cache  Cache   Cache  Cache
```

**Rule:**
> **Always assume you might see OLD data**
> **Verify production with cache-busting methods**

### Theory 4: Selective Verification Bias

**The mistake:**
1. You check the EASY path (local build) → ✅ Looks good
2. You skip the HARD path (production reality)
3. You stop searching after first confirmation

**The fix:**
> **Verify where the pain is, not where it's convenient**
> **User's error > Your assumptions > Tool reports**

---

## 🔍 Investigation Process

### Phase 1: Gather Information

**Ask clarifying questions:**
- What exact error message or behavior are you seeing?
- When does this occur? (timing, context, triggers)
- What were you doing when it happened?
- Can you share the error logs, stack trace, or screenshots?
- Is this reproducible? If so, how?

**Use tools to investigate:**
```bash
# Read actual code/config (NEVER guess)
Read: Examine the relevant files

# Search for patterns
Grep: Find similar code, error patterns, related issues

# Locate all relevant files
Glob: Find all files that might be involved

# Check current state
Bash: View logs, check processes, test current behavior
```

### Phase 2: Root Cause Analysis (5 Whys)

Apply the **5 Whys technique** - ask "why" at least 5 times:

```
PROBLEM: API returns 500 error
Why 1? → Database query times out
Why 2? → Connection pool is exhausted
Why 3? → Connections aren't being closed
Why 4? → Error path doesn't call connection.close()
Why 5? → Missing finally block in error handling

ROOT CAUSE: Missing finally block to close connections in error path
```

**Distinguish symptom vs root cause:**
- ❌ Symptom: "Page loads slowly" → ✅ Root cause: "Unoptimized N+1 database queries"
- ❌ Symptom: "Button doesn't work" → ✅ Root cause: "Event listener attached before DOM element exists"
- ❌ Symptom: "Tests fail" → ✅ Root cause: "Race condition in async initialization"

### Phase 3: Goal Understanding

**Ask about the real objective:**
- "What are you ultimately trying to accomplish?"
- "Why do you need this feature/fix?"
- "What problem would solving this enable you to do?"

**Consider alternative approaches:**
- Maybe the user's goal can be achieved differently
- Perhaps they're solving the wrong problem
- There might be a simpler/better way

### Phase 4: Solution Design

**Only AFTER identifying root cause:**
1. Propose solution that addresses the root cause
2. Ensure solution aligns with user's actual goal
3. Consider edge cases and side effects
4. Plan verification steps

### Phase 5: Verification Plan - The Production Reality Check

**🚨 CRITICAL: Verify where users actually experience the problem**

#### Standard Verification Flow (for most cases):
1. Read the code you modified
2. Use Grep to check for similar issues
3. Run tests with Bash
4. Check logs for errors

#### 🔴 PRODUCTION Verification Flow (for deployed apps):

**Step 1: Extract actual URLs from error messages**
```bash
# User error: "index-FPRo3oei.js:18 API call failed"
# → Extract filename: index-FPRo3oei.js
# → This is the ONLY source of truth
```

**Step 2: Verify what's ACTUALLY running**
```bash
# ❌ WRONG: Check your local build
cat dist/assets/index-D0w4YXqF.js | grep API_URL

# ✅ RIGHT: Check the file from error message
curl https://domain.com/assets/index-FPRo3oei.js | grep API_URL

# Or better: Get actual filename from HTML first
curl https://domain.com/ | grep -o "assets/index-.*\.js"
# Then verify THAT specific file
```

**Step 3: Cache-busting verification**
```bash
# Method 1: Direct file inspection (bypasses HTML cache)
curl -s https://domain.com/assets/ACTUAL-FILENAME.js | grep PATTERN

# Method 2: With cache-busting headers
curl -H "Cache-Control: no-cache" \
     -H "Pragma: no-cache" \
     https://domain.com/assets/ACTUAL-FILENAME.js

# Method 3: Instruct user to hard refresh
# Chrome/Cmd+Shift+R, Firefox/Ctrl+Shift+R
```

**Step 4: Deployment verification anti-patterns**
```bash
# ❌ DON'T TRUST THESE:
- "Wrangler: Upload successful (21 files)"
- "Deploy completed in 3.2s"
- "Build succeeded"

# ✅ DO TRUST THESE:
- Actual file content inspection
- Browser DevTools Network tab
- User's error messages
```

**Verification Checklist for Deployed Apps:**
- [ ] Extracted exact filename from user's error
- [ ] Retrieved HTML to see what files are referenced
- [ ] Verified the ACTUAL referenced file (not local build)
- [ ] Checked with cache-busting method
- [ ] Confirmed with user that error is resolved
- Test the specific behavior that was broken

**Verification checklist:**
- [ ] Did I read the actual code (not assume)?
- [ ] Did I fix the root cause, not just symptom?
- [ ] Will this serve the user's real goal?
- [ ] Can I test/verify this works?
- [ ] What tools will I use to verify?

---

## 🛠️ Tools-Based Verification

### Before Proposing Solutions

**USE THESE TOOLS to understand the problem:**

1. **Read** - Examine actual code/config
   ```
   Read the file to see the real implementation
   Don't guess - look at the actual code
   ```

2. **Grep** - Search for patterns
   ```
   Find similar error handling
   Locate all uses of a function
   Search for related code patterns
   ```

3. **Glob** - Find relevant files
   ```
   Locate all test files
   Find configuration files
   Identify all files that might be affected
   ```

4. **Bash** - Check current state
   ```
   View logs: cat logs/error.log
   Check processes: ps aux | grep app
   Test behavior: curl endpoint
   Run linter/tests
   ```

### After Implementing Solutions

**USE THESE TOOLS to verify the fix:**

1. **Run tests**
   ```bash
   npm test
   pytest
   go test
   ```

2. **Check the fix**
   ```bash
   Read: Verify code changes are correct
   Grep: Ensure no similar issues elsewhere
   ```

3. **Test the specific behavior**
   ```bash
   Reproduce the issue scenario
   Verify error is gone
   Check edge cases
   ```

---

## 📋 Example: Good vs Bad Debugging

### ❌ BAD: Symptom-Focused Approach

```
User: "My page loads slowly"

Assistant: "Add caching to speed it up."

Problems:
- Didn't find root cause (why is it slow?)
- Didn't verify what's actually slow
- Didn't understand user's goal
- Can't verify if caching solves the real issue
```

### ✓ GOOD: Root Cause Analysis

```
User: "My page loads slowly"

Assistant:
1. Read the page code (Read tool)
2. Check database queries (Grep for N+1 patterns)
3. View browser network logs (ask user)
4. Found: N+1 query problem loading user data

5 Whys:
- Slow? → 150 database queries
- 150 queries? → Fetching user for each item
- Fetching per item? → No eager loading
- No eager loading? → Missing .include()
- Missing? → Dev didn't know about it

ROOT CAUSE: Missing eager loading causes N+1 queries

Solution: Add .include('user') to eager load
Verify: Run query, confirm only 2 queries instead of 150
```

---

## ⚠️ Common Pitfalls to Avoid

1. **Guessing instead of reading** - Always Read the actual code first
2. **Treating symptoms** - Use 5 Whys to find root cause
3. **Ignoring user goals** - Ask what they're really trying to do
4. **No verification** - Always plan how to test the fix
5. **Premature solutions** - Don't propose solutions until you understand the problem
6. **Not using tools** - Use Read/Grep/Bash to investigate and verify

### 🔴 CRITICAL: Production Debugging Pitfalls

7. **Trusting "build artifacts" over "runtime errors"**
   - ❌ "Local build looks correct"
   - ✅ "User's error shows file ABC.js, let me check THAT file"

8. **Believing deployment tools**
   - ❌ "Wrangler says deployed successfully"
   - ✅ "Let me verify what's actually being served"

9. **Checking the wrong file**
   - ❌ Checking `dist/index-NEW.js` (your build)
   - ✅ Checking `assets/index-OLD.js` (what user loads)

10. **Ignoring the cache layer**
    - ❌ "I deployed, users should see it"
    - ✅ "CDN might cache old files, let me verify"

---

## 📚 Real-World Case Study: The Verification Gap

### Scenario: Custom Domain Can't Connect to Backend

**User Report:**
```
Error: volaris-api-test-ajfyavbcgacdc0a3.eastasia-01.azurewebsites.net
       Failed to load resource: net::ERR_NAME_NOT_RESOLVED
File: index-FPRo3oei.js
```

### ❌ The Wrong Way (What I Did)

```bash
# Step 1: Rebuild locally
npm run build
# Creates: dist/assets/index-D0w4YXqF.js

# Step 2: Check LOCAL build (WRONG!)
curl dist/assets/index-D0w4YXqF.js | grep API
# Result: https://volaris-api-flex.azurewebsites.net ✅

# Step 3: Deploy
npx wrangler pages deploy dist
# Result: "21 files uploaded" ✅

# Step 4: Declare success
# "Problem solved!"

# REALITY: User still sees OLD file with OLD API
```

**Mistakes:**
1. ✅ Checked file, but **wrong file** (local vs production)
2. ✅ Used tools, but **trusted tool output** over user reality
3. ✅ Deployed, but **didn't verify what was served**
4. ❌ **Didn't check the actual file from error message**

### ✓ The Right Way (What I Should Have Done)

```bash
# Step 1: Extract ACTUAL filename from error
# User error shows: index-FPRo3oei.js

# Step 2: Check what HTML references
curl https://volaris.skyliu.tech/ | grep "index-.*\.js"
# Result: assets/index-FPRo3oei.js (matches error!)

# Step 3: Verify THAT specific file
curl https://volaris.skyliu.tech/assets/index-FPRo3oei.js | grep API
# Result: https://volaris-api-test-ajfyavbcgacdc0a3.eastasia-01.azurewebsites.net ❌

# Step 4: ROOT CAUSE FOUND
# Production serves OLD build, not new build

# Step 5: Force cache invalidation
# Method: Touch files to change hashes, wait CDN propagation
```

**Key Insights:**
- Error message → **Source of truth** for filenames
- HTML → **Source of truth** for what's loaded
- curl production file → **Only reliable verification**
- "Deployed" ≠ "Served to users"

---

## 🎯 Quick Reference: Production Debugging

### When User Reports a Bug in Deployed App:

```bash
# 1. Get exact filenames from error
cat browser-error.txt | grep "\.js:"

# 2. Verify production HTML
curl -s https://domain.com/ | grep -o "assets/[^\"']*\.[js|css]"

# 3. Check ACTUAL production files
curl -s https://domain.com/assets/ACTUAL-FILENAME.js | grep "PATTERN"

# 4. Cache-bust if needed
curl -H "Cache-Control: no-cache" https://domain.com/assets/ACTUAL-FILENAME.js

# 5. Only then: Check local code
Read src/code.js  # Compare, don't assume
```

### Golden Rules:

1. **Error messages = Reality**
2. **Production files ≠ Local files**
3. **Tool success ≠ User success**
4. **Always verify at the user's layer**
5. **Assume cache is lying to you**

---

## 🎯 Quick Reference

When you encounter a problem:

1. **STOP** - Don't propose a solution yet
2. **READ** - Use Read tool to examine code
3. **SEARCH** - Use Grep to find patterns
4. **ASK** - Use 5 Whys to find root cause
5. **VERIFY** - Use tools to confirm your understanding
6. **ALIGN** - Ensure solution matches user's goal
7. **TEST** - Verify the fix actually works

**Remember: Use tools to investigate, use tools to verify. Never assume.**
