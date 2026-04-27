---
name: project-dependencies
description: Guide through tasks where project dependencies must be added.
license: MIT
author: DevTrev
---

## Project Dependencies

Project dependencies MUST be managed via command line utilities and NEVER by
directly editing project files. For example, use `npm add <dep>`, `uv add
<dep>`, `flutter pub add <dep>`, `cargo add <dep>`, etc. Do NOT specify version
numbers in these commands unless explicitly told to or the project is using a
version of the dependency that is not the latest version.

**NEVER** manually edit `pyproject.toml`, `Cargo.toml`, `package.json`,
`go.mod`, `Gemfile`, or any other dependency manifest file by hand. Always use
the appropriate CLI tool for the project's ecosystem.

