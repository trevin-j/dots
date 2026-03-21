#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DOTCTL_LIB="$(cd -- "$SCRIPT_DIR/../../.local/lib/dotctl/lib" && pwd -P)"

source "$DOTCTL_LIB/lib.sh"

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

# --- contains tests ---

test_contains_finds_element() {
    contains "b" "a" "b" "c"
}

test_contains_returns_false_for_missing() {
    ! contains "d" "a" "b" "c" || return 1
}

test_contains_first_element() {
    contains "a" "a" "b" "c"
}

test_contains_last_element() {
    contains "c" "a" "b" "c"
}

# --- path_is_within tests ---

test_path_is_within_exact_match() {
    path_is_within "/home/user/config" "/home/user/config"
}

test_path_is_within_subpath() {
    path_is_within "/home/user/config/file" "/home/user"
}

test_path_is_within_false_for_sibling() {
    ! path_is_within "/home/other/config" "/home/user" || return 1
}

# --- normalize_path tests ---

test_normalize_path_removes_dotdot() {
    local result
    result=$(normalize_path "/home/user/../user/config")
    [[ "$result" == "/home/user/config" ]] || return 1
}

test_normalize_path_keeps_absolute() {
    local result
    result=$(normalize_path "/home/user/config")
    [[ "$result" == "/home/user/config" ]] || return 1
}

# --- is_managed_symlink tests ---

test_is_managed_symlink_inside_dotdir() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    DOTDIR="$TEST_ROOT/dotdir"
    mkdir -p "$DOTDIR/pkg/.config"
    printf 'data\n' > "$DOTDIR/pkg/.config/data"
    ln -s "$DOTDIR/pkg/.config/data" "$TEST_ROOT/link"

    is_managed_symlink "$TEST_ROOT/link"
}

test_is_managed_symlink_outside_dotdir() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    DOTDIR="$TEST_ROOT/dotdir"
    mkdir -p "$DOTDIR/pkg"
    ln -s "/usr/share/other" "$TEST_ROOT/link"

    ! is_managed_symlink "$TEST_ROOT/link" || return 1
}

test_is_managed_symlink_broken() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    DOTDIR="$TEST_ROOT/dotdir"
    mkdir -p "$DOTDIR/pkg"
    ln -s "$DOTDIR/nonexistent" "$TEST_ROOT/link"

    ! is_managed_symlink "$TEST_ROOT/link" || return 1
}

test_is_managed_symlink_regular_file() {
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotctl-mod-test.XXXXXX")
    printf 'data\n' > "$TEST_ROOT/file"

    ! is_managed_symlink "$TEST_ROOT/file" || return 1
}

echo "=== lib.sh module tests ==="
echo

run_case 'contains finds element' test_contains_finds_element
run_case 'contains returns false for missing' test_contains_returns_false_for_missing
run_case 'contains first element' test_contains_first_element
run_case 'contains last element' test_contains_last_element
run_case 'path_is_within exact match' test_path_is_within_exact_match
run_case 'path_is_within subpath' test_path_is_within_subpath
run_case 'path_is_within false for sibling' test_path_is_within_false_for_sibling
run_case 'normalize_path removes dotdot' test_normalize_path_removes_dotdot
run_case 'normalize_path keeps absolute' test_normalize_path_keeps_absolute
run_case 'is_managed_symlink inside dotdir' test_is_managed_symlink_inside_dotdir
run_case 'is_managed_symlink outside dotdir' test_is_managed_symlink_outside_dotdir
run_case 'is_managed_symlink broken' test_is_managed_symlink_broken
run_case 'is_managed_symlink regular file' test_is_managed_symlink_regular_file

echo
echo "Module tests: $TEST_COUNT run, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
    exit 1
fi
