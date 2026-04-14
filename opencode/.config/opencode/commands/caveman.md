---
description: Activate caveman response mode with optional intensity
author: DevTrev
license: MIT
---

Load the `caveman` skill and apply it for the rest of the conversation.

The selected mode is: $ARGUMENTS
If no mode specified, default to "full" mode.

Behavior:
1. Supported modes: `lite`, `full`, `ultra`, `wenyan-lite`, `wenyan`, `wenyan-ultra`.
2. Respond in the selected caveman mode starting now.
3. Keep caveman mode active for later responses until the user says `stop caveman` or `normal mode`.
4. If the requested mode is invalid, say which modes are supported and default to `full`.

Examples:
- `/caveman` -> use `full`
- `/caveman ultra` -> use `ultra`
- `/caveman wenyan` -> use `wenyan`
