#!/usr/bin/env bats
# beads-hk.bats - Focused test suite for beads-hk

load test_helper

#------------------------------------------------------------------------------
# CLI Basics
#------------------------------------------------------------------------------

@test "shows usage with no args" {
    run "$BEADS_HK"
    assert_success
    assert_output --partial "USAGE:"
}

@test "shows usage with --help" {
    run "$BEADS_HK" --help
    assert_success
    assert_output --partial "check-todos"
}

@test "shows version" {
    run "$BEADS_HK" --version
    assert_success
    assert_output --partial "beads-hk v"
}

@test "unknown command shows error" {
    run "$BEADS_HK" bogus
    assert_success  # exits 0 after showing usage
    assert_output --partial "Unknown command"
}

#------------------------------------------------------------------------------
# Graceful degradation when bd not installed
#------------------------------------------------------------------------------

@test "exits gracefully when bd not found" {
    # Point BEADS_CMD to nonexistent command
    export BEADS_CMD="nonexistent-bd-command"

    run "$BEADS_HK" check-todos test.py
    assert_success
    assert_output --partial "Beads not found"
}

#------------------------------------------------------------------------------
# check-todos
#------------------------------------------------------------------------------

@test "check-todos passes when all TODOs have bead refs" {
    cat > test.py << 'EOF'
# TODO(BD-abc123): implement this
# FIXME(BD-def456): fix later
EOF

    run "$BEADS_HK" check-todos test.py
    assert_success
    assert_output --partial "All TODOs have bead references"
}

@test "check-todos warns on naked TODO" {
    cat > test.py << 'EOF'
# TODO: naked todo without bead ref
EOF

    run "$BEADS_HK" check-todos test.py
    assert_success  # warns but doesn't fail by default
    assert_output --partial "TODO(s) without bead references"
}

@test "check-todos strict mode fails on naked TODO" {
    cat > test.py << 'EOF'
# TODO: naked todo
EOF

    BEADS_HK_STRICT=true run "$BEADS_HK" check-todos test.py
    assert_failure
}

@test "check-todos handles no files" {
    run "$BEADS_HK" check-todos
    assert_success
    assert_output --partial "No files provided"
}

#------------------------------------------------------------------------------
# health-check
#------------------------------------------------------------------------------

@test "health-check passes for small file" {
    # Create 100 line file (under 500 default threshold)
    for i in $(seq 1 100); do echo "# line $i"; done > small.py

    run "$BEADS_HK" health-check small.py
    assert_success
    assert_output --partial "Code health checks passed"
}

@test "health-check warns on large file" {
    # Create 600 line file (over 500 default threshold)
    for i in $(seq 1 600); do echo "# line $i"; done > large.py

    run "$BEADS_HK" health-check large.py
    assert_success  # warns but doesn't fail
    assert_output --partial "Large file"
}

@test "health-check strict mode fails on large file" {
    for i in $(seq 1 600); do echo "# line $i"; done > large.py

    BEADS_HK_STRICT=true run "$BEADS_HK" health-check large.py
    assert_failure
}

#------------------------------------------------------------------------------
# validate-commit-msg
#------------------------------------------------------------------------------

@test "validate-commit-msg passes with valid bead ref" {
    echo "Fix bug BD-abc123" > msg.txt

    run "$BEADS_HK" validate-commit-msg msg.txt
    assert_success
    assert_output --partial "Bead references validated"
}

@test "validate-commit-msg fails on invalid bead ref" {
    echo "Fix bug BD-invalid999" > msg.txt

    run "$BEADS_HK" validate-commit-msg msg.txt
    assert_failure
    assert_output --partial "Invalid bead references"
}

@test "validate-commit-msg allows no ref in non-strict mode" {
    echo "Fix bug without ref" > msg.txt

    run "$BEADS_HK" validate-commit-msg msg.txt
    assert_success
}

@test "validate-commit-msg strict requires bead ref" {
    echo "Fix bug without ref" > msg.txt

    BEADS_HK_STRICT=true run "$BEADS_HK" validate-commit-msg msg.txt
    assert_failure
    assert_output --partial "must reference a bead"
}
