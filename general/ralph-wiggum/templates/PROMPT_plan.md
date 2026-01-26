# Ralph Wiggum - Plan Mode Prompt

## Phase 0: Quick Context Check

0a. **Read key documentation files** (in order):
   - @README.md (if present) - to understand project overview
   - @IMPLEMENTATION_PLAN.md (if present) - to understand the implementation plan
   - @AGENTS.md (if present) - to understand current task status
   - Any @*.md in project root that might contain specs or requirements

0b. **Quick project structure scan**:
   - Use Glob to find main source directories (usually `src/`, `lib/`, `app/`, etc.)
   - Use Glob to find config files (`package.json`, `Cargo.toml`, `go.mod`, etc.)
   - Use Glob to find existing specs in `specs/*.md` (if the directory exists)

**Do NOT read source code files yet.** Focus only on documentation first.

---

## Phase 0.5: Implementation Plan Check

Check for IMPLEMENTATION_PLAN.md:

1. **If IMPLEMENTATION_PLAN.md exists**:
   - Read it to understand the project plan
   - Use it to inform AGENTS.md generation (skip to Phase 3)
   - Extract from the plan:
     - Core Features → Tasks section
     - Acceptance Criteria → Validation section
     - Implementation Phases → Task ordering
     - Technical Considerations → Build & Run section

2. **If IMPLEMENTATION_PLAN.md does NOT exist**:
   - Ask user: "No IMPLEMENTATION_PLAN.md found. Would you like to create one using first-principles-planner for deeper project planning?"
   - If yes: Call `/first-principles-planner` skill, wait for completion, then proceed to Phase 3
   - If no: Proceed with Phase 1 (current manual planning flow)

**Rationale**: First-principles-planner provides structured, thoughtful planning using 5 Whys technique, resulting in better AGENTS.md with clear feature prioritization and acceptance criteria.

---

## Phase 1: Interactive User Guidance

**IMPORTANT**: Before diving into analysis, you MUST gather key information from the user.

Use AskUserQuestion to ask the following:

1. **Project Goals**
   - What is the main objective of this project?
   - What problem does it solve?
   - Who are the target users?

2. **Current Status**
   - Is this a new project or existing codebase?
   - If existing, what's already working?
   - What needs to be built or improved?

3. **Technical Stack** (if not obvious from config files)
   - Preferred programming language/framework?
   - Any specific libraries or tools to use/avoid?
   - Any architectural patterns or constraints?

4. **Task Priorities**
   - Which features are most critical?
   - Any deadlines or time constraints?
   - Any dependencies between tasks?

5. **Scope Boundaries**
   - What should NOT be included in this project?
   - Are there any out-of-scope items to note?

**Document the answers** in a temporary section at the top of @AGENTS.md (labeled "## PROJECT CONTEXT - Planning Phase").

---

## Phase 2: Targeted Analysis

Now that you understand the user's goals, perform targeted analysis:

2a. **Study relevant specs** (if specs/ directory exists):
   - Only read specs that relate to the user's stated goals
   - Use up to 50 parallel subagents for specs (not 500)
   - Focus on specs that match the priority areas user mentioned

2b. **Identify key source files**:
   - Search for files mentioned in specs or user requirements
   - Look for TODO/FIXME/HACK comments in relevant areas only
   - Use Grep to find specific function/class names mentioned in requirements

2c. **Minimal source code study**:
   - Only read source files that are:
     - Directly mentioned in specs/requirements
     - Referenced in existing TODOs
     - Core entry points (main.ts, index.js, etc.)
   - Use up to 50 parallel subagents (not 500)
   - Stop reading once you understand the architecture

---

## Phase 1.5: Git Branch & Commit Strategy

**IMPORTANT**: Protect the codebase by working on a separate branch.

1. **Create a new git branch**:
   - Check current git status
   - If working directory is not clean, use AskUserQuestion to confirm
   - Create branch with format: `ralph-iteration-{timestamp}` or let user specify
   - Command: `git checkout -b ralph-iteration-{timestamp}`

2. **Verify branch creation**:
   - Confirm we're on the new branch
   - Ensure it tracks from the original branch

**Commit Strategy** (documented for Build mode):

After each **iteration** (loop cycle):
- Commit message format: `iteration {N}: {brief_summary}`
- Example: `iteration 3: implemented user authentication`
- Auto-commit all changes

After each **task completion**:
- Commit message format: `{task_name} done`
- Example: `data import feature done`
- Auto-commit all changes

This ensures:
- Easy rollback if something breaks
- Clear history of what was done per iteration/task
- Ability to review changes systematically

---

## Phase 3: Generate AGENTS.md

3a. **Create or update @AGENTS.md** with:
   - Build & Run commands (from config files like package.json, Makefile, etc.)
   - Validation commands (test scripts, typecheck, lint commands)
   - Prioritized task list based on user's priorities
   - Operational notes (only critical info)
   - Debug skills section

3b. **Task list quality**:
   - Each task should be concrete and actionable
   - Include acceptance criteria when possible
   - Order by priority (user's stated priorities first)
   - Mark already-completed tasks as `- [x]`

3c. **Remove the temporary PROJECT CONTEXT section** after incorporating it into the task list.

---

## Important Constraints

**IMPORTANT: Plan only. Do NOT implement anything.**

- Do NOT assume functionality is missing; confirm with targeted searches first
- Do NOT read entire codebase; focus on relevant areas only
- Use AskUserQuestion liberally - when in doubt, ask the user
- Prefer reading .md files over source files initially
- Only use parallel subagents for targeted searches (max 50-100, not 500)

---

## Debug Integration (Optional)

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

## Key Language Patterns

These are the specific phrases that work best. Use them exactly:

- **"Ask the user"** (when uncertain about requirements or priorities)
- **"don't assume not implemented"** (critical - this is the Achilles' heel)
- **"targeted search"** (not "read everything")
- **"focus on relevant areas"** (not "study entire codebase")
- **"capture the why"** (when documenting)

---

## Output Format

Update @AGENTS.md with the following structure:

```markdown
## Build & Run

[Project-specific build commands - discovered from package.json, Makefile, etc.]

## Validation

[Validation commands: tests, typecheck, lint, etc.]

## Tasks

Prioritized task list (ordered by user's stated priorities):

- [ ] Task 1: [Description] - [Acceptance criteria if possible]
- [ ] Task 2: [Description]
- [x] Task 3: [Description] (if already complete)

## Operational Notes

[Succinct operational learnings - keep brief]

### Debug Skills

[Debug skills available in this project - e.g., /debug from liuxiaoyusky/ai-developer-skills]
```

---

## Completion

When the plan is complete:

1. Show the user a summary of what you've created:
   - Number of tasks identified
   - Top 3 priorities
   - Any critical missing information

2. Ask if the user wants to:
   - Revise the plan
   - Add more tasks
   - Proceed to Build mode

3. If user confirms, output:

```
<PLAN_COMPLETE>
Plan generation complete. Ready to start Build mode with /ralph-wiggum build
```

Then exit. The loop will detect completion and stop.
