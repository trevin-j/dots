# dotctl Improvement Findings

## High

- **Flag parsing is brittle**: global flags are detected but never removed from positional args, so `dotctl install foo --force` can treat `--force` as another package.
  - Evidence: `dotctl/.local/bin/dotctl:418`, `dotctl/.local/bin/dotctl:449`, `dotctl/.local/bin/dotctl:467`
  - Why it matters: breaks valid CLI usage and makes automation unreliable.
  - Fix pattern: replace ad hoc flag detection with a real parser such as `getopts` or a manual `while [[ $# -gt 0 ]]` loop that consumes flags before command dispatch.

- **Manifest loading is too coupled to shell execution**: `load_manifest` directly `source`s package manifests into the main process, so metadata and executable behavior are mixed together.
  - Evidence: `dotctl/.local/bin/dotctl:94`, `dotctl/.local/bin/dotctl:106`, `dotctl/.local/bin/dotctl:223`
  - Why it matters: package metadata becomes arbitrary code execution and the installer becomes harder to test and reason about.
  - Fix pattern: separate declarative manifest data from imperative hooks, or isolate hook execution behind a narrower subprocess interface.

- **Conflict handling is fragile for a file-moving path**: `backup_conflicts` scrapes human-readable `stow -nv` output with `sed`, then moves user files aside.
  - Evidence: `dotctl/.local/bin/dotctl:144`, `dotctl/.local/bin/dotctl:150`, `dotctl/.local/bin/dotctl:167`
  - Why it matters: if `stow` output changes, dotctl can misdetect conflicts right before mutating user files.
  - Fix pattern: replace output scraping with explicit filesystem collision checks or another machine-readable preflight.

## Medium

- **The main script is doing too much in one place**: install planning, manifest parsing, dependency installation, upgrades, tracking, and CLI dispatch all live in one script.
  - Evidence: `dotctl/.local/bin/dotctl:1`
  - Why it matters: maintenance cost grows quickly and targeted testing becomes harder.
  - Fix pattern: split command handling and core helpers into smaller shell modules or command-specific scripts.

- **Path resolution is not very portable or defensive**: the script depends on GNU-style `realpath -m -s` and also uses plain `realpath` on tracked paths.
  - Evidence: `dotctl/.local/bin/dotctl:90`, `dotctl/.local/bin/dotctl:274`, `dotctl/.local/bin/dotctl:284`
  - Why it matters: broken symlinks and non-GNU environments can cause hard failures.
  - Fix pattern: centralize path handling in a helper that explicitly handles missing paths, broken symlinks, and portability constraints.

- **`upgrade` mixes repo sync with package application**: it performs a raw `git pull` before reinstalling packages.
  - Evidence: `dotctl/.local/bin/dotctl:386`
  - Why it matters: dirty repos, detached HEAD states, or non-fast-forward pulls can produce confusing failures.
  - Fix pattern: separate `sync` from `upgrade`, or at minimum add dirty-tree checks and use `git pull --ff-only`.

- **Help output lags the actual feature set**: implemented commands and flags are not fully documented.
  - Evidence: `dotctl/.local/bin/dotctl:401`, `dotctl/.local/bin/dotctl:473`, `dotctl/.local/bin/dotctl:476`
  - Why it matters: discoverability and scriptability are worse than they need to be.
  - Fix pattern: generate help text from the same command/flag definitions used by the parser.

## Low

- **Package enumeration can be made more robust**: `install all` and `ls` use `find | xargs basename` style pipelines.
  - Evidence: `dotctl/.local/bin/dotctl:444`, `dotctl/.local/bin/dotctl:478`
  - Why it matters: results are less deterministic and less robust than necessary.
  - Fix pattern: use safer shell-native enumeration or a dedicated helper function.

- **AUR helper bootstrapping is rough around cleanup/idempotence**: it clones into `$HOME/tmp` and installs inline.
  - Evidence: `dotctl/.local/bin/dotctl:68`, `dotctl/.local/bin/dotctl:73`
  - Why it matters: it leaves temp state behind and is harder to repeat cleanly.
  - Fix pattern: use a proper temp directory and clean it up automatically.

## Resolved

- ~~**Flag parsing is brittle**~~ — fixed in commit `dddf023`; replaced ad hoc detection with a proper argument parse loop.
- ~~**Manifest loading is too coupled to shell execution**~~ — fixed; `load_manifest` now parses manifests line-by-line without `source`, hooks moved to executable files at `meta/pre_dl`, `meta/pre_stow`, `meta/post_stow`, executed as isolated subprocesses via `run_pkg_hook`.
- ~~**Help output lags the actual feature set**~~ — fixed in commit `dddf023`; help now documents all commands and global flags.
- ~~**Conflict handling is fragile**~~ — fixed; replaced `stow -nv` output scraping with explicit filesystem walk in `detect_package_conflicts`, which checks each package file against the target. Added `check_stow_sanity` as a post-backup safety net. Conflicts now include broken symlinks. Added `is_managed_symlink` helper to distinguish already-managed symlinks from real conflicts.

## Testing Notes

- The current shell test suite passed, but it only covers six cases and misses the riskiest edges.
  - Evidence: `dotctl/testing/run:181`, `dotctl/testing/run:231`, `dotctl/testing/run:274`
  - Gaps: flag parsing, conflict backup behavior, `upgrade`, `ls`, help completeness, and broken-symlink/path handling.
  - Fix pattern: add focused tests for failure modes first, especially parser behavior and conflict simulation.

## Overall Assessment

- Architecture: fair; functional, but tightly coupled
- Code quality: fair to good; readable Bash, but several fragile boundaries
- Testing: fair; core flows covered, failure modes under-covered
- Operations and UX: fair; useful commands exist, but safety and discoverability can improve

## Top 3 Next Actions

1. Replace ad hoc flag detection with a real argument parser and align help output with implemented commands.
2. Separate manifest metadata from executable hooks, or at least isolate hook execution from metadata loading.
3. Rework conflict detection and add tests for conflict backup, `upgrade`, and flag parsing.
