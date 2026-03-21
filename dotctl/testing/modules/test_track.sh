#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DOTCTL_LIB="$(cd -- "$SCRIPT_DIR/../../.local/lib/dotctl/lib" && pwd -P)"

source "$DOTCTL_LIB/lib.sh"
source "$DOTCTL_LIB/track.sh"

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

trap cleanup_sandbox EXIT

# --- same_realpath tests ---

test_same_realpath_same_file() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    printf 'hello\n' > "$TEST_ROOT/file.txt"
    same_realpath "$TEST_ROOT/file.txt" "$TEST_ROOT/file.txt"
}

test_same_realpath_symlink_to_same() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    printf 'hello\n' > "$TEST_ROOT/file.txt"
    ln -s "$TEST_ROOT/file.txt" "$TEST_ROOT/link.txt"
    same_realpath "$TEST_ROOT/file.txt" "$TEST_ROOT/link.txt"
}

test_same_realpath_different_files() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    printf 'hello\n' > "$TEST_ROOT/a.txt"
    printf 'world\n' > "$TEST_ROOT/b.txt"
    ! same_realpath "$TEST_ROOT/a.txt" "$TEST_ROOT/b.txt" || return 1
}

test_same_realpath_missing_left() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    printf 'world\n' > "$TEST_ROOT/b.txt"
    ! same_realpath "$TEST_ROOT/nonexistent.txt" "$TEST_ROOT/b.txt" || return 1
}

# --- merge_directory_into_destination tests ---

test_merge_moves_matching_symlink() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/src" "$TEST_ROOT/dst"
    printf 'hello\n' > "$TEST_ROOT/src/file.txt"
    ln -s "$TEST_ROOT/src/file.txt" "$TEST_ROOT/dst/file.txt"

    merge_directory_into_destination "$TEST_ROOT/src" "$TEST_ROOT/dst"

    [[ -e "$TEST_ROOT/src/file.txt" ]] || return 1
    [[ -L "$TEST_ROOT/dst/file.txt" ]] || return 1
}

test_merge_replaces_conflicting_file() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/src" "$TEST_ROOT/dst"
    printf 'src version\n' > "$TEST_ROOT/src/file.txt"
    printf 'dst version\n' > "$TEST_ROOT/dst/file.txt"
    package="test-pkg"

    (merge_directory_into_destination "$TEST_ROOT/src" "$TEST_ROOT/dst") 2>/dev/null && return 1 || return 0
}

test_merge_merges_subdirectories() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/src/sub" "$TEST_ROOT/dst/sub"
    printf 'file1\n' > "$TEST_ROOT/src/sub/file1.txt"
    printf 'file2\n' > "$TEST_ROOT/src/sub/file2.txt"
    printf 'existing\n' > "$TEST_ROOT/dst/sub/existing.txt"

    merge_directory_into_destination "$TEST_ROOT/src" "$TEST_ROOT/dst"

    [[ -f "$TEST_ROOT/dst/sub/file1.txt" ]] || return 1
    [[ -f "$TEST_ROOT/dst/sub/file2.txt" ]] || return 1
    [[ -f "$TEST_ROOT/dst/sub/existing.txt" ]] || return 1
    [[ ! -e "$TEST_ROOT/src/sub/file1.txt" ]] || return 1
}

test_merge_moves_file_into_existing_dir() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    mkdir -p "$TEST_ROOT/src" "$TEST_ROOT/dst"
    printf 'content\n' > "$TEST_ROOT/src/file.txt"

    merge_directory_into_destination "$TEST_ROOT/src" "$TEST_ROOT/dst"

    [[ ! -e "$TEST_ROOT/src/file.txt" ]] || return 1
    [[ -f "$TEST_ROOT/dst/file.txt" ]] || return 1
}

echo "=== track.sh module tests ==="
echo

run_case 'same_realpath same file' test_same_realpath_same_file
run_case 'same_realpath symlink to same' test_same_realpath_symlink_to_same
run_case 'same_realpath different files' test_same_realpath_different_files
run_case 'same_realpath missing left' test_same_realpath_missing_left
run_case 'merge moves matching symlink' test_merge_moves_matching_symlink
run_case 'merge replaces conflicting file' test_merge_replaces_conflicting_file
run_case 'merge merges subdirectories' test_merge_merges_subdirectories
run_case 'merge moves file into existing dir' test_merge_moves_file_into_existing_dir

echo
echo "Module tests: $TEST_COUNT run, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
    exit 1
fi
