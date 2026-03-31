---
name: git
description: Guide Opencode through coding tasks where git should be utilized. Use when the user asks to implement a specific change and commit it, or says "commit this," "make the change and commit," or similar. Also use for branch creation, listing, cleanup, and management tasks.
license: MIT
author: DevTrev
---

# Git Basics

## Overview

Apply a disciplined, test-first git commit workflow for coding tasks that end in a commit. Enforce Conventional Commits with scope, run tests/lint/static analysis, keep commits narrowly scoped by excluding unrelated formatting or incidental changes, and raise concerns before committing.

## ⚠️ CRITICAL: Branch Safety Rules

### NEVER Commit Directly to Protected Branches
- **NEVER** commit directly to `main`, `master`, or `develop` unless explicitly instructed by the user
- **ALWAYS** create a feature branch for new work
- **WHEN IN DOUBT**: Ask the user before committing

### Branch Selection Decision Tree
```
Starting work on a feature/fix:
├── Is current branch main/master/develop?
│   ├── YES → Create feature branch first (see naming below)
│   └── NO → Continue on current branch if appropriately named
└── Is the branch name scoped to this specific work?
    ├── YES → Commit to current branch
    └── NO → Create new appropriately-named branch
```

### Before Committing Checklist
- [ ] Check current branch with `git branch --show-current`
- [ ] If on main/master/develop: STOP and create feature branch
- [ ] If branch name is generic (e.g., "feature", "test"): Consider creating scoped branch
- [ ] If unsure: Ask the user "Should I commit to the current branch or create a feature branch?"

## 🚨 CRITICAL: NEVER PUSH AUTOMATICALLY

**UNDER NO CIRCUMSTANCES should you push to remote repositories automatically.**

- **NEVER** run `git push` without explicit user approval
- **NEVER** push to origin, upstream, or any remote
- **NEVER** assume pushing is safe
- **NEVER** use `--force` or `-f` flags

### After Committing: Ask Before Pushing
After making a commit, you **MUST** ask the user:
> "I've committed the changes to branch `<branch-name>`. Would you like me to push this branch to the remote repository?"

Wait for explicit confirmation (yes/no) before pushing.

### Why This Matters
- The user may want to review before sharing
- There may be pre-commit hooks that need to run
- The user may be on a different branch locally
- Pushing can trigger CI/CD pipelines
- Force pushing can destroy work

## Workflow

1. **Check Current Branch and State**
   - Run `git branch --show-current` to identify where you are
   - If on `main`/`master`/`develop`: Create feature branch before any commits
   - Review `git status`, `git diff`, and recent commit messages to match style

2. **Create Feature Branch (if needed)**
   - Determine appropriate branch name (see Branch Naming Convention below)
   - Get user's name from `git config user.name` (first name, lowercase)
   - Create branch: `git checkout -b <branch-name>`
   - Proceed with implementation

3. **Implement the requested change only**
   - Keep edits minimal and aligned to the request.
   - Avoid drive-by formatting or refactors unless explicitly requested.

4. **Enforce scope hygiene**
   - If a formatter or tool touches unrelated lines, revert those unrelated hunks.
   - If unrelated changes are already present in the working tree, do not modify or revert them unless asked.

5. **Run quality gates**
   - Run tests, linters, and static analysis relevant to the change.
   - If failures occur, report them and ask how to proceed before committing.

6. **Draft a Conventional Commit**
   - Use `type(scope): summary` with a specific scope and clear purpose.
   - Prefer summaries that explain intent (the "why"), not just the file edits.

7. **Commit and verify**
   - Stage only the intended files.
   - Commit with the prepared message.
   - Re-run `git status` to confirm a clean working tree.

8. **Ask about pushing (DO NOT PUSH AUTOMATICALLY)**
   - Ask: "Would you like me to push branch `<branch-name>` to remote?"
   - Wait for explicit user confirmation
   - Only push if user says yes

## Commit Message Guidance

