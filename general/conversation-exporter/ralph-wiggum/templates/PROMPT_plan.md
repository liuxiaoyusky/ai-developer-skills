# Ralph Wiggum - Plan Mode Prompt

## Phase 0: Orientation

0a. Study `specs/*` with up to 250 parallel Sonnet subagents to learn the application specifications.

0b. Study @AGENTS.md (if present) to understand the current tasks and operational setup.

0c. Study `src/lib/*` with up to 250 parallel Sonnet subagents to understand shared utilities and components.

0d. For reference, the application source code is in `src/*`.

---

## Main Task

1. **Gap Analysis and Task Generation**

   Study @AGENTS.md (if present; it may be incorrect) and use up to 500 Sonnet subagents to study existing source code in `src/*` and compare it against `specs/*`.

   Use an Opus subagent with 'ultrathink' to analyze findings, prioritize tasks, and create/update @AGENTS.md as a prioritized task list.

   Consider:
   - Searching for TODO, minimal implementations, placeholders
   - Skipped or flaky tests
   - Inconsistent patterns
   - Missing features from specifications

   Study @AGENTS.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.

2. **Important Constraints**

   **IMPORTANT: Plan only. Do NOT implement anything.**

   Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library for shared utilities and components. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

3. **Debug Integration** (Optional)

   If you encounter build failures or test errors during analysis:

   ```
   When encountering build failures or test errors, you may invoke the debug skill:
   /debug <specific error message>

   This skill will:
   1. Analyze the error
   2. Search for similar issues
   3. Suggest fixes
   4. Document findings in the plan
   ```

---

## Ultimate Goal

We want to achieve **[PROJECT-SPECIFIC-GOAL-TO-BE-DEFINED-BY-USER]**.

Consider missing elements and plan accordingly. If an element is missing:
1. Search first to confirm it doesn't exist
2. If needed, author the specification at `specs/FILENAME.md`
3. Document the plan to implement it in @AGENTS.md using a subagent

---

## Key Language Patterns

These are the specific phrases that work best. Use them exactly:

- **"study"** (not "read" or "look at")
- **"don't assume not implemented"** (critical - this is the Achilles' heel)
- **"using parallel subagents"** or **"up to N subagents"**
- **"Ultrathink"** (for complex reasoning tasks)
- **"capture the why"** (when documenting)
- **"keep it up to date"** (for maintaining the plan)

---

## Output Format

Update @AGENTS.md with the following structure:

```markdown
## Build & Run

[Project-specific build commands]

## Validation

[Validation commands: tests, typecheck, lint, etc.]

## Tasks

Prioritized task list:

- [ ] Task 1: [Description]
- [ ] Task 2: [Description]
- [x] Task 3: [Description] (if already complete)

## Operational Notes

[Succinct operational learnings - keep brief]

### Debug Skills

[Debug skills available in this project]
```

---

## Completion

When the gap analysis is complete and @AGENTS.md is updated with a comprehensive task list, output:

```
<PLAN_COMPLETE>
Plan generation complete. Ready to start Build mode.
```

Then exit. The loop will detect completion and stop.
