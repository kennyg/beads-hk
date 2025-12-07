# beads-hk

Git hook integration for [Beads](https://github.com/steveyegge/beads) issue tracker using [hk](https://hk.jdx.dev).

Automates the connection between your git workflow and agent-friendly issue tracking.

## Why?

Based on [Steve Yegge's agent coding tips](https://steve-yegge.medium.com/six-new-tips-for-better-coding-with-agents-d4e9c86e42a9):

- **30-40% of time on code health** - Automated health checks that file beads
- **Swarm merge wall detection** - Early warning for parallel agent work conflicts
- **TODO accountability** - No orphaned TODOs; everything tracked in beads
- **Commit traceability** - Clear connection between work and issues

## Features

| Hook | Feature |
|------|---------|
| `prepare-commit-msg` | Suggests in-progress beads to reference |
| `pre-commit` | Enforces `TODO(BD-xxx)` format |
| `pre-commit` | Code health checks (file size, function length) |
| `commit-msg` | Validates bead references exist |
| `post-commit` | Auto-closes beads on `Closes BD-xxx` |
| `pre-push` | Warns about merge conflicts with other beads |

## Installation

### Prerequisites

- [hk](https://hk.jdx.dev) - `mise use hk` or see hk docs
- [beads](https://github.com/steveyegge/beads) - `go install github.com/steveyegge/beads/cmd/bd@latest`

### Install beads-hk

```bash
# Clone this repo
git clone https://github.com/YOUR_USERNAME/beads-hk.git
cd beads-hk

# Install the script
make install
# Or manually:
# cp bin/beads-hk ~/.local/bin/
# chmod +x ~/.local/bin/beads-hk
```

### Configure your project

```bash
cd your-project

# Initialize beads if not already done
bd init

# Copy the hk config
cp /path/to/beads-hk/examples/hk.pkl ./hk.pkl
# Edit hk.pkl to match your project's file patterns

# Install git hooks
hk install
```

## Usage

### Basic Workflow

```bash
# Work on a bead
bd start BD-abc123

# Make changes, commit with reference
git commit -m "Add feature X

Relates-to: BD-abc123"

# Or close the bead
git commit -m "Complete feature X

Closes BD-abc123"
```

### TODO Format

All TODOs must reference a bead:

```python
# Bad - will be flagged
# TODO: fix this later

# Good - tracked
# TODO(BD-abc123): fix this later
```

Or file a bead first:
```bash
bd add --title "Fix the thing" --tag todo
# Returns BD-xyz789

# Then in code:
# TODO(BD-xyz789): fix this later
```

### Profile-Based Checks

Some checks are optional and profile-gated:

```bash
# Normal commit - basic checks only
git commit -m "Quick fix"

# Thorough commit - includes health checks
HK_PROFILE=health git commit -m "Feature complete"

# Strict mode - requires bead reference
HK_PROFILE=strict git commit -m "Important change

Relates-to: BD-abc123"
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BEADS_CMD` | `bd` | Beads CLI command |
| `BEADS_HK_STRICT` | `false` | Fail on issues instead of warn |
| `BEADS_HK_AUTO_FILE` | `false` | Auto-file beads for health issues |
| `BEADS_HK_MAX_FILE_LINES` | `500` | Threshold for large file warning |
| `BEADS_HK_MAX_FUNC_LINES` | `50` | Threshold for long function warning |

### Customizing hk.pkl

See `examples/hk.pkl` for a full example. Key customizations:

```pkl
// Change file patterns
local codeFiles = List("*.py", "*.go", "*.rs")

// Enable/disable specific hooks
["beads-health"] {
  // Only run on explicit request
  profiles = List("health")
}

// Make TODO check a hard failure
["beads-todo"] {
  // Set env var in the check
  check = "BEADS_HK_STRICT=true beads-hk check-todos {{files}}"
}
```

## Commands

```
beads-hk <command> [args]

Commands:
  check-todos <files...>              Check for TODOs without bead references
  health-check <files...>             Run code health checks
  prepare-commit-msg <msg-file>       Suggest bead references for commit
  validate-commit-msg <msg-file>      Validate commit references valid beads
  post-commit                         Update beads based on commit message
  check-merge-risk                    Warn about potential merge conflicts

Options:
  -h, --help                          Show help
```

## Integration with Agent Workflows

This tool is designed to support AI coding agent workflows:

1. **Agents file beads** for discovered work during code health reviews
2. **Commits reference beads** automatically via prepare-commit-msg
3. **TODOs are tracked** - agents can't leave orphaned work items
4. **Merge walls detected early** - swarm coordination before push

### AGENTS.md Integration

Add to your `AGENTS.md`:

```markdown
## Issue Tracking

Use Beads for all issue tracking:
- File beads for discovered work: `bd add --title "..." --tag health`
- Reference beads in commits: `Relates-to: BD-xxx` or `Closes BD-xxx`
- All TODOs must include bead ID: `TODO(BD-xxx): description`

Before pushing, check for merge risks with other in-progress beads.
```

## Development

```bash
# Run tests
make test

# Lint
make lint

# Build (if converting to Go later)
make build
```

## Roadmap

- [ ] Go rewrite for better beads integration
- [ ] File-to-bead association tracking
- [ ] Smarter merge risk detection (file overlap analysis)
- [ ] Integration with Yegge's orchestrator (when released)
- [ ] VSCode extension for inline bead suggestions

## License

MIT

## Credits

- [Steve Yegge](https://github.com/steveyegge) - Beads and the agent coding philosophy
- [jdx](https://github.com/jdx) - hk git hook manager
