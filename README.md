# Ralph

A working implementation of the Ralph Wiggum autonomous loop technique for Claude Code.

## Background

The [official ralph-wiggum plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) in Anthropic's plugin marketplace is currently broken due to a security update in Claude Code v1.0.20 (August 2025).

The security patch ([CVE-2025-54795](https://www.cvedetails.com/cve/CVE-2025-54795/)) correctly blocks `$()` command substitution and multi-line bash commands to prevent command injection attacks. However, the official plugin's command file contains multi-line bash that triggers this protection:
```
Error: Bash command permission check failed for pattern "...": 
Command contains newlines that could separate multiple commands
```

Multiple issues have been filed:
- [#12170](https://github.com/anthropics/claude-code/issues/12170) - Nov 23, 2025
- [#15640](https://github.com/anthropics/claude-code/issues/15640) - Dec 29, 2025
- [#15708](https://github.com/anthropics/claude-code/issues/15708) - Dec 29, 2025
- [#16037](https://github.com/anthropics/claude-code/issues/16037) - Jan 1, 2026

As of January 3, 2026, these remain unfixed.

## This Plugin

This is a clean reimplementation that works with current Claude Code security restrictions.

**Key architectural difference:** The official plugin tries to execute bash directly from the command file. This plugin instead instructs Claude to create the state file using its Write tool, keeping the command file pure markdown with no bash execution. The stop hook runs as a separate shell script outside the permission system.

## Installation

### Option 1: Dev mode (for testing)
```bash
claude --plugin-dir /path/to/ralph
```

### Option 2: Local marketplace (for permanent use)
```bash
# Create marketplace
mkdir -p ~/claude-plugins/.claude-plugin
echo '{"name": "local", "owner": {"name": "You"}}' > ~/claude-plugins/.claude-plugin/marketplace.json

# Move plugin into marketplace
mv /path/to/ralph ~/claude-plugins/

# In Claude Code:
/plugin marketplace add ~/claude-plugins
/plugin install ralph@local
```

## Usage
```
/ralph:ralph-loop "Your task" --max-iterations 30 --completion-promise "DONE"
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| prompt | The task to complete | (required) |
| --max-iterations N | Safety limit | 30 |
| --completion-promise TEXT | Completion signal | TASK_COMPLETE |

### Examples
```
/ralph:ralph-loop "Build a REST API with tests" --completion-promise "API_COMPLETE"
```
```
/ralph:ralph-loop "Follow the instructions in CLAUDE.md" --max-iterations 50 --completion-promise "BENCHMARK_COMPLETE"
```

### Cancel
```
/ralph:cancel-ralph
```

## How It Works

1. **Command** instructs Claude to create `.claude/ralph-loop.local.md` with task and config
2. **Claude** works on the task
3. **Claude** finishes its turn (natural stop)
4. **Stop hook** fires, checks transcript for `<promise>COMPLETION_PROMISE</promise>`
5. **Not found?** → Hook returns `{"decision": "block", "reason": "..."}`, Claude continues
6. **Found?** → Hook allows stop, cleans up state file
7. **Max iterations?** → Hook allows stop regardless

## Requirements

- Claude Code 1.0.20+
- `jq` (for JSON parsing in stop hook)

## Credits

- **Geoffrey Huntley** — [Original Ralph technique](https://ghuntley.com/ralph/)
- **Boris Cherny** — [Official plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) 
- **Ralph** — [This working reimplementation](https://github.com/dial481/ralph)

## License

MIT
