---
description: Generate a terse caveman-style commit message
author: DevTrev
license: MIT
---

Load the `caveman-commit` skill, then generate a commit message for the current staged changes.

Behavior:
1. Inspect the staged changes only.
2. Follow the skill's Conventional Commits rules.
3. Prefer a subject-only commit when the why is obvious.
4. Add a body only when the why is not obvious, or for breaking changes, security fixes, migrations, or reverts.
5. Output only the commit message in a fenced code block ready to paste.

Do not stage files. Do not run `git commit`.
