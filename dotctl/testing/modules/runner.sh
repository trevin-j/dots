#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DOTCTL_LIB="$(cd -- "$SCRIPT_DIR/../../.local/lib/dotctl/lib" && pwd -P)"
TEST_COUNT=0
FAILED=0

source "$DOTCTL_LIB/lib.sh"

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

echo "Running dotctl module tests..."
echo
