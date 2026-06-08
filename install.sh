#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
target_dir="${HOME}/.claude"
target="${target_dir}/statusline.sh"
settings="${target_dir}/settings.json"

mkdir -p "$target_dir"

if [ -f "$target" ]; then
  backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$target" "$backup"
  printf 'Backed up existing statusline to %s\n' "$backup"
fi

cp "${repo_dir}/statusline.sh" "$target"
chmod +x "$target"

printf 'Installed %s\n' "$target"

if [ -f "$settings" ]; then
  printf '\nAdd or update this block in %s if it is not already configured:\n\n' "$settings"
else
  printf '\nCreate %s with this content, or merge the block into your existing settings:\n\n' "$settings"
fi

cat <<JSON
{
  "statusLine": {
    "type": "command",
    "command": "${target}",
    "padding": 0
  }
}
JSON
