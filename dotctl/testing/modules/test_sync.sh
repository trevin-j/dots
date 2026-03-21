#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DOTCTL_LIB="$(cd -- "$SCRIPT_DIR/../../.local/lib/dotctl/lib" && pwd -P)"

source "$DOTCTL_LIB/lib.sh"
source "$DOTCTL_LIB/sync.sh"

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

trap cleanup_sandbox EXIT

echo "=== sync.sh module tests ==="
echo

echo "  (sync_repo requires a real git repo — tested via integration suite)"
echo "  cmd_sync_help defined: $(type -t cmd_sync_help == 'function' && echo yes || echo no)"

echo
echo "Module tests: $TEST_COUNT run (syncRepo covered by integration tests)"
