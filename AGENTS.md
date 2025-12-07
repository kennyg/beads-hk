# AGENTS.md - Instructions for AI Coding Agents

## Issue Tracking with Beads

This project uses [Beads](https://github.com/steveyegge/beads) for issue tracking. Track ALL work in beads, not markdown TODOs or external systems.

### Essential Commands

```bash
# Find work
bd ready                              # Show issues ready to work (no blockers)
bd list --status=open                 # All open issues
bd show <id>                          # Detailed issue view

# Create & update
bd create --title="..." --type=task   # New issue (task, bug, or feature)
bd update <id> --status=in_progress   # Claim work
bd close <id>                         # Mark complete
bd close <id1> <id2> ...              # Close multiple at once

# Dependencies
bd dep add <issue> <depends-on>       # Add dependency
bd blocked                            # Show blocked issues
```

### Workflow

**Starting work:**
```bash
bd ready                                    # Find available work
bd update <id> --status=in_progress         # Claim it
```

**Completing work:**
```bash
bd close <id>                               # Close completed issues
git add . && git commit -m "..."            # Commit changes
```

### TODO Format

All TODOs must reference a bead:
```bash
# TODO(BD-abc123): description    # Good
# TODO: description               # Bad - will be flagged by beads-hk
```

## Project Overview

**beads-hk**: Git hook integration for [Beads](https://github.com/steveyegge/beads) issue tracker using [hk](https://hk.jdx.dev).

### What This Project Does

Provides a CLI tool (`beads-hk`) that bridges git hooks (via hk) with the Beads issue tracking system. It enforces TODO accountability, runs code health checks, and automates bead lifecycle management through git commit/push workflows.

### Tech Stack

- **Language**: Bash (considering Go rewrite)
- **Dependencies**: beads (`bd`), hk, standard Unix tools
- **Testing**: Bash test runner with mocked beads
- **Config**: pkl (for hk.pkl examples)

### Project Structure

```
bin/           - Main executable
examples/      - Example hk.pkl configurations
test/          - Test suite
```

## Working With This Codebase

### Code Style

- Bash scripts follow Google Shell Style Guide
- Use `shellcheck` for linting
- Functions prefixed with `cmd_` are CLI commands
- Helper functions are internal

### Development Commands

```bash
mise run setup    # Setup dev environment (installs tools, hooks)
mise run test     # Run tests (bats test/beads-hk.bats)
mise run check    # Run linters (shellcheck, shfmt)
mise run fix      # Auto-fix formatting
```

Tests use a mocked `bd` command to avoid requiring real beads installation.

### Before Committing

1. Run: `mise run check`
2. Run: `mise run test`
3. Update README if adding commands

## Agent-Specific Instructions

### Key Files

| File | Purpose | When to Read |
|------|---------|--------------|
| `bin/beads-hk` | Main script | Any code changes |
| `examples/hk.pkl` | Example config | Hook behavior changes |
| `test/run_tests.sh` | Test suite | Adding features |
| `README.md` | Documentation | API/usage changes |

### Adding a New Command

1. Add `cmd_<name>()` function in `bin/beads-hk`
2. Add case in `main()` dispatch
3. Add to usage/help text
4. Add test in `test/run_tests.sh`
5. Update README.md

### Code Health Rules

This project should follow its own advice:

- No naked TODOs (use `TODO(BD-xxx):` format)
- Functions under 50 lines
- File under 500 lines (split if growing)

### Testing Changes

Always run the full test suite:

```bash
mise run test
# Or run a single test:
bats test/beads-hk.bats --filter "test name"
```

For manual testing with real beads:

```bash
# Initialize a test repo
mkdir /tmp/test-repo && cd /tmp/test-repo
git init
bd init

# Install beads-hk
export PATH="/path/to/beads-hk/bin:$PATH"

# Test commands
beads-hk check-todos *.sh
beads-hk health-check *.sh
```

## Boundaries and Limitations

### Out of Scope

- Modifying beads itself
- Modifying hk itself
- Complex AST parsing (keep heuristics simple)

### Requires Human Review

- Changes to command interface
- New environment variables
- Breaking changes to hk.pkl format
