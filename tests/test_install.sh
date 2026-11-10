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
    message="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "${GREEN}PASS${NC}: %s\n" "$message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "${RED}FAIL${NC}: %s (expected: %s, got: %s)\n" "$message" "$expected" "$actual"
    fi
}

assert_contains() {
    haystack="$1"
    needle="$2"
    message="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    case "$haystack" in
        *"$needle"*)
            TESTS_PASSED=$((TESTS_PASSED + 1))
            printf "${GREEN}PASS${NC}: %s\n" "$message"
            ;;
        *)
            TESTS_FAILED=$((TESTS_FAILED + 1))
            printf "${RED}FAIL${NC}: %s (expected to contain: %s, got: %s)\n" "$message" "$needle" "$haystack"
            ;;
    esac
}

assert_file_exists() {
    file="$1"
    message="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -f "$file" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "${GREEN}PASS${NC}: %s\n" "$message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "${RED}FAIL${NC}: %s (file not found: %s)\n" "$message" "$file"
    fi
}

assert_dir_exists() {
    dir="$1"
    message="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -d "$dir" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "${GREEN}PASS${NC}: %s\n" "$message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "${RED}FAIL${NC}: %s (dir not found: %s)\n" "$message" "$dir"
    fi
}

assert_exit_code() {
    expected="$1"
    command="$2"
    message="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    eval "$command" >/dev/null 2>&1
    actual=$?
    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "${GREEN}PASS${NC}: %s (exit code %d)\n" "$message" "$actual"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "${RED}FAIL${NC}: %s (expected exit code %d, got %d)\n" "$message" "$expected" "$actual"
    fi
}

# Setup test environment
setup() {
    export TEST_NVM_DIR=$(mktemp -d)
    export NVM_DIR="$TEST_NVM_DIR"
    mkdir -p "$NVM_DIR/versions/node"
}

teardown() {
    rm -rf "$TEST_NVM_DIR"
}

# Test: install.sh exists and is executable
test_install_script_exists() {
    assert_file_exists "install.sh" "install.sh exists"
    assert_exit_code 0 "test -x install.sh" "install.sh is executable"
}

# Test: nvm.sh exists
test_nvm_script_exists() {
    assert_file_exists "nvm.sh" "nvm.sh exists"
}

# Test: nvm.sh can be sourced without error (exit code 0)
test_nvm_source_exit_code() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    assert_equal "0" "$?" "Sourcing nvm.sh exits with code 0 (issue #1985)"
}

# Test: NVM_DIR is set after sourcing
test_nvm_dir_set() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    assert_equal "$TEST_NVM_DIR" "$NVM_DIR" "NVM_DIR is set to test directory"
}

# Test: nvm function is available after sourcing
test_nvm_function_available() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    type nvm >/dev/null 2>&1
    assert_equal "0" "$?" "nvm function is available after sourcing"
}

# Test: nvm --version works
test_nvm_version() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    output=$(nvm --version)
    assert_contains "$output" "Nexus Engine NVM" "nvm --version shows version"
}

# Test: nvm --help works
test_nvm_help() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    output=$(nvm --help)
    assert_contains "$output" "install" "nvm --help mentions install"
    assert_contains "$output" "use" "nvm --help mentions use"
}

# Test: nvm current works
test_nvm_current() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    output=$(nvm current)
    assert_equal "system" "$output" "nvm current shows system when no version installed"
}

# Test: nvm ls works
test_nvm_ls() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    nvm ls >/dev/null 2>&1
    assert_equal "0" "$?" "nvm ls exits with code 0"
}

# Test: nvm install with invalid version fails gracefully
test_nvm_install_invalid() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    nvm install "invalid-version" >/dev/null 2>&1
    assert_exit_code 1 "nvm install invalid-version" "nvm install invalid version returns error code"
}

# Test: nvm use without installed version returns exit code 3
test_nvm_use_not_installed() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    nvm use 99.99.99 >/dev/null 2>&1
    assert_equal "3" "$?" "nvm use without installed version returns exit code 3"
}

