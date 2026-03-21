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
  - Evidence: `dotctl/.local/bin/dotctl:1` (pre-split)
  - Why it matters: maintenance cost grows quickly and targeted testing becomes harder.
  - Fix pattern: split command handling and core helpers into smaller shell modules or command-specific scripts.

- **Path resolution is not very portable or defensive**: the script depends on GNU-style `realpath -m -s` and also uses plain `realpath` on tracked paths.
  - Evidence: `dotctl/.local/bin/dotctl:90`, `dotctl/.local/bin/dotctl:274`, `dotctl/.local/bin/dotctl:284` (pre-split)
  - Why it matters: broken symlinks and non-GNU environments can cause hard failures.
  - Fix pattern: centralize path handling in a helper that explicitly handles missing paths, broken symlinks, and portability constraints.

- **Help output lags the actual feature set**: implemented commands and flags are not fully documented.
  - Evidence: `dotctl/.local/bin/dotctl:401`, `dotctl/.local/bin/dotctl:473`, `dotctl/.local/bin/dotctl:476` (pre-split)
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
- ~~**Upgrade mixes repo sync with package application**~~ — fixed; separated `sync`, `upgrade`, and `update` into distinct commands. `sync` validates clean repo state, runs `git pull --ff-only`, and fails with guidance on dirty or divergent history. `upgrade` reinstalls packages without touching the repo. `update` combines both. Removed `--no-pull`; `upgrade --no-pull` now errors with guidance to use `sync` or `update` instead.

- ~~**The main script is doing too much in one place**~~ — fixed; split into 5 module files under `.local/lib/dotctl/lib/`: `lib.sh` (shared utilities and globals), `install.sh` (install pipeline), `track.sh` (tracking and merging), `sync.sh` (git sync), `upgrade.sh` (reinstall), `update.sh` (orchestration). Entry point `.local/bin/dotctl` is now a thin dispatcher (~150 lines) that sources modules and dispatches. Added per-module unit tests under `testing/modules/`.

- ~~**Help output lags the actual feature set**~~ — help text is now aggregated from `cmd_<name>_help` functions defined in each module, so help is always in sync with the commands available.

## Testing Notes

- The integration test suite (`testing/run`) covers 19 cases including all major command paths, conflict detection, git safety, and flag parsing.
- Per-module unit tests in `testing/modules/` cover `lib.sh`, `install.sh`, and `track.sh` with 31 unit tests total covering individual function behavior.
- Remaining test gaps: per-module tests for `sync.sh`, `upgrade.sh`, and `update.sh` (covered by integration tests); `ls` command output; edge cases in `merge_directory_into_destination`.

## Overall Assessment

- Architecture: good; modular with clear separation of concerns
- Code quality: good; readable Bash with logical module boundaries
- Testing: good; 19 integration + 31 unit tests, major failure modes covered
- Operations and UX: good; all commands documented, git safety enforced

## Top 3 Next Actions

1. Add remaining per-module unit tests for `sync.sh`, `upgrade.sh`, and `update.sh`.
2. Address `ls` command coverage in integration tests.
3. Address AUR helper bootstrapping roughness (low priority).
