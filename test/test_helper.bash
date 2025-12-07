#!/usr/bin/env bash
# test_helper.bash - Common setup and utilities for bats tests

# Get the directory paths
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
export BEADS_HK="$PROJECT_ROOT/bin/beads-hk"

# Load bats libraries
# Auto-downloads to test/.bats-libs if not found elsewhere

BATS_LIBS_DIR="$TEST_DIR/.bats-libs"

# Download bats helpers if needed
ensure_bats_libs() {
	if [[ ! -d "$BATS_LIBS_DIR/bats-support" ]]; then
		mkdir -p "$BATS_LIBS_DIR"
		git clone --quiet --depth 1 https://github.com/bats-core/bats-support.git "$BATS_LIBS_DIR/bats-support" 2>/dev/null
	fi
	if [[ ! -d "$BATS_LIBS_DIR/bats-assert" ]]; then
		mkdir -p "$BATS_LIBS_DIR"
		git clone --quiet --depth 1 https://github.com/bats-core/bats-assert.git "$BATS_LIBS_DIR/bats-assert" 2>/dev/null
	fi
}

# Try to load from common locations, fall back to local download
if [[ -d "$PROJECT_ROOT/node_modules/bats-support" ]]; then
	load "$PROJECT_ROOT/node_modules/bats-support/load.bash"
	load "$PROJECT_ROOT/node_modules/bats-assert/load.bash"
elif [[ -f "/opt/homebrew/lib/bats-support/load.bash" ]]; then
	load "/opt/homebrew/lib/bats-support/load.bash"
	load "/opt/homebrew/lib/bats-assert/load.bash"
elif [[ -f "/usr/local/lib/bats-support/load.bash" ]]; then
	load "/usr/local/lib/bats-support/load.bash"
	load "/usr/local/lib/bats-assert/load.bash"
else
	# Download and use local copies
	ensure_bats_libs
	load "$BATS_LIBS_DIR/bats-support/load.bash"
	load "$BATS_LIBS_DIR/bats-assert/load.bash"
fi

# Setup function called before each test
setup() {
	# Create temporary directory for test files
	TEST_TEMP_DIR="$(mktemp -d)"

	# Create mock beads (bd) command
	MOCK_BD_DIR="$TEST_TEMP_DIR/bin"
	MOCK_BD="$MOCK_BD_DIR/bd"
	mkdir -p "$MOCK_BD_DIR"

	cat >"$MOCK_BD" <<'MOCK_EOF'
#!/usr/bin/env bash
# Mock beads command for testing

# Store calls for verification
echo "$@" >> "$BD_CALLS_LOG" 2>/dev/null || true

case "$1" in
    list)
        if [[ "$2" == "--status=in-progress" ]]; then
            cat <<EOF
BD-abc123  [in-progress] Implement user authentication
BD-def456  [in-progress] Fix database connection bug
BD-ghi789  [in-progress] Add API documentation
EOF
        else
            cat <<EOF
BD-abc123  [in-progress] Implement user authentication
BD-def456  [in-progress] Fix database connection bug
BD-xyz999  [done] Old completed task
EOF
        fi
        ;;

    show)
        # Valid beads: BD-abc123, BD-def456, BD-ghi789
        case "$2" in
            BD-abc123|BD-def456|BD-ghi789|BD-valid123)
                cat <<EOF
ID: $2
Title: Test bead
Status: in-progress
Created: 2024-01-01
EOF
                exit 0
                ;;
            *)
                echo "Error: Bead $2 not found" >&2
                exit 1
                ;;
        esac
        ;;

    add)
        echo "Created BD-new123: mock bead"
        echo "BD-new123"
        exit 0
        ;;

    update)
        # Check if bead exists
        case "$2" in
            BD-abc123|BD-def456|BD-ghi789)
                echo "Updated $2"
                exit 0
                ;;
            *)
                echo "Error: Bead $2 not found" >&2
                exit 1
                ;;
        esac
        ;;

    *)
        echo "Unknown beads command: $1" >&2
        exit 1
        ;;
