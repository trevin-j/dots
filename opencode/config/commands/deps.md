---
description: Audit project dependencies for outdated or vulnerable packages
author: DevTrev
license: MIT
---

Perform a dependency audit for this project.

1. Detect the package manager (npm, pip, cargo, go mod, etc.)
2. Check for outdated dependencies
3. Check for known vulnerabilities using native tools (npm audit, pip audit, cargo audit, etc.)
4. Report findings with severity levels

Return a prioritized list of updates needed, distinguishing between:
- Security vulnerabilities (update immediately)
- Major version updates (review before updating)
- Minor/patch updates (can wait)