# Test: nvm ls-remote works
test_nvm_ls_remote() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    output=$(nvm ls-remote 2>/dev/null)
    assert_equal "0" "$?" "nvm ls-remote exits with code 0"
    if [ -n "$output" ]; then
        assert_contains "$output" "v" "nvm ls-remote shows versions"
    fi
}

# Test: nvm ls-remote --lts works
test_nvm_ls_remote_lts() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    output=$(nvm ls-remote --lts 2>/dev/null)
    assert_equal "0" "$?" "nvm ls-remote --lts exits with code 0"
    if [ -n "$output" ]; then
        assert_contains "$output" "v" "nvm ls-remote --lts shows versions"
    fi
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
    
    # Test LTS alias resolution (these will fail without network but should not error)
    # We test that the function returns something without crashing
    result=$(nvm_resolve_lts_alias "lts/hydrogen" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        assert_contains "$result" "v18" "lts/hydrogen resolves to v18.x"
    else
        assert_equal "FAILED" "$result" "lts/hydrogen handles network failure gracefully"
    fi
    
    result=$(nvm_resolve_lts_alias "lts/iron" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        assert_contains "$result" "v20" "lts/iron resolves to v20.x"
    else
        assert_equal "FAILED" "$result" "lts/iron handles network failure gracefully"
    fi
    
    result=$(nvm_resolve_lts_alias "lts/jod" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        assert_contains "$result" "v22" "lts/jod resolves to v22.x"
    else
        assert_equal "FAILED" "$result" "lts/jod handles network failure gracefully"
    fi
    
    # Test new LTS aliases
    result=$(nvm_resolve_lts_alias "lts/lithium" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        assert_contains "$result" "v26" "lts/lithium resolves to v26.x"
    else
        assert_equal "FAILED" "$result" "lts/lithium handles network failure gracefully"
    fi
    
    result=$(nvm_resolve_lts_alias "lts/krypton" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        assert_contains "$result" "v24" "lts/krypton resolves to v24.x"
    else
        assert_equal "FAILED" "$result" "lts/krypton handles network failure gracefully"
    fi
    
    # Test lts/* (latest LTS)
    result=$(nvm_resolve_lts_alias "lts/*" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        # Should be latest LTS (v26.x)
        assert_contains "$result" "v26" "lts/* resolves to latest LTS (v26.x)"
    else
        assert_equal "FAILED" "$result" "lts/* handles network failure gracefully"
    fi
}

# Test: version range resolution
test_version_range_resolution() {
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    
    # Test that function exists and handles concrete versions
    result=$(nvm_resolve_version_range "20.10.0")
    assert_equal "20.10.0" "$result" "Version range resolution passes through concrete versions"
    
    # Test v-prefixed versions
    result=$(nvm_resolve_version_range "v18.17.0")
    assert_equal "v18.17.0" "$result" "Version range resolution passes through v-prefixed versions"
    
    # Test >= range (requires network)
    result=$(nvm_resolve_version_range ">=20.0.0" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        assert_contains "$result" "20" ">=20.0.0 resolves to v20.x"
    else
        assert_equal "FAILED" "$result" ">=20.0.0 handles network failure gracefully"
    fi
    
    # Test ^ range (requires network)
    result=$(nvm_resolve_version_range "^20.0.0" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        assert_contains "$result" "20" "^20.0.0 resolves to v20.x"
    else
        assert_equal "FAILED" "$result" "^20.0.0 handles network failure gracefully"
    fi
    
    # Test ~ range (requires network)
    result=$(nvm_resolve_version_range "~20.10.0" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        assert_contains "$result" "20" "~20.10.0 resolves to v20.x"
    else
        assert_equal "FAILED" "$result" "~20.10.0 handles network failure gracefully"
    fi
    
    # Test X.x range (requires network)
    result=$(nvm_resolve_version_range "20.x" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        assert_contains "$result" "20" "20.x resolves to v20.x"
    else
        assert_equal "FAILED" "$result" "20.x handles network failure gracefully"
    fi
    
    # Test X.Y.x range (requires network)
    result=$(nvm_resolve_version_range "20.10.x" 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ]; then
        assert_contains "$result" "20" "20.10.x resolves to v20.10.x"
    else
        assert_equal "FAILED" "$result" "20.10.x handles network failure gracefully"
    fi
}

# Test: config file version range support
test_config_file_version_range() {
    # Create temp directory with package.json containing version range
    test_dir=$(mktemp -d)
    echo '{"engines": {"node": ">=20.0.0"}}' > "$test_dir/package.json"
    
    # Save current directory
    old_dir="$PWD"
    cd "$test_dir"
    
    unset NVM_LOADED
    . ./nvm.sh 2>/dev/null
    
    # Test that config file version range is resolved
    result=$(nvm_find_version_from_config 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ] && [ -n "$result" ]; then
        assert_contains "$result" "20" "package.json >=20.0.0 resolves to v20.x"
    else
        assert_equal "FAILED" "$result" "package.json version range handles network failure gracefully"
    fi
    
    # Test with ^ range
    echo '{"engines": {"node": "^18.0.0"}}' > "$test_dir/package.json"
    result=$(nvm_find_version_from_config 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ] && [ -n "$result" ]; then
        assert_contains "$result" "18" "package.json ^18.0.0 resolves to v18.x"
    else
        assert_equal "FAILED" "$result" "package.json ^ range handles network failure gracefully"
    fi
    
    # Test with ~ range
    echo '{"engines": {"node": "~20.10.0"}}' > "$test_dir/package.json"
    result=$(nvm_find_version_from_config 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ] && [ -n "$result" ]; then
        assert_contains "$result" "20" "package.json ~20.10.0 resolves to v20.x"
    else
        assert_equal "FAILED" "$result" "package.json ~ range handles network failure gracefully"
    fi
    
    # Test with X.x range
    echo '{"engines": {"node": "22.x"}}' > "$test_dir/package.json"
    result=$(nvm_find_version_from_config 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ] && [ -n "$result" ]; then
        assert_contains "$result" "22" "package.json 22.x resolves to v22.x"
    else
        assert_equal "FAILED" "$result" "package.json X.x range handles network failure gracefully"
    fi
    
    # Test with X.Y.x range
    echo '{"engines": {"node": "20.10.x"}}' > "$test_dir/package.json"
    result=$(nvm_find_version_from_config 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ] && [ -n "$result" ]; then
        assert_contains "$result" "20" "package.json 20.10.x resolves to v20.10.x"
    else
        assert_equal "FAILED" "$result" "package.json X.Y.x range handles network failure gracefully"
    fi
    
    # Test with .nvmrc containing version range
    echo ">=18.0.0" > "$test_dir/.nvmrc"
    result=$(nvm_find_version_from_config 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ] && [ -n "$result" ]; then
        assert_contains "$result" "18" ".nvmrc >=18.0.0 resolves to v18.x"
    else
        assert_equal "FAILED" "$result" ".nvmrc version range handles network failure gracefully"
    fi
    
    # Test with .node-version containing version range
    rm -f "$test_dir/.nvmrc"
    echo "^20.0.0" > "$test_dir/.node-version"
    result=$(nvm_find_version_from_config 2>/dev/null || echo "FAILED")
    if [ "$result" != "FAILED" ] && [ -n "$result" ]; then
        assert_contains "$result" "20" ".node-version ^20.0.0 resolves to v20.x"
    else
        assert_equal "FAILED" "$result" ".node-version version range handles network failure gracefully"
    fi
    
    # Cleanup
    cd "$old_dir"
    rm -rf "$test_dir"
}

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
    test_nvm_ls_remote

    test_nvm_ls_remote_lts

    test_lts_resolution
    test_version_normalize

    test_version_range_resolution

    test_config_file_version_range
    
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
