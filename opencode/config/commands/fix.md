---
description: Debug and fix issues in the codebase
license: MIT
author: DevTrev
---

Use the grand-master orchestrator to debug and fix issues.

1. First, use the `debug-reporter` subagent to diagnose the issue and identify the root cause.

2. Then, use the `builder` subagent to implement the minimal fix for each identified issue.

3. After implementing fixes, run validation (tests, lints) to confirm the fixes work.

4. Report back what was found and what was fixed.

The debug-reporter will investigate without modifying code. The builder will implement only the minimal changes needed to fix the issues.
