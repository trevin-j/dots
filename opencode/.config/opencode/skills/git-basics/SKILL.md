---
name: git-basics
description: Guide Opencode through coding tasks where git should be utilized. Use when the user asks to implement a specific change and commit it, or says “commit this,” “make the change and commit,” or similar.
license: MIT
author: DevTrev
---

# Git Basics

## Overview

Apply a disciplined, test-first git commit workflow for coding tasks that end in a commit.
Enforce Conventional Commits with scope, run tests/lint/static analysis, keep commits narrowly scoped by excluding unrelated formatting or incidental changes, and raise concerns before committing.

## Workflow

1. Confirm the task and repo state
   - Verify the repo is a git repository and identify the target branch.
   - Review `git status`, `git diff`, and recent commit messages to match style.
2. Implement the requested change only
   - Keep edits minimal and aligned to the request.
   - Avoid drive-by formatting or refactors unless explicitly requested.
3. Enforce scope hygiene
   - If a formatter or tool touches unrelated lines, revert those unrelated hunks.
   - If unrelated changes are already present in the working tree, do not modify or revert them unless asked.
4. Run quality gates
   - Run tests, linters, and static analysis relevant to the change.
   - If failures occur, report them and ask how to proceed before committing.
5. Draft a Conventional Commit
   - Use `type(scope): summary` with a specific scope and clear purpose.
   - Prefer summaries that explain intent (the “why”), not just the file edits.
6. Commit and verify
   - Stage only the intended files.
   - Commit with the prepared message.
   - Re-run `git status` to confirm a clean working tree.

## Commit Message Guidance

- Use Conventional Commits: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `build`, `ci`, `perf`, `style`.
- Always include a scope that reflects the module or area changed.
- Keep the subject precise and descriptive; avoid vague verbs like “update.”

## Quality and Risk Checks

- Run the relevant test suite and static analysis tools before committing.
- If tests are slow, ask whether to run the full suite or a targeted subset.
- Flag concerns about formatting churn, ambiguous requirements, or risky changes before committing.

## When to Ask the User

- The repo has failing tests or lint errors after changes.
- The diff includes unrelated formatting or accidental edits.
- The requested change is ambiguous or risky.
- Commit scope is unclear or spans multiple concerns.
