# Claude Statusline

A compact Powerline-style status line for Claude Code.

It shows the model, reasoning effort, current directory, Git branch, dirty file count, context usage, token count, cost, elapsed time, API wait ratio, and local time.

## Preview

```text
 ● Sonnet 4.5[1M] 💭 medium  power  main +2  ctx 42% 1.5k/1M  $1.23  10s │ api 50% │ 00:41 
```

High context usage switches the context label to `ctx!` and changes the segment color.

## Requirements

- Claude Code with `statusLine` command support
- Bash
- Python 3
- Git, for branch and dirty-state display
- A terminal font that supports Powerline glyphs, such as a Nerd Font

## Install

```bash
git clone https://github.com/Covet95/claude-statusline.git
cd claude-statusline
./install.sh
```

If your Claude settings are not already configured, add this block to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/YOU/.claude/statusline.sh",
    "padding": 0
  }
}
```

Replace `/Users/YOU` with your home directory.

## Test

```bash
./test.sh
```

You can preview a sample manually:

```bash
./statusline.sh < samples/normal.json
```

## What It Displays

- Model name and reasoning effort
- Current directory basename
- Git branch or detached commit hash
- Dirty file count for tracked and untracked changes
- Context usage percentage and token count
- Total cost
- Total elapsed time
- API wait ratio
- Local clock time

## License

MIT
