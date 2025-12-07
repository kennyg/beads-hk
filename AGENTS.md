# AGENTS.md - Instructions for AI Coding Agents

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

### Testing

```bash
make test
```

Tests use a mocked `bd` command to avoid requiring real beads installation.

### Before Committing

1. Run: `make lint`
2. Run: `make test`
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
./test/run_tests.sh
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
