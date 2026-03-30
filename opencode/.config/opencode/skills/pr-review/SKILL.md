---
name: pr-review
description: Reviews GitHub pull requests with structured findings on code quality, security, performance, and test coverage. Use when user asks to "review PR", "review pull request", "review 123", "review owner/repo#123", "review https://github.com/owner/repo/pull/123", or similar PR review requests. Always attempts to clone the repo and create a worktree for full git analysis before resorting to API-only review. Never proceeds with degraded review without explicit user permission.
license: MIT
author: DevTrev
---

# PR Review Skill

## Overview

Review a GitHub pull request using `gh api` to fetch PR details (works regardless of worktree dirtiness) and create a temporary worktree for actual code review.

## Workflow

### 1. Parse PR Input

Accept flexible input formats:
- PR number: `review 123`
- Full URL: `review https://github.com/owner/repo/pull/123`
- Owner/repo#number: `review owner/repo#123`
- Short form: `review owner/repo-123` (GitHub's copy-link format)

Extract: owner, repo, PR number

### 2. Fetch PR Metadata via gh api

```bash
# Get PR details
gh api repos/{owner}/{repo}/pulls/{pr_number}

# Get existing review comments
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments

# Get changed files
gh api repos/{owner}/{repo}/pulls/{pr_number}/files
```

Key fields from PR metadata:
- `title`, `body`, `state`, `base.ref`, `head.ref`
- `user.login` (author)
- `additions`, `deletions`, `changed_files`
- `labels[]`, `requested_reviewers[]`

### 3. Find or Clone the Repository

#### A. Check for local repo first

Before cloning, check if the repo already exists locally in the current directory:

```bash
# List contents of current directory to find matching repo
ls -la

# Or use glob to find directories matching owner-repo or repo pattern
ls -d *-{repo} *{repo} 2>/dev/null
```

If the repo is found locally, you can create a worktree from the existing checkout.

#### B. Clone if not found locally

If the repo is not found, attempt to clone in this order:

1. **Try gh cli first** (handles authentication automatically):
```bash
gh repo clone {owner}/{repo}
```

2. **If gh fails, try git SSH**:
```bash
git clone git@github.com:{owner}/{repo}.git
```

3. **If SSH fails, try git HTTPS**:
```bash
git clone https://github.com/{owner}/{repo}.git
```

4. **If all clone methods fail**: STOP immediately. Do NOT proceed with API-only review. Report to the user:
> "I couldn't access the repository '{owner}/{repo}'. I tried gh CLI, git SSH, and git HTTPS but all failed. Please ensure:
> - You have appropriate GitHub permissions for this private repo
> - The repository exists and the URL is correct
> 
> Would you like me to proceed with a limited review using only the PR metadata and diffs from the GitHub API? (Note: This would be a degraded review with no git history or full file context.)"

Only proceed with API-only review if the user explicitly authorizes it.

#### C. Create Temporary Worktree

Once you have a local clone, create a worktree for the PR:

```bash
# Get the PR head ref
git fetch origin pull/{pr_number}/head:pr-{pr_number}

# Create worktree in temp location
WORKTREE_DIR=$(mktemp -d)
git worktree add "$WORKTREE_DIR" pr-{pr_number}
```

### 4. Perform Review

In the worktree, analyze:
- `git log origin/{base}..HEAD` - commits in PR
- `git diff origin/{base}...HEAD` - full diff
- Changed files for: code quality, security, performance, tests

### 5. Review Dimensions

| Dimension | What to Check |
|-----------|---------------|
| **Code Quality** | Style consistency, naming, complexity, error handling |
| **Security** | Input validation, auth checks, sensitive data exposure, SQL/command injection |
| **Performance** | N+1 queries, unnecessary iterations, memory leaks, missing indexes |
| **Tests** | Test coverage, edge cases, mocking quality |
| **Architecture** | Coupling, separation of concerns, API design |
| **Redundancy** | Modular code and no redundant code or functions with more than one focus |

### 6. Output Structured Findings

```
## PR Summary
- **Author**: {author}
- **Branch**: {head} → {base}
- **Size**: {changed_files} files, +{additions}/-{deletions}
- **Labels**: {labels}

## Review Findings

### Blocking Issues (must fix)
- [ ] {issue}

### Suggestions (should consider)
- [ ] {suggestion}

### Nitpicks (optional)
- [ ] {nitpick}

### Praises (worth keeping)
- [ ] {positive}

## Recommendation
{APPROVE / REQUEST_CHANGES / COMMENT}
```

## Error Handling

- If `gh api` fails: report authentication error, ask user to run `gh auth login`
- If PR not found: verify PR number and repo, suggest checking PR is open
- If all clone attempts fail: STOP and report to user (see step 3B)
- If worktree creation fails after successful clone: report error with git version check
- **Never fall back to API-only review without explicit user permission**
- Always cleanup worktrees and cloned repos even on error

## Cleanup

```bash
# Remove worktree
git worktree remove "$WORKTREE_DIR"

# Remove cloned repo if you created it (don't remove if repo existed locally)
if [ -d "{repo}" ] && [ ! -d ".git" ]; then
  rm -rf "{repo}"  # Only if this was a fresh clone with no .git at origin
fi

# Clean up fetched branch
git branch -D pr-{pr_number} 2>/dev/null || true
```

## Key Principles

- **Always attempt full clone before API-only review** - full git analysis is always preferred
- **Create worktree for actual review** - allows full git analysis without dirtying working directory
- **Report blocking issues separately from suggestions** - helps author prioritize
- **Be concise** - focus on high-impact findings
- **Never proceed with degraded review without user consent** - the user deserves to know they're getting limited analysis
