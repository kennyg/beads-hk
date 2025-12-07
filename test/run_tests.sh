#!/usr/bin/env bash
# Basic test suite for beads-hk

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BEADS_HK="$PROJECT_ROOT/bin/beads-hk"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helpers
setup() {
	TEST_TMP=$(mktemp -d)
	cd "$TEST_TMP"

	# Mock beads command
	mkdir -p "$TEST_TMP/bin"
	cat >"$TEST_TMP/bin/bd" <<'EOF'
#!/bin/bash
case "$1" in
    list)
        echo "BD-abc123  [in-progress] Test bead 1"
        echo "BD-def456  [in-progress] Test bead 2"
        ;;
    show)
        if [[ "$2" == "BD-abc123" || "$2" == "BD-def456" ]]; then
            echo "Found"
            exit 0
        else
            exit 1
        fi
        ;;
    add)
        echo "Created BD-new123"
        ;;
    update)
        echo "Updated $2"
        ;;
esac
EOF
	chmod +x "$TEST_TMP/bin/bd"
	export PATH="$TEST_TMP/bin:$PATH"
	export BEADS_CMD="bd"
}

teardown() {
	cd /
	rm -rf "$TEST_TMP"
}

assert_success() {
	if [[ $? -eq 0 ]]; then
		return 0
	else
		echo -e "${RED}Expected success but got failure${NC}"
		return 1
	fi
}

assert_failure() {
	if [[ $? -ne 0 ]]; then
		return 0
	else
		echo -e "${RED}Expected failure but got success${NC}"
		return 1
	fi
}

assert_contains() {
	local output="$1"
	local expected="$2"
	if echo "$output" | grep -q "$expected"; then
		return 0
	else
		echo -e "${RED}Expected output to contain: $expected${NC}"
		echo "Got: $output"
		return 1
	fi
}

run_test() {
	local name="$1"
	local func="$2"

	((TESTS_RUN++))

	echo -n "  $name... "

	setup

	if $func; then
		echo -e "${GREEN}PASS${NC}"
		((TESTS_PASSED++))
	else
		echo -e "${RED}FAIL${NC}"
		((TESTS_FAILED++))
	fi

	teardown
}

#------------------------------------------------------------------------------
# Tests
#------------------------------------------------------------------------------

test_help() {
	local output
	output=$("$BEADS_HK" --help 2>&1)
	assert_contains "$output" "beads-hk"
	assert_contains "$output" "check-todos"
}

test_version() {
	local output
	output=$("$BEADS_HK" --version 2>&1)
	assert_contains "$output" "beads-hk v"
}

test_check_todos_clean() {
	# File with proper bead reference
	cat >test.py <<'EOF'
# TODO(BD-abc123): This is tracked
def hello():
    pass
EOF

	local output
	output=$("$BEADS_HK" check-todos test.py 2>&1)
	assert_success
	assert_contains "$output" "All TODOs have bead references"
}

test_check_todos_naked() {
	# File with naked TODO
	cat >test.py <<'EOF'
# TODO: This is not tracked
def hello():
    pass
EOF

	local output
	output=$("$BEADS_HK" check-todos test.py 2>&1) || true
	assert_contains "$output" "Found 1 TODO"
}

test_check_todos_strict() {
	cat >test.py <<'EOF'
# TODO: This is not tracked
EOF

	BEADS_HK_STRICT=true "$BEADS_HK" check-todos test.py 2>&1 || assert_failure
}

test_health_check_small_file() {
	# Small file should pass
	echo "print('hello')" >test.py

	local output
	output=$("$BEADS_HK" health-check test.py 2>&1)
	assert_success
	assert_contains "$output" "Code health checks passed"
}

test_health_check_large_file() {
	# Generate large file
	for i in $(seq 1 600); do
		echo "line $i"
	done >test.py

	local output
	output=$("$BEADS_HK" health-check test.py 2>&1) || true
	assert_contains "$output" "Large file"
}

test_validate_commit_msg_valid() {
	echo "Add feature

Relates-to: BD-abc123" >commit_msg.txt

	"$BEADS_HK" validate-commit-msg commit_msg.txt
	assert_success
}

test_validate_commit_msg_invalid_bead() {
	echo "Add feature

Relates-to: BD-invalid999" >commit_msg.txt

	"$BEADS_HK" validate-commit-msg commit_msg.txt 2>&1 || assert_failure
}

test_prepare_commit_msg() {
	echo "Initial message" >commit_msg.txt

	"$BEADS_HK" prepare-commit-msg commit_msg.txt

	local content
	content=$(cat commit_msg.txt)
	assert_contains "$content" "BD-abc123"
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

echo "Running beads-hk tests..."
echo ""

run_test "help flag" test_help
run_test "version flag" test_version
run_test "check-todos clean" test_check_todos_clean
run_test "check-todos naked TODO" test_check_todos_naked
run_test "check-todos strict mode" test_check_todos_strict
run_test "health-check small file" test_health_check_small_file
run_test "health-check large file" test_health_check_large_file
run_test "validate-commit-msg valid" test_validate_commit_msg_valid
run_test "validate-commit-msg invalid bead" test_validate_commit_msg_invalid_bead
run_test "prepare-commit-msg" test_prepare_commit_msg

echo ""
echo "Results: $TESTS_PASSED/$TESTS_RUN passed"

if [[ $TESTS_FAILED -gt 0 ]]; then
	echo -e "${RED}$TESTS_FAILED test(s) failed${NC}"
	exit 1
else
	echo -e "${GREEN}All tests passed!${NC}"
fi
