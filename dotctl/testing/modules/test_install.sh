#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DOTCTL_LIB="$(cd -- "$SCRIPT_DIR/../../.local/lib/dotctl/lib" && pwd -P)"

source "$DOTCTL_LIB/lib.sh"
source "$DOTCTL_LIB/install.sh"

TEST_COUNT=0
FAILED=0

cleanup_sandbox() {
    if [[ -n "${TEST_ROOT:-}" && -d "$TEST_ROOT" ]]; then
        rm -rf "$TEST_ROOT"
    fi
}

run_case() {
    local name="$1"
    shift

    TEST_COUNT=$((TEST_COUNT + 1))
    printf '[%02d] %s... ' "$TEST_COUNT" "$name"
    if "$@"; then
        echo 'ok'
    else
        echo 'FAIL'
        FAILED=$((FAILED + 1))
    fi
}

assert_equals() {
    local expected="$1" actual="$2"
    [[ "$expected" == "$actual" ]] || return 1
}

assert_output_contains() {
    local output="$1" needle="$2"
    [[ "$output" == *"$needle"* ]] || return 1
}

trap cleanup_sandbox EXIT

# --- load_manifest tests ---

test_load_manifest_parses_requires() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/pkg/meta"
    printf 'export requires=(foo bar)\n' > "$TEST_ROOT/pkg/meta/manifest.sh"

    load_manifest "$TEST_ROOT/pkg/meta/manifest.sh"

    assert_equals 2 ${#requires[@]} || return 1
    [[ "${requires[0]}" == "foo" ]] || return 1
    [[ "${requires[1]}" == "bar" ]] || return 1
}

test_load_manifest_parses_pacman_deps() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/pkg/meta"
    printf 'export pacman_deps=(pkg-a pkg-b)\n' > "$TEST_ROOT/pkg/meta/manifest.sh"

    load_manifest "$TEST_ROOT/pkg/meta/manifest.sh"

    assert_equals 2 ${#pacman_deps[@]} || return 1
    [[ "${pacman_deps[0]}" == "pkg-a" ]] || return 1
}

test_load_manifest_parses_aur_deps() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/pkg/meta"
    printf 'export aur_deps=(some-aur-package)\n' > "$TEST_ROOT/pkg/meta/manifest.sh"

    load_manifest "$TEST_ROOT/pkg/meta/manifest.sh"

    assert_equals 1 ${#aur_deps[@]} || return 1
    [[ "${aur_deps[0]}" == "some-aur-package" ]] || return 1
}

test_load_manifest_ignores_deps() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/pkg/meta"
    printf 'export deps=(legacy-package)\n' > "$TEST_ROOT/pkg/meta/manifest.sh"

    load_manifest "$TEST_ROOT/pkg/meta/manifest.sh"

    assert_equals 0 ${#requires[@]} || return 1
    assert_equals 0 ${#pacman_deps[@]} || return 1
    assert_equals 0 ${#aur_deps[@]} || return 1
}

test_load_manifest_handles_multiline() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/pkg/meta"
    cat > "$TEST_ROOT/pkg/meta/manifest.sh" <<'EOF'
export requires=(foo)
export pacman_deps=(bar baz)
export aur_deps=(qux)
EOF

    load_manifest "$TEST_ROOT/pkg/meta/manifest.sh"

    assert_equals 1 ${#requires[@]} || return 1
    assert_equals 2 ${#pacman_deps[@]} || return 1
    assert_equals 1 ${#aur_deps[@]} || return 1
}

# --- detect_package_conflicts tests ---

test_detect_conflicts_reports_existing_file() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    DOTDIR="$TEST_ROOT/dotdir"
    HOME="$TEST_ROOT/home"
    mkdir -p "$DOTDIR/pkg/.config/pkg" "$HOME/.config/pkg"

    printf 'config\n' > "$DOTDIR/pkg/.config/pkg/settings.conf"
    printf 'existing\n' > "$HOME/.config/pkg/settings.conf"

    local output
    output=$(detect_package_conflicts pkg 2>&1)
    [[ "$output" == *"Conflicts detected"* ]] || return 1
    [[ "$output" == *"settings.conf"* ]] || return 1
}

test_detect_conflicts_skips_managed_symlink() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    DOTDIR="$TEST_ROOT/dotdir"
    HOME="$TEST_ROOT/home"
    mkdir -p "$DOTDIR/pkg/.config/pkg" "$HOME/.config/pkg"

    printf 'config\n' > "$DOTDIR/pkg/.config/pkg/settings.conf"
    ln -s "$DOTDIR/pkg/.config/pkg/settings.conf" "$HOME/.config/pkg/settings.conf"

    local output
    output=$(detect_package_conflicts pkg 2>&1)
    [[ "$output" != *"Conflicts detected"* ]] || return 1
}

test_detect_conflicts_reports_broken_symlink() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    DOTDIR="$TEST_ROOT/dotdir"
    HOME="$TEST_ROOT/home"
    mkdir -p "$DOTDIR/pkg/.config/pkg" "$HOME/.config/pkg"

    printf 'config\n' > "$DOTDIR/pkg/.config/pkg/settings.conf"
    ln -s "$DOTDIR/nonexistent" "$HOME/.config/pkg/settings.conf"

    local output
    output=$(detect_package_conflicts pkg 2>&1)
    [[ "$output" == *"Conflicts detected"* ]] || return 1
}

test_detect_conflicts_skips_directory() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    DOTDIR="$TEST_ROOT/dotdir"
    HOME="$TEST_ROOT/home"
    mkdir -p "$DOTDIR/pkg/.config/pkg" "$HOME/.config/pkg"

    printf 'config\n' > "$DOTDIR/pkg/.config/pkg/settings.conf"
    mkdir -p "$HOME/.config/pkg"

    local output
    output=$(detect_package_conflicts pkg 2>&1)
    [[ "$output" != *"Conflicts detected"* ]] || return 1
}

