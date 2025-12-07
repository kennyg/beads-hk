# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**beads-hk** is a Bash CLI tool that integrates git hooks (via [hk](https://hk.jdx.dev)) with the [Beads](https://github.com/steveyegge/beads) issue tracker. It enforces TODO accountability, runs code health checks, and automates bead lifecycle management through git workflows.

## Development Commands

```bash
# Setup development environment (installs tools, hooks)
mise run setup

# Run tests
mise run test              # or: bats test/beads-hk.bats

# Run linters (shellcheck, shfmt)
mise run check             # or: hk run pre-commit --all

# Auto-fix formatting
mise run fix               # or: hk run pre-commit --all --fix

# Install to ~/.local/bin
mise run install
```

## Architecture

### Core Components

- `bin/beads-hk` - Single Bash script (~560 lines) containing all CLI commands
- `hk.pkl` - Git hook configuration for this project (shellcheck, shfmt)
- `examples/hk.pkl` - Full-featured example config for users to copy

### Command Structure

CLI commands are implemented as `cmd_<name>()` functions dispatched from `main()`:

| Command | Purpose |
|---------|---------|
| `check-todos` | Scans files for TODOs without `BD-xxx` bead references |
| `health-check` | Checks file sizes and function lengths |
| `prepare-commit-msg` | Appends in-progress beads as commit message suggestions |
| `validate-commit-msg` | Validates bead references exist |
| `post-commit` | Auto-closes beads on `Closes BD-xxx` patterns |
| `check-merge-risk` | Warns about other in-progress beads |

### Key Patterns

- Environment variables control behavior: `BEADS_HK_STRICT`, `BEADS_HK_AUTO_FILE`, `BEADS_HK_MAX_FILE_LINES`, `BEADS_HK_MAX_FUNC_LINES`
- `maybe_fail()` handles strict vs warning mode
- `check_beads()` gracefully exits when `bd` command unavailable
- Language-specific function length checks use simple heuristics (not AST parsing)

## Testing

Tests use [bats-core](https://github.com/bats-core/bats-core) with bats-assert/bats-support.

- Test file: `test/beads-hk.bats`
- Helper: `test/test_helper.bash` - provides mock `bd` command and utilities
- Mock beads returns predefined responses for `BD-abc123`, `BD-def456`, `BD-ghi789`

```bash
# Run single test
bats test/beads-hk.bats --filter "check-todos passes"

# Run with verbose output
bats test/beads-hk.bats --tap
```

## Code Style

- Follow Google Shell Style Guide
- Use `shellcheck` for linting
- Use `shfmt` for formatting
- Functions prefixed with `cmd_` are CLI entry points
- Keep functions under 50 lines, files under 500 lines (the tool's own rules)
