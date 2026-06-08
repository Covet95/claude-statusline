#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
statusline="${script_dir}/statusline.sh"

bash -n "$statusline"

plain_normal=$("$statusline" < "${script_dir}/samples/normal.json" | perl -pe 's/\e\[[0-9;]*m//g')
plain_high=$("$statusline" < "${script_dir}/samples/high-context.json" | perl -pe 's/\e\[[0-9;]*m//g')

case "$plain_normal" in
  *"1.5k/1M"*) ;;
  *) printf 'FAIL: expected normal sample to contain 1.5k/1M\n' >&2; exit 1 ;;
esac

case "$plain_normal" in
  *" │ api 50% │ "*) ;;
  *) printf 'FAIL: expected normal sample to contain visible api separators\n' >&2; exit 1 ;;
esac

case "$plain_high" in
  *"My Project"*) ;;
  *) printf 'FAIL: expected high-context sample to preserve directory names with spaces\n' >&2; exit 1 ;;
esac

case "$plain_high" in
  *"ctx! 91% 950k/1M"*) ;;
  *) printf 'FAIL: expected high-context sample to show ctx! warning\n' >&2; exit 1 ;;
esac

printf 'OK\n'