esac
MOCK_EOF

	chmod +x "$MOCK_BD"

	# Set up environment - use full path to mock to avoid using real bd
	export PATH="$MOCK_BD_DIR:$PATH"
	export BEADS_CMD="$MOCK_BD"
	export BD_CALLS_LOG="$TEST_TEMP_DIR/bd_calls.log"

	# Change to temp directory for tests
	cd "$TEST_TEMP_DIR" || return 1

	# Initialize a git repo for tests that need it
	git init --quiet
	git config user.email "test@example.com"
	git config user.name "Test User"

	# Reset environment variables to defaults
	export BEADS_HK_STRICT="false"
	export BEADS_HK_AUTO_FILE="false"
	export BEADS_HK_MAX_FILE_LINES="500"
	export BEADS_HK_MAX_FUNC_LINES="50"
}

# Teardown function called after each test
teardown() {
	# Clean up temporary directory
	if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
		rm -rf "$TEST_TEMP_DIR"
	fi
}

# Helper function to create a test file with content
create_file() {
	local file="$1"
	local content="$2"

	mkdir -p "$(dirname "$file")"
	echo "$content" >"$file"
}

# Helper function to create a Python file with TODOs
create_python_file_with_todos() {
	local file="$1"
	local has_bead_ref="${2:-false}"

	if [[ "$has_bead_ref" == "true" ]]; then
		cat >"$file" <<'EOF'
#!/usr/bin/env python3
# TODO(BD-abc123): Add error handling
def calculate(x, y):
    # FIXME(BD-def456): Handle division by zero
    return x / y

# HACK(BD-ghi789): Temporary workaround
def process():
    pass
EOF
	else
		cat >"$file" <<'EOF'
#!/usr/bin/env python3
# TODO: Add error handling
def calculate(x, y):
    # FIXME: Handle division by zero
    return x / y

# HACK: Temporary workaround
def process():
    pass
EOF
	fi
}

# Helper function to create a large Python file
create_large_python_file() {
	local file="$1"
	local lines="${2:-600}"

	echo "#!/usr/bin/env python3" >"$file"
	for i in $(seq 1 "$lines"); do
		echo "# Line $i" >>"$file"
	done
}

# Helper function to create a Python file with long function
create_python_file_with_long_function() {
	local file="$1"
	local func_lines="${2:-60}"

	cat >"$file" <<'EOF'
#!/usr/bin/env python3

def short_function():
    return True

def very_long_function():
EOF

	for i in $(seq 1 "$func_lines"); do
		echo "    # Function line $i" >>"$file"
	done

	cat >>"$file" <<'EOF'
    return True

def another_short_function():
    return False
EOF
}

# Helper function to create a commit message file
create_commit_msg() {
	local file="${1:-commit_msg.txt}"
	local content="$2"

	echo "$content" >"$file"
}

# Helper function to create a commit message with bead reference
create_commit_msg_with_bead() {
	local file="${1:-commit_msg.txt}"
	local bead_id="${2:-BD-abc123}"
	local relation="${3:-Relates-to}"

	cat >"$file" <<EOF
Add new feature

This commit adds a new feature to the codebase.

$relation: $bead_id
EOF
}

# Helper function to check if beads command was called
assert_bd_called_with() {
	local expected="$1"

	if [[ ! -f "$BD_CALLS_LOG" ]]; then
		echo "BD_CALLS_LOG not found"
		return 1
	fi

	if grep -q "$expected" "$BD_CALLS_LOG"; then
		return 0
	else
		echo "Expected bd to be called with: $expected"
		echo "Actual calls:"
		cat "$BD_CALLS_LOG"
		return 1
	fi
}

# Helper to create mock bd command that always fails
mock_bd_unavailable() {
	rm -f "$MOCK_BD"
	# Don't create the mock - it won't be available
}

# Helper to strip ANSI color codes from output
strip_colors() {
	sed -E 's/\x1b\[[0-9;]*m//g'
}
