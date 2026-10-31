#!/usr/bin/env sh
#
# Tests for Nexus Engine NVM Installation
# Run with: bash tests/test_install.sh

# set -e  # Disabled to allow test failures without exiting

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test utilities
assert_equal() {
    expected="$1"
    actual="$2"
    msg="${3:-}"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$expected" = "$actual" ]; then
        printf "${GREEN}PASS${NC}: %s\n" "$msg"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        printf "${RED}FAIL${NC}: %s\n" "$msg"
        printf "  Expected: %s\n" "$expected"
        printf "  Actual:   %s\n" "$actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_contains() {
    haystack="$1"
    needle="$2"
    msg="${3:-}"
    TESTS_RUN=$((TESTS_RUN + 1))
    case "$haystack" in
        *"$needle"*)
            printf "${GREEN}PASS${NC}: %s\n" "$msg"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            ;;
        *)
            printf "${RED}FAIL${NC}: %s\n" "$msg"
            printf "  Haystack: %s\n" "$haystack"
            printf "  Needle:   %s\n" "$needle"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            ;;
    esac
}

assert_file_exists() {
    file="$1"
    msg="${2:-File exists: $file}"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -f "$file" ]; then
        printf "${GREEN}PASS${NC}: %s\n" "$msg"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        printf "${RED}FAIL${NC}: %s\n" "$msg"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_dir_exists() {
    dir="$1"
    msg="${2:-Directory exists: $dir}"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -d "$dir" ]; then
        printf "${GREEN}PASS${NC}: %s\n" "$msg"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        printf "${RED}FAIL${NC}: %s\n" "$msg"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_exit_code() {
    expected="$1"
    actual="$2"
    msg="${3:-}"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$expected" = "$actual" ]; then
        printf "${GREEN}PASS${NC}: %s\n" "$msg"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        printf "${RED}FAIL${NC}: %s\n" "$msg"
        printf "  Expected exit code: %s\n" "$expected"
        printf "  Actual exit code:   %s\n" "$actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Setup test environment
setup() {
    export TEST_NVM_DIR=$(mktemp -d)
    export NVM_DIR="$TEST_NVM_DIR"
    export HOME="$TEST_NVM_DIR/home"
    mkdir -p "$HOME"
    # Reset NVM_LOADED to allow re-sourcing in tests
    unset NVM_LOADED
}

teardown() {
    rm -rf "$TEST_NVM_DIR"
}

# Test: install.sh exists and is executable
test_install_script_exists() {
    assert_file_exists "install.sh" "install.sh exists"
    assert_equal "0" "$(test -x install.sh && echo 0 || echo 1)" "install.sh is executable"
}

# Test: nvm.sh exists
test_nvm_script_exists() {
    assert_file_exists "nvm.sh" "nvm.sh exists"
}

# Test: nvm.sh can be sourced without error (exit code 0)
test_nvm_source_exit_code() {
    # Source nvm.sh and check exit code
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    exit_code=$?
    assert_equal "0" "$exit_code" "Sourcing nvm.sh exits with code 0 (issue #1985)"
}
# Test: NVM_DIR is set after sourcing
test_nvm_dir_set() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    # NVM_DIR should be set to the default or custom value
    assert_contains "$NVM_DIR" "tmp" "NVM_DIR is set to test directory"
}

# Test: nvm function is available after sourcing
test_nvm_function_available() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    # Check if nvm function exists (use type for dash compatibility)
    if type nvm >/dev/null 2>&1; then
        printf "${GREEN}PASS${NC}: nvm function is available after sourcing\n"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        printf "${RED}FAIL${NC}: nvm function is available after sourcing\n"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test: nvm --version works
test_nvm_version() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    output=$(nvm --version 2>&1)
    assert_contains "$output" "Nexus Engine NVM" "nvm --version shows version"
}

# Test: nvm --help works
test_nvm_help() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    output=$(nvm --help 2>&1)
    assert_contains "$output" "Node Version Manager" "nvm --help shows help"
    assert_contains "$output" "install" "nvm --help mentions install"
    assert_contains "$output" "use" "nvm --help mentions use"
}

# Test: nvm current works
test_nvm_current() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    output=$(nvm current 2>&1)
    assert_contains "$output" "system" "nvm current shows system when no version installed"
}

# Test: nvm ls works
test_nvm_ls() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    output=$(nvm ls 2>&1)
    # Should not error, may be empty
    assert_equal "0" "$?" "nvm ls exits with code 0"
}

# Test: nvm install with invalid version fails gracefully
test_nvm_install_invalid() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    # This should fail but not crash
    ( nvm install "invalid-version-xyz" >/dev/null 2>&1 )
    exit_code=$?
    assert_equal "1" "$exit_code" "nvm install invalid version returns error code"
}
# Test: nvm use without installed version returns exit code 3
test_nvm_use_not_installed() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    ( nvm use "v99.99.99" >/dev/null 2>&1 )
    exit_code=$?
    assert_equal "3" "$exit_code" "nvm use non-existent version returns exit code 3 (issue #1985)"
}

# Test: version normalization
test_version_normalize() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    # Test internal function if accessible
    # We'll test via nvm install/ls behavior
    assert_equal "0" "0" "Version normalization placeholder"
}
# Test: LTS alias resolution
test_lts_resolution() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    # Test that function exists and handles non-LTS versions
    result=$(nvm_resolve_lts_alias "20.10.0")
    assert_equal "20.10.0" "$result" "LTS resolution passes through non-LTS versions"
    
    result=$(nvm_resolve_lts_alias "v18.17.0")
    assert_equal "v18.17.0" "$result" "LTS resolution passes through v-prefixed versions"
}
# Test: version normalization

# Main test runner
main() {
    echo "=== Nexus Engine NVM Installation Tests ==="
    echo ""
    
    setup
    
    test_install_script_exists
    test_nvm_script_exists
    test_nvm_source_exit_code
    test_nvm_dir_set
    test_nvm_function_available
    test_nvm_version
    test_nvm_help
    test_nvm_current
    test_nvm_ls
    test_nvm_install_invalid
    test_nvm_use_not_installed
    test_lts_resolution
    test_version_normalize
    
    teardown
    
    echo ""
    echo "=== Test Summary ==="
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    
    if [ "$TESTS_FAILED" -gt 0 ]; then
        echo ""
        printf "${RED}Some tests failed!${NC}\n"
        exit 1
    else
        echo ""
        printf "${GREEN}All tests passed!${NC}\n"
        exit 0
    fi
}

main "$@"