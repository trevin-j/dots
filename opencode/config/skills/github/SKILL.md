---
name: github
description: Use the GitHub CLI (gh) to manage issues, pull requests, labels, and repo metadata; includes safe body formatting with temp files or HEREDOCs to avoid shell mangling.
license: MIT
author: DevTrev
---

# Skill: github

Use the GitHub CLI (`gh`) to manage issues, pull requests, checks, and related workflows. Prioritize safety, correctness, and clear formatting.

## Core Principles
- Verify the target repo before creating or editing items.
- Use non-interactive commands only.
- Prefer explicit labels and structured templates.
- Avoid shell mangling by using temporary body files or HEREDOCs.

## Repo Verification
1) Confirm remotes and repo identity:
   - `git remote -v`
   - `gh repo view --json nameWithOwner,url`
2) Ensure the issue/PR is created against the intended repo.

## Issues

### Create an Issue (recommended workflow)
1) Create a temporary markdown file for the body.
2) Write the full issue content into the file.
3) Create the issue with `--body-file`.
4) Delete the temporary file.

Example:
```
cat <<'EOF' > .tmp_issue.md
## Summary
<one-paragraph summary>

## Problem
<what is wrong>

## Proposal
- <bullet list>

## Acceptance Criteria
- <bullet list>

## Context
<links or file paths>
EOF

gh issue create --title "<title>" --label "backend,enhancement" --body-file .tmp_issue.md
rm .tmp_issue.md
```

### Edit an Issue (recommended workflow)
```
cat <<'EOF' > .tmp_issue.md
<full updated body>
EOF

gh issue edit <number> --body-file .tmp_issue.md
rm .tmp_issue.md
```

## Pull Requests

### Create a PR (recommended workflow)
1) Run all CI checks (lints, tests, static analysis, type checks, etc.) and confirm they pass.
2) Ensure branch is pushed.
3) Use a HEREDOC for the body to preserve formatting.

Example:
```
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
- <bullet>
- <bullet>

## Testing
- <command>
EOF
)"
```

### Edit a PR
```
gh pr edit <number> --title "<title>"
gh pr edit <number> --body "$(cat <<'EOF'
<updated body>
EOF
)"
```

## Labels
List labels before selecting:
```
gh label list --limit 200
```

## Safety Checklist
- Confirm repo via `gh repo view`.
- Use `--body-file` or HEREDOC to avoid shell parsing.
- Remove temp files after use.
- Avoid interactive flags (`-i`).
