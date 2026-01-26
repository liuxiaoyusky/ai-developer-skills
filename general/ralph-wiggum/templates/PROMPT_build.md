# Ralph Wiggum - Build Mode Prompt

## Phase 0: Orientation

0a. Study `specs/*` with up to 500 parallel Sonnet subagents to learn the application specifications.

0b. Study @AGENTS.md to understand the tasks and validation commands.

0c. For reference, the application source code is in `src/*`.

---

## Phase 1: Task Selection and Implementation

1. **Choose and Implement**

   Your task is to implement functionality per the specifications using parallel subagents.

   Follow @AGENTS.md and **choose the most important task** from the Tasks section to address.

   **Before making changes**, search the codebase to confirm what's implemented (don't assume not implemented) using up to 500 parallel Sonnet subagents for searches/reads and only 1 Sonnet subagent for build/tests.

   Use Opus subagents when complex reasoning is needed (debugging, architectural decisions).

2. **Implement**

   Implement the functionality completely. No placeholders or stubs - they waste effort and time redoing the same work.

   If functionality is missing based on the task description, it's your job to add it as per the specifications.

   **Ultrathink.**

---

## Phase 2: Validation and Debugging

3. **Run Validation**

   After implementing functionality or resolving problems, **run the validation commands specified in @AGENTS.md**:
   - Tests
   - Typecheck
   - Lint
   - Any other validation commands

4. **Debug with Skills**

   When encountering errors or stuck situations:

   **First attempt**: Try to fix using standard debugging (max 3 attempts).

   **If stuck after 3 attempts**: Invoke the `/debug` skill:

   ```
   /debug "<specific error message with context>"

   Example:
   /debug "Tests failing: TypeError: Cannot read property 'x' of undefined in src/auth.ts:45. Tests: npm test. Error: Cannot read property 'user' of undefined when calling authenticateUser function."
   ```

   **The `/debug` skill** (from liuxiaoyusky/ai-developer-skills marketplace) provides:
   - Root cause analysis (5 Whys technique)
   - Production debugging best practices
   - Tool usage guidelines (Read/Grep/Bash)
   - Common debugging pitfalls to avoid

   After the debug skill provides analysis and fix:
   1. Implement the suggested fix
   2. Re-run validation commands
   3. Continue with next task

---

## Phase 3: Update and Commit

5. **Update AGENTS.md**

   When you discover issues or complete tasks:
   - Immediately update @AGENTS.md using a subagent
   - Mark completed tasks as `- [x]`
   - Remove or note resolved issues
   - Add new issues discovered during implementation

6. **Commit Changes**

   When the validation passes (no errors):
   - Update @AGENTS.md (mark task as complete)
   - `git add -A`
   - `git commit` with a message describing the changes
   - `git push`

7. **Completion Detection**

   When **all tasks in @AGENTS.md are complete** (all marked as `- [x]`):
   - Output: `<RALPH_COMPLETE>`
   - Exit the loop

---

## Critical Guardrails (999... series)

99999. **Important**: When authoring documentation, capture the **why** — tests and implementation importance. This context is crucial for future maintenance.

999999. **Important**: Single sources of truth, no migrations/adapters. If tests unrelated to your work fail, resolve them as part of the increment. They are blocking the build.

9999999. As soon as there are no build or test errors, create a git tag. If no git tags exist, start at 0.0.0 and increment patch by 1 (e.g., 0.0.1).

99999999. You may add extra logging if required to debug issues, but remove it before committing.

999999999. Keep @AGENTS.md current with learnings using a subagent — **future work depends on this to avoid duplicating efforts**. Update especially after finishing your turn.

9999999999. When you learn something new about how to run the application, update @AGENTS.md using a subagent but **keep it brief**. For example, if you run commands multiple times before learning the correct command, that file should be updated.

99999999999. For any bugs you notice, resolve them or document them in @AGENTS.md using a subagent, even if unrelated to the current piece of work.

999999999999. Implement functionality completely. **No placeholders or stubs** — they waste effort and time redoing the same work.

9999999999999. When @AGENTS.md becomes large, periodically clean out the items that are completed from the file using a subagent. This keeps the file focused on remaining work.

99999999999999. If you find inconsistencies in the `specs/*`, use an Opus subagent with 'ultrathink' requested to update the specs.

999999999999999. **IMPORTANT: Keep @AGENTS.md operational only** — status updates and progress notes belong in the task list, not in operational notes. A bloated AGENTS.md pollutes every future loop's context.

9999999999999999. **Don't assume not implemented** — always search first to confirm. This is the most common mistake that wastes cycles.

99999999999999999. **Single source of truth**: If duplicate implementations exist, consolidate them. Prefer implementations in `src/lib` as the project's standard library.

---

## Key Language Patterns

Use these exact phrases for best results:

- **"study"** (not "read" or "look at")
- **"don't assume not implemented"** (critical)
- **"using parallel subagents"** or **"up to N subagents"**
- **"Ultrathink"** (for complex reasoning)
- **"capture the why"** (when documenting)
- **"keep it up to date"** (for maintenance)

---

## Completion Criteria

You are **DONE** when:

1. ✅ All tasks in @AGENTS.md are marked as `- [x]` (complete)
2. ✅ All validation commands pass (tests, typecheck, lint)
3. ✅ No build errors
4. ✅ No test failures
5. ✅ Changes are committed and pushed

When done, output:

```
<RALPH_COMPLETE>
All tasks in @AGENTS.md completed successfully.
All tests passing.
Build clean.
```

Then exit. The loop will detect completion and stop.

---

## Operational Notes Summary

- **One task per iteration** - Choose the most important task, implement it completely, validate, commit.
- **Validation is mandatory** - Never skip running tests, typecheck, lint.
- **Keep AGENTS.md current** - Update it with every discovery and completion.
- **Use debug skills** - Don't waste cycles on stuck errors.
- **Complete implementation** - No placeholders, stubs, or TODOs.

**Let Ralph Ralph** — trust the process, iterate until done, capture learnings for the next cycle.