test_detect_conflicts_empty_on_no_conflicts() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    DOTDIR="$TEST_ROOT/dotdir"
    HOME="$TEST_ROOT/home"
    mkdir -p "$DOTDIR/pkg/.config/pkg" "$HOME/.config/other"

    printf 'config\n' > "$DOTDIR/pkg/.config/pkg/settings.conf"

    local output
    output=$(detect_package_conflicts pkg 2>&1)
    [[ -z "$output" ]] || return 1
}

# --- handle_deps tests ---

test_handle_deps_skips_installed() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/bin"

    cat > "$TEST_ROOT/bin/pacman" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-Q" ]]; then
    # pretend everything is installed
    exit 0
fi
echo "unexpected pacman args: $*" >&2
exit 1
EOF
    chmod +x "$TEST_ROOT/bin/pacman"

    cat > "$TEST_ROOT/bin/sudo" <<'EOF'
#!/usr/bin/env bash
echo "sudo invoked: $*" >&2
exit 1
EOF
    chmod +x "$TEST_ROOT/bin/sudo"

    local output
    output=$(PATH="$TEST_ROOT/bin:$PATH" handle_deps pacman foo bar 2>&1)

    [[ "$output" == *"already installed"* ]] || return 1
    [[ "$output" != *"Installing missing"* ]] || return 1
}

test_handle_deps_installs_missing() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/bin"

    cat > "$TEST_ROOT/bin/pacman" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-Q" ]]; then
    # nothing is installed
    exit 1
fi
echo "pacman install: $*"
EOF
    chmod +x "$TEST_ROOT/bin/pacman"

    cat > "$TEST_ROOT/bin/sudo" <<'EOF'
#!/usr/bin/env bash
"$@"
EOF
    chmod +x "$TEST_ROOT/bin/sudo"

    local output
    output=$(PATH="$TEST_ROOT/bin:$PATH" handle_deps pacman foo bar 2>&1)

    [[ "$output" == *"Installing missing"* ]] || return 1
    [[ "$output" == *"pacman install: -S --needed --noconfirm foo bar"* ]] || return 1
}

test_handle_deps_mixed_installed_missing() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/bin"

    cat > "$TEST_ROOT/bin/pacman" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-Q" ]]; then
    # only "foo" is installed
    if [[ "$2" == "foo" ]]; then
        exit 0
    fi
    exit 1
fi
echo "pacman install: $*"
EOF
    chmod +x "$TEST_ROOT/bin/pacman"

    cat > "$TEST_ROOT/bin/sudo" <<'EOF'
#!/usr/bin/env bash
"$@"
EOF
    chmod +x "$TEST_ROOT/bin/sudo"

    local output
    output=$(PATH="$TEST_ROOT/bin:$PATH" handle_deps pacman foo bar 2>&1)

    [[ "$output" == *"Installing missing"* ]] || return 1
    [[ "$output" == *"pacman install: -S --needed --noconfirm bar"* ]] || return 1
    [[ "$output" != *"foo"*"install"* ]] || return 1
}

test_handle_deps_empty_after_filter() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/bin"

    cat > "$TEST_ROOT/bin/pacman" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$TEST_ROOT/bin/pacman"

    local output
    output=$(PATH="$TEST_ROOT/bin:$PATH" handle_deps pacman 2>&1)
    [[ -z "$output" ]] || return 1
}

echo "=== install.sh module tests ==="
echo

run_case 'load_manifest parses requires' test_load_manifest_parses_requires
run_case 'load_manifest parses pacman_deps' test_load_manifest_parses_pacman_deps
run_case 'load_manifest parses aur_deps' test_load_manifest_parses_aur_deps
run_case 'load_manifest ignores legacy deps' test_load_manifest_ignores_deps
run_case 'load_manifest handles multiline manifest' test_load_manifest_handles_multiline
run_case 'detect conflicts reports existing file' test_detect_conflicts_reports_existing_file
run_case 'detect conflicts skips managed symlink' test_detect_conflicts_skips_managed_symlink
run_case 'detect conflicts reports broken symlink' test_detect_conflicts_reports_broken_symlink
run_case 'detect conflicts skips directory' test_detect_conflicts_skips_directory
run_case 'detect conflicts empty on no conflicts' test_detect_conflicts_empty_on_no_conflicts
run_case 'handle_deps skips installed packages' test_handle_deps_skips_installed
run_case 'handle_deps installs missing packages' test_handle_deps_installs_missing
run_case 'handle_deps handles mixed installed/missing' test_handle_deps_mixed_installed_missing
run_case 'handle_deps empty when no deps' test_handle_deps_empty_after_filter

echo
echo "Module tests: $TEST_COUNT run, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
    exit 1
fi
