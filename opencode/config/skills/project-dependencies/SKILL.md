---
name: project-dependencies
description: Guide through tasks where project dependencies must be added.
license: MIT
author: DevTrev
---

## Project Dependencies

Where possible, project dependencies should be managed via command line
utilities and not by directly editing project files. For example, use `npm add
<dep>`, `uv add <dep>`, `flutter pub add <dep>`, `cargo add <dep>` etc. Do not
specify version numbers in these commands unless explicitly told to or the
project is using a version of the dependency that is not the latest version.

