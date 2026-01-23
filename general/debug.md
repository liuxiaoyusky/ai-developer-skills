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

### Phase 5: Verification Plan

**Always verify with tools:**
- Read the code you modified to ensure correctness
- Use Grep to check for similar issues elsewhere
- Run tests with Bash
- Check logs for errors
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