- Use Conventional Commits: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`,
`build`, `ci`, `perf`, `style`.
- Always include a scope that reflects the module or area changed.
- Keep the subject precise and descriptive; avoid vague verbs like "update."
- Always include the summary title in conventional commit format, and
a detailed description with further details.
- Always note breaking changes with an exclamation point according to official
conventional commit standards, along with detail in the description.

## Branch Naming Convention

Use `<name>/<type>/<short-summary>` format where `<name>` is the user's first name from `git config user.name`:

### Getting User's Name
```bash
# Get first name from git config, lowercase
git config user.name | awk '{print tolower($1)}'
# Example: "Trevin Jones" → "trevin"
```

### Format: `name/type/summary`

| Type | Use For | Examples (for user "Trevin") |
|------|---------|------------------------------|
| `feat/` | New features | `trevin/feat/user-auth`, `trevin/feat/add-dark-mode` |
| `fix/` | Bug fixes | `trevin/fix/login-crash`, `trevin/fix/memory-leak` |
| `chore/` | Maintenance | `trevin/chore/update-deps`, `trevin/chore/refactor-utils` |
| `docs/` | Documentation | `trevin/docs/api-guide`, `trevin/docs/readme-update` |
| `refactor/` | Code refactoring | `trevin/refactor/auth-module`, `trevin/refactor/cleanup-db` |
| `test/` | Tests only | `trevin/test/user-flows`, `trevin/test/add-integration` |
| `hotfix/` | urgent production fixes | `trevin/hotfix/security-patch`, `trevin/hotfix/crash-on-start` |
| `release/` | Release branches | `trevin/release/v2.0.0` |

Rules:
- Use lowercase for name and type
- Use hyphens to separate words in summary
- Keep short summary under 50 characters
- Be specific: `trevin/feat/user-auth` not `trevin/feat/changes`
- Always prefix with user's name for personal attribution

## Quality and Risk Checks

- Run the relevant test suite and static analysis tools before committing.
- If tests are slow, ask whether to run the full suite or a targeted subset.
- Flag concerns about formatting churn, ambiguous requirements, or risky changes before committing.

## When to Ask the User

- **ALWAYS ask**: Current branch is main/master/develop - "Should I create a feature branch for this work?"
- **ALWAYS ask**: Branch name doesn't reflect the work being done
- **ALWAYS ask**: After committing - "Would you like me to push this branch?"
- The repo has failing tests or lint errors after changes.
- The diff includes unrelated formatting or accidental edits.
- The requested change is ambiguous or risky.
- Commit scope is unclear or spans multiple concerns.
- **Any uncertainty about git workflow** - better to ask than commit incorrectly

## Example Scenarios

### Scenario 1: On develop branch, starting new feature
```bash
# WRONG - Don't do this
git add .
git commit -m "feat: add new feature"  # ❌ Commits directly to develop!

# CORRECT
git config user.name  # Get: "Trevin Jones"
# Use: trevin as prefix
git checkout -b trevin/feat/user-invitations   # ✅ Create feature branch first
git add .
git commit -m "feat(invitations): add user invitation system"
# Then ask: "Would you like me to push trevin/feat/user-invitations?"
```

### Scenario 2: Unclear branch situation
```
User: "Add a login page"
AI: "I see we're currently on the 'develop' branch. Should I:
  1. Create a feature branch (trevin/feat/login-page) for this work?
  2. Or commit directly to develop?"
[Wait for user response before proceeding]
```

### Scenario 3: User explicitly requests direct commit
```
User: "Commit this hotfix directly to main"
AI: "Understood, you want me to commit directly to main. Proceeding with hotfix..."
# Only now proceed with commit to main
```

### Scenario 4: After committing, asking to push
```
AI: "I've successfully committed the changes to branch 'trevin/feat/user-invitations'.

Would you like me to push this branch to the remote repository?

Options:
- 'yes' or 'y' - I'll push the branch
- 'no' or 'n' - Branch stays local only
"
[Wait for user response - DO NOT PUSH AUTOMATICALLY]
```

## Forbidden Commands

**NEVER run these without explicit user instruction:**

```bash
# ❌ NEVER push automatically
git push
git push origin <branch>
git push -u origin <branch>

# ❌ NEVER force push
git push --force
git push -f
git push --force-with-lease

# ❌ NEVER push to main/master/develop directly
git push origin main
git push origin master
git push origin develop

# ❌ NEVER delete remote branches without confirmation
git push origin --delete <branch>
```
