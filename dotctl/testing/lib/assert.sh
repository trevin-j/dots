#!/usr/bin/env bash

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_file_exists() {
    local path="$1"
    [[ -e "$path" || -L "$path" ]] || fail "Expected path to exist: $path"
}

assert_not_exists() {
    local path="$1"
    [[ ! -e "$path" && ! -L "$path" ]] || fail "Expected path to not exist: $path"
}

assert_is_symlink() {
    local path="$1"
    [[ -L "$path" ]] || fail "Expected symlink: $path"
}

assert_file_contains() {
    local path="$1"
    local needle="$2"
    grep -Fq "$needle" "$path" || fail "Expected '$needle' in $path"
}

assert_output_contains() {
    local output="$1"
    local needle="$2"
    [[ "$output" == *"$needle"* ]] || fail "Expected output to contain '$needle'"
}

assert_output_not_contains() {
    local output="$1"
    local needle="$2"
    [[ "$output" != *"$needle"* ]] || fail "Expected output to not contain '$needle'"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    [[ "$expected" == "$actual" ]] || fail "Expected '$expected' but got '$actual'"
}
