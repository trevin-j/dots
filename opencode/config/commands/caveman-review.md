---
description: Review current changes with terse caveman review comments
author: DevTrev
license: MIT
---

Load the `caveman-review` skill, then review the current code changes.

Behavior:
1. Inspect the current diff or changed files relevant to the user's request.
2. Output one line per finding using the format defined by the skill.
3. Keep findings concrete and actionable.
4. Skip praise and obvious restatements.
5. If there are no meaningful findings, say `LGTM` and stop.

Do not implement fixes unless the user asks separately.
