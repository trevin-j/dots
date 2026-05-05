## Subagent Usage Guidelines

Use subagents for:

1. **Parallel execution** - Perform multiple tasks simultaneously
2. **Context isolation** - Tasks that produce verbose output
3. **Specialized workflows** - Security audits, test writing, refactoring
4. **Long-running tasks** - Keep main context clean while AI works

## Long-Running Task Guidelines

For tasks that run without interruption:

1. Subagents maintain isolated context
2. Main agent stays informed via summaries
3. User remains decision-maker - subagents suggest, user approves

## Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 0. Critical Non-Negotiable Rules

These rules are mandatory and take precedence over all other guidelines.

**Be brief**

**Run all CI checks before opening any PR**
- Before creating or opening a pull request, you MUST run every check that CI would run (lints, tests, static analysis, type checks, etc.) and confirm they all pass.
- Do NOT skip this step or assume checks will pass.
- Do NOT open a PR with failing checks.

**Use CLI tools for all dependency changes**
- When adding, removing, or modifying dependencies, you MUST use the appropriate CLI tool (e.g., `cargo add`, `npm add`, `uv add`, `flutter pub add`).
- NEVER manually edit `pyproject.toml`, `Cargo.toml`, `package.json`, or any other dependency manifest file by hand.
- ALWAYS load the `project-dependencies` skill when touching anything related to dependencies.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
